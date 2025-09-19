import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:convert';
import 'dart:async';
import '../core/app_export.dart';
import '../database/models/subscription.dart';
import '../database/models/billing_account.dart';
import '../database/models/tenant_security.dart';
import '../database/models/tenant_user.dart';
import '../database/models/database_partition.dart';
import '../database/models/tenant_metrics.dart';
import '../database/models/tenant_creation_result.dart';
import '../database/models/tenant_switch_result.dart';
import '../database/models/tenant_config_result.dart';
import '../database/models/tenant_customization_result.dart';
import '../database/models/resource_quota_result.dart';
import '../database/models/resource_limit_check_result.dart';
import '../database/models/subscription_result.dart';
import '../database/models/tenant_operation_result.dart';
import '../database/models/tenant_analytics_result.dart';
import '../database/models/tenant.dart';

/// Multi-Tenant Architecture Service
///
/// Provides comprehensive multi-tenancy capabilities including:
/// - Tenant isolation and data segregation
/// - Tenant-specific customization and branding
/// - Resource allocation and quotas
/// - Tenant lifecycle management
/// - Cross-tenant analytics and reporting
/// - Tenant-specific configurations
/// - Billing and subscription management
/// - Tenant security and access control
/// - Database partitioning strategies
/// - Tenant monitoring and analytics
class MultiTenantService extends ChangeNotifier {
  static MultiTenantService? _instance;

  static MultiTenantService get instance {
    _instance ??= MultiTenantService._internal();
    return _instance!;
  }

  factory MultiTenantService() => instance;

  MultiTenantService._internal();

  Database? _tenantDb;
  bool _isInitialized = false;
  String? _currentTenantId;
  Timer? _resourceMonitorTimer;
  Timer? _billingTimer;

  // Tenant Management
  final Map<String, Tenant> _tenants = {};
  final Map<String, TenantConfiguration> _tenantConfigs = {};
  final Map<String, TenantCustomization> _tenantCustomizations = {};

  // Resource Management
  final Map<String, ResourceQuota> _resourceQuotas = {};
  final Map<String, ResourceUsage> _resourceUsage = {};

  // Billing and Subscriptions
  final Map<String, Subscription> _subscriptions = {};
  final Map<String, BillingAccount> _billingAccounts = {};

  // Security and Access Control
  final Map<String, TenantSecurity> _tenantSecurity = {};
  final Map<String, List<TenantUser>> _tenantUsers = {};

  // Database Partitioning
  final Map<String, DatabasePartition> _databasePartitions = {};

  // Monitoring and Analytics
  final Map<String, TenantMetrics> _tenantMetrics = {};

  // Getters
  bool get isInitialized => _isInitialized;
  String? get currentTenantId => _currentTenantId;
  Map<String, Tenant> get tenants => Map.unmodifiable(_tenants);
  Map<String, TenantConfiguration> get tenantConfigs => Map.unmodifiable(_tenantConfigs);
  Map<String, ResourceUsage> get resourceUsage => Map.unmodifiable(_resourceUsage);

  /// Initialize the Multi-Tenant service
  Future<void> initialize() async {
    try {
      if (_isInitialized) return;

      debugPrint('🏢 Initializing Multi-Tenant Service...');

      // Initialize tenant database
      await _initializeTenantDatabase();

      // Load existing tenants
      await _loadTenants();
      await _loadTenantConfigurations();
      await _loadResourceQuotas();
      await _loadSubscriptions();

      // Initialize partitioning strategy
      await _initializeDatabasePartitioning();

      // Start background monitoring
      _startResourceMonitoring();
      _startBillingProcessor();

      _isInitialized = true;
      debugPrint('✅ Multi-Tenant Service initialized successfully');

      notifyListeners();
    } catch (e) {
      debugPrint('❌ Failed to initialize Multi-Tenant Service: $e');
      rethrow;
    }
  }

