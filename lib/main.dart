import 'dart:async';

import 'package:flutter/material.dart';
import 'package:menu_chat/adv.dart';
import 'package:menu_chat/menu.dart';
import 'package:menu_chat/menu_tree.dart';
import 'package:menu_chat/constants.dart';

Future<Null> main() async {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: Consts.appName,
      theme: ThemeData(
        primaryColor: Color(0xff075E54),
        accentColor: Color(0xff25D366),
      ),
      debugShowCheckedModeBanner: false,
      home: MenuChat(),
    );
  }
}

class MenuChat extends StatefulWidget {
  MenuChat();

  @override
  MenuChatState createState() => MenuChatState();
}

class MenuChatState extends State<MenuChat>
with SingleTickerProviderStateMixin {
   TabController _tabController;
   List<List<MenuNode>> filterMenu;
   List<List<MenuNode>> advMenu;

   MenuChatState()
   {
      // I will use the same menus on both the filter and adv stacks.
      // I see no reason for duplication state. It also reduces memory
      // consumption, though I do not know how much.
      List<MenuNode> locMenu = LocationFactory();
      List<MenuNode> modelsMenu = ModelsFactory();

      filterMenu = List<List<MenuNode>>();
      filterMenu.add(locMenu);
      filterMenu.add(modelsMenu);

      advMenu = List<List<MenuNode>>();
      advMenu.add(locMenu);
      advMenu.add(modelsMenu);
   }

   @override
   void initState()
   {
      super.initState();
      _tabController = TabController(vsync: this, initialIndex: 1, length: 3);
   }

   @override
   Widget build(BuildContext context)
   {
      return createApp(context);
   }

   Widget createApp(BuildContext context) {
      return Scaffold(
            appBar: AppBar(
                  title: Text(Consts.appName),
                  elevation: 0.7,
                  bottom: TabBar(
                        controller: _tabController,
                        indicatorColor: Colors.white,
                        tabs: <Widget>[
                           Tab(text: "FILTROS",),
                           Tab(text: "ANUNCIOS"),
                           Tab(text: "CHATS",),
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
               Menu(filterMenu),
               Adv(advMenu),
               Tab(text: "Chat list"),
            ],
      ),
      );
   }
}

