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

class IdxPair {
   int i = 0;
   int j = 0;
   IdxPair(this.i, this.j);
}

void
handleLongPressedChat( List<IdxPair> pairs
                     , final List<PostData> posts
                     , int i, int j)
{
   ChatHistory history = posts[i].chats[j];
   final bool old = history.isLongPressed;
   if (old) {
      history.isLongPressed = false;
      pairs.removeWhere((IdxPair e) { return e.i == i && e.j == j; });
   } else {
      history.isLongPressed = true;
      pairs.add(IdxPair(i, j));
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

List<PostData> safeReadPostsFromFile(final String fullPath)
{
   List<PostData> foo = List<PostData>();

   try {
      final List<String> lines = File(fullPath).readAsLinesSync();
      for (String o in lines) {
         Map<String, dynamic> map = jsonDecode(o);
         foo.add(PostData.fromJson(map));
      }

   } catch (e) {
   }

   return foo;
}

List<String> safeReadFileAsLines(final String fullPath)
{
   try {
      return File(fullPath).readAsLinesSync();
   } catch (e) {
      return List<String>();
   }
}

String safeReadFileStr(final String fullPath)
{
   try {
      return File(fullPath).readAsStringSync();
   } catch (e) {
      return '';
   }
}

List<bool> readFileAsBoolStrs(final String path)
{
   final List<String> list = safeReadFileAsLines(path);
   List<bool> ret = List<bool>();
   for (String s in list) {
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
makeChatScreenActionsList( BuildContext ctx
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
   IconButton blockUserBut = IconButton(
      icon: Icon(Icons.block, color: Colors.white),
      tooltip: cts.blockUserChatStr,
      onPressed: () { print('Kabuff'); });

   actions.add(blockUserBut);

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
                         fontWeight: FontWeight.bold,
                         fontSize: 20.0)),
         color: cts.postFrameColor,
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
               hintText: cts.newPostTextFieldHistStr))));

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

