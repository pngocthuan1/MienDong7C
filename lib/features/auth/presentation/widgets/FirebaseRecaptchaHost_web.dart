import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:benhvien7c/core/firebase/FirebaseBootstrap.dart';
import 'package:benhvien7c/core/firebase/FirebaseRecaptchaConfig.dart';

class FirebaseRecaptchaHost extends StatefulWidget {
  const FirebaseRecaptchaHost({super.key});

  @override
  State<FirebaseRecaptchaHost> createState() => _FirebaseRecaptchaHostState();
}

class _FirebaseRecaptchaHostState extends State<FirebaseRecaptchaHost> {
  static bool _registered = false;

  @override
  void initState() {
    super.initState();
    _registerViewFactory();
  }

  void _registerViewFactory() {
    if (_registered) {
      return;
    }

    ui_web.platformViewRegistry.registerViewFactory(
      FirebaseRecaptchaConfig.containerId,
      (int _) {
        return html.DivElement()
          ..id = FirebaseRecaptchaConfig.containerId
          ..style.width = '0px'
          ..style.height = '0px'
          ..style.display = 'none';
      },
    );

    _registered = true;
  }

  @override
  Widget build(BuildContext context) {
    if (!FirebaseBootstrap.isInitialized) {
      return const SizedBox.shrink();
    }

    return const SizedBox(
      width: 0,
      height: 0,
      child: HtmlElementView(
        viewType: FirebaseRecaptchaConfig.containerId,
      ),
    );
  }
}
