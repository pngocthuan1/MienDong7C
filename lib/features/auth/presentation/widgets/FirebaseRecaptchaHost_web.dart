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
          ..style.width = '100%'
          ..style.minHeight = '80px'
          ..style.display = 'block';
      },
    );

    _registered = true;
  }

  @override
  Widget build(BuildContext context) {
    if (!FirebaseBootstrap.isInitialized) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: const SizedBox(
        height: 80,
        child: HtmlElementView(
          viewType: FirebaseRecaptchaConfig.containerId,
        ),
      ),
    );
  }
}
