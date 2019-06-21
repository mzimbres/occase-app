import 'dart:async';
import 'dart:convert';
import 'dart:io' show File, FileMode, Directory;
import 'dart:collection';

import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:flutter/services.dart';
import 'package:device_info/device_info.dart';
import 'package:flutter/scheduler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

import 'package:flutter/material.dart';
import 'package:menu_chat/post.dart';
import 'package:menu_chat/menu.dart';
import 'package:menu_chat/menu_tree.dart';
import 'package:menu_chat/constants.dart';
import 'package:menu_chat/text_constants.dart' as cts;
import 'package:menu_chat/globals.dart' as glob;

class Coord {
   Post post = null;
   Chat chat = null;
   int msgIdx = -1;
   Coord(this.post, this.chat, this.msgIdx);
}

void myprint(Coord c, String prefix)
{
   print('$prefix ===> (${c.post.id}, ${c.chat.peer}, ${c.msgIdx})');
}

bool CompPostIdAndPeer(Coord a, Coord b)
{
   return a.post.id == b.post.id && a.chat.peer == b.chat.peer;
}

bool CompPeerAndChatIdx(Coord a, Coord b)
{
   return a.chat.peer == b.chat.peer && a.msgIdx == b.msgIdx;
}

void
handleLPChats(List<Coord> pairs, bool old, Coord coord, Function comp)
{
   if (old) {
      pairs.removeWhere((e) {return comp(e, coord);});
   } else {
      pairs.add(coord);
   }
}

void toggleLPChats(List<Coord> coords)
{
   for (Coord c in coords) {
      myprint(c, '');
      toggleLPChat(c.chat);
   }
}

Future<void> removeLPChats(List<Coord> coords) async
{
   for (Coord c in coords) {
      final int j = c.post.getChatHistIdx(c.chat.peer);
      assert(j != -1);
      await c.post.removeLPChats(j);
   }
}

void unmarkLPChatMsgsImpl(List<Coord> lpChatMsgs)
{
   for (Coord o in lpChatMsgs)
      toggleLPChatMsg(o.chat.msgs[o.msgIdx]);
}

Future<void>
onPinPost(List<Post> posts, int i, Database db) async
{
   if (posts[i].pinDate == 0) {
      posts[i].pinDate = DateTime.now().millisecondsSinceEpoch;
   } else {
      posts[i].pinDate = 0;
   }

   await db.execute(cts.updatePostPinDate,
                    [posts[i].pinDate, posts[i].id]);

   posts.sort(CompPosts);
}

Future<void>
onRemovePost(List<Post> posts, int i, Database db) async
{
   await db.execute(cts.deletePost, [posts[i].id]);
   posts.removeAt(i);
}

Future<Null> main() async
{
  runApp(MyApp());
}

class ChatMsgOutQueueElem {
   int isChat = 0;
   String payload = '';
   ChatMsgOutQueueElem(this.isChat, this.payload);
}

String accumulateChatMsgs(final Queue<ChatMsgOutQueueElem> data)
{
   String str = '';
   for (ChatMsgOutQueueElem o in data)
      str += '${o.isChat} ${o.payload}\n';

   return str;
}

Future<List<Post>> decodePostsStr(final List<String> lines) async
{
   List<Post> foo = List<Post>();

   for (String o in lines) {
      Map<String, dynamic> map = jsonDecode(o);
      Post tmp = Post.fromJson(map);
      await tmp.loadChats();
      foo.add(tmp);
   }

   return foo;
}

String makePostPayload(final Post post)
{
   var pubMap = {
      'cmd': 'publish',
      'items': <Post>[post]
   };

   return jsonEncode(pubMap);
}

String makeLoginCmd( final String id
                    , final String pwd
                    , final List<int> versions)
{
   var loginCmd = {
      'cmd': 'login',
      'user': id,
      'password': pwd,
      'menu_versions': versions,
   };

   return jsonEncode(loginCmd);
}

String makeRegisterCmd()
{
   var loginCmd = {'cmd': 'register'};
   return jsonEncode(loginCmd);
}

List<Widget>
makeOnLongPressedActions(BuildContext ctx,
                         Function deleteChatEntryDialog,
                         Function pinChat)
{
   List<Widget> actions = List<Widget>();

   IconButton pinChatBut = IconButton(
      icon: Icon(Icons.place, color: Colors.white),
      tooltip: cts.pinChatStr,
      onPressed: pinChat);

   actions.add(pinChatBut);

   IconButton delChatBut = IconButton(
      icon: Icon(Icons.delete_forever, color: Colors.white),
      tooltip: cts.deleteChatStr,
      onPressed: () { deleteChatEntryDialog(ctx); });

   actions.add(delChatBut);

   // Block user button.
   //IconButton blockUserBut = IconButton(
   //   icon: Icon(Icons.block, color: Colors.white),
   //   tooltip: cts.blockUserChatStr,
   //   onPressed: () { print('Kabuff'); });

   //actions.add(blockUserBut);

   return actions;
}

Scaffold
makeNickRegisterScreen( TextEditingController txtCtrl
                      , Function onNickPressed)
{
   TextField tf =
      makeTextInputFieldCard(
         txtCtrl,
         null,
         InputDecoration(
            hintText: cts.nichTextFieldHintStr,
            hintStyle: TextStyle(fontSize: 25.0,
              fontWeight: FontWeight.normal)));

   Padding padd =
      Padding( child: tf
             , padding: EdgeInsets.all(20.0));

   RaisedButton but =
      RaisedButton(
         child: Text( 'Continuar'
                    , style: TextStyle(
                         color: Colors.white,
                         fontWeight: FontWeight.bold,
                         fontSize: 18.0)),
         color: Colors.blue,
         onPressed: onNickPressed
         );

   Column col =
      Column( mainAxisAlignment: MainAxisAlignment.center
            , crossAxisAlignment: CrossAxisAlignment.center
            , children: <Widget>
              [ padd
              , but
              ]);

   return Scaffold(body: Center(child: col));
}

ListView
makeNewPostFinalScreenWidget( BuildContext ctx
                            , Post post
                            , final List<MenuItem> menu
                            , TextEditingController txtCtrl
                            , onSendNewPostPressed)
{
   List<Card> cards =
      makeMenuInfoCards(ctx, post, menu, Theme.of(ctx).primaryColor);

   cards.add(makePostDetailElem(post.filter));
   cards.add(
      makeCard(
         makeTextInputFieldCard(
            txtCtrl,
            null,
            InputDecoration.collapsed(
               hintText: cts.newPostTextFieldHistStr)),
         cts.postLocHeaderColor));

   Widget widget_tmp =
      makePostWidget( ctx
                    , cards
                    , (final int add) { onSendNewPostPressed(ctx, add); }
                    , Icon(Icons.publish, color: Colors.white)
                    , cts.postFrameColor);

   // FIXME: I added this ListView to prevent widget_tmp from
   // extending the whole screen. Inside the ListView it appears
   // compact. Remove this later.
   return ListView(
      shrinkWrap: true,
      //padding: const EdgeInsets.all(20.0),
      children: <Widget>[widget_tmp]
   );
}

WillPopScope
makeNewPostScreens( BuildContext ctx
                  , Post postInput
                  , final List<MenuItem> menu
                  , TextEditingController txtCtrl
                  , onSendNewPostPressed
                  , int screen
                  , Function onNewPostDetail
                  , Function onPostLeafPressed
                  , Function onPostNodePressed
                  , Function onWillPopMenu
                  , Function onNewPostBotBarTapped)
{
   Widget wid;
   if (screen == 3) {
      wid = makeNewPostFinalScreenWidget(
               ctx,
               postInput,
               menu,
               txtCtrl,
               onSendNewPostPressed);

   } else if (screen == 2) {
      wid = makePostDetailScreen(
               ctx,
               onNewPostDetail,
               postInput.filter,
               1);
   } else {
      wid = createPostMenuListView(
               ctx,
               menu[screen].root.last,
               onPostLeafPressed,
               onPostNodePressed);
   }

   AppBar appBar = AppBar(
         title: Text(cts.postAppBarMsg[screen],
                     style: TextStyle(color: Colors.white)),
         elevation: 0.7,
         toolbarOpacity : 1.0,
         leading: IconButton( icon: Icon( Icons.arrow_back
                                        , color: Colors.white)
                            , onPressed: onWillPopMenu)
   );

   return WillPopScope(
             onWillPop: () async { return onWillPopMenu();},
             child: Scaffold(
                       appBar: appBar,
                       body: wid,
                       bottomNavigationBar:
                          makeBottomBarItems(
                             cts.newPostTabIcons,
                             cts.newPostTabNames,
                             onNewPostBotBarTapped,
                             screen)));
}

