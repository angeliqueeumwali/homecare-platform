import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:mobile/providers/auth_provider.dart';
import 'package:mobile/providers/provider_viewmodel.dart';
import 'package:mobile/screens/customer/customer_dashboard.dart';
import 'package:mobile/screens/customer/notification_screen.dart';
import 'package:mobile/screens/customer/profile_screen.dart';
import 'package:mobile/screens/customer/request_history_screen.dart';
import 'package:mobile/screens/provider/provider_assignments_screen.dart';
import 'package:mobile/screens/provider/provider_dashboard.dart';
import 'package:mobile/screens/provider/provider_notification_screen.dart';
import 'package:mobile/screens/provider/provider_profile_screen.dart';
import 'package:mobile/theme/colors.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  /// Customer tabs: Home, Requests, Notifications, Profile.
  final List<BottomNavigationBarItem> _customerItems = [
    const BottomNavigationBarItem(
      icon: Icon(Icons.home_outlined),
      activeIcon: Icon(Icons.home),
      label: 'Home',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.assignment_outlined),
      activeIcon: Icon(Icons.assignment),
      label: 'Requests',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.notifications_outlined),
      activeIcon: Icon(Icons.notifications),
      label: 'Notifications',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.person_outlined),
      activeIcon: Icon(Icons.person),
      label: 'Profile',
    ),
  ];

  /// Provider tabs: Home, Assignments, Notifications, Profile.
  final List<BottomNavigationBarItem> _providerItems = [
    const BottomNavigationBarItem(
      icon: Icon(Icons.dashboard_outlined),
      activeIcon: Icon(Icons.dashboard),
      label: 'Home',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.assignment_outlined),
      activeIcon: Icon(Icons.assignment),
      label: 'Assignments',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.notifications_outlined),
      activeIcon: Icon(Icons.notifications),
      label: 'Notifications',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.person_outlined),
      activeIcon: Icon(Icons.person),
      label: 'Profile',
    ),
  ];

  @override
  void initState() {
    super.initState();
    // Ask the backend whether this account has a provider profile, so the tabs
    // match the real account state instead of guessing from the role alone.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<ProviderViewModel>().refreshAccountState(),
    );
  }

  /// Provider tabs are shown only for an account the backend reports as a
  /// service provider. Accounts are created by an administrator, so the role on
  /// /users/me is the source of truth here.
  bool _useProviderTabs() {
    final user = context.watch<AuthProvider>().user;
    return user?.isProvider ?? false;
  }

  /// Payments and reviews are reached from within the Requests and Profile
  /// screens rather than as their own tabs, so they are not lost.
  List<Widget> _buildPages(bool isProvider) => isProvider
      ? [
          const ProviderDashboardScreen(),
          const ProviderAssignmentsScreen(),
          const ProviderNotificationScreen(),
          const ProviderProfileScreen(),
        ]
      : [
          const CustomerDashboardScreen(),
          ServiceRequestHistoryScreen(),
          const NotificationScreen(),
          ProfileScreen(),
        ];

  @override
  Widget build(BuildContext context) {
    final isProvider = _useProviderTabs();
    final items = isProvider ? _providerItems : _customerItems;

    // Guard against an index left over from a different tab list.
    final index = _currentIndex < items.length ? _currentIndex : 0;

    return Scaffold(
      backgroundColor: AppColors.lightGrey,
      body: IndexedStack(index: index, children: _buildPages(isProvider)),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: index,
        onTap: (value) => setState(() => _currentIndex = value),
        items: items,
        selectedItemColor: AppColors.darkNavyBlue,
        unselectedItemColor: AppColors.secondaryText,
        backgroundColor: AppColors.white,
      ),
    );
  }
}
