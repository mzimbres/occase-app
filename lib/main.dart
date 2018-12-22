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
   List<List<MenuNode>> _filterMenus;
   List<List<MenuNode>> _advMenus;
   AdvData data1;
   bool _onSelection = false;
   int _BotBarIdx = 0; // Used on menu screens.

   void _onAdvSelection(bool newValue, AdvData data)
   {
      print('Anuncio salvo');
      data.saved = newValue;
      setState(() { });
   }

   void _onNewAdv()
   {
      print("Open menu selection.");
      _onSelection = true;
      setState(() { });
   }

   MenuChatState()
   {
      // I will use the same menu objects on both the filter and adv
      // stacks.  I see no reason for duplication state. It also
      // reduces memory consumption, though I do not know how much.
      List<MenuNode> locMenu = LocationFactory();
      List<MenuNode> modelsMenu = ModelsFactory();

      _filterMenus = List<List<MenuNode>>();
      _filterMenus.add(locMenu);
      _filterMenus.add(modelsMenu);

      _advMenus = List<List<MenuNode>>();
      _advMenus.add(locMenu);
      _advMenus.add(modelsMenu);

      data1 = SimulateAdvData();
      _onSelection = false;
   }

   bool _onWillPopMenu()
   {
      if (_advMenus[_BotBarIdx].length == 1) {
         _onSelection = false;
         setState(() { });
         return false;
      }

      _advMenus[_BotBarIdx].removeLast();
      setState(() { });
      return false;
   }

   void _onBotBarTapped(int index)
   {
      setState(() { _BotBarIdx = index; });
   }

   void _onLeafPressed(bool newValue, int i)
   {
      MenuNode o = _advMenus[_BotBarIdx].last.children[i];
      String code = o.code;
      print('$code ===> $newValue');
      o.status = newValue;
      setState(() { });
   }

   void _onNodePressed(int i)
   {
      print("I am calling a adv non leaf onPressed");
      MenuNode o = _advMenus[_BotBarIdx].last.children[i];
      _advMenus[_BotBarIdx].add(o);
      setState(() { });
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

   Widget createApp(BuildContext context)
   {
      if (_onSelection) {
         Widget w;
         if (_BotBarIdx == 2) {
            w = createSendScreen();
         } else {
            w = createMenuListView(
                  context,
                  _advMenus[_BotBarIdx].last,
                  _onLeafPressed,
                  _onNodePressed);
         }

         return WillPopScope(
               onWillPop: () async { return _onWillPopMenu();},
               child: Scaffold(
                     appBar: AppBar(
                           title: Text("Escolha uma localizacao"),
                           elevation: 0.7,
                     ),
                     body: w,
                     bottomNavigationBar: BottomNavigationBar(
                           items: <BottomNavigationBarItem>[
                              BottomNavigationBarItem(
                                    icon: Icon(Icons.home), title: Text('Localizacao')),
                              BottomNavigationBarItem(
                                    icon: Icon(Icons.directions_car), title: Text('Modelos')),
                              BottomNavigationBarItem(
                                    icon: Icon(Icons.send), title: Text('Enviar')),
                           ],

                           currentIndex: _BotBarIdx,
                           fixedColor: Colors.deepPurple,
                           onTap: _onBotBarTapped,
                     )
               )
            );
      }

      List<Widget> widgets = <Widget>[
         Menu(_filterMenus), 
         createAdvScreen(context, data1, _onAdvSelection, _onNewAdv),
         Tab(text: "Chat list"),
      ];

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
            body: TabBarView(controller: _tabController, children: widgets,),
      );
   }
}

