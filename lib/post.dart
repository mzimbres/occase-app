import 'dart:convert';
import 'dart:io' show File, FileMode, Directory;
import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:menu_chat/constants.dart';
import 'package:menu_chat/tree.dart';
import 'package:menu_chat/text_constants.dart' as cts;
import 'package:menu_chat/globals.dart' as glob;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

String serializeList<T>(final List<T> data)
{
   String content = '';
   for (T o in data) {
      final String postStr = jsonEncode(o);
      content += '$postStr\n';
   }

   return content;
}

int chatStatusStrToInt(final String cmd)
{
   if (cmd == 'chat')
      return 0;
   if (cmd == 'server_ack')
      return 1;
   if (cmd == 'app_ack_received')
      return 2;
   if (cmd == 'app_ack_read')
      return 3;

   assert(false);
}

String chatStatusIntToStr(final int status)
{
   if (status == 0)
      return 'chat';
   if (status == 1)
      return 'server_ack';
   if (status == 2)
      return 'app_ack_received';
   if (status == 3)
      return 'app_ack_read';

   assert(false);
}

class ChatItem {
   bool thisApp; 
   String msg = '';
   int status = 0;
   int date = 0;
   bool isLongPressed = false;

   ChatItem(this.thisApp, this.msg, this.status, this.date);

   ChatItem.fromJson(Map<String, dynamic> map)
   {
      thisApp = map["this_app"];
      msg = map["msg"];
      status = map["status"];
   }

   Map<String, dynamic> toJson()
   {
      return
      {
         'this_app': thisApp,
         'msg': msg,
         'status': status,
      };
   }
}

List<ChatItem> chatItemsFromStrs(final List<String> lines)
{
   List<ChatItem> foo = List<ChatItem>();
   for (String line in lines) {
      Map<String, dynamic> map = jsonDecode(line);
      ChatItem item = ChatItem.fromJson(map);
      if (item.msg.isEmpty) {
         assert(!foo.isEmpty);
         for (int i = 0; i < foo.length; ++i) {
            final int j = foo.length - i - 1;
            if (foo[j].status >= item.status)
               break;
            foo[j].status = item.status;
         }
      } else {
         foo.add(item);
      }
   }

   return foo;
}

class Chat {
   String peer = '';
   String nick = '';
   int date = 0;
   int pinDate = 0;
   bool isLongPressed = false;
   List<ChatItem> msgs = List<ChatItem>();

   String getChatDisplayName()
   {
      if (nick.isEmpty)
         return '$peer';

      return '$nick ($peer)';
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

   Chat(this.peer, this.nick, this.date, final int postId);

   String makeFullPath(final String prefix, final int postId)
   {
      return '${glob.docDir}/${prefix}_${postId}_${peer}.txt';
   }

   int getMostRecentTimestamp()
   {
      if (msgs.isEmpty)
         return 0;

      return msgs.last.date;
   }

   Future<void> loadMsgs(final int postId) async
   {
      try {
         File f = File(makeFullPath(cts.chatFilePrefix, postId));
         final List<String> lines = await f.readAsLines();
         msgs = chatItemsFromStrs(lines);
      } catch (e) {
      }
   }

   int getNumberOfMsgs()
   {
      return msgs.length;
   }

   Future<void> setPeerMsgStatus(int status, int postId) async
   {
      for (int i = 0; i < msgs.length; ++i) {
         final int j = msgs.length - i - 1;
         if (msgs[j].thisApp)
            continue;

         if (msgs[j].status >= status)
            break;

         msgs[j].status = status;
         await persistStatus(postId, status, false);
      }
   }

   int getNumberOfUnreadMsgs()
   {
      int n = 0;
      for (int i = 0; i < msgs.length; ++i) {
         final int j = msgs.length - i - 1;
         if (msgs[j].thisApp)
            continue;

         if (msgs[j].status >= 3)
            break;

         ++n;
      }

      return n;
   }

   bool hasUnreadMsgs()
   {
      if (msgs.isEmpty)
         return false;

      return !msgs.last.thisApp && msgs.last.status < 3;
   }

   String getLastMsg()
   {
      if (msgs.isEmpty)
         return '';

      return msgs.last.msg;
   }

   Future<void>
   addMsg(final String msg, final bool thisApp,
          final int postId, int status, int now) async
   {
      ChatItem item = ChatItem(thisApp, msg, status, now);
      msgs.add(item);

      final String content = serializeList(<ChatItem>[item]);
      await File(makeFullPath(cts.chatFilePrefix, postId))
         .writeAsString(content, mode: FileMode.append);
   }

   Future<void>
   markAppChatAck(final int postId, final int status) async
   {
      //assert(!msgs.isEmpty); 
      if (msgs.isEmpty) {
         print('markAppChatAck ignoring1');
         return;
      }

      for (int i = 0; i < msgs.length; ++i) {
         final int j = msgs.length - i - 1; // Idx of the last element.
         if (!msgs[j].thisApp)
            continue; // Not a message from this app.

         if (msgs[j].status >= status) // Should be >=
            break;

         msgs[j].status = status;
      }

      await persistStatus(postId, status, true);
   }

   Future<void>
   persistStatus(int postId, int status, bool thisApp) async
   {
      ChatItem item = ChatItem(thisApp, '', status, 0);
      final String str = jsonEncode(item);
      await File(makeFullPath(cts.chatFilePrefix, postId))
         .writeAsString('${str}\n', mode: FileMode.append);
   }
}

int CompChats(final Chat lhs, final Chat rhs)
{

   if (lhs.msgs.length == 0 && rhs.msgs.length == 0)
      return lhs.date > rhs.date ? -1 : 1;

   if (lhs.msgs.length == 0)
      return 1;

   if (rhs.msgs.length == 0)
      return -1;

   if (lhs.pinDate != 0 && rhs.pinDate != 0)
      return lhs.pinDate > rhs.pinDate ? -1 : 1;

   if (lhs.pinDate != 0)
      return -1;

   if (rhs.pinDate != 0)
      return 1;

   final int ts1 = lhs.getMostRecentTimestamp();
   final int ts2 = rhs.getMostRecentTimestamp();
   return ts1 > ts2 ? -1 : 1;
}

Chat selectMostRecentChat(final Chat lhs, final Chat rhs)
{
   final int t1 = lhs.getMostRecentTimestamp();
   final int t2 = rhs.getMostRecentTimestamp();

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
   String nick = cts.unknownNick;

   // Contains the channel this post was published in.
   //
   //  [[[1, 2]], [[3, 2]], [[3, 2, 1, 1]]]
   //
   List<List<List<int>>> channel;

   int filter = 0;

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
      channel = makeEmptyMenuCodesContainer(cts.menuDepthNames.length);
   }

