import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/api_service.dart';
import '../core/theme.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<dynamic> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    final res = await context.read<ApiService>().getNotifications();
    if (res['success'] == true) {
      if (mounted) setState(() => _notifications = res['data'] ?? []);
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _markAsRead(int id) async {
    final res = await context.read<ApiService>().markNotifRead({'id': id});
    if (res['success'] == true) {
      setState(() {
        final idx = _notifications.indexWhere((n) => n['id'] == id);
        if (idx != -1) _notifications[idx]['is_read'] = 1;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: _isLoading
        ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGold))
        : _notifications.isEmpty
          ? const Center(child: Text('No new notifications', style: TextStyle(color: AppTheme.textDim)))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _notifications.length,
              itemBuilder: (ctx, i) {
                final notif = _notifications[i];
                final isRead = notif['is_read'] == 1 || notif['is_read'] == true;
                
                return Card(
                  color: isRead ? AppTheme.surfaceDarker : AppTheme.surfaceDark,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: isRead ? Colors.transparent : AppTheme.primaryGold.withAlpha(50)),
                  ),
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isRead ? Colors.grey.withAlpha(50) : AppTheme.primaryGold.withAlpha(30),
                      child: Icon(Icons.notifications, color: isRead ? Colors.grey : AppTheme.primaryGold),
                    ),
                    title: Text(notif['title'] ?? 'Notification', style: TextStyle(color: isRead ? AppTheme.textDim : Colors.white, fontWeight: isRead ? FontWeight.normal : FontWeight.bold)),
                    subtitle: Text(notif['message'] ?? '', style: const TextStyle(color: AppTheme.textDim)),
                    onTap: () {
                      if (!isRead) _markAsRead(notif['id']);
                    },
                  ),
                );
              },
            ),
    );
  }
}
