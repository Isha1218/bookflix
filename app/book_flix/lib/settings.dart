import 'package:book_flix/auth.dart';
import 'package:book_flix/database_functions.dart';
import 'package:book_flix/load_data.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// This widget is the settings page. The user has the ability to
// alter their genre weights to edit their book recommendations
class Settings extends StatefulWidget {
  const Settings({super.key, required this.isGettingStarted});

  final bool isGettingStarted;

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  Map<String, double> genreWeights = {};
  DatabaseFunctions db = DatabaseFunctions();

  @override
  void initState() {
    retrieveGenreWeights();
    super.initState();
  }

  // Gets the genre weights from firebase
  Future<void> retrieveGenreWeights() async {
    var snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(Auth().currentUser!.uid)
        .get();

    if (snapshot.exists) {
      Map<String, dynamic> rawGenreWeights = snapshot.data()!['genreWeights'];
      setState(() {
        genreWeights = rawGenreWeights
            .map((key, value) => MapEntry(key, value.toDouble()));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: genreWeights.length == 0
            ? CircularProgressIndicator()
            : SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      titleWidget('Recommendation', 'Settings'),
                      SizedBox(
                        height: 20,
                      ),
                      Text(
                        'Please input your preferences for which genres we should recommend',
                        style: GoogleFonts.ubuntu(color: Color(0xff909090)),
                      ),
                      SizedBox(height: 20),
                      ListView.builder(
                        physics: NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: genreWeights.length,
                        itemBuilder: (context, index) {
                          return settingItem(
                              title: genreWeights.keys
                                      .toList()[index]
                                      .substring(0, 1)
                                      .toUpperCase() +
                                  genreWeights.keys.toList()[index].substring(
                                        1,
                                      ),
                              initialValue: genreWeights.values.toList()[index],
                              onValueChanged: (value) {
                                setState(() {
                                  genreWeights[genreWeights.keys
                                      .toList()[index]] = value;
                                });
                              });
                        },
                      ),
                      SizedBox(
                        height: 20,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: TextButton(
                          style: TextButton.styleFrom(
                            minimumSize: Size.zero,
                            padding: EdgeInsets.zero,
                          ),
                          onPressed: () async {
                            await db.addGenreWeights(genreWeights);
                            showSnackbar(context);
                            if (widget.isGettingStarted) {
                              Navigator.of(context)
                                  .push(MaterialPageRoute(builder: (context) {
                                return LoadData();
                              }));
                            }
                          },
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(5),
                                color: Color(0xff4BB1A3),
                                boxShadow: [
                                  BoxShadow(
                                      color:
                                          Color(0xff4BB1A3).withOpacity(0.35),
                                      offset: Offset(0, 4),
                                      blurRadius: 15)
                                ]),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 40, vertical: 12),
                              child: Center(
                                child: Text(
                                  'Save Preferences',
                                  style: GoogleFonts.ubuntu(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 20,
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  // Represents each single weight (or one genre)
  // and provides a slider, so that the user can
  // edit that weight
  Widget settingItem({
    required String title,
    required double initialValue,
    required ValueChanged<double> onValueChanged,
  }) {
    double current = initialValue;

    return StatefulBuilder(
      builder: (context, setState) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style:
                  GoogleFonts.ubuntu(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            Slider(
              value: current,
              activeColor: Color(0xff4BB1A3),
              inactiveColor: Color.fromARGB(255, 207, 207, 207),
              max: 1,
              label: current.toStringAsFixed(2),
              onChanged: (double value) {
                setState(() {
                  current = value;
                });
                onValueChanged(value);
              },
            ),
            SizedBox(
              height: 10,
            ),
            Divider(),
            SizedBox(
              height: 10,
            )
          ],
        );
      },
    );
  }

  // Shows a snackbar at the bottom once the user hits
  // the "save" button
  void showSnackbar(BuildContext settingsContext) {
    ScaffoldMessenger.of(settingsContext).showSnackBar(
      SnackBar(
        content: Text('Your settings have been updated'),
        duration: Duration(seconds: 5),
      ),
    );
  }

  // Represents the title at the top of the page
  Widget titleWidget(String word1, String word2) {
    return Align(
      alignment: Alignment.topLeft,
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: word1 + ' ',
              style: GoogleFonts.agbalumo(
                fontSize: 24,
                color: Colors.black,
              ),
            ),
            TextSpan(
              text: word2,
              style:
                  GoogleFonts.agbalumo(fontSize: 26, color: Color(0xff4BB1A3)),
            ),
          ],
        ),
      ),
    );
  }
}
