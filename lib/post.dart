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

class ChatItem {
   bool thisApp; 
   String msg = '';
   int date = 0;
   bool isLongPressed = false;

   ChatItem(this.thisApp, this.msg, this.date);

   ChatItem.fromJson(Map<String, dynamic> map)
   {
      thisApp = map["this_app"];
      msg = map['msg'];
      date = map['date'];
   }

   Map<String, dynamic> toJson()
   {
      return
      {
         'this_app': thisApp,
         'msg': msg,
         'date': date,
      };
   }
}

class Chat {
   String peer = '';
   String nick = '';
   int date = 0;
   int pinDate = 0;
   int lastAppReadIdx = -1;
   int lastAppReceivedIdx = -1;
   int lastServerAckedIdx = -1;
   int nUnreadMsgs = 0;
   ChatItem lastChatItem = ChatItem(true, '', 0);

   bool isLongPressed = false;
   List<ChatItem> msgs = null;
   File _msgsFile = null;

   Chat(this.peer, this.nick, this.date, this.pinDate,
        this.lastAppReadIdx, this.lastAppReceivedIdx,
        this.lastServerAckedIdx, this.nUnreadMsgs,
        this.lastChatItem);

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
      _msgsFile = File(makeFullPath(cts.chatFilePrefix, postId));
   }

   void loadMsgs(final int postId)
   {
      print('Loading msgs');
      try {
         if (!_isFileOpen()) {
            print('Opening file');
            _openFile(postId);
         }

         List<String> lines = _msgsFile.readAsLinesSync();
         msgs = List<ChatItem>.generate(lines.length, (int i)
            { return ChatItem.fromJson(jsonDecode(lines[i])); });
      } catch (e) {
         print(e);
      }
   }

   void persistChatMsg(ChatItem item, final int postId)
   {
      if (!_isFileOpen())
         _openFile(postId);

      String content = jsonEncode(item);
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

   int createChatEntryForPeer(String peer, String nick)
   {
      print('Creating chat entry for: $peer');
      final int now = DateTime.now().millisecondsSinceEpoch;
      Chat history =
         Chat(peer, nick, now, 0, -1, -1, -1, 0, ChatItem(true, '', 0));
      final int l = chats.length;
      chats.add(history);
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
         return createChatEntryForPeer(peer, nick);

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

   final int l = posts[i].chats[j].msgs.length;

   if (status == 1) {
      print('1 Writing $peer $postId $status $l');
      posts[i].chats[j].lastServerAckedIdx = l - 1;
      batch.rawUpdate(cts.updateLastServerAckedIdx,
                      [l - 1, postId, peer]);
      return;
   }

   if (status == 2) {
      print('2 Writing $peer $postId $status $l');
      posts[i].chats[j].lastAppReceivedIdx = l - 1;
      batch.rawUpdate(cts.updateLastAppReceivedIdx,
                      [l - 1, postId, peer]);
      return;
   }

   if (status == 3) {
      print('3 Writing $peer $postId $status $l');
      posts[i].chats[j].lastAppReadIdx = l - 1;
      batch.rawUpdate(cts.updateLastAppReadIdx,
                      [l - 1, postId, peer]);
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

Future<List<Chat>> loadChats(Database db, int postId) async
{
  final List<Map<String, dynamic>> maps =
     await db.rawQuery(cts.selectChatStatusItem, [postId]);

  return List.generate(maps.length, (i)
  {
     final int postId = maps[i]['post_id'];
     final String peer = maps[i]['user_id'];
     final int date = maps[i]['date'];
     final int pinDate = maps[i]['pin_date'];
     final String nick = maps[i]['nick'];
     final int lastAppReadIdx = maps[i]['last_app_read_idx'];
     final int lastAppReceivedIdx = maps[i]['last_app_received_idx'];
     final int lastServerAckedIdx = maps[i]['last_server_acked_idx'];
     final int nUnreadMsgs = maps[i]['n_unread_msgs'];
     final String lastChatItemStr = maps[i]['last_chat_item'];

     print('$peer $postId $date $pinDate $lastAppReadIdx $lastAppReceivedIdx $lastServerAckedIdx $nUnreadMsgs $lastChatItemStr');

     ChatItem lastChatItem = ChatItem(true, '', 0);
     if (!lastChatItemStr.isEmpty)
         lastChatItem = ChatItem.fromJson(jsonDecode(lastChatItemStr));

     return Chat(peer, nick, date, pinDate, lastAppReadIdx,
                 lastAppReceivedIdx, lastServerAckedIdx,
                 nUnreadMsgs, lastChatItem);
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
   , chat.lastAppReadIdx
   , chat.lastAppReceivedIdx
   , chat.lastServerAckedIdx
   , chat.nUnreadMsgs
   , payload
   ];
}

