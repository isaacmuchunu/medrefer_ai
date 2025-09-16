import 'package:flutter/material.dart';
import 'rbac_service.dart';
import 'auth_service.dart';
import '../database/models/user.dart';

/// Route Guard Service for protecting routes based on user permissions
class RouteGuardService {
  RouteGuardService._internal();

  final RBACService _rbacService = RBACService();
  final AuthService _authService = AuthService();

  static final RouteGuardService _instance = RouteGuardService._internal();
  factory RouteGuardService() => _instance;

  /// Check if user can access a route
  bool canAccessRoute(String routeName) {
    // Check if user is authenticated
    if (!_authService.isAuthenticated) {
      return _isPublicRoute(routeName);
    }

    // Check route-specific permissions
    switch (routeName) {
      // Public routes (accessible without authentication)
      case '/':
      case '/splash':
      case '/onboarding':
      case '/login':
      case '/register':
      case '/forgot-password':
        return true;

      // Dashboard - all authenticated users
      case '/dashboard':
        return _authService.isAuthenticated;

      // Pharmacy routes
      case '/pharmacy':
        return _rbacService.canAccess('pharmacy');
      case '/drug-detail':
        return _rbacService.canAccess('pharmacy');
      case '/cart':
        return _rbacService.canAccess('pharmacy_purchase');
      case '/checkout':
        return _rbacService.canAccess('pharmacy_purchase');
      case '/mpesa-payment':
        return _rbacService.canAccess('pharmacy_purchase');

      // Patient management routes
      case '/patient-search':
        return _rbacService.canAccess('patient_management');
      case '/patient-profile':
        return _rbacService.canAccess('patient_management') || 
               _rbacService.hasRole(UserRole.patient); // Patients can view their own profile
      case '/patient-selection':
        return _rbacService.canAccess('patient_management');

      // Referral routes
      case '/create-referral':
        return _rbacService.canAccess('referral_creation');
      case '/referral-details':
        return _rbacService.canAccess('referral_management');
      case '/referral-tracking':
        return _rbacService.canAccess('referral_management');

      // Specialist routes
      case '/specialist-directory':
        return _rbacService.hasAnyRole([UserRole.doctor, UserRole.patient, UserRole.nurse]);
      case '/doctor-detail':
        return _rbacService.hasAnyRole([UserRole.doctor, UserRole.patient, UserRole.nurse]);

      // Appointment routes
      case '/appointment-booking':
        return _rbacService.canAccess('appointment_booking');
      case '/appointment-management':
        return _rbacService.canAccess('appointment_management');
      case '/appointment-scheduling':
        return _rbacService.canAccess('appointment_management');

      // Communication routes
      case '/secure-messaging':
        return _rbacService.canAccess('secure_messaging');
      case '/teleconference-call':
        return _rbacService.hasAnyRole([UserRole.doctor, UserRole.specialist, UserRole.patient]);

      // Document routes
      case '/document-viewer':
        return _rbacService.canAccess('document_management');

      // Settings and profile routes
      case '/settings':
        return _authService.isAuthenticated;
      case '/notifications':
        return _authService.isAuthenticated;
      case '/help-support':
        return true; // Help is available to all users
      case '/payment':
        return _authService.isAuthenticated;

      // Admin routes
      case '/admin':
        return _rbacService.hasAnyRole([UserRole.admin, UserRole.superAdmin]);
      case '/user-management':
        return _rbacService.hasAnyRole([UserRole.admin, UserRole.superAdmin]);
      case '/system-settings':
        return _rbacService.hasRole(UserRole.superAdmin);

      // Prescription management (pharmacists and doctors)
      case '/prescription-management':
        return _rbacService.hasAnyRole([UserRole.doctor, UserRole.pharmacist]);

      default:
        // By default, require authentication for unknown routes
        return _authService.isAuthenticated;
    }
  }

  /// Check if a route is public (doesn't require authentication)
  bool _isPublicRoute(String routeName) {
    const publicRoutes = [
      '/',
      '/splash',
      '/onboarding',
      '/login',
      '/register',
      '/forgot-password',
      '/help-support',
      '/error-offline',
    ];
    return publicRoutes.contains(routeName);
  }

  /// Get redirect route for unauthorized access
  String getRedirectRoute(String attemptedRoute) {
    if (!_authService.isAuthenticated) {
      return '/login';
    }

    // If authenticated but no permission, redirect to dashboard
    return '/dashboard';
  }

  /// Check if user can perform action on resource
  bool canPerformAction(String action, String resource, {String? resourceOwnerId}) {
    if (!_authService.isAuthenticated) return false;
    return _rbacService.canPerformAction(action, resource, resourceOwnerId: resourceOwnerId);
  }

