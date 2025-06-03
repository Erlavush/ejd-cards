import 'package:flutter/material.dart';
import 'package:ejd_cards/features/deck_list/screens/deck_list_screen.dart';
// We will create our actual screens and navigation soon.
// For now, we'll use a placeholder.

void main() {
  // We might add more initialization logic here later (e.g., for services).
  runApp(const EjdCardsApp()); // Changed class name
}

class EjdCardsApp extends StatelessWidget { // Changed class name
  const EjdCardsApp({super.key}); // Changed class name

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EJD Cards', // Changed app title
      debugShowCheckedModeBanner: false, // Removes the debug banner
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent), // Changed seed color
        visualDensity: VisualDensity.adaptivePlatformDensity,
        appBarTheme: const AppBarTheme(
          elevation: 0,
        ),
      ),
      home: const DeckListScreen(),
    );
  }
}

// Temporary placeholder screen
class PlaceholderHomeScreen extends StatelessWidget {
  const PlaceholderHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('EJD Cards - Home'), // Changed app bar title
      ),
      body: const Center(
        child: Text('Welcome! App structure coming soon.'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          print("Add deck button pressed");
        },
        tooltip: 'Add Deck',
        child: const Icon(Icons.add),
      ),
    );
  }
}