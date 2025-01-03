import 'package:book_flix/book.dart';
import 'package:book_flix/book_view.dart';
import 'package:book_flix/function.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:simple_shadow/simple_shadow.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// This widget represents the search library page, where the
// user has the ability to search for books by title, author,
// or series. Or the user can filter books by genre
// ignore: must_be_immutable
class Search extends StatefulWidget {
  Search(
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
  State<Search> createState() => _SearchState();
}

class _SearchState extends State<Search> {
  var searchBooks = null;
  TextEditingController controller = TextEditingController();
  String url = '';
  Map<String, bool> genres = {
    'Fantasy': false,
    'Romance': false,
    'Sci-Fi': false,
    'Young-adult': false,
    'Dystopian': false,
    'Adventure': false,
    'Biography': false,
    'History': false,
  };
  String ipAddress = dotenv.env['IP_ADDRESS'] ?? '';

  @override
  void initState() {
    super.initState();
    addBookData(widget.initialSearchGrid);
  }

  // Adds the status of each book object here
  void addBookData(List<Book> books) {
    for (Book book in books) {
      if (bookExists(widget.shelvedForLater, book.bookId)) {
        book.isOnList = true;
      } else if (bookExists(widget.continueReading, book.bookId)) {
        book.status = 'In Progress';
      } else if (bookExists(widget.completeShelf, book.bookId)) {
        book.status = 'Complete';
      } else if (bookExists(widget.didNotCompleteShelf, book.bookId)) {
        book.status = 'Did Not Finish';
      }
    }
  }

  // Determines if a certain book exists in a list of books
  bool bookExists(List<Book> books, String targetBookId) {
    return books.any((book) => book.bookId == targetBookId);
  }

  // Gets books that have been filtered by genre
  Future<void> _loadGenreBooks() async {
    if (isMapFalse()) {
      setState(() {
        searchBooks = null;
      });
    } else {
      var tempBooks = await fetchbooks(mapToString());
      setState(() {
        searchBooks = tempBooks;
        addBookData(searchBooks);
      });
    }
  }

  // Converts a map with a key of genre and boolean of
  // whether that genre has been selected to be filtered by
  // to a string
  String mapToString() {
    String url = 'http://' + ipAddress + ':5000/bookflix/search/genres?';
    for (var entry in genres.entries) {
      url += entry.key + "=" + entry.value.toString() + "&";
    }
    return url;
  }

  // Determines if every value in the genres map is false
  bool isMapFalse() {
    for (bool val in genres.values) {
      if (val) {
        return false;
      }
    }
    return true;
  }

  // Gets books based on user's search query
  Future<void> _loadSearchBooks() async {
    if (url == '' ||
        url == 'http://' + ipAddress + ':5000/bookflix/search?query=') {
      setState(() {
        searchBooks = null;
      });
    } else {
      var tempBooks = await fetchbooks(url);
      setState(() {
        searchBooks = tempBooks;
        addBookData(searchBooks);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  titleWidget('Search', 'Library'),
                  SizedBox(
                    height: 20,
                  ),
                  searchWidget(),
                  SizedBox(
                    height: 15,
                  ),
                  Container(
                    height: 38,
                    clipBehavior: Clip.none,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: genres.length,
                      itemBuilder: (context, index) {
                        return genreItem(genres.keys.elementAt(index),
                            genres.values.elementAt(index), index);
                      },
                    ),
                  ),
                  SizedBox(
                    height: 20,
                  ),
                  searchBooks != null && widget.initialSearchGrid.length == 0
                      ? CircularProgressIndicator()
                      : GridView.builder(
                          physics: NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            childAspectRatio: 0.62,
                          ),
                          itemBuilder: (_, index) {
                            return searchBooks == null
                                ? bookCardGridWidget(
                                    widget.initialSearchGrid[index])
                                : bookCardGridWidget(searchBooks[index]);
                          },
                          itemCount: searchBooks == null
                              ? widget.initialSearchGrid.length
                              : searchBooks.length,
                        ),
                ],
              ),
            ),
          ),
        ));
  }

  // Represents each genre filter
  Widget genreItem(String genre, bool isClicked, int index) {
    return TextButton(
      style: TextButton.styleFrom(
        minimumSize: Size.zero,
        padding: EdgeInsets.zero,
      ),
      onPressed: () async {
        setState(() {
          genres[genre] = !genres.values.elementAt(index);
          controller.text = '';
        });
        await _loadGenreBooks();
      },
      child: Container(
        margin: EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
            color: isClicked ? Color(0xff4BB1A3) : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: isClicked
                ? Border.all(color: Color(0xff4BB1A3), width: 1)
                : Border.all(color: Color(0xff909090), width: 1)),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Center(
            child: Text(
              genre,
              style: GoogleFonts.ubuntu(
                  color: isClicked ? Colors.white : Color(0xff909090)),
            ),
          ),
        ),
      ),
    );
  }

  // Sets all values in the genres map to false
  resetMap() {
    setState(() {
      for (var key in genres.keys) {
        genres[key] = false;
      }
    });
  }

  // Widget representing the search bar that user can
  // input their search query into
  Widget searchWidget() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Color(0xffF8F8F8),
        borderRadius: BorderRadius.circular(20),
      ),
      child: TextField(
        textInputAction: TextInputAction.done,
        autocorrect: false,
        controller: controller,
        onEditingComplete: () async {
          url = 'http://' +
              ipAddress +
              ':5000/bookflix/search?query=' +
              controller.text.toString();
          await _loadSearchBooks();
        },
        onSubmitted: (value) {
          FocusScope.of(context).unfocus();
        },
        onTap: () {
          resetMap();
          setState(() {
            searchBooks = null;
          });
        },
        onChanged: (value) {
          if (value == '') {
            setState(() {
              searchBooks = null;
            });
          }
        },
        style: GoogleFonts.ubuntu(
          color: Colors.black,
          fontSize: 14,
        ),
        textAlignVertical: TextAlignVertical.center,
        decoration: InputDecoration(
          contentPadding: EdgeInsets.zero,
          border: InputBorder.none,
          prefixIcon: Icon(Icons.search),
          hintText: 'Search for books by title, author, or series',
          hintStyle: GoogleFonts.ubuntu(
            color: Colors.black,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  // Determines the background color for the book card grid widget
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

  // A miniature representation of info from the Book object,
  // including info on book image, title, author, and rating
  Widget bookCardGridWidget(Book book) {
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
            height: 165,
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
                  height: 105,
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
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.black),
                      ),
                      Text(
                        book.author,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.ubuntu(
                          color: Color(0xff909090),
                          fontSize: 10,
                        ),
                      ),
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

  // Representts the title at the top of the screen
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
          const begin = Offset(1.0, 0.0); // Slide in from the right
          const end = Offset.zero; // End at default position
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