   String makePathToPeersFile()
   {
      return '${glob.docDir}/post_peers_${id}.txt';
   }

   Future<void> loadChats() async
   {
      try {
         chats = List<Chat>();
         File f = File(makePathToPeersFile());
         final List<String> lines = await f.readAsLines();
         print('Peers: $lines');
         for (String line in lines) {
            final List<String> fields = line.split(';');
            // The assertion should be for == not >=.
            assert(fields.length >= 3);
            Chat hist = Chat(
               fields[0], fields[1], int.parse(fields[2]), id);
            await hist.loadMsgs(id);
            chats.add(hist);
         }
      } catch (e) {
         //print(e);
      }
   }

   Post clone()
   {
      Post ret = Post();
      ret.channel = List<List<List<int>>>.from(this.channel);
      ret.description = this.description;
      ret.chats = List<Chat>.from(this.chats);
      ret.from = this.from;
      ret.id = this.id;
      ret.filter = this.filter;
      ret.nick = this.nick;
      ret.date = this.date;
      ret.status = this.status;
      ret.pinDate = this.pinDate;
      return ret;
   }

   Future<void> setNick(final String peer, final String nick) async
   {
      final int j = getChatHistIdx(peer);
      if (j == -1) {
         // AFAIK, the only way this can happen ist if the app user
         // has deleted the Chat in the time between the
         // nick_req has been sent and the ack has been received.  So
         // there is no need or way to proceeed.
         return;
      }

      chats[j].nick = nick;
      await persistPeers();
   }

   Future<void> persistPeers() async
   {
      // Overwrites the previous content.
      String data = '';
      for (Chat o in chats)
         data += '${o.peer};${o.nick};${o.date}\n';

      print('Persisting peers: \n$data');

      await File(makePathToPeersFile())
         .writeAsString(data, mode: FileMode.write);
   }

   Future<void>
   createChatEntryForPeer(String peer, final String nick) async
   {
      print('Creating chat entry for: $peer');
      final int now = DateTime.now().millisecondsSinceEpoch;
      Chat history = Chat(peer, nick, now, id);
      chats.add(history);
      await persistPeers();
   }

   int getChatHistIdx(final String peer)
   {
      return chats.indexWhere((e) {return e.peer == peer;});
   }

   Future<int>
   getChatHistIdxOrCreate(final String peer, final String nick) async
   {
      final int i = getChatHistIdx(peer);
      if (i == -1) {
         print('creating $peer $id');
         // This is the first message with this user (peer).
         final int l = chats.length;
         await createChatEntryForPeer(peer, nick);
         return l;
      }

      return i;
   }

   Future<void>
   markChatAppAck(final String peer, final int status) async
   {
      final int i = getChatHistIdx(peer);
      if (i == -1) {
         print('markChatAppAck: Ignoring ack.');
         return;
      }

      await chats[i].markAppChatAck(id, status);
   }

   int getNumberOfUnreadChats()
   {
      int i = 0;
      for (Chat h in chats)
         if (h.getNumberOfUnreadMsgs() > 0)
            ++i;

      return i;
   }

   bool hasUnreadChats()
   {
      // This is more eficient than comparing
      // getNumberOfUnreadChats != 0

      for (Chat h in chats)
         if (h.getNumberOfUnreadMsgs() > 0)
            return true;

      return false;
   }

