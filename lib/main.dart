import 'dart:async';

import 'package:flutter/material.dart';
import 'package:menu_chat/adv.dart';
import 'package:menu_chat/menu.dart';
import 'package:menu_chat/menu_tree.dart';
import 'package:menu_chat/constants.dart';
import 'package:menu_chat/text_constants.dart';

Future<Null> main() async
{
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: TextConsts.appName,
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

// Returns the widget for the *new adv screen*.
Widget createMenuScreen(
      BuildContext context,
      Widget widget,
      Widget appBar,
      Function onWillPopMenu,
      Function onBotBarTapped,
      int i)
{
   return WillPopScope(
         onWillPop: () async { return onWillPopMenu();},
         child: Scaffold(
               appBar: appBar,
               body: widget,
               bottomNavigationBar: BottomNavigationBar(
                     items: <BottomNavigationBarItem>[
                        BottomNavigationBarItem(
                              icon: Icon(Icons.home),
                              title: Text(TextConsts.newAdvTab[0])),
                        BottomNavigationBarItem(
                              icon: Icon(Icons.directions_car),
                              title: Text(TextConsts.newAdvTab[1])),
                        BottomNavigationBarItem(
                              icon: Icon(Icons.send),
                              title: Text(TextConsts.newAdvTab[2])),
                     ],

                     currentIndex: i,
                     fixedColor: Colors.deepPurple,
                     onTap: onBotBarTapped,
               )
               )
               );
}

void restoreMenuStack(List<MenuNode> st)
{
   if (st.isEmpty)
      return;

   while (st.length != 1)
      st.removeLast();
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

   AdvData advInput;

   // A flag that is set to true when the floating button (new
   // advertisement) is clicked. It must be carefully set to false
   // when that screens are left.
   bool _onNewAdvPressed = false;

   // The index of the tab we are currently in in the *new
   // advertisement screen*. For example 0 for the localization menu,
   // 1 for the models menu etc.
   int _BotBarIdx = 0;

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
      restoreMenuStack(_menus[0]);
      restoreMenuStack(_menus[1]);
      _BotBarIdx = 0;
      setState(() { });
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
      if ((_BotBarIdx + 1) != TextConsts.newAdvTab.length)
         restoreMenuStack(_menus[_BotBarIdx]);

      setState(() { _BotBarIdx = index; });
   }

   void _onAdvLeafPressed(int i)
   {
      MenuNode o = _menus[_BotBarIdx].last.children[i];
      _menus[_BotBarIdx].add(o);

      List<KeyValuePair> header = List<KeyValuePair>();

      // Let us read the corresponding header.
      final int length = _menus[_BotBarIdx].length;
      for (int i = 1; i < length; ++i) {
         String key = TextConsts.menuDepthNames[_BotBarIdx][i];
         String value = _menus[_BotBarIdx][i].name;
         header.add(KeyValuePair(key, ": " + value));
      }

      advInput.infos[_BotBarIdx] = header;

      restoreMenuStack(_menus[_BotBarIdx]);

      _BotBarIdx = _advIndexHelper(_BotBarIdx);
      setState(() { });
   }

   void _onNodePressed(int i)
   {
      //print("I am calling a adv non leaf onPressed");
      MenuNode o = _menus[_BotBarIdx].last.children[i];
      _menus[_BotBarIdx].add(o);
      setState(() { });
   }

   void _onFilterLeafNodePressed(bool newValue, int i)
   {
      if (i == 0) {
         for (MenuNode p in _menus[_BotBarIdx].last.children) {
            p.status = newValue;
         }

         setState(() { });
         return;
      }

      MenuNode o = _menus[_BotBarIdx].last.children[i];
      String code = o.code;
      print('$code ===> $newValue');
      o.status = newValue;
      setState(() { });
   }

   MenuChatState()
   {
      _menus = List<List<MenuNode>>(2);
      _menus[0] = menuReader(Consts.locMenu);
      _menus[1] = menuReader(Consts.modelsMenu);

      advInput = SimulateAdvData();

      _onNewAdvPressed = false;
      _BotBarIdx = 0;
   }

   void onAdvSendPressed(bool, AdvData)
   {
      // Have to clean menu tree state.
      print("Sending adv to server.");
      _onNewAdvPressed = false;
      _BotBarIdx = 0;
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
            w = createAdvWidget(context, advInput, onAdvSendPressed);
         } else {
            w = createAdvMenuListView(context,
                  _menus[_BotBarIdx].last,
                  _onAdvLeafPressed,
                  _onNodePressed);
         }

         AppBar appBar = AppBar(
               title: Text(TextConsts.advAppBarMsg[_BotBarIdx]),
                     elevation: 0.7, toolbarOpacity : 1.0);

         return createMenuScreen( context, w, appBar, _onWillPopMenu,
               _onBotBarTapped, _BotBarIdx);
      }

      Widget w2;
      if (_BotBarIdx == 2) {
         w2 = createSendScreen();
      } else {
         final int d = _menus[_BotBarIdx].length;
         w2 = createMenuListView(
                  context,
                  _menus[_BotBarIdx].last,
                  _onFilterLeafNodePressed,
                  _onNodePressed,
                  d == Consts.maxFilterDepth);
      }

      List<Widget> widgets = <Widget>[
         createMenuScreen(context, w2, null, _onWillPopMenu,
               _onBotBarTapped, _BotBarIdx),
         createAdvTab(context, advInput, _onAdvSelection, _onNewAdv),
         Tab(text: "Chat list"),
      ];

      return Scaffold(
            appBar: AppBar(
                  title: Text(TextConsts.appName),
                  elevation: 0.7,
                  bottom: TabBar(
                        controller: _tabController,
                        indicatorColor: Colors.white,
                        tabs: <Widget>[
                           Tab(text: TextConsts.tabNames[0],),
                           Tab(text: TextConsts.tabNames[1]),
                           Tab(text: TextConsts.tabNames[2]),
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

