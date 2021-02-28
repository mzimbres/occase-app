import 'dart:convert';
import 'dart:async' show Future;
import 'package:meta/meta.dart';
import 'package:occase/globals.dart' as g;
import 'package:occase/tree.dart' as tree;
import 'package:occase/sql.dart' as sql;
import 'package:occase/constants.dart' as cts;
import 'package:sqflite/sqflite.dart';
import 'dart:developer';

class AppMsgQueueElem {
   int rowid;
   int isChat;
   String payload;

   AppMsgQueueElem({
      this.rowid = 0,
      this.isChat = 0,
      this.payload = '',
   });

   AppMsgQueueElem.fromJson(Map<String, dynamic> map)
   {
      rowid = map['rowid'] ?? -1;
      isChat = map['is_chat'] ?? false;
      payload = map['payload'] ?? '';
   }

   Map<String, dynamic> toJson()
   {
      return
      { 'rowid': rowid
      , 'is_chat': isChat
      , 'payload': payload
      };
   }
}

class ChatItem {
   // This field is -1 if the message belongs to this app or the peer id
   // if it belongs to the peer.
   int peerId = -1;

   // If the message is redirected, be it from this app or from the peer, this
   // field will be set to 1.
   int isRedirected = 0;

   // A value different from -1 means this message refers to another
   // message.
   int refersTo;

   // When the message is from this app, we show the icon informing
   //
   // 0: Message didn't reach the server yet.
   // 1: Server has received the message.
   // 2: Peer has received the message.
   // 3: Peer has read the message.
   //
   // This field is only meaningful when the message belongs to this app.
   int status;

   // The chat message.
   String body = '';

   // The date where the message was sent or received.
   int date = 0;

   bool isLongPressed;

   ChatItem(
   { this.peerId = -1
   , this.isRedirected = 0
   , this.refersTo = -1
   , this.status = 0
   , this.isLongPressed = false
   , this.body = ''
   , this.date = 0
   });

   bool redirected()
   {
      return isRedirected != 0;
   }

   bool isFromThisApp()
   {
      return peerId == -1;
   }

   bool refersToOther()
   {
      return refersTo != -1;
   }

   // Used only by ChatMetadata to store the last chat message that is shown
   // without requiring load of all messages.
   ChatItem.fromJson(Map<String, dynamic> map)
   {
      peerId = map["peer_id"] ?? -1;
      refersTo = map['refers_to'] ?? -1;
      status = map['status'] ?? 3;
      isRedirected = map['is_redirected'] ?? 0;
      body = map['body'] ?? '';
      date = map['date'] ?? 0;
      isLongPressed = false;
   }

   Map<String, dynamic> toJson()
   {
      return
      { 'peer_id': peerId
      , 'refers_to': refersTo
      , 'status': status
      , 'is_redirected': isRedirected
      , 'body': body
      , 'date': date
      };
   }
}

List<ChatItem> decChatItemList(List<dynamic> list)
{
   if (list == null)
      return null;

   return List.generate(list.length, (int i) { return ChatItem.fromJson(list[i]);});
}

// To be able to ack unread chat messages as the user clicks on the chat,
// we need the peer rowids.
List<int> makeAckIds(
   final int size,
   final int n,
) {
   if (n > size)
      return <int>[];
   
   List<int> res = List<int>();
   for (int i = n; i < size; ++i)
      res.add(i);

   return res;
}

Map<String, dynamic> makeChatItemToMap(
   String postId,
   String userId,
   ChatItem ci,
) {
    return
    { 'post_id': postId
    , 'user_id': userId
    , 'peer_id': ci.peerId
    , 'is_redirected': ci.isRedirected
    , 'refers_to': ci.refersTo
    , 'status': ci.refersTo
    , 'date': ci.date
    , 'body': ci.body
    };
}

class ChatMetadata {
   String peer;
   String nick;
   String avatar;

   // The date the chat has been selected to fav.
   int date;
   int pinDate;
   int nUnreadMsgs;

   List<ChatItem> msgs = <ChatItem>[];

