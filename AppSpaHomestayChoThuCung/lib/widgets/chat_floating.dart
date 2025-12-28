import 'package:flutter/material.dart';

const kChatPink = Color(0xFFFF6185);
const kBackgroundPink = Color(0xFFFFF0F5);

class ChatFloatingButton extends StatefulWidget {
  const ChatFloatingButton({super.key});

  @override
  State<ChatFloatingButton> createState() => _ChatFloatingButtonState();
}

class _ChatFloatingButtonState extends State<ChatFloatingButton> {
  void _openChat() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent, // 🔹 bo góc đẹp
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(12),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.6, // ❗ không quá bự
            decoration: BoxDecoration(
              color: kBackgroundPink,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                /// =========================
                /// 🔹 HEADER
                /// =========================
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: const BoxDecoration(
                    color: kChatPink,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  child: const Center(
                    child: Text(
                      "Chat hỗ trợ",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                /// =========================
                /// 🔹 CHAT CONTENT
                /// =========================
                const Expanded(
                  child: Center(
                    child: Text(
                      "Danh sách tin nhắn",
                      style: TextStyle(color: Colors.black54),
                    ),
                  ),
                ),

                /// =========================
                /// 🔹 INPUT
                /// =========================
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: "Nhập tin nhắn...",
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding:
                            const EdgeInsets.symmetric(horizontal: 14),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      CircleAvatar(
                        backgroundColor: kChatPink,
                        child: IconButton(
                          icon: const Icon(Icons.send,
                              color: Colors.white, size: 20),
                          onPressed: () {},
                        ),
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      backgroundColor: kChatPink,
      shape: const CircleBorder(),
      elevation: 4,
      onPressed: _openChat,
      child: const Icon(
        Icons.message,
        color: Colors.white,
        size: 28,
      ),
    );
  }
}
