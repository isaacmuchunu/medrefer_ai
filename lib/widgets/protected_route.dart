import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_export.dart';
import '../services/route_guard_service.dart';
import '../services/rbac_service.dart';
import '../services/auth_service.dart';

/// Protected Route Widget that checks permissions before rendering content
class ProtectedRoute extends StatelessWidget {
  final Widget child;
  final String? requiredPermission;
  final List<Permission>? requiredPermissions;
  final UserRole? requiredRole;
  final List<UserRole>? requiredRoles;
  final String? feature;
  final Widget? fallbackWidget;
  final bool showUnauthorizedMessage;

  const ProtectedRoute({
    Key? key,
    required this.child,
    this.requiredPermission,
    this.requiredPermissions,
    this.requiredRole,
    this.requiredRoles,
    this.feature,
    this.fallbackWidget,
    this.showUnauthorizedMessage = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer3<AuthService, RBACService, RouteGuardService>(
      builder: (context, authService, rbacService, routeGuard, child) {
        // Check authentication first
        if (!authService.isAuthenticated) {
          return _buildUnauthorizedWidget(
            context,
            'Authentication Required',
            'Please log in to access this feature.',
            Icons.login,
          );
        }

        // Check specific permission
        if (requiredPermission != null) {
          final permission = _getPermissionFromString(requiredPermission!);
          if (permission != null && !rbacService.hasPermission(permission)) {
            return _buildUnauthorizedWidget(
              context,
              'Access Denied',
              'You don\'t have permission to access this feature.',
              Icons.block,
            );
          }
        }

        // Check multiple permissions (user must have ALL)
        if (requiredPermissions != null && requiredPermissions!.isNotEmpty) {
          if (!rbacService.hasAllPermissions(requiredPermissions!)) {
            return _buildUnauthorizedWidget(
              context,
              'Access Denied',
              'You don\'t have the required permissions to access this feature.',
              Icons.block,
            );
          }
        }

        // Check specific role
        if (requiredRole != null) {
          if (!rbacService.hasRole(requiredRole!)) {
            return _buildUnauthorizedWidget(
              context,
              'Access Denied',
              'This feature is only available to ${_getRoleDisplayName(requiredRole!)}s.',
              Icons.person_off,
            );
          }
        }

        // Check multiple roles (user must have ANY)
        if (requiredRoles != null && requiredRoles!.isNotEmpty) {
          if (!rbacService.hasAnyRole(requiredRoles!)) {
            final roleNames = requiredRoles!.map(_getRoleDisplayName).join(', ');
            return _buildUnauthorizedWidget(
              context,
              'Access Denied',
              'This feature is only available to: $roleNames.',
              Icons.person_off,
            );
          }
        }

        // Check feature access
        if (feature != null) {
          if (!rbacService.canAccess(feature!)) {
            return _buildUnauthorizedWidget(
              context,
              'Feature Unavailable',
              'This feature is not available for your account type.',
              Icons.disabled_by_default,
            );
          }
        }

        // All checks passed, render the child
        return this.child;
      },
    );
  }

  Widget _buildUnauthorizedWidget(
    BuildContext context,
    String title,
    String message,
    IconData icon,
  ) {
    if (fallbackWidget != null) {
      return fallbackWidget!;
    }

    if (!showUnauthorizedMessage) {
      return SizedBox.shrink();
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Access Denied'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(4.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 80.sp,
                color: Colors.red[300],
              ),
              SizedBox(height: 3.h),
              Text(
                title,
                style: TextStyle(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryLight,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 2.h),
              Text(
                message,
                style: TextStyle(
                  fontSize: 16.sp,
                  color: AppTheme.textSecondaryLight,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 4.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[600],
                      foregroundColor: Colors.white,
                    ),
                    child: Text('Go Back'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pushNamedAndRemoveUntil(
                      context,
                      AppRoutes.dashboard,
                      (route) => false,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryLight,
                      foregroundColor: Colors.white,
                    ),
                    child: Text('Dashboard'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Permission? _getPermissionFromString(String permissionString) {
    try {
      return Permission.values.firstWhere(
        (p) => p.name == permissionString,
      );
    } catch (e) {
      return null;
    }
  }

  String _getRoleDisplayName(UserRole role) {
    switch (role) {
      case UserRole.patient:
        return 'Patient';
      case UserRole.doctor:
        return 'Doctor';
      case UserRole.specialist:
        return 'Specialist';
      case UserRole.nurse:
        return 'Nurse';
      case UserRole.pharmacist:
        return 'Pharmacist';
      case UserRole.admin:
        return 'Administrator';
      case UserRole.superAdmin:
        return 'Super Administrator';
    }
  }
}

/// Permission-based widget that shows/hides content based on permissions
class PermissionWidget extends StatelessWidget {
  final Widget child;
  final Permission? permission;
  final List<Permission>? permissions;
  final UserRole? role;
  final List<UserRole>? roles;
  final String? feature;
  final Widget? fallback;

  const PermissionWidget({
    Key? key,
    required this.child,
    this.permission,
    this.permissions,
    this.role,
    this.roles,
    this.feature,
    this.fallback,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<RBACService>(
      builder: (context, rbacService, child) {
        bool hasAccess = true;

        // Check specific permission
        if (permission != null) {
          hasAccess = hasAccess && rbacService.hasPermission(permission!);
        }

        // Check multiple permissions (must have ALL)
        if (permissions != null && permissions!.isNotEmpty) {
          hasAccess = hasAccess && rbacService.hasAllPermissions(permissions!);
        }

        // Check specific role
        if (role != null) {
          hasAccess = hasAccess && rbacService.hasRole(role!);
        }

        // Check multiple roles (must have ANY)
        if (roles != null && roles!.isNotEmpty) {
          hasAccess = hasAccess && rbacService.hasAnyRole(roles!);
        }

        // Check feature access
        if (feature != null) {
          hasAccess = hasAccess && rbacService.canAccess(feature!);
        }

        if (hasAccess) {
          return this.child;
        } else {
          return fallback ?? SizedBox.shrink();
        }
      },
    );
  }
}

/// Role-based navigation drawer
class RoleBasedDrawer extends StatelessWidget {
  const RoleBasedDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthService, RouteGuardService>(
      builder: (context, authService, routeGuard, child) {
        final navigationItems = routeGuard.getAvailableNavigationItems();
        final currentUserRole = routeGuard.getCurrentUserRole();

        return Drawer(
          child: Column(
            children: [
              // Drawer Header
              DrawerHeader(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primaryLight, AppTheme.primaryVariantLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.person,
                        size: 30,
                        color: AppTheme.primaryLight,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      authService.currentUser?.firstName ?? 'User',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      currentUserRole,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14.sp,
                      ),
                    ),
                  ],
                ),
              ),

              // Navigation Items
              Expanded(
                child: ListView.builder(
                  itemCount: navigationItems.length,
                  itemBuilder: (context, index) {
                    final item = navigationItems[index];
                    return ListTile(
                      leading: Icon(item.icon),
                      title: Text(item.title),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, item.route);
                      },
                    );
                  },
                ),
              ),

              // Logout
              Divider(),
              ListTile(
                leading: Icon(Icons.logout, color: Colors.red),
                title: Text(
                  'Logout',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  await authService.logout();
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    AppRoutes.loginScreen,
                    (route) => false,
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
