from flask import Flask, request, jsonify
import pandas as pd
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity
import re
import numpy as np
import ast
from scipy.sparse import coo_matrix
from sklearn.metrics.pairwise import cosine_similarity
import json

app = Flask(__name__)

books = pd.read_csv('api/books.csv', converters={"embedding": json.loads})
users = pd.read_csv('api/users.csv')

# Returns 1 + {highest user_id}
@app.route('/bookflix/get_next_user_id', methods = ['GET'])
def get_next_user_id():
    return str(users['user_id'].max() + 1)

# Adds new rating to users df
@app.route('/bookflix/add_user_rating', methods = ['POST'])
def add_user_rating():
    global users
    data = request.get_json()
    user_id = int(data.get('user_id'))
    book_id = int(data.get('book_id'))
    rating = int(data.get('rating'))

    new_book = pd.DataFrame([[user_id, book_id, rating]], columns=['user_id', 'book_id', 'rating'])
    users = pd.concat([users, new_book], ignore_index=True)
    
    users.to_csv('api/new_users.csv', index=False)

    return jsonify({'message': 'Book added successfully'}), 200

# Gets all books in the books df
@app.route('/bookflix/get_all_books', methods = ['GET'])
def get_all_books():
    return books.to_json(orient='records')

# Gets 20 random books in books df
@app.route('/bookflix',  methods = ['GET'])
def return_random_books():
    books_20 = books.sample(20)
    d = books_20.to_json(orient='records')
    return d

# Gets books similar to a certain book via cosine similarities
# of embeddings
@app.route('/bookflix/similar_books', methods = ['GET'])
def get_similar_books():
    df = books.copy()
    df['book_id'] = df['book_id'].astype(str)
    df = df.set_index('book_id')
    target_index = str(request.args['query'])
    target_embedding = np.array(df.loc[target_index, 'embedding'])
    embeddings = np.array(df['embedding'].tolist())
    cosine_similarities = cosine_similarity([target_embedding], embeddings)[0]
    df['cosine_similarity'] = cosine_similarities
    df_sorted = df.sort_values(by='cosine_similarity', ascending=False)
    df_sorted = df_sorted.reset_index()
    return df_sorted[1:6].to_json(orient='records')

# Returns json data for an individual book
@app.route('/bookflix/indiv_book', methods = ['GET'])
def return_indiv_book():
    book_id = str(request.args['query'])
    return books[books['book_id'].astype(str) == book_id].to_json(orient='records')

# Determines if a certain user_id exists in users_df
def my_user_id_exists(my_user_id):
    return len(users[users['user_id'] == my_user_id]) != 0

# Converts genre_weights represented as a string to a dictionary
def convert_string_to_map(map_str):
    map_str = map_str[1:-1]
    pairs = map_str.split(',')
    conv_map = {}
    for pair in pairs:
        key, value = pair.split(':')
        conv_map[key.replace('_', '')] = float(value.replace('_', ''))
    return conv_map

