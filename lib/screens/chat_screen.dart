// ignore_for_file: deprecated_member_use

import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flugo_chat/app_theme.dart';
import 'package:flugo_chat/components/chat_message.dart';
import 'package:flugo_chat/components/swipe_to_reply.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  static const _bgPrefKey = 'chat_background_path';

  final _db = FirebaseDatabase.instance.ref();
  final _auth = FirebaseAuth.instance;

  final _textController = TextEditingController();
  final _scrollController = ScrollController();

  final _imagePicker = ImagePicker();

  ChatMessage? _replyingTo;

  void _startReply(ChatMessage msg) => setState(() => _replyingTo = msg);
  void _cancelReply() => setState(() => _replyingTo = null);

  String? _backgroundPath;

  final Query _messagesQuery = FirebaseDatabase.instance
      .ref()
      .child('messages')
      .orderByChild('timestamp')
      .limitToLast(200);

  @override
  void initState() {
    super.initState();
    _loadBackground();
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadBackground() async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString(_bgPrefKey);

    if (path != null && path.isNotEmpty && File(path).existsSync()) {
      setState(() => _backgroundPath = path);
    } else {
      if (path != null) {
        await prefs.remove(_bgPrefKey);
      }
      setState(() => _backgroundPath = null);
    }
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    final user = _auth.currentUser;
    if (user == null) return;

    final userName = (user.displayName?.trim().isNotEmpty ?? false)
        ? user.displayName!.trim()
        : (user.email ?? 'Usuário');

    final replying = _replyingTo;

    final message = {
      'text': text,
      'userId': user.uid,
      'userName': userName,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'responding': replying == null
          ? null
          : {
              'id': replying.id,
              'userName': replying.userName,
              'userId': replying.userId,
              'text': replying.text,
            },
    };

    _textController.clear();
    await _db.child('messages').push().set(message);

    setState(() => _replyingTo = null);

    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  Future<void> _pickAndSaveBackground() async {
    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (picked == null) return;

    final docsDir = await getApplicationDocumentsDirectory();
    final ext = p.extension(picked.path);
    final fileName = 'chat_bg_${DateTime.now().millisecondsSinceEpoch}$ext';
    final destPath = p.join(docsDir.path, fileName);

    final copied = await File(picked.path).copy(destPath);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_bgPrefKey, copied.path);

    if (!mounted) return;
    setState(() => _backgroundPath = copied.path);
  }

  Future<void> _removeBackground() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_bgPrefKey);

    if (!mounted) return;
    setState(() => _backgroundPath = null);
  }

  Future<void> _handleMenu(String value) async {
    switch (value) {
      case 'bg':
        await _pickAndSaveBackground();
        break;
      case 'bg_remove':
        await _removeBackground();
        break;
      case 'logout':
        await _auth.signOut();
        break;
    }
  }

  Widget _replyBar(BuildContext context) {
    final replying = _replyingTo;
    if (replying == null) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    const namePalette = <Color>[
      Color(0xFF1E88E5),
      Color(0xFFD81B60),
      Color(0xFF43A047),
      Color(0xFF8E24AA),
      Color(0xFFF4511E),
      Color(0xFF3949AB),
      Color(0xFF00897B),
      Color(0xFF5E35B1),
      Color(0xFF039BE5),
      Color(0xFF7CB342),
      Color(0xFFC0CA33),
    ];

    int stableHash(String input) {
      var hash = 0;
      for (final unit in input.codeUnits) {
        hash = (hash * 31 + unit) & 0x7fffffff;
      }
      return hash;
    }

    Color userNameColor(String userId) {
      final idx = stableHash(userId) % namePalette.length;
      return namePalette[idx];
    }

    final accent = userNameColor(replying.userId);

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.06)
            : Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(width: 4, color: accent)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Respondendo a ${replying.userName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: accent,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  replying.text,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black87,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _cancelReply,
            icon: Icon(
              Icons.close,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
            tooltip: 'Cancelar resposta',
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat geral'),
        actions: [
          IconButton(
            onPressed: () {
              final brightness = Theme.of(context).brightness;
              AppTheme.toggleFromBrightness(brightness);
            },
            tooltip: 'Alternar tema',
            icon: Icon(
              Theme.of(context).brightness == Brightness.dark
                  ? Icons.light_mode
                  : Icons.dark_mode,
            ),
          ),

          PopupMenuButton<String>(
            onSelected: _handleMenu,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'bg',
                child: Row(
                  children: const [
                    Icon(Icons.image_outlined, size: 18),
                    SizedBox(width: 10),
                    Text('Alterar fundo do chat'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'bg_remove',
                enabled: _backgroundPath != null,
                child: Row(
                  children: const [
                    Icon(Icons.layers_clear_outlined, size: 18),
                    SizedBox(width: 10),
                    Text('Remover fundo'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: const [
                    Icon(Icons.logout, size: 18),
                    SizedBox(width: 10),
                    Text('Sair'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: _backgroundPath != null
                        ? Image.file(File(_backgroundPath!), fit: BoxFit.cover)
                        : Container(
                            color: isDark
                                ? const Color(0xFF0B141A)
                                : Colors.white.withOpacity(0.15),
                            child: Center(
                              child: Opacity(
                                opacity: 0.15,
                                child: Image.asset(
                                  'assets/logo.png',
                                  width: 180,
                                ),
                              ),
                            ),
                          ),
                  ),

                  Positioned.fill(
                    child: Container(
                      color: isDark
                          ? Colors.black.withOpacity(0.35)
                          : Colors.white.withOpacity(0.15),
                    ),
                  ),

                  StreamBuilder<DatabaseEvent>(
                    stream: _messagesQuery.onValue,
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final data = snapshot.data!.snapshot.value;
                      if (data == null) {
                        return const Center(child: Text('Sem mensagens.'));
                      }

                      final map = Map<dynamic, dynamic>.from(data as Map);
                      final items = map.entries.map((e) {
                        final value = Map<dynamic, dynamic>.from(e.value);
                        final respondingRaw = value['responding'];
                        return ChatMessage(
                          id: e.key.toString(),
                          text: (value['text'] ?? '').toString(),
                          userId: (value['userId'] ?? '').toString(),
                          userName: (value['userName'] ?? '').toString(),
                          timestamp: (value['timestamp'] ?? 0) as int,
                          responding: respondingRaw is Map
                              ? ChatMessageReply.fromMap(
                                  Map<dynamic, dynamic>.from(respondingRaw),
                                )
                              : null,
                        );
                      }).toList();

                      items.sort((a, b) => a.timestamp.compareTo(b.timestamp));

                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _scrollToBottom();
                      });

                      final currentUserId = _auth.currentUser?.uid;

                      return ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final msg = items[index];
                          final isMe = msg.userId == currentUserId;

                          final prev = index > 0 ? items[index - 1] : null;
                          final next = index < items.length - 1
                              ? items[index + 1]
                              : null;

                          final isFirstInGroup =
                              prev == null || prev.userId != msg.userId;
                          final isLastInGroup =
                              next == null || next.userId != msg.userId;

                          final showName = !isMe && isFirstInGroup;
                          final topSpacing = isFirstInGroup ? 8.0 : 2.0;

                          return Padding(
                            padding: EdgeInsets.only(top: topSpacing),
                            child: SwipeToReply(
                              isMe: isMe,
                              onReply: () => _startReply(msg),
                              child: MessageBubble(
                                message: msg,
                                isMe: isMe,
                                showName: showName,
                                isFirstInGroup: isFirstInGroup,
                                isLastInGroup: isLastInGroup,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            Container(
              color: isDark ? const Color(0xFF121212) : Colors.white,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _replyBar(context),

                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _textController,
                            textCapitalization: TextCapitalization.sentences,
                            minLines: 1,
                            maxLines: 4,
                            decoration: InputDecoration(
                              hintText: 'Digite sua mensagem...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              filled: true,
                              fillColor: isDark
                                  ? Colors.white.withOpacity(0.08)
                                  : Colors.grey.withOpacity(0.08),
                            ),
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) => _sendMessage(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          height: 48,
                          width: 52,
                          child: ElevatedButton(
                            onPressed: _sendMessage,
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.zero,
                              alignment: Alignment.center,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Icon(Icons.send),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
