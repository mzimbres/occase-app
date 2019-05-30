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

void safeDeleteFile(final String path)
{
   try {
      File(path).deleteSync();
   } catch (e) {
      print(e);
   }
}

void writeToFile( final String data
                , final String fullPath
                , final FileMode mode)
{
   try {
      File(fullPath).writeAsStringSync(data, mode: mode);
   } catch (e) {
   }
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
   int date = 0;

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
      _init(postId);
   }

   String makeFullPath(final String prefix, final int postId)
   {
      return '${glob.docDir}/${prefix}_${postId}_${peer}.txt';
   }

   int getMostRecentTimestamp()
   {
      if (!msgs.isEmpty)
         return msgs.last.date;

      if (!_unreadMsgs.isEmpty)
         return _unreadMsgs.last.date;

      return 0;
   }

   void _init(final int postId)
   {
      try {
         File f = File(makeFullPath(cts.chatHistReadPrefix, postId));
         final List<String> lines = f.readAsLinesSync();
         msgs = chatItemsFromStrs(lines);
      } catch (e) {
         //print(e);
      }

      try {
         File f = File(makeFullPath(cts.chatHistUnreadPrefix, postId));
         final List<String> lines = f.readAsLinesSync();
         _unreadMsgs  = chatItemsFromStrs(lines);
      } catch (e) {
         //print(e);
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

      writeListToDisk( _unreadMsgs
                     , makeFullPath(cts.chatHistReadPrefix, postId)
                     , FileMode.append);

      _unreadMsgs.clear();

      writeToFile( ''
                 , makeFullPath(cts.chatHistUnreadPrefix, postId)
                 , FileMode.write);

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
      final int now = DateTime.now().millisecondsSinceEpoch;
      ChatItem item = ChatItem(thisApp, msg, 0, now);
      msgs.add(item);

      writeListToDisk( <ChatItem>[item]
                     , makeFullPath(cts.chatHistReadPrefix, postId)
                     , FileMode.append);
   }

   void addUnreadMsg(final String msg, final bool thisApp, final int postId)
   {
      final int now = DateTime.now().millisecondsSinceEpoch;
      ChatItem item = ChatItem(thisApp, msg, 0, now);
      _unreadMsgs.add(item);

      writeListToDisk( <ChatItem>[item]
                     , makeFullPath(cts.chatHistUnreadPrefix, postId)
                     , FileMode.append);
   }

   void markAppChatAck(final int postId, final int status)
   {
      //assert(!msgs.isEmpty); 
      if (msgs.isEmpty)
         return;

      int idx = findIdxToAck(msgs, status);
      if (idx == -1)
         return;

      while (msgs[idx].status < status) {
         msgs[idx].status = status;
         if (idx == 0)
            break;

         --idx;
      }

      ChatItem item = ChatItem(true, '', status, 0);
      final String str = jsonEncode(item);
      writeToFile( '${str}\n'
                 , makeFullPath(cts.chatHistReadPrefix, postId)
                 , FileMode.append);
   }
}

