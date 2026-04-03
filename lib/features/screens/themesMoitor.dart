import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class Themesmoitor extends StatelessWidget {
  const Themesmoitor({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Center(
          child: Text(
            "Themes Monitor Content Area",
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      ),
    );
  }
}
