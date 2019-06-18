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

import 'package:flutter/material.dart';
import 'package:menu_chat/post.dart';
import 'package:menu_chat/menu.dart';
import 'package:menu_chat/menu_tree.dart';
import 'package:menu_chat/constants.dart';
import 'package:menu_chat/text_constants.dart' as cts;
import 'package:menu_chat/globals.dart' as glob;

class Coord {
   PostData post = null;
   String peer = '';
   int msgIdx = -1;
   Coord(this.post, this.peer, this.msgIdx);
}

void myprint(Coord c, String prefix)
{
   print('$prefix ===> (${c.post.id}, ${c.peer}, ${c.msgIdx})');
}

bool CompPostIdAndPeer(Coord a, Coord b)
{
   return a.post.id == b.post.id && a.peer == b.peer;
}

bool CompPeerAndChatIdx(Coord a, Coord b)
{
   return a.peer == b.peer && a.msgIdx == b.msgIdx;
}

void
handleLPChats(List<Coord> pairs, bool old, Coord coord, Function comp)
{
   if (old) {
      myprint(coord, 'Removing');
      pairs.removeWhere((e) {return comp(e, coord);});
   } else {
      myprint(coord, 'Adding');
      pairs.add(coord);
   }
}

void toggleLPChats(List<PostData> posts, List<Coord> coords)
{
   for (Coord c in coords) {
      final int j = c.post.getChatHistIdx(c.peer);
      assert(j != -1);
      myprint(c, '');
      toggleLPChat(c.post.chats[j]);
   }
}

