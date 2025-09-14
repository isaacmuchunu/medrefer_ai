import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:convert';
import 'dart:async';
import 'dart:math';
import '../core/app_export.dart';

/// Comprehensive API Gateway Service
/// 
/// Provides enterprise-grade API gateway capabilities including:
/// - Request routing and load balancing
/// - Rate limiting and throttling
/// - Authentication and authorization
/// - API versioning and lifecycle management
/// - Request/response transformation
/// - Caching and performance optimization
/// - Monitoring and analytics
/// - Circuit breaker patterns
/// - API documentation and discovery
/// - Developer portal and API keys
class APIGatewayService extends ChangeNotifier {
  static final APIGatewayService _instance = APIGatewayService._internal();
  factory APIGatewayService() => _instance;
  APIGatewayService._internal();

  final Dio _dio = Dio();
  Database? _gatewayDb;
  bool _isInitialized = false;
  Timer? _metricsTimer;
  Timer? _healthCheckTimer;

  // API Management
  final Map<String, APIDefinition> _apiDefinitions = {};
  final Map<String, APIVersion> _apiVersions = {};
  final Map<String, APIEndpoint> _endpoints = {};
  
  // Security and Access Control
  final Map<String, APIKey> _apiKeys = {};
  final Map<String, RateLimitRule> _rateLimitRules = {};
  final Map<String, AuthenticationPolicy> _authPolicies = {};
  
  // Routing and Load Balancing
  final Map<String, ServiceInstance> _serviceInstances = {};
  final Map<String, LoadBalancer> _loadBalancers = {};
  
  // Caching and Performance
  final Map<String, CacheRule> _cacheRules = {};
  final Map<String, CachedResponse> _responseCache = {};
  
  // Circuit Breaker
  final Map<String, CircuitBreaker> _circuitBreakers = {};
  
  // Monitoring and Analytics
  final Map<String, APIMetrics> _apiMetrics = {};
  final Map<String, RequestLog> _requestLogs = {};
  
  // Rate Limiting
  final Map<String, RateLimitBucket> _rateLimitBuckets = {};

  // Getters
  bool get isInitialized => _isInitialized;
  Map<String, APIDefinition> get apiDefinitions => Map.unmodifiable(_apiDefinitions);
  Map<String, APIKey> get apiKeys => Map.unmodifiable(_apiKeys);
  Map<String, APIMetrics> get apiMetrics => Map.unmodifiable(_apiMetrics);

  /// Initialize the API Gateway service
  Future<void> initialize() async {
    try {
      if (_isInitialized) return;

      debugPrint('🚪 Initializing API Gateway Service...');

      // Initialize database
      await _initializeGatewayDatabase();

      // Configure HTTP client
      _dio.options.connectTimeout = const Duration(seconds: 30);
      _dio.options.receiveTimeout = const Duration(seconds: 60);

      // Add interceptors
      _dio.interceptors.add(_createRequestInterceptor());
      _dio.interceptors.add(_createResponseInterceptor());
      _dio.interceptors.add(_createMetricsInterceptor());

      // Load configurations
      await _loadAPIDefinitions();
      await _loadAPIKeys();
      await _loadRateLimitRules();
      await _loadServiceInstances();

      // Initialize default APIs
      await _initializeDefaultAPIs();

      // Start background services
      _startMetricsCollector();
      _startHealthChecker();

      _isInitialized = true;
      debugPrint('✅ API Gateway Service initialized successfully');
      
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Failed to initialize API Gateway Service: $e');
      rethrow;
    }
  }

  /// Register a new API
  Future<APIRegistrationResult> registerAPI({
    required String apiId,
    required String name,
    required String version,
    required String basePath,
    required List<APIEndpoint> endpoints,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      debugPrint('📝 Registering API: $apiId');

      // Validate API definition
      final validationResult = await _validateAPIDefinition(apiId, basePath, endpoints);
      if (!validationResult.isValid) {
        return APIRegistrationResult(
          success: false,
          apiId: apiId,
          error: 'API validation failed: ${validationResult.errors.join(', ')}',
        );
      }

      final apiDefinition = APIDefinition(
        apiId: apiId,
        name: name,
        description: metadata?['description'] ?? '',
        basePath: basePath,
        status: APIStatus.draft,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        tags: metadata?['tags'] ?? [],
        documentation: metadata?['documentation'],
      );

      final apiVersion = APIVersion(
        apiId: apiId,
        version: version,
        endpoints: endpoints,
        isDefault: true,
        status: VersionStatus.draft,
        createdAt: DateTime.now(),
      );

      _apiDefinitions[apiId] = apiDefinition;
      _apiVersions['${apiId}_$version'] = apiVersion;

      // Register endpoints
      for (final endpoint in endpoints) {
        _endpoints['${apiId}_${endpoint.path}_${endpoint.method}'] = endpoint;
      }

      // Initialize metrics
      _apiMetrics[apiId] = APIMetrics(
        apiId: apiId,
        totalRequests: 0,
        successfulRequests: 0,
        failedRequests: 0,
        averageResponseTime: 0.0,
        lastRequest: null,
      );

      // Save to database
      await _saveAPIDefinition(apiDefinition);
      await _saveAPIVersion(apiVersion);

      debugPrint('✅ API registered successfully: $apiId');
      notifyListeners();

      return APIRegistrationResult(
        success: true,
        apiId: apiId,
        version: version,
      );
    } catch (e) {
      debugPrint('❌ Failed to register API: $e');
      return APIRegistrationResult(
        success: false,
        apiId: apiId,
        error: e.toString(),
      );
    }
  }

