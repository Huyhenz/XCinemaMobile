// File: lib/screens/snack_selection_screen.dart
// Màn hình chọn bắp nước sau khi chọn ghế

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/snack.dart';
import '../services/database_services.dart';
import 'payment_screen.dart';

class SnackSelectionScreen extends StatefulWidget {
  final String showtimeId;
  final String cinemaId;
  final List<String> selectedSeats;
  final double totalPrice;

  const SnackSelectionScreen({
    super.key,
    required this.showtimeId,
    required this.cinemaId,
    required this.selectedSeats,
    required this.totalPrice,
  });

  @override
  State<SnackSelectionScreen> createState() => _SnackSelectionScreenState();
}

class _SnackSelectionScreenState extends State<SnackSelectionScreen> {
  final DatabaseService _dbService = DatabaseService();
  List<SnackModel> _snacks = [];
  Map<String, int> _selectedSnacks = {}; // snackId -> quantity
  bool _isLoading = true;
  double _snackTotal = 0.0;

  @override
  void initState() {
    super.initState();
    _loadSnacks();
  }

  Future<void> _loadSnacks() async {
    setState(() => _isLoading = true);
    try {
      final allSnacks = await _dbService.getAllSnacks();
      setState(() {
        _snacks = allSnacks.where((s) => s.isActive).toList();
      });
    } catch (e) {
      print('Error loading snacks: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _updateSnackQuantity(String snackId, int quantity) {
    setState(() {
      if (quantity <= 0) {
        _selectedSnacks.remove(snackId);
      } else {
        _selectedSnacks[snackId] = quantity;
      }
      _calculateTotal();
    });
  }

  void _calculateTotal() {
    double total = 0.0;
    _selectedSnacks.forEach((snackId, quantity) {
      final snack = _snacks.firstWhere((s) => s.id == snackId);
      total += snack.price * quantity;
    });
    setState(() {
      _snackTotal = total;
    });
  }

  void _proceedToPayment() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentScreen(
          showtimeId: widget.showtimeId,
          cinemaId: widget.cinemaId,
          selectedSeats: widget.selectedSeats,
          totalPrice: widget.totalPrice + _snackTotal,
          voucherId: null,
          selectedSnacks: _selectedSnacks,
        ),
      ),
    );
  }

  Widget _buildSnackCard(SnackModel snack) {
    final quantity = _selectedSnacks[snack.id] ?? 0;
    final categoryColors = {
      'popcorn': const Color(0xFFFF9800),
      'drink': const Color(0xFF2196F3),
      'combo': const Color(0xFF9C27B0),
      'snack': const Color(0xFF4CAF50),
    };
    final categoryColor = categoryColors[snack.category] ?? Colors.grey;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: quantity > 0 ? categoryColor : const Color(0xFF2A2A2A),
          width: quantity > 0 ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          // Image
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              bottomLeft: Radius.circular(16),
            ),
            child: CachedNetworkImage(
              imageUrl: snack.imageUrl,
              width: 120,
              height: 120,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                width: 120,
                height: 120,
                color: const Color(0xFF2A2A2A),
                child: const Center(
                  child: CircularProgressIndicator(color: Color(0xFF2196F3)),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                width: 120,
                height: 120,
                color: const Color(0xFF2A2A2A),
                child: const Icon(Icons.fastfood, color: Colors.grey, size: 48),
              ),
            ),
          ),
          // Info
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: categoryColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          snack.category.toUpperCase(),
                          style: TextStyle(
                            color: categoryColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${snack.price.toStringAsFixed(0)}đ',
                        style: const TextStyle(
                          color: Color(0xFFE50914),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snack.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    snack.description,
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 12,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  // Quantity controls
                  Row(
                    children: [
                      IconButton(
                        onPressed: quantity > 0
                            ? () => _updateSnackQuantity(snack.id, quantity - 1)
                            : null,
                        icon: const Icon(Icons.remove_circle_outline),
                        color: quantity > 0 ? Colors.white : Colors.grey,
                        iconSize: 28,
                      ),
                      Container(
                        width: 40,
                        alignment: Alignment.center,
                        child: Text(
                          '$quantity',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => _updateSnackQuantity(snack.id, quantity + 1),
                        icon: const Icon(Icons.add_circle_outline),
                        color: Colors.white,
                        iconSize: 28,
                      ),
                      const Spacer(),
                      if (quantity > 0)
                        Text(
                          '${(snack.price * quantity).toStringAsFixed(0)}đ',
                          style: TextStyle(
                            color: categoryColor,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categories = ['popcorn', 'drink', 'combo', 'snack'];
    final categoryNames = {
      'popcorn': 'Bắp',
      'drink': 'Nước',
      'combo': 'Combo',
      'snack': 'Đồ Ăn',
    };

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          'Chọn Bắp Nước',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFE50914)),
            )
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Summary
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1A1A),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF2A2A2A)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Tổng ghế: ${widget.totalPrice.toStringAsFixed(0)}đ',
                                    style: TextStyle(color: Colors.grey[400], fontSize: 14),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Bắp nước: ${_snackTotal.toStringAsFixed(0)}đ',
                                    style: const TextStyle(color: Colors.white, fontSize: 16),
                                  ),
                                ],
                              ),
                              Text(
                                'Tổng: ${(widget.totalPrice + _snackTotal).toStringAsFixed(0)}đ',
                                style: const TextStyle(
                                  color: Color(0xFFE50914),
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Snacks by category
                        ...categories.map((category) {
                          final categorySnacks = _snacks.where((s) => s.category == category).toList();
                          if (categorySnacks.isEmpty) return const SizedBox.shrink();
                          
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Text(
                                  categoryNames[category] ?? category,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              ...categorySnacks.map((snack) => _buildSnackCard(snack)),
                              const SizedBox(height: 8),
                            ],
                          );
                        }),
                        const SizedBox(height: 100), // Space for bottom button
                      ],
                    ),
                  ),
                ),
                // Bottom button
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _proceedToPayment,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE50914),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.payment, color: Colors.white, size: 20),
                            const SizedBox(width: 12),
                            Text(
                              'TIẾP TỤC THANH TOÁN - ${(widget.totalPrice + _snackTotal).toStringAsFixed(0)}đ',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

