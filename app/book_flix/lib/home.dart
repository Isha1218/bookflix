import 'package:book_flix/auth.dart';
import 'package:book_flix/book_view.dart';
import 'package:book_flix/database_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:book_flix/book.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:simple_shadow/simple_shadow.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:flutter_rating/flutter_rating.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Home page of Book Flix, where users can see their recommendations
// ignore: must_be_immutable
class Home extends StatefulWidget {
  Home(
      {super.key,
      required this.continueReading,
      required this.recBooks,
      required this.shelvedForLater,
      required this.completeShelf,
      required this.didNotCompleteShelf,
      required this.totalCompleteShelf,
      required this.initialSearchGrid});

  List<Book> continueReading;
  Map<String, List<Book>> recBooks;
  List<Book> shelvedForLater;
  List<Book> completeShelf;
  List<Book> didNotCompleteShelf;
  List<Book> totalCompleteShelf;
  List<Book> initialSearchGrid;

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  DatabaseFunctions db = DatabaseFunctions();
  ValueNotifier<String> updateStringNotifier =
      ValueNotifier<String>('In Progress');
  ValueNotifier<double> ratingNotifier = ValueNotifier<double>(3);
  int starCount = 5;
  TextEditingController pageNum = TextEditingController();
  String ipAddress = dotenv.env['IP_ADDRESS'] ?? '';
  static int df_user_id = -2; // user id can never be -2

