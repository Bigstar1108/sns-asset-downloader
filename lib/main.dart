import 'dart:async';

import 'package:flutter_sharing_intent/flutter_sharing_intent.dart';
import 'package:flutter_sharing_intent/model/sharing_file.dart';

import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Flutter Demo',
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({
    super.key,
    required this.title,
  });

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late final StreamSubscription appLinksSubscription;
  late final StreamSubscription urlStreamSubscription;

  List<SharedFile>? sharedFileList;

  @override
  void initState() {
    super.initState();

    urlStreamSubscription = FlutterSharingIntent.instance.getMediaStream().listen(
      (List<SharedFile> value) {
        print('FlutterSharingIntent getMediaStream: $value');

        setState(() {
          sharedFileList = value;
        });
      },
      onError: (error) {
        print('FlutterSharingIntent.instance.getMediaStream Error: $error');
      },
    );

    FlutterSharingIntent.instance.getInitialSharing().then((List<SharedFile> value) {
      print('FlutterSharingIntent getInitialSharing: $value');

      setState(() {
        sharedFileList = value;
      });
    });
  }

  @override
  void dispose() {
    urlStreamSubscription.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> children = [];

    final List<SharedFile>? sharedFileList = this.sharedFileList;
    if (sharedFileList != null) {
      children.addAll(
        sharedFileList.map((e) => Text(e.value ?? 'value is null')),
      );
    }

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: children,
        ),
      ),
    );
  }
}
