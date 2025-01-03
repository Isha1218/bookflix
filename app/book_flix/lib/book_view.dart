import 'dart:convert';
import 'package:book_flix/auth.dart';
import 'package:book_flix/book.dart';
import 'package:book_flix/database_functions.dart';
import 'package:book_flix/function.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:simple_shadow/simple_shadow.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:flutter_rating/flutter_rating.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Provides lots of information about each book
// ignore: must_be_immutable
class BookView extends StatefulWidget {
  BookView({
    super.key,
    required this.book,
    required this.bgColor,
    required this.continueReading,
    required this.recBooks,
    required this.shelvedForLater,
    required this.completeShelf,
    required this.didNotCompleteShelf,
    required this.totalCompleteShelf,
    required this.initialSearchGrid,
  });

  final Book book;
  final Color bgColor;
  List<Book> continueReading;
  Map<String, List<Book>> recBooks;
  List<Book> shelvedForLater;
  List<Book> completeShelf;
  List<Book> didNotCompleteShelf;
  List<Book> totalCompleteShelf;
  List<Book> initialSearchGrid;

  @override
  State<BookView> createState() => _BookViewState();
}

class _BookViewState extends State<BookView> {
  var similarBooks = [];
  TextEditingController pageNum = TextEditingController();
  DatabaseFunctions db = DatabaseFunctions();
  ValueNotifier<String> updateStringNotifier =
      ValueNotifier<String>('In Progress');
  ValueNotifier<double> ratingNotifier = ValueNotifier<double>(3);
  int starCount = 5;
  TextEditingController updatedPageNum = TextEditingController();
  String ipAddress = dotenv.env['IP_ADDRESS'] ?? '';
  static int df_user_id = -1;

  @override
  void initState() {
    super.initState();
    db.retrieveUserId();
    df_user_id = db.df_user_id;
    _loadSimilarBooks();
    List<String> splitUrl = widget.book.imageUrl.split('/');
    splitUrl[4] = splitUrl[4].substring(0, splitUrl[4].length - 1) + 'l';
    widget.book.imageUrl = splitUrl.join('/');
  }

  // Gets books similar to current book using cosine similarity
  // on pre-initialized embeddings
  Future<void> _loadSimilarBooks() async {
    var tempBooks = await fetchbooks('http://' +
        ipAddress +
        ':5000/bookflix/similar_books?query=' +
        widget.book.bookId);
    setState(() {
      similarBooks = tempBooks;
    });
  }

