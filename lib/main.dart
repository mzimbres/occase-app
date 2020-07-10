import 'dart:async' show Future, Timer;
import 'dart:convert';
import 'dart:io';
import 'dart:collection';

import 'dart:io'
       if (dart.library.io) 'package:web_socket_channel/io.dart'
       if (dart.library.html) 'package:web_socket_channel/html.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/scheduler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:photo_view/photo_view_gallery.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:share/share.dart';

import 'package:flutter/material.dart';
import 'package:occase/post.dart';
import 'package:occase/tree.dart';
import 'package:occase/constants.dart' as cts;
import 'package:occase/parameters.dart';
import 'package:occase/globals.dart' as g;
import 'package:occase/sql.dart' as sql;
import 'package:occase/stl.dart' as stl;
import 'package:occase/persistency.dart';

typedef OnPressedFn0 = void Function();
typedef OnPressedFn1 = void Function(int);
typedef OnPressedFn2 = void Function(BuildContext, int);
typedef OnPressedFn3 = void Function(int, int);
typedef OnPressedFn4 = void Function(BuildContext);
typedef OnPressedFn5 = void Function(BuildContext, int, int);
typedef OnPressedFn6 = void Function(int, RangeValues);
typedef OnPressedFn7 = bool Function();
typedef OnPressedFn8 = void Function(int, double);
typedef OnPressedFn9 = void Function(String);
typedef OnPressedFn10 = void Function(int, bool);
typedef OnPressedFn11 = void Function(BuildContext, int, DragStartDetails);
typedef OnPressedFn12 = void Function(List<int>, int);
typedef OnPressedFn13 = void Function(bool, int);

class Persistency2 {
   int insertPostId = 0;
   int chatRowId = 0;

   Future<List<Config>> loadConfig() async
   {
      return <Config>[Config(nick: g.param.unknownNick)];
   }

   Future<List<NodeInfo>> loadTrees() async
   {
      List<Tree> trees = await readTreeFromAsset();

      List<NodeInfo> elems = List<NodeInfo>();
      for (int i = 0; i < trees.length; ++i)
         elems.addAll(makeMenuElems(trees[i].root.first, i, 1000));
      return elems;
   }

   Future<List<Post>> loadPosts(List<int> rangesMinMax) async
   {
      return List<Post>();
   }

   Future<List<ChatMetadata>> loadChatMetadata(int postId) async
   {
      return List<ChatMetadata>();
   }

   Future<List<AppMsgQueueElem>> loadOutChatMsg() async
   {
      return List<AppMsgQueueElem>();
   }

   Future<void> updateShowDialogOnDelPost(bool v) async
   {
   }

   Future<void> updateShowDialogOnSelectPost(bool v) async
   {
   }

   Future<void> updateShowDialogOnReportPost(bool v) async
   {
   }

   Future<void> clearPosts() async
   {
   }

   Future<void> updateRanges(List<int> ranges) async
   {
   }

   Future<void> delPostWithId(int id) async
   {
   }

   Future<void> updateLastSeenPostId(int id) async
   {
   }

   Future<void> updateNUnreadMsgs(int postId, String peer) async
   {
   }

   Future<int> insertPost(Post post, ConflictAlgorithm v) async
   {
      return ++insertPostId;
   }

   Future<void> updatePostPinDate(int pinDate, int postId) async
   {
   }

   Future<List<ChatItem>> loadChatMsgs(int postId, String userId) async
   {
      return List<ChatItem>();
   }

   Future<int> insertOutChatMsg(int isChat, String payload) async
   {
      return ++chatRowId;
   }

   Future<int> insertChatMsg(int postId, String peer, ChatItem ci) async
   {
      return ++chatRowId;
   }

   Future<void> insertChatOnPost(int postId, ChatMetadata cm) async
   {
   }

   Future<void> _onCreateDb(Database a, int version) async
   {
   }

   Future<void> open() async
   {
   }

   Future<int> deleteChatStElem(int postId, String peer) async
   {
      return 1;
   }

   Future<void> updateEmail(String email) async
   {
   }

   Future<void> updateNick(String nick) async
   {
   }

   Future<void> updateNotifications(String str) async
   {
   }

   Future<void> updateAnyOfFeatures(String str) async
   {
   }

   Future<void> insertChatOnPost2(int postId, ChatMetadata cm) async
   {
   }

   Future<void> insertChatOnPost3(
      int postId,
      ChatMetadata chat,
      String peer,
      ChatItem ci,
   ) async {
   }

   Future<void> updateAppCredentials(String appId, String appPwd) async
   {
   }

   Future<void> updateLastPostId(int id) async
   {
   }

   Future<void> updateLeafReach(NodeInfo2 v, int idx) async
   {
   }

   Future<void> updateLeafReach2(List<NodeInfo2> list, int idx) async
   {
   }

   Future<void> delPostWithRowid(int dbId) async
   {
   }

   Future<void> updatePostOnAck(int status, int id, int date, int dbId) async
   {
   }

   Future<void> updateAckStatus(
      ChatItem ci,
      int status,
      int rowid,
      int postId,
      String from,
   ) async {
   }

   Future<void> deleteOutChatMsg(int rowid) async
   {
   }
}

class Persistency {
   Database _db;

   Future<List<Config>> loadConfig() async
   {
      final List<Map<String, dynamic>> maps =
         await _db.query('config');

      return List.generate(maps.length, (i)
      {
         String str = maps[i]['ranges'];
         assert(str != null);
         List<String> fields = str.split(' ');
         List<int> ranges = List.generate(
            fields.length,
            (int i) { return int.parse(fields[i]); },
         );

         Config cfg = Config(
            appId: maps[i]['app_id'],
            appPwd: maps[i]['app_pwd'],
            email: maps[i]['email'],
            nick: maps[i]['nick'],
            lastPostId: maps[i]['last_post_id'],
            lastSeenPostId: maps[i]['last_seen_post_id'],
            showDialogOnSelectPost: maps[i]['show_dialog_on_select_post'],
            showDialogOnReportPost: maps[i]['show_dialog_on_report_post'],
            showDialogOnDelPost: maps[i]['show_dialog_on_del_post'],
            ranges: ranges,
            anyOfFeatures: int.parse(maps[i]['any_of_features']),
            notifications: NtfConfig.fromJson(jsonDecode(maps[i]['notifications'])),
         );

         return cfg;
      });
   }

   Future<List<NodeInfo>> loadTrees() async
   {
      final List<Map<String, dynamic>> maps = await _db.query('menu');

      return List.generate(maps.length, (i)
      {
         NodeInfo me = NodeInfo(
            code: maps[i]['code'],
            depth: maps[i]['depth'],
            leafReach: maps[i]['leaf_reach'],
            name: maps[i]['name'],
            index: maps[i]['idx'],
         );

         return me;
      });
   }

   Future<List<Post>> loadPosts(List<int> rangesMinMax) async
   {
      List<Map<String, dynamic>> maps = await _db.rawQuery(sql.loadPosts);

      return List.generate(maps.length, (i)
      {
         Post post = Post(rangesMinMax: rangesMinMax);
         post.dbId = maps[i]['rowid'];
         post.id = maps[i]['id'];
         post.date = maps[i]['date'];
         post.pinDate = maps[i]['pin_date'];
         post.status = maps[i]['status'];

         final String body = maps[i]['body'];
         Map<String, dynamic> bodyMap = jsonDecode(body);


         post.from = bodyMap['from'];
         post.nick = bodyMap['nick'];
         post.avatar = bodyMap['avatar'];
         post.channel = decodeChannel(jsonDecode(bodyMap['channel']));

         post.exDetails = decodeList(
            cts.maxExDetailSize,
            1,
            jsonDecode(bodyMap['ex_details']),
         );

         post.inDetails = decodeList(
            cts.maxInDetailSize,
            0,
            jsonDecode(bodyMap['in_details']),
         );

         final int rangeDivsLength = rangesMinMax.length >> 1;
         post.rangeValues = decodeList(
            rangeDivsLength,
            0,
            jsonDecode(bodyMap['range_values']),
         );

         post.images = decodeList(1, '', bodyMap['images']) ?? <String>[];

         post.description = bodyMap['description'] ?? '';
         return post;
      });
   }

   Future<List<ChatMetadata>> loadChatMetadata(int postId) async
   {
     final List<Map<String, dynamic>> maps =
	await _db.rawQuery(sql.selectChatStatusItem, [postId]);

     return List.generate(maps.length, (i)
     {
	final String str = maps[i]['last_chat_item'];
	ChatItem lastChatItem = ChatItem();
	if (str.isNotEmpty)
	    lastChatItem = ChatItem.fromJson(jsonDecode(str));

	return ChatMetadata(
	   peer: maps[i]['user_id'],
	   nick: maps[i]['nick'],
	   avatar: maps[i]['avatar'],
	   date: maps[i]['date'],
	   pinDate: maps[i]['pin_date'],
	   chatLength: maps[i]['chat_length'],
	   nUnreadMsgs: maps[i]['n_unread_msgs'],
	   lastChatItem: lastChatItem,
	);
     });
   }

   Future<List<AppMsgQueueElem>> loadOutChatMsg() async
   {
     final List<Map<String, dynamic>> maps =
	await _db.rawQuery(sql.loadOutChats);

     return List.generate(maps.length, (i)
     {
	return AppMsgQueueElem(
	   rowid: maps[i]['rowid'],
	   isChat: maps[i]['is_chat'],
	   payload: maps[i]['payload'],
	   sent: false);
     });
   }

   Future<void> updateShowDialogOnDelPost(bool v) async
   {
      final String str = v ? 'yes' : 'no';
      await _db.execute(sql.updateShowDialogOnDelPost, [str]);
   }

   Future<void> updateShowDialogOnSelectPost(bool v) async
   {
      final String str = v ? 'yes' : 'no';
      await _db.execute(sql.updateShowDialogOnSelectPost, [str]);
   }

   Future<void> updateShowDialogOnReportPost(bool v) async
   {
      final String str = v ? 'yes' : 'no';
      await _db.execute(sql.updateShowDialogOnReportPost, [str]);
   }

   Future<void> clearPosts() async
   {
      await _db.execute(sql.clearPosts, [1]);
   }

   Future<void> updateRanges(List<int> ranges) async
   {
      await _db.execute(sql.updateRanges, [ranges.join(' ')]);
   }

   Future<void> delPostWithId(int id) async
   {
      await _db.execute(sql.delPostWithId, [id]);
   }

   Future<void> updateLastSeenPostId(int id) async
   {
      await _db.execute(sql.updateLastSeenPostId, [id]);
   }

   Future<void> updateNUnreadMsgs(int postId, String peer) async
   {
      await _db.rawUpdate(sql.updateNUnreadMsgs, [0, postId, peer]);
   }

   Future<int> insertPost(Post post, ConflictAlgorithm v) async
   {
      return await _db.insert('posts', postToMap(post), conflictAlgorithm: v);
   }

   Future<void> updatePostPinDate(int pinDate, int postId) async
   {
      await _db.execute(sql.updatePostPinDate, [pinDate, postId]);
   }

   Future<List<ChatItem>> loadChatMsgs(int postId, String userId) async
   {
      try {
	 final List<Map<String, dynamic>> maps =
	    await _db.rawQuery(sql.selectChats, [postId, userId]);

	 return List.generate(maps.length, (i)
	 {
	    return ChatItem(
	       rowid: maps[i]['rowid'],
	       peerRowid: maps[i]['peer_rowid'],
	       isRedirected: maps[i]['is_redirected'],
	       date: maps[i]['date'],
	       msg: maps[i]['msg'],
	       refersTo: maps[i]['refers_to'],
	       status: maps[i]['status'],
	    );
	 });

      } catch (e) {
	 print(e);
      }

      return null;
   }

   Future<int> insertOutChatMsg(int isChat, String payload) async
   {
      return await _db.rawInsert(sql.insertOutChatMsg, [isChat, payload]);
   }

   Future<int> insertChatMsg(int postId, String peer, ChatItem ci) async
   {
      return await _db.insert(
	 'chats',
	 makeChatItemToMap(postId, peer, ci),
	 conflictAlgorithm: ConflictAlgorithm.replace,
      );
   }

   Future<void> insertChatOnPost(int postId, ChatMetadata cm) async
   {
      await _db.rawInsert(sql.insertOrReplaceChatOnPost, makeChatMetadataSql(cm, postId));
   }

   Future<void> _onCreateDb(Database a, int version) async
   {
      await a.execute(sql.createPostsTable);
      await a.execute(sql.createConfig);
      await a.execute(sql.createChats);
      await a.execute(sql.createChatStatus);
      await a.execute(sql.creatOutChatTable);
      await a.execute(sql.createMenuTable);

      // When the database is created, we also have to create the
      // default menu table.
      List<Tree> trees = await readTreeFromAsset();

      List<NodeInfo> elems = List<NodeInfo>();
      for (int i = 0; i < trees.length; ++i) {
         elems.addAll(makeMenuElems(
               trees[i].root.first,
               i,
               1000, // Large enough to include nodes at all depths.
            ),
         );
      }

      Batch batch = a.batch();

      Config cfg = Config();
      cfg.nick = g.param.unknownNick;
      batch.insert(
         'config',
         configToMap(cfg),
         conflictAlgorithm: ConflictAlgorithm.replace,
      );

      elems.forEach((NodeInfo me) { batch.insert('menu', menuElemToMap(me)); });

      await batch.commit(noResult: true, continueOnError: true);
   }

   Future<void> open() async
   {
      _db = await openDatabase(
	 p.join(await getDatabasesPath(), 'main.db'),
	 readOnly: false,
	 onCreate: _onCreateDb,
	 version: 1,
      );
   }

   Future<int> deleteChatStElem(int postId, String peer) async
   {
      return await _db.rawDelete(sql.deleteChatStElem, [postId, peer]);
   }

   Future<void> updateEmail(String email) async
   {
      await _db.execute(sql.updateEmail, [email]);
   }

   Future<void> updateNick(String nick) async
   {
      await _db.execute(sql.updateNick, [nick]);
   }

   Future<void> updateNotifications(String str) async
   {
      await _db.execute(sql.updateNotifications, [str]);
   }

   Future<void> updateAnyOfFeatures(String str) async
   {
      await _db.execute(sql.updateAnyOfFeatures, [str]);
   }

   Future<void> insertChatOnPost2(int postId, ChatMetadata cm) async
   {
      Batch batch = _db.batch();
      batch.rawInsert(sql.insertChatStOnPost, makeChatMetadataSql(cm, postId));
      batch.execute(sql.updatePostStatus, [2, postId]);
      await batch.commit(noResult: true, continueOnError: true);
   }

   Future<void> insertChatOnPost3(
      int postId,
      ChatMetadata chat,
      String peer,
      ChatItem ci,
   ) async {
      await _db.transaction((txn) async {
         Batch batch = txn.batch();
         batch.rawInsert(
            sql.insertOrReplaceChatOnPost,
            makeChatMetadataSql(chat, postId),
         );

         batch.insert(
            'chats',
            makeChatItemToMap(postId, peer, ci),
            conflictAlgorithm: ConflictAlgorithm.replace,
         );

         final List<dynamic> tmp = await batch.commit(
            noResult: false,
            continueOnError: true,
         );
      });
   }

   Future<void> updateAppCredentials(String appId, String appPwd) async
   {
      await _db.execute(sql.updateAppCredentials, [appId, appPwd]);
   }

   Future<void> updateLastPostId(int id) async
   {
      await _db.execute(sql.updateLastPostId, [id]);
   }

   Future<void> updateLeafReach(NodeInfo2 v, int idx) async
   {
      await _db.rawUpdate(sql.updateLeafReach, [v.leafReach, v.code, idx]);
   }

   Future<void> updateLeafReach2(List<NodeInfo2> list, int idx) async
   {
      Batch batch = _db.batch();
      list.forEach((v){
	 batch.rawUpdate(sql.updateLeafReach, [v.leafReach, v.code, idx]);
      });
      await batch.commit(noResult: true, continueOnError: true);
   }

   Future<void> delPostWithRowid(int dbId) async
   {
      await _db.execute(sql.delPostWithRowid, [dbId]);
   }

   Future<void> updatePostOnAck(int status, int id, int date, int dbId) async
   {
      await _db.execute(sql.updatePostOnAck, [status, id, date, dbId]);
   }

   Future<void> updateAckStatus(
      ChatItem ci,
      int status,
      int rowid,
      int postId,
      String from,
   ) async {
      Batch batch = _db.batch();
      batch.rawUpdate(sql.updateAckStatus, [status, rowid]);
      batch.rawUpdate(sql.updateLastChat, [jsonEncode(ci), postId, from]);
      await batch.commit(noResult: true, continueOnError: true);
   }

   Future<void> deleteOutChatMsg(int rowid) async
   {
      await _db.rawDelete(sql.deleteOutChatMsg, [rowid]);
   }
}

Future<List<Tree>> readTreeFromAsset() async
{
   // When the database is created, we also have to create the
   // default tree table.
   List<Tree> l = List<Tree>(2);

   final String tree0 = await rootBundle.loadString('data/menu0.txt');
   l[0] = treeReader(jsonDecode(tree0)).first;

   final String tree1 = await rootBundle.loadString('data/menu1.txt');
   l[1] = treeReader(jsonDecode(tree1)).first;

   return l;
}

Future<void> fcmOnBackgroundMessage(Map<String, dynamic> message) async
{
  print("onBackgroundMessage: $message");
}

String emailToGravatarHash(String email)
{
   if (email.isEmpty)
      return '';

   email = email.replaceAll(' ', '');
   email = email.toLowerCase();
   List<int> bytes = utf8.encode(email);
   return md5.convert(bytes).toString();
}

class Coord {
   Post post;
   ChatMetadata chat;
   int msgIdx;

   Coord({this.post,
          this.chat,
          this.msgIdx = -1,
   });
}

void myprint(Coord c, String prefix)
{
   print('$prefix ===> (${c.post.id}, ${c.chat.peer}, ${c.msgIdx})');
}

void toggleChatPinDate(ChatMetadata chat)
{
   if (chat.pinDate == 0)
      chat.pinDate = DateTime.now().millisecondsSinceEpoch;
   else
      chat.pinDate = 0;
}

bool compPostIdAndPeer(Coord a, Coord b)
{
   return a.post.id == b.post.id && a.chat.peer == b.chat.peer;
}

bool compPeerAndChatIdx(Coord a, Coord b)
{
   return a.chat.peer == b.chat.peer && a.msgIdx == b.msgIdx;
}

void handleLPChats(
   List<Coord> pairs,
   bool old,
   Coord coord,
   Function comp,
) {
   if (old) {
      pairs.removeWhere((e) {return comp(e, coord);});
   } else {
      pairs.add(coord);
   }
}

Future<void> removeLpChat(Coord c, Persistency2 p) async
{
   // removeWhere could also be used, but that traverses all elements
   // always and we know there is only one element to remove.

   final bool ret = c.post.chats.remove(c.chat);
   assert(ret);

   final int n = await p.deleteChatStElem(c.post.id, c.chat.peer);
   assert(n == 1);
}

Future<Null> main() async
{
  runApp(MyApp());
}

class AppMsgQueueElem {
   int rowid;
   int isChat;
   String payload;
   bool sent; // Used for debugging.
   AppMsgQueueElem({
      this.rowid = 0,
      this.isChat = 0,
      this.payload = '',
      this.sent = false,
   });
}

String makePostPayload(final Post post)
{
   var pubMap = {
      'cmd': 'publish',
      'items': <Post>[post]
   };

   return jsonEncode(pubMap);
}

enum ConfigActions
{ ChangeNick
, Notifications
}

Widget makeAppBarVertAction(Function onSelected)
{
   return PopupMenuButton<ConfigActions>(
     icon: Icon(Icons.more_vert, color: Colors.white),
     onSelected: onSelected,
     itemBuilder: (BuildContext ctx)
     {
        return <PopupMenuEntry<ConfigActions>>
        [ PopupMenuItem<ConfigActions>(
             value: ConfigActions.ChangeNick,
             child: Text(g.param.changeNickHint),
          ),
          PopupMenuItem<ConfigActions>(
             value: ConfigActions.Notifications,
             child: Text(g.param.changeNotifications),
          ),
        ];
     }
   );
}

List<Widget> makeOnLongPressedActions(OnPressedFn0 deleteChatEntryDialog, OnPressedFn0 pinChat)
{
   List<Widget> actions = List<Widget>();

   IconButton pinChatBut = IconButton(
      icon: Icon(Icons.place, color: Colors.white),
      tooltip: g.param.pinChat,
      onPressed: pinChat,
   );

   actions.add(pinChatBut);

   IconButton delChatBut = IconButton(
      icon: Icon(Icons.delete_forever, color: Colors.white),
      tooltip: g.param.deleteChat,
      onPressed: deleteChatEntryDialog,
   );

   actions.add(delChatBut);

   return actions;
}

Scaffold makeWaitMenuScreen()
{
   return Scaffold(
      appBar: AppBar(title: Text(g.param.appName)),
      body: Center(child: CircularProgressIndicator()),
      backgroundColor: stl.colorScheme.background,
   );
}

Widget makeImgExpandScreen(Function onWillPopScope, Post post)
{
   //final double width = makeWidth(ctx);
   //final double height = makeHeight(ctx);

   final int l = post.images.length;

   Widget foo = PhotoViewGallery.builder(
      scrollPhysics: const BouncingScrollPhysics(),
      itemCount: post.images.length,
      //loadingChild: Container(
      //         width: 30.0,
      //         height: 30.0,
      //),
      reverse: true,
      //backgroundDecoration: widget.backgroundDecoration,
      //pageController: widget.pageController,
      onPageChanged: (int i){ print('===> New index: $i');},
      builder: (BuildContext context, int i) {
         // No idea why this is showing in reverse order, I will have
         // to manually reverse the indexes.
         final int idx = l - i - 1;
         return PhotoViewGalleryPageOptions(
            //imageProvider: AssetImage(widget.galleryItems[idx].image),
            imageProvider: CachedNetworkImageProvider(post.images[idx]),
            //initialScale: PhotoViewComputedScale.contained * 0.8,
            //minScale: PhotoViewComputedScale.contained * 0.8,
            //maxScale: PhotoViewComputedScale.covered * 1.1,
            //heroAttributes: HeroAttributes(tag: galleryItems[idx].id),
         );
      },
   );

   return WillPopScope(
      onWillPop: () async { return onWillPopScope();},
      child: Scaffold(
         //appBar: AppBar(title: Text(g.param.appName)),
         body: Center(child: foo),
         backgroundColor: stl.colorScheme.primary,
      ),
   );
}

TextField makeNickTxtField(
   TextEditingController txtCtrl,
   Icon icon,
   int fieldMaxLength,
   String hint,
) {
   Color focusedColor = stl.colorScheme.primary;

   Color enabledColor = focusedColor;

   return TextField(
      style: stl.textField,
      controller: txtCtrl,
      maxLines: 1,
      maxLength: fieldMaxLength,
      decoration: InputDecoration(
         hintText: hint,
         focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(
               Radius.circular(stl.cornerRadius),
            ),
            borderSide: BorderSide(
               color: focusedColor,
               width: 2.5
            ),
         ),
         enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(
               Radius.circular(stl.cornerRadius),
            ),
            borderSide: BorderSide(
               color: enabledColor,
               width: 2.5,
            ),
         ),
         prefixIcon: icon,
      ),
   );
}

Scaffold makeRegisterScreen(
   TextEditingController emailCtrl,
   TextEditingController nickCtrl,
   Function onContinue,
   String appBarTitle,
   String previousEmail,
   String previousNick,
   double maxWidth,
) {
   if (previousEmail.isNotEmpty)
      emailCtrl.text = previousEmail;

   TextField emailTf = makeNickTxtField(
      emailCtrl,
      Icon(Icons.email),
      cts.emailMaxLength,
      g.param.emailHint,
   );

   if (previousNick.isNotEmpty)
      nickCtrl.text = previousNick;

   TextField nickTf = makeNickTxtField(
      nickCtrl,
      Icon(Icons.person),
      cts.nickMaxLength,
      g.param.nickHint,
   );

   Widget button = createRaisedButton(
      onContinue,
      g.param.next,
      stl.colorScheme.secondary,
      stl.colorScheme.onSecondary,
   );

   Column col = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>
      [ Padding(
           child: emailTf,
           padding: EdgeInsets.only(bottom: 30.0),
        )
      , Padding(
           child: nickTf,
           padding: EdgeInsets.only(bottom: 30.0),
        )
      , button
      ]
   );

   // TODO: Use ConstrainedBox
   Widget body = col;
   if (!isWideScreenImpl(maxWidth))
      body = SizedBox(width: maxWidth, child: col);

   return Scaffold(
      appBar: AppBar(title: Text(appBarTitle)),
      body: Center(
         child: Padding(
            child: body,
            padding: EdgeInsets.symmetric(horizontal: 20.0),
         ),
      ),
   );
}

Scaffold makeNtfScreen(
   BuildContext ctx,
   Function onChange,
   final String appBarTitle,
   final NtfConfig conf,
   final List<String> titleDesc,
) {
   assert(titleDesc.length >= 2);

   CheckboxListTile chat = CheckboxListTile(
      dense: true,
      title: Text(titleDesc[0], style: stl.ltTitle),
      subtitle: Text(titleDesc[1], style: stl.ltSubtitle),
      value: conf.chat,
      onChanged: (bool v) { onChange(0, v); },
      activeColor: stl.colorScheme.primary,
      isThreeLine: true,
   );

   Column col = Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>
      [ Padding(
           child: chat,
           padding: EdgeInsets.only(bottom: 30.0),
        ),
        createRaisedButton(
           () {onChange(-1, false);},
           g.param.ok,
	   stl.colorScheme.secondary,
	   stl.colorScheme.onSecondary,
        ),
      ]
   );

   final double width = makeWidth(ctx);

   Widget tmp = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: width),
      child: col,
   );

   return Scaffold(
      appBar: AppBar(title: Text(appBarTitle)),
      body: Padding(
         child: Center(child: tmp),
         padding: EdgeInsets.symmetric(vertical: 20.0),
      ),
   );
}

Widget makeNetImgBox(
   double width,
   double height,
   String url,
   BoxFit bf)
{
   return CachedNetworkImage(
      imageUrl: url,
      width: width,
      height: height,
      fit: bf,
      placeholder: (ctx, url) => CircularProgressIndicator(),
      errorWidget: (ctx, url, error) {
         print('====> $error $url $error');
         //Icon ic = Icon(Icons.error, color: stl.colorScheme.primary);
         Widget w = Text(g.param.unreachableImgError,
            overflow: TextOverflow.clip,
            style: TextStyle(
               color: stl.colorScheme.background,
               fontSize: stl.tt.title.fontSize,
            ),
         );

         return makeImgPlaceholder(width, height, w);
      },
   );
}

Widget makeImgPlaceholder(
   double width,
   double height,
   Widget w)
{
   return SizedBox(
      width: width,
      height: height,
      child: Card(
         elevation: 0.0,
         margin: EdgeInsets.all(0.0),
         color: Colors.grey,
         child: Center(
            child: Padding(
               padding: const EdgeInsets.symmetric(horizontal: 15.0),
               child: w,
            ),
         ),
         shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(0.0)),
            //side: BorderSide(
            //   width: stl.imgLvBorderWidth,
            //   color: stl.colorScheme.background,
            //),
         ),
      ),
   );
}

Widget constrainBox(double width, double height, Widget lv)
{
   return ConstrainedBox(
      constraints: BoxConstraints(
         maxWidth: width,
         minWidth: width,
         maxHeight: height,
         minHeight: height,
      ),
      child: SingleChildScrollView(
         scrollDirection: Axis.horizontal,
         reverse: true,
         child: lv
      ),
   );
}

Widget makeWdgOverImg(Widget wdg)
{
   return Padding(
      padding: const EdgeInsets.all(2.0),
      child: Card(child: wdg,
	    elevation: 0.0,
	    color: Colors.white.withOpacity(0.7),
	    margin: EdgeInsets.all(5.0),
      ),
   );
}

