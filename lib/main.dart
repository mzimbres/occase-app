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

// Returns the widget for the *new adv screen*.
Widget createBotBarScreen(
      BuildContext context,
      Widget scafBody,
      Widget appBar,
      List<IconData> icons,
      List<String> iconLabels,
      Function onWillPop,
      Function onBotBarTapped,
      int i)
{
   assert(icons.length == iconLabels.length);
   final int length = icons.length;

   List<BottomNavigationBarItem> items =
         List<BottomNavigationBarItem>(length);

   for (int i = 0; i < length; ++i) {
      items[i] = BottomNavigationBarItem(
               icon: Icon(icons[i]),
               title: Text(iconLabels[i])
      );
   }

   return WillPopScope(
          onWillPop: () async { return onWillPop();},
          child: Scaffold(
               appBar: appBar,
               body: scafBody,
               bottomNavigationBar: BottomNavigationBar(
                     items: items,
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

int advIndexHelper(int i)
{
   if (i == 0) return 1;
   if (i == 1) return 2;
   return 1;

   // Assert we do not get here.
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

   // The user own adv.
   AdvData _advInput;

   // The list of advs received from the server.
   List<AdvData> _advsFromServer;

   // The list of advs the user found interesting. The are moved from
   // the list of ads received from the server.
   List<AdvData> _advsUserSelected;

   // Advs the user wrote itself and sent to the server. One issue we
   // have to observe here is that we will send _advInput to the
   // server and if the user is subscribed to the channel the adv
   // belongs to, we will receive it back from the server and we
   // should not display it or duplicate it on this list.
   List<AdvData> _advsFromUser;

   // A flag that is set to true when the floating button (new
   // advertisement) is clicked. It must be carefully set to false
   // when that screens are left.
   bool _onNewAdvPressed = false;

   // The index of the tab we are currently in in the *new
   // advertisement screen*. For example 0 for the localization menu,
   // 1 for the models menu etc.
   int _BotBarIdx = 0;

   int _chatBotBarIdx = 0;

   // The *new adv* text controler
   TextEditingController _newAdvTextCtrl = TextEditingController();

   void _onAdvSelection(AdvData data)
   {
      print('Anuncio salvo');
      _advsUserSelected.add(data);
      _advsFromServer.remove(data);
      setState(() { });
   }

   void _onNewAdv()
   {
      print("Open menu selection.");
      _onNewAdvPressed = true;
      restoreMenuStack(_menus[0]);
      restoreMenuStack(_menus[1]);
      _BotBarIdx = 0;
      _chatBotBarIdx = 0;
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

   void _onBotBarTapped(int i)
   {
      if ((_BotBarIdx + 1) != TextConsts.newAdvTab.length)
         restoreMenuStack(_menus[_BotBarIdx]);

      setState(() { _BotBarIdx = i; });
   }

   void _onChatBotBarTapped(int i)
   {
      setState(() { _chatBotBarIdx = i; });
   }

   void _onAdvLeafPressed(int i)
   {
      MenuNode o = _menus[_BotBarIdx].last.children[i];
      _menus[_BotBarIdx].add(o);
      _onAdvLeafReached();
      setState(() { });
   }

   void _onAdvLeafReached()
   {
      List<KeyValuePair> header = List<KeyValuePair>();

      // Let us read the corresponding header.
      final int length = _menus[_BotBarIdx].length;
      for (int i = 1; i < length; ++i) {
         String key = TextConsts.menuDepthNames[_BotBarIdx][i];
         String value = _menus[_BotBarIdx][i].name;
         header.add(KeyValuePair(key, ": " + value));
      }

      _advInput.infos[_BotBarIdx] = header;

      restoreMenuStack(_menus[_BotBarIdx]);

      _BotBarIdx = advIndexHelper(_BotBarIdx);
   }

   void _onNodePressed(int i)
   {
      do {
         MenuNode o = _menus[_BotBarIdx].last.children[i];
         _menus[_BotBarIdx].add(o);
         i = 1;
      } while (_menus[_BotBarIdx].last.children.length == 2);

      final int length = _menus[_BotBarIdx].last.children.length;

      assert(length != 1);

      if (length == 0) {
         _onAdvLeafReached();
      }

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

   void _onAdvSendPressed()
   {
      _onNewAdvPressed = false;
      _BotBarIdx = 0;

      final String key = "Descricao";
      final String value = _newAdvTextCtrl.text;
      _advInput.infos.last.add(KeyValuePair(key, ": " + value));

      //________
      //
      // TODO: This line is needed only in the prototype. Later when
      // we connect the app in the server to adv that has been
      // published we get sent back to us by the server.
      _advsFromServer.add(_advInput.clone());

      // The following code may also have to be removed to avoid
      // duplicates. See comments in the declaration of _advsFromUser

      _advsFromUser.add(_advInput.clone());

      //_______

      _newAdvTextCtrl.text = "";
      _advInput = AdvData();

      setState(() { });
   }

   void _onChat()
   {
      print("On chat clicked.");
   }

   MenuChatState()
   {
      _menus = List<List<MenuNode>>(2);
      _menus[0] = menuReader(Consts.locMenu);
      _menus[1] = menuReader(Consts.modelsMenu);

      _onNewAdvPressed = false;
      _BotBarIdx = 0;

      _advInput = AdvData();
      _advsFromServer = List<AdvData>();
      _advsUserSelected = List<AdvData>();
      _advsFromUser = List<AdvData>();
   }

   @override
   void initState()
   {
      super.initState();
      _tabController = TabController(vsync: this, initialIndex: 1, length: 3);
   }

   @override
   void dispose()
   {
     _newAdvTextCtrl.dispose();
     super.dispose();
   }

   @override
   Widget build(BuildContext context)
   {
      if (_onNewAdvPressed) {
         Widget widget;
         if (_BotBarIdx == 2) {
            Widget widget_tmp = createNewAdvWidget(
                        context,
                        _advInput,
                        _onAdvSendPressed,
                        TextConsts.newAdvButtonText,
                        _newAdvTextCtrl
                     );

            // I added this ListView to prevent widget_tmp from
            // extending the whole screen. Inside the ListView it
            // appears compact. Remove this later.
            widget = ListView(
               shrinkWrap: true,
               //padding: const EdgeInsets.all(20.0),
               children: <Widget>[widget_tmp]
            );

         } else {
            widget = createAdvMenuListView(
                        context,
                        _menus[_BotBarIdx].last,
                        _onAdvLeafPressed,
                        _onNodePressed
                     );
         }

         AppBar appBar = AppBar(
               title: Text(TextConsts.advAppBarMsg[_BotBarIdx]),
               elevation: 0.7,
               toolbarOpacity : 1.0
         );

         return createBotBarScreen(
                   context,
                   widget,
                   appBar,
                   TextConsts.newAdvTabIcons,
                   TextConsts.newAdvTab,
                   _onWillPopMenu,
                   _onBotBarTapped,
                   _BotBarIdx
                );
      }

      Widget filterTabWidget;
      if (_BotBarIdx == 2) {
         filterTabWidget = createSendScreen();
      } else {
         final int d = _menus[_BotBarIdx].length;
         filterTabWidget = createMenuListView(
                             context,
                             _menus[_BotBarIdx].last,
                             _onFilterLeafNodePressed,
                             _onNodePressed,
                             d == Consts.maxFilterDepth);
      }

      List<Widget> widgets = List<Widget>(TextConsts.tabNames.length);

      widgets[0] = createBotBarScreen(
                      context,
                      filterTabWidget,
                      null,
                      TextConsts.newAdvTabIcons,
                      TextConsts.newAdvTab,
                      _onWillPopMenu,
                      _onBotBarTapped,
                      _BotBarIdx
                   );

      widgets[1] = createAdvTab(
                      context,
                      _advsFromServer,
                      _onAdvSelection,
                      _onNewAdv
                   );

      String buttonText = TextConsts.chatButtonText;
      if (_chatBotBarIdx == 0)
         buttonText = TextConsts.ownAdvButtonText;

      widgets[2] = createBotBarScreen(context,
                      createChatTab(
                            context,
                            _advsUserSelected,
                            _onChat,
                            buttonText),
                      null,
                      TextConsts.chatIcons,
                      TextConsts.chatIconTexts,
                      () {print("Implement me");},
                      _onChatBotBarTapped,
                      _chatBotBarIdx);


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
            body: TabBarView(controller: _tabController, children: widgets)
      );
   }
}

