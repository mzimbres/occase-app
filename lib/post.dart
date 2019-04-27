import 'dart:convert';
import 'dart:io' show File, FileMode, Directory;
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

class ChatItem {
   bool thisApp; 
   String msg = '';
   ChatItem(this.thisApp, this.msg) { }

   ChatItem.fromJson(Map<String, dynamic> map)
   {
      thisApp = map["this_app"];
      msg = map["msg"];
   }

   Map<String, dynamic> toJson()
   {
      return
      {
         'this_app': thisApp,
         'msg': msg,
      };
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

class ChatHistory {
   String peer = '';
   List<ChatItem> msgs = List<ChatItem>();
   List<ChatItem> unreadMsgs = List<ChatItem>();
   bool isLongPressed = false;
   int postId;

   ChatHistory(this.peer, this.postId)
   {
      getApplicationDocumentsDirectory().then((Directory dir) async
         { _init(dir.path, postId); });
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
         unreadMsgs  = chatItemsFromStrs(lines);
      } catch (e) {
         print(e);
      }
   }

   void moveToReadHistory()
   {
      if (unreadMsgs.isEmpty)
         return;

      msgs.addAll(unreadMsgs);

      getApplicationDocumentsDirectory().then((Directory dir) async
      {
         final String path = dir.path;
         final String readFullPath =
            '$path/chat_read_${postId}_${peer}.txt';
         final String unreadFullPath =
            '$path/chat_unread_${postId}_${peer}.txt';
         writeListToDisk(unreadMsgs, readFullPath, FileMode.append);
         unreadMsgs.clear();
         writeToFile('', unreadFullPath, FileMode.write);
      });
   }

   String getLastUnreadMsg()
   {
      if (unreadMsgs.isEmpty)
         return '';

      return unreadMsgs.last.msg;
   }

   int getNumberOfUnreadMsgs()
   {
      if (unreadMsgs.isEmpty)
         return 0;

      return unreadMsgs.length;
   }

   String getLastReadMsg()
   {
      if (msgs.isEmpty)
         return '';

      return msgs.last.msg;
   }

   void addMsg(final String msg, final bool thisApp)
   {
      ChatItem item = ChatItem(thisApp, msg);
      msgs.add(item);

      getApplicationDocumentsDirectory().then((Directory dir) async
      {
         final String readFullPath =
            '${dir.path}/chat_read_${postId}_${peer}.txt';
         writeListToDisk( <ChatItem>[item], readFullPath
                         , FileMode.append);
      });
   }

   void addUnreadMsg(final String msg, final bool thisApp)
   {
      ChatItem item = ChatItem(thisApp, msg);
      unreadMsgs.add(item);

      getApplicationDocumentsDirectory().then((Directory dir) async
      {
         final String unreadFullPath =
            '${dir.path}/chat_unread_${postId}_${peer}.txt';
         writeListToDisk( <ChatItem>[item], unreadFullPath
                         , FileMode.append);
      });
   }
}

class PostData {
   // The person that published this post.
   String from = '';

   // Together with *from* this is a unique identifier for this post.
   // Its value is sent back by the server when it acknowledges the
   // post.
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
      codes = List<List<List<int>>>(cts.menuDepthNames.length);
      for (int i = 0; i < codes.length; ++i) {
         codes[i] = List<List<int>>(1);
         codes[i][0] = List<int>();
      }
   }

   void loadChats()
   {
      getApplicationDocumentsDirectory().then((Directory dir) async
         { _loadImpl(dir.path); });
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

   void persistPeers(final String basename) async
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
      .then((Directory dir) async { persistPeers(dir.path); });
   }

   ChatHistory getChatHist(String peer)
   {
      final int i = chats.indexWhere((e) {return e.peer == peer;});

      if (i == -1) {
         // This is the first message with this user (peer).
         createChatEntryForPeer(peer);
         return chats.last;
      }

      return chats[i];
   }

   int getNumberOfUnreadChats()
   {
      int i = 0;
      for (ChatHistory h in chats)
         if (!h.unreadMsgs.isEmpty)
            ++i;

      return i;
   }

   // This function will return true if there is any chat marked as
   // long pressed. It will traverse the PostData array and stop at the
   // first PostData::chats that has isLongPressed true.
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
      .then((Directory dir) async { persistPeers(dir.path); });
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

      loadChats();
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
}

bool hasLongPressed(final List<PostData> posts)
{
   for (PostData post in posts)
      if (post.hasLongPressed())
         return true;

   return false;
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

