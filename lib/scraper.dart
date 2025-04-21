import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;
import 'package:http/io_client.dart';

class QuotesScreen extends StatefulWidget {
  const QuotesScreen({super.key});

  @override
  _QuotesScreenState createState() => _QuotesScreenState();
}

class _QuotesScreenState extends State<QuotesScreen> {
  List<String> _quotes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchQuotes();
  }


  //bypass SSL validation
  HttpClient getCustomHttpClient() {
    final httpClient = HttpClient()
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
    return httpClient;
  }

  Future<void> fetchQuotes() async {
    // const url = 'http://quotes.toscrape.com';
    final url = 'https://www.techlandbd.com/pc-components/processor';

    try {

      final ioClient = IOClient(getCustomHttpClient());
      final response = await ioClient.get(Uri.parse(url));


      //final response = await http.get(Uri.parse(url));


      if (response.statusCode == 200) {
        final document = parse(response.body);
        final quoteElements = document.querySelectorAll('div.caption');

        debugPrint(quoteElements.toString());

        setState(() {
          _quotes = quoteElements.map((e) {
            final text = e.querySelector('div.name')?.text ?? "";

            final author = e.querySelector('span.price-new')?.text ?? "";



            debugPrint("-----------${author.toString()}");
            //final author = e.querySelector('span.price-new')?.text ?? '';
            //return '$text — $author';
            return '$text - $author';
          }).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _quotes = ['Failed to load quotes: ${response.statusCode}'];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _quotes = ['Error fetching quotes: $e'];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quotes to Scrape'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
            onRefresh: fetchQuotes,
            child: ListView.builder(
                itemCount: _quotes.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    //leading: Text('${index + 1}'),
                    title: Text(
                      _quotes[index],
                      style: const TextStyle(fontSize: 16),
                    ),
                  );
                },
              ),
          ),
    );
  }
}
