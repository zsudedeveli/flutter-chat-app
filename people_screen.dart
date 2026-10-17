// fileName: people_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_screen.dart';

class PeopleScreen extends StatefulWidget {
  const PeopleScreen({Key? key}) : super(key: key);

  @override
  State<PeopleScreen> createState() => _PeopleScreenState();
}

class _PeopleScreenState extends State<PeopleScreen> {
  String searchText = "";

  @override
  Widget build(BuildContext context) {
    final myUid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(title: const Text("Kişi Ara (E-mail)")),
      body: Column(
        children: [
          // 🔍 Arama kutusu
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(
                labelText: "E-mail ile ara",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (val) {
                setState(() {
                  searchText = val.trim();
                });
              },
            ),
          ),

          // 🔽 ARAMA SONUÇLARI
          Expanded(
            child: (searchText.isEmpty)
                ? const Center(child: Text("Arama yapmak için e-mail yazınız."))
                : StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection("users")
                        .where("email", isGreaterThanOrEqualTo: searchText)
                        .where(
                          "email",
                          isLessThanOrEqualTo: "$searchText\uf8ff",
                        )
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      var users = snapshot.data!.docs;
                      // Kendini listeden çıkar
                      final searchResults = users
                          .where((user) => user["uid"] != myUid)
                          .toList();

                      if (searchResults.isEmpty) {
                        return const Center(
                          child: Text("Kullanıcı bulunamadı."),
                        );
                      }

                      return ListView.builder(
                        itemCount: searchResults.length,
                        itemBuilder: (context, index) {
                          var user = searchResults[index];
                          final otherUid = user["uid"];

                          // Chat ID'sini oluştur
                          final chatRoomId = (myUid.compareTo(otherUid) < 0)
                              ? '${myUid}_$otherUid'
                              : '${otherUid}_$myUid';

                          return ListTile(
                            leading: const CircleAvatar(
                              child: Icon(Icons.person),
                            ),
                            title: Text(user["email"]),
                            subtitle: Text(user["displayName"] ?? ""),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ChatScreen(
                                    uid: otherUid,
                                    displayName:
                                        user["displayName"] ?? user["email"],
                                    chatRoomId: chatRoomId,
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