  /// Get available navigation items for current user
  List<NavigationItem> getAvailableNavigationItems() {
    final items = <NavigationItem>[];

    // Dashboard - available to all authenticated users
    if (_authService.isAuthenticated) {
      items.add(NavigationItem(
        title: 'Dashboard',
        route: '/dashboard',
        icon: Icons.dashboard,
      ));
    }

    // Patient-specific items
    if (_rbacService.hasRole(UserRole.patient)) {
      items.addAll([
        NavigationItem(
          title: 'Pharmacy',
          route: '/pharmacy',
          icon: Icons.local_pharmacy,
        ),
        NavigationItem(
          title: 'My Profile',
          route: '/patient-profile',
          icon: Icons.person,
        ),
        NavigationItem(
          title: 'Book Appointment',
          route: '/appointment-booking',
          icon: Icons.calendar_today,
        ),
        NavigationItem(
          title: 'Find Doctors',
          route: '/specialist-directory',
          icon: Icons.search,
        ),
      ]);
    }

    // Doctor-specific items
    if (_rbacService.hasRole(UserRole.doctor)) {
      items.addAll([
        NavigationItem(
          title: 'Patients',
          route: '/patient-search',
          icon: Icons.people,
        ),
        NavigationItem(
          title: 'Create Referral',
          route: '/create-referral',
          icon: Icons.send,
        ),
        NavigationItem(
          title: 'Appointments',
          route: '/appointment-management',
          icon: Icons.schedule,
        ),
        NavigationItem(
          title: 'Prescriptions',
          route: '/prescription-management',
          icon: Icons.medication,
        ),
      ]);
    }

    // Specialist-specific items
    if (_rbacService.hasRole(UserRole.specialist)) {
      items.addAll([
        NavigationItem(
          title: 'My Patients',
          route: '/patient-search',
          icon: Icons.people,
        ),
        NavigationItem(
          title: 'Referrals',
          route: '/referral-tracking',
          icon: Icons.assignment,
        ),
        NavigationItem(
          title: 'Appointments',
          route: '/appointment-management',
          icon: Icons.schedule,
        ),
      ]);
    }

    // Pharmacist-specific items
    if (_rbacService.hasRole(UserRole.pharmacist)) {
      items.addAll([
        NavigationItem(
          title: 'Pharmacy Management',
          route: '/pharmacy',
          icon: Icons.local_pharmacy,
        ),
        NavigationItem(
          title: 'Orders',
          route: '/pharmacy-orders',
          icon: Icons.shopping_bag,
        ),
        NavigationItem(
          title: 'Prescriptions',
          route: '/prescription-management',
          icon: Icons.medication,
        ),
      ]);
    }

    // Nurse-specific items
    if (_rbacService.hasRole(UserRole.nurse)) {
      items.addAll([
        NavigationItem(
          title: 'Patients',
          route: '/patient-search',
          icon: Icons.people,
        ),
        NavigationItem(
          title: 'Appointments',
          route: '/appointment-management',
          icon: Icons.schedule,
        ),
      ]);
    }

    // Admin items
    if (_rbacService.hasAnyRole([UserRole.admin, UserRole.superAdmin])) {
      items.addAll([
        NavigationItem(
          title: 'Admin Panel',
          route: '/admin',
          icon: Icons.admin_panel_settings,
        ),
        NavigationItem(
          title: 'User Management',
          route: '/user-management',
          icon: Icons.manage_accounts,
        ),
      ]);
    }

    // Super Admin items
    if (_rbacService.hasRole(UserRole.superAdmin)) {
      items.add(NavigationItem(
        title: 'System Settings',
        route: '/system-settings',
        icon: Icons.settings_applications,
      ));
    }

    // Common items for all authenticated users
    if (_authService.isAuthenticated) {
      items.addAll([
        NavigationItem(
          title: 'Messages',
          route: '/secure-messaging',
          icon: Icons.message,
        ),
        NavigationItem(
          title: 'Documents',
          route: '/document-viewer',
          icon: Icons.folder,
        ),
        NavigationItem(
          title: 'Settings',
          route: '/settings',
          icon: Icons.settings,
        ),
      ]);
    }

    return items;
  }

  /// Check if user can access specific feature
  bool canAccessFeature(String feature) {
    return _rbacService.canAccess(feature);
  }

  /// Get user role display name
  String getCurrentUserRole() {
    if (_rbacService.currentRole != null) {
      return _rbacService.getRoleName(_rbacService.currentRole!);
    }
    return 'Guest';
  }
}

/// Navigation item model
class NavigationItem {
  final String title;
  final String route;
  final IconData icon;
  final List<NavigationItem>? children;

  NavigationItem({
    required this.title,
    required this.route,
    required this.icon,
    this.children,
  });
}
