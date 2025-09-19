class TenantCustomizationResult {
  final bool success;
  final String tenantId;
  final TenantCustomization? customization;
  final String? error;

  TenantCustomizationResult({
    required this.success,
    required this.tenantId,
    this.customization,
    this.error,
  });

  Map<String, dynamic> toMap() {
    return {
      'success': success,
      'tenantId': tenantId,
      'customization': customization?.toMap(),
      'error': error,
    };
  }

  factory TenantCustomizationResult.success(String tenantId, TenantCustomization customization) {
    return TenantCustomizationResult(
      success: true,
      tenantId: tenantId,
      customization: customization,
    );
  }

  factory TenantCustomizationResult.failure(String tenantId, String error) {
    return TenantCustomizationResult(
      success: false,
      tenantId: tenantId,
      error: error,
    );
  }

  factory TenantCustomizationResult.fromMap(Map<String, dynamic> map) {
    return TenantCustomizationResult(
      success: map['success'],
      tenantId: map['tenantId'],
      customization: map['customization'] != null ? TenantCustomization.fromMap(map['customization']) : null,
      error: map['error'],
    );
  }
}

class TenantCustomization {
  final String tenantId;
  TenantBranding branding;
  TenantLocalization localization;
  final Map<String, dynamic> uiCustomizations;

  TenantCustomization({
    required this.tenantId,
    required this.branding,
    required this.localization,
    required this.uiCustomizations,
  });

  Map<String, dynamic> toMap() {
    return {
      'tenantId': tenantId,
      'branding': branding.toMap(),
      'localization': localization.toMap(),
      'uiCustomizations': uiCustomizations,
    };
  }

  factory TenantCustomization.fromMap(Map<String, dynamic> map) {
    return TenantCustomization(
      tenantId: map['tenantId'],
      branding: TenantBranding.fromMap(map['branding']),
      localization: TenantLocalization.fromMap(map['localization']),
      uiCustomizations: Map<String, dynamic>.from(map['uiCustomizations']),
    );
  }
}

class TenantBranding {
  String primaryColor;
  String secondaryColor;
  String? logo;
  String? favicon;
  String? customCss;

  TenantBranding({
    required this.primaryColor,
    required this.secondaryColor,
    this.logo,
    this.favicon,
    this.customCss,
  });

  Map<String, dynamic> toMap() {
    return {
      'primaryColor': primaryColor,
      'secondaryColor': secondaryColor,
      'logo': logo,
      'favicon': favicon,
      'customCss': customCss,
    };
  }

  factory TenantBranding.fromMap(Map<String, dynamic> map) {
    return TenantBranding(
      primaryColor: map['primaryColor'],
      secondaryColor: map['secondaryColor'],
      logo: map['logo'],
      favicon: map['favicon'],
      customCss: map['customCss'],
    );
  }
}

class TenantLocalization {
  String defaultLanguage;
  List<String> supportedLanguages;
  Map<String, Map<String, String>> customTranslations;

  TenantLocalization({
    required this.defaultLanguage,
    required this.supportedLanguages,
    required this.customTranslations,
  });

  Map<String, dynamic> toMap() {
    return {
      'defaultLanguage': defaultLanguage,
      'supportedLanguages': supportedLanguages,
      'customTranslations': customTranslations,
    };
  }

  factory TenantLocalization.fromMap(Map<String, dynamic> map) {
    return TenantLocalization(
      defaultLanguage: map['defaultLanguage'],
      supportedLanguages: List<String>.from(map['supportedLanguages']),
      customTranslations: Map<String, Map<String, String>>.from(
        map['customTranslations'].map((key, value) => MapEntry(key, Map<String, String>.from(value))),
      ),
    );
  }
}