import 'package:book_flix/auth.dart';
import 'package:book_flix/database_functions.dart';
import 'package:book_flix/getting_started.dart';
import 'package:book_flix/load_data.dart';
import 'package:book_flix/login_register.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

// This widget displays the widget based on the user's current
// authentication status
class WidgetTree extends StatefulWidget {
  const WidgetTree({super.key});

  @override
  State<WidgetTree> createState() => _WidgetTreeState();
}

class _WidgetTreeState extends State<WidgetTree> {
  DatabaseFunctions db = DatabaseFunctions();

  bool _isLoading = true;
  bool _hasData = false;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  // Determines whether the user exists in firebase. If not, then this
  // means that _hasData is false
  Future<void> _fetchUserData() async {
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (doc.exists && doc.data() != null) {
        setState(() {
          _hasData = true;
        });
      }
    } catch (e) {
      print('Error fetching user data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: Auth().authStateChanges,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            if (_isLoading) {
              return Scaffold(
                  backgroundColor: Colors.white,
                  body: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 50, vertical: 100),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Spacer(),
                          Image.asset('assets/loading_image.png'),
                          Spacer(),
                          Text(
                            'Loading your book recommendations. This may take a moment...',
                            style: GoogleFonts.ubuntu(
                                color: Color(0xff909090), fontSize: 16),
                          ),
                          Spacer(),
                          CircularProgressIndicator(
                            color: Color(0xff4BB1A3),
                          ),
                          Spacer()
                        ],
                      ),
                    ),
                  ));
            }
            if (_hasData) {
              return LoadData();
            } else {
              return GettingStarted();
            }
          } else {
            return LoginPage();
          }
        });
  }
}
