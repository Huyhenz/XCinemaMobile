import 'package:flutter/material.dart';
import 'package:pay/pay.dart';
import 'dart:convert';

class GooglePayScreen extends StatefulWidget {
  final double amount;
  final String currency;
  final String description;

  const GooglePayScreen({
    super.key,
    required this.amount,
    required this.currency,
    required this.description,
  });

  @override
  State<GooglePayScreen> createState() => _GooglePayScreenState();
}

class _GooglePayScreenState extends State<GooglePayScreen> {
  bool _isProcessing = false;
  String? _errorMessage;
  bool _isEmulator = false; // Detect if running on emulator

  // Payment items for Google Pay
  List<PaymentItem> get _paymentItems {
    // Convert VND to USD if needed
    double payAmount = widget.amount;
    String payCurrency = widget.currency;
    
    if (widget.currency == 'VND') {
      payAmount = widget.amount / 24000;
      payCurrency = 'USD';
    }

    return [
      PaymentItem(
        label: widget.description,
        amount: payAmount.toStringAsFixed(2),
        status: PaymentItemStatus.final_price,
      ),
    ];
  }

  // Payment configuration - load asynchronously
  Future<PaymentConfiguration> _getPaymentConfiguration() async {
    return await PaymentConfiguration.fromAsset('google_pay_config.json');
  }

