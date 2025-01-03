import 'package:book_flix/auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Represents a book object
class Book {
  final String bookId;
  final String title;
  final String series;
  final String author;
  final String description;
  final List<String> genres;
  final int publicationYear;
  final double averageRating;
  final int ratingsCount;
  String imageUrl;
  String status;
  bool isOnList;

  Book({
    required this.bookId,
    required this.title,
    required this.series,
    required this.author,
    required this.description,
    required this.genres,
    required this.publicationYear,
    required this.averageRating,
    required this.ratingsCount,
    required this.imageUrl,
    required this.status,
    required this.isOnList,
  });

  TextEditingController pageNum = TextEditingController();
  final ValueNotifier<String> updateStringNotifier =
      ValueNotifier<String>('In Progress');
  final ValueNotifier<double> ratingNotifier = ValueNotifier<double>(3);
  int starCount = 5;

  // Converts json to a Book object
  factory Book.fromJson(
      Map<String, dynamic> json, String status, bool isOnList) {
    return Book(
        bookId: json['book_id'].toString(),
        title: json['title'] ?? 'Untitled',
        series: json['series'] ?? '',
        author: json['author'] ?? '',
        description: json['description'] ?? '',
        genres: _parseGenres(json['genres']),
        publicationYear: json['publication_year'] ?? 0,
        averageRating: json['average_rating'].toDouble() ?? 0,
        ratingsCount: json['ratings_count'] ?? 0,
        imageUrl: json['image_url'] ?? '',
        status: status,
        isOnList: isOnList);
  }

  // Converts string of genres to a list of genres
  static List<String> _parseGenres(String genresString) {
    return genresString
        .replaceAll(RegExp(r"[\[\]']"), '')
        .split(',')
        .map((genre) => genre.trim())
        .toList();
  }

  // Widget representing in progress text.
  // Uses a stream builder to dynamically update progress.
  Widget shelfInProgressWidget() {
    return Row(
      children: [
        StreamBuilder(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(Auth().currentUser!.uid)
                .collection('in_progress')
                .doc(bookId)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Container();
              } else if (snapshot.hasError) {
                return Text("Couldn't determine progress");
              } else if (snapshot.hasData && snapshot.data!.exists) {
                final data = snapshot.data!.data();
                return Text(
                  'Book In Progress (' +
                      (100 * data!['currPage'] / data['pages'])
                          .round()
                          .toString() +
                      '%)'.toString(),
                  style: GoogleFonts.ubuntu(
                      fontSize: 13,
                      color: Color(0xff4BB1A3),
                      fontWeight: FontWeight.w500),
                );
              } else {
                return Text("Couldn't determine progress");
              }
            }),
        SizedBox(
          width: 5,
        ),
        Icon(
          Icons.hourglass_bottom,
          color: Color(0xff4BB1A3),
          size: 18,
        ),
      ],
    );
  }

  // Widget representing book complete text
  Widget shelfCompleteWidget() {
    return Row(
      children: [
        Text(
          'Book Complete',
          style: GoogleFonts.ubuntu(
              fontSize: 13,
              color: Color(0xff7000F9),
              fontWeight: FontWeight.w500),
        ),
        SizedBox(
          width: 5,
        ),
        Icon(
          Icons.verified,
          color: Color(0xff7000F9),
          size: 18,
        ),
      ],
    );
  }

  // Widget representing did not finish book text
  Widget shelfDidNotCompleteWidget() {
    return Row(
      children: [
        Text(
          'Did Not Finish',
          style: GoogleFonts.ubuntu(
              fontSize: 13,
              color: Color(0xffE65E11),
              fontWeight: FontWeight.w500),
        ),
        SizedBox(
          width: 5,
        ),
        CircleAvatar(
          radius: 8,
          backgroundColor: Color(0xffE65E11),
          child: Center(
              child: Icon(
            Icons.close,
            color: Colors.white,
            size: 16,
          )),
        ),
      ],
    );
  }
}
