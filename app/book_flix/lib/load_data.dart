import 'dart:math';
import 'package:book_flix/auth.dart';
import 'package:flutter/material.dart';
import 'package:book_flix/book.dart';
import 'package:book_flix/database_functions.dart';
import 'package:book_flix/function.dart';
import 'package:book_flix/tab_bar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// This class loads all the data before passing it
// on to the tab bars for display
class LoadData extends StatefulWidget {
  const LoadData({super.key});

  @override
  State<LoadData> createState() => _LoadDataState();
}

class _LoadDataState extends State<LoadData> {
  DatabaseFunctions db = DatabaseFunctions();

  List<Book> continueReading = [];
  Map<String, List<Book>> recBooks = {};
  List<Book> shelvedForLater = [];
  List<Book> completeShelf = [];
  List<Book> didNotCompleteShelf = [];
  List<Book> initialSearchGrid = [];
  bool isLoading = true;
  Map<String, double> genreWeights = {};
  String ipAddress = dotenv.env['IP_ADDRESS'] ?? '';

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  // Gets the user's initialized genre weights from firebase
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

  // Loads all necessary data in this method
  Future<void> _initializeData() async {
    await db.initialize();
    await retrieveGenreWeights();
    await _loadBooks();
    setState(() {
      isLoading = false;
    });
  }

  // Loads all data regarding books in this method
  Future<void> _loadBooks() async {
    await _loadShelvedForLater();
    await _loadContinueReadingBooks();
    await _loadHomeBooks();
    removeBooksFromRecBooks();
    await _loadCompleteShelf();
    await _loadDidNotFinishShelf();
    await _loadInitialSearchGrid();
  }

  // Removes books that are currently being read in
  // book recommendation
  void removeBooksFromRecBooks() {
    final continueReadingIds =
        continueReading.map((book) => book.bookId).toSet();

    recBooks.forEach((key, books) {
      books.removeWhere((book) => continueReadingIds.contains(book.bookId));
    });
  }

  // Gets pre-loaded books that will show up when the user
  // hasn't searched up for a book yet
  Future<void> _loadInitialSearchGrid() async {
    var tempBooks = await fetchbooks(
        'http://' + ipAddress + ':5000/bookflix/search/initial');
    initialSearchGrid = tempBooks;
  }

  // Gets all books that have been shelved for later
  Future<void> _loadShelvedForLater() async {
    for (String bookId in db.shelvedForLater) {
      var data = await fetchdata(
          'http://' + ipAddress + ':5000/bookflix/indiv_book?query=' + bookId);
      Book book = (data as List)
          .map((json) => Book.fromJson(
                json as Map<String, dynamic>,
                'Did Not Read',
                true,
              ))
          .toList()[0];
      shelvedForLater.add(book);
    }
  }

  // Gets all books that have been completed by the user
  Future<void> _loadCompleteShelf() async {
    for (String bookId in db.completedBooks) {
      var data = await fetchdata(
          'http://' + ipAddress + ':5000/bookflix/indiv_book?query=' + bookId);
      Book book = (data as List)
          .map((json) =>
              Book.fromJson(json as Map<String, dynamic>, 'Complete', false))
          .toList()[0];
      completeShelf.add(book);
    }
  }

  // Gets all books that were not finished by the user
  Future<void> _loadDidNotFinishShelf() async {
    for (String bookId in db.didNotFinishBooks) {
      var data = await fetchdata(
          'http://' + ipAddress + ':5000/bookflix/indiv_book?query=' + bookId);
      Book book = (data as List)
          .map((json) => Book.fromJson(
                json as Map<String, dynamic>,
                'Did Not Finish',
                false,
              ))
          .toList()[0];
      didNotCompleteShelf.add(book);
    }
  }

  // Gets all book recommendations to show in the home page
  Future<void> _loadHomeBooks() async {
    var data = await fetchdata('http://' +
        ipAddress +
        ':5000/bookflix/home_books?query=' +
        db.df_user_id.toString() +
        '&genreWeights=' +
        genreWeights.toString().replaceAll(' ', '_'));
    print('http://' +
        ipAddress +
        ':5000/bookflix/home_books?query=' +
        db.df_user_id.toString() +
        '&genreWeights=' +
        genreWeights.toString().replaceAll(' ', '_'));

    recBooks = {
      getTitle('first_genre', data): await generateBooks('first_genre', data),
      getTitle('second_genre', data): await generateBooks('second_genre', data),
      getTitle('third_genre', data): await generateBooks('third_genre', data),
      getTitle('new_books', data): await generateBooks('new_books', data),
      getTitle('popular_books', data):
          await generateBooks('popular_books', data),
      getTitle('most_liked', data): await generateBooks('most_liked', data),
      getTitle('series', data): await generateBooks('series', data),
    };

    shuffleMap(recBooks);
  }

  // Randomly organizes the category of recommendation of books to show
  void shuffleMap(Map<String, List<Book>> recBooks) {
    final random = Random();
    final shuffledEntries = recBooks.entries.toList()..shuffle(random);
    recBooks
      ..clear()
      ..addEntries(shuffledEntries);
  }

  // Converts json data to a Book object
  Future<List<Book>> generateBooks(String fieldName, var data) async {
    List<Book> books = (data[fieldName]['books'] as List)
        .map((json) => Book.fromJson(
              json as Map<String, dynamic>,
              'Did Not Read',
              false,
            ))
        .toList();

    for (int i = 0; i < books.length; i++) {
      if (db.shelvedForLater.contains(books[i].bookId)) {
        books[i].isOnList = true;
      }
    }
    return books;
  }

  // Loads books that the user is currently reading
  Future<void> _loadContinueReadingBooks() async {
    for (String bookId in db.inProgressBooks) {
      var data = await fetchdata(
          'http://' + ipAddress + ':5000/bookflix/indiv_book?query=' + bookId);
      Book book = (data as List)
          .map((json) =>
              Book.fromJson(json as Map<String, dynamic>, 'In Progress', false))
          .toList()[0];
      continueReading.add(book);
    }
  }

  // Gets the title of the recommendation category from json data
  String getTitle(String fieldName, var data) {
    return data[fieldName]['title'];
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 50, vertical: 100),
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

    return TabBarWidget(
      continueReading: continueReading,
      recBooks: recBooks,
      shelvedForLater: shelvedForLater,
      completeShelf: completeShelf,
      didNotCompleteShelf: didNotCompleteShelf,
      totalCompleteShelf: [...completeShelf, ...didNotCompleteShelf],
      initialSearchGrid: initialSearchGrid,
      selectedIndex: 0,
    );
  }
}
