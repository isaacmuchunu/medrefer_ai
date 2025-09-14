import 'package:medrefer_ai/core/app_export.dart';

/// Search result model
class SearchResult extends BaseModel {
  final String id;
  final String entityType; // patient, referral, user, document, etc.
  final String entityId;
  final String title;
  final String description;
  final double score;
  final Map<String, dynamic> data;
  final List<String> highlights;
  final Map<String, dynamic> metadata;
  final DateTime indexedAt;

  SearchResult({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.title,
    required this.description,
    required this.score,
    this.data = const {},
    this.highlights = const [],
    this.metadata = const {},
    required this.indexedAt,
  });

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'entity_type': entityType,
      'entity_id': entityId,
      'title': title,
      'description': description,
      'score': score,
      'data': jsonEncode(data),
      'highlights': jsonEncode(highlights),
      'metadata': jsonEncode(metadata),
      'indexed_at': indexedAt.toIso8601String(),
    };
  }

  factory SearchResult.fromMap(Map<String, dynamic> map) {
    return SearchResult(
      id: map['id'] ?? '',
      entityType: map['entity_type'] ?? '',
      entityId: map['entity_id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      score: (map['score'] ?? 0.0).toDouble(),
      data: map['data'] != null 
          ? Map<String, dynamic>.from(jsonDecode(map['data'])) 
          : {},
      highlights: map['highlights'] != null 
          ? List<String>.from(jsonDecode(map['highlights'])) 
          : [],
      metadata: map['metadata'] != null 
          ? Map<String, dynamic>.from(jsonDecode(map['metadata'])) 
          : {},
      indexedAt: DateTime.parse(map['indexed_at'] ?? DateTime.now().toIso8601String()),
    );
  }
}

/// Search query model
class SearchQuery extends BaseModel {
  final String id;
  final String query;
  final String? userId;
  final String? organizationId;
  final List<String> entityTypes;
  final Map<String, dynamic> filters;
  final Map<String, dynamic> facets;
  final String sortBy;
  final String sortOrder;
  final int page;
  final int pageSize;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;

  SearchQuery({
    required this.id,
    required this.query,
    this.userId,
    this.organizationId,
    this.entityTypes = const [],
    this.filters = const {},
    this.facets = const {},
    this.sortBy = 'score',
    this.sortOrder = 'desc',
    this.page = 1,
    this.pageSize = 20,
    this.metadata = const {},
    required this.createdAt,
  });

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'query': query,
      'user_id': userId,
      'organization_id': organizationId,
      'entity_types': jsonEncode(entityTypes),
      'filters': jsonEncode(filters),
      'facets': jsonEncode(facets),
      'sort_by': sortBy,
      'sort_order': sortOrder,
      'page': page,
      'page_size': pageSize,
      'metadata': jsonEncode(metadata),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory SearchQuery.fromMap(Map<String, dynamic> map) {
    return SearchQuery(
      id: map['id'] ?? '',
      query: map['query'] ?? '',
      userId: map['user_id'],
      organizationId: map['organization_id'],
      entityTypes: map['entity_types'] != null 
          ? List<String>.from(jsonDecode(map['entity_types'])) 
          : [],
      filters: map['filters'] != null 
          ? Map<String, dynamic>.from(jsonDecode(map['filters'])) 
          : {},
      facets: map['facets'] != null 
          ? Map<String, dynamic>.from(jsonDecode(map['facets'])) 
          : {},
      sortBy: map['sort_by'] ?? 'score',
      sortOrder: map['sort_order'] ?? 'desc',
      page: map['page'] ?? 1,
      pageSize: map['page_size'] ?? 20,
      metadata: map['metadata'] != null 
          ? Map<String, dynamic>.from(jsonDecode(map['metadata'])) 
          : {},
      createdAt: DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }
}

/// Saved search model
class SavedSearch extends BaseModel {
  final String id;
  final String name;
  final String description;
  final String query;
  final String? userId;
  final String? organizationId;
  final List<String> entityTypes;
  final Map<String, dynamic> filters;
  final Map<String, dynamic> facets;
  final String sortBy;
  final String sortOrder;
  final bool isPublic;
  final List<String> tags;
  final int useCount;
  final DateTime lastUsed;
  final DateTime createdAt;
  final DateTime updatedAt;

