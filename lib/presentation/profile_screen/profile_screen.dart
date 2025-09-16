import '../../core/app_export.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
      ),
      body: user == null
          ? const Center(child: Text('No user logged in.'))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                children: [
                  _buildProfileHeader(context, user, theme),
                  const SizedBox(height: 30),
                  _buildProfileMenu(context, authService),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, User user, ThemeData theme) {
    return Column(
      children: [
        CircleAvatar(
          radius: 50,
          backgroundImage: user.profileImageUrl != null
              ? NetworkImage(user.profileImageUrl!)
              : const AssetImage('assets/images/no-image.jpg') as ImageProvider,
          backgroundColor: theme.colorScheme.surface,
        ),
        const SizedBox(height: 15),
        Text(
          user.displayName,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          user.email,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileMenu(BuildContext context, AuthService authService) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          _buildMenuOption(
            context,
            icon: Icons.person_outline,
            title: 'Edit Profile',
            onTap: () {
              Navigator.pushNamed(context, AppRoutes.profileEdit);
            },
          ),
          _buildMenuOption(
            context,
            icon: Icons.history,
            title: 'Appointment History',
            onTap: () {
              Navigator.pushNamed(context, AppRoutes.appointmentHistory);
            },
          ),
          _buildMenuOption(
            context,
            icon: Icons.payment,
            title: 'Billing & Payments',
            onTap: () {
              Navigator.pushNamed(context, AppRoutes.billingPayment);
            },
          ),
          _buildMenuOption(
            context,
            icon: Icons.settings_outlined,
            title: 'Settings',
            onTap: () {
              Navigator.pushNamed(context, AppRoutes.settingsScreen);
            },
          ),
          const Divider(height: 20, thickness: 1),
          _buildMenuOption(
            context,
            icon: Icons.help_outline,
            title: 'Help & Support',
            onTap: () {
              Navigator.pushNamed(context, AppRoutes.helpSupportScreen);
            },
          ),
          _buildMenuOption(
            context,
            icon: Icons.logout,
            title: 'Logout',
            textColor: Theme.of(context).colorScheme.error,
            onTap: () async {
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
  }

  Widget _buildMenuOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? textColor,
  }) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon, color: textColor ?? theme.colorScheme.primary),
      title: Text(
        title,
        style: theme.textTheme.bodyLarge?.copyWith(color: textColor),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: textColor ?? theme.colorScheme.onSurface.withOpacity(0.5),
      ),
      onTap: onTap,
    );
  }
}