  Future<void> _handleGooglePayPayment() async {
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      // Check if running on emulator
      // Google Pay doesn't work on emulator, so we'll show a test flow
      if (_isEmulator) {
        print('⚠️ Running on emulator - using test flow');
        await _simulateGooglePayFlow();
        return;
      }

      // Load payment configuration
      final paymentConfiguration = await _getPaymentConfiguration();
      
      // For now, we'll use a simple implementation
      // Google Pay button will handle the payment flow
      // The onPaymentResult callback will be called when user completes payment
      
      setState(() {
        _isProcessing = false;
        _errorMessage = 'Vui lòng sử dụng nút Google Pay bên dưới để thanh toán.';
      });
    } catch (e) {
      print('❌ Google Pay error: $e');
      // If error, assume emulator and use test flow
      if (e.toString().contains('not available') || 
          e.toString().contains('Google Play Services')) {
        await _simulateGooglePayFlow();
      } else {
        setState(() {
          _isProcessing = false;
          _errorMessage = 'Lỗi: $e';
        });
      }
    }
  }

  // Simulate Google Pay flow for emulator testing
  Future<void> _simulateGooglePayFlow() async {
    // Show card selection dialog (simulating Google Pay sheet)
    if (!mounted) return;

    final selectedCard = await showDialog<String>(
      context: context,
      builder: (context) => _buildCardSelectionDialog(),
    );

    if (selectedCard == null) {
      setState(() {
        _isProcessing = false;
      });
      if (mounted) {
        Navigator.of(context).pop({
          'success': false,
          'cancelled': true,
        });
      }
      return;
    }

    // Simulate payment processing
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      Navigator.of(context).pop({
        'success': true,
        'paymentData': {
          'card': selectedCard,
          'test': true,
        },
      });
    }
  }

  Widget _buildCardSelectionDialog() {
    final testCards = [
      {'number': '4242 4242 4242 4242', 'type': 'Visa', 'name': 'Test Card 1'},
      {'number': '5555 5555 5555 4444', 'type': 'Mastercard', 'name': 'Test Card 2'},
      {'number': '3782 822463 10005', 'type': 'American Express', 'name': 'Test Card 3'},
    ];

    return AlertDialog(
      backgroundColor: const Color(0xFF1A1A1A),
      title: const Text(
        'Chọn Thẻ Thanh Toán',
        style: TextStyle(color: Colors.white),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A2A),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.orange, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Đang chạy trên emulator. Chọn thẻ test để tiếp tục.',
                    style: TextStyle(color: Colors.grey[400], fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ...testCards.map((card) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A2A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF4285F4)),
            ),
            child: ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF4285F4),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Text(
                    'G',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              title: Text(
                card['name'] as String,
                style: const TextStyle(color: Colors.white),
              ),
              subtitle: Text(
                '${card['type']} • ${card['number']}',
                style: TextStyle(color: Colors.grey[400], fontSize: 12),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
              onTap: () => Navigator.of(context).pop(card['number']),
            ),
          )),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
        ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    // Try to detect if running on emulator
    _checkIfEmulator();
  }

  Future<void> _checkIfEmulator() async {
    try {
      // Try to check Google Pay availability
      // If it fails, likely running on emulator
      final paymentConfiguration = await _getPaymentConfiguration();
      // If we get here, might be real device, but we'll check availability later
    } catch (e) {
      // Likely emulator
      setState(() {
        _isEmulator = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Convert amount for display
    double displayAmount = widget.amount;
    String displayCurrency = widget.currency;
    
    if (widget.currency == 'VND') {
      displayAmount = widget.amount / 24000;
      displayCurrency = 'USD';
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: _isProcessing ? null : () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Google Pay',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Google Pay Logo
                Container(
                  padding: const EdgeInsets.all(30),
                  child: Image.asset(
                    'assets/google_pay_logo.png',
                    height: 80,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 80,
                        decoration: BoxDecoration(
                          color: const Color(0xFF4285F4),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Text(
                            'G',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 30),

                // Payment Details
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF2A2A2A)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Chi Tiết Thanh Toán',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildDetailRow('Mô tả', widget.description),
                      const Divider(color: Color(0xFF2A2A2A), height: 24),
                      _buildDetailRow('Số tiền', '${displayAmount.toStringAsFixed(2)} $displayCurrency'),
                      if (widget.currency == 'VND') ...[
                        const SizedBox(height: 8),
                        Text(
                          '(${widget.amount.toStringAsFixed(0)} VND)',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // Error message
                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE50914).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE50914)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Color(0xFFE50914)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),

                if (_errorMessage != null) const SizedBox(height: 20),

                // Google Pay Button - Load configuration asynchronously
                FutureBuilder<PaymentConfiguration>(
                  future: _getPaymentConfiguration(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SizedBox(
                        height: 56,
                        child: Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF4285F4),
                          ),
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE50914).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Lỗi tải cấu hình: ${snapshot.error}',
                          style: const TextStyle(color: Colors.white),
                        ),
                      );
                    }

                    final paymentConfiguration = snapshot.data!;
                    
                    return Container(
                      height: 56,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: GooglePayButton(
                        paymentConfiguration: paymentConfiguration,
                        paymentItems: _paymentItems,
                        type: GooglePayButtonType.pay,
                        margin: EdgeInsets.zero,
                        onPaymentResult: (paymentResult) {
                          // Payment successful
                          print('✅ Google Pay payment result: $paymentResult');
                          if (mounted) {
                            Navigator.of(context).pop({
                              'success': true,
                              'paymentData': paymentResult,
                            });
                          }
                        },
                        loadingIndicator: const Center(
                          child: CircularProgressIndicator(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    );
                  },
                ),

                // Alternative: Custom button if GooglePayButton doesn't work
                if (!_isProcessing)
                  const SizedBox(height: 16),
                if (!_isProcessing)
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _handleGooglePayPayment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4285F4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Center(
                              child: Text(
                                'G',
                                style: TextStyle(
                                  color: Color(0xFF4285F4),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Thanh Toán với Google Pay',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Processing indicator
                if (_isProcessing)
                  Container(
                    padding: const EdgeInsets.all(20),
                    child: const Column(
                      children: [
                        CircularProgressIndicator(
                          color: Color(0xFF4285F4),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Đang xử lý thanh toán...',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 20),

                // Info
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _isEmulator 
                        ? Colors.orange.withOpacity(0.2)
                        : const Color(0xFF1A1A1A).withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: _isEmulator 
                        ? Border.all(color: Colors.orange.withOpacity(0.5))
                        : null,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _isEmulator ? Icons.warning_amber_rounded : Icons.info_outline,
                        color: _isEmulator ? Colors.orange : Colors.grey[400],
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _isEmulator
                              ? 'Đang chạy trên emulator. Sử dụng nút "Thanh Toán Test" để test flow.'
                              : 'Chọn thẻ thanh toán và xác nhận trong Google Pay',
                          style: TextStyle(
                            color: _isEmulator ? Colors.orange : Colors.grey[400],
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

