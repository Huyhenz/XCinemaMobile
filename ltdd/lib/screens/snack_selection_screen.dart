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
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        gradient: quantity > 0
            ? LinearGradient(
                colors: [
                  const Color(0xFF2A2A2A),
                  const Color(0xFF1A1A1A),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : const LinearGradient(
                colors: [Color(0xFF2A2A2A), Color(0xFF1A1A1A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: quantity > 0
              ? categoryColor.withOpacity(0.5)
              : const Color(0xFFE50914).withOpacity(0.3),
          width: quantity > 0 ? 2 : 1.5,
        ),
        boxShadow: quantity > 0
            ? [
                BoxShadow(
                  color: categoryColor.withOpacity(0.3),
                  blurRadius: 15,
                  spreadRadius: 1,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
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
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              categoryColor.withOpacity(0.3),
                              categoryColor.withOpacity(0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: categoryColor.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          snack.category.toUpperCase(),
                          style: TextStyle(
                            color: categoryColor,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFE50914), Color(0xFFB20710)],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${snack.price.toStringAsFixed(0)}đ',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
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
                      Container(
                        decoration: BoxDecoration(
                          color: quantity > 0
                              ? const Color(0xFFE50914).withOpacity(0.2)
                              : const Color(0xFF2A2A2A),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: quantity > 0
                                ? const Color(0xFFE50914)
                                : Colors.grey.withOpacity(0.3),
                            width: 1.5,
                          ),
                        ),
                        child: IconButton(
                          onPressed: quantity > 0
                              ? () => _updateSnackQuantity(snack.id, quantity - 1)
                              : null,
                          icon: const Icon(Icons.remove),
                          color: quantity > 0 ? Colors.white : Colors.grey,
                          iconSize: 20,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ),
                      Container(
                        width: 50,
                        margin: const EdgeInsets.symmetric(horizontal: 12),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF2A2A2A).withOpacity(0.8),
                              const Color(0xFF1A1A1A).withOpacity(0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(0xFFE50914).withOpacity(0.2),
                            width: 1,
                          ),
                        ),
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
                      Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFE50914), Color(0xFFB20710)],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFE50914).withOpacity(0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          onPressed: () => _updateSnackQuantity(snack.id, quantity + 1),
                          icon: const Icon(Icons.add),
                          color: Colors.white,
                          iconSize: 20,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ),
                      const Spacer(),
                      if (quantity > 0)
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  categoryColor.withOpacity(0.3),
                                  categoryColor.withOpacity(0.1),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: categoryColor.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              '${(snack.price * quantity).toStringAsFixed(0)}đ',
                              style: TextStyle(
                                color: categoryColor,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
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
    final categoryColors = {
      'popcorn': const Color(0xFFFF9800),
      'drink': const Color(0xFF2196F3),
      'combo': const Color(0xFF9C27B0),
      'snack': const Color(0xFF4CAF50),
    };

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F0F),
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2A2A2A), Color(0xFF1A1A1A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFFE50914).withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFE50914).withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: const Text(
          'Chọn Bắp Nước',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
            letterSpacing: 0.5,
          ),
        ),
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
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF2A2A2A), Color(0xFF1A1A1A)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFFE50914).withOpacity(0.3),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFE50914).withOpacity(0.1),
                                blurRadius: 15,
                                spreadRadius: 1,
                                offset: const Offset(0, 4),
                              ),
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                const Color(0xFFE50914).withOpacity(0.2),
                                                const Color(0xFFB20710).withOpacity(0.1),
                                              ],
                                            ),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: const Icon(
                                            Icons.event_seat,
                                            color: Color(0xFFE50914),
                                            size: 18,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Flexible(
                                          child: Text(
                                            'Tổng ghế: ${widget.totalPrice.toStringAsFixed(0)}đ',
                                            style: TextStyle(
                                              color: Colors.grey[300],
                                              fontSize: 15,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                const Color(0xFF2196F3).withOpacity(0.2),
                                                const Color(0xFF1976D2).withOpacity(0.1),
                                              ],
                                            ),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: const Icon(
                                            Icons.fastfood,
                                            color: Color(0xFF2196F3),
                                            size: 18,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Flexible(
                                          child: Text(
                                            'Bắp nước: ${_snackTotal.toStringAsFixed(0)}đ',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFFE50914), Color(0xFFB20710)],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFE50914).withOpacity(0.4),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  'Tổng: ${(widget.totalPrice + _snackTotal).toStringAsFixed(0)}đ',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                  textAlign: TextAlign.center,
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
                                padding: const EdgeInsets.only(bottom: 16, top: 8),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            categoryColors[category]?.withOpacity(0.3) ?? Colors.grey.withOpacity(0.3),
                                            categoryColors[category]?.withOpacity(0.1) ?? Colors.grey.withOpacity(0.1),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        category == 'popcorn'
                                            ? Icons.local_movies
                                            : category == 'drink'
                                                ? Icons.local_drink
                                                : category == 'combo'
                                                    ? Icons.restaurant_menu
                                                    : Icons.fastfood,
                                        color: categoryColors[category] ?? Colors.grey,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      categoryNames[category] ?? category,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
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
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2A2A2A), Color(0xFF1A1A1A)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    border: Border(
                      top: BorderSide(
                        color: const Color(0xFFE50914).withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.4),
                        blurRadius: 15,
                        offset: const Offset(0, -5),
                      ),
                      BoxShadow(
                        color: const Color(0xFFE50914).withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, -3),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        const Color(0xFFE50914).withOpacity(0.2),
                                        const Color(0xFFB20710).withOpacity(0.1),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.shopping_cart,
                                    color: Color(0xFFE50914),
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Tổng cộng',
                                  style: TextStyle(
                                    color: Colors.grey[300],
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFE50914), Color(0xFFB20710)],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${(widget.totalPrice + _snackTotal).toStringAsFixed(0)}đ',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Container(
                          width: double.infinity,
                          height: 64,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFE50914), Color(0xFFB20710), Color(0xFF8B0000)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFE50914).withOpacity(0.5),
                                blurRadius: 20,
                                spreadRadius: 2,
                                offset: const Offset(0, 8),
                              ),
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 15,
                                offset: const Offset(0, 4),
                              ),
                            ],
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _proceedToPayment,
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                alignment: Alignment.center,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.payment, color: Colors.white, size: 24),
                                    ),
                                    const SizedBox(width: 16),
                                    const Text(
                                      'TIẾP TỤC THANH TOÁN',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.2,
                                        shadows: [
                                          Shadow(
                                            color: Colors.black26,
                                            blurRadius: 8,
                                          ),
                                        ],
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
                  ),
                ),
              ],
            ),
    );
  }
}

