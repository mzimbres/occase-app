import 'dart:async' show Future, Timer;
import 'dart:io';
import 'dart:convert';
import 'dart:collection';
import 'package:path/path.dart' as p;

import 'package:sqflite/sqflite.dart';
import 'package:occase/sql.dart' as sql;
import 'package:occase/post.dart';
import 'package:occase/constants.dart' as cts;
import 'package:occase/globals.dart' as g;

class Persistency {
   Database _db;

   Future<Config> loadConfig() async
   {
      //Config cfg = Config();
      //cfg.nick = g.param.unknownNick;
      //return cfg;
      List<Map<String, dynamic>> maps = await _db.rawQuery(sql.readConfig);
      print(maps);
      return Config.fromJson(jsonDecode(maps[0]['cfg']));
   }

   Future<List<Post>> loadPosts() async
   {
      List<Map<String, dynamic>> maps = await _db.rawQuery(sql.loadPosts);

      return List.generate(maps.length, (i)
      {
	 Post post = Post(rangesMinMax: g.param.rangesMinMax);
	 try {
	    post.rowid = maps[i]['rowid'];
	    post.id = maps[i]['id'];
	    post.date = maps[i]['date'];
	    post.pinDate = maps[i]['pin_date'];
	    post.status = maps[i]['status'];

	    final String body = maps[i]['body'];
	    Map<String, dynamic> bodyMap = jsonDecode(body);

	    post.from = bodyMap['from'];
	    post.nick = bodyMap['nick'];
	    post.avatar = bodyMap['avatar'];
	    // TODO: Remove comment after server implementation.
	    //print('------');
	    //post.location = jsonDecode(bodyMap['location'] ?? <int>[]);
	    //print('------');
	    //post.product = jsonDecode(bodyMap['product'] ?? <int>[]);
	    //print('------');
	    //print(post.location);
	    //print(post.product);

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
	 } catch (e) {
	    print('kadjlaalskk  aklsdjf');
	    print(e);
	 }
         return post;
      });
   }

   Future<List<ChatMetadata>> loadChatMetadata(String postId) async
   {
     final List<Map<String, dynamic>> maps =
	await _db.rawQuery(sql.selectChatStatusItem, [postId]);

     return List.generate(maps.length, (i)
     {
	return ChatMetadata(
	   peer: maps[i]['user_id'],
	   nick: maps[i]['nick'],
	   avatar: maps[i]['avatar'],
	   date: maps[i]['date'],
	   pinDate: maps[i]['pin_date'],
	   chatLength: maps[i]['chat_length'],
	   nUnreadMsgs: maps[i]['n_unread_msgs'],
	);
     });
   }

   Future<List<AppMsgQueueElem>> loadOutChatMsg() async
   {
     final List<Map<String, dynamic>> maps = await _db.rawQuery(sql.loadOutChats);

     return List.generate(maps.length, (i)
     {
	return AppMsgQueueElem(
	   rowid: maps[i]['rowid'],
	   isChat: maps[i]['is_chat'],
	   payload: maps[i]['payload'],
	   sent: false);
     });
   }

   Future<void> delFavPost(List<Post> post, int i) async
   {
      await _db.execute(sql.delPostWithId, [post[i].id]);
   }

   Future<void> delOwnPost(List<Post> post, int i) async
   {
      await _db.execute(sql.delPostWithId, [post[i].id]);
   }

   Future<void> updateNUnreadMsgs(String postId, String peer) async
   {
      await _db.rawUpdate(sql.updateNUnreadMsgs, [0, postId, peer]);
   }

   Future<int> insertPost(List<Post> posts, int i, bool isFav) async
   {
      return
	 await _db.insert('posts',
	                  postToMap(posts[i]),
			  conflictAlgorithm: ConflictAlgorithm.replace);
   }

   Future<void> updatePostPinDate(int pinDate, String postId) async
   {
      await _db.execute(sql.updatePostPinDate, [pinDate, postId]);
   }

   Future<List<ChatItem>> loadChatMsgs(String postId, String userId) async
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

   Future<void> insertChatMsg(String postId, String peer, ChatItem ci) async
   {
      await _db.insert(
	 'chats',
	 makeChatItemToMap(postId, peer, ci),
	 conflictAlgorithm: ConflictAlgorithm.replace,
      );
   }

   Future<void> insertChatOnPost(String postId, ChatMetadata cm) async
   {
      await _db.rawInsert(sql.insertOrReplaceChatOnPost, makeChatMetadataSql(cm, postId));
   }

   Future<void> _onCreateDb(Database a, int version) async
   {
      Config cfg = Config();
      cfg.nick = g.param.unknownNick;
      final String str = jsonEncode(cfg.toJson());

      Batch batch = a.batch();
      a.execute(sql.createPostsTable);
      a.execute(sql.createConfig);
      a.execute(sql.createChats);
      a.execute(sql.createChatStatus);
      a.execute(sql.creatOutChatTable);
      final int oooo = await a.rawInsert(sql.insertConfig, [str]);
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

   Future<int> deleteChatStElem(String postId, String peer) async
   {
      return await _db.rawDelete(sql.deleteChatStElem, [postId, peer]);
   }

   Future<void> persistConfig(Config cfg) async
   {
      final String str = jsonEncode(cfg.toJson());
      await _db.execute(sql.updateConfig, [str, 1]);
   }

   Future<void> insertChatOnPost2(String postId, ChatMetadata cm) async
   {
      await _db.rawInsert(sql.insertChatStOnPost, makeChatMetadataSql(cm, postId));
   }

   Future<void> insertChatOnPost3(
      String postId,
      ChatMetadata chat,
      String peer,
      ChatItem ci,
      bool isFav,
      List<Post> posts,
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

         await batch.commit(
            noResult: false,
            continueOnError: true,
         );
      });
   }

   Future<void> updateAckStatus(
      int status,
      int rowid,
      String postId,
      String from,
   ) async {
      Batch batch = _db.batch();
      batch.rawUpdate(sql.updateAckStatus, [status, rowid]);
      await batch.commit(noResult: true, continueOnError: true);
   }

   Future<void> deleteOutChatMsg(int rowid) async
   {
      await _db.rawDelete(sql.deleteOutChatMsg, [rowid]);
   }

   void persistFavPosts(List<Post> posts)
   {
   }

   void persistOwnPosts(List<Post> posts)
   {
   }
}

