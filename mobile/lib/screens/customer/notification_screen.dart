import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:mobile/models/notification_model.dart';
import 'package:mobile/providers/provider_viewmodel.dart';
import 'package:mobile/theme/colors.dart';
import 'package:mobile/theme/spacing.dart';
import 'package:mobile/widgets/app_widgets.dart';
import 'package:mobile/widgets/common_widgets.dart';

/// Real notifications from `GET /notifications`, with unread marking via
/// `PATCH /notifications/{id}/read`.
///
/// The backend has no endpoint that generates notifications, so this list is
/// only ever what the API returns. It is never filled with sample data.
class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<NotificationViewModel>().fetchNotifications(),
    );
  }

  Future<void> _markRead(NotificationModel notification) async {
    if (notification.isRead) return;
    final vm = context.read<NotificationViewModel>();
    final updated = await vm.markAsRead(notification.id);
    if (!mounted || updated == null) {
      if (vm.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(vm.errorMessage!),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }

  void _open(NotificationModel notification) {
    _markRead(notification);
    final reference = notification.referenceId;
    if (reference == null) return;

    // The backend does not tell us what each reference points at, so only the
    // types it documents are opened.
    switch (notification.notificationType.toUpperCase()) {
      case 'SERVICE_REQUEST':
        Navigator.pushNamed(context, '/request/$reference');
        break;
      case 'QUOTE':
        Navigator.pushNamed(context, '/quotes/$reference');
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<NotificationViewModel>();

    return Scaffold(
      backgroundColor: AppColors.lightGrey,
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: AppColors.white,
        actions: [
          if (vm.unreadCount > 0)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.md),
              child: Center(child: AppCountBadge(count: vm.unreadCount)),
            ),
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: vm.isLoading ? null : vm.fetchNotifications,
          ),
        ],
      ),
      body: _buildBody(vm),
    );
  }

  Widget _buildBody(NotificationViewModel vm) {
    if (vm.isLoading && vm.notifications.isEmpty) {
      return const AppLoadingIndicator(message: 'Loading notifications');
    }

    if (vm.errorMessage != null && vm.notifications.isEmpty) {
      return ErrorView(
        message: vm.errorMessage!,
        onRetry: vm.fetchNotifications,
      );
    }

    if (vm.notifications.isEmpty) {
      return const EmptyState(
        icon: Icons.notifications_none,
        message:
            'You have no notifications.\n'
            'Updates about your requests, quotes and payments will appear here.',
      );
    }

    return RefreshIndicator(
      onRefresh: vm.fetchNotifications,
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.lg),
        itemCount: vm.notifications.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, index) {
          final notification = vm.notifications[index];
          return _NotificationTile(
            notification: notification,
            onTap: () => _open(notification),
          );
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;

  const _NotificationTile({required this.notification, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isUnread = !notification.isRead;

    return AppCard(
      margin: EdgeInsets.zero,
      onTap: onTap,
      backgroundColor: isUnread ? AppColors.white : AppColors.lightGrey,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isUnread
                  ? AppColors.darkNavyBlue.withValues(alpha: 0.12)
                  : AppColors.borderGrey.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(AppBorderRadius.medium),
            ),
            child: Icon(
              _iconFor(notification.notificationType),
              size: 20,
              color: isUnread
                  ? AppColors.darkNavyBlue
                  : AppColors.secondaryText,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        notification.title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isUnread
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: AppColors.mainText,
                        ),
                      ),
                    ),
                    if (isUnread)
                      const AppCountBadge(
                        count: 1,
                        color: AppColors.darkNavyBlue,
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  notification.message,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.secondaryText,
                    height: 1.35,
                  ),
                ),
                if (notification.createdAt != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    _formatIso(notification.createdAt!),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.secondaryText,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  static IconData _iconFor(String type) {
    switch (type.toUpperCase()) {
      case 'SERVICE_REQUEST':
        return Icons.assignment_outlined;
      case 'ASSIGNMENT':
        return Icons.work_outline;
      case 'QUOTE':
        return Icons.request_quote_outlined;
      case 'PAYMENT':
        return Icons.payments_outlined;
      case 'ISSUE':
        return Icons.report_problem_outlined;
      default:
        return Icons.notifications_none;
    }
  }

  static String _formatIso(String iso) {
    final parsed = DateTime.tryParse(iso);
    if (parsed == null) return iso;
    final local = parsed.toLocal();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${local.year}-${two(local.month)}-${two(local.day)} '
        '${two(local.hour)}:${two(local.minute)}';
  }
}
