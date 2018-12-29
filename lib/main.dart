import 'dart:async';

import 'package:flutter/material.dart';
import 'package:menu_chat/adv.dart';
import 'package:menu_chat/menu.dart';
import 'package:menu_chat/menu_tree.dart';
import 'package:menu_chat/constants.dart';

Future<Null> main() async
{
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

   // The outermost list is an array with the length equal to the
   // number of menus there are. The inner most list is actually a
   // stack whose first element is the menu root node. When menu
   // entries are selected we push those items on the stack. Used both
   // on the filter and on the advertizement screens.
   List<List<MenuNode>> _menus;

   AdvData data1;

   // A flag that is set to true when the floating button (new
   // advertisement) is clicked. It must be carefully set to false
   // when that screens are left.
   bool _onNewAdvPressed = false;

   // The index of the tab we are currently in in the *new
   // advertisement screen*. For example 0 for the localization menu,
   // 1 for the models menu etc.
   int _BotBarIdx = 0;

   // The text shown on the app bar for each tab on the *new
   // advertisement screen.*
   List<String> _advAppBarMsg;

   void _onAdvSelection(bool newValue, AdvData data)
   {
      print('Anuncio salvo');
      data.saved = newValue;
      setState(() { });
   }

   void _onNewAdv()
   {
      print("Open menu selection.");
      _onNewAdvPressed = true;
      setState(() { });
   }

   MenuChatState()
   {
      _menus = List<List<MenuNode>>(2);
      _menus[0] = LocationFactory();
      _menus[1] = ModelsFactory();

      data1 = SimulateAdvData();

      _onNewAdvPressed = false;
      _BotBarIdx = 0;
      _advAppBarMsg = List<String>(3);
      _advAppBarMsg[0] = "Escolha uma localizacao";
      _advAppBarMsg[1] = "Escolha um modelo";
      _advAppBarMsg[2] = "Verificacao e envio";
   }

   bool _onWillPopMenu()
   {
      if (_menus[_BotBarIdx].length == 1) {
         _onNewAdvPressed = false;
         setState(() { });
         return false;
      }

      _menus[_BotBarIdx].removeLast();
      setState(() { });
      return false;
   }

   int _advIndexHelper(int i)
   {
      if (i == 0) return 1;
      if (i == 1) return 2;
      return 1;

      // Assert we do not get here.
   }

   void _onBotBarTapped(int index)
   {
      setState(() { _BotBarIdx = index; });
   }

   void _onAdvLeafPressed(bool newValue, int i)
   {
      MenuNode o = _menus[_BotBarIdx].last.children[i];
      String code = o.code;
      print('$code ===> $newValue');
      o.status = newValue;

      while (_menus[_BotBarIdx].length != 1) {
         _menus[_BotBarIdx].removeLast();
      }

      _BotBarIdx = _advIndexHelper(_BotBarIdx);
      setState(() { });
   }

   void _onNodePressed(int i)
   {
      print("I am calling a adv non leaf onPressed");
      MenuNode o = _menus[_BotBarIdx].last.children[i];
      _menus[_BotBarIdx].add(o);
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
      if (_onNewAdvPressed) {
         Widget w;
         if (_BotBarIdx == 2) {
            w = Center(child:RaisedButton(
                        child: Text( "Enviar",
                              style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: Consts.mainFontSize )
                        ),
                        onPressed: ()
                        {
                           // Have to clean menu tree state.
                           print("Sending adv to server.");
                           _onNewAdvPressed = false;
                           _BotBarIdx = 0;
                           setState(() { });
                        },
                        //color: const Color(0xFFFFFF),
                        //highlightColor: const Color(0xFFFFFF)
            )
            );
         } else {
            w = createMenuListView(
                  context,
                  _menus[_BotBarIdx].last,
                  _onAdvLeafPressed,
                  _onNodePressed);
         }

         print("Current index $_BotBarIdx");

         return WillPopScope(
               onWillPop: () async { return _onWillPopMenu();},
               child: Scaffold(
                     appBar: AppBar(
                           title: Text(_advAppBarMsg[_BotBarIdx]),
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
         Menu(_menus), 
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