// Generates the image list view of a post.
Widget makeImgListView2(
   BuildContext ctx,
   Post post,
   BoxFit bf,
   List<File> imgFiles,
   OnPressedFn1 onExpandImg,
   OnPressedFn2 addImg,
) {
   final int l1 = post.images.length;
   final int l2 = imgFiles.length;

   final double width = makeTabWidth(ctx);
   if (l1 == 0 && l2 == 0) {
      Widget w = makeImgTextPlaceholder(g.param.addImgMsg);
      return makeImgPlaceholder(width, width, w);
   }

   final double height = makeImgHeight(ctx, cts.imgHeightFactor);

   final int l = l1 == 0 ? l2 : l1;

   ListView lv = ListView.builder(
      scrollDirection: Axis.horizontal,
      shrinkWrap: true,
      padding: const EdgeInsets.all(0.0),
      itemCount: l,
      itemBuilder: (BuildContext ctx, int i)
      {
         FlatButton b = FlatButton(
            onPressed: (){onExpandImg(l -i -1);},
            child: Container(
               width: width * 0.9,
               height: height * 0.9,
            ),
         );

	 Widget imgCounter = makeTextWdg('${i + 1}/$l', 3.0, 3.0, 3.0, 3.0, FontWeight.normal);

	 List<Widget> wdgs = List<Widget>();

	 if (post.images.isNotEmpty) {
	    Widget tmp = makeNetImgBox(width, height, post.images[l -i -1], bf);
	    wdgs.add(tmp);
	    wdgs.add(Positioned(child: makeWdgOverImg(imgCounter), top: 4.0));
	 } else if (imgFiles.isNotEmpty) {
	    Widget tmp = Image.file(imgFiles[i],
	       width: width,
	       height: width,
	       fit: BoxFit.cover,
	       filterQuality: FilterQuality.high,
	    );

	    wdgs.add(tmp);

	    IconButton add = IconButton(
	       onPressed: (){addImg(ctx, -1);},
	       icon: Icon(Icons.add_a_photo, color: stl.colorScheme.primary),
	    );

	    Widget addWdg = makeWdgOverImg(add);
	    wdgs.add(Positioned(child: addWdg, bottom: 4.0, right: 4.0));

	    IconButton remove = IconButton(
	       onPressed: (){addImg(ctx, i);},
	       icon: Icon(Icons.cancel, color: stl.colorScheme.primary),
	    );

	    Widget removeWdg = makeWdgOverImg(remove);
	    wdgs.add(Positioned(child: removeWdg, top: 4.0, right: 4.0));
	    wdgs.add(Positioned(child: makeWdgOverImg(imgCounter), top: 4.0, left: 4.0));
	 } else {
	    assert(false);
	 }

         return Stack(children: wdgs);
      },
   );

   return constrainBox(width, height, lv);
}

Widget makeImgListView(
   double width,
   double height,
   Function onAddPhoto,
   List<File> imgFiles,
   Post post)
{
   int l = 1;
   if (imgFiles.isNotEmpty)
      l = imgFiles.length;

   ListView lv = ListView.builder(
      scrollDirection: Axis.horizontal,
      shrinkWrap: true,
      padding: const EdgeInsets.all(0.0),
      itemCount: l,
      itemBuilder: (BuildContext ctx, int i)
      {
         Widget img = Image.file(imgFiles[i],
            width: width,
            height: height,
            fit: BoxFit.cover,
            filterQuality: FilterQuality.high,
         );

         Widget delPhotoWidget = makeAddOrRemoveWidget(
            () {onAddPhoto(ctx, i);},
            Icons.clear,
            stl.colorScheme.secondaryVariant,
         );

         return Stack(children: <Widget>[img, delPhotoWidget]);
      },
   );

   return constrainBox(width, height, lv);
}

int searchBitOn(int o, int n)
{
   assert(n <= 64);

   while (--n > 0) {
      if (o & (1 << n) != 0)
         return n;
   }

   return 0;
}

RichText makeExpTileTitle(
   String first,
   String second,
   String sep,
   bool changeColor,
) {
   Color color = changeColor
               ? stl.colorScheme.secondaryVariant
               : stl.colorScheme.secondary;

   return RichText(
      text: TextSpan(
         text: '$first$sep ',
         style: stl.tsSubheadOnPrimary,
         children: <TextSpan>
         [ TextSpan(
              text: second,
              style: stl.tt.subhead.copyWith(color: color),
           ),
         ],
      ),
   );
}

Widget wrapOnDetailExpTitle(
   Widget title,
   List<Widget> children,
   bool initiallyExpanded,
) {
   // Passing a global key has the effect that an expansion tile will
   // collapse after setState is called, but without animation not in
   // an nice way.
   //Key key = UniqueKey();

   return Card(
      color: stl.expTileCardColor,
      shape: RoundedRectangleBorder(
         borderRadius: BorderRadius.all(Radius.circular(10.0)),
      ),
      child: Theme(
         data: makeExpTileThemeData(),
         child: ExpansionTile(
             //key: key,
             backgroundColor: stl.expTileCardColor,
             title: title,
             children: children,
             initiallyExpanded: initiallyExpanded,
         ),
      ),
   );
}

Widget makeNewPostDetailExpTile(
   Function onInDetail,
   Node titleNode,
   int state,
   String strDisplay,
) {
   List<Widget> bar =
      makeNewPostDetailElemList(
         onInDetail,
         state,
         titleNode.children,
      );

   final RichText richTitle = makeExpTileTitle(
      titleNode.name(g.param.langIdx),
      strDisplay,
      ':',
      state == 0,
   );

   return wrapOnDetailExpTitle(richTitle, bar, false);
}

int counterBitsSet(int v)
{
   // See https://graphics.stanford.edu/~seander/bithacks.html#CountBitsSetKernighan
   int c; // c accumulates the total bits set in v
   for (c = 0; v != 0; c++)
     v &= v - 1;

   return c;
}

List<Widget> makeSliderList({
   double value,
   double min,
   double max,
   int divisions,
   Function onValueChanged,
}) {
   final int d = (max - min).round();

   if (d <= divisions) {
      Slider sld = Slider(
         value: value,
         min: min,
         max: max,
         divisions: divisions,
         onChanged: onValueChanged,
      );

      return <Widget>[sld];
   }

   final double max2 = max / divisions;

   final double value2 = value % max2;

   Slider sld1 = Slider(
      value: value,
      min: min,
      max: max,
      divisions: divisions,
      onChanged: (double v) {
         double vv = v + value2;
         if (vv > max)
            vv = max;
         onValueChanged(vv);
      },
   );

   final double offset = value - value2;

   Slider sld2 = Slider(
      value: value2,
      min: 0,
      max: max2,
      divisions: divisions,
      onChanged: (double v) {
         double vv = offset + v;
         if (vv > max)
            vv = max;
         onValueChanged(vv);
      },
   );

   return <Widget>[sld2, sld1];
}

List<Widget> makeCheckBoxes(
      final int state,
      final List<String> items,
      final OnPressedFn13 onChanged,
) {
   List<Widget> ret = List<Widget>();

   for (int i = 0; i < items.length; ++i) {
      final bool v = ((state & (1 << i)) != 0);
      CheckboxListTile tmp = CheckboxListTile(
         dense: true,
         title: Text(items[i], style: stl.newPostTreeLT),
         value: v,
         onChanged: (bool v) { onChanged(v, i); },
         activeColor: stl.colorScheme.primary,
	 isThreeLine: false,
      );

      ret.add(tmp);
   }

   return ret;
}

List<Widget> makeNewPostDetailScreen(
   Function onExDetail,
   Function onInDetail,
   Post post,
   Node exDetailsRootNode,
   Node inDetailsRootNode,
   TextEditingController txtCtrl,
   Function onRangeValueChanged,
) {
   final int idx = post.getProductDetailIdx();
   if (idx == -1)
      return List<Widget>();

   List<String> exDetailsNames = makeExDetailsNamesAll(
      exDetailsRootNode,
      post.exDetails,
      post.getProductDetailIdx(),
      g.param.langIdx,
   );

   List<Widget> all = List<Widget>();

   final int l1 = exDetailsRootNode.children[idx].children.length;
   for (int i = 0; i < l1; ++i) {
      Widget foo = makeNewPostDetailExpTile(
         (int j) {onExDetail(i, j);},
         exDetailsRootNode.children[idx].children[i],
         post.exDetails[i],
         exDetailsNames[i],
      );

      all.add(foo);
   }

   final int l2 = inDetailsRootNode.children[idx].children.length;
   for (int i = 0; i < l2; ++i) {
      final int nBitsSet = counterBitsSet(post.inDetails[i]);
      Widget foo = makeNewPostDetailExpTile(
         (int j) {onInDetail(i, j);},
         inDetailsRootNode.children[idx].children[i],
         post.inDetails[i],
         '$nBitsSet items',
      );

      all.add(foo);
   }

   for (int i = 0; i < g.param.rangeDivs.length; ++i) {
      final int j = 2 * i;

      List<Widget> col = makeSliderList(
         value: post.rangeValues[i].toDouble(),
         min: g.param.rangesMinMax[j + 0].toDouble(),
         max: g.param.rangesMinMax[j + 1].toDouble(),
         divisions: g.param.rangeDivs[i],
         onValueChanged: (double v) {onRangeValueChanged(i, v);}
      );

      Column sliderCol = Column(children: col);

      all.add(wrapOnDetailExpTitle(
            makeExpTileTitle(
               g.param.rangePrefixes[i],
               post.rangeValues[i].toString(),
               ':',
               false,
            ),
            <Widget>[wrapDetailRowOnCard(sliderCol)],
            false,
         ),
      );
   }

   // __________________________________________________
   TextField tf = TextField(
      controller: txtCtrl,
      keyboardType: TextInputType.multiline,
      maxLines: null,
      maxLength: 200,
      style: stl.textField,
      decoration: InputDecoration.collapsed(
         hintText: g.param.newPostTextFieldHist,
      ),
   );

   Padding pad = Padding(
      padding: EdgeInsets.all(10.0),
      child: tf,
   );

   all.add(wrapOnDetailExpTitle(
         Text(g.param.postDescTitle, style: stl.tsSubheadOnPrimary),
         <Widget>[wrapDetailRowOnCard(pad)],
         false,
      ),
   );

   all.add(
      createRaisedButton(
         (){onExDetail(-1, -1);},
         g.param.next,
	 stl.colorScheme.secondary,
	 stl.colorScheme.onSecondary,
      ),
   );

   return all;
}

Widget makeNewPostFinalScreen({
   BuildContext ctx,
   final Post post,
   final List<Tree> trees,
   final Node exDetailsRootNode,
   final Node inDetailsRootNode,
   final List<File> imgFiles,
   final OnPressedFn2 onAddPhoto,
   final OnPressedFn4 onPublishPost,
   final OnPressedFn4 onRemovePost,
}) {

   // NOTE: This ListView is used to provide a new context, so that
   // it is possible to show the snackbar using the scaffold.of on
   // the new context.

   Widget w0 = makeNewPost(
      ctx: ctx,
      screen: cts.ownIdx,
      snackbarStr: g.param.cancelNewPost,
      post: post,
      exDetailsRootNode: exDetailsRootNode,
      inDetailsRootNode: inDetailsRootNode,
      trees: trees,
      imgFiles: imgFiles,
      onAddPhoto: onAddPhoto,
      onExpandImg: (int j){ print('Noop00'); },
      onAddPostToFavorite: () { print('Noop01'); },
      onDelPost: () { print('Noop02');},
      onSharePost: () { print('Noop03');},
      onReportPost: () { print('Noop05');},
      onPinPost: () { print('Noop06');},
   );

   Widget w1 = createRaisedButton(
      () {onRemovePost(ctx);},
      g.param.cancel,
      stl.expTileCardColor,
      Colors.black,
   );

   Widget w2 = createRaisedButton(
      () { onPublishPost(ctx); },
      g.param.newPostAppBarTitle,
      stl.colorScheme.secondary,
      stl.colorScheme.onSecondary,
   );

   Row r = Row(children: <Widget>[Expanded(child: w1), Expanded(child: w2)]);

   Widget tmp = Padding(
      padding: EdgeInsets.only(top: 30.0, bottom: 30.0),
      child: r,
   );

   return Column(children: <Widget>[w0, tmp]);
}

List<Widget> makeTabActions({
   int screen,
   bool newPostPressed,
   bool hasLPChats,
   bool hasLPChatMsgs,
   OnPressedFn0 deleteChatDialog,
   OnPressedFn0 pinChats,
   OnPressedFn0 onClearPostsDialog,
}) {
   final bool fav = screen == cts.favIdx;
   final bool own = screen == cts.ownIdx;
   final bool search = screen == cts.searchIdx;

   List<Widget> ret = List<Widget>();
   if (own) {
      if (newPostPressed) {
      } else if (hasLPChats && !hasLPChatMsgs) {
	 ret = makeOnLongPressedActions(deleteChatDialog, pinChats);
      }
   } else if (fav) {
      if (hasLPChats && !hasLPChatMsgs) {
	 IconButton delChatBut = IconButton(
	    icon: Icon(
	       Icons.delete_forever,
	       color: stl.colorScheme.onPrimary,
	    ),
	    tooltip: g.param.deleteChat,
	    onPressed: deleteChatDialog,
	 );

	 ret.add(delChatBut);
      }
   } else if (search) {
      IconButton clearPosts = IconButton(
	 icon: Icon(
	    Icons.delete_forever,
	    color: stl.colorScheme.onPrimary,
	 ),
	 tooltip: g.param.clearPosts,
	 onPressed: onClearPostsDialog,
      );

      ret.add(clearPosts);
   }

   return ret;
}

List<Widget> makeGlobalActionsWeb({
   OnPressedFn0 onSearchPressed,
   OnPressedFn0 onNewPost,
   Function onAppBarVertPressed,
}) {
   List<Widget> ret = List<Widget>();

   IconButton searchButton = IconButton(
      icon: Icon(
	 Icons.search,
	 color: stl.colorScheme.onPrimary,
      ),
      tooltip: g.param.notificationsButton,
      onPressed: onSearchPressed,
   );

   IconButton publishButton = IconButton(
      icon: Icon(
	 stl.newPostIcon,
	 color: stl.colorScheme.onPrimary,
      ),
      onPressed: onNewPost,
   );

   //ret.add(publishButton);
   //ret.add(searchButton);
   ret.add(makeAppBarVertAction(onAppBarVertPressed));

   return ret;
}

List<Widget> makeGlobalActionsApp({
   bool hasLPChats,
   bool hasLPChatMsgs,
   OnPressedFn0 onSearchPressed,
   OnPressedFn0 onNewPost,
   Function onAppBarVertPressed,
}) {
   // We only add the global action buttons if
   // 1. There is no chat selected for selection.
   // 2. We are not forwarding a message.
   if (!hasLPChats && !hasLPChatMsgs)
      return makeGlobalActionsWeb(
	 onSearchPressed: onSearchPressed,
	 onNewPost: onNewPost,
	 onAppBarVertPressed: onAppBarVertPressed,
      );

   return List<Widget>();
}

Widget makeAppBarLeading({
   final bool hasLpChats,
   final bool hasLpChatMsgs,
   final bool newPostPressed,
   final bool newSearchPressed,
   final int screen,
   final OnPressedFn0 onWillLeaveSearch,
   final OnPressedFn0 onWillLeaveNewPost,
   final OnPressedFn0 onBackFromChatMsgRedirect,
}) {
   final bool own = screen == cts.ownIdx;
   final bool search = screen == cts.searchIdx;
   final bool fav = screen == cts.favIdx;

   if ((fav || own) && hasLpChatMsgs)
      return IconButton(
	 icon: Icon(Icons.arrow_back),
	 onPressed: onBackFromChatMsgRedirect,
      );

   if (own && newPostPressed)
      return IconButton(
	 icon: Icon(Icons.arrow_back, color: stl.colorScheme.secondary),
	 onPressed: onWillLeaveNewPost,
      );

   if (search && newSearchPressed)
      return IconButton(
	 icon: Icon(Icons.arrow_back),
	 onPressed: onWillLeaveSearch,
      );

   return null;
}

Widget makeAppBarWdg({
   bool hasLpChatMsgs,
   bool newPostPressed,
   bool newSearchPressed,
   final int botBarIndex,
   final int screen,
   final List<Tree> trees,
   Widget defaultWdg,
}) {
   final bool fav = screen == cts.favIdx;
   final bool own = screen == cts.ownIdx;
   final bool search = screen == cts.searchIdx;

   if ((fav || own) && hasLpChatMsgs)
      return Text(g.param.msgOnRedirectingChat);

   if (own && newPostPressed)
      return makeSearchAppBar(
	 screen: botBarIndex,
	 trees: trees,
	 title: g.param.newPostAppBarTitle,
      );

   if (search && newSearchPressed)
      return makeSearchAppBar(
	 screen: botBarIndex,
	 trees: trees,
	 title: g.param.filterAppBarTitle,
      );

   return defaultWdg;
}

BottomNavigationBar makeBotNavBar({
   int botBarIndex,
   bool newPostPressed,
   bool newSearchPressed,
   int screen,
   OnPressedFn1 onNewPostBotBarTapped,
   OnPressedFn1 onSearchBotBarPressed,
}) {
   if ((screen == cts.ownIdx) && newPostPressed)
      return null;

   if ((screen == cts.searchIdx) && newSearchPressed)
      return makeBottomBarItems(
	 stl.filterTabIcons,
	 g.param.filterTabNames,
	 onSearchBotBarPressed,
	 botBarIndex,
      );

   return null;
}

Widget makeNewPostLT({
   final String title,
   final String subTitle,
   final IconData icon,
   OnPressedFn0 onTap,
}) {
   Widget leading;
   if (icon != null)
      leading = CircleAvatar(
	  child: Icon(icon,
	     color: stl.colorScheme.primary,
	  ),
	  backgroundColor: Colors.white,
       );
      
   return ListTile(
       contentPadding: EdgeInsets.all(3.0),
       leading: leading,
       title: Text(title,
	  maxLines: 1,
	  overflow: TextOverflow.clip,
	  style: stl.newPostSubtitleLT,
       ),
       dense: true,
       subtitle:
	  Text(subTitle,
	     maxLines: 1,
	     overflow: TextOverflow.clip,
	     style: stl.newPostTreeLT,
	  ),
       onTap: onTap,
       enabled: true,
       isThreeLine: false,
    );
}

ListView makeNewPostListView(List<Widget> list)
{
   return ListView.builder(
      itemCount: list.length,
      itemBuilder: (BuildContext ctx, int i)
      {
	 return list[i];
      },
   );
}

Widget makeNewPostScreenWdgs2({
   BuildContext ctx,
   final bool filenamesTimerActive,
   final Tree locationTree,
   final Tree productTree,
   final Node exDetailsRootNode,
   final Node inDetailsRootNode,
   final Post post,
   TextEditingController txtCtrl,
   final OnPressedFn12 onSetLocTreeCode,
   final OnPressedFn3 onSetExDetail,
   final OnPressedFn3 onSetInDetail,
   final List<File> imgFiles,
   final OnPressedFn2 onAddPhoto,
   final OnPressedFn4 onPublishPost,
   final OnPressedFn4 onRemovePost,
}) {
   const double leftIndent = 10.0;
   Divider div = Divider(
      color: Colors.grey,
      height: 2.0,
      indent: leftIndent,
      endIndent: leftIndent,
      thickness: 1.0,
   );

   final Node locRootNode = locationTree.root.first;
   final Node productRootNode = productTree.root.first;

   List<Widget> list = List<Widget>();

   { // Location
      List<int> locCode = post.getLocationCode();
      String locSubtitle = g.param.unknownNick;
      if (locCode.isNotEmpty)
	 locSubtitle = loadNames(locRootNode, locCode, g.param.langIdx).join(', ');

      Widget location = makeNewPostLT(
	 title: g.param.newPostTabNames[0],
	 subTitle: locSubtitle,
	 icon: Icons.edit_location,
	 onTap: () async
	 {
	    final List<int> code = await showDialog<List<int>>(
	       context: ctx,
	       builder: (BuildContext ctx2) { return TreeView(root: locRootNode); },
	    );

	    onSetLocTreeCode(code, 0);
	 },
      );

      list.add(location);
      list.add(div);
   }

   if (post.getLocationCode().isEmpty)
      return makeNewPostListView(list);

   { // Product
      List<int> productCode = post.getProductCode();
      String productSubtitle = g.param.unknownNick;
      if (productCode.isNotEmpty)
	 productSubtitle = loadNames(productRootNode, productCode, g.param.langIdx).join(', ');

      Widget product = makeNewPostLT(
	 title: g.param.newPostTabNames[1],
	 subTitle: productSubtitle,
	 icon: Icons.directions_car,
	 onTap: () async
	 {
	    final List<int> code = await showDialog<List<int>>(
	       context: ctx,
	       builder: (BuildContext ctx2) { return TreeView(root: productRootNode); },
	    );

	    if (code != null)
	       onSetLocTreeCode(code, 1);
	 },
      );

      list.add(product);
      list.add(div);
   }

   // ---------------------------------------------------

   final int productIdx = post.getProductDetailIdx();
   if (productIdx != -1) {

      { // exDetails
	 final int nDetails = getNumberOfProductDetails(exDetailsRootNode, productIdx);
	 for (int i = 0; i < nDetails; ++i) {
	    final int length = productDetailLength(exDetailsRootNode, productIdx, i);
	    final int k = post.exDetails[i] < length ? post.exDetails[i] : 0;

	    final List<String> names = loadNames(
               exDetailsRootNode,
	       <int>[productIdx, i, k],
	       g.param.langIdx,
	    );

	    final List<String> detailStrs = listAllDetails(
               exDetailsRootNode,
	       productIdx,
	       i,
	       g.param.langIdx,
	    );

	    Widget exDetailWdg = makeNewPostLT(
	       title: names[1],
	       subTitle: names[2],
	       icon: null,
	       onTap: () async
	       {
	          final int state = await showDialog<int>(
	             context: ctx,
	             builder: (BuildContext ctx2)
	             {
	        	return ExDetailsView(
	        	   title: names[1],
	        	   names: detailStrs,
	        	   onIdx: k,
	        	);
	             },
	          );

	          if (state != null)
	             onSetExDetail(i, state);
	       },
	    );

	    list.add(Padding(padding: EdgeInsets.only(left: leftIndent), child: exDetailWdg));
	    list.add(div);
	 }
      }

      { // inDetails
	 final int nDetails = inDetailsRootNode.children[productIdx].children.length;
	 for (int i = 0; i < nDetails; ++i) {
	    final List<String> detailStrs = listAllDetails(
               inDetailsRootNode,
	       productIdx,
	       i,
	       g.param.langIdx,
	    );

	    List<String> subtitles = makeInDetailNames(
               inDetailsRootNode,
	       post.inDetails[i],
	       productIdx, i,
	       g.param.langIdx,
	    );

	    final String subtitle = subtitles.join(', ');;

	    final String title =
	       inDetailsRootNode.children[productIdx].children[i].name(g.param.langIdx);

	    Widget inDetailWdg = makeNewPostLT(
	       title: title,
	       subTitle: subtitle,
	       icon: null,
	       onTap: () async
	       {
		  final int state = await showDialog<int>(
		     context: ctx,
		     builder: (BuildContext ctx2)
		     {
			return InDetailsView(
			      state: post.inDetails[i],
			      title: title,
			      names: detailStrs,
			);
		     },
		  );

		  if (state != null)
		     onSetInDetail(i, state);
	       },
	    );

	    list.add(Padding(padding: EdgeInsets.only(left: leftIndent), child: inDetailWdg));
	    list.add(div);
	 }
      }

      { // Description
	 TextField tf = TextField(
	    controller: txtCtrl,
	    keyboardType: TextInputType.multiline,
	    maxLines: null,
	    maxLength: 300,
	    style: stl.textField,
	    decoration: InputDecoration.collapsed(
	       hintText: g.param.newPostTextFieldHist,
	    ),
	 );

	 Padding pad = Padding(
	    padding: EdgeInsets.all(10.0),
	    child: tf,
	 );

	 list.add(pad);
	 list.add(div);
      }

      // ---------------------------------------------------

      { // Title
	 Text pageTitle = Text('Review and send',
	    style: TextStyle(
	       fontSize: 18.0,
	       color: stl.colorScheme.primary,
	       fontWeight: FontWeight.w500,
	    ),
	 );

	 Padding tmp = Padding(
	    child: pageTitle,
	   padding: EdgeInsets.only(top: 20.0, bottom: 20.0),
	 );

	 list.add(Center(child: tmp));
      }

   // ----------------------------------

      { // final
	 Widget finalScreen = makeNewPostFinalScreen(
	    ctx: ctx,
	    post: post,
	    trees: <Tree>[locationTree, productTree],
	    exDetailsRootNode: exDetailsRootNode,
	    inDetailsRootNode: inDetailsRootNode,
	    imgFiles: imgFiles,
	    onAddPhoto: onAddPhoto,
	    onPublishPost: onPublishPost,
	    onRemovePost: onRemovePost,
	 );

	 Card c = Card(
	    margin: const EdgeInsets.all(0.0),
	    color: Colors.white,
	    child: finalScreen,
	    elevation: 2.0,
	    shape: RoundedRectangleBorder(
	       borderRadius: BorderRadius.all(Radius.circular(0.0)),
	    ),
	 );

	 list.add(finalScreen);
      }

   } // ------------------------

   final Widget lv = makeNewPostListView(list);

   if (!filenamesTimerActive)
      return lv;

   List<Widget> ret = List<Widget>();
   ret.add(lv);

   ModalBarrier mb = ModalBarrier(
      color: Colors.grey.withOpacity(0.4),
      dismissible: false,
   );

   ret.add(mb);
   ret.add(Center(child: CircularProgressIndicator()));

   return Stack(children: ret);
}

Widget makeNewPostScreenWdgs({
   BuildContext ctx,
   final Post post,
   final List<Tree> trees,
   final TextEditingController txtCtrl,
   final int navBar,
   final Node exDetailsRootNode,
   final Node inDetailsRootNode,
   final List<File> imgFiles,
   final bool filenamesTimerActive,
   final OnPressedFn3 onExDetail,
   final OnPressedFn1 onPostLeafPressed,
   final OnPressedFn1 onPostNodePressed,
   final OnPressedFn3 onInDetail,
   final OnPressedFn8 onRangeValueChanged,
   final OnPressedFn2 onAddPhoto,
   final OnPressedFn4 onPublishPost,
   final OnPressedFn4 onRemovePost,
}) {
   List<Widget> list = List<Widget>();
   if (navBar == 3) {
      Widget finalScreen = makeNewPostFinalScreen(
	 ctx: ctx,
	 post: post,
	 trees: trees,
	 exDetailsRootNode: exDetailsRootNode,
	 inDetailsRootNode: inDetailsRootNode,
	 imgFiles: imgFiles,
	 onAddPhoto: onAddPhoto,
	 onPublishPost: onPublishPost,
	 onRemovePost: onRemovePost,
      );

      list.add(finalScreen);

   } else if (navBar == 2) {
      final List<Widget> widgets = makeNewPostDetailScreen(
         onExDetail,
         onInDetail,
         post,
         exDetailsRootNode,
         inDetailsRootNode,
         txtCtrl,
         onRangeValueChanged,
      );

      // Consider changing this to column.
      ListView wid = ListView.builder(
         padding: const EdgeInsets.only(
            left: stl.postListViewSidePadding,
            right: stl.postListViewSidePadding,
            top: stl.postListViewTopPadding,
         ),
         itemCount: widgets.length,
         itemBuilder: (BuildContext ctx, int i)
         {
            return widgets[i];
         },
      );

      list.add(wid);
   } else {
      ListView wid = makeNewPostTreeLV(
         trees[navBar].root.last,
         onPostLeafPressed,
         onPostNodePressed,
      );

      list.add(wid);
   }

   if (filenamesTimerActive) {
      ModalBarrier mb = ModalBarrier(
         color: Colors.grey.withOpacity(0.4),
         dismissible: false,
      );
      list.add(mb);
      list.add(Center(child: CircularProgressIndicator()));
   }

   return Stack(children: list);
}

Widget makeSearchFinalScreen(OnPressedFn1 onPressed)
{
   // See the comment in _onPostSelection for why I removed the middle
   // button for now.
   return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      //mainAxisSize: MainAxisSize.min,
      children: <Widget>
      [ Padding(
          padding: const EdgeInsets.symmetric(vertical: 40.0),
          child: createRaisedButton(
             () {onPressed(0);},
             g.param.newFiltersFinalScreenButton[0],
	     stl.expTileCardColor,
	     Colors.black,
          ),
	)
      , Padding(
          padding: const EdgeInsets.symmetric(vertical: 40.0),
          child: createRaisedButton(
             () {onPressed(2);},
             g.param.newFiltersFinalScreenButton[2],
	     stl.colorScheme.secondary,
	     stl.colorScheme.onSecondary,
          ),
	)
      ]
   );
}

Widget makeSearchAppBar({
   final int screen,
   final List<Tree> trees,
   final String title,
}) {
   assert(screen < 4);

   if (screen == 3 || screen == 2)
      return Text(title, style: stl.appBarLtTitle);

   return ListTile(
      dense: true,
      title: Text(title,
	 maxLines: 1,
	 overflow: TextOverflow.clip,
	 style: stl.appBarLtTitle.copyWith(color: stl.colorScheme.secondary),
      ),
      //subtitle: Text(trees[screen].getStackNames(),
      //   maxLines: 1,
      //   overflow: TextOverflow.clip,
      //   style: stl.appBarLtSubtitle,
      //),
   );
}

