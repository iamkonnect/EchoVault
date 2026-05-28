import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/chat_provider.dart';
import '../providers/user_provider.dart';
import '../models/message_model.dart';
import '../services/image_utils.dart';

enum ViewMode { inbox, chat }

class InboxScreen extends ConsumerStatefulWidget {
  const InboxScreen({super.key});

  @override
  ConsumerState<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends ConsumerState<InboxScreen> with TickerProviderStateMixin {
  ViewMode _currentView = ViewMode.inbox;
  bool _showStickers = false;
  final bool _isTyping = false;
  late AnimationController _slideController;
  late AnimationController _stickerController;
  late AnimationController _typingController;
  late Animation<Offset> _slideAnimation;
  final TextEditingController _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _stickerController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _typingController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeInOut));
  }

  void _toggleStickers() {
    setState(() {
      _showStickers = !_showStickers;
    });
    if (_showStickers) {
      _stickerController.forward();
    } else {
      _stickerController.reverse();
    }
  }

  void _sendTextMessage(WidgetRef ref) {
    if (_messageController.text.trim().isNotEmpty) {
      ref.read(chatProvider.notifier).addMessage(_messageController.text.trim(), MessageType.text);
      _messageController.clear();
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    _stickerController.dispose();
    _typingController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    
    // Authentication Guard: Redirect to login if not authenticated
    if (user == null) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text('Messages'),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outlined, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 24),
              const Text(
                'Sign in to view messages',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                'You need to be logged in to access your messages',
                style: TextStyle(color: Colors.grey, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/login'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
                icon: const Icon(Icons.login, color: Colors.white),
                label: const Text(
                  'Sign In',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final chatState = ref.watch(chatProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(_currentView == ViewMode.inbox ? 'Messages' : 'Chat'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: _currentView == ViewMode.chat
            ? [
                IconButton(
                  icon: const Icon(Icons.music_note, color: Colors.purple),
                  onPressed: () {}, // Later: voice message
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.white70),
                  onSelected: (value) {},
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'Clear chat', child: Text('Clear Chat')),
                  ],
                ),
              ]
            : null,
        leading: _currentView == ViewMode.chat
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => setState(() => _currentView = ViewMode.inbox),
              )
            : null,
      ),
      body: Column(
        children: [
          // Tab Indicator
          if (_currentView == ViewMode.inbox)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _currentView = ViewMode.inbox),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.purple.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inbox, color: Colors.purple, size: 20),
                            SizedBox(width: 8),
                            Text('Inbox', style: TextStyle(color: Colors.purple, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          // Content
          Expanded(
            child: _currentView == ViewMode.inbox
                ? _buildInboxList(chatState.conversations)
                : SlideTransition(
                    position: _slideAnimation,
                    child: _buildChatView(chatState),
                  ),
          ),
        ],
      ),
      floatingActionButton: _currentView == ViewMode.inbox
          ? FloatingActionButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('New conversation feature coming soon! 🎵')),
                );
              },
              backgroundColor: Colors.purple,
              child: const Icon(Icons.edit, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildInboxList(List<dynamic> conversations) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: conversations.length,
      itemBuilder: (context, index) {
        final convo = conversations[index] as dynamic;
        return _buildConversationTile(convo, index);
      },
    );
  }

  Widget _buildConversationTile(dynamic convo, int index) {
    final lastMsg = convo.messages.isNotEmpty ? convo.messages.last.content : '';
    final timeStr = _formatTime(convo.lastMessageTime);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            ref.read(chatProvider.notifier).selectItem(convo.id, false);
            setState(() => _currentView = ViewMode.chat);
            _slideController.forward();
            ref.read(chatProvider.notifier).clearUnread(convo.id, false);
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundImage: ImageUtils.getTrackImage(convo.avatar),
                    ),
                    if (convo.isOnline ?? false)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.black, width: 2),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              convo.userName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          Text(
                            timeStr,
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        lastMsg,
                        style: TextStyle(
                          color: Colors.grey[300],
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if ((convo.unreadCount ?? 0) > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.purple,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${convo.unreadCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChatView(ChatState chatState) {
    if (chatState.selectedIndex == -1) {
      return const Center(
        child: Text('Select a conversation', style: TextStyle(color: Colors.grey)),
      );
    }

    final convo = chatState.conversations[chatState.selectedIndex];
    final messages = convo.messages;

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            reverse: true,
            padding: const EdgeInsets.all(16),
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final message = messages[messages.length - 1 - index];
              return _buildMessageBubble(message);
            },
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  border: Border(top: BorderSide(color: Colors.grey[800]!)),
                ),
                child: SafeArea(
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[900],
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: TextField(
                            controller: _messageController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Type a message...',
                              hintStyle: TextStyle(color: Colors.grey[500]),
                              prefixIcon: IconButton(
                                icon: Icon(
                                  Icons.emoji_emotions_outlined,
                                  color: _showStickers ? Colors.purple : Colors.grey,
                                ),
                                onPressed: _toggleStickers,
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                            ),
                            maxLines: null,
                            onSubmitted: (text) {
                              if (text.trim().isNotEmpty) {
                                ref.read(chatProvider.notifier).addMessage(text.trim(), MessageType.text);
                                _messageController.clear();
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      FloatingActionButton(
                        mini: true,
                        heroTag: 'send',
                        backgroundColor: Colors.purple,
                        onPressed: () {
                          if (_messageController.text.trim().isNotEmpty) {
                            ref.read(chatProvider.notifier).addMessage(_messageController.text.trim(), MessageType.text);
                            _messageController.clear();
                          }
                        },
                        child: const Icon(Icons.send, color: Colors.white, size: 20),
                      ),
                    ],
                  ),
                ),
              ),
              if (_showStickers)
                AnimatedBuilder(
                  animation: _stickerController,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, 1 - _stickerController.value),
                      child: Container(
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.grey[900],
                          border: Border(
                            top: BorderSide(color: Colors.purple.withOpacity(0.3)),
                          ),
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.purple.withOpacity(0.1),
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(20),
                                  topRight: Radius.circular(20),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const SizedBox(width: 16),
                                  const Text(
                                    'Music Stickers',
                                    style: TextStyle(
                                      color: Colors.purple,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Spacer(),
                                  IconButton(
                                    icon: const Icon(Icons.close, color: Colors.purple),
                                    onPressed: _toggleStickers,
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: GridView.builder(
                                padding: const EdgeInsets.all(8),
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 4,
                                  childAspectRatio: 1,
                                  crossAxisSpacing: 8,
                                  mainAxisSpacing: 8,
                                ),
                                itemCount: ref.watch(chatProvider).stickers.length,
                                itemBuilder: (context, index) {
                                  final stickerPath = ref.watch(chatProvider).stickers[index];
                                  return GestureDetector(
                                    onTap: () {
                                      ref.read(chatProvider.notifier).addMessage(stickerPath, MessageType.sticker);
                                      _toggleStickers();
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: Colors.purple.withOpacity(0.3)),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.asset(
                                          stickerPath,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMessageBubble(Message message) {
    final isSent = message.isSent;
    final isSticker = message.type == MessageType.sticker;

    return Align(
      alignment: isSent ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          crossAxisAlignment: isSent ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isSent)
              Padding(
                padding: const EdgeInsets.only(left: 60),
                child: Text(
                  _formatTime(message.timestamp),
                  style: TextStyle(color: Colors.grey[500], fontSize: 11),
                ),
              ),
            Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: EdgeInsets.symmetric(
                horizontal: isSticker ? 8 : 16,
                vertical: isSticker ? 4 : 12,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isSent
                      ? [const Color(0xFF9C27B0), Colors.purple.shade700]
                      : [Colors.grey.shade800, Colors.grey.shade700],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(isSent ? 20 : 20),
                  topRight: Radius.circular(isSent ? 20 : 20),
                  bottomLeft: Radius.circular(isSent ? 20 : 4),
                  bottomRight: Radius.circular(isSent ? 4 : 20),
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: isSticker
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        message.content,
                        height: 120,
                        width: 120,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Text(
                      message.content,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                      ),
                    ),
            ),
            if (isSent)
              Padding(
                padding: const EdgeInsets.only(right: 60),
                child: Text(
                  _formatTime(message.timestamp),
                  style: TextStyle(color: Colors.grey[500], fontSize: 11),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    if (now.difference(time).inDays > 0) {
      return '${time.day}/${time.month}';
    }
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
