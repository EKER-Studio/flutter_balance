
import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:isar_community/isar.dart';
import 'package:balance/core/utils/field_cipher.dart';
import 'package:balance/features/weight/data/models/weight_entry_model.dart';
import 'package:balance/features/weight/domain/entities/weight_entry.dart';
import 'package:balance/features/weight/domain/repositories/weight_repository.dart';
import 'package:balance/features/weight/domain/weight_error_type.dart';

typedef _DecryptionPayload = (
  int id,
  DateTime dateTime,
  String encryptedWeight,
  String? encryptedNote,
);

List<WeightEntry> _decryptPayloads((List<_DecryptionPayload>, Uint8List) args) {
  final payloads = args.$1;
  final key = args.$2;

  return payloads.map((p) {
    double weight = 0.0;
    String? note;

    try {
      final decryptedStr = FieldCipher.decrypt(p.$3, key);
      weight = double.tryParse(decryptedStr) ?? 0.0;
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[IsarWeightRepository] Decryption failed for weight (id: ${p.$1}, dateTime: ${p.$2}): ${e.runtimeType}',
        );
      }
      weight = 0.0;
    }

    if (p.$4 != null && p.$4!.isNotEmpty) {
      try {
        note = FieldCipher.decrypt(p.$4!, key);
      } catch (e) {
        if (kDebugMode) {
          debugPrint(
            '[IsarWeightRepository] Decryption failed for note (id: ${p.$1}, dateTime: ${p.$2}): ${e.runtimeType}',
          );
        }
        note = '[Decryption Error]';
      }
    }

    return WeightEntry(id: p.$1, weightKg: weight, dateTime: p.$2, note: note);
  }).toList();
}

typedef _EncryptionPayload = (
  int id,
  DateTime dateTime,
  String encryptedWeight,
  String? encryptedNote,
);

List<_EncryptionPayload> _encryptPayloads((List<WeightEntry>, Uint8List) args) {
  final entries = args.$1;
  final key = args.$2;

  return entries.map((entity) {
    final encryptedWeight = FieldCipher.encrypt(
      entity.weightKg.toString(),
      key,
    );
    String? encryptedNote;
    if (entity.note != null && entity.note!.isNotEmpty) {
      encryptedNote = FieldCipher.encrypt(entity.note!, key);
    }
    return (
      entity.id == 0 ? Isar.autoIncrement : entity.id,
      entity.dateTime,
      encryptedWeight,
      encryptedNote,
    );
  }).toList();
}

/// An Isar-backed implementation of [WeightRepository] using field-level AES-256 encryption.
///
/// Weight and note values are encrypted with [FieldCipher] before persistence
/// and decrypted on read. The watch stream is resilient: transient failures
/// (e.g. an inaccessible encryption key while the device is locked) trigger an
/// exponential retry that is immediately short-circuited by the optional
/// [unlockSignal] emitted after successful biometric authentication.
///
/// ```dart
/// final repository = IsarWeightRepository(
///   isar: isar,
///   unlockSignal: BiometricService.instance.authenticationSuccesses,
/// );
/// final stream = repository.watchAllEntries();
//// ```
class IsarWeightRepository implements WeightRepository {
  /// The default cap on entries loaded or watched at once, newest-first.
  ///
  /// Covers roughly 14 years of daily weigh-ins plus multiple measurements
  /// per day, so the cap is practically unreachable for realistic users.
  static const int defaultMaxEntriesLoaded = 5000;

  /// The maximum number of entries loaded or watched at once, newest-first.
  ///
  /// Bounds memory/UI cost for very long-running users. Entries beyond this
  /// cap are not visible to [WeightBloc] (streaks, statistics, calendar).
  /// Configurable for tests; add pagination rather than raising this further.
  final int maxEntriesLoaded;

  /// An optional stream fired after each successful biometric authentication.
  ///
  /// The [watchAllEntries] retry loop wakes up on this signal and re-subscribes
  /// immediately, instead of waiting out the full backoff, once the user has
  /// authenticated again and the device keystore is accessible.
  final Stream<void>? unlockSignal;

  /// The base delay in milliseconds before the first [watchAllEntries] retry.
  static const int _retryBaseDelayMs = 250;

  /// The cap in milliseconds on the exponential retry backoff.
  static const int _retryMaxDelayMs = 32000;

  /// The [Isar] database instance.
  final Isar isar;

  /// The secure storage instance for retrieving the encryption key.
  final FlutterSecureStorage secureStorage;

  /// A cached AES-256 encryption key, dropped on stream failures so it is
  /// re-read from secure storage once the device is unlocked again.
  Uint8List? _encryptionKey;