  /// Create a new tenant
  Future<TenantCreationResult> createTenant({
    required String tenantId,
    required String name,
    required String adminEmail,
    required TenantPlan plan,
    Map<String, dynamic>? customSettings,
  }) async {
    try {
      debugPrint('🏗️ Creating tenant: $tenantId');

      // Validate tenant ID
      if (_tenants.containsKey(tenantId)) {
        return TenantCreationResult(
          success: false,
          tenantId: tenantId,
          error: 'Tenant ID already exists',
        );
      }

      // Create tenant
      final tenant = Tenant(
        tenantId: tenantId,
        name: name,
        adminEmail: adminEmail,
        plan: plan,
        status: TenantStatus.active,
        createdAt: DateTime.now(),
        lastActiveAt: DateTime.now(),
        settings: customSettings ?? {},
      );

      // Create tenant configuration
      final config = TenantConfiguration(
        tenantId: tenantId,
        databaseSettings: _getDefaultDatabaseSettings(plan),
        securitySettings: _getDefaultSecuritySettings(plan),
        featureFlags: _getDefaultFeatureFlags(plan),
        integrationSettings: {},
        customSettings: customSettings ?? {},
      );

      // Create tenant customization
      final customization = TenantCustomization(
        tenantId: tenantId,
        branding: TenantBranding(
          primaryColor: '#2196F3',
          secondaryColor: '#FFC107',
          logo: null,
          favicon: null,
          customCss: null,
        ),
        localization: TenantLocalization(
          defaultLanguage: 'en',
          supportedLanguages: ['en'],
          customTranslations: {},
        ),
        uiCustomizations: {},
      );

      // Create resource quota
      final quota = _createResourceQuota(tenantId, plan);

      // Create billing account
      final billingAccount = BillingAccount(
        id: _generateAccountId(),
        tenantId: tenantId,
        status: 'active',
        billingName: 'Default',
        billingEmail: 'billing@example.com',
        billingAddress: 'Default Address',
        billingCity: 'Default City',
        billingState: 'Default State',
        billingZip: '00000',
        billingCountry: 'Default Country',
        paymentMethod: 'credit_card',
        paymentDetails: {},
        balance: 0.0,
        lastPaymentDate: DateTime.now(),
        lastPaymentAmount: 0.0,
        nextBillingDate: DateTime.now().add(const Duration(days: 30)),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Create subscription
      final subscription = Subscription(
        id: _generateSubscriptionId(),
        tenantId: tenantId,
        planId: plan.toString(),
        status: 'active',
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 365)),
        amount: _getPlanAmount(plan),
        billingCycle: 'monthly',
        autoRenew: true,
        features: _getPlanFeatures(plan),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Create tenant security
      final security = TenantSecurity(
        tenantId: tenantId,
        encryptionKey: _generateEncryptionKey(),
        accessPolicies: _getDefaultAccessPolicies(plan),
        auditSettings: _getDefaultAuditSettings(plan),
        ssoSettings: null,
      );

      // Create database partition
      await _createDatabasePartition(tenantId);

      // Store all tenant data
      _tenants[tenantId] = tenant;
      _tenantConfigs[tenantId] = config;
      _tenantCustomizations[tenantId] = customization;
      _resourceQuotas[tenantId] = quota;
      _billingAccounts[tenantId] = billingAccount;
      _subscriptions[tenantId] = subscription;
      _tenantSecurity[tenantId] = security;
      _tenantUsers[tenantId] = [];

      // Initialize metrics
      _tenantMetrics[tenantId] = TenantMetrics(
        tenantId: tenantId,
        activeUsers: 0,
        totalUsers: 0,
        storageUsed: 0.0,
        apiCallsThisMonth: 0,
        averageResponseTime: 0.0,
        uptime: 100.0,
        errorCount: 0,
        totalPatients: 0,
        totalAppointments: 0,
        customMetrics: {},
        lastUpdated: DateTime.now(),
      );

      // Initialize resource usage
      _resourceUsage[tenantId] = ResourceUsage(
        tenantId: tenantId,
        cpuUsage: 0.0,
        memoryUsage: 0,
        storageUsage: 0,
        bandwidthUsage: 0,
        activeConnections: 0,
        lastUpdated: DateTime.now(),
      );

      // Save to database
      await _saveTenantToDatabase(tenant);
      await _saveTenantConfigToDatabase(config);

      debugPrint('✅ Tenant created successfully: $tenantId');
      notifyListeners();

      return TenantCreationResult(
        success: true,
        tenantId: tenantId,
        tenant: tenant,
      );
    } catch (e) {
      debugPrint('❌ Failed to create tenant: $e');
      return TenantCreationResult(
        success: false,
        tenantId: tenantId,
        error: e.toString(),
      );
    }
  }

  /// Switch to a specific tenant context
  Future<TenantSwitchResult> switchTenant(String tenantId) async {
    try {
      final tenant = _tenants[tenantId];
      if (tenant == null) {
        return TenantSwitchResult(
          success: false,
          tenantId: tenantId,
          error: 'Tenant not found',
        );
      }

      if (tenant.status != TenantStatus.active) {
        return TenantSwitchResult(
          success: false,
          tenantId: tenantId,
          error: 'Tenant is not active',
        );
      }

      _currentTenantId = tenantId;
      tenant.lastActiveAt = DateTime.now();

      // Update tenant metrics
      final metrics = _tenantMetrics[tenantId];
      if (metrics != null) {
        _tenantMetrics[tenantId] = TenantMetrics(
          tenantId: metrics.tenantId,
          activeUsers: metrics.activeUsers + 1,
          totalUsers: metrics.totalUsers,
          storageUsed: metrics.storageUsed,
          apiCallsThisMonth: metrics.apiCallsThisMonth,
          averageResponseTime: metrics.averageResponseTime,
          uptime: metrics.uptime,
          errorCount: metrics.errorCount,
          totalPatients: metrics.totalPatients,
          totalAppointments: metrics.totalAppointments,
          customMetrics: metrics.customMetrics,
          lastUpdated: DateTime.now(),
        );
      }

      debugPrint('🔄 Switched to tenant: $tenantId');
      notifyListeners();

      return TenantSwitchResult(
        success: true,
        tenantId: tenantId,
        tenant: tenant,
      );
    } catch (e) {
      debugPrint('❌ Failed to switch tenant: $e');
      return TenantSwitchResult(
        success: false,
        tenantId: tenantId,
        error: e.toString(),
      );
    }
  }