WillPopScope
makeNewFiltersScreens( BuildContext ctx
                     , Function onSendFilters
                     , Function onFilterDetail
                     , Function onFilterNodePressed
                     , Function onWillPopMenu
                     , Function onBotBarTaped
                     , Function onFilterLeafNodePressed
                     , final List<MenuItem> menu
                     , int filter
                     , int screen)
{
   Widget wid;
   String appBarTitle = cts.filterTabNames[screen];
   if (screen == 3) {
      wid = createSendScreen((){onSendFilters(ctx);}, 'Enviar');
   } else if (screen == 2) {
      wid = makePostDetailScreen(
               ctx,
               onFilterDetail,
               filter,
               0);
   } else {
      if (menu[screen].root.length > 1)
         appBarTitle = menu[screen].root.last.name;

      wid = createFilterListView(
               ctx,
               menu[screen].root.last,
               onFilterLeafNodePressed,
               onFilterNodePressed,
               menu[screen].isFilterLeaf());
   }

   AppBar appBar = AppBar(
         title: Text(appBarTitle,
                     style: TextStyle(color: Colors.white)),
         elevation: 0.7,
         toolbarOpacity : 1.0,
         leading: IconButton( icon: Icon( Icons.arrow_back
                                        , color: Colors.white)
                            , onPressed: onWillPopMenu)
   );

   return WillPopScope(
       onWillPop: () async { return onWillPopMenu();},
       child: Scaffold(
           appBar: appBar,
           body: wid,
           bottomNavigationBar: makeBottomBarItems(
              cts.filterTabIcons,
              cts.filterTabNames,
              onBotBarTaped,
              screen)));
}

ListView
makePostDetailScreen( BuildContext ctx
                    , Function proceed
                    , int filter
                    , int shift)
{
   return ListView.builder(
      padding: const EdgeInsets.all(3.0),
      itemCount: cts.postDetails.length + shift,
      itemBuilder: (BuildContext ctx, int i)
      {
         if (i == cts.postDetails.length)
            return createSendScreen((){proceed(i);}, 'Continuar');

         bool v = ((filter & (1 << i)) != 0);
         Color color = Theme.of(ctx).primaryColor;
         if (v)
            color = cts.selectedMenuColor;

         return CheckboxListTile(
            dense: true,
            secondary:
               makeCircleAvatar(
                  Text( cts.postDetails[i].substring(0, 2)
                      , style: cts.abbrevStl),
                  color),
            title: Text(cts.postDetails[i]),
            value: v,
            onChanged: (bool v) { proceed(i); },
            activeColor: color,
         );
      },
   );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext ctx) {
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

TabBar
makeTabBar(List<int> counters,
           TabController tabCtrl,
           List<double> opacity,
           bool isFwd)
{
   if (isFwd)
      return null;

   List<Widget> tabs = List<Widget>(cts.tabNames.length);

   for (int i = 0; i < tabs.length; ++i) {
      tabs[i] = Tab(
         child: makeTabWidget(
            counters[i], cts.tabNames[i], opacity[i]));
   }

   return TabBar(controller: tabCtrl,
                 indicatorColor: Colors.white,
                 tabs: tabs);
}

BottomNavigationBar
makeBottomBarItems(List<IconData> icons,
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
                    icon: Icon(icons[i]),
                    title: Text(iconLabels[i]));
   }

   return BottomNavigationBar(
             items: items,
             type: BottomNavigationBarType.fixed,
             currentIndex: i,
             onTap: onBotBarTapped);
}

FloatingActionButton
makeFiltersFaButton(Function onNewPost, IconData id)
{
   return FloatingActionButton(
             backgroundColor: cts.postFrameColor,
             child: Icon(id, color: Colors.white),
             onPressed: onNewPost);
}

FloatingActionButton
makeFaButton(Function onNewPost,
             Function onFwdChatMsg,
             int lpChats,
             int lpChatMsgs)
{
   if (lpChats == 0 && lpChatMsgs != 0)
      return null;

   IconData id = cts.newPostIcon;
   if (lpChats != 0 && lpChatMsgs != 0) {
      return FloatingActionButton(
         backgroundColor: cts.postFrameColor,
         child: Icon(Icons.send, color: Colors.white),
         onPressed: onFwdChatMsg);
   }

   if (lpChats != 0)
      return null;

   if (onNewPost == null)
      return null;

   return FloatingActionButton(
      backgroundColor: cts.postFrameColor,
      child: Icon(id, color: Colors.white),
      onPressed: onNewPost);
}

int postIndexHelper(int i)
{
   if (i == 0) return 1;
   if (i == 1) return 2;
   if (i == 2) return 3;
   return 1;
}

ListView
makeChatMsgListView(
   BuildContext ctx,
   ScrollController scrollCtrl,
   Chat ch,
   onChatSendPressed,
   onChatMsgLongPressed)
{
   final int nMsgs = ch.msgs.length;
   final int nUnreadMsgs = ch.getNumberOfUnreadMsgs();
   final int shift = nUnreadMsgs == 0 ? 0 : 1;

   return ListView.builder(
      controller: scrollCtrl,
      reverse: false,
      //padding: const EdgeInsets.all(6.0),
      itemCount: nMsgs + shift,
      itemBuilder: (BuildContext ctx, int i)
      {
         List<ChatItem> items = ch.msgs;
         if (shift == 1) {
            if (i == nMsgs - nUnreadMsgs) {
               return Card(
                  color: cts.postFrameColor,
                  margin: const EdgeInsets.all(12.0),
                  child: Center(
                      child: Text(
                         '$nUnreadMsgs nao lidas.',
                         style: TextStyle(fontSize: 17.0))));
            }

            if (i > (nMsgs - nUnreadMsgs)) {
               i -= 1; // For the shift
            }
         }

         Alignment align = Alignment.bottomLeft;
         Color color = Color(0xFFFFFFFF);
         Color onSelectedMsgColor = Colors.grey[300];
         if (items[i].thisApp) {
            align = Alignment.bottomRight;
            color = Colors.lightGreenAccent[100];
         }

         if (items[i].isLongPressed) {
            onSelectedMsgColor = Colors.blue[100];
         }

         double width = 300.0;
         if (items[i].msg.length < 10)
            width = 150.0;
         else if (items[i].msg.length < 20)
            width = 200.0;

         Widget msgAndStatus;
         if (items[i].thisApp) {
            final int st =  items[i].status;
            Align foo =
               Align(alignment: Alignment.bottomRight,
                     child: chooseIcon(st));

            msgAndStatus = Row(children: <Widget>
            [ Expanded(child: Text(items[i].msg))
            , foo]);
         } else {
            msgAndStatus = Text(items[i].msg);
         }

         final Radius rd = const Radius.circular(45.0);
         Container cont = Container(
             margin: const EdgeInsets.all(5.0),
             padding: const EdgeInsets.all(5.0),
             constraints: BoxConstraints(maxWidth: width),
             decoration:
                BoxDecoration(
                   color: onSelectedMsgColor,
                   borderRadius:
                      BorderRadius.only(
                         topLeft:  rd,
                         topRight: rd,
                         bottomLeft: rd,
                         bottomRight: rd)),
               child: Card(
                  child: Padding(
                     padding: const EdgeInsets.all(2.0),
                        child: Center(widthFactor: 1.0, child: msgAndStatus)),
                        elevation: 0.0,
                        color: color,
                     ));

         Row r = null;
         if (items[i].thisApp) {
            r = Row(children: <Widget>
            [ Spacer()
            , cont
            ]);
         } else {
            r = Row(children: <Widget>
            [ cont
            , Spacer()
            ]);
         }

         return GestureDetector(
            onLongPress: () {onChatMsgLongPressed(i, false);},
            onTap: () {onChatMsgLongPressed(i, true);},
            onPanStart: (DragStartDetails d){print('Cool');},
            child: Card(child: r, color: onSelectedMsgColor,
               elevation: 0.0,
               margin: const EdgeInsets.all(0.0),
               shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(0.0))))
            );
      },
   );
}

