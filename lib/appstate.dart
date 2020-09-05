import 'dart:async' show Future, Timer;
import 'dart:convert';
import 'dart:io';
import 'dart:collection';
import 'dart:developer';

import 'dart:io'
       if (dart.library.io)
          'package:occase/persistency_app.dart'
       if (dart.library.html)
          'package:occase/persistency_web.dart';

import 'package:sqflite/sqflite.dart';

import 'package:occase/post.dart';
import 'package:occase/constants.dart' as cts;
import 'package:occase/parameters.dart';
import 'package:occase/globals.dart' as g;

class AppState {
   Config cfg = Config();

   // The list of posts received from the server. Our own posts that the
   // server echoes back to us will be filtered out.
   List<Post> _posts = List<Post>();

   // The list of posts the user has selected in the posts screen.
   // They are moved from posts to here.
   List<Post> favPosts = List<Post>();

   // Posts the user wrote itself and sent to the server. One issue we have to
   // observe is that if the post is received back it shouldn't be displayed
   // or duplicated on this list. The posts received from the server will not
   // be inserted in posts.
   //
   // The only posts inserted here are those that have been acked with
   // ok by the server, before that they will live in outPost.
   List<Post> ownPosts = List<Post>();

   // Posts sent to the server that haven't been acked yet. At the
   // moment this queue will contain only one element. It is needed if
   // to handle the case where we go offline between a publish and a
   // publish_ack.
   Post outPost = Post(rangesMinMax: g.param.rangesMinMax);

   // Stores chat messages that cannot be lost in case the connection
   // to the server is lost. 
   Queue<AppMsgQueueElem> appMsgQueue = Queue<AppMsgQueueElem>();

   Persistency _persistency;

   List<Post> get posts => _posts;

   void clearState()
   {
      cfg = Config();
      _posts = List<Post>();
      favPosts = List<Post>();
      ownPosts = List<Post>();
      outPost = Post(rangesMinMax: g.param.rangesMinMax);
      appMsgQueue = Queue<AppMsgQueueElem>();
   }

   AppState(Function onCrossTab)
   {
      _persistency = Persistency(onCrossTab);
   }

   Future<void> load() async
   {
      clearState();
      try {
	 await _persistency.open();
      } catch (e) {
         log(e);
      }

      try {
         // Warning: The construction of Config depends on the
         // parameters that have been load above, but where not loaded
         // by the time it was inititalized. Ideally we would remove
         // the use of global variable from within its constructor,
         // for now I will construct it again before it is used to
         // initialize the db.
	 cfg = await _persistency.loadConfig();
      } catch (e) {
         log(e);
      }

      try {
         final List<Post> posts = await _persistency.loadPosts();
         for (Post p in posts) {
            if (p.status == 0) {
               ownPosts.add(p);
               for (Post o in ownPosts) {
		  if (o.chats.isEmpty)
		     o.chats = await _persistency.loadChatMetadata(o.id);
	       }
            } else if (p.status == 2) {
               favPosts.add(p);
               for (Post o in favPosts)
		  if (o.chats.isEmpty)
		     o.chats = await _persistency.loadChatMetadata(o.id);
            } else {
	       log('Wrong post status ${p.status}');
            }
         }

         ownPosts.sort(compPosts);
         favPosts.sort(compPosts);
      } catch (e) {
         log(e);
      }

      List<AppMsgQueueElem> tmp = await _persistency.loadOutChatMsg();
      appMsgQueue = Queue<AppMsgQueueElem>.from(tmp.reversed);
   }

   Future<void> clearPosts() async
   {
      _posts = List<Post>();
   }

   Future<void> setDialogPreferences(int i, bool v) async
   {
      cfg.dialogPreferences[i] = v;
      await _persistency.persistConfig(cfg);
   }

   Future<void> updateConfig() async
   {
      await _persistency.persistConfig(cfg);
   }

   // Return the index where the post in located in favPosts.
   Future<int> movePostToFav(int i) async
   {
      // i refers to a post in the posts array. 
      Post post = _posts[i];

      // Remove from the posts array so that the user does not see it anymore?
      _posts.removeAt(i);

      var f = (e) { return e.id == post.id; };

      // We have to prevent the user from adding a chat twice. This can happen
      // when he makes a new search.
      int j = favPosts.indexWhere(f);
      if (j == -1) { // The post is already in favorites?
	 post.status = 2; // fav status.
	 final int k = post.addChat(post.from, post.nick, post.avatar);
	 await _persistency.insertChatOnPost2(post.id, post.chats[k]);
	 favPosts.add(post);
	 favPosts.sort(compPosts);
	 j = favPosts.indexWhere(f);
	 assert(j != -1);
	 await _persistency.insertPost(favPosts, j, true);
      }

      return j;
   }

