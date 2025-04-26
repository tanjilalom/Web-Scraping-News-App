import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class BanglaNews24Screen extends StatefulWidget {
  const BanglaNews24Screen({super.key});

  @override
  _BanglaNews24ScreenState createState() => _BanglaNews24ScreenState();
}

class _BanglaNews24ScreenState extends State<BanglaNews24Screen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<NewsItem> _latestNews = [];
  List<NewsItem> _popularNews = [];
  bool _isLoading = true;
  bool _hasError = false;
  DateTime? _lastUpdated;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchNews();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchNews() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final response = await http.get(Uri.parse('https://www.banglanews24.com'))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final document = parse(response.body);

        // Scrape latest news
        final latestItems = document.querySelectorAll('#latest li');
        final latestNews = latestItems.map((item) {
          final link = item.querySelector('a')?.attributes['href'] ?? '';
          final title = item.querySelector('a')?.text.trim() ?? 'No title';
          final time = item.querySelector('.publish-time')?.text.trim() ?? '';

          return NewsItem(
            title: title,
            url: link.startsWith('http') ? link : 'https://www.banglanews24.com$link',
            time: time,
            isPopular: false,
          );
        }).toList();

        // Scrape popular news
        final popularItems = document.querySelectorAll('#readers-choice li');
        final popularNews = popularItems.map((item) {
          final link = item.querySelector('a')?.attributes['href'] ?? '';
          final title = item.querySelector('a')?.text.trim() ?? 'No title';

          return NewsItem(
            title: title,
            url: link.startsWith('http') ? link : 'https://www.banglanews24.com$link',
            time: '',
            isPopular: true,
          );
        }).toList();

        setState(() {
          _latestNews = latestNews;
          _popularNews = popularNews;
          _lastUpdated = DateTime.now();
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load news (${response.statusCode})');
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
      _showErrorSnackbar(e.toString());
    }
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
          'BanglaNews24',
          style: GoogleFonts.notoSansBengali(
            fontWeight: FontWeight.w700,
            fontSize: 22,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF1E88E5),
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF1E88E5),
                Color(0xFF00ACC1),
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
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelStyle: GoogleFonts.notoSansBengali(
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
          unselectedLabelStyle: GoogleFonts.notoSansBengali(
            fontWeight: FontWeight.w400,
          ),
          tabs: const [
            Tab(text: 'Latest News'),
            Tab(text: 'Popular News'),
          ],
        ),
      ),
      body: _isLoading && _latestNews.isEmpty
          ? const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF1E88E5),
        ),
      )
          : _hasError && _latestNews.isEmpty
          ? Center(
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
                backgroundColor: const Color(0xFF1E88E5),
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
      )
          : RefreshIndicator(
        onRefresh: _fetchNews,
        color: const Color(0xFF1E88E5),
        child: Column(
          children: [
            if (_lastUpdated != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.update,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Updated ${DateFormat('MMM dd, hh:mm a').format(_lastUpdated!)}',
                      style: GoogleFonts.poppins(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildNewsList(_latestNews),
                  _buildNewsList(_popularNews),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewsList(List<NewsItem> newsItems) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: newsItems.length,
      itemBuilder: (context, index) {
        final item = newsItems[index];
        return _NewsCard(
          title: item.title,
          time: item.time,
          isPopular: item.isPopular,
          onTap: () => _openNews(item.url),
        );
      },
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
  final bool isPopular;
  final VoidCallback onTap;

  const _NewsCard({
    required this.title,
    required this.time,
    required this.isPopular,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.notoSansBengali(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF2D3748),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  if (time.isNotEmpty)
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
                  if (isPopular) ...[
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF7043).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.trending_up,
                            size: 14,
                            color: const Color(0xFFFF7043),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Popular',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFFFF7043),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class NewsItem {
  final String title;
  final String url;
  final String time;
  final bool isPopular;

  NewsItem({
    required this.title,
    required this.url,
    required this.time,
    required this.isPopular,
  });
}