# Gets book recommendations based on previous user data via collaborative filtering
@app.route('/bookflix/home_books',  methods = ['GET'])
def return_home_books():
    my_user_id = int(request.args['query'])
    genre_weights = convert_string_to_map(request.args['genreWeights'])
    my_books = users[users['user_id'] == my_user_id]
    book_set = set(my_books['book_id'])

    if my_user_id_exists(my_user_id):
        overlap_users_df = users[(users['book_id'].isin(book_set)) & (users['user_id'] != my_user_id)]
        overlap_users = overlap_users_df['user_id'].value_counts().to_dict()

        filtered_overlap_users = set([k for k in overlap_users if overlap_users[k] > my_books.shape[0] / 5])

        filtered_overlap_users_df = users[users['user_id'].isin(filtered_overlap_users)]
        interactions_list = filtered_overlap_users_df.values.tolist()

        interactions = pd.DataFrame(interactions_list, columns=['user_id', 'book_id', 'rating'])
        interactions = pd.concat([my_books[['user_id', 'book_id', 'rating']], interactions])
        interactions['book_id'] = interactions['book_id'].astype(str)
        interactions['user_id'] = interactions['user_id'].astype(str)
        interactions['rating'] = pd.to_numeric(interactions['rating'])
        interactions['user_index'] = interactions['user_id'].astype('category').cat.codes
        interactions['book_index'] = interactions['book_id'].astype('category').cat.codes

        my_index = interactions[interactions['user_id'] == str(my_user_id)].iloc[0]['user_index']

        ratings_mat_coo = coo_matrix((interactions['rating'], (interactions['user_index'], interactions['book_index'])))
        ratings_mat = ratings_mat_coo.tocsr()

        similarity = cosine_similarity(ratings_mat[my_index,:], ratings_mat).flatten()
        k = min(30, len(similarity))
        indices = np.argpartition(similarity, -k)[-k:]
        similar_users = interactions[interactions['user_index'].isin(indices)].copy()
        similar_users = similar_users[similar_users['user_id'] != str(my_user_id)]
        book_recs = similar_users.groupby('book_id').rating.agg(['count', 'mean'])
        books['book_id'] = books['book_id'].astype(str)
        book_recs = book_recs.merge(books, how='inner', on='book_id')
        book_recs['adjusted_count'] = book_recs['count'] * (book_recs['count'] / book_recs['average_rating'])
        book_recs['score'] = book_recs['mean'] * book_recs['adjusted_count']
        my_books['book_id'] = my_books['book_id'].astype(str)
        book_recs = book_recs[~book_recs['book_id'].isin(my_books['book_id'])]
        book_recs['score'] = book_recs.apply(lambda row: row['score'] * genre_weights.get(row['main_genre'], 1), axis=1)
        top_recs = book_recs.sort_values('score', ascending=False)
        top_3_genres = list(top_recs.groupby('main_genre')['score'].mean().nlargest(3).index)
        top_recs = top_recs.fillna('')
    
    else:
        similar_users = users
        book_recs = similar_users.groupby('book_id').rating.agg(['count', 'mean'])
        book_recs = book_recs.merge(books, how='inner', on='book_id')
        book_recs['adjusted_count'] = book_recs['count'] * (book_recs['count'] / book_recs['average_rating'])
        book_recs['score'] = book_recs['mean'] * book_recs['adjusted_count']
        book_recs['score'] = book_recs.apply(lambda row: row['score'] * genre_weights.get(row['main_genre'], 1), axis=1)
        top_recs = book_recs.sort_values('score', ascending=False)
        top_3_genres = list(top_recs.groupby('main_genre')['score'].mean().nlargest(3).index)
        top_recs = top_recs.fillna('')

    first_genre = top_recs[top_recs['main_genre'] == top_3_genres[0]][0:40]
    second_genre = top_recs[top_recs['main_genre'] == top_3_genres[1]][0:40]
    third_genre = top_recs[top_recs['main_genre'] == top_3_genres[2]][0:40]
    new_books = top_recs.nlargest(40, 'publication_year')
    popular_books = top_recs.nlargest(40, 'ratings_count')
    most_liked = top_recs.nlargest(40, 'average_rating')
    series = top_recs[top_recs['series'].notna()][0:40]

    first_genre = first_genre.sample(n=min(20, len(first_genre)), replace=False)
    second_genre = second_genre.sample(n=min(20, len(second_genre)), replace=False)
    third_genre = third_genre.sample(n=min(20, len(third_genre)), replace=False)
    new_books = new_books.sample(n=min(20, len(new_books)), replace=False)
    popular_books = popular_books.sample(n=min(20, len(popular_books)), replace=False)
    most_liked = most_liked.sample(n=min(20, len(most_liked)), replace=False)
    series = series.sample(n=min(20, len(series)), replace=False)

    result = {
        "first_genre": {
            'title': top_3_genres[0][0].upper() + top_3_genres[0][1:],
            'books': first_genre.to_dict(orient='records')
        },
        "second_genre": {
            'title': top_3_genres[1][0].upper() + top_3_genres[1][1:],
            'books': second_genre.to_dict(orient='records')
        },
        "third_genre": {
            'title': top_3_genres[2][0].upper() + top_3_genres[2][1:],
            'books': third_genre.to_dict(orient='records')
        },
        "new_books": {
            'title': 'New Books on Bookflix',
            'books': new_books.to_dict(orient='records')
        },
        "popular_books": {
            'title': 'Popular Books on Bookflix',
            'books': popular_books.to_dict(orient='records')
        },
        "most_liked": {
            'title': 'Most Liked Books on Bookflix',
            'books': most_liked.to_dict(orient='records')
        },
        "series": {
            'title': 'Books Part of a Series',
            'books': series.to_dict(orient='records')
        }
    }

    return jsonify(result)

