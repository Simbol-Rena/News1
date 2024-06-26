import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:connectivity/connectivity.dart';
import 'package:carousel_slider/carousel_slider.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '25 News',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: LoadingScreen(),
    );
  }
}

class LoadingScreen extends StatefulWidget {
  @override
  _LoadingScreenState createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  @override
  void initState() {
    super.initState();
    startLoading();
  }

  void startLoading() {
    Timer(Duration(seconds: 5), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => NewsPage()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Image.network(
          'https://i.pinimg.com/originals/ee/2d/02/ee2d02c40139498879e0fd078f815dc8.gif',
          height: 200,
          width: 200,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

class NewsPage extends StatefulWidget {
  @override
  _NewsPageState createState() => _NewsPageState();
}

class _NewsPageState extends State<NewsPage> {
  List<dynamic> articles = [];
  List<dynamic> bookmarks = [];
  bool isLoading = false;
  String errorMessage = '';

  List<String> categories = [
    'general',
    'business',
    'entertainment',
    'health',
    'science',
    'sports',
    'technology'
  ];
  String selectedCategory = 'general';

  @override
  void initState() {
    super.initState();
    fetchNews();
    checkConnectivity();
    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      if (result == ConnectivityResult.none) {
        showNoConnectionDialog();
      } else {
        fetchNews(); // Fetch news if connection is regained
      }
    });
  }

  Future<void> checkConnectivity() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      showNoConnectionDialog();
    }
  }

  Future<void> showNoConnectionDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('No Connection Found'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Please check your internet connection and try again.'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> fetchNews() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    final apiKey = '6173ddd0c15d46aeaa6fe39785e6a0f1'; // Replace with your API key
    final apiUrl =
        'https://newsapi.org/v2/top-headlines?country=us&category=$selectedCategory&apiKey=$apiKey';

    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        setState(() {
          articles = json.decode(response.body)['articles'];
        });
      } else {
        setState(() {
          errorMessage = 'Failed to load news';
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to connect to the server';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void toggleBookmark(int index) {
    setState(() {
      final article = articles[index];
      final bool isBookmarked = bookmarks.contains(article);
      if (isBookmarked) {
        bookmarks.remove(article);
      } else {
        bookmarks.add(article);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                'MC News',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        onTap: (int index) {
          // Handle navigation
          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => BookmarkPage(bookmarks: bookmarks)),
            );
          }
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bookmark),
            label: 'Bookmark',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => fetchNews(),
        child: isLoading
            ? Center(child: CircularProgressIndicator())
            : errorMessage.isNotEmpty
            ? Center(child: Text(errorMessage))
            : SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildCategories(),
              _buildBreakingNews(),
              _buildRecommendations(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategories() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories
            .map(
              (category) => Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  selectedCategory = category;
                });
                fetchNews();
              },
              child: Text(category),
            ),
          ),
        )
            .toList(),
      ),
    );
  }

  Widget _buildBreakingNews() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            'Breaking News',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        CarouselSlider(
          options: CarouselOptions(
            height: 200.0,
            enableInfiniteScroll: true,
            enlargeCenterPage: true,
            viewportFraction: 0.9,
            autoPlay: true,
          ),
          items: articles.map((article) {
            return Builder(
              builder: (BuildContext context) {
                return GestureDetector(
                  onTap: () {
                    _showNewsDetails(article);
                  },
                  child: Card(
                    margin: EdgeInsets.symmetric(horizontal: 8.0),
                    elevation: 2.0,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: Stack(
                            alignment: Alignment.topRight,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  image: DecorationImage(
                                    image: NetworkImage(
                                      article['urlToImage'] ?? '',
                                    ),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  bookmarks.contains(article)
                                      ? Icons.bookmark
                                      : Icons.bookmark_border,
                                  color: bookmarks.contains(article)
                                      ? Colors.yellow
                                      : null,
                                ),
                                onPressed: () {
                                  toggleBookmark(articles.indexOf(article));
                                },
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            article['title'] ?? '',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text(
                            article['description'] ?? '',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildRecommendations() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            'Recommendations',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        for (var article in articles)
          GestureDetector(
            onTap: () {
              _showNewsDetails(article);
            },
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  if (article['urlToImage'] != null)
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: NetworkImage(article['urlToImage']),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'News: ${article['description']}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  void _showNewsDetails(dynamic article) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NewsDetailsPage(article: article),
      ),
    );
  }
}

class NewsDetailsPage extends StatelessWidget {
  final dynamic article;

  NewsDetailsPage({required this.article});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('News Details'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (article['urlToImage'] != null)
              Image.network(
                article['urlToImage'],
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                article['title'] ?? '',
                style: TextStyle(
                  fontSize: 20.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                article['description'] ?? '',
                style: TextStyle(fontSize: 16.0),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BookmarkPage extends StatelessWidget {
  final List<dynamic> bookmarks;

  BookmarkPage({required this.bookmarks});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bookmarks'),
      ),
      body: ListView.builder(
        itemCount: bookmarks.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(bookmarks[index]['title'] ?? ''),
            subtitle: Text(bookmarks[index]['description'] ?? ''),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      NewsDetailsPage(article: bookmarks[index]),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
