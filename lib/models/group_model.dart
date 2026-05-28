import 'message_model.dart';

class Group {
  final String id;
  final String name;
  final String avatar;
  final List<String> members;
  final List<Message> messages;
  final DateTime lastMessageTime;
  int unreadCount;

  Group({
    required this.id,
    required this.name,
    required this.avatar,
    this.members = const [],
    this.messages = const [],
    required this.lastMessageTime,
    this.unreadCount = 0,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'avatar': avatar,
    'members': members,
    'messages': messages.map((m) => m.toJson()).toList(),
    'lastMessageTime': lastMessageTime.millisecondsSinceEpoch,
    'unreadCount': unreadCount,
  };

  factory Group.fromJson(Map<String, dynamic> json) => Group(
    id: json['id'],
    name: json['name'],
    avatar: json['avatar'],
    members: List<String>.from(json['members'] ?? []),
    messages: (json['messages'] as List?)?.map((m) => Message.fromJson(m)).toList() ?? [],
    lastMessageTime: DateTime.fromMillisecondsSinceEpoch(json['lastMessageTime']),
    unreadCount: json['unreadCount'] ?? 0,
  );
}