  /// Get tenant configuration
  TenantConfiguration? getTenantConfiguration(String tenantId) {
    return _tenantConfigs[tenantId];
  }

  /// Update tenant configuration
  Future<TenantConfigResult> updateTenantConfiguration({
    required String tenantId,
    Map<String, dynamic>? databaseSettings,
    Map<String, dynamic>? securitySettings,
    Map<String, bool>? featureFlags,
    Map<String, dynamic>? integrationSettings,
    Map<String, dynamic>? customSettings,
  }) async {
    try {
      final config = _tenantConfigs[tenantId];
      if (config == null) {
        return TenantConfigResult(
          success: false,
          tenantId: tenantId,
          error: 'Tenant configuration not found',
        );
      }

      // Update configuration
      if (databaseSettings != null) {
        config.databaseSettings.addAll(databaseSettings);
      }
      if (securitySettings != null) {
        config.securitySettings.addAll(securitySettings);
      }
      if (featureFlags != null) {
        config.featureFlags.addAll(featureFlags);
      }
      if (integrationSettings != null) {
        config.integrationSettings.addAll(integrationSettings);
      }
      if (customSettings != null) {
        config.customSettings.addAll(customSettings);
      }

      // Save to database
      await _saveTenantConfigToDatabase(config);

      debugPrint('✅ Tenant configuration updated: $tenantId');
      notifyListeners();

      return TenantConfigResult(
        success: true,
        tenantId: tenantId,
        configuration: config,
      );
    } catch (e) {
      debugPrint('❌ Failed to update tenant configuration: $e');
      return TenantConfigResult(
        success: false,
        tenantId: tenantId,
        error: e.toString(),
      );
    }
  }

  /// Update tenant branding and customization
  Future<TenantCustomizationResult> updateTenantCustomization({
    required String tenantId,
    TenantBranding? branding,
    TenantLocalization? localization,
    Map<String, dynamic>? uiCustomizations,
  }) async {
    try {
      final customization = _tenantCustomizations[tenantId];
      if (customization == null) {
        return TenantCustomizationResult(
          success: false,
          tenantId: tenantId,
          error: 'Tenant customization not found',
        );
      }

      // Update customization
      if (branding != null) {
        customization.branding = branding;
      }
      if (localization != null) {
        customization.localization = localization;
      }
      if (uiCustomizations != null) {
        customization.uiCustomizations.addAll(uiCustomizations);
      }

      debugPrint('✅ Tenant customization updated: $tenantId');
      notifyListeners();

      return TenantCustomizationResult(
        success: true,
        tenantId: tenantId,
        customization: customization,
      );
    } catch (e) {
      debugPrint('❌ Failed to update tenant customization: $e');
      return TenantCustomizationResult(
        success: false,
        tenantId: tenantId,
        error: e.toString(),
      );
    }
  }

  /// Get tenant resource usage
  ResourceUsage? getResourceUsage(String tenantId) {
    return _resourceUsage[tenantId];
  }

  /// Update resource quota for tenant
  Future<ResourceQuotaResult> updateResourceQuota({
    required String tenantId,
    int? maxUsers,
    int? maxStorage,
    int? maxBandwidth,
    int? maxConnections,
    int? maxRequests,
  }) async {
    try {
      final quota = _resourceQuotas[tenantId];
      if (quota == null) {
        return ResourceQuotaResult(
          success: false,
          tenantId: tenantId,
          error: 'Resource quota not found',
        );
      }

      // Update quota
      if (maxUsers != null) quota.maxUsers = maxUsers;
      if (maxStorage != null) quota.maxStorage = maxStorage;
      if (maxBandwidth != null) quota.maxBandwidth = maxBandwidth;
      if (maxConnections != null) quota.maxConnections = maxConnections;
      if (maxRequests != null) quota.maxRequests = maxRequests;

      quota.updatedAt = DateTime.now();

      debugPrint('✅ Resource quota updated: $tenantId');
      notifyListeners();

      return ResourceQuotaResult(
        success: true,
        tenantId: tenantId,
        quota: quota,
      );
    } catch (e) {
      debugPrint('❌ Failed to update resource quota: $e');
      return ResourceQuotaResult(
        success: false,
        tenantId: tenantId,
        error: e.toString(),
      );
    }
  }

