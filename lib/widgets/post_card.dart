import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../models/post_model.dart';

const _figmaPurplePrimary = Color(0xFF520052);
const _figmaPurpleSecondary = Color(0xFFA3049F);
const _figmaTagGreen = Color(0xFF1A7815);
const _figmaChipGray = Color(0xFFD9D9D9);
const _figmaDivider = Color(0x33000000);

class PostCard extends StatelessWidget {
  final PostModel post;
  final String? currentUserId;
  final String? userVote; // 'up', 'down', or null
  final VoidCallback? onUpvote;
  final VoidCallback? onDownvote;
  final VoidCallback? onTap;

  const PostCard({
    super.key,
    required this.post,
    this.currentUserId,
    this.userVote,
    this.onUpvote,
    this.onDownvote,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.white,
          border: Border(
            top: BorderSide(color: Colors.black.withValues(alpha: 0.2)),
            bottom: BorderSide(color: Colors.black.withValues(alpha: 0.2)),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 18, 22, 0),
              child: _PostHeader(post: post),
            ),
            const SizedBox(height: 18),
            if (post.imageUrls.isNotEmpty)
              _ImageCarousel(imageUrls: post.imageUrls)
            else if (post.imageUrl != null)
              Image.network(
                post.imageUrl!,
                width: double.infinity,
                height: 217,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _ImagePlaceholder(),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 10, 28, 0),
              child: _PostActions(
                post: post,
                userVote: userVote,
                onUpvote: onUpvote,
                onDownvote: onDownvote,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 10, 28, 18),
              child: _ExpandableCaption(
                authorUsername: post.authorUsername,
                isVerified: post.authorIsVerified,
                caption: post.caption,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Image Carousel ────────────────────────────────────────────────────────────
class _ImageCarousel extends StatefulWidget {
  final List<String> imageUrls;
  const _ImageCarousel({required this.imageUrls});

  @override
  State<_ImageCarousel> createState() => _ImageCarouselState();
}

class _ImageCarouselState extends State<_ImageCarousel> {
  int _current = 0;
  final PageController _ctrl = PageController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SizedBox(
          height: 217,
          child: PageView.builder(
            controller: _ctrl,
            itemCount: widget.imageUrls.length,
            onPageChanged: (i) => setState(() => _current = i),
            itemBuilder: (context, i) => Image.network(
              widget.imageUrls[i],
              width: double.infinity,
              height: 217,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _ImagePlaceholder(),
            ),
          ),
        ),
        // Dot indicators
        if (widget.imageUrls.length > 1)
          Positioned(
            bottom: 10,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.imageUrls.length, (i) =>
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: _current == i ? 16 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: _current == i ? AppColors.primary : Colors.white.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ),
        // Image counter badge
        if (widget.imageUrls.length > 1)
          Positioned(
            top: 10,
            right: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_current + 1}/${widget.imageUrls.length}',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ─── Post Header ───────────────────────────────────────────────────────────────
class _PostHeader extends StatelessWidget {
  final PostModel post;
  const _PostHeader({required this.post});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: const Color(0xFFFFF1F4),
          backgroundImage: post.authorAvatarUrl != null
              ? NetworkImage(post.authorAvatarUrl!)
              : null,
          child: post.authorAvatarUrl == null
              ? const Icon(Icons.public, color: Colors.orange, size: 18)
              : null,
        ),
        const SizedBox(width: 11),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      post.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: _figmaPurplePrimary,
                        height: 1.1,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                '${post.barangay}, ${post.city} • ${_timeAgo(post.createdAt)}',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: _figmaPurpleSecondary,
                ),
              ),
              const SizedBox(height: 6),
              _TagRow(tags: post.tags, isUrgent: post.isUrgent, category: post.category),
            ],
          ),
        ),
      ],
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}mins ago';
    if (diff.inHours < 24) return '${diff.inHours}hrs ago';
    return DateFormat('MMM d').format(dt);
  }
}