Widget
makeChatScreen(BuildContext ctx,
               Function onWillPopScope,
               Chat ch,
               TextEditingController ctrl,
               Function onChatSendPressed,
               ScrollController scrollCtrl,
               Function onChatMsgLongPressed,
               int nLongPressed,
               Function onFwdChatMsg)
{
   IconButton sendButCol =
      IconButton(
         icon: Icon(Icons.send),
         onPressed: onChatSendPressed,
         color: Theme.of(ctx).primaryColor
         );

   TextField tf = TextField(
       controller: ctrl,
       //textInputAction: TextInputAction.go,
       //onSubmitted: onTextFieldPressed,
       keyboardType: TextInputType.multiline,
       maxLines: null,
       maxLength: null,
       decoration:
          InputDecoration.collapsed( hintText: cts.chatTextFieldHintStr));

   Container cont = Container(
       child: ConstrainedBox(
           constraints: BoxConstraints(maxHeight: 100.0),
           child: Row(children: <Widget>
              [ Expanded( child: Column(children: <Widget>
                  [ Expanded(child: Scrollbar(
                     child: SingleChildScrollView(
                         //padding: EdgeInsets.all(10.0),
                         scrollDirection: Axis.vertical,
                         reverse: true,
                         child: Card(
                            margin: EdgeInsets.all(0.0),
                            color: Colors.white,
                            child: Padding(
                               padding: EdgeInsets.all(14.0),
                               child: tf))))),
                    
                    ]))
              , Column(children: <Widget>
                    [ Spacer()
                    , sendButCol])
              ])),
   );

   ListView list = makeChatMsgListView(
         ctx,
         scrollCtrl,
         ch,
         onChatSendPressed,
         onChatMsgLongPressed,
         );

   Column mainCol = Column(
         children: <Widget>[
            Expanded(child: list),
            cont
         ],
   );

   List<Widget> actions = List<Widget>();
   Widget title = null;
   TextStyle ts = TextStyle(
       fontWeight: FontWeight.bold,
       fontSize: cts.mainFontSize,
       color: Color(0xFFFFFFFF));

   if (nLongPressed != 0) {
      IconButton reply = IconButton(
         icon: Icon(Icons.reply, color: Colors.white),
         onPressed: (){print('------');});

      actions.add(reply);

      IconButton forward = IconButton(
         icon: Icon(Icons.forward, color: Colors.white),
         onPressed: onFwdChatMsg);

      actions.add(forward);

      title = Text('$nLongPressed', style: ts);
   } else {
      title = ListTile(
          leading: CircleAvatar(
              child: cts.unknownPersonIcon,
              backgroundColor: Colors.grey),
          title: Text(ch.getChatDisplayName(), style: ts),
          dense: true,
          //subtitle: subtitle
       );
   }

   return WillPopScope(
          onWillPop: () async { return onWillPopScope();},
          child: Scaffold(
             appBar : AppBar(
                actions: actions,
                title: title,
                backgroundColor: Theme.of(ctx).primaryColor,
                leading: IconButton(
                   icon: Icon(Icons.arrow_back,
                              color: Colors.white),
                 onPressed: onWillPopScope)
             ),
          body: mainCol,
          backgroundColor: Colors.grey[300],
       )
    );
}

Widget makeTabWidget(int n, String title, double opacity)
{
   if (n == 0)
      return Text(title);

   List<Widget> widgets = List<Widget>(2);
   widgets[0] = Text(title);

   // See: https://docs.flutter.io/flutter/material/TabBar/labelColor.html
   // for opacity values.
   widgets[1] =
      Opacity( child: makeCircleUnreadMsgs(n, Colors.white,
                      cts.primaryColor)
             , opacity: opacity);

   return Row(children: widgets);
}

//_____________________________________________________________________

class DialogWithOp extends StatefulWidget {
   DialogWithOp( this.idx
               , this.getValueFunc
               , this.setValueFunc
               , this.onPostSelection
               , this.title
               , this.body);

   int idx = 0;
   Function getValueFunc;
   Function setValueFunc;
   Function onPostSelection;
   String title;
   String body;

   @override
   DialogWithOpState createState() => DialogWithOpState();
}

class DialogWithOpState extends State<DialogWithOp> {
   int _idx = 0;
   Function _getValueFunc;
   Function _setValueFunc;
   Function _onPostSelection;
   String _title;
   String _body;
   
   @override
   void initState()
   {
      _idx = widget.idx;
      _getValueFunc = widget.getValueFunc;
      _setValueFunc = widget.setValueFunc;
      _onPostSelection = widget.onPostSelection;
      _title = widget.title;
      _body = widget.body;

      super.initState();
   }

   @override
   Widget build(BuildContext ctx)
   {
      final SimpleDialogOption ok =
         SimpleDialogOption(
            child:
               Text('Ok'
                   , style: TextStyle( color: Colors.blue
                                     , fontSize: 16.0)),
            onPressed: () async
            {
               await _onPostSelection();
               Navigator.of(ctx).pop();
            });

      final SimpleDialogOption cancel =
         SimpleDialogOption(
            child:
               Text('Cancelar'
                   , style: TextStyle( color: Colors.blue
                                     , fontSize: 16.0)),
            onPressed: ()
            {
               Navigator.of(ctx).pop();
            });

      List<SimpleDialogOption> actions =
            List<SimpleDialogOption>(2);
      actions[0] = cancel;
      actions[1] = ok;

      Row row =
         Row(children: <Widget>
            [Icon(Icons.check_circle_outline, color: Colors.red)]);

      CheckboxListTile tile = CheckboxListTile(
                title: Text('Nao mostrar novamente'),
                value: !_getValueFunc(),
                onChanged: (bool v)
                           {
                              print(v);
                              _setValueFunc(!v);
                              setState(() { });
                           },
                controlAffinity: ListTileControlAffinity.leading
                );

      return SimpleDialog(
             title: Text(_title),
             children: <Widget>
             [ Padding( child: Center(child:
                           Text( _body
                               , style: TextStyle(fontSize: 16.0)))
                      , padding: EdgeInsets.all(25.0))
             , tile
             , Padding( child: Row(children: actions)
                      , padding: EdgeInsets.only(left: 105.0))
                           
             ]);
   }
}

class Config {
   String appId = '';
   String appPwd = '';
   String nick = '';
   int lastPostId = 0;
   int lastSeenPostId = 0;
   String showDialogOnSelectPost = 'yes';
   String showDialogOnDelPost = 'yes';

   Config();
}

Map<String, dynamic> configToMap(Config cfg)
{
    return {
      'app_id': cfg.appId,
      'app_pwd': cfg.appPwd,
      'nick': cfg.nick,
      'last_post_id': cfg.lastPostId,
      'last_seen_post_id': cfg.lastSeenPostId,
      'show_dialog_on_select_post': cfg.showDialogOnSelectPost,
      'show_dialog_on_del_post': cfg.showDialogOnDelPost,
    };
}

Future<List<Config>> loadConfig(Database db, String tableName) async
{
  final List<Map<String, dynamic>> maps =
     await db.query(tableName);

  return List.generate(maps.length, (i)
  {
     Config cfg = Config();
     cfg.appId = maps[i]['app_id'];
     cfg.appPwd = maps[i]['app_pwd'];
     cfg.nick = maps[i]['nick'];
     cfg.lastPostId = maps[i]['last_post_id'];
     cfg.lastSeenPostId = maps[i]['last_seen_post_id'];
     cfg.showDialogOnSelectPost = maps[i]['show_dialog_on_select_post'];
     cfg.showDialogOnDelPost = maps[i]['show_dialog_on_del_post'];

     return cfg;
  });
}

//_____________________________________________________________________

class MenuChat extends StatefulWidget {
  MenuChat();

  @override
  MenuChatState createState() => MenuChatState();
}

