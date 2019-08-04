import 'dart:convert';
import 'dart:io' show File, FileMode, Directory;
import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:menu_chat/constants.dart';
import 'package:menu_chat/tree.dart';
import 'package:menu_chat/txt_pt.dart' as txt;
import 'package:menu_chat/sql.dart' as sql;
import 'package:menu_chat/globals.dart' as glob;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

String convertChatMsgTypeToString(int type)
{
   if (type == 2)
      return 'chat';

   if (type == 3)
      return 'chat_redirected';

   assert(false);
}

enum MsgType
{ fromPeer
, fromPeerFwd
, own
, ownFwd
}

class ChatItem {
   int type;

   String msg;
   int date;

   // A value different from -1 means this message refers to another
   // message.
   int refersTo;

   bool isLongPressed;

   ChatItem({this.type = 2,
             this.msg = '',
             this.date = 0,
             this.refersTo = -1,
             this.isLongPressed = false,
   });

   bool isRedirected()
   {
      return type == 1 || type == 3;
   }

   bool isFromThisApp()
   {
      return type == 2 || type == 3;
   }

   bool refersToOther()
   {
      return refersTo != -1;
   }

   ChatItem.fromJson(Map<String, dynamic> map)
   {
      type = map["this_app"];
      msg = map['msg'];
      date = map['date'];
      refersTo = map['refers_to'];
      isLongPressed = false;
   }

   Map<String, dynamic> toJson()
   {
      return
      {
         'this_app': type,
         'msg': msg,
         'date': date,
         'refers_to': refersTo,
      };
   }
}

class Chat {
   String peer;
   String nick;
   int date;
   int pinDate;
   int appAckReadEnd;
   int appAckReceivedEnd;
   int serverAckEnd;
   int chatLength;
   int nUnreadMsgs;
   ChatItem lastChatItem;

   bool isLongPressed;
   List<ChatItem> msgs;
   File _msgsFile;

   Chat({this.peer = '',
         this.nick = '',
         this.date = 0,
         this.pinDate = 0,
         this.appAckReadEnd = 0,
         this.appAckReceivedEnd = 0,
         this.serverAckEnd = 0,
         this.chatLength = 0,
         this.nUnreadMsgs = 0,
         this.lastChatItem,
         this.isLongPressed = false,
   });

   void addChatItem(ChatItem ci, int postId)
   {
      lastChatItem = ci;
      if (isLoaded()) {
         msgs.add(ci);
         chatLength = msgs.length;
      } else {
         ++chatLength;
      }

      persistChatMsg(ci, postId);
   }

   String getChatDisplayName()
   {
      if (nick.isEmpty)
         return '$peer';

      return '$nick';
   }

   String getChatAbbrevStr()
   {
      if (nick.isEmpty) { // For safety
         if (peer.length < 2)
            return peer;

         return peer.substring(0, 2);
      }
               
      if (nick.length < 2)
         return nick;

      return nick.substring(0, 2);
   }

   String makeFullPath(final String prefix, final int postId)
   {
      return '${glob.docDir}/${prefix}_${postId}_${peer}.txt';
   }

   bool isLoaded()
   {
      return msgs != null;
   }

   bool _isFileOpen()
   {
      return _msgsFile != null;
   }

   void _openFile(int postId)
   {
      _msgsFile = File(makeFullPath(txt.chatFilePrefix, postId));
   }

   void loadMsgs(final int postId)
   {
      try {
         if (!_isFileOpen()) {
            _openFile(postId);
         }

         msgs = List<ChatItem>(); 

         List<String> lines = _msgsFile.readAsLinesSync();
         msgs = List<ChatItem>.generate(lines.length, (int i)
            { return ChatItem.fromJson(jsonDecode(lines[i])); });
      } catch (e) {
         print(e);
      }
   }

   void persistChatMsg(ChatItem ci, final int postId)
   {
      if (!_isFileOpen())
         _openFile(postId);

      String content = jsonEncode(ci);
      content += '\n';
      _msgsFile.writeAsStringSync(content, mode: FileMode.append);
   }
}

