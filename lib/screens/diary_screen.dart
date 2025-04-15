import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'dart:developer' as developer;
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

class DiaryScreen extends StatefulWidget {
  const DiaryScreen({super.key});

  @override
  State<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends State<DiaryScreen> {
  List<Map<String, dynamic>> notes = [];
  Map<String, dynamic>? selectedNote;
  List<String> selectedTags = [];
  bool isLoading = true;
  bool modalVisible = false;
  bool hasError = false;
  String errorMessage = '';
  bool hasConnectivity = true;
  Timer? _connectivityTimer;

  // Define fallback sample note in case the API fails
  final List<Map<String, dynamic>> sampleNotes = [
    {
      'id': 'hola.md',
      'title': 'Hola!',
      'date': '2024-11-14T18:30:00',
      'lastEdited': '2024-11-14T18:30:00',
      'tags': ['personal'],
      'isPinned': true,
      'content':
          'My name is Shishir, and I am an embedded systems designer. I enjoy engaging with the technology community and connecting with others who share my passions. I enjoy scrolling through memes, watching movies and reading articles. I am happy you have stumbled upon my site, and I hope you find something of interest. Thank you for visiting!',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadNotesFromRemote();
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
      if (!hasConnectivity) {
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
        if (!hasConnectivity) {
          setState(() {
            hasConnectivity = true;
          });
          await _loadNotesFromRemote();
        }
      }
    } catch (e) {
      if (hasConnectivity) {
        setState(() {
          hasConnectivity = false;
        });
      }
    }
  }

  Future<void> _loadNotesFromRemote() async {
    try {
      setState(() {
        isLoading = true;
        hasError = false;
      });

      // Try different possible API endpoints for the list of notes
      final possibleListUrls = [
        'https://shishir-dey.github.io/content/notes/metadata.json',
        'https://raw.githubusercontent.com/shishir-dey/shishir-dey.github.io/main/content/notes/metadata.json',
        'https://api.github.com/repos/shishir-dey/shishir-dey.github.io/contents/content/notes',
      ];

      http.Response? listResponse;
      String baseUrl = '';

      for (final url in possibleListUrls) {
        developer.log('Trying to fetch notes list from: $url');
        try {
          final tempResponse = await http
              .get(Uri.parse(url))
              .timeout(const Duration(seconds: 10));

          developer.log('Response status code: ${tempResponse.statusCode}');

          if (tempResponse.statusCode == 200) {
            listResponse = tempResponse;
            // Extract the base URL for individual note fetching
            if (url.contains('github.io')) {
              baseUrl = 'https://shishir-dey.github.io/content/notes/';
            } else if (url.contains('raw.githubusercontent.com')) {
              baseUrl =
                  'https://raw.githubusercontent.com/shishir-dey/shishir-dey.github.io/main/content/notes/';
            }
            developer.log('Successfully connected to: $url');
            setState(() {
              hasConnectivity = true;
            });
            break;
          } else {
            developer.log(
              'Failed with status ${tempResponse.statusCode} from: $url',
            );
          }
        } catch (e) {
          developer.log('Error connecting to $url: $e');
          continue;
        }
      }

      if (listResponse == null) {
        setState(() {
          hasConnectivity = false;
        });
        throw Exception('All API endpoints for note list failed');
      }

      // Parse the list of note filenames
      List<String> noteFiles = [];

      try {
        final jsonData = json.decode(listResponse.body);

        if (jsonData is List) {
          // Direct list of filenames
          noteFiles = jsonData.map((item) => item.toString()).toList();
        } else if (jsonData is Map && jsonData.containsKey('content')) {
          // GitHub API returns content in base64
          final content = utf8.decode(base64.decode(jsonData['content']));
          final decodedContent = json.decode(content);
          if (decodedContent is List) {
            noteFiles = decodedContent.map((item) => item.toString()).toList();
          }
        } else if (jsonData is Map && jsonData.containsKey('notes')) {
          // If the response has a 'notes' property containing the list
          final notesData = jsonData['notes'];
          if (notesData is List) {
            noteFiles = notesData.map((item) => item.toString()).toList();
          }
        }
      } catch (e) {
        developer.log('Error parsing note list: $e');
        throw Exception('Failed to parse note list: $e');
      }

      if (noteFiles.isEmpty) {
        developer.log('No note files found in the response');
        throw Exception('No note filenames found in the API response');
      }

      developer.log('Found ${noteFiles.length} note files: $noteFiles');

      // Fetch individual note files
      List<Map<String, dynamic>> fetchedNotes = [];
      int successCount = 0;

      for (final noteFile in noteFiles) {
        final noteUrl = '$baseUrl$noteFile';
        developer.log('Fetching note: $noteUrl');

        try {
          final noteResponse = await http
              .get(Uri.parse(noteUrl))
              .timeout(const Duration(seconds: 5));

          if (noteResponse.statusCode == 200) {
            // Parse the markdown content with frontmatter
            final content = noteResponse.body;
            final Map<String, dynamic> noteData = {'id': noteFile};

            // Extract frontmatter between --- markers
            if (content.startsWith('---')) {
              final endOfFrontmatter = content.indexOf('---', 3);
              if (endOfFrontmatter != -1) {
                final frontmatter =
                    content.substring(3, endOfFrontmatter).trim();
                final lines = frontmatter.split('\n');

                for (final line in lines) {
                  if (line.contains(':')) {
                    final parts = line.split(':');
                    final key = parts[0].trim();
                    var value = parts.sublist(1).join(':').trim();

                    // Handle quoted values
                    if (value.startsWith('"') && value.endsWith('"')) {
                      value = value.substring(1, value.length - 1);
                    }

                    // Handle tags which are in format: tags: ["tag1", "tag2"]
                    if (key == 'tags') {
                      try {
                        final tagString = value.replaceAll(
                          "'",
                          '"',
                        ); // Normalize quotes
                        final tagList = json.decode(tagString);
                        noteData['tags'] = tagList;
                      } catch (e) {
                        // Fallback for simple tag lists
                        noteData['tags'] =
                            value.split(',').map((t) => t.trim()).toList();
                      }
                    } else if (key == 'pinned') {
                      noteData['isPinned'] = value.toLowerCase() == 'true';
                    } else {
                      noteData[key] = value;
                    }
                  }
                }

                // Extract the content after frontmatter
                noteData['content'] =
                    content.substring(endOfFrontmatter + 3).trim();
              } else {
                noteData['content'] = content;
              }
            } else {
              noteData['content'] = content;
            }

            // Set lastEdited to date if present, or current time
            noteData['lastEdited'] =
                noteData['date'] ?? DateTime.now().toIso8601String();

            fetchedNotes.add(noteData);
            successCount++;
            developer.log(
              'Successfully parsed note: ${noteData['title'] ?? noteFile}',
            );
          } else {
            developer.log(
              'Failed to fetch note $noteFile: ${noteResponse.statusCode}',
            );
          }
        } catch (e) {
          developer.log('Error fetching note $noteFile: $e');
        }
      }

      if (fetchedNotes.isEmpty) {
        throw Exception('Could not fetch any individual notes');
      }

      developer.log(
        'Successfully loaded $successCount out of ${noteFiles.length} notes',
      );

      setState(() {
        notes = fetchedNotes;
        isLoading = false;
      });
    } catch (e) {
      developer.log('Error loading notes: $e');
      developer.log('Stack trace: ${StackTrace.current}');

      setState(() {
        // Use sample notes as fallback
        notes = sampleNotes;
        isLoading = false;
        hasError = true;

        // Provide more detailed error message (only for debugging purposes)
        String detailedError = e.toString();
        if (e is Exception) {
          detailedError = 'Exception: $e';
        } else if (e is Error) {
          detailedError = 'Error: $e';
        } else if (e is http.ClientException) {
          detailedError = 'Network error: $e';
        } else if (e is FormatException) {
          detailedError = 'Format error: $e';
        }

        errorMessage = detailedError;
      });
    }
  }

  // Get all unique tags
  List<String> get allTags {
    final Set<String> tags = {};
    for (final note in notes) {
      if (note['tags'] != null && note['tags'] is List) {
        for (final tag in (note['tags'] as List)) {
          tags.add(tag.toString());
        }
      }
    }
    return tags.toList();
  }

  // Filter notes based on selected tags
  List<Map<String, dynamic>> get filteredNotes {
    if (selectedTags.isEmpty) {
      return notes;
    }

    return notes.where((note) {
      if (note['tags'] == null || note['tags'] is! List) {
        return false;
      }

      for (final tag in selectedTags) {
        if (!(note['tags'] as List).contains(tag)) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  void _openModal(Map<String, dynamic> note) {
    developer.log('Opening modal for note: ${note['title']}');
    setState(() {
      selectedNote = note;
      modalVisible = true;
    });
  }

  void _closeModal() {
    setState(() {
      modalVisible = false;
      selectedNote = null;
    });
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'Unknown date';

    try {
      // Remove quotes if present
      String cleanDateString = dateString;
      if ((cleanDateString.startsWith('"') && cleanDateString.endsWith('"')) ||
          (cleanDateString.startsWith("'") && cleanDateString.endsWith("'"))) {
        cleanDateString = cleanDateString.substring(
          1,
          cleanDateString.length - 1,
        );
      }

      final date = DateTime.parse(cleanDateString);
      final formatter = DateFormat('MMM d, y h:mm a');
      return formatter.format(date);
    } catch (e) {
      developer.log('Error parsing date: $dateString, error: $e');
      return 'Unknown date';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CupertinoActivityIndicator(radius: 20));
    }

    if (notes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'No notes available',
              style: TextStyle(fontSize: 18, color: CupertinoColors.black),
            ),
            if (hasError)
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  errorMessage,
                  style: TextStyle(
                    fontSize: 14,
                    color: CupertinoColors.systemGrey,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            const SizedBox(height: 20),
            CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              color: CupertinoColors.activeBlue,
              onPressed: _loadNotesFromRemote,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    // Main content with RefreshIndicator for pull-to-refresh
    Widget mainContent = CustomScrollView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      slivers: [
        // Pull-to-refresh control
        CupertinoSliverRefreshControl(onRefresh: _loadNotesFromRemote),

        // Tags section
        SliverToBoxAdapter(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children:
                    allTags.map((tag) {
                      final isSelected = selectedTags.contains(tag);
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: () {
                            setState(() {
                              if (isSelected) {
                                selectedTags.remove(tag);
                              } else {
                                selectedTags.add(tag);
                              }
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  isSelected
                                      ? CupertinoColors.activeBlue
                                      : CupertinoColors.systemGrey5,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              '#$tag',
                              style: TextStyle(
                                color:
                                    isSelected
                                        ? CupertinoColors.white
                                        : CupertinoColors.black,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
              ),
            ),
          ),
        ),

        // Notes grid
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.75,
            ),
            delegate: SliverChildBuilderDelegate((context, index) {
              final note = filteredNotes[index];
              return GestureDetector(
                onTap: () => _openModal(note),
                child: Transform.translate(
                  offset: const Offset(0, -1),
                  child: Container(
                    decoration: BoxDecoration(
                      color: CupertinoColors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: CupertinoColors.activeBlue.withAlpha(20),
                          blurRadius: 8,
                          spreadRadius: 1,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title and pin icon
                          Container(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        note['title'] ?? 'Untitled',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: CupertinoColors.black,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (note['url'] != null)
                                        GestureDetector(
                                          onTap: () {
                                            launchUrl(
                                              Uri.parse(note['url']),
                                              mode:
                                                  LaunchMode
                                                      .externalApplication,
                                            );
                                          },
                                          child: const Padding(
                                            padding: EdgeInsets.only(top: 2),
                                            child: Text(
                                              'View ↗',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color:
                                                    CupertinoColors
                                                        .activeOrange,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                if (note['isPinned'] == true)
                                  const Icon(
                                    CupertinoIcons.pin_fill,
                                    size: 16,
                                    color: CupertinoColors.activeBlue,
                                  ),
                              ],
                            ),
                          ),

                          // Content preview
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              child: Text(
                                note['content'] ?? 'No content',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: CupertinoColors.black,
                                ),
                                maxLines: 5,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),

                          // Date
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  CupertinoIcons.clock,
                                  size: 12,
                                  color: CupertinoColors.systemGrey,
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    _formatDate(note['lastEdited']),
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: CupertinoColors.systemGrey,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Tags
                          if (note['tags'] != null && note['tags'] is List)
                            Padding(
                              padding: const EdgeInsets.only(
                                left: 12,
                                right: 12,
                                bottom: 12,
                              ),
                              child: Wrap(
                                spacing: 4,
                                runSpacing: 4,
                                children:
                                    (note['tags'] as List).map<Widget>((tag) {
                                      return Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: CupertinoColors.activeBlue
                                              .withAlpha(25),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Text(
                                          '#$tag',
                                          style: const TextStyle(
                                            fontSize: 10,
                                            color: CupertinoColors.activeBlue,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      );
                                    }).toList(),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }, childCount: filteredNotes.length),
          ),
        ),
      ],
    );

    return Stack(
      children: [
        // Main content with proper padding when no connectivity
        Column(
          children: [
            // No connectivity notification
            if (!hasConnectivity && !isLoading)
              Container(
                color: CupertinoColors.systemRed.withOpacity(0.9),
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
            Expanded(child: mainContent),
          ],
        ),

        // Modal for note detail - using Stack to position it over everything
        if (modalVisible && selectedNote != null) _buildNoteModal(context),
      ],
    );
  }

  Widget _buildNoteModal(BuildContext context) {
    // Calculate modal size - 85% width, 50% height of screen
    final size = MediaQuery.of(context).size;
    final modalWidth = size.width * 0.85;
    final modalHeight = size.height * 0.5;

    return GestureDetector(
      onTap: _closeModal,
      child: Container(
        color: CupertinoColors.black.withAlpha(150),
        width: double.infinity,
        height: double.infinity,
        child: Center(
          child: GestureDetector(
            onTap: () {}, // Prevent taps from closing modal when tapping inside
            child: Container(
              width: modalWidth,
              height: modalHeight,
              decoration: BoxDecoration(
                color: CupertinoColors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: CupertinoColors.black.withAlpha(70),
                    blurRadius: 16,
                    spreadRadius: 0,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Column(
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: CupertinoColors.systemGrey5,
                            width: 1,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              selectedNote!['title'] ?? 'Untitled',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: CupertinoColors.black,
                              ),
                            ),
                          ),
                          CupertinoButton(
                            padding: EdgeInsets.zero,
                            onPressed: _closeModal,
                            minimumSize: Size(24, 24),
                            child: const Icon(
                              CupertinoIcons.xmark,
                              color: CupertinoColors.systemGrey,
                              size: 22,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Content area
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Note content
                            Text(
                              selectedNote!['content'] ?? 'No content',
                              style: const TextStyle(
                                fontSize: 16,
                                height: 1.5,
                                color: CupertinoColors.black,
                              ),
                            ),

                            const SizedBox(height: 20),

                            // Date
                            Row(
                              children: [
                                const Icon(
                                  CupertinoIcons.clock,
                                  size: 14,
                                  color: CupertinoColors.systemGrey,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _formatDate(selectedNote!['lastEdited']),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: CupertinoColors.systemGrey,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 12),

                            // Tags
                            if (selectedNote!['tags'] != null &&
                                selectedNote!['tags'] is List)
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children:
                                    (selectedNote!['tags'] as List).map<Widget>(
                                      (tag) {
                                        return Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: CupertinoColors.activeBlue
                                                .withAlpha(25),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Text(
                                            '#$tag',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: CupertinoColors.activeBlue,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        );
                                      },
                                    ).toList(),
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
    );
  }

  // Helper for minimum value
  int min(int a, int b) => a < b ? a : b;
}
