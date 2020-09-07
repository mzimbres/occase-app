import 'dart:async' show Future, Timer;
import 'dart:html' show window, BroadcastChannel;
import 'dart:convert';
import 'dart:collection';
import 'dart:developer';

import 'package:sqflite/sqflite.dart';
import 'package:occase/post.dart';
import 'package:occase/constants.dart' as cts;
import 'package:occase/globals.dart' as g;

class Persistency {
   static const String _configKey =   'config';
   static const String _ownPostsKey = 'ownPosts';
   static const String _favPostsKey = 'favPosts';
   static const String _msgQueueKey = 'msgQueueKey';

   BroadcastChannel _crossTabWriteDetector = BroadcastChannel('_configKey');

   Persistency(Function onCrossTab)
   {
      _crossTabWriteDetector.onMessage.listen(
	 onCrossTab,
	 onError: (var err) {print(err);},
	 onDone: () {print('End');},
      );
   }

   void _persistMsgQueue(List<AppMsgQueueElem> msgQueue)
   {
      final String str = jsonEncode(msgQueue);
      window.localStorage[_msgQueueKey] = str;
      _crossTabWriteDetector.postMessage('');
   }

   void _persistPosts(List<Post> posts, String key)
   {
      final String str = jsonEncode(posts);
      window.localStorage[key] = str;
      _crossTabWriteDetector.postMessage('');
   }

   Future<void> persistConfig(Config c) async
   {
      final String str = jsonEncode(c.toJson());
      window.localStorage[_configKey] = str;
      _crossTabWriteDetector.postMessage('');
   }

   Future<Config> loadConfig() async
   {
      final String str = window.localStorage[_configKey];
      if (str != null)
	 return Config.fromJson(jsonDecode(str));

      return Config(nick: g.param.unknownNick);
   }

   List<Post> _loadPostsImpl(String key)
   {
      List<Post> posts = <Post>[];

      final String str = window.localStorage[key];
      if (str != null) {
	 var l = jsonDecode(str);
	 l.forEach((v) => posts.add(Post.fromJson(v, g.param.rangeDivs.length)));
      }

      return posts;
   }

   Future<List<Post>> loadPosts() async
   {
      List<Post> posts = <Post>[];
      posts.addAll(_loadPostsImpl(_ownPostsKey));
      posts.addAll(_loadPostsImpl(_favPostsKey));
      return posts;
   }

   Future<List<ChatMetadata>> loadChatMetadata(String postId) async
   {
      // NOOP
      return <ChatMetadata>[];
   }

   Future<List<AppMsgQueueElem>> loadOutChatMsg() async
   {
      List<AppMsgQueueElem> msgs = <AppMsgQueueElem>[];

      final String str = window.localStorage[_msgQueueKey];
      if (str != null) {
	 var m = jsonDecode(str);
	 m.forEach((v) => msgs.add(AppMsgQueueElem.fromJson(v)));
      }

      return msgs;
   }

   Future<void> delFavPost(List<Post> posts, int i) async
   {
      _persistPosts(posts, _favPostsKey);
   }

   Future<void> delOwnPost(List<Post> posts, int i) async
   {
      _persistPosts(posts, _ownPostsKey);
   }

   Future<void> updateNUnreadMsgs({
      bool isFav,
      String postId,
      String peer,
      List<Post> posts,
   }) async {
      final String key = isFav ? _favPostsKey : _ownPostsKey;
      _persistPosts(posts, key);
   }

   Future<void> insertPost(List<Post> posts, int i, bool isFav) async
   {
      final String key = isFav ? _favPostsKey : _ownPostsKey;
      _persistPosts(posts, key);
   }

   Future<void> updatePostPinDate(int pinDate, String postId) async
   {
      // NOOP
   }

   Future<List<ChatItem>> loadChatMsgs(String postId, String userId) async
   {
      // This function should not be called in web persistency.
      //assert(false);
      return List<ChatItem>();
   }

   Future<int> insertOutChatMsg(Queue<AppMsgQueueElem> q) async
   {
      _persistMsgQueue(q.toList());
      return 0;
   }

   Future<void> insertChatMsg(String postId, String peer, ChatItem ci) async
   {
   }

   Future<void> insertChatOnPost(String postId, ChatMetadata cm) async
   {
   }

   Future<void> _onCreateDb(Database a, int version) async
   {
   }

   Future<void> open() async
   {
   }

   Future<int> deleteChatStElem(String postId, String peer) async
   {
      return 1;
   }

   Future<void> insertChatOnPost2(String postId, ChatMetadata cm) async
   {
      // NOOP
   }

   Future<void> insertChatOnPost3(
      String postId,
      ChatMetadata chat,
      String peer,
      ChatItem ci,
      bool isFav,
      List<Post> posts,
   ) async {
      String s = isFav ? _favPostsKey : _ownPostsKey;
      _persistPosts(posts, s);
   }

   Future<void> updateAckStatus(
      int status,
      int rowid,
      String postId,
      String from,
   ) async {
   }

   Future<void> deleteOutChatMsg(Queue<AppMsgQueueElem> appMsgQueue) async
   {
   }

   void persistFavPosts(List<Post> posts)
   {
      _persistPosts(posts, _favPostsKey);
   }

   void persistOwnPosts(List<Post> posts)
   {
      _persistPosts(posts, _ownPostsKey);
   }
}

