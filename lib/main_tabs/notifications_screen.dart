import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/new_app_theme.dart';
import '../theme/app_typography.dart';
import 'package:intl/intl.dart';
import '../story/read_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  Future<void> _markAllAsRead(String uid) async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('notifications')
          .where('isRead', isEqualTo: false)
          .get();

      if (snap.docs.isEmpty) return;

      final batch = FirebaseFirestore.instance.batch();
      for (var doc in snap.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (e) {
      debugPrint('[Notifications] Error marking all as read: $e');
    }
  }

  Future<void> _clearAllNotifications(String uid) async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('notifications')
          .get();

      if (snap.docs.isEmpty) return;

      final batch = FirebaseFirestore.instance.batch();
      for (var doc in snap.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      debugPrint('[Notifications] All notifications cleared.');
    } catch (e) {
      debugPrint('[Notifications] Error clearing all notifications: $e');
    }
  }

  Future<void> _handleNotificationTap(
      String uid, String docId, Map<String, dynamic> data) async {
    // 1. Mark as read immediately
    if (!(data['isRead'] as bool? ?? false)) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('notifications')
          .doc(docId)
          .update({'isRead': true});
    }

    // 2. Navigate if it's a story-related notification
    final storyId = data['storyId'] as String?;    // Robust numeric handling for chapterNumber
    final rawChapterNum = data['chapterNumber'];
    final int? chapterNumber = rawChapterNum is int 
        ? rawChapterNum 
        : (rawChapterNum is num ? rawChapterNum.toInt() : null);

    if (storyId != null && storyId.isNotEmpty && mounted) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('stories')
            .doc(storyId)
            .get();

        if (doc.exists && mounted) {
          final storyData = doc.data() as Map<String, dynamic>;
          storyData['storyId'] = doc.id;
          
          // Ensure the chapterNumber is passed to the read screen as a hint
          if (chapterNumber != null) {
            storyData['chapterNumber'] = chapterNumber;
          }

          // If it's a comment or reply, tell the ReadScreen to open comments automatically
          if (data['type'] == 'comment') {
            storyData['openComments'] = true;
          }

          final storyType = storyData['storyType'] as String? ?? 'Short Story';

          if (storyType == 'Novel' && mounted) {
            // Fetch specific chapter if provided, otherwise fetch the first published chapter
            Query chaptersQuery = FirebaseFirestore.instance
                .collection('stories')
                .doc(storyId)
                .collection('chapters')
                .where('isPublished', isEqualTo: true);

            if (chapterNumber != null) {
              chaptersQuery = chaptersQuery.where('chapterNumber', isEqualTo: chapterNumber);
            } else {
              chaptersQuery = chaptersQuery.orderBy('chapterNumber').limit(1);
            }

            final snapshot = await chaptersQuery.get();
            if (snapshot.docs.isNotEmpty) {
              final chapterData = snapshot.docs.first.data() as Map<String, dynamic>;
              // Merge story metadata with chapter content
              storyData.addAll(chapterData);
            }
          }

          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => StoryReadScreen(story: storyData),
              ),
            );
          }
        }
      } catch (e) {
        debugPrint('[Notifications] Error navigating: $e');
      }
    }
  }

  Future<void> _deleteNotification(String uid, String notificationId) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('notifications')
          .doc(notificationId)
          .delete();
      debugPrint('[Notifications] Notification $notificationId deleted.');
    } catch (e) {
      debugPrint('[Notifications] Error deleting notification: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete notification: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: AppTheme.surfaceColor,
      body: user == null
          ? Center(
              child: Text('Please log in to see notifications',
                  style: AppTypography.bodyMd.copyWith(color: AppTheme.inkUmber)))
          : CustomScrollView(
              slivers: [
                // ── Header Section with Margin ────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.inkMaroon,
                        borderRadius: BorderRadius.circular(32),
                      ),
                      child: SafeArea(
                        top: false,
                        bottom: false,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                          child: Row(
                            children: [
                              GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.notifications_active_rounded,
                                      color: Colors.white,
                                      size: 22,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Notifications',
                                      style: AppTypography.headingLg
                                          .copyWith(
                                        color: Colors.white,
                                        fontSize: 28,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Stay updated with your activities',
                                      style: AppTypography.bodyMd.copyWith(
                                        color: Colors.white
                                            .withValues(alpha: 0.85),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: () => _markAllAsRead(user.uid),
                                icon: const Icon(Icons.done_all_rounded,
                                    color: Colors.white, size: 22),
                                tooltip: 'Mark all as read',
                              ),
                              IconButton(
                                onPressed: () => _clearAllNotifications(user.uid),
                                icon: const Icon(Icons.delete_sweep_rounded,
                                    color: Colors.white, size: 22),
                                tooltip: 'Clear all notifications',
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Notifications List ────────────────────────────────────
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(user.uid)
                        .collection('notifications')
                        .orderBy('timestamp', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return SliverToBoxAdapter(
                          child: Center(
                            child: CircularProgressIndicator(
                              color: AppTheme.inkMaroon,
                              strokeWidth: 2,
                            ),
                          ),
                        );
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return SliverToBoxAdapter(
                          child: Center(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 60),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.notifications_none_rounded,
                                    size: 64,
                                    color: AppTheme.inkUmber
                                        .withValues(alpha: 0.15),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'All caught up!',
                                    style: AppTypography.headingSm.copyWith(
                                      color: AppTheme.inkEspresso,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'No new notifications for now.',
                                    style: AppTypography.bodyMd.copyWith(
                                      color: AppTheme.inkUmber
                                          .withValues(alpha: 0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }

                      final docs = snapshot.data!.docs;

                      return SliverList.separated(
                        itemCount: docs.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final data = docs[index].data()
                              as Map<String, dynamic>;
                          final timestamp = data['timestamp'] as Timestamp?;
                          final timeString = timestamp != null
                              ? _formatTimeString(timestamp.toDate())
                              : '';
                          final isRead = data['isRead'] as bool? ?? false;
                          final docId = docs[index].id;

                          return Dismissible(
                            key: Key(docId), // Unique key for Dismissible
                            direction: DismissDirection.endToStart, // Swipe from right to left
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              decoration: BoxDecoration(
                                color: Colors.red.shade700, // Background color when swiping
                                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                              ),
                              child: const Icon(Icons.delete, color: Colors.white),
                            ),
                            onDismissed: (direction) {
                              final deletedData = Map<String, dynamic>.from(data);
                              _deleteNotification(user.uid, docId);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text('Notification deleted'),
                                  action: SnackBarAction(
                                    label: 'UNDO',
                                    onPressed: () async {
                                      await FirebaseFirestore.instance
                                          .collection('users')
                                          .doc(user.uid)
                                          .collection('notifications')
                                          .doc(docId)
                                          .set(deletedData);
                                    },
                                  ),
                                ),
                              );
                            },
                            child: GestureDetector(
                              onTap: () =>
                                  _handleNotificationTap(user.uid, docId, data),
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: isRead
                                      ? AppTheme.inkBgMain
                                      : AppTheme.inkMaroon
                                          .withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(
                                      AppTheme.radiusMd),
                                  border: Border.all(
                                    color: isRead
                                        ? AppTheme.borderColor
                                        : AppTheme.inkMaroon
                                            .withValues(alpha: 0.2),
                                    width: 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.03),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: AppTheme.inkMaroon
                                            .withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        _getNotificationIcon(
                                            data['type'] as String? ?? 'default'),
                                        color: AppTheme.inkMaroon,
                                        size: 18,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            data['title'] ?? 'New Notification',
                                            style: AppTypography.bodyLg.copyWith(
                                              fontWeight: isRead
                                                  ? FontWeight.w600
                                                  : FontWeight.w700,
                                              color: AppTheme.inkEspresso,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            data['body'] ?? '',
                                            style: AppTypography.bodyMd.copyWith(
                                              color: AppTheme.inkUmber
                                                  .withValues(alpha: 0.7),
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            timeString,
                                            style: AppTypography.bodySm.copyWith(
                                              color: AppTheme.inkUmber
                                                  .withValues(alpha: 0.5),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  // Explicit Delete Button
                                  IconButton(
                                    onPressed: () => _deleteNotification(user.uid, docId),
                                    icon: Icon(
                                      Icons.delete_outline_rounded,
                                      size: 18,
                                      color: AppTheme.inkUmber.withValues(alpha: 0.4),
                                    ),
                                    visualDensity: VisualDensity.compact,
                                    tooltip: 'Delete',
                                  ),
                                    if (!isRead)
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: AppTheme.inkMaroon,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  String _formatTimeString(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d, h:mm a').format(dateTime);
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'follow':
        return Icons.person_add_rounded;
      case 'like':
        return Icons.favorite_rounded;
      case 'comment':
        return Icons.chat_bubble_rounded;
      case 'share':
        return Icons.share_rounded;
      case 'story_update':
        return Icons.update_rounded;
      case 'new_chapter':
        return Icons.library_add_rounded;
      case 'new_story':
        return Icons.auto_stories_rounded;
      default:
        return Icons.notifications_active_rounded;
    }
  }
}