import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:collection';

import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:flutter/services.dart';
import 'package:device_info/device_info.dart';

import 'package:flutter/material.dart';
import 'package:menu_chat/post.dart';
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

TabBar makeTabBar(List<int> counters, TabController tabCtrl)
{
   List<Widget> tabs = List<Widget>(cts.tabNames.length);

   for (int i = 0; i < tabs.length; ++i)
      tabs[i] = Tab(child: makeTabWidget(counters[i], cts.tabNames[i]));

   return TabBar(controller: tabCtrl,
                 indicatorColor: Colors.white,
                 tabs: tabs);
}

BottomNavigationBar
makeBottomBarItems(List<Icon> icons,
                   List<String> iconLabels,
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
                    title: Text(iconLabels[i]));
   }

   return BottomNavigationBar(
             items: items,
             currentIndex: i,
             onTap: onBotBarTapped);
}

// Returns the widget for the *new post screen*.
Widget createBotBarScreen(
          Widget body,
          BottomNavigationBar bottNavBar)
{
   return Scaffold(
             body: body,
             bottomNavigationBar: bottNavBar);
}

int postIndexHelper(int i)
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
          backgroundColor: Colors.white,
       )
    );
}

Widget makeTabWidget(int n, String title)
{
   if (n == 0)
      return Text(title, style: TextStyle(color: Colors.white));

   List<Widget> widgets = List<Widget>(2);
   widgets[0] = Text(title, style: TextStyle(color: Colors.white));

   // TODO: The container should change from white to the color when
   // it is not focused. 
   // See: https://docs.flutter.io/flutter/material/TabBar/labelColor.html
   widgets[1] = makeCircleUnreadMsgs(n, Colors.white,
                   cts.primaryColor);

   return Row(children: widgets);
}

class MenuChat extends StatefulWidget {
  MenuChat();

  @override
  MenuChatState createState() => MenuChatState();
}