/* Chat sorting criteria
 *
 * (applies to chats belonging to the same post)
 *
 * 1. A pined chat alwas wins, even if it contains no messages. The
 *    need to sort chats that contain no messages however won't
 *    happen.  If _favPosts there is only one chat, and in _ownPosts
 *    they will always contain messages.
 * 2. If two chats are pined, the one with the most recent date wins.
 *    The date to be used is the date of the last chat message. Again,
 *    two or more chats with no message won't happen as said above.
 *
 * FIXME: Chats may contain empty messages if they are a reply to
 *        other messages. The function bellow has to be adapted to
 *        such cases.
 */
int CompChats(final Chat lhs, final Chat rhs)
{
   if (lhs.pinDate != 0 && rhs.pinDate != 0)
      return lhs.pinDate > rhs.pinDate ? -1
           : lhs.pinDate < rhs.pinDate ? 1 : 0;

   if (lhs.pinDate != 0)
      return -1;

   if (rhs.pinDate != 0)
      return 1;

   if (lhs.lastChatItem.msg == '' && rhs.lastChatItem.msg == '')
      return lhs.date > rhs.date ? -1
           : lhs.date < rhs.date ? 1 : 0;

   if (lhs.lastChatItem.msg.isEmpty)
      return 1;

   if (rhs.lastChatItem.msg.isEmpty)
      return -1;

   if (lhs.lastChatItem.msg.isEmpty && rhs.lastChatItem.msg.isEmpty)
      return lhs.date > rhs.date ? -1
           : lhs.date < rhs.date ? 1 : 0;

   if (lhs.lastChatItem.msg.isEmpty)
      return 1;

   if (rhs.lastChatItem.msg.isEmpty)
      return -1;

   return lhs.lastChatItem.date > rhs.lastChatItem.date ? -1
        : lhs.lastChatItem.date < rhs.lastChatItem.date ? 1 : 0;
}

Chat selectMostRecentChat(final Chat lhs, final Chat rhs)
{
   final int t1 = lhs.lastChatItem.date;
   final int t2 = rhs.lastChatItem.date;

   return t1 >= t2 ? lhs : rhs;
}

List<List<List<int>>> makeEmptyMenuCodesContainer(int n)
{
   List<List<List<int>>> channel = List<List<List<int>>>(n);
   for (int i = 0; i < n; ++i) {
      channel[i] = List<List<int>>(1);
      channel[i][0] = List<int>();
   }

   return channel;
}

class Post {
   // The auto increment sqlite rowid.
   int dbId = -1;

   // The post unique identifier.  Its value is sent back by the
   // server when the post publication is acknowledged.
   int id = -1;

   // The person that published this post.
   String from = '';

   // The publisher nick name.
   String nick = txt.unknownNick;

   // Contains the channel this post was published in. It has the
   // follwing form
   //
   //  [[[1, 2]], [[3, 2]]]
   //
   List<List<List<int>>> channel;

   List<int> exDetails;
   List<int> inDetails;

   // The publication date.
   int date = 0;

   // The date this post has been pinned by the user.
   int pinDate = 0;

   // Post status.
   //   0: Posts published by the app.
   //   1: Posts received
   //   2: Posts moved to favorites.
   //   3: Posts published by the app but still unacked by the server.
   int status = -1;

   // The string *description* inputed when user writes an post.
   String description = '';

   List<Chat> chats = List<Chat>();

   Post()
   {
      channel = makeEmptyMenuCodesContainer(txt.menuDepthNames.length);
      exDetails = List.generate(txt.maxExDetailSize, (_) => 0);
      inDetails = List.generate(txt.maxInDetailSize, (_) => 0);
   }

   int getProductDetailIdx()
   {
      return channel[1][0][0];
   }

