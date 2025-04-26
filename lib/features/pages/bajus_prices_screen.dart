import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'package:html/dom.dart' as dom;
import 'package:google_fonts/google_fonts.dart';

class MetalRate {
  final String product;
  final String description;
  final String price;

  MetalRate(this.product, this.description, this.price);
}

class BajusRateScreen extends StatefulWidget {
  const BajusRateScreen({super.key});

  @override
  _BajusRateScreenState createState() => _BajusRateScreenState();
}

class _BajusRateScreenState extends State<BajusRateScreen> {
  List<MetalRate> goldRates = [];
  List<MetalRate> silverRates = [];
  bool isLoading = true;
  DateTime? lastUpdated;

  @override
  void initState() {
    super.initState();
    fetchRates();
  }

  Future<void> fetchRates() async {
    setState(() => isLoading = true);
    const url = 'https://www.bajus.org/gold-price';

    try {
      final response =
          await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final document = parser.parse(response.body);
        final goldRows = document.querySelectorAll('.gold-table tbody tr');
        final silverRows = document.querySelectorAll('.silver-table tbody tr');

        setState(() {
          goldRates = _parseMetalRates(goldRows);
          silverRates = _parseMetalRates(silverRows);
          lastUpdated = DateTime.now();
          isLoading = false;
        });
      } else {
        _showError('Failed to load data (${response.statusCode})');
      }
    } catch (e) {
      _showError('Connection error: ${e.toString()}');
    }
  }

  List<MetalRate> _parseMetalRates(List<dom.Element> rows) {
    return rows.map((row) {
      final product = row.querySelector('h6')?.text.trim() ?? 'N/A';
      final desc = row.querySelector('td p')?.text.trim() ?? '';
      final price = row.querySelector('.price')?.text.trim() ?? 'N/A';
      return MetalRate(product, desc, price);
    }).toList();
  }

  void _showError(String message) {
    setState(() => isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: Colors.red[400],
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFD),
      appBar: AppBar(
        title: Text(
          'Gold & Silver Rates',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF3366FF),
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF3366FF),
                Color(0xFF00CCFF),
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
            onPressed: fetchRates,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: fetchRates,
              color: const Color(0xFF3366FF),
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (lastUpdated != null)
                            Text(
                              'Last updated: ${lastUpdated!.toString().substring(0, 16)}',
                              style: GoogleFonts.poppins(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),
                  _buildMetalSection(
                      'Gold Rates', goldRates, Icons.monetization_on),
                  _buildMetalSection(
                      'Silver Rates', silverRates, Icons.currency_exchange),
                  const SliverToBoxAdapter(child: SizedBox(height: 20)),
                ],
              ),
            ),
    );
  }

  Widget _buildMetalSection(
      String title, List<MetalRate> rates, IconData icon) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFF3366FF).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: const Color(0xFF3366FF),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2D3748),
                  ),
                ),
              ],
            ),
          ),
          ...rates.map((rate) => _buildRateCard(rate)).toList(),
        ]),
      ),
    );
  }

  Widget _buildRateCard(MetalRate rate) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Colors.grey.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  rate.product,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2D3748),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF28C76F).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    rate.price,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF28C76F),
                    ),
                  ),
                ),
              ],
            ),
            if (rate.description.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  rate.description,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