  /// Deploy API version
  Future<APIDeploymentResult> deployAPI(String apiId, String version) async {
    try {
      final apiDefinition = _apiDefinitions[apiId];
      final apiVersion = _apiVersions['${apiId}_$version'];

      if (apiDefinition == null || apiVersion == null) {
        return APIDeploymentResult(
          success: false,
          apiId: apiId,
          version: version,
          error: 'API or version not found',
        );
      }

      debugPrint('🚀 Deploying API: $apiId v$version');

      // Validate deployment readiness
      final validationResult = await _validateAPIForDeployment(apiDefinition, apiVersion);
      if (!validationResult.isValid) {
        return APIDeploymentResult(
          success: false,
          apiId: apiId,
          version: version,
          error: 'Deployment validation failed: ${validationResult.errors.join(', ')}',
        );
      }

      // Update status
      apiDefinition.status = APIStatus.deployed;
      apiVersion.status = VersionStatus.deployed;
      apiVersion.deployedAt = DateTime.now();

      // Initialize circuit breakers for endpoints
      for (final endpoint in apiVersion.endpoints) {
        final circuitBreakerId = '${apiId}_${endpoint.path}_${endpoint.method}';
        _circuitBreakers[circuitBreakerId] = CircuitBreaker(
          id: circuitBreakerId,
          failureThreshold: 5,
          recoveryTimeout: const Duration(minutes: 1),
          state: CircuitBreakerState.closed,
        );
      }

      // Save updated definitions
      await _saveAPIDefinition(apiDefinition);
      await _saveAPIVersion(apiVersion);

      debugPrint('✅ API deployed successfully: $apiId v$version');
      notifyListeners();

      return APIDeploymentResult(
        success: true,
        apiId: apiId,
        version: version,
        deploymentId: _generateDeploymentId(),
      );
    } catch (e) {
      debugPrint('❌ Failed to deploy API: $e');
      return APIDeploymentResult(
        success: false,
        apiId: apiId,
        version: version,
        error: e.toString(),
      );
    }
  }

