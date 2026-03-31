import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class Marketmonitor extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Center(
          child: Text(
            "Market Monitor Content Area",
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      ),
    );
  }
}
