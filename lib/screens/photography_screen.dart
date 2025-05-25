import 'package:flutter/cupertino.dart';
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;

class PhotographyScreen extends StatefulWidget {
  const PhotographyScreen({super.key});

  @override
  State<PhotographyScreen> createState() => _PhotographyScreenState();
}

class _PhotographyScreenState extends State<PhotographyScreen> {
  final List<String> _categories = ['All'];
  String _selectedCategory = 'All';
  List<PhotoItem> _photos = [];
  bool _isLoading = true;
  bool _hasConnectivity = true;
  Timer? _connectivityTimer;

  // Map to store image aspect ratios
  final Map<String, double> _imageAspectRatios = {};

  @override
  void initState() {
    super.initState();
    _fetchPhotos();
    // Start connectivity check timer
    _startConnectivityTimer();
  }

  @override
  void dispose() {
    _connectivityTimer?.cancel();
    super.dispose();
  }

  void _startConnectivityTimer() {
    _connectivityTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!_hasConnectivity) {
        _checkConnectivityAndLoad();
      }
    });
  }

  Future<void> _checkConnectivityAndLoad() async {
    try {
      final response = await http
          .head(Uri.parse('https://www.google.com'))
          .timeout(const Duration(seconds: 5));

      // If we get a response, we have connectivity
      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (!_hasConnectivity) {
          setState(() {
            _hasConnectivity = true;
          });
          await _fetchPhotos();
        }
      }
    } catch (e) {
      if (_hasConnectivity) {
        setState(() {
          _hasConnectivity = false;
        });
      }
    }
  }

  Future<void> _fetchPhotos() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final response = await http.get(
        Uri.parse('https://shishir-dey.github.io/content/photos/metadata.json'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _photos = data.map((item) => PhotoItem.fromJson(item)).toList();
          _isLoading = false;
          _hasConnectivity = true;

          // Extract unique categories from tags
          final Set<String> uniqueTags = {};
          for (var photo in _photos) {
            if (photo.tags.isNotEmpty) {
              uniqueTags.addAll(photo.tags);
            }
          }

          // Update categories list
          _categories.clear();
          _categories.add('All');
          _categories.addAll(uniqueTags);
        });

        // Pre-load images to determine aspect ratios
        for (var photo in _photos) {
          _preloadImage(photo.url);
        }
      } else {
        setState(() {
          _isLoading = false;
          _hasConnectivity = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasConnectivity = false;
      });
    }
  }

  Future<void> _preloadImage(String imageUrl) async {
    final imageProvider = NetworkImage(imageUrl);
    final imageStream = imageProvider.resolve(ImageConfiguration.empty);
    final completer = Completer<ImageInfo>();

    final imageStreamListener = ImageStreamListener(
      (ImageInfo info, bool synchronousCall) {
        if (!completer.isCompleted) {
          completer.complete(info);
        }
      },
      onError: (exception, stackTrace) {
        if (!completer.isCompleted) {
          completer.completeError(exception, stackTrace);
        }
      },
    );

    imageStream.addListener(imageStreamListener);

    try {
      final imageInfo = await completer.future;
      final aspectRatio = imageInfo.image.width / imageInfo.image.height;

      setState(() {
        _imageAspectRatios[imageUrl] = aspectRatio;
      });
    } catch (e) {
      // Default to landscape (4:3) if error
      setState(() {
        _imageAspectRatios[imageUrl] = 4 / 3;
      });
    } finally {
      imageStream.removeListener(imageStreamListener);
    }
  }

  // Get aspect ratio for an image URL
  double _getAspectRatio(String url) {
    // If we have calculated the aspect ratio, return it
    if (_imageAspectRatios.containsKey(url)) {
      final ratio = _imageAspectRatios[url]!;
      // If portrait (height > width), use 3:4 ratio
      if (ratio < 1.0) {
        return 3 / 4;
      }
      // If landscape (width > height), use 4:3 ratio
      else {
        return 4 / 3;
      }
    }

    // Default to 1:1 if not yet determined
    return 1.0;
  }

  List<PhotoItem> get _filteredPhotos {
    if (_selectedCategory == 'All') {
      return _photos;
    } else {
      return _photos
          .where((photo) => photo.tags.contains(_selectedCategory))
          .toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content = CustomScrollView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      slivers: [
        // Pull-to-refresh control
        CupertinoSliverRefreshControl(onRefresh: _fetchPhotos),

        // Categories horizontal scroll
        SliverToBoxAdapter(
          child: SizedBox(
            height: 56,
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
                              ? const Color.fromRGBO(80, 75, 65, 1)
                              : const Color.fromRGBO(237, 230, 209, 1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color.fromRGBO(180, 170, 150, 1),
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        category,
                        style: TextStyle(
                          color:
                              isSelected
                                  ? const Color.fromRGBO(237, 230, 209, 1)
                                  : CupertinoColors.black,
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

        // Loading indicator or empty state
        if (_isLoading)
          const SliverFillRemaining(
            child: Center(child: CupertinoActivityIndicator()),
          )
        else if (_filteredPhotos.isEmpty)
          const SliverFillRemaining(
            child: Center(
              child: Text(
                'No photos available',
                style: TextStyle(
                  color: CupertinoColors.systemGrey,
                  fontSize: 16,
                ),
              ),
            ),
          )
        else
          // Photo posts
          SliverPadding(
            padding: const EdgeInsets.only(top: 8),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => Padding(
                  padding: const EdgeInsets.only(
                    bottom: 16,
                    left: 16,
                    right: 16,
                  ),
                  child: _buildPhotoPost(context, index),
                ),
                childCount: _filteredPhotos.length,
              ),
            ),
          ),

        // Bottom padding
        const SliverToBoxAdapter(child: SizedBox(height: 20)),
      ],
    );

    return Column(
      children: [
        // No connectivity notification
        if (!_hasConnectivity && !_isLoading)
          Container(
            color: CupertinoColors.systemRed.withValues(alpha: 0.9),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 16,
                ),
                child: Row(
                  children: [
                    const Icon(
                      CupertinoIcons.wifi_slash,
                      color: CupertinoColors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'No internet connection - Showing offline content',
                        style: TextStyle(
                          color: CupertinoColors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: _checkConnectivityAndLoad,
                      minimumSize: Size(0, 0),
                      child: const Icon(
                        CupertinoIcons.refresh,
                        color: CupertinoColors.white,
                        size: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

        // Content area
        Expanded(child: content),
      ],
    );
  }

  Widget _buildPhotoPost(BuildContext context, int index) {
    final photo = _filteredPhotos[index];
    final aspectRatio = _getAspectRatio(photo.url);

    return Container(
      decoration: BoxDecoration(
        color: const Color.fromRGBO(245, 240, 225, 1),
        borderRadius: BorderRadius.circular(16),
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
            onTap: () => _showPhotoDetail(context, index),
            child: Hero(
              tag: 'photo_${photo.url}',
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                child: AspectRatio(
                  aspectRatio: aspectRatio,
                  child: Image.network(
                    photo.url,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: const Color.fromRGBO(237, 230, 209, 1),
                        child: const Center(
                          child: CupertinoActivityIndicator(),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: const Color.fromRGBO(237, 230, 209, 1),
                        child: const Center(
                          child: Icon(
                            CupertinoIcons.exclamationmark_triangle,
                            size: 40,
                            color: Color.fromRGBO(120, 115, 110, 1),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),

          // Caption and tags if available
          if (photo.caption.isNotEmpty || photo.tags.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Wrap(
                alignment: WrapAlignment.start,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                children: [
                  // Caption text if available
                  if (photo.caption.isNotEmpty)
                    Text(
                      photo.caption,
                      style: const TextStyle(
                        fontSize: 13,
                        color: CupertinoColors.black,
                      ),
                    ),

                  // First tag if available (as category)
                  if (photo.tags.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _getCategoryColor(
                          photo.tags.first,
                        ).withAlpha(20),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _getCategoryColor(
                            photo.tags.first,
                          ).withAlpha(127),
                          width: 0.5,
                        ),
                      ),
                      child: Text(
                        photo.tags.first,
                        style: const TextStyle(
                          color: CupertinoColors.black,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
            ),

          // Location if available
          if (photo.location.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 12, right: 12, bottom: 12),
              child: Row(
                children: [
                  const Icon(
                    CupertinoIcons.location,
                    color: Color.fromRGBO(120, 115, 110, 1),
                    size: 12,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    photo.location,
                    style: const TextStyle(
                      color: Color.fromRGBO(120, 115, 110, 1),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _showPhotoDetail(BuildContext context, int index) {
    final photo = _filteredPhotos[index];
    final String primaryTag = photo.tags.isNotEmpty ? photo.tags.first : '';
    final aspectRatio = _getAspectRatio(photo.url);
    final isPortrait = aspectRatio < 1.0;

    showCupertinoModalPopup(
      context: context,
      builder:
          (context) => Container(
            color: const Color.fromRGBO(50, 45, 40, 1),
            child: SafeArea(
              child: Column(
                children: [
                  // Navigation bar
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
                        const Spacer(),
                      ],
                    ),
                  ),

                  // Photo
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Hero(
                        tag: 'photo_${photo.url}',
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
                                  1,
                                ).withAlpha(127),
                                width: 2,
                              ),
                            ),
                            constraints: BoxConstraints(
                              // Adjust maximum width based on whether image is portrait or landscape
                              maxWidth:
                                  isPortrait
                                      ? MediaQuery.of(context).size.width * 0.7
                                      : MediaQuery.of(context).size.width - 32,
                              maxHeight:
                                  isPortrait
                                      ? MediaQuery.of(context).size.height * 0.7
                                      : MediaQuery.of(context).size.height *
                                          0.5,
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Image.network(
                                photo.url,
                                fit: BoxFit.contain,
                                loadingBuilder: (
                                  context,
                                  child,
                                  loadingProgress,
                                ) {
                                  if (loadingProgress == null) return child;
                                  return Container(
                                    color: const Color.fromRGBO(50, 45, 40, 1),
                                    width: double.infinity,
                                    height: 300,
                                    child: const Center(
                                      child: CupertinoActivityIndicator(),
                                    ),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: const Color.fromRGBO(50, 45, 40, 1),
                                    width: double.infinity,
                                    height: 300,
                                    child: const Center(
                                      child: Icon(
                                        CupertinoIcons.exclamationmark_triangle,
                                        size: 60,
                                        color: Color.fromRGBO(210, 200, 180, 1),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Photo details if available
                  if (photo.caption.isNotEmpty ||
                      photo.location.isNotEmpty ||
                      photo.tags.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      color: const Color.fromRGBO(50, 45, 40, 1),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Caption and first tag if available
                          if (photo.caption.isNotEmpty || primaryTag.isNotEmpty)
                            Wrap(
                              alignment: WrapAlignment.start,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 8,
                              children: [
                                // Caption
                                if (photo.caption.isNotEmpty)
                                  Text(
                                    photo.caption,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Color.fromRGBO(245, 240, 225, 1),
                                    ),
                                  ),

                                // First tag as category
                                if (primaryTag.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getCategoryColor(
                                        primaryTag,
                                      ).withAlpha(51),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: _getCategoryColor(
                                          primaryTag,
                                        ).withAlpha(127),
                                        width: 0.5,
                                      ),
                                    ),
                                    child: Text(
                                      primaryTag,
                                      style: TextStyle(
                                        color: _getCategoryColor(primaryTag),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                              ],
                            ),

                          // Location if available
                          if (photo.location.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 16),
                              child: Row(
                                children: [
                                  const Icon(
                                    CupertinoIcons.location,
                                    color: Color.fromRGBO(210, 200, 180, 1),
                                    size: 14,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    photo.location,
                                    style: const TextStyle(
                                      color: Color.fromRGBO(210, 200, 180, 1),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          // Timestamp if available
                          if (photo.timestamp.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Row(
                                children: [
                                  const Icon(
                                    CupertinoIcons.calendar,
                                    color: Color.fromRGBO(210, 200, 180, 1),
                                    size: 14,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    photo.timestamp,
                                    style: const TextStyle(
                                      color: Color.fromRGBO(210, 200, 180, 1),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
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
    final Map<String, Color> categoryColors = {
      'Nature': const Color.fromRGBO(105, 125, 95, 1),
      'Animals': const Color.fromRGBO(130, 105, 80, 1),
      'City': const Color.fromRGBO(90, 110, 140, 1),
      'Urban': const Color.fromRGBO(90, 110, 140, 1),
      'Travel': const Color.fromRGBO(160, 120, 85, 1),
      'Architecture': const Color.fromRGBO(100, 100, 130, 1),
      'Portrait': const Color.fromRGBO(150, 100, 110, 1),
      'Abstract': const Color.fromRGBO(120, 100, 140, 1),
    };

    return categoryColors[category] ?? const Color.fromRGBO(120, 115, 110, 1);
  }
}

class PhotoItem {
  final String url;
  final String location;
  final String caption;
  final List<String> tags;
  final String timestamp;

  PhotoItem({
    required this.url,
    required this.location,
    required this.caption,
    required this.tags,
    required this.timestamp,
  });

  factory PhotoItem.fromJson(Map<String, dynamic> json) {
    return PhotoItem(
      url: json['url'] ?? '',
      location: json['location'] ?? '',
      caption: json['caption'] ?? '',
      tags: List<String>.from(json['tags'] ?? []),
      timestamp: json['timestamp'] ?? '',
    );
  }
}
