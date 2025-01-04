**Book Flix**

Book Flix is an app that provides book recommendations to users based on the previous reads and book ratings. This makes finding your next read quick and easy, as opposed to scrolling for hours on Goodreads.

**Code**

Book Flix uses Dart programming language and the Flutter framework as the frontend. Python (through integration with Flask)  was used as the backend. Firebase Firestore was the database used and Firebase Authentication was the authentication provider used for users to sign in or create an account. The following packages were used

**Dart Packages** 



* [http](https://pub.dev/packages/http): Used to make requests to the Flask API.
* [google_fonts](https://pub.dev/packages/google_fonts): Changes the default font family of the app to a Google Font.
* [palette_generator](https://pub.dev/packages/palette_generator): Extracts prominent colors from an image.
* [simple_shadow](https://pub.dev/packages/simple_shadow): Adds a shadow for any widget in Flutter.
* [firebase_auth](https://pub.dev/packages/firebase_auth): Authenticates user using email and password.
* [firebase_core](https://pub.dev/packages/firebase_core): Enables connecting to multiple Firebase apps.
* [cloud_firestore](https://pub.dev/packages/cloud_firestore): Allows for access to the Firestore database in order to access users and progress on their books
* [sliding_clipped_nav_bar](https://pub.dev/packages/sliding_clipped_nav_bar): Bottom navigation bar to switch between main screens
* [flutter_rating](https://pub.dev/packages/flutter_rating): Rating system for users to rate the books they have finished reading
* [flutter_launcher_icons](https://pub.dev/packages/flutter_launcher_icons): Sets app icon
* [share_plus](https://pub.dev/packages/share_plus): Shares content from app to other platforms
* [flutter_dotenv](https://pub.dev/packages/flutter_dotenv): Loads sensitive API keys and tokens at runtime from a .env file which can be used throughout the application.

**Python Libraries**



* [flask](https://flask.palletsprojects.com/en/stable/): Used to integrate Flutter with Python as the backend
* [pandas](https://pandas.pydata.org/): Enabled manipulation of the books and users dataframes
* [sklearn](https://scikit-learn.org/stable/): Used to compute TF-IDF and cosine similarity
* [regex](https://docs.python.org/3/library/re.html): Formed search pattern
* [numpy](https://numpy.org/): Used when handling matrices
* [ast](https://docs.python.org/3/library/ast.html): Converted a String version of a list to a list data type
* [scipy](https://scipy.org/): Constructed a sparse matrix
* [json](https://docs.python.org/3/library/json.html): Converts dataframe to json data

**Data**

A link to the data can be found here (they aren’t available in this repo because their file sizes were too large):  [https://www.kaggle.com/datasets/ishitamundra/bookflix-data/settings](https://www.kaggle.com/datasets/ishitamundra/bookflix-data/settings) 

The original source of the data can be found here: [https://mengtingwan.github.io/data/goodreads.html](https://mengtingwan.github.io/data/goodreads.html) 

The data was collected from goodreads.com in 2017 using the Good Reads API (now deprecated).

Two csv files were important to this project:



* users.csv: 
    * ‘user_id’: a unique id given to each user
    * ‘book_id’: a unique id given to each book corresponding to the book ids in books.csv
    * ‘rating’: the numerical rating that book received (from 1-5)
* books.csv:
    * ‘book_id’: a unique id given to each book corresponding to the book ids in users.csv
    * ‘title’: title of the book
    * ‘series’: name of the series book is a part of and a number indicating the position of the book in the series
    * ‘author’: main author of the book
    * ‘description’: short summary of the book
    * ‘genres’: a list of genres the book falls under
    * ‘publication_year’: year the book was published in
    * ‘average_rating': the average rating out of 5 in Good Reads
    * ‘ratings_count’: the number of ratings the book received in Good Reads
    * ‘image_url’: the url of the cover image of the book
    * ‘mod_title’: title stripped of unnecessary characters
    * ‘mod_author’: author stripped of unnecessary characters
    * ‘mod_series’: series name that book is a part stripped of unnecessary characters
    * ‘embedding’: Embeddings of the description column calculated by the Sentence2Vec algorithm to determine text similarity
    * ‘main_genre’: first genre in the list of genres book falls under

**Demo**

Video here

**Features**



* Book recommendation: Recommendations are determined using collaborative filtering, which uses data from the current user and all the other users. Users who have similar ratings to the current user are likely to have similar tastes in books. Thus, similar users are identified and books rated highly by these users are suggested to the current user. The current user’s genre preferences (which act as weights) are further used to provide recommendations (can be edited on the settings tab).
* Book progress tracker: Books that the user is currently reading, finished, did not finish, and is on a user’s list are tracked. The user has the ability to update their progress along the way.
* Filter/search for books: Users have the ability to search for books by name, series name, or author. They additionally can filter books by genre, offering them a wide selection of books to browse through.

**Support**

If any help is needed while navigating through the app, please contact: [ishita.mundra@gmail.com](mailto:ishita.mundra@gmail.com). 
