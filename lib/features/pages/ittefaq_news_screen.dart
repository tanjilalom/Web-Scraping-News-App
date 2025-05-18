import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class IttefaqNewsScreen extends StatefulWidget {
  const IttefaqNewsScreen({super.key});

  @override
  State<IttefaqNewsScreen> createState() => _IttefaqNewsScreenState();
}

class _IttefaqNewsScreenState extends State<IttefaqNewsScreen> {
  final String _channelTitle = 'Ittefaq News';
  List<Map<String, String>> _newsList = [];
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _fetchIttefaqNews();
  }

  Future<void> _fetchIttefaqNews() async {
    // const String baseUrl = 'https://www.ittefaq.com.bd';
    // const String url = '$baseUrl/trade';
    const String url = 'https://www.ittefaq.com.bd';

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final document = html_parser.parse(utf8.decode(response.bodyBytes));
        final infoBlocks = document.querySelectorAll('div.info');

        final List<Map<String, String>> items = [];

        for (var block in infoBlocks) {
          final titleElement = block.querySelector('h2.title a.link_overlay');
          final descElement = block.querySelector('div.summery');

          if (titleElement != null && descElement != null) {
            final title = titleElement.text.trim();
            final href = titleElement.attributes['href'] ?? '';
            final fullLink = href.startsWith('http') ? href : '$url$href';
            final summary = descElement.text.trim();

            items.add({
              'title': title,
              'link': fullLink,
              'description': summary,
              'pubDate': DateFormat('MMM dd, yyyy - hh:mm a').format(DateTime.now()), // No real pubDate
            });
          }
        }

        setState(() {
          _newsList = items;
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load page: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: $e'),
        backgroundColor: Colors.red,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFD),
      appBar: AppBar(
        title: Text(
          _channelTitle,
          style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF3366FF),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchIttefaqNews,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _hasError
          ? Center(child: Text("Error loading news."))
          : RefreshIndicator(
        onRefresh: _fetchIttefaqNews,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _newsList.length,
          itemBuilder: (context, index) {
            final item = _newsList[index];
            return _NewsCard(
              title: item['title']!,
              date: item['pubDate']!,
              description: item['description']!,
              onTap: () async {
                debugPrint('Opening: ${item['link']}');
                final url = item['link']!;
                if (await canLaunchUrl(Uri.parse(url))) {
                  await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Could not launch the URL'),
                    backgroundColor: Colors.red,
                  ));
                }
              },

            );
          },
        ),
      ),
    );
  }
}

class _NewsCard extends StatelessWidget {
  final String title;
  final String date;
  final String description;
  final VoidCallback onTap;

  const _NewsCard({
    required this.title,
    required this.date,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
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
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF2D3748),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 6),
                  Text(
                    date,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7367F0).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Read',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF7367F0),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_forward, size: 14, color: Color(0xFF7367F0)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
