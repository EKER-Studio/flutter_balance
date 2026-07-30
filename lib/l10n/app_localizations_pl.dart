// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Polish (`pl`).
class AppLocalizationsPl extends AppLocalizations {
  AppLocalizationsPl([String locale = 'pl']) : super(locale);

  @override
  String get appTitle => 'PureWeight';

  @override
  String get settingsTitle => 'Ustawienia';

  @override
  String get metricUnit => 'Metryczny (kg, cm)';

  @override
  String get imperialUnit => 'Imperialny (lb, ft/in)';

  @override
  String get height => 'Wzrost';

  @override
  String get goal => 'Cel';

  @override
  String get targetWeight => 'Waga docelowa';

  @override
  String get notSet => 'Nie ustawiono';

  @override
  String get security => 'Bezpieczeństwo';

  @override
  String get biometricLock => 'Blokada biometryczna';

  @override
  String get biometricDesc =>
      'Wymagaj Face ID lub odcisku palca przy uruchamianiu';

  @override
  String get database => 'Baza danych';

  @override
  String get importCsv => 'Importuj dane z CSV';

  @override
  String get importCsvDesc =>
      'Importuj wpisy wagi z poprzednio wyeksportowanego pliku CSV.';

  @override
  String get wipeData => 'Wyczyść wszystkie dane';

  @override
  String get wipeDataDesc =>
      'To trwale usunie wszystkie wpisy wagi i zresetuje ustawienia aplikacji.';

  @override
  String get cancel => 'Anuluj';

  @override
  String get save => 'Zapisz';

  @override
  String get retry => 'Spróbuj ponownie';

  @override
  String get invalidPositiveNumber => 'Wprowadź poprawną liczbę dodatnią.';

  @override
  String get heightDialogTitle => 'Ustaw wzrost';

  @override
  String get heightCmLabel => 'Wzrost (cm)';

  @override
  String get heightHint => 'np. 177';

  @override
  String get targetWeightDialogTitle => 'Waga docelowa';

  @override
  String get weightInKgLabel => 'Waga (kg)';

  @override
  String get weightInLbLabel => 'Waga w lb';

  @override
  String get weightHint => 'np. 75,5';

  @override
  String get noteLabel => 'Notatka (opcjonalnie)';

  @override
  String get theme => 'Motyw';

  @override
  String get system => 'Systemowy';

  @override
  String get light => 'Jasny';

  @override
  String get dark => 'Ciemny';

  @override
  String get measurementUnit => 'Jednostka miary';

  @override
  String get biometricsNotAvailable =>
      'Biometria niedostępna na tym urządzeniu';

  @override
  String get wipeDataContent =>
      'To trwale usunie wszystkie wpisy wagi i zresetuje ustawienia aplikacji. Tej operacji nie można cofnąć.';

  @override
  String get wipeDataButton => 'Wyczyść dane';

  @override
  String get dataWipedSuccess =>
      'Wszystkie dane zostały wyczyszczone. Uruchom aplikację ponownie.';

  @override
  String errorWipingData(Object error) {
    return 'Błąd podczas czyszczenia danych: $error';
  }

  @override
  String get importNoDataFound =>
      'Nie znaleziono poprawnych wpisów wagi w zaimportowanym pliku.';

  @override
  String importSuccess(Object count) {
    return 'Zaimportowano $count wpisów.';
  }

  @override
  String get importFailed => 'Nie udało się zaimportować danych.';

  @override
  String importError(Object error) {
    return 'Błąd importu: $error';
  }

  @override
  String get exportCsv => 'Eksportuj CSV';

  @override
  String get setYourHeightTitle => 'Ustaw swój wzrost';

  @override
  String get emptyState => 'Brak wpisów. Dodaj swój pierwszy pomiar poniżej!';

  @override
  String get history => 'Historia';

  @override
  String get stats => 'Statystyki';

  @override
  String get lowest => 'Najniższa';

  @override
  String get highest => 'Najwyższa';

  @override
  String get toGoal => 'Do celu';

  @override
  String get reached => 'Osiągnięto!';

  @override
  String get latestMeasurement => 'Ostatni pomiar';

  @override
  String get addWeight => 'Dodaj wagę';

  @override
  String get weightCannotBeEmpty => 'Waga nie może być pusta';

  @override
  String get enterValidNumber => 'Wprowadź poprawną liczbę';

  @override
  String get weightRangeError => 'Waga musi być z zakresu od 20 do 300 kg';

  @override
  String get bmi => 'BMI';

  @override
  String bmiValue(Object value) {
    return 'BMI: $value';
  }

  @override
  String get bmiSubtitle => 'Na podstawie Twojego wzrostu i ostatniej wagi';

  @override
  String get lastUpdatedToday => 'Ostatnia aktualizacja: Dzisiaj';

