import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../core/constants/prohibited_keywords.dart';
import '../../models/post_model.dart';
import '../../providers/auth_provider.dart';

class PostDetailScreen extends StatefulWidget {
  final PostModel post;
  const PostDetailScreen({super.key, required this.post});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final TextEditingController _commentCtrl = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _filterText(String text) {
    String result = text;
    for (String keyword in prohibitedKeywords) {
      result = result.replaceAll(RegExp(keyword, caseSensitive: false), '');
    }
    return result;
  }

  void _sharePost() {
    Share.share(
      '${widget.post.title}\n\n${widget.post.caption}\n\nPosted by ${widget.post.authorUsername} in ${widget.post.barangay}, ${widget.post.city}',
      subject: widget.post.title,
    );
  }

  Future<void> _postComment() async {
    final auth = context.read<AuthProvider>();
    final user = auth.user;
    if (user == null || _commentCtrl.text.trim().isEmpty) return;

    final commentData = {
      'userId': user.uid,
      'username': user.username,
      'avatarUrl': user.avatarUrl,
      'text': _commentCtrl.text.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    };

    await _firestore
        .collection('posts')
        .doc(widget.post.id)
        .collection('comments')
        .add(commentData);

    if (!mounted) return; // ADDED

    await _firestore
        .collection('posts')
        .doc(widget.post.id)
        .update({'commentCount': FieldValue.increment(1)});

    _commentCtrl.clear();
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.post.title, style: AppTextStyles.h3),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textDark,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: _sharePost,
            tooltip: 'Share',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundImage: widget.post.authorAvatarUrl != null
                            ? NetworkImage(widget.post.authorAvatarUrl!)
                            : null,
                        child: widget.post.authorAvatarUrl == null
                            ? Text(widget.post.authorUsername[0].toUpperCase())
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.post.authorUsername,
                                style: AppTextStyles.labelMedium),
                            Text(
                              '${widget.post.barangay}, ${widget.post.city} • ${DateFormat('MMM d, yyyy').format(widget.post.createdAt)}',
                              style: AppTextStyles.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(widget.post.title, style: AppTextStyles.h1),
                  const SizedBox(height: 8),
                  if (widget.post.imageUrl != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(widget.post.imageUrl!,
                          width: double.infinity, fit: BoxFit.cover),
                    ),
                  const SizedBox(height: 12),
                  Text(widget.post.caption, style: AppTextStyles.bodyMedium),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: widget.post.tags
                        .map((t) => Chip(
                              label: Text('#$t', style: AppTextStyles.bodySmall),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Icon(Icons.arrow_upward, size: 16,
                          color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text('${widget.post.upvotes}',
                          style: AppTextStyles.bodyMedium),
                      const SizedBox(width: 16),
                      Icon(Icons.chat_bubble_outline, size: 16,
                          color: AppColors.hintGrey),
                      const SizedBox(width: 4),
                      Text('${widget.post.commentCount}',
                          style: AppTextStyles.bodyMedium),
                    ],
                  ),
                  const Divider(),
                  const Text('Comments', style: AppTextStyles.h3),
                  const SizedBox(height: 8),
                  StreamBuilder<QuerySnapshot>(
                    stream: _firestore
                        .collection('posts')
                        .doc(widget.post.id)
                        .collection('comments')
                        .orderBy('createdAt', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(
                            child: CircularProgressIndicator());
                      }
                      final comments = snapshot.data?.docs ?? [];
                      if (comments.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.all(32),
                          child: Center(
                            child: Text('No comments yet. Be the first!',
                                style: AppTextStyles.bodySmall),
                          ),
                        );
                      }
                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: comments.length,
                        itemBuilder: (context, i) {
                          final data =
                              comments[i].data() as Map<String, dynamic>;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundImage: data['avatarUrl'] != null
                                      ? NetworkImage(data['avatarUrl'])
                                      : null,
                                  child: data['avatarUrl'] == null
                                      ? Text(
                                          (data['username'] ?? 'U')[0]
                                              .toUpperCase())
                                      : null,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(data['username'] ?? 'User',
                                          style: AppTextStyles.labelMedium
                                              .copyWith(fontSize: 12)),
                                      const SizedBox(height: 2),
                                      Text(data['text'] ?? '',
                                          style: AppTextStyles.bodySmall),
                                    ],
                                  ),
                                ),
                                Text(
                                  _timeAgo((data['createdAt'] as Timestamp?)
                                          ?.toDate() ??
                                      DateTime.now()),
                                  style: AppTextStyles.bodySmall.copyWith(
                                      fontSize: 10, color: AppColors.hintGrey),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentCtrl,
                    onChanged: (value) {
                      String filtered = _filterText(value);
                      if (filtered != value) {
                        _commentCtrl.text = filtered;
                        _commentCtrl.selection = TextSelection.collapsed(offset: filtered.length);
                      }
                    },
                    decoration: const InputDecoration(
                      hintText: 'Write a comment...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(24)),
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send, color: AppColors.primary),
                  onPressed: _postComment,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return DateFormat('MMM d').format(dt);
  }
}