   // The number of unread messages shown in the new msgs divisor shown
   // in the chat screen when one enters it and threre were unread
   // msgs in the chat.
   int divisorUnreadMsgs;

   // The index where the divisor above shall be shown.
   int divisorUnreadMsgsIdx;

   // The timestamps of the last time we sent a presence-writing message to the
   // peer.
   int lastPresenceSent;

   // The timestamp from the last presence message received from the peer.
   int lastPresenceReceived;
   bool isLongPressed;

   int getLastChatMsgDate()
   {
      if (msgs.isEmpty)
	 return 0;

      return msgs.last.date;
   }

   int getLastChatMsgStatus()
   {
      if (msgs.isEmpty)
	 return -1;

      return msgs.last.status;
   }

   String getLastChatMsg()
   {
      if (msgs.isEmpty)
	 return '';

      return msgs.last.body;
   }

   bool isLastChatMsgFromThisApp()
   {
      if (msgs.isEmpty)
	 return false;

      return msgs.last.isFromThisApp();
   }

   int getMostRecentChatDate()
   {
      if (msgs.isEmpty)
	 return date;

      return msgs.last.date;
   }

   ChatMetadata(
   { this.peer = ''
   , this.nick = ''
   , this.avatar = ''
   , this.date = 0
   , this.pinDate = 0
   , this.nUnreadMsgs = 0
   , this.isLongPressed = false
   , this.lastPresenceSent = 0
   , this.lastPresenceReceived = 0
   }) {
      divisorUnreadMsgs = nUnreadMsgs;
      divisorUnreadMsgsIdx = msgs.length - nUnreadMsgs;
      assert(divisorUnreadMsgsIdx >= 0);
   }

   int addChatItem(ChatItem ci)
   {
      msgs.add(ci);
      return msgs.length - 1;
   }

   void setAckStatus(int i, int status)
   {
      if (i < msgs.length)
	 msgs[i].status = status;
      else
	 log('Error: Index $i does not belong in the array.');
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

   ChatMetadata.fromJson(Map<String, dynamic> map)
   {
      peer = map["peer"];
      nick = map["nick"];
      avatar = map["avatar"];
      date = map["date"];
      pinDate = map["pinDate"];
      nUnreadMsgs = map["nUnreadMsgs"];
      msgs = decChatItemList(map["msgs"]);

      isLongPressed = false;
      divisorUnreadMsgs = nUnreadMsgs;
      divisorUnreadMsgsIdx = msgs.length - nUnreadMsgs;
      lastPresenceSent = 0;
      lastPresenceReceived = 0;
   }

   Map<String, dynamic> toJson()
   {
      return
      { 'peer': peer
      , 'nick': nick
      , 'avatar': avatar
      , 'date':   date
      , 'pinDate': pinDate
      , 'nUnreadMsgs': nUnreadMsgs
      , 'msgs': msgs,
      //, 'isLongPressed': isLongPressed
      //, 'divisorUnreadMsgs': divisorUnreadMsgs
      //, 'divisorUnreadMsgsIdx': divisorUnreadMsgsIdx
      //, 'lastPresenceSent': lastPresenceSent
      //, 'lastPresenceReceived': lastPresenceReceived
      };
   }
}

/* Chat sorting criteria
 *
 * (applies to chats belonging to the same post)
 *
 * 1. A pined chat always wins, even if it contains no messages. The
 *    need to sort chats that contain no messages however won't happen.  In
 *    favPosts there will only be one chat and in _ownPosts they will always
 *    contain messages.
 *
 * 2. If two chats are pined, the one with the most recent date wins.
 *    The date to be used is the date of the last chat message. Again,
 *    two or more chats with no message won't happen as said above.
 *
 * FIXME: Chats may contain empty messages if they are a reply to
 *        other messages. The function bellow has to be adapted to
 *        such cases.
 */
int compChatByMsg(final ChatMetadata lhs, final ChatMetadata rhs)
{
   if (lhs.msgs.isEmpty && rhs.msgs.isEmpty)
      return lhs.date > rhs.date ? -1
           : lhs.date < rhs.date ? 1 : 0;

   if (lhs.msgs.isEmpty)
      return 1;

   if (rhs.msgs.isEmpty)
      return -1;

   if (lhs.msgs.last.body.isEmpty && rhs.msgs.last.body.isEmpty)
      return lhs.date > rhs.date ? -1
           : lhs.date < rhs.date ? 1 : 0;

   if (lhs.msgs.last.body.isEmpty)
      return 1;

   if (rhs.msgs.last.body.isEmpty)
      return -1;

   return lhs.msgs.last.date > rhs.msgs.last.date ? -1
        : lhs.msgs.last.date < rhs.msgs.last.date ? 1 : 0;
}

int compChats(final ChatMetadata lhs, final ChatMetadata rhs)
{
   if (lhs.pinDate != 0 && rhs.pinDate != 0)
      return lhs.pinDate > rhs.pinDate ? -1
           : lhs.pinDate < rhs.pinDate ? 1 : 0;

   if (lhs.pinDate == 0)
      return 1;

   if (rhs.pinDate == 0)
      return -1;

   return compChatByMsg(lhs, rhs);
}

ChatMetadata selectMostRecentChat(
   final ChatMetadata lhs,
   final ChatMetadata rhs
) {
   final int t1 = lhs.getMostRecentChatDate();
   final int t2 = rhs.getMostRecentChatDate();

   return t1 >= t2 ? lhs : rhs;
}

int compPostByDate(Post a, Post b)
{
   return a.date > b.date ? -1
	: a.date < b.date ? 1 : 0;
}

List<T> decodeList<T>(int size, T init, List<dynamic> details)
{
   if (details == null) {
      log('Value not found.');
      return List.filled(size, init);
   }

   return List.generate(details.length, (int i) { return details[i]; });
}

List<ChatMetadata> decChatMetadataList(List<dynamic> list)
{
   if (list == null)
      return <ChatMetadata>[];

   return List.generate(list.length, (int i) { return ChatMetadata.fromJson(list[i]);});
}

class Post {
   // The auto increment sqlite rowid.
   int rowid;

