class ChatSummary {
  final String uid;
  final String lastMessage;
  final String lastMessageType;
  final DateTime? lastTime;
  final int messageCount;
  final int unreadForAdmin;
  ChatSummary({
    required this.uid,
    required this.lastMessage,
    this.lastMessageType = 'text',
    required this.lastTime,
    required this.messageCount,
    required this.unreadForAdmin,
  });
}
