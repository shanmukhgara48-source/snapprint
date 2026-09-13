import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/error_snackbar.dart';
import '../../data/datasources/customer_remote_datasource.dart';
import '../providers/social_providers.dart';

class StarRow extends StatelessWidget {
  const StarRow({super.key, required this.value, this.size = 14});
  final double value;
  final double size;

  @override
  Widget build(BuildContext context) {
    final full = value.round();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        5,
        (i) => Icon(
          i < full ? Icons.star_rounded : Icons.star_border_rounded,
          size: size,
          color: i < full ? const Color(0xFFF59E0B) : AppColors.textHint,
        ),
      ),
    );
  }
}

/// Amazon-style ratings block for the product detail screen.
class ProductReviewsSection extends ConsumerStatefulWidget {
  const ProductReviewsSection({super.key, required this.productId});
  final String productId;

  @override
  ConsumerState<ProductReviewsSection> createState() =>
      _ProductReviewsSectionState();
}

class _ProductReviewsSectionState
    extends ConsumerState<ProductReviewsSection> {
  bool _recentFirst = false;

  @override
  Widget build(BuildContext context) {
    final summaryAsync = ref.watch(reviewSummaryProvider(widget.productId));
    final listKey = (id: widget.productId, sort: _recentFirst ? 'recent' : 'helpful');
    final reviewsAsync = ref.watch(productReviewsProvider(listKey));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Ratings & reviews', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        summaryAsync.when(
          loading: () => const LinearProgressIndicator(),
          error: (_, s) => const SizedBox.shrink(),
          data: (summary) => Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.divider),
            ),
            child: Row(
              children: [
                Column(
                  children: [
                    Text(
                      summary.avgRating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    StarRow(value: summary.avgRating),
                    const SizedBox(height: 4),
                    Text(
                      '${summary.reviewCount} ratings',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    children: List.generate(5, (i) {
                      final star = 5 - i;
                      final count = summary.histogram[star] ?? 0;
                      final maxBin = [
                        ...summary.histogram.values,
                        1,
                      ].reduce((a, b) => a > b ? a : b);
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 30,
                              child: Text(
                                '$star★',
                                style: const TextStyle(fontSize: 11),
                              ),
                            ),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: count / maxBin,
                                  minHeight: 6,
                                  backgroundColor: AppColors.divider,
                                  color: const Color(0xFFF59E0B),
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 24,
                              child: Text(
                                '$count',
                                textAlign: TextAlign.right,
                                style: const TextStyle(fontSize: 11),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            ChoiceChip(
              label: const Text('Most helpful'),
              selected: !_recentFirst,
              onSelected: (_) => setState(() => _recentFirst = false),
            ),
            const SizedBox(width: 8),
            ChoiceChip(
              label: const Text('Most recent'),
              selected: _recentFirst,
              onSelected: (_) => setState(() => _recentFirst = true),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () => _openWriteSheet(context),
              icon: const Icon(Icons.rate_review_outlined, size: 16),
              label: const Text('Write a review'),
            ),
          ],
        ),
        reviewsAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, s) => const Text('Could not load reviews.'),
          data: (reviews) {
            if (reviews.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('No reviews yet — be the first!'),
              );
            }
            return Column(
              children: reviews
                  .map((r) => _ReviewTile(
                        reviewId: r.id,
                        rating: r.rating,
                        title: r.title,
                        body: r.body,
                        reviewer: r.reviewer,
                        verified: r.verifiedPurchase,
                        helpful: r.helpfulCount,
                        voted: r.voted,
                        sellerResponse: r.sellerResponse,
                        date: r.createdAt,
                      ))
                  .toList(),
            );
          },
        ),
      ],
    );
  }

  void _openWriteSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: _WriteReviewSheet(productId: widget.productId),
      ),
    ).then((_) {
      ref.invalidate(reviewSummaryProvider(widget.productId));
      ref.invalidate(
        productReviewsProvider((id: widget.productId, sort: 'helpful')),
      );
      ref.invalidate(
        productReviewsProvider((id: widget.productId, sort: 'recent')),
      );
    });
  }
}