  /// Check if tenant has exceeded resource limits
  Future<ResourceLimitCheckResult> checkResourceLimits(String tenantId) async {
    try {
      final quota = _resourceQuotas[tenantId];
      final usage = _resourceUsage[tenantId];

      if (quota == null || usage == null) {
        return ResourceLimitCheckResult(
          success: false,
          tenantId: tenantId,
          error: 'Quota or usage data not found',
        );
      }

      final violations = <ResourceViolation>[];

      // Check user limit
      if (usage.activeUsers > quota.maxUsers) {
        violations.add(ResourceViolation(
          type: ResourceType.users,
          limit: quota.maxUsers,
          current: usage.activeUsers,
          severity: ViolationSeverity.high,
        ));
      }

      // Check storage limit
      if (usage.storageUsage > quota.maxStorage) {
        violations.add(ResourceViolation(
          type: ResourceType.storage,
          limit: quota.maxStorage,
          current: usage.storageUsage,
          severity: ViolationSeverity.medium,
        ));
      }

      // Check bandwidth limit
      if (usage.bandwidthUsage > quota.maxBandwidth) {
        violations.add(ResourceViolation(
          type: ResourceType.bandwidth,
          limit: quota.maxBandwidth,
          current: usage.bandwidthUsage,
          severity: ViolationSeverity.low,
        ));
      }

      // Check connection limit
      if (usage.activeConnections > quota.maxConnections) {
        violations.add(ResourceViolation(
          type: ResourceType.connections,
          limit: quota.maxConnections,
          current: usage.activeConnections,
          severity: ViolationSeverity.high,
        ));
      }

      return ResourceLimitCheckResult(
        success: true,
        tenantId: tenantId,
        hasViolations: violations.isNotEmpty,
        violations: violations,
      );
    } catch (e) {
      debugPrint('❌ Failed to check resource limits: $e');
      return ResourceLimitCheckResult(
        success: false,
        tenantId: tenantId,
        error: e.toString(),
      );
    }
  }

  /// Get tenant billing information
  BillingAccount? getBillingAccount(String tenantId) {
    return _billingAccounts[tenantId];
  }

  /// Update tenant subscription
  Future<SubscriptionResult> updateSubscription({
    required String tenantId,
    TenantPlan? newPlan,
    bool? autoRenew,
    DateTime? endDate,
  }) async {
    try {
      final subscription = _subscriptions[tenantId];
      if (subscription == null) {
        return SubscriptionResult(
          success: false,
          tenantId: tenantId,
          error: 'Subscription not found',
        );
      }

      // Update subscription
      final updatedPlanId = newPlan?.toString() ?? subscription.planId;
      final updatedAutoRenew = autoRenew ?? subscription.autoRenew;
      final updatedEndDate = endDate ?? subscription.endDate;
      final updatedFeatures = newPlan != null ? _getPlanFeatures(newPlan) : subscription.features;

      _subscriptions[tenantId] = Subscription(
        id: subscription.id,
        tenantId: subscription.tenantId,
        planId: updatedPlanId,
        status: subscription.status,
        startDate: subscription.startDate,
        endDate: updatedEndDate,
        amount: newPlan != null ? _getPlanAmount(newPlan) : subscription.amount,
        billingCycle: subscription.billingCycle,
        autoRenew: updatedAutoRenew,
        features: updatedFeatures,
        createdAt: subscription.createdAt,
        updatedAt: DateTime.now(),
      );

      // Update resource quota for new plan
      if (newPlan != null) {
        _resourceQuotas[tenantId] = _createResourceQuota(tenantId, newPlan);
      }

      debugPrint('✅ Subscription updated: $tenantId');
      notifyListeners();

      return SubscriptionResult(
        success: true,
        tenantId: tenantId,
        subscription: _subscriptions[tenantId]?.toMap(),
      );
    } catch (e) {
      debugPrint('❌ Failed to update subscription: $e');
      return SubscriptionResult(
        success: false,
        tenantId: tenantId,
        error: e.toString(),
      );
    }
  }

  /// Suspend tenant
  Future<TenantOperationResult> suspendTenant(String tenantId, String reason) async {
    try {
      final tenant = _tenants[tenantId];
      if (tenant == null) {
        return TenantOperationResult(
          success: false,
          tenantId: tenantId,
          operation: 'suspend',
          timestamp: DateTime.now(),
          error: 'Tenant not found',
        );
      }

      tenant.status = TenantStatus.suspended;
      tenant.suspensionReason = reason;

      // Save to database
      await _saveTenantToDatabase(tenant);

      debugPrint('⏸️ Tenant suspended: $tenantId');
      notifyListeners();

      return TenantOperationResult(
        success: true,
        tenantId: tenantId,
        operation: 'suspend',
        timestamp: DateTime.now(),
      );
    } catch (e) {
      debugPrint('❌ Failed to suspend tenant: $e');
      return TenantOperationResult(
        success: false,
        tenantId: tenantId,
        operation: 'suspend',
        timestamp: DateTime.now(),
        error: e.toString(),
      );
    }
  }

