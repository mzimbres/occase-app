import 'dart:async';

import 'package:flutter/material.dart';

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

class Menu extends StatefulWidget {
  @override
  MenuState createState() => new MenuState();
}

class MenuState extends State<Menu> {
  List<Widget> _marcas;
  List<String> _brands = <String>[
                "Alfa Romeo",
                "BMW",
                "Fiat",
                "Volkswagen",
                "Mercedes",
                "Ford",
                "Chevrolet",
                "Citroen",
                "Peugeot",
                "Ferrari",
                "Dodge",
                "Rolls Roice",
             ];

  List<String> _models =
        <String>[ "Uno mil",
                "Palio",
                ];

  @override
  void initState() {
    super.initState();
    _marcas = new List<Widget>();
    for (String o in _brands) {
       _marcas.add(RaisedButton(
                   child: Text(o),
                   onPressed: () {setState(update);}
                   ));
    }
    //_marcas = _brands;
  }

  void update()
  {
     print("pressed2");
  }

  @override
  Widget build(BuildContext context) {
     return ListView(
                 shrinkWrap: true,
                 padding: const EdgeInsets.all(20.0),
                 children: this._marcas
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
  List<Widget> marcas = <Widget>[
             RaisedButton( child: Text("Alfa Romeo")
                         , onPressed: () => print("pressed")),
             RaisedButton( child: Text("BMW")
                         , onPressed: () => print("pressed")),
             RaisedButton( child: Text("Fiat")
                         , onPressed: () => print("pressed")),
          ];

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
            Tab(text: "ANUNCIOS"),
            Tab( text: "TABELA",),
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
          Tab(text: "Anuncios"),
          Menu(),
          Tab(text: "Chat list"),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Theme.of(context).accentColor,
        child: Icon(
          Icons.message,
          color: Colors.white,
        ),
        onPressed: () => print("open chats"),
      ),
    );
  }
}