  SavedSearch({
    required this.id,
    required this.name,
    required this.description,
    required this.query,
    this.userId,
    this.organizationId,
    this.entityTypes = const [],
    this.filters = const {},
    this.facets = const {},
    this.sortBy = 'score',
    this.sortOrder = 'desc',
    this.isPublic = false,
    this.tags = const [],
    this.useCount = 0,
    required this.lastUsed,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'query': query,
      'user_id': userId,
      'organization_id': organizationId,
      'entity_types': jsonEncode(entityTypes),
      'filters': jsonEncode(filters),
      'facets': jsonEncode(facets),
      'sort_by': sortBy,
      'sort_order': sortOrder,
      'is_public': isPublic ? 1 : 0,
      'tags': jsonEncode(tags),
      'use_count': useCount,
      'last_used': lastUsed.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory SavedSearch.fromMap(Map<String, dynamic> map) {
    return SavedSearch(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      query: map['query'] ?? '',
      userId: map['user_id'],
      organizationId: map['organization_id'],
      entityTypes: map['entity_types'] != null 
          ? List<String>.from(jsonDecode(map['entity_types'])) 
          : [],
      filters: map['filters'] != null 
          ? Map<String, dynamic>.from(jsonDecode(map['filters'])) 
          : {},
      facets: map['facets'] != null 
          ? Map<String, dynamic>.from(jsonDecode(map['facets'])) 
          : {},
      sortBy: map['sort_by'] ?? 'score',
      sortOrder: map['sort_order'] ?? 'desc',
      isPublic: (map['is_public'] ?? 0) == 1,
      tags: map['tags'] != null 
          ? List<String>.from(jsonDecode(map['tags'])) 
          : [],
      useCount: map['use_count'] ?? 0,
      lastUsed: DateTime.parse(map['last_used'] ?? DateTime.now().toIso8601String()),
      createdAt: DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(map['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }
}

/// Search facet model
class SearchFacet extends BaseModel {
  final String field;
  final String displayName;
  final List<FacetValue> values;
  final int totalCount;
  final Map<String, dynamic> metadata;

  SearchFacet({
    required this.field,
    required this.displayName,
    required this.values,
    required this.totalCount,
    this.metadata = const {},
  });

  @override
  Map<String, dynamic> toMap() {
    return {
      'field': field,
      'display_name': displayName,
      'values': jsonEncode(values.map((v) => v.toMap()).toList()),
      'total_count': totalCount,
      'metadata': jsonEncode(metadata),
    };
  }

  factory SearchFacet.fromMap(Map<String, dynamic> map) {
    return SearchFacet(
      field: map['field'] ?? '',
      displayName: map['display_name'] ?? '',
      values: map['values'] != null 
          ? (jsonDecode(map['values']) as List)
              .map((v) => FacetValue.fromMap(v))
              .toList()
          : [],
      totalCount: map['total_count'] ?? 0,
      metadata: map['metadata'] != null 
          ? Map<String, dynamic>.from(jsonDecode(map['metadata'])) 
          : {},
    );
  }
}

/// Facet value model
class FacetValue extends BaseModel {
  final String value;
  final String displayValue;
  final int count;
  final bool isSelected;
  final Map<String, dynamic> metadata;

  FacetValue({
    required this.value,
    required this.displayValue,
    required this.count,
    this.isSelected = false,
    this.metadata = const {},
  });

  @override
  Map<String, dynamic> toMap() {
    return {
      'value': value,
      'display_value': displayValue,
      'count': count,
      'is_selected': isSelected ? 1 : 0,
      'metadata': jsonEncode(metadata),
    };
  }

  factory FacetValue.fromMap(Map<String, dynamic> map) {
    return FacetValue(
      value: map['value'] ?? '',
      displayValue: map['display_value'] ?? '',
      count: map['count'] ?? 0,
      isSelected: (map['is_selected'] ?? 0) == 1,
      metadata: map['metadata'] != null 
          ? Map<String, dynamic>.from(jsonDecode(map['metadata'])) 
          : {},
    );
  }

  FacetValue copyWith({
    String? value,
    String? displayValue,
    int? count,
    bool? isSelected,
    Map<String, dynamic>? metadata,
  }) {
    return FacetValue(
      value: value ?? this.value,
      displayValue: displayValue ?? this.displayValue,
      count: count ?? this.count,
      isSelected: isSelected ?? this.isSelected,
      metadata: metadata ?? this.metadata,
    );
  }
}

/// Search analytics model
class SearchAnalytics extends BaseModel {
  final String id;
  final String query;
  final String? userId;
  final String? organizationId;
  final List<String> entityTypes;
  final int resultCount;
  final int page;
  final String sortBy;
  final String sortOrder;
  final Map<String, dynamic> filters;
  final List<String> clickedResults;
  final DateTime searchedAt;
  final int responseTime; // milliseconds
  final Map<String, dynamic> metadata;

  SearchAnalytics({
    required this.id,
    required this.query,
    this.userId,
    this.organizationId,
    this.entityTypes = const [],
    required this.resultCount,
    required this.page,
    required this.sortBy,
    required this.sortOrder,
    this.filters = const {},
    this.clickedResults = const [],
    required this.searchedAt,
    required this.responseTime,
    this.metadata = const {},
  });

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'query': query,
      'user_id': userId,
      'organization_id': organizationId,
      'entity_types': jsonEncode(entityTypes),
      'result_count': resultCount,
      'page': page,
      'sort_by': sortBy,
      'sort_order': sortOrder,
      'filters': jsonEncode(filters),
      'clicked_results': jsonEncode(clickedResults),
      'searched_at': searchedAt.toIso8601String(),
      'response_time': responseTime,
      'metadata': jsonEncode(metadata),
    };
  }

  factory SearchAnalytics.fromMap(Map<String, dynamic> map) {
    return SearchAnalytics(
      id: map['id'] ?? '',
      query: map['query'] ?? '',
      userId: map['user_id'],
      organizationId: map['organization_id'],
      entityTypes: map['entity_types'] != null 
          ? List<String>.from(jsonDecode(map['entity_types'])) 
          : [],
      resultCount: map['result_count'] ?? 0,
      page: map['page'] ?? 1,
      sortBy: map['sort_by'] ?? 'score',
      sortOrder: map['sort_order'] ?? 'desc',
      filters: map['filters'] != null 
          ? Map<String, dynamic>.from(jsonDecode(map['filters'])) 
          : {},
      clickedResults: map['clicked_results'] != null 
          ? List<String>.from(jsonDecode(map['clicked_results'])) 
          : [],
      searchedAt: DateTime.parse(map['searched_at'] ?? DateTime.now().toIso8601String()),
      responseTime: map['response_time'] ?? 0,
      metadata: map['metadata'] != null 
          ? Map<String, dynamic>.from(jsonDecode(map['metadata'])) 
          : {},
    );
  }
}

/// Search suggestion model
class SearchSuggestion extends BaseModel {
  final String id;
  final String text;
  final String type; // query, entity, filter, etc.
  final String? entityType;
  final String? entityId;
  final int frequency;
  final double score;
  final String? userId;
  final String? organizationId;
  final DateTime lastUsed;
  final DateTime createdAt;

  SearchSuggestion({
    required this.id,
    required this.text,
    required this.type,
    this.entityType,
    this.entityId,
    required this.frequency,
    required this.score,
    this.userId,
    this.organizationId,
    required this.lastUsed,
    required this.createdAt,
  });

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
      'type': type,
      'entity_type': entityType,
      'entity_id': entityId,
      'frequency': frequency,
      'score': score,
      'user_id': userId,
      'organization_id': organizationId,
      'last_used': lastUsed.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory SearchSuggestion.fromMap(Map<String, dynamic> map) {
    return SearchSuggestion(
      id: map['id'] ?? '',
      text: map['text'] ?? '',
      type: map['type'] ?? 'query',
      entityType: map['entity_type'],
      entityId: map['entity_id'],
      frequency: map['frequency'] ?? 1,
      score: (map['score'] ?? 0.0).toDouble(),
      userId: map['user_id'],
      organizationId: map['organization_id'],
      lastUsed: DateTime.parse(map['last_used'] ?? DateTime.now().toIso8601String()),
      createdAt: DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }
}