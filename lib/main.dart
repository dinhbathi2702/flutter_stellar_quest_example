import 'package:flutter/material.dart';
import 'package:flutter_stellar_quest_example/quests/quest_13.dart';

void main() {
  runApp(const Quest());
}

class Quest extends StatelessWidget {
  const Quest({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Stellar Quest ',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      //change Page file to run Quest
      home: const Quest13(),
    );
  }
}
