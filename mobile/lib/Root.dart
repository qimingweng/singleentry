import 'package:flutter/material.dart';
import 'package:mobile/Camera.dart';

class Root extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Camera(),
    );
  }
}
