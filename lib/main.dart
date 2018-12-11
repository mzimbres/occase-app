import 'dart:async';

import 'package:flutter/material.dart';
import 'package:menu_chat/adv.dart';
import 'package:menu_chat/menu.dart';

Future<Null> main() async {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "MenuChat",
      theme: ThemeData(
        primaryColor: Color(0xff075E54),
        accentColor: Color(0xff25D366),
      ),
      debugShowCheckedModeBanner: false,
      home: MenuChatApp(),
    );
  }
}

class MenuChatApp extends StatefulWidget {
  MenuChatApp();

  @override
  _MenuAppChatState createState() => new _MenuAppChatState();
}

class _MenuAppChatState extends State<MenuChatApp>
    with SingleTickerProviderStateMixin {
  TabController _tabController;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _tabController = new TabController(vsync: this, initialIndex: 1, length: 3);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("FipeChat"),
        elevation: 0.7,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: <Widget>[
            Tab( text: "FILTROS",),
            Tab(text: "ANUNCIOS"),
            Tab( text: "CHATS",),
          ],
        ),
        actions: <Widget>[
          Icon(Icons.search),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5.0),
          ),
          Icon(Icons.more_vert)
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: <Widget>[
          Menu(),
          Adv(),
          Tab(text: "Chat list"),
        ],
      ),
    );
  }
}

