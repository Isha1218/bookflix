import 'package:book_flix/auth.dart';
import 'package:book_flix/book.dart';
import 'package:book_flix/book_view.dart';
import 'package:book_flix/database_functions.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:simple_shadow/simple_shadow.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// This widget represents the user's shelf, including
// what the user has on their list, currently reading,
// and already finished/did not finish
// ignore: must_be_immutable
class Shelf extends StatefulWidget {
  Shelf(
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
  State<Shelf> createState() => _ShelfState();
}

class _ShelfState extends State<Shelf> {
  List<Book> finishedOrInProgressBooks = [];

  @override
  void initState() {
    super.initState();
    finishedOrInProgressBooks.addAll(widget.continueReading);
    finishedOrInProgressBooks.addAll(widget.totalCompleteShelf);
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
                        child: widget.shelvedForLater.length == 0 &&
                                finishedOrInProgressBooks.length == 0
                            ? Text('You don\'t have any books in your shelf')
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                    titleWidget("My", 'Shelf'),
                                    widget.shelvedForLater.length == 0
                                        ? Container()
                                        : SizedBox(
                                            height: 25,
                                          ),
                                    widget.shelvedForLater.length == 0
                                        ? Container()
                                        : recRowWidget(widget.shelvedForLater,
                                            'Shelved for later'),
                                    finishedOrInProgressBooks.length == 0
                                        ? Container()
                                        : SizedBox(
                                            height: 25,
                                          ),
                                    finishedOrInProgressBooks.length == 0
                                        ? Container()
                                        : Text(
                                            'Finished/In Progress Shelf',
                                            style: GoogleFonts.ubuntu(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w500),
                                          ),
                                    SizedBox(
                                      height: 10,
                                    ),
                                    SingleChildScrollView(
                                      child: ListView.builder(
                                        physics: ScrollPhysics(),
                                        shrinkWrap: true,
                                        clipBehavior: Clip.none,
                                        itemCount:
                                            finishedOrInProgressBooks.length,
                                        itemBuilder: (context, count) {
                                          return shelfWidget(
                                              finishedOrInProgressBooks[count]);
                                        },
                                      ),
                                    )
                                  ]))))));
  }

  // A vertical list of books the user is currently reading, has completed, or did not finish
  Widget shelfWidget(Book book) {
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
            margin: EdgeInsets.only(bottom: 20),
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                    offset: Offset(0, 4),
                    blurRadius: 20,
                    color: Colors.black.withOpacity(0.15))
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 90,
                  decoration: BoxDecoration(
                      color: backgroundColor == null
                          ? Colors.white
                          : backgroundColor.withOpacity(0.5),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(10),
                        bottomLeft: Radius.circular(10),
                      )),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
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
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                book.title,
                                style: GoogleFonts.prata(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Colors.black,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                book.author +
                                    '  •  ' +
                                    book.genres[0].replaceFirst(
                                        book.genres[0][0],
                                        book.genres[0][0].toUpperCase()),
                                style: GoogleFonts.ubuntu(
                                  color: Color(0xff909090),
                                  fontSize: 13,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(
                                height: 5,
                              ),
                              book.status == 'Complete'
                                  ? book.shelfCompleteWidget()
                                  : book.status == "In Progress"
                                      ? book.shelfInProgressWidget()
                                      : book.shelfDidNotCompleteWidget(),
                              SizedBox(
                                height: 5,
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 5, vertical: 3),
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
                        ),
                        book.status == "Complete"
                            ? StreamBuilder(
                                stream: FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(Auth().currentUser!.uid)
                                    .collection('completed')
                                    .doc(book.bookId)
                                    .snapshots(),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return Container();
                                  } else if (snapshot.hasError) {
                                    return Container();
                                  } else if (snapshot.hasData &&
                                      snapshot.data!.exists) {
                                    final data = snapshot.data!.data();
                                    return TextButton(
                                        onPressed: () async {
                                          if (snapshot.data!['isFavorite']) {
                                            await DatabaseFunctions()
                                                .removeBookFromIsFavoriteList(
                                                    book);
                                          } else {
                                            await DatabaseFunctions()
                                                .addBookToIsFavoriteList(book);
                                          }
                                        },
                                        child: Icon(
                                          data!['isFavorite']
                                              ? Icons.favorite
                                              : Icons.favorite_border,
                                          size: 24,
                                          color: Color(0xffD6046A),
                                        ));
                                  } else {
                                    return Container();
                                  }
                                })
                            : Container()
                      ],
                    ),
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  // A row of all books that the user has on their list
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

  // Determines background color for the book card widget and shelf widget
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

  // Miniature representation of Book object, containing info on
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

  // Represents the title at the top of the screen
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
      List<Book> finishedOrInProgressBooksTemp = [];
      finishedOrInProgressBooksTemp.addAll(result['continueReading']);
      finishedOrInProgressBooksTemp.addAll(result['totalCompleteShelf']);
      setState(() {
        widget.continueReading = result['continueReading'];
        widget.recBooks = result['recBooks'];
        widget.shelvedForLater = result['shelvedForLater'];
        widget.completeShelf = result['completeShelf'];
        widget.didNotCompleteShelf = result['didNotCompleteShelf'];
        widget.totalCompleteShelf = result['totalCompleteShelf'];
        widget.initialSearchGrid = result['initialSearchGrid'];
        finishedOrInProgressBooks = finishedOrInProgressBooksTemp;
      });
    }
  }
}