   int getMostRecentTimestamp()
   {
      if (chats.isEmpty)
         return 0;

      final Chat hist = chats.reduce(selectMostRecentChat);

      return hist.getMostRecentTimestamp();
   }

   Future<void> removeLPChats(int idx) async
   {
      try {
         print('removeLPC($idx), length = ${chats.length}, id = $id');

         assert(!chats.isEmpty);
         assert(idx < chats.length);

         if (chats[idx].isLongPressed) {
            try {
               await File(chats[idx].makeFullPath(cts.chatFilePrefix, id))
                  .deleteSync();
            } catch (e) {
            }
         }

         chats.removeAt(idx);
         await persistPeers();
      } catch (e) {
      }
   }

   Post.fromJson(Map<String, dynamic> map)
   {
      // Part of the object can be deserialized by readPostData. The
      // only remaining field will be *peers* and the chat history.
      Post pd = readPostData(map);
      from = pd.from;
      id = pd.id;
      channel = pd.channel;
      description = pd.description;
      filter = pd.filter;
      nick = pd.nick;
      date = pd.date;
      pinDate = pd.pinDate;
      status = pd.status;
   }

   Map<String, dynamic> toJson()
   {
      // To make the deserialization easier, we will make the json
      // partially deserializable by readPostData.
      return
      {
         'from': from,
         'to': channel,
         'id': id,
         'filter': filter,
         'msg': description,
         'nick': nick,
         'date': date,
      };
   }
}

Map<String, dynamic> postToMap(Post post)
{
    return {
      'id': post.id,
      'from_': post.from,
      'nick': post.nick,
      'channel': jsonEncode(post.channel),
      'filter': post.filter,
      'date': post.date,
      'pin_date': post.pinDate,
      'status': post.status,
      'description': post.description,
    };
}

Future<List<Post>> loadPosts(Database db, String tableName) async
{
  final List<Map<String, dynamic>> maps =
     await db.query(tableName);

  return List.generate(maps.length, (i)
  {
     Post post = Post();
     post.dbId = maps[i]['rowid'];
     post.id = maps[i]['id'];
     post.from = maps[i]['from_'];
     post.nick = maps[i]['nick'];
     post.channel = decodeChannel(jsonDecode(maps[i]['channel']));
     post.filter = maps[i]['filter'];
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

// Post sorting criteria
//
// 1. A pined post always wins, even one with no chat entries.
// 2. If two posts are pined, the one with the most recent time stamp
//    wins.
//
// Otherwise (both posts are not pined)
//
// 3. A post with chat entries always wins, even if the chat entries
//    have no message.
// 4. If two posts do not have chat entries than the one with the most
//    recent publication date wins.
//
// Otherwise (both posts have chat entries)
//
// 5. The post with the most recent chat message always wins.
// 6. If the most recent chat message is zero for both posts, meaning
//    the chat is empty, the chat entry date is used as criteria.
//
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

   if (c1.msgs.isEmpty && c2.msgs.isEmpty)
      return c1.date > c2.date ? -1
           : c1.date < c2.date ? 1 : 0;

   if (c1.msgs.isEmpty)
      return 1;

   if (c2.msgs.isEmpty)
      return -1;

   return c1.msgs.last.date > c2.msgs.last.date ? -1
        : c1.msgs.last.date < c2.msgs.last.date ? 1 : 0;
}

Future<void>
findAndMarkChatApp( final List<Post> posts
                  , final String from
                  , final int postId
                  , final int status) async
{
   final int i = posts.indexWhere((e) { return e.id == postId;});

   if (i == -1) {
      print('====> findAndMarkChatApp: Cannot find msg.');
      return;
   }

   await posts[i].markChatAppAck(from, status);
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

Post readPostData(var item)
{
   Post post = Post();
   post.description = item['msg'];
   post.from = item['from'];
   post.id = item['id'];
   post.filter = item['filter'];
   post.nick = item['nick'];
   post.channel = decodeChannel(item['to']);
   post.pinDate = 0;
   post.status = -1;
   return post;
}

class Config {
   String appId = '';
   String appPwd = '';
   String nick = '';
   int lastPostId = 0;
   int lastSeenPostId = 0;
   String showDialogOnSelectPost = 'yes';
   String showDialogOnDelPost = 'yes';
   String menu = Consts.menus;

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
      'menu': cfg.menu,
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
     cfg.menu = maps[i]['menu'];

     return cfg;
  });
}

Future<List<Chat>> loadChat(Database db, int postId) async
{
  final List<Map<String, dynamic>> maps =
     await db.rawQuery(cts.selectChatStatusItem, [postId]);

  return List.generate(maps.length, (i)
  {
     final String user_id = maps[i]['user_id'];
     final int date = maps[i]['date'];
     final int pinDate = maps[i]['pin_date'];
     final String nick = maps[i]['nick'];
     final String last_msg = maps[i]['last_msg'];
     print('====> $user_id $date $pinDate $nick $last_msg');

     return Chat('', '', 0, 0);
  });
}

