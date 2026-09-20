import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
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
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    final res = await context.read<ApiService>().getNotifications();
    if (res['success'] == true) {
      if (mounted) {
        setState(() {
          _notifications = res['data']?['notifications'] ?? [];
          _unreadCount = res['data']?['unread_count'] ?? 0;
        });
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _markAsRead(int id) async {
    final res = await context.read<ApiService>().markNotifRead({'notification_id': id});
    if (res['success'] == true) {
      setState(() {
        final idx = _notifications.indexWhere((n) => n['id'] == id);
        if (idx != -1 && (_notifications[idx]['is_read'] == 0 || _notifications[idx]['is_read'] == false)) {
          _notifications[idx]['is_read'] = 1;
          if (_unreadCount > 0) _unreadCount--;
        }
      });
    }
  }

  Future<void> _markAllAsRead() async {
    final res = await context.read<ApiService>().markNotifRead({});
    if (res['success'] == true) {
      setState(() {
        for (var notif in _notifications) {
          notif['is_read'] = 1;
        }
        _unreadCount = 0;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All notifications marked as read'),
            backgroundColor: AppTheme.primaryNavy,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  String? _extractImageUrl(String? message, dynamic notif) {
    if (notif['image_url'] != null && notif['image_url'].toString().trim().isNotEmpty) {
      return _formatImageUrl(notif['image_url'].toString().trim());
    }
    if (notif['image'] != null && notif['image'].toString().trim().isNotEmpty) {
      return _formatImageUrl(notif['image'].toString().trim());
    }
    if (message == null) return null;
    final regExp = RegExp(r'\[IMG:(.+?)\]');
    final match = regExp.firstMatch(message);
    if (match != null && match.groupCount >= 1) {
      return _formatImageUrl(match.group(1)!.trim());
    }
    return null;
  }

  String _formatImageUrl(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    String path = url;
    if (path.startsWith('/')) {
      path = path.substring(1);
    }
    if (path.startsWith('backend/')) {
      return 'https://japsanpay.com/$path';
    }
    return 'https://japsanpay.com/backend/$path';
  }

  String _cleanMessage(String? message) {
    if (message == null) return '';
    return message.replaceAll(RegExp(r'\[IMG:.+?\]'), '').trim();
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    try {
      final dt = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(dt);

      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';

      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      final month = months[dt.month - 1];
      final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final ampm = dt.hour >= 12 ? 'PM' : 'AM';
      final min = dt.minute.toString().padLeft(2, '0');
      return '${dt.day} $month, $hour:$min $ampm';
    } catch (_) {
      return dateStr;
    }
  }

  IconData _getTypeIcon(String? type) {
    switch (type) {
      case 'cashback':
        return Icons.card_giftcard;
      case 'referral':
        return Icons.group_add;
      case 'payment':
        return Icons.payment;
      case 'withdrawal':
        return Icons.account_balance;
      case 'kyc':
        return Icons.verified_user;
      case 'transaction':
        return Icons.swap_horiz;
      case 'expiry':
        return Icons.alarm;
      case 'system':
      default:
        return Icons.notifications;
    }
  }

  Color _getTypeColor(String? type) {
    switch (type) {
      case 'cashback':
        return AppTheme.premiumGold;
      case 'referral':
        return Colors.teal;
      case 'payment':
        return AppTheme.primaryNavy;
      case 'withdrawal':
        return Colors.indigo;
      case 'kyc':
        return Colors.deepPurple;
      case 'transaction':
        return Colors.blue;
      case 'expiry':
        return Colors.orange;
      case 'system':
      default:
        return AppTheme.primaryNavy;
    }
  }

  void _showImageDialog(String imageUrl) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: InteractiveViewer(
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      height: 300,
                      color: Colors.black54,
                      child: const Center(
                        child: CircularProgressIndicator(color: AppTheme.premiumGold),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => Container(
                    padding: const EdgeInsets.all(24),
                    color: Colors.white,
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.broken_image, size: 48, color: Colors.grey),
                        SizedBox(height: 8),
                        Text('Failed to load image', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () => Navigator.of(ctx).pop(),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showNotificationDetailDialog(dynamic notif) {
    final rawMessage = notif['message'] ?? '';
    final cleanMsg = _cleanMessage(rawMessage);
    final imageUrl = _extractImageUrl(rawMessage, notif);
    final title = notif['title'] ?? 'Notification';
    final dateFormatted = _formatDate(notif['created_at']);
    final type = notif['type']?.toString().toLowerCase() ?? 'system';
    final typeIcon = _getTypeIcon(type);
    final typeColor = _getTypeColor(type);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
        contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: typeColor.withAlpha(25),
                shape: BoxShape.circle,
              ),
              child: Icon(typeIcon, color: typeColor, size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                      textStyle: const TextStyle(
                        fontFamilyFallback: ['Noto Sans Devanagari', 'Noto Sans Gujarati', 'Roboto', 'sans-serif'],
                      ),
                    ),
                  ),
                  if (dateFormatted.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      dateFormatted,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppTheme.textLight,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (cleanMsg.isNotEmpty)
                Text(
                  cleanMsg,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                    height: 1.5,
                    textStyle: const TextStyle(
                      fontFamilyFallback: ['Noto Sans Devanagari', 'Noto Sans Gujarati', 'Roboto', 'sans-serif'],
                    ),
                  ),
                ),
              if (imageUrl != null && imageUrl.isNotEmpty) ...[
                const SizedBox(height: 14),
                GestureDetector(
                  onTap: () => _showImageDialog(imageUrl),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Image.network(
                          imageUrl,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                        ),
                        Container(
                          margin: const EdgeInsets.all(8),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withAlpha(150),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.zoom_in, color: Colors.white, size: 14),
                              SizedBox(width: 4),
                              Text('Zoom', style: TextStyle(color: Colors.white, fontSize: 10)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryNavy,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.appBackground,
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (_unreadCount > 0)
            TextButton.icon(
              onPressed: _markAllAsRead,
              icon: const Icon(Icons.done_all, size: 18, color: AppTheme.premiumGold),
              label: const Text(
                'Mark read',
                style: TextStyle(color: AppTheme.premiumGold, fontWeight: FontWeight.w600),
              ),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.premiumGold))
          : RefreshIndicator(
              color: AppTheme.premiumGold,
              onRefresh: _fetchNotifications,
              child: _notifications.isEmpty
                  ? Center(
                      child: ListView(
                        shrinkWrap: true,
                        children: [
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryNavy.withAlpha(15),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.notifications_none_rounded,
                                  size: 42,
                                  color: AppTheme.primaryNavy,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No notifications yet',
                                style: GoogleFonts.inter(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'You will receive updates and rewards alerts here.',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      itemCount: _notifications.length,
                      itemBuilder: (ctx, i) {
                        final notif = _notifications[i];
                        final isRead = notif['is_read'] == 1 || notif['is_read'] == true;
                        final rawMessage = notif['message'] ?? '';
                        final cleanMsg = _cleanMessage(rawMessage);
                        final imageUrl = _extractImageUrl(rawMessage, notif);
                        final title = notif['title'] ?? 'Notification';
                        final dateFormatted = _formatDate(notif['created_at']);
                        final type = notif['type']?.toString().toLowerCase() ?? 'system';
                        final typeIcon = _getTypeIcon(type);
                        final typeColor = _getTypeColor(type);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: isRead ? AppTheme.cardBackground : const Color(0xFFFCF9F2),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isRead
                                  ? AppTheme.lightBorder
                                  : AppTheme.premiumGold.withAlpha(90),
                              width: isRead ? 1 : 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: isRead
                                    ? Colors.black.withAlpha(6)
                                    : AppTheme.premiumGold.withAlpha(20),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              if (!isRead) _markAsRead(notif['id']);
                              _showNotificationDetailDialog(notif);
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 38,
                                        height: 38,
                                        decoration: BoxDecoration(
                                          color: typeColor.withAlpha(25),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Icon(typeIcon, color: typeColor, size: 20),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    title,
                                                    style: GoogleFonts.inter(
                                                      fontSize: 15,
                                                      fontWeight: isRead ? FontWeight.w600 : FontWeight.w800,
                                                      color: AppTheme.textPrimary,
                                                      textStyle: const TextStyle(
                                                        fontFamilyFallback: ['Noto Sans Devanagari', 'Noto Sans Gujarati', 'Roboto', 'sans-serif'],
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                if (!isRead)
                                                  Container(
                                                    width: 8,
                                                    height: 8,
                                                    margin: const EdgeInsets.only(left: 6),
                                                    decoration: const BoxDecoration(
                                                      color: AppTheme.premiumGold,
                                                      shape: BoxShape.circle,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                            if (dateFormatted.isNotEmpty) ...[
                                              const SizedBox(height: 2),
                                              Text(
                                                dateFormatted,
                                                style: GoogleFonts.inter(
                                                  fontSize: 11,
                                                  color: AppTheme.textLight,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (cleanMsg.isNotEmpty) ...[
                                    const SizedBox(height: 10),
                                    Text(
                                      cleanMsg,
                                      style: GoogleFonts.inter(
                                        fontSize: 13.5,
                                        height: 1.45,
                                        color: isRead ? AppTheme.textSecondary : const Color(0xFF2C3E50),
                                        fontWeight: isRead ? FontWeight.w400 : FontWeight.w500,
                                        textStyle: const TextStyle(
                                          fontFamilyFallback: ['Noto Sans Devanagari', 'Noto Sans Gujarati', 'Roboto', 'sans-serif'],
                                        ),
                                      ),
                                    ),
                                  ],
                                  if (imageUrl != null && imageUrl.isNotEmpty) ...[
                                    const SizedBox(height: 12),
                                    GestureDetector(
                                      onTap: () => _showImageDialog(imageUrl),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Container(
                                          constraints: const BoxConstraints(maxHeight: 200),
                                          width: double.infinity,
                                          decoration: BoxDecoration(
                                            color: Colors.grey.withAlpha(25),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: AppTheme.lightBorder),
                                          ),
                                          child: Stack(
                                            alignment: Alignment.bottomRight,
                                            children: [
                                              Image.network(
                                                imageUrl,
                                                width: double.infinity,
                                                fit: BoxFit.cover,
                                                loadingBuilder: (context, child, loadingProgress) {
                                                  if (loadingProgress == null) return child;
                                                  return Container(
                                                    height: 140,
                                                    alignment: Alignment.center,
                                                    child: CircularProgressIndicator(
                                                      value: loadingProgress.expectedTotalBytes != null
                                                          ? loadingProgress.cumulativeBytesLoaded /
                                                              loadingProgress.expectedTotalBytes!
                                                          : null,
                                                      color: AppTheme.premiumGold,
                                                      strokeWidth: 2,
                                                    ),
                                                  );
                                                },
                                                errorBuilder: (context, error, stackTrace) => Container(
                                                  height: 100,
                                                  alignment: Alignment.center,
                                                  child: const Row(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                      Icon(Icons.broken_image, size: 24, color: Colors.grey),
                                                      SizedBox(width: 8),
                                                      Text('Image unavailable', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              Positioned(
                                                bottom: 6,
                                                right: 6,
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                                  decoration: BoxDecoration(
                                                    color: Colors.black.withAlpha(150),
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: const Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Icon(Icons.zoom_in, color: Colors.white, size: 14),
                                                      SizedBox(width: 3),
                                                      Text('Tap to zoom', style: TextStyle(color: Colors.white, fontSize: 10)),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