Widget makeSearchScreenWdg({
   final int filter,
   final int screen,
   final Node exDetailsFilterNodes,
   final List<Tree> trees,
   final List<int> ranges,
   final OnPressedFn1 onSendFilters,
   final OnPressedFn1 onFilterDetail,
   final OnPressedFn1 onFilterNodePressed,
   final OnPressedFn1 onFilterLeafNodePressed,
   final OnPressedFn6 onRangeChanged,
}) {
   if (screen == 3)
      return makeSearchFinalScreen(onSendFilters);

   if (screen == 2) {
      List<Widget> foo = List<Widget>();

      final Widget vv = makeNewPostDetailExpTile(
         onFilterDetail,
         exDetailsFilterNodes,
         filter,
         '',
      );

      foo.add(vv);

      for (int i = 0; i < g.param.discreteRanges.length; ++i) {
         final int vmin = ranges[2 * i + 0];
         final int vmax = ranges[2 * i + 1];

         final int l = g.param.discreteRanges[i].length - 1;

         final Widget rs = RangeSlider(
            min: 0,
            max: l.toDouble(),
            divisions: g.param.discreteRanges[i].length,
            onChanged: (RangeValues rv) {onRangeChanged(i, rv);},
            values: RangeValues(vmin.toDouble(), vmax.toDouble()),
         );

         final int vmin2 = g.param.discreteRanges[i][vmin];
         final int vmax2 = g.param.discreteRanges[i][vmax];

         final String rangeTitle = '$vmin2 - $vmax2';
         final RichText rt = makeExpTileTitle(
            g.param.rangePrefixes[i],
            rangeTitle,
            ':',
            false,
         );

         foo.add(wrapOnDetailExpTitle(rt, <Widget>[rs], false));
      }

      return ListView.builder(
         padding: const EdgeInsets.all(3.0),
         itemCount: foo.length,
         itemBuilder: (BuildContext ctx, int i) { return foo[i]; },
      );
   }

   return makeNewFilterListView(
      trees[screen].root.last,
      onFilterLeafNodePressed,
      onFilterNodePressed,
      trees[screen].isFilterLeaf(),
   );
}

Widget wrapDetailRowOnCard(Widget body)
{
   return Card(
      margin: const EdgeInsets.only(
       left: 1.5, right: 1.5, top: 0.0, bottom: 0.0
      ),
      color: stl.colorScheme.background,
      child: body,
      elevation: 0.0,
      shape: RoundedRectangleBorder(
         borderRadius: BorderRadius.all(Radius.circular(0.0)),
      ),
   );
}

List<Widget> makeNewPostDetailElemList(
   Function proceed,
   int filter,
   List<Node> list,
) {
   List<Widget> widgets = List<Widget>();

   for (int i = 0; i < list.length; ++i) {
      bool v = ((filter & (1 << i)) != 0);

      Color avatarBgColor = stl.colorScheme.secondary;
      Color avatarTxtColor = stl.colorScheme.onSecondary;
      if (v) {
         avatarBgColor = stl.colorScheme.primary;
         avatarTxtColor = stl.colorScheme.onPrimary;
      }

       CheckboxListTile cblt = CheckboxListTile(
         dense: true,
         secondary: CircleAvatar(
            child: Text(makeStrAbbrev(list[i].name(g.param.langIdx)),
               style: TextStyle(color: avatarTxtColor)
            ),
            backgroundColor: avatarBgColor
         ),
         title: Text(list[i].name(g.param.langIdx), style: stl.ltTitle),
         value: v,
         onChanged: (bool v) { proceed(i); },
         activeColor: stl.colorScheme.primary,
      );

       widgets.add(wrapDetailRowOnCard(cblt));
   }

   return widgets;
}

class MyApp extends StatelessWidget {
   @override
   Widget build(BuildContext ctx) {
      return MaterialApp(
         title: g.param.appName,
         theme: ThemeData(
            colorScheme: stl.colorScheme,
            brightness: stl.colorScheme.brightness,
            primaryColor: stl.colorScheme.primary,
            accentColor: stl.colorScheme.secondary,
         ),
         debugShowCheckedModeBanner: false,
         home: Occase(),
            localizationsDelegates: [
               GlobalMaterialLocalizations.delegate,
               GlobalWidgetsLocalizations.delegate,
               GlobalCupertinoLocalizations.delegate,
            ],
         supportedLocales: [
            const Locale('de'),
            const Locale('pt'),
            const Locale('es'),
            const Locale('fr'),
         ],
      );
   }
}

Widget makeAppScaffoldWdg({
   OnPressedFn7 onWillPops,
   BottomNavigationBar bottomNavBar,
   ScrollController scrollCtrl,
   Widget appBarTitle,
   Widget appBarLeading,
   Widget floatBut,
   Widget body,
   TabBar tabBar,
   List<Widget> actions,
}) {
   return WillPopScope(
      onWillPop: () async { return onWillPops();},
      child: Scaffold(
	 bottomNavigationBar: bottomNavBar,
	 body: NestedScrollView(
	    controller: scrollCtrl,
	    body: body,
	    headerSliverBuilder: (BuildContext ctx, bool innerBoxIsScrolled)
	    {
	       return <Widget>[
		  SliverAppBar(
		     title: appBarTitle,
		     pinned: true,
		     floating: true,
		     forceElevated: innerBoxIsScrolled,
		     bottom: tabBar,
		     actions: actions,
		     leading: appBarLeading,
		  ),
	       ];
	    },
	 ),
	 backgroundColor: Colors.white,
	 floatingActionButton: floatBut,
      ),
   );
}

Widget makeWebScaffoldWdg({
   Widget body,
   Widget appBar,
   OnPressedFn7 onWillPopScope,
}) {
   return WillPopScope(
         onWillPop: () async { return onWillPopScope();},
         child: Scaffold(
            appBar : appBar,
            body: body,
            backgroundColor: Colors.white,
      ),
   );
}

List<Widget> makeTabWdgs({
   BuildContext ctx,
   List<int> counters,
   List<double> opacities,
}) {
   List<Widget> list = List<Widget>();

   for (int i = 0; i < g.param.tabNames.length; ++i) {
      Widget w = makeTabWidget(
	 ctx,
	 counters[i],
	 g.param.tabNames[i],
	 opacities[i]
      );

      list.add(w);
   }

   return list;
}

TabBar makeTabBar(
   BuildContext ctx,
   List<int> counters,
   TabController tabCtrl,
   List<double> opacities,
   bool isFwd,
) {
   if (isFwd)
      return null;

   List<Widget> wdgs = makeTabWdgs(
      ctx: ctx,
      counters: counters,
      opacities: opacities,
   );

   List<Widget> tabs = List<Widget>();
   for (int i = 0; i < wdgs.length; ++i)
      tabs.add(Tab(child: wdgs[i]));

   return TabBar(
      controller: tabCtrl,
      indicatorColor: Colors.white,
      tabs: tabs,
   );
}

BottomNavigationBar makeBottomBarItems(
   List<IconData> icons,
   List<String> iconLabels,
   OnPressedFn1 onBotBarTapped,
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
      onTap: onBotBarTapped,
   );
}

Widget makeFaButton(
   int nOwnPosts,
   OnPressedFn0 onNewPost,
   OnPressedFn0 onFwdChatMsg,
   int lpChats,
   int lpChatMsgs,
) {
   if (nOwnPosts != -1 && nOwnPosts == 0)
      return SizedBox.shrink();

   if (lpChats == 0 && lpChatMsgs != 0)
      return SizedBox.shrink();

   IconData id = stl.newPostIcon;
   if (lpChats != 0 && lpChatMsgs != 0) {
      return FloatingActionButton(
         backgroundColor: stl.colorScheme.secondary,
	 mini: false,
         child: Icon(
            Icons.send,
            color: stl.colorScheme.onSecondary,
         ),
         onPressed: onFwdChatMsg,
      );
   }

   if (lpChats != 0)
      return SizedBox.shrink();

   if (onNewPost == null)
      return SizedBox.shrink();

   return FloatingActionButton(
      backgroundColor: stl.colorScheme.secondary,
      mini: false,
      child: Icon(id,
         color: stl.colorScheme.onSecondary,
      ),
      onPressed: onNewPost,
   );
}

List<Widget> makeFaButtons({
   final int nOwnPosts,
   final bool newSearchPressed,
   final List<List<Coord>> lpChats,
   final List<List<Coord>> lpChatMsgs,
   final OnPressedFn0 onNewPost,
   final OnPressedFn1 onFwdSendButton,
   final OnPressedFn0 onSearch,
}) {
   List<Widget> ret = List<Widget>(g.param.tabNames.length);

   ret[0] = makeFaButton(
      nOwnPosts,
      onNewPost,
      () {onFwdSendButton(0);},
      lpChats[0].length,
      lpChatMsgs[0].length
   );

   ret[1] = makeFAButtonMiddleScreen(
      newSearchPressed,
      onSearch,
   );

   ret[2] = makeFaButton(
      -1,
      null,
      () {onFwdSendButton(2);},
      lpChats[2].length,
      lpChatMsgs[2].length,
   );

   return ret;
}

Widget makeFAButtonMiddleScreen(
   final bool onSearchScreen,
   final OnPressedFn0 onSearch,
) {
   if (onSearchScreen)
      return SizedBox.shrink();

   return FloatingActionButton(
      onPressed: onSearch,
      backgroundColor: stl.colorScheme.secondary,
      mini: false,
      child: Icon(
	 Icons.search,
	 color: stl.colorScheme.onSecondary,
      ),
   );
}

int postIndexHelper(int i)
{
   if (i == 0) return 1;
   if (i == 1) return 2;
   if (i == 2) return 3;
   return 1;
}

Widget putRefMsgInBorder(Widget w, Color borderColor)
{
   return Card(
      color: Colors.grey[200],
      elevation: 0.7,
      margin: const EdgeInsets.all(4.0),
      //shape: RoundedRectangleBorder(
      //   borderRadius: BorderRadius.all(Radius.circular(stl.cornerRadius)),
      //),
      child: Center(
         widthFactor: 1.0,
         child: Padding(
            child: w,
            padding: EdgeInsets.all(4.0),
         )
      ),
   );
}

Card makeChatMsgWidget(
   BuildContext ctx,
   ChatMetadata ch,
   int i,
   Function onChatMsgLongPressed,
   Function onDragChatMsg,
   bool isNewMsg,
   String ownNick,
) {
   Color txtColor = Colors.black;
   Color color = Color(0xFFFFFFFF);
   Color onSelectedMsgColor = Colors.grey[300];
   if (ch.msgs[i].isFromThisApp()) {
      color = Colors.lime[100];
   } else if (isNewMsg) {
      txtColor = stl.colorScheme.onPrimary;
      color = Color(0xFF0080CF);
   }

   if (ch.msgs[i].isLongPressed) {
      onSelectedMsgColor = Colors.blue[200];
      color = Colors.blue[100];
      txtColor = Colors.black;
   }

   RichText msgAndDate = RichText(
      text: TextSpan(
         text: ch.msgs[i].msg,
         style: stl.textField.copyWith(color: txtColor),
         children: <TextSpan>
         [ TextSpan(
              text: '  ${makeDateString(ch.msgs[i].date)}',
              style: Theme.of(ctx).textTheme.caption.copyWith(
                 color: Colors.grey[700],
              ),
           ),
         ]
      ),
   );

   // Unfortunately TextSpan still does not support general
   // widgets so I have to put the msg status in a row instead
   // of simply appending it to the richtext as I do for the
   // date. Hopefully this will be fixed this later.
   Widget msgAndStatus;
   if (ch.msgs[i].isFromThisApp()) {
      msgAndStatus = Row(
         mainAxisSize: MainAxisSize.min,
         mainAxisAlignment: MainAxisAlignment.end,
         children: <Widget>
      [ Flexible(child: Padding(
            padding: EdgeInsets.all(stl.chatMsgPadding),
            child: msgAndDate))
      , Padding(
            padding: EdgeInsets.all(2.0),
            child: chooseMsgStatusIcon(ch.msgs[i].status))
      ]);
   } else {
      msgAndStatus = Padding(
            padding: EdgeInsets.all(stl.chatMsgPadding),
            child: msgAndDate);
   }

   Widget ww = msgAndStatus;
   if (ch.msgs[i].redirected()) {
      final Color redirTitleColor =
         isNewMsg ? stl.colorScheme.secondary : Colors.blueGrey;

      Row redirWidget = Row(
         mainAxisSize: MainAxisSize.min,
         mainAxisAlignment: MainAxisAlignment.start,
         crossAxisAlignment: CrossAxisAlignment.center,
         textBaseline: TextBaseline.alphabetic,
         children: <Widget>
         [ Icon(Icons.forward, color: stl.chatDateColor)
         , Text(g.param.msgOnRedirectedChat,
            style: TextStyle(color: redirTitleColor,
               fontSize: stl.listTileSubtitleFontSize,
               fontStyle: FontStyle.italic),
           )
         ]
      );

      ww = Column( children: <Widget>
         [ Padding(
              padding: EdgeInsets.all(3.0),
              child: redirWidget)
         , msgAndStatus
         ]);
   } else if (ch.msgs[i].refersToOther()) {
      final int refersTo = ch.msgs[i].refersTo;
      final Color c1 = selectColor(int.parse(ch.peer));

      Widget refWidget = makeRefChatMsgWidget(
         ctx,
         ch,
         refersTo,
         c1,
         isNewMsg,
         ownNick,
      );

      Row refMsg = Row(
         mainAxisSize: MainAxisSize.min,
         crossAxisAlignment: CrossAxisAlignment.start,
         children: <Widget>
         [ Flexible(child: putRefMsgInBorder(refWidget, stl.chatDateColor)),
         ],
      );

      ww = Column(
         mainAxisSize: MainAxisSize.min,
         crossAxisAlignment: CrossAxisAlignment.start,
         children: <Widget>
         [ refMsg
         , msgAndStatus
         ]);
   }

   double marginLeft = 10.0;
   double marginRight = 0.0;
   if (ch.msgs[i].isFromThisApp()) {
      double tmp = marginLeft;
      marginLeft = marginRight;
      marginRight = tmp;
   }

   final double screenWidth = makeWidth(ctx);
   Card w1 = Card(
      margin: EdgeInsets.only(
            left: marginLeft,
            top: 2.0,
            right: marginRight,
            bottom: 0.0),
      elevation: 0.7,
      color: color,
      child: Center(
         widthFactor: 1.0,
         child: ConstrainedBox(
            constraints: BoxConstraints(
               maxWidth: 0.75 * screenWidth,
               minWidth: 0.20 * screenWidth,
            ),
            child: ww)));

   Row r;
   if (ch.msgs[i].isFromThisApp()) {
      r = Row(children: <Widget>
      [ Spacer()
      , w1
      ]);
   } else {
      r = Row(children: <Widget>
      [ w1
      , Spacer()
      ]);
   }

   return Card(
      child: r,
      color: onSelectedMsgColor,
      elevation: 0.0,
      margin: const EdgeInsets.all(0.0),
      shape: RoundedRectangleBorder(
         borderRadius: BorderRadius.all(Radius.circular(0.0)),
      ),
   );
}

ListView makeChatMsgListView(
   ScrollController scrollCtrl,
   ChatMetadata ch,
   Function onChatMsgLongPressed,
   Function onDragChatMsg,
   String ownNick,
) {
   final int nMsgs = ch.msgs.length;
   final int shift = ch.divisorUnreadMsgs == 0 ? 0 : 1;

   return ListView.builder(
      controller: scrollCtrl,
      reverse: false,
      padding: const EdgeInsets.only(bottom: 3.0, top: 3.0),
      itemCount: nMsgs + shift,
      itemBuilder: (BuildContext ctx, int i)
      {
         if (shift == 1) {
            if (i == ch.divisorUnreadMsgsIdx) {
               return Card(
                  color: Colors.white,
                  margin: const EdgeInsets.symmetric(vertical: 10.0),
                  shape: RoundedRectangleBorder(
                     borderRadius: BorderRadius.all(Radius.circular(0.0)),
                  ),
                  child: Center(
                      child: Padding(
                         padding: EdgeInsets.all(3.0),
                         child: Text(
                            '${ch.divisorUnreadMsgs}',
                            style: TextStyle(
                               fontSize: 17.0,
                               fontWeight: FontWeight.normal,
                               color:
                               stl.colorScheme.primary,
                            ),
                         )
                      ),
                   ),
               );
            }

            if (i > ch.divisorUnreadMsgsIdx)
               i -= 1; // For the shift
         }

         final bool isNewMsg =
            shift == 1 &&
            i >= ch.divisorUnreadMsgsIdx &&
            i < ch.divisorUnreadMsgsIdx + ch.divisorUnreadMsgs;
                               
         Card chatMsgWidget = makeChatMsgWidget(
            ctx,
            ch,
            i,
            onChatMsgLongPressed,
            onDragChatMsg,
            isNewMsg,
            ownNick,
         );

         return GestureDetector(
            onLongPress: () {onChatMsgLongPressed(i, false);},
            onTap: () {onChatMsgLongPressed(i, true);},
            onHorizontalDragStart: (DragStartDetails d) {onDragChatMsg(ctx, i, d);},
            child: chatMsgWidget);
      },
   );
}

Card makeChatScreenBotCard(Widget w1, Widget w1a, Widget w2,
                           Widget w3, Widget w4)
{
   const double padding = 10.0;
   const EdgeInsets ei = const EdgeInsets.symmetric(horizontal: padding);
   Padding placeholder = Padding(
      child: Icon(Icons.send, color: Colors.white),
         padding: ei);

   List<Widget> widgets = List<Widget>();
   if (w1 == null) {
      widgets.add(placeholder);
   } else {
      widgets.add(Padding(child: w1, padding: ei));
   }

   if (w1a != null)
      widgets.add(w1a);

   widgets.add(Expanded(
      child: Padding(child: w2, padding: ei)));

   if (w3 == null) {
      widgets.add(placeholder);
   } else {
      widgets.add(Padding(child: w3, padding: ei));
   }

   if (w4 == null) {
      widgets.add(placeholder);
   } else {
      widgets.add(Padding(child: w4, padding: ei));
   }

   Row rr = Row(children: widgets);

   return Card(
      elevation: 0.0,
      shape: RoundedRectangleBorder(
         borderRadius: BorderRadius.all(Radius.circular(0.0))),
      margin: EdgeInsets.all(0.0),
      color: Colors.white,
      child: Padding(
         padding: EdgeInsets.all(4.0),
         child: ConstrainedBox(
            constraints: BoxConstraints(
            maxHeight: 140.0,
            minHeight: 45.0),
            child: rr)));
}

Widget makeRefChatMsgWidget(
   BuildContext ctx,
   ChatMetadata ch,
   int i,
   Color cc,
   bool isNewMsg,
   String ownNick,
) {
   Color titleColor = cc;
   Color bodyTxtColor = Colors.black;
   
   if (isNewMsg) {
      titleColor = stl.colorScheme.secondary;
      //bodyTxtColor = Colors.grey[300];
   }

   Text body = Text(ch.msgs[i].msg,
      maxLines: 3,
      overflow: TextOverflow.clip,
      style: Theme.of(ctx).textTheme.caption.copyWith(
         color: bodyTxtColor,
      ),
   );

   String nick = ch.nick;
   if (ch.msgs[i].isFromThisApp())
      nick = ownNick;

   Text title = Text(nick,
      maxLines: 1,
      overflow: TextOverflow.clip,
      style: TextStyle(
         fontSize: stl.mainFontSize,
         fontWeight: FontWeight.bold,
         color: titleColor,
      ),
   );

   Column col = Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>
      [ Padding(
           child: title,
           padding: const EdgeInsets.symmetric(vertical: 3.0)
        )
      , body
      ]);

   return col;
}

Widget makeChatSecondLayer(
   BuildContext ctx,
   Function onChatSend,
   Function onAttachment)
{
   IconButton sendButton = IconButton(
      icon: Icon(Icons.send),
      onPressed: onChatSend,
      color: stl.colorScheme.primary,
   );

   IconButton attachmentButton = IconButton(
      icon: Icon(Icons.add_a_photo),
      onPressed: onAttachment,
      color: stl.colorScheme.primary,
   );

   // At the moment we do not support sending of multimedia files
   // through the chat, so I will remove the button attachmentButton.
   return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[Row(
         mainAxisSize: MainAxisSize.min,
         children: <Widget>[sendButton],
      )],
   );
}

Widget makeChatScreen(
   BuildContext ctx,
   ChatMetadata ch,
   TextEditingController ctrl,
   ScrollController scrollCtrl,
   int nLongPressed,
   FocusNode chatFocusNode,
   String postSummary,
   int dragedIdx,
   bool showChatJumpDownButton,
   String avatar,
   String ownNick,
   OnPressedFn7 onWillPopScope,
   OnPressedFn0 onSendChatMsg,
   OnPressedFn10 onChatMsgLongPressed,
   OnPressedFn0 onFwdChatMsg,
   OnPressedFn11 onDragChatMsg,
   OnPressedFn4 onChatMsgReply,
   OnPressedFn0 onAttachment,
   OnPressedFn0 onCancelFwdLPChatMsg,
   OnPressedFn0 onChatJumpDown,
   OnPressedFn9 onWritingChat,
) {
   Column secondLayer = makeChatSecondLayer(
      ctx,
      ctrl.text.isEmpty ? null : onSendChatMsg,
      onAttachment,
   );

   TextField tf = TextField(
       style: stl.textField,
       controller: ctrl,
       keyboardType: TextInputType.multiline,
       maxLines: null,
       maxLength: null,
       focusNode: chatFocusNode,
       onChanged: onWritingChat,
       decoration:
          InputDecoration.collapsed(hintText: g.param.chatTextFieldHint),
    );

   Scrollbar sb = Scrollbar(
       child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          reverse: true,
          child: tf));

   Card card = makeChatScreenBotCard(null, null, sb, null, null);

   ListView list = makeChatMsgListView(
      scrollCtrl,
      ch,
      onChatMsgLongPressed,
      onDragChatMsg,
      ownNick,
   );

   List<Widget> cols = List<Widget>();

   List<Widget> foo = List<Widget>();
   foo.add(list);

   if (showChatJumpDownButton) {
      Widget jumDownButton = Positioned(
         bottom: 20.0,
         right: 15.0,
         child: FloatingActionButton(
            mini: false,
            onPressed: onChatJumpDown,
            backgroundColor: stl.colorScheme.secondary,
            child: Icon(Icons.expand_more,
               color: stl.colorScheme.onSecondary,
            ),
         ),
      );

      foo.add(jumDownButton);

      if (ch.nUnreadMsgs > 0) {
         Widget jumDownButton = Positioned(
            bottom: 53.0,
            right: 23.0,
            child: makeUnreadMsgsCircle(
               ctx,
               ch.nUnreadMsgs,
               stl.colorScheme.secondaryVariant,
               stl.colorScheme.onSecondary,
            ),
         );

         foo.add(jumDownButton);
      }
   }

   Stack chatMsgStack = Stack(children: foo);

   cols.add(Expanded(child: chatMsgStack));

   if (dragedIdx != -1) {
      Color co1 = selectColor(int.parse(ch.peer));
      Icon w1 = Icon(Icons.forward, color: Colors.grey);

      // It looks like there is not maxlines option on TextSpan, so
      // for now I wont be able to show the date at the end.
      Widget w2 = Padding(
         padding: const EdgeInsets.symmetric(horizontal: 5.0),
         child: makeRefChatMsgWidget(
            ctx,
            ch,
            dragedIdx,
            co1,
            false,
            ownNick,
         ),
      );

      IconButton w4 = IconButton(
         icon: Icon(Icons.clear, color: Colors.grey),
         onPressed: onCancelFwdLPChatMsg);

      // C0001
      // NOTE: At the moment I do not know how to add the division bar
      // without fixing the height. That means on some rather short
      // text msgs there will be too much empty vertical space, that
      // do not look good. I will leave this out untill I find a
      // solution.
      //SizedBox sb = SizedBox(
      //   width: 4.0,
      //   height: 60.0,
      //   child: DecoratedBox(
      //     decoration: BoxDecoration(
      //       color: co1)));

      Card c1 = makeChatScreenBotCard(w1, null, w2, null, w4);
      cols.add(c1);
      cols.add(Divider(color: Colors.deepOrange, height: 0.0));
   }

   cols.add(card);

   Stack mainCol = Stack(children: <Widget>
   [ Column(children: cols)
   , Positioned(child: secondLayer, bottom: 1.0, right: 1.0)
   ]);

   List<Widget> actions = List<Widget>();
   Widget title;

   if (nLongPressed == 1) {
      IconButton reply = IconButton(
         icon: Icon(Icons.reply, color: Colors.white),
         onPressed: () {onChatMsgReply(ctx);});

      actions.add(reply);
   }

   if (nLongPressed > 0) {
      IconButton forward = IconButton(
         icon: Icon(Icons.forward, color: Colors.white),
         onPressed: onFwdChatMsg,
      );

      actions.add(forward);

      title = Text('$nLongPressed',
            maxLines: 1,
            overflow: TextOverflow.clip,
      );
   } else {
      Widget child;
      ImageProvider backgroundImage;
      if (avatar.isNotEmpty) {
         final String url = cts.gravatarUrl + avatar + '.jpg';
         backgroundImage = CachedNetworkImageProvider(url);
      } else {
         child = stl.unknownPersonIcon;
      }

      ChatPresenceSubtitle cps = makeLTPresenceSubtitle(
         ch,
         postSummary,
         stl.onPrimarySubtitleColor,
      );

      title = ListTile(
          contentPadding: EdgeInsets.all(0.0),
          leading: CircleAvatar(
              child: child,
              backgroundImage: backgroundImage,
              backgroundColor: selectColor(int.parse(ch.peer)),
          ),
          title: Text(ch.getChatDisplayName(),
             maxLines: 1,
             overflow: TextOverflow.clip,
             style: stl.appBarLtTitle.copyWith(color: stl.colorScheme.onSecondary),
          ),
          dense: true,
          subtitle:
             Text(cps.subtitle,
                maxLines: 1,
                overflow: TextOverflow.clip,
                style: stl.appBarLtSubtitle.copyWith(color: cps.color),
             ),
       );
   }

   return WillPopScope(
         onWillPop: () async { return onWillPopScope();},
         child: Scaffold(
            appBar : AppBar(
               actions: actions,
               title: title,
	       backgroundColor: stl.colorScheme.secondary,
               leading: IconButton(
                  padding: EdgeInsets.all(0.0),
                  icon: Icon(Icons.arrow_back, color: stl.colorScheme.onSecondary),
                  onPressed: onWillPopScope,
               ),
            ),
         body: mainCol,
         backgroundColor: Colors.grey[300],
      )
   );
}

Widget makeTabWidget(
   BuildContext ctx,
   int n,
   String title,
   double opacity,
) {
   if (n == 0)
      return Center(child: Text(title));

   List<Widget> widgets = List<Widget>(2);
   widgets[0] = Text(title);

   // See: https://docs.flutter.io/flutter/material/TabBar/labelColor.html
   // for opacity values.
   widgets[1] = Opacity(
      child: makeUnreadMsgsCircle(
         ctx,
         n,
         stl.colorScheme.secondary,
         stl.colorScheme.onSecondary,
      ),
      opacity: opacity,
   );

   return Row(children: widgets);
}

CircleAvatar makeChatListTileLeading(
   bool isLongPressed,
   String avatar,
   Color bgcolor,
   Function onLeadingPressed)
{
   List<Widget> l = List<Widget>();

   ImageProvider bgImg;
   if (avatar.isEmpty) {
      l.add(Center(child: stl.unknownPersonIcon));
   } else {
      final String url = cts.gravatarUrl + avatar + '.jpg';
      bgImg = CachedNetworkImageProvider(url);
   }

   l.add(OutlineButton(
         child: Text(''),
         borderSide: BorderSide(style: BorderStyle.none),
         onPressed: onLeadingPressed,
         shape: CircleBorder()
      ),
   );

   if (isLongPressed) {
      Positioned p = Positioned(
         bottom: 0.0,
         right: 0.0,
         child: Container(
            height: 20,
            width: 20,
            child: Icon(Icons.check,
               color: Colors.white,
               size: 15,
            ),
            decoration: BoxDecoration(
               color: stl.primaryColor,
               shape: BoxShape.circle,
            ),
         ),
      );

      l.add(p);
   }

   return CircleAvatar(
      child: Stack(children: l),
      backgroundColor: bgcolor,
      backgroundImage: bgImg,
   );
}

