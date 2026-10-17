// fileName: main.dart - YENİ ÇÖZÜM İÇİN GÜNCELLENMİŞ VERSİYON

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';
import 'firebase_options.dart';
import 'homepage_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Asap Chat',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
        textTheme: Theme.of(context).textTheme.apply(fontFamily: 'Roboto'),
      ),
      // Auth durumunu dinleyen yeni giriş noktası
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // Auth durumunu StreamBuilder ile dinleyelim
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Eğer bağlantı henüz kurulmadıysa (Initial state)
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;

        // Kullanıcı giriş yapmamışsa LoginScreen'e git
        if (user == null) {
          return const LoginScreen();
        }

        // Kullanıcı giriş yapmışsa HomePageScreen'e git
        return HomePageScreen(uid: user.uid, displayName: user.email ?? 'Anon');
      },
    );
  }
}