// ─── Tag row ───────────────────────────────────────────────────────────────────
class _TagRow extends StatelessWidget {
  final List<String> tags;
  final bool isUrgent;
  final PostCategory category;
  const _TagRow({
    required this.tags,
    required this.isUrgent,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    final normalizedTags = tags.where((tag) => tag.trim().isNotEmpty).toList();
    final primaryLabel = normalizedTags.isNotEmpty
        ? normalizedTags.first
        : _fallbackCategoryLabel(category, isUrgent);
    final secondaryTags = normalizedTags.skip(1).take(2).toList();
    final overflow = normalizedTags.length - 3;

    return Wrap(
      spacing: 5,
      runSpacing: 5,
      children: [
        _TagChip(label: primaryLabel, isPrimary: true, isUrgent: isUrgent),
        ...secondaryTags.map((tag) => _TagChip(label: tag)),
        if (overflow > 0) _TagChip(label: '+$overflow', isOverflow: true),
      ],
    );
  }

  String _fallbackCategoryLabel(PostCategory category, bool isUrgent) {
    if (isUrgent) return 'Urgent';

    switch (category) {
      case PostCategory.tasks:
        return 'Task';
      case PostCategory.verified:
        return 'Verified';
      case PostCategory.news:
        return 'News';
      case PostCategory.community:
        return 'Community';
    }
  }
}

class _TagChip extends StatelessWidget {
  final String label;
  final bool isPrimary;
  final bool isOverflow;
  final bool isUrgent;
  const _TagChip({
    required this.label,
    this.isPrimary = false,
    this.isOverflow = false,
    this.isUrgent = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: isPrimary
            ? (isUrgent ? AppColors.urgent : _figmaTagGreen)
            : _figmaChipGray,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isPrimary) ...[
            Icon(
              isUrgent ? Icons.warning_amber_rounded : Icons.eco,
              size: 10,
              color: Colors.white,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 10,
              fontWeight: FontWeight.w400,
              color: isPrimary ? Colors.white : Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Expandable caption ────────────────────────────────────────────────────────
class _ExpandableCaption extends StatefulWidget {
  final String authorUsername;
  final bool isVerified;
  final String caption;
  const _ExpandableCaption({
    required this.authorUsername,
    required this.isVerified,
    required this.caption,
  });

  @override
  State<_ExpandableCaption> createState() => _ExpandableCaptionState();
}

class _ExpandableCaptionState extends State<_ExpandableCaption> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final words = widget.caption.split(' ');
    final isLong = words.length > 25;
    final preview = isLong && !_expanded
        ? '${words.take(25).join(' ')}...'
        : widget.caption;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CaptionText(
          authorUsername: widget.authorUsername,
          isVerified: widget.isVerified,
          text: preview,
        ),
        if (isLong)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: GestureDetector(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Text(
                _expanded ? 'See less' : 'See more',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: _figmaPurplePrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _CaptionText extends StatelessWidget {
  final String authorUsername;
  final bool isVerified;
  final String text;
  const _CaptionText({
    required this.authorUsername,
    required this.isVerified,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final parts = text.split(RegExp(r'\s+'));
    return RichText(
      text: TextSpan(
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 13,
          height: 1.45,
          color: Colors.black,
        ),
        children: [
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  authorUsername,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    height: 1.45,
                    color: Colors.black,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (isVerified) ...[
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.verified,
                    size: 14,
                    color: _figmaPurpleSecondary,
                  ),
                ],
                const Text(
                  ' • ',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    height: 1.45,
                    color: Colors.black,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          ...parts.map((word) {
            if (word.startsWith('#')) {
              return TextSpan(
                text: '$word ',
                style: const TextStyle(
                  color: _figmaPurplePrimary,
                  decoration: TextDecoration.underline,
                ),
              );
            }
            return TextSpan(text: '$word ');
          }),
        ],
      ),
    );
  }
}

// ─── Post actions (votes + comments) ──────────────────────────────────────────
class _PostActions extends StatelessWidget {
  final PostModel post;
  final String? userVote;
  final VoidCallback? onUpvote;
  final VoidCallback? onDownvote;

  const _PostActions({
    required this.post,
    this.userVote,
    this.onUpvote,
    this.onDownvote,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _VoteButton(
          icon: Icons.arrow_upward_rounded,
          count: post.upvotes,
          isActive: userVote == 'up',
          activeColor: AppColors.primary,
          onTap: onUpvote,
        ),
        const SizedBox(width: 6),
        _VoteButton(
          icon: Icons.arrow_downward_rounded,
          count: post.downvotes,
          isActive: userVote == 'down',
          activeColor: AppColors.error,
          onTap: onDownvote,
        ),
        const SizedBox(width: 20),
        Row(
          children: [
            const Icon(Icons.chat_bubble_outline,
                size: 16, color: Colors.black),
            const SizedBox(width: 4),
            Text(
              _formatCount(post.commentCount),
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 10,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _formatCount(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return n.toString();
  }
}

class _VoteButton extends StatelessWidget {
  final IconData icon;
  final int count;
  final bool isActive;
  final Color activeColor;
  final VoidCallback? onTap;

  const _VoteButton({
    required this.icon,
    required this.count,
    required this.isActive,
    required this.activeColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final outlineColor = isActive ? activeColor : Colors.black.withValues(alpha: 0.7);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        constraints: const BoxConstraints(minHeight: 34, minWidth: 46),
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
        decoration: BoxDecoration(
          color: isActive ? activeColor.withValues(alpha: 0.16) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: outlineColor,
            width: 1.6,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 19,
              color: outlineColor,
            ),
            const SizedBox(width: 5),
            Text(
              _formatCount(count),
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                color: outlineColor,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatCount(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return n.toString();
  }
}

// ─── Image placeholder ─────────────────────────────────────────────────────────
class _ImagePlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 217,
      color: AppColors.lightGrey,
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image_outlined, color: AppColors.borderGrey, size: 40),
          SizedBox(height: 8),
          Text(
            'No image',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              color: AppColors.hintGrey,
            ),
          ),
        ],
      ),
    );
  }
}