  @override
  String lastUpdatedDate(Object date) {
    return 'Ostatnia aktualizacja: $date';
  }

  @override
  String get setWeightGoal => 'Ustaw cel wagi';

  @override
  String get weightTrend => 'Trend wagi';

  @override
  String get weightGoal => 'Cel wagowy';

  @override
  String get goalNotSet => 'Cel nie ustawiony';

  @override
  String get goalAchieved => 'Cel osiągnięty!';

  @override
  String get toTarget => 'do celu';

  @override
  String get setGoalMotivation => 'Ustaw cel, aby zachować motywację';

  @override
  String get rightOnTarget => 'Jesteś dokładnie przy celu';

  @override
  String get targetLabel => 'Cel:';

  @override
  String get chartEmpty => 'Za mało danych, aby wyświetlić wykres.';

  @override
  String get week => 'Tydzień';

  @override
  String get month => 'Miesiąc';

  @override
  String get year => 'Rok';

  @override
  String get all => 'Wszystkie';

  @override
  String get chartTargetLabel => 'Cel';

  @override
  String get bmiCategoryUnderweight => 'Niedowaga';

  @override
  String get bmiCategoryNormal => 'Norma';

  @override
  String get bmiCategoryOverweight => 'Nadwaga';

  @override
  String get bmiCategoryObese => 'Otyłość';

  @override
  String get bmiCategoryDescriptionUnderweight =>
      'BMI poniżej 18,5 — warto zyskać na wadze';

  @override
  String get bmiCategoryDescriptionNormal =>
      'BMI między 18,5 a 24,9 — zakres zdrowy';

  @override
  String get bmiCategoryDescriptionOverweight =>
      'BMI między 25,0 a 29,9 — niewielki nadmiar wagi';

  @override
  String get bmiCategoryDescriptionObese =>
      'BMI 30,0 lub więcej — warto skonsultować się ze specjalistą';

  @override
  String get biometricAuthReason =>
      'Zautentyfikuj się, aby uzyskać dostęp do PureWeight';

  @override
  String get appLocked => 'Aplikacja zablokowana';

  @override
  String get unlock => 'Odblokuj';

  @override
  String get notifications => 'Powiadomienia';

  @override
  String get dailyReminder => 'Codzienne przypomnienie';

  @override
  String get dailyReminderDesc => 'Przypominaj codziennie o ważeniu';

  @override
  String get reminderTime => 'Godzina przypomnienia';

  @override
  String get notificationsDisabledOs =>
      'Powiadomienia są wyłączone w ustawieniach systemu.';

  @override
  String get openSettings => 'Ustawienia';

  @override
  String get errorStream => 'Błąd połączenia z bazą danych.';

  @override
  String get errorHeightNotSet => 'Najpierw ustaw swój wzrost.';

  @override
  String get errorAddEntryFailed => 'Nie udało się dodać pomiaru.';

  @override
  String get errorDeleteEntryFailed => 'Nie udało się usunąć pomiaru.';

  @override
  String get errorReadFailed => 'Nie udało się odczytać danych wagi.';

  @override
  String get errorWriteFailed => 'Nie udało się zapisać danych wagi.';

  @override
  String get errorWipeFailed => 'Nie udało się wyczyścić danych wagi.';

  @override
  String get deleteEntryTooltip => 'Usuń wpis';

  @override
  String skippedRows(Object count) {
    return 'Pominięto $count wierszy';
  }

  @override
  String chartSemanticsTitle(Object period, Object weight) {
    return 'Wykres liniowy historii wagi dla okresu $period. Ostatni zarejestrowany wynik to $weight.';
  }

  @override
  String get chartSemanticsFilter => 'filtr';

  @override
  String get tabToday => 'Dzisiaj';

  @override
  String get tabCalendar => 'Kalendarz';

  @override
  String get tabStats => 'Statystyki';

  @override
  String get tabSettings => 'Ustawienia';

  @override
  String get todaySummary => 'Dzisiejsze podsumowanie';

  @override
  String get noEntriesToday => 'Brak zarejestrowanych pomiarów dzisiaj.';

  @override
  String addMeasurementForDate(Object date) {
    return 'Dodaj pomiar dla $date';
  }

  @override
  String get missingData => 'Brak danych';

  @override
  String get singleEntry => '1 pomiar';

  @override
  String multipleEntries(Object count) {
    return '$count pomiary';
  }

  @override
  String get loggingStreak => 'Seria ważenia';

  @override
  String streakDays(Object count) {
    return '$count dni';
  }

  @override
  String get monthlyCompliance => 'Regularność w miesiącu';

  @override
  String get averageWeight => 'Średnia waga';

  @override
  String get totalProgress => 'Całkowita zmiana';
}