  /// Creates an [IsarWeightRepository] backed by [isar] and managed secure storage.
  ///
  /// Takes an optional [secureStorage] handler.
  /// Takes an optional [encryptionKey] for testing override.
  /// Takes an optional [maxEntriesLoaded] cap, defaulting to [defaultMaxEntriesLoaded].
  /// Takes an optional [unlockSignal] that triggers immediate stream recovery.
  IsarWeightRepository({
    required this.isar,
    this.secureStorage = const FlutterSecureStorage(),
    this._encryptionKey,
    this.maxEntriesLoaded = defaultMaxEntriesLoaded,
    this.unlockSignal,
  });

  /// Resolves the live [Isar] instance for this repository.
  ///
  /// Prefers the currently registered open instance with the same name so
  /// operations keep working after [DatabaseModule] recovers the database
  /// (e.g. on app resumption), falling back to the captured [isar] instance.
  Isar get liveIsar {
    final registered = Isar.getInstance(isar.name);
    return (registered != null && registered.isOpen) ? registered : isar;
  }

  /// Loads the cached AES-256 key or reads it from secure storage.
  ///
  /// Throws [WeightRepositoryException] with the given [WeightErrorType] when
  //// the key is missing or inaccessible.
  Future<Uint8List> _getOrLoadKey({bool isWrite = false}) async {
    if (_encryptionKey != null) {
      return _encryptionKey!;
    }
    String? stored;
    try {
      stored = await secureStorage.read(key: 'isar_encryption_key');
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[IsarWeightRepository] Error reading key from secureStorage: ${e.runtimeType}',
        );
      }
    }

    if (stored != null && stored.isNotEmpty) {
      final key = Uint8List.fromList(base64Decode(stored));
      _encryptionKey = key;
      return key;
    }

    throw WeightRepositoryException(
      type: isWrite ? WeightErrorType.writeFailed : WeightErrorType.readFailed,
      message: 'Missing or inaccessible encryption key',
    );
  }

  /// Converts a domain [WeightEntry] into its encrypted [WeightEntryModel].
  WeightEntryModel _entityToModel(WeightEntry entity, Uint8List key) {
    final model = WeightEntryModel()
      ..id = entity.id == 0 ? Isar.autoIncrement : entity.id
      ..dateTime = entity.dateTime
      ..encryptedWeight = FieldCipher.encrypt(entity.weightKg.toString(), key);

    if (entity.note != null && entity.note!.isNotEmpty) {
      model.encryptedNote = FieldCipher.encrypt(entity.note!, key);
    } else {
      model.encryptedNote = null;
    }

    return model;
  }

  /// Emits decrypted weight entries in real time, newest first, bounded by
  /// [maxEntriesLoaded].
  ///
  /// Backed by a reactive Isar watch stream on `weightEntryModels` with
  /// `fireImmediately: true`, so the first emission arrives on subscription.
  /// The stream is resilient: any error drops the cached encryption key and
  /// retries the subscription with exponential backoff, short-circuited by
  /// [unlockSignal] when provided.
  ///
  /// Emits a [WeightRepositoryException] as a stream error if the decryption
  /// key is missing or the underlying Isar stream fails. Never completes on
  /// its own.
  @override
  Stream<List<WeightEntry>> watchAllEntries() {
    return resilientStream(
      _watchAndDecryptEntries,
      mapError: (error, stack) {
        // Drop the cached key so the next attempt re-reads it from secure
        // storage, which becomes accessible again once the user unlocks the
        // device and authenticates.
        _encryptionKey = null;
        if (kDebugMode) {
          debugPrint(
            '[IsarWeightRepository] watchAllEntries failure: $error\n$stack',
          );
        }
        return error is WeightRepositoryException
            ? error
            : WeightRepositoryException(
                type: WeightErrorType.streamError,
                message: 'Weight entry stream failure: $error',
                sourceError: error,
              );
      },
      recoverySignal: unlockSignal,
      backoffFor: (consecutiveFailures) {
        final shift = consecutiveFailures > 7 ? 7 : consecutiveFailures;
        final delayMs = _retryBaseDelayMs << shift;
        return Duration(
          milliseconds: delayMs < _retryMaxDelayMs ? delayMs : _retryMaxDelayMs,
        );
      },
    );
  }

  /// Watches the Isar query, decrypting each emitted batch with the loaded key.
  ///
  /// The returned stream errors (surfaced as a [WeightRepositoryException])
  /// when the encryption key is missing or the database raises an error, but
  //// never completes on its own.
  Stream<List<WeightEntry>> _watchAndDecryptEntries() {
    return liveIsar.weightEntryModels
        .where()
        .sortByDateTimeDesc()
        .limit(maxEntriesLoaded)
        .watch(fireImmediately: true)
        .asyncMap((models) async {
          try {
            final key = await _getOrLoadKey(isWrite: false);
            if (models.isEmpty) return [];
            final payloads = models
                .map(
                  (m) => (m.id, m.dateTime, m.encryptedWeight, m.encryptedNote),
                )
                .toList();
            return await compute(_decryptPayloads, (payloads, key));
          } on WeightRepositoryException {
            rethrow;
          } catch (e) {
            if (kDebugMode) {
              debugPrint(
                '[IsarWeightRepository] watchAllEntries decryption error: '
                '${e.runtimeType}',
              );
            }
            throw WeightRepositoryException(
              type: WeightErrorType.readFailed,
              message: 'Failed to decrypt weight entries: ${e.runtimeType}',
              sourceError: e,
            );
          }
        });
  }

  /// Reads and decrypts up to [maxEntriesLoaded] entries, newest first.
  ///
  /// Throws [WeightRepositoryException] with [WeightErrorType.readFailed] when
  /// the encryption key is missing or the Isar query or decryption fails.
  @override
  Future<List<WeightEntry>> getAllEntries() async {
    try {
      final key = await _getOrLoadKey(isWrite: false);
      final models = await liveIsar.weightEntryModels
          .where()
          .sortByDateTimeDesc()
          .limit(maxEntriesLoaded)
          .findAll();
      if (models.isEmpty) return [];
      final payloads = models
          .map((m) => (m.id, m.dateTime, m.encryptedWeight, m.encryptedNote))
          .toList();
      return await compute(_decryptPayloads, (payloads, key));
    } on WeightRepositoryException {
      rethrow;
    } on IsarError catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[IsarWeightRepository] getAllEntries IsarError: ${e.runtimeType}',
        );
      }
      throw WeightRepositoryException(
        type: WeightErrorType.readFailed,
        message: 'Database read failure: ${e.message}',
        sourceError: e,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[IsarWeightRepository] getAllEntries unexpected error: ${e.runtimeType}',
        );
      }
      throw WeightRepositoryException(
        type: WeightErrorType.readFailed,
        message: 'Unexpected error while reading entries: ${e.runtimeType}',
        sourceError: e,
      );
    }
  }

  /// Encrypts and persists [entry] within a single Isar write transaction.
  ///
  /// Assigns an auto-increment [WeightEntry.id] when it is unset.
  ///
  /// Throws [WeightRepositoryException] with [WeightErrorType.writeFailed] when
  /// the encryption key is missing, the write transaction fails, or an
  /// unexpected error occurs.
  @override
  Future<void> addEntry(WeightEntry entry) async {
    try {
      final key = await _getOrLoadKey(isWrite: true);
      final model = _entityToModel(entry, key);
      await liveIsar.writeTxn(() async {
        await liveIsar.weightEntryModels.put(model);
      });
    } on WeightRepositoryException {
      rethrow;
    } on IsarError catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[IsarWeightRepository] addEntry IsarError: ${e.runtimeType}',
        );
      }
      throw WeightRepositoryException(
        type: WeightErrorType.writeFailed,
        message: 'Database write failure: ${e.message}',
        sourceError: e,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[IsarWeightRepository] addEntry unexpected error: ${e.runtimeType}',
        );
      }
      throw WeightRepositoryException(
        type: WeightErrorType.writeFailed,
        message: 'Unexpected error while adding entry: $e',
        sourceError: e,
      );
    }
  }

  /// Deletes the entry identified by [id] within a single Isar write transaction.
  ///
  /// Throws [WeightRepositoryException] with
  /// [WeightErrorType.deleteEntryFailed] when the delete transaction fails.
  @override
  Future<void> deleteEntry(int id) async {
    try {
      await liveIsar.writeTxn(() async {
        await liveIsar.weightEntryModels.delete(id);
      });
    } on IsarError catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[IsarWeightRepository] deleteEntry IsarError: ${e.runtimeType}',
        );
      }
      throw WeightRepositoryException(
        type: WeightErrorType.deleteEntryFailed,
        message: 'Database delete failure: ${e.message}',
        sourceError: e,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[IsarWeightRepository] deleteEntry unexpected error: ${e.runtimeType}',
        );
      }
      throw WeightRepositoryException(
        type: WeightErrorType.deleteEntryFailed,
        message: 'Unexpected error while deleting entry: $e',
        sourceError: e,
      );
    }
  }

  /// Encrypts and persists all [entries] within a single Isar write transaction.
  ///
  /// Returns the number of models written. Throws [WeightRepositoryException]
  /// with [WeightErrorType.writeFailed] when the encryption key is missing,
  /// the bulk transaction fails, or an unexpected error occurs.
  @override
  Future<int> bulkImportEntries(List<WeightEntry> entries) async {
    try {
      final key = await _getOrLoadKey(isWrite: true);
      final payloads = await compute(_encryptPayloads, (entries, key));
      final models = payloads.map((p) {
        return WeightEntryModel()
          ..id = p.$1
          ..dateTime = p.$2
          ..encryptedWeight = p.$3
          ..encryptedNote = p.$4;
      }).toList();
      await liveIsar.writeTxn(() async {
        await liveIsar.weightEntryModels.putAll(models);
      });
      return models.length;
    } on WeightRepositoryException {
      rethrow;
    } on IsarError catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[IsarWeightRepository] bulkImportEntries IsarError: ${e.runtimeType}',
        );
      }
      throw WeightRepositoryException(
        type: WeightErrorType.writeFailed,
        message: 'Database bulk import failure: ${e.message}',
        sourceError: e,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[IsarWeightRepository] bulkImportEntries unexpected error: ${e.runtimeType}',
        );
      }
      throw WeightRepositoryException(
        type: WeightErrorType.writeFailed,
        message: 'Unexpected error during bulk import: $e',
        sourceError: e,
      );
    }
  }

  /// Wipes all stored Isar collections within a single write transaction.
  ///
  /// Throws [WeightRepositoryException] with [WeightErrorType.wipeFailed] when
  /// the clear transaction fails or an unexpected error occurs.
  @override
  Future<void> clearAllData() async {
    try {
      await liveIsar.writeTxn(() async {
        await liveIsar.clear();
      });
    } on IsarError catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[IsarWeightRepository] clearAllData IsarError: ${e.runtimeType}',
        );
      }
      throw WeightRepositoryException(
        type: WeightErrorType.wipeFailed,
        message: 'Database wipe failure: ${e.message}',
        sourceError: e,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[IsarWeightRepository] clearAllData unexpected error: ${e.runtimeType}',
        );
      }
      throw WeightRepositoryException(
        type: WeightErrorType.wipeFailed,
        message: 'Unexpected error while clearing data: $e',
        sourceError: e,
      );
    }
  }
}

