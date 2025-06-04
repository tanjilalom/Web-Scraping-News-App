import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;
import 'package:url_launcher/url_launcher.dart';

class TBSNewsScreen extends StatefulWidget {
  const TBSNewsScreen({super.key});

  @override
  State<TBSNewsScreen> createState() => _TBSNewsScreenState();
}

class _TBSNewsScreenState extends State<TBSNewsScreen> {
  late Future<List<TBSNewsModel>> futureNews;

  @override
  void initState() {
    super.initState();
    futureNews = NewsScraperService().fetchNews();
  }

  Future<void> _refreshNews() async {
    setState(() {
      futureNews = NewsScraperService().fetchNews();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('TBS News বাংলা',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: Colors.white,
            )),
        centerTitle: true,
        backgroundColor: const Color(0xFF01141A),
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(16),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _refreshNews,
          ),
        ],
      ),
      body: FutureBuilder<List<TBSNewsModel>>(
        future: futureNews,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.deepOrange),
              ),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}',
                      style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _refreshNews,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Retry',
                        style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            );
          }

          final newsList = snapshot.data!;

          return RefreshIndicator(
            color: Colors.deepOrange,
            onRefresh: _refreshNews,
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(12),
              itemCount: newsList.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final news = newsList[index];

                return InkWell(
                  onTap: () => _openNews(news.articleUrl),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (news.imageUrl.isNotEmpty)
                            Hero(
                              tag: 'newsImage$index',
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  news.imageUrl,
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Container(
                                    width: 100,
                                    height: 100,
                                    color: Colors.grey[200],
                                    child: const Icon(Icons.broken_image,
                                        color: Colors.grey),
                                  ),
                                  loadingBuilder:
                                      (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Container(
                                      width: 100,
                                      height: 100,
                                      color: Colors.grey[200],
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          value: loadingProgress
                                                      .expectedTotalBytes !=
                                                  null
                                              ? loadingProgress
                                                      .cumulativeBytesLoaded /
                                                  loadingProgress
                                                      .expectedTotalBytes!
                                              : null,
                                          color: Colors.deepOrange,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          if (news.imageUrl.isNotEmpty)
                            const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.deepOrange.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    news.category,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.deepOrange[700],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  news.title,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    height: 1.3,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  news.description,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[700],
                                    height: 1.4,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Icon(Icons.access_time,
                                        size: 14, color: Colors.grey[500]),
                                    const SizedBox(width: 4),
                                    Text(
                                      news.time,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    const Spacer(),
                                    IconButton(
                                      icon: const Icon(Icons.share),
                                      iconSize: 18,
                                      color: Colors.grey[600],
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      onPressed: () {
                                        // Add share functionality
                                      },
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
              },
            ),
          );
        },
      ),
    );
  }

  void _openNews(String url) async {
    debugPrint('Opening: $url');
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open the link'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error launching URL: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid URL'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

class TBSNewsModel {
  final String title;
  final String description;
  final String articleUrl;
  final String category;
  final String time;
  final String imageUrl;

  TBSNewsModel({
    required this.title,
    required this.description,
    required this.articleUrl,
    required this.category,
    required this.time,
    required this.imageUrl,
  });
}

class NewsScraperService {
  static const String baseUrl = 'https://www.tbsnews.net';

  Future<List<TBSNewsModel>> fetchNews() async {
    final url = Uri.parse('$baseUrl/bangla');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final document = parse(response.body);
      final newsCards = document.querySelectorAll('.card');
      List<TBSNewsModel> articles = [];

      for (var card in newsCards) {
        try {
          if (card.querySelector('h3 a') == null) continue;

          final titleElement = card.querySelector('h3 a')!;
          final descElement = card.querySelector('.card-section p');
          final dateElement = card.querySelector('.date');
          final imageElement = card.querySelector('img');

          String imageUrl = imageElement?.attributes['data-src'] ??
              imageElement?.attributes['src'] ??
              '';

          if (imageUrl.isNotEmpty && imageUrl.startsWith('//')) {
            imageUrl = 'https:$imageUrl';
          }

          String time = '';
          String category = '';
          if (dateElement != null) {
            final dateText = dateElement.text.trim();
            final parts = dateText.split('|');
            if (parts.length > 1) {
              time = parts[0].trim();
              category = parts[1].trim();
            } else {
              time = dateText;
            }
          }

          articles.add(TBSNewsModel(
            title: titleElement.text.trim(),
            description: descElement?.text.trim() ?? '',
            articleUrl: '$baseUrl${titleElement.attributes['href'] ?? ''}',
            category: category,
            time: time,
            imageUrl: imageUrl,
          ));
        } catch (e) {
          debugPrint("Error parsing news card: $e");
        }
      }

      return articles;
    } else {
      throw Exception('Failed to load TBS news: ${response.statusCode}');
    }
  }
}