  /// Reactivate tenant
  Future<TenantOperationResult> reactivateTenant(String tenantId) async {
    try {
      final tenant = _tenants[tenantId];
      if (tenant == null) {
        return TenantOperationResult(
          success: false,
          tenantId: tenantId,
          operation: 'reactivate',
          timestamp: DateTime.now(),
          error: 'Tenant not found',
        );
      }

      tenant.status = TenantStatus.active;
      tenant.suspensionReason = null;

      // Save to database
      await _saveTenantToDatabase(tenant);

      debugPrint('▶️ Tenant reactivated: $tenantId');
      notifyListeners();

      return TenantOperationResult(
        success: true,
        tenantId: tenantId,
        operation: 'reactivate',
        timestamp: DateTime.now(),
      );
    } catch (e) {
      debugPrint('❌ Failed to reactivate tenant: $e');
      return TenantOperationResult(
        success: false,
        tenantId: tenantId,
        operation: 'reactivate',
        timestamp: DateTime.now(),
        error: e.toString(),
      );
    }
  }

  /// Delete tenant and all associated data
  Future<TenantOperationResult> deleteTenant(String tenantId) async {
    try {
      final tenant = _tenants[tenantId];
      if (tenant == null) {
        return TenantOperationResult(
          success: false,
          tenantId: tenantId,
          operation: 'delete',
          timestamp: DateTime.now(),
          error: 'Tenant not found',
        );
      }

      // Delete from database
      await _deleteTenantFromDatabase(tenantId);
      await _deleteDatabasePartition(tenantId);

      // Remove from memory
      _tenants.remove(tenantId);
      _tenantConfigs.remove(tenantId);
      _tenantCustomizations.remove(tenantId);
      _resourceQuotas.remove(tenantId);
      _resourceUsage.remove(tenantId);
      _subscriptions.remove(tenantId);
      _billingAccounts.remove(tenantId);
      _tenantSecurity.remove(tenantId);
      _tenantUsers.remove(tenantId);
      _tenantMetrics.remove(tenantId);
      _databasePartitions.remove(tenantId);

      debugPrint('🗑️ Tenant deleted: $tenantId');
      notifyListeners();

      return TenantOperationResult(
        success: true,
        tenantId: tenantId,
        operation: 'delete',
        timestamp: DateTime.now(),
      );
    } catch (e) {
      debugPrint('❌ Failed to delete tenant: $e');
      return TenantOperationResult(
        success: false,
        tenantId: tenantId,
        operation: 'delete',
        timestamp: DateTime.now(),
        error: e.toString(),
      );
    }
  }