   // The publication date.
   int date;

   // The date this post has been pinned by the user.
   int pinDate;

   // Post status.
   //   0: Posts published by the app.
   //   1: Posts received
   //   2: Posts moved to favorites.
   int status;

   // The post priority. Paid posts get higher priority.
   int priority = 0;

   // The number of times this post appeared on searches.
   int onSearch = 0;

   // The number of visualizations this post had so far.
   int visualizations = 0;

   // The number of detailed visualizations this post had.
   int clicks = 0;

   // Post id received from on publish ack from the server.
   String id;

   // Post publisher id.
   String from;

   // Publisher nickname.
   String nick;

   // Publisher avatar hash code from gravatar.
   String avatar;

   // The string *description* inputed when user writes an post.
   String description;

   // The user email
   String email;

   // Location tree code.
   List<int> location = <int>[];

   // Product tree code.
   List<int> product = <int>[];

   // Each element is an index in an array of exclusive details.
   List<int> exDetails;

   // Integers containing which elements have been selected.
   List<int> inDetails;

   List<int> rangeValues;

   // Post image url's.
   List<String> images;

   // The chats that belongs to this post.
   List<ChatMetadata> chats = List<ChatMetadata>();

   static List<int> initExDetails = <int>[1, 1, 2, 1, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1];
   static List<int> initInDetails = <int>[1, 1, 1, 1, 2049, 1, 4, 15, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0];

   Post(
   { this.rowid = -1
   , this.id = ''
   , this.from = ''
   , this.nick = ''
   , this.avatar = ''
   , this.date = 0
   , this.pinDate = 0
   , this.status = -1
   , this.description = ''
   , this.email = ''
   , this.images = const <String>[]
   , @required List<int> rangesMinMax // g.param.rangesMinMax
   })
   {
      final int rangeDivsLength = rangesMinMax.length >> 1;
      exDetails = initExDetails;
      inDetails = initExDetails;
      rangeValues = List.generate(rangeDivsLength, (int i) {
         return rangesMinMax[2 * i];
      });

      location = <int>[3, 1, 0, 0];
      product = <int>[0, 0, 0];
      chats = List<ChatMetadata>();
   }