// Used to rotate a new chat item in a chat history and also posts.
void rotateElements<T>(List<T> elems, int j)
{
   if (j == 0)
      return; // This is already the first element.

   T elem = elems[j];
   for (int i = j; i > 0; --i)
      elems[i] = elems[i - 1];

   elems[0] = elem;
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

   int filter = 0;

   // The string *description* inputed when user writes an post.
   String description = '';

   List<ChatHistory> chats = List<ChatHistory>();

   PostData()
   {
      codes = makeEmptyMenuCodesContainer(cts.menuDepthNames.length);
   }

   String makeFullPath()
   {
      return '${glob.docDir}/post_peers_${id}.txt';
   }

   void _loadChats()
   {
      try {
         chats = List<ChatHistory>();
         File f = File(makeFullPath());
         final List<String> lines = f.readAsLinesSync();
         print('Peers: $lines');
         for (String line in lines)
            chats.add(ChatHistory(line, id));
      } catch (e) {
         //print(e);
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

   void _persistPeers()
   {
      // Overwrites the previous content.
      String data = '';
      for (ChatHistory o in chats)
         data += '${o.peer}\n';

      print('Persisting peers: \n$data');

      writeToFile(data, makeFullPath(), FileMode.write);
   }

   void createChatEntryForPeer(String peer)
   {
      print('Creating chat entry for: $peer');
      ChatHistory history = ChatHistory(peer, id);
      chats.add(history);
      _persistPeers();
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

   void addMsg(final int j, final String msg, final bool thisApp)
   {
      chats[j].addMsg(msg, thisApp, id);
   }

   void moveToFront(final int j)
   {
      rotateElements(chats, j);
      _persistPeers();
   }

   void addUnreadMsg(final String peer, final String msg, final bool thisApp)
   {
      final int j = getChatHistIdx(peer);
      ChatHistory history = chats[j];
      history.addUnreadMsg(msg, thisApp, id);
      rotateElements(chats, j);
      _persistPeers();
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

      final ChatHistory hist =
         chats.reduce(selectMostRecentChat);

      return hist.getMostRecentTimestamp();
   }

   void removeLongPressedChats(int idx)
   {
      print('removeLPC($idx), length = ${chats.length}, id = $id');

      assert(!chats.isEmpty);
      assert(idx < chats.length);

      if (chats[idx].isLongPressed) {
         safeDeleteFile(chats[idx].makeFullPath(cts.chatHistReadPrefix, id));
         safeDeleteFile(chats[idx].makeFullPath(cts.chatHistUnreadPrefix, id));
      }

      chats.removeAt(idx);
      _persistPeers();
   }

   void unmarkLongPressedChats(int idx)
   {
      print('removeLPC($idx), length = ${chats.length}, id = $id');

      assert(!chats.isEmpty);
      assert(idx < chats.length);
      chats[idx].isLongPressed = false;
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
         'from': from,
         'to': codes,
         'id': id,
         'filter': filter,
         'msg': description,
      };
   }

   int moveToReadHistory(int i)
   {
      final int n = chats[i].moveToReadHistory(id);
      return n;
   }
}

int CompPostData(final PostData lhs, final PostData rhs)
{
   //final bool b1 = lhs.hasUnreadChats();
   //final bool b2 = rhs.hasUnreadChats();

   //// The first criterium is having unread messages.
   //if (b1 && !b2)
   //   return true;

   //if (!b1 && b2)
   //   return false;

   // At this point both posts have unread messages. The one with the
   // most recent unread msgs wins.
   final int ts1 = lhs.getMostRecentTimestamp();
   final int ts2 = rhs.getMostRecentTimestamp();
   return ts1 < ts2 ? -1 : 1;
}

bool findAndInsertNewMsg(List<PostData> posts,
                         final int postId,
                         final String from,
                         final String msg,
                         final bool thisApp)
{
   final int i = posts.indexWhere((e) { return e.id == postId;});

   if (i == -1)
      return false;

   posts[i].addUnreadMsg(from, msg, thisApp);
   rotateElements(posts, i);
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
            margin: EdgeInsets.all(Consts.postInnerMargin),
            elevation: 0.0,
   );
}

Card makePostElem(BuildContext context, List<String> values,
                  List<String> keys, Icon ic)
{
   List<Widget> leftList = List<Widget>();
   List<Widget> rightList = List<Widget>();

   for (int i = 0; i < values.length; ++i) {
      RichText left =
         RichText(text: TextSpan( text: keys[i] + ': '
                                , style: cts.menuTitleStl));
      leftList.add(left);

      RichText right =
         RichText(text: TextSpan( text: values[i]
                                , style: cts.valueTextStl));
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

Card makePostDetailElem(Icon ic, int filter)
{
   List<Widget> leftList = List<Widget>();

   for (int i = 0; i < cts.postDetails.length; ++i) {
      final bool b = (filter & (1 << i)) == 0;
      if (b)
         continue;

      Icon icTmp = Icon(Icons.check, color: Colors.red);
      Text txt = Text( ' ${cts.postDetails[i]}'
                     , style: cts.valueTextStl);
      Row row = Row(children: <Widget>[icTmp, txt]); 
      leftList.add(row);
   }

   Column col =
      Column( children: leftList
            , crossAxisAlignment: CrossAxisAlignment.start);

   return makePostElemSimple(ic, <Column>[col]);
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

      Card card = makePostElem(
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

   Card dc1 = makePostElem(context, values, cts.descList,
                           cts.personIcon);

   list.add(dc1);

   Card dc2 = makePostDetailElem(cts.personIcon, data.filter);
   list.add(dc2);

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
             title: Text( '${cts.postTimePrefix}: ${post.id}'
                        , style: cts.expTileStl),
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
                          (int fav) {onPostSelection(posts[idx], fav);},
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
         final String subStr = makeLeafCounterString(child.leafCounter);
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
         bgColor = cts.chatLongPressendColor;
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
   int filter = item['filter'];

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
   post.filter = filter;

   return post;
}

