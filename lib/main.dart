import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:collection';

import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:flutter/services.dart';
import 'package:device_info/device_info.dart';

import 'package:flutter/material.dart';
import 'package:menu_chat/adv.dart';
import 'package:menu_chat/menu.dart';
import 'package:menu_chat/menu_tree.dart';
import 'package:menu_chat/constants.dart';
import 'package:menu_chat/text_constants.dart' as cts;

Future<Null> main() async
{
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: cts.appName,
      theme: ThemeData(
                brightness: Brightness.light,
                primaryColor: cts.primaryColor,
                accentColor: cts.accentColor,
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
      List<Icon> icons,
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
               icon: icons[i],
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
}

Widget
createChatScreen(BuildContext context,
                 Function onWillPopScope,
                 ChatHistory chatHist,
                 TextEditingController ctrl,
                 Function onChatSendPressed)
{
   TextField tf = makeTextInputFieldCard(ctrl);

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
            Expanded(child: makeCard(tf)),
            makeCard(sendButCol)
         ],
   );

   ListView list = ListView.builder(
         reverse:true,
         padding: const EdgeInsets.all(6.0),
         itemCount: chatHist.msgs.length,
         itemBuilder: (BuildContext context, int i)
         {
            Alignment align = Alignment.bottomLeft;
            Color color = Color(0xFFFFFFFF);
            if (chatHist.msgs[i].thisApp) {
               align = Alignment.bottomRight;
               color = Colors.lightGreenAccent[100];
            }

            return Align( alignment: align,
                  child:FractionallySizedBox( child: Card(
                    child: Padding( padding: EdgeInsets.all(4.0),
                          child: Text(chatHist.msgs[i].msg)),
                    color: color,
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
                title: ListTile(
                   leading: CircleAvatar(child: Text("")),
                   title: Text( chatHist.peer,
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

Widget makeTabWidget(BuildContext context, int n, String title)
{
   if (n == 0)
      return Text(title, style: TextStyle(color: Colors.white));

   // TODO: Change the text color to primary color?
   return Row(children: <Widget>[
      Text(title + " ", style: TextStyle(color: Colors.white)),
      makeCircleUnreadMsgs(n, Colors.white,
                           Theme.of(context).primaryColor)
      ]
   );
}

class MenuChat extends StatefulWidget {
  MenuChat();

  @override
  MenuChatState createState() => MenuChatState();
}

class MenuChatState extends State<MenuChat>
      with SingleTickerProviderStateMixin {
   TabController _tabCtrl;

   // The id we will use to communicate with the server.
   String _appId = '007';

   // The outermost list is an array with the length equal to the
   // number of menus there are. The inner most list is actually a
   // stack whose first element is the menu root node. When menu
   // entries are selected we push those items on the stack. Used both
   // on the filter and on the advertizement screens.
   List<MenuItem> _menus;

   // The temporary variable used to store the adv the user sends.
   AdvData _advInput = AdvData();

   // The list of advs received from the server. Our own advs that the
   // server echoes back to us (if we are subscribed to the channel)
   // will be filtered out.
   List<AdvData> _advs = List<AdvData>();
   List<AdvData> _unreadAdvs = List<AdvData>();

   // The list of advs the user found interesting and moved to
   // favorites. They are moved from the list of advs received from
   // the server to this list.
   List<AdvData> _favAdvs = List<AdvData>();

   // Advs the user wrote itself and sent to the server. One issue we
   // have to observe here is that we will send _advInput to the
   // server and if the user is subscribed to the channel the adv
   // belongs to, we will receive it back from the server and we
   // should not display it or duplicate it on this list. The advs
   // received from the server will not be inserted here. The only
   // advs inserted here are those that have been acked with ok by the
   // server, before that they will live in the output queue
   // _outAdvQueue
   List<AdvData> _ownAdvs = List<AdvData>();

   // Advs sent by the user that have not been acked by the server
   // yet.
   Queue<AdvData> _outAdvQueue = Queue<AdvData>();

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

   // Stores the current chat index in the array _favAdvs, -1
   // means we are not in this screen.
   int _currFavChatIdx = -1;

   // Similar to _currFavChatIdx but corresponds to the *my own advs*
   // screen.
   int _currOwnChatIdx = -1;

   // This string will be set to the name of user interested on our
   // adv.
   String _ownAdvChatPeer;

   // The *new adv* text controler
   TextEditingController _newAdvTextCtrl = TextEditingController();

   IOWebSocketChannel channel;

   static final DeviceInfoPlugin devInfo = DeviceInfoPlugin();

   MenuChatState()
   {
      Map<String, dynamic> rawMenuMap = jsonDecode(Consts.menus);
      if (rawMenuMap.containsKey('menus')) {
         // TODO: How to deal with a null menu.
         _menus = menuReader(rawMenuMap);
      }

      _onNewAdvPressed = false;
      _botBarIdx = 0;
   }

   Future<void> readDevInfo() async
   {
      Map<String, dynamic> deviceData;

      try {
         if (Platform.isAndroid) {
            AndroidDeviceInfo info = await devInfo.androidInfo;
            // To void colision between devices running on the same
            // machine, I will also use time stamp. Remove this later.
            final int now = DateTime.now().millisecondsSinceEpoch;
            _appId = info.id + "${now}";
            print("========>: " + _appId);
         } else if (Platform.isIOS) {
            // Not implemented.
         }
      } on PlatformException {
         // Id unavailable?
      }

      // What is this meand for?
      if (!mounted)
         return;

      _connectToServer(_appId);
   }

   @override
   void initState()
   {
      super.initState();

      _tabCtrl = TabController(vsync: this,
            initialIndex: 1, length: 3);

      _tabCtrl.addListener(_tabCtrlChangeHandler);

      readDevInfo();
   }

   void _onAdvSelection(AdvData data, bool fav)
   {
      if (fav)
         _favAdvs.add(data);

      //_ownAdvs.add(data);
      _advs.remove(data);
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

   bool _onWillPopOwnChatScreen()
   {
      _ownAdvChatPeer = null;
      //_currOwnChatIdx = -1;
      setState(() { });
      return false;
   }

   void _onBotBarTapped(int i)
   {
      if ((_botBarIdx + 1) != cts.newAdvTabNames.length)
         _menus[_botBarIdx].restoreMenuStack();

      setState(() { _botBarIdx = i; });
   }

   void _onNewAdvBotBarTapped(int i)
   {
      // We allow the user to tap backwards to a new tab not forward.
      // This is to avoid complex logic of avoid the publication of
      // imcomplete advs.
      if (i >= _botBarIdx)
         return;

      // The desired tab is *i* the current tab is _botBarIdx. For any
      // tab we land on or walk through we have to restore the menu
      // stack, except for the last tab or any *non-menu* tab that we
      // happen to add.

      // To handle the boundary condition on the last tab.
      if ((_botBarIdx + 1) != cts.newAdvTabNames.length)
         ++_botBarIdx;

      do {
         --_botBarIdx;
         _menus[_botBarIdx].restoreMenuStack();
      } while (_botBarIdx != i);

      setState(() { });
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
      _advInput.codes[_botBarIdx][0] = _menus[_botBarIdx].root.last.code;
      _menus[_botBarIdx].restoreMenuStack();
      _botBarIdx = advIndexHelper(_botBarIdx);
   }

   void _onAdvNodePressed(int i)
   {
      // We continue pushing on the stack if the next screen will have
      // only one menu option.
      do {
         MenuNode o = _menus[_botBarIdx].root.last.children[i];
         _menus[_botBarIdx].root.add(o);
         i = 0;
      } while (_menus[_botBarIdx].root.last.children.length == 1);

      final int length = _menus[_botBarIdx].root.last.children.length;

      assert(length != 1);

      if (length == 0) {
         _onAdvLeafReached();
      }

      setState(() { });
   }

   void _onFilterNodePressed(int i)
   {
      MenuNode o = _menus[_botBarIdx].root.last.children[i];
      _menus[_botBarIdx].root.add(o);

      setState(() { });
   }

   void _onFilterLeafNodePressed(int i)
   {
      if (i == 0) {
         for (MenuNode p in _menus[_botBarIdx].root.last.children)
            p.status = true;

         setState(() { });
         return;
      }

      --i; // Accounts for the Todos index.

      MenuNode o = _menus[_botBarIdx].root.last.children[i];
      final bool b = o.status;
      o.status = !b;;
      setState(() { });
   }

   void _onSendNewAdvPressed(bool add)
   {
      _onNewAdvPressed = false;

      if (!add) {
         _advInput = AdvData();
         _advInput.from = _appId;
         setState(() { });
         return;
      }

      _botBarIdx = 0;
      _advInput.description = _newAdvTextCtrl.text;
      _newAdvTextCtrl.text = "";

      // Was only useful when the app was not connected in the server.
      // Remove this later.
      //_advs.add(_advInput.clone());

      // We add it here in our own list of advs and keep in mind it
      // will be echoed back to us and have to be filtered out from
      // _advs since that list should not contain our own
      // advs.
      _advInput.from = _appId;
      print(_advInput.from);
      _outAdvQueue.add(_advInput.clone());
      _advInput = AdvData();

      var pubMap = {
         'cmd': 'publish',
         'from': _outAdvQueue.first.from,
         'to': _outAdvQueue.first.codes,
         'msg': _outAdvQueue.first.description,
      };

      final String pubText = jsonEncode(pubMap);
      print(pubText);
      channel.sink.add(pubText);

      setState(() { });
   }

   // This function is called with the index in _favAdvs.
   void _onFavChatPressed(int i, int j)
   {
      assert(j == 0);
      _currFavChatIdx = i;
      setState(() { });
   }

   void _onFavChatLongPressed(int i, int j)
   {
      assert(j == 0);
      final bool old = _favAdvs[i].chats[0].isLongPressed;
      _favAdvs[i].chats[0].isLongPressed = !old;
      setState(() { });
   }

   void _onOwnAdvChatPressed(int i, int j)
   {
      _currOwnChatIdx = i;
     _ownAdvChatPeer = _ownAdvs[i].chats[j].peer;

      setState(() { });
   }

   void _onOwnAdvChatLongPressed(int i, int j)
   {
      final bool old = _ownAdvs[i].chats[j].isLongPressed;
      _ownAdvs[i].chats[j].isLongPressed = !old;
      setState(() { });
      print("_onOwnAdvChatLongPressed");
   }

   void _onFavChatSendPressed()
   {
      if (_newAdvTextCtrl.text.isEmpty)
         return;

      final String msg = _newAdvTextCtrl.text;
      _newAdvTextCtrl.text = "";

      final String to = _favAdvs[_currFavChatIdx].from;

      var msgMap = {
         'cmd': 'user_msg',
         'from': _appId,
         'to': to,
         'msg': msg,
         'id': _favAdvs[_currFavChatIdx].id,
         'is_sender_adv': false,
      };

      final String payload = jsonEncode(msgMap);
      print(payload);
      channel.sink.add(payload);

      _favAdvs[_currFavChatIdx].addMsg(to, msg, true);
      setState(() { });
   }

   void _onOwnChatSendPressed()
   {
      if (_newAdvTextCtrl.text.isEmpty)
         return;

      final String msg = _newAdvTextCtrl.text;
      _newAdvTextCtrl.text = "";

      var msgMap = {
         'cmd': 'user_msg',
         'from': _appId,
         'to': _ownAdvChatPeer,
         'msg': msg,
         'id': _ownAdvs[_currOwnChatIdx].id,
         'is_sender_adv': true,
      };

      final String payload = jsonEncode(msgMap);
      print(payload);
      channel.sink.add(payload);

      _ownAdvs[_currOwnChatIdx].addMsg(_ownAdvChatPeer, msg, true);
      setState(() { });
   }

   void onWSData(msg)
   {
      Map<String, dynamic> ack = jsonDecode(msg);
      final String cmd = ack["cmd"];

      if (cmd == "auth_ack") {
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
         }

         // TODO: Handle the subscribe ack.
         return;
      }

      print("Received from server: ${ack}");

      if (cmd == "publish") {
         String msg = ack['msg'];
         String from = ack['from'];
         int id = ack['id'];

         if (from == _appId) {
            // TODO: Ignore own messages.
            print("Ignoring own publish message.");
            return;
         }

         List<dynamic> to = ack['to'];

         List<List<List<int>>> codes = List<List<List<int>>>();
         for (List<dynamic> a in to) {
            List<List<int>> foo = List<List<int>>();
            for (List<dynamic> b in a) {
               List<int> bar = List<int>();
               for (int c in b) {
                  bar.add(c);
               }
               foo.add(bar);
            }
            codes.add(foo);
         }

         AdvData adv = AdvData();
         adv.from = from;
         adv.description = msg;
         adv.codes = codes;
         adv.id = id;

         // Since this adv is not from this app we have to add a chat
         // entry in it.
         adv.createChatEntryForPeer(adv.from);

         _unreadAdvs.add(adv);

         // TODO: Before triggering a redraw we should perhaps check
         // whether it is necessary given our current state.
         setState(() { });
      }

      if (cmd == "publish_ack") {
         final String msg = ack['msg'];
         final String res = ack['result'];
         if (res != 'ok') {
            print("Message could not be sent.");
            // TODO: Retry to send. Since we send one by one the
            // message that failed is in the top of the stack.
            return;
         }

         final int id = ack['id'];
         print("Message with id = ${id} has been acked.");

         _outAdvQueue.first.id = id;

         assert(!_outAdvQueue.isEmpty);
         _ownAdvs.add(_outAdvQueue.removeFirst());
      }

      if (cmd == "user_msg") {
         final String to = ack['to'];
         if (to != _appId) {
            // The server routed us a msg that was meant for somebody
            // else. This is a server bug.
            print("Server bug caught.");
            return;
         }

         final int id = ack['id'];
         final String msg = ack['msg'];
         final String from = ack['from'];

         // TODO: The logic below is equal for both case. Do not
         // duplicate code, move it into a function.

         // A user message can be either directed to one of the advs
         // published by this app or one that the app is interested
         // in. We distinguish this with the field 'is_sender_adv'
         final bool is_sender_adv = ack['is_sender_adv'];
         if (is_sender_adv) {
            // This message is meant to one of the advs this app
            // selected as favorite. We have to search it and insert
            // this new message in the chat history.
            final int i =
                  _favAdvs.indexWhere((e) { return e.id == id;});

            if (i == -1) {
               // There is a bug in the logic. Fix this.
               print("Logic error. Please fix.");
               return;
            }

            _favAdvs[i].addUnreadMsg(from, msg, false);

         } else {
            // This is a message to our own adv, some interested user.
            // We have to find first which one of our own advs it
            // refers to.

            final int i =
                  _ownAdvs.indexWhere((e) { return e.id == id;});

            if (i == -1) {
               // There is a bug in the logic. Fix this.
               print("Logic error. Please fix.");
               return;
            }

            _ownAdvs[i].addUnreadMsg(from, msg, false);
         }

         setState((){});
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
      List<List<List<int>>> codes = List<List<List<int>>>();
      for (MenuItem item in _menus) {
         List<List<int>> hashCodes =
               readHashCodes(item.root.first, item.filterDepth);

         if (hashCodes.isEmpty) {
            print("====> Menu codes is empty.");
            return;
         }

         codes.add(hashCodes);
      }

      var subCmd = {
         'cmd': 'subscribe',
         'channels': codes,
      };

      final String subText = jsonEncode(subCmd);
      print(subText);
      channel.sink.add(subText);
   }

   // Called when the main tab changes.
   void _tabCtrlChangeHandler()
   {
      // This function is meant to change the tab widgets when we
      // switch tab. This is needed to show the number of unread
      // messages.
      setState(() { });
   }

   int _getNumberOfUnreadChats()
   {
      int i = 0;
      for (AdvData adv in _favAdvs)
         i += adv.getNumberOfUnreadChats();
      for (AdvData adv in _ownAdvs)
         i += adv.getNumberOfUnreadChats();

      return i;
   }

   bool _onOwnAdvsBackPressed()
   {
      print("Implement me");

      if (_chatBotBarIdx == 0 && _currOwnChatIdx != -1) {
         _currOwnChatIdx = -1;
         setState(() { });
         return false;
      }

      return true;
   }

   bool hasLongPressedChat()
   {
      if (_chatBotBarIdx == 0)
         return hasLongPressed(_ownAdvs);
      else
         return hasLongPressed(_favAdvs);
   }

   void _deleteChatEntryDialog(BuildContext context)
   {
      showDialog(
         context: context,
         builder: (BuildContext context)
         {
            final FlatButton ok = FlatButton(
                     child: cts.deleteChatOkText,
                     onPressed: ()
                     {
                        print("ok");
                        Navigator.of(context).pop();
                     });

            final FlatButton cancel = FlatButton(
                     child: cts.deleteChatCancelText,
                     onPressed: ()
                     {
                        print("cancel");
                        Navigator.of(context).pop();
                     });

            List<FlatButton> actions = List<FlatButton>(2);
            actions[0] = ok;
            actions[1] = cancel;

            return AlertDialog(
                  title: cts.deleteChatTitleText,
                  content: Text(""),
                  actions: actions);
         },
      );
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
            List<Card> cards = makeMenuInfoCards(
                                  context,
                                  _advInput,
                                  _menus,
                                  Theme.of(context).primaryColor);

            cards.add(makeCard(makeTextInputFieldCard(_newAdvTextCtrl)));
   
            Widget widget_tmp = makeAdvWidget(
                                   context,
                                   cards,
                                   _onSendNewAdvPressed,
                                   Icon( Icons.publish,
                                        color: Colors.white),
                                   Theme.of(context).primaryColor);

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
                        _onAdvNodePressed
                     );
         }

         AppBar appBar = AppBar(
               title: Text(cts.advAppBarMsg[_botBarIdx],
                           style: TextStyle(color: Colors.white)),
               elevation: 0.7,
               toolbarOpacity : 1.0
         );

         return createBotBarScreen(
                   context,
                   widget,
                   appBar,
                   cts.newAdvTabIcons,
                   cts.newAdvTabNames,
                   _onWillPopMenu,
                   _onNewAdvBotBarTapped,
                   _botBarIdx
                );
      }

      if (_tabCtrl.index == 2 && _currFavChatIdx != -1) {
         // We are in the favorite advs screen, where pressing the
         // chat button in any of the advs leads us to the chat
         // screen with the advertiser.
         final String peer = _favAdvs[_currFavChatIdx].from;
         ChatHistory chatHist =
               _favAdvs[_currFavChatIdx].getChatHistory(peer);
         chatHist.moveToReadHistory();
         return createChatScreen(
                   context,
                   _onWillPopFavChatScreen,
                   chatHist,
                   _newAdvTextCtrl,
                   _onFavChatSendPressed);
      }

      if (_tabCtrl.index == 2 &&
          _currOwnChatIdx != -1 && _ownAdvChatPeer != null) {
         // We are in the chat screen with one interested user on a
         // specific adv.
         ChatHistory chatHist =
               _ownAdvs[_currOwnChatIdx].getChatHistory(_ownAdvChatPeer);
         chatHist.moveToReadHistory();
         return createChatScreen(
                   context,
                   _onWillPopOwnChatScreen,
                   chatHist,
                   _newAdvTextCtrl,
                   _onOwnChatSendPressed);
      }

      Widget filterTabWidget;
      if (_botBarIdx == 2) {
         filterTabWidget = createSendScreen(_sendHahesToServer);
      } else {
         filterTabWidget = createFilterListView(
                             context,
                             _menus[_botBarIdx].root.last,
                             _onFilterLeafNodePressed,
                             _onFilterNodePressed,
                             _menus[_botBarIdx].isFilterLeaf());
      }

      List<Widget> widgets = List<Widget>(cts.tabNames.length);

      widgets[0] = createBotBarScreen(
                      context,
                      filterTabWidget,
                      null,
                      cts.filterTabIcons,
                      cts.filterTabNames,
                      _onWillPopMenu,
                      _onBotBarTapped,
                      _botBarIdx
                   );

      final int newAdvsLength = _unreadAdvs.length;
      if (_tabCtrl.index == 1) {
         _advs.addAll(_unreadAdvs);
         _unreadAdvs.clear();
      }

      // This is the widget of the incoming advs screen.
      widgets[1] = makeAdvTab(context,
                              _advs,
                              _onAdvSelection,
                              _onNewAdv,
                              _menus,
                              newAdvsLength);

      Widget chatWidget;
      if (_chatBotBarIdx == 0) {
         // The own advs tab in the chat screen.
         chatWidget = makeAdvChatTab(
                            context,
                            _ownAdvs,
                            _onOwnAdvChatPressed,
                            _onOwnAdvChatLongPressed,
                            _menus);
      } else {
         // The favorite tab in the chat screen.
         chatWidget = makeAdvChatTab(
                            context,
                            _favAdvs,
                            _onFavChatPressed,
                            _onFavChatLongPressed,
                            _menus);
      }

      widgets[2] = createBotBarScreen(context,
                      chatWidget,
                      null,
                      cts.chatIcons,
                      cts.chatIconTexts,
                      _onOwnAdvsBackPressed,
                      _onChatBotBarTapped,
                      _chatBotBarIdx);


      final int newChats = _getNumberOfUnreadChats();

      List<Widget> actions = List<Widget>();
      if (_tabCtrl.index == 2 && hasLongPressedChat()) {
         IconButton ib = IconButton(
            icon: Icon(Icons.delete, color: Colors.white),
            tooltip: cts.deleteChatStr,
            onPressed: () { _deleteChatEntryDialog(context); });
         actions.add(ib);
      }

      actions.add(Padding(padding: const EdgeInsets.symmetric(horizontal: 5.0)));
      actions.add(Icon(Icons.more_vert, color: Colors.white));

      return Scaffold(
         appBar: AppBar(
            title: Text(cts.appName, style: TextStyle(color:
                        Colors.white)),
            elevation: 0.7,
            bottom: TabBar(
                  controller: _tabCtrl,
                  indicatorColor: Colors.white,
                  tabs: <Widget>[
                     Tab(child: makeTabWidget(context, 0,
                                 cts.tabNames[0])),
                     Tab(child: makeTabWidget(context, newAdvsLength,
                                 cts.tabNames[1])),
                     Tab(child: makeTabWidget(context, newChats,
                                cts.tabNames[2])),
                  ],
            ),
            actions: actions,
         ),
         body: TabBarView(controller: _tabCtrl, children: widgets)
      );
   }

   void _connectToServer(String from)
   {
      // WARNING: localhost or 127.0.0.1 is the emulator or the phone
      // address. The host address is 10.0.2.2.
      channel = IOWebSocketChannel.connect('ws://188.104.195.99:80');
      channel.stream.listen(onWSData,
            onError: onWSError, onDone: onWSDone);

      // This is where we will read the raw menu from files and send
      // our versions to the app. By sending -1 we will always receive
      // back from the server.
      var authCmd = {
         'cmd': 'auth',
         'from': from,
         'menu_versions': <int>[-1, -1],
      };

      final String authText = jsonEncode(authCmd);
      print(authText);
      channel.sink.add(authText);
   }
}

