// fileName: chat_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'login_screen.dart';
import 'homepage_screen.dart';

class ChatScreen extends StatefulWidget {
  final String uid; // Karşı tarafın UID'si (Sadece referans ve isim için)
  final String displayName; // Karşı tarafın adı
  final String? chatRoomId; // ✅ KRİTİK: Özel sohbet ID'si (Nullable olmalı)

  const ChatScreen({
    required this.uid,
    required this.displayName,
    this.chatRoomId, // Nullable parametre
    super.key,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();

  // ✅ Firestore koleksiyon referansı artık initState'te atanacak.
  late final CollectionReference _messages;
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    if (widget.chatRoomId != null) {
      // ✅ Özel sohbet: 'chats' koleksiyonu altındaki benzersiz ChatRoom ID belgesine bağlanır.
      _messages = FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatRoomId!)
          .collection('messages');
    } else {
      // Genel sohbet (Eğer uygulamanızda hala genel sohbet varsa, burası eski mantığı korur)
      _messages = FirebaseFirestore.instance.collection('messages');
    }
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final currentUser = FirebaseAuth.instance.currentUser!;

    // ✅ Mesajı doğru sohbete ve doğru gönderen bilgisiyle kaydet
    await _messages.add({
      'text': text,
      'senderUid': currentUser.uid, // Mevcut kullanıcının UID'si
      'senderName': currentUser.displayName ?? currentUser.email ?? 'Anon',
      'createdAt': FieldValue.serverTimestamp(),
    });
    _controller.clear();
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  Widget _buildMessageItem(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final ts = data['createdAt'] as Timestamp?;
    final time = ts != null ? DateFormat.Hm().format(ts.toDate()) : '';

    // ✅ isMe kontrolü: Gönderen UID'sinin mevcut kullanıcının UID'si olup olmadığını kontrol et.
    final isMe = data['senderUid'] == currentUserId;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ), // Maksimum genişlik
        decoration: BoxDecoration(
          color: isMe ? Colors.blue.shade400 : Colors.grey.shade300,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isMe ? const Radius.circular(16) : Radius.zero,
            bottomRight: isMe ? Radius.zero : const Radius.circular(16),
          ),
        ),
        child: Column(
          crossAxisAlignment: isMe
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isMe &&
                widget.chatRoomId != null) // Karşı tarafın adını göster
              Text(
                data['senderName'] ?? 'Anon',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            Text(
              data['text'] ?? '',
              style: TextStyle(color: isMe ? Colors.white : Colors.black),
            ),
            const SizedBox(height: 4),
            Text(
              time,
              style: TextStyle(
                fontSize: 10,
                color: isMe ? Colors.white70 : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Başlığı karşı tarafın adı veya "Genel Sohbet" olarak ayarla
        title: Text(
          widget.chatRoomId != null ? widget.displayName : "Genel Sohbet",
        ),
        actions: [
          // ✅ Geri Butonu: Home butonu, sadece özel sohbette HomePageScreen'e döner
          if (widget.chatRoomId != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: IconButton(
                icon: const Icon(Icons.home, size: 24),
                tooltip: "Ana Sayfa",
                onPressed: () {
                  // PushReplacement ile HomePageScreen'e geri dön (geçmişi temizleyerek)
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => HomePageScreen(
                        uid: currentUserId,
                        displayName:
                            FirebaseAuth.instance.currentUser!.displayName ??
                            FirebaseAuth.instance.currentUser!.email ??
                            "Kullanıcı",
                      ),
                    ),
                  );
                },
              ),
            ),
          // Logout butonu
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: IconButton(
              icon: const Icon(Icons.logout, size: 24),
              onPressed: _signOut,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _messages
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;

                return ListView.builder(
                  reverse: true,
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    return _buildMessageItem(docs[index]);
                  },
                );
              },
            ),
          ),
          // Mesaj yazma alanı
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: "Mesaj yaz...",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
