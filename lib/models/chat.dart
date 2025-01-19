class Chat {
  final String id;
  final List<String> participants;
  final bool isGroupChat;
  final String? groupName;

  Chat({
    required this.id,
    required this.participants,
    required this.isGroupChat,
    this.groupName,
  });

  factory Chat.fromJson(Map<String, dynamic> json) {
    return Chat(
      id: json['_id'],
      participants: List<String>.from(json['participants']),
      isGroupChat: json['isGroupChat'] ?? false,
      groupName: json['groupName'],
    );
  }
}
