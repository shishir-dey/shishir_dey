import 'package:flutter/cupertino.dart';
import 'dart:math' as math;

class PhotographyScreen extends StatefulWidget {
  const PhotographyScreen({super.key});

  @override
  State<PhotographyScreen> createState() => _PhotographyScreenState();
}

class _PhotographyScreenState extends State<PhotographyScreen> {
  final List<String> _categories = [
    'All',
    'Nature',
    'Urban',
    'Travel',
    'Architecture',
    'Portrait',
    'Abstract',
  ];

  String _selectedCategory = 'All';

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // Categories horizontal scroll - now at the very top
        SliverToBoxAdapter(
          child: SizedBox(
            height: 56, // Increased height to prevent vertical clipping
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: 8,
              ),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = category == _selectedCategory;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedCategory = category;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isSelected
                              ? const Color.fromRGBO(
                                80,
                                75,
                                65,
                                1,
                              ) // Darker vintage brown
                              : const Color.fromRGBO(
                                237,
                                230,
                                209,
                                1,
                              ), // Light vintage cream
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color.fromRGBO(
                          180,
                          170,
                          150,
                          1,
                        ), // Vintage border
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        category,
                        style: TextStyle(
                          color:
                              isSelected
                                  ? const Color.fromRGBO(
                                    237,
                                    230,
                                    209,
                                    1,
                                  ) // Light cream text
                                  : CupertinoColors.black, // Black text
                          fontSize: 14,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),

        // Photo posts
        SliverPadding(
          padding: const EdgeInsets.only(top: 8),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => Padding(
                padding: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
                child: _buildPhotoPost(context, index),
              ),
              childCount:
                  10, // Placeholder count, will be replaced with actual data
            ),
          ),
        ),

        // Bottom padding to ensure the last item is fully visible
        const SliverToBoxAdapter(child: SizedBox(height: 20)),
      ],
    );
  }

  Widget _buildPhotoPost(BuildContext context, int index) {
    // Generate random heights for placeholders
    final random = math.Random();
    final aspectRatio = 1.0 + random.nextDouble() * 0.5; // Between 1.0 and 1.5

    // Select a random category for the placeholder
    final category =
        _categories[random.nextInt(_categories.length - 1) + 1]; // Skip "All"

    // Generate caption and location that will be shared with the detail view
    final caption = _generateRandomCaption();
    final location = _getRandomLocation();

    return Container(
      decoration: BoxDecoration(
        color: const Color.fromRGBO(245, 240, 225, 1), // Vintage paper color
        borderRadius: BorderRadius.circular(16), // More rounded corners
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.black.withAlpha(20),
            blurRadius: 6,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: const Color.fromRGBO(210, 200, 180, 1).withAlpha(127),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Photo content
          GestureDetector(
            onTap:
                () => _showPhotoDetail(
                  context,
                  index,
                  category,
                  aspectRatio,
                  caption,
                  location,
                ),
            child: Hero(
              tag: 'photo_$index',
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                child: AspectRatio(
                  aspectRatio: aspectRatio,
                  child: Container(
                    color: _getCategoryColor(category).withAlpha(25),
                    child: Stack(
                      children: [
                        Center(
                          child: Icon(
                            CupertinoIcons.photo,
                            size: 50,
                            color: _getCategoryColor(category).withAlpha(178),
                          ),
                        ),
                        Positioned(
                          left: 12,
                          bottom: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getCategoryColor(category).withAlpha(51),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color.fromRGBO(
                                  210,
                                  200,
                                  180,
                                  0.5,
                                ).withAlpha(127),
                                width: 0.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  CupertinoIcons.location,
                                  color: Color.fromRGBO(245, 240, 225, 1),
                                  size: 12,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  location,
                                  style: const TextStyle(
                                    color: Color.fromRGBO(245, 240, 225, 1),
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Caption with category tag next to it
          Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              alignment: WrapAlignment.start,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              children: [
                // Caption text
                Text(
                  caption,
                  style: const TextStyle(
                    fontSize: 13,
                    color: CupertinoColors.black,
                  ),
                ),
                // Category tag inline after caption
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _getCategoryColor(category).withAlpha(20),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _getCategoryColor(category).withAlpha(127),
                      width: 0.5,
                    ),
                  ),
                  child: Text(
                    category,
                    style: TextStyle(
                      color: CupertinoColors.black,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showPhotoDetail(
    BuildContext context,
    int index,
    String category,
    double aspectRatio,
    String caption,
    String location,
  ) {
    showCupertinoModalPopup(
      context: context,
      builder:
          (context) => Container(
            color: const Color.fromRGBO(
              50,
              45,
              40,
              1,
            ), // Dark vintage background
            child: SafeArea(
              child: Column(
                children: [
                  // Navigation bar - simplified without category tag and share button
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Icon(
                            CupertinoIcons.xmark,
                            color: Color.fromRGBO(245, 240, 225, 1),
                          ),
                        ),
                        const Spacer(), // To keep the X icon on the left
                      ],
                    ),
                  ),

                  // Photo
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Hero(
                        tag: 'photo_$index',
                        child: Center(
                          child: Container(
                            margin: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color.fromRGBO(
                                  210,
                                  200,
                                  180,
                                  0.5,
                                ).withAlpha(127),
                                width: 2,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: AspectRatio(
                                aspectRatio: aspectRatio,
                                child: Container(
                                  color: _getCategoryColor(
                                    category,
                                  ).withAlpha(25),
                                  child: Center(
                                    child: Icon(
                                      CupertinoIcons.photo,
                                      size: 100,
                                      color: _getCategoryColor(
                                        category,
                                      ).withAlpha(178),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Photo details - caption with inline tag and location only
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: const Color.fromRGBO(50, 45, 40, 1),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Caption with inline category tag
                        Wrap(
                          alignment: WrapAlignment.start,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          children: [
                            // Caption
                            Text(
                              caption,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Color.fromRGBO(245, 240, 225, 1),
                              ),
                            ),
                            // Category tag
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: _getCategoryColor(
                                  category,
                                ).withAlpha(51),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _getCategoryColor(
                                    category,
                                  ).withAlpha(127),
                                  width: 0.5,
                                ),
                              ),
                              child: Text(
                                category,
                                style: TextStyle(
                                  color: _getCategoryColor(category),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Location only - no date/timestamp
                        Row(
                          children: [
                            const Icon(
                              CupertinoIcons.location,
                              color: Color.fromRGBO(210, 200, 180, 1),
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              location,
                              style: const TextStyle(
                                color: Color.fromRGBO(210, 200, 180, 1),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Nature':
        return const Color.fromRGBO(105, 125, 95, 1); // Vintage green
      case 'Urban':
        return const Color.fromRGBO(90, 110, 140, 1); // Vintage blue
      case 'Travel':
        return const Color.fromRGBO(160, 120, 85, 1); // Vintage brown
      case 'Architecture':
        return const Color.fromRGBO(100, 100, 130, 1); // Vintage indigo
      case 'Portrait':
        return const Color.fromRGBO(150, 100, 110, 1); // Vintage rose
      case 'Abstract':
        return const Color.fromRGBO(120, 100, 140, 1); // Vintage purple
      default:
        return const Color.fromRGBO(120, 115, 110, 1); // Vintage grey
    }
  }

  String _generateRandomCaption() {
    final captions = [
      'Capturing moments in time',
      'The beauty of nature',
      'Urban exploration',
      'Light and shadow play',
      'Street photography',
      'Architecture details',
      'Travel memories',
      'Patterns and textures',
      'Minimalist composition',
      'Colors of life',
    ];

    return captions[math.Random().nextInt(captions.length)];
  }

  String _getRandomLocation() {
    final locations = [
      'New York',
      'Tokyo',
      'Paris',
      'London',
      'Sydney',
      'Mumbai',
      'Barcelona',
      'San Francisco',
      'Seoul',
      'Berlin',
    ];

    return locations[math.Random().nextInt(locations.length)];
  }
}
