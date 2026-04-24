enum MessageType {
  text,
  sticker,
  image,
}

class Message {
  final String id;
  final String content; // text or asset path
  final MessageType type;
  final String senderId;
  final String senderName;
  final DateTime timestamp;
  final bool isSent; // true if from current user

  Message({
    required this.id,
    required this.content,
    required this.type,
    required this.senderId,
    required this.senderName,
    required this.timestamp,
    this.isSent = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'content': content,
    'type': type.name,
    'senderId': senderId,
    'senderName': senderName,
    'timestamp': timestamp.millisecondsSinceEpoch,
    'isSent': isSent,
  };

  factory Message.fromJson(Map<String, dynamic> json) => Message(
    id: json['id'],
    content: json['content'],
    type: MessageType.values.byName(json['type']),
    senderId: json['senderId'],
    senderName: json['senderName'],
    timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp']),
    isSent: json['isSent'] ?? false,
  );
}

