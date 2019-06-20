import 'dart:convert';
import 'dart:io' show File, FileMode, Directory;
import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:menu_chat/constants.dart';
import 'package:menu_chat/menu_tree.dart';
import 'package:menu_chat/menu.dart';
import 'package:menu_chat/text_constants.dart' as cts;
import 'package:menu_chat/globals.dart' as glob;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

void writeToFile( final String data
                , final String fullPath
                , final FileMode mode)
{
   try {
      File(fullPath).writeAsStringSync(data, mode: mode);
   } catch (e) {
   }
}

String serializeList<T>(final List<T> data)
{
   String content = '';
   for (T o in data) {
      final String postStr = jsonEncode(o);
      content += '$postStr\n';
   }

   return content;
}

void writeListToDisk<T>( final List<T> data, final String fullPath
                       , FileMode mode)
{
   final String content = serializeList(data);

   // TODO: Limit the size of this file to a given size. When
   // this happens it may be easier to always overwrite the file
   // contents.
   writeToFile(content, fullPath, mode);
}

int cmdToChatStatus(final String cmd)
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

   void setStatus(final String st)
   {
      // This check is just in case some messages come out of order.
      final int foo = cmdToChatStatus(st);
      if (foo > status)
         status = foo;
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

class ChatHistory {
   String peer = '';
   String nick = '';
   List<ChatItem> msgs = List<ChatItem>();
   bool isLongPressed = false;
   int date = 0;
   int pinDate = -1;

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

   ChatHistory(this.peer, this.nick, this.date, final int postId);

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
          final int postId, int status) async
   {
      final int now = DateTime.now().millisecondsSinceEpoch;
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

// Used to rotate a new chat item in a chat history and also posts.
void rotateElements(List<ChatHistory> elems, int j)
{
   if (j == 0)
      return; // This is already the first element.

   if (elems[j].pinDate != -1)
      return; // The element is pinned and should not be rotated.

   ChatHistory elem = elems[j];
   int i = j;
   for (; i > 0; --i) {
      elems[i] = elems[i - 1];
   }

   elems[i] = elem;
}

ChatHistory
selectMostRecentChat(final ChatHistory lhs, final ChatHistory rhs)
{
   final int t1 = lhs.getMostRecentTimestamp();
   final int t2 = rhs.getMostRecentTimestamp();

   return t1 < t2 ? lhs : rhs;
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

class PostData {
   // The post unique identifier.  Its value is sent back by the
   // server when the post publication is acknowledged.
   int id = -1;

   // The person that published this post.
   String from = '';

   // The publisher nick name.
   String nick = cts.unknownNick;

   // Contains the channel of the channel this post was published.
   //
   //  [[[1, 2]], [[3, 2]], [[3, 2, 1, 1]]]
   //
   List<List<List<int>>> channel;

   int filter = 0;

   // The publication date.
   int date = 0;

   // The date this post has been pinned by the user.
   int pinDate = -1;

   // Post status.
   //   0: Posts published by the app.
   //   1: Posts received
   //   2: Posts moved to favorites.
   int status = -1;

   // The string *description* inputed when user writes an post.
   String description = '';

   List<ChatHistory> chats = List<ChatHistory>();

   PostData()
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
         chats = List<ChatHistory>();
         File f = File(makePathToPeersFile());
         final List<String> lines = await f.readAsLines();
         print('Peers: $lines');
         for (String line in lines) {
            final List<String> fields = line.split(';');
            // The assertion should be for == not >=.
            assert(fields.length >= 3);
            ChatHistory hist =
               ChatHistory(
                  fields[0], fields[1], int.parse(fields[2]), id);
            await hist.loadMsgs(id);
            chats.add(hist);
         }
      } catch (e) {
         //print(e);
      }
   }

   PostData clone()
   {
      PostData ret = PostData();
      ret.channel = List<List<List<int>>>.from(this.channel);
      ret.description = this.description;
      ret.chats = List<ChatHistory>.from(this.chats);
      ret.from = this.from;
      ret.id = this.id;
      ret.filter = this.filter;
      ret.nick = this.nick;
      ret.date = this.date;
      ret.pinDate = this.pinDate;
      return ret;
   }

   Future<void> setNick(final String peer, final String nick) async
   {
      final int j = getChatHistIdx(peer);
      if (j == -1) {
         // AFAIK, the only way this can happen ist if the app user
         // has deleted the ChatHistory in the time between the
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
      for (ChatHistory o in chats)
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
      ChatHistory history = ChatHistory(peer, nick, now, id);
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
   addMsg(final int j, final String msg,
          final bool thisApp, int status) async
   {
      await chats[j].addMsg(msg, thisApp, id, status);
   }

   Future<void> moveToFront(final int j) async
   {
      rotateElements(chats, j);
      await persistPeers();
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
      for (ChatHistory h in chats)
         if (h.getNumberOfUnreadMsgs() > 0)
            ++i;

      return i;
   }

   bool hasUnreadChats()
   {
      // This is more eficient than comparing
      // getNumberOfUnreadChats != 0

      for (ChatHistory h in chats)
         if (h.getNumberOfUnreadMsgs() > 0)
            return true;

      return false;
   }

   int getMostRecentTimestamp()
   {
      if (chats.isEmpty)
         return 0;

      final ChatHistory hist = chats.reduce(selectMostRecentChat);

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

   PostData.fromJson(Map<String, dynamic> map)
   {
      // Part of the object can be deserialized by readPostData. The
      // only remaining field will be *peers* and the chat history.
      PostData pd = readPostData(map);
      from = pd.from;
      id = pd.id;
      channel = pd.channel;
      description = pd.description;
      filter = pd.filter;
      nick = pd.nick;
      date = pd.date;
      pinDate = pd.pinDate;
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

Map<String, dynamic> postToMap(PostData post)
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

Future<List<PostData>> loadPosts(Database db, String tableName) async
{
  final List<Map<String, dynamic>> maps =
     await db.query(tableName);

  return List.generate(maps.length, (i)
  {
     PostData post = PostData();
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

bool toggleLPChat(ChatHistory ch)
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

int CompPostData(final PostData lhs, final PostData rhs)
{

   if (lhs.chats.length == 0 && rhs.chats.length == 0)
      return lhs.date > rhs.date ? -1 : 1;

   if (lhs.chats.length == 0)
      return 1;

   if (rhs.chats.length == 0)
      return -1;

   if (lhs.pinDate != -1 && rhs.pinDate != -1)
      return lhs.pinDate > rhs.pinDate ? -1 : 1;

   if (lhs.pinDate != -1)
      return -1;

   if (rhs.pinDate != -1)
      return 1;

   final int ts1 = lhs.getMostRecentTimestamp();
   final int ts2 = rhs.getMostRecentTimestamp();
   return ts1 > ts2 ? -1 : 1;
}

int rotatePostData(List<PostData> posts, int j)
{
   if (j == 0)
      return 0; // This is already the first element.

   if (posts[j].pinDate != -1) {
      print('====> Element is fixed.');
      return j; // The element is pinned and should not be rotated.
   }

   PostData elem = posts[j];
   int i = j;
   for (; i > 0; --i) {
      if (CompPostData(posts[i], posts[i - 1]) < 0)
         posts[i] = posts[i - 1];
      else
         break;
   }

   posts[i] = elem;
   return i;
}

Future<void>
findAndMarkChatApp( final List<PostData> posts
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

// Study how to convert this into an elipsis like whatsapp.
Container makeCircleUnreadMsgs(int n, Color bgColor, Color textColor)
{
   final Text txt = Text("${n}", style: TextStyle(color: textColor));
   final Radius rd = const Radius.circular(45.0);
   return Container(
       margin: const EdgeInsets.all(2.0),
       padding: const EdgeInsets.all(2.0),
       constraints: BoxConstraints(
             minHeight: 21.0, minWidth: 21.0,
             maxHeight: 21.0, maxWidth: 40.0),
       //height: 21.0,
       //width: 21.0,
       decoration:
          BoxDecoration(
             color: bgColor,
             borderRadius:
                BorderRadius.only(
                   topLeft:  rd,
                   topRight: rd,
                   bottomLeft: rd,
                   bottomRight: rd)),
         child: Center(widthFactor: 1.0, child: txt));
}

Card makePostElemSimple(Icon ic, List<Column> cols)
{
   List<Widget> r = List<Widget>();
   r.add(Padding(child: Center(child: ic), padding: EdgeInsets.all(4.0)));

   Row row = Row(children: cols);
   r.add(row);

   // Padding needed to show the text inside the post element with some
   // distance from the border.
   Padding leftWidget = Padding(
         padding: EdgeInsets.all(cts.postElemTextPadding),
         child: Column(
               crossAxisAlignment: CrossAxisAlignment.stretch,
               children: r,
            )
         );

   // Here we need another padding to make the post inner element have
   // some distance to the outermost card.
   return Card(
            child: leftWidget,
            color: Colors.white,
            margin: EdgeInsets.all(cts.postInnerMargin),
            elevation: 0.0,
   );
}

Card makePostElem( BuildContext context
                 , List<String> values
                 , List<String> keys
                 , Icon ic)
{
   List<Widget> leftList = List<Widget>();
   List<Widget> rightList = List<Widget>();

   for (int i = 0; i < values.length; ++i) {
      RichText left =
         RichText(text: TextSpan( text: keys[i] + ': '
                                , style: cts.postTitleStl));
      leftList.add(left);

      RichText right =
         RichText(text: TextSpan( text: values[i]
                                , style: cts.postValueTextStl));
      rightList.add(right);
   }

   Column leftCol =
      Column( children: leftList
            , crossAxisAlignment: CrossAxisAlignment.start);

   Column rightCol =
      Column( children: rightList
            , crossAxisAlignment: CrossAxisAlignment.start);

   return makePostElemSimple(ic, <Column>[leftCol, rightCol]);
}

Card makePostDetailElem(int filter)
{
   List<Widget> leftList = List<Widget>();

   for (int i = 0; i < cts.postDetails.length; ++i) {
      final bool b = (filter & (1 << i)) == 0;
      if (b)
         continue;

      Icon icTmp = Icon(Icons.check, color: cts.postFrameColor);
      Text txt = Text( ' ${cts.postDetails[i]}'
                     , style: cts.postValueTextStl);
      Row row = Row(children: <Widget>[icTmp, txt]); 
      leftList.add(row);
   }

   Column col =
      Column( children: leftList
            , crossAxisAlignment: CrossAxisAlignment.start);

   Icon ic = Icon(Icons.details, color: cts.postFrameColor);
   return makePostElemSimple(ic, <Column>[col]);
}

List<Card>
makeMenuInfoCards(BuildContext context,
                  PostData data,
                  List<MenuItem> menus,
                  Color color)
{
   List<Card> list = List<Card>();

   for (int i = 0; i < data.channel.length; ++i) {
      List<String> names =
            loadNames(menus[i].root.first, data.channel[i][0]);

      Card card = makePostElem(
                     context,
                     names,
                     cts.menuDepthNames[i],
                     Icon( cts.newPostTabIcons[i]
                         , color: cts.postFrameColor));

      list.add(card);
   }

   return list;
}

// Will assemble menu information and the description in cards
List<Card> postTextAssembler(BuildContext context,
                            PostData data,
                            List<MenuItem> menus,
                            Color color)
{
   List<Card> list = makeMenuInfoCards(context, data, menus, color);
   DateTime date = DateTime.fromMillisecondsSinceEpoch(data.date);
   DateFormat format = DateFormat.yMd().add_jm();
   String dateString = format.format(date);

   List<String> values = List<String>();
   values.add(data.nick);
   values.add('${data.from}');
   values.add('${data.id}');
   values.add(dateString);
   values.add(data.description);

   Card dc1 =
      makePostElem( context, values, cts.descList
                  , Icon( Icons.description
                        , color: cts.postFrameColor));

   list.add(dc1);
   list.add(makePostDetailElem(data.filter));

   return list;
}

Text makeChatSubStrWidget(ChatHistory ch)
{
   FontWeight fw = FontWeight.normal;
   if (ch.hasUnreadMsgs())
      fw = FontWeight.bold;

   return createMenuItemSubStrWidget(ch.getLastMsg(), FontWeight.bold);
}

Card createChatEntry(BuildContext context,
                     PostData post,
                     List<MenuItem> menus,
                     Widget chats,
                     Function onDelPost,
                     Function onPinPost,
                     int i)
{
   List<Card> textCards = postTextAssembler(context, post, menus,
                                       cts.postFrameColor);

   IconData pinIcon = post.pinDate == -1 ? Icons.place : Icons.pin_drop;
   Row leading = Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>
   [ IconButton(icon: Icon(Icons.clear),
                onPressed: (){onDelPost(i);})
   , IconButton(icon: Icon(pinIcon),
                onPressed: (){onPinPost(i);})
   ]);

   ExpansionTile et =
      ExpansionTile(
          leading: leading,
          key: PageStorageKey<int>(2 * post.id),
          title: Text('${cts.postTimePrefix}: ${post.id}',
                      style: cts.expTileStl),
          children: ListTile.divideTiles(
                     context: context,
                     tiles: textCards,
                     color: Colors.grey).toList());

   List<Widget> cards = List<Card>();
   cards.add(Card(child: et,
                  color: cts.postFrameColor,
                  margin: EdgeInsets.all(0.0),
                  elevation: 0.0));

   Card chatCard = Card(child: chats,
                        color: cts.postFrameColor,
                        margin: EdgeInsets.all(cts.postInnerMargin),
                        elevation: 0.0);

   cards.add(chatCard);

   Column col = Column(children: cards);

   final double padding = cts.outerPostCardPadding;
   return Card(
      child: Padding(child: col, padding: EdgeInsets.all(padding)),
      color: cts.postFrameColor,
      margin: EdgeInsets.all(cts.postMarging),
      elevation: 0.0,
   );
}

Card makePostWidget(BuildContext context,
                    List<Card> cards,
                    Function onPressed,
                    Icon icon,
                    Color color)
{
   IconButton icon1 = IconButton(
                         icon: Icon(Icons.clear, color: Colors.white),
                         iconSize: 30.0,
                         onPressed: () {onPressed(0);});

   IconButton icon2 = IconButton(
                         icon: icon,
                         onPressed: () {onPressed(1);},
                         color: Theme.of(context).primaryColor,
                         iconSize: 30.0);

   Row row = Row(children: <Widget>[
                Expanded(child: icon1),
                Expanded(child: icon2)]);

   Card c4 = Card(
      child: row,
      color: color,
      margin: EdgeInsets.all(cts.postInnerMargin),
      elevation: 0.0,
   );

   cards.add(c4);

   Column col = Column(children: cards);

   final double padding = cts.outerPostCardPadding;
   return Card(
      child: Padding(child: col, padding: EdgeInsets.all(padding)),
      color: color,
      margin: EdgeInsets.all(cts.postMarging),
      elevation: 5.0,
   );
}

Card makeCard(Widget widget, Color color)
{
   return Card(
         child:
            Padding(child: widget,
                    padding: EdgeInsets.all( cts.postElemTextPadding)),
         color: color,
         margin: EdgeInsets.all(cts.postInnerMargin),
         elevation: 0.0,
   );
}

TextField
makeTextInputFieldCard( TextEditingController ctrl
                      , int maxLength
                      , InputDecoration deco)
{
   // TODO: Set a max length.
   return TextField(
             controller: ctrl,
             //textInputAction: TextInputAction.go,
             //onSubmitted: onTextFieldPressed,
             keyboardType: TextInputType.multiline,
             maxLines: null,
             maxLength: maxLength,
             decoration: deco);
}

ListView
makePostTabListView(BuildContext ctx,
                    List<PostData> posts,
                    Function onPostSelection,
                    List<MenuItem> menus,
                    Function updateLasSeenPostIdx)
{
   final int postsLength = posts.length;

   return ListView.builder(
             padding: const EdgeInsets.all(0.0),
             itemCount: posts.length,
             itemBuilder: (BuildContext ctx, int i)
             {
                updateLasSeenPostIdx(i);

                // New posts are shown with a different color.
                Color color = cts.postFrameColor;
                //if (i > lastSeenPostIdx)
                //   color = cts.newReceivedPostColor; 

                List<Card> cards =
                   postTextAssembler(
                      ctx,
                      posts[i],
                      menus,
                      color);
   
                return makePostWidget(
                    ctx,
                    cards,
                    (int fav) async
                       {await onPostSelection(ctx, i, fav);},
                    cts.favIcon,
                    color);
             });
}

ListView createPostMenuListView(BuildContext context, MenuNode o,
      Function onLeafPressed, Function onNodePressed)
{
   return ListView.builder(
      itemCount: o.children.length,
      itemBuilder: (BuildContext context, int i)
      {
         final int c = o.children[i].getCounterOfFilterChildren();
         final int cs = o.children[i].getChildrenSize();

         final String names = o.children[i].getChildrenNames();
         final String subtitle = '($c/$cs) $names';

         MenuNode child = o.children[i];
         if (child.isLeaf()) {
            return ListTile(
                leading: makeCircleAvatar(
                   Text(makeStrAbbrev(child.name),
                        style: cts.abbrevStl),
                   Colors.grey),
                title: Text(child.name, style: cts.menuTitleStl),
                dense: true,
                onTap: () { onLeafPressed(i);},
                enabled: true,
                onLongPress: (){});
         }
         
         return
            ListTile(
                leading: makeCircleAvatar(
                   Text(
                      makeStrAbbrev(
                         o.children[i].name),
                         style: cts.abbrevStl),
                   Colors.grey),
                title: Text(o.children[i].name, style: cts.menuTitleStl),
                dense: true,
                subtitle: Text(
                   subtitle,
                   style: TextStyle(fontSize: 14.0), maxLines: 2,
                                    overflow: TextOverflow.clip),
                trailing: Icon(Icons.keyboard_arrow_right),
                onTap: () { onNodePressed(i); },
                enabled: true,
                selected: c != 0,
                isThreeLine: true);
      },
   );
}

// Returns an icon based on the message status.
Widget chooseIcon(final int status)
{
   final double s = 17.0;

   Icon icon = Icon(Icons.clear, color: Colors.grey, size: s);

   if (status == 1)
      icon = Icon(Icons.check, color: Colors.grey, size: s);

   if (status == 2)
      icon = Icon(Icons.done_all, color: Colors.grey, size: s);

   if (status == 3)
      icon = Icon(Icons.done_all, color: Colors.green, size: s);

   return Padding(
      child: icon,
      padding: const EdgeInsets.symmetric(horizontal: 2.0));
}

Widget makeChatTileSubStr(final ChatHistory ch)
{
   if (ch.getNumberOfUnreadMsgs() > 0)
      return makeChatSubStrWidget(ch);

   if (ch.msgs.isEmpty)
      return makeChatSubStrWidget(ch);

   if (!ch.msgs.last.thisApp)
      return makeChatSubStrWidget(ch);

   return Row(children: <Widget>
             [ chooseIcon(ch.msgs.last.status)
             , Expanded(child: makeChatSubStrWidget(ch))]);
}

Widget makePostChatCol(BuildContext context,
                      List<ChatHistory> ch,
                      Function onPressed,
                      Function onLongPressed,
                      int postId)
{
   List<Widget> list = List<Widget>(ch.length);

   int nUnredChats = 0;
   for (int i = 0; i < list.length; ++i) {
      final int n = ch[i].getNumberOfUnreadMsgs();
      if (n > 0)
         ++nUnredChats;

      Widget widget;
      Color bgColor;
      if (ch[i].isLongPressed) {
         widget = Icon(Icons.check);
         bgColor = cts.chatLongPressendColor;
      } else {
         widget = cts.unknownPersonIcon;
         bgColor = Colors.white;
      }

      Widget trailing = null;
      if (n != 0 && ch[i].pinDate != -1) {
         trailing = Column(children: <Widget>
         [ Icon(Icons.place)
         , makeCircleUnreadMsgs(n, Colors.grey, Colors.white)
         ]);
      } else if (n == 0 && ch[i].pinDate != -1) {
         trailing = Icon(Icons.place);
      } else if (n != 0 && ch[i].pinDate == -1) {
         trailing = makeCircleUnreadMsgs(n, Colors.grey, Colors.white);
      }

      ListTile lt =
         ListTile(
            dense: false,
            enabled: true,
            leading: makeCircleAvatar(widget, Colors.grey),
            trailing: trailing,
            title: Text(ch[i].getChatDisplayName(),
                        maxLines: 1,
                        overflow: TextOverflow.clip,
                        style: cts.menuTitleStl),
            subtitle: makeChatTileSubStr(ch[i]),
            //contentPadding: EdgeInsets.symmetric(horizontal: 10.0),
            onTap: () { onPressed(i); },
            onLongPress: () { onLongPressed(i); });

      list[i] = Container(decoration: BoxDecoration(color: bgColor),
                  child: lt);
   }

  if (list.length == 1)
     return Column(children: ListTile.divideTiles(
                      context: context,
                      tiles: list,
                      color: Colors.grey).toList());

   final TextStyle stl =
             TextStyle(fontSize: 15.0,
                       fontWeight: FontWeight.normal,
                       color: Colors.white);

   String str = '${ch.length} conversas';
   if (nUnredChats != 0)
      str = '${ch.length} conversas / $nUnredChats nao lidas';

   final bool expState = ch.length <= 5 || nUnredChats != 0;
   return ExpansionTile(
             initiallyExpanded: expState,
             leading: Icon(Icons.chat, color: Colors.white),
             key: PageStorageKey<int>(2 * postId + 1),
             title: Text(str, style: cts.expTileStl),
             children: ListTile.divideTiles(
                        context: context,
                        tiles: list,
                        color: Colors.grey).toList());
}

Widget makeChatTab(
   BuildContext context,
   List<PostData> data,
   Function onPressed,
   Function onLongPressed,
   List<MenuItem> menus,
   Function onDelPost,
   Function onPinPost)
{
   return ListView.builder(
         padding: const EdgeInsets.all(0.0),
         itemCount: data.length,
         itemBuilder: (BuildContext context, int i)
         {
            return createChatEntry(
                      context,
                      data[i],
                      menus,
                      makePostChatCol(
                         context,
                         data[i].chats,
                         (j) {onPressed(i, j);},
                         (j) {onLongPressed(i, j);},
                         data[i].id),
                      onDelPost,
                      onPinPost,
                      i);
         },
   );
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

PostData readPostData(var item)
{
   PostData post = PostData();
   post.description = item['msg'];
   post.from = item['from'];
   post.id = item['id'];
   post.filter = item['filter'];
   post.nick = item['nick'];
   post.channel = decodeChannel(item['to']);
   post.pinDate = -1;
   return post;
}

