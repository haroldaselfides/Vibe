import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  /// Notifies all followers when a new story is published.
  static Future<void> notifyFollowersOfNewStory({
    required String authorId,
    required String authorName,
    required String storyId,
    required String storyTitle,
  }) async {
    debugPrint('[NotificationService] notifyFollowersOfNewStory triggered for: $storyTitle');
    if (authorId.isEmpty || storyId.isEmpty) {
      debugPrint('[NotificationService] Aborting: authorId or storyId is empty');
      return;
    }
    try {
      // 1. Fetch all followers of the author from users/{authorId}/followers
      final followersSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(authorId)
          .collection('followers')
          .get();

      if (followersSnap.docs.isEmpty) {
        debugPrint('[NotificationService] No followers found to notify.');
        return;
      }

      final now = FieldValue.serverTimestamp();
      final docs = followersSnap.docs;

      // Firestore batches are limited to 500 writes. 
      // Chunking ensures we can handle authors with more than 500 followers.
      for (var i = 0; i < docs.length; i += 500) {
        final batch = FirebaseFirestore.instance.batch();
        final end = (i + 500 < docs.length) ? i + 500 : docs.length;
        final chunk = docs.sublist(i, end);

        for (var doc in chunk) {
          final notifRef = FirebaseFirestore.instance
              .collection('users')
              .doc(doc.id)
              .collection('notifications')
              .doc();

          batch.set(notifRef, {
            'title': 'New Story Published',
            'body': '$authorName just published a new story: "$storyTitle"',
            'type': 'new_story',
            'timestamp': now,
            'isRead': false,
            'fromId': authorId,
            'storyId': storyId,
          });
          debugPrint('[NotificationService] Queued new story notification for follower: ${doc.id}');
        }
        await batch.commit();
      }

      debugPrint('[NotificationService] Notified ${followersSnap.docs.length} followers of new story.');
    } catch (e) {
      debugPrint('[NotificationService] Error notifying followers: $e');
    }
  }

  /// Notifies all library holders when an existing story/novel is updated or a new chapter is added.
  static Future<void> notifyLibraryHolders({
    required String storyId,
    required String authorId,
    required String authorName,
    required String storyTitle,
    required String storyType,
    bool isNewChapter = true,
    int? chapterNumber,
  }) async {
    debugPrint('[NotificationService] notifyLibraryHolders triggered for: $storyTitle ($storyType)');
    try {
      if (storyId.isEmpty) {
        debugPrint('[NotificationService] Error: storyId is empty.');
        return;
      }
      
      // 1. Find all users who have this story in their library using a collectionGroup query
      // This requires a Single Field Index with "Collection Group" scope enabled for 'storyId'.
      final snap = await FirebaseFirestore.instance
          .collectionGroup('library')
          .where('storyId', isEqualTo: storyId)
          .get();

      if (snap.docs.isEmpty) {
        debugPrint('[NotificationService] ⚠ No readers found in any library for storyId: "$storyId"');
        debugPrint('''[NotificationService] If readers are not being notified, verify:
- the library document path is users/{uid}/library/{entry}
- each library doc has field storyId == "$storyId"''');
        return;
      }

      final isNovel = storyType == 'Novel';
      final now = FieldValue.serverTimestamp();
      final docs = snap.docs;
      
      debugPrint('[NotificationService] Found ${docs.length} total entries in library. Filtering author...');

      for (var i = 0; i < docs.length; i += 500) {
        final batch = FirebaseFirestore.instance.batch();
        final end = (i + 500 < docs.length) ? i + 500 : docs.length;
        final chunk = docs.sublist(i, end);

        int batchCount = 0;
        for (var doc in chunk) {
          // Path is typically users/{userId}/library/{entryDocId}
          // In some schemas, parent.parent may not be users/{userId}, so add a robust fallback.
          final recipientId = doc.reference.parent.parent?.id;
          if (recipientId == null || recipientId == authorId) {
            debugPrint('[NotificationService] Skipping recipient: "$recipientId" (is author/null) for library doc: ${doc.id}');
            continue;
          }

          batchCount++;


          final notifRef = FirebaseFirestore.instance
              .collection('users')
              .doc(recipientId)
              .collection('notifications')
              .doc();

          batch.set(notifRef, {
            'title': isNovel ? (isNewChapter ? 'New Chapter' : 'Chapter Updated') : 'Story Updated',
            'body': isNovel 
                ? '$authorName ${isNewChapter ? "added" : "updated"} a chapter in "$storyTitle"'
                : '$authorName updated "$storyTitle"',
            'type': isNovel ? 'new_chapter' : 'story_update',
            'timestamp': now,
            'isRead': false,
            'fromId': authorId,
            'storyId': storyId,
            'chapterNumber': chapterNumber,
          });
        }
        debugPrint('[NotificationService] Attempting to commit batch of $batchCount update notifications...');
        if (batchCount > 0) { // Only commit if there are actual notifications in the batch
          await batch.commit();
          debugPrint('[NotificationService] Committed batch of $batchCount update notifications.');
        }
      }

      debugPrint('[NotificationService] Successfully processed update notifications for ${docs.length} library entries.');
    } catch (e) {
      debugPrint('[NotificationService] Error notifying library holders: $e');
    }
  }
}