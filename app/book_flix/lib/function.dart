import 'dart:convert';

import 'package:book_flix/book.dart';
import 'package:http/http.dart' as http;

// Retrieves json data from http request
fetchdata(String url) async {
  http.Response response = await http.get(Uri.parse(url));
  return json.decode(response.body);
}

// Converts json data to a Book object from http request
fetchbooks(String url) async {
  http.Response response = await http.get(Uri.parse(url));
  if (response.statusCode == 200) {
    List<dynamic> data = jsonDecode(response.body);
    return data
        .map((json) => Book.fromJson(
              json,
              'Did Not Read',
              false,
            ))
        .toList();
  } else {
    throw Exception('Failed to load books');
  }
}
