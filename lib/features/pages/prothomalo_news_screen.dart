import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class ProthomAloNewsScreen extends StatefulWidget {
  const ProthomAloNewsScreen({super.key});

  @override
  _ProthomAloNewsScreenState createState() => _ProthomAloNewsScreenState();
}

class _ProthomAloNewsScreenState extends State<ProthomAloNewsScreen> {
  List<NewsItem> newsItems = [];
  bool isLoading = true;
  bool hasError = false;
  DateTime? lastUpdated;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    _fetchNews();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      _fetchMoreNews();
    }
  }

  Future<void> _fetchNews() async {
    setState(() {
      isLoading = true;
      hasError = false;
    });

    try {
      final response = await http
          .get(Uri.parse('https://www.prothomalo.com/collection/latest'))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final document = parse(response.body);
        final articles =
            document.querySelectorAll('.news_with_item, .wide-story-card');

        final List<NewsItem> extractedItems = [];

        for (var article in articles) {
          final titleElement = article.querySelector('.headline-title');
          final anchor = titleElement?.querySelector('a');
          final title = anchor?.text.trim() ?? 'No title';
          final link = anchor?.attributes['href'] ?? '';
          final timeElement =
              article.querySelector('.published-at, .published-time');
          final time = timeElement?.text.trim() ?? '';
          final categoryElement = article.querySelector('.sub-title');
          final category = categoryElement?.text.trim() ?? '';

          if (title.isNotEmpty && link.isNotEmpty) {
            extractedItems.add(NewsItem(
              title: title,
              url: link.startsWith('http')
                  ? link
                  : 'https://www.prothomalo.com$link',
              time: time,
              category: category,
              isVideo:
                  article.querySelector('.story-icon[href*="video-play"]') !=
                      null,
              isPhoto:
                  article.querySelector('.story-icon[href*="photo-camera"]') !=
                      null,
            ));
          }
        }

        setState(() {
          newsItems = extractedItems;
          lastUpdated = DateTime.now();
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load news (${response.statusCode})');
      }
    } catch (e) {
      setState(() {
        hasError = true;
        isLoading = false;
      });
      _showErrorSnackbar(e.toString());
    }
  }

  Future<void> _fetchMoreNews() async {
    // Implement pagination if needed
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[400],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        action: SnackBarAction(
          label: 'Retry',
          textColor: Colors.white,
          onPressed: _fetchNews,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFD),
      appBar: AppBar(
        title: Text(
          'প্রথম আলো',
          style: GoogleFonts.notoSansBengali(
            fontWeight: FontWeight.w700,
            fontSize: 22,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFE51A1B),
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFE51A1B),
                Color(0xFFC62828),
              ],
            ),
          ),
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchNews,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOut,
        ),
        backgroundColor: const Color(0xFFE51A1B),
        child: const Icon(Icons.arrow_upward, color: Colors.white),
      ),
    );
  }

  Widget _buildBody() {
    if (isLoading && newsItems.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFFE51A1B),
        ),
      );
    }

    if (hasError && newsItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.red[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load news',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchNews,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE51A1B),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: Text(
                'Try Again',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchNews,
      color: const Color(0xFFE51A1B),
      child: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        slivers: [
          if (lastUpdated != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.update,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Last updated: ${DateFormat('MMM dd, hh:mm a').format(lastUpdated!)}',
                      style: GoogleFonts.poppins(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final item = newsItems[index];
                return _NewsCard(
                  title: item.title,
                  time: item.time,
                  category: item.category,
                  onTap: () => _openNews(item.url),
                );
              },
              childCount: newsItems.length,
            ),
          ),
          if (isLoading && newsItems.isNotEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFFE51A1B),
                  ),
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
        ],
      ),
    );
  }

  void _openNews(String url) {
    debugPrint('Opening: $url');
    // Implement webview or browser launch
  }
}

class _NewsCard extends StatelessWidget {
  final String title;
  final String time;
  final String category;
  final VoidCallback onTap;

  const _NewsCard({
    required this.title,
    required this.time,
    required this.category,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (category.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        category,
                        style: GoogleFonts.notoSansBengali(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFFE51A1B),
                        ),
                      ),
                    ),
                  Text(
                    title,
                    style: GoogleFonts.notoSansBengali(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF2D3748),
                    ),
                  ),
                  if (time.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          time,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE51A1B).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Read Full Story',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFFE51A1B),
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.arrow_forward,
                              size: 14,
                              color: Color(0xFFE51A1B),
                            ),
                          ],
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
    );
  }
}

class NewsItem {
  final String title;
  final String url;
  final String time;
  final String category;
  final bool isVideo;
  final bool isPhoto;

  NewsItem({
    required this.title,
    required this.url,
    required this.time,
    required this.category,
    required this.isVideo,
    required this.isPhoto,
  });
}
