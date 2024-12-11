import 'dart:convert';

GroupChat groupChatFromJson(String str) => GroupChat.fromJson(json.decode(str));

String groupChatToJson(GroupChat data) => json.encode(data.toJson());

class GroupChat {
  GroupChat({
    required this.id,
    required this.username,
    required this.sentAt,
    required this.message,
  });

  String id;
  String username;
  String sentAt;
  String message;

  factory GroupChat.fromJson(Map<String, dynamic> json) => GroupChat(
        id: json["id"],
        username: json["username"],
        sentAt: json["sentAt"],
        message: json["message"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "username": username,
        "sentAt": sentAt,
        "message": message,
      };
}