String makeStrAbbrev(final String str)
{
   if (str.length < 2)
      return str;

   return str.substring(0, 2);
}

RichText makeFilterListTileTitleWidget(
   String str1,
   String str2,
   TextStyle stl1,
   TextStyle stl2)
{
   return RichText(
      text: TextSpan(
         text: str1,
         style: stl1,
         children: <TextSpan>
         [TextSpan(text: str2, style: stl2)]));
}

ListTile makeFilterSelectAllItem(
   BuildContext ctx,
   Node node,
   String title,
   Function onTap,
) {
   return ListTile(
       leading: Icon(
          Icons.select_all,
          size: 35.0,
          color: stl.colorScheme.secondaryVariant
       ),
       title: makeListTileTreeTitle(ctx, node, title),
       subtitle: makeListTileTreeSubtitle(node),
       dense: true,
       onTap: onTap,
       enabled: true,
       isThreeLine: true,
    );
}

Widget makePayPriceListTile(
   BuildContext ctx,
   String price,
   String title,
   String subtitle,
   Function onTap,
   Color color)
{
   Text subtitleW = Text(subtitle,
      maxLines: 2,
      overflow: TextOverflow.clip,
      style: stl.ltSubtitle,
   );

   Text titleW = Text(title,
      maxLines: 1,
      overflow: TextOverflow.clip,
      style: stl.ltTitle,
   );

   Widget leading = Card(
      margin: const EdgeInsets.all(0.0),
      color: color,
      elevation: 0.0,
      shape: RoundedRectangleBorder(
         borderRadius: BorderRadius.all(Radius.circular(10.0)),
      ),
      child: Padding(
         padding: EdgeInsets.all(10.0),
         child: Text(price, style: TextStyle(color: Colors.white),),
      ),
   );

   return ListTile(
       leading: leading,
       title: titleW,
       dense: true,
       subtitle: subtitleW,
       trailing: Icon(Icons.keyboard_arrow_right),
       contentPadding: EdgeInsets.symmetric(horizontal: 10.0),
       onTap: onTap,
       enabled: true,
       selected: false,
       isThreeLine: false,
    );
}

//void pay()
//{
//   InAppPayments.setSquareApplicationId('APPLICATION_ID');
//   InAppPayments.startCardEntryFlow(
//      onCardEntryCancel: (){},
//      onCardNonceRequestSuccess: cardNonceRequestSuccess,
//   );
//}
//
//void cardNonceRequestSuccess(sq.CardDetails result)
//{
//   // Use this nonce from your backend to pay via Square API
//   print(result.nonce);
//
//   final bool invalidZipCode = false;
//
//   if (invalidZipCode) {
//      // Stay in the card flow and show an error:
//      InAppPayments.showCardNonceProcessingError('Invalid ZipCode');
//   }
//
//   InAppPayments.completeCardEntry(
//      onCardEntryComplete: (){},
//   );
//}

Widget makePaymentChoiceWidget(
   BuildContext ctx,
   Function freePayment)
{
   List<Widget> widgets = List<Widget>();
   Widget title = Padding(
      padding: EdgeInsets.all(10.0),
      child: Text(g.param.paymentTitle, style: stl.tsSubheadPrimary),
   );

   widgets.add(title);

   // Depending on the length of the text, change the function ListTile.
   // dense: true,
   // isThreeLine: false,
   List<Function> payments = <Function>
   [ () { freePayment(ctx);   }
   , () { print('===> pay1'); }
   , () { print('===> pay2'); }
   ];
   for (int i = 0; i < g.param.payments0.length; ++i) {
      Widget p = makePayPriceListTile(
         ctx,
         g.param.payments0[i],
         g.param.payments1[i],
         g.param.payments2[i],
         payments[i],
         stl.priceColors[i],
      );

      widgets.add(p);
   }

   return Card(
      margin: const EdgeInsets.only(
       left: 1.5, right: 1.5, top: 0.0, bottom: 0.0
      ),
      color: stl.colorScheme.background,
      //elevation: 0.0,
      shape: RoundedRectangleBorder(
         borderRadius: BorderRadius.only(
           topLeft: Radius.circular(20.0),
           topRight: Radius.circular(20.0),
         ),
      ),
      child: Column(
         mainAxisSize: MainAxisSize.min,
         children: widgets
      ),
   );
}

Widget makeListTileTreeTitle(
   BuildContext ctx,
   Node node,
   String title,
) {
   final int c = node.leafReach;
   final int cs = node.leafCounter;

   String s = ' ($c/$cs)';
   TextStyle counterTxtStl = Theme.of(ctx).textTheme.caption;
   if (node.isLeaf() && node.leafCounter > 1) {
      s = ' (${node.leafCounter})';
      counterTxtStl = Theme.of(ctx).textTheme.caption.copyWith(
         color: stl.colorScheme.primary,
      );
   }

   return RichText(
      text: TextSpan(
         text: title,
         style: stl.ltTitle,
         children: <TextSpan>
         [ TextSpan(text: s, style: counterTxtStl),
         ]
      )
   );
}

Widget makeListTileTreeSubtitle(Node node)
{
   if (!node.isLeaf())
      return Text(
          node.getChildrenNames(g.param.langIdx),
          style: stl.ltSubtitle,
          maxLines: 2,
          overflow: TextOverflow.clip,
      );

   Widget subtitle;
   return subtitle;
}

ListTile makeFilterListTitle(
   BuildContext ctx,
   Node child,
   Function onTap,
   Icon trailing,
) {
   Color avatarBgColor = stl.colorScheme.secondary;
   Color avatarTxtColor = stl.colorScheme.onSecondary;

   if (child.leafReach != 0) {
      avatarBgColor = stl.colorScheme.primary;
      avatarTxtColor = stl.colorScheme.onPrimary;
   }

   return
      ListTile(
          leading: CircleAvatar(
             child: Text(
                makeStrAbbrev(child.name(g.param.langIdx)),
                style: TextStyle(color: avatarTxtColor),
             ),
             backgroundColor: avatarBgColor,
          ),
          title: makeListTileTreeTitle(ctx, child,
                child.name(g.param.langIdx)),
          dense: true,
          subtitle: makeListTileTreeSubtitle(child),
          trailing: trailing,
          contentPadding: EdgeInsets.symmetric(horizontal: 10.0),
          onTap: onTap,
          enabled: true,
          selected: child.leafReach != 0,
          isThreeLine: !child.isLeaf(),
       );
}

/*
 *  To support the "select all" buttom in the menu checkbox we have to
 *  add some complex logic.  First we note that the "Todos" checkbox
 *  should appear in all screens that present checkboxes, namely, when
 *  
 *  1. makeLeaf is true, or
 *  2. isLeaf is true for more than one node.
 *
 *  In those cases the builder will go through all node children
 *  otherwise the first should be skipped.
 */
ListView makeNewFilterListView(
   Node o,
   Function onLeafPressed,
   Function onNodePressed,
   bool makeLeaf,
) {
   int shift = 0;
   if (makeLeaf || o.children.last.isLeaf())
      shift = 1;

   return ListView.builder(
      //padding: const EdgeInsets.all(8.0),
      itemCount: o.children.length + shift,
      itemBuilder: (BuildContext ctx, int i)
      {
         if (shift == 1 && i == 0)
            return makeFilterSelectAllItem(
               ctx,
               o,
               g.param.selectAll,
               () { onLeafPressed(0); },
            );

         if (shift == 1) {
            Node child = o.children[i - 1];

            Widget icon = Icon(Icons.check_box_outline_blank);
            if (child.leafReach > 0)
               icon = Icon(Icons.check_box);

            return makeFilterListTitle(
               ctx,
               child,
               () { onLeafPressed(i);},
               icon,
            );
         }

         return makeFilterListTitle(
            ctx,
            o.children[i],
            () { onNodePressed(i); },
            Icon(Icons.keyboard_arrow_right),
         );
      },
   );
}

Widget createRaisedButton(
   OnPressedFn0 onPressed,
   final String txt,
   Color color,
   Color textColor,
) {
   RaisedButton but = RaisedButton(
      child: Text(txt,
         style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: stl.mainFontSize,
            color: textColor,
         ),
      ),
      color: color,
      onPressed: onPressed,
   );

   return Center(child: ButtonTheme(minWidth: 100.0, child: but));
}

// Study how to convert this into an elipsis like whatsapp.
Container makeUnreadMsgsCircle(
   BuildContext ctx,
   int n,
   Color bgColor,
   Color textColor,
) {
   final Text txt =
      Text("$n",
           style: TextStyle(
              color: textColor,
              fontSize: Theme.of(ctx).textTheme.caption.fontSize));
   final Radius rd = const Radius.circular(45.0);
   return Container(
       margin: const EdgeInsets.all(2.0),
       padding: const EdgeInsets.all(2.0),
       constraints: BoxConstraints(
          minHeight: 21.0, minWidth: 21.0,
          maxHeight: 21.0, maxWidth: 40.0
       ),
       //height: 21.0,
       //width: 21.0,
       decoration:
          BoxDecoration(
             color: bgColor,
             borderRadius:
                BorderRadius.only(
                   topLeft:  rd,
                   topRight: rd,
                   bottomLeft: rd,
                   bottomRight: rd
                )
             ),
      child: Center(widthFactor: 1.0, child: txt)
   );
}

//ababab
Row makePostRowElem(BuildContext ctx, String key, String value)
{
   RichText left = RichText(
      text: TextSpan(
         text: key + ': ',
         style: stl.ltTitle.copyWith(
            color: stl.infoKeyColor,
            fontWeight: FontWeight.normal,
         ),
         children: <TextSpan>
         [ TextSpan(
              text: value,
              style: stl.ltTitle.copyWith(
                 color: stl.infoValueColor
              ),
           ),
         ],
      ),
   );

   final double width = makeWidth(ctx);
   return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: <Widget>
      [ Icon(Icons.arrow_right, color: stl.infoKeyArrowColor)
      , ConstrainedBox(
         constraints: BoxConstraints(
            maxWidth: 0.80 * width,
            minWidth: 0.80 * width,
         ),
         child: left)
      ]
   );
}

List<Widget> makePostInRows(
   List<Node> nodes,
   int state,
) {
   List<Widget> list = List<Widget>();

   for (int i = 0; i < nodes.length; ++i) {
      if ((state & (1 << i)) == 0)
         continue;

      Text text = Text(' ${nodes[i].name(g.param.langIdx)}',
         style: stl.tt.subhead.copyWith(
            color: stl.infoValueColor,
         ),
      );

      Row row = Row(children: <Widget>
      [ Icon(Icons.check, color: stl.colorScheme.primaryVariant)
      , text
      ]); 

      list.add(row);
   }

   return list;
}

Widget makePostSectionTitle(
   BuildContext ctx,
   String str)
{
   return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
         padding: EdgeInsets.all(stl.postSectionPadding),
         child: Text(str,
            style: TextStyle(
               fontSize: stl.subtitleFontSize,
               color: Colors.grey[500],
            ),
         ),
      ),
   );
}

// Assembles the menu information.
List<Widget> makeMenuInfo(
   BuildContext ctx,
   Post post,
   List<Tree> menus)
{
   List<Widget> list = List<Widget>();

   for (int i = 0; i < post.channel.length; ++i) {
      list.add(makePostSectionTitle(ctx, g.param.newPostTabNames[i]));

      List<String> names = loadNames(
         menus[i].root.first,
         post.channel[i][0],
         g.param.langIdx,
      );

      List<Widget> items = List.generate(names.length, (int j)
      {
         assert(i == 0 || i == 1);

         List<String> menuDepthNames;
         if (i == 0)
            menuDepthNames = g.param.menuDepthNames0;
         else 
            menuDepthNames = g.param.menuDepthNames1;

         return makePostRowElem(
            ctx,
            menuDepthNames[j],
            names[j],
         );
      });

      list.addAll(items); // The menu info.
   }

   return list;
}

String makeRangeStr(Post post, int i)
{
   assert(i < post.rangeValues.length);

   final int j = 2 * i;

   assert((j + 1) < g.param.rangeUnits.length);

   return g.param.rangeUnits[j + 0]
        + post.rangeValues[i].toString()
        + g.param.rangeUnits[j + 1];
}

List<Widget> makePostValues(BuildContext ctx, Post post)
{
   List<Widget> list = List<Widget>();

   list.add(makePostSectionTitle(ctx, g.param.rangesTitle));

   List<Widget> items = List.generate(g.param.rangeDivs.length, (int i)
   {

      return makePostRowElem(
         ctx,
         g.param.rangePrefixes[i],
         makeRangeStr(post, i),
      );
   });

   list.addAll(items); // The menu info.

   return list;
}

List<Widget> makePostExDetails(
   BuildContext ctx,
   Post post,
   Node exDetailsRootNode,
) {
   // Post details varies according to the first index of the products
   // entry in the menu.
   final int idx = post.getProductDetailIdx();
   if (idx == -1)
      return List<Widget>();

   List<Widget> list = List<Widget>();
   list.add(makePostSectionTitle(ctx, g.param.postExDetailsTitle));

   final int l1 = exDetailsRootNode.children[idx].children.length;
   for (int i = 0; i < l1; ++i) {
      final int n = exDetailsRootNode.children[idx].children[i].children.length;
      final int k = post.exDetails[i];
      if (k == -1 || k >= n)
	 continue;
      
      list.add(
         makePostRowElem(
            ctx,
            exDetailsRootNode.children[idx].children[i].name(g.param.langIdx),
            exDetailsRootNode.children[idx].children[i].children[k].name(g.param.langIdx),
         ),
      );
   }

   list.add(makePostSectionTitle(ctx, g.param.postRefSectionTitle));

   List<String> values = List<String>();
   values.add(post.nick);
   values.add('${post.from}');

   int date;
   if (post.id == -1) {
      // We are publishing.
      values.add('');
      date = DateTime.now().millisecondsSinceEpoch;
   } else {
      values.add('${post.id}');
      date = post.date;
   }

   values.add(makeDateString2(date));

   for (int i = 0; i < values.length; ++i)
      list.add(makePostRowElem(ctx, g.param.descList[i], values[i]));

   return list;
}

List<Widget> makePostInDetails(
   BuildContext ctx,
   Post post,
   Node inDetailsRootNode)
{
   List<Widget> all = List<Widget>();

   final int i = post.getProductDetailIdx();
   if (i == -1)
      return List<Widget>();

   final int l1 = inDetailsRootNode.children[i].children.length;
   for (int j = 0; j < l1; ++j) {
      List<Widget> foo = makePostInRows(
         inDetailsRootNode.children[i].children[j].children,
         post.inDetails[j],
      );

      if (foo.length != 0) {
         all.add(makePostSectionTitle(
               ctx,
               inDetailsRootNode.children[i].children[j].name(g.param.langIdx),
            ),
         );
         all.addAll(foo);
      }
   }

   return all;
}

Card putPostElemOnCard(List<Widget> list, double padding)
{
   Column col = Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      children: list,
   );

   return Card(
      elevation: 0.0,
      //color: stl.colorScheme.background,
      color: Colors.white,
      margin: EdgeInsets.all(0.0),
      child: Padding(
         child: col,
         padding: EdgeInsets.all(padding),
      ),
      shape: RoundedRectangleBorder(
         borderRadius: BorderRadius.all(
            Radius.circular(0.0)
         ),
      ),
   );
}

Widget makePostDescription(BuildContext ctx, String desc)
{
   final double width = makeWidth(ctx);

   return ConstrainedBox(
      constraints: BoxConstraints(
         maxWidth: stl.infoWidthFactor * width,
         minWidth: stl.infoWidthFactor * width,
      ),
      child: Text(
         desc,
         overflow: TextOverflow.clip,
         style: stl.textField,
      ),
   );
}

List<Widget> assemblePostRows(
   BuildContext ctx,
   Post post,
   List<Tree> menu,
   Node exDetailsRootNode,
   Node inDetailsRootNode,
) {
   List<Widget> all = List<Widget>();
   all.addAll(makePostValues(ctx, post));
   all.addAll(makeMenuInfo(ctx, post, menu));
   all.addAll(makePostExDetails(ctx, post, exDetailsRootNode));
   all.addAll(makePostInDetails(ctx, post, inDetailsRootNode));
   if (post.description.isNotEmpty) {
      all.add(makePostSectionTitle(ctx, g.param.postDescTitle));
      all.add(makePostDescription(ctx, post.description));
   }

   return all;
}

String makeTreeItemStr(Node root, List<int> nodeCoordinate)
{
   if (nodeCoordinate.isEmpty)
      return '';

   final List<String> names = loadNames(
      root,
      nodeCoordinate,
      g.param.langIdx,
   );

   final int l = names.length;
   assert(names.length >= 2);

   final String a = names[l - 2];
   final String b = names[l - 1];

   return '$a - $b';
}

ThemeData makeExpTileThemeData()
{
   return ThemeData(
      accentColor: Colors.black,
      unselectedWidgetColor: stl.colorScheme.primary,
      textTheme: TextTheme(
         subhead: TextStyle(
            color: Colors.black,
         ),
      ),
   );
}

String makePriceStr(int price)
{
   final String s = price.toString();
   return 'R\$$s';
}

Widget makeTextWdg(
   String str,
   double paddingTop,
   double paddingBot,
   double paddingLeft,
   double paddingRight,
   FontWeight fw,
) {
   return Padding(
      child: Text(str,
         style: TextStyle(
            color: Colors.black,
	    fontSize: stl.subtitleFontSize,
	    fontWeight: fw,
         ),
         overflow: TextOverflow.ellipsis,
      ),
      padding: EdgeInsets.only(right: paddingRight, left: paddingLeft, top: paddingTop, bottom: paddingBot),
   );
}

Widget makeAddOrRemoveWidget(
   Function add,
   IconData id,
   Color color)
{
   return Padding(
      padding: const EdgeInsets.all(stl.imgInfoWidgetPadding),
      child: IconButton(
         onPressed: add,
         icon: Icon(id,
            color: color,
            size: 30.0,
         ),
      ),
   );
}

Widget makeImgTextPlaceholder(final String str)
{
   return Text(str,
      overflow: TextOverflow.clip,
      style: TextStyle(
         color: stl.colorScheme.background,
         fontSize: stl.tt.title.fontSize,
      ),
   );
}

bool isWideScreenImpl(double w)
{
   return w > (3 * cts.maxWebTabWidth);
}

double makeTabWidthImpl(double w)
{
   if (isWideScreenImpl(w))
      return w / 3.0;

   return w;
}

double makeTabWidth(BuildContext ctx)
{
   final double w = MediaQuery.of(ctx).size.width;
   return makeTabWidthImpl(w);
}

bool isWideScreen(BuildContext ctx)
{
   final double w = MediaQuery.of(ctx).size.width;

   return isWideScreenImpl(w);
}

double makeImgAvatarWidth(BuildContext ctx)
{
   final double w = MediaQuery.of(ctx).size.width;
   if (isWideScreenImpl(w))
      return cts.postImgAvatarTabWidthRate * cts.maxWebTabWidth;

   if (w > cts.maxWebTabWidth)
      return cts.postImgAvatarTabWidthRate * cts.maxWebTabWidth;

   return cts.postImgAvatarTabWidthRate * w;
}

double makePostTextWidth(BuildContext ctx)
{
   final double tabWidth = makeTabWidth(ctx);
   final double imgWidth = makeImgAvatarWidth(ctx);
   return tabWidth - imgWidth - 5.00;
}

double makeDialogWidthHeight(BuildContext ctx)
{
   double w = makeTabWidth(ctx);
   return 0.80 * w;
}

double makeWidth(BuildContext ctx)
{
   final double w = MediaQuery.of(ctx).size.width;

   if (isWideScreenImpl(w))
      return makeTabWidthImpl(w);

   final double max = w > cts.maxWebTabWidth ? cts.maxWebTabWidth : w;
   return max;
}

double makeHeight(BuildContext ctx)
{
   return MediaQuery.of(ctx).size.height;
}

double makeImgWidth(BuildContext ctx)
{
   return makeWidth(ctx);
}

double makeImgHeight(BuildContext ctx, double r)
{
   final double width = makeImgWidth(ctx);
   return width * r;
}

List<Widget> makePostButtons({
   int pinDate,
   OnPressedFn0 onDelPost,
   OnPressedFn0 onSharePost,
   OnPressedFn0 onShowChatBox,
   OnPressedFn0 onPinPost,
}) {
   IconButton remove = IconButton(
      padding: EdgeInsets.all(0.0),
      onPressed: onDelPost,
      icon: Icon(
         Icons.clear,
         color: Colors.grey,
      ),
   );

   IconButton share = IconButton(
      padding: EdgeInsets.all(0.0),
      onPressed: onSharePost,
      color: stl.colorScheme.primary,
      icon: Icon(Icons.share,
         color: stl.colorScheme.secondary,
      ),
   );

   IconButton chat = IconButton(
      padding: EdgeInsets.all(0.0),
      icon: stl.favIcon,
      onPressed: onShowChatBox,
      color: stl.colorScheme.primary,
   );

   IconData pinIcon = pinDate == 0 ? Icons.place : Icons.pin_drop;

   IconButton pin = IconButton(
      padding: EdgeInsets.all(0.0),
      onPressed: onPinPost,
      icon: Icon(
         pinIcon,
         color: Colors.brown,
      ),
   );


   return <Widget>[remove, share, chat, pin];
}

Widget makeNewPostDialogWdg({
   final double width,
   final Widget title,
   final List<Widget> list,
   final List<Widget> actions,
}) {
   ListView lv = ListView.separated(
      separatorBuilder: (BuildContext context, int index)
      {
	 return stl.alertDivider;
      },
      itemCount: list.length,
      itemBuilder: (BuildContext ctx, int i)
      {
	 return list[i];
      }
   );

   return AlertDialog(
      title: title,
      actions: actions,
      content: Container(
	 width: width,
	 height: width,
	 child: lv,
      ),
   );
}

//------------------------------------------------------------------------------------
class InDetailsView extends StatefulWidget {
   int state;
   final String title;
   final List<String> names;

   @override
   InDetailsViewState createState() => InDetailsViewState();
   InDetailsView(
   { @required this.state
   , @required this.title
   , @required this.names
   });
}

class InDetailsViewState extends State<InDetailsView> with TickerProviderStateMixin {

   @override
   void dispose()
   {
      super.dispose();
   }

   @override
   void initState()
   {
      super.initState();
   }

   void _onPressed(bool v, int i)
   {
      setState(() {widget.state ^= 1 << i;});
   }

   void _onOkPressed(BuildContext ctx)
   {
      Navigator.pop(ctx, widget.state);
   }

   @override
   Widget build(BuildContext ctx)
   {
      final FlatButton ok = FlatButton(
	 child: Text(g.param.ok, style: TextStyle(color: stl.colorScheme.primary)),
	 onPressed: () {_onOkPressed(ctx);},
      );

      List<Widget> list = makeCheckBoxes(
	 widget.state,
	 widget.names,
	 _onPressed,
      );

      return makeNewPostDialogWdg(
	 width: makeDialogWidthHeight(ctx),
	 title: Text(widget.title, style: stl.newPostSubtitleLT),
	 list: list,
	 actions: <FlatButton>[ok],
      );
   }
}

//--------------------------------------------------------------------------------------
class ExDetailsView extends StatefulWidget {
   final String title;
   final List<String> names;
   final int onIdx;

   @override
   ExDetailsViewState createState() => ExDetailsViewState();
   ExDetailsView(
   { @required this.title
   , @required this.names
   , @required this.onIdx
   });
}

class ExDetailsViewState extends State<ExDetailsView> with TickerProviderStateMixin {

   @override
   void dispose()
   {
      super.dispose();
   }

   @override
   void initState()
   {
      super.initState();
   }

   void _onPressed(BuildContext ctx, bool v, int i)
   {
      Navigator.pop(ctx, v ? i : -1);
   }

   void _onOkPressed(BuildContext ctx)
   {
      Navigator.pop(ctx);
   }

   @override
   Widget build(BuildContext ctx)
   {
      List<Widget> exDetails = List<Widget>();
      for (int i = 0; i < widget.names.length; ++i) {
	 CheckboxListTile cb = CheckboxListTile(
	    dense: true,
	    title: Text(widget.names[i], style: stl.newPostTreeLT),
	    value: i == widget.onIdx,
	    onChanged: (bool v) { _onPressed(ctx, v, i); },
	    activeColor: stl.colorScheme.primary,
	    isThreeLine: false,
	 );

	 Align a = Align(alignment: Alignment.centerLeft, child: cb);
	 exDetails.add(a);
      }

      final FlatButton ok = FlatButton(
	 child: Text(g.param.ok, style: TextStyle(color: stl.colorScheme.primary)),
	 onPressed: () {_onOkPressed(ctx);},
      );

      return makeNewPostDialogWdg(
	 width: makeDialogWidthHeight(ctx),
	 title: Text(widget.title, style: stl.newPostSubtitleLT),
	 list: exDetails,
	 actions: <FlatButton>[ok],
      );
   }
}

//---------------------------------------------------------------------

class TreeView extends StatefulWidget {
   final Node root;

   @override
   TreeViewState createState() => TreeViewState();

   TreeView({@required this.root});
}

class TreeViewState extends State<TreeView> with TickerProviderStateMixin {
   List<Node> _stack = List<Node>();

   @override
   void dispose()
   {
      super.dispose();
   }

   @override
   void initState()
   {
      super.initState();
      _stack = <Node>[widget.root];
   }

   void _onPostLeafPressed(BuildContext ctx, int i)
   {
      _stack.add(_stack.last.children[i]);
      _onPostLeafReached(ctx);
      setState(() { });
   }

   void _onPostLeafReached(BuildContext ctx)
   {
      List<int> code = <int>[];
      if (_stack.last.code.isNotEmpty)
	 code = _stack.last.code;

      Navigator.pop(ctx, code);
      _stack = <Node>[widget.root];
   }

   void _onPostNodePressed(BuildContext ctx, int i)
   {
      // We continue pushing on the stack if the next screen will have
      // only one menu option.
      do {
         Node o = _stack.last.children[i];
         _stack.add(o);
         i = 0;
      } while (_stack.last.children.length == 1);

      final int length = _stack.last.children.length;

      assert(length != 1);

      if (length == 0)
         _onPostLeafReached(ctx);

      setState(() { });
   }

   void _onBack(BuildContext ctx)
   {
      setState((){
	 _stack.removeLast();
	 if (_stack.isEmpty)
	    Navigator.pop(ctx);
      });
   }

   @override
   Widget build(BuildContext ctx)
   {
      if (_stack.isEmpty)
	 return SizedBox.shrink();

      List<Widget> locWdgs = makeNewPostTreeWdgs(
	 ctx: ctx,
	 node: _stack.last,
	 onLeafPressed: (int i) {_onPostLeafPressed(ctx, i);},
	 onNodePressed: (int i) {_onPostNodePressed(ctx, i);},
      );

      final String titleStr = _stack.join(', ');

      Widget titleWdg = RichText(
	 text: TextSpan(
	    text: '${g.param.newPostTabNames[0]}: ',
	    style: stl.newPostTreeLT,
	    children: <TextSpan>
	    [ TextSpan(
		 text: titleStr,
		 style: stl.newPostTreeLT.copyWith(color: stl.colorScheme.secondary),
	      ),
	    ],
	 ),
      );

      FlatButton back =  FlatButton(
	 child: Text(g.param.newFiltersFinalScreenButton[0],
	    style: TextStyle(color: stl.colorScheme.primary),
	 ),
	 onPressed: () {_onBack(ctx);},
      );

      return makeNewPostDialogWdg(
	 width: makeDialogWidthHeight(ctx),
	 title: titleWdg,
	 list: locWdgs,
	 actions: <FlatButton>[back],
      );
   }
}

//---------------------------------------------------------------------

class SizeAnimation extends StatefulWidget {
   int milliseconds;
   int screen;
   Post post;
   Node exDetailsRootNode;
   Node inDetailsRootNode;
   Widget detailsWidget;
   List<File> imgFiles;
   List<Tree> trees;
   OnPressedFn2 onAddPhoto;
   OnPressedFn1 onExpandImg;
   OnPressedFn0 onAddPostToFavorite;
   OnPressedFn0 onDelPost;
   OnPressedFn0 onSharePost;
   OnPressedFn0 onPinPost;

   @override
   SizeAnimationState createState() => SizeAnimationState();

   SizeAnimation(
   { @required this.milliseconds
   , @required this.screen
   , @required this.post
   , @required this.exDetailsRootNode
   , @required this.inDetailsRootNode
   , @required this.detailsWidget
   , @required this.imgFiles
   , @required this.trees
   , @required this.onAddPhoto
   , @required this.onExpandImg
   , @required this.onAddPostToFavorite
   , @required this.onDelPost
   , @required this.onSharePost
   , @required this.onPinPost
   });
}