  // Pop-up that shows up when 'read now' button is clicked
  // Allows user to add number of pages of book to record
  // progress
  Future openDialog() {
    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            backgroundColor: Color.alphaBlend(
              widget.bgColor.withOpacity(0.5),
              Colors.white,
            ),
            title: Text(
              'How many pages are in your copy of this book?',
              style: GoogleFonts.ubuntu(
                fontSize: 15,
                color: widget.bgColor.withOpacity(0.5).computeLuminance() < 0.2
                    ? Colors.white
                    : Colors.black,
              ),
            ),
            content: TextField(
              style: GoogleFonts.ubuntu(
                color: widget.bgColor.withOpacity(0.5).computeLuminance() < 0.2
                    ? Colors.white
                    : Colors.black,
                fontSize: 14,
              ),
              cursorColor:
                  widget.bgColor.withOpacity(0.5).computeLuminance() < 0.2
                      ? Colors.white
                      : Colors.black,
              controller: pageNum,
              decoration: InputDecoration(
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(
                      color:
                          widget.bgColor.withOpacity(0.5).computeLuminance() <
                                  0.2
                              ? Colors.white
                              : Colors.black,
                      width: 1),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(
                      color:
                          widget.bgColor.withOpacity(0.5).computeLuminance() <
                                  0.2
                              ? Colors.white
                              : Colors.black,
                      width: 1),
                ),
                hintText: 'Enter the number of pages',
                hintStyle: GoogleFonts.ubuntu(
                  color:
                      widget.bgColor.withOpacity(0.5).computeLuminance() < 0.2
                          ? Colors.white
                          : Colors.black,
                  fontSize: 14,
                ),
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
                        color:
                            widget.bgColor.withOpacity(0.5).computeLuminance() <
                                    0.2
                                ? Colors.white
                                : Colors.black,
                        fontWeight: FontWeight.w500),
                  )),
              TextButton(
                  onPressed: () async {
                    // Adds book to 'in progress' list
                    // Removes book from 'home books'
                    // Removes book from 'shelved for later' list
                    setState(() {
                      widget.book.status = 'In Progress';
                    });
                    await DatabaseFunctions().addBookToInProgressList(
                        widget.book, int.parse(pageNum.text));
                    widget.recBooks.forEach((key, books) {
                      books.removeWhere(
                          (book) => book.bookId == widget.book.bookId);
                    });
                    widget.shelvedForLater.removeWhere(
                        (book) => book.bookId == widget.book.bookId);
                    widget.continueReading.add(widget.book);
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    'Submit',
                    style: GoogleFonts.ubuntu(
                        color:
                            widget.bgColor.withOpacity(0.5).computeLuminance() <
                                    0.2
                                ? Colors.white
                                : Colors.black,
                        fontWeight: FontWeight.w500),
                  ))
            ],
          );
        });
  }

  // Displays the 'Read Now' button
  Widget readNowWidget() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: TextButton(
              style: TextButton.styleFrom(
                minimumSize: Size.zero,
                padding: EdgeInsets.zero,
              ),
              onPressed: () {
                openDialog();
              },
              child: Container(
                width: double.infinity,
                height: 40,
                decoration: BoxDecoration(
                    color: Color(0xff4BB1A3),
                    borderRadius: BorderRadius.circular(10)),
                child: Center(
                  child: Text(
                    'Read Now',
                    style: GoogleFonts.ubuntu(
                        color: Colors.white, fontWeight: FontWeight.w500),
                  ),
                ),
              )),
        ),
        SizedBox(
          width: 20,
        ),
        IconButton(
            style: IconButton.styleFrom(
              minimumSize: Size.zero,
              padding: EdgeInsets.zero,
            ),
            onPressed: () {
              setState(() {
                // Removes book from 'shelved for later' list
                // if currently on shelf
                if (widget.book.isOnList) {
                  db.removeFromShelvedForLater(widget.book);
                  for (var entry in widget.recBooks.entries) {
                    for (var book in entry.value) {
                      if (widget.book.bookId == book.bookId) {
                        book.isOnList = false;
                      }
                    }
                  }
                  widget.book.isOnList = false;
                  widget.shelvedForLater.removeWhere(
                      (someBook) => someBook.bookId == widget.book.bookId);
                } else {
                  // Adds book to 'shelved for later' list if
                  // not currently on shelf
                  db.addToShelvedForLater(widget.book);
                  for (var entry in widget.recBooks.entries) {
                    for (var book in entry.value) {
                      if (widget.book.bookId == book.bookId) {
                        book.isOnList = true;
                      }
                    }
                  }
                  widget.book.isOnList = true;
                  widget.shelvedForLater.add(widget.book);
                }
              });
            },
            icon: widget.book.isOnList
                ? Icon(
                    Icons.bookmark,
                    color: Color(0xff4BB1A3),
                    size: 40,
                  )
                : Icon(
                    Icons.bookmark_border,
                    color: Color(0xff4BB1A3),
                    size: 40,
                  ))
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Scaffold(
        backgroundColor: widget.bgColor.withOpacity(0.5),
        body: SafeArea(
          bottom: false,
          child: Stack(
            children: [
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: () {
                            // Passes in updated data to previous page route
                            Navigator.of(context).pop({
                              'continueReading': widget.continueReading,
                              'recBooks': widget.recBooks,
                              'shelvedForLater': widget.shelvedForLater,
                              'completeShelf': widget.completeShelf,
                              'didNotCompleteShelf': widget.didNotCompleteShelf,
                              'totalCompleteShelf': widget.totalCompleteShelf,
                              'initialSearchGrid': widget.initialSearchGrid,
                            });
                          },
                          icon: Icon(
                            Icons.arrow_back,
                            color: widget.bgColor
                                        .withOpacity(0.5)
                                        .computeLuminance() <
                                    0.4
                                ? Colors.white
                                : Colors.black,
                          ),
                        ),
                        Text(
                          'Book Details',
                          style: GoogleFonts.agbalumo(
                            fontSize: 16,
                            color: widget.bgColor
                                        .withOpacity(0.5)
                                        .computeLuminance() <
                                    0.4
                                ? Colors.white
                                : Colors.black,
                          ),
                        ),
                        // Allows users to share current book through
                        // various apps and to various people
                        IconButton(
                          onPressed: () {
                            sharePressed();
                          },
                          icon: Icon(
                            Icons.share,
                            color: widget.bgColor
                                        .withOpacity(0.5)
                                        .computeLuminance() <
                                    0.4
                                ? Colors.white
                                : Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 15,
                  ),
                  SimpleShadow(
                    offset: Offset(0, 4),
                    color: Colors.black,
                    opacity: 0.25,
                    sigma: 20,
                    child: Container(
                      height: MediaQuery.of(context).size.height * 0.3,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          widget.book.imageUrl.replaceFirst('/m/', '/l/'),
                          fit: BoxFit.fitHeight,
                          filterQuality: FilterQuality.high,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              DraggableScrollableSheet(
                initialChildSize: 0.55,
                minChildSize: 0.55,
                maxChildSize: 0.95,
                builder: (context, scrollController) {
                  return Container(
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                        boxShadow: [
                          BoxShadow(
                            offset: Offset(0, -4),
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 50,
                          )
                        ]),
                    child: SingleChildScrollView(
                      controller: scrollController,
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  child: Text(
                                    widget.book.series == ''
                                        ? widget.book.title
                                        : widget.book.title +
                                            ' (' +
                                            widget.book.series +
                                            ')',
                                    style: GoogleFonts.prata(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                    ),
                                  ),
                                ),
                                // Dynamically updates screen with isFavorite field
                                widget.book.status == 'Complete'
                                    ? StreamBuilder(
                                        stream: FirebaseFirestore.instance
                                            .collection('users')
                                            .doc(Auth().currentUser!.uid)
                                            .collection('completed')
                                            .doc(widget.book.bookId)
                                            .snapshots(),
                                        builder: (context, snapshot) {
                                          if (snapshot.connectionState ==
                                              ConnectionState.waiting) {
                                            return Container();
                                          } else if (snapshot.hasError) {
                                            return Text("Couldn't find book");
                                          } else if (snapshot.hasData &&
                                              snapshot.data!.exists) {
                                            final data = snapshot.data;
                                            return TextButton(
                                                style: TextButton.styleFrom(
                                                  minimumSize: Size.zero,
                                                  padding: EdgeInsets.zero,
                                                ),
                                                onPressed: () async {
                                                  if (snapshot
                                                      .data!['isFavorite']) {
                                                    await DatabaseFunctions()
                                                        .removeBookFromIsFavoriteList(
                                                            widget.book);
                                                  } else {
                                                    await DatabaseFunctions()
                                                        .addBookToIsFavoriteList(
                                                            widget.book);
                                                  }
                                                },
                                                child: Icon(
                                                  data!['isFavorite']
                                                      ? Icons.favorite
                                                      : Icons.favorite_border,
                                                  size: 35,
                                                  color: Color(0xffD6046A),
                                                ));
                                          } else {
                                            return Text('');
                                          }
                                        },
                                      )
                                    : Container()
                              ],
                            ),
                            SizedBox(
                              height: 5,
                            ),
                            Text(
                              widget.book.author,
                              style: GoogleFonts.ubuntu(
                                color: Color(0xff909090),
                                fontSize: 15,
                              ),
                            ),
                            SizedBox(
                              height: 15,
                            ),
                            // Dyanamically updates status and progress of book
                            widget.book.status == 'Complete'
                                ? widget.book.shelfCompleteWidget()
                                : widget.book.status == 'In Progress'
                                    ? StreamBuilder(
                                        stream: FirebaseFirestore.instance
                                            .collection('users')
                                            .doc(Auth().currentUser!.uid)
                                            .collection('in_progress')
                                            .doc(widget.book.bookId)
                                            .snapshots(),
                                        builder: (context, snapshot) {
                                          if (snapshot.connectionState ==
                                              ConnectionState.waiting) {
                                            return Container();
                                          } else if (snapshot.hasError) {
                                            return Text(
                                                "Couldn't determine progress");
                                          } else if (snapshot.hasData &&
                                              snapshot.data!.exists) {
                                            final data = snapshot.data;
                                            return TextButton(
                                                style: TextButton.styleFrom(
                                                  minimumSize: Size.zero,
                                                  padding: EdgeInsets.zero,
                                                ),
                                                onPressed: () {
                                                  updateProgress(widget.book);
                                                },
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              5),
                                                      border: Border.all(
                                                          color:
                                                              Color(0xff4BB1A3),
                                                          width: 1)),
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            8.0),
                                                    child: Text(
                                                      'Update Progress (' +
                                                          (100 *
                                                                  data![
                                                                      'currPage'] /
                                                                  data['pages'])
                                                              .round()
                                                              .toString() +
                                                          '%'.toString() +
                                                          ')',
                                                      style: GoogleFonts.ubuntu(
                                                        color:
                                                            Color(0xff4BB1A3),
                                                        fontSize: 13,
                                                      ),
                                                    ),
                                                  ),
                                                ));
                                          } else {
                                            return Text('');
                                          }
                                        })
                                    : widget.book.status == 'Did Not Finish'
                                        ? widget.book
                                            .shelfDidNotCompleteWidget()
                                        : readNowWidget(),
                            SizedBox(
                              height: 20,
                            ),
                            Container(
                              decoration: BoxDecoration(
                                color: Color(0xffF7F7F7),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 16, horizontal: 24),
                                child: Container(
                                  height: 40,
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceAround,
                                    children: [
                                      Flexible(
                                          flex: 1,
                                          child: statWidget(
                                              'Rating',
                                              widget.book.averageRating
                                                  .toString())),
                                      VerticalDivider(
                                        color: Color(0xffC9C9C9),
                                        thickness: 1,
                                      ),
                                      Flexible(
                                          flex: 2,
                                          child: statWidget(
                                              'Genre',
                                              widget.book.genres[0]
                                                  .replaceFirst(
                                                      widget.book.genres[0][0],
                                                      widget.book.genres[0][0]
                                                          .toUpperCase()))),
                                      VerticalDivider(
                                        color: Color(0xffC9C9C9),
                                        thickness: 1,
                                      ),
                                      Flexible(
                                          flex: 1,
                                          child: statWidget(
                                              'Year',
                                              widget.book.publicationYear
                                                  .toString()))
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(
                              height: 20,
                            ),
                            Text(
                              widget.book.description.replaceAll('\n', '\n\n'),
                              style: GoogleFonts.ubuntu(
                                fontSize: 13,
                              ),
                            ),
                            SizedBox(
                              height: 30,
                            ),
                            Text(
                              'More Books Like This...',
                              style: GoogleFonts.ubuntu(
                                color: Color(0xff4BB1A3),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(
                              height: 15,
                            ),
                            similarBooks.length == 0
                                ? CircularProgressIndicator()
                                : Container(
                                    height: 220,
                                    child: ListView.builder(
                                      shrinkWrap: true,
                                      clipBehavior: Clip.none,
                                      scrollDirection: Axis.horizontal,
                                      itemCount: 5,
                                      itemBuilder: (context, count) {
                                        return bookCardWidget(
                                            similarBooks[count]);
                                      },
                                    ),
                                  ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Allows user to update progress of book through pop up dialog
  Future updateProgress(Book book) {
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
                                    controller: updatedPageNum,
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
                                      book, updateString, rating);
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

  // Multiple choice menu selection askig the user their current status of the book
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

  // Performs process of sharing book
  void sharePressed() {
    String message = 'Check out this book: ' +
        widget.book.title +
        ' by ' +
        widget.book.author;
    Share.share(message);
  }

  // If book has been completed or was not finished,
  // the book is added to users_df to provide more
  // accurate book recommendations
  Future<void> addBookToDf() async {
    await compute(addBookToDfCompute, {
      'ipAddress': ipAddress,
      'bookId': widget.book.bookId,
      'rating': ratingNotifier.value.toInt(),
    });
    return;
  }

  // Performs flask process of adding book to users_df
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

  // Performs various processes depending on user progress of book
  Future<void> _submitUpdate(
      Book book, String updateString, double rating) async {
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
        widget.continueReading
            .removeWhere((book) => book.bookId == widget.book.bookId);
        widget.completeShelf.add(book);
        widget.totalCompleteShelf.add(book);
      });
      addBookToDf();
      // If user is still reading the books, then the current page
      // number that user is on is updated in Firebase.
    } else if (updateString == 'In Progress') {
      book.status = 'In Progress';
      await DatabaseFunctions()
          .updatePageNumber(book, int.parse(updatedPageNum.text));
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
        widget.continueReading
            .removeWhere((book) => book.bookId == widget.book.bookId);
        widget.didNotCompleteShelf.add(book);
        widget.totalCompleteShelf.add(book);
      });
      addBookToDf();
    }
  }

  // Determines the background color, based on the primary, secondary,
  // or tertiary color found in the book image. The color shouldn't
  // be too dark and it shouldn't be too light.
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

  // A miniature version of this widget, containg essential info,
  // like image, rating, title, and author
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
            Navigator.of(context).push(MaterialPageRoute(builder: (context) {
              return BookView(
                book: book,
                bgColor: backgroundColor!,
                continueReading: widget.continueReading,
                recBooks: widget.recBooks,
                shelvedForLater: widget.shelvedForLater,
                completeShelf: widget.completeShelf,
                didNotCompleteShelf: widget.didNotCompleteShelf,
                totalCompleteShelf: widget.totalCompleteShelf,
                initialSearchGrid: widget.initialSearchGrid,
              );
            }));
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

  // Text that represents stats about the book, including
  // publication year, rating, and genre.
  Widget statWidget(String stat, String val) {
    return Column(
      children: [
        Text(
          stat,
          style: GoogleFonts.ubuntu(color: Color(0xff909090), fontSize: 12),
        ),
        Text(
          val,
          style: GoogleFonts.ubuntu(fontWeight: FontWeight.bold, fontSize: 14),
        )
      ],
    );
  }
}
