import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/new_app_theme.dart';
import '../theme/app_typography.dart';


class CommentsSection extends StatefulWidget {
  final String storyId;
  final String authorId;
  final String storyTitle;

  const CommentsSection({
    super.key,
    required this.storyId,
    required this.authorId,
    required this.storyTitle,
  });

  @override
  State<CommentsSection> createState() => _CommentsSectionState();
}

class _CommentsSectionState extends State<CommentsSection> {
  final TextEditingController _commentController = TextEditingController();
  final TextEditingController _replyController   = TextEditingController();
  final FocusNode _commentFocus = FocusNode();
  final FocusNode _replyFocus   = FocusNode();

  bool _submittingComment = false;
  bool _submittingReply   = false;

  String? _replyingToCommentId;
  String? _replyingToUsername;

  @override
  void initState() {
    super.initState();
    // FIX 4: Log storyId on init to catch empty/wrong ID early
    debugPrint('[CommentsSection] storyId = "${widget.storyId}"');
    debugPrint('[CommentsSection] authorId = "${widget.authorId}"');
  }

  @override
  void dispose() {
    _commentController.dispose();
    _replyController.dispose();
    _commentFocus.dispose();
    _replyFocus.dispose();
    super.dispose();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  String get _currentUid =>
      FirebaseAuth.instance.currentUser?.uid ?? '';

  bool get _isAuthor => _currentUid == widget.authorId;

  CollectionReference get _commentsRef => FirebaseFirestore.instance
      .collection('stories')
      .doc(widget.storyId)
      .collection('comments');

  Future<String> _getDisplayName() async {
    if (_currentUid.isEmpty) return 'Anonymous';
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(_currentUid)
        .get();
    final data = doc.data();
    return (data?['displayName'] as String?)?.trim().isNotEmpty == true
        ? data!['displayName'] as String
        : (data?['username'] as String?) ?? 'Anonymous';
  }

  // ── Submit top-level comment ───────────────────────────────────────────────

  Future<void> _submitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty || _submittingComment) return;

    setState(() => _submittingComment = true);
    try {
      final name = await _getDisplayName();
      final commentDoc = await _commentsRef.add({
        'text'      : text,
        'userId'    : _currentUid,
        'userName'  : name,
        'isAuthor'  : _isAuthor,
        'createdAt' : FieldValue.serverTimestamp(),
        'createdAtMs': DateTime.now().millisecondsSinceEpoch,
        'replyCount': 0,
      });

      // Notify the Story Author (Reader -> Author)
      // Ensure authorId is not empty and is not the person who just commented
      if (widget.authorId.isNotEmpty && widget.authorId != _currentUid) {
        debugPrint('[CommentsSection] Notifying author: ${widget.authorId}');
        
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.authorId)
            .collection('notifications')
            .add({
          'title': 'New Comment',
          'body': '$name commented on "${widget.storyTitle}": "$text"',
          'type': 'comment',
          'timestamp': FieldValue.serverTimestamp(),
          'isRead': false,
          'fromId': _currentUid,
          'storyId': widget.storyId,
        });
        debugPrint('[Notification] Comment notification sent to author: ${widget.authorId}');
      }