TabBar makeTabBar( List<int> counters
                 , TabController tabCtrl
                 , double opacity)
{
   List<Widget> tabs = List<Widget>(cts.tabNames.length);

   for (int i = 0; i < tabs.length; ++i) {
      tabs[i] =
         Tab(child: makeTabWidget( counters[i], cts.tabNames[i]
                                 , opacity));
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

int postIndexHelper(int i)
{
   if (i == 0) return 1;
   if (i == 1) return 2;
   if (i == 2) return 3;
   return 1;
}

Widget
makeChatScreen(BuildContext ctx,
               Function onWillPopScope,
               ChatHistory chatHist,
               TextEditingController ctrl,
               Function onChatSendPressed,
               ScrollController scrollCtrl)
{
   TextField tf =
      makeTextInputFieldCard(
         ctrl,
         null,
         InputDecoration.collapsed(hintText: cts.chatTextFieldHintStr));

   CircleAvatar sendButCol =
         CircleAvatar(
               child: IconButton(
                  icon: Icon(Icons.send),
                  onPressed: onChatSendPressed,
                  color: Color(0xFFFFFFFF)
                  ),
               backgroundColor: Theme.of(ctx).primaryColor
               );

   Container cont = Container(
       child: ConstrainedBox(
           constraints: BoxConstraints(maxHeight: 100.0),
           child: Scrollbar(
               child: SingleChildScrollView(
                   scrollDirection: Axis.vertical,
                   reverse: true,
                   child: makeCard(tf),
               ),
           ),
       ),
   );

   Row row = Row(
      children: <Widget>
      [ Expanded(child: cont)
      , makeCard(sendButCol)
      ],
   );
 
   //_____________

   ListView list = ListView.builder(
         controller: scrollCtrl,
         reverse: false,
         padding: const EdgeInsets.all(6.0),
         itemCount: chatHist.msgs.length,
         itemBuilder: (BuildContext ctx, int i)
         {
            Alignment align = Alignment.bottomLeft;
            Color color = Color(0xFFFFFFFF);
            if (chatHist.msgs[i].thisApp) {
               align = Alignment.bottomRight;
               color = Colors.lightGreenAccent[100];
            }

            Widget msgAndStatus;
            if (chatHist.msgs[i].thisApp) {
               final int st =  chatHist.msgs[i].status;
               Align foo =
                  Align(alignment: Alignment.bottomRight,
                        child: chooseIcon(st));
               msgAndStatus = Row(children:
                  <Widget>[Expanded(child: Text(chatHist.msgs[i].msg)),
                           Expanded(child: foo)]);
            } else {
               msgAndStatus = Text(chatHist.msgs[i].msg);
            }

            // TODO: Insert a divider for new messages here.
            return Align( alignment: align,
                  child:FractionallySizedBox( child: Card(
                    child: Padding( padding: EdgeInsets.all(4.0),
                                    child: msgAndStatus),
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
                   //leading: CircleAvatar(child: Icon(Icons.person)),
                   //leading: Icon(Icons.person, color: Colors.white),
                   title: Text( chatHist.getChatDisplayName(),
                      style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: cts.mainFontSize,
                            color: Color(0xFFFFFFFF)
                      )
                   ),
                   dense: true,
                   //subtitle: subtitle
                ),
                backgroundColor: Theme.of(ctx).primaryColor,
                leading: IconButton( icon: Icon( Icons.arrow_back
                                               , color: Colors.white)
                                   , onPressed:onWillPopScope)
             ),
          body: mainCol,
          backgroundColor: Colors.white,
       )
    );
}

Widget makeTabWidget(int n, String title, double opacity)
{
   if (n == 0)
      return Text(title);

   List<Widget> widgets = List<Widget>(2);
   widgets[0] = Text(title);

   // TODO: The container should change from white to the color when
   // it is not focused. 
   // See: https://docs.flutter.io/flutter/material/TabBar/labelColor.html
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
            onPressed: ()
            {
               _onPostSelection();
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

   // The temporary variable used to store the post the user sends.
   PostData _postInput = PostData();

   // The list of posts received from the server. Our own posts that the
   // server echoes back to us (if we are subscribed to the channel)
   // will be filtered out.
   List<PostData> _posts = List<PostData>();

   // Same as _posts but stores posts that have been just received
   // from the server and haven't been viewed by the user.
   List<PostData> _unreadPosts = List<PostData>();

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

   // The index of the tab we are currently in in the *new
   // post* or *Filters* screen. For example 0 for the localization
   // menu, 1 for the models menu etc.
   int _botBarIdx = 0;

   // Stores the last tapped botton bar of the *chats* screen. See
   // that without this variable we cannot know which of the two chat
   // screens we are currently in. It should be only used when both
   // _favPostIdx and _favPostIdx are -1.
   int _chatScreenIdx = 1;

   // Stores the current chat index in the array _favPosts, -1
   // means we are not in this screen.
   int _favPostIdx = -1;

   // Similar to _favPostIdx but corresponds to the *my own posts*
   // screen.
   int _ownPostIdx = -1;

   // This string will be set to the name of user interested on our
   // post.
   String _ownPostChatPeer = '';

   // The last post id we have received. It will be persisted on every
   // post received and will be read when the app starts. It used by
   // the subscribe command.
   int _lastPostId = 0;

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
   List<IdxPair> _postsWithLongPressed = List<IdxPair>();

   // The menu details filter.
   int _filter = 0;

   // The nickname provided by the user.
   String _nick = '';

   // The *new post* text controler
   TextEditingController _txtCtrl = TextEditingController();

   IOWebSocketChannel channel;

   static final DeviceInfoPlugin devInfo = DeviceInfoPlugin();

   void _initPaths()
   {
      _nickFullPath            = '${glob.docDir}/${cts.nickFullPath}';
      _unreadPostsFileFullPath = '${glob.docDir}/${cts.unreadPostsFileName}';
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

   void _load(final String docDir)
   {
      _nick = safeReadFileStr(_nickFullPath);
      _menus = _readMenuFromFile();
      _lastPostId = _readLastPostIdFromFile(docDir);
      _posts = safeReadPostsFromFile(_postsFileFullPath);
      _unreadPosts = safeReadPostsFromFile(_unreadPostsFileFullPath);
      _favPosts = safeReadPostsFromFile(_favPostsFileFullPath);
      _favPosts.sort(CompPostData);
      _ownPosts = safeReadPostsFromFile(_ownPostsFileFullPath);
      _ownPosts.sort(CompPostData);

      List<PostData> tmp =
            safeReadPostsFromFile(_outPostsFileFullPath);

      _outPostsQueue = Queue<PostData>.from(tmp);

      final List<String> tmp2 =
         safeReadFileAsLines(_outChatMsgsFileFullPath);

      for (String s in tmp2) {
         final List<String> foo = s.split(' ');
         assert(foo.length == 2);
         final int isChat = int.parse(foo.first);
         _outChatMsgsQueue.add(ChatMsgOutQueueElem(isChat, foo.last));
      }

      final List<bool> dialogPrefs =
         readFileAsBoolStrs(_dialogPrefsFullPath);
      if (!dialogPrefs.isEmpty) {
         _dialogPrefs = dialogPrefs;
         assert(_dialogPrefs.length == 2);
         // To avoid problems it may be a good idea to set the file
         // empty and let the user choose the options again.
      }

      //print('====> dialogPref: $_dialogPrefs');

      _connectToServer();

      _loadLogin();
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

   List<MenuItem> _readMenuFromFile()
   {
      try {
         final String filePath = '${glob.docDir}/${cts.menuFileName}';
         final String menu = File(filePath).readAsStringSync();
         Map<String, dynamic> rawMenuMap = jsonDecode(menu);
         assert(rawMenuMap.containsKey('menus'));
         print('The menu has been read from file.');
         return menuReader(rawMenuMap);
      } catch (e) {
         Map<String, dynamic> rawMenuMap = jsonDecode(Consts.menus);
         assert(rawMenuMap.containsKey('menus'));
         return menuReader(rawMenuMap);
      }
   }

   int _readLastPostIdFromFile(final String docDir)
   {
      try {
         final String filePath = '${docDir}/${cts.lastPostIdFileName}';
         final String n = File(filePath).readAsStringSync();
         return int.parse(n);
      } catch (e) {
         print('Unable to read last post id from file.');
         return 0;
      }
   }

   void _loadLogin()
   {
      final List<String> login = safeReadFileAsLines(_loginFileFullPath);
      if (login.isEmpty)
         return;

      final List<String> fields = login.first.split(":");

      _appId = fields.first;
      _appPwd = fields.last;
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

   void _setDialogPref(final int idx, bool v)
   {
      _dialogPrefs[idx] = v;

      // At the moment there are only two options so I will not loop.
      String data = '';
      data += '${_dialogPrefs[0]}\n';
      data += '${_dialogPrefs[1]}\n';

      writeToFile(data, _dialogPrefsFullPath, FileMode.write);
   }

   void _alertUserOnselectPost( BuildContext ctx
                              , PostData data, int fav)
   {
      if (!_dialogPrefs[fav]) {
         _onPostSelection(data, fav);
         return;
      }

      showDialog(
         context: ctx,
         builder: (BuildContext ctx)
         {
            return
               DialogWithOp( fav
                           , () {return _dialogPrefs[fav];}
                           , (bool v) {_setDialogPref(fav, v);}
                           , (){_onPostSelection(data, fav);}
                           , cts.dialTitleStrs[fav]
                           , cts.dialBodyStrs[fav]);
            
         },
      );
   }

   void _onPostSelection(PostData data, int fav)
   {
      if (fav == 1) {
         // Had I use a queue, there would be no need of rotating the
         // posts.
         _favPosts.add(data);
         rotateElements(_favPosts, _favPosts.length - 1);
         writeListToDisk( <PostData>[data], _favPostsFileFullPath
                        , FileMode.append);
      }

      _posts.remove(data);

      // As far as I can see, there is no way of removing the element
      // from the posts persisted on file without rewriting it
      // completely. We can use the oportunity to write only the
      // newest.
      writeListToDisk(_posts, _postsFileFullPath, FileMode.write);

      setState(() { });
   }

   void _onNewPost()
   {
      _newPostPressed = true;
      _menus[0].restoreMenuStack();
      _menus[1].restoreMenuStack();
      _botBarIdx = 0;
      setState(() { });
   }

   bool _onWillPopMenu()
   {
      // TODO: Split this function in two: One for the filters and one
      // for the new post screen.
      if (_botBarIdx >= _menus.length) {
         --_botBarIdx;
         setState(() { });
         return false;
      }

      if (_menus[_botBarIdx].root.length == 1) {
         if (_botBarIdx == 0){
            _newPostPressed = false;
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

   bool _onWillPopFavChatScreen()
   {
      _favPostIdx = -1;
      setState(() { });
      return false;
   }

   bool _onWillPopOwnChatScreen()
   {
      _ownPostChatPeer = '';
      setState(() { });
      return false;
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

   void _onChatBotBarTapped(int i)
   {
      _unmarkLongPressedChatEntries();
      setState(() { _chatScreenIdx = i; });
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

   void sendPost(PostData post)
   {
      final bool isEmpty = _outPostsQueue.isEmpty;

      // We add it here in our own list of posts and keep in mind it
      // will be echoed back to us if we are subscribed to its
      // channel. It has to be filtered out from _posts since that
      // list should not contain our own posts.
      _outPostsQueue.add(post);

      writeListToDisk( <PostData>[post], _outPostsFileFullPath
                     , FileMode.append);
      if (!isEmpty)
         return;

      // The queue was empty before we inserted the new post.
      // Therefore we are not waiting for an ack.

      final String payload = makePostPayload(_outPostsQueue.first);
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

   void handlePublishAck(final int id)
   {
      assert(!_outPostsQueue.isEmpty);

      final PostData post = _outPostsQueue.removeFirst();
      writeListToDisk(List<PostData>.from(_outPostsQueue),
                      _outPostsFileFullPath , FileMode.write);

      if (id == -1) {
         // What should we do with the other elements in the queue?
         // Should they all be discarded? This will be a very rare
         // situation.
         print("Publish failed. The post will be discarded.");
         return;
      }

      post.id = id;
      _ownPosts.add(post);
      writeListToDisk( <PostData>[post], _ownPostsFileFullPath
                     , FileMode.append);

      if (_outPostsQueue.isEmpty)
         return;

      // If the queue is not empty we can send the next.
      final String payload = makePostPayload(_outPostsQueue.first);
      channel.sink.add(payload);
   }

   void _onSendNewPostPressedImpl(final int i)
   {
      _newPostPressed = false;

      if (i == 0) {
         _postInput = PostData();
         _postInput.from = _appId;
         _postInput.nick = _nick;
         setState(() { });
         return;
      }

      _botBarIdx = 0;
      _postInput.description = _txtCtrl.text;
      _txtCtrl.text = '';

      _postInput.from = _appId;
      _postInput.nick = _nick;
      sendPost(_postInput.clone());
      _postInput = PostData();
      setState(() { });
   }

   void _onSendNewPostPressed(BuildContext ctx, final int add)
   {
      _onSendNewPostPressedImpl(add);

      // If the user cancels the operation we do not show the dialog.
      if (add == 1)
         _showSimpleDial(ctx, (){}, 3);
   }

   // This function is called with the index in _favPosts.
   void _onFavChatPressed(int i, int j)
   {
      assert(j == 0);
      if (!_postsWithLongPressed.isEmpty) {
         _onFavChatLongPressed(i, j);
      } else {
         _favPostIdx = i;
         setState(() {
            SchedulerBinding.instance.addPostFrameCallback((_)
            {
               _chatScrollCtrl.jumpTo(
                  _chatScrollCtrl.position.maxScrollExtent);
            });
         });
      }
   }

   void _onFavChatLongPressed(int i, int j)
   {
      assert(j == 0);
      handleLongPressedChat(_postsWithLongPressed, _favPosts, i, j);
      setState(() { });
   }

   void _onOwnPostChatPressed(int i, int j)
   {
      if (!_postsWithLongPressed.isEmpty) {
         _onOwnPostChatLongPressed(i, j);
      } else {
         _ownPostIdx = i;
         _ownPostChatPeer = _ownPosts[i].chats[j].peer;
         setState(() {
            SchedulerBinding.instance.addPostFrameCallback((_)
            {
               _chatScrollCtrl.jumpTo(
                  _chatScrollCtrl.position.maxScrollExtent);
            });
         });
      }
   }

   void _onOwnPostChatLongPressed(int i, int j)
   {
      handleLongPressedChat(_postsWithLongPressed, _ownPosts, i, j);
      setState(() { });
   }

   void sendChatMsg(final String payload, int isChat)
   {
      final bool isEmpty = _outChatMsgsQueue.isEmpty;
      _outChatMsgsQueue.add(ChatMsgOutQueueElem(isChat, payload));
      writeToFile( '${isChat} ${payload}\n'
                 , _outChatMsgsFileFullPath
                 , FileMode.append);

      if (isEmpty) {
         //print('=====> sendChatMsg: ${_outChatMsgsQueue.first.payload}');
         channel.sink.add(_outChatMsgsQueue.first.payload);
      }
   }

   void sendOfflineChatMsgs()
   {
      if (!_outChatMsgsQueue.isEmpty) {
         //print('====> OfflineChatMsgs: ${_outChatMsgsQueue.first.payload}');
         channel.sink.add(_outChatMsgsQueue.first.payload);
      }
   }

   void _onFavChatSendPressed(final int chatIdx)
   {
      if (_txtCtrl.text.isEmpty)
         return;

      final String msg = _txtCtrl.text;
      _txtCtrl.text = "";

      final String to = _favPosts[_favPostIdx].from;
      final int id = _favPosts[_favPostIdx].id;

      var msgMap = {
         'cmd': 'message',
         'type': 'chat',
         'to': to,
         'msg': msg,
         'post_id': id,
         'is_sender_post': false,
         'nick': _nick
      };

      final String payload = jsonEncode(msgMap);
      sendChatMsg(payload, 1);
      _favPosts[_favPostIdx].addMsg(chatIdx, msg, true);
      _favPosts[_favPostIdx].moveToFront(chatIdx);
      rotateElements(_favPosts, _favPostIdx);
      _favPostIdx = 0;

      setState(()
      {
         // Needed to automatically scroll the chat to the last
         // message on the list.
         SchedulerBinding.instance.addPostFrameCallback((_)
         {
            _chatScrollCtrl.animateTo(
               _chatScrollCtrl.position.maxScrollExtent,
               duration: const Duration(milliseconds: 300),
               curve: Curves.easeOut);
         });
      });
   }

   void _onOwnChatSendPressed(final int chatIdx)
   {
      if (_txtCtrl.text.isEmpty)
         return;

      final String msg = _txtCtrl.text;
      final int id =_ownPosts[_ownPostIdx].id;

      _txtCtrl.text = "";

      var msgMap = {
         'cmd': 'message',
         'type': 'chat',
         'to': _ownPostChatPeer,
         'msg': msg,
         'post_id': id,
         'is_sender_post': true,
         'nick': _nick
      };

      final String payload = jsonEncode(msgMap);
      sendChatMsg(payload, 1);
      _ownPosts[_ownPostIdx].addMsg(chatIdx, msg, true);
      _ownPosts[_ownPostIdx].moveToFront(chatIdx);
      rotateElements(_ownPosts, _ownPostIdx);
      _ownPostIdx = 0;

      setState(()
      {
         // Needed to automatically scroll the chat to the last
         // message on the list.
         SchedulerBinding.instance.addPostFrameCallback((_)
         {
            _chatScrollCtrl.animateTo(
               _chatScrollCtrl.position.maxScrollExtent,
               duration: const Duration(milliseconds: 300),
               curve: Curves.easeOut);
         });
      });
   }

   void _chatServerAckHandler(Map<String, dynamic> ack)
   {
      assert(!_outChatMsgsQueue.isEmpty);

      _outChatMsgsQueue.removeFirst();
      final String accStr = accumulateChatMsgs(_outChatMsgsQueue);
      writeToFile(accStr, _outChatMsgsFileFullPath, FileMode.write);
      if (!_outChatMsgsQueue.isEmpty)
         channel.sink.add(_outChatMsgsQueue.first.payload);
   }

   void _chatMsgHandler(Map<String, dynamic> ack)
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
      final bool is_sender_post = ack['is_sender_post'];

      // A user message can be either directed to one of the posts
      // published by this app or one that the app is interested
      // in. We distinguish this with the field 'is_sender_post'
      List<PostData> foo = _ownPosts;
      if (is_sender_post)
         foo = _favPosts;

      final int postIdIdx =
         findAndInsertNewMsg(foo, postId, from, msg, false, '');

      if (postIdIdx == -1) {
         print('===> Error: Ignoring chat msg.');
         return;
      }

      // When we insert the message above the chat history it belongs
      // to is moved to the front in that history.
      foo.first.chats.first.nick = nick;

      // Acks we have received the message.
      var map = {
         'cmd': 'message',
         'type': 'app_ack_received',
         'to': from,
         'post_id': postId,
         'is_sender_post': !is_sender_post,
      };

      final String payload = jsonEncode(map);
      sendChatMsg(payload, 0);
   }

   void _chatAppAckHandler(Map<String, dynamic> ack, final int status)
   {
      final String from = ack['from'];
      final int postId = ack['post_id'];

      final bool isSenderPost = ack['is_sender_post'];
      if (isSenderPost) {
         findAndMarkChatApp(_favPosts, from, postId, status);
      } else {
         findAndMarkChatApp(_ownPosts, from, postId, status);
      }
   }

   void _onMessage(Map<String, dynamic> ack)
   {
      final String type = ack['type'];
      if (type == 'server_ack') {
         final String res = ack['result'];
         if (res == 'ok') {
            final int isChat = _outChatMsgsQueue.first.isChat;
            _chatServerAckHandler(ack);
            if (isChat == 1)
               _chatAppAckHandler(ack, 1);
         }
      } else if (type == 'chat') {
         _chatMsgHandler(ack);
      } else if (type == 'app_ack_received') {
         _chatAppAckHandler(ack, 2);
      } else if (type == 'app_ack_read') {
         _chatAppAckHandler(ack, 3);
      }

      setState((){});
   }

   void _onRegisterAck(Map<String, dynamic> ack, final String msg)
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
      writeToFile(login, _loginFileFullPath, FileMode.write);

      _menus = menuReader(ack);
      assert(_menus != null);

      print('register_ack: Persisting the menu received.');
      _persistMenu();
   }

   void _onLoginAck(Map<String, dynamic> ack, final String msg)
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
         _persistMenu();
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

   void _onPost(Map<String, dynamic> ack)
   {
      // Remember the size of the list to append later the new items
      // to a file.
      final int size = _unreadPosts.length;
      var items = ack['items'];
      for (var item in items) {
         final String from = item['from'];
         if (from == _appId) {
            // Our own post being sent back to us.
            continue;
         }

         PostData post = readPostData(item);
         // Since this post is not from this app we have to add a chat
         // entry in it. It is important to let the nick empty, this
         // is how we will detect that the nick must be requested from
         // the user.
         post.createChatEntryForPeer(post.from, post.nick);
         _unreadPosts.add(post);

         // It is not guaranteed that the array of posts sent by
         // the server has increasing post ids so we should check.
         if (post.id > _lastPostId)
            _lastPostId = post.id;
      }

      final String lastPostIdStr = '${_lastPostId}';
      writeToFile(lastPostIdStr, _lastPostIdFileFullPath, FileMode.write);

      // At the moment we do not impose a limit on how big this
      // file can grow.
      writeListToDisk( _unreadPosts, _unreadPostsFileFullPath
                     , FileMode.append);

      // Consider: Before triggering a redraw we should perhaps
      // check whether it is necessary given our current state.
      setState(() { });
   }

   void _onPublishAck(Map<String, dynamic> ack)
   {
      final String res = ack['result'];
      if (res == 'ok')
         handlePublishAck(ack['id']);
      else
         handlePublishAck(-1);
   }

   void onWSData(msg)
   {
      Map<String, dynamic> ack = jsonDecode(msg);
      final String cmd = ack["cmd"];

      // TODO: Put most used commands first to improve performance.
      if (cmd == "register_ack") {
         _onRegisterAck(ack, msg);
      } else if (cmd == "login_ack") {
         _onLoginAck(ack, msg);
      } else if (cmd == "subscribe_ack") {
         _onSubscribeAck(ack);
      } else if (cmd == "post") {
         _onPost(ack);
      } else if (cmd == "publish_ack") {
         _onPublishAck(ack);
      } else if (cmd == "message") {
         _onMessage(ack);
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

   void _persistMenu()
   {
      var foo = {'menus': _menus};
      final String bar = jsonEncode(foo);
      writeToFile(bar, _menuFileFullPath, FileMode.write);
   }

   void _onSendFilters(BuildContext ctx)
   {
      // First send the hashes then show the dialog.
      _subscribeToChannels();

      // We also have to persist the menu on file here since we may
      // not receive a subscribe_ack if the app is offline. In this
      // case if the user kills the app, the changes in the filter
      // will be lost.
      _persistMenu();

      _showSimpleDial(ctx, _onOkDialAfterSendFilters, 2);
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
      _unmarkLongPressedChatEntries();

      if (_chatScreenIdx == 0 && _ownPostIdx != -1) {
         _ownPostIdx = -1;
         setState(() { });
         return false;
      }

      return true;
   }

   bool hasLongPressedChat()
   {
      return !_postsWithLongPressed.isEmpty;
   }

   void _unmarkLongPressedChatEntries()
   {
      // Optimization to avoid writing files.
      if (_postsWithLongPressed.isEmpty)
         return;

      if (_chatScreenIdx == 0) {
         for (IdxPair e in _postsWithLongPressed)
            _ownPosts[e.i].unmarkLongPressedChats(e.j);
      } else {
         for (IdxPair e in _postsWithLongPressed)
            _favPosts[e.i].unmarkLongPressedChats(e.j);
      }

      _postsWithLongPressed = List<IdxPair>();
      setState(() { });
   }

   void _removeLongPressedChatEntries()
   {
      assert(_tabCtrl.index == 2);

      // Optimization to avoid writing files.
      if (_postsWithLongPressed.isEmpty)
         return;

      // Now we have to observe carefully that the indexes contained
      // in _postsWithLongPressed may come in any other the user
      // selected the chats. So if we can removeLongPressedChats on
      // say 2 and then with 3, it will be a bug since the order of
      // the element will change. It may even cause a crash. Therefore
      // we have move bigger indexes to the front.
      _postsWithLongPressed.sort((IdxPair a, IdxPair b) {
         return a.j < b.j ? 1 : -1;
      });

      if (_chatScreenIdx == 0) {
         for (IdxPair e in _postsWithLongPressed)
            _ownPosts[e.i].removeLongPressedChats(e.j);

         // We do not remove the post from the list of own posts if it
         // became empty. Otherwise other chat messages directed to it
         // would be ignored.
      } else {
         for (IdxPair e in _postsWithLongPressed)
            _favPosts[e.i].removeLongPressedChats(e.j);

         _favPosts.removeWhere((e) { return e.chats.isEmpty; });
         writeListToDisk(_favPosts, _favPostsFileFullPath, FileMode.write);
      }

      _postsWithLongPressed = List<IdxPair>();
      setState(() { });
   }

   void _deleteChatEntryDialog(BuildContext ctx)
   {
      showDialog(
         context: ctx,
         builder: (BuildContext ctx)
         {
            final FlatButton ok = FlatButton(
                     child: cts.deleteChatOkText,
                     onPressed: ()
                     {
                        _removeLongPressedChatEntries();
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
            if (_chatScreenIdx == 1) {
               txt = cts.delFavChatTitleText;
            }

            return AlertDialog(
                  title: txt,
                  content: Text(""),
                  actions: actions);
         },
      );
   }

   void _onNickPressed()
   {
      _nick = _txtCtrl.text;;
      writeToFile(_nick, _nickFullPath, FileMode.write);
      _txtCtrl.text = '';
      setState(() { });
   }

   void _onNewPostDetail(int i)
   {
      if (i == cts.postDetails.length) {
         _botBarIdx = 3;
         setState(() { });
         return;
      }

      _postInput.filter ^= 1 << i;
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
      // Just for safety we did not load the menu fast enough.
      if (_menus.isEmpty)
         return Scaffold();

      if (_nick.isEmpty)
         return makeNickRegisterScreen(_txtCtrl, _onNickPressed);

      if ((_tabCtrl.index != 2) && (_tabCtrl.previousIndex == 2))
         _unmarkLongPressedChatEntries();

      if (_newPostPressed)
         return makeNewPostScreens(
                   ctx,
                   _postInput,
                   _menus,
                   _txtCtrl,
                   _onSendNewPostPressed,
                   _botBarIdx,
                   _onNewPostDetail,
                   _onPostLeafPressed,
                   _onPostNodePressed,
                   _onWillPopMenu,
                   _onNewPostBotBarTapped);

      if (_tabCtrl.index == 2 && _favPostIdx != -1) {
         // We are in the favorite posts screen, where pressing the
         // chat button in any of the posts leads us to the chat
         // screen with the postertiser.
         final String peer = _favPosts[_favPostIdx].from;
         final int id = _favPosts[_favPostIdx].id;
         final int chatIdx = _favPosts[_favPostIdx].getChatHistIdx(peer);
         assert(chatIdx != -1);
         final int n =
            _favPosts[_favPostIdx].moveToReadHistory(chatIdx);

         if (n != 0) {
            var msgMap = {
               'cmd': 'message',
               'type': 'app_ack_read',
               'from': _appId,
               'to': peer,
               'post_id': id,
               'number_of_msgs': n, // Still unused on the app.
               'is_sender_post': false,
            };

            final String payload = jsonEncode(msgMap);
            sendChatMsg(payload, 0);
         }

         return makeChatScreen(
                   ctx,
                   _onWillPopFavChatScreen,
                   _favPosts[_favPostIdx].chats[chatIdx],
                   _txtCtrl,
                   (){_onFavChatSendPressed(chatIdx);},
                   _chatScrollCtrl);
      }

      if (_tabCtrl.index == 2 &&
          _ownPostIdx != -1 && !_ownPostChatPeer.isEmpty) {
         // We are in the chat screen with one interested user on a
         // specific post.
         final int chatIdx =
               _ownPosts[_ownPostIdx].getChatHistIdx(_ownPostChatPeer);
         assert(chatIdx != -1);
         final int n =
               _ownPosts[_ownPostIdx].moveToReadHistory(chatIdx);

         if (n != 0) {
            var msgMap = {
               'cmd': 'message',
               'type': 'app_ack_read',
               'from': _appId,
               'to': _ownPostChatPeer,
               'post_id': _ownPosts[_ownPostIdx].id,
               'number_of_msgs': n,
               'is_sender_post': true,
            };

            final String payload = jsonEncode(msgMap);
            sendChatMsg(payload, 0);
         }

         return makeChatScreen(
                   ctx,
                   _onWillPopOwnChatScreen,
                   _ownPosts[_ownPostIdx].chats[chatIdx],
                   _txtCtrl,
                   (){_onOwnChatSendPressed(chatIdx);},
                   _chatScrollCtrl);
      }

      List<Widget> bodies =
            List<Widget>(cts.tabNames.length);

      List<FloatingActionButton> fltButtons =
            List<FloatingActionButton>(cts.tabNames.length);

      List<BottomNavigationBar> bottNavBars =
            List<BottomNavigationBar>(cts.tabNames.length);

      List<Function> onWillPops =
            List<Function>(cts.tabNames.length);

      if (_botBarIdx == 3) {
         bodies[0] =
            createSendScreen((){_onSendFilters(ctx);}, 'Enviar');
      } else if (_botBarIdx == 2) {
         bodies[0] =
            makePostDetailScreen( ctx
                                , _onFilterDetail
                                , _filter
                                , 0);
      } else {
         bodies[0] = createFilterListView(
                        ctx,
                        _menus[_botBarIdx].root.last,
                        _onFilterLeafNodePressed,
                        _onFilterNodePressed,
                        _menus[_botBarIdx].isFilterLeaf());
      }

      fltButtons[0] = null;

      bottNavBars[0] = makeBottomBarItems(
                          cts.filterTabIcons,
                          cts.filterTabNames,
                          _onBotBarTapped,
                          _botBarIdx);

      onWillPops[0] = _onWillPopMenu;

      final int newPostsLength = _unreadPosts.length;
      if (_tabCtrl.index == 1) {
         if (!_unreadPosts.isEmpty) {
            _posts.addAll(_unreadPosts);
            writeListToDisk( _unreadPosts, _postsFileFullPath
                           , FileMode.append);
            _unreadPosts.clear();
            // Wipes out all the data in the unread posts file.
            writeToFile('', _unreadPostsFileFullPath, FileMode.write);
         }
      }

      bodies[1] =
         makePostTabListView( ctx
                            , _posts
                            , (PostData data, int fav)
                              {_alertUserOnselectPost(ctx, data, fav);}
                            , _menus
                            , newPostsLength);

      fltButtons[1] = makeNewPostButton(_onNewPost);
      bottNavBars[1] = null;
      onWillPops[1] = (){return false;};

      if (_chatScreenIdx == 0) {
         // The own posts tab in the chat screen.
         bodies[2] = makePostChatTab(
                        ctx,
                        _ownPosts,
                        _onOwnPostChatPressed,
                        _onOwnPostChatLongPressed,
                        _menus);
      } else {
         // The favorite tab in the chat screen.
         bodies[2] = makePostChatTab(
                        ctx,
                        _favPosts,
                        _onFavChatPressed,
                        _onFavChatLongPressed,
                        _menus);
      }

      fltButtons[2] = null;

      bottNavBars[2] = makeBottomBarItems(
                          cts.chatIcons,
                          cts.chatIconTexts,
                          _onChatBotBarTapped,
                          _chatScreenIdx);

      onWillPops[2] = _onOwnPostsBackPressed;

      final int newChats = _getNumberOfUnreadChats();

      List<Widget> actions = List<Widget>();
      if (_tabCtrl.index == 2 && hasLongPressedChat()) {
         actions = makeChatScreenActionsList(ctx, _deleteChatEntryDialog);
      }
      
      Widget leading = null;
      if (_tabCtrl.index == 0) {
         if (_botBarIdx == 0 && _menus[_botBarIdx].root.length == 1) {
         } else {
            leading =
               IconButton( icon: Icon( Icons.arrow_back
                                     , color: Colors.white)
                         , onPressed: _onWillPopMenu);
         }
      }

      actions.add(Icon(Icons.more_vert, color: Colors.white));

      List<int> newMsgsCounters = List<int>(cts.tabNames.length);
      newMsgsCounters[0] = 0;
      newMsgsCounters[1] = newPostsLength;
      newMsgsCounters[2] = newChats;

      final double newMsgCircleOpacity =
         _tabCtrl.index == 2 ? 1.0 : 0.70;

      return WillPopScope(
                onWillPop: () async { return onWillPops[_tabCtrl.index]();},
                child: Scaffold(
                    body: NestedScrollView(
                             controller: _scrollCtrl,
                             headerSliverBuilder: (BuildContext ctx, bool innerBoxIsScrolled) {
                               return <Widget>[
                                 SliverAppBar(
                                   title: Text(cts.appName, style: TextStyle(color: Colors.white)),
                                   pinned: true,
                                   floating: true,
                                   forceElevated: innerBoxIsScrolled,
                                   bottom: makeTabBar( newMsgsCounters
                                                     , _tabCtrl
                                                     , newMsgCircleOpacity),
                                   actions: actions,
                                   leading: leading
                                 ),
                               ];
                             },
                             body: TabBarView(controller: _tabCtrl,
                                         children: bodies),
                      ),
                      backgroundColor: Colors.white,
                      floatingActionButton: fltButtons[_tabCtrl.index],
                      bottomNavigationBar: bottNavBars[_tabCtrl.index],
                    )
              );
   }

   void _connectToServer()
   {
      // WARNING: localhost or 127.0.0.1 is the emulator or the phone
      // address. The host address is 10.0.2.2.
      //channel = IOWebSocketChannel.connect('ws://10.0.2.2:80');
      //channel = IOWebSocketChannel.connect('ws://192.168.2.102:80');
      channel = IOWebSocketChannel.connect('ws://37.24.165.216:80');
      //channel = IOWebSocketChannel.connect('ws://192.168.0.27:80');
      channel.stream.listen(onWSData, onError: onWSError, onDone: onWSDone);
   }
}