class _ReviewTile extends ConsumerStatefulWidget {
  const _ReviewTile({
    required this.reviewId,
    required this.rating,
    required this.title,
    required this.body,
    required this.reviewer,
    required this.verified,
    required this.helpful,
    required this.voted,
    required this.date,
    this.sellerResponse,
  });

  final String reviewId;
  final int rating;
  final String title;
  final String body;
  final String reviewer;
  final bool verified;
  final int helpful;
  final bool voted;
  final String? sellerResponse;
  final DateTime date;

  @override
  ConsumerState<_ReviewTile> createState() => _ReviewTileState();
}

class _ReviewTileState extends ConsumerState<_ReviewTile> {
  late int _helpful = widget.helpful;
  late bool _voted = widget.voted;
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: AppColors.accentLight,
                child: Text(
                  widget.reviewer.isNotEmpty ? widget.reviewer[0].toUpperCase() : '?',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(widget.reviewer)),
              StarRow(value: widget.rating.toDouble(), size: 13),
            ],
          ),
          if (widget.title.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(widget.title, style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
          if (widget.verified)
            const Padding(
              padding: EdgeInsets.only(top: 2),
              child: Text(
                'Verified Purchase',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E7E34),
                ),
              ),
            ),
          if (widget.body.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(widget.body),
          ],
          if (widget.sellerResponse != null && widget.sellerResponse!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Response from SnapPrint: ${widget.sellerResponse}',
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
          const SizedBox(height: 8),
          InkWell(
            onTap: _busy ? null : _toggleVote,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: _voted ? AppColors.accent : AppColors.divider,
                ),
              ),
              child: Text(
                _helpful > 0 ? 'Helpful ($_helpful)' : 'Helpful',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _voted ? AppColors.accent : AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleVote() async {
    setState(() => _busy = true);
    try {
      final updated = await ref
          .read(customerDataSourceProvider)
          .voteHelpful(widget.reviewId, _voted);
      setState(() {
        _helpful = updated.helpfulCount;
        _voted = updated.voted;
      });
    } catch (_) {
      if (mounted) showErrorSnackbar(context, 'Please sign in to vote.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

class _WriteReviewSheet extends ConsumerStatefulWidget {
  const _WriteReviewSheet({required this.productId});
  final String productId;

  @override
  ConsumerState<_WriteReviewSheet> createState() => _WriteReviewSheetState();
}

class _WriteReviewSheetState extends ConsumerState<_WriteReviewSheet> {
  int _rating = 5;
  final _title = TextEditingController();
  final _body = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Write a review', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Row(
            children: List.generate(
              5,
              (i) => IconButton(
                onPressed: () => setState(() => _rating = i + 1),
                icon: Icon(
                  i < _rating ? Icons.star_rounded : Icons.star_border_rounded,
                  color: const Color(0xFFF59E0B),
                  size: 32,
                ),
              ),
            ),
          ),
          TextField(
            controller: _title,
            maxLength: 120,
            decoration: const InputDecoration(labelText: 'Headline'),
          ),
          TextField(
            controller: _body,
            maxLines: 4,
            maxLength: 2000,
            decoration: const InputDecoration(
              labelText: 'What did you like about the print?',
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          const SizedBox(height: 12),
          CustomButton(
            label: _busy ? 'Posting...' : 'Submit review',
            onPressed: _busy ? null : _submit,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (_title.text.trim().isEmpty && _body.text.trim().isEmpty) {
      setState(() => _error = 'Please add a headline or a few words.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(customerDataSourceProvider).createReview(
        widget.productId,
        {
          'rating': _rating,
          'title': _title.text.trim(),
          'body': _body.text.trim(),
        },
      );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      var msg = 'Could not post your review. Please try again.';
      if (e is AppException) {
        msg = e.message;
      } else if (e is DioException && e.error is AppException) {
        msg = (e.error as AppException).message;
      }
      setState(() => _error = msg);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