      _commentController.clear();
      _commentFocus.unfocus();
    } catch (e) {
      debugPrint('[CommentsSection] Error submitting comment: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to post comment: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _submittingComment = false);
    }
  }

  // ── Submit reply ───────────────────────────────────────────────────────────

  Future<void> _submitReply(String commentId) async {
    final text = _replyController.text.trim();
    if (text.isEmpty || _submittingReply) return;

    setState(() => _submittingReply = true);
    try {
      final name = await _getDisplayName();
      
      // Get parent comment details for notification
      final parentCommentDoc = await _commentsRef.doc(commentId).get();
      final parentData = parentCommentDoc.data() as Map<String, dynamic>?;

      // Run comment creation in a batch
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final replyRef = _commentsRef.doc(commentId).collection('replies').doc();
        
        transaction.set(replyRef, {
          'text'        : text,
          'userId'      : _currentUid,
          'userName'    : name,
          'isAuthor'    : _isAuthor,
          'createdAt'   : FieldValue.serverTimestamp(),
          'createdAtMs' : DateTime.now().millisecondsSinceEpoch,
        });

        transaction.update(_commentsRef.doc(commentId), {
          'replyCount': FieldValue.increment(1),
        });
      });

      // Notify the Comment Owner (Author -> Reader OR Reader -> Reader)
      final parentUserId = parentData?['userId'] as String?;
      if (parentUserId != null && parentUserId != _currentUid) {
        debugPrint('[CommentsSection] Notifying comment owner: $parentUserId');
        
        await FirebaseFirestore.instance
            .collection('users')
            .doc(parentUserId)
            .collection('notifications')
            .add({
          'title': 'New Reply',
          'body': '$name replied to your comment: "$text"',
          'type': 'comment',
          'timestamp': FieldValue.serverTimestamp(),
          'isRead': false,
          'fromId': _currentUid,
          'storyId': widget.storyId,
        });
        debugPrint('[Notification] Reply notification sent to comment owner: $parentUserId');
      }

      _replyController.clear();
      _replyFocus.unfocus();
      setState(() {
        _replyingToCommentId = null;
        _replyingToUsername  = null;
      });
    } catch (e) {
      debugPrint('[CommentsSection] Error submitting reply: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to post reply: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _submittingReply = false);
    }
  }

  // ── Delete comment ─────────────────────────────────────────────────────────

  Future<void> _deleteComment(String commentId, String commentUserId) async {
    if (_currentUid != commentUserId && !_isAuthor) return;
    try {
      await _commentsRef.doc(commentId).delete();
    } catch (e) {
      debugPrint('[CommentsSection] Error deleting comment: $e');
    }
  }

  // ── Delete reply ───────────────────────────────────────────────────────────

  Future<void> _deleteReply(
      String commentId, String replyId, String replyUserId) async {
    if (_currentUid != replyUserId && !_isAuthor) return;
    try {
      final batch = FirebaseFirestore.instance.batch();
      batch.delete(
          _commentsRef.doc(commentId).collection('replies').doc(replyId));
      batch.update(_commentsRef.doc(commentId), {
        'replyCount': FieldValue.increment(-1),
      });
      await batch.commit();
    } catch (e) {
      debugPrint('[CommentsSection] Error deleting reply: $e');
    }
  }

  // ── UI ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
          child: Text('Comments', style: AppTypography.headingSm),
        ),
        _buildCommentInput(),
        _buildCommentList(),
      ],
    );
  }

  // ── Comment input bar ──────────────────────────────────────────────────────

  Widget _buildCommentInput() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color        : AppTheme.inkBgCard,
                borderRadius : BorderRadius.circular(AppTheme.radiusFull),
              ),
              child: TextField(
                controller : _commentController,
                focusNode  : _commentFocus,
                minLines   : 1,
                maxLines   : 3,
                decoration : InputDecoration(
                  hintText       : 'Write a comment…', hintStyle: AppTypography.bodyMd.copyWith(
                      color: AppTheme.inkUmber.withValues(alpha: 0.5)),
                  border         : InputBorder.none,
                  isDense        : true,
                  contentPadding : const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 10),
                ),
                style: AppTypography.bodyMd
                    .copyWith(color: AppTheme.inkEspresso),
              ),
            ),
          ),
          const SizedBox(width: 8),
          _sendButton(
            loading  : _submittingComment,
            onPressed: _submitComment,
          ),
        ],
      ),
    );
  }

  Widget _sendButton({
    required bool loading,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width : 40,
      height: 40,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.inkMaroon,
          padding        : EdgeInsets.zero,
          elevation      : 0,
          shape          : RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusFull)),
        ),
        child: loading
            ? const SizedBox(
                width : 16,
                height: 16,
                child : CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white))
            : const Icon(Icons.send_rounded,
                size: 16, color: Colors.white),
      ),
    );
  }

  // ── Comment list ───────────────────────────────────────────────────────────

  Widget _buildCommentList() {
    // FIX 1: Guard against empty storyId before even querying
    if (widget.storyId.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: Text('No story selected.')),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      // FIX 1 & 2: Order by the client-side ms field as a safe fallback.
      // Replace with 'createdAt' once your Firestore index is confirmed.
      stream: _commentsRef
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        // FIX 5: Expose stream errors instead of swallowing them
        if (snapshot.hasError) {
          debugPrint('[CommentsSection] Stream error: ${snapshot.error}');
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Could not load comments.',
                  style: AppTypography.bodyMd
                      .copyWith(color: AppTheme.inkUmber),
                ),
                const SizedBox(height: 4),
                // Shows the real Firestore error (index link, rules, etc.)
                SelectableText(
                  '${snapshot.error}',
                  style: AppTypography.caption
                      .copyWith(color: AppTheme.inkUmber.withValues(alpha: 0.6)),
                ),
              ],
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(
                child: CircularProgressIndicator(
                    color: AppTheme.inkMaroon)),
          );
        }

        final docs = snapshot.data?.docs ?? [];
        debugPrint('[CommentsSection] Loaded ${docs.length} comments');

        if (docs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                'No comments yet. Be the first!',
                style: AppTypography.bodyMd
                    .copyWith(color: AppTheme.inkUmber),
              ),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap  : true,
          physics     : const NeverScrollableScrollPhysics(),
          itemCount   : docs.length,
          itemBuilder : (context, i) =>
              _buildCommentTile(docs[i]),
        );
      },
    );
  }

  // ── Single comment tile ────────────────────────────────────────────────────

  Widget _buildCommentTile(QueryDocumentSnapshot doc) {
    final data            = doc.data() as Map<String, dynamic>;
    final commentId       = doc.id;
    final userName        = (data['userName']  as String?) ?? 'User';
    final text            = (data['text']      as String?) ?? '';
    final userId          = (data['userId']    as String?) ?? '';
    final isCommentAuthor = (data['isAuthor']  as bool?)
        ?? (userId == widget.authorId);
    final replyCount      = (data['replyCount'] as int?) ?? 0;
    final ts              = data['createdAt'] as Timestamp?;
    // FIX 2: fall back to client-side ms timestamp if server ts is null
    final time = ts != null
        ? _formatTime(ts.toDate())
        : data['createdAtMs'] != null
            ? _formatTime(DateTime.fromMillisecondsSinceEpoch(
                data['createdAtMs'] as int))
            : '';

    final canDelete  = _currentUid == userId || _isAuthor;
    final isReplying = _replyingToCommentId == commentId;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Comment bubble ──────────────────────────────────────────
          Container(
            padding    : const EdgeInsets.all(12),
            decoration : BoxDecoration(
              color       : AppTheme.inkBgCard,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius         : 14,
                      backgroundColor: AppTheme.inkMaroon.withValues(alpha: 0.15),
                      child: Text(
                        userName.isNotEmpty
                            ? userName[0].toUpperCase()
                            : '?',
                        style: AppTypography.caption.copyWith(
                          color     : AppTheme.inkMaroon,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(userName,
                              style: AppTypography.labelMd
                                  .copyWith(color: AppTheme.inkEspresso)),
                          if (isCommentAuthor)
                            Container(
                              margin : const EdgeInsets.only(top: 2),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color       : AppTheme.inkMaroon,
                                borderRadius: BorderRadius.circular(
                                    AppTheme.radiusXs),
                              ),
                              child: Text(
                                'Author',
                                style: AppTypography.caption.copyWith(
                                  color     : Colors.white,
                                  fontSize  : 8,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          if (time.isNotEmpty)
                            Text(time,
                                style: AppTypography.caption.copyWith(
                                    color: AppTheme.inkUmber.withValues(alpha: 0.6))),
                        ],
                      ),
                    ),
                    if (canDelete)
                      GestureDetector(
                        onTap: () => _deleteComment(commentId, userId),
                        child: Icon(Icons.close,
                            size : 16,
                            color: AppTheme.inkUmber.withValues(alpha: 0.4)),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(text,
                    style: AppTypography.bodyMd
                        .copyWith(color: AppTheme.inkEspresso)),
              ],
            ),
          ),

          // ── Action row ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(left: 8, top: 4),
            child: Row(
              children: [
                if (_currentUid.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isReplying) {
                          _replyingToCommentId = null;
                          _replyingToUsername  = null;
                          _replyController.clear();
                        } else {
                          _replyingToCommentId = commentId;
                          _replyingToUsername  = userName;
                          _replyController.clear();
                          Future.delayed(
                            const Duration(milliseconds: 100),
                            () => _replyFocus.requestFocus(),
                          );
                        }
                      });
                    },
                    child: Row(
                      children: [
                        Icon(
                          isReplying
                              ? Icons.close
                              : Icons.reply_rounded,
                          size : 14,
                          color: isReplying
                              ? AppTheme.inkMaroon
                              : AppTheme.inkUmber,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isReplying
                              ? 'Cancel'
                              : (_isAuthor ? 'Reply as Author' : 'Reply'),
                          style: AppTypography.caption.copyWith(
                            color: isReplying
                                ? AppTheme.inkMaroon
                                : AppTheme.inkUmber,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (replyCount > 0) ...[
                  const SizedBox(width: 12),
                  Text(
                    '$replyCount ${replyCount == 1 ? 'reply' : 'replies'}',
                    style: AppTypography.caption
                        .copyWith(color: AppTheme.inkUmber),
                  ),
                ],
              ],
            ),
          ),

          // ── Inline reply input ──────────────────────────────────────
          if (isReplying) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 24),
              child: Row(
                children: [
                  if (_isAuthor)
                    Container(
                      margin : const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color       : AppTheme.inkMaroon,
                        borderRadius: BorderRadius.circular(
                            AppTheme.radiusFull),
                      ),
                      child: Text(
                        'Author',
                        style: AppTypography.caption.copyWith(
                          color     : Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color       : AppTheme.surfaceColor,
                        borderRadius: BorderRadius.circular(
                            AppTheme.radiusFull),
                        border: Border.all(
                            color: AppTheme.inkMaroon
                                .withValues(alpha: 0.3)),
                      ),
                      child: TextField(
                        controller : _replyController,
                        focusNode  : _replyFocus,
                        minLines   : 1,
                        maxLines   : 3,
                        decoration : InputDecoration(hintText : 'Replying to @$_replyingToUsername…', hintStyle: AppTypography.bodyMd.copyWith(
                              color: AppTheme.inkUmber.withValues(alpha: 0.5)),
                          border         : InputBorder.none,
                          isDense        : true,
                          contentPadding : const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                        ),
                        style: AppTypography.bodyMd
                            .copyWith(color: AppTheme.inkEspresso),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _sendButton(
                    loading  : _submittingReply,
                    onPressed: () => _submitReply(commentId),
                  ),
                ],
              ),
            ),
          ],

          // ── Replies list ────────────────────────────────────────────
          if (replyCount > 0)
            _buildReplies(commentId),

          const SizedBox(height: 4),
        ],
      ),
    );
  }

  // ── Replies list ───────────────────────────────────────────────────────────

  Widget _buildReplies(String commentId) {
    return StreamBuilder<QuerySnapshot>(
      stream: _commentsRef
          .doc(commentId)
          .collection('replies')
          .orderBy('createdAt')
          .snapshots(),
      builder: (context, snapshot) {
        // FIX 5: Show reply stream errors too
        if (snapshot.hasError) {
          debugPrint('[CommentsSection] Replies stream error: ${snapshot.error}');
          return Padding(
            padding: const EdgeInsets.only(left: 24, top: 4),
            child: SelectableText(
              'Could not load replies: ${snapshot.error}',
              style: AppTypography.caption
                  .copyWith(color: AppTheme.inkUmber.withValues(alpha: 0.6)),
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.only(left: 24, top: 6),
          child: Column(
            children: docs.map((doc) {
              final data          = doc.data() as Map<String, dynamic>;
              final replyId       = doc.id;
              final userName      = (data['userName']  as String?) ?? 'User';
              final text          = (data['text']      as String?) ?? '';
              final userId        = (data['userId']    as String?) ?? '';
              final isAuthorReply = (data['isAuthor']  as bool?) ?? false;
              final ts            = data['createdAt'] as Timestamp?;
              // FIX 2: fallback for replies too
              final time = ts != null
                  ? _formatTime(ts.toDate())
                  : data['createdAtMs'] != null
                      ? _formatTime(DateTime.fromMillisecondsSinceEpoch(
                          data['createdAtMs'] as int))
                      : '';
              final canDelete = _currentUid == userId || _isAuthor;

              return Container(
                margin    : const EdgeInsets.only(bottom: 6),
                padding   : const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color       : isAuthorReply
                      ? AppTheme.inkMaroon.withValues(alpha: 0.06)
                      : AppTheme.inkBgCard.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  border      : isAuthorReply
                      ? Border.all(
                          color: AppTheme.inkMaroon.withValues(alpha: 0.2))
                      : null,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius         : 11,
                          backgroundColor: isAuthorReply
                              ? AppTheme.inkMaroon
                              : AppTheme.inkBgCard,
                          child: Text(
                            userName.isNotEmpty
                                ? userName[0].toUpperCase()
                                : '?',
                            style: AppTypography.caption.copyWith(
                              color: isAuthorReply
                                  ? Colors.white
                                  : AppTheme.inkUmber,
                              fontSize  : 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        if (isAuthorReply)
                          Container(
                            margin : const EdgeInsets.only(right: 4),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color       : AppTheme.inkMaroon,
                              borderRadius: BorderRadius.circular(
                                  AppTheme.radiusFull),
                            ),
                            child: Text(
                              'Author',
                              style: AppTypography.caption.copyWith(
                                color     : Colors.white,
                                fontSize  : 9,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        Expanded(
                          child: Text(userName,
                              style: AppTypography.caption.copyWith(
                                color     : AppTheme.inkEspresso,
                                fontWeight: FontWeight.w600,
                              )),
                        ),
                        if (time.isNotEmpty)
                          Text(time,
                              style: AppTypography.caption.copyWith(
                                  color: AppTheme.inkUmber.withValues(alpha: 0.4))),
                        if (canDelete) ...[
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: () =>
                                _deleteReply(commentId, replyId, userId),
                            child: Icon(Icons.close,
                                size : 13,
                                color: AppTheme.inkUmber.withValues(alpha: 0.4)),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(text,
                        style: AppTypography.bodySm
                            .copyWith(color: AppTheme.inkEspresso)),
                  ],
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  // ── Time formatter ─────────────────────────────────────────────────────────

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours   < 24) return '${diff.inHours}h ago';
    if (diff.inDays    < 7)  return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}