import 'package:flutter/material.dart';
import 'package:medrefer_ai/core/app_export.dart';
import 'package:medrefer_ai/services/enterprise_user_management_service.dart';
import 'package:medrefer_ai/database/models/user_management_models.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({Key? key}) : super(key: key);

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen>
    with TickerProviderStateMixin {
  late EnterpriseUserManagementService _userManagementService;
  late TabController _tabController;
  
  List<EnterpriseUser> _users = [];
  List<UserGroup> _userGroups = [];
  List<Role> _roles = [];
  List<Department> _departments = [];
  List<Organization> _organizations = [];
  
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedRole = 'all';
  String _selectedDepartment = 'all';
  String _selectedStatus = 'all';

  @override
  void initState() {
    super.initState();
    _userManagementService = EnterpriseUserManagementService();
    _tabController = TabController(length: 5, vsync: this);
    _initializeScreen();
  }

  Future<void> _initializeScreen() async {
    try {
      await _userManagementService.initialize();
      await _loadData();
      _userManagementService.addListener(_onUserManagementUpdate);
    } catch (e) {
      debugPrint('Error initializing user management screen: $e');
    }
  }

  void _onUserManagementUpdate() {
    _loadUsers();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      await Future.wait([
        _loadUsers(),
        _loadUserGroups(),
        _loadRoles(),
        _loadDepartments(),
        _loadOrganizations(),
      ]);
    } catch (e) {
      debugPrint('Error loading data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadUsers() async {
    final users = _userManagementService.getAllUsers();
    setState(() => _users = users);
  }

  Future<void> _loadUserGroups() async {
    final groups = _userManagementService.getAllUserGroups();
    setState(() => _userGroups = groups);
  }

  Future<void> _loadRoles() async {
    final roles = _userManagementService.getAllRoles();
    setState(() => _roles = roles);
  }

  Future<void> _loadDepartments() async {
    final departments = _userManagementService.getAllDepartments();
    setState(() => _departments = departments);
  }

  Future<void> _loadOrganizations() async {
    final organizations = _userManagementService.getAllOrganizations();
    setState(() => _organizations = organizations);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstant.gray50,
      appBar: AppBar(
        title: Text(
          'User Management',
          style: AppStyle.txtInterBold24,
        ),
        backgroundColor: ColorConstant.whiteA700,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadData,
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert),
            onSelected: _onMenuSelected,
            itemBuilder: (context) => [
              PopupMenuItem(value: 'export', child: Text('Export Users')),
              PopupMenuItem(value: 'bulk_import', child: Text('Bulk Import')),
              PopupMenuItem(value: 'statistics', child: Text('View Statistics')),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: [
            Tab(text: 'Users', icon: Icon(Icons.people)),
            Tab(text: 'Groups', icon: Icon(Icons.group)),
            Tab(text: 'Roles', icon: Icon(Icons.admin_panel_settings)),
            Tab(text: 'Departments', icon: Icon(Icons.business)),
            Tab(text: 'Organizations', icon: Icon(Icons.account_balance)),
          ],
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildUsersTab(),
                _buildGroupsTab(),
                _buildRolesTab(),
                _buildDepartmentsTab(),
                _buildOrganizationsTab(),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateUserDialog,
        child: Icon(Icons.person_add),
        backgroundColor: ColorConstant.blue600,
      ),
    );
  }

  Widget _buildUsersTab() {
    final filteredUsers = _getFilteredUsers();

    return Column(
      children: [
        _buildUserFilters(),
        Expanded(
          child: filteredUsers.isEmpty
              ? _buildEmptyState('No users found')
              : ListView.builder(
                  padding: EdgeInsets.all(16.w),
                  itemCount: filteredUsers.length,
                  itemBuilder: (context, index) {
                    final user = filteredUsers[index];
                    return _buildUserCard(user);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildUserFilters() {
    return Container(
      padding: EdgeInsets.all(16.w),
      color: ColorConstant.whiteA700,
      child: Column(
        children: [
          // Search bar
          TextField(
            decoration: InputDecoration(
              hintText: 'Search users...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            ),
            onChanged: (value) {
              setState(() => _searchQuery = value);
            },
          ),
          SizedBox(height: 16.h),
          // Filter dropdowns
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedRole,
                  decoration: InputDecoration(
                    labelText: 'Role',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                  ),
                  items: [
                    DropdownMenuItem(value: 'all', child: Text('All Roles')),
                    ..._roles.map((role) => DropdownMenuItem(
                      value: role.name,
                      child: Text(role.name),
                    )),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedRole = value ?? 'all');
                  },
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedDepartment,
                  decoration: InputDecoration(
                    labelText: 'Department',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                  ),
                  items: [
                    DropdownMenuItem(value: 'all', child: Text('All Departments')),
                    ..._departments.map((dept) => DropdownMenuItem(
                      value: dept.id,
                      child: Text(dept.name),
                    )),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedDepartment = value ?? 'all');
                  },
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedStatus,
                  decoration: InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                  ),
                  items: [
                    DropdownMenuItem(value: 'all', child: Text('All Status')),
                    DropdownMenuItem(value: 'active', child: Text('Active')),
                    DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedStatus = value ?? 'all');
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(EnterpriseUser user) {
    final department = _departments.firstWhere(
      (d) => d.id == user.departmentId,
      orElse: () => Department(
        id: '',
        name: 'No Department',
        description: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );

    return Card(
      margin: EdgeInsets.only(bottom: 16.h),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: ColorConstant.blue600,
          child: Text(
            user.firstName[0].toUpperCase(),
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          user.fullName,
          style: AppStyle.txtInterMedium14.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              user.email,
              style: AppStyle.txtInterRegular12,
            ),
            SizedBox(height: 4.h),
            Row(
              children: [
                _buildRoleChip(user.role),
                SizedBox(width: 8.w),
                _buildDepartmentChip(department.name),
                SizedBox(width: 8.w),
                _buildStatusChip(user.isActive),
              ],
            ),
            if (user.jobTitle != null) ...[
              SizedBox(height: 4.h),
              Text(
                user.jobTitle!,
                style: AppStyle.txtInterRegular12.copyWith(
                  color: ColorConstant.gray600,
                ),
              ),
            ],
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _onUserAction(value, user),
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit),
                  SizedBox(width: 8.w),
                  Text('Edit'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'permissions',
              child: Row(
                children: [
                  Icon(Icons.security),
                  SizedBox(width: 8.w),
                  Text('Permissions'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'groups',
              child: Row(
                children: [
                  Icon(Icons.group),
                  SizedBox(width: 8.w),
                  Text('Groups'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'toggle_status',
              child: Row(
                children: [
                  Icon(user.isActive ? Icons.person_off : Icons.person),
                  SizedBox(width: 8.w),
                  Text(user.isActive ? 'Deactivate' : 'Activate'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8.w),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
        onTap: () => _showUserDetails(user),
      ),
    );
  }

  Widget _buildRoleChip(String role) {
    Color color;
    switch (role.toLowerCase()) {
      case 'super admin':
        color = Colors.red;
        break;
      case 'admin':
        color = Colors.orange;
        break;
      case 'doctor':
        color = Colors.green;
        break;
      case 'nurse':
        color = Colors.blue;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        role,
        style: AppStyle.txtInterBold10.copyWith(color: color),
      ),
    );
  }

  Widget _buildDepartmentChip(String department) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: ColorConstant.blue600.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: ColorConstant.blue600.withOpacity(0.3)),
      ),
      child: Text(
        department,
        style: AppStyle.txtInterBold10.copyWith(color: ColorConstant.blue600),
      ),
    );
  }

  Widget _buildStatusChip(bool isActive) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: (isActive ? Colors.green : Colors.red).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: (isActive ? Colors.green : Colors.red).withOpacity(0.3)),
      ),
      child: Text(
        isActive ? 'ACTIVE' : 'INACTIVE',
        style: AppStyle.txtInterBold10.copyWith(
          color: isActive ? Colors.green : Colors.red,
        ),
      ),
    );
  }

  Widget _buildGroupsTab() {
    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: _userGroups.length,
      itemBuilder: (context, index) {
        final group = _userGroups[index];
        return _buildGroupCard(group);
      },
    );
  }

  Widget _buildGroupCard(UserGroup group) {
    final department = _departments.firstWhere(
      (d) => d.id == group.departmentId,
      orElse: () => Department(
        id: '',
        name: 'No Department',
        description: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );

    return Card(
      margin: EdgeInsets.only(bottom: 16.h),
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: Color(group.color).withOpacity(0.1),
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Icon(
            _getIconData(group.icon),
            color: Color(int.parse(group.color.replaceFirst('#', '0xff'))),
          ),
        ),
        title: Text(
          group.name,
          style: AppStyle.txtInterMedium14.copyWith(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              group.description,
              style: AppStyle.txtInterRegular12,
            ),
            SizedBox(height: 4.h),
            Row(
              children: [
                Text(
                  'Department: ',
                  style: AppStyle.txtInterRegular10.copyWith(
                    color: ColorConstant.gray500,
                  ),
                ),
                Text(
                  department.name,
                  style: AppStyle.txtInterBold10,
                ),
                Spacer(),
                Text(
                  '${group.memberIds.length} members',
                  style: AppStyle.txtInterRegular10.copyWith(
                    color: ColorConstant.gray500,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _onGroupAction(value, group),
          itemBuilder: (context) => [
            PopupMenuItem(value: 'edit', child: Text('Edit')),
            PopupMenuItem(value: 'members', child: Text('Manage Members')),
            PopupMenuItem(value: 'permissions', child: Text('Permissions')),
            PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
        onTap: () => _showGroupDetails(group),
      ),
    );
  }

  Widget _buildRolesTab() {
    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: _roles.length,
      itemBuilder: (context, index) {
        final role = _roles[index];
        return _buildRoleCard(role);
      },
    );
  }

  Widget _buildRoleCard(Role role) {
    return Card(
      margin: EdgeInsets.only(bottom: 16.h),
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: Color(role.color).withOpacity(0.1),
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Icon(
            Icons.admin_panel_settings,
            color: Color(int.parse(role.color.replaceFirst('#', '0xff'))),
          ),
        ),
        title: Text(
          role.name,
          style: AppStyle.txtInterMedium14.copyWith(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              role.description,
              style: AppStyle.txtInterRegular12,
            ),
            SizedBox(height: 4.h),
            Row(
              children: [
                Text(
                  'Level: ',
                  style: AppStyle.txtInterRegular10.copyWith(
                    color: ColorConstant.gray500,
                  ),
                ),
                Text(
                  role.level.toString(),
                  style: AppStyle.txtInterBold10,
                ),
                Spacer(),
                Text(
                  '${role.permissions.length} permissions',
                  style: AppStyle.txtInterRegular10.copyWith(
                    color: ColorConstant.gray500,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _onRoleAction(value, role),
          itemBuilder: (context) => [
            PopupMenuItem(value: 'edit', child: Text('Edit')),
            PopupMenuItem(value: 'permissions', child: Text('Manage Permissions')),
            PopupMenuItem(value: 'users', child: Text('View Users')),
            PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
        onTap: () => _showRoleDetails(role),
      ),
    );
  }

  Widget _buildDepartmentsTab() {
    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: _departments.length,
      itemBuilder: (context, index) {
        final department = _departments[index];
        return _buildDepartmentCard(department);
      },
    );
  }

  Widget _buildDepartmentCard(Department department) {
    final userCount = _users.where((u) => u.departmentId == department.id).length;

    return Card(
      margin: EdgeInsets.only(bottom: 16.h),
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: Color(department.color).withOpacity(0.1),
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Icon(
            _getIconData(department.icon),
            color: Color(int.parse(department.color.replaceFirst('#', '0xff'))),
          ),
        ),
        title: Text(
          department.name,
          style: AppStyle.txtInterMedium14.copyWith(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              department.description,
              style: AppStyle.txtInterRegular12,
            ),
            SizedBox(height: 4.h),
            Row(
              children: [
                Text(
                  'Users: ',
                  style: AppStyle.txtInterRegular10.copyWith(
                    color: ColorConstant.gray500,
                  ),
                ),
                Text(
                  userCount.toString(),
                  style: AppStyle.txtInterBold10,
                ),
                Spacer(),
                Text(
                  department.isActive ? 'ACTIVE' : 'INACTIVE',
                  style: AppStyle.txtInterBold10.copyWith(
                    color: department.isActive ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _onDepartmentAction(value, department),
          itemBuilder: (context) => [
            PopupMenuItem(value: 'edit', child: Text('Edit')),
            PopupMenuItem(value: 'users', child: Text('View Users')),
            PopupMenuItem(value: 'structure', child: Text('Department Structure')),
            PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
        onTap: () => _showDepartmentDetails(department),
      ),
    );
  }

  Widget _buildOrganizationsTab() {
    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: _organizations.length,
      itemBuilder: (context, index) {
        final organization = _organizations[index];
        return _buildOrganizationCard(organization);
      },
    );
  }

  Widget _buildOrganizationCard(Organization organization) {
    final userCount = _users.where((u) => u.organizationId == organization.id).length;

    return Card(
      margin: EdgeInsets.only(bottom: 16.h),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: ColorConstant.blue600,
          child: Text(
            organization.name[0].toUpperCase(),
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          organization.name,
          style: AppStyle.txtInterMedium14.copyWith(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              organization.description,
              style: AppStyle.txtInterRegular12,
            ),
            SizedBox(height: 4.h),
            Row(
              children: [
                if (organization.email != null) ...[
                  Icon(Icons.email, size: 12),
                  SizedBox(width: 4.w),
                  Text(
                    organization.email!,
                    style: AppStyle.txtInterRegular10,
                  ),
                  SizedBox(width: 16.w),
                ],
                Text(
                  '$userCount users',
                  style: AppStyle.txtInterRegular10.copyWith(
                    color: ColorConstant.gray500,
                  ),
                ),
                Spacer(),
                Text(
                  organization.isActive ? 'ACTIVE' : 'INACTIVE',
                  style: AppStyle.txtInterBold10.copyWith(
                    color: organization.isActive ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _onOrganizationAction(value, organization),
          itemBuilder: (context) => [
            PopupMenuItem(value: 'edit', child: Text('Edit')),
            PopupMenuItem(value: 'settings', child: Text('Settings')),
            PopupMenuItem(value: 'departments', child: Text('Departments')),
            PopupMenuItem(value: 'users', child: Text('View Users')),
          ],
        ),
        onTap: () => _showOrganizationDetails(organization),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 64, color: ColorConstant.gray400),
          SizedBox(height: 16.h),
          Text(
            message,
            style: AppStyle.txtInterBold18.copyWith(color: ColorConstant.gray400),
          ),
        ],
      ),
    );
  }

  List<EnterpriseUser> _getFilteredUsers() {
    List<EnterpriseUser> filtered = _users;

    // Search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((user) {
        return user.firstName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               user.lastName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               user.email.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               user.jobTitle?.toLowerCase().contains(_searchQuery.toLowerCase()) == true;
      }).toList();
    }

    // Role filter
    if (_selectedRole != 'all') {
      filtered = filtered.where((user) => user.role == _selectedRole).toList();
    }

    // Department filter
    if (_selectedDepartment != 'all') {
      filtered = filtered.where((user) => user.departmentId == _selectedDepartment).toList();
    }

    // Status filter
    if (_selectedStatus != 'all') {
      final isActive = _selectedStatus == 'active';
      filtered = filtered.where((user) => user.isActive == isActive).toList();
    }

    return filtered;
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'favorite':
        return Icons.favorite;
      case 'psychology':
        return Icons.psychology;
      case 'local_hospital':
        return Icons.local_hospital;
      case 'computer':
        return Icons.computer;
      case 'medical_services':
        return Icons.medical_services;
      case 'emergency':
        return Icons.emergency;
      case 'support_agent':
        return Icons.support_agent;
      default:
        return Icons.group;
    }
  }

  void _showCreateUserDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Create New User'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: InputDecoration(labelText: 'First Name'),
              ),
              TextField(
                decoration: InputDecoration(labelText: 'Last Name'),
              ),
              TextField(
                decoration: InputDecoration(labelText: 'Email'),
              ),
              TextField(
                decoration: InputDecoration(labelText: 'Phone Number'),
              ),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(labelText: 'Role'),
                items: _roles.map((role) => DropdownMenuItem(
                  value: role.name,
                  child: Text(role.name),
                )).toList(),
                onChanged: (value) {},
              ),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(labelText: 'Department'),
                items: _departments.map((dept) => DropdownMenuItem(
                  value: dept.id,
                  child: Text(dept.name),
                )).toList(),
                onChanged: (value) {},
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Implement user creation
              Navigator.pop(context);
            },
            child: Text('Create'),
          ),
        ],
      ),
    );
  }

  void _onUserAction(String action, EnterpriseUser user) {
    switch (action) {
      case 'edit':
        _showEditUserDialog(user);
        break;
      case 'permissions':
        _showUserPermissions(user);
        break;
      case 'groups':
        _showUserGroups(user);
        break;
      case 'toggle_status':
        _userManagementService.toggleUserStatus(user.id);
        break;
      case 'delete':
        _showDeleteUserDialog(user);
        break;
    }
  }

  void _onGroupAction(String action, UserGroup group) {
    // Implement group actions
  }

  void _onRoleAction(String action, Role role) {
    // Implement role actions
  }

  void _onDepartmentAction(String action, Department department) {
    // Implement department actions
  }

  void _onOrganizationAction(String action, Organization organization) {
    // Implement organization actions
  }

  void _onMenuSelected(String value) {
    switch (value) {
      case 'export':
        // Implement export functionality
        break;
      case 'bulk_import':
        // Implement bulk import functionality
        break;
      case 'statistics':
        _showStatisticsDialog();
        break;
    }
  }

  void _showUserDetails(EnterpriseUser user) {
    // Implement user details view
  }

  void _showGroupDetails(UserGroup group) {
    // Implement group details view
  }

  void _showRoleDetails(Role role) {
    // Implement role details view
  }

  void _showDepartmentDetails(Department department) {
    // Implement department details view
  }

  void _showOrganizationDetails(Organization organization) {
    // Implement organization details view
  }

  void _showEditUserDialog(EnterpriseUser user) {
    // Implement edit user dialog
  }

  void _showUserPermissions(EnterpriseUser user) {
    // Implement user permissions view
  }

  void _showUserGroups(EnterpriseUser user) {
    // Implement user groups view
  }

  void _showDeleteUserDialog(EnterpriseUser user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete User'),
        content: Text('Are you sure you want to delete ${user.fullName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _userManagementService.deleteUser(user.id);
              Navigator.pop(context);
            },
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showStatisticsDialog() {
    final stats = _userManagementService.getUserStatistics();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('User Statistics'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildStatRow('Total Users', stats['total_users'].toString()),
              _buildStatRow('Active Users', stats['active_users'].toString()),
              _buildStatRow('Inactive Users', stats['inactive_users'].toString()),
              _buildStatRow('Total Groups', stats['total_groups'].toString()),
              _buildStatRow('Total Departments', stats['total_departments'].toString()),
              _buildStatRow('Total Organizations', stats['total_organizations'].toString()),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppStyle.txtInterMedium14),
          Text(value, style: AppStyle.txtInterBold14.copyWith(color: ColorConstant.blue600)),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _userManagementService.removeListener(_onUserManagementUpdate);
    _tabController.dispose();
    super.dispose();
  }
}