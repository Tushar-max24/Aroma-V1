import 'package:flutter/material.dart';

class ReviewSection extends StatefulWidget {
  final List<Map<String, dynamic>> reviews;
  final String recipeName;

  const ReviewSection({
    super.key,
    required this.reviews,
    required this.recipeName,
  });

  @override
  State<ReviewSection> createState() => _ReviewSectionState();
}

class _ReviewSectionState extends State<ReviewSection> {
  late List<Map<String, dynamic>> _reviews;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _reviews = widget.reviews;
    _generateAIReviews();
  }

  Future<void> _generateAIReviews() async {
    // Simulate AI review generation
    await Future.delayed(const Duration(seconds: 1));
    
    final aiReviews = [
      {
        'name': 'AI Foodie',
        'comment': 'This ${widget.recipeName} recipe is absolutely delicious! The flavors are perfectly balanced and the instructions were easy to follow.',
        'rating': 5,
        'isAI': true,
        'timeAgo': 'Just now',
      },
      {
        'name': 'ChefBot',
        'comment': 'As an AI with extensive recipe knowledge, I can confirm this is one of the best ${widget.recipeName} recipes I\'ve analyzed. The cooking time and temperature are spot on!',
        'rating': 5,
        'isAI': true,
        'timeAgo': '1 min ago',
      },
    ];

    setState(() {
      _reviews = [..._reviews, ...aiReviews];
      _isLoading = false;
    });
  }

  double get averageRating {
    if (_reviews.isEmpty) return 0.0;
    final total = _reviews.fold<double>(
      0,
      (sum, r) => sum + (r["rating"] ?? 5).toDouble(),
    );
    return (total / _reviews.length).clamp(0.0, 5.0);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// ---- HEADER ----
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Reviews",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),

            if (_reviews.isNotEmpty)
              Row(
                children: [
                  const Text(
                    "Rating",
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.star,
                            size: 16, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(
                          averageRating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),

        const SizedBox(height: 10),

        /// ---- META ----
        Row(
          children: [
            Text(
              _reviews.isEmpty
                  ? "No reviews yet"
                  : "${_reviews.length} ${_reviews.length == 1 ? 'Review' : 'Reviews'}",
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
            if (_reviews.isNotEmpty) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.auto_awesome, size: 12, color: Colors.blue),
                    const SizedBox(width: 2),
                    Text(
                      'AI Enhanced',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue.shade800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),

        const SizedBox(height: 22),

        /// ---- LOADING / EMPTY ----
        if (_isLoading)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 12),
                const Text(
                  "AI is generating reviews...",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
          )
        else
          /// ---- SHOW REVIEWS ----
          Column(
            children: _reviews.take(2).map((review) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// Avatar with AI badge
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: (review['isAI'] ?? false)
                              ? Colors.blue.shade100
                              : Colors.orange.shade100,
                          child: Text(
                            (review["name"] ?? "U")
                                .toString()
                                .substring(0, 1)
                                .toUpperCase(),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: (review['isAI'] ?? false)
                                  ? Colors.blue.shade800
                                  : Colors.orange.shade800,
                            ),
                          ),
                        ),
                        if (review['isAI'] ?? false)
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.auto_awesome,
                                size: 12,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(width: 14),

                    /// Name + Comment
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            review["name"] ?? "Anonymous",
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              ...List.generate(
                                5,
                                (index) => Icon(
                                  index < (review['rating'] ?? 5)
                                      ? Icons.star
                                      : Icons.star_border,
                                  size: 16,
                                  color: Colors.amber,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                review['timeAgo'] ?? '',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            review["comment"] ?? "",
                            style: const TextStyle(
                              fontSize: 14,
                              height: 1.5,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),

        const SizedBox(height: 12),

        /// ---- ACTION BUTTONS ----
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _actionButton(Icons.edit, "Write review"),
            _actionButton(Icons.read_more, "Read More"),
          ],
        ),

        const SizedBox(height: 10),
      ],
    );
  }

  Widget _actionButton(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFFFF6A45), size: 20),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFFFF6A45),
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
