import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/status.dart' as status;

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

int advIndexHelper(int i)
{
   if (i == 0) return 1;
   if (i == 1) return 2;
   return 1;

   // Assert we do not get here.
}

Widget
createChatScreen(BuildContext context,
                 Function onWillPopScope,
                 List<String> chatMsgs,
                 TextEditingController newAdvTextCtrl,
                 Function onChatSendPressed)
{
   TextField textField = TextField(
      controller: newAdvTextCtrl,
      //textInputAction: TextInputAction.go,
      keyboardType: TextInputType.multiline,
      maxLines: null,
      decoration: InputDecoration(
            hintText: TextConsts.hintTextChat,
            fillColor:Color(0xFFFFFFFF),
            )
   );

   CircleAvatar sendButCol =
         CircleAvatar(
               child: IconButton(
                  icon: Icon(Icons.send),
                  onPressed: onChatSendPressed,
                  color: Color(0xFFFFFFFF)
                  ),
               backgroundColor: Theme.of(context).primaryColor
               );

   Row row = Row(
         children: <Widget>[
            Expanded(child: textField),
            sendButCol
         ],
   );

   ListView list = ListView.builder(
         reverse:true,
         padding: const EdgeInsets.all(6.0),
         itemCount: chatMsgs.length,
         itemBuilder: (BuildContext context, int i)
         {
            return Align( alignment: Alignment.bottomRight,
                  child:FractionallySizedBox( child: Card(
                    child: Padding( padding: EdgeInsets.all(4.0),
                          child: Text(chatMsgs[i])),
                    color: Colors.lightGreenAccent[100],
                    margin: EdgeInsets.all(6.0),
                    elevation: 6.0,
                  ),
                  widthFactor: 0.8
            ));
         },
   );

   Column mainCol = Column(
         children: <Widget>[
            Expanded(child: list),
            row
         ],
   );

   return WillPopScope(
          onWillPop: () async { return onWillPopScope();},
          child: Scaffold(
             appBar : AppBar(
                //title: Text("Anunciante: Paulo nascimento"),
                title: ListTile(
                   leading: CircleAvatar(child: Text("")),
                   title: Text( "Paulo nascimento",
                      style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: Consts.mainFontSize,
                            color: Color(0xFFFFFFFF)
                      )
                   ),
                   dense: false,
                   //subtitle: subtitle
                ),
                backgroundColor: Theme.of(context).primaryColor,
             ),
          body: mainCol,
          backgroundColor: Consts.scaffoldBackground,
       )
    );
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
   List<MenuItem> _menus;

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
   int _botBarIdx = 0;

   // Stores the last tapped botton bar of *chats* screen. See that
   // without this variable we cannot know which of the two chat
   // screens we are currently in. It should be only used when both
   // _currFavChatIdx and _currFavChatIdx are -1.
   int _chatBotBarIdx = 1;

   // Stores the current chat index on favorites chat screen, -1 means
   // we are not in this screen.
   int _currFavChatIdx = -1;

   // Similar to _currFavChatIdx but corresponds to the *my own advs*
   // screen.
   int _currOwnChatIdx = -1;

   // A provisory list of user chat messages.
   List<String> _chatMsgs = List<String>();

   // The *new adv* text controler
   TextEditingController _newAdvTextCtrl = TextEditingController();

   IOWebSocketChannel channel;

   void _onAdvSelection(AdvData data)
   {
      print('Anuncio salvo');
      _advsUserSelected.add(data);
      //_advsFromUser.add(data);
      _advsFromServer.remove(data);
      setState(() { });
   }

   void _onNewAdv()
   {
      print("Open menu selection.");
      _onNewAdvPressed = true;
      _menus[0].restoreMenuStack();
      _menus[1].restoreMenuStack();
      _botBarIdx = 0;
      //_chatBotBarIdx = 0;
      setState(() { });
   }

   bool _onWillPopMenu()
   {
      if (_menus[_botBarIdx].root.length == 1) {
         _onNewAdvPressed = false;
         setState(() { });
         return false;
      }

      _menus[_botBarIdx].root.removeLast();
      setState(() { });
      return false;
   }

   bool _onWillPopFavChatScreen()
   {
      _currFavChatIdx = -1;
      setState(() { });
      return false;
   }

   void _onBotBarTapped(int i)
   {
      if ((_botBarIdx + 1) != TextConsts.newAdvTab.length)
         _menus[_botBarIdx].restoreMenuStack();

      setState(() { _botBarIdx = i; });
   }

   void _onChatBotBarTapped(int i)
   {
      setState(() { _chatBotBarIdx = i; });
   }

   void _onAdvLeafPressed(int i)
   {
      MenuNode o = _menus[_botBarIdx].root.last.children[i];
      _menus[_botBarIdx].root.add(o);
      _onAdvLeafReached();
      setState(() { });
   }

   void _onAdvLeafReached()
   {
      List<KeyValuePair> header = List<KeyValuePair>();

      // Let us read the corresponding header.
      final int length = _menus[_botBarIdx].root.length;
      for (int i = 1; i < length; ++i) {
         String key = TextConsts.menuDepthNames[_botBarIdx][i];
         String value = _menus[_botBarIdx].root[i].name;
         header.add(KeyValuePair(key, ": " + value));
      }

      _advInput.infos[_botBarIdx] = header;

      _menus[_botBarIdx].restoreMenuStack();

      _botBarIdx = advIndexHelper(_botBarIdx);
   }

   void _onNodePressed(int i)
   {
      do {
         MenuNode o = _menus[_botBarIdx].root.last.children[i];
         _menus[_botBarIdx].root.add(o);
         i = 1;
      } while (_menus[_botBarIdx].root.last.children.length == 2);

      final int length = _menus[_botBarIdx].root.last.children.length;

      assert(length != 1);

      if (length == 0) {
         _onAdvLeafReached();
      }

      setState(() { });
   }

   void _onFilterLeafNodePressed(int i)
   {
      if (i == 0) {
         final bool allStatus =
               _menus[_botBarIdx].root.last.children.first.status;
         for (MenuNode p in _menus[_botBarIdx].root.last.children) {
            p.status = !allStatus;
         }

         setState(() { });
         return;
      }

      MenuNode o = _menus[_botBarIdx].root.last.children[i];
      String code = o.code;
      final bool b = o.status;
      print('$code ===> $b');
      o.status = !b;;
      setState(() { });
   }

   void _onAdvSendPressed()
   {
      _onNewAdvPressed = false;
      _botBarIdx = 0;

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

   void _onFavChat(int i)
   {
      print("On chat clicked.");
      _currFavChatIdx = i;
      setState(() { });
   }

   void _onOwnAdvChat(int i)
   {
      _currOwnChatIdx = i;
      setState(() { });
   }

   void _onChatSendPressed()
   {
      if (_newAdvTextCtrl.text.isEmpty)
         return;

      _chatMsgs.add(_newAdvTextCtrl.text);
      _newAdvTextCtrl.text = "";
      print("Chat send");
      setState(() { });
   }

   void onWSData(msg)
   {
      Map<String, dynamic> ack = jsonDecode(msg);
      final String cmd = ack["cmd"];
      print("Received from server: $cmd");
      if (cmd == "auth_ack") {
         // First we check if the auth was successful.
         final String res = ack["result"];
         if (res == 'fail') {
            print("Handle failed auth.");
            return;
         }

         // TODO: Handle failed auths.
         assert(res == 'ok');

         // This list will have to be written to a file.
         if (ack.containsKey('menus')) {
            _menus = menuReader(ack);
            assert(_menus != null);
            print('Received menus with length ${_menus.length}');
         }
      }
   }

   void onWSError(error)
   {
      // TODO: Start a reconnect timer.
      print(error);
   }

   void onWSDone()
   {
      print("Communication closed by peer.");
   }

   void _sendHahesToServer()
   {
      print("Sending hashes to server");
      List<String> codes =
            readHashCodes(_menus[0].root.first, _menus[0].filterDepth);

      print(codes);
   }

   MenuChatState()
   {
      Map<String, dynamic> rawMenuMap = jsonDecode(Consts.menus);
      if (rawMenuMap.containsKey('menus')) {
         // TODO: How to deal with a null menu.
         _menus = menuReader(rawMenuMap);
      }

      _onNewAdvPressed = false;
      _botBarIdx = 0;

      _advInput = AdvData();
      _advsFromServer = List<AdvData>();
      _advsUserSelected = List<AdvData>();
      _advsFromUser = List<AdvData>();

      // WARNING: localhost or 127.0.0.1 is the emulator or the phone
      // address.
      channel = IOWebSocketChannel.connect('ws://10.0.2.2:8080');
      channel.stream.listen(onWSData,
            onError: onWSError, onDone: onWSDone);

      // This is where we will read the raw menu from files and send
      // our versions to the app. By sending -1 we will always receive
      // back from the server.
      var authCmd = {
         'cmd': 'auth',
         'from': '0001',
         'menu_versions': <int>[-1, -1],
      };

      final String authText = jsonEncode(authCmd);
      print(authText);
      channel.sink.add(authText);
   }

   @override
   void initState()
   {
      super.initState();
      _tabController = TabController(vsync: this,
            initialIndex: 1, length: 3);
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
         if (_botBarIdx == 2) {
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
                        _menus[_botBarIdx].root.last,
                        _onAdvLeafPressed,
                        _onNodePressed
                     );
         }

         AppBar appBar = AppBar(
               title: Text(TextConsts.advAppBarMsg[_botBarIdx]),
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
                   _botBarIdx
                );
      }

      if (_tabController.index == 2 && _currFavChatIdx != -1) {
         if (_currFavChatIdx != -1) {
            // We are in the favorite advs screen, where pressing the
            // chat button in any of the advs leads us to the chat
            // screen with the advertizer.
            return createChatScreen(
                  context,
                  _onWillPopFavChatScreen,
                  _chatMsgs,
                  _newAdvTextCtrl,
                  _onChatSendPressed);
         }
      }

      Widget filterTabWidget;
      if (_botBarIdx == 2) {
         filterTabWidget = createSendScreen(_sendHahesToServer);
      } else {
         final int d = _menus[_botBarIdx].root.length;
         filterTabWidget = createFilterListView(
                             context,
                             _menus[_botBarIdx].root.last,
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
                      _botBarIdx
                   );

      widgets[1] = createAdvTab(
                      context,
                      _advsFromServer,
                      _onAdvSelection,
                      _onNewAdv
                   );

      Widget chatWidget;
      if (_chatBotBarIdx == 0) {
         chatWidget = createChatTab(
                            context,
                            _advsFromUser,
                            _onOwnAdvChat,
                            TextConsts.ownAdvButtonText);
      } else {
         chatWidget = createChatTab(
                            context,
                            _advsUserSelected,
                            _onFavChat,
                            TextConsts.chatButtonText);
      }

      widgets[2] = createBotBarScreen(context,
                      chatWidget,
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

