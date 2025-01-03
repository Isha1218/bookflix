import 'package:book_flix/database_functions.dart';
import 'package:book_flix/settings.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Page that user is taken to when this is the first time they
// are using the app
class GettingStarted extends StatefulWidget {
  const GettingStarted({super.key});

  @override
  State<GettingStarted> createState() => _GettingStartedState();
}

class _GettingStartedState extends State<GettingStarted> {
  DatabaseFunctions db = DatabaseFunctions();
  int user_id = -2; // a user_id of -2 will never exist

  @override
  void initState() {
    getNextUserId();
    super.initState();
  }

  // Gets the user's user id. This user id
  // hasn't been given to the user just yet
  Future<void> getNextUserId() async {
    user_id = await db.getNextUserId();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 60),
          child: Column(
            children: [
              Spacer(),
              Image.asset('assets/getting_started_image.png',
                  fit: BoxFit.cover),
              SizedBox(
                height: 60,
              ),
              Text(
                'Let\'s start by getting to know more about you by telling us your favorite books and genres',
                style: GoogleFonts.ubuntu(
                  fontSize: 16,
                ),
              ),
              SizedBox(
                height: 60,
              ),
              TextButton(
                style: TextButton.styleFrom(
                  minimumSize: Size.zero,
                  padding: EdgeInsets.zero,
                ),
                onPressed: () async {
                  // Adds the user_id that has been identified for the
                  // new user to firebase
                  await db.addUserId(user_id);
                  // Pre initializes all genre weights to 0.5
                  await db.addGenreWeights({
                    'children': 0.5,
                    'fiction': 0.5,
                    'young-adult': 0.5,
                    'romance': 0.5,
                    'mystery': 0.5,
                    'dystopian': 0.5,
                    'fantasy': 0.5,
                    'non-fiction': 0.5,
                    'science-fiction': 0.5,
                    'biography': 0.5,
                    'history': 0.5,
                    'philosophy': 0.5,
                    'horror': 0.5,
                    'thriller': 0.5,
                    'poetry': 0.5,
                    'politics': 0.5,
                    'humor': 0.5,
                    'adventure': 0.5,
                    'classic': 0.5,
                    'drama': 0.5
                  });
                  Navigator.of(context)
                      .push(MaterialPageRoute(builder: (context) {
                    return Settings(isGettingStarted: true);
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Text(
                          'Get Started',
                          style: GoogleFonts.ubuntu(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w500),
                        ),
                        Icon(
                          Icons.arrow_forward,
                          color: Colors.white,
                          size: 28,
                        )
                      ],
                    ),
                  ),
                ),
              ),
              Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
