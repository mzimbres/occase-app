import 'dart:convert';
import 'dart:async' show Future;
import 'package:occase/globals.dart' as g;
import 'package:occase/tree.dart' as tree;
import 'package:occase/sql.dart' as sql;
import 'package:occase/constants.dart' as cts;
import 'package:sqflite/sqflite.dart';

class ChatItem {
   // The auto increment sqlite rowid.
   int rowid = -1;

   // This field is -1 if the message belongs to this app or the peer row id
   // if it belongs to the peer.
   int peerRowid = -1;

   // If the message is redirected, be it from this app or from the peer, this
   // field will be set to 1.
   int isRedirected = 0;

   // A value different from -1 means this message refers to another
   // message.
   int refersTo;

   // When the message is from this app, we have to show the icond
   //
   // 0: Message unsent
   // 1: The server has received the message.
   // 2: The peer has received the message.
   // 3: The peer has read the message.
   //
   // This field is only meaningfull when the message belongs to this app.
   int status;

   String msg;
   int date;

   bool isLongPressed;

   ChatItem(
   { this.rowid = -1
   , this.peerRowid = -1
   , this.isRedirected = 0
   , this.refersTo = -1
   , this.status = 0
   , this.isLongPressed = false
   , this.msg = ''
   , this.date = 0
   });

   bool redirected()
   {
      return isRedirected != 0;
   }

   bool isFromThisApp()
   {
      return peerRowid == -1;
   }

   bool refersToOther()
   {
      return refersTo != -1;
   }

   // Used only by ChatMetadata to store the last chat message that is shown
   // without requiring load of all messages.
   ChatItem.fromJson(Map<String, dynamic> map)
   {
      peerRowid = map["peer_rowid"];
      refersTo = map['refers_to'];
      status = map['status'];
      isRedirected = map['is_redirected'];
      msg = map['msg'];
      date = map['date'];

      isLongPressed = false;
   }

   Map<String, dynamic> toJson()
   {
      return
      { 'peer_rowid': peerRowid
      , 'refers_to': refersTo
      , 'status': status
      , 'is_redirected': isRedirected
      , 'msg': msg
      , 'date': date
      };
   }
}

// To be able to ack unread chat messages as the user clicks on the chat,
// we need the peer rowids.
List<int> readPeerRowIdsToAck(
   final List<ChatItem> chats,
   final int n,
) {
   
   List<int> res = List<int>();
   final int l = chats.length;
   for (int i = l - n; i < l; ++i)
      res.add(chats[i].peerRowid);

   return res;
}

Map<String, dynamic> makeChatItemToMap(
   int postId,
   String userId,
   ChatItem ci,
) {
    return
    { 'post_id': postId
    , 'user_id': userId
    , 'peer_rowid': ci.peerRowid
    , 'is_redirected': ci.isRedirected
    , 'refers_to': ci.refersTo
    , 'status': ci.refersTo
    , 'date': ci.date
    , 'msg': ci.msg
    };
}

int indexWhereBackwards(final List<ChatItem> list, int rowid)
{
   int l = list.length;
   print('Length $l');
   while (l != 0) {
      --l;
      if (list[l].rowid == rowid)
         return l;

      print('${list[l].rowid} != $rowid');
   }

   return -1;
}

class ChatMetadata {
   String peer;
   String nick;
   int date;
   int pinDate;
   int chatLength;
   int nUnreadMsgs;
   ChatItem lastChatItem;

   bool isLongPressed;
   List<ChatItem> msgs;

   // The number of unread msgs shown int the new msgs divisor shown
   // in the chat screen when one enters it and threre were unread
   // msgs in the chat.
   int divisorUnreadMsgs;

   // The index where the divisor above shall be shown.
   int divisorUnreadMsgsIdx;

   // This variable contains the timestamps of the last time we sent a
   // presence-writing message to the peer.
   int lastPresenceSent;

   // This variable contains the timestamp from the last presence
   // message received from the peer.
   int lastPresenceReceived;

   ChatMetadata(
   { this.peer = ''
   , this.nick = ''
   , this.date = 0
   , this.pinDate = 0
   , this.chatLength = 0
   , this.nUnreadMsgs = 0
   , this.lastChatItem
   , this.isLongPressed = false
   , this.lastPresenceSent = 0
   , this.lastPresenceReceived = 0
   }) {
      divisorUnreadMsgs = nUnreadMsgs;
      divisorUnreadMsgsIdx = chatLength - nUnreadMsgs;
   }

   bool isLoaded()
   {
      return msgs != null;
   }

   void addChatItem(ChatItem ci)
   {
      lastChatItem = ci;
      if (isLoaded()) {
         msgs.add(ci);
         chatLength = msgs.length;
      } else {
         ++chatLength;
      }
   }