   void reset()
   {
      images = List<String>();
      exDetails = initExDetails;
      inDetails = initInDetails;

      final int l = g.param.rangesMinMax.length >> 1;
      rangeValues = List.generate(l, (int i) { return g.param.rangesMinMax[2 * i]; });
   }

   int getPrice()
      { return rangeValues[0]; }

   int getProductDetailIdx()
   {
      if (product.isEmpty)
	 return -1;

      return product[0];
   }

   Post clone()
   {
      Post ret = Post(rangesMinMax: <int>[]);
      ret.rowid = -1;
      ret.id = this.id;
      ret.from = this.from;
      ret.nick = this.nick;
      ret.avatar = this.avatar;
      ret.location = List<int>.from(this.location);
      ret.product = List<int>.from(this.product);
      ret.exDetails = this.exDetails;
      ret.inDetails = this.inDetails;
      ret.date = this.date;
      ret.pinDate = this.pinDate;
      ret.rangeValues = List<int>.from(this.rangeValues);
      ret.status = this.status;
      ret.priority = this.priority;
      ret.onSearch = this.onSearch;
      ret.visualizations = this.visualizations;
      ret.clicks = this.clicks;
      ret.description = this.description;
      ret.email = this.email;
      ret.images = List<String>.from(this.images);
      ret.chats = List<ChatMetadata>.from(this.chats);
      return ret;
   }

   int addChat(String peer, String nick, String avatar)
   {
      final int now = DateTime.now().millisecondsSinceEpoch;
      final int l = chats.length;
      chats.add(ChatMetadata(
            peer: peer,
            nick: nick,
            avatar: avatar,
            date: now,
         ),
      );

      return l;
   }

   int getChatMetadataIndex(final String peer)
   {
      return chats.indexWhere((e) {return e.peer == peer;});
   }

