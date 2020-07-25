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

   Future<List<Post>> loadPosts(List<int> rangesMinMax) async
   {
      List<Map<String, dynamic>> maps = await _db.rawQuery(sql.loadPosts);

      return List.generate(maps.length, (i)
      {
	 Post post = Post(rangesMinMax: rangesMinMax);
	 try {
	    post.dbId = maps[i]['rowid'];
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

   Future<List<ChatMetadata>> loadChatMetadata(int postId) async
   {
     final List<Map<String, dynamic>> maps =
	await _db.rawQuery(sql.selectChatStatusItem, [postId]);

     return List.generate(maps.length, (i)
     {
	final String str = maps[i]['last_chat_item'];
	ChatItem lastChatItem = ChatItem();
	if (str.isNotEmpty)
	    lastChatItem = ChatItem.fromJson(jsonDecode(str));

	return ChatMetadata(
	   peer: maps[i]['user_id'],
	   nick: maps[i]['nick'],
	   avatar: maps[i]['avatar'],
	   date: maps[i]['date'],
	   pinDate: maps[i]['pin_date'],
	   chatLength: maps[i]['chat_length'],
	   nUnreadMsgs: maps[i]['n_unread_msgs'],
	   lastChatItem: lastChatItem,
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

   Future<void> clearPosts() async
   {
      await _db.execute(sql.clearPosts, [1]);
   }

   Future<void> delPostWithId(int id) async
   {
      await _db.execute(sql.delPostWithId, [id]);
   }

   Future<void> updateNUnreadMsgs(int postId, String peer) async
   {
      await _db.rawUpdate(sql.updateNUnreadMsgs, [0, postId, peer]);
   }

   Future<int> insertPost(Post post, ConflictAlgorithm v) async
   {
      return await _db.insert('posts', postToMap(post), conflictAlgorithm: v);
   }

   Future<void> updatePostPinDate(int pinDate, int postId) async
   {
      await _db.execute(sql.updatePostPinDate, [pinDate, postId]);
   }

   Future<List<ChatItem>> loadChatMsgs(int postId, String userId) async
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

   Future<int> insertChatMsg(int postId, String peer, ChatItem ci) async
   {
      return await _db.insert(
	 'chats',
	 makeChatItemToMap(postId, peer, ci),
	 conflictAlgorithm: ConflictAlgorithm.replace,
      );
   }

   Future<void> insertChatOnPost(int postId, ChatMetadata cm) async
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

   Future<int> deleteChatStElem(int postId, String peer) async
   {
      return await _db.rawDelete(sql.deleteChatStElem, [postId, peer]);
   }

   Future<void> updateConfig(Config cfg) async
   {
      final String str = jsonEncode(cfg.toJson());
      await _db.execute(sql.updateConfig, [str, 1]);
   }

   Future<void> insertChatOnPost2(int postId, ChatMetadata cm) async
   {
      await _db.rawInsert(sql.insertChatStOnPost, makeChatMetadataSql(cm, postId));
   }

   Future<void> insertChatOnPost3(
      int postId,
      ChatMetadata chat,
      String peer,
      ChatItem ci,
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

   Future<void> delPostWithRowid(int dbId) async
   {
      await _db.execute(sql.delPostWithRowid, [dbId]);
   }

   Future<void> updatePostOnAck(int status, int id, int date, int dbId) async
   {
      await _db.execute(sql.updatePostOnAck, [status, id, date, dbId]);
   }

   Future<void> updateAckStatus(
      ChatItem ci,
      int status,
      int rowid,
      int postId,
      String from,
   ) async {
      Batch batch = _db.batch();
      batch.rawUpdate(sql.updateAckStatus, [status, rowid]);
      batch.rawUpdate(sql.updateLastChat, [jsonEncode(ci), postId, from]);
      await batch.commit(noResult: true, continueOnError: true);
   }

   Future<void> deleteOutChatMsg(int rowid) async
   {
      await _db.rawDelete(sql.deleteOutChatMsg, [rowid]);
   }
}

