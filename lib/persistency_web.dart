import 'dart:async' show Future, Timer;
import 'dart:html' show window;
import 'dart:convert';
import 'dart:collection';

import 'package:sqflite/sqflite.dart';
import 'package:occase/post.dart';
import 'package:occase/constants.dart' as cts;
import 'package:occase/globals.dart' as g;

class Persistency {
   static const String _configKey = 'config';
   static const String _ownPostsKey = 'ownPosts';
   static const String _favPostsKey = 'favPosts';

   void _persistPosts(List<Post> posts, String key)
   {
      final String str = jsonEncode(posts);
      window.localStorage[key] = str;
   }

   Future<void> persistConfig(Config c) async
   {
      final String str = jsonEncode(c.toJson());
      window.localStorage[_configKey] = str;
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
      print('-------------------');
      print(str);
      print('-------------------');
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

   Future<List<ChatMetadata>> loadChatMetadata(int postId) async
   {
      // NOOP
      return <ChatMetadata>[];
   }

   Future<List<AppMsgQueueElem>> loadOutChatMsg() async
   {
      return List<AppMsgQueueElem>();
   }

   Future<void> delFavPost(List<Post> posts, int i) async
   {
      _persistPosts(posts, _favPostsKey);
   }

   Future<void> delOwnPost(List<Post> posts, int i) async
   {
      _persistPosts(posts, _ownPostsKey);
   }

   Future<void> updateNUnreadMsgs(int postId, String peer) async
   {
   }

   Future<void> insertPost(List<Post> posts, int i) async
   {
      _persistPosts(posts, _favPostsKey);
   }

   Future<void> updatePostPinDate(int pinDate, int postId) async
   {
      // NOOP
   }

   Future<List<ChatItem>> loadChatMsgs(int postId, String userId) async
   {
      // This function should not be called in web persistency.
      //assert(false);
      return List<ChatItem>();
   }

   Future<int> insertOutChatMsg(int isChat, String payload) async
   {
      return 0;
   }

   Future<void> insertChatMsg(int postId, String peer, ChatItem ci) async
   {
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

   Future<void> insertChatOnPost2(int postId, ChatMetadata cm) async
   {
      // NOOP
   }

   Future<void> insertChatOnPost3(
      int postId,
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

   void persistFavPosts(List<Post> posts)
   {
      _persistPosts(posts, _favPostsKey);
   }

   void persistOwnPosts(List<Post> posts)
   {
      _persistPosts(posts, _ownPostsKey);
   }
}

