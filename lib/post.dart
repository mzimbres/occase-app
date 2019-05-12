import 'dart:convert';
import 'dart:io' show File, FileMode, Directory;
import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:menu_chat/constants.dart';
import 'package:menu_chat/menu_tree.dart';
import 'package:menu_chat/menu.dart';
import 'package:menu_chat/text_constants.dart' as cts;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

void writeToFile(String data, String fullPath, FileMode mode)
{
   // Do not do this. We also use this function to wipe out data from
   // files.
   //if (data.isEmpty)
   //   return;

   File file = File(fullPath);
   file.create(recursive: true).then((File f) async {
      try {
         var sink = f.openWrite(mode: mode);
         sink.write(data);
         await sink.flush();
         await sink.close();
         print('Finished writing to $fullPath');
      } catch (e) {
         print(e);
      }
   });
}

void writeListToDisk<T>( final List<T> data, final String fullPath
                        , FileMode mode)
{
   String content = '';
   for (T o in data) {
      final String postStr = jsonEncode(o);
      content += '$postStr\n';
   }

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

   ChatItem(this.thisApp, this.msg)
   {
      status = cmdToChatStatus('chat');
   }

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

// This is a duplicate of postsFromStrs since dart does not support
// proper generics.
List<ChatItem> chatItemsFromStrs(final List<String> items)
{
   List<ChatItem> foo = List<ChatItem>();
   for (String o in items) {
      Map<String, dynamic> map = jsonDecode(o);
      foo.add(ChatItem.fromJson(map));
   }

   return foo;
}

int findIdxToAck(final List<ChatItem> msgs, final int status)
{
   // Since we do not have ids to know which message exactly has
   // been acked. We should try to find the oldest msg that has not
   // been acked. But the algorithm is complicated since we have to
   // skip the chat items from the peer. For now, I will ack in the
   // reverse order. This should not be perceptible to the user.
   //
   // Here we could use for example indexWhere to search for the
   // index but to avoid performance later when the chat history
   // becomes too long I will begin the search from the back.
   int i = 0;
   for (; i < msgs.length; ++i) {
      final int j = msgs.length - i - 1; // Idx of the last element.
      if (!msgs[j].thisApp)
         continue; // Not a message from this app.

      final int st = msgs[j].status;
      if (st < status) // Should be >=
         break;
   }

   if (i == msgs.length) {
      // Most likely an out of order problem. Catching this here may
      // hide the source of problem, that maybe for example be on the
      // server. For debuging one may think of replacing it with an
      // assert.
      return -1;
   }

   final int idx = msgs.length - i - 1;
   assert(msgs[idx].thisApp);
   return idx;
}

class ChatHistory {
   String peer = '';
   List<ChatItem> msgs = List<ChatItem>();
   List<ChatItem> _unreadMsgs = List<ChatItem>();
   bool isLongPressed = false;

   ChatHistory(this.peer, final int postId)
   {
      getApplicationDocumentsDirectory()
      .then((Directory dir) async { _init(dir.path, postId); });
   }

   Future<void> _init(final String path, final int postId) async
   {
      final String readFullPath = '$path/chat_read_${postId}_${peer}.txt';

      try {
         File f = File(readFullPath);
         final List<String> lines = await f.readAsLines();
         msgs = chatItemsFromStrs(lines);
      } catch (e) {
         print(e);
      }

      final String unreadFullPath =
         '$path/chat_unread_${postId}_${peer}.txt';

      try {
         File f = File(unreadFullPath);
         final List<String> lines = await f.readAsLines();
         _unreadMsgs  = chatItemsFromStrs(lines);
      } catch (e) {
         print(e);
      }
   }

   // Returns the number of unread messages that have been moved to
   // the read history.
   int moveToReadHistory(final int postId)
   {
      if (_unreadMsgs.isEmpty)
         return 0;

      final int n = _unreadMsgs.length;

      msgs.addAll(_unreadMsgs);

      getApplicationDocumentsDirectory()
      .then((Directory dir) async
      {
         final String readFullPath =
            '${dir.path}/chat_read_${postId}_${peer}.txt';

         writeListToDisk(_unreadMsgs, readFullPath, FileMode.append);
         _unreadMsgs.clear();

         final String unreadFullPath =
            '${dir.path}/chat_unread_${postId}_${peer}.txt';
         writeToFile('', unreadFullPath, FileMode.write);
      });

      return n;
   }

   String getLastUnreadMsg()
   {
      if (_unreadMsgs.isEmpty)
         return '';

      return _unreadMsgs.last.msg;
   }

   int getNumberOfUnreadMsgs()
   {
      if (_unreadMsgs.isEmpty)
         return 0;

      return _unreadMsgs.length;
   }

   String getLastReadMsg()
   {
      if (msgs.isEmpty)
         return '';

      return msgs.last.msg;
   }

   void addMsg(final String msg, final bool thisApp, final int postId)
   {
      ChatItem item = ChatItem(thisApp, msg);
      msgs.add(item);

      getApplicationDocumentsDirectory()
      .then((Directory dir) async
      {
         final String readFullPath =
            '${dir.path}/chat_read_${postId}_${peer}.txt';

         writeListToDisk( <ChatItem>[item], readFullPath
                         , FileMode.append);
      });
   }

   void addUnreadMsg(final String msg, final bool thisApp, final int postId)
   {
      ChatItem item = ChatItem(thisApp, msg);
      _unreadMsgs.add(item);

      getApplicationDocumentsDirectory()
      .then((Directory dir) async
      {
         final String unreadFullPath =
            '${dir.path}/chat_unread_${postId}_${peer}.txt';

         writeListToDisk( <ChatItem>[item], unreadFullPath
                         , FileMode.append);
      });
   }

   void markAppChatAck(final int postId, final int status)
   {
      // TODO: Make sure to read chat messages before publishing the
      // offline ones to the server. If the server acks before they
      // have been completely loaded, we will miss them below.
      //assert(!msgs.isEmpty); 
      if (msgs.isEmpty)
         return;

      int idx = findIdxToAck(msgs, status);
      if (idx == -1)
         return;

      while (msgs[idx].status < status) {
         print('====> markAppChatAck $idx ${msgs.length}');
         msgs[idx].status = status;
         if (idx == 0)
            break;

         --idx;
      }

      // TODO: Soon or later we will have to use a database. Now we
      // are having to write the whole file of msgs on every ack which
      // is very bad for performance. We only want to change a flag.
      // We could also think of storing status flags in a separate
      // file?
      getApplicationDocumentsDirectory()
      .then((Directory dir) async
      {
         final String unreadFullPath =
            '${dir.path}/chat_read_${postId}_${peer}.txt';

         writeListToDisk(msgs, unreadFullPath, FileMode.write);
      });
   }
}

List<List<List<int>>> makeEmptyMenuCodesContainer(int n)
{
   List<List<List<int>>> codes = List<List<List<int>>>(n);
   for (int i = 0; i < n; ++i) {
      codes[i] = List<List<int>>(1);
      codes[i][0] = List<int>();
   }

   return codes;
}

class PostData {
   // The person that published this post.
   String from = '';

   // The post unique identifier.  Its value is sent back by the
   // server when the post is acknowledged.
   int id = -1;

   // Contains channel codes in the form
   //
   //  [[[1, 2]], [[3, 2]], [[3, 2, 1, 1]]]
   //
   List<List<List<int>>> codes;

   // The string *description* inputed when user writes an post.
   String description = '';

   List<ChatHistory> chats = List<ChatHistory>();

   PostData()
   {
      codes = makeEmptyMenuCodesContainer(cts.menuDepthNames.length);
   }

   void _loadChats()
   {
      getApplicationDocumentsDirectory()
      .then((Directory dir) async { _loadImpl(dir.path); });
   }

   Future<void> _loadImpl(final String path) async
   {
      try {
         final String fullPath = '$path/post_peers_${id}.txt';
         chats = List<ChatHistory>();
         File f = File(fullPath);
         final List<String> lines = await f.readAsLines();
         for (String line in lines)
            chats.add(ChatHistory(line, id));
         print('Peers $lines read from file: $fullPath');
      } catch (e) {
         print(e);
      }
   }

   PostData clone()
   {
      PostData ret = PostData();
      ret.codes = List<List<List<int>>>.from(this.codes);
      ret.description = this.description;
      ret.chats = List<ChatHistory>.from(this.chats);
      ret.from = this.from;
      ret.id = this.id;
      return ret;
   }

   void _persistPeers(final String basename) async
   {
      // Overwrites the previous content.
      String foo = '';
      for (ChatHistory o in chats)
         foo += '${o.peer}\n';

      final String path = '${basename}/post_peers_${id}.txt';
      print('Persisting peers: $foo');
      writeToFile(foo, path, FileMode.write);
   }

   void createChatEntryForPeer(String peer)
   {
      print('createChatEntryForPeer: $peer');
      ChatHistory history = ChatHistory(peer, id);
      chats.add(history);

      getApplicationDocumentsDirectory()
      .then((Directory dir) async { _persistPeers(dir.path); });
   }

   int getChatHistIdx(final String peer)
   {
      final int i = chats.indexWhere((e) {return e.peer == peer;});

      if (i == -1) {
         // This is the first message with this user (peer).
         final int l = chats.length;
         createChatEntryForPeer(peer);
         return l;
      }

      return i;
   }

   ChatHistory getChatHist(final String peer)
   {
      final int i = getChatHistIdx(peer);
      return chats[i];
   }

   void addMsg(final String peer, final String msg, final bool thisApp)
   {
      ChatHistory history = getChatHist(peer);
      history.addMsg(msg, thisApp, id);
   }

   void addUnreadMsg(final String peer, final String msg, final bool thisApp)
   {
      final int j = getChatHistIdx(peer);
      ChatHistory history = chats[j];
      history.addUnreadMsg(msg, thisApp, id);

      // This chat history is now the most recent and should appear
      // first int the list of chats. It is enough to rotate the list
      // one element.
      if (j == 0)
         return; // This already the first element.

      for (int i = j; i > 0; --i)
         chats[i] = chats[i - 1];

      chats[0] = history;
   }

   void markChatAppAck(final String peer, final int status)
   {
      ChatHistory history = getChatHist(peer);
      history.markAppChatAck(id, status);
   }

   int getNumberOfUnreadChats()
   {
      int i = 0;
      for (ChatHistory h in chats)
         if (h.getNumberOfUnreadMsgs() > 0)
            ++i;

      return i;
   }

   // This function will return true if there is any chat marked as
   // long pressed. It will traverse the PostData array and stop at the
   // first PostData::chats for which isLongPressed is true.
   bool hasLongPressed()
   {
      for (ChatHistory ch in chats)
         if (ch.isLongPressed)
            return true;

      return false;
   }

   void removeLongPressedChats()
   {
      chats.removeWhere((e) { return e.isLongPressed; });

      // TODO: Remove files from chat entries that have been remove
      // obove.

      getApplicationDocumentsDirectory()
      .then((Directory dir) async { _persistPeers(dir.path); });
   }

   PostData.fromJson(Map<String, dynamic> map)
   {
      // Part of the object can be deserialized by readPostData. The
      // only remaining field will be *peers* and the chat history.
      PostData pd = readPostData(map);
      from = pd.from;
      id = pd.id;
      codes = pd.codes;
      description = pd.description;

      _loadChats();
   }

   Map<String, dynamic> toJson()
   {
      // To make the deserialization easier, we will make the json
      // partially deserializable by readPostData.
      return
      {
         'msg': description,
         'from': from,
         'id': id,
         'to': codes,
      };
   }

   int moveToReadHistory(int i)
   {
      final int n = chats[i].moveToReadHistory(id);

      // Now we have to put this chatHistory behind any other that has
      // unread messages.

      // If this is already the last history we have nothing to do.
      if ((i + 1) == chats.length)
         return n;

      // We know now it is not the last element.

      if (chats[i + 1].getNumberOfUnreadMsgs() == 0)
         return n;

      // We known the next element has unread messages. We can loop.

      ChatHistory hist = chats[i];
      while ((i + 1) != chats.length &&
             chats[i + 1].getNumberOfUnreadMsgs() > 0) {
         chats[i] = chats[i + 1];
         ++i;
      }

      chats[i] = hist;
      return n;
   }
}

bool hasLongPressed(final List<PostData> posts)
{
   for (PostData post in posts)
      if (post.hasLongPressed())
         return true;

   return false;
}

bool findAndAddMsg(final List<PostData> posts,
                   final int postId,
                   final String from,
                   final String msg,
                   final bool thisApp)
{
   final int i = posts.indexWhere((e) { return e.id == postId;});

   if (i == -1)
      return false;

   posts[i].addUnreadMsg(from, msg, thisApp);
   return true;
}

void
findAndMarkChatApp( final List<PostData> posts
                  , final String from
                  , final int postId
                  , final int status)
{
   final int i = posts.indexWhere((e) { return e.id == postId;});

   if (i == -1) {
      print('====> findAndMarkChatApp: Cannot find msg.');
      return;
   }

   //print('====> IndexWhere: $i');

   posts[i].markChatAppAck(from, status);
}

// Study how to convert this into an elipsis like whatsapp.
Container makeCircleUnreadMsgs(int n,
                               Color bgColor,
                               Color textColor)
{
   // TODO: The container width has to be wide enough to fit the
   // number of digits in string.
   final Text txt = Text("${n}", style: TextStyle(
                  color: textColor));

   final Radius rd = const Radius.circular(45.0);
   return Container(
             margin: const EdgeInsets.all(2.0),
             padding: const EdgeInsets.all(0.0),
             height: 23.0,
             width: 23.0,
             decoration:
                BoxDecoration(
                   color: bgColor,
                   borderRadius:
                      BorderRadius.only(
                         topLeft:  rd,
                         topRight: rd,
                         bottomLeft: rd,
                         bottomRight: rd)),
               child: Center(child: txt));
}

Card postElemFactory(BuildContext context,
                    List<String> values,
                    List<String> keys,
                    Icon ic)
{
   List<Widget> r = List<Widget>();
   r.add(Padding(child: Center(child: ic), padding: EdgeInsets.all(4.0)));

   for (int i = 0; i < values.length; ++i) {
      RichText rt = RichText(
            text: TextSpan(
                  text: keys[i] + ': ',
                  style: cts.menuTitleStl,
                  children: <TextSpan>[
                     TextSpan(text: values[i],
                              style: cts.valueTextStl),
                  ],
            ),
         );

      r.add(rt);
   }

   // Padding needed to show the text inside the post element with some
   // distance from the border.
   Padding padd = Padding(
         padding: EdgeInsets.all(cts.postElemTextPadding),
         child: Column(
               crossAxisAlignment: CrossAxisAlignment.stretch,
               children: r,
            )
         );

   // Here we need another padding to make the post inner element have
   // some distance to the outermost card.
   return Card(
            child: padd,
            color: Colors.white,
            margin: EdgeInsets.all(Consts.postInnerMargin),
            elevation: 0.0,
   );
}

List<Card>
makeMenuInfoCards(BuildContext context,
                  PostData data,
                  List<MenuItem> menus,
                  Color color)
{
   List<Card> list = List<Card>();

   for (int i = 0; i < data.codes.length; ++i) {
      List<String> names =
            loadNames(menus[i].root.first, data.codes[i][0]);

      Card card = postElemFactory(
                  context,
                  names,
                  cts.menuDepthNames[i],
                  cts.newPostTabIcons[i]);

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

   DateTime date = DateTime.fromMillisecondsSinceEpoch(data.id);
   DateFormat format = DateFormat.yMd().add_jm();
   String dateString = format.format(date);

   List<String> values = List<String>();
   values.add(data.from);
   values.add(dateString);
   values.add(data.description);

   Card descCard = postElemFactory(context, values, cts.descList,
                                  cts.personIcon);

   list.add(descCard);

   return list;
}

Card makeTextSeparator(BuildContext context)
{
   return Card(child: Icon(Icons.message, color: Colors.white),
               color: Theme.of(context).primaryColor,
               elevation: 0.0);
}

Text makeChatSubStrWidget(ChatHistory ch)
{
   final String subTitle = ch.getLastUnreadMsg();

   if (subTitle.isEmpty) // There is no unread message.
      return createMenuItemSubStrWidget(ch.getLastReadMsg(),
                FontWeight.normal);

   return createMenuItemSubStrWidget(subTitle, FontWeight.bold);
}

Card createChatEntry(BuildContext context,
                     PostData post,
                     List<MenuItem> menus,
                     Widget chats)
{
   List<Card> textCards = postTextAssembler(context, post, menus,
                                       Theme.of(context).primaryColor);

   final Color ac = Colors.blueGrey[400];
   ExpansionTile et = ExpansionTile(
             //key: PageStorageKey<Entry>(root),
             title: Text("Detalhes do post", style: cts.expTileStl),
             children: ListTile.divideTiles(
                        context: context,
                        tiles: textCards,
                        color: Colors.grey).toList());

   List<Widget> cards = List<Card>();
   cards.add(Card(child: et,
                  color: ac,
                  margin: EdgeInsets.all(0.0),
                  elevation: 0.0));

   //cards.add(makeTextSeparator(context));

   Card chatCard = Card(child: chats,
                        color: ac,
                        margin: EdgeInsets.all(Consts.postInnerMargin),
                        elevation: 0.0);

   cards.add(chatCard);

   Column col = Column(children: cards);

   final double padding = cts.outerPostCardPadding;
   return Card(
      child: Padding(child: col, padding: EdgeInsets.all(padding)),
      color: ac,
      margin: EdgeInsets.all(Consts.postMarging),
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
                         onPressed: () {onPressed(false);});

   IconButton icon2 = IconButton(
                         icon: icon,
                         onPressed: () {onPressed(true);},
                         color: Theme.of(context).primaryColor,
                         iconSize: 30.0);

   Row row = Row(children: <Widget>[
                Expanded(child: icon1),
                Expanded(child: icon2)]);

   Card c4 = Card(
      child: row,
      color: color,
      margin: EdgeInsets.all(Consts.postInnerMargin),
      elevation: 0.0,
   );

   cards.add(c4);

   Column col = Column(children: cards);

   final double padding = cts.outerPostCardPadding;
   return Card(
      child: Padding(child: col, padding: EdgeInsets.all(padding)),
      color: color,
      margin: EdgeInsets.all(Consts.postMarging),
      elevation: 5.0,
   );
}

Card makeCard(Widget widget)
{
   return Card(
         child:
            Padding(child: widget,
                    padding: EdgeInsets.all( cts.postElemTextPadding)),
         color: Consts.postLocHeaderColor,
         margin: EdgeInsets.all(Consts.postInnerMargin),
         elevation: 0.0,
   );
}

TextField makeTextInputFieldCard(TextEditingController ctrl)
{
   // TODO: Set a max length.
   return TextField(
             controller: ctrl,
             //textInputAction: TextInputAction.go,
             //onSubmitted: onTextFieldPressed,
             keyboardType: TextInputType.multiline,
             maxLines: null,
             decoration:
                InputDecoration(hintText: cts.newPostDescDeco));
}

ListView
makePostTabListView(BuildContext context,
                    List<PostData> posts,
                    Function onPostSelection,
                    List<MenuItem> menus,
                    int numberOfNewPosts)
{
   final int postsLength = posts.length;

   return ListView.builder(
             padding: const EdgeInsets.all(0.0),
             itemCount: postsLength,
             itemBuilder: (BuildContext context, int i)
             {
                // Posts are shown in reverse order.
                final int idx = postsLength - i - 1;

                // New posts are shown with a different color.
                Color color = cts.primaryColor;
                if (i < numberOfNewPosts)
                   color = cts.newReceivedPostColor; 

                List<Card> cards = postTextAssembler(
                                      context,
                                      posts[i],
                                      menus,
                                      color);
   
                return makePostWidget(
                          context,
                          cards,
                          (fav) {onPostSelection(posts[idx], fav);},
                          cts.favIcon,
                          color);
             });
}

FloatingActionButton makeNewPostButton(Function onNewPost)
{
   return FloatingActionButton(
             backgroundColor: cts.primaryColor,
             child: Icon(cts.newPostIcon, color: Colors.white),
             onPressed: onNewPost);
}

ListView createPostMenuListView(BuildContext context, MenuNode o,
      Function onLeafPressed, Function onNodePressed)
{
   return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: o.children.length,
      itemBuilder: (BuildContext context, int i)
      {
         MenuNode child = o.children[i];
         final String firstLetter = getFirstLetter(child.name);
         final String subStr = makeSubItemsString(child.leafCounter);
         if (child.isLeaf()) {
            return createListViewItem(
                         context,
                         child.name,
                         createMenuItemSubStrWidget(
                               subStr,
                               FontWeight.normal),
                         null,
                         Theme.of(context).primaryColor,
                         () { onLeafPressed(i);},
                         (){},
                         Text(firstLetter,
                              style: cts.firstLetterStl));
         }
         
         return createListViewItem(
                         context,
                         child.name,
                         createMenuItemSubStrWidget(
                               subStr,
                               FontWeight.normal),
                         null,
                         Theme.of(context).primaryColor,
                         () { onNodePressed(i); },
                         (){},
                         Text(firstLetter,
                              style: cts.firstLetterStl));
      },
   );
}

Widget makePostChatCol(BuildContext context,
                      List<ChatHistory> ch,
                      Function onPressed,
                      Function onLongPressed)
{
   List<Widget> list = List<Widget>(ch.length);

   for (int i = 0; i < list.length; ++i) {
      final int n = ch[i].getNumberOfUnreadMsgs();
      Widget widget;
      Color bgColor;
      if (ch[i].isLongPressed) {
         widget = Icon(Icons.check);
         bgColor = Theme.of(context).accentColor;
      } else {
         final String firstLetter = getFirstLetter(ch[i].peer);
         widget = Text(firstLetter, style: cts.firstLetterStl);
         bgColor = Colors.white;
      }

      Color cc = Theme.of(context).primaryColor;
      if (n == 0)
         cc = bgColor;

      ListTile lt = createListViewItem(context,
                        ch[i].peer,
                        makeChatSubStrWidget(ch[i]),
                        makeCircleUnreadMsgs(n, cc, Colors.white),
                        Theme.of(context).primaryColor,
                        () { onPressed(i); },
                        () { onLongPressed(i); },
                        widget);

      list[i] = Container(decoration: BoxDecoration(color: bgColor),
                  child: lt);
   }

   if (list.length <= 10)
      return Column(children: ListTile.divideTiles(
                       context: context,
                       tiles: list,
                       color: Colors.grey).toList());

   final TextStyle stl =
             TextStyle(fontSize: 15.0,
                       fontWeight: FontWeight.normal,
                       color: Colors.white);

   return ExpansionTile(
             //key: PageStorageKey<Entry>(root),
             title: Text("Conversas", style: cts.expTileStl),
             children: ListTile.divideTiles(
                        context: context,
                        tiles: list,
                        color: Colors.grey).toList());
}

Widget makePostChatTab(
         BuildContext context,
         List<PostData> data,
         Function onPressed,
         Function onLongPressed,
         List<MenuItem> menus)
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
                            (j) {onLongPressed(i, j);}));
         },
   );
}

PostData readPostData(var item)
{
   String msg = item['msg'];
   String from = item['from'];
   int id = item['id'];

   List<dynamic> to = item['to'];

   List<List<List<int>>> codes = List<List<List<int>>>();
   for (List<dynamic> a in to) {
      List<List<int>> foo = List<List<int>>();
      for (List<dynamic> b in a) {
         List<int> bar = List<int>();
         for (int c in b) {
            bar.add(c);
         }
         foo.add(bar);
      }
      codes.add(foo);
   }

   PostData post = PostData();
   post.from = from;
   post.description = msg;
   post.codes = codes;
   post.id = id;

   return post;
}

