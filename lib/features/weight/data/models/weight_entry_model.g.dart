// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'weight_entry_model.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetWeightEntryModelCollection on Isar {
  IsarCollection<WeightEntryModel> get weightEntryModels => this.collection();
}

const WeightEntryModelSchema = CollectionSchema(
  name: r'WeightEntryModel',
  id: 7313730065132991878,
  properties: {
    r'dateTime': PropertySchema(
      id: 0,
      name: r'dateTime',
      type: IsarType.dateTime,
    ),
    r'note': PropertySchema(id: 1, name: r'note', type: IsarType.string),
    r'weightKg': PropertySchema(
      id: 2,
      name: r'weightKg',
      type: IsarType.double,
    ),
  },

  estimateSize: _weightEntryModelEstimateSize,
  serialize: _weightEntryModelSerialize,
  deserialize: _weightEntryModelDeserialize,
  deserializeProp: _weightEntryModelDeserializeProp,
  idName: r'id',
  indexes: {
    r'dateTime': IndexSchema(
      id: -138851979697481250,
      name: r'dateTime',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'dateTime',
          type: IndexType.value,
          caseSensitive: false,
        ),
      ],
    ),
  },
  links: {},
  embeddedSchemas: {},

  getId: _weightEntryModelGetId,
  getLinks: _weightEntryModelGetLinks,
  attach: _weightEntryModelAttach,
  version: '3.3.2',
);

int _weightEntryModelEstimateSize(
  WeightEntryModel object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.note;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _weightEntryModelSerialize(
  WeightEntryModel object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTime(offsets[0], object.dateTime);
  writer.writeString(offsets[1], object.note);
  writer.writeDouble(offsets[2], object.weightKg);
}

WeightEntryModel _weightEntryModelDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = WeightEntryModel();
  object.dateTime = reader.readDateTime(offsets[0]);
  object.id = id;
  object.note = reader.readStringOrNull(offsets[1]);
  object.weightKg = reader.readDouble(offsets[2]);
  return object;
}

P _weightEntryModelDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDateTime(offset)) as P;
    case 1:
      return (reader.readStringOrNull(offset)) as P;
    case 2:
      return (reader.readDouble(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _weightEntryModelGetId(WeightEntryModel object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _weightEntryModelGetLinks(WeightEntryModel object) {
  return [];
}

void _weightEntryModelAttach(
  IsarCollection<dynamic> col,
  Id id,
  WeightEntryModel object,
) {
  object.id = id;
}

extension WeightEntryModelQueryWhereSort
    on QueryBuilder<WeightEntryModel, WeightEntryModel, QWhere> {
  QueryBuilder<WeightEntryModel, WeightEntryModel, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<WeightEntryModel, WeightEntryModel, QAfterWhere> anyDateTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'dateTime'),
      );
    });
  }
}

extension WeightEntryModelQueryWhere
    on QueryBuilder<WeightEntryModel, WeightEntryModel, QWhereClause> {
  QueryBuilder<WeightEntryModel, WeightEntryModel, QAfterWhereClause> idEqualTo(
    Id id,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<WeightEntryModel, WeightEntryModel, QAfterWhereClause>
  idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<WeightEntryModel, WeightEntryModel, QAfterWhereClause>
  idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<WeightEntryModel, WeightEntryModel, QAfterWhereClause>
  idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<WeightEntryModel, WeightEntryModel, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.between(
          lower: lowerId,
          includeLower: includeLower,
          upper: upperId,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<WeightEntryModel, WeightEntryModel, QAfterWhereClause>
  dateTimeEqualTo(DateTime dateTime) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'dateTime', value: [dateTime]),
      );
    });
  }

  QueryBuilder<WeightEntryModel, WeightEntryModel, QAfterWhereClause>
  dateTimeNotEqualTo(DateTime dateTime) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'dateTime',
                lower: [],
                upper: [dateTime],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'dateTime',
                lower: [dateTime],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'dateTime',
                lower: [dateTime],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'dateTime',
                lower: [],
                upper: [dateTime],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<WeightEntryModel, WeightEntryModel, QAfterWhereClause>
  dateTimeGreaterThan(DateTime dateTime, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'dateTime',
          lower: [dateTime],
          includeLower: include,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<WeightEntryModel, WeightEntryModel, QAfterWhereClause>
  dateTimeLessThan(DateTime dateTime, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'dateTime',
          lower: [],
          upper: [dateTime],
          includeUpper: include,
        ),
      );
    });
  }

  QueryBuilder<WeightEntryModel, WeightEntryModel, QAfterWhereClause>
  dateTimeBetween(
    DateTime lowerDateTime,
    DateTime upperDateTime, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'dateTime',
          lower: [lowerDateTime],
          includeLower: includeLower,
          upper: [upperDateTime],
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension WeightEntryModelQueryFilter
    on QueryBuilder<WeightEntryModel, WeightEntryModel, QFilterCondition> {
  QueryBuilder<WeightEntryModel, WeightEntryModel, QAfterFilterCondition>
  dateTimeEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'dateTime', value: value),
      );
    });
  }

  QueryBuilder<WeightEntryModel, WeightEntryModel, QAfterFilterCondition>
  dateTimeGreaterThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'dateTime',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<WeightEntryModel, WeightEntryModel, QAfterFilterCondition>
  dateTimeLessThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'dateTime',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<WeightEntryModel, WeightEntryModel, QAfterFilterCondition>
  dateTimeBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'dateTime',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<WeightEntryModel, WeightEntryModel, QAfterFilterCondition>
  idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<WeightEntryModel, WeightEntryModel, QAfterFilterCondition>
  idGreaterThan(Id value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<WeightEntryModel, WeightEntryModel, QAfterFilterCondition>
  idLessThan(Id value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<WeightEntryModel, WeightEntryModel, QAfterFilterCondition>
  idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'id',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<WeightEntryModel, WeightEntryModel, QAfterFilterCondition>
  noteIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'note'),
      );
    });
  }

  QueryBuilder<WeightEntryModel, WeightEntryModel, QAfterFilterCondition>
  noteIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'note'),
      );
    });
  }

  QueryBuilder<WeightEntryModel, WeightEntryModel, QAfterFilterCondition>
  noteEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'note',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<WeightEntryModel, WeightEntryModel, QAfterFilterCondition>
  noteGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'note',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<WeightEntryModel, WeightEntryModel, QAfterFilterCondition>
  noteLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'note',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<WeightEntryModel, WeightEntryModel, QAfterFilterCondition>
  noteBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'note',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<WeightEntryModel, WeightEntryModel, QAfterFilterCondition>
  noteStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'note',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<WeightEntryModel, WeightEntryModel, QAfterFilterCondition>
  noteEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'note',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<WeightEntryModel, WeightEntryModel, QAfterFilterCondition>
  noteContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'note',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<WeightEntryModel, WeightEntryModel, QAfterFilterCondition>
  noteMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'note',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<WeightEntryModel, WeightEntryModel, QAfterFilterCondition>
  noteIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'note', value: ''),
      );
    });
  }

  QueryBuilder<WeightEntryModel, WeightEntryModel, QAfterFilterCondition>
  noteIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'note', value: ''),
      );
    });
  }

  QueryBuilder<WeightEntryModel, WeightEntryModel, QAfterFilterCondition>
  weightKgEqualTo(double value, {double epsilon = Query.epsilon}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'weightKg',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<WeightEntryModel, WeightEntryModel, QAfterFilterCondition>
  weightKgGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'weightKg',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<WeightEntryModel, WeightEntryModel, QAfterFilterCondition>
  weightKgLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'weightKg',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<WeightEntryModel, WeightEntryModel, QAfterFilterCondition>
  weightKgBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'weightKg',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,

          epsilon: epsilon,
        ),
      );
    });
  }
}

