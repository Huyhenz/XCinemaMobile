import 'package:firebase_database/firebase_database.dart';

class PaymentModel {
  final String id; // Key
  final String bookingId;
  final String cinemaId; // ID của rạp chiếu (để biết thanh toán ở rạp nào)
  final double amount; // Số tiền cuối cùng (sau voucher)
  final String status; // 'success', 'failed', 'pending'
  final String? transactionId; // Từ PayPal, Google Pay, ZaloPay hoặc gateway khác
  final String? paymentMethod; // 'paypal', 'googlepay', 'zalopay'
  final int? paidAt; // Timestamp

  PaymentModel({
    required this.id,
    required this.bookingId,
    required this.cinemaId,
    required this.amount,
    required this.status,
    this.transactionId,
    this.paymentMethod,
    this.paidAt,
  });

  factory PaymentModel.fromMap(Map<dynamic, dynamic> data, String key) {
    return PaymentModel(
      id: key,
      bookingId: data['bookingId'] ?? '',
      cinemaId: data['cinemaId']?.toString() ?? '',
      amount: data['amount']?.toDouble() ?? 0.0,
      status: data['status'] ?? 'pending',
      transactionId: data['transactionId'],
      paymentMethod: data['paymentMethod'],
      paidAt: data['paidAt'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'bookingId': bookingId,
      'cinemaId': cinemaId,
      'amount': amount,
      'status': status,
      'transactionId': transactionId,
      'paymentMethod': paymentMethod,
      'paidAt': ServerValue.timestamp,
    };
  }
}