   Post clone()
   {
      Post ret = Post();
      ret.dbId = -1;
      ret.id = this.id;
      ret.from = this.from;
      ret.nick = this.nick;
      ret.channel = List<List<List<int>>>.from(this.channel);
      ret.exDetails = this.exDetails;
      ret.inDetails = this.inDetails;
      ret.date = this.date;
      ret.pinDate = this.pinDate;
      ret.status = this.status;
      ret.description = this.description;
      ret.chats = List<Chat>.from(this.chats);
      return ret;
   }

   int addChat(String peer, String nick)
   {
      final int now = DateTime.now().millisecondsSinceEpoch;
      final int l = chats.length;
      chats.add(Chat(
            peer: peer,
            nick: nick,
            date: now,
            lastChatItem: ChatItem(date: now),
         ),
      );
      return l;
   }

   int getChatHistIdx(final String peer)
   {
      return chats.indexWhere((e) {return e.peer == peer;});
   }

   int getChatHistIdxOrCreate(final String peer,
                              final String nick)
   {
      final int i = getChatHistIdx(peer);
      if (i == -1)
         return addChat(peer, nick);

      return i;
   }

   int getNumberOfUnreadChats()
   {
      int i = 0;
      for (Chat h in chats)
         if (h.nUnreadMsgs > 0)
            ++i;

      return i;
   }

   bool hasUnreadChats()
   {
      // This is more eficient than comparing
      // getNumberOfUnreadChats != 0

      for (Chat h in chats)
         if (h.nUnreadMsgs > 0)
            return true;

      return false;
   }

   int getMostRecentTimestamp()
   {
      if (chats.isEmpty)
         return 0;

      final Chat hist = chats.reduce(selectMostRecentChat);

      return hist.lastChatItem.date;
   }

   Post.fromJson(Map<String, dynamic> map)
   {
      dbId = -1;
      id = map['id'];
      from = map['from'];
      nick = map['nick'];
      channel = decodeChannel(map['to']);

      // FIXME: Fix the server and read the arrays from the json
      // command.
      //exDetails = map['ex_details'];
      //inDetails = map['in_details'];
      exDetails = List.generate(txt.maxExDetailSize, (_) => 0);
      inDetails = List.generate(txt.maxInDetailSize, (_) => 0);

      date = map['date'];
      pinDate = 0;
      status = -1;
      description = map['msg'];
   }

   // This serialization is used to communicate with the server.
   Map<String, dynamic> toJson()
   {
      assert(exDetails.isNotEmpty);
      assert(inDetails.isNotEmpty);

      // NOTE1: The filter field bellow prevents the server from
      // having to parse the ex_details field.
      //
      // NOTE2: The ex- and inDetails arrays are initialized to a size
      // that is bigger than usually need (see maxExDetailSize and
      // maxInDetailSize). We could spare some space in the json
      // payload by reducing their size to the minimum needed before
      // we serialize, this may with a cost of not being able to
      // provide backwards compatibility if expansion of these fields
      // are required in the future. I think the better strategy is to
      // choose these arrays to have two unused elements.
      //
      // To reduce the size to what is exactly needed one has to first
      // get the product index with *int getProductDetailIdx()* and
      // then the size from txt.exDetailTitles[index].length (or
      // txt.exDetails[index].length) and similar to the inDetails
      // array.
      return
      {
         'from': from,
         'to': channel,
         'id': id,
         'filter': exDetails.first,
         'ex_details': exDetails,
         'in_details': inDetails,
         'msg': description,
         'nick': nick,
         'date': date,
      };
   }
}

// This serialization is more complete than the toJson member function
// and is used to persist json objects on the database.
Map<String, dynamic> postToMap(Post post)
{
    return {
      'id': post.id,
      'from_': post.from,
      'nick': post.nick,
      'channel': jsonEncode(post.channel),
      'ex_details': jsonEncode(post.exDetails),
      'in_details': jsonEncode(post.inDetails),
      'date': post.date,
      'pin_date': post.pinDate,
      'status': post.status,
      'description': post.description,
    };
}

