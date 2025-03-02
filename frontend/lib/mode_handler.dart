import 'package:flutter/material.dart';
import 'package:rehber_sistem/modes/homepage.dart';
import 'package:rehber_sistem/modes/walk.dart';
import 'package:rehber_sistem/modes/talk.dart';
import 'package:rehber_sistem/modes/read.dart';
import 'package:rehber_sistem/modes/location.dart';

class ModeHandler extends StatelessWidget{
  const ModeHandler({super.key});

  @override
  Widget build(context){
    return MaterialApp(
      initialRoute: '/',
      routes: {
        '/': (context) => const Homepage(),
        '/walk': (context) => const WalkPage(),
        '/talk': (context) => const TalkPage(),
        '/read': (context) => const ReadPage(),
        '/location': (context) => const LocationPage(),
      },
    );
  }
}