/// Re-subscribes to [createStream] whenever it errors or completes.
///
/// Each failure is surfaced to the listener via [mapError] before the retry
/// loop waits [backoffFor] — an exponential delay bounded by the caller —
/// unless [recoverySignal] fires first. The returned stream never terminates
/// on its own, so transient infrastructure failures (e.g. an encryption key
/// that is inaccessible while the device is locked) recover without a restart.
///
/// The controller approach is used (instead of `yield*`) because inner-stream
/// errors forwarded through `yield*` cannot be intercepted by a surrounding
/// `try`/`catch` when the listener handles errors.
///
/// @param createStream Factory producing the stream to retry.
/// @param mapError Maps each failure into the error surfaced to listeners.
/// @param recoverySignal Optional signal that fires a retry before the backoff
///   elapses, so recovery is immediate once the underlying condition clears.
/// @param backoffFor Computes the retry delay from the number of consecutive failures.
Stream<T> resilientStream<T>(
  Stream<T> Function() createStream, {
  required Object Function(Object error, StackTrace stack) mapError,
  Stream<void>? recoverySignal,
  required Duration Function(int consecutiveFailures) backoffFor,
}) {
  final controller = StreamController<T>();
  var consecutiveFailures = 0;
  var disposed = false;
  StreamSubscription<T>? sourceSub;
  Timer? retryTimer;
  StreamSubscription<void>? retryWaitSub;

  void cancelWait() {
    retryTimer?.cancel();
    retryTimer = null;
    retryWaitSub?.cancel();
    retryWaitSub = null;
  }

  // Forward references allow the mutually recursive retry closures below.
  void Function() resubscribe = () {};
  void Function() scheduleRetry = () {};

  resubscribe = () {
    if (disposed) return;
    cancelWait();
    sourceSub?.cancel();
    if (disposed) return;
    sourceSub = createStream().listen(
      (data) {
        if (disposed) return;
        consecutiveFailures = 0;
        controller.add(data);
      },
      onError: (Object error, StackTrace stack) {
        if (disposed) return;
        consecutiveFailures++;
        controller.addError(mapError(error, stack), stack);
        scheduleRetry();
      },
      onDone: () {
        if (disposed) return;
        // A clean completion is treated like a disruption: the underlying
        // stream is expected to stay open while the database is alive.
        scheduleRetry();
      },
    );
  };

  scheduleRetry = () {
    if (disposed) return;
    final backoff = backoffFor(consecutiveFailures);
    final signal = recoverySignal;
    if (signal == null) {
      retryTimer = Timer(backoff, resubscribe);
    } else {
      retryWaitSub = signal
          .timeout(backoff)
          .listen((_) => resubscribe(), onError: (Object _) => resubscribe());
    }
  };

  controller.onCancel = () {
    disposed = true;
    cancelWait();
    sourceSub?.cancel();
    sourceSub = null;
  };

  resubscribe();
  return controller.stream;
}
