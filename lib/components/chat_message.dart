import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ChatMessageReply {
  final String id;
  final String userName;
  final String userId;
  final String text;

  ChatMessageReply({
    required this.id,
    required this.userName,
    required this.userId,
    required this.text,
  });

  factory ChatMessageReply.fromMap(Map<dynamic, dynamic> map) {
    return ChatMessageReply(
      id: (map['id'] ?? '').toString(),
      userName: (map['userName'] ?? '').toString(),
      userId: (map['userId'] ?? '').toString(),
      text: (map['text'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'userName': userName,
    'userId': userId,
    'text': text,
  };
}

class ChatMessage {
  final String id;
  final String text;
  final String userId;
  final String userName;
  final int timestamp;

  // NOVO: mensagem respondida
  final ChatMessageReply? responding;

  ChatMessage({
    required this.id,
    required this.text,
    required this.userId,
    required this.userName,
    required this.timestamp,
    this.responding,
  });
}

class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;

  final bool showName;
  final bool isFirstInGroup;
  final bool isLastInGroup;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.showName,
    required this.isFirstInGroup,
    required this.isLastInGroup,
  });

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _formatTime(int timestampMs) {
    final dt = DateTime.fromMillisecondsSinceEpoch(timestampMs);
    final now = DateTime.now();
    if (_isSameDay(dt, now)) {
      return DateFormat('HH:mm').format(dt);
    }
    return DateFormat('dd/MM HH:mm').format(dt);
  }

  BorderRadius _bubbleRadius() {
    final base = 16.0;
    final tight = 6.0;
    final tail = 4.0;

    if (isMe) {
      return BorderRadius.only(
        topLeft: Radius.circular(base),
        topRight: Radius.circular(isFirstInGroup ? base : tight),
        bottomLeft: Radius.circular(base),
        bottomRight: Radius.circular(isLastInGroup ? tail : tight),
      );
    }

    return BorderRadius.only(
      topLeft: Radius.circular(isFirstInGroup ? base : tight),
      topRight: Radius.circular(base),
      bottomLeft: Radius.circular(isLastInGroup ? tail : tight),
      bottomRight: Radius.circular(base),
    );
  }

  static const List<Color> _namePalette = [
    Color(0xFF1E88E5),
    Color(0xFFD81B60),
    Color(0xFF43A047),
    Color(0xFF8E24AA),
    Color(0xFFF4511E),
    Color(0xFF3949AB),
    Color(0xFF00897B),
    Color(0xFF5E35B1),
    Color(0xFF039BE5),
    Color(0xFFC0CA33),
  ];

  int _stableHash(String input) {
    var hash = 0;
    for (final unit in input.codeUnits) {
      hash = (hash * 31 + unit) & 0x7fffffff;
    }
    return hash;
  }

  Color _userNameColor(String userId) {
    final idx = _stableHash(userId) % _namePalette.length;
    return _namePalette[idx];
  }

  @override
  Widget build(BuildContext context) {
    final time = _formatTime(message.timestamp);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bubbleColor = isMe
        ? (isDark ? const Color(0xFF1F6F43) : const Color(0xFFDCF8C6))
        : (isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF2F2F2));

    final nameColor = _userNameColor(message.userId);

    final maxBubbleWidth = MediaQuery.of(context).size.width * 0.78;

    final hasReply = message.responding != null;
    final reply = message.responding;

    // Card interno do reply (quote)
    Widget replyWidget() {
      final accent = _userNameColor(reply!.userId); // AQUI

      final replyBg = isMe
          ? (isDark
                ? Colors.black.withOpacity(0.18)
                : Colors.white.withOpacity(0.45))
          : (isDark
                ? Colors.black.withOpacity(0.20)
                : Colors.white.withOpacity(0.55));

      final replyTextColor = isDark ? Colors.white70 : Colors.black87;

      return Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: replyBg,
          borderRadius: BorderRadius.circular(10),
          border: Border(left: BorderSide(width: 4, color: accent)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              reply.userName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 12.5,
                color: accent,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              reply.text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12.5,
                color: replyTextColor,
                height: 1.2,
              ),
            ),
          ],
        ),
      );
    }

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxBubbleWidth),
        child: Container(
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: _bubbleRadius(),
          ),
          padding: const EdgeInsets.fromLTRB(12, 8, 10, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showName) ...[
                Text(
                  message.userName,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: nameColor,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
              ],

              if (hasReply) replyWidget(),

              Wrap(
                alignment: WrapAlignment.end,
                crossAxisAlignment: WrapCrossAlignment.end,
                spacing: 8,
                runSpacing: 4,
                children: [
                  Text(
                    message.text,
                    style: const TextStyle(fontSize: 16, height: 1.25),
                  ),
                  Text(
                    time,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: isDark && isMe
                          ? Colors.grey.shade300
                          : Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
