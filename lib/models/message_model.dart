//Como se presenta un mensaje

class MessageModel {
  final String senderId;
  final String receiverId;
  final String groupId;
  final String content;
  final DateTime timestamp;

  MessageModel({
    required this.senderId,
    required this.receiverId,
    required this.groupId,
    required this.content,
    required this.timestamp,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      senderId: json['senderId'],
      receiverId: json['receiverId'],
      groupId: json['groupId'],
      content: json['content'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}
