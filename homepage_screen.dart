import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_screen.dart';
import 'login_screen.dart';
import 'people_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomePageScreen extends StatelessWidget {
  final String uid;
  final String displayName;
  const HomePageScreen({
    super.key,
    required this.uid,
    required this.displayName,
  });

  Future<void> _signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    // ignore: use_build_context_synchronously
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final myUid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Sohbetler"), // ✅ Ekrandaki başlık artık bu
        actions: [
          // KİŞİLER (ARAMA) BUTONU
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: "Kişi Ara",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PeopleScreen()),
              );
            },
          ),
          // Çıkış butonu
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _signOut(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            // ✅ KULLANICI LİSTESİ BURADA YÜKLENİYOR
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("users")
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  ); // Yükleme ekranı
                }

                if (snapshot.hasError) {
                  return Center(child: Text("Hata: ${snapshot.error}."));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text("Kayıtlı kullanıcı bulunamadı."),
                  );
                }

                var users = snapshot.data!.docs;
                // Kendini listeden çıkar
                final chatList = users
                    .where((user) => user["uid"] != myUid)
                    .toList();

                if (chatList.isEmpty) {
                  return const Center(
                    child: Text("Başka bir kullanıcı bulunamadı."),
                  );
                }

                return ListView.builder(
                  itemCount: chatList.length,
                  itemBuilder: (context, index) {
                    var user = chatList[index];
                    final otherUid = user["uid"];

                    // ChatRoom ID oluşturma mantığı
                    final chatRoomId = (myUid.compareTo(otherUid) < 0)
                        ? '${myUid}_$otherUid'
                        : '${otherUid}_$myUid';

                    return ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.person)),
                      title: Text(user["displayName"] ?? user["email"]),
                      subtitle: const Text("Sohbet başlatmak için tıklayın."),
                      onTap: () {
                        // Seçilen kullanıcıyla ChatScreen'e git
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatScreen(
                              uid: otherUid,
                              displayName: user["displayName"] ?? user["email"],
                              chatRoomId:
                                  chatRoomId, // ✅ chatRoomId gönderiliyor
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