class SizeAnimationState extends State<SizeAnimation> with TickerProviderStateMixin {
   AnimationController _detailsCtrl;
   AnimationController _chatCtrl;

   @override
   void dispose()
   {
      _detailsCtrl.dispose();
      _chatCtrl.dispose();
      super.dispose();
   }

   @override
   void initState()
   {
      super.initState();
      _detailsCtrl = AnimationController(
	 vsync: this,
	 duration: Duration(milliseconds: widget.milliseconds),
      );

      _chatCtrl = AnimationController(
	 vsync: this,
	 duration: Duration(milliseconds: widget.milliseconds),
      );

      _detailsCtrl.reverse();
      _chatCtrl.reverse();
   }

   void _onPressed(int i)
   {
      setState((){
	 if (i == 0 || i == 1) {
	    if (_detailsCtrl.status == AnimationStatus.dismissed) {
	       _detailsCtrl.forward();
	    } else if (_detailsCtrl.status == AnimationStatus.completed) {
	       _detailsCtrl.reverse();
	    }
	 }

	 if (i == 2) {
	    if (_chatCtrl.status == AnimationStatus.dismissed) {
	       _chatCtrl.forward();
	    } else if (_chatCtrl.status == AnimationStatus.completed) {
	       _chatCtrl.reverse();
	    }
	 }
      });
   }

   @override
   Widget build(BuildContext ctx)
   {
      //Text owner = Text(
      //   widget.post.nick,
      //   maxLines: 1,
      //   overflow: TextOverflow.clip,
      //   style: TextStyle(
      //      fontSize: stl.listTileSubtitleFontSize,
      //      color: Colors.grey[600],
      //      fontWeight: FontWeight.normal,
      //   ),
      //);

      final List<Widget> buttons = makePostButtons(
	 pinDate: widget.post.pinDate,
	 onDelPost: widget.onDelPost,
	 onSharePost: widget.onSharePost,
	 onShowChatBox: () {_onPressed(2);},
	 onPinPost: widget.onPinPost,
      );

      Widget dateWdg = makeTextWdg(makeDateString2(widget.post.date), 0.0, 0.0, 0.0, 0.0, FontWeight.normal);
      List<Widget> buttonWdgs = List<Widget>();
      //buttonWdgs.add(Expanded(child: Padding(child: owner, padding: const EdgeInsets.only(left: 10.0))));
      buttonWdgs.add(Expanded(child: Padding(child: dateWdg, padding: const EdgeInsets.only(left: 10.0))));

      if (widget.screen == cts.searchIdx) {
	 buttonWdgs.add(Expanded(child: buttons[1]));
	 buttonWdgs.add(Expanded(child: buttons[2]));
      } else {
	 buttonWdgs.add(Expanded(child: buttons[3]));
	 buttonWdgs.add(Expanded(child: buttons[0]));
	 buttonWdgs.add(Expanded(child: buttons[1]));
      }

      Row buttonsRow = Row(children: buttonWdgs);

      final double imgAvatarWidth = makeImgAvatarWidth(ctx);

      Widget imgWdg;
      if (widget.post.images.isNotEmpty) {
	 Container img = Container(
	    //margin: const EdgeInsets.only(top: 10.0),
	    margin: const EdgeInsets.all(0.0),
	    child: makeNetImgBox(
	       imgAvatarWidth,
	       imgAvatarWidth,
	       widget.post.images.first,
	       BoxFit.cover,
	    ),
	 );

	 Widget kmText = makeTextWdg(makeRangeStr(widget.post, 2), 3.0, 3.0, 3.0, 3.0, FontWeight.normal);
	 Widget priceText = makeTextWdg(makeRangeStr(widget.post, 0), 3.0, 3.0, 3.0, 3.0, FontWeight.normal);

	 imgWdg = Stack(
	    //alignment: Alignment.topLeft,
	    children: <Widget>
	    [ img
	    , Positioned(
		 left: 0.0,
		 bottom: 0.0,
		 child: Card(child: kmText,
		    elevation: 0.0,
		    color: Colors.white.withOpacity(0.7),
		    margin: EdgeInsets.all(5.0),
		 ),
	      )
	    , Positioned(
		 left: 0.0,
		 top: 0.0,
		 child: Card(child: priceText,
		    elevation: 0.0,
		    color: Colors.white.withOpacity(0.7),
		    margin: EdgeInsets.all(5.0),
		 ),
	      )
	    ],
	 );
      } else if (widget.imgFiles.isNotEmpty) {
	 imgWdg = Image.file(widget.imgFiles.last,
	    width: imgAvatarWidth,
	    height: imgAvatarWidth,
	    fit: BoxFit.cover,
	    filterQuality: FilterQuality.high,
	 );
      } else {
	 Widget w = makeImgTextPlaceholder(g.param.addImgMsg);
	 imgWdg = makeImgPlaceholder(
	    imgAvatarWidth,
	    imgAvatarWidth,
	    w,
	 );
      }

      List<Widget> row1List = List<Widget>();

      // The add a photo button should appear only when this function is
      // called on the new posts screen. We determine that in the
      // following way.
      if (widget.post.images.isEmpty && (widget.imgFiles.length < cts.maxImgsPerPost)) {
	 Widget addImgWidget = makeAddOrRemoveWidget(
	    () {widget.onAddPhoto(ctx, -1);},
	    Icons.add_a_photo,
	    stl.colorScheme.primary,
	 );

	 Stack st = Stack(
	    alignment: Alignment(0.0, 0.0),
	    children: <Widget>
	    [ imgWdg
	    , Card(child: addImgWidget,
		    elevation: 0.0,
		    color: Colors.white.withOpacity(0.7),
		    margin: EdgeInsets.all(0.0),
		 )
	    ],
	 );

	 row1List.add(st);
      } else {
	 row1List.add(imgWdg);
      }

      final String locationStr =
         makeTreeItemStr(widget.trees[0].root.first, widget.post.channel[0][0]);
      final String modelStr =
	 makeTreeItemStr(widget.trees[1].root.first, widget.post.channel[1][0]);

      List<String> exDetailsNames = makeExDetailsNamesAll(
         widget.exDetailsRootNode,
	 widget.post.exDetails,
	 widget.post.getProductDetailIdx(),
	 g.param.langIdx,
      );

      List<String> inDetailsNames = makeInDetailNamesAll(
         widget.inDetailsRootNode,
	 widget.post.inDetails,
	 widget.post.getProductDetailIdx(),
	 g.param.langIdx,
      );

      Widget modelTitle = makeTextWdg(modelStr, 3.0, 3.0, 3.0, 3.0, FontWeight.w500);
      Widget location = makeTextWdg(locationStr, 0.0, 0.0, 0.0, 0.0, FontWeight.normal);

      Widget s1 = makeTextWdg(exDetailsNames.join(', '), 0.0, 0.0, 0.0, 0.0, FontWeight.normal);
      Widget s2 = makeTextWdg(inDetailsNames.join(', '), 0.0, 0.0, 0.0, 0.0, FontWeight.normal);

      final double widthCol2 = makePostTextWidth(ctx);

      Column infoWdg = Column(children: <Widget>
      [ Flexible(child: SizedBox(width: widthCol2, child: Padding(child: modelTitle, padding: EdgeInsets.only(left: 5.0))))
      , Flexible(child: SizedBox(width: widthCol2, child: Row(children: <Widget>[Icon(Icons.arrow_right, color: stl.infoKeyArrowColor), Expanded(child: s1)])))
      , Flexible(child: SizedBox(width: widthCol2, child: Row(children: <Widget>[Icon(Icons.arrow_right, color: stl.infoKeyArrowColor), Expanded(child: s2)])))
      , Flexible(child: SizedBox(width: widthCol2, child: Row(children: <Widget>[Icon(Icons.arrow_right, color: stl.infoKeyArrowColor), Expanded(child: location)])))
      //, Flexible(child: SizedBox(width: widthCol2, child: Row(children: <Widget>[Icon(Icons.arrow_right, color: stl.infoKeyArrowColor), Expanded(child: dateWdg)])))
      , Expanded(child: SizedBox(width: widthCol2, child: buttonsRow))
      ]);

      row1List.add(SizedBox(height: imgAvatarWidth, child: infoWdg));

      List<Widget> rows = List<Widget>();
      rows.add(widget.detailsWidget);
      rows.add(Row(children: row1List));

      ChatMetadata cm = ChatMetadata(
	peer: widget.post.from,
	nick: widget.post.nick,
	avatar: widget.post.avatar,
	date: DateTime.now().millisecondsSinceEpoch,
	lastChatItem: ChatItem(),
      );

      Widget tmp = makeChatListTile(
	 ctx,
	 cm,
	 0,
	 false,
	 '',
	 stl.chatListTilePadding,
	 2.0,
	 widget.onAddPostToFavorite,
	 widget.onAddPostToFavorite,
	 widget.onAddPostToFavorite,
      );

      rows.add(tmp);

      List<Widget> sss = List<Widget>();

      Widget detailsWgd = SizeTransition(
	 child: RaisedButton(
	    color: Colors.white,
	    onPressed: () {_onPressed(0);},
	    elevation: 0.0,
	    child: rows[0],
	    padding: const EdgeInsets.all(0.0),
	 ),
	 sizeFactor: CurvedAnimation(
	       curve: Curves.fastOutSlowIn,
	       parent: _detailsCtrl,
	 ),
      );

      sss.add(detailsWgd);

      Widget postWdg = RaisedButton(
	 color: Colors.white,
	 onPressed: () {_onPressed(1);},
	 elevation: 0.0,
	 child: rows[1],
	 padding: const EdgeInsets.all(0.0),
      );

      sss.add(postWdg);

      Widget chatWdg = SizeTransition(
	 child: rows[2],
	 sizeFactor: CurvedAnimation(
	       curve: Curves.fastOutSlowIn,
	       parent: _chatCtrl,
	 ),
      );

      sss.add(chatWdg);
      return Column(children: sss);
   }
}

Widget makePostDetailsWdg({
   BuildContext ctx,
   final Post post,
   final Node exDetailsRootNode,
   final Node inDetailsRootNode,
   final List<Tree> trees,
   final List<File> imgFiles,
   OnPressedFn2 onAddPhoto,
   OnPressedFn1 onExpandImg,
   OnPressedFn0 onReportPost,
}) {
   List<Widget> rows = List<Widget>();

   Widget lv = makeImgListView2(
      ctx,
      post,
      BoxFit.cover,
      imgFiles,
      (int j){onExpandImg(j);},
      onAddPhoto,
   );

   rows.add(lv);

   IconButton inapropriate = IconButton(
      padding: EdgeInsets.all(0.0),
      onPressed: onReportPost,
      icon: Icon(
         Icons.report,
         color: stl.colorScheme.primary,
      ),
   );

   rows.add(inapropriate);

   List<Widget> tmp = assemblePostRows(
      ctx,
      post,
      trees,
      exDetailsRootNode,
      inDetailsRootNode,
   );

   rows.add(putPostElemOnCard(tmp, 4.0));

   return putPostElemOnCard(rows, 0.0);
}

Widget makeNewPost({
   BuildContext ctx,
   final int screen,
   final String snackbarStr,
   final Post post,
   final Node exDetailsRootNode,
   final Node inDetailsRootNode,
   final List<Tree> trees,
   final List<File> imgFiles,
   OnPressedFn2 onAddPhoto,
   OnPressedFn1 onExpandImg,
   OnPressedFn0 onAddPostToFavorite,
   OnPressedFn0 onDelPost,
   OnPressedFn0 onSharePost,
   OnPressedFn0 onReportPost,
   OnPressedFn0 onPinPost,
}) {
   assert(trees.length == 2);

   Widget title = Text(
      makeTreeItemStr(trees[0].root.first, post.channel[1][0]),
      maxLines: 1,
      overflow: TextOverflow.clip,
   );

   Widget detailsWdg = makePostDetailsWdg(
      ctx: ctx,
      post: post,
      exDetailsRootNode: exDetailsRootNode,
      inDetailsRootNode: inDetailsRootNode,
      trees: trees,
      imgFiles: imgFiles,
      onAddPhoto: onAddPhoto,
      onExpandImg: onExpandImg,
      onReportPost: onReportPost,
   );

   return SizeAnimation(
     milliseconds: 500,
     screen: screen,
     post: post,
     exDetailsRootNode: exDetailsRootNode,
     inDetailsRootNode: inDetailsRootNode,
     detailsWidget: detailsWdg,
     imgFiles: imgFiles,
     trees: trees,
     onAddPhoto: onAddPhoto,
     onExpandImg: onExpandImg,
     onAddPostToFavorite: onAddPostToFavorite,
     onDelPost: onDelPost,
     onSharePost: onSharePost,
     onPinPost: onPinPost,
   );
}

Widget makeOwnEmptyScreenWidget({
   final OnPressedFn0 onPressed,
}) {
   Widget button = createRaisedButton(
      onPressed,
      g.param.newPostAppBarTitle,
      stl.colorScheme.secondary,
      stl.colorScheme.onSecondary,
   );

   return Center(child: button);
}

Widget makeFavEmptyScreenWidget()
{
   return Center(
      child: Text(g.param.appName,
         style: TextStyle(
            color: Colors.grey,
            fontSize: 30.0,
         ),
      ),
   );
}

Widget makeNewPostLv({
   final int nNewPosts,
   final Node exDetailsRootNode,
   final Node inDetailsRootNode,
   final List<Post> posts,
   final List<Tree> trees,
   final OnPressedFn3 onExpandImg,
   final OnPressedFn2 onAddPostToFavorite,
   final OnPressedFn2 onDelPost,
   final OnPressedFn2 onSharePost,
   final OnPressedFn2 onReportPost,
   final OnPressedFn0 onNext,
}) {
   final int l = posts.length - nNewPosts;
   if (l == 0)
      return makeFavEmptyScreenWidget();

   // No controller should be assigned to this listview. This will
   // break the automatic hiding of the tabbar
   return ListView.separated(
      //key: PageStorageKey<String>('aaaaaaa'),
      padding: const EdgeInsets.all(0.0),
      itemCount: l + 1,
      separatorBuilder: (BuildContext context, int index)
      {
	 return Divider(color: Colors.black, height: 5.0);
      },
      itemBuilder: (BuildContext ctx, int i)
      {
         final int j = l - i - 1;
	 if (i == l) {
	    Widget ret = createRaisedButton(
	       onNext,
	       g.param.next,
	       stl.colorScheme.secondary,
	       stl.colorScheme.onSecondary,
	    );

	    return Padding(
	       child: ret,
	       padding: const EdgeInsets.only(top: 20.0, bottom: 20.0),
	    );
	 }

         return makeNewPost(
            ctx: ctx,
	    screen: cts.searchIdx,
            snackbarStr: g.param.dissmissedPost,
            post: posts[j],
            exDetailsRootNode: exDetailsRootNode,
            inDetailsRootNode: inDetailsRootNode,
            trees: trees,
            imgFiles: List<File>(),
            onAddPhoto: (var ctx, var i) {print('Error: Please fix.');},
            onExpandImg: (int k) {onExpandImg(j, k);},
            onAddPostToFavorite: () {onAddPostToFavorite(ctx, j);},
	    onDelPost: () {onDelPost(ctx, j);},
	    onSharePost: () {onSharePost(ctx, j);},
	    onReportPost: () {onReportPost(ctx, j);},
	    onPinPost: (){print('Noop20');},
         );
      },
   );
}

ListTile makeNewPostTreeWdg({
   Node child,
   OnPressedFn0 onLeafPressed,
   OnPressedFn0 onNodePressed,
}) {
   if (child.isLeaf()) {
      return ListTile(
	 //leading: CircleAvatar(
	 //   child: Text(makeStrAbbrev(child.name(g.param.langIdx)),
	 //      style: TextStyle(color: stl.colorScheme.onSecondary),
	 //   ),
	 //   backgroundColor: stl.colorScheme.secondary,
	 //),
	 title: Text(child.name(g.param.langIdx), style: stl.newPostTreeLT),
	 dense: true,
	 onTap: onLeafPressed,
	 enabled: true,
	 onLongPress: (){},
      );
   }
   
   return
      ListTile(
	 //leading: CircleAvatar(
	 //   child: Text(makeStrAbbrev(child.name(g.param.langIdx)),
	 //      style: TextStyle(
	 //         color: stl.colorScheme.onSecondary
	 //      ),
	 //   ),
	 //   backgroundColor: stl.colorScheme.secondary,
	 //),
	 title: Text(child.name(g.param.langIdx), style: stl.newPostTreeLT),
	 dense: true,
	 subtitle: Text(
	    child.getChildrenNames(g.param.langIdx),
	    maxLines: 1,
	    overflow: TextOverflow.clip,
	    style: stl.newPostSubtitleLT,
	 ),
	 trailing: Icon(Icons.keyboard_arrow_right, color: stl.colorScheme.primary),
	 onTap: onNodePressed,
	 enabled: true,
	 isThreeLine: false,
      );
}

List<Widget> makeNewPostTreeWdgs({
   BuildContext ctx,
   Node node,
   OnPressedFn1 onLeafPressed,
   OnPressedFn1 onNodePressed,
}) {
   List<Widget> list = List<Widget>();

   for (int i = 0; i < node.children.length; ++i) {
      Node child = node.children[i];
      Widget o =  makeNewPostTreeWdg(
	 child: child,
	 onLeafPressed: () {onLeafPressed(i);},
	 onNodePressed: () {onNodePressed(i);},
      );
      list.add(SizedBox(width: makeWidth(ctx), child: o));
   }

   return list;
}

ListView makeNewPostTreeLV(
   Node o,
   OnPressedFn1 onLeafPressed,
   OnPressedFn1 onNodePressed,
) {
   return ListView.builder(
      itemCount: o.children.length,
      itemBuilder: (BuildContext ctx, int i)
      {
	 return makeNewPostTreeWdg(
	    child: o.children[i],
	    onLeafPressed: () {onLeafPressed(i);},
	    onNodePressed: () {onNodePressed(i);},
	 );
      },
   );
}

// Returns an icon based on the message status.
Widget chooseMsgStatusIcon(int status)
{
   final double s = 20.0;

   Icon icon = Icon(Icons.clear, color: Colors.grey, size: s);

   if (status == 3) {
      icon = Icon(Icons.done_all, color: Colors.green, size: s);
   } else if (status == 2) {
      icon = Icon(Icons.done_all, color: Colors.grey, size: s);
   } else if (status == 1) {
      icon = Icon(Icons.check, color: Colors.grey, size: s);
   }

   return Padding(
      child: icon,
      padding: const EdgeInsets.symmetric(horizontal: 2.0));
}

class ChatPresenceSubtitle {
   String subtitle;
   Color color;
   ChatPresenceSubtitle({this.subtitle = '', this.color = Colors.white});
}

ChatPresenceSubtitle makeLTPresenceSubtitle(
   final ChatMetadata cm,
   String str,
   Color color,
) {
   final int now = DateTime.now().millisecondsSinceEpoch;
   final int last = cm.lastPresenceReceived + cts.presenceInterval;

   final bool moreRecent =
      cm.lastPresenceReceived > cm.lastChatItem.date;

   if (moreRecent && now < last) {
      return ChatPresenceSubtitle(
         subtitle: g.param.typing,
         color: stl.colorScheme.secondary,
      );
   }

   return ChatPresenceSubtitle(
      subtitle: str,
      color: color,
   );
}

Widget makeChatTileSubtitle(BuildContext ctx, final ChatMetadata ch)
{
   String str = ch.lastChatItem.msg;

   // Chats that are empty have always prevalence
   if (str.isEmpty) {
      return Text(
         g.param.msgOnEmptyChat,
         maxLines: 1,
         overflow: TextOverflow.clip,
         style: Theme.of(ctx).textTheme.subtitle.copyWith(
            color: stl.colorScheme.secondary,
            //fontWeight: FontWeight.w500,
            fontStyle: FontStyle.italic,
         ),
      );
   }

   ChatPresenceSubtitle cps = makeLTPresenceSubtitle(
      ch,
      str,
      Colors.grey,
   );

   if (ch.nUnreadMsgs > 0 || !ch.lastChatItem.isFromThisApp())
      return Text(
         cps.subtitle,
         style: Theme.of(ctx).textTheme.subtitle.copyWith(
            color: cps.color,
         ),
         maxLines: 1,
         overflow: TextOverflow.clip
      );

   return Row(children: <Widget>
   [ chooseMsgStatusIcon(ch.lastChatItem.status)
   , Expanded(
        child: Text(cps.subtitle,
           maxLines: 1,
           overflow: TextOverflow.clip,
           style: Theme.of(ctx).textTheme.subtitle.copyWith(
              color: cps.color,
           ),
        ),
     ),
   ]);
}

String makeDateString(int date)
{
   DateTime dateObj = DateTime.fromMillisecondsSinceEpoch(date);
   DateFormat format = DateFormat.Hm();
   return format.format(dateObj);
}

String makeDateString2(int date)
{
   DateTime dateObj = DateTime.fromMillisecondsSinceEpoch(date);
   DateFormat format = Intl(g.param.localeName).date().add_yMEd().add_jm();
   return format.format(dateObj);
}

Widget makeChatListTileTrailingWidget(
   BuildContext ctx,
   int nUnreadMsgs,
   int date,
   int pinDate,
   int now,
   bool isFwdChatMsgs)
{
   if (isFwdChatMsgs)
      return null;

   Text dateText = Text(
      makeDateString(date),
      style: Theme.of(ctx).textTheme.caption,
   );

   if (nUnreadMsgs != 0 && pinDate != 0) {
      Row row = Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>
      [ Icon(Icons.place)
      , makeUnreadMsgsCircle(
          ctx,
          nUnreadMsgs,
          stl.colorScheme.secondary,
          stl.colorScheme.onSecondary,
        )
      ]);
      
      return Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget> [dateText, row]);
   } 
   
   if (nUnreadMsgs == 0 && pinDate != 0) {
      return Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget> [dateText, Icon(Icons.place)]);
   }
   
   if (nUnreadMsgs != 0 && pinDate == 0) {
      return Column(
         mainAxisSize: MainAxisSize.min,
         children: <Widget>
         [ dateText
         , makeUnreadMsgsCircle(
             ctx,
             nUnreadMsgs,
             stl.colorScheme.secondary,
             stl.colorScheme.onSecondary,
           )
         ]);
   }

   return dateText;
}

Color selectColor(int n)
{
   final int v = n % 14;
   switch (v) {
      case 0: return Colors.yellow[500];
      case 1: return Colors.pink;
      case 2: return Colors.pink;
      case 3: return Colors.pinkAccent;
      case 4: return Colors.redAccent;
      case 5: return Colors.deepOrange;
      case 6: return Colors.teal;
      case 7: return Colors.orange;
      case 8: return Colors.orangeAccent;
      case 9: return Colors.amberAccent;
      case 10: return Colors.lightGreen;
      case 11: return Colors.deepOrange[300];
      case 12: return Colors.teal[100];
      case 13: return Colors.green[500];
      case 14: return Colors.green[400];
      default: return Colors.grey;
   }
}

Widget makeChatListTile(
   BuildContext ctx,
   ChatMetadata chat,
   int now,
   bool isFwdChatMsgs,
   String avatar,
   double padding,
   double elevation,
   OnPressedFn0 onChatLeadingPressed,
   OnPressedFn0 onChatLongPressed,
   OnPressedFn0 onStartChatPressed,
) {
   Color bgColor;
   if (chat.isLongPressed) {
      bgColor = stl.chatLongPressendColor;
   } else {
      bgColor = stl.colorScheme.background;
   }

   Widget trailing = makeChatListTileTrailingWidget(
      ctx,
      chat.nUnreadMsgs,
      chat.lastChatItem.date,
      chat.pinDate,
      now,
      isFwdChatMsgs
   );

   ListTile lt =  ListTile(
      dense: false,
      enabled: true,
      trailing: trailing,
      onTap: onStartChatPressed,
      onLongPress: onChatLongPressed,
      subtitle: makeChatTileSubtitle(ctx, chat),
      leading: makeChatListTileLeading(
         chat.isLongPressed,
         avatar,
         selectColor(chat.peer.length),
         onChatLeadingPressed,
      ),
      title: Text(
         chat.getChatDisplayName(),
         maxLines: 1,
         overflow: TextOverflow.clip,
         style: stl.ltTitle,
      ),
   );

   return Padding(
	 padding: EdgeInsets.all(padding),
	 child: Card(
	    child: lt,
	    color: bgColor,
	    margin: EdgeInsets.all(0.0),
	    elevation: elevation,
	    shape: RoundedRectangleBorder(
	       borderRadius: BorderRadius.all(
		  Radius.circular(stl.cornerRadius)
	       ),
	       //side: BorderSide(width: 1.0, color: Colors.grey),
	    ),
	 ),
   );
}

Widget makeChatsExp(
   BuildContext ctx,
   bool isFav,
   bool isFwdChatMsgs,
   int now,
   Post post,
   List<ChatMetadata> ch,
   OnPressedFn1 onPressed,
   OnPressedFn1 onLongPressed,
   OnPressedFn3 onLeadingPressed,
   Function onPinPost,
) {
   List<Widget> list = List<Widget>(ch.length);

   int nUnreadChats = 0;
   for (int i = 0; i < list.length; ++i) {
      final int n = ch[i].nUnreadMsgs;
      if (n > 0)
         ++nUnreadChats;

      Widget card = makeChatListTile(
         ctx,
         ch[i],
         now,
         isFwdChatMsgs,
         isFav ? post.avatar : ch[i].avatar,
	 0.0,
	 0.0,
         (){onLeadingPressed(post.id, i);},
         () { onLongPressed(i); },
         () { onPressed(i); },
      );

      list[i] = Padding(
         child: card,
         padding: EdgeInsets.only(
            left: stl.chatTilePadding,
            right: stl.chatTilePadding,
            bottom: stl.chatTilePadding,
         ),
      );
   }

  if (ch.length < 5) {
     return Padding(
        child: Column(children: list),
        padding: EdgeInsets.only(top: stl.chatTilePadding),
     );
  }

  Widget title;
   if (nUnreadChats == 0) {
      title = Text('${ch.length} ${g.param.numberOfChatsSuffix}');
   } else {
      title = makeExpTileTitle(
         '${ch.length} ${g.param.numberOfChatsSuffix}',
         '$nUnreadChats ${g.param.numberOfUnreadChatsSuffix}',
         ', ',
         false,
      );
   }

   bool expState = (ch.length < 6 && ch.length > 0)
                       || nUnreadChats != 0;

   // I have observed that if the post has no chats and a chat
   // arrives, the chat expansion will continue collapsed independent
   // whether expState is true or not. This is undesireble, so I will
   // add a special case to handle it below.
   if (nUnreadChats == 0)
      expState = true;

   return Theme(
      data: makeExpTileThemeData(),
      child: ExpansionTile(
         backgroundColor: stl.expTileCardColor,
         initiallyExpanded: expState,
         leading: stl.favIcon,
         //key: GlobalKey(),
         //key: PageStorageKey<int>(post.id),
         title: title,
         children: list,
      ),
   );
}

Widget wrapPostOnButton(
   BuildContext ctx,
   List<Widget> wlist,
   double elevation,
   Function onPressed)
{
   return RaisedButton(
      color: Colors.white,
      onPressed: onPressed,
      elevation: elevation,
      child: Column(children: wlist),
      padding: const EdgeInsets.all(0.0),
   );
}