# Gets the first genre from a string of a list of genres
def get_main_genre(genre_string):
    try:
        genres = ast.literal_eval(genre_string)
        if isinstance(genres, list) and len(genres) > 0:
            return genres[0]
        else:
            return None
    except (ValueError, SyntaxError):
        return None

# Gets 24 random books from books df as the initial search books
@app.route('/bookflix/search/initial', methods=['GET'])
def get_initial_search():
    initial_search = books.sample(24)
    d = initial_search.to_json(orient='records')
    return d

# Retrieves books that have been filtered by genre
@app.route('/bookflix/search/genres', methods=['GET'])
def search_books_by_genre():
    mask_fantasy = create_genre_mask('fantasy', 'Fantasy')
    mask_romance = create_genre_mask('romance', 'Romance')
    mask_scifi = create_genre_mask('science-fiction', 'Sci-Fi')
    mask_youngadult = create_genre_mask('young-adult', 'Young-adult')
    mask_dystopian = create_genre_mask('dystopian', 'Dystopian')
    mask_adventure = create_genre_mask('adventure', 'Adventure')
    mask_biography = create_genre_mask('biography', 'Biography')
    mask_history = create_genre_mask('history', 'History')

    genre_books = books[mask_fantasy & mask_romance & mask_scifi & mask_youngadult & mask_dystopian & mask_adventure & mask_biography & mask_history]
    return genre_books.to_json(orient='records') if len(genre_books) <= 24 else genre_books.sample(24).to_json(orient='records')

# Creates a mask to only contain books who have genre equivalent to queryGenre
def create_genre_mask(containsGenre, queryGenre):
    genre = containsGenre if str(request.args[queryGenre]) == 'true' else ''
    return books['genres'].str.contains(genre, na=False)

# Uses TF-IDF to provide users with search results that best match their search query
@app.route('/bookflix/search', methods=['GET'])
def search_books():
    books['mod_title'] = books['mod_title'].fillna("")
    books['mod_author'] = books['mod_author'].fillna("")
    books['mod_series'] = books['mod_series'].fillna("")
    query = str(request.args['query'])
    processed = re.sub("[^a-zA-Z0-9 ]", "", query.lower())

    if len(query) < 5:
        starts_with_title = books[books['mod_title'].str.lower().str.startswith(processed, na=False)]
        contains_title = books[
            books['mod_title'].str.contains(processed, case=False, na=False) &
            ~books['mod_title'].str.lower().str.startswith(processed, na=False)
        ]

        starts_with_author = books[books['mod_author'].str.lower().str.startswith(processed, na=False)]
        contains_author = books[
            books['mod_author'].str.contains(processed, case=False, na=False) &
            ~books['mod_author'].str.lower().str.startswith(processed, na=False)
        ]

        starts_with_series = books[books['mod_series'].str.lower().str.startswith(processed, na=False)]
        contains_series = books[
            books['mod_series'].str.contains(processed, case=False, na=False) &
            ~books['mod_series'].str.lower().str.startswith(processed, na=False)
        ]

        top_results = pd.concat([
        starts_with_title,
        starts_with_author,
        starts_with_series,
        contains_title,
        contains_author,
        contains_series,
    ]).drop_duplicates().head(24)
    else:
        vectorizer_title = TfidfVectorizer()
        tfidf_title = vectorizer_title.fit_transform(books['mod_title'])
        query_vec_title = vectorizer_title.transform([processed])
        similarity_title = cosine_similarity(query_vec_title, tfidf_title).flatten()

        vectorizer_author = TfidfVectorizer()
        tfidf_author = vectorizer_author.fit_transform(books['mod_author'])
        query_vec_author = vectorizer_author.transform([processed])
        similarity_author = cosine_similarity(query_vec_author, tfidf_author).flatten()

        vectorizer_series = TfidfVectorizer()
        tfidf_series = vectorizer_series.fit_transform(books['mod_series'])
        query_vec_series = vectorizer_series.transform([processed])
        similarity_series = cosine_similarity(query_vec_series, tfidf_series).flatten()

        title_weight = 0.5
        author_weight = 0.5
        series_weight = 0.5

        combined_similarity = (title_weight * similarity_title) + (author_weight * similarity_author) + (series_weight * similarity_series)

        threshold = 0.25

        filtered_indices = np.where(combined_similarity >= threshold)[0]
        sorted_indices = filtered_indices[np.argsort(-combined_similarity[filtered_indices])]
        top_results = books.iloc[sorted_indices[:24]]


    d = top_results.to_json(orient='records')
    return d

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)