Future<List<Post>> loadPosts(Database db) async
{
  List<Map<String, dynamic>> maps = await db.rawQuery(sql.loadPosts);

  return List.generate(maps.length, (i)
  {
     Post post = Post();
     post.dbId = maps[i]['rowid'];
     post.id = maps[i]['id'];
     post.from = maps[i]['from_'];
     post.nick = maps[i]['nick'];
     post.channel = decodeChannel(jsonDecode(maps[i]['channel']));

     post.exDetails = List.generate(txt.maxExDetailSize, (_) => 0);
     List<dynamic> exDetails = jsonDecode(maps[i]['ex_details']);
     if (exDetails != null)
        post.exDetails = List.generate(exDetails.length, (int i)
           { return exDetails[i]; });

     post.inDetails = List.generate(txt.maxInDetailSize, (_) => 0);
     List<dynamic> inDetails = jsonDecode(maps[i]['in_details']);
     if (inDetails != null)
        post.inDetails = List.generate(inDetails.length, (int i)
           { return inDetails[i]; });

     post.date = maps[i]['date'];
     post.pinDate = maps[i]['pin_date'];
     post.status = maps[i]['status'];
     post.description = maps[i]['description'];
     return post;
  });
}

bool toggleLPChat(Chat ch)
{
   final bool old = ch.isLongPressed;
   ch.isLongPressed = !old;
   return old;
}

bool toggleLPChatMsg(ChatItem ci)
{
   final bool old = ci.isLongPressed;
   ci.isLongPressed = !old;
   return old;
}

/* Post sorting criteria
 *
 * 1. A pined post always wins, even one with no chat entries.
 * 2. If two posts are pined, the one with the most recent time stamp
 *    wins.
 *
 * Otherwise (both posts are not pined)
 *
 * 3. A post with chat entries always wins, even if the chat entries
 *    have no message.
 * 4. If two posts do not have chat entries than the one with the most
 *    recent publication date wins.
 *
 * Otherwise (both posts have chat entries)
 *
 * 5. The post with the most recent chat message always wins.
 * 6. If the most recent chat message is zero for both posts, meaning
 *    the chat is empty, the chat entry date is used as criteria.
 */
int CompPosts(final Post lhs, final Post rhs)
{
   if (lhs.pinDate != 0 && rhs.pinDate != 0)
      return lhs.pinDate > rhs.pinDate ? -1
           : lhs.pinDate < rhs.pinDate ? 1 : 0;

   if (lhs.pinDate != 0)
      return -1;

   if (rhs.pinDate != 0)
      return 1;

   if (lhs.chats.length == 0 && rhs.chats.length == 0)
      return lhs.date > rhs.date ? -1
           : lhs.date < rhs.date ? 1 : 0;

   if (lhs.chats.length == 0)
      return 1;

   if (rhs.chats.length == 0)
      return -1;

   final Chat c1 = lhs.chats.reduce(selectMostRecentChat);
   final Chat c2 = rhs.chats.reduce(selectMostRecentChat);

   if (c1.lastChatItem.msg.isEmpty && c2.lastChatItem.msg.isEmpty)
      return c1.date > c2.date ? -1
           : c1.date < c2.date ? 1 : 0;

   if (c1.lastChatItem.msg.isEmpty)
      return 1;

   if (c2.lastChatItem.msg.isEmpty)
      return -1;

   return c1.lastChatItem.date > c2.lastChatItem.date ? -1
        : c1.lastChatItem.date < c2.lastChatItem.date ? 1 : 0;
}

