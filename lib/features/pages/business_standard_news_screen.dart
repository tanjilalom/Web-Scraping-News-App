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
      backgroundColor: const Color(0xFFF8FAFD),
      appBar: AppBar(
        title: const Text(
          'TBS News বাংলা',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF3366FF),
        elevation: 0,
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
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text("Error loading news."));
          }

          final newsList = snapshot.data!;

          return RefreshIndicator(
            onRefresh: _refreshNews,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: newsList.length,
              itemBuilder: (context, index) {
                final news = newsList[index];
                return InkWell(
                  onTap: () => _openNews(news.articleUrl),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
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
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (news.imageUrl.isNotEmpty)
                          ClipRRect(
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
                                      value:
                                          loadingProgress.expectedTotalBytes !=
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
                        if (news.imageUrl.isNotEmpty) const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
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
                              const SizedBox(height: 8),
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
                                  Text(
                                    news.category,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.blueGrey[600],
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