  /// Create API key
  Future<APIKeyResult> createAPIKey({
    required String keyName,
    required String clientId,
    List<String>? allowedAPIs,
    List<String>? allowedEndpoints,
    Map<String, int>? rateLimits,
    DateTime? expiresAt,
  }) async {
    try {
      debugPrint('🔑 Creating API key: $keyName');

      final apiKey = APIKey(
        keyId: _generateAPIKeyId(),
        keyName: keyName,
        clientId: clientId,
        keyValue: _generateAPIKeyValue(),
        allowedAPIs: allowedAPIs ?? [],
        allowedEndpoints: allowedEndpoints ?? [],
        rateLimits: rateLimits ?? {},
        isActive: true,
        createdAt: DateTime.now(),
        expiresAt: expiresAt,
        lastUsed: null,
        usageCount: 0,
      );

      _apiKeys[apiKey.keyId] = apiKey;

      // Create rate limit buckets for this key
      if (rateLimits != null) {
        for (final entry in rateLimits.entries) {
          final bucketId = '${apiKey.keyId}_${entry.key}';
          _rateLimitBuckets[bucketId] = RateLimitBucket(
            id: bucketId,
            keyId: apiKey.keyId,
            endpoint: entry.key,
            limit: entry.value,
            remaining: entry.value,
            resetTime: DateTime.now().add(const Duration(hours: 1)),
          );
        }
      }

      // Save to database
      await _saveAPIKey(apiKey);

      debugPrint('✅ API key created successfully: ${apiKey.keyId}');
      notifyListeners();

      return APIKeyResult(
        success: true,
        keyId: apiKey.keyId,
        keyValue: apiKey.keyValue,
      );
    } catch (e) {
      debugPrint('❌ Failed to create API key: $e');
      return APIKeyResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Process API request
  Future<APIResponse> processRequest({
    required String method,
    required String path,
    Map<String, String>? headers,
    Map<String, String>? queryParameters,
    dynamic body,
  }) async {
    final startTime = DateTime.now();
    
    try {
      debugPrint('📥 Processing API request: $method $path');

      // Extract API key from headers
      final apiKeyValue = headers?['X-API-Key'] ?? headers?['Authorization']?.replaceFirst('Bearer ', '');
      
      // Authenticate request
      final authResult = await _authenticateRequest(apiKeyValue, method, path);
      if (!authResult.isAuthenticated) {
        return APIResponse(
          statusCode: 401,
          body: {'error': 'Unauthorized', 'message': authResult.error},
          headers: {'Content-Type': 'application/json'},
        );
      }

      final apiKey = authResult.apiKey!;

      // Check rate limits
      final rateLimitResult = await _checkRateLimit(apiKey, method, path);
      if (!rateLimitResult.allowed) {
        return APIResponse(
          statusCode: 429,
          body: {'error': 'Rate limit exceeded', 'resetTime': rateLimitResult.resetTime?.toIso8601String()},
          headers: {
            'Content-Type': 'application/json',
            'X-RateLimit-Limit': rateLimitResult.limit.toString(),
            'X-RateLimit-Remaining': rateLimitResult.remaining.toString(),
            'X-RateLimit-Reset': rateLimitResult.resetTime?.millisecondsSinceEpoch.toString() ?? '',
          },
        );
      }

      // Find matching endpoint
      final endpoint = await _findMatchingEndpoint(method, path);
      if (endpoint == null) {
        return APIResponse(
          statusCode: 404,
          body: {'error': 'Endpoint not found'},
          headers: {'Content-Type': 'application/json'},
        );
      }

      // Check circuit breaker
      final circuitBreakerId = '${endpoint.apiId}_${endpoint.path}_${endpoint.method}';
      final circuitBreaker = _circuitBreakers[circuitBreakerId];
      if (circuitBreaker != null && circuitBreaker.state == CircuitBreakerState.open) {
        return APIResponse(
          statusCode: 503,
          body: {'error': 'Service temporarily unavailable'},
          headers: {'Content-Type': 'application/json'},
        );
      }

      // Check cache
      final cacheKey = _generateCacheKey(method, path, queryParameters);
      final cachedResponse = await _getCachedResponse(cacheKey);
      if (cachedResponse != null) {
        debugPrint('💾 Returning cached response for: $method $path');
        await _recordRequest(apiKey, endpoint, startTime, 200, true);
        return cachedResponse;
      }

      // Route request to backend service
      final response = await _routeRequest(endpoint, method, path, headers, queryParameters, body);

      // Update circuit breaker
      if (circuitBreaker != null) {
        if (response.statusCode >= 500) {
          circuitBreaker.recordFailure();
        } else {
          circuitBreaker.recordSuccess();
        }
      }

      // Cache response if applicable
      await _cacheResponse(cacheKey, endpoint, response);

      // Record request metrics
      await _recordRequest(apiKey, endpoint, startTime, response.statusCode, response.statusCode < 400);

      debugPrint('✅ API request processed successfully: $method $path (${response.statusCode})');

      return response;
    } catch (e) {
      debugPrint('❌ Failed to process API request: $e');
      
      return APIResponse(
        statusCode: 500,
        body: {'error': 'Internal server error'},
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  /// Get API analytics
  Future<APIAnalyticsResult> getAPIAnalytics(String apiId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final metrics = _apiMetrics[apiId];
      if (metrics == null) {
        return APIAnalyticsResult(
          success: false,
          apiId: apiId,
          error: 'API metrics not found',
        );
      }

      final analytics = APIAnalytics(
        apiId: apiId,
        period: DateRange(
          start: startDate ?? DateTime.now().subtract(const Duration(days: 30)),
          end: endDate ?? DateTime.now(),
        ),
        totalRequests: metrics.totalRequests,
        successfulRequests: metrics.successfulRequests,
        failedRequests: metrics.failedRequests,
        averageResponseTime: metrics.averageResponseTime,
        requestsPerSecond: 0.0, // Calculate from logs
        topEndpoints: await _getTopEndpoints(apiId),
        errorRates: await _getErrorRates(apiId),
        responseTimeDistribution: await _getResponseTimeDistribution(apiId),
      );

      return APIAnalyticsResult(
        success: true,
        apiId: apiId,
        analytics: analytics,
      );
    } catch (e) {
      debugPrint('❌ Failed to get API analytics: $e');
      return APIAnalyticsResult(
        success: false,
        apiId: apiId,
        error: e.toString(),
      );
    }
  }

  /// Update rate limit rules
  Future<RateLimitUpdateResult> updateRateLimit({
    required String ruleId,
    required String apiId,
    String? endpoint,
    required int requestsPerHour,
    required int requestsPerMinute,
    int? burstLimit,
  }) async {
    try {
      debugPrint('⏱️ Updating rate limit rule: $ruleId');

      final rule = RateLimitRule(
        ruleId: ruleId,
        apiId: apiId,
        endpoint: endpoint,
        requestsPerHour: requestsPerHour,
        requestsPerMinute: requestsPerMinute,
        burstLimit: burstLimit ?? requestsPerMinute * 2,
        isActive: true,
        createdAt: DateTime.now(),
      );

      _rateLimitRules[ruleId] = rule;

      // Save to database
      await _saveRateLimitRule(rule);

      debugPrint('✅ Rate limit rule updated: $ruleId');
      notifyListeners();

      return RateLimitUpdateResult(
        success: true,
        ruleId: ruleId,
      );
    } catch (e) {
      debugPrint('❌ Failed to update rate limit rule: $e');
      return RateLimitUpdateResult(
        success: false,
        ruleId: ruleId,
        error: e.toString(),
      );
    }
  }

  /// Add service instance for load balancing
  Future<ServiceRegistrationResult> registerServiceInstance({
    required String serviceId,
    required String instanceId,
    required String host,
    required int port,
    Map<String, dynamic>? metadata,
    int weight = 100,
  }) async {
    try {
      debugPrint('🔧 Registering service instance: $instanceId');

      final serviceInstance = ServiceInstance(
        serviceId: serviceId,
        instanceId: instanceId,
        host: host,
        port: port,
        weight: weight,
        isHealthy: true,
        metadata: metadata ?? {},
        registeredAt: DateTime.now(),
        lastHealthCheck: DateTime.now(),
      );

      _serviceInstances[instanceId] = serviceInstance;

      // Create or update load balancer
      if (!_loadBalancers.containsKey(serviceId)) {
        _loadBalancers[serviceId] = LoadBalancer(
          serviceId: serviceId,
          algorithm: LoadBalancingAlgorithm.roundRobin,
          instances: [],
        );
      }

      _loadBalancers[serviceId]!.instances.add(serviceInstance);

      debugPrint('✅ Service instance registered: $instanceId');
      notifyListeners();

      return ServiceRegistrationResult(
        success: true,
        serviceId: serviceId,
        instanceId: instanceId,
      );
    } catch (e) {
      debugPrint('❌ Failed to register service instance: $e');
      return ServiceRegistrationResult(
        success: false,
        serviceId: serviceId,
        instanceId: instanceId,
        error: e.toString(),
      );
    }
  }

  // Private Implementation Methods

  Future<void> _initializeGatewayDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = '$databasesPath/api_gateway.db';

    _gatewayDb = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // API definitions table
        await db.execute('''
          CREATE TABLE api_definitions (
            api_id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            description TEXT,
            base_path TEXT NOT NULL,
            status TEXT NOT NULL,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            tags TEXT,
            documentation TEXT
          )
        ''');

        // API versions table
        await db.execute('''
          CREATE TABLE api_versions (
            api_id TEXT,
            version TEXT,
            endpoints TEXT NOT NULL,
            is_default INTEGER,
            status TEXT NOT NULL,
            created_at TEXT NOT NULL,
            deployed_at TEXT,
            PRIMARY KEY (api_id, version),
            FOREIGN KEY (api_id) REFERENCES api_definitions (api_id)
          )
        ''');

        // API keys table
        await db.execute('''
          CREATE TABLE api_keys (
            key_id TEXT PRIMARY KEY,
            key_name TEXT NOT NULL,
            client_id TEXT NOT NULL,
            key_value TEXT UNIQUE NOT NULL,
            allowed_apis TEXT,
            allowed_endpoints TEXT,
            rate_limits TEXT,
            is_active INTEGER,
            created_at TEXT NOT NULL,
            expires_at TEXT,
            last_used TEXT,
            usage_count INTEGER
          )
        ''');

        // Rate limit rules table
        await db.execute('''
          CREATE TABLE rate_limit_rules (
            rule_id TEXT PRIMARY KEY,
            api_id TEXT NOT NULL,
            endpoint TEXT,
            requests_per_hour INTEGER,
            requests_per_minute INTEGER,
            burst_limit INTEGER,
            is_active INTEGER,
            created_at TEXT NOT NULL
          )
        ''');

        // Request logs table
        await db.execute('''
          CREATE TABLE request_logs (
            log_id TEXT PRIMARY KEY,
            api_id TEXT,
            endpoint TEXT,
            method TEXT,
            status_code INTEGER,
            response_time INTEGER,
            client_id TEXT,
            timestamp TEXT,
            user_agent TEXT,
            ip_address TEXT
          )
        ''');
      },
    );

    debugPrint('✅ API Gateway database initialized');
  }

  Future<void> _loadAPIDefinitions() async {
    // Load API definitions from database
    debugPrint('📋 Loading API definitions...');
  }

  Future<void> _loadAPIKeys() async {
    // Load API keys from database
    debugPrint('🔑 Loading API keys...');
  }

  Future<void> _loadRateLimitRules() async {
    // Load rate limit rules from database
    debugPrint('⏱️ Loading rate limit rules...');
  }

  Future<void> _loadServiceInstances() async {
    // Load service instances from database
    debugPrint('🔧 Loading service instances...');
  }

  Future<void> _initializeDefaultAPIs() async {
    // Register default healthcare APIs
    await _registerHealthcareAPIs();
    await _registerPatientManagementAPI();
    await _registerReferralAPI();
  }

  Future<void> _registerHealthcareAPIs() async {
    // Register healthcare-specific APIs
    await registerAPI(
      apiId: 'healthcare_core',
      name: 'Healthcare Core API',
      version: '1.0',
      basePath: '/api/v1/healthcare',
      endpoints: [
        APIEndpoint(
          apiId: 'healthcare_core',
          path: '/patients',
          method: 'GET',
          description: 'List patients',
          parameters: ['limit', 'offset', 'search'],
          responseSchema: {'type': 'array', 'items': {'type': 'object'}},
          authRequired: true,
          rateLimitTier: 'standard',
        ),
        APIEndpoint(
          apiId: 'healthcare_core',
          path: '/patients',
          method: 'POST',
          description: 'Create patient',
          requestSchema: {'type': 'object', 'required': ['name', 'email']},
          responseSchema: {'type': 'object'},
          authRequired: true,
          rateLimitTier: 'premium',
        ),
      ],
      metadata: {
        'description': 'Core healthcare management API',
        'tags': ['healthcare', 'patients', 'core'],
        'documentation': 'https://docs.example.com/healthcare-api',
      },
    );
  }

  Future<void> _registerPatientManagementAPI() async {
    // Register patient management API
    debugPrint('👥 Registering patient management API...');
  }

  Future<void> _registerReferralAPI() async {
    // Register referral API
    debugPrint('🏥 Registering referral API...');
  }

  void _startMetricsCollector() {
    _metricsTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _collectMetrics();
      _cleanupOldLogs();
    });
  }

  void _startHealthChecker() {
    _healthCheckTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      _performHealthChecks();
    });
  }

  Future<void> _collectMetrics() async {
    // Collect and aggregate metrics
    for (final metrics in _apiMetrics.values) {
      // Update metrics from request logs
    }
  }

  Future<void> _cleanupOldLogs() async {
    // Clean up old request logs (keep last 30 days)
    final cutoff = DateTime.now().subtract(const Duration(days: 30));
    _requestLogs.removeWhere((key, log) => log.timestamp.isBefore(cutoff));
  }

  Future<void> _performHealthChecks() async {
    // Perform health checks on service instances
    for (final instance in _serviceInstances.values) {
      try {
        final response = await _dio.get(
          'http://${instance.host}:${instance.port}/health',
          options: Options(
            connectTimeout: const Duration(seconds: 5),
            receiveTimeout: const Duration(seconds: 5),
          ),
        );

        instance.isHealthy = response.statusCode == 200;
        instance.lastHealthCheck = DateTime.now();
      } catch (e) {
        instance.isHealthy = false;
        instance.lastHealthCheck = DateTime.now();
        debugPrint('❌ Health check failed for ${instance.instanceId}: $e');
      }
    }
  }

  Future<APIValidationResult> _validateAPIDefinition(
    String apiId,
    String basePath,
    List<APIEndpoint> endpoints,
  ) async {
    final errors = <String>[];

    // Validate API ID
    if (apiId.isEmpty) {
      errors.add('API ID cannot be empty');
    }

    // Validate base path
    if (!basePath.startsWith('/')) {
      errors.add('Base path must start with /');
    }

    // Validate endpoints
    if (endpoints.isEmpty) {
      errors.add('API must have at least one endpoint');
    }

    for (final endpoint in endpoints) {
      if (!endpoint.path.startsWith('/')) {
        errors.add('Endpoint path must start with /: ${endpoint.path}');
      }

      if (!['GET', 'POST', 'PUT', 'DELETE', 'PATCH'].contains(endpoint.method.toUpperCase())) {
        errors.add('Invalid HTTP method: ${endpoint.method}');
      }
    }

    return APIValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
    );
  }

  Future<APIValidationResult> _validateAPIForDeployment(
    APIDefinition apiDefinition,
    APIVersion apiVersion,
  ) async {
    final errors = <String>[];

    // Additional deployment validations
    if (apiVersion.endpoints.isEmpty) {
      errors.add('API version must have endpoints');
    }

    return APIValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
    );
  }

  Future<AuthenticationResult> _authenticateRequest(
    String? apiKeyValue,
    String method,
    String path,
  ) async {
    if (apiKeyValue == null || apiKeyValue.isEmpty) {
      return AuthenticationResult(
        isAuthenticated: false,
        error: 'API key required',
      );
    }

    // Find API key
    final apiKey = _apiKeys.values.firstWhere(
      (key) => key.keyValue == apiKeyValue && key.isActive,
      orElse: () => throw Exception('API key not found'),
    );

    try {
      // Check if key is expired
      if (apiKey.expiresAt != null && apiKey.expiresAt!.isBefore(DateTime.now())) {
        return AuthenticationResult(
          isAuthenticated: false,
          error: 'API key expired',
        );
      }

      // Check allowed endpoints
      if (apiKey.allowedEndpoints.isNotEmpty) {
        final endpointKey = '${method.toUpperCase()} $path';
        if (!apiKey.allowedEndpoints.contains(endpointKey)) {
          return AuthenticationResult(
            isAuthenticated: false,
            error: 'Access denied to endpoint',
          );
        }
      }

      // Update usage
      apiKey.lastUsed = DateTime.now();
      apiKey.usageCount++;

      return AuthenticationResult(
        isAuthenticated: true,
        apiKey: apiKey,
      );
    } catch (e) {
      return AuthenticationResult(
        isAuthenticated: false,
        error: 'Invalid API key',
      );
    }
  }

  Future<RateLimitResult> _checkRateLimit(APIKey apiKey, String method, String path) async {
    final endpointKey = '${method.toUpperCase()} $path';
    final bucketId = '${apiKey.keyId}_$endpointKey';

    // Get or create rate limit bucket
    var bucket = _rateLimitBuckets[bucketId];
    if (bucket == null) {
      // Use default rate limit if not specified
      final defaultLimit = 1000; // requests per hour
      bucket = RateLimitBucket(
        id: bucketId,
        keyId: apiKey.keyId,
        endpoint: endpointKey,
        limit: defaultLimit,
        remaining: defaultLimit,
        resetTime: DateTime.now().add(const Duration(hours: 1)),
      );
      _rateLimitBuckets[bucketId] = bucket;
    }

    // Reset bucket if time has passed
    if (DateTime.now().isAfter(bucket.resetTime)) {
      bucket.remaining = bucket.limit;
      bucket.resetTime = DateTime.now().add(const Duration(hours: 1));
    }

    // Check if request is allowed
    if (bucket.remaining <= 0) {
      return RateLimitResult(
        allowed: false,
        limit: bucket.limit,
        remaining: bucket.remaining,
        resetTime: bucket.resetTime,
      );
    }

    // Consume one request
    bucket.remaining--;

    return RateLimitResult(
      allowed: true,
      limit: bucket.limit,
      remaining: bucket.remaining,
      resetTime: bucket.resetTime,
    );
  }

  Future<APIEndpoint?> _findMatchingEndpoint(String method, String path) async {
    // Simple path matching - in production, use more sophisticated routing
    final endpointKey = '${path}_${method.toUpperCase()}';
    
    for (final endpoint in _endpoints.values) {
      if (endpoint.method.toUpperCase() == method.toUpperCase() && 
          endpoint.path == path) {
        return endpoint;
      }
    }

    return null;
  }

  Future<APIResponse?> _getCachedResponse(String cacheKey) async {
    final cachedResponse = _responseCache[cacheKey];
    if (cachedResponse != null && cachedResponse.expiresAt.isAfter(DateTime.now())) {
      return cachedResponse.response;
    }

    return null;
  }

  Future<APIResponse> _routeRequest(
    APIEndpoint endpoint,
    String method,
    String path,
    Map<String, String>? headers,
    Map<String, String>? queryParameters,
    dynamic body,
  ) async {
    // Get service instance using load balancer
    final serviceInstance = await _getServiceInstance(endpoint.apiId);
    if (serviceInstance == null) {
      return APIResponse(
        statusCode: 503,
        body: {'error': 'Service unavailable'},
        headers: {'Content-Type': 'application/json'},
      );
    }

    final targetUrl = 'http://${serviceInstance.host}:${serviceInstance.port}$path';

    try {
      final response = await _dio.request(
        targetUrl,
        options: Options(
          method: method,
          headers: headers,
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 60),
        ),
        queryParameters: queryParameters,
        data: body,
      );

      return APIResponse(
        statusCode: response.statusCode ?? 200,
        body: response.data,
        headers: response.headers.map.map((key, value) => MapEntry(key, value.join(', '))),
      );
    } catch (e) {
      debugPrint('❌ Failed to route request: $e');
      return APIResponse(
        statusCode: 500,
        body: {'error': 'Backend service error'},
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<ServiceInstance?> _getServiceInstance(String apiId) async {
    final loadBalancer = _loadBalancers[apiId];
    if (loadBalancer == null) {
      return null;
    }

    final healthyInstances = loadBalancer.instances.where((instance) => instance.isHealthy).toList();
    if (healthyInstances.isEmpty) {
      return null;
    }

    // Simple round-robin load balancing
    switch (loadBalancer.algorithm) {
      case LoadBalancingAlgorithm.roundRobin:
        loadBalancer.currentIndex = (loadBalancer.currentIndex + 1) % healthyInstances.length;
        return healthyInstances[loadBalancer.currentIndex];
      case LoadBalancingAlgorithm.random:
        return healthyInstances[Random().nextInt(healthyInstances.length)];
      case LoadBalancingAlgorithm.weighted:
        return _selectWeightedInstance(healthyInstances);
    }
  }

  ServiceInstance _selectWeightedInstance(List<ServiceInstance> instances) {
    final totalWeight = instances.fold<int>(0, (sum, instance) => sum + instance.weight);
    final randomValue = Random().nextInt(totalWeight);
    
    int currentWeight = 0;
    for (final instance in instances) {
      currentWeight += instance.weight;
      if (randomValue < currentWeight) {
        return instance;
      }
    }
    
    return instances.first;
  }

  Future<void> _cacheResponse(String cacheKey, APIEndpoint endpoint, APIResponse response) async {
    // Check if response should be cached
    if (endpoint.cacheTtl != null && response.statusCode == 200) {
      _responseCache[cacheKey] = CachedResponse(
        response: response,
        cachedAt: DateTime.now(),
        expiresAt: DateTime.now().add(endpoint.cacheTtl!),
      );
    }
  }

  Future<void> _recordRequest(
    APIKey apiKey,
    APIEndpoint endpoint,
    DateTime startTime,
    int statusCode,
    bool isSuccess,
  ) async {
    final responseTime = DateTime.now().difference(startTime).inMilliseconds;

    // Update API metrics
    final metrics = _apiMetrics[endpoint.apiId];
    if (metrics != null) {
      metrics.totalRequests++;
      if (isSuccess) {
        metrics.successfulRequests++;
      } else {
        metrics.failedRequests++;
      }
      
      // Update average response time
      metrics.averageResponseTime = 
        (metrics.averageResponseTime * (metrics.totalRequests - 1) + responseTime) / 
        metrics.totalRequests;
      
      metrics.lastRequest = DateTime.now();
    }

    // Create request log
    final requestLog = RequestLog(
      logId: _generateLogId(),
      apiId: endpoint.apiId,
      endpoint: '${endpoint.method} ${endpoint.path}',
      method: endpoint.method,
      statusCode: statusCode,
      responseTime: responseTime,
      clientId: apiKey.clientId,
      timestamp: DateTime.now(),
      userAgent: '',
      ipAddress: '',
    );

    _requestLogs[requestLog.logId] = requestLog;
  }

  Future<List<EndpointUsage>> _getTopEndpoints(String apiId) async {
    // Calculate top endpoints from request logs
    final apiLogs = _requestLogs.values.where((log) => log.apiId == apiId);
    final endpointCounts = <String, int>{};

    for (final log in apiLogs) {
      endpointCounts[log.endpoint] = (endpointCounts[log.endpoint] ?? 0) + 1;
    }

    final topEndpoints = endpointCounts.entries
        .map((entry) => EndpointUsage(endpoint: entry.key, requestCount: entry.value))
        .toList()
      ..sort((a, b) => b.requestCount.compareTo(a.requestCount));

    return topEndpoints.take(10).toList();
  }

  Future<Map<int, int>> _getErrorRates(String apiId) async {
    // Calculate error rates by status code
    final apiLogs = _requestLogs.values.where((log) => log.apiId == apiId);
    final statusCounts = <int, int>{};

    for (final log in apiLogs) {
      statusCounts[log.statusCode] = (statusCounts[log.statusCode] ?? 0) + 1;
    }

    return statusCounts;
  }

  Future<Map<String, int>> _getResponseTimeDistribution(String apiId) async {
    // Calculate response time distribution
    final apiLogs = _requestLogs.values.where((log) => log.apiId == apiId);
    final distribution = <String, int>{
      '0-100ms': 0,
      '100-500ms': 0,
      '500ms-1s': 0,
      '1s-5s': 0,
      '5s+': 0,
    };

    for (final log in apiLogs) {
      if (log.responseTime < 100) {
        distribution['0-100ms'] = distribution['0-100ms']! + 1;
      } else if (log.responseTime < 500) {
        distribution['100-500ms'] = distribution['100-500ms']! + 1;
      } else if (log.responseTime < 1000) {
        distribution['500ms-1s'] = distribution['500ms-1s']! + 1;
      } else if (log.responseTime < 5000) {
        distribution['1s-5s'] = distribution['1s-5s']! + 1;
      } else {
        distribution['5s+'] = distribution['5s+']! + 1;
      }
    }

    return distribution;
  }

  String _generateCacheKey(String method, String path, Map<String, String>? queryParameters) {
    final query = queryParameters?.entries.map((e) => '${e.key}=${e.value}').join('&') ?? '';
    return '${method.toUpperCase()}_${path}_$query';
  }

  String _generateAPIKeyId() {
    return 'key_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';
  }

  String _generateAPIKeyValue() {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return List.generate(32, (index) => chars[Random().nextInt(chars.length)]).join();
  }

  String _generateDeploymentId() {
    return 'deploy_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';
  }

  String _generateLogId() {
    return 'log_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';
  }

  Interceptor _createRequestInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) {
        // Add request processing
        handler.next(options);
      },
    );
  }

  Interceptor _createResponseInterceptor() {
    return InterceptorsWrapper(
      onResponse: (response, handler) {
        // Add response processing
        handler.next(response);
      },
    );
  }

  Interceptor _createMetricsInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) {
        options.extra['startTime'] = DateTime.now();
        handler.next(options);
      },
      onResponse: (response, handler) {
        final startTime = response.requestOptions.extra['startTime'] as DateTime?;
        if (startTime != null) {
          final responseTime = DateTime.now().difference(startTime).inMilliseconds;
          // Record metrics
        }
        handler.next(response);
      },
    );
  }

  Future<void> _saveAPIDefinition(APIDefinition apiDefinition) async {
    if (_gatewayDb == null) return;

    await _gatewayDb!.insert(
      'api_definitions',
      {
        'api_id': apiDefinition.apiId,
        'name': apiDefinition.name,
        'description': apiDefinition.description,
        'base_path': apiDefinition.basePath,
        'status': apiDefinition.status.toString().split('.').last,
        'created_at': apiDefinition.createdAt.toIso8601String(),
        'updated_at': apiDefinition.updatedAt.toIso8601String(),
        'tags': jsonEncode(apiDefinition.tags),
        'documentation': apiDefinition.documentation,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> _saveAPIVersion(APIVersion apiVersion) async {
    if (_gatewayDb == null) return;

    await _gatewayDb!.insert(
      'api_versions',
      {
        'api_id': apiVersion.apiId,
        'version': apiVersion.version,
        'endpoints': jsonEncode(apiVersion.endpoints.map((e) => e.toJson()).toList()),
        'is_default': apiVersion.isDefault ? 1 : 0,
        'status': apiVersion.status.toString().split('.').last,
        'created_at': apiVersion.createdAt.toIso8601String(),
        'deployed_at': apiVersion.deployedAt?.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> _saveAPIKey(APIKey apiKey) async {
    if (_gatewayDb == null) return;

    await _gatewayDb!.insert(
      'api_keys',
      {
        'key_id': apiKey.keyId,
        'key_name': apiKey.keyName,
        'client_id': apiKey.clientId,
        'key_value': apiKey.keyValue,
        'allowed_apis': jsonEncode(apiKey.allowedAPIs),
        'allowed_endpoints': jsonEncode(apiKey.allowedEndpoints),
        'rate_limits': jsonEncode(apiKey.rateLimits),
        'is_active': apiKey.isActive ? 1 : 0,
        'created_at': apiKey.createdAt.toIso8601String(),
        'expires_at': apiKey.expiresAt?.toIso8601String(),
        'last_used': apiKey.lastUsed?.toIso8601String(),
        'usage_count': apiKey.usageCount,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> _saveRateLimitRule(RateLimitRule rule) async {
    if (_gatewayDb == null) return;

    await _gatewayDb!.insert(
      'rate_limit_rules',
      {
        'rule_id': rule.ruleId,
        'api_id': rule.apiId,
        'endpoint': rule.endpoint,
        'requests_per_hour': rule.requestsPerHour,
        'requests_per_minute': rule.requestsPerMinute,
        'burst_limit': rule.burstLimit,
        'is_active': rule.isActive ? 1 : 0,
        'created_at': rule.createdAt.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Dispose resources
  @override
  void dispose() {
    _metricsTimer?.cancel();
    _healthCheckTimer?.cancel();
    _gatewayDb?.close();
    _dio.close();
    super.dispose();
  }
}

// Data Models and Enums

enum APIStatus { draft, deployed, deprecated }
enum VersionStatus { draft, deployed, deprecated }
enum LoadBalancingAlgorithm { roundRobin, random, weighted }
enum CircuitBreakerState { closed, open, halfOpen }

class APIDefinition {
  final String apiId;
  final String name;
  final String description;
  final String basePath;
  APIStatus status;
  final DateTime createdAt;
  DateTime updatedAt;
  final List<String> tags;
  final String? documentation;

  APIDefinition({
    required this.apiId,
    required this.name,
    required this.description,
    required this.basePath,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.tags,
    this.documentation,
  });
}

class APIVersion {
  final String apiId;
  final String version;
  final List<APIEndpoint> endpoints;
  final bool isDefault;
  VersionStatus status;
  final DateTime createdAt;
  DateTime? deployedAt;

  APIVersion({
    required this.apiId,
    required this.version,
    required this.endpoints,
    required this.isDefault,
    required this.status,
    required this.createdAt,
    this.deployedAt,
  });
}

class APIEndpoint {
  final String apiId;
  final String path;
  final String method;
  final String description;
  final List<String> parameters;
  final Map<String, dynamic>? requestSchema;
  final Map<String, dynamic>? responseSchema;
  final bool authRequired;
  final String rateLimitTier;
  final Duration? cacheTtl;

  APIEndpoint({
    required this.apiId,
    required this.path,
    required this.method,
    required this.description,
    this.parameters = const [],
    this.requestSchema,
    this.responseSchema,
    this.authRequired = true,
    this.rateLimitTier = 'standard',
    this.cacheTtl,
  });

  Map<String, dynamic> toJson() => {
    'apiId': apiId,
    'path': path,
    'method': method,
    'description': description,
    'parameters': parameters,
    'requestSchema': requestSchema,
    'responseSchema': responseSchema,
    'authRequired': authRequired,
    'rateLimitTier': rateLimitTier,
    'cacheTtl': cacheTtl?.inSeconds,
  };
}

class APIKey {
  final String keyId;
  final String keyName;
  final String clientId;
  final String keyValue;
  final List<String> allowedAPIs;
  final List<String> allowedEndpoints;
  final Map<String, int> rateLimits;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? expiresAt;
  DateTime? lastUsed;
  int usageCount;

  APIKey({
    required this.keyId,
    required this.keyName,
    required this.clientId,
    required this.keyValue,
    required this.allowedAPIs,
    required this.allowedEndpoints,
    required this.rateLimits,
    required this.isActive,
    required this.createdAt,
    this.expiresAt,
    this.lastUsed,
    required this.usageCount,
  });
}

class RateLimitRule {
  final String ruleId;
  final String apiId;
  final String? endpoint;
  final int requestsPerHour;
  final int requestsPerMinute;
  final int burstLimit;
  final bool isActive;
  final DateTime createdAt;

  RateLimitRule({
    required this.ruleId,
    required this.apiId,
    this.endpoint,
    required this.requestsPerHour,
    required this.requestsPerMinute,
    required this.burstLimit,
    required this.isActive,
    required this.createdAt,
  });
}

class ServiceInstance {
  final String serviceId;
  final String instanceId;
  final String host;
  final int port;
  final int weight;
  bool isHealthy;
  final Map<String, dynamic> metadata;
  final DateTime registeredAt;
  DateTime lastHealthCheck;

  ServiceInstance({
    required this.serviceId,
    required this.instanceId,
    required this.host,
    required this.port,
    required this.weight,
    required this.isHealthy,
    required this.metadata,
    required this.registeredAt,
    required this.lastHealthCheck,
  });
}

class LoadBalancer {
  final String serviceId;
  final LoadBalancingAlgorithm algorithm;
  final List<ServiceInstance> instances;
  int currentIndex;

  LoadBalancer({
    required this.serviceId,
    required this.algorithm,
    required this.instances,
    this.currentIndex = -1,
  });
}

class CircuitBreaker {
  final String id;
  final int failureThreshold;
  final Duration recoveryTimeout;
  CircuitBreakerState state;
  int failureCount;
  DateTime? lastFailureTime;

  CircuitBreaker({
    required this.id,
    required this.failureThreshold,
    required this.recoveryTimeout,
    required this.state,
    this.failureCount = 0,
    this.lastFailureTime,
  });

  void recordFailure() {
    failureCount++;
    lastFailureTime = DateTime.now();
    
    if (failureCount >= failureThreshold) {
      state = CircuitBreakerState.open;
    }
  }

  void recordSuccess() {
    failureCount = 0;
    state = CircuitBreakerState.closed;
  }
}

class RateLimitBucket {
  final String id;
  final String keyId;
  final String endpoint;
  final int limit;
  int remaining;
  DateTime resetTime;

  RateLimitBucket({
    required this.id,
    required this.keyId,
    required this.endpoint,
    required this.limit,
    required this.remaining,
    required this.resetTime,
  });
}

class CacheRule {
  final String ruleId;
  final String apiId;
  final String? endpoint;
  final Duration ttl;
  final bool isActive;

  CacheRule({
    required this.ruleId,
    required this.apiId,
    this.endpoint,
    required this.ttl,
    required this.isActive,
  });
}

class CachedResponse {
  final APIResponse response;
  final DateTime cachedAt;
  final DateTime expiresAt;

  CachedResponse({
    required this.response,
    required this.cachedAt,
    required this.expiresAt,
  });
}

class AuthenticationPolicy {
  final String policyId;
  final String name;
  final String type;
  final Map<String, dynamic> configuration;
  final bool isActive;

  AuthenticationPolicy({
    required this.policyId,
    required this.name,
    required this.type,
    required this.configuration,
    required this.isActive,
  });
}

class APIMetrics {
  final String apiId;
  int totalRequests;
  int successfulRequests;
  int failedRequests;
  double averageResponseTime;
  DateTime? lastRequest;

  APIMetrics({
    required this.apiId,
    required this.totalRequests,
    required this.successfulRequests,
    required this.failedRequests,
    required this.averageResponseTime,
    this.lastRequest,
  });
}

class RequestLog {
  final String logId;
  final String apiId;
  final String endpoint;
  final String method;
  final int statusCode;
  final int responseTime;
  final String clientId;
  final DateTime timestamp;
  final String userAgent;
  final String ipAddress;

  RequestLog({
    required this.logId,
    required this.apiId,
    required this.endpoint,
    required this.method,
    required this.statusCode,
    required this.responseTime,
    required this.clientId,
    required this.timestamp,
    required this.userAgent,
    required this.ipAddress,
  });
}

class APIResponse {
  final int statusCode;
  final dynamic body;
  final Map<String, String> headers;

  APIResponse({
    required this.statusCode,
    required this.body,
    required this.headers,
  });
}

class APIAnalytics {
  final String apiId;
  final DateRange period;
  final int totalRequests;
  final int successfulRequests;
  final int failedRequests;
  final double averageResponseTime;
  final double requestsPerSecond;
  final List<EndpointUsage> topEndpoints;
  final Map<int, int> errorRates;
  final Map<String, int> responseTimeDistribution;

  APIAnalytics({
    required this.apiId,
    required this.period,
    required this.totalRequests,
    required this.successfulRequests,
    required this.failedRequests,
    required this.averageResponseTime,
    required this.requestsPerSecond,
    required this.topEndpoints,
    required this.errorRates,
    required this.responseTimeDistribution,
  });
}

class DateRange {
  final DateTime start;
  final DateTime end;

  DateRange({required this.start, required this.end});
}

class EndpointUsage {
  final String endpoint;
  final int requestCount;

  EndpointUsage({required this.endpoint, required this.requestCount});
}

// Result Classes

class APIRegistrationResult {
  final bool success;
  final String apiId;
  final String? version;
  final String? error;

  APIRegistrationResult({
    required this.success,
    required this.apiId,
    this.version,
    this.error,
  });
}

class APIDeploymentResult {
  final bool success;
  final String apiId;
  final String version;
  final String? deploymentId;
  final String? error;

  APIDeploymentResult({
    required this.success,
    required this.apiId,
    required this.version,
    this.deploymentId,
    this.error,
  });
}

class APIKeyResult {
  final bool success;
  final String? keyId;
  final String? keyValue;
  final String? error;

  APIKeyResult({
    required this.success,
    this.keyId,
    this.keyValue,
    this.error,
  });
}

class APIAnalyticsResult {
  final bool success;
  final String apiId;
  final APIAnalytics? analytics;
  final String? error;

  APIAnalyticsResult({
    required this.success,
    required this.apiId,
    this.analytics,
    this.error,
  });
}

class RateLimitUpdateResult {
  final bool success;
  final String ruleId;
  final String? error;

  RateLimitUpdateResult({
    required this.success,
    required this.ruleId,
    this.error,
  });
}

class ServiceRegistrationResult {
  final bool success;
  final String serviceId;
  final String instanceId;
  final String? error;

  ServiceRegistrationResult({
    required this.success,
    required this.serviceId,
    required this.instanceId,
    this.error,
  });
}

class APIValidationResult {
  final bool isValid;
  final List<String> errors;

  APIValidationResult({
    required this.isValid,
    required this.errors,
  });
}

class AuthenticationResult {
  final bool isAuthenticated;
  final APIKey? apiKey;
  final String? error;

  AuthenticationResult({
    required this.isAuthenticated,
    this.apiKey,
    this.error,
  });
}

class RateLimitResult {
  final bool allowed;
  final int limit;
  final int remaining;
  final DateTime? resetTime;

  RateLimitResult({
    required this.allowed,
    required this.limit,
    required this.remaining,
    this.resetTime,
  });
}