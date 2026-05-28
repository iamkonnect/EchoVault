import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/message_model.dart';
import '../../models/group_model.dart';
import 'app_providers.dart';

class Conversation {
  final String id;
  final String userId;
  final String userName;
  final String avatar;
  final List<Message> messages;
  final DateTime lastMessageTime;
  final bool isOnline;
  int unreadCount;

  Conversation({
    required this.id,
    required this.userId,
    required this.userName,
    required this.avatar,
    required this.messages,
    required this.lastMessageTime,
    this.isOnline = false,
    this.unreadCount = 0,
  });
}

class ChatState {
  final List<Conversation> conversations;
  final List<Group> groups;
  final int selectedIndex;
  final bool isGroupView;
  final List<String> stickers;
  final bool isTyping;

  ChatState({
    this.conversations = const [],
    this.groups = const [],
    this.selectedIndex = -1,
    this.isGroupView = false,
    this.stickers = const [],
    this.isTyping = false,
  });

  ChatState copyWith({
    List<Conversation>? conversations,
    List<Group>? groups,
    int? selectedIndex,
    bool? isGroupView,
    List<String>? stickers,
    bool? isTyping,
  }) {
    return ChatState(
      conversations: conversations ?? this.conversations,
      groups: groups ?? this.groups,
      selectedIndex: selectedIndex ?? this.selectedIndex,
      isGroupView: isGroupView ?? this.isGroupView,
      stickers: stickers ?? this.stickers,
      isTyping: isTyping ?? this.isTyping,
    );
  }
}

class ChatNotifier extends StateNotifier<ChatState> {
  final Ref _ref;

  ChatNotifier(this._ref) : super(ChatState()) {
    _initializeData();
  }

  Future<void> _initializeData() async {
    // Start with mock data or empty state, then fetch from API
    _initializeMockData();
    
    try {
      final apiService = _ref.read(apiServiceProvider);
      // Example: fetch conversations from backend
      // final remoteConvos = await apiService.getConversations();
      // if (remoteConvos != null) state = state.copyWith(conversations: remoteConvos);
    } catch (e) {
      // Silent fallback to mocks - no log spam
    }
  }

  void _initializeMockData() {
    final now = DateTime.now();
    state = state.copyWith(
      conversations: [
        Conversation(
          id: '1',
          userId: 'dj_shadow',
          userName: 'DJ Shadowfax',
          avatar: 'assets/Echo-Vault-Icon.png',
          messages: _mockMessages('DJ Shadowfax', now.subtract(const Duration(minutes: 5))),
          lastMessageTime: now.subtract(const Duration(minutes: 2)),
          isOnline: true,
          unreadCount: 2,
        ),
        Conversation(
          id: '2',
          userId: 'chillhop',
          userName: 'Chillhop Music',
          avatar: 'assets/WhatsApp Image 2026-03-17 at 13.04.46 (6).jpeg',
          messages: _mockMessages('Chillhop Music', now.subtract(const Duration(hours: 1))),
          lastMessageTime: now.subtract(const Duration(hours: 1)),
          unreadCount: 0,
        ),
        Conversation(
          id: '3',
          userId: 'smooth_jazz',
          userName: 'Smooth Jazz',
          avatar: 'assets/WhatsApp Image 2026-03-17 at 13.04.46 (7).jpeg',
          messages: [],
          lastMessageTime: now.subtract(const Duration(hours: 3)),
          unreadCount: 0,
        ),
        Conversation(
          id: '4',
          userId: 'beatmaker_pro',
          userName: 'Beatmaker Pro',
          avatar: 'assets/WhatsApp Image 2026-03-17 at 13.04.45.jpeg',
          messages: _mockMessages('Beatmaker Pro', now),
          lastMessageTime: now,
          isOnline: true,
        ),
        Conversation(
          id: '5',
          userId: 'vinyl_vibes',
          userName: 'Vinyl Vibes',
          avatar: 'assets/WhatsApp Image 2026-03-17 at 13.04.46 (10).jpeg',
          messages: [],
          lastMessageTime: now.subtract(const Duration(days: 1)),
          unreadCount: 1,
        ),
      ],
      groups: [
        Group(
          id: 'g1',
          name: 'Music Producers',
          avatar: 'assets/Echo-Vault-Icon.png',
          members: ['user1', 'user2', 'user3'],
          messages: _mockMessages('Group', now),
          lastMessageTime: now,
          unreadCount: 1,
        ),
        Group(
          id: 'g2',
          name: 'DJ Collective',
          avatar: 'assets/WhatsApp Image 2026-03-17 at 13.04.46 (6).jpeg',
          members: ['dj1', 'dj2'],
          messages: [],
          lastMessageTime: now.subtract(const Duration(hours: 2)),
        ),
        Group(
          id: 'g3',
          name: 'Lo-Fi Lovers',
          avatar: 'assets/WhatsApp Image 2026-03-17 at 13.04.46 (7).jpeg',
          members: ['chill1', 'chill2', 'chill3'],
          messages: _mockMessages('Group', now.subtract(const Duration(minutes: 10))),
          lastMessageTime: now.subtract(const Duration(minutes: 10)),
          unreadCount: 3,
        ),
      ],
      stickers: [
        'assets/WhatsApp Image 2026-03-17 at 13.04.45.jpeg',
        'assets/WhatsApp Image 2026-03-17 at 13.04.45 (1).jpeg',
        'assets/WhatsApp Image 2026-03-17 at 13.04.45 (2).jpeg',
        'assets/WhatsApp Image 2026-03-17 at 13.04.45 (3).jpeg',
        'assets/WhatsApp Image 2026-03-17 at 13.04.46.jpeg',
        'assets/WhatsApp Image 2026-03-17 at 13.04.46 (1).jpeg',
        'assets/WhatsApp Image 2026-03-17 at 13.04.46 (5).jpeg',
        'assets/WhatsApp Image 2026-03-17 at 13.04.46 (6).jpeg',
        'assets/WhatsApp Image 2026-03-17 at 13.04.46 (7).jpeg',
        'assets/WhatsApp Image 2026-03-17 at 13.04.46 (10).jpeg',
        'assets/WhatsApp Image 2026-03-17 at 13.04.46 (15).jpeg',
        'assets/Echo-Vault-Icon.png',
      ],
    );
  }

