import 'dart:async';

import 'package:book_flix/auth.dart';
import 'package:book_flix/login.dart';
import 'package:book_flix/widget_tree.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';

// User taken to this page when they are registering
// as a new user
class Register extends StatefulWidget {
  const Register({super.key});

  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  TextEditingController email = TextEditingController();
  TextEditingController password = TextEditingController();
  String? errorMessage = '';

  // Text field where the user can input their email
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

  // Text field where the user can input their password
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

  // Performs the process of creating a user and catching any
  // invalid emails/passwords in the process
  Future<void> createUserWithEmailAndPassword() async {
    try {
      await Auth().createUserWithEmailAndPassword(
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

  // Submit button that creates the user if there is no error
  // and takes user to the home page
  Widget submitWidget() {
    return TextButton(
      onPressed: () async {
        await createUserWithEmailAndPassword();
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
            'Create Account',
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
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Create Account Here',
                  style: GoogleFonts.ubuntu(
                    color: Color(0xff4BB1A3),
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 25),
                Text(
                  "Get personal reading recommendations",
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
                      return Login();
                    }));
                  },
                  style: TextButton.styleFrom(
                    minimumSize: Size.zero,
                    padding: EdgeInsets.zero,
                  ),
                  child: Text(
                    'Already have an account? Login',
                    style: GoogleFonts.ubuntu(
                      color: Colors.black,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
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
