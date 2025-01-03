import 'package:book_flix/login.dart';
import 'package:book_flix/register.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// If user is not currently logged in, then they are taken to this page,
// where they are given the option to either login or register
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  String? errorMessage = '';
  bool isLogin = false;

  // Widget representing a button that takes the user
  // to the login page
  Widget loginButton() {
    return TextButton(
      style: TextButton.styleFrom(
        minimumSize: Size.zero,
        padding: EdgeInsets.zero,
      ),
      onPressed: () {
        Navigator.of(context).push(MaterialPageRoute(builder: (context) {
          return Login();
        }));
      },
      child: Container(
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
            color: Color(0xff4BB1A3),
            boxShadow: [
              BoxShadow(
                  color: Color(0xff4BB1A3).withOpacity(0.35),
                  offset: Offset(0, 4),
                  blurRadius: 15)
            ]),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
          child: Text(
            'Login',
            style: GoogleFonts.ubuntu(
                color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500),
          ),
        ),
      ),
    );
  }

  // Widget representing a button that takes the user
  // the register page
  Widget registerButton() {
    return TextButton(
      style: TextButton.styleFrom(
        minimumSize: Size.zero,
        padding: EdgeInsets.zero,
      ),
      onPressed: () {
        Navigator.of(context).push(MaterialPageRoute(builder: (context) {
          return Register();
        }));
      },
      child: Container(
        decoration: BoxDecoration(color: Colors.white),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
          child: Text(
            'Register',
            style: GoogleFonts.ubuntu(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.w500,
                shadows: [
                  Shadow(
                      color: Colors.black.withOpacity(0.15),
                      offset: Offset(0, 4),
                      blurRadius: 50)
                ]),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        height: double.infinity,
        width: double.infinity,
        padding: EdgeInsets.all(20),
        child: Padding(
          padding: EdgeInsets.fromLTRB(24, 100, 24, 75),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                  height: 300, child: Image.asset('assets/bookflix_logo.png')),
              //
              Spacer(),
              Text(
                'Discover Your \nPerfect Read Here',
                style: GoogleFonts.ubuntu(
                  color: Color(0xff4BB1A3),
                  fontSize: 28,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(
                height: 30,
              ),
              Text(
                'No more scrolling endlessly on Goodreads to find your next book. You\'re welcome!',
                style: GoogleFonts.ubuntu(
                  color: Colors.black,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [loginButton(), registerButton()],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