class MenuChatState extends State<MenuChat>
      with SingleTickerProviderStateMixin {
   TabController _tabCtrl;
   ScrollController _scrollCtrl = ScrollController();
   ScrollController _chatScrollCtrl = ScrollController();

   Config cfg = Config();

   // Array with the length equal to the number of menus there
   // are. Used both on the filter and on the *new post* screens.
   List<MenuItem> _menus = List<MenuItem>();

   // The temporary variable used to store the post the user sends or
   // the post the current chat screen belongs to, if any.
   Post _post = null;

   // The list of posts received from the server. Our own posts that the
   // server echoes back to us (if we are subscribed to the channel)
   // will be filtered out.
   List<Post> _posts = List<Post>();

   // The list of posts the user has selected in the posts screen.
   // They are moved from _posts to here.
   List<Post> _favPosts = List<Post>();

   // Posts the user wrote itself and sent to the server. One issue we
   // have to observe is that if the user is subscribed to the channel
   // the post belongs to, it will be received back and shouldn't be
   // displayed or duplicated on this list. The posts received from
   // the server will not be inserted in _posts.
   //
   // The only posts inserted here are those that have been acked with
   // ok by the server, before that they will live in _outPostsQueue
   List<Post> _ownPosts = List<Post>();

   // Posts sent to the server that haven't been acked yet. I found it
   // easier to have this list. For example, if the user sends more
   // than one post while the app is offline we do not have to search
   // _ownPosts to set the post id in the correct order. It is also
   // more efficient in terms of persistency. The _ownPosts becomes
   // append only, this is important if there is a large number of
   // posts.
   Queue<Post> _outPostsQueue = Queue<Post>();

   // Stores chat messages that cannot be lost in case the connection
   // to the server is lost. 
   Queue<ChatMsgOutQueueElem> _outChatMsgsQueue =
         Queue<ChatMsgOutQueueElem>();

   // A flag that is set to true when the floating button (new post)
   // is clicked. It must be carefully set to false when that screen
   // are left.
   bool _newPostPressed = false;

   // Similar to _newPostPressed but for the filter screen.
   bool _newFiltersPressed = false;

   // The index of the tab we are currently in in the *new
   // post* or *Filters* screen. For example 0 for the localization
   // menu, 1 for the models menu etc.
   int _botBarIdx = 0;

   // The current chat, if any.
   Chat _chat = null;

   // The last post id seen by the user.
   int _lastSeenPostIdx = 0;

   // Whether or not to show the dialog informing the user what
   // happens to selected or deleted posts in the posts screen.
   List<bool> _dialogPrefs = List<bool>(2);

   // Full path to files.
   String _unreadPostsFileFullPath = '';
   String _menuFileFullPath = '';
   String _outPostsFileFullPath = '';
   String _outChatMsgsFileFullPath = '';

   // This list will store the posts in _fav or _own chat screens that
   // have been long pressed by the user. However, once one post is
   // long pressed to select the others is enough to perform a simple
   // click.
   List<Coord> _lpChats = List<Coord>();

   // The menu details filter.
   int _filter = 0;

   // The *new post* text controler
   TextEditingController _txtCtrl = TextEditingController();

   // A temporary variable used to store forwarded chat messages.
   List<Coord> _lpChatMsgs = List<Coord>();

   IOWebSocketChannel channel;
   
   Database _db;

   bool _isOnOwn()
   {
      return _tabCtrl.index == 0;
   }

   bool _previousWasOwn()
   {
      return _tabCtrl.previousIndex == 0;
   }

   bool isOnPosts()
   {
      return _tabCtrl.index == 1;
   }

   bool _isOnFav()
   {
      return _tabCtrl.index == 2;
   }

   bool _previousWasFav()
   {
      return _tabCtrl.previousIndex == 2;
   }

   bool isOnFavChat()
   {
      return _isOnFav() && _post != null && _chat != null;
   }

   bool isOnOwnChat()
   {
      return _isOnOwn() && _post != null && _chat != null;
   }

   bool hasSwitchedTab()
   {
      return _tabCtrl.indexIsChanging;
   }

   List<double> getNewMsgsOpacities()
   {
      List<double> opacities = List<double>(3);

      double onFocusOp = 1.0;
      double notOnFocusOp = 0.7;

      opacities[0] = notOnFocusOp;
      if (_isOnOwn())
         opacities[0] = onFocusOp;

      opacities[1] = notOnFocusOp;
      if (isOnPosts())
         opacities[1] = onFocusOp;

      opacities[2] = notOnFocusOp;
      if (_isOnFav())
         opacities[2] = onFocusOp;

      return opacities;
   }

   void _initPaths()
   {
      _menuFileFullPath        = '${glob.docDir}/${cts.menuFileName}';
      _outPostsFileFullPath    = '${glob.docDir}/${cts.outPostsFileName}';
      _outChatMsgsFileFullPath = '${glob.docDir}/${cts.outChatMsgsFileName}';
   }

   MenuChatState()
   {
      _newPostPressed = false;
      _newFiltersPressed = false;
      _botBarIdx = 0;

      getApplicationDocumentsDirectory().then((Directory docDir) async
      {
         glob.docDir = docDir.path;
         _initPaths();
         _load(docDir.path);
      });
   }

   Future<void> _load(final String docDir) async
   {
      final String dbPath = await getDatabasesPath();
      _db = await openDatabase(
         p.join(dbPath, 'main.db'),
         readOnly: false,
         onCreate: (db, version) async
         {
            print('====> Creating posts table.');
            await db.execute(cts.createPostsTable);
            print('====> Creating config table.');
            await db.execute(cts.createConfig);
            print('====> Creating chats table.');
            await db.execute(cts.createChats);
            print('====> Creating chat-status table.');
            await db.execute(cts.createChatStatus);
         },

         version: 1,
      );

      try {
         final String path = '${glob.docDir}/${cts.menuFileName}';
         final String menu = await File(path).readAsString();
         print('The menu has been read from file.');
         _menus = menuReader(jsonDecode(menu));
      } catch (e) {
         print('Using default menu.');
         _menus = menuReader(jsonDecode(Consts.menus));
      }

      List<String> lines = List<String>();

      try {
         final List<Post> posts = await loadPosts(_db, 'posts');
         for (Post p in posts) {
            if (p.status == 0) {
               await p.loadChats();
               _ownPosts.add(p);
            } else if (p.status == 1) {
               _posts.add(p);
            } else if (p.status == 2) {
               await p.loadChats();
               _favPosts.add(p);
            } else {
               assert(false);
            }
         }

         _ownPosts.sort(CompPosts);
         _favPosts.sort(CompPosts);
      } catch (e) {
         print('===> Error caught.');
      }

      try {
         lines = await File(_outPostsFileFullPath).readAsLines();
         List<Post> tmp = await decodePostsStr(lines);
         _outPostsQueue = Queue<Post>.from(tmp);
      } catch (e) {
      }

      try {
         lines = await File(_outChatMsgsFileFullPath).readAsLines();
         for (String s in lines) {
            final List<String> foo = s.split(' ');
            assert(foo.length == 2);
            final int isChat = int.parse(foo.first);
            _outChatMsgsQueue.add(ChatMsgOutQueueElem(isChat, foo.last));
         }
      } catch (e) {
      }

      channel = IOWebSocketChannel.connect(cts.host);
      channel.stream.listen(onWSData, onError: onWSError, onDone: onWSDone);

      try {
         final List<Config> configs = await loadConfig(_db, 'config');
         if (!configs.isEmpty) {
            cfg = configs.first;
            // TODO: The _posts array is expected to be sorted on its
            // ids, so we could perform a binary search here instead.
            final int i = _posts.indexWhere((e)
               { return e.id == cfg.lastSeenPostId; });

            if (i != -1) {
               _lastSeenPostIdx = i + 1;
            }

            _dialogPrefs[0] = cfg.showDialogOnDelPost == 'yes';
            _dialogPrefs[1] = cfg.showDialogOnSelectPost == 'yes';
         }
      } catch (e) {
         print(e);
      }

      final List<int> versions = _makeMenuVersions(_menus);
      final String cmd = _makeConnCmd(versions);
      channel.sink.add(cmd);

      print('Last post id: ${cfg.lastPostId}.');
      print('Last post id seen: ${cfg.lastSeenPostId}.');
      print('Menu versions: ${versions}');
      print('Login: ${cfg.appId}:${cfg.appPwd}.');
      setState(() { });
   }

   List<int> _makeMenuVersions(final List<MenuItem> menus)
   {
      List<int> versions = List<int>();
      for (MenuItem o in menus)
         versions.add(o.version);

      return versions;
   }

   String _makeConnCmd(final List<int> versions)
   {
      if (cfg.appId.isEmpty) {
         // This is the first time we are connecting to the server (or
         // the login file is corrupted, etc.)
         return makeRegisterCmd();
      }

      // We are already registered in the server.
      return makeLoginCmd(cfg.appId, cfg.appPwd, versions);
   }

   @override
   void initState()
   {
      super.initState();
      _tabCtrl = TabController(vsync: this, initialIndex: 1, length: 3);
      _tabCtrl.addListener(_tabCtrlChangeHandler);
   }

   Future<void> _setDialogPref(final int i, bool v) async
   {
      _dialogPrefs[i] = v;

      final String str = v ? 'yes' : 'no';

      if (i == 0)
         await _db.execute(cts.updateShowDialogOnDelPost, [str]);
      else
         await _db.execute(cts.updateShowDialogOnSelectPost, [str]);
   }

   Future<void>
   _alertUserOnselectPost(BuildContext ctx, int i, int fav) async
   {
      if (!_dialogPrefs[fav]) {
         await _onPostSelection(i, fav);
         return;
      }

      showDialog(
         context: ctx,
         builder: (BuildContext ctx)
         {
            return DialogWithOp(
               fav,
               () {return _dialogPrefs[fav];},
               (bool v) async {await _setDialogPref(fav, v);},
               () async {await _onPostSelection(i, fav);},
               cts.dialTitleStrs[fav],
               cts.dialBodyStrs[fav]);
            
         },
      );
   }

   Future<void> _onPostSelection(int i, int fav) async
   {
      assert(isOnPosts());

      if (fav == 1) {
         _posts[i].status = 2;
         await _posts[i].createChatEntryForPeer(_posts[i].from,
               _posts[i].nick);
         _favPosts.add(_posts[i]);
         _favPosts.sort(CompPosts);

         await _db.execute(cts.updatePostStatus, [2, _posts[i].id]);
      } else {
         await _db.execute(cts.deletePost, [_posts[i].id]);
      }

      _posts.removeAt(i);

      if (i < _lastSeenPostIdx)
         --_lastSeenPostIdx;

      setState(() { });
   }

   void _onNewPost()
   {
      _newPostPressed = true;
      _post = Post();
      _menus[0].restoreMenuStack();
      _menus[1].restoreMenuStack();
      _botBarIdx = 0;
      setState(() { });
   }

   void _onNewFilters()
   {
      _newFiltersPressed = true;
      _menus[0].restoreMenuStack();
      _menus[1].restoreMenuStack();
      _botBarIdx = 0;
      setState(() { });
   }

   bool _onWillPopMenu()
   {
      // We may want to  split this function in two: One for the
      // filters and one for the new post screen.
      if (_botBarIdx >= _menus.length) {
         --_botBarIdx;
         setState(() { });
         return false;
      }

      if (_menus[_botBarIdx].root.length == 1) {
         if (_botBarIdx == 0){
            _newPostPressed = false;
            _newFiltersPressed = false;
         } else {
            --_botBarIdx;
         }

         setState(() { });
         return false;
      }

      _menus[_botBarIdx].root.removeLast();
      setState(() { });
      return false;
   }

   void _cleanUpLpOnSwitchTab()
   {
      toggleLPChats(_lpChats);
      unmarkLPChatMsgsImpl(_lpChatMsgs);

      _lpChats.clear();
      _lpChatMsgs.clear();
   }

   Future<void> _onFwdSendButton() async
   {
      for (Coord c1 in _lpChats) {
         myprint(c1, '');
         for (Coord c2 in _lpChatMsgs) {
            if (_isOnFav()) {
               await _onSendChatMsgImpl(
                  _favPosts, c1.post.id, c1.chat.peer,
                   false, c2.chat.msgs[c2.msgIdx].msg);
            } else {
               myprint(c2, '   ');
               await _onSendChatMsgImpl(
                  _ownPosts, c1.post.id, c1.chat.peer,
                  true, c2.chat.msgs[c2.msgIdx].msg);
            }
         }
      }

      toggleLPChats(_lpChats);
      unmarkLPChatMsgsImpl(_lpChatMsgs);

      _post = _lpChatMsgs.first.post;
      _chat = _lpChatMsgs.first.chat;

      _lpChats.clear();
      _lpChatMsgs.clear();

      setState(() { });
   }

   Future<bool> _onPopChat() async
   {
      for (Coord o in _lpChatMsgs)
         toggleLPChatMsg(_chat.msgs[o.msgIdx]);

      final bool isEmpty = _lpChatMsgs.isEmpty;
      _lpChatMsgs.clear();

      await _chat.setPeerMsgStatus(3, _post.id);

      if (isEmpty) {
         _post = null;
         _chat = null;
      }

      setState(() { });
      return false;
   }

   Future<void> _onSendChatMsg() async
   {
      if (_isOnFav()) {
         await _onSendChatMsgImpl(_favPosts, _post.id,
                                 _chat.peer, false, _txtCtrl.text);
      } else {
         await _onSendChatMsgImpl(_ownPosts, _post.id,
                                  _chat.peer, true, _txtCtrl.text);
      }

      _txtCtrl.text = "";

      setState(()
      {
         SchedulerBinding.instance.addPostFrameCallback((_)
         {
            _chatScrollCtrl.animateTo(
               _chatScrollCtrl.position.maxScrollExtent,
               duration: const Duration(milliseconds: 300),
               curve: Curves.easeOut);
         });
      });
   }

   void _onFwdChatMsg()
   {
      assert(!_lpChatMsgs.isEmpty);

      _post = null;
      _chat = null;

      setState(() { });
   }

   void _onBotBarTapped(int i)
   {
      if (_botBarIdx < _menus.length)
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
      // stack, except for the last two tabs.

      if (i == 3) {
         _botBarIdx = 3;
         setState(() { });
         return;
      }

      // To handle the boundary condition on the last tab.
      if (_botBarIdx < _menus.length)
         ++_botBarIdx;

      do {
         --_botBarIdx;
         _menus[_botBarIdx].restoreMenuStack();
      } while (_botBarIdx != i);

      setState(() { });
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
      _post.channel[_botBarIdx][0] = _menus[_botBarIdx].root.last.code;
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

   Future<void> sendPost(Post post) async
   {
      final bool isEmpty = _outPostsQueue.isEmpty;

      // We add it here in our own list of posts and keep in mind it
      // will be echoed back to us if we are subscribed to its
      // channel. It has to be filtered out from _posts since that
      // list should not contain our own posts.
      _outPostsQueue.add(post);

      final String content = serializeList(<Post>[post]);
      await File(_outPostsFileFullPath).writeAsString(content, mode: FileMode.append);

      if (!isEmpty)
         return;

      // The queue was empty before we inserted the new post.
      // Therefore we are not waiting for an ack.

      final String payload = makePostPayload(_outPostsQueue.first);
      print('Sending ===> $payload');
      print(payload);
      channel.sink.add(payload);
   }

   void sendOfflinePosts()
   {
      if (_outPostsQueue.isEmpty)
         return;

      final String payload = makePostPayload(_outPostsQueue.first);
      channel.sink.add(payload);
   }

   Future<void> handlePublishAck(final int id, final int timestamp) async
   {
      try {
         assert(!_outPostsQueue.isEmpty);

         // When working with the simulator I found out that is
         // replies on my machine before we could move the post from
         // the output queue to the _ownPosts. In normal cases users
         // won't be so fast. But since this is my test condition, I
         // will cope with that by inserting the post in _ownPosts and
         // only after removing from the queue.
         Post post = _outPostsQueue.removeFirst();
         if (id != -1) {
            post.id = id;
            post.date = timestamp;
            post.status = 0;
            post.pinDate = 0;
            _ownPosts.add(post);
            _ownPosts.sort(CompPosts);
         }

         final String content1 =
            serializeList(List<Post>.from(_outPostsQueue));
         await File(_outPostsFileFullPath)
            .writeAsString(content1, mode: FileMode.write);

         if (id == -1) {
            print("Publish failed. The post will be discarded.");
            // Wipe out all queue elements.
            await File(_outPostsFileFullPath)
               .writeAsString('', mode: FileMode.write);
            return;
         }

         await _db.insert(
            'posts',
            postToMap(post),
            conflictAlgorithm: ConflictAlgorithm.replace);

         if (_outPostsQueue.isEmpty)
            return;

         // If the queue is not empty we can send the next.
         final String payload = makePostPayload(_outPostsQueue.first);
         channel.sink.add(payload);
      } catch (e) {
      }
   }

   Future<void> _onRemovePost(int i) async
   {
      if (_isOnFav()) {
         await onRemovePost(_favPosts, i, _db);
      } else {
         await onRemovePost(_ownPosts, i, _db);
      }

      setState(() { });
   }

   Future<void> _onPinPost(int i) async
   {
      if (_isOnFav()) {
         await onPinPost(_favPosts, i, _db);
      } else {
         await onPinPost(_ownPosts, i, _db);
      }
      setState(() { });
   }

   Future<void>
   _onSendNewPostPressed(BuildContext ctx, final int i) async
   {
      _newPostPressed = false;

      if (i == 0) {
         _post = null;
         setState(() { });
         return;
      }

      _botBarIdx = 0;
      _post.description = _txtCtrl.text;
      _txtCtrl.text = '';

      _post.from = cfg.appId;
      _post.nick = cfg.nick;
      await sendPost(_post.clone());
      _post = null;
      setState(() { });

      // If the user cancels the operation we do not show the dialog.
      if (i == 1)
         _showSimpleDial(ctx, (){}, 3);
   }

   Future<void>
   _onChatPressedImpl(List<Post> posts,
                      bool isSenderPost, int i, int j) async
   {
      // WARNING: When working with indexes, ensure you colect them
      // before any asynchronous functions is called.

      if (!_lpChats.isEmpty || !_lpChatMsgs.isEmpty) {
         _onChatLPImpl(posts, i, j);
         setState(() { });
         return;
      }
      
      _post = posts[i];
      _chat = posts[i].chats[j];

      final int n = posts[i].chats[j].getNumberOfUnreadMsgs();
      final double jumpToIdx = 1.0 - n / posts[i].chats[j].msgs.length;

      if (n != 0) {
         var msgMap = {
            'cmd': 'message',
            'type': 'app_ack_read',
            'from': cfg.appId,
            'to': posts[i].chats[j].peer,
            'post_id': posts[i].id,
            'is_sender_post': isSenderPost,
         };

         final String payload = jsonEncode(msgMap);
         //print('Sending ===> $payload');
         await sendChatMsg(payload, 0);
      }

      setState(() {
         SchedulerBinding.instance.addPostFrameCallback((_)
         {
            // It would be actually more correct to calculate
            // jumpToIdx here, since we may receive other messages
            // at the time this function is called. But this
            // extremely unlikey, so I won't care.
            print('====> Jumping to $jumpToIdx');
            //_chatScrollCtrl.jumpTo(jumpToIdx);
            _chatScrollCtrl.jumpTo(_chatScrollCtrl.position.maxScrollExtent);
         });
      });
   }

   Future<void> _onChatPressed(int i, int j) async
   {
      if (_isOnFav())
         await _onChatPressedImpl(_favPosts, false, i, j);
      else
         await _onChatPressedImpl(_ownPosts, true, i, j);
   }

   void _onChatLPImpl(List<Post> posts, int i, int j)
   {
      final Coord tmp = Coord(posts[i], posts[i].chats[j], -1);

      handleLPChats(
         _lpChats,
         toggleLPChat(posts[i].chats[j]),
         tmp, CompPostIdAndPeer);
   }

   void _onChatLP(int i, int j)
   {
      if (_isOnFav()) {
         _onChatLPImpl(_favPosts, i, j);
      } else {
         _onChatLPImpl(_ownPosts, i, j);
      }

      setState(() { });
   }

   Future<void> sendChatMsg(final String payload, int isChat) async
   {
      print(payload);
      final bool isEmpty = _outChatMsgsQueue.isEmpty;
      _outChatMsgsQueue.add(ChatMsgOutQueueElem(isChat, payload));

      await File(_outChatMsgsFileFullPath)
         .writeAsString('${isChat} ${payload}\n', mode: FileMode.append);

      if (isEmpty)
         channel.sink.add(_outChatMsgsQueue.first.payload);
   }

   void sendOfflineChatMsgs()
   {
      if (!_outChatMsgsQueue.isEmpty) {
         //print('====> OfflineChatMsgs: ${_outChatMsgsQueue.first.payload}');
         channel.sink.add(_outChatMsgsQueue.first.payload);
      }
   }

   void _toggleLPChatMsgs(int k, bool isTap)
   {
      assert(_post != null);
      assert(_chat != null);

      if (isTap && _lpChatMsgs.isEmpty)
         return;

      final Coord tmp = Coord(_post, _chat, k);

      handleLPChats(_lpChatMsgs,
                    toggleLPChatMsg(_chat.msgs[k]),
                    tmp, CompPeerAndChatIdx);

      setState((){});
   }

   Future<void>
   _onSendChatMsgImpl(List<Post> posts,
                      int postId,
                      String peer,
                      bool isSenderPost,
                      String msg) async
   {
      try {
         if (msg.isEmpty)
            return;

         final int i = posts.indexWhere((e) { return e.id == postId;});
         assert(i != -1);

         // We have to make sure every unread msg is marked as read
         // before we receive any reply.
         final int j = posts[i].getChatHistIdx(peer);
         assert(j != -1);

         final int now = DateTime.now().millisecondsSinceEpoch;
         await posts[i].chats[j].setPeerMsgStatus(3, postId);
         await posts[i].chats[j].addMsg(msg, true, postId, 0, now);
         await posts[i].persistPeers();

         posts[i].chats.sort(CompChats);
         posts.sort(CompPosts);

         var msgMap = {
            'cmd': 'message',
            'type': 'chat',
            'to': peer,
            'msg': msg,
            'post_id': postId,
            'is_sender_post': isSenderPost,
            'nick': cfg.nick
         };

         await sendChatMsg(jsonEncode(msgMap), 1);

      } catch(e) {
      }
   }

   Future<void> _chatServerAckHandler(Map<String, dynamic> ack) async
   {
      try {
         assert(!_outChatMsgsQueue.isEmpty);

         _outChatMsgsQueue.removeFirst();
         final String accStr = accumulateChatMsgs(_outChatMsgsQueue);
         await File(_outChatMsgsFileFullPath)
            .writeAsString(accStr, mode: FileMode.write);

         if (!_outChatMsgsQueue.isEmpty)
            channel.sink.add(_outChatMsgsQueue.first.payload);
      } catch (e) {
      }
   }

   Future<void> _chatMsgHandler(Map<String, dynamic> ack) async
   {
      final String to = ack['to'];
      if (to != cfg.appId) {
         print("Server bug caught. Please report.");
         return;
      }

      final int postId = ack['post_id'];
      final String msg = ack['msg'];
      final String peer = ack['from'];
      final String nick = ack['nick'];
      final bool isSenderPost = ack['is_sender_post'];

      // A user message can be either directed to one of the posts
      // published by this app or one that the app is interested
      // in. We distinguish this with the field 'is_sender_post'
      List<Post> posts = _ownPosts;
      if (isSenderPost)
         posts = _favPosts;

      final int i = posts.indexWhere((e) { return e.id == postId;});
      if (i == -1) {
         print('===> Error: Ignoring chat msg.');
         return;
      }

      final int j = await posts[i].getChatHistIdxOrCreate(peer, nick);
      final int now = DateTime.now().millisecondsSinceEpoch;
      await posts[i].chats[j].addMsg(msg, false, postId, 0, now);

      // FIXME: The indexes used in the rotate function below may be
      // wrong after the await function.
      Post postTmp = posts[i];
      Chat chatTmp = postTmp.chats[j];
      posts[i].chats.sort(CompChats);
      posts.sort(CompPosts);

      // If we are in the screen having chat with the user we can ack
      // it with app_ack_read and skip app_ack_received.
      if (isOnFavChat() || isOnOwnChat()) {
         if (postTmp.id == _post.id && chatTmp.peer == _chat.peer) {
            _post.chats.first.setPeerMsgStatus(3, postId);
            var msgMap = {
               'cmd': 'message',
               'type': 'app_ack_read',
               'from': cfg.appId,
               'to': peer,
               'post_id': postId,
               'is_sender_post': !isSenderPost,
            };

            final String payload = jsonEncode(msgMap);
            await sendChatMsg(payload, 0);
            return;
         }
      }

      // Acks we have received the message.
      var map = {
         'cmd': 'message',
         'type': 'app_ack_received',
         'to': peer,
         'post_id': postId,
         'is_sender_post': !isSenderPost,
      };

      final String payload = jsonEncode(map);
      await sendChatMsg(payload, 0);
   }

   Future<void>
   _chatAppAckHandler(Map<String, dynamic> ack,
                      final int status) async
   {
      final String from = ack['from'];
      final int postId = ack['post_id'];

      final bool isSenderPost = ack['is_sender_post'];
      if (isSenderPost) {
         await findAndMarkChatApp(_favPosts, from, postId, status);
      } else {
         await findAndMarkChatApp(_ownPosts, from, postId, status);
      }
   }

   Future<void> _onMessage(Map<String, dynamic> ack) async
   {
      final String type = ack['type'];
      if (type == 'server_ack') {
         final String res = ack['result'];
         if (res == 'ok') {
            final int isChat = _outChatMsgsQueue.first.isChat;
            await _chatServerAckHandler(ack);
            if (isChat == 1) {
               await _chatAppAckHandler(ack, 1);
            }
         }
      } else if (type == 'chat') {
         _chatMsgHandler(ack);
      } else if (type == 'app_ack_received') {
         await _chatAppAckHandler(ack, 2);
      } else if (type == 'app_ack_read') {
         await _chatAppAckHandler(ack, 3);
      }

      setState((){});
   }

   Future<void>
   _onRegisterAck(Map<String, dynamic> ack, final String msg) async
   {
      final String res = ack["result"];
      if (res == 'fail') {
         print("register_ack: fail.");
         return;
      }

      print('register_ack: ok.');

      cfg.appId = ack["id"];
      cfg.appPwd = ack["password"];

      print('register_ack: Persisting the login.');
      await _db.insert(
         'config',
         configToMap(cfg),
         conflictAlgorithm: ConflictAlgorithm.replace);

      _menus = menuReader(ack);
      assert(_menus != null);

      await _persistMenu();
   }

   Future<void>
   _onLoginAck(Map<String, dynamic> ack, final String msg) async
   {
      final String res = ack["result"];

      // I still do not know how a failed login should be handled.
      // Perhaps send a new register command? It can only happen if
      // the server is blocking this user.
      if (res == 'fail') {
         print("login_ack: fail.");
         return;
      }

      // We are loggen in and can send the channels we are
      // subscribed to to receive posts sent while we were offline.
      _subscribeToChannels();

      // Sends any chat messages that may have been written while
      // the app were offline.
      sendOfflineChatMsgs();

      // The same for posts.
      sendOfflinePosts();

      if (ack.containsKey('menus')) {
         // The server has sent us a menu, that means we have to
         // update the current one keeping the status of each
         // field. TODO: Keep the status field.
         _menus = menuReader(ack);
         assert(_menus != null);
         print('login_ack: Persisting new menu received.');
         await _persistMenu();
      }
   }

   void _onSubscribeAck(Map<String, dynamic> ack)
   {
      final String res = ack["result"];
      if (res == 'fail') {
         print("subscribe_ack: $res");
         return;
      }
   }

   Future<void> _onPost(Map<String, dynamic> ack) async
   {
      for (var item in ack['items']) {
         Post post = readPostData(item);
         post.status = 1;

         // Just in case the server sends us posts out of order I
         // will check. It should however be considered a server
         // error.
         if (post.id > cfg.lastPostId)
            cfg.lastPostId = post.id;

         if (post.from == cfg.appId)
            continue;

         await _db.insert(
            'posts',
            postToMap(post),
            conflictAlgorithm: ConflictAlgorithm.replace);

         _posts.add(post);
      }

      await _db.execute(cts.updateLastPostId, [cfg.lastPostId]);

      setState(() { });
   }

   Future<void> _onPublishAck(Map<String, dynamic> ack) async
   {
      final String res = ack['result'];
      print('publish_ack ===> $res');
      if (res == 'ok')
         await handlePublishAck(ack['id'], ack['date']);
      else
         await handlePublishAck(-1, -1);
   }

   Future<void> onWSData(msg) async
   {
      print(msg);
      Map<String, dynamic> ack = jsonDecode(msg);
      final String cmd = ack["cmd"];

      // TODO: Put most used commands first to improve performance.
      if (cmd == "register_ack") {
         await _onRegisterAck(ack, msg);
      } else if (cmd == "login_ack") {
         await _onLoginAck(ack, msg);
      } else if (cmd == "subscribe_ack") {
         _onSubscribeAck(ack);
      } else if (cmd == "post") {
         await _onPost(ack);
      } else if (cmd == "publish_ack") {
         await _onPublishAck(ack);
      } else if (cmd == "message") {
         print('_onMessage.');
         await _onMessage(ack);
      } else {
         print('Unhandled message received from the server:\n$msg.');
      }
   }

   void onWSError(error)
   {
      print(error);
   }

   void onWSDone()
   {
      print("Communication closed by peer.");
   }

   void _onOkDialAfterSendFilters()
   {
      _tabCtrl.index = 1;
      _botBarIdx = 0;
      setState(() { });
   }

   void _showSimpleDial(BuildContext ctx, Function onOk, final int i)
   {
      showDialog(
         context: ctx,
         builder: (BuildContext ctx)
         {
            final FlatButton ok = FlatButton(
                     child: Text('Ok'),
                     onPressed: ()
                     {
                        onOk();
                        Navigator.of(ctx).pop();
                     });

            List<FlatButton> actions = List<FlatButton>(1);
            actions[0] = ok;

            return AlertDialog( title: Text(cts.dialTitleStrs[i])
                              , content: Text(cts.dialBodyStrs[i])
                              , actions: actions);
         },
      );
   }

   Future<void> _persistMenu() async
   {
      try {
         var foo = {'menus': _menus};
         final String bar = jsonEncode(foo);
         await File(_menuFileFullPath)
               .writeAsString(bar, mode: FileMode.write);
      } catch (e) {
      }
   }

   Future<void> _onSendFilters(BuildContext ctx) async
   {
      _newFiltersPressed = false;

      // First send the hashes then show the dialog.
      _subscribeToChannels();

      _showSimpleDial(ctx, _onOkDialAfterSendFilters, 2);

      // We also have to persist the menu on file here since we may
      // not receive a subscribe_ack if the app is offline.
      await _persistMenu();
   }

   void _subscribeToChannels()
   {
      List<List<List<int>>> channels = List<List<List<int>>>();
      for (MenuItem item in _menus) {
         List<List<int>> hashCodes =
               readHashCodes(item.root.first, item.filterDepth);

         if (hashCodes.isEmpty) {
            print("Menu channels hash is empty. Nothing to do ...");
            return;
         }

         channels.add(hashCodes);
      }

      var subCmd = {
         'cmd': 'subscribe',
         'last_post_id': cfg.lastPostId,
         'channels': channels,
         'filter': _filter
      };

      final String payload = jsonEncode(subCmd);
      print('====> $payload');
      channel.sink.add(payload);
   }

   // Called when the main tab changes.
   void _tabCtrlChangeHandler()
   {
      // This function is meant to change the tab widgets when we
      // switch tab. This is needed to show the number of unread
      // messages.
      setState(() { });
   }

   int _getNUnreadFavChats()
   {
      int i = 0;
      for (Post post in _favPosts)
         i += post.getNumberOfUnreadChats();

      return i;
   }

   int _getNUnreadOwnChats()
   {
      int i = 0;
      for (Post post in _ownPosts)
         i += post.getNumberOfUnreadChats();

      return i;
   }

   bool _onChatsBackPressed()
   {
      _unmarkLPChats();

      if (_post != null) {
         _post = null;
         setState(() { });
         return false;
      }

      setState(() { });
      return true;
   }

   bool _hasLPChats()
   {
      return !_lpChats.isEmpty;
   }

   bool _hasLPChatMsgs()
   {
      return !_lpChatMsgs.isEmpty;
   }

   void _unmarkLPChats()
   {
      toggleLPChats(_lpChats);
      _lpChats.clear();
   }

   Future<void> _pinChats() async
   {
      assert(_isOnFav() || _isOnOwn());

      if (_lpChats.isEmpty)
         return;

      for (Coord c in _lpChats) {
         if (c.chat.pinDate == 0)
            c.chat.pinDate = DateTime.now().millisecondsSinceEpoch;
         else
            c.chat.pinDate = 0;

         toggleLPChat(c.chat);
      }

      _lpChats.clear();

      // TODO: Sort _favPosts and _ownPosts. Beaware that the array
      // Coord many have entries from chats from different posts and
      // they may be out of order. So care should be taken to not sort
      // the arrays multiple times.

      setState(() { });
   }

   Future<void> _removeLPChats() async
   {
      assert(_isOnFav() || _isOnOwn());

      if (_lpChats.isEmpty)
         return;

      await removeLPChats(_lpChats);

      if (_isOnFav()) {
         for (Post o in _favPosts)
            if (o.chats.isEmpty)
               await _db.execute(cts.deletePost, [o.id]);

         _favPosts.removeWhere((e) { return e.chats.isEmpty; });
      } else {
         _ownPosts.sort(CompPosts);
      }

      _lpChats.clear();
      setState(() { });
   }

   void _deleteChatDialog(BuildContext ctx)
   {
      showDialog(
         context: ctx,
         builder: (BuildContext ctx)
         {
            final FlatButton ok = FlatButton(
                     child: cts.deleteChatOkText,
                     onPressed: () async
                     {
                        await _removeLPChats();
                        Navigator.of(ctx).pop();
                     });

            final FlatButton cancel = FlatButton(
                     child: cts.deleteChatCancelText,
                     onPressed: ()
                     {
                        Navigator.of(ctx).pop();
                     });

            List<FlatButton> actions = List<FlatButton>(2);
            actions[0] = cancel;
            actions[1] = ok;

            Text txt = cts.delOwnChatTitleText;
            if (_isOnFav()) {
               txt = cts.delFavChatTitleText;
            }

            return AlertDialog(
                  title: txt,
                  content: Text(""),
                  actions: actions);
         },
      );
   }

   void _onBackFromChatMsgRedirect()
   {
      assert(!_lpChatMsgs.isEmpty);

      // Unmark any long pressed chats.
      _unmarkLPChats();

      // All items int _lpChatMsgs should have the same post id and
      // peer so we can use the first.
      _post = _lpChatMsgs.first.post;
      _chat = _lpChatMsgs.first.chat;

      setState(() { });
   }

   Future<void> _onNickPressed() async
   {
      cfg.nick = _txtCtrl.text;;
      _txtCtrl.text = '';
      await _db.execute(cts.updateNick, [cfg.nick]);
      setState(() { });
   }

   Future<void> _updateLastSeenPostIdx(int i) async
   {
      if (i <= _lastSeenPostIdx)
         return;

      _lastSeenPostIdx = i;

      await _db.execute(cts.updateLastSeenPostId,
                        [_posts[i].id]);

      SchedulerBinding.instance.addPostFrameCallback((_)
      {
         setState(() { });
      });
   }

   void _onNewPostDetail(int i)
   {
      if (i == cts.postDetails.length) {
         _botBarIdx = 3;
         setState(() { });
         return;
      }

      _post.filter ^= 1 << i;
      setState(() { });
   }

   void _onFilterDetail(int i)
   {
      _filter ^= 1 << i;
      setState(() { });
   }

   @override
   void dispose()
   {
      _txtCtrl.dispose();
      _tabCtrl.dispose();
      _scrollCtrl.dispose();
      _chatScrollCtrl.dispose();

      super.dispose();
   }

   @override
   Widget build(BuildContext ctx)
   {
      // Just for safety if we did not load the menu fast enough.
      if (_menus.isEmpty)
         return Scaffold();

      if (cfg.nick.isEmpty)
         return makeNickRegisterScreen(_txtCtrl, _onNickPressed);

      if (hasSwitchedTab())
         _cleanUpLpOnSwitchTab();

      if (_newPostPressed) {
         return
            makeNewPostScreens(
               ctx,
               _post,
               _menus,
               _txtCtrl,
               _onSendNewPostPressed,
               _botBarIdx,
               _onNewPostDetail,
               _onPostLeafPressed,
               _onPostNodePressed,
               _onWillPopMenu,
               _onNewPostBotBarTapped);
      }

      if (_newFiltersPressed)
         return
            makeNewFiltersScreens(
               ctx,
               _onSendFilters,
               _onFilterDetail,
               _onFilterNodePressed,
               _onWillPopMenu,
               _onBotBarTapped,
               _onFilterLeafNodePressed,
               _menus,
               _filter,
               _botBarIdx);

      if (isOnFavChat() || isOnOwnChat()) {
         return makeChatScreen(
            ctx,
            _onPopChat,
            _chat,
            _txtCtrl,
            _onSendChatMsg,
            _chatScrollCtrl,
            _toggleLPChatMsgs,
            _lpChatMsgs.length,
            _onFwdChatMsg);
      }

      List<Function> onWillPops = List<Function>(cts.tabNames.length);
      onWillPops[0] = _onChatsBackPressed;
      onWillPops[1] = (){return false;};
      onWillPops[2] = _onChatsBackPressed;

      String appBarTitle = cts.appName;

      List<FloatingActionButton> fltButtons =
            List<FloatingActionButton>(cts.tabNames.length);

      fltButtons[0] = makeFaButton(
         _onNewPost,
         _onFwdSendButton,
         _lpChats.length,
         _lpChatMsgs.length);

      fltButtons[1] = makeFiltersFaButton(_onNewFilters, Icons.filter_list);

      fltButtons[2] = makeFaButton(
         null,
         _onFwdSendButton,
         _lpChats.length,
         _lpChatMsgs.length);

      List<Widget> bodies = List<Widget>(cts.tabNames.length);
      bodies[0] = makeChatTab(
         ctx,
         _ownPosts,
         _onChatPressed,
         _onChatLP,
         _menus,
         (int i){_showSimpleDial(ctx, () async { await _onRemovePost(i);}, 4);},
         _onPinPost);

      bodies[1] = makePostTabListView(
         ctx,
         _posts,
         _alertUserOnselectPost,
         _menus,
         _updateLastSeenPostIdx);

      bodies[2] = makeChatTab(
         ctx,
         _favPosts,
         _onChatPressed,
         _onChatLP,
         _menus,
         (int i){_showSimpleDial(ctx, () async {await _onRemovePost(i);}, 4);},
         _onPinPost);

      List<Widget> actions = List<Widget>();
      Widget appBarLeading = null;
      if (_isOnFav() || _isOnOwn()) {
         if (_hasLPChatMsgs()) {
            appBarTitle = 'Redirecionando ...';
            appBarLeading = IconButton(
               icon: Icon(Icons.arrow_back , color: Colors.white),
                  onPressed: _onBackFromChatMsgRedirect);
         }

         if (_hasLPChats() && !_hasLPChatMsgs()) {
            actions =
               makeOnLongPressedActions(
                  ctx,
                  _deleteChatDialog,
                  _pinChats);
         }
      }

      actions.add(Icon(Icons.more_vert, color: Colors.white));

      List<int> newMsgsCounters = List<int>(cts.tabNames.length);
      newMsgsCounters[0] = _getNUnreadOwnChats();
      newMsgsCounters[1] = _posts.length - _lastSeenPostIdx;
      newMsgsCounters[2] = _getNUnreadFavChats();

      List<double> opacities = getNewMsgsOpacities();

      return WillPopScope(
          onWillPop: () async { return onWillPops[_tabCtrl.index]();},
          child: Scaffold(
              body: NestedScrollView(
                 controller: _scrollCtrl,
                 headerSliverBuilder: (BuildContext ctx, bool innerBoxIsScrolled) {
                   return <Widget>[
                     SliverAppBar(
                       title: Text(appBarTitle, style: TextStyle(color: Colors.white)),
                       pinned: true,
                       floating: true,
                       forceElevated: innerBoxIsScrolled,
                       bottom: makeTabBar(newMsgsCounters,
                                         _tabCtrl,
                                         opacities,
                                         _hasLPChatMsgs()),
                       actions: actions,
                       leading: appBarLeading
                     ),
                   ];
                 },
                 body: TabBarView(controller: _tabCtrl,
                             children: bodies),
                ),
                backgroundColor: Colors.white,
                floatingActionButton: fltButtons[_tabCtrl.index],
              )
        );
   }
}

