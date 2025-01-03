import 'package:book_flix/book.dart';
import 'package:book_flix/home.dart';
import 'package:book_flix/search.dart';
import 'package:book_flix/settings.dart';
import 'package:book_flix/shelf.dart';
import 'package:flutter/material.dart';
import 'package:sliding_clipped_nav_bar/sliding_clipped_nav_bar.dart';

// Represents the bottom tab bar to switch between pages
// ignore: must_be_immutable
class TabBarWidget extends StatefulWidget {
  TabBarWidget(
      {super.key,
      required this.continueReading,
      required this.recBooks,
      required this.shelvedForLater,
      required this.completeShelf,
      required this.didNotCompleteShelf,
      required this.totalCompleteShelf,
      required this.initialSearchGrid,
      required this.selectedIndex});

  List<Book> continueReading;
  Map<String, List<Book>> recBooks;
  List<Book> shelvedForLater;
  List<Book> completeShelf;
  List<Book> didNotCompleteShelf;
  List<Book> totalCompleteShelf;
  List<Book> initialSearchGrid;
  int selectedIndex;

  @override
  State<TabBarWidget> createState() => _TabBarWidgetState();
}

class _TabBarWidgetState extends State<TabBarWidget> {
  late PageController _pageController;
  int currIndex = 0;

  List<Widget> tabItems = [];

  @override
  void initState() {
    super.initState();
    currIndex = widget.selectedIndex;
    setTabs();
    _pageController = PageController(initialPage: currIndex);
  }

  // Initializes all the pages that users can navigate through using the tab
  // bar after all the data has been initialized
  void setTabs() {
    List<Book> finishedOrInProgressBooks = [];
    finishedOrInProgressBooks.addAll(widget.continueReading);
    finishedOrInProgressBooks.addAll(widget.totalCompleteShelf);
    setState(() {
      tabItems = [
        Home(
            continueReading: widget.continueReading,
            recBooks: widget.recBooks,
            shelvedForLater: widget.shelvedForLater,
            completeShelf: widget.completeShelf,
            didNotCompleteShelf: widget.didNotCompleteShelf,
            totalCompleteShelf: widget.totalCompleteShelf,
            initialSearchGrid: widget.initialSearchGrid),
        Shelf(
          continueReading: widget.continueReading,
          recBooks: widget.recBooks,
          shelvedForLater: widget.shelvedForLater,
          completeShelf: widget.completeShelf,
          didNotCompleteShelf: widget.didNotCompleteShelf,
          totalCompleteShelf: widget.totalCompleteShelf,
          initialSearchGrid: widget.initialSearchGrid,
        ),
        Search(
            continueReading: widget.continueReading,
            recBooks: widget.recBooks,
            shelvedForLater: widget.shelvedForLater,
            completeShelf: widget.completeShelf,
            didNotCompleteShelf: widget.didNotCompleteShelf,
            totalCompleteShelf: widget.totalCompleteShelf,
            initialSearchGrid: widget.initialSearchGrid),
        Settings(
          isGettingStarted: false,
        )
      ];
    });
  }

  // When a certain tab is clicked, the user will be taken to this
  // page and a transition will be applied
  void onButtonPressed(int index) {
    setState(() {
      currIndex = index;
    });
    _pageController.animateToPage(currIndex,
        duration: const Duration(milliseconds: 1000),
        curve: Curves.easeInToLinear);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: PageView(
        physics: NeverScrollableScrollPhysics(),
        controller: _pageController,
        children: tabItems,
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.only(bottom: 30),
        height: 90,
        child: SlidingClippedNavBar(
          barItems: [
            BarItem(title: 'Home', icon: Icons.home),
            BarItem(title: 'Shelf', icon: Icons.book),
            BarItem(title: 'Search', icon: Icons.search),
            BarItem(title: 'Settings', icon: Icons.settings)
          ],
          selectedIndex: currIndex,
          onButtonPressed: onButtonPressed,
          activeColor: Color(0xff4BB1A3),
          fontWeight: FontWeight.w500,
          fontSize: 15,
        ),
      ),
    );
  }
}
