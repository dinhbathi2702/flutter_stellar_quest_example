import 'package:flutter/material.dart';

class BasePage extends StatelessWidget {
  final Widget? child;
  final String? title;
  const BasePage({super.key, this.child, this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: title != null ? const Text('title') : null,
      ),
      body: Center(
          child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: child,
      )),
    );
  }
}
