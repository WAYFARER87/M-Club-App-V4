import 'package:flutter/material.dart';

class RatingWidget extends StatelessWidget {
  final int rating;
  final int userVote;
  final VoidCallback? onVoteUp;
  final VoidCallback? onVoteDown;

  const RatingWidget({
    super.key,
    required this.rating,
    required this.userVote,
    this.onVoteUp,
    this.onVoteDown,
  });

  static const _iconSize = 24.0;
  static const _gap = SizedBox(width: 8);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final ratingColor = rating > 0
        ? colorScheme.primary
        : (rating < 0 ? colorScheme.error : colorScheme.onSurface);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border.all(color: colorScheme.outline),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(
              width: _iconSize,
              height: _iconSize,
            ),
            icon: Icon(
              userVote == 1
                  ? Icons.arrow_upward
                  : Icons.arrow_upward_outlined,
              color:
                  userVote == 1 ? colorScheme.primary : colorScheme.onSurface,
            ),
            onPressed: onVoteUp,
          ),
          _gap,
          Text(
            '$rating',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: ratingColor,
            ),
          ),
          _gap,
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(
              width: _iconSize,
              height: _iconSize,
            ),
            icon: Icon(
              userVote == -1
                  ? Icons.arrow_downward
                  : Icons.arrow_downward_outlined,
              color:
                  userVote == -1 ? colorScheme.error : colorScheme.onSurface,
            ),
            onPressed: onVoteDown,
          ),
        ],
      ),
    );
  }
}

