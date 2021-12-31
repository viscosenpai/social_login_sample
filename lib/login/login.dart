import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:crypto/crypto.dart';
import 'package:twitter_login/twitter_login.dart';
import '../app.dart';

/// Generates a cryptographically secure random nonce, to be included in a
/// credential request.
String generateNonce([int length = 32]) {
  const charset =
      '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
  final random = Random.secure();
  return List.generate(length, (_) => charset[random.nextInt(charset.length)])
      .join();
}

/// Returns the sha256 hash of [input] in hex notation.
String sha256ofString(String input) {
  final bytes = utf8.encode(input);
  final digest = sha256.convert(bytes);
  return digest.toString();
}

class Login extends StatelessWidget {
  Login({Key? key}) : super(key: key);

  // Google認証
  final _googleSignin = GoogleSignIn(scopes: [
    'email',
    'https://www.googleapis.com/auth/contacts.readonly',
  ]);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            children: <Widget>[
              ElevatedButton(
                onPressed: () async {
                  final GoogleSignInAccount? googleUser =
                      await _googleSignin.signIn();
                  final GoogleSignInAuthentication? googleAuth =
                      await googleUser?.authentication;
                  final credential = GoogleAuthProvider.credential(
                    accessToken: googleAuth?.accessToken,
                    idToken: googleAuth?.idToken,
                  );

                  try {
                    UserCredential result = await FirebaseAuth.instance
                        .signInWithCredential(credential);
                    User? user = result.user;
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => App(userId: user!.uid),
                        ));
                  } catch (e) {
                    print(e);
                  }
                },
                child: const Text('Google 認証'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final rawNonce = generateNonce();
                  final nonce = sha256ofString(rawNonce);

                  final appleCredential =
                      await SignInWithApple.getAppleIDCredential(
                    scopes: [
                      AppleIDAuthorizationScopes.email,
                      AppleIDAuthorizationScopes.fullName,
                    ],
                    nonce: nonce,
                  );
                  final oauthCredential = OAuthProvider("apple.com").credential(
                    idToken: appleCredential.identityToken,
                    rawNonce: rawNonce,
                  );

                  try {
                    UserCredential result = await FirebaseAuth.instance
                        .signInWithCredential(oauthCredential);
                    User? user = result.user;
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => App(userId: user!.uid),
                        ));
                  } catch (e) {
                    print(e);
                  }
                },
                child: const Text('Apple 認証'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final twitterLogin = TwitterLogin(
                    // apiKey: "kPA8p7WimMXGOBy4M7vrWU6eH",
                    apiKey: dotenv.get('TWITTER_API_KEY'),
                    // apiSecretKey:
                    //     "risBmA4tyNawmHOqOLpPfePGtSNuCNLkEkC3FJ7UtYaXjHiab7",
                    apiSecretKey: dotenv.get('TWITTER_API_SECRET'),
                    redirectURI: "twittersdk://",
                  );
                  final authResult = await twitterLogin.login();
                  switch (authResult.status) {
                    case TwitterLoginStatus.loggedIn:
                      print('logged in');
                      final AuthCredential twitterAuthCredential =
                          TwitterAuthProvider.credential(
                              accessToken: authResult.authToken!,
                              secret: authResult.authTokenSecret!);
                      try {
                        UserCredential result = await FirebaseAuth.instance
                            .signInWithCredential(twitterAuthCredential);
                        User? user = result.user;
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => App(userId: user!.uid),
                            ));
                      } catch (e) {
                        print(e);
                      }
                      break;
                    case TwitterLoginStatus.cancelledByUser:
                      print('cancelledByUser');
                      break;
                    case TwitterLoginStatus.error:
                      print('error');
                      break;
                    default:
                      return null;
                  }
                },
                child: const Text('Twitter 認証'),
              )
            ],
          ),
        ),
      ),
    );
  }
}