extension WeightEntryModelQueryObject
    on QueryBuilder<WeightEntryModel, WeightEntryModel, QFilterCondition> {}

extension WeightEntryModelQueryLinks
    on QueryBuilder<WeightEntryModel, WeightEntryModel, QFilterCondition> {}

extension WeightEntryModelQuerySortBy
    on QueryBuilder<WeightEntryModel, WeightEntryModel, QSortBy> {
  QueryBuilder<WeightEntryModel, WeightEntryModel, QAfterSortBy>
  sortByDateTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dateTime', Sort.asc);
    });
  }

  QueryBuilder<WeightEntryModel, WeightEntryModel, QAfterSortBy>
  sortByDateTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dateTime', Sort.desc);
    });
  }

  QueryBuilder<WeightEntryModel, WeightEntryModel, QAfterSortBy> sortByNote() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'note', Sort.asc);
    });
  }

  QueryBuilder<WeightEntryModel, WeightEntryModel, QAfterSortBy>
  sortByNoteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'note', Sort.desc);
    });
  }

  QueryBuilder<WeightEntryModel, WeightEntryModel, QAfterSortBy>
  sortByWeightKg() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'weightKg', Sort.asc);
    });
  }

  QueryBuilder<WeightEntryModel, WeightEntryModel, QAfterSortBy>
  sortByWeightKgDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'weightKg', Sort.desc);
    });
  }
}

extension WeightEntryModelQuerySortThenBy
    on QueryBuilder<WeightEntryModel, WeightEntryModel, QSortThenBy> {
  QueryBuilder<WeightEntryModel, WeightEntryModel, QAfterSortBy>
  thenByDateTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dateTime', Sort.asc);
    });
  }

  QueryBuilder<WeightEntryModel, WeightEntryModel, QAfterSortBy>
  thenByDateTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dateTime', Sort.desc);
    });
  }

  QueryBuilder<WeightEntryModel, WeightEntryModel, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<WeightEntryModel, WeightEntryModel, QAfterSortBy>
  thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<WeightEntryModel, WeightEntryModel, QAfterSortBy> thenByNote() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'note', Sort.asc);
    });
  }

  QueryBuilder<WeightEntryModel, WeightEntryModel, QAfterSortBy>
  thenByNoteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'note', Sort.desc);
    });
  }

  QueryBuilder<WeightEntryModel, WeightEntryModel, QAfterSortBy>
  thenByWeightKg() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'weightKg', Sort.asc);
    });
  }

  QueryBuilder<WeightEntryModel, WeightEntryModel, QAfterSortBy>
  thenByWeightKgDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'weightKg', Sort.desc);
    });
  }
}

extension WeightEntryModelQueryWhereDistinct
    on QueryBuilder<WeightEntryModel, WeightEntryModel, QDistinct> {
  QueryBuilder<WeightEntryModel, WeightEntryModel, QDistinct>
  distinctByDateTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'dateTime');
    });
  }

  QueryBuilder<WeightEntryModel, WeightEntryModel, QDistinct> distinctByNote({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'note', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<WeightEntryModel, WeightEntryModel, QDistinct>
  distinctByWeightKg() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'weightKg');
    });
  }
}

extension WeightEntryModelQueryProperty
    on QueryBuilder<WeightEntryModel, WeightEntryModel, QQueryProperty> {
  QueryBuilder<WeightEntryModel, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<WeightEntryModel, DateTime, QQueryOperations>
  dateTimeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'dateTime');
    });
  }

  QueryBuilder<WeightEntryModel, String?, QQueryOperations> noteProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'note');
    });
  }

  QueryBuilder<WeightEntryModel, double, QQueryOperations> weightKgProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'weightKg');
    });
  }
}
