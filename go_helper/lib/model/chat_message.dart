import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  final String text;
  final bool isDriver;
  final String time;
  final String? senderId;
  final DateTime? timestamp;

  ChatMessage({
    required this.text,
    required this.isDriver,
    required this.time,
    this.senderId,
    this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'isDriver': isDriver,
      'time': time,
      'senderId': senderId,
      'timestamp': timestamp ?? FieldValue.serverTimestamp(),
    };
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      text: map['text'] ?? '',
      isDriver: map['isDriver'] ?? false,
      time: map['time'] ?? '',
      senderId: map['senderId'],
      timestamp: (map['timestamp'] as Timestamp?)?.toDate(),
    );
  }
}