  @override
  void initState() {
    super.initState();
    db.retrieveUserId();
    df_user_id = db.df_user_id;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Align(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      titleWidget('Book', 'Flix'),
                      PopupMenuButton(
                        padding: EdgeInsets.zero,
                        icon: Icon(
                          Icons.person_rounded,
                          size: 30,
                        ),
                        itemBuilder: (context) {
                          return [
                            PopupMenuItem(
                              onTap: () async {
                                await Auth().signOut();
                              },
                              child: Center(
                                  child: Text(
                                'Sign Out',
                                style: GoogleFonts.ubuntu(),
                              )),
                              textStyle: TextStyle(color: Colors.black),
                            ),
                          ];
                        },
                        color: Colors.white,
                        offset: Offset(0, 40),
                      ),
                    ],
                  ),
                  widget.continueReading.length == 0
                      ? Container()
                      : SizedBox(height: 25),
                  widget.continueReading.length == 0
                      ? Container()
                      : Text(
                          'Continue Reading',
                          style: GoogleFonts.ubuntu(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                  widget.continueReading.length == 0
                      ? Container()
                      : SizedBox(height: 10),
                  widget.continueReading.length == 0
                      ? Container()
                      : Container(
                          height: 170,
                          child: ListView.builder(
                            clipBehavior: Clip.none,
                            scrollDirection: Axis.horizontal,
                            itemCount: widget.continueReading.length,
                            itemBuilder: (context, index) {
                              widget.continueReading[index].status =
                                  'In Progress';
                              return continueReadingWidget(
                                  widget.continueReading[index], index);
                            },
                          ),
                        ),
                  SizedBox(height: 30),
                  widget.recBooks.isEmpty
                      ? CircularProgressIndicator()
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            widget.shelvedForLater.length >= 1
                                ? recRowWidget(
                                    widget.shelvedForLater, 'Shelved For Later')
                                : Container(),
                            widget.shelvedForLater.length >= 1
                                ? SizedBox(
                                    height: 20,
                                  )
                                : Container(),
                            Column(
                              children: widget.recBooks.entries.map((entry) {
                                final title = entry.key;
                                final books = entry.value;
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    recRowWidget(books, title),
                                    SizedBox(height: 20),
                                  ],
                                );
                              }).toList(),
                            ),
                          ],
                        )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Pop up menu that allows users to update the progress of a book
  // that they are currently reading
  Future updateProgress(Book book, int index) {
    return showDialog(
        context: context,
        builder: (context) {
          return FutureBuilder<Color>(
              future: _updatePalette(book.imageUrl),
              builder: (context, snapshot) {
                Color? backgroundColor =
                    snapshot.connectionState == ConnectionState.done &&
                            snapshot.hasData
                        ? snapshot.data!
                        : Colors.white;

                return ValueListenableBuilder<String>(
                  valueListenable: updateStringNotifier,
                  builder: (context, updateString, child) {
                    return ValueListenableBuilder<double>(
                      valueListenable: ratingNotifier,
                      builder: (context, rating, child) {
                        return AlertDialog(
                          backgroundColor: Color.alphaBlend(
                            backgroundColor.withOpacity(0.5),
                            Colors.white,
                          ),
                          content: Padding(
                            padding: const EdgeInsets.only(top: 30),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Have you finished this book?',
                                  style: GoogleFonts.ubuntu(
                                    fontSize: 16,
                                    color: backgroundColor
                                                .withOpacity(0.5)
                                                .computeLuminance() <
                                            0.2
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                ),
                                ..._buildRadioOptions(
                                    backgroundColor, updateString),
                                const SizedBox(height: 25),
                                if (updateString == 'In Progress')
                                  TextField(
                                    style: GoogleFonts.ubuntu(
                                      color: backgroundColor
                                                  .withOpacity(0.5)
                                                  .computeLuminance() <
                                              0.2
                                          ? Colors.white
                                          : Colors.black,
                                      fontSize: 14,
                                    ),
                                    cursorColor: backgroundColor
                                                .withOpacity(0.5)
                                                .computeLuminance() <
                                            0.2
                                        ? Colors.white
                                        : Colors.black,
                                    controller: pageNum,
                                    decoration: InputDecoration(
                                      enabledBorder: UnderlineInputBorder(
                                        borderSide: BorderSide(
                                            color: backgroundColor
                                                        .withOpacity(0.5)
                                                        .computeLuminance() <
                                                    0.2
                                                ? Colors.white
                                                : Colors.black,
                                            width: 1),
                                      ),
                                      focusedBorder: UnderlineInputBorder(
                                        borderSide: BorderSide(
                                            color: backgroundColor
                                                        .withOpacity(0.5)
                                                        .computeLuminance() <
                                                    0.2
                                                ? Colors.white
                                                : Colors.black,
                                            width: 1),
                                      ),
                                      hintText: 'Updated page number',
                                      hintStyle: GoogleFonts.ubuntu(
                                        color: backgroundColor
                                                    .withOpacity(0.5)
                                                    .computeLuminance() <
                                                0.2
                                            ? Colors.white
                                            : Colors.black,
                                        fontSize: 14,
                                      ),
                                    ),
                                  )
                                else
                                  Column(
                                    children: [
                                      Text(
                                        updateString == 'Finished'
                                            ? 'Great! Please rate this book'
                                            : 'Sorry to hear that. Please rate this book',
                                        style: GoogleFonts.ubuntu(
                                          color: backgroundColor
                                                      .withOpacity(0.5)
                                                      .computeLuminance() <
                                                  0.2
                                              ? Colors.white
                                              : Colors.black,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      StarRating(
                                        size: 40,
                                        rating: rating,
                                        color: backgroundColor
                                                    .withOpacity(0.5)
                                                    .computeLuminance() <
                                                0.2
                                            ? Colors.white
                                            : Colors.black,
                                        borderColor: backgroundColor
                                                    .withOpacity(0.5)
                                                    .computeLuminance() <
                                                0.2
                                            ? Colors.white
                                            : Colors.black,
                                        allowHalfRating: false,
                                        starCount: starCount,
                                        onRatingChanged: (newRating) {
                                          ratingNotifier.value = newRating;
                                        },
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                          actions: [
                            TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: Text(
                                  'Cancel',
                                  style: GoogleFonts.ubuntu(
                                      color: backgroundColor
                                                  .withOpacity(0.5)
                                                  .computeLuminance() <
                                              0.2
                                          ? Colors.white
                                          : Colors.black,
                                      fontWeight: FontWeight.w500),
                                )),
                            TextButton(
                                onPressed: () async {
                                  await _submitUpdate(
                                      book, index, updateString, rating);
                                  Navigator.of(context).pop();
                                },
                                child: Text(
                                  'Submit',
                                  style: GoogleFonts.ubuntu(
                                      color: backgroundColor
                                                  .withOpacity(0.5)
                                                  .computeLuminance() <
                                              0.2
                                          ? Colors.white
                                          : Colors.black,
                                      fontWeight: FontWeight.w500),
                                )),
                          ],
                        );
                      },
                    );
                  },
                );
              });
        });
  }

  // Builds a multiple choice questionaire, so that users can
  // select an option indicating the progress of their book
  List<Widget> _buildRadioOptions(Color backgroundColor, String updateString) {
    return [
      RadioListTile(
        fillColor: MaterialStateColor.resolveWith(
          (states) => backgroundColor.computeLuminance() < 0.2
              ? Colors.white
              : Colors.black,
        ),
        title: Text(
          'Finished',
          style: GoogleFonts.ubuntu(
            fontSize: 15,
            color: backgroundColor.computeLuminance() < 0.2
                ? Colors.white
                : Colors.black,
          ),
        ),
        value: 'Finished',
        groupValue: updateString,
        onChanged: (value) {
          updateStringNotifier.value = value as String;
        },
      ),
      RadioListTile(
        fillColor: MaterialStateColor.resolveWith(
          (states) => backgroundColor.computeLuminance() < 0.2
              ? Colors.white
              : Colors.black,
        ),
        title: Text(
          "Couldn't Complete",
          style: GoogleFonts.ubuntu(
            fontSize: 15,
            color: backgroundColor.computeLuminance() < 0.2
                ? Colors.white
                : Colors.black,
          ),
        ),
        value: 'Did Not Finish',
        groupValue: updateString,
        onChanged: (value) {
          updateStringNotifier.value = value as String;
        },
      ),
      RadioListTile(
        fillColor: MaterialStateColor.resolveWith(
          (states) => backgroundColor.computeLuminance() < 0.2
              ? Colors.white
              : Colors.black,
        ),
        title: Text(
          'In Progress',
          style: GoogleFonts.ubuntu(
            fontSize: 15,
            color: backgroundColor.computeLuminance() < 0.2
                ? Colors.white
                : Colors.black,
          ),
        ),
        value: 'In Progress',
        groupValue: updateString,
        onChanged: (value) {
          updateStringNotifier.value = value as String;
        },
      ),
    ];
  }

  // Adds book to users_df if user has finished reading it
  Future<void> addBookToDf(Book book) async {
    await compute(addBookToDfCompute, {
      'ipAddress': ipAddress,
      'bookId': book.bookId,
      'rating': ratingNotifier.value.toInt(),
    });
    return;
  }

  // Performs process of adding book to users_df
  static Future<void> addBookToDfCompute(Map<String, dynamic> data) async {
    final String ipAddress = data['ipAddress'];
    final int bookId = int.parse(data['bookId']);
    final int rating = data['rating'];

    final url =
        Uri.parse('http://' + ipAddress + ':5000/bookflix/add_user_rating');
    try {
      final response = await http.post(url,
          headers: {'Content-Type': 'application/json'},
          body: json.encode(
              {'user_id': df_user_id, 'book_id': bookId, 'rating': rating}));
      if (response.statusCode == 200) {
        print('Successfully added to users df');
      } else {
        print('Failed to add to users df');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  // Updates backend depending on what user has selected
  Future<void> _submitUpdate(
      Book book, int index, String updateString, double rating) async {
    // If user has finished book, this book is added to firebase,
    // removed from continue reading list, added to the completed
    // books list, and added to the total completed books list.
    // It is also added to users_df via Flask.
    if (updateString == 'Finished') {
      await DatabaseFunctions()
          .addBookToCompleted(book, rating.toInt(), 'Finished');
      await DatabaseFunctions().removeFromInProgressList(book);
      setState(() {
        book.status = 'Complete';
        widget.continueReading.removeAt(index);
        widget.completeShelf.add(book);
        widget.totalCompleteShelf.add(book);
      });
      addBookToDf(book);
      // If user is still reading the books, then the current page
      // number that user is on is updated in Firebase.
    } else if (updateString == 'In Progress') {
      book.status = 'In Progress';
      await DatabaseFunctions().updatePageNumber(book, int.parse(pageNum.text));
      pageNum.clear();
      // If the user was unable to complete a book, then this book
      // is added to Firebase, removed from 'continue reading' books
      // list, added to the 'did not complete' books list, and added
      // to the 'total completed' books list. It is also added to
      // users_df via Flask.
    } else {
      book.status = 'Did Not Finish';
      await DatabaseFunctions()
          .addBookToCompleted(book, rating.toInt(), 'Did Not Finish');
      await DatabaseFunctions().removeFromInProgressList(book);
      setState(() {
        widget.continueReading.removeAt(index);
        widget.didNotCompleteShelf.add(book);
        widget.totalCompleteShelf.add(book);
      });
      addBookToDf(book);
    }
  }

  // Miniature widget representing a Book object. Includes info on
  // book image, title, author, and rating
  Widget bookCardWidget(Book book) {
    return FutureBuilder<Color>(
      future: _updatePalette(book.imageUrl),
      builder: (context, snapshot) {
        Color? backgroundColor = null;
        if (snapshot.connectionState == ConnectionState.done &&
            snapshot.hasData) {
          backgroundColor = snapshot.data!;
        }

        return TextButton(
          style: TextButton.styleFrom(
            minimumSize: Size.zero,
            padding: EdgeInsets.zero,
          ),
          onPressed: () {
            navigateToBookView(context, book, backgroundColor!);
          },
          child: Container(
            width: 140,
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  offset: Offset(0, 4),
                  blurRadius: 20,
                ),
              ],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 135,
                  decoration: BoxDecoration(
                    color: backgroundColor != null
                        ? backgroundColor.withOpacity(0.5)
                        : Colors.white,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(10),
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(14),
                    child: SimpleShadow(
                      offset: Offset(0, 4),
                      color: Colors.black,
                      opacity: 0.25,
                      sigma: 8,
                      child: Center(
                        child: Image.network(
                          book.imageUrl,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        book.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.prata(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.black),
                      ),
                      Text(
                        book.author,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.ubuntu(
                          color: Color(0xff909090),
                          fontSize: 12,
                        ),
                      ),
                      SizedBox(
                        height: 5,
                      ),
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                        decoration: BoxDecoration(
                            color: Color(0xffF2D232).withOpacity(0.3),
                            borderRadius: BorderRadius.circular(8)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.star,
                              color: Color(0xffF2D232),
                              size: 14,
                            ),
                            SizedBox(
                              width: 2,
                            ),
                            Text(
                              book.averageRating.toStringAsFixed(1),
                              style: GoogleFonts.ubuntu(
                                  fontSize: 10, color: Colors.black),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  // Widget representing a row of recommendations that belong
  // to a certain category
  Widget recRowWidget(var books, String title) {
    return books == null
        ? CircularProgressIndicator()
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.ubuntu(
                    fontSize: 15, fontWeight: FontWeight.w500),
              ),
              SizedBox(
                height: 10,
              ),
              Container(
                height: 220,
                child: ListView.builder(
                  shrinkWrap: true,
                  clipBehavior: Clip.none,
                  scrollDirection: Axis.horizontal,
                  itemCount: books!.length,
                  itemBuilder: (context, count) {
                    return bookCardWidget(books[count]);
                  },
                ),
              ),
            ],
          );
  }

  // Represents title at the top of the screen
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

  // Determines the background color of each book card widget
  Future<Color> _updatePalette(String imageUrl) async {
    try {
      final paletteGenerator = await PaletteGenerator.fromImageProvider(
        NetworkImage(imageUrl),
      );

      final primaryColor = paletteGenerator.dominantColor?.color;
      final secondaryColor = paletteGenerator.paletteColors.length > 1
          ? paletteGenerator.paletteColors[1].color
          : Colors.grey;
      final tertiaryColor = paletteGenerator.paletteColors.length > 2
          ? paletteGenerator.paletteColors[2].color
          : Colors.grey;

      if (primaryColor != null) {
        final primaryLuminance = primaryColor.computeLuminance();

        const double blackThreshold = 0.3;
        const double whiteThreshold = 0.7;

        if (primaryLuminance < blackThreshold ||
            primaryLuminance > whiteThreshold) {
          var secondaryLuminance = secondaryColor.computeLuminance();
          if (secondaryLuminance < blackThreshold ||
              secondaryLuminance > whiteThreshold) {
            return tertiaryColor;
          } else {
            return secondaryColor;
          }
        } else {
          return primaryColor;
        }
      } else {
        return Colors.grey;
      }
    } catch (e) {
      return Colors.grey;
    }
  }

  // Widget representing a book that is currently in progress
  Widget continueReadingWidget(Book book, int index) {
    return FutureBuilder(
        future: _updatePalette(book.imageUrl),
        builder: (context, snapshot) {
          Color? backgroundColor = null;
          if (snapshot.connectionState == ConnectionState.done &&
              snapshot.hasData) {
            backgroundColor = snapshot.data!;
          }

          return TextButton(
            style: TextButton.styleFrom(
              minimumSize: Size.zero,
              padding: EdgeInsets.zero,
            ),
            onPressed: () {
              navigateToBookView(context, book, backgroundColor!);
            },
            child: Container(
              margin: EdgeInsets.only(right: 32),
              width: 350,
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                        offset: Offset(0, 4),
                        blurRadius: 20,
                        color: Colors.black.withOpacity(0.15))
                  ]),
              child: Container(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Container(
                        height: double.infinity,
                        decoration: BoxDecoration(
                            color: backgroundColor != null
                                ? backgroundColor.withOpacity(0.5)
                                : Colors.white,
                            borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(10),
                                bottomLeft: Radius.circular(10))),
                        child: Container(
                          padding: EdgeInsets.all(20),
                          child: SimpleShadow(
                            offset: Offset(0, 4),
                            color: Colors.black,
                            opacity: 0.25,
                            sigma: 8,
                            child: Center(
                              child: Image.network(
                                book.imageUrl,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Flexible(
                      flex: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: StreamBuilder(
                            stream: FirebaseFirestore.instance
                                .collection('users')
                                .doc(Auth().currentUser!.uid)
                                .collection('in_progress')
                                .doc(book.bookId)
                                .snapshots(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return Container();
                              } else if (snapshot.hasError) {
                                return Text("Couldn't determine progress");
                              } else if (snapshot.hasData &&
                                  snapshot.data!.exists) {
                                final data = snapshot.data;
                                return Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      book.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.prata(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black),
                                    ),
                                    Text(
                                      book.author,
                                      style: GoogleFonts.ubuntu(
                                          fontSize: 13,
                                          color: Color(0xff909090)),
                                    ),
                                    SizedBox(
                                      height: 10,
                                    ),
                                    LinearProgressIndicator(
                                      color: Color(0xff4BB1A3),
                                      backgroundColor: Color(0xffD9D9D9),
                                      value: data!['currPage'] / data['pages'],
                                      borderRadius: BorderRadius.circular(5),
                                      minHeight: 6,
                                    ),
                                    Align(
                                      alignment: Alignment.topRight,
                                      child: Text(
                                        (100 * data['currPage'] / data['pages'])
                                                .round()
                                                .toString() +
                                            '%'.toString(),
                                        style: GoogleFonts.ubuntu(
                                            fontSize: 10,
                                            color: Color(0xff909090)),
                                      ),
                                    ),
                                    TextButton(
                                        style: TextButton.styleFrom(
                                          minimumSize: Size.zero,
                                          padding: EdgeInsets.zero,
                                        ),
                                        onPressed: () {
                                          updateProgress(book, index);
                                        },
                                        child: Container(
                                          decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(5),
                                              border: Border.all(
                                                  color: Color(0xff4BB1A3),
                                                  width: 1)),
                                          child: Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Text(
                                              'Update Progress',
                                              style: GoogleFonts.ubuntu(
                                                color: Color(0xff4BB1A3),
                                                fontSize: 13,
                                              ),
                                            ),
                                          ),
                                        ))
                                  ],
                                );
                              } else {
                                return Text("Couldn't determine progress");
                              }
                            }),
                      ),
                    )
                  ],
                ),
              ),
            ),
          );
        });
  }

  // Pushes BookView page route and receives and sets updated data
  void navigateToBookView(
      BuildContext context, Book book, Color bgColor) async {
    final result = await Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => BookView(
          book: book,
          bgColor: bgColor,
          continueReading: widget.continueReading,
          recBooks: widget.recBooks,
          shelvedForLater: widget.shelvedForLater,
          completeShelf: widget.completeShelf,
          didNotCompleteShelf: widget.didNotCompleteShelf,
          totalCompleteShelf: widget.totalCompleteShelf,
          initialSearchGrid: widget.initialSearchGrid,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;

          var tween =
              Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);

          return SlideTransition(
            position: offsetAnimation,
            child: child,
          );
        },
      ),
    );

    if (result != null) {
      setState(() {
        widget.continueReading = result['continueReading'];
        widget.recBooks = result['recBooks'];
        widget.shelvedForLater = result['shelvedForLater'];
        widget.completeShelf = result['completeShelf'];
        widget.didNotCompleteShelf = result['didNotCompleteShelf'];
        widget.totalCompleteShelf = result['totalCompleteShelf'];
        widget.initialSearchGrid = result['initialSearchGrid'];
      });
    }
  }
}
