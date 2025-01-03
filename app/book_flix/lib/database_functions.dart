import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:book_flix/auth.dart';
import 'package:book_flix/book.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Functions related to editing Firebase Firestore database
class DatabaseFunctions {
  FirebaseFirestore db = FirebaseFirestore.instance;
  String userId = Auth().currentUser!.uid;
  Set<String> inProgressBooks = {};
  Set<String> shelvedForLater = {};
  Set<String> completedBooks = {};
  Set<String> didNotFinishBooks = {};
  int df_user_id = -2;
  String ipAddress = dotenv.env['IP_ADDRESS'] ?? '';

  // Performs a set of functions to retrieve data
  Future<void> initialize() async {
    await retrieveUserId();
    await retrieveInProgressBooks();
    await retrieveShelvedForLaterBooks();
    await retrieveCompletedBooks();
  }

  // Adds updated genre weights that user inputted
  Future<void> addGenreWeights(Map<String, double> genreWeights) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .set({'genreWeights': genreWeights}, SetOptions(merge: true));
  }

  // Determines if this is the first time the user has signed in
  Future<bool> doesUserIdExist() async {
    var snapshot = await db.collection('users').doc(userId).get();
    return snapshot.exists;
  }

  // For each new user, gets a user id that 1 + max user id
  Future<int> getNextUserId() async {
    final url =
        Uri.parse('http://' + ipAddress + ':5000/bookflix/get_next_user_id');
    final response = await http.get(url);
    return int.parse(response.body);
  }

  // Adds user id to firebase
  Future<void> addUserId(int next_user_id) async {
    await db.collection('users').doc(userId).set({'user_id': next_user_id});
  }

  // Gets the user id from firebase
  Future<void> retrieveUserId() async {
    var doc = await db.collection('users').doc(userId).get();
    if (doc.exists) {
      df_user_id = doc.data()!['user_id'];
    } else {
      df_user_id = -2;
    }
  }

  // Gets all books that user has completed
  Future<void> retrieveCompletedBooks() async {
    await db
        .collection('users')
        .doc(userId)
        .collection('completed')
        .get()
        .then((snapshot) {
      snapshot.docs.forEach((result) {
        if (result.data()['didComplete'] == 'Did Not Finish') {
          didNotFinishBooks.add(result.data()['bookId']);
        } else {
          completedBooks.add(result.data()['bookId']);
        }
      });
    });
  }

  // Adds book to completed collection in firebase
  Future<void> addBookToCompleted(
      Book book, int rating, String didComplete) async {
    await db
        .collection('users')
        .doc(userId)
        .collection('completed')
        .doc(book.bookId)
        .set({
      'bookId': book.bookId,
      'rating': rating,
      'didComplete': didComplete,
      'isFavorite': false,
    });
  }

  // Updates the current page number of a book that user is on
  Future<void> updatePageNumber(Book book, int pageNum) async {
    await db
        .collection('users')
        .doc(userId)
        .collection('in_progress')
        .doc(book.bookId)
        .update({'currPage': pageNum});
  }

  // Removes book from in progress collection
  Future<void> removeFromInProgressList(Book book) async {
    await db
        .collection('users')
        .doc(userId)
        .collection('in_progress')
        .doc(book.bookId)
        .delete();
  }

  // Sets isFavorite field in book document to true
  Future<void> addBookToIsFavoriteList(Book book) async {
    await db
        .collection('users')
        .doc(userId)
        .collection('completed')
        .doc(book.bookId)
        .update({'isFavorite': true});
  }

  // Sets isFavorite field in book document to false
  Future<void> removeBookFromIsFavoriteList(Book book) async {
    await db
        .collection('users')
        .doc(userId)
        .collection('completed')
        .doc(book.bookId)
        .update({'isFavorite': false});
  }

  // Adds book to in progress collection in firebase
  Future<void> addBookToInProgressList(Book book, int numPages) async {
    await db
        .collection('users')
        .doc(userId)
        .collection('in_progress')
        .doc(book.bookId)
        .set({'pages': numPages, 'currPage': 0, 'bookId': book.bookId});
    await removeFromShelvedForLater(book);
  }

  // Adds book to shelved for later collection in firebase
  Future<void> addToShelvedForLater(Book book) async {
    await db
        .collection('users')
        .doc(userId)
        .collection('shelved_for_later')
        .doc(book.bookId)
        .set({'bookId': book.bookId});
  }

  // Removes book from shelved for later collection in firebase
  Future<void> removeFromShelvedForLater(Book book) async {
    await db
        .collection('users')
        .doc(userId)
        .collection('shelved_for_later')
        .doc(book.bookId)
        .delete();
  }

  // Gets all books that have been shelved for later by the user
  Future<void> retrieveShelvedForLaterBooks() async {
    await db
        .collection('users')
        .doc(userId)
        .collection('shelved_for_later')
        .get()
        .then((snapshot) {
      snapshot.docs.forEach((result) {
        shelvedForLater.add(result.data()['bookId']);
      });
    });
  }

  // Gets all books that the user is currently reading
  Future<void> retrieveInProgressBooks() async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('in_progress')
        .get()
        .then((snapshot) {
      snapshot.docs.forEach((result) {
        inProgressBooks.add(result.data()['bookId']);
      });
    });
  }
}