Future<void> removeLPChats(List<PostData> posts, List<Coord> coords) async
{
   for (Coord c in coords) {
      final int j = c.post.getChatHistIdx(c.peer);
      assert(j != -1);
      await c.post.removeLPChats(j);
   }
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

Future<List<PostData>> decodePostsStr(final List<String> lines) async
{
   List<PostData> foo = List<PostData>();

   for (String o in lines) {
      Map<String, dynamic> map = jsonDecode(o);
      PostData tmp = PostData.fromJson(map);
      await tmp.loadChats();
      foo.add(tmp);
   }

   return foo;
}

List<bool> parseBoolsFromLines(final List<String> lines)
{
   List<bool> ret = List<bool>();
   for (String s in lines) {
      if (s == 'true')
         ret.add(true);
      else
         ret.add(false);
   }

   return ret;
}

String makePostPayload(final PostData post)
{
   var pubMap = {
      'cmd': 'publish',
      'items': <PostData>[post]
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
makeOnLongPressedActions( BuildContext ctx
                        , Function deleteChatEntryDialog)
{
   List<Widget> actions = List<Widget>();

   // Delete chat forever button.
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
                            , PostData post
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

   // I added this ListView to prevent widget_tmp from
   // extending the whole screen. Inside the ListView it
   // appears compact. Remove this later.
   return ListView(
      shrinkWrap: true,
      //padding: const EdgeInsets.all(20.0),
      children: <Widget>[widget_tmp]
   );
}

WillPopScope
makeNewPostScreens( BuildContext ctx
                  , PostData postInput
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
   print('$lpChats === $lpChatMsgs');
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
   ChatHistory ch,
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
               ChatHistory ch,
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

   // The credentials we use to communicate with the server. Both are
   // sent back by the server in the acknowledge to the register
   // command.
   String _appId = '';
   String _appPwd = '';

   // Array with the length equal to the number of menus there
   // are. Used both on the filter and on the *new post* screens.
   List<MenuItem> _menus = List<MenuItem>();

   // The temporary variable used to store the post the user sends or
   // the post the current chat screen belongs to, if any.
   PostData _post = null;

   // The list of posts received from the server. Our own posts that the
   // server echoes back to us (if we are subscribed to the channel)
   // will be filtered out.
   List<PostData> _posts = List<PostData>();

   // The list of posts the user has selected in the posts screen.
   // They are moved from _posts to here.
   List<PostData> _favPosts = List<PostData>();

   // Posts the user wrote itself and sent to the server. One issue we
   // have to observe is that if the user is subscribed to the channel
   // the post belongs to, it will be received back and shouldn't be
   // displayed or duplicated on this list. The posts received from
   // the server will not be inserted in _posts.
   //
   // The only posts inserted here are those that have been acked with
   // ok by the server, before that they will live in _outPostsQueue
   List<PostData> _ownPosts = List<PostData>();

   // Posts sent to the server that haven't been acked yet. I found it
   // easier to have this list. For example, if the user sends more
   // than one post while the app is offline we do not have to search
   // _ownPosts to set the post id in the correct order. It is also
   // more efficient in terms of persistency. The _ownPosts becomes
   // append only, this is important if there is a large number of
   // posts.
   Queue<PostData> _outPostsQueue = Queue<PostData>();

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

   // This string will be set to the name of user interested on our
   // post.
   String _peer = '';

   // The last post id we have received. It will be persisted on every
   // post received and will be read when the app starts. It used by
   // the subscribe command.
   int _lastPostId = 0;

   // The last post id seen by the user.
   int _lastSeenPostIdx = 0;

   // Whether or not to show the dialog informing the user what
   // happens to selected or deleted posts in the posts screen.
   List<bool> _dialogPrefs = List<bool>(2);

   // Full path to files.
   String _nickFullPath = '';
   String _unreadPostsFileFullPath = '';
   String _loginFileFullPath = '';
   String _menuFileFullPath = '';
   String _lastPostIdFileFullPath = '';
   String _postsFileFullPath = '';
   String _favPostsFileFullPath = '';
   String _ownPostsFileFullPath = '';
   String _outPostsFileFullPath = '';
   String _outChatMsgsFileFullPath = '';
   String _dialogPrefsFullPath = '';

   // This list will store the posts in _fav or _own chat screens that
   // have been long pressed by the user. However, once one post is
   // long pressed to select the others is enough to perform a simple
   // click.
   List<Coord> _lpChats = List<Coord>();

   // The menu details filter.
   int _filter = 0;

   // The nickname provided by the user.
   String _nick = '';

   // The *new post* text controler
   TextEditingController _txtCtrl = TextEditingController();

   // A temporary variable used to store forwarded chat messages.
   List<Coord> _lpChatMsgs = List<Coord>();

   IOWebSocketChannel channel;

   static final DeviceInfoPlugin devInfo = DeviceInfoPlugin();

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
      return _isOnFav() && _post != null && !_peer.isEmpty;
   }

   bool isOnOwnChat()
   {
      return _isOnOwn() && _post != null && !_peer.isEmpty;
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
      _nickFullPath            = '${glob.docDir}/${cts.nickFullPath}';
      _loginFileFullPath       = '${glob.docDir}/${cts.loginFileName}';
      _menuFileFullPath        = '${glob.docDir}/${cts.menuFileName}';
      _lastPostIdFileFullPath  = '${glob.docDir}/${cts.lastPostIdFileName}';
      _postsFileFullPath       = '${glob.docDir}/${cts.postsFileName}';
      _favPostsFileFullPath    = '${glob.docDir}/${cts.favPostsFileName}';
      _ownPostsFileFullPath    = '${glob.docDir}/${cts.ownPostsFileName}';
      _outPostsFileFullPath    = '${glob.docDir}/${cts.outPostsFileName}';
      _outChatMsgsFileFullPath = '${glob.docDir}/${cts.outChatMsgsFileName}';
      _dialogPrefsFullPath     = '${glob.docDir}/${cts.dialogPrefsFullPath}';
   }

   MenuChatState()
   {
      _newPostPressed = false;
      _newFiltersPressed = false;
      _botBarIdx = 0;

      _dialogPrefs[0] = true;
      _dialogPrefs[1] = true;

      getApplicationDocumentsDirectory().then((Directory docDir) async
      {
         glob.docDir = docDir.path;
         _initPaths();
         _load(docDir.path);
      });
   }

   Future<void> _load(final String docDir) async
   {
      try {
         _nick = await File(_nickFullPath).readAsString();
      } catch (e) {
      }

      try {
         final String path = '${glob.docDir}/${cts.menuFileName}';
         final String menu = await File(path).readAsString();
         print('The menu has been read from file.');
         _menus = menuReader(jsonDecode(menu));
      } catch (e) {
         print('Using default menu.');
         _menus = menuReader(jsonDecode(Consts.menus));
      }

      try {
         final String path = '${docDir}/${cts.lastPostIdFileName}';
         final String n = await File(path).readAsString();
         _lastPostId = int.parse(n);
      } catch (e) {
         print('Unable to read last post id from file.');
         _lastPostId = 0;
      }

      List<String> lines = List<String>();

      try {
         lines = await File(_postsFileFullPath).readAsLines();
         _posts = await decodePostsStr(lines);
      } catch (e) {
      }

      try {
         lines = await File(_favPostsFileFullPath).readAsLines();
         _favPosts = await decodePostsStr(lines);
         _favPosts.sort(CompPostData);
      } catch (e) {
      }

      try {
         lines = await File(_ownPostsFileFullPath).readAsLines();
         _ownPosts = await decodePostsStr(lines);
         _ownPosts.sort(CompPostData);
      } catch (e) {
      }

      try {
         lines = await File(_outPostsFileFullPath).readAsLines();
         List<PostData> tmp = await decodePostsStr(lines);
         _outPostsQueue = Queue<PostData>.from(tmp);
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

      try {
         lines = await File(_dialogPrefsFullPath).readAsLines();
         final List<bool> dialogPrefs = parseBoolsFromLines(lines);
         if (!dialogPrefs.isEmpty) {
            _dialogPrefs = dialogPrefs;
            assert(_dialogPrefs.length == 2);
            // To avoid problems it may be a good idea to set the file
            // empty and let the user choose the options again.
         }
      } catch (e) {
      }

      channel = IOWebSocketChannel.connect(cts.host);
      channel.stream.listen(onWSData, onError: onWSError, onDone: onWSDone);

      try {
         lines = await File(_loginFileFullPath).readAsLines();
         if (!lines.isEmpty) {
            final List<String> fields = lines.first.split(":");
            _appId = fields.first;
            _appPwd = fields.last;
         }
      } catch (e) {
      }


      final List<int> versions = _makeMenuVersions(_menus);
      final String cmd = _makeConnCmd(versions);
      channel.sink.add(cmd);

      print('Last post id: ${_lastPostId}.');
      print('Menu versions: ${versions}');
      print('Login: ${_appId}:${_appPwd}.');
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
      if (_appId.isEmpty) {
         // This is the first time we are connecting to the server (or
         // the login file is corrupted, etc.)
         return makeRegisterCmd();
      }

      // We are already registered in the server.
      return makeLoginCmd(_appId, _appPwd, versions);
   }

   @override
   void initState()
   {
      super.initState();
      _tabCtrl = TabController(vsync: this, initialIndex: 1, length: 3);
      _tabCtrl.addListener(_tabCtrlChangeHandler);
   }

   Future<void> _setDialogPref(final int idx, bool v) async
   {
      _dialogPrefs[idx] = v;

      // At the moment there are only two options so I will not loop.
      String data = '';
      data += '${_dialogPrefs[0]}\n';
      data += '${_dialogPrefs[1]}\n';

      await File(_dialogPrefsFullPath).writeAsString(data, mode: FileMode.write);
   }

   Future<void>
   _alertUserOnselectPost(BuildContext ctx,
                          PostData data, int fav) async
   {
      if (!_dialogPrefs[fav]) {
         await _onPostSelection(data, fav);
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
               () async {await _onPostSelection(data, fav);},
               cts.dialTitleStrs[fav],
               cts.dialBodyStrs[fav]);
            
         },
      );
   }

   Future<void> _onPostSelection(PostData data, int fav) async
   {
      if (fav == 1) {
         // Had I use a queue, there would be no need of rotating the
         // posts.
         _favPosts.add(data);
         rotateElements(_favPosts, _favPosts.length - 1);
         assert(_post == null);

         final String content = serializeList(<PostData>[data]);
         await File(_favPostsFileFullPath).
            writeAsString(content, mode: FileMode.append);
      }

      _posts.remove(data);

      // As far as I can see, there is no way of removing the element
      // from the posts persisted on file without rewriting it
      // completely. We can use the oportunity to write only the
      // newest.
      final String content = serializeList(_posts);
      await File(_postsFileFullPath).
         writeAsString(content, mode: FileMode.write);

      setState(() { });
   }

   void _onNewPost()
   {
      _newPostPressed = true;
      _post = PostData();
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
      if (_previousWasFav()) {
         toggleLPChats(_favPosts, _lpChats);
         _unmarkLPChatMsgsImpl(_favPosts);
      } else if (_previousWasOwn()) {
         toggleLPChats(_ownPosts, _lpChats);
         _unmarkLPChatMsgsImpl(_ownPosts);
      }

      _lpChats.clear();
      _lpChatMsgs.clear();
   }

   Future<void> _onFwdSendButton() async
   {
      for (Coord chat in _lpChats) {
         myprint(chat, '');
         for (Coord msgs in _lpChatMsgs) {
            if (_isOnFav()) {
               await _onSendChatMsgImpl(_favPosts, chat.post,
                                        chat.peer, false, "aaaaaaaaa");
            } else {
               myprint(msgs, '   ');
               await _onSendChatMsgImpl(_ownPosts, chat.post,
                                        chat.peer, true, "bbbbbbbbbb");
            }
         }
      }

      if (_isOnFav()) {
         toggleLPChats(_favPosts, _lpChats);
         _unmarkLPChatMsgsImpl(_favPosts);
      } else {
         toggleLPChats(_ownPosts, _lpChats);
         _unmarkLPChatMsgsImpl(_ownPosts);
      }

      _post = _lpChatMsgs.first.post;
      _peer = _lpChatMsgs.first.peer;

      _lpChats.clear();
      _lpChatMsgs.clear();

      setState(() { });
   }

   // FIXME: Make this non-member.
   void _unmarkLPChatMsgsImpl(List<PostData> posts)
   {
      if (_lpChatMsgs.isEmpty)
         return;
      
      final String peer = _lpChatMsgs.first.peer;

      // WARNING: All items in _lpChatMsgs should have the same id
      // and peer, so I will use the first in the list.

      final int j = _lpChatMsgs.first.post.getChatHistIdx(peer);
      if (j == -1) {
         print('Cannot find2');
         return;
      }

      for (Coord o in _lpChatMsgs)
         toggleLPChatMsg(o.post.chats[j].msgs[o.msgIdx]);
   }

   Future<bool>
   _onPopChatImpl(List<PostData> posts) async
   {
      // The following four lines of code are equal to
      // _unmarkLPChatMsgsImpl. I cannot reuse them here though as I
      // need the indexes futher below and I do not want to create a
      // return value to return them.

      final int j = _post.getChatHistIdx(_peer);

      for (Coord o in _lpChatMsgs)
         toggleLPChatMsg(_post.chats[j].msgs[o.msgIdx]);

      final bool isEmpty = _lpChatMsgs.isEmpty;
      _lpChatMsgs.clear();

      await _post.chats[j].setPeerMsgStatus(3, _post.id);

      if (isEmpty) {
         _post = null;
         _peer = '';
      }
   }

   Future<bool> _onPopChat() async
   {
      if (_isOnFav())
         await _onPopChatImpl(_favPosts);
      else
         await _onPopChatImpl(_ownPosts);

      setState(() { });
      return false;
   }

   Future<void> _onSendChatMsg() async
   {
      if (_isOnFav()) {
         await _onSendChatMsgImpl(_favPosts, _post,
                                 _peer, false, _txtCtrl.text);
      } else {
         await _onSendChatMsgImpl(_ownPosts, _post,
                                  _peer, true, _txtCtrl.text);
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
      _peer = '';

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
      _post.codes[_botBarIdx][0] = _menus[_botBarIdx].root.last.code;
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

   Future<void> sendPost(PostData post) async
   {
      final bool isEmpty = _outPostsQueue.isEmpty;

      // We add it here in our own list of posts and keep in mind it
      // will be echoed back to us if we are subscribed to its
      // channel. It has to be filtered out from _posts since that
      // list should not contain our own posts.
      _outPostsQueue.add(post);

      final String content = serializeList(<PostData>[post]);
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
         PostData post = _outPostsQueue.removeFirst();
         if (id != -1) {
            post.id = id;
            post.date = timestamp;
            _ownPosts.add(post);
            print('Insertion ready');
            rotateElements(_ownPosts, _ownPosts.length - 1);
         }

         final String content1 = serializeList(List<PostData>.from(_outPostsQueue));
         await File(_outPostsFileFullPath).writeAsString(content1, mode: FileMode.write);

         if (id == -1) {
            print("Publish failed. The post will be discarded.");
            // Wipe out all queue elements.
            await File(_outPostsFileFullPath).writeAsString('', mode: FileMode.write);
            return;
         }

         final String content2 = serializeList(<PostData>[post]);
         await File(_ownPostsFileFullPath).writeAsString(content2, mode: FileMode.append);
         if (_outPostsQueue.isEmpty)
            return;

         // If the queue is not empty we can send the next.
         final String payload = makePostPayload(_outPostsQueue.first);
         channel.sink.add(payload);
      } catch (e) {
      }
   }

   void _onRemovePost()
   {
      print('Has no implementation yet.');
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

      _post.from = _appId;
      _post.nick = _nick;
      await sendPost(_post.clone());
      _post = null;
      setState(() { });

      // If the user cancels the operation we do not show the dialog.
      if (i == 1)
         _showSimpleDial(ctx, (){}, 3);
   }

   Future<void>
   _onChatPressedImpl(List<PostData> posts,
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
      _peer = posts[i].chats[j].peer;

      final int n = posts[i].chats[j].getNumberOfUnreadMsgs();
      final double jumpToIdx = 1.0 - n / posts[i].chats[j].msgs.length;

      if (n != 0) {
         var msgMap = {
            'cmd': 'message',
            'type': 'app_ack_read',
            'from': _appId,
            'to': posts[i].chats[j].peer,
            'post_id': posts[i].id,
            'is_sender_post': isSenderPost,
         };

         final String payload = jsonEncode(msgMap);
         print('Sending ===> $payload');
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

   void _onChatLPImpl(List<PostData> posts, int i, int j)
   {
      final Coord tmp = Coord(posts[i], posts[i].chats[j].peer, -1);

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

   void
   toggleLPChatMsgsImpl(PostData post, int j, int k, bool isTap)
   {
      if (isTap && _lpChatMsgs.isEmpty)
         return;

      final Coord tmp = Coord(post, post.chats[j].peer, k);

      handleLPChats(
         _lpChatMsgs,
         toggleLPChatMsg(post.chats[j].msgs[k]),
         tmp, CompPeerAndChatIdx);
   }

   void _toggleLPChatMsgs(int k, bool isTap)
   {
      assert(_post != null);
      if (_isOnFav()) {
         int j = _post.getChatHistIdx(_peer);
         assert(j != -1);
         toggleLPChatMsgsImpl(_post, j, k, isTap);
      } else {
         int j = _post.getChatHistIdx(_peer);
         assert(j != -1);
         toggleLPChatMsgsImpl(_post, j, k, isTap);
      }

      setState((){});
   }

   Future<void>
   _onSendChatMsgImpl(List<PostData> posts,
                      PostData post,
                      String peer,
                      bool isSenderPost,
                      String msg) async
   {
      try {
         if (msg.isEmpty)
            return;

         final int i = posts.indexWhere((e) { return e.id == post.id;});
         // We have to make sure every unread msg is marked as read
         // before we receive any reply.
         final int j = post.getChatHistIdx(peer);

         await post.chats[j].setPeerMsgStatus(3, post.id);
         await post.chats[j].addMsg(msg, true, post.id, 0);
         rotateElements(post.chats, j);
         await post.persistPeers();
         rotateElements(posts, i);

         var msgMap = {
            'cmd': 'message',
            'type': 'chat',
            'to': peer,
            'msg': msg,
            'post_id': post.id,
            'is_sender_post': isSenderPost,
            'nick': _nick
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
      if (to != _appId) {
         print("Server bug caught. Please report.");
         return;
      }

      final int postId = ack['post_id'];
      final String msg = ack['msg'];
      final String from = ack['from'];
      final String nick = ack['nick'];
      final bool isSenderPost = ack['is_sender_post'];

      // A user message can be either directed to one of the posts
      // published by this app or one that the app is interested
      // in. We distinguish this with the field 'is_sender_post'
      List<PostData> posts = _ownPosts;
      if (isSenderPost)
         posts = _favPosts;

      final int i = posts.indexWhere((e) { return e.id == postId;});
      if (i == -1) {
         print('===> Error: Ignoring chat msg.');
         return;
      }

      final int j = await posts[i].getChatHistIdxOrCreate(from, nick);
      await posts[i].addMsg(j, msg, false, 0);

      // FIXME: The indexes used in the rotate function below may be
      // wrong after the await function.
      rotateElements(posts[i].chats, j);
      rotateElements(posts, i);

      // When we insert the message above the chat history it belongs
      // to is moved to the front in that history.
      //posts.first.chats.first.nick = nick;

      // If we are in the screen having chat with the user we can ack
      // it with app_ack_read and skip app_ack_received.
      if (isOnFavChat() || isOnOwnChat()) {
         // Yes, we are chatting with an user.
         if (posts.first.id == _post.id || posts.first.id == _post.id) {
            posts.first.chats.first.setPeerMsgStatus(3, postId);
            var msgMap = {
               'cmd': 'message',
               'type': 'app_ack_read',
               'from': _appId,
               'to': from,
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
         'to': from,
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

      assert(res == 'ok');

      _appId = ack["id"];
      _appPwd = ack["password"];
      final String login = '${_appId}:${_appPwd}';

      // On register_ack ok we will receive our credentials to log
      // in the server and the menu, they should both be persisted
      // in a file.
      print('register_ack: Persisting login $login');
      await File(_loginFileFullPath).writeAsString(login, mode: FileMode.write);

      _menus = menuReader(ack);
      assert(_menus != null);

      print('register_ack: Persisting the menu received.');
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
      // Remember the size of the list to append later the new items
      // to a file.
      var items = ack['items'];
      List<PostData> tmp = List<PostData>();
      for (var item in items) {
         PostData post = readPostData(item);
         if (post.from == _appId) {
            // Our own post being sent back to us. We have to drop it
            // but update our last post id.
            if (post.id > _lastPostId)
               _lastPostId = post.id;

            continue;
         }

         // Since this post is not from this app we have to add a chat
         // entry in it.
         //
         // TODO: Change this to only create the entry if the post is
         // moved to the _fav list.
         await post.createChatEntryForPeer(post.from, post.nick);
         tmp.add(post);

         // It is not guaranteed that the array of posts sent by
         // the server has increasing post ids so we should check.
         if (post.id > _lastPostId)
            _lastPostId = post.id;
      }

      try {
         await File(_lastPostIdFileFullPath)
            .writeAsString('${_lastPostId}', mode: FileMode.write);

         _posts.addAll(tmp);
         writeListToDisk( tmp, _postsFileFullPath
                        , FileMode.append);
      } catch (e) {
      }

      // Consider: Before triggering a redraw we should perhaps
      // check whether it is necessary given our current state.
      setState(() { });
   }

   Future<void> _onPublishAck(Map<String, dynamic> ack) async
   {
      final String res = ack['result'];
      print('publish_ack ===> $res');
      if (res == 'ok')
         await handlePublishAck(ack['id'], ack['date']);
      else
         await handlePublishAck(-1, 0);
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
      List<List<List<int>>> codes = List<List<List<int>>>();
      for (MenuItem item in _menus) {
         List<List<int>> hashCodes =
               readHashCodes(item.root.first, item.filterDepth);

         if (hashCodes.isEmpty) {
            print("Menu hash codes is empty. Nothing to do ...");
            return;
         }

         codes.add(hashCodes);
      }

      var subCmd = {
         'cmd': 'subscribe',
         'last_post_id': _lastPostId,
         'channels': codes,
         'filter': _filter
      };

      final String subText = jsonEncode(subCmd);
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

   int _getNUnreadFavChats()
   {
      int i = 0;
      for (PostData post in _favPosts)
         i += post.getNumberOfUnreadChats();

      return i;
   }

   int _getNUnreadOwnChats()
   {
      int i = 0;
      for (PostData post in _ownPosts)
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
      if (_isOnOwn()) {
         toggleLPChats(_ownPosts, _lpChats);
      } else {
         toggleLPChats(_favPosts, _lpChats);
      }

      _lpChats.clear();
   }

   Future<void> _removeLPChats() async
   {
      assert(_isOnFav() || _isOnOwn());

      // Optimization to avoid writing files.
      if (_lpChats.isEmpty)
         return;

      if (_isOnOwn()) {
         await removeLPChats(_ownPosts, _lpChats);

         // We do not remove the post from the list of own posts if it
         // became empty. Otherwise other chat messages directed to it
         // would be ignored.
      } else {
         await removeLPChats(_favPosts, _lpChats);

         _favPosts.removeWhere((e) { return e.chats.isEmpty; });

         final String content = serializeList(_favPosts);
         await File(_favPostsFileFullPath).
            writeAsString(content, mode: FileMode.write);
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
      _peer = _lpChatMsgs.first.peer;

      setState(() { });
   }

   Future<void> _onNickPressed() async
   {
      _nick = _txtCtrl.text;;

      await File(_nickFullPath).writeAsString(_nick, mode: FileMode.write);

      _txtCtrl.text = '';
      setState(() { });
   }

   void _updateLastSeenPostIdx(int i)
   {
      if (i > _lastSeenPostIdx)
         _lastSeenPostIdx = i;
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

      if (_nick.isEmpty)
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
         final int j = _post.getChatHistIdx(_peer);
         assert(_post != null);
         assert(j != -1);

         return makeChatScreen(
            ctx,
            _onPopChat,
            _post.chats[j],
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

      fltButtons[0] =
         makeFaButton(
            _onNewPost,
            _onFwdSendButton,
            _lpChats.length,
            _lpChatMsgs.length);

      fltButtons[1] = makeFiltersFaButton(_onNewFilters, Icons.filter_list);
      fltButtons[2] = null;

      List<Widget> bodies = List<Widget>(cts.tabNames.length);
      bodies[0] = makeChatTab(
         ctx,
         _ownPosts,
         _onChatPressed,
         _onChatLP,
         _menus,
         (){_showSimpleDial(ctx, _onRemovePost, 4);});

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
         (){_showSimpleDial(ctx, _onRemovePost, 4);});

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
            actions = makeOnLongPressedActions(ctx, _deleteChatDialog);
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