class MenuChatState extends State<MenuChat>
      with SingleTickerProviderStateMixin {
   TabController _tabCtrl;
   ScrollController _scrollCtrl;

   // The id we will use to communicate with the server.
   String _appId = '007';

   // The outermost list is an array with the length equal to the
   // number of menus there are. The inner most list is actually a
   // stack whose first element is the menu root node. When menu
   // entries are selected we push those items on the stack. Used both
   // on the filter and on the postertizement screens.
   List<MenuItem> _menus;

   // The temporary variable used to store the post the user sends.
   PostData _postInput = PostData();

   // The list of posts received from the server. Our own posts that the
   // server echoes back to us (if we are subscribed to the channel)
   // will be filtered out.
   List<PostData> _posts = List<PostData>();
   List<PostData> _unreadPosts = List<PostData>();

   // The list of posts the user found interesting and moved to
   // favorites. They are moved from the list of posts received from
   // the server to this list.
   List<PostData> _favPosts = List<PostData>();

   // Posts the user wrote itself and sent to the server. One issue we
   // have to observe here is that we will send _postInput to the
   // server and if the user is subscribed to the channel the post
   // belongs to, we will receive it back from the server and we
   // should not display it or duplicate it on this list. The posts
   // received from the server will not be inserted here. The only
   // posts inserted here are those that have been acked with ok by the
   // server, before that they will live in the output queue
   // _outPostQueue
   List<PostData> _ownPosts = List<PostData>();

   // Posts sent by the user that have not been acked by the server
   // yet.
   Queue<PostData> _outPostQueue = Queue<PostData>();

   // A flag that is set to true when the floating button (new
   // postertisement) is clicked. It must be carefully set to false
   // when that screens are left.
   bool _onNewPostPressed = false;

   // The index of the tab we are currently in in the *new
   // postertisement screen*. For example 0 for the localization menu,
   // 1 for the models menu etc.
   int _botBarIdx = 0;

   // Stores the last tapped botton bar of *chats* screen. See that
   // without this variable we cannot know which of the two chat
   // screens we are currently in. It should be only used when both
   // _currFavChatIdx and _currFavChatIdx are -1.
   int _chatBotBarIdx = 1;

   // Stores the current chat index in the array _favPosts, -1
   // means we are not in this screen.
   int _currFavChatIdx = -1;

   // Similar to _currFavChatIdx but corresponds to the *my own posts*
   // screen.
   int _currOwnChatIdx = -1;

   // This string will be set to the name of user interested on our
   // post.
   String _ownPostChatPeer;

   // The *new post* text controler
   TextEditingController _newPostTextCtrl = TextEditingController();

   IOWebSocketChannel channel;

   static final DeviceInfoPlugin devInfo = DeviceInfoPlugin();

   MenuChatState()
   {
      Map<String, dynamic> rawMenuMap = jsonDecode(Consts.menus);
      if (rawMenuMap.containsKey('menus')) {
         // TODO: How to deal with a null menu.
         _menus = menuReader(rawMenuMap);
      }

      _onNewPostPressed = false;
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

      _scrollCtrl = ScrollController();

      _tabCtrl.addListener(_tabCtrlChangeHandler);

      readDevInfo();
   }

   void _onPostSelection(PostData data, bool fav)
   {
      if (fav)
         _favPosts.add(data);

      //_ownPosts.add(data);
      _posts.remove(data);
      setState(() { });
   }

   void _onNewPost()
   {
      print("Open menu selection.");
      _onNewPostPressed = true;
      _menus[0].restoreMenuStack();
      _menus[1].restoreMenuStack();
      _botBarIdx = 0;
      //_chatBotBarIdx = 0;
      setState(() { });
   }

   bool _onWillPopMenu()
   {
      if (_menus[_botBarIdx].root.length == 1) {
         _onNewPostPressed = false;
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
      _ownPostChatPeer = null;
      //_currOwnChatIdx = -1;
      setState(() { });
      return false;
   }

   void _onBotBarTapped(int i)
   {
      if ((_botBarIdx + 1) != cts.newPostTabNames.length)
         _menus[_botBarIdx].restoreMenuStack();

      setState(() { _botBarIdx = i; });
   }

   void _onNewPostBotBarTapped(int i)
   {
      // We allow the user to tap backwards to a new tab not forward.
      // This is to avoid complex logic of avoid the publication of
      // imcomplete posts.
      if (i >= _botBarIdx)
         return;

      // The desired tab is *i* the current tab is _botBarIdx. For any
      // tab we land on or walk through we have to restore the menu
      // stack, except for the last tab or any *non-menu* tab that we
      // happen to add.

      // To handle the boundary condition on the last tab.
      if ((_botBarIdx + 1) != cts.newPostTabNames.length)
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

   void _onPostLeafPressed(int i)
   {
      MenuNode o = _menus[_botBarIdx].root.last.children[i];
      _menus[_botBarIdx].root.add(o);
      _onPostLeafReached();
      setState(() { });
   }

   void _onPostLeafReached()
   {
      _postInput.codes[_botBarIdx][0] = _menus[_botBarIdx].root.last.code;
      _menus[_botBarIdx].restoreMenuStack();
      _botBarIdx = postIndexHelper(_botBarIdx);
   }

   void _onPostNodePressed(int i)
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
         _onPostLeafReached();
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

   void _onSendNewPostPressed(bool add)
   {
      _onNewPostPressed = false;

      if (!add) {
         _postInput = PostData();
         _postInput.from = _appId;
         setState(() { });
         return;
      }

      _botBarIdx = 0;
      _postInput.description = _newPostTextCtrl.text;
      _newPostTextCtrl.text = "";

      // Was only useful when the app was not connected in the server.
      // Remove this later.
      //_posts.add(_postInput.clone());

      // We add it here in our own list of posts and keep in mind it
      // will be echoed back to us and have to be filtered out from
      // _posts since that list should not contain our own
      // posts.
      _postInput.from = _appId;
      print(_postInput.from);
      _outPostQueue.add(_postInput.clone());
      _postInput = PostData();

      var pubMap = {
         'cmd': 'publish',
         'from': _outPostQueue.first.from,
         'to': _outPostQueue.first.codes,
         'msg': _outPostQueue.first.description,
      };

      final String pubText = jsonEncode(pubMap);
      print(pubText);
      channel.sink.add(pubText);

      setState(() { });
   }

   // This function is called with the index in _favPosts.
   void _onFavChatPressed(int i, int j)
   {
      assert(j == 0);
      _currFavChatIdx = i;
      setState(() { });
   }

   void _onFavChatLongPressed(int i, int j)
   {
      assert(j == 0);
      final bool old = _favPosts[i].chats[0].isLongPressed;
      _favPosts[i].chats[0].isLongPressed = !old;
      setState(() { });
   }

   void _onOwnPostChatPressed(int i, int j)
   {
      _currOwnChatIdx = i;
     _ownPostChatPeer = _ownPosts[i].chats[j].peer;

      setState(() { });
   }

   void _onOwnPostChatLongPressed(int i, int j)
   {
      final bool old = _ownPosts[i].chats[j].isLongPressed;
      _ownPosts[i].chats[j].isLongPressed = !old;
      setState(() { });
      print("_onOwnPostChatLongPressed");
   }

   void _onFavChatSendPressed()
   {
      if (_newPostTextCtrl.text.isEmpty)
         return;

      final String msg = _newPostTextCtrl.text;
      _newPostTextCtrl.text = "";

      final String to = _favPosts[_currFavChatIdx].from;

      var msgMap = {
         'cmd': 'user_msg',
         'from': _appId,
         'to': to,
         'msg': msg,
         'post_id': _favPosts[_currFavChatIdx].id,
         'is_sender_post': false,
      };

      final String payload = jsonEncode(msgMap);
      print(payload);
      channel.sink.add(payload);

      _favPosts[_currFavChatIdx].addMsg(to, msg, true);
      setState(() { });
   }

   void _onOwnChatSendPressed()
   {
      if (_newPostTextCtrl.text.isEmpty)
         return;

      final String msg = _newPostTextCtrl.text;
      _newPostTextCtrl.text = "";

      var msgMap = {
         'cmd': 'user_msg',
         'from': _appId,
         'to': _ownPostChatPeer,
         'msg': msg,
         'post_id': _ownPosts[_currOwnChatIdx].id,
         'is_sender_post': true,
      };

      final String payload = jsonEncode(msgMap);
      print(payload);
      channel.sink.add(payload);

      _ownPosts[_currOwnChatIdx].addMsg(_ownPostChatPeer, msg, true);
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

      //print("Received from server: ${ack}");

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

         PostData post = PostData();
         post.from = from;
         post.description = msg;
         post.codes = codes;
         post.id = id;

         // Since this post is not from this app we have to add a chat
         // entry in it.
         post.createChatEntryForPeer(post.from);

         _unreadPosts.add(post);

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

         _outPostQueue.first.id = ack['id'];

         assert(!_outPostQueue.isEmpty);
         _ownPosts.add(_outPostQueue.removeFirst());
      }

      if (cmd == "user_msg") {
         final String to = ack['to'];
         if (to != _appId) {
            // The server routed us a msg that was meant for somebody
            // else. This is a server bug.
            print("Server bug caught.");
            return;
         }

         final int post_id = ack['post_id'];
         final String msg = ack['msg'];
         final String from = ack['from'];

         // TODO: The logic below is equal for both case. Do not
         // duplicate code, move it into a function.

         // A user message can be either directed to one of the posts
         // published by this app or one that the app is interested
         // in. We distinguish this with the field 'is_sender_post'
         final bool is_sender_post = ack['is_sender_post'];
         if (is_sender_post) {
            // This message is meant to one of the posts this app
            // selected as favorite. We have to search it and insert
            // this new message in the chat history.
            final int i =
               _favPosts.indexWhere((e) { return e.id == post_id;});

            if (i == -1) {
               // There is a bug in the logic. Fix this.
               print("Logic error. Please fix.");
               return;
            }

            _favPosts[i].addUnreadMsg(from, msg, false);

         } else {
            // This is a message to our own post, some interested user.
            // We have to find first which one of our own posts it
            // refers to.

            final int i =
               _ownPosts.indexWhere((e) { return e.id == post_id;});

            if (i == -1) {
               // There is a bug in the logic. Fix this.
               print("Logic error. Please fix.");
               return;
            }

            _ownPosts[i].addUnreadMsg(from, msg, false);
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
      for (PostData post in _favPosts)
         i += post.getNumberOfUnreadChats();
      for (PostData post in _ownPosts)
         i += post.getNumberOfUnreadChats();

      return i;
   }

   bool _onOwnPostsBackPressed()
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
         return hasLongPressed(_ownPosts);
      else
         return hasLongPressed(_favPosts);
   }

   void _removeLongPressedChatEntries()
   {
      assert(_tabCtrl.index == 2);
      if (_chatBotBarIdx == 0) {
         for (PostData post in _ownPosts)
            post.removeLongPressedChats();

         // TODO: Should the whole post be removed if after this
         // action it became empty or should we keep it. If we remove
         // it and a user sends a message to this chat it will have to
         // be ignored.
         setState(() { });
      } else {
         for (PostData post in _favPosts)
            post.removeLongPressedChats();

         _favPosts.removeWhere((e) { return e.chats.isEmpty; });

         setState(() { });
      }
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
                        _removeLongPressedChatEntries();
                        Navigator.of(context).pop();
                     });

            final FlatButton cancel = FlatButton(
                     child: cts.deleteChatCancelText,
                     onPressed: ()
                     {
                        Navigator.of(context).pop();
                     });

            List<FlatButton> actions = List<FlatButton>(2);
            actions[0] = cancel;
            actions[1] = ok;

            Text txt = cts.delOwnChatTitleText;
            if (_chatBotBarIdx == 1) {
               txt = cts.delFavChatTitleText;
            }

            return AlertDialog(
                  title: txt,
                  content: Text(""),
                  actions: actions);
         },
      );
   }

   @override
   void dispose()
   {
     _newPostTextCtrl.dispose();
     _tabCtrl.dispose();
     _scrollCtrl.dispose();

     super.dispose();
   }

   @override
   Widget build(BuildContext context)
   {
      if (_onNewPostPressed) {
         Widget widget;
         if (_botBarIdx == 2) {
            List<Card> cards = makeMenuInfoCards(
                                  context,
                                  _postInput,
                                  _menus,
                                  Theme.of(context).primaryColor);

            cards.add(makeCard(makeTextInputFieldCard(_newPostTextCtrl)));
   
            Widget widget_tmp = makePostWidget(
                                   context,
                                   cards,
                                   _onSendNewPostPressed,
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
            widget = createPostMenuListView(
                        context,
                        _menus[_botBarIdx].root.last,
                        _onPostLeafPressed,
                        _onPostNodePressed
                     );
         }

         AppBar appBar = AppBar(
               title: Text(cts.postAppBarMsg[_botBarIdx],
                           style: TextStyle(color: Colors.white)),
               elevation: 0.7,
               toolbarOpacity : 1.0
         );

         return WillPopScope(
                   onWillPop: () async { return _onWillPopMenu();},
                   child: Scaffold(
                             appBar: appBar,
                             body: widget,
                             bottomNavigationBar:
                                makeBottomBarItems(
                                   cts.newPostTabIcons,
                                   cts.newPostTabNames,
                                   _onNewPostBotBarTapped,
                                   _botBarIdx)));
      }

      if (_tabCtrl.index == 2 && _currFavChatIdx != -1) {
         // We are in the favorite posts screen, where pressing the
         // chat button in any of the posts leads us to the chat
         // screen with the postertiser.
         final String peer = _favPosts[_currFavChatIdx].from;
         ChatHistory chatHist =
               _favPosts[_currFavChatIdx].getChatHistory(peer);
         chatHist.moveToReadHistory();
         return createChatScreen(
                   context,
                   _onWillPopFavChatScreen,
                   chatHist,
                   _newPostTextCtrl,
                   _onFavChatSendPressed);
      }

      if (_tabCtrl.index == 2 &&
          _currOwnChatIdx != -1 && _ownPostChatPeer != null) {
         // We are in the chat screen with one interested user on a
         // specific post.
         ChatHistory chatHist =
               _ownPosts[_currOwnChatIdx].getChatHistory(_ownPostChatPeer);
         chatHist.moveToReadHistory();
         return createChatScreen(
                   context,
                   _onWillPopOwnChatScreen,
                   chatHist,
                   _newPostTextCtrl,
                   _onOwnChatSendPressed);
      }

      List<Widget> bodies =
            List<Widget>(cts.tabNames.length);

      List<FloatingActionButton> fltButtons =
            List<FloatingActionButton>(cts.tabNames.length);

      List<BottomNavigationBar> bottBars =
            List<BottomNavigationBar>(cts.tabNames.length);

      List<Function> onWillPops =
            List<Function>(cts.tabNames.length);

      if (_botBarIdx == 2) {
         bodies[0] = createSendScreen(_sendHahesToServer);
      } else {
         bodies[0] = createFilterListView(
                        context,
                        _menus[_botBarIdx].root.last,
                        _onFilterLeafNodePressed,
                        _onFilterNodePressed,
                        _menus[_botBarIdx].isFilterLeaf(),
                        _scrollCtrl);
      }

      fltButtons[0] = null;

      bottBars[0] = makeBottomBarItems(
                       cts.filterTabIcons,
                       cts.filterTabNames,
                       _onBotBarTapped,
                       _botBarIdx);

      onWillPops[0] = _onWillPopMenu;

      final int newPostsLength = _unreadPosts.length;
      if (_tabCtrl.index == 1) {
         _posts.addAll(_unreadPosts);
         _unreadPosts.clear();
      }

      bodies[1] = makePostTabListView(context,
                                      _posts,
                                      _onPostSelection,
                                      _menus,
                                      newPostsLength);

      fltButtons[1] = makeNewPostButton(_onNewPost);
      bottBars[1] = null;
      onWillPops[1] = (){return false;};

      if (_chatBotBarIdx == 0) {
         // The own posts tab in the chat screen.
         bodies[2] = makePostChatTab(
                        context,
                        _ownPosts,
                        _onOwnPostChatPressed,
                        _onOwnPostChatLongPressed,
                        _menus);
      } else {
         // The favorite tab in the chat screen.
         bodies[2] = makePostChatTab(
                        context,
                        _favPosts,
                        _onFavChatPressed,
                        _onFavChatLongPressed,
                        _menus);
      }

      fltButtons[2] = null;

      bottBars[2] = makeBottomBarItems(
                       cts.chatIcons,
                       cts.chatIconTexts,
                       _onChatBotBarTapped,
                       _chatBotBarIdx);

      onWillPops[2] = _onOwnPostsBackPressed;

      List<Widget> widgets = List<Widget>(bodies.length);
      for (int i = 0; i < widgets.length; ++i) {
         widgets[i] = WillPopScope(
                         onWillPop: () async { return onWillPops[i]();},
                         child: createBotBarScreen(
                                   bodies[i], bottBars[i]));
      }

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

      List<int> newMsgsCounters = List<int>(cts.tabNames.length);
      newMsgsCounters[0] = 0;
      newMsgsCounters[1] = newPostsLength;
      newMsgsCounters[2] = newChats;

      return Scaffold(
        body: NestedScrollView(
                 controller: _scrollCtrl,
                 headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
                   return <Widget>[
                     SliverAppBar(
                       title: Text(cts.appName, style: TextStyle(color: Colors.white)),
                       pinned: true,
                       floating: true,
                       forceElevated: innerBoxIsScrolled,
                       bottom: makeTabBar(newMsgsCounters, _tabCtrl),
                     ),
                   ];
                 },
                 body: TabBarView(controller: _tabCtrl, children: widgets),
          ),
          backgroundColor: Colors.white,
          floatingActionButton: fltButtons[_tabCtrl.index],
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