Widget makeChatTab({
   final bool isFwdChatMsgs,
   final int screen,
   final Node exDetailsRootNode,
   final Node inDetailsRootNode,
   final List<Post> posts,
   final List<Tree> trees,
   final OnPressedFn3 onPressed,
   final OnPressedFn3 onLongPressed,
   final OnPressedFn1 onDelPost1,
   final OnPressedFn1 onPinPost1,
   OnPressedFn5 onUserInfoPressed,
   final OnPressedFn3 onExpandImg1,
   final OnPressedFn1 onSharePost,
   final OnPressedFn0 onPost,
}) {
   if (posts.length == 0) {
      if (screen == cts.ownIdx)
	 return makeOwnEmptyScreenWidget(
            onPressed: onPost,
	 );

      if (screen == cts.favIdx)
	 return makeFavEmptyScreenWidget();
   }

   // No controller should be assigned to this listview. This will
   // break the automatic hiding of the tabbar
   return ListView.builder(
      padding: const EdgeInsets.only(
         left: stl.postListViewSidePadding,
         right: stl.postListViewSidePadding,
         top: stl.postListViewTopPadding,
      ),
      itemCount: posts.length,
      itemBuilder: (BuildContext ctx, int i)
      {
         OnPressedFn0 onPinPost = () {onPinPost1(i);};
         OnPressedFn0 onDelPost = () {onDelPost1(i);};
         OnPressedFn1 onExpandImg = (int j) {onExpandImg1(i, j);};

         if (isFwdChatMsgs) {
            onUserInfoPressed = (var a, var b, var c){};
            onPinPost = (){};
            onDelPost = (){};
         }

         Widget title = Text(
            makeTreeItemStr(trees[0].root.first, posts[i].channel[0][0]),
            maxLines: 1,
            overflow: TextOverflow.clip,
         );

         // If the post contains no images, which should not happen,
         // we provide no expand image button.
         if (posts[i].images.isEmpty)
            onExpandImg = (int j){print('Error: post.images is empty.');};

	 Widget bbb = makeNewPost(
            ctx: ctx,
	    screen: screen,
            snackbarStr: '',
            post: posts[i],
            exDetailsRootNode: exDetailsRootNode,
            inDetailsRootNode: inDetailsRootNode,
            trees: trees,
            imgFiles: List<File>(),
            onAddPhoto: (var a, var b) {print('Noop10');},
            onExpandImg: onExpandImg,
            onAddPostToFavorite:() {print('Noop14');},
	    onDelPost: onDelPost,
	    onSharePost: () {onSharePost(i);},
	    onReportPost:() {print('Noop18');},
	    onPinPost: onPinPost,
	 );

         Widget chatExpansion = makeChatsExp(
            ctx,
            screen == cts.favIdx,
            isFwdChatMsgs,
            DateTime.now().millisecondsSinceEpoch,
            posts[i],
            posts[i].chats,
            (int j) {onPressed(i, j);},
            (int j) {onLongPressed(i, j);},
            (int a, int b) {onUserInfoPressed(ctx, a, b);},
            onPinPost,
         );

         return Card(
            elevation: 2.0,
	    margin: EdgeInsets.only(bottom: 15.0),
	    color: Colors.grey[300],
	    child: Column(children: <Widget> [bbb, chatExpansion ]),
	 );
      },
   );
}

//_____________________________________________________________________

class DialogWithOp extends StatefulWidget {
   final Function getValueFunc;
   final Function setValueFunc;
   final Function onPostSelection;
   final String title;
   final String body;

   DialogWithOp(
      this.getValueFunc,
      this.setValueFunc,
      this.onPostSelection,
      this.title,
      this.body,
   );

   @override
   DialogWithOpState createState() => DialogWithOpState();
}

class DialogWithOpState extends State<DialogWithOp> {
   @override
   void initState()
   {
      super.initState();
   }

   @override
   Widget build(BuildContext ctx)
   {
      final SimpleDialogOption ok = SimpleDialogOption(
         child: Text(g.param.ok,
            style: TextStyle(color: Colors.blue, fontSize: 16.0),
         ),
         onPressed: () async
         {
            await widget.onPostSelection();
            Navigator.of(ctx).pop();
         },
      );

      final SimpleDialogOption cancel = SimpleDialogOption(
         child: Text(g.param.cancel,
            style: TextStyle(color: Colors.blue, fontSize: 16.0),
         ),
         onPressed: () { Navigator.of(ctx).pop(); },
      );

      List<SimpleDialogOption> actions = List<SimpleDialogOption>(2);
      actions[0] = cancel;
      actions[1] = ok;

      //Row row = Row(children:
      //   <Widget> [Icon(Icons.check_circle_outline, color: Colors.red)],
      //);

      CheckboxListTile tile = CheckboxListTile(
         title: Text(g.param.doNotShowAgain),
         value: !widget.getValueFunc(),
         onChanged: (bool v) { setState(() {widget.setValueFunc(!v);}); },
         controlAffinity: ListTileControlAffinity.leading,
      );

      return SimpleDialog(
         title: Text(widget.title),
         children: <Widget>
         [ Padding(
              padding: EdgeInsets.all(25.0),
              child: Center(
                 child: Text(widget.body,
                    style: TextStyle(fontSize: 16.0),
                 ),
              ),
           )
         , tile
         , Padding( child: Row(children: actions)
                  , padding: EdgeInsets.only(left: 70.0))
         ]);
   }
}

//_____________________________________________________________________

class AppState {
   Config cfg = Config();

   // The trees holding the locations and product trees.
   List<Tree> trees = List<Tree>();

   // The ex details tree root node.
   Node exDetailsRoot;

   // The in details tree root node.
   Node inDetailsRoot;

   // The list of posts received from the server. Our own posts that the
   // server echoes back to us (if we are subscribed to the channel)
   // will be filtered out.
   List<Post> posts = List<Post>();

   // The list of posts the user has selected in the posts screen.
   // They are moved from posts to here.
   List<Post> favPosts = List<Post>();

   // Posts the user wrote itself and sent to the server. One issue we
   // have to observe is that if the user is subscribed to the channel
   // the post belongs to, it will be received back and shouldn't be
   // displayed or duplicated on this list. The posts received from
   // the server will not be inserted in posts.
   //
   // The only posts inserted here are those that have been acked with
   // ok by the server, before that they will live in outPostsQueue
   List<Post> ownPosts = List<Post>();

   // Posts sent to the server that haven't been acked yet. At the
   // moment this queue will contain only one element. It is needed if
   // to handle the case where we go offline between a publish and a
   // publish_ack.
   Queue<Post> outPostsQueue = Queue<Post>();

   // Stores chat messages that cannot be lost in case the connection
   // to the server is lost. 
   Queue<AppMsgQueueElem> appMsgQueue = Queue<AppMsgQueueElem>();

   // Whether or not to show the dialog informing the user what
   // happens to selected or deleted posts in the posts screen.
   List<bool> dialogPrefs = List<bool>(6);

   Persistency2 persistency = Persistency2();

   AppState()
   {
   }

   Future<void> load() async
   {
      try {
         final String text = await rootBundle.loadString('data/parameters.txt');
         g.param = Parameters.fromJson(jsonDecode(text));
         await initializeDateFormatting(g.param.localeName, null);

         // Warning: The construction of Config depends on the
         // parameters that have been load above, but where not loaded
         // by the time it was inititalized. Ideally we would remove
         // the use of global variable from within its constructor,
         // for now I will construct it again before it is used to
         // initialize the db.
	 await persistency.open();

         final String exDetailsStr = await rootBundle.loadString('data/ex_details_menu.txt');
         exDetailsRoot = treeReader(jsonDecode(exDetailsStr)).first.root.first;

         final String inDetailsStr = await rootBundle.loadString('data/in_details_menu.txt');
         inDetailsRoot = treeReader(jsonDecode(inDetailsStr)).first.root.first;
      } catch (e) {
         print(e);
      }

      try {
         List<Config> configs = await persistency.loadConfig();
         if (configs.isNotEmpty)
            cfg = configs.first;
      } catch (e) {
         print(e);
      }

      dialogPrefs[0] = cfg.showDialogOnDelPost == 'yes';
      dialogPrefs[1] = cfg.showDialogOnSelectPost == 'yes';
      dialogPrefs[2] = cfg.showDialogOnReportPost == 'yes';
      dialogPrefs[3] = false;
      dialogPrefs[4] = false;
      dialogPrefs[5] = false;

      trees = loadTreeItems(await persistency.loadTrees(), g.param.filterDepths);

      try {
         final List<Post> posts = await persistency.loadPosts(g.param.rangesMinMax);
         for (Post p in posts) {
            if (p.status == 0) {
               ownPosts.add(p);
               for (Post o in ownPosts)
                  o.chats = await persistency.loadChatMetadata(o.id);
            } else if (p.status == 1) {
               posts.add(p);
            } else if (p.status == 2) {
               favPosts.add(p);
               for (Post o in favPosts)
                  o.chats = await persistency.loadChatMetadata(o.id);
            } else if (p.status == 3) {
               outPostsQueue.add(p);
            } else {
               assert(false);
            }
         }

         ownPosts.sort(compPosts);
         favPosts.sort(compPosts);
      } catch (e) {
         print(e);
      }

      List<AppMsgQueueElem> tmp = await persistency.loadOutChatMsg();

      appMsgQueue = Queue<AppMsgQueueElem>.from(tmp.reversed);

      print('Last post id: ${cfg.lastPostId}.');
      print('Last post id seen: ${cfg.lastSeenPostId}.');
      print('Login: ${cfg.appId}:${cfg.appPwd}');
   }

   int getNewPosts()
   {
      // NOTE: The posts array is expected to be sorted on its
      // ids, so we could perform a binary search here instead.
      final int i = posts.indexWhere((e)
         { return e.id == cfg.lastSeenPostId; });

      return i == -1 ? 0 : posts.length - i - 1;
   }

   Future<void> clearPosts() async
   {
      posts = List<Post>();
      await persistency.clearPosts();
   }

   Future<void> setRange(int i, RangeValues rv) async
   {
      cfg.ranges[2 * i + 0] = rv.start.round();
      cfg.ranges[2 * i + 1] = rv.end.round();
      await persistency.updateRanges(cfg.ranges);
   }

   void restoreTreeStacks()
   {
      trees[0].restoreMenuStack();
      trees[1].restoreMenuStack();
   }

   Future<void> setDialogPref(int i, bool v) async
   {
      dialogPrefs[i] = v;

      final String str = v ? 'yes' : 'no';

      if (i == 0)
         await persistency.updateShowDialogOnDelPost(v);
      else if (i == 1)
         await persistency.updateShowDialogOnSelectPost(v);
      else if (i == 2)
         await persistency.updateShowDialogOnReportPost(v);
   }

   // Return the index where the post in located in favPosts.
   Future<int> moveToFavorite(int i) async
   {
      // i refers to a post in the posts array.  We have to prevent the user
      // from adding a chat twice. This can happen when he makes a new search,
      // since in that case the lastPostId will be updated to 0.

      Post post = posts[i];
      posts.removeAt(i);

      var f = (e) { return e.id == post.id; };

      final int a = favPosts.indexWhere(f);
      if (a != -1)
	 return a;
      
      post.status = 2;
      final int k = post.addChat(post.from, post.nick, post.avatar);
      await persistency.insertChatOnPost2(post.id, post.chats[k]);

      favPosts.add(post);
      favPosts.sort(compPosts);

      return favPosts.indexWhere(f);
   }

   Future<void> delPostWithId(int i) async
   {
      await persistency.delPostWithId(posts[i].id);
      posts.removeAt(i);
   }

   Future<void>
   setChatAckStatus(String from, int postId, List<int> rowids, int status) async
   {
      List<Post> list = favPosts;
      IdxPair p = findChat(list, from, postId);
      if (IsInvalidPair(p)) {
	 list = ownPosts;
	 p = findChat(ownPosts, from, postId);
      }

      if (IsInvalidPair(p)) {
	 print('Chat not found: from = $from, postId = $postId');
	 return;
      }

      for (int rowid in rowids) {
	 final ChatMetadata cm = list[p.i].chats[p.j];
	 cm.setAckStatus(rowid, status);
	 cm.lastChatItem.status = status;

	 // Typically there won't be many rowids in this loop so it is fine to
	 // use await here. The ideal case however is to offer a List<ChatItem>
	 // interface in Persistency and use batch there.

	 await persistency.updateAckStatus(cm.lastChatItem, status, rowid, postId, from);
      }
   }

   Future<void>
   setCredentials(String id, String password) async
   {
      cfg.appId = id;
      cfg.appPwd = password;
      await persistency.updateAppCredentials(id, password);
   }

   Future<int>
   setChatMessage(int postId, String peer, ChatItem ci, bool fav) async
   {
      List<Post> list = ownPosts;
      if (fav)
	 list = favPosts;

      final int i = list.indexWhere((e) { return e.id == postId;});
      assert(i != -1);

      Post post = list[i];
      // We have to make sure every unread msg is marked as read
      // before we receive any reply.
      final int j = post.getChatHistIdx(peer);
      assert(j != -1);

      final int rowid = await persistency.insertChatMsg(postId, peer, ci);
      ci.rowid = rowid;
      post.chats[j].addChatItem(ci);

      await persistency.insertChatOnPost(postId, post.chats[j]);

      post.chats.sort(compChats);
      list.sort(compPosts);
      return rowid;
   }

   Future<void> setLastPostId(int id) async
   {
      await persistency.updateLastSeenPostId(id);
   }

   Future<void> setNUnreadMsgs(int id, String from) async
   {
      await persistency.updateNUnreadMsgs(id, from);
   }

   Future<void> setPinPostDate(int i, bool fav) async
   {
      List<Post> list = ownPosts;
      if (fav)
	 list = favPosts;

      Post post = list[i];
      await persistency.updatePostPinDate(post.pinDate, post.id);
      post.pinDate = post.pinDate == 0 ? DateTime.now().millisecondsSinceEpoch : 0;
      list.sort(compPosts);
   }
}

//_____________________________________________________________________

class Occase extends StatefulWidget {
  Occase();

  @override
  OccaseState createState() => OccaseState();
}

