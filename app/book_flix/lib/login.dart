import 'dart:async';

import 'package:book_flix/auth.dart';
import 'package:book_flix/register.dart';
import 'package:book_flix/widget_tree.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';

// User taken to this page when they are signing
// in with an existing email and password
class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  TextEditingController email = TextEditingController();
  TextEditingController password = TextEditingController();
  String? errorMessage = '';

  // Performs the process of signing the user and catching any
  // incorrect emails/passwords in the process
  Future<void> signInWithEmailAndPassword() async {
    try {
      await Auth().signInWithEmailAndPassword(
          email: email.text, password: password.text);
    } on FirebaseAuthException catch (e) {
      setState(() {
        errorMessage = e.message;
      });
      Timer(Duration(seconds: 5), () {
        setState(() {
          errorMessage = '';
        });
      });
    }
  }

  // The text field for the user to enter their email
  Widget emailTextField() {
    return TextField(
      style: GoogleFonts.ubuntu(
        fontSize: 14,
        color: Colors.black,
      ),
      autocorrect: false,
      controller: email,
      decoration: InputDecoration(
          filled: true,
          fillColor: Color(0xff4BB1A3).withOpacity(0.15),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
              color: Color(0xff4BB1A3),
              width: 2,
            ),
          ),
          hintText: 'Email',
          hintStyle: GoogleFonts.ubuntu(
              color: Color.fromARGB(255, 112, 112, 112), fontSize: 14)),
    );
  }

  // The text field for the user to enter their password
  Widget passwordTextField() {
    return TextField(
      style: GoogleFonts.ubuntu(
        fontSize: 14,
        color: Colors.black,
      ),
      autocorrect: false,
      obscureText: true,
      controller: password,
      decoration: InputDecoration(
          filled: true,
          fillColor: Color(0xff4BB1A3).withOpacity(0.15),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
              color: Color(0xff4BB1A3),
              width: 2,
            ),
          ),
          hintText: 'Password',
          hintStyle: GoogleFonts.ubuntu(
              color: Color.fromARGB(255, 112, 112, 112), fontSize: 14)),
    );
  }

  // Represents the submit button. Once submitted and
  // there is no error message, the user will be taken
  // to the home page.
  Widget submitWidget() {
    return TextButton(
      onPressed: () async {
        await signInWithEmailAndPassword();
        if (errorMessage == '') {
          Navigator.of(context).push(MaterialPageRoute(builder: (context) {
            return WidgetTree();
          }));
        }
      },
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
            color: Color(0xff4BB1A3),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                  color: Color(0xff4BB1A3).withOpacity(0.35),
                  offset: Offset(0, 4),
                  blurRadius: 15)
            ]),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Center(
              child: Text(
            'Sign In',
            style: GoogleFonts.ubuntu(
                color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500),
          )),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 100, 24, 0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize:
                  MainAxisSize.min, // Allows column to shrink if needed
              children: [
                Text(
                  'Login Here',
                  style: GoogleFonts.ubuntu(
                    color: Color(0xff4BB1A3),
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 25),
                Text(
                  "Welcome back you've\nbeen missed!",
                  style: GoogleFonts.ubuntu(
                    color: Colors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 50),
                emailTextField(),
                SizedBox(height: 20),
                passwordTextField(),
                SizedBox(height: 50),
                submitWidget(),
                if (errorMessage != null)
                  Text(
                    errorMessage!,
                    style: GoogleFonts.ubuntu(
                      color: Colors.red,
                      fontSize: 12,
                    ),
                  ),
                SizedBox(height: 20),
                TextButton(
                  onPressed: () {
                    Navigator.of(context)
                        .push(MaterialPageRoute(builder: (context) {
                      return Register();
                    }));
                  },
                  style: TextButton.styleFrom(
                    minimumSize: Size.zero,
                    padding: EdgeInsets.zero,
                  ),
                  child: Text(
                    'Create new account',
                    style: GoogleFonts.ubuntu(
                      color: Colors.black,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
