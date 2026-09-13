class ReviewModel {
  const ReviewModel({
    required this.id,
    required this.productId,
    required this.rating,
    required this.title,
    required this.body,
    required this.reviewer,
    required this.verifiedPurchase,
    required this.helpfulCount,
    required this.voted,
    this.sellerResponse,
    required this.createdAt,
  });

  final String id;
  final String productId;
  final int rating;
  final String title;
  final String body;
  final String reviewer;
  final bool verifiedPurchase;
  final int helpfulCount;
  final bool voted;
  final String? sellerResponse;
  final DateTime createdAt;

  factory ReviewModel.fromJson(Map<String, dynamic> json) => ReviewModel(
        id: json['id'].toString(),
        productId: json['product_id'].toString(),
        rating: (json['rating'] as num).toInt(),
        title: json['title'] as String? ?? '',
        body: json['body'] as String? ?? '',
        reviewer: json['reviewer'] as String? ?? 'Customer',
        verifiedPurchase: json['verified_purchase'] as bool? ?? false,
        helpfulCount: (json['helpful_count'] as num?)?.toInt() ?? 0,
        voted: json['voted'] as bool? ?? false,
        sellerResponse: json['seller_response'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}

class ReviewSummaryModel {
  const ReviewSummaryModel({
    required this.avgRating,
    required this.reviewCount,
    required this.histogram,
  });

  final double avgRating;
  final int reviewCount;
  final Map<int, int> histogram;

  factory ReviewSummaryModel.fromJson(Map<String, dynamic> json) {
    final raw = (json['histogram'] as Map?) ?? {};
    return ReviewSummaryModel(
      avgRating: (json['avg_rating'] as num? ?? 0).toDouble(),
      reviewCount: (json['review_count'] as num? ?? 0).toInt(),
      histogram: {
        for (var s = 1; s <= 5; s++)
          s: (raw['$s'] as num?)?.toInt() ?? 0,
      },
    );
  }
}