   int getChatHistIdxOrCreate(
      final String peer,
      final String nick,
      final String avatar,
   ) {
      final int i = getChatMetadataIndex(peer);
      if (i == -1)
         return addChat(peer, nick, avatar);

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

   // This serialization is used to communicate with the occase-db,
   // not the one used in the sqlite localy.
   Post.fromJson(
      Map<String, dynamic> map,
      int rangeDivsLength, // g.param.rangeDivs.length,
   ) {
      try {
	 rowid = map['rowid'] ?? -1;
	 id = map['id'];
	 from = map['from'];
	 nick = map['nick'] ?? '';
	 avatar = map['avatar'] ?? '';
	 location = decodeList(0, 0, map['location']);
	 product = decodeList(0, 0, map['product']);
	 exDetails = decodeList(cts.maxExDetailSize, 1, map['ex_details']);
	 inDetails = decodeList(cts.maxInDetailSize, 1, map['in_details']);
	 date = map['date'] ?? 0;
	 pinDate = map['pin_date'] ?? 0;
	 rangeValues = decodeList(rangeDivsLength, 0, map['range_values']);
	 status = map['status'] ?? -1;
	 priority = map['priority'] ?? 0;
	 onSearch = map['on_search'] ?? 0;
	 visualizations = map['visualizations'] ?? 0;
	 clicks = map['clicks'] ?? 0;
	 description = map['description'] ?? '';
	 email = map['email'] ?? '';
	 images = decodeList(0, '', map['images']);
	 chats = decChatMetadataList(map['chats']);
      } catch (e) {
	 log('Post.fromJson: ${e}');
      }
   }

   Map<String, dynamic> toJson()
   {
      assert(exDetails.isNotEmpty);
      assert(inDetails.isNotEmpty);

      // NOTE2: The ex- and inDetails arrays are initialized to a size that is
      // bigger than usually needed (see maxExDetailSize and maxInDetailSize).
      // We could spare some space in the json payload by reducing their size
      // to the minimum needed before serialization, this may come with a cost
      // of not being able to provide backwards compatibility if expansion of
      // these fields is required in the future. I think the better strategy is
      // to choose these arrays to have two unused elements.
      //
      // To reduce the size to what is exactly needed one has to first get the
      // product index with *int getProductDetailIdx()* and then the size from
      // txt.exDetailTitles[index].length (or txt.exDetails[index].length) and
      // similar to the inDetails array.

      return
      { 'rowid': rowid
      , 'id': id
      , 'from': from
      , 'nick': nick
      , 'avatar': avatar
      , 'description': description
      , 'email': email
      , 'location': location
      , 'product': product
      , 'ex_details': exDetails
      , 'in_details': inDetails
      , 'date': date
      , 'pin_date': pinDate
      , 'range_values': rangeValues
      , 'status': status
      , 'images': images
      , 'chats': chats
      , 'priority': priority
      , 'on_search': onSearch
      , 'visualizations': visualizations
      , 'clicks': clicks
      };
   }
}

// This serialization is more complete than the toJson member function
// and is used to persist json objects on the database.
//
// NOTE: I believe this will not be needed anymore soon.  
Map<String, dynamic> postToMap(Post post)
{
   // Changing theses fields does not require changes the schema in
   // sqlite.

   var subCmd =
   { 'from': post.from
   , 'nick': post.nick
   , 'avatar': post.avatar
   , 'location': post.location
   , 'product': post.product
   , 'ex_details': jsonEncode(post.exDetails)
   , 'in_details': jsonEncode(post.inDetails)
   , 'range_values': jsonEncode(post.rangeValues)
   , 'description': post.description
   , 'email': post.email
   , 'images': post.images
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

   if (lhs.chats.isEmpty && rhs.chats.isEmpty)
      return lhs.date > rhs.date ? -1
           : lhs.date < rhs.date ? 1 : 0;

   if (lhs.chats.isEmpty)
      return 1;

   if (rhs.chats.isEmpty)
      return -1;

   final ChatMetadata c1 = lhs.chats.reduce(selectMostRecentChat);
   final ChatMetadata c2 = rhs.chats.reduce(selectMostRecentChat);
   return compChatByMsg(c1, c2);
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

IdxPair findChat(final List<Post> posts, String peer, String postId)
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
   final String postId,
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

class NtfConfig {
   bool chat;
   bool post;

   NtfConfig(
   { this.chat = true
   , this.post = true
   });

   int getFlag()
   {
      // If the number of configurations increase we can use flags.
      if (chat && post)
         return 3;

      if (post)
         return 2;

      if (chat)
         return 1;

      return 0;
   }

   NtfConfig.fromJson(Map<String, dynamic> map)
   {
      chat = map["chat"];
      post = map['post'];
   }

   Map<String, dynamic> toJson()
   {
      return
      { 'chat': chat
      , 'post': post
      };
   }
}

class Config {
   String user;
   String key;
   String userId;
   String email;
   String nick;
   List<bool> dialogPreferences = List<bool>.filled(20, true);
   NtfConfig notifications;

   Config({
      this.user = '',
      this.key = '',
      this.userId = '',
      this.email = '',
      this.nick = '',
   })
   {
      notifications = NtfConfig(chat: true, post: true);
      dialogPreferences = List<bool>.filled(20, true);
   }

   Config.fromJson(Map<String, dynamic> map)
   {
      try {
	 user = map['user'] ?? '';
	 key = map['key'] ?? '';
	 userId = map['user_id'] ?? '';
	 email = map['email'] ?? '';
	 nick = map['nick'] ?? '';
	 dialogPreferences = decodeList(20, true, map['dialogPreferences']);
	 notifications = NtfConfig.fromJson(map['notifications']);
      } catch (e) {
	 log('oowoow');
	 log(e);
      }
   }

   Map<String, dynamic> toJson()
   {
      return
      { 'user': user
      , 'key': key
      , 'user_id': userId
      , 'email': email
      , 'nick': nick
      , 'dialogPreferences': dialogPreferences
      , 'notifications': notifications.toJson()
      };
   }
}

List<dynamic> makeChatMetadataSql(ChatMetadata chat, String postId)
{
   return <dynamic>
   [ postId
   , chat.peer
   , chat.date
   , chat.pinDate
   , chat.nick
   , chat.avatar
   , chat.nUnreadMsgs
   ];
}