  List<Message> _mockMessages(String senderName, DateTime baseTime) {
    return [
      Message(
        id: 'm1',
        content: 'Hey! Loving your latest track 🔥',
        type: MessageType.text,
        senderId: senderName.toLowerCase().replaceAll(' ', '_'),
        senderName: senderName,
        timestamp: baseTime,
        isSent: false,
      ),
      Message(
        id: 'm2',
        content: 'Thanks! What\'s your favorite part?',
        type: MessageType.text,
        senderId: 'current_user',
        senderName: 'You',
        timestamp: baseTime.add(const Duration(minutes: 1)),
        isSent: true,
      ),
    ];
  }

  void selectItem(String itemId, bool isGroup) {
    if (isGroup) {
      final index = state.groups.indexWhere((g) => g.id == itemId);
      if (index != -1) {
        state = state.copyWith(selectedIndex: index, isGroupView: true);
      }
    } else {
      final index = state.conversations.indexWhere((c) => c.id == itemId);
      if (index != -1) {
        state = state.copyWith(selectedIndex: index, isGroupView: false);
      }
    }
  }

  void addMessage(String content, MessageType type) async {
    final newMsg = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      type: type,
      senderId: 'current_user',
      senderName: 'You',
      timestamp: DateTime.now(),
      isSent: true,
    );

    // Send to backend via WebSocket/Realtime service
    try {
      final realtimeService = _ref.read(realtimeServiceProvider);
      final recipientId = state.isGroupView 
          ? state.groups[state.selectedIndex].id 
          : state.conversations[state.selectedIndex].userId;
      
      realtimeService.sendMessage(recipientId, content, isGroup: state.isGroupView);
    } catch (e) {
      print('Error sending message to backend: $e');
    }

    if (state.isGroupView) {
      final groups = List<Group>.from(state.groups);
      final group = groups[state.selectedIndex];
      final updatedGroup = Group(
        id: group.id,
        name: group.name,
        avatar: group.avatar,
        members: group.members,
        messages: [...group.messages, newMsg],
        lastMessageTime: newMsg.timestamp,
        unreadCount: group.unreadCount,
      );
      groups[state.selectedIndex] = updatedGroup;
      state = state.copyWith(groups: groups);
    } else {
      final convs = List<Conversation>.from(state.conversations);
      final conv = convs[state.selectedIndex];
      final updatedConvo = Conversation(
        id: conv.id,
        userId: conv.userId,
        userName: conv.userName,
        avatar: conv.avatar,
        messages: [...conv.messages, newMsg],
        lastMessageTime: newMsg.timestamp,
        isOnline: conv.isOnline,
      );
      convs[state.selectedIndex] = updatedConvo;
      state = state.copyWith(conversations: convs);
    }
  }

  void clearUnread(String itemId, bool isGroup) {
    if (isGroup) {
      final index = state.groups.indexWhere((g) => g.id == itemId);
      if (index != -1) {
        final groups = List<Group>.from(state.groups);
        final group = groups[index];
        groups[index] = Group(
          id: group.id,
          name: group.name,
          avatar: group.avatar,
          members: group.members,
          messages: group.messages,
          lastMessageTime: group.lastMessageTime,
          unreadCount: 0,
        );
        state = state.copyWith(groups: groups);
      }
    } else {
      final index = state.conversations.indexWhere((c) => c.id == itemId);
      if (index != -1) {
        final convs = List<Conversation>.from(state.conversations);
        final conv = convs[index];
        convs[index] = Conversation(
          id: conv.id,
          userId: conv.userId,
          userName: conv.userName,
          avatar: conv.avatar,
          messages: conv.messages,
          lastMessageTime: conv.lastMessageTime,
          isOnline: conv.isOnline,
          unreadCount: 0,
        );
        state = state.copyWith(conversations: convs);
      }
    }
  }
}

final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  return ChatNotifier(ref);
});