class OccaseState extends State<Occase>
   with SingleTickerProviderStateMixin, WidgetsBindingObserver
{
   AppState _appState = AppState();

   // Will be set to true if the user scrolls up a chat screen so that
   // the jump down button can be used
   List<bool> _showChatJumpDownButtons = List<bool>.filled(3, true);

   // Set to true when the user wants to change his email or nick or on
   // the first time the user opens the app.
   bool _goToRegScreen = false;

   // Set to true when the user wants to change his notification
   // settings.
   bool _goToNtfScreen = false;

   // A flag that is set to true when the floating button (new post)
   // is clicked. It must be carefully set to false when that screen
   // are left.
   bool _newPostPressed = false;

   // This error code assumes the following values
   // -1: No error, nothing to do.
   //  0: There was an error uploading the images.
   //  1: The post was sent to the server.
   int _newPostErrorCode = -1;

   // Similar to _newPostPressed but for the filter screen.
   bool _newSearchPressed = false;

   // The index of the tab we are currently in in the *new
   // post* or *Filters* screen. For example 0 for the localization
   // tree, 1 for the models tree etc.
   int _botBarIdx = 0;

   // The temporary variable used to store the post the user sends or
   // the post the current chat screen is open, if any.
   List<Post> _posts = List<Post>(3);

   // The current chat, if any.
   List<ChatMetadata> _chats = List<ChatMetadata>(3);

   // The number of posts in the _appState.posts array that hasn't been seen
   // yet by the user.
   int _nNewPosts = 0;

   // This list will store the posts in _fav or _own chat screens that
   // have been long pressed by the user. However, once one post is
   // long pressed to select the others is enough to perform a simple
   // click.
   List<List<Coord>> _lpChats = List<List<Coord>>.filled(3, List<Coord>());

   // A temporary variable used to store forwarded chat messages.
   List<List<Coord>> _lpChatMsgs = List<List<Coord>>.filled(3, List<Coord>());

   Queue<dynamic> _wsMsgQueue = Queue<dynamic>();

   // When the user is on a chat screen and dragged a message or
   // clicked reply on a long-pressed message this index will be set
   // to the index that leads to the message. It will be set back to
   // -1 when
   //
   // 1. The message is sent
   // 2. The user cancels the operation.
   // 3. The user leaves the chat screen.
   List<int> _dragedIdxs = List<int>.filled(3, -1);

   TabController _tabCtrl;

   // Each tab gets one scroll controller.
   List<ScrollController> _scrollCtrl = List<ScrollController>.filled(3, ScrollController());

   List<ScrollController> _chatScrollCtrl = List<ScrollController>.filled(3, ScrollController());

   // Used for every screen that offers text input.
   TextEditingController _txtCtrl;

   // Used in some cases where two text fields are required.
   TextEditingController _txtCtrl2;
   List<FocusNode> _chatFocusNodes = List<FocusNode>.filled(3, FocusNode());

   HtmlWebSocketChannel channel;
   //IOWebSocketChannel channel;

   // This variable is set to the last time the app was disconnected
   // from the server, a value of -1 means we still did not get
   // disconnected since startup..
   int _lastDisconnect = -1;

   // Used in the final new post screen to store the files while the
   // user chooses the images.
   List<File> _imgFiles = List<File>();

   Timer _filenamesTimer = Timer(Duration(seconds: 0), (){});

   // These indexes will be set to values different from -1 when the
   // user clics on an image to expand it.
   List<int> _expPostIdxs = List<int>.filled(3, -1);
   List<int> _expImgIdxs = List<int>.filled(3, -1);

   // Used to cache to fcmToken.
   String _fcmToken = '';

   //final FirebaseMessaging _firebaseMessaging = FirebaseMessaging();

   @override
   void initState()
   {
      super.initState();

      _tabCtrl = TabController(vsync: this, initialIndex: 1, length: 3);
      _txtCtrl = TextEditingController();
      _txtCtrl2 = TextEditingController();
      _tabCtrl.addListener(_tabCtrlChangeHandler);

      _chatScrollCtrl[cts.ownIdx].addListener(() {_chatScrollListener(cts.ownIdx);});
      _chatScrollCtrl[cts.favIdx].addListener(() {_chatScrollListener(cts.favIdx);});

      _lastDisconnect = -1;

      WidgetsBinding.instance.addObserver(this);

      //_firebaseMessaging.configure(
      //   onMessage: (Map<String, dynamic> message) async {
      //     print("onMessage: $message");
      //   },
      //   onBackgroundMessage: fcmOnBackgroundMessage,
      //   onLaunch: (Map<String, dynamic> message) async {
      //     print("onLaunch: $message");
      //   },
      //   onResume: (Map<String, dynamic> message) async {
      //     print("onResume: $message");
      //   },
      //);

      //_firebaseMessaging.getToken().then((String token) {
      //   if (_fcmToken != null)
      //      _fcmToken = token;

      //   print('Token: $token');
      //});

      WidgetsBinding.instance.addPostFrameCallback((_) async
      {
	 await _appState.load();
         _nNewPosts = _appState.getNewPosts();
	 _goToRegScreen = _appState.cfg.nick.isEmpty;
	 prepareNewPost();
	 _stablishNewConnection(_fcmToken);
	 setState(() { });
      });
   }

   @override
   void dispose()
   {
      _txtCtrl.dispose();
      _txtCtrl2.dispose();
      _tabCtrl.dispose();
      _scrollCtrl[0].dispose();
      _scrollCtrl[1].dispose();
      _scrollCtrl[2].dispose();
      _chatScrollCtrl[cts.ownIdx].dispose();
      _chatScrollCtrl[cts.favIdx].dispose();
      _chatFocusNodes[0].dispose();
      _chatFocusNodes[1].dispose();
      _chatFocusNodes[2].dispose();
      WidgetsBinding.instance.removeObserver(this);

      super.dispose();
   }

   @override
   void didChangeAppLifecycleState(AppLifecycleState state)
   {
      // We should not try to reconnect if disconnection happened just
      // a couples of seconds ago. This is needed because it may
      // haven't been a clean disconnect with a close websocket frame.
      // The server will wait until the pong answer times out.  To
      // solve this we compare _lastDisconnect with the current time.

      bool doConnect = false;
      if (_lastDisconnect != -1) {
         final int now = DateTime.now().millisecondsSinceEpoch;
         final int interval = now - _lastDisconnect;
         doConnect = interval > cts.pongTimeout;
      }

      if (state == AppLifecycleState.resumed && doConnect) {
         print('Trying to reconnect.');
         _stablishNewConnection(_fcmToken);
      }
   }

   int _screenIdx()
   {
      return _isOnOwn() ? cts.ownIdx :
	     _isOnFav() ? cts.favIdx :
	                  cts.searchIdx;
   }

   bool _isOnOwn()
   {
      return _tabCtrl.index == cts.ownIdx;
   }

   bool _isOnSearch()
   {
      return _tabCtrl.index == cts.searchIdx;
   }

   bool _isOnFav()
   {
      return _tabCtrl.index == cts.favIdx;
   }

   bool _isOnFavChat()
   {
      return _isOnFav() && _posts[cts.favIdx] != null && _chats[cts.favIdx] != null;
   }

   bool _isOnOwnChat()
   {
      return _isOnOwn() && _posts[cts.ownIdx] != null && _chats[cts.ownIdx] != null;
   }

   bool _onTabSwitch()
   {
      return _tabCtrl.indexIsChanging;
   }

   List<double> _getNewMsgsOpacities()
   {
      List<double> opacities = List<double>(3);

      double onFocusOp = 1.0;
      double notOnFocusOp = 0.7;

      opacities[0] = notOnFocusOp;
      if (_isOnOwn())
         opacities[0] = onFocusOp;

      opacities[1] = notOnFocusOp;
      if (_isOnSearch())
         opacities[1] = onFocusOp;

      opacities[2] = notOnFocusOp;
      if (_isOnFav())
         opacities[2] = onFocusOp;

      return opacities;
   }

   OccaseState()
   {
      _botBarIdx = 0;
   }

   void sendOfflinePosts()
   {
      if (_appState.outPostsQueue.isEmpty)
         return;
       
      final String payload = makePostPayload(_appState.outPostsQueue.first);
      channel.sink.add(payload);
   }

   void _stablishNewConnection(String fcmToken)
   {
      try {
	 // For the web
	 channel = HtmlWebSocketChannel.connect(cts.dbHost);
	 //channel = IOWebSocketChannel.connect(cts.dbHost);
	 channel.stream.listen(
	    _onWSData,
	    onError: _onWSError,
	    onDone: _onWSDone,
	 );

	 final String cmd = makeConnCmd(
	    _appState.cfg.appId,
	    _appState.cfg.appPwd,
	    fcmToken,
	    _appState.cfg.notifications.getFlag(),
	 );

	 channel.sink.add(cmd);
      } catch (e) {
	 print('Unable to stablish ws connection to server.');
	 print(e);
      }
   }

   Future<void> _setDialogPref(int i, bool v) async
   {
      _appState.setDialogPref(i, v);
   }

   Future<void>
   _alertUserOnPressed(BuildContext ctx, int i, int j) async
   {
      if (!_appState.dialogPrefs[j]) {
         await _onPostSelection(i, j);
         return;
      }

      showDialog(
         context: ctx,
         builder: (BuildContext ctx)
         {
            return DialogWithOp(
               () {return _appState.dialogPrefs[j];},
               (bool v) async {await _setDialogPref(j, v);},
               () async {await _onPostSelection(i, j);},
               g.param.dialogTitles[j],
               g.param.dialogBodies[j]);
         },
      );
   }

   Future<void> _clearPosts() async
   {
      await _appState.clearPosts();
      setState((){ _nNewPosts = 0; });
   }

   void _clearPostsDialog(BuildContext ctx)
   {
      _showSimpleDialog(
         ctx,
         () async { await _clearPosts(); },
         g.param.clearPostsTitle,
         Text(g.param.clearPostsContent),
      );
   }

   // Used to either add or remove a photo from the new post.
   // i = -1 ==> add
   // i != -1 ==> remove, in this case i is the index to remove.
   Future<void> _onAddPhoto(BuildContext ctx, int i) async
   {
      try {
         // It looks like we do not need to show any dialog here to
         // inform the maximum number of photos has been reached.
         if (i == -1) {
            File img = await ImagePicker.pickImage(
               source: ImageSource.gallery,
               maxWidth: 2 * makeImgWidth(ctx),
               maxHeight: makeImgHeight(ctx, 2 * cts.imgHeightFactor),
               //imageQuality: cts.imgQuality,
            );

            if (img == null)
               return;

            setState((){_imgFiles.add(img); });
         } else {
            setState((){_imgFiles.removeAt(i); });
         }
      } catch (e) {
         print(e);
      }
   }

   // i = index in _appState.posts, _appState.favPosts, _own_posts.
   // j = image index in the post.
   void _onExpandImg(int i, int j, int k)
   {
      //print('Expand image clicked with $i $j.');

      //_nNewPosts

      setState((){
         _expPostIdxs[k] = i;
         _expImgIdxs[k] = j;
      });
   }

   void _onRangeValueChanged(int i, double v)
   {
      setState((){_posts[cts.ownIdx].rangeValues[i] = v.round();});
   }

   Future<void> _onRangeChanged(int i, RangeValues rv) async
   {
      _appState.setRange(i, rv);
      setState(() { });
   }

   void _onClickOnPost(int i, int j)
   {
      if (j == 1) {
	 print('Sharing post $i');
         Share.share(g.param.share, subject: g.param.shareSubject);
         return;
      }
   }

   Future<void> _onMovePostToFav(int i) async
   {
      final int h = await _appState.moveToFavorite(i);
      assert(h != -1);

      // We should be using the animate function below, but there is no way
      // one can wait until the animation is ready. The is needed to be able to call
      // _onChatPressed(i, 0) correctly. I will let it commented out for now.

      // Use _tabCtrlChangeHandler() as listener
      //_tabCtrl.animateTo(2, duration: Duration(seconds: 2));
      _tabCtrl.index = cts.favIdx;

      // The chat index in the fav screen is always zero.
      await _onChatPressed(h, 0);
   }

   // For the meaning of the index j see makeNewPostImpl.
   //
   // j = 0: Ignore post.
   // j = 1: Move to favorite.
   // j = 2: Report inapropriate.
   // j = 3: Share.
   Future<void> _onPostSelection(int i, int j) async
   {
      if (j == 3) {
         Share.share(g.param.share, subject: g.param.shareSubject);
         return;
      }

      if (j == 1) {
	 await _onMovePostToFav(i);
      } else {
         await _appState.delPostWithId(i);
         // TODO: Send command to server to report if j = 2.
      }

      setState(() { });
   }

   void prepareNewPost()
   {
      _posts[cts.ownIdx] = Post(rangesMinMax: g.param.rangesMinMax);
      _posts[cts.ownIdx].reset();
   }

   void _onNewPost()
   {
      setState(() {
	 _newPostPressed = true;
	 prepareNewPost();
	 _appState.restoreTreeStacks();
	 _botBarIdx = 0;
      });
   }

   // This function has a side effect. It updates _nNewPosts.
   int _makeLastSeenPostId()
   {
      assert(_nNewPosts >= 0);

      // The number of posts that will be shown to the user when he
      // clicks the download button. It is at most maxPostsOnDownload.
      // If it is less than that number we show all.
      int n = _nNewPosts;
      if (n > cts.maxPostsOnDownload)
         n = cts.maxPostsOnDownload;

      _nNewPosts -= n;

      final int l = _appState.posts.length;

      assert(l >= _nNewPosts);

      print('----------> $l $_nNewPosts ${_appState.posts.length} ');
      // The index of the last post already shown to the user.
      return l - _nNewPosts - 1;
   }

   Future<void> _onShowNewPosts() async
   {
      final int idx = _makeLastSeenPostId();
      await _appState.setLastPostId(_appState.posts[idx].id);
      setState((){});
   }

   bool _onWillPopMenu(
      final List<Tree> trees,
      int leaveIdx,
   ) {
      // We may want to  split this function in two: One for the
      // search and one for the new post screen.
      if (_botBarIdx >= trees.length) {
         setState(() { --_botBarIdx; });
         return false;
      }

      if (trees[_botBarIdx].root.length == 1) {
         if (_botBarIdx <= leaveIdx){
            _newPostPressed = false;
            _newSearchPressed = false;
         } else {
            --_botBarIdx;
         }

         setState(() { });
         return false;
      }

      trees[_botBarIdx].root.removeLast();
      setState(() { });
      return false;
   }

   void _cleanUpLpOnSwitchTab(int i)
   {
      _lpChats[i].forEach((e){toggleLPChat(e.chat);});
      _lpChatMsgs[i].forEach((e){toggleLPChatMsg(e.chat.msgs[e.msgIdx]);});

      _lpChats[i].clear();
      _lpChatMsgs[i].clear();
   }

   // Called with
   //
   // i = 0: own
   // i = 2: fav
   //
   Future<void> _onFwdSendButton(int i) async
   {
      final int now = DateTime.now().millisecondsSinceEpoch;
      for (Coord c1 in _lpChats[i]) {
         for (Coord c2 in _lpChatMsgs[i]) {
            ChatItem ci = ChatItem(
               isRedirected: 1,
               msg: c2.chat.msgs[c2.msgIdx].msg,
               date: now,
            );

	    await _onSendChatImpl(c1.post.id, c1.chat.peer, ci);
         }
      }

      _lpChats[i].forEach((e){toggleLPChat(e.chat);});
      _lpChatMsgs[i].forEach((e){toggleLPChatMsg(e.chat.msgs[e.msgIdx]);});

      _posts[i] = _lpChatMsgs[i].first.post;
      _chats[i] = _lpChatMsgs[i].first.chat;

      _lpChats[i].clear();
      _lpChatMsgs[i].clear();

      setState(() { });
   }

   Future<bool> _onPopChat(int i) async
   {
      await _appState.setNUnreadMsgs(_posts[i].id, _chats[i].peer);

      _showChatJumpDownButtons[i] = false;
      _dragedIdxs[i] = -1;
      _chats[i].nUnreadMsgs = 0;
      _chats[i].divisorUnreadMsgs = 0;
      _chats[i].divisorUnreadMsgsIdx = -1;
      _lpChatMsgs[i].forEach((e){toggleLPChatMsg(_chats[i].msgs[e.msgIdx]);});

      final bool isEmpty = _lpChatMsgs[i].isEmpty;
      _lpChatMsgs[i].clear();

      if (isEmpty) {
         _posts[i] = null;
         _chats[i] = null;
      }

      setState(() { });
      return false;
   }

   void _onCancelFwdLpChat(int i)
   {
      _dragedIdxs[i] = -1;
      setState(() { });
   }

   Future<void> _onSendChat(int i) async
   {
      _chats[i].nUnreadMsgs = 0;
      await _onSendChatImpl(
         _posts[i].id,
         _chats[i].peer,
         ChatItem(
            isRedirected: 0,
            msg: _txtCtrl.text,
            date: DateTime.now().millisecondsSinceEpoch,
            refersTo: _dragedIdxs[i],
            status: 0,
         ),
      );

      _txtCtrl.clear();
      _dragedIdxs[i] = -1;

      setState(()
      {
         SchedulerBinding.instance.addPostFrameCallback((_)
         {
            _chatScrollCtrl[i].animateTo(
               _chatScrollCtrl[i].position.maxScrollExtent,
               duration: const Duration(milliseconds: 300),
               curve: Curves.easeOut);
         });
      });
   }

   // Called when the user changes text in the chat text field.
   void _onWritingChat(String v, int i)
   {
      assert(_chats[i] != null);
      assert(_posts[i] != null);

      // When the chat input text field was empty and the user types
      // in some text, we have to call set state to enable the send
      // button. If the user erases all the text we have to disable
      // the button. To simplify the implementation I will call
      // setState on every change, since this does not significantly
      // decreases performance.
      setState((){});

      final int now = DateTime.now().millisecondsSinceEpoch;
      final int last = _chats[i].lastPresenceSent + cts.presenceInterval;

      if (now < last)
         return;

      _chats[i].lastPresenceSent = now;

      var subCmd = {
         'cmd': 'presence',
         'to': _chats[i].peer,
         'type': 'writing',
         'post_id': _posts[i].id,
      };

      final String payload = jsonEncode(subCmd);
      print(payload);
      channel.sink.add(payload);
   }

   void _chatScrollListener(int i)
   {
      if (i != _screenIdx()) {
	 // The control listener seems to be bound to all screens, thats why I
	 // have to filter it here.
	 print('Ignoring ---> $i');
	 return;
      }

      final double offset = _chatScrollCtrl[i].offset;
      final double max = _chatScrollCtrl[i].position.maxScrollExtent;

      final double tol = 40.0;

      final bool old = _showChatJumpDownButtons[i];

      if (_showChatJumpDownButtons[i] && !(offset < max))
         setState(() {_showChatJumpDownButtons[i] = false;});

      if (!_showChatJumpDownButtons[i] && (offset < (max - tol)))
         setState(() {_showChatJumpDownButtons[i] = true;});

      if (!old && _showChatJumpDownButtons[i])
         _chats[i].nUnreadMsgs = 0;
   }

   void _onFwdChatMsg(int i)
   {
      assert(_lpChatMsgs[i].isNotEmpty);

      _posts[i] = null;
      _chats[i] = null;

      setState(() { });
   }

   void _onDragChatMsg(BuildContext ctx, int k, DragStartDetails d, int i)
   {
      _dragedIdxs[i] = k;
      FocusScope.of(ctx).requestFocus(_chatFocusNodes[i]);
      setState(() {});
   }

   void _onChatMsgReply(BuildContext ctx, int i)
   {
      assert(_lpChatMsgs[i].length == 1);

      _dragedIdxs[i] = _lpChatMsgs[i].first.msgIdx;

      assert(_dragedIdxs[i] != -1);

      _lpChatMsgs[i].forEach((e){toggleLPChatMsg(e.chat.msgs[e.msgIdx]);});
      _lpChatMsgs[i].clear();
      FocusScope.of(ctx).requestFocus(_chatFocusNodes[i]);
      setState(() { });
   }

   Future<void> _onChatAttachment() async
   {
      print('_onChatAttachment.');
      var image =
         await ImagePicker.pickImage(source: ImageSource.gallery);

       setState(() { });
   }

   void _onBotBarTapped(int i)
   {
      if (_botBarIdx < _appState.trees.length)
         _appState.trees[_botBarIdx].restoreMenuStack();

      setState(() { _botBarIdx = i; });
   }

   void _onNewPostBotBarTapped(int i)
   {
      // We allow the user to tap backwards to a new tab but not
      // forward.  This is to avoid complex logic of avoid the
      // publication of imcomplete posts.
      if (i >= _botBarIdx)
         return;

      // The desired tab is *i* the current tab is _botBarIdx. For any
      // tab we land on or walk through we have to restore the menu
      // stack, except for the last two tabs.

      if (i == 2) {
         _botBarIdx = 2;
         setState(() { });
         return;
      }

      _botBarIdx = i + 1;

      do {
         --_botBarIdx;
         _appState.trees[_botBarIdx].restoreMenuStack();
      } while (_botBarIdx != i);

      setState(() { });
   }

   void _onPostLeafPressed(int i, int j)
   {
      Node o = _appState.trees[_botBarIdx].root.last.children[i];
      _appState.trees[_botBarIdx].root.add(o);
      _onPostLeafReached(j);
      setState(() { });
   }

   void _onPostLeafReached(int i)
   {
      _posts[i].channel[_botBarIdx][0] = _appState.trees[_botBarIdx].root.last.code;
      _appState.trees[_botBarIdx].restoreMenuStack();
      _botBarIdx = postIndexHelper(_botBarIdx);
   }

   void _onPostNodePressed(int i, int j)
   {
      print('asssaaa $i $j $_botBarIdx');
      // We continue pushing on the stack if the next screen will have
      // only one menu option.
      do {
         Node o = _appState.trees[_botBarIdx].root.last.children[i];
         _appState.trees[_botBarIdx].root.add(o);
         i = 0;
      } while (_appState.trees[_botBarIdx].root.last.children.length == 1);

      final int length = _appState.trees[_botBarIdx].root.last.children.length;

      assert(length != 1);

      if (length == 0) {
         _onPostLeafReached(j);
      }

      setState(() { });
   }

   void _onFilterNodePressed(int i)
   {
      Node o = _appState.trees[_botBarIdx].root.last.children[i];
      _appState.trees[_botBarIdx].root.add(o);

      setState(() { });
   }

   Future<void> _onFilterLeafNodePressed(int k) async
   {
      // k = 0 means the *check all fields*.
      if (k == 0) {
         List<NodeInfo2> list = _appState.trees[_botBarIdx].updateLeafReachAll(_botBarIdx);
	 await _appState.persistency.updateLeafReach2(list, _botBarIdx);
         setState(() { });
         return;
      }

      --k; // Accounts for the Todos index.

      NodeInfo2 ni2 = _appState.trees[_botBarIdx].updateLeafReach(k, _botBarIdx);
      await _appState.persistency.updateLeafReach(ni2, _botBarIdx);
      setState(() { });
   }

   Future<void> _sendPost() async
   {
      _posts[cts.ownIdx].from = _appState.cfg.appId;
      _posts[cts.ownIdx].nick = _appState.cfg.nick;
      _posts[cts.ownIdx].avatar = emailToGravatarHash(_appState.cfg.email);
      _posts[cts.ownIdx].status = 3;

      Post post = _posts[cts.ownIdx].clone();

      final bool isEmpty = _appState.outPostsQueue.isEmpty;

      // We add it here in our own list of posts and keep in mind it
      // will be echoed back to us if we are subscribed to its
      // channel. It has to be filtered out from _appState.posts since that
      // list should not contain our own posts.

      post.dbId = await _appState.persistency.insertPost(post, ConflictAlgorithm.replace);
      _appState.outPostsQueue.add(post);

      if (!isEmpty)
         return;

      // The queue was empty before we inserted the new post.
      // Therefore we are not waiting for an ack.

      final String payload = makePostPayload(_appState.outPostsQueue.first);
      print(payload);
      channel.sink.add(payload);
   }

   Future<void> _handlePublishAck(final int id, final int date) async
   {
      try {
         assert(_appState.outPostsQueue.isNotEmpty);
         Post post = _appState.outPostsQueue.removeFirst();
         if (id == -1) {
	    await _appState.persistency.delPostWithRowid(post.dbId);
            setState(() {_newPostErrorCode = 0;});
            return;
         }

         // When working with the simulator I noticed on my machine
         // that it replies before the post could be moved from the
         // output queue to the . In normal cases users won't
         // be so fast. But since this is my test condition, I will
         // cope with that by inserting the post in _appState.ownPosts and only
         // after that removing from the queue.
         // TODO: I think this does not hold anymore after I
         // introduced a message queue.

         post.id = id;
         post.date = date;
         post.status = 0;
         post.pinDate = 0;
         _appState.ownPosts.add(post);
         _appState.ownPosts.sort(compPosts);

         await _appState.persistency.updatePostOnAck(0, id, date, post.dbId);

         setState(() {_newPostErrorCode = 1;});

         if (_appState.outPostsQueue.isEmpty)
            return;

         final String payload = makePostPayload(_appState.outPostsQueue.first);
         channel.sink.add(payload);
      } catch (e) {
         print(e);
      }
   }

   Future<void> _onRemovePost(int i) async
   {
      if (_isOnFav()) {
         await _appState.persistency.delPostWithId(_appState.favPosts[i].id);
         _appState.favPosts.removeAt(i);
      } else {
         await _appState.persistency.delPostWithId(_appState.ownPosts[i].id);
         final Post delPost = _appState.ownPosts.removeAt(i);

         var msgMap = {
            'cmd': 'delete',
            'id': delPost.id,
            'to': toChannelHashCode(
               delPost.channel[1][0],
               g.param.filterDepths[1]
            ),
         };

         await _sendAppMsg(jsonEncode(msgMap), 0);
      }

      setState(() { });
   }

   Future<void> _onPinPost(int i) async
   {
      await _appState.setPinPostDate(i, _isOnFav());
      setState(() { });
   }

   Future<int> _uploadImgs(List<String> fnames) async
   {
      // TODO: Add timeouts.

      final int l1 = fnames.length;
      final int l2 = _imgFiles.length;

      final int l = l1 < l2 ? l1 : l2; // min

      for (int i = 0; i < l; ++i) {
         final String path = _imgFiles[i].path;
         final String basename = p.basename(path);
         final String extension = p.extension(basename);
         //String newname = fnames[i] + '.' + extension;
         final String newname = fnames[i] + '.jpg';

         print('=====> Path $path');
         print('=====> Image name $basename');
         print('=====> Image extention $extension');
         print('=====> New name $newname');
         print('=====> Http target $newname');

         //var headers = {'Accept-Encoding': 'identity'};

         var response = await http.post(newname,
            //headers: headers,
            body: await _imgFiles[i].readAsBytes(),
         );

         final int stCode = response.statusCode;
         if (stCode != 200) {
            _imgFiles = List<File>();
            return 0;
         }

         _posts[cts.ownIdx].images.add(newname);
      }

      _imgFiles = List<File>();
      return -1;
   }

   void _requestFilenames()
   {
      // Consider: Check if the app is online before sending.

      var cmd = {
         'cmd': 'filenames',
      };

      String payload = jsonEncode(cmd);
      print(payload);
      channel.sink.add(payload);

      _filenamesTimer = Timer(
         Duration(seconds: cts.filenamesTimeout),
         () {
            _leaveNewPostScreen();
            _newPostErrorCode = 0;
         },
      );

      setState(() { });
   }

   Future<void> _onSendNewPost(BuildContext ctx, int i) async
   {
      // When the user sends a post, we start a timer and a circular
      // progress indicator on the screen. To prevent the user from
      // interacting with the screen after clicking we use a modal
      // barrier.

      if (_filenamesTimer.isActive)
         return;

      assert(i != 2);

      if (i == 0) {
         _showSimpleDialog(
            ctx,
            (){
               _newPostPressed = false;
               _posts[cts.ownIdx] = null;
               setState((){});
            },
            g.param.cancelPost,
            Text(g.param.cancelPostContent),
         );
         return;
      }

      if (_imgFiles.length < cts.minImgsPerPost) {
         _showSimpleDialog(
            ctx,
            (){ },
            g.param.postMinImgs,
            Text(g.param.postMinImgsContent),
         );
         return;
      }

      await showModalBottomSheet<void>(
         context: ctx,
         backgroundColor: Colors.white,
         elevation: 1.0,
         shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(20.0)),
         ),
         builder: (BuildContext ctx)
         {
            return makePaymentChoiceWidget(
               ctx,
               (BuildContext ctx)
               {
                  Navigator.of(ctx).pop();
                  _requestFilenames();
               },
            );
         },
      );
   }

   void _removePostDialog(BuildContext ctx, int i)
   {
      _showSimpleDialog(
         ctx,
         () async { await _onRemovePost(i);},
         g.param.dialogTitles[4],
         Text(g.param.dialogBodies[4]),
      );
   }

   Future<void> _onChatPressedImpl(
      List<Post> posts,
      int i,
      int j,
      int k,
   ) async {
      if (_lpChats[k].isNotEmpty || _lpChatMsgs[i].isNotEmpty) {
         _onChatLPImpl(posts, i, j, k);
         setState(() { });
         return;
      }

      _showChatJumpDownButtons[k] = false;
      Post post = posts[i];
      ChatMetadata chat = posts[i].chats[j];

      if (!chat.isLoaded())
         chat.msgs = await _appState.persistency.loadChatMsgs(post.id, chat.peer);
      
      // These variables must be set after the chats are loaded. Otherwise
      // chat.msgs may be called on null if a message arrives. 
      _posts[k] = post;
      _chats[k] = chat;

      if (_chats[k].nUnreadMsgs != 0) {
         _chats[k].divisorUnreadMsgsIdx = _chats[k].msgs.length - _chats[k].nUnreadMsgs;

         // We know the number of unread messages, now we have to generate
         // the array with the messages peer rowid.

         var msgMap =
         { 'cmd': 'message'
         , 'type': 'chat_ack_read'
         , 'to': posts[i].chats[j].peer
         , 'post_id': posts[i].id
         , 'id': -1
         , 'ack_ids': readPeerRowIdsToAck(_chats[k].msgs, _chats[k].nUnreadMsgs)
         };

         await _sendAppMsg(jsonEncode(msgMap), 0);
      }

      setState(() {
         SchedulerBinding.instance.addPostFrameCallback((_)
         {
            _chatScrollCtrl[k].jumpTo(_chatScrollCtrl[k].position.maxScrollExtent);
         });
      });
   }

   void _onChatJumpDown(int k)
   {
      setState(()
      {
         _chatScrollCtrl[k].jumpTo(_chatScrollCtrl[k].position.maxScrollExtent);
      });
   }

   Future<void> _onChatPressed(int i, int j) async
   {
      if (_isOnFav())
         await _onChatPressedImpl(_appState.favPosts, i, j, cts.favIdx);
      else
         await _onChatPressedImpl(_appState.ownPosts, i, j, cts.ownIdx);
   }

   void _onUserInfoPressed(BuildContext ctx, int postId, int j)
   {
      List<Post> posts;
      if (_isOnFav()) {
         posts = _appState.favPosts;
      } else {
         posts = _appState.ownPosts;
      }

      final int i = posts.indexWhere((e) { return e.id == postId;});
      assert(i != -1);
      assert(j < posts[i].chats.length);

      final String peer = posts[i].chats[j].peer;
      final String nick = posts[i].chats[j].nick;
      final String title = '$nick: $peer';

      final String avatar =
         _isOnFav() ? posts[i].avatar : posts[i].chats[j].avatar;

      final String url = cts.gravatarUrl + avatar + '.jpg';

      _showSimpleDialog(
         ctx,
         (){},
         title,
         makeNetImgBox(
            cts.onClickAvatarWidth,
            cts.onClickAvatarWidth,
            url,
            BoxFit.contain,
         ),
      );
   }

   void _onChatLPImpl(List<Post> posts, int i, int j, int k)
   {
      final Coord tmp = Coord(post: posts[i], chat: posts[i].chats[j]);

      handleLPChats(
         _lpChats[k],
         toggleLPChat(posts[i].chats[j]),
         tmp,
	 compPostIdAndPeer,
      );
   }

   void _onChatLP(int i, int j)
   {
      if (_isOnFav()) {
         _onChatLPImpl(_appState.favPosts, i, j, cts.favIdx);
      } else {
         _onChatLPImpl(_appState.ownPosts, i, j, cts.ownIdx);
      }

      setState(() { });
   }

   Future<void> _sendAppMsg(String payload, int isChat) async
   {
      final bool isEmpty = _appState.appMsgQueue.isEmpty;
      AppMsgQueueElem tmp = AppMsgQueueElem(
         rowid: -1,
         isChat: isChat,
         payload: payload,
         sent: false
      );

      _appState.appMsgQueue.add(tmp);

      tmp.rowid = await _appState.persistency.insertOutChatMsg(isChat, payload);

      if (isEmpty) {
         assert(!_appState.appMsgQueue.first.sent);
         _appState.appMsgQueue.first.sent = true;
         print(_appState.appMsgQueue.first.payload);
         channel.sink.add(_appState.appMsgQueue.first.payload);
      }
   }

   void _sendOfflineChatMsgs()
   {
      if (_appState.appMsgQueue.isNotEmpty) {
         assert(!_appState.appMsgQueue.first.sent);
         _appState.appMsgQueue.first.sent = true;
         channel.sink.add(_appState.appMsgQueue.first.payload);
      }
   }

   void _toggleLPChatMsgs(int k, bool isTap, int i)
   {
      assert(_posts[i] != null);
      assert(_chats[i] != null);

      if (isTap && _lpChatMsgs[i].isEmpty)
         return;

      final Coord tmp = Coord(
         post: _posts[i],
         chat: _chats[i],
         msgIdx: k
      );

      handleLPChats(_lpChatMsgs[i],
                    toggleLPChatMsg(_chats[i].msgs[k]),
                    tmp, compPeerAndChatIdx);

      setState((){});
   }

   Future<void> _onSendChatImpl(
      int postId,
      String peer,
      ChatItem ci,
   ) async {
      try {
	 if (ci.msg.isEmpty)
	    return;

	 final int rowid = 
	    await _appState.setChatMessage(postId, peer, ci, _isOnFav());

         // At a certain point in the future, I want to stop sending
         // the user avatar on every message and deduced it from the
         // user id instead.
         var msgMap =
         { 'cmd': 'message'
         , 'type': 'chat'
         , 'is_redirected': ci.isRedirected
         , 'to': peer
         , 'msg': ci.msg
         , 'refers_to': ci.refersTo
         , 'post_id': postId
         , 'nick': _appState.cfg.nick
         , 'id': rowid
         , 'avatar': emailToGravatarHash(_appState.cfg.email)
         };

         final String payload = jsonEncode(msgMap);
         await _sendAppMsg(payload, 1);

      } catch(e) {
         print(e);
      }
   }

   Future<void> _onServerAck(Map<String, dynamic> ack) async
   {
      try {
         assert(_appState.appMsgQueue.first.sent);
         assert(_appState.appMsgQueue.isNotEmpty);

         final String res = ack['result'];

         await _appState.persistency.deleteOutChatMsg(_appState.appMsgQueue.first.rowid);

         final bool isChat = _appState.appMsgQueue.first.isChat == 1;
         _appState.appMsgQueue.removeFirst();

         if (res == 'ok' && isChat) {
            await _onChatAck(ack['from'], ack['post_id'], <int>[ack['ack_id']], 1);
            setState(() { });
         }

         if (_appState.appMsgQueue.isNotEmpty) {
            assert(!_appState.appMsgQueue.first.sent);
            _appState.appMsgQueue.first.sent = true;
            channel.sink.add(_appState.appMsgQueue.first.payload);
         }
      } catch (e) {
         print(e);
      }
   }

   Future<void> _onChat(
      final Map<String, dynamic> ack,
      final String peer,
      final int postId,
      int isRedirected,
   ) async {
      final String to = ack['to'];
      if (to != _appState.cfg.appId) {
         print("Server bug caught. Please report.");
         return;
      }

      final String msg = ack['msg'];
      final String nick = ack['nick'];
      final String avatar = ack['avatar'] ?? '';
      final int refersTo = ack['refers_to'];
      final int peerRowid = ack['id'];

      final int favIdx = _appState.favPosts.indexWhere((e) {
         return e.id == postId;
      });

      List<Post> posts;
      if (favIdx != -1)
         posts = _appState.favPosts;
      else
         posts = _appState.ownPosts;

      await _onChatImpl(
         to,
         postId,
         msg,
         peer,
         nick,
         avatar,
         posts,
         isRedirected,
         refersTo,
         peerRowid,
      );
   }

   Future<void> _onChatImpl(
      String to,
      int postId,
      String msg,
      String peer,
      String nick,
      String avatar,
      List<Post> posts,
      int isRedirected,
      int refersTo,
      int peerRowid,
   ) async {
      final int i = posts.indexWhere((e) { return e.id == postId;});
      if (i == -1) {
         print('Ignoring message to postId $postId.');
         return;
      }

      final int j = posts[i].getChatHistIdxOrCreate(peer, nick, avatar);
      final int now = DateTime.now().millisecondsSinceEpoch;

      final ChatItem ci = ChatItem(
         isRedirected: isRedirected,
         msg: msg,
         date: now,
         refersTo: refersTo,
         peerRowid: peerRowid,
      );

      posts[i].chats[j].addChatItem(ci);
      if (avatar.isNotEmpty)
         posts[i].chats[j].avatar = avatar;

      // If we are in the screen having chat with the user we can ack
      // it with chat_ack_read and skip chat_ack_received.
      final bool isOnOwnPost = _posts[cts.ownIdx] != null && _posts[cts.ownIdx].id == postId; 
      final bool isOnFavPost = _posts[cts.favIdx] != null && _posts[cts.favIdx].id == postId; 

      final bool isOnOwnChat = _chats[cts.ownIdx] != null && _chats[cts.ownIdx].peer == peer; 
      final bool isOnFavChat = _chats[cts.favIdx] != null && _chats[cts.favIdx].peer == peer; 

      ++posts[i].chats[j].nUnreadMsgs;

      String ack;
      if ((isOnOwnPost && isOnOwnChat) || (isOnFavPost && isOnFavChat)) {
         // We are in the chat screen with the peer.
         ack = 'chat_ack_read';

	 final int k = isOnOwnPost ? cts.ownIdx : cts.favIdx;

         // We are not currently showing the jump down button and can
         // animate to the bottom.
         if (!_showChatJumpDownButtons[k]) {
            setState(()
            {
               posts[i].chats[j].nUnreadMsgs = 0;
               SchedulerBinding.instance.addPostFrameCallback((_)
               {
                  _chatScrollCtrl[k].animateTo(
                     _chatScrollCtrl[k].position.maxScrollExtent,
                     duration: const Duration(milliseconds: 300),
                     curve: Curves.easeOut,
                  );
               });
            });
         }

      } else {
         ack = 'chat_ack_received';
         final int n = posts[i].chats[j].nUnreadMsgs;
         posts[i].chats[j].divisorUnreadMsgs = n;
         final int l = posts[i].chats[j].chatLength;
         posts[i].chats[j].divisorUnreadMsgsIdx = l - n;
      }

      final ChatMetadata chat = posts[i].chats[j];

      posts[i].chats.sort(compChats);
      posts.sort(compPosts);

      var msgMap =
      { 'cmd': 'message'
      , 'type': ack
      , 'to': peer
      , 'post_id': postId
      , 'id': -1
      , 'ack_ids': <int>[peerRowid]
      };

      // Generating the payload before the async operation to avoid
      // problems.
      final String payload = jsonEncode(msgMap);
      await _appState.persistency.insertChatOnPost3(postId, chat, peer, ci);
      await _sendAppMsg(payload, 0);
   }

   void _onPresence(Map<String, dynamic> ack)
   {
      final String peer = ack['from'];
      final int postId = ack['post_id'];

      // We have to perform the following action
      //
      // 1. Search the chat from user from
      // 2. Set the presence timestamp.
      // 3. Call setState.
      //
      // We do not know if the post belongs to the sender or receiver, so
      // we have to try both.

      final bool b = markPresence(_appState.favPosts, peer, postId);
      if (!b)
         markPresence(_appState.ownPosts, peer, postId);

      // A timer that is launched after presence arrives. It is used
      // to call setState so that presence e.g. typing messages are
      // not shown after some time
      Timer(
         Duration(milliseconds: cts.presenceInterval),
         () { setState((){}); },
      );

      setState((){});
   }

   Future<void> _onChatAck(
      String from,
      int postId,
      List<int> rowids,
      int status,
   ) async {
      _appState.setChatAckStatus(from, postId, rowids, status);
   }

   Future<void> _onMessage(Map<String, dynamic> ack) async
   {
      final String from = ack['from'];
      final String type = ack['type'];
      final int postId = ack['post_id'];

      if (type == 'chat') {
         await _onChat(ack, from, postId, ack['is_redirected']);
      } else if (type == 'server_ack') {
         await _onServerAck(ack);
      } else if (type == 'chat_ack_received') {
         final List<int> rowids = decodeList(0, 0, ack['ack_ids']);
         await _onChatAck(from, postId, rowids, 2);
      } else if (type == 'chat_ack_read') {
         final List<int> rowids = decodeList(0, 0, ack['ack_ids']);
         await _onChatAck(from, postId, rowids, 3);
      }

      setState((){});
   }

   Future<void> _onRegisterAck(
      Map<String, dynamic> ack,
      final String msg,
   ) async {
      final String res = ack["result"];
      if (res == 'fail') {
         print("register_ack: fail.");
         return;
      }

      String id = ack["id"];
      String pwd = ack["password"];

      if (id == null || pwd == null)
         return;

      await _appState.setCredentials(id, pwd);

      // Retrieves some posts for the newly registered user.
      _subscribeToChannels(0);
   }

   void _leaveNewPostScreen()
   {
      setState((){
         _newPostPressed = false;
         _botBarIdx = 0;
         _posts[cts.ownIdx] = null;
      });
   }

   Future<void> _onFilenamesAck(Map<String, dynamic> ack) async
   {
      try {
         final String res = ack["result"];
         if (res == 'fail') {
            _newPostErrorCode = 0;
         } else if (_filenamesTimer.isActive) {
            _filenamesTimer.cancel();

            List<dynamic> names = ack["names"];
            List<String> fnames = List.generate(names.length, (i) {
               return names[i];
            });

            _newPostErrorCode = await _uploadImgs(fnames);

            if (_newPostErrorCode == -1)
               await _sendPost();
         }
      } catch (e) {
         print(e);
      }

      _leaveNewPostScreen();
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
      _subscribeToChannels(_appState.cfg.lastPostId);

      // Sends any chat messages that may have been written while
      // the app were offline.
      _sendOfflineChatMsgs();

      // The same for posts.
      sendOfflinePosts();
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
      // When we are receiving new posts here as a result of the user
      // clicking the search buttom, we have to clear all old posts before
      // showing the new posts to the user.
      final bool showPosts = _appState.cfg.lastPostId == 0 || _appState.posts.isEmpty;
      if (_appState.cfg.lastPostId == 0)
	 await _appState.clearPosts();

      for (var item in ack['items']) {
         try {
            Post post = Post.fromJson(item, g.param.rangeDivs.length);
            post.status = 1;

            // Just in case the server sends us posts out of order I
            // will check. It should however be considered a server
            // error.
            if (post.id > _appState.cfg.lastPostId)
               _appState.cfg.lastPostId = post.id;

            if (post.from == _appState.cfg.appId)
               continue;

	    await _appState.persistency.insertPost(post, ConflictAlgorithm.ignore);

            _appState.posts.add(post);
            ++_nNewPosts;
         } catch (e) {
            print("Error: Invalid post detected.");
         }
      }

      await _appState.persistency.updateLastPostId(_appState.cfg.lastPostId);

      if (showPosts) {
         final int idx = _makeLastSeenPostId();
	 if (idx != -1)
	    await _appState.setLastPostId(_appState.posts[idx].id);
      }

      setState(() { });
   }

   Future<void>
   _onPublishAck(Map<String, dynamic> ack) async
   {
      final String res = ack['result'];
      if (res == 'ok') {
         await _handlePublishAck(ack['id'], 1000 * ack['date']);
      } else {
         await _handlePublishAck(-1, -1);
      }
   }

   Future<void> _onWSDataImpl() async
   {
      while (_wsMsgQueue.isNotEmpty) {
         var msg = _wsMsgQueue.removeFirst();

         Map<String, dynamic> ack = jsonDecode(msg);
         final String cmd = ack["cmd"];
         if (cmd == "presence") {
            _onPresence(ack);
         } else if (cmd == "message") {
            await _onMessage(ack);
         } else if (cmd == "login_ack") {
            _onLoginAck(ack, msg);
         } else if (cmd == "subscribe_ack") {
            _onSubscribeAck(ack);
         } else if (cmd == "post") {
            await _onPost(ack);
         } else if (cmd == "publish_ack") {
            await _onPublishAck(ack);
         } else if (cmd == "delete_ack") {
            await _onServerAck(ack);
         } else if (cmd == "register_ack") {
            await _onRegisterAck(ack, msg);
         } else if (cmd == "filenames_ack") {
            await _onFilenamesAck(ack);
         } else {
            print('Unhandled message received from the server:\n$msg.');
         }
      }
   }

   Future<void> _onWSData(msg) async
   {
      print(msg);
      final bool isEmpty = _wsMsgQueue.isEmpty;
      _wsMsgQueue.add(msg);
      if (isEmpty)
         await _onWSDataImpl();
   }

   void _onWSError(error)
   {
      print("Error: _onWSError $error");
      _lastDisconnect = DateTime.now().millisecondsSinceEpoch;
   }

   void _onWSDone()
   {
      print("Communication closed by peer.");
      _lastDisconnect = DateTime.now().millisecondsSinceEpoch;
   }

   void _onOkDialAfterSendFilters()
   {
      _tabCtrl.index = 1;
      _botBarIdx = 0;
      setState(() { });
   }

   void _showSimpleDialog(
      BuildContext ctx,
      Function onOk,
      String title,
      Widget content)
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

            return AlertDialog(
               title: Text(title),
               content: content,
               actions: actions,
            );
         },
      );
   }

  /* The variable i can assume the following values
   * 0: Only leaves the screen.
   * 1: Retrieve all posts from the server. (I think we do not need this
   *    option).
   * 2: Notifications: When the user presses search we will zero the
   *    lastPostId and search.
   */
   Future<void>
   _onSendFilters(BuildContext ctx, int i) async
   {
      _newSearchPressed = false;

      if (i == 0) {
         setState(() { });
         return;
      }

      //final int lastPostId = i == 1 ? 0 : _appState.cfg.lastPostId;
      //final int lastPostId = _appState.cfg.lastPostId;

      // I changed my mind in 8.12.2019 and decided it is less confusing to
      // the user if we always search for all posts not only for those that
      // have a more recent post id than what is stored in the app. For
      // that we rely on the fact that
      //
      // 1. When the user moves a post to the chats screen it will not be
      //    added twice.
      // 2. Old posts will be cleared when we receive the answer to this
      //    request.

      _appState.cfg.lastPostId = 0;
      _nNewPosts = 0;

      await _appState.persistency.updateLastPostId(0);

      _subscribeToChannels(0);

      _showSimpleDialog(
         ctx,
         _onOkDialAfterSendFilters,
         g.param.dialogTitles[3],
         Text(g.param.dialogBodies[3]),
      );
   }

   void _subscribeToChannels(int lastPostId)
   {
      List<List<int>> channels = List<List<int>>();

      // An empty channels list means we do not want any filter for
      // that menu item.
      for (Tree item in _appState.trees)
         channels.add(readHashCodes(item.root.first, item.filterDepth));

      assert(channels.length == 2);

      var subCmd =
      { 'cmd': 'subscribe'
      , 'last_post_id': lastPostId
      , 'filters': channels[0]
      , 'channels': channels[1]
      , 'any_of_features': _appState.cfg.anyOfFeatures
      , 'ranges': convertToValues(_appState.cfg.ranges)
      };

      final String payload = jsonEncode(subCmd);
      print(payload);
      channel.sink.add(payload);
   }

   // Called when the main tab changes.
   void _tabCtrlChangeHandler()
   {
      // This function is meant to change the tab widgets when we
      // switch tab. This is needed to show the number of unread
      // messages.
      setState(() { print('Tab changed');});
   }

   int _getNUnreadFavChats()
   {
      int i = 0;
      for (Post post in _appState.favPosts)
         i += post.getNumberOfUnreadChats();

      return i;
   }

   int _getNUnreadOwnChats()
   {
      int i = 0;
      for (Post post in _appState.ownPosts)
         i += post.getNumberOfUnreadChats();

      return i;
   }

   bool _onChatsBackPressed(int i)
   {
      if (_hasLPChatMsgs(i)) {
         _onBackFromChatMsgRedirect(i);
         return false;
      }

      if (_hasLPChats(i)) {
         _unmarkLPChats(i);
         setState(() { });
         return false;
      }

      if (_posts[i] != null) {
         _posts[i] = null;
         setState(() { });
         return false;
      }

      _tabCtrl.animateTo(1, duration: Duration(seconds: 1));
      setState(() { });
      return false;
   }

   bool _hasLPChats(int i)
   {
      return _lpChats[i].isNotEmpty;
   }

   bool _hasLPChatMsgs(int i)
   {
      return _lpChatMsgs[i].isNotEmpty;
   }

   void _unmarkLPChats(int i)
   {
      _lpChats[i].forEach((e){toggleLPChat(e.chat);});
      _lpChats[i].clear();
   }

   void _onAppBarVertPressed(ConfigActions ca)
   {
      if (ca == ConfigActions.ChangeNick) {
         setState(() {
            _goToRegScreen = true;
         });
      }

      if (ca == ConfigActions.Notifications) {
         setState(() {
            _goToNtfScreen = true;
         });
      }
   }

   void _onSearchPressed()
   {
      setState(() {
         _newSearchPressed = true;
         _appState.trees[0].restoreMenuStack();
         _appState.trees[1].restoreMenuStack();
         // If you changes this, also change the index _onWillPopMenu
         // will be called with.
         _botBarIdx = 1;
      });
   }

   Future<void> _pinChats(int i) async
   {
      assert(_isOnFav() || _isOnOwn());

      if (_lpChats[i].isEmpty)
         return;

      _lpChats[i].forEach((e){toggleChatPinDate(e.chat);});
      _lpChats[i].forEach((e){toggleLPChat(e.chat);});
      _lpChats[i].first.post.chats.sort(compChats);
      _lpChats[i].clear();

      // TODO: Sort _appState.favPosts and _appState.ownPosts. Beaware that the array
      // Coord many have entries from chats from different posts and
      // they may be out of order. So care should be taken to not sort
      // the arrays multiple times.

      setState(() { });
   }

   Future<void> _removeLPChats(int i) async
   {
      assert(_isOnFav() || _isOnOwn());

      if (_lpChats[i].isEmpty)
         return;

      // FIXME: For _fav chats we can directly delete the post since
      // it will only have one chat element.

      _lpChats[i].forEach((e) async {removeLpChat(e, _appState.persistency);});

      if (_isOnFav()) {
         for (Post o in _appState.favPosts)
            if (o.chats.isEmpty)
	       await _appState.persistency.delPostWithId(o.id);

         _appState.favPosts.removeWhere((e) { return e.chats.isEmpty; });
      } else {
         _appState.ownPosts.sort(compPosts);
      }

      _lpChats[i].clear();
      setState(() { });
   }

   void _deleteChatDialog(BuildContext ctx, int i)
   {
      showDialog(
         context: ctx,
         builder: (BuildContext ctx)
         {
            final FlatButton ok = FlatButton(
	       child: Text(g.param.devChatOkStr,
		  style: TextStyle(color: stl.colorScheme.secondary),
	       ),
	       onPressed: () async
	       {
		  await _removeLPChats(i);
		  Navigator.of(ctx).pop();
	       },
	    );

            final FlatButton cancel = FlatButton(
               child: Text(g.param.delChatCancelStr,
                  style: TextStyle(color: stl.colorScheme.secondary),
               ),
               onPressed: () { Navigator.of(ctx).pop(); });

            List<FlatButton> actions = List<FlatButton>(2);
            actions[0] = cancel;
            actions[1] = ok;

            Text text = Text(g.param.delOwnChatTitleStr,
               style: TextStyle(color: Colors.black));

            if (_isOnFav()) {
               text = Text(
                  g.param.delFavChatTitleStr,
                  style: TextStyle(color: Colors.black));
            }

            return AlertDialog(
                  title: text,
                  content: Text(""),
                  actions: actions);
         },
      );
   }

   void _onBackFromChatMsgRedirect(int i)
   {
      assert(_lpChatMsgs[i].isNotEmpty);

      if (_lpChats[i].isEmpty) {
         // All items int _lpChatMsgs should have the same post id and
         // peer so we can use the first.
         _posts[i] = _lpChatMsgs[i].first.post;
         _chats[i] = _lpChatMsgs[i].first.chat;
      } else {
         _unmarkLPChats(i);
      }

      setState(() { });
   }

   Future<void> _onRegisterContinue(BuildContext ctx) async
   {
      try {
         if (_txtCtrl.text.length < cts.nickMinLength) {
            _showSimpleDialog(
               ctx,
               (){},
               g.param.onEmptyNickTitle,
               Text(g.param.onEmptyNickContent),
            );
            return;
         }

         if (_txtCtrl2.text.isNotEmpty) {
            _appState.cfg.email = _txtCtrl2.text;
            await _appState.persistency.updateEmail(_appState.cfg.email);
         }

         _appState.cfg.nick = _txtCtrl.text;
         await _appState.persistency.updateNick(_appState.cfg.nick);

         setState(()
         {
            _txtCtrl2.clear();
            _txtCtrl.clear();
            _goToRegScreen = false;
         });

      } catch (e) {
         print(e);
      }
   }

   Future<void> _onChangeNtf(int i, bool v) async
   {
      try {
         if (i == 0)
            _appState.cfg.notifications.chat = v;

         if (i == 1)
            _appState.cfg.notifications.post = v;

         final String str = jsonEncode(_appState.cfg.notifications.toJson());
         await _appState.persistency.updateNotifications(str);

         if (i == -1)
            _goToNtfScreen = false;

         setState(() { });
      } catch (e) {
         print(e);
      }
   }

   void _onExDetails(int i, int j)
   {
      if (j == -1) {
         _posts[cts.ownIdx].description = _txtCtrl.text;
         _txtCtrl.clear();
         _botBarIdx = 3;
         setState(() { });
         return;
      }

      _posts[cts.ownIdx].exDetails[i] = 1 << j;

      setState(() { });
   }

   void _onNewPostInDetail(int i, int j)
   {
      _posts[cts.ownIdx].inDetails[i] ^= 1 << j;
      setState(() { });
   }

   Future<void> _onFilterDetail(int i) async
   {
      _appState.cfg.anyOfFeatures ^= 1 << i;

      final String str = _appState.cfg.anyOfFeatures.toString();
      await _appState.persistency.updateAnyOfFeatures(str);
      setState(() { });
   }

   void _onNewPostSetTreeCode(List<int> code, int i)
   {
      if (code.isEmpty)
	 return;

      _posts[cts.ownIdx].channel[i].first = code;

      setState(() {});
   }

   void _onSetExDetail(int detailIdx, int index)
   {
      setState(() {_posts[cts.ownIdx].exDetails[detailIdx] = index;});
   }

   void _onSetInDetail(int detailIdx, int state)
   {
      setState(() { _posts[cts.ownIdx].inDetails[detailIdx] = state; });
   }

   // Widget factories.
   //
   // i: screen index.
   //
   Widget _makeChatScreen(BuildContext ctx, int i)
   {
      return makeChatScreen(
	 ctx,
	 _chats[i],
	 _txtCtrl,
	 _chatScrollCtrl[i],
	 _lpChatMsgs[i].length,
	 _chatFocusNodes[i],
	 makeTreeItemStr(_appState.trees[0].root.first, _posts[i].channel[1][0]),
	 _dragedIdxs[i],
	 _showChatJumpDownButtons[i],
	 _isOnFavChat() ? _posts[i].avatar : _chats[i].avatar,
	 _appState.cfg.nick,
	 () { _onPopChat(i);},
	 () {_onSendChat(i);},
	 (int a, bool b) {_toggleLPChatMsgs(a, b, i);},
	 () {_onFwdChatMsg(i);},
	 (var a, var b, var d) {_onDragChatMsg(a, b, d, i);},
	 (var a) {_onChatMsgReply(a, i);},
	 _onChatAttachment,
	 () {_onCancelFwdLpChat(i);},
	 () {_onChatJumpDown(i);},
	 (var s) {_onWritingChat(s, i);},
      );
   }

   Widget _makeNewPostScreenWdgs(BuildContext ctx)
   {
      return makeNewPostScreenWdgs(
	 ctx: ctx,
	 post: _posts[cts.ownIdx],
	 trees: _appState.trees,
	 txtCtrl: _txtCtrl,
	 navBar: _botBarIdx,
	 exDetailsRootNode: _appState.exDetailsRoot,
	 inDetailsRootNode: _appState.inDetailsRoot,
	 imgFiles: _imgFiles,
	 filenamesTimerActive: _filenamesTimer.isActive,
	 onExDetail: _onExDetails,
	 onPostLeafPressed: (int i) {_onPostLeafPressed(i, cts.ownIdx);},
	 onPostNodePressed: (int i) {_onPostNodePressed(i, cts.ownIdx);},
	 onInDetail: _onNewPostInDetail,
	 onRangeValueChanged: _onRangeValueChanged,
	 onAddPhoto: _onAddPhoto,
	 onPublishPost: (var a) { _onSendNewPost(a, 1); },
	 onRemovePost: (var a) { _onSendNewPost(a, 0); },
      );
   }

   Widget _makeNewPostScreenWdgs2(BuildContext ctx)
   {
      return makeNewPostScreenWdgs2(
	 ctx: ctx,
	 filenamesTimerActive: _filenamesTimer.isActive,
	 locationTree: _appState.trees[0],
	 productTree: _appState.trees[1],
	 exDetailsRootNode: _appState.exDetailsRoot,
	 inDetailsRootNode: _appState.inDetailsRoot,
	 post: _posts[cts.ownIdx],
	 txtCtrl: _txtCtrl,
	 onSetLocTreeCode: _onNewPostSetTreeCode,
	 onSetExDetail: _onSetExDetail,
	 onSetInDetail: _onSetInDetail,
	 imgFiles: _imgFiles,
	 onAddPhoto: _onAddPhoto,
	 onPublishPost: (var a) { _onSendNewPost(a, 1); },
	 onRemovePost: (var a) { _onSendNewPost(a, 0); },
      );
   }

   Widget _makeSearchScreenWdg(BuildContext ctx)
   {
      // Below we use txt.exDetails[0][0], because the filter is
      // common to all products.
      return makeSearchScreenWdg(
	 filter: _appState.cfg.anyOfFeatures,
	 screen: _botBarIdx,
	 exDetailsFilterNodes: _appState.exDetailsRoot.children[0].children[0],
	 trees: _appState.trees,
	 ranges: _appState.cfg.ranges,
	 onSendFilters: (int i) {_onSendFilters(ctx, i);},
	 onFilterDetail: _onFilterDetail,
	 onFilterNodePressed: _onFilterNodePressed,
	 onFilterLeafNodePressed: _onFilterLeafNodePressed,
	 onRangeChanged: _onRangeChanged,
      );
   }

   Widget _makeNewPostLv()
   {
      return makeNewPostLv(
	nNewPosts: _nNewPosts,
	exDetailsRootNode: _appState.exDetailsRoot,
	inDetailsRootNode: _appState.inDetailsRoot,
	posts: _appState.posts,
	trees: _appState.trees,
	onExpandImg: (int i, int j) {_onExpandImg(i, j, cts.searchIdx);},
	onAddPostToFavorite: (var a, int j) {_alertUserOnPressed(a, j, 1);},
	onDelPost: (var a, int j) {_alertUserOnPressed(a, j, 0);},
	onSharePost: (var a, int j) {_alertUserOnPressed(a, j, 3);},
	onReportPost: (var a, int j) {_alertUserOnPressed(a, j, 2);},
	onNext: _onShowNewPosts,
      );
   }

   List<Widget> _makeFaButtons(int i)
   {
      return makeFaButtons(
	 nOwnPosts: _appState.ownPosts.length,
	 newSearchPressed: _newSearchPressed,
	 lpChats: _lpChats,
	 lpChatMsgs: _lpChatMsgs,
	 onNewPost: _newPostPressed ? null : _onNewPost,
	 onFwdSendButton: _onFwdSendButton,
	 onSearch: _onSearchPressed,
      );
   }

   BottomNavigationBar _makeBotNavBar(int screen)
   {
      return makeBotNavBar(
	 botBarIndex: _botBarIdx,
	 newPostPressed: _newPostPressed,
	 newSearchPressed: _newSearchPressed,
	 screen: screen,
	 onNewPostBotBarTapped: _onNewPostBotBarTapped,
	 onSearchBotBarPressed: _onBotBarTapped,
      );
   }

   Widget _makeChatTab(BuildContext ctx, int i)
   {
      List<Post> posts = _appState.ownPosts;
      if (i == cts.favIdx)
	 posts = _appState.favPosts;

      return makeChatTab(
	 isFwdChatMsgs: _lpChatMsgs[i].isNotEmpty,
	 screen: i,
	 exDetailsRootNode: _appState.exDetailsRoot,
	 inDetailsRootNode: _appState.inDetailsRoot,
	 posts: posts,
	 trees: _appState.trees,
	 onPressed: _onChatPressed,
	 onLongPressed: _onChatLP,
	 onDelPost1: (int i) { _removePostDialog(ctx, i);},
	 onPinPost1: _onPinPost,
	 onUserInfoPressed: _onUserInfoPressed,
	 onExpandImg1: (int i, int j) {_onExpandImg(i, j, i);},
	 onSharePost: (int i) {_onClickOnPost(i, 1);},
	 onPost: _onNewPost,
      );
   }

   List<Widget> _makeTabActions(BuildContext ctx, int i)
   {
      return makeTabActions(
         screen: i,
	 newPostPressed: _newPostPressed,
	 hasLPChats: _hasLPChats(i),
	 hasLPChatMsgs: _hasLPChatMsgs(i),
	 deleteChatDialog: () {_deleteChatDialog(ctx, i);},
	 pinChats: () {_pinChats(i);},
	 onClearPostsDialog: () { _clearPostsDialog(ctx); },
      );
   }

   List<Widget> _makeGlobalActionsApp(BuildContext ctx, int i)
   {
      // In the web version we do not need to hide anything if there are long
      // pressed chats.
      return makeGlobalActionsApp(
	 hasLPChats: _hasLPChats(i),
	 hasLPChatMsgs: _hasLPChatMsgs(i),
	 onSearchPressed: _onSearchPressed,
	 onNewPost: _onNewPost,
	 onAppBarVertPressed: _onAppBarVertPressed,
      );
   }

   List<Widget> _makeGlobalActionsWeb(BuildContext ctx)
   {
      // In the web version we do not need to hide anything if there are long
      // pressed chats.
      return makeGlobalActionsWeb(
	 onSearchPressed: _onSearchPressed,
	 onNewPost: _onNewPost,
	 onAppBarVertPressed: _onAppBarVertPressed,
      );
   }


   Widget _makeAppBarLeading(int i)
   {
      return makeAppBarLeading(
	 hasLpChats: _hasLPChats(i),
	 hasLpChatMsgs: _hasLPChatMsgs(i),
	 newPostPressed: _newPostPressed,
	 newSearchPressed: _newSearchPressed,
	 screen: i,
	 onWillLeaveSearch: () { return _onWillPopMenu(_appState.trees, 1);},
	 onWillLeaveNewPost: () { return _onWillPopMenu(_appState.trees, 0); },
	 onBackFromChatMsgRedirect: () { _onBackFromChatMsgRedirect(i);},
      );
   }

   Widget _makeAppBarTitleWdg(int i, Widget defaultWdg)
   {
      return makeAppBarWdg(
	 hasLpChatMsgs: _hasLPChatMsgs(i),
	 newPostPressed: _newPostPressed,
	 newSearchPressed: _newSearchPressed,
	 botBarIndex: _botBarIdx,
	 screen: i,
	 trees: _appState.trees,
	 defaultWdg: defaultWdg,
      );
   }

   List<int> _newMsgsCounters()
   {
      List<int> ret = List<int>(g.param.tabNames.length);
      ret[cts.ownIdx] = _getNUnreadOwnChats();
      ret[cts.searchIdx] = _nNewPosts;
      ret[cts.favIdx] = _getNUnreadFavChats();
      return ret;
   }

   List<Widget> _makeAppBodies(BuildContext ctx)
   {
      List<Widget> ret = List<Widget>(g.param.tabNames.length);

      if (_newPostPressed) {
	 //ret[cts.ownIdx] = _makeNewPostScreenWdgs(ctx);
	 ret[cts.ownIdx] = _makeNewPostScreenWdgs2(ctx);
      } else {
	 ret[cts.ownIdx] = _makeChatTab(ctx, cts.ownIdx);
      }

      if (_newSearchPressed) {
	 ret[cts.searchIdx] = _makeSearchScreenWdg(ctx);
      } else {
	 ret[cts.searchIdx] = _makeNewPostLv();
      }

      ret[cts.favIdx] = _makeChatTab(ctx, cts.favIdx);

      return ret;
   }

   List<OnPressedFn7> _makeOnWillPop()
   {
      List<OnPressedFn7> ret = List<OnPressedFn7>(g.param.tabNames.length);

      ret[cts.ownIdx] = ()
      {
	 if (_newPostPressed)
	    return _onWillPopMenu(_appState.trees, cts.ownIdx);

	 return _onChatsBackPressed(cts.ownIdx);
      };

      ret[cts.searchIdx] = ()
      {
	 print('aa');
	 if (_newSearchPressed)
	    return _onWillPopMenu(_appState.trees, cts.searchIdx);

	 setState((){});
	 return true;
      };

      ret[cts.favIdx] = () {return _onChatsBackPressed(cts.favIdx);};

      return ret;
   }

   @override
   Widget build(BuildContext ctx)
   {
      final bool mustWait =
         _appState.trees.isEmpty    ||
         (_appState.exDetailsRoot == null) ||
         (_appState.inDetailsRoot == null) ||
         (g.param == null);

      if (mustWait)
         return makeWaitMenuScreen();

      Locale locale = Localizations.localeOf(ctx);
      g.param.setLang(locale.languageCode);

      if (_goToRegScreen) {
         return makeRegisterScreen(
            _txtCtrl2,
            _txtCtrl,
            (){_onRegisterContinue(ctx);},
            g.param.changeNickAppBarTitle,
            _appState.cfg.email,
            _appState.cfg.nick,
	    makeWidth(ctx),
         );
      }

      if (_goToNtfScreen) {
         return makeNtfScreen(
	    ctx,
            _onChangeNtf,
            g.param.changeNtfAppBarTitle,
            _appState.cfg.notifications,
            g.param.ntfTitleDesc,
         );
      }

      if (_onTabSwitch()) {
         _cleanUpLpOnSwitchTab(cts.ownIdx);
         _cleanUpLpOnSwitchTab(cts.favIdx);
	 _botBarIdx = 0;
      }

      if (_newPostErrorCode != -1) {
         SchedulerBinding.instance.addPostFrameCallback((_)
         {
            String title = g.param.newPostErrorTitles[_newPostErrorCode];
            String body = g.param.newPostErrorBodies[_newPostErrorCode];
            _showSimpleDialog(ctx, (){},
               title,
               Text(body)
            );
            _newPostErrorCode = -1;
         });
      }

      final int screenIdx = _screenIdx();
      if (_expPostIdxs[screenIdx] != -1 && _expImgIdxs[screenIdx] != -1) {
         Post post;
         if (_isOnOwn())
            post = _appState.ownPosts[_expPostIdxs[screenIdx]];
         else if (_isOnSearch())
            post = _appState.posts[_expPostIdxs[screenIdx]];
         else if (_isOnFav())
            post = _appState.favPosts[_expPostIdxs[screenIdx]];
         else
            assert(false);

         return makeImgExpandScreen(
	    () { _onExpandImg(-1, -1, _screenIdx()); return false;},
	    post,
	 );
      }

      List<OnPressedFn7> onWillPops = _makeOnWillPop();
      List<Widget> fltButtons = _makeFaButtons(screenIdx);
      List<Widget> bodies = _makeAppBodies(ctx);
      BottomNavigationBar bottomNavBar = _makeBotNavBar(screenIdx);
      List<int> newMsgCounters = _newMsgsCounters();

      if (isWideScreen(ctx)) {
	 const double sep = 3.0;
	 Divider div = Divider(height: sep, thickness: sep, indent: 0.0, color: Colors.grey);

	 List<Widget> tabWdgs = makeTabWdgs(
	    ctx: ctx,
	    counters: newMsgCounters,
	    opacities: cts.newMsgsOpacitiesWeb,
	 );

	 Widget ownTopBar = AppBar(
	    actions: _makeTabActions(ctx, cts.ownIdx),
	    title: _makeAppBarTitleWdg(cts.ownIdx, tabWdgs[cts.ownIdx]),
	    leading: _makeAppBarLeading(cts.ownIdx),
	 );

	 Widget own;
	 if (_isOnOwnChat())
	    own = Column(children: <Widget>[div, Expanded(child: _makeChatScreen(ctx, cts.ownIdx)), div]);
	 else
	    own = Column(children: <Widget>[div, ownTopBar, Expanded(child: bodies[cts.ownIdx]), div]);

	 Widget searchTopBar = AppBar(
	    actions: _makeTabActions(ctx, cts.searchIdx),
	    title: _makeAppBarTitleWdg(cts.searchIdx, tabWdgs[cts.searchIdx]),
	    leading: _makeAppBarLeading(cts.searchIdx),
	 );

	 Widget search = Column(
	    children: <Widget>
	    [ div
	    , searchTopBar
	    , Expanded(child: bodies[cts.searchIdx])
	    , div
	    ]
	 );

	 Widget favTopBar = AppBar(
	    actions: _makeTabActions(ctx, cts.favIdx),
	    title: _makeAppBarTitleWdg(cts.favIdx, tabWdgs[cts.favIdx]),
	    leading: _makeAppBarLeading(cts.favIdx),
	 );

         Widget fav;
	 if (_isOnFavChat())
	    fav = Column(children: <Widget>[div, Expanded(child: _makeChatScreen(ctx, cts.favIdx)), div]);
	 else
	    fav = Column(children: <Widget>[div, favTopBar, Expanded(child: bodies[cts.favIdx]), div]);

	 VerticalDivider vdiv = VerticalDivider(width: sep, thickness: sep, indent: 0.0, color: Colors.grey);
	 Widget body = Row(children: <Widget>
	    [ vdiv
	    , Expanded(child: Stack(children: <Widget>[own, Positioned(bottom: 20.0, right: 20.0, child: fltButtons[cts.ownIdx])]))
	    , vdiv
	    , Expanded(child: Stack(children: <Widget>[search, Positioned(bottom: 20.0, right: 20.0, child: fltButtons[cts.searchIdx])]))
	    , vdiv
	    , Expanded(child: Stack(children: <Widget>[fav, Positioned(bottom: 20.0, right: 20.0, child: fltButtons[cts.favIdx])]))
	    , vdiv
	    ],
	 );

	 return makeWebScaffoldWdg(
	    body: body,
	    appBar: AppBar(
               title: Text(g.param.appName),
	       elevation: 0.0,
	       actions: _makeGlobalActionsWeb(ctx),
	    ),
	    onWillPopScope: () {print('Noop');},
	 );
      }

      if (_isOnFavChat() || _isOnOwnChat())
         return _makeChatScreen(ctx, screenIdx);

      List<Widget> actions = _makeTabActions(ctx, screenIdx);
      actions.addAll(_makeGlobalActionsApp(ctx, screenIdx));
      List<double> opacities = _getNewMsgsOpacities();

      return makeAppScaffoldWdg(
	 onWillPops: onWillPops[_tabCtrl.index],
	 bottomNavBar: bottomNavBar,
	 scrollCtrl: _scrollCtrl[_screenIdx()],
	 appBarTitle: _makeAppBarTitleWdg(screenIdx, Text(g.param.appName)),
	 appBarLeading: _makeAppBarLeading(screenIdx),
	 floatBut: fltButtons[_tabCtrl.index],
	 body: TabBarView(controller: _tabCtrl, children: bodies),
	 tabBar: makeTabBar(ctx, newMsgCounters, _tabCtrl, opacities, _hasLPChatMsgs(screenIdx)),
	 actions: actions,
      );
   }
}