   void setAckStatus(int rowid, int status)
   {
      if (lastChatItem.rowid == rowid)
         lastChatItem.status = status;

      if (isLoaded()) {
         // Searching backwards to improve performance. We may also want to
         // add a limit on how many messages back we are willing to search.
         final int i = indexWhereBackwards(msgs, rowid);
         if (i != -1) {
            msgs[i].status = status;
         } else {
            print('===> rowid $rowid not found.');
         }
      }
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

   Future<void> loadMsgs(
      final int postId,
      final String userId,
      Database db,
   ) async {
      try {
         final List<Map<String, dynamic>> maps =
            await db.rawQuery(sql.selectChats, [postId, userId]);

         msgs = List.generate(maps.length, (i)
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
int compChats(final ChatMetadata lhs, final ChatMetadata rhs)
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

ChatMetadata selectMostRecentChat(
   final ChatMetadata lhs,
   final ChatMetadata rhs
) {
   final int t1 = lhs.lastChatItem.date;
   final int t2 = rhs.lastChatItem.date;

   return t1 >= t2 ? lhs : rhs;
}

List<List<List<int>>> makeEmptyChannels()
{
   return <List<List<int>>>
   [ <List<int>>[<int>[]]
   , <List<int>>[<int>[]]
   ];
}

List<T> decodeList<T>(int size, T init, List<dynamic> details)
{
   List<T> ret = List.filled(size, init);
   if (details != null) {
      ret = List.generate(details.length, (int i) { return details[i]; });
   } else {
      print('Value not found.');
   }

   return ret;
}

class Post {
   // The auto increment sqlite rowid. TODO: Rename this to rowid.
   int dbId = -1;

   // The post unique identifier.  Its value is sent back by the
   // server when the post publication is acknowledged.
   int id = -1;

   // The person that published this post.
   String from = '';

   // Publisher nick name.
   String nick = g.param.unknownNick;

   // Publisher avatar hash code from gravatar.
   String avatar = '';

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

   List<int> rangeValues = List<int>();

   // Post status.
   //   0: Posts published by the app.
   //   1: Posts received
   //   2: Posts moved to favorites.
   //   3: Posts published by the app but still unacked by the server.
   int status = -1;

   // The string *description* inputed when user writes an post.
   String description = '';

   List<String> images = List<String>();

   List<ChatMetadata> chats = List<ChatMetadata>();

   Post()
   {
      channel = makeEmptyChannels();
      exDetails = List.generate(cts.maxExDetailSize, (_) => 1);
      inDetails = List.generate(cts.maxInDetailSize, (_) => 0);
      rangeValues = List.generate(g.param.rangeDivs.length, (int i) {
         return g.param.rangesMinMax[2 * i];
      });

      avatar = '';
   }

   int getPrice()
      { return rangeValues[0]; }

   int getProductDetailIdx()
      { return channel[1][0][0]; }

   Post clone()
   {
      Post ret = Post();
      ret.dbId = -1;
      ret.id = this.id;
      ret.from = this.from;
      ret.nick = this.nick;
      ret.avatar = this.avatar;
      ret.channel = List<List<List<int>>>.from(this.channel);
      ret.exDetails = this.exDetails;
      ret.inDetails = this.inDetails;
      ret.date = this.date;
      ret.pinDate = this.pinDate;
      ret.rangeValues = List<int>.from(this.rangeValues);
      ret.status = this.status;
      ret.description = this.description;
      ret.chats = List<ChatMetadata>.from(this.chats);
      ret.images = List<String>.from(this.images);
      return ret;
   }

   int addChat(String peer, String nick)
   {
      final int now = DateTime.now().millisecondsSinceEpoch;
      final int l = chats.length;
      chats.add(ChatMetadata(
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
      for (ChatMetadata h in chats)
         if (h.nUnreadMsgs > 0)
            ++i;

      return i;
   }

   bool hasUnreadChats()
   {
      // This is more eficient than comparing
      // getNumberOfUnreadChats != 0

      for (ChatMetadata h in chats)
         if (h.nUnreadMsgs > 0)
            return true;

      return false;
   }

   int getMostRecentTimestamp()
   {
      if (chats.isEmpty)
         return 0;

      final ChatMetadata hist = chats.reduce(selectMostRecentChat);

      return hist.lastChatItem.date;
   }

   // This serialization is used to communicate with the occase-db,
   // not the one used in the sqlite localy.
   Post.fromJson(Map<String, dynamic> map)
   {
      dbId = -1;
      id = map['id'];
      from = map['from'];
      date = map['date'];
      pinDate = 0;
      status = -1;
      rangeValues = decodeList(g.param.rangeDivs.length, 0, map['range_values']);

      final String body = map['body'];
      Map<String, dynamic> bodyMap = jsonDecode(body);
      nick = bodyMap['nick'] ?? g.param.unknownNick;
      avatar = bodyMap['avatar'] ?? '';
      images = decodeList(1, '', bodyMap['images']) ?? <String>[];
      description = bodyMap['msg'];
      exDetails = decodeList(cts.maxExDetailSize, 1, bodyMap['ex_details']);
      inDetails = decodeList(cts.maxInDetailSize, 0, bodyMap['in_details']);
      channel = decodeChannel(bodyMap['channel']);
   }

   Map<String, dynamic> toJson()
   {
      assert(exDetails.isNotEmpty);
      assert(inDetails.isNotEmpty);

      // NOTE2: The ex- and inDetails arrays are initialized to a size
      // that is bigger than usually need (see maxExDetailSize and
      // maxInDetailSize). We could spare some space in the json
      // payload by reducing their size to the minimum needed before
      // serialization, this may come with a cost of not being able to
      // provide backwards compatibility if expansion of these fields
      // is required in the future. I think the better strategy is to
      // choose these arrays to have two unused elements.
      //
      // To reduce the size to what is exactly needed one has to first
      // get the product index with *int getProductDetailIdx()* and
      // then the size from txt.exDetailTitles[index].length (or
      // txt.exDetails[index].length) and similar to the inDetails
      // array.

      assert(channel.length == 2);

      var subCmd = {
         'msg': description,
         'nick': nick,
         'avatar': avatar,
         'images': images,
         'ex_details': exDetails,
         'in_details': inDetails,
         'channel': channel,
      };

      final String body = jsonEncode(subCmd);

      return
      { 'from': from
      , 'to': tree.toChannelHashCode(
           channel[1][0],
           g.param.filterDepths[1])
      , 'filter': tree.toChannelHashCode(
           channel[0][0],
           g.param.filterDepths[0])
      , 'id': id
      , 'features': exDetails.first
      , 'body': body
      , 'date': date
      , 'range_values': rangeValues
      };
   }
}

// This serialization is more complete than the toJson member function
// and is used to persist json objects on the database.
Map<String, dynamic> postToMap(Post post)
{
   // Changing theses fields does not require changes the schema in
   // sqlite.

   var subCmd = {
     'from': post.from,
     'nick': post.nick,
     'avatar': post.avatar,
     'channel': jsonEncode(post.channel),
     'ex_details': jsonEncode(post.exDetails),
     'in_details': jsonEncode(post.inDetails),
     'range_values': jsonEncode(post.rangeValues),
     'description': post.description,
     'images': post.images,
   };

   final String body = jsonEncode(subCmd);

   return {
     'id': post.id,
     'date': post.date,
     'pin_date': post.pinDate,
     'status': post.status,
     'body': body
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
      post.date = maps[i]['date'];
      post.pinDate = maps[i]['pin_date'];
      post.status = maps[i]['status'];

      final String body = maps[i]['body'];
      Map<String, dynamic> bodyMap = jsonDecode(body);


      post.from = bodyMap['from'];
      post.nick = bodyMap['nick'];
      post.avatar = bodyMap['nick'];
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

      post.rangeValues = decodeList(
         g.param.rangeDivs.length,
         0,
         jsonDecode(bodyMap['range_values']),
      );

      post.images = decodeList(1, '', bodyMap['images']) ?? <String>[];

      post.description = bodyMap['description'] ?? '';
      return post;
   });
}

bool toggleLPChat(ChatMetadata ch)
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
int compPosts(final Post lhs, final Post rhs)
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

   final ChatMetadata c1 = lhs.chats.reduce(selectMostRecentChat);
   final ChatMetadata c2 = rhs.chats.reduce(selectMostRecentChat);

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

class IdxPair {
   int i;
   int j;
   IdxPair({this.i = -1, this.j = -1});
}

bool IsInvalidPair(final IdxPair p)
{
   return p.i == -1 || p.j == -1;
}

IdxPair findChat(final List<Post> posts, String peer, int postId)
{
   final int i = posts.indexWhere((e) { return e.id == postId;});
   if (i == -1)
      return IdxPair(i: -1, j: -1);

   final int j = posts[i].chats.indexWhere((e) {return e.peer == peer;});
   if (i == -1)
      return IdxPair(i: -1, j: -1);

   return IdxPair(i: i, j: j);
}

bool markPresence(
   final List<Post> posts,
   final String peer,
   final int postId,
) {
   // We have to traverse all posts and in each one search chat by
   // chat for the user with the given id.

   final IdxPair p = findChat(posts, peer, postId);

   if (IsInvalidPair(p))
      return false;

   final int now = DateTime.now().millisecondsSinceEpoch;
   posts[p.i].chats[p.j].lastPresenceReceived = now;
   return true;
}

bool findAndMarkChatApp(
   final List<Post> posts,
   final String peer,
   final int postId,
   final int status,
   final int rowid,
   Batch batch,
) {
   final IdxPair p = findChat(posts, peer, postId);
   if (IsInvalidPair(p))
      return false;

   posts[p.i].chats[p.j].setAckStatus(rowid, status);
   posts[p.i].chats[p.j].lastChatItem.status = status;

   batch.rawUpdate(
      sql.updateAckStatus,
      [status, rowid],
   );

   batch.rawUpdate(
      sql.updateLastChat,
      [jsonEncode(posts[p.i].chats[p.j].lastChatItem), postId, peer],
   );

   return true;
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
   String email;
   String nick;
   int lastPostId;
   int lastSeenPostId;
   String showDialogOnSelectPost;
   String showDialogOnReportPost;
   String showDialogOnDelPost;

   // Filter Ranges. There is one range for each value, see
   // g.param.rangesMinMax, g.param.rangeDivs and txt. rangePrefixes.
   List<int> ranges;

   int anyOfFeatures;

   Config({
      this.appId = '',
      this.appPwd = '',
      this.email = '',
      this.nick = '',
      this.lastPostId = 0,
      this.lastSeenPostId = 0,
      this.showDialogOnSelectPost = 'yes',
      this.showDialogOnReportPost = 'yes',
      this.showDialogOnDelPost = 'yes',
      this.ranges,
      this.anyOfFeatures = 0,
   })
   {
      if (ranges == null) {
         final int l = g.param.discreteRanges.length;
         ranges = List<int>(2 * l);
         for (int i = 0; i < l; ++i) {
            assert(g.param.discreteRanges[i].isNotEmpty);
            ranges[2 * i + 0] = 0;
            ranges[2 * i + 1] = g.param.discreteRanges[i].length - 1;
         }
      }
   }
}

List<int> convertToValues(final List<int> ranges)
{
   final int l = g.param.discreteRanges.length;
   List<int> rangeValues = List<int>(2 * l);
   assert(ranges.length == 2 * l);

   for (int i = 0; i < l; ++i) {
      final int idx1 = 2 * i + 0;
      final int idx2 = 2 * i + 1;
      rangeValues[idx1] = g.param.discreteRanges[i][ranges[idx1]];
      rangeValues[idx2] = g.param.discreteRanges[i][ranges[idx2]];
   }

   return rangeValues;
}

Map<String, dynamic> configToMap(Config cfg)
{
    return {
      'app_id': cfg.appId,
      'app_pwd': cfg.appPwd,
      'email': cfg.email,
      'nick': cfg.nick,
      'last_post_id': cfg.lastPostId,
      'last_seen_post_id': cfg.lastSeenPostId,
      'show_dialog_on_select_post': cfg.showDialogOnSelectPost,
      'show_dialog_on_report_post': cfg.showDialogOnReportPost,
      'show_dialog_on_del_post': cfg.showDialogOnDelPost,
      'ranges': cfg.ranges.join(' '),
      'any_of_features': cfg.anyOfFeatures.toString(),
    };
}

Future<List<Config>> loadConfig(Database db) async
{
  final List<Map<String, dynamic>> maps =
     await db.query('config');

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
     );

     return cfg;
  });
}

Future<List<ChatMetadata>>
loadChatMetadata(Database db, int postId) async
{
  final List<Map<String, dynamic>> maps =
     await db.rawQuery(sql.selectChatStatusItem, [postId]);

  return List.generate(maps.length, (i)
  {
     final String str = maps[i]['last_chat_item'];
     ChatItem lastChatItem = ChatItem();
     if (str.isNotEmpty)
         lastChatItem = ChatItem.fromJson(jsonDecode(str));

     return ChatMetadata(
        peer: maps[i]['user_id'],
        nick: maps[i]['nick'],
        date: maps[i]['date'],
        pinDate: maps[i]['pin_date'],
        chatLength: maps[i]['chat_length'],
        nUnreadMsgs: maps[i]['n_unread_msgs'],
        lastChatItem: lastChatItem,
     );
  });
}

List<dynamic> makeChatUpdateSql(ChatMetadata chat, int postId)
{
   final String payload = jsonEncode(chat.lastChatItem);

   return <dynamic>
   [ postId
   , chat.peer
   , chat.date
   , chat.pinDate
   , chat.nick
   , chat.chatLength
   , chat.nUnreadMsgs
   , payload
   ];
}