void
findAndMarkChatApp( final List<Post> posts
                  , final String peer
                  , final int postId
                  , final int status
                  , Batch batch)
{
   final int i = posts.indexWhere((e) { return e.id == postId;});
   if (i == -1) {
      print('====> findAndMarkChatApp: Cannot find post id.');
      return;
   }

   final int j = posts[i].chats.indexWhere((e) {return e.peer == peer;});
   if (i == -1) {
      print('====> findAndMarkChatApp: Cannot find user id.');
      return;
   }

   if (status == 1) {
      final int idx = posts[i].chats[j].chatLength;
      posts[i].chats[j].serverAckEnd = idx;
      batch.rawUpdate(sql.updateServerAckEnd,
                     [idx, postId, peer]);
      return;
   }

   if (status == 2) {
      final int idx = posts[i].chats[j].serverAckEnd;
      posts[i].chats[j].appAckReceivedEnd = idx;
      batch.rawUpdate(sql.updateAppAckReceivedEnd,
                     [idx, postId, peer]);
      return;
   }

   if (status == 3) {
      // NOTE: To optimize the system, the app won't send an
      // app_ack_received if the user is in the screen the
      // app_ack_received belongs to, intead an app_ack_read will be
      // sent directly. In such cases we have to update both the
      // received and the read indexes.
      final int idx = posts[i].chats[j].serverAckEnd;
      posts[i].chats[j].appAckReceivedEnd = idx;
      posts[i].chats[j].appAckReadEnd = idx;

      batch.rawUpdate(sql.updateAppAckReceivedEnd,
                     [idx, postId, peer]);

      batch.rawUpdate(sql.updateAppAckReadEnd,
                      [idx, postId, peer]);
      return;
   }

   assert(false);
}

List<List<List<int>>> decodeChannel(List<dynamic> to)
{
   List<List<List<int>>> channel = List<List<List<int>>>();

   for (List<dynamic> a in to) {
      List<List<int>> foo = List<List<int>>();
      for (List<dynamic> b in a) {
         List<int> bar = List<int>();
         for (int c in b) {
            bar.add(c);
         }
         foo.add(bar);
      }

      channel.add(foo);
   }

   return channel;
}

class Config {
   String appId;
   String appPwd;
   String nick;
   int lastPostId;
   int lastSeenPostId;
   String showDialogOnSelectPost;
   String showDialogOnDelPost;

   Config({this.appId = '',
           this.appPwd = '',
           this.nick = '',
           this.lastPostId = 0,
           this.lastSeenPostId = 0,
           this.showDialogOnSelectPost = 'yes',
           this.showDialogOnDelPost = 'yes',
   });
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

Future<List<Config>> loadConfig(Database db) async
{
  final List<Map<String, dynamic>> maps =
     await db.query('config');

  return List.generate(maps.length, (i)
  {
     Config cfg = Config(
        appId: maps[i]['app_id'],
        appPwd: maps[i]['app_pwd'],
        nick: maps[i]['nick'],
        lastPostId: maps[i]['last_post_id'],
        lastSeenPostId: maps[i]['last_seen_post_id'],
        showDialogOnSelectPost: maps[i]['show_dialog_on_select_post'],
        showDialogOnDelPost: maps[i]['show_dialog_on_del_post'],
     );

     return cfg;
  });
}

Future<List<Chat>> loadChats(Database db, int postId) async
{
  final List<Map<String, dynamic>> maps =
     await db.rawQuery(sql.selectChatStatusItem, [postId]);

  return List.generate(maps.length, (i)
  {
     final String str = maps[i]['last_chat_item'];
     ChatItem lastChatItem = ChatItem();
     if (!str.isEmpty)
         lastChatItem = ChatItem.fromJson(jsonDecode(str));

     return Chat(
        peer: maps[i]['user_id'],
        nick: maps[i]['nick'],
        date: maps[i]['date'],
        pinDate: maps[i]['pin_date'],
        appAckReadEnd: maps[i]['app_ack_read_end'],
        appAckReceivedEnd: maps[i]['app_ack_received_end'],
        serverAckEnd: maps[i]['server_ack_end'],
        chatLength: maps[i]['chat_length'],
        nUnreadMsgs: maps[i]['n_unread_msgs'],
        lastChatItem: lastChatItem,
     );
  });
}

List<dynamic> makeChatUpdateSql(Chat chat, int postId)
{
   final String payload = jsonEncode(chat.lastChatItem);

   return <dynamic>
   [ postId
   , chat.peer
   , chat.date
   , chat.pinDate
   , chat.nick
   , chat.appAckReadEnd
   , chat.appAckReceivedEnd
   , chat.serverAckEnd
   , chat.chatLength
   , chat.nUnreadMsgs
   , payload
   ];
}

