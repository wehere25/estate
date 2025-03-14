import 'package:flutter/material.dart';
import 'package:azharapp/features/home/presentation/screens/home_screen.dart';
import 'package:azharapp/features/search/presentation/screens/search_screen.dart';
import 'package:azharapp/features/favorites/presentation/screens/favorites_screen.dart';
import 'package:azharapp/features/profile/presentation/screens/profile_screen.dart';

class MainContainerScreen extends StatefulWidget {
  final int initialIndex;
  
  const MainContainerScreen({
    Key? key,
    this.initialIndex = 0,  // Add initialIndex parameter with default value
  }) : super(key: key);

  @override
  _MainContainerScreenState createState() => _MainContainerScreenState();
}

class _MainContainerScreenState extends State<MainContainerScreen> {
  late int _selectedIndex;
  
  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }
  
  // List of screens to show
  final List<Widget> _screens = [
    const HomeScreen(),
    const SearchScreen(),
    const FavoritesScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      // Ensure the HomeScreen itself doesn't have its own bottom navigation bar
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Favorites'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
