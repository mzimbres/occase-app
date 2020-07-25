import 'dart:async' show Future, Timer;
import 'dart:html' show window;
import 'dart:convert';
import 'dart:collection';

import 'package:sqflite/sqflite.dart';
import 'package:occase/post.dart';
import 'package:occase/constants.dart' as cts;
import 'package:occase/globals.dart' as g;

class Persistency {
   int chatRowId = 0;
   List<Post> _posts = List<Post>();
   Config _config = Config(nick: g.param.unknownNick);

   static const String _configKey = 'config';
   static const String _postsKey = 'posts';

   Future<void> _persistPosts() async
   {
      final String str = jsonEncode(_posts);
      window.localStorage[_postsKey] = str;
   }

   Future<void> _persistConfig(Config c) async
   {
      final String str = jsonEncode(_config.toJson());
      window.localStorage[_configKey] = str;
   }

   Future<Config> loadConfig() async
   {
      // TODO: Implement a clone method.
      final String str = window.localStorage[_configKey];
      if (str != null)
	 _config = Config.fromJson(jsonDecode(str));

      return _config;
   }

   Future<List<Post>> loadPosts(List<int> rangesMinMax) async
   {
      _posts.clear();

      final String str = window.localStorage[_postsKey];
      print(str);
      if (str != null) {
	 var l = jsonDecode(str);
	 l.forEach((v) => _posts.add(Post.fromJson(v, g.param.rangeDivs.length)));
      }

      return List<Post>.from(_posts);
   }

   Future<void> setDialogPreferences(int i, bool v) async
   {
      _config.dialogPreferences[i] = v;
      await _persistConfig(Config());
   }

   Future<List<ChatMetadata>> loadChatMetadata(int postId) async
   {
      return List<ChatMetadata>();
   }

   Future<List<AppMsgQueueElem>> loadOutChatMsg() async
   {
      return List<AppMsgQueueElem>();
   }

   Future<void> clearPosts() async
   {
      _posts.clear();
      await _persistPosts();
   }

   Future<void> delPostWithId(int id) async
   {
   }

   Future<void> updateNUnreadMsgs(int postId, String peer) async
   {
   }

   Future<int> insertPost(Post post, ConflictAlgorithm v) async
   {
      final int i = _posts.length;
      _posts.add(post); // TODO: Handle conflict?
      await _persistPosts();
      return i;
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

   Future<void> updateNick(String nick) async
   {
      if (nick != null) {
	 _config.nick = nick;
	 await _persistConfig(Config());
      }
   }

   Future<void> updateConfig(Config c) async
   {
      _config = c;
      await _persistConfig(Config());
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

