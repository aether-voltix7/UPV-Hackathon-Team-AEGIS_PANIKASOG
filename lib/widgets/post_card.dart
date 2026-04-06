import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../models/post_model.dart';

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
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
              child: _PostHeader(post: post),
            ),

            // ── Title ────────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
              child: Text(post.title, style: AppTextStyles.h3),
            ),

            // ── Tags ──────────────────────────────────────────────────────────
            if (post.tags.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
                child: _TagRow(tags: post.tags, isUrgent: post.isUrgent),
              ),

            // ── Image(s) ──────────────────────────────────────────────────────
            if (post.imageUrls.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: _ImageCarousel(imageUrls: post.imageUrls),
              )
            else if (post.imageUrl != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Image.network(
                  post.imageUrl!,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _ImagePlaceholder(),
                ),
              ),
            // ── Caption ───────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
              child: _ExpandableCaption(caption: post.caption),
            ),

            // ── Actions ───────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              child: _PostActions(
                post: post,
                userVote: userVote,
                onUpvote: onUpvote,
                onDownvote: onDownvote,
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
          height: 220,
          child: PageView.builder(
            controller: _ctrl,
            itemCount: widget.imageUrls.length,
            onPageChanged: (i) => setState(() => _current = i),
            itemBuilder: (context, i) => Image.network(
              widget.imageUrls[i],
              width: double.infinity,
              height: 220,
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
      children: [
        // Avatar
        CircleAvatar(
          radius: 18,
          backgroundColor: AppColors.chipBg,
          backgroundImage: post.authorAvatarUrl != null
              ? NetworkImage(post.authorAvatarUrl!)
              : null,
          child: post.authorAvatarUrl == null
              ? Text(
                  post.authorUsername.isNotEmpty
                      ? post.authorUsername[0].toUpperCase()
                      : '?',
                  style: AppTextStyles.labelMedium
                      .copyWith(color: AppColors.primary),
                )
              : null,
        ),
        const SizedBox(width: 10),

        // Name + location + time
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    post.authorUsername,
                    style: AppTextStyles.labelMedium
                        .copyWith(fontSize: 13, color: AppColors.primary),
                  ),
                  if (post.authorIsVerified) ...[
                    const SizedBox(width: 4),
                    const Icon(Icons.verified,
                        color: AppColors.primary, size: 14),
                  ],
                ],
              ),
              Text(
                '${post.barangay}, ${post.city} • ${_timeAgo(post.createdAt)}',
                style: AppTextStyles.bodySmall,
              ),
            ],
          ),
        ),

        // More options
        const Icon(Icons.more_horiz, color: AppColors.hintGrey, size: 20),
      ],
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return DateFormat('MMM d').format(dt);
  }
}

// ─── Tag row ───────────────────────────────────────────────────────────────────
class _TagRow extends StatelessWidget {
  final List<String> tags;
  final bool isUrgent;
  const _TagRow({required this.tags, required this.isUrgent});

  @override
  Widget build(BuildContext context) {
    final displayTags = tags.take(3).toList();
    final overflow = tags.length - 3;

    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
        if (isUrgent) _UrgentChip(),
        ...displayTags.map((t) => _TagChip(label: t)),
        if (overflow > 0) _TagChip(label: '+$overflow', isOverflow: true),
      ],
    );
  }
}

class _TagChip extends StatelessWidget {
  final String label;
  final bool isOverflow;
  const _TagChip({required this.label, this.isOverflow = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: isOverflow ? AppColors.lightGrey : AppColors.chipBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '#$label',
        style: AppTextStyles.bodySmall.copyWith(
          color: isOverflow ? AppColors.hintGrey : AppColors.primary,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _UrgentChip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.urgent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.urgent, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: AppColors.urgent, size: 12),
          const SizedBox(width: 4),
          Text(
            'URGENT',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.urgent,
              fontWeight: FontWeight.w700,
              fontSize: 10,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Expandable caption ────────────────────────────────────────────────────────
class _ExpandableCaption extends StatefulWidget {
  final String caption;
  const _ExpandableCaption({required this.caption});

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
        // Caption with hashtag colouring
        _HashtagText(text: preview),
        if (isLong)
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Text(
              _expanded ? 'See less' : 'See more',
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.primary, fontWeight: FontWeight.w600),
            ),
          ),
      ],
    );
  }
}

class _HashtagText extends StatelessWidget {
  final String text;
  const _HashtagText({required this.text});

  @override
  Widget build(BuildContext context) {
    final parts = text.split(' ');
    return Text.rich(
      TextSpan(
        children: parts.map((word) {
          if (word.startsWith('#')) {
            return TextSpan(
              text: '$word ',
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.primary, fontWeight: FontWeight.w500),
            );
          }
          return TextSpan(
            text: '$word ',
            style: AppTextStyles.bodySmall,
          );
        }).toList(),
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
        // Upvote
        _VoteButton(
          icon: Icons.arrow_upward_rounded,
          count: post.upvotes,
          isActive: userVote == 'up',
          activeColor: AppColors.primary,
          onTap: onUpvote,
        ),
        const SizedBox(width: 8),

        // Downvote
        _VoteButton(
          icon: Icons.arrow_downward_rounded,
          count: post.downvotes,
          isActive: userVote == 'down',
          activeColor: AppColors.error,
          onTap: onDownvote,
        ),
        const Spacer(),

        // Comments
        Row(
          children: [
            const Icon(Icons.chat_bubble_outline,
                size: 16, color: AppColors.hintGrey),
            const SizedBox(width: 4),
            Text(
              _formatCount(post.commentCount),
              style: AppTextStyles.bodySmall,
            ),
          ],
        ),
        const SizedBox(width: 12),

        // Share
        const Icon(Icons.share_outlined, size: 16, color: AppColors.hintGrey),
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
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isActive ? activeColor.withValues(alpha: 0.1) : AppColors.lightGrey,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isActive ? activeColor : AppColors.hintGrey,
            ),
            const SizedBox(width: 4),
            Text(
              _formatCount(count),
              style: AppTextStyles.bodySmall.copyWith(
                color: isActive ? activeColor : AppColors.hintGrey,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
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
      height: 200,
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
