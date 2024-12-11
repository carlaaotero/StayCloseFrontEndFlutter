class Chat {
  late String message;
  late bool isMy;
  late bool isImage;
  late String createdAt;

  Chat({required this.message, required this.isMy, required this.createdAt});

  Chat.fromJson(Map<String, dynamic> json) {
    message = json['message'] ?? "";
    isMy = json['ismy'];
    createdAt = json['createdAt'];
  }
}