   Future<void> setChatAckStatus({
      String from,
      String postId,
      List<int> ackIds,
      int status,
   }) async {
      List<Post> list = favPosts;
      IdxPair p = findChat(list, from, postId);
      if (IsInvalidPair(p)) {
	 list = ownPosts;
	 p = findChat(ownPosts, from, postId);
      }

      if (IsInvalidPair(p)) {
	 log('Chat not found: from = $from, postId = $postId');
	 return;
      }

      for (int rowid in ackIds) {
	 list[p.i].chats[p.j].setAckStatus(rowid, status);

	 // Typically there won't be many ackIds in this loop so it is fine to
	 // use await here. The ideal case however is to offer a List<ChatItem>
	 // interface in Persistency and use batch there.

	 await _persistency.updateAckStatus(status, rowid, postId, from);
      }
   }

   Future<void> setCredentials(String user, String key, String userId) async
   {
      cfg.user = user;
      cfg.key = key;
      cfg.userId = userId;

      await _persistency.persistConfig(cfg);
   }

   Future<int>
   setChatMessage(String postId, String peer, ChatItem ci, bool fav) async
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

      await _persistency.insertChatMsg(postId, peer, ci);
      final int id = post.chats[j].addChatItem(ci);

      await _persistency.insertChatOnPost(postId, post.chats[j]);

      post.chats.sort(compChats);
      list.sort(compPosts);
      if (fav)
	 _persistency.persistFavPosts(favPosts);
      else
	 _persistency.persistFavPosts(ownPosts);

      return id;
   }

   Future<void> setNUnreadMsgs(String id, String from) async
   {
      await _persistency.updateNUnreadMsgs(id, from);
   }

   Future<void> setPinPostDate(int i, bool fav) async
   {
      List<Post> list = ownPosts;
      if (fav)
	 list = favPosts;

      Post post = list[i];
      await _persistency.updatePostPinDate(post.pinDate, post.id);
      post.pinDate = post.pinDate == 0 ? DateTime.now().millisecondsSinceEpoch : 0;
      list.sort(compPosts);
   }

   Future<int> deleteChatStElem(String post_id, String peer) async
   {
      return await _persistency.deleteChatStElem(post_id, peer);
   }

   Future<void> addOwnPost(String id, int date) async
   {
      outPost.id = id;
      outPost.date = date;
      outPost.status = 0;
      outPost.pinDate = 0;
      final int i = ownPosts.length;
      ownPosts.add(outPost);
      await _persistency.insertPost(ownPosts, i, false);
      ownPosts.sort(compPosts);
   }

   Future<Post> delFavPost(int i) async
   {
      await _persistency.delFavPost(favPosts, i);
      return favPosts.removeAt(i);
   }

   Future<Post> delOwnPost(int i) async
   {
      final Post post = ownPosts.removeAt(i);
      await _persistency.delOwnPost(ownPosts, i);
      return post;
   }

   Post delSearchPost(int i)
   {
      return _posts.removeAt(i);
   }

   Future<void> removeFavWithNoChats() async
   {
      // If performance becomes a thing, we should call persistency only once.
      for (int i = 0; i < favPosts.length; ++i)
	 if (favPosts[i].chats.isEmpty)
	    await _persistency.delFavPost(favPosts, i);

      favPosts.removeWhere((e) { return e.chats.isEmpty; });
   }

   Future<void> insertChatOnPost3(
      String postId,
      ChatMetadata chat,
      String peer,
      ChatItem ci,
      bool isFav,
   ) async {
      List<Post> posts = isFav ? favPosts : ownPosts;
      await _persistency.insertChatOnPost3(postId, chat, peer, ci, isFav, posts);
   }

   Future<void> insertOutChatMsg(String payload, int isChat) async
   {
      final bool isEmpty = appMsgQueue.isEmpty;

      AppMsgQueueElem tmp = AppMsgQueueElem(
         rowid: -1,
         isChat: isChat,
         payload: payload,
      );

      appMsgQueue.add(tmp);

      tmp.rowid = await _persistency.insertOutChatMsg(appMsgQueue);
   }

   Future<bool> deleteOutChatMsg() async
   {
      final AppMsgQueueElem e = appMsgQueue.removeFirst();
      await _persistency.deleteOutChatMsg(appMsgQueue);
      return e.isChat == 1;
   }
}