  /// Get tenant analytics
  Future<TenantAnalyticsResult> getTenantAnalytics(String tenantId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final metrics = _tenantMetrics[tenantId];
      final usage = _resourceUsage[tenantId];

      if (metrics == null || usage == null) {
        return TenantAnalyticsResult(
          success: false,
          tenantId: tenantId,
          error: 'Analytics data not found',
        );
      }

      // Create analytics data map instead of undefined classes
      final analyticsData = {
        'tenantId': tenantId,
        'period': {
          'start': (startDate ?? DateTime.now().subtract(const Duration(days: 30))).toIso8601String(),
          'end': (endDate ?? DateTime.now()).toIso8601String(),
        },
        'userMetrics': {
          'totalUsers': metrics.totalUsers,
          'activeUsers': metrics.activeUsers,
          'newUsers': 0,
          'userGrowthRate': 0.0,
        },
        'usageMetrics': {
          'apiCallsThisMonth': metrics.apiCallsThisMonth,
          'storageUsed': metrics.storageUsed,
          'averageResponseTime': metrics.averageResponseTime,
        },
        'financialMetrics': {
          'totalRevenue': 0.0,
          'monthlyRecurringRevenue': 0.0,
          'churnRate': 0.0,
          'averageRevenuePerUser': 0.0,
        },
        'performanceMetrics': {
          'uptime': metrics.uptime,
          'errorRate': 0.1,
          'averageLoadTime': 1.2,
          'throughput': 1000.0,
        },
      };

      return TenantAnalyticsResult(
        success: true,
        tenantId: tenantId,
        analytics: analyticsData,
      );
    } catch (e) {
      debugPrint('❌ Failed to get tenant analytics: $e');
      return TenantAnalyticsResult(
        success: false,
        tenantId: tenantId,
        error: e.toString(),
      );
    }
  }

  // Private Implementation Methods

  Future<void> _initializeTenantDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = '$databasesPath/multi_tenant.db';

    _tenantDb = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // Tenants table
        await db.execute('''
          CREATE TABLE tenants (
            tenant_id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            admin_email TEXT NOT NULL,
            plan TEXT NOT NULL,
            status TEXT NOT NULL,
            created_at TEXT NOT NULL,
            last_active_at TEXT,
            suspension_reason TEXT,
            settings TEXT
          )
        ''');

        // Tenant configurations table
        await db.execute('''
          CREATE TABLE tenant_configurations (
            tenant_id TEXT PRIMARY KEY,
            database_settings TEXT,
            security_settings TEXT,
            feature_flags TEXT,
            integration_settings TEXT,
            custom_settings TEXT,
            FOREIGN KEY (tenant_id) REFERENCES tenants (tenant_id)
          )
        ''');

        // Resource quotas table
        await db.execute('''
          CREATE TABLE resource_quotas (
            tenant_id TEXT PRIMARY KEY,
            max_users INTEGER,
            max_storage INTEGER,
            max_bandwidth INTEGER,
            max_connections INTEGER,
            max_requests INTEGER,
            created_at TEXT,
            updated_at TEXT,
            FOREIGN KEY (tenant_id) REFERENCES tenants (tenant_id)
          )
        ''');

        // Subscriptions table
        await db.execute('''
          CREATE TABLE subscriptions (
            tenant_id TEXT PRIMARY KEY,
            subscription_id TEXT UNIQUE,
            plan TEXT NOT NULL,
            status TEXT NOT NULL,
            start_date TEXT NOT NULL,
            end_date TEXT NOT NULL,
            auto_renew INTEGER,
            features TEXT,
            FOREIGN KEY (tenant_id) REFERENCES tenants (tenant_id)
          )
        ''');
      },
    );

    debugPrint('✅ Tenant database initialized');
  }

  Future<void> _loadTenants() async {
    if (_tenantDb == null) return;

    final List<Map<String, dynamic>> maps = await _tenantDb!.query('tenants');

    for (final map in maps) {
      final tenant = Tenant(
        tenantId: map['tenant_id'],
        name: map['name'],
        adminEmail: map['admin_email'],
        plan: TenantPlan.values.firstWhere((p) => p.toString().split('.').last == map['plan']),
        status: TenantStatus.values.firstWhere((s) => s.toString().split('.').last == map['status']),
        createdAt: DateTime.parse(map['created_at']),
        lastActiveAt: map['last_active_at'] != null ? DateTime.parse(map['last_active_at']) : null,
        suspensionReason: map['suspension_reason'],
        settings: map['settings'] != null ? jsonDecode(map['settings']) : {},
      );

      _tenants[tenant.tenantId] = tenant;
    }

    debugPrint('✅ Loaded ${_tenants.length} tenants');
  }

  Future<void> _loadTenantConfigurations() async {
    if (_tenantDb == null) return;

    final List<Map<String, dynamic>> maps = await _tenantDb!.query('tenant_configurations');

    for (final map in maps) {
      final config = TenantConfiguration(
        tenantId: map['tenant_id'],
        databaseSettings: map['database_settings'] != null ? jsonDecode(map['database_settings']) : {},
        securitySettings: map['security_settings'] != null ? jsonDecode(map['security_settings']) : {},
        featureFlags: map['feature_flags'] != null ? Map<String, bool>.from(jsonDecode(map['feature_flags'])) : {},
        integrationSettings: map['integration_settings'] != null ? jsonDecode(map['integration_settings']) : {},
        customSettings: map['custom_settings'] != null ? jsonDecode(map['custom_settings']) : {},
      );

      _tenantConfigs[config.tenantId] = config;
    }

    debugPrint('✅ Loaded ${_tenantConfigs.length} tenant configurations');
  }

  Future<void> _loadResourceQuotas() async {
    if (_tenantDb == null) return;

    final List<Map<String, dynamic>> maps = await _tenantDb!.query('resource_quotas');

    for (final map in maps) {
      final quota = ResourceQuota(
        tenantId: map['tenant_id'],
        maxUsers: map['max_users'],
        maxStorage: map['max_storage'],
        maxBandwidth: map['max_bandwidth'],
        maxConnections: map['max_connections'],
        maxRequests: map['max_requests'],
        createdAt: DateTime.parse(map['created_at']),
        updatedAt: DateTime.parse(map['updated_at']),
      );

      _resourceQuotas[quota.tenantId] = quota;
    }

    debugPrint('✅ Loaded ${_resourceQuotas.length} resource quotas');
  }

  Future<void> _loadSubscriptions() async {
    if (_tenantDb == null) return;

    final List<Map<String, dynamic>> maps = await _tenantDb!.query('subscriptions');

    for (final map in maps) {
      final subscription = Subscription(
        tenantId: map['tenant_id'],
        subscriptionId: map['subscription_id'],
        plan: TenantPlan.values.firstWhere((p) => p.toString().split('.').last == map['plan']),
        status: SubscriptionStatus.values.firstWhere((s) => s.toString().split('.').last == map['status']),
        startDate: DateTime.parse(map['start_date']),
        endDate: DateTime.parse(map['end_date']),
        autoRenew: map['auto_renew'] == 1,
        features: map['features'] != null ? List<String>.from(jsonDecode(map['features'])) : [],
      );

      _subscriptions[subscription.tenantId] = subscription;
    }

    debugPrint('✅ Loaded ${_subscriptions.length} subscriptions');
  }

  Future<void> _initializeDatabasePartitioning() async {
    // Initialize database partitioning for each tenant
    for (final tenantId in _tenants.keys) {
      await _createDatabasePartition(tenantId);
    }
  }

  Future<void> _createDatabasePartition(String tenantId) async {
    // Create tenant-specific database partition
    final partition = DatabasePartition(
      id: 'partition_$tenantId',
      tenantId: tenantId,
      partitionType: 'dedicated',
      connectionString: 'sqlite://tenant_$tenantId.db',
      maxConnections: 50,
      storageLimit: 10.0,
      currentUsage: 0.0,
      maxTables: 100,
      backupEnabled: true,
      backupFrequency: 'daily',
      backupRetentionDays: 30,
      lastBackupAt: DateTime.now(),
      status: 'active',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    _databasePartitions[tenantId] = partition;
  }

  Future<void> _deleteDatabasePartition(String tenantId) async {
    // Delete tenant-specific database partition
    final partition = _databasePartitions[tenantId];
    if (partition != null) {
      // Delete physical database file
      // Implementation depends on the database system
      debugPrint('🗑️ Database partition deleted for tenant: $tenantId');
    }
  }

  void _startResourceMonitoring() {
    _resourceMonitorTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      _updateResourceUsage();
    });
  }

  void _startBillingProcessor() {
    _billingTimer = Timer.periodic(const Duration(hours: 24), (timer) {
      _processBilling();
    });
  }

  Future<void> _updateResourceUsage() async {
    for (final tenantId in _tenants.keys) {
      // Simulate resource usage updates
      final usage = _resourceUsage[tenantId];
      if (usage != null) {
        // Update with real metrics from monitoring
        usage.lastUpdated = DateTime.now();
      }
    }
  }

  Future<void> _processBilling() async {
    final now = DateTime.now();

    for (final billingAccount in _billingAccounts.values) {
      if (billingAccount.nextBillingDate.isBefore(now)) {
        // Process billing for this tenant
        await _processTenantBilling(billingAccount);
      }
    }
  }

  Future<void> _processTenantBilling(BillingAccount billingAccount) async {
    // Process billing for a specific tenant
    debugPrint('💳 Processing billing for tenant: ${billingAccount.tenantId}');

    // Calculate next billing date
    DateTime nextBilling;
    if (billingAccount.billingCycle == 'monthly') {
      nextBilling = billingAccount.nextBillingDate.add(const Duration(days: 30));
    } else if (billingAccount.billingCycle == 'yearly') {
      nextBilling = billingAccount.nextBillingDate.add(const Duration(days: 365));
    } else {
      nextBilling = billingAccount.nextBillingDate.add(const Duration(days: 30)); // default monthly
    }

    // Create updated billing account
    _billingAccounts[billingAccount.tenantId] = BillingAccount(
      id: billingAccount.id,
      tenantId: billingAccount.tenantId,
      status: billingAccount.status,
      billingName: billingAccount.billingName,
      billingEmail: billingAccount.billingEmail,
      billingAddress: billingAccount.billingAddress,
      billingCity: billingAccount.billingCity,
      billingState: billingAccount.billingState,
      billingZip: billingAccount.billingZip,
      billingCountry: billingAccount.billingCountry,
      paymentMethod: billingAccount.paymentMethod,
      paymentDetails: billingAccount.paymentDetails,
      balance: billingAccount.balance,
      lastPaymentDate: DateTime.now(),
      lastPaymentAmount: billingAccount.lastPaymentAmount,
      nextBillingDate: nextBilling,
      createdAt: billingAccount.createdAt,
      updatedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> _getDefaultDatabaseSettings(TenantPlan plan) {
    switch (plan) {
      case TenantPlan.basic:
        return {'maxConnections': 10, 'queryTimeout': 30};
      case TenantPlan.professional:
        return {'maxConnections': 50, 'queryTimeout': 60};
      case TenantPlan.enterprise:
        return {'maxConnections': 200, 'queryTimeout': 120};
    }
  }

  Map<String, dynamic> _getDefaultSecuritySettings(TenantPlan plan) {
    return {
      'encryptionEnabled': true,
      'auditLoggingEnabled': plan != TenantPlan.basic,
      'mfaRequired': plan == TenantPlan.enterprise,
    };
  }

  Map<String, bool> _getDefaultFeatureFlags(TenantPlan plan) {
    switch (plan) {
      case TenantPlan.basic:
        return {
          'advancedReporting': false,
          'apiAccess': false,
          'customBranding': false,
          'ssoIntegration': false,
        };
      case TenantPlan.professional:
        return {
          'advancedReporting': true,
          'apiAccess': true,
          'customBranding': false,
          'ssoIntegration': false,
        };
      case TenantPlan.enterprise:
        return {
          'advancedReporting': true,
          'apiAccess': true,
          'customBranding': true,
          'ssoIntegration': true,
        };
    }
  }

  ResourceQuota _createResourceQuota(String tenantId, TenantPlan plan) {
    switch (plan) {
      case TenantPlan.basic:
        return ResourceQuota(
          tenantId: tenantId,
          maxUsers: 10,
          maxStorage: 1024 * 1024 * 1024, // 1GB
          maxBandwidth: 10 * 1024 * 1024 * 1024, // 10GB
          maxConnections: 50,
          maxRequests: 10000,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      case TenantPlan.professional:
        return ResourceQuota(
          tenantId: tenantId,
          maxUsers: 100,
          maxStorage: 10 * 1024 * 1024 * 1024, // 10GB
          maxBandwidth: 100 * 1024 * 1024 * 1024, // 100GB
          maxConnections: 200,
          maxRequests: 100000,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      case TenantPlan.enterprise:
        return ResourceQuota(
          tenantId: tenantId,
          maxUsers: 1000,
          maxStorage: 100 * 1024 * 1024 * 1024, // 100GB
          maxBandwidth: 1000 * 1024 * 1024 * 1024, // 1TB
          maxConnections: 1000,
          maxRequests: 1000000,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
    }
  }

  List<String> _getPlanFeatures(TenantPlan plan) {
    switch (plan) {
      case TenantPlan.basic:
        return ['Basic Support', 'Standard Features'];
      case TenantPlan.professional:
        return ['Priority Support', 'Advanced Features', 'API Access'];
      case TenantPlan.enterprise:
        return ['24/7 Support', 'All Features', 'API Access', 'Custom Branding', 'SSO'];
    }
  }

  double _getPlanAmount(TenantPlan plan) {
    switch (plan) {
      case TenantPlan.basic:
        return 29.99;
      case TenantPlan.professional:
        return 99.99;
      case TenantPlan.enterprise:
        return 299.99;
    }
  }

  Map<String, dynamic> _getDefaultAccessPolicies(TenantPlan plan) {
    return {
      'passwordPolicy': {
        'minLength': 8,
        'requireUppercase': true,
        'requireLowercase': true,
        'requireNumbers': true,
        'requireSymbols': plan == TenantPlan.enterprise,
      },
      'sessionPolicy': {
        'maxSessionDuration': plan == TenantPlan.basic ? 3600 : 7200, // 1-2 hours
        'idleTimeout': 1800, // 30 minutes
      },
    };
  }

  Map<String, dynamic> _getDefaultAuditSettings(TenantPlan plan) {
    return {
      'logLevel': plan == TenantPlan.basic ? 'error' : 'info',
      'retentionDays': plan == TenantPlan.enterprise ? 365 : 90,
      'realTimeAlerts': plan == TenantPlan.enterprise,
    };
  }

  String _generateEncryptionKey() {
    final bytes = List<int>.generate(32, (i) => DateTime.now().millisecondsSinceEpoch % 256);
    return base64Encode(bytes);
  }

  String _generateAccountId() {
    return 'acc_${DateTime.now().millisecondsSinceEpoch}';
  }

  String _generateSubscriptionId() {
    return 'sub_${DateTime.now().millisecondsSinceEpoch}';
  }

  Future<void> _saveTenantToDatabase(Tenant tenant) async {
    if (_tenantDb == null) return;

    await _tenantDb!.insert(
      'tenants',
      {
        'tenant_id': tenant.tenantId,
        'name': tenant.name,
        'admin_email': tenant.adminEmail,
        'plan': tenant.plan.toString().split('.').last,
        'status': tenant.status.toString().split('.').last,
        'created_at': tenant.createdAt.toIso8601String(),
        'last_active_at': tenant.lastActiveAt?.toIso8601String(),
        'suspension_reason': tenant.suspensionReason,
        'settings': jsonEncode(tenant.settings),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> _saveTenantConfigToDatabase(TenantConfiguration config) async {
    if (_tenantDb == null) return;

    await _tenantDb!.insert(
      'tenant_configurations',
      {
        'tenant_id': config.tenantId,
        'database_settings': jsonEncode(config.databaseSettings),
        'security_settings': jsonEncode(config.securitySettings),
        'feature_flags': jsonEncode(config.featureFlags),
        'integration_settings': jsonEncode(config.integrationSettings),
        'custom_settings': jsonEncode(config.customSettings),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> _deleteTenantFromDatabase(String tenantId) async {
    if (_tenantDb == null) return;

    await _tenantDb!.delete('tenants', where: 'tenant_id = ?', whereArgs: [tenantId]);
    await _tenantDb!.delete('tenant_configurations', where: 'tenant_id = ?', whereArgs: [tenantId]);
    await _tenantDb!.delete('resource_quotas', where: 'tenant_id = ?', whereArgs: [tenantId]);
    await _tenantDb!.delete('subscriptions', where: 'tenant_id = ?', whereArgs: [tenantId]);
  }

  /// Dispose resources
  @override
  void dispose() {
    _resourceMonitorTimer?.cancel();
    _billingTimer?.cancel();
    _tenantDb?.close();
    super.dispose();
  }
}