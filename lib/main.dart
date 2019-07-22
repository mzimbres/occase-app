import 'dart:async';
import 'dart:convert';
import 'dart:io' show File, FileMode, Directory;
import 'dart:collection';

import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:flutter/services.dart';
import 'package:device_info/device_info.dart';
import 'package:flutter/scheduler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:intl/intl.dart';
import 'package:image_picker_modern/image_picker_modern.dart';

import 'package:flutter/material.dart';
import 'package:menu_chat/post.dart';
import 'package:menu_chat/tree.dart';
import 'package:menu_chat/constants.dart';
import 'package:menu_chat/txt_pt.dart' as txt;
import 'package:menu_chat/globals.dart' as glob;
import 'package:menu_chat/sql.dart' as sql;
import 'package:menu_chat/stl.dart' as stl;

class Coord {
   Post post;
   Chat chat;
   int msgIdx;

   Coord({this.post,
          this.chat,
          this.msgIdx = -1,
   });
}

void myprint(Coord c, String prefix)
{
   print('$prefix ===> (${c.post.id}, ${c.chat.peer}, ${c.msgIdx})');
}

void toggleChatPinDate(Chat chat)
{
   if (chat.pinDate == 0)
      chat.pinDate = DateTime.now().millisecondsSinceEpoch;
   else
      chat.pinDate = 0;
}

bool CompPostIdAndPeer(Coord a, Coord b)
{
   return a.post.id == b.post.id && a.chat.peer == b.chat.peer;
}

bool CompPeerAndChatIdx(Coord a, Coord b)
{
   return a.chat.peer == b.chat.peer && a.msgIdx == b.msgIdx;
}

void
handleLPChats(List<Coord> pairs, bool old, Coord coord, Function comp)
{
   if (old) {
      pairs.removeWhere((e) {return comp(e, coord);});
   } else {
      pairs.add(coord);
   }
}

Future<void> removeLpChat(Coord c, Database db) async
{
   // removeWhere could also be used, but that traverses all elements
   // always and we know there is only one element to remove.

   final bool ret = c.post.chats.remove(c.chat);
   assert(ret);

   print('${sql.deleteChatStElem} ${c.post.id} ${c.chat.peer}');
   final int n =
      await db.rawDelete(sql.deleteChatStElem,
         [c.post.id, c.chat.peer]);

   assert(n == 1);
}

Future<void>
onPinPost(List<Post> posts, int i, Database db) async
{
   if (posts[i].pinDate == 0) {
      posts[i].pinDate = DateTime.now().millisecondsSinceEpoch;
   } else {
      posts[i].pinDate = 0;
   }

   await db.execute(sql.updatePostPinDate,
                    [posts[i].pinDate, posts[i].id]);

   posts.sort(CompPosts);
}

Future<Null> main() async
{
  runApp(MyApp());
}

class ChatMsgOutQueueElem {
   int rowid;
   int isChat;
   String payload;
   bool sent; // Used for debugging.
   ChatMsgOutQueueElem({this.rowid = 0,
                        this.isChat = 0,
                        this.payload = '',
                        this.sent = false,
   });
}

Future<List<ChatMsgOutQueueElem>> loadOutChatMsg(Database db) async
{
  final List<Map<String, dynamic>> maps =
     await db.rawQuery(sql.loadOutChats);

  return List.generate(maps.length, (i)
  {
     return ChatMsgOutQueueElem(
        rowid: maps[i]['rowid'],
        isChat: maps[i]['is_chat'],
        payload: maps[i]['payload'],
        sent: false);
  });
}

String makePostPayload(final Post post)
{
   var pubMap = {
      'cmd': 'publish',
      'items': <Post>[post]
   };

   return jsonEncode(pubMap);
}

enum ConfigActions
{ ChangeNick
, ChangeProfilePhoto
}

Widget makeAppBarVertAction(Function onSelected)
{
   return PopupMenuButton<ConfigActions>(
     icon: Icon(Icons.more_vert, color: Colors.white),
     onSelected: onSelected,
     itemBuilder: (BuildContext ctx)
     {
        return <PopupMenuEntry<ConfigActions>>
        [
           const PopupMenuItem<ConfigActions>(
             value: ConfigActions.ChangeNick,
             child: Text(txt.changeNickStr),
           ),
           const PopupMenuItem<ConfigActions>(
             value: ConfigActions.ChangeProfilePhoto,
             child: Text(txt.changePhoto),
           ),
        ];
     }
   );
}

List<Widget>
makeOnLongPressedActions(BuildContext ctx,
                         Function deleteChatEntryDialog,
                         Function pinChat)
{
   List<Widget> actions = List<Widget>();

   IconButton pinChatBut = IconButton(
      icon: Icon(Icons.place, color: Colors.white),
      tooltip: txt.pinChatStr,
      onPressed: pinChat);

   actions.add(pinChatBut);

   IconButton delChatBut = IconButton(
      icon: Icon(Icons.delete_forever, color: Colors.white),
      tooltip: txt.deleteChatStr,
      onPressed: () { deleteChatEntryDialog(ctx); });

   actions.add(delChatBut);

   return actions;
}

Scaffold
makeWaitMenuScreen(BuildContext ctx)
{
   return Scaffold(
      appBar: AppBar(
         title: Text(
            txt.appName,
            style: Theme.of(ctx).appBarTheme.textTheme.title
         ),
         elevation: Theme.of(ctx).appBarTheme.elevation,
      ),
      body: Center(
         child: CircularProgressIndicator(),
      ),
   );
}

Scaffold
makeNickRegisterScreen( BuildContext ctx
                      , TextEditingController txtCtrl
                      , Function onNickPressed
                      , String appBarTitle)
{
   TextField tf = TextField(
      controller: txtCtrl,
      maxLines: 1,
      maxLength: 20,
      decoration: InputDecoration(
         hintText: txt.nickTextFieldHintStr,
         focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(20.0)),
            borderSide: BorderSide(
               color: Theme.of(ctx).primaryColor,
               width: 3.0),
         ),
         enabledBorder: OutlineInputBorder(
           borderRadius: BorderRadius.all(Radius.circular(20.0)),
           borderSide: BorderSide(
              color: Colors.red[900],
              width: 3.0
           ),
         ),
         suffixIcon: IconButton(
            icon: Icon(Icons.send),
            onPressed: onNickPressed,
            color: stl.postFrameColor,
         ),
      ),
   );

   return Scaffold(
      appBar: AppBar(
         title: Text(
            appBarTitle,
            style: Theme.of(ctx).appBarTheme.textTheme.title
         ),
         elevation: Theme.of(ctx).appBarTheme.elevation,
      ),
      body: Center(
         child: Padding(
            child: tf,
            padding: EdgeInsets.symmetric(horizontal: 20.0),
         ),
      ),
   );
}

ListView
makeNewPostFinalScreenWidget( BuildContext ctx
                            , Post post
                            , final List<MenuItem> menu
                            , TextEditingController txtCtrl
                            , onSendNewPostPressed)
{
   List<Card> cards =
      makeMenuInfoCards(ctx, post, menu, Theme.of(ctx).primaryColor);

   cards.add(makePostDetailElem(ctx, post.filter));

   TextField tf = TextField(
      controller: txtCtrl,
      keyboardType: TextInputType.multiline,
      maxLines: null,
      maxLength: 500,
      decoration:
         InputDecoration.collapsed(
            hintText: txt.newPostTextFieldHistStr));

   Card tfc = Card(
      child: Padding(child: Center(child: tf),
         padding: EdgeInsets.all(stl.postElemTextPadding)),
      color: stl.postLocHeaderColor,
      margin: EdgeInsets.all(stl.postInnerMargin),
      elevation: 0.0);

   cards.add(tfc);

   Card card = 
      makePostWidget( ctx
                    , cards
                    , (final int add) { onSendNewPostPressed(ctx, add); }
                    , Icon(Icons.publish, color: Colors.white)
                    , stl.postFrameColor);

   return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.all(0.0),
      children: <Widget>[card]);
}

WillPopScope
makeNewPostScreens( BuildContext ctx
                  , Post postInput
                  , final List<MenuItem> menu
                  , TextEditingController txtCtrl
                  , onSendNewPostPressed
                  , int screen
                  , Function onNewPostDetail
                  , Function onPostLeafPressed
                  , Function onPostNodePressed
                  , Function onWillPopMenu
                  , Function onNewPostBotBarTapped)
{
   Widget wid;
   Widget appBarTitle = Text(
         //txt.filterTabNames[screen],
         txt.newPostAppBarTitle,
         style: Theme.of(ctx).appBarTheme.textTheme.title);

   Widget appBarTitleWidget = appBarTitle;

   if (screen == 3) {
      wid = makeNewPostFinalScreenWidget(
         ctx,
         postInput,
         menu,
         txtCtrl,
         onSendNewPostPressed);

   } else if (screen == 2) {
      wid = makePostDetailScreen(ctx, onNewPostDetail, postInput.filter, 1);
   } else {
      wid = createPostMenuListView(
         ctx,
         menu[screen].root.last,
         onPostLeafPressed,
         onPostNodePressed);

      appBarTitleWidget = ListTile(
         title: appBarTitle,
         dense: true,
         subtitle: Text(menu[screen].getStackNames(),
                     style: Theme.of(ctx).appBarTheme.textTheme.subtitle));
   }

   AppBar appBar = AppBar(
      title: appBarTitleWidget,
      elevation: 0.7,
      leading: IconButton(
         icon: Icon(
            Icons.arrow_back,
            color: Theme.of(ctx).appBarTheme.iconTheme.color,
         ),
         onPressed: onWillPopMenu
      )
   );

   return WillPopScope(
       onWillPop: () async { return onWillPopMenu();},
       child: Scaffold(
           appBar: appBar,
           body: wid,
           bottomNavigationBar:
              makeBottomBarItems(
                 txt.newPostTabIcons,
                 txt.newPostTabNames,
                 onNewPostBotBarTapped,
                 screen)));
}

Widget
makeNewFiltersEndWidget( Function onSendNewFilters
                       , Function onCancelNewFilters)
{
   return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      //mainAxisSize: MainAxisSize.min,
      children: <Widget>
      [ Padding(
          padding: const EdgeInsets.symmetric(vertical: 40.0),
          child: createSendButton(onCancelNewFilters,
                                  'Cancelar',
                                  Colors.red))
      , Padding(
          padding: const EdgeInsets.symmetric(vertical: 40.0),
          child: createSendButton(onSendNewFilters,
                                  'Enviar',
                                  stl.postFrameColor))]);
}

WillPopScope
makeNewFiltersScreens( BuildContext ctx
                     , Function onSendFilters
                     , Function onFilterDetail
                     , Function onFilterNodePressed
                     , Function onWillPopMenu
                     , Function onBotBarTaped
                     , Function onFilterLeafNodePressed
                     , final List<MenuItem> menu
                     , int filter
                     , int screen
                     , Function onCancelNewFilters)
{
   Widget wid;
   Widget appBarTitle = Text(
      //txt.filterTabNames[screen],
      txt.filterAppBarTitle,
      maxLines: 1,
      overflow: TextOverflow.clip,
      style: Theme.of(ctx).appBarTheme.textTheme.title);

   Widget appBarTitleWidget = appBarTitle;

   if (screen == 3) {
      wid = makeNewFiltersEndWidget((){onSendFilters(ctx);},
                                    onCancelNewFilters);
   } else if (screen == 2) {
      wid = makePostDetailScreen(ctx, onFilterDetail, filter, 0);
   } else {
      wid = createFilterListView(
         ctx,
         menu[screen].root.last,
         onFilterLeafNodePressed,
         onFilterNodePressed,
         menu[screen].isFilterLeaf());

      appBarTitleWidget = ListTile(
         title: appBarTitle,
         dense: true,
         subtitle: Text(menu[screen].getStackNames(),
            maxLines: 1,
            overflow: TextOverflow.clip,
            style: Theme.of(ctx).appBarTheme.textTheme.subtitle));
   }

   AppBar appBar = AppBar(
      title: appBarTitleWidget,
      elevation: 0.7,
      leading: IconButton(
         icon: Icon(
            Icons.arrow_back,
            color: Theme.of(ctx).appBarTheme.iconTheme.color,
         ),
         onPressed: onWillPopMenu
      )
   );

   return WillPopScope(
       onWillPop: () async { return onWillPopMenu();},
       child: Scaffold(
           appBar: appBar,
           body: wid,
           bottomNavigationBar: makeBottomBarItems(
              txt.filterTabIcons,
              txt.filterTabNames,
              onBotBarTaped,
              screen)));
}

ListView
makePostDetailScreen( BuildContext ctx
                    , Function proceed
                    , int filter
                    , int shift)
{
   return ListView.builder(
      padding: const EdgeInsets.all(3.0),
      itemCount: txt.postDetails.length + shift,
      itemBuilder: (BuildContext ctx, int i)
      {
         if (i == txt.postDetails.length)
            return createSendButton((){proceed(i);},
                                    'Continuar',
                                    stl.postFrameColor);

         bool v = ((filter & (1 << i)) != 0);
         Color color = stl.selectedMenuColor;
         if (v)
            color = Theme.of(ctx).primaryColor;

         return CheckboxListTile(
            dense: true,
            secondary:
               makeCircleAvatar(
                  Text( txt.postDetails[i].substring(0, 2)
                      , style: TextStyle(color: Colors.white)
                  ),
                  color
               ),
            title: Text(
               txt.postDetails[i],
               style: Theme.of(ctx).textTheme.subhead,
            ),
            value: v,
            onChanged: (bool v) { proceed(i); },
            activeColor: color,
         );
      },
   );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext ctx) {
    return MaterialApp(
      title: txt.appName,
      //theme: ThemeData.dark(),
      theme: ThemeData(
          fontFamily: 'Montserrat',
          brightness: Brightness.light,
          primaryColor: stl.primaryColor,
          accentColor: stl.accentColor,
          appBarTheme: AppBarTheme(
             textTheme: TextTheme(
                title: TextStyle(
                   fontWeight: FontWeight.normal,
                   color: Colors.white,
                   fontSize: 20.0
                ),
                subtitle: TextStyle(
                   color: Colors.grey[300],
                   fontSize: 14.0
                ),
             ),
             iconTheme: IconThemeData(
                color: Colors.white,
             ),
          ),
          textTheme: TextTheme(
             subtitle: TextStyle(
                fontWeight: FontWeight.normal,
                color: Colors.grey[600]
             ),
             subhead: TextStyle(
                fontWeight: FontWeight.w500,
             ),
          ),
      ),
      debugShowCheckedModeBanner: false,
      home: MenuChat(),
    );
  }
}

TabBar
makeTabBar(BuildContext ctx,
           List<int> counters,
           TabController tabCtrl,
           List<double> opacity,
           bool isFwd)
{
   if (isFwd)
      return null;

   List<Widget> tabs = List<Widget>(txt.tabNames.length);

   for (int i = 0; i < tabs.length; ++i) {
      tabs[i] = Tab(
         child: makeTabWidget( ctx,
            counters[i], txt.tabNames[i], opacity[i]));
   }

   return TabBar(controller: tabCtrl,
                 indicatorColor: Colors.white,
                 tabs: tabs);
}

BottomNavigationBar
makeBottomBarItems(List<IconData> icons,
                   List<String> iconLabels,
                   Function onBotBarTapped,
                   int i)
{
   assert(icons.length == iconLabels.length);
   final int length = icons.length;

   List<BottomNavigationBarItem> items =
         List<BottomNavigationBarItem>(length);

   for (int i = 0; i < length; ++i) {
      items[i] = BottomNavigationBarItem(
                    icon: Icon(icons[i]),
                    title: Text(iconLabels[i]));
   }

   return BottomNavigationBar(
             items: items,
             type: BottomNavigationBarType.fixed,
             currentIndex: i,
             onTap: onBotBarTapped);
}

FloatingActionButton
makeFiltersFaButton(Function onNewPost, IconData id)
{
   return FloatingActionButton(
      backgroundColor: stl.faButtonColor,
      child: Icon(id, color: Colors.white),
      onPressed: onNewPost
   );
}

FloatingActionButton
makeFaButton(Function onNewPost,
             Function onFwdChatMsg,
             int lpChats,
             int lpChatMsgs)
{
   if (lpChats == 0 && lpChatMsgs != 0)
      return null;

   IconData id = txt.newPostIcon;
   if (lpChats != 0 && lpChatMsgs != 0) {
      return FloatingActionButton(
         backgroundColor: stl.darkYellow,
         child: Icon(Icons.send, color: Colors.white),
         onPressed: onFwdChatMsg);
   }

   if (lpChats != 0)
      return null;

   if (onNewPost == null)
      return null;

   return FloatingActionButton(
      backgroundColor: stl.faButtonColor,
      child: Icon(id, color: Colors.white),
      onPressed: onNewPost);
}

int postIndexHelper(int i)
{
   if (i == 0) return 1;
   if (i == 1) return 2;
   if (i == 2) return 3;
   return 1;
}

Card
makeChatMsgWidget(
   BuildContext ctx,
   Chat ch,
   int i,
   Function onChatMsgLongPressed,
   Function onDragChatMsg)
{
   Alignment align = Alignment.bottomLeft;
   Color color = Color(0xFFFFFFFF);
   Color onSelectedMsgColor = Colors.grey[300];
   if (ch.msgs[i].isFromThisApp()) {
      align = Alignment.bottomRight;
      color = Colors.lime[100];
   }

   if (ch.msgs[i].isLongPressed)
      onSelectedMsgColor = Colors.blue[200];

   RichText msgAndDate = RichText(
      text: TextSpan(
         text: ch.msgs[i].msg,
         style: Theme.of(ctx).textTheme.body1,
         children: <TextSpan>
         [TextSpan(
            text: '  ${makeDateString(ch.msgs[i].date)}',
            style: Theme.of(ctx).textTheme.caption)]));

   // Unfourtunately TextSpan still does not support general
   // widgets so I have to put the msg status in a row instead
   // of simply appending it to the richtext as I do for the
   // date. Hopefully this will be fixed this later.
   Widget msgAndStatus;
   if (ch.msgs[i].isFromThisApp()) {
      msgAndStatus = Row(
         mainAxisSize: MainAxisSize.min,
         mainAxisAlignment: MainAxisAlignment.end,
         children: <Widget>
      [ Flexible(child: Padding(
            padding: EdgeInsets.all(stl.chatMsgPadding),
            child: msgAndDate))
      , Padding(
            padding: EdgeInsets.all(2.0),
            child: chooseMsgStatusIcon(ch, i))
      ]);
   } else {
      msgAndStatus = Padding(
            padding: EdgeInsets.all(stl.chatMsgPadding),
            child: msgAndDate);
   }

   Widget ww = msgAndStatus;
   if (ch.msgs[i].isRedirected()) {
      Row redirWidget = Row(
         mainAxisSize: MainAxisSize.min,
         mainAxisAlignment: MainAxisAlignment.start,
         crossAxisAlignment: CrossAxisAlignment.center,
         textBaseline: TextBaseline.alphabetic,
         children: <Widget>
         [ Icon(Icons.forward, color: Colors.blueGrey)
         , Text(txt.chatMsgRedirectedText,
                style: TextStyle(color: Colors.blueGrey,
                  fontSize: stl.listTileSubtitleFontSize,
                 fontStyle: FontStyle.italic))
         ]);

      ww = Column( children: <Widget>
         [ Padding(
              padding: EdgeInsets.all(3.0),
              child: redirWidget)
         , msgAndStatus
         ]);
   } else if (ch.msgs[i].refersToOther()) {
      final int refersTo = ch.msgs[i].refersTo;
      final Color c1 = selectColor(int.parse(ch.peer));
      SizedBox sb = SizedBox(
         width: 4.0,
         height: 60.0,
         child: DecoratedBox(
           decoration: BoxDecoration(
             color: c1)));

      Row refMsg = Row(
         mainAxisSize: MainAxisSize.min,
         crossAxisAlignment: CrossAxisAlignment.start,
         children: <Widget>
         [ Padding(
              padding: const EdgeInsets.all(5.0),
              child: sb,
           )
         , Flexible(
              child: Padding(
                 padding: const EdgeInsets.symmetric(horizontal: 5.0),
                 child: makeRefChatMsgWidget(ctx, ch, refersTo, c1),
              )
           )
         ]
      );

      ww = Column(
         mainAxisSize: MainAxisSize.min,
         crossAxisAlignment: CrossAxisAlignment.start,
         children: <Widget>
         [ refMsg
         , msgAndStatus
         ]);
   }

   double marginLeft = 10.0;
   double marginRight = 0.0;
   if (ch.msgs[i].isFromThisApp()) {
      double tmp = marginLeft;
      marginLeft = marginRight;
      marginRight = tmp;
   }

   Card w1 = Card(
      margin: EdgeInsets.only(
            left: marginLeft,
            top: 2.0,
            right: marginRight,
            bottom: 0.0),
      elevation: 3.0,
      color: color,
      child: Center(
         widthFactor: 1.0,
         child: ConstrainedBox(
            constraints: BoxConstraints(
               maxWidth: 290.0,
               minWidth: 35.0),
            child: ww)));

   Row r = null;
   if (ch.msgs[i].isFromThisApp()) {
      r = Row(children: <Widget>
      [ Spacer()
      , w1
      ]);
   } else {
      r = Row(children: <Widget>
      [ w1
      , Spacer()
      ]);
   }

   return Card(
      child: r,
      color: onSelectedMsgColor,
      elevation: 0.0,
      margin: const EdgeInsets.all(0.0),
      shape: RoundedRectangleBorder(
         borderRadius: BorderRadius.all(Radius.circular(0.0)),
      ),
   );
}

ListView
makeChatMsgListView(
   BuildContext ctx,
   ScrollController scrollCtrl,
   Chat ch,
   Function onChatSendPressed,
   Function onChatMsgLongPressed,
   Function onDragChatMsg)
{
   final int nMsgs = ch.msgs.length;
   final int shift = ch.nUnreadMsgs == 0 ? 0 : 1;

   return ListView.builder(
      controller: scrollCtrl,
      reverse: false,
      padding: const EdgeInsets.only(bottom: 3.0, top: 3.0),
      itemCount: nMsgs + shift,
      itemBuilder: (BuildContext ctx, int i)
      {
         if (shift == 1) {
            if (i == nMsgs - ch.nUnreadMsgs) {
               return Card(
                  color: Colors.white,
                  margin: const EdgeInsets.symmetric(vertical: 10.0),
                  shape: RoundedRectangleBorder(
                     borderRadius: BorderRadius.all(Radius.circular(0.0)),
                  ),
                  child: Center(
                      child: Padding(
                         padding: EdgeInsets.all(3.0),
                         child: Text(
                            '${ch.nUnreadMsgs} nao lidas.',
                            style: TextStyle(
                               fontSize: 17.0,
                               fontWeight: FontWeight.normal,
                               color: Theme.of(ctx).primaryColor,
                            ),
                         )
                      ),
                   ),
               );
            }

            if (i > (nMsgs - ch.nUnreadMsgs))
               i -= 1; // For the shift
         }

         Card chatMsgWidget =
            makeChatMsgWidget( ctx,
               ch, i, onChatMsgLongPressed,
               onDragChatMsg);

         return GestureDetector(
            onLongPress: () {onChatMsgLongPressed(i, false);},
            onTap: () {onChatMsgLongPressed(i, true);},
            onHorizontalDragStart: (DragStartDetails d) {onDragChatMsg(ctx, i, d);},
            child: chatMsgWidget);
      },
   );
}

Card makeChatScreenBotCard(Widget w1, Widget w1a, Widget w2,
                           Widget w3, Widget w4)
{
   const double padding = 10.0;
   const EdgeInsets ei = const EdgeInsets.symmetric(horizontal: padding);
   Padding placeholder = Padding(
      child: Icon(Icons.send, color: Colors.white),
         padding: ei);

   List<Widget> widgets = List<Widget>();
   if (w1 == null) {
      widgets.add(placeholder);
   } else {
      widgets.add(Padding(child: w1, padding: ei));
   }

   if (w1a != null)
      widgets.add(w1a);

   widgets.add(Expanded(
      child: Padding(child: w2, padding: ei)));

   if (w3 == null) {
      widgets.add(placeholder);
   } else {
      widgets.add(Padding(child: w3, padding: ei));
   }

   if (w4 == null) {
      widgets.add(placeholder);
   } else {
      widgets.add(Padding(child: w4, padding: ei));
   }

   Row rr = Row(children: widgets);

   return Card(
      elevation: 0.0,
      shape: RoundedRectangleBorder(
         borderRadius: BorderRadius.all(Radius.circular(0.0))),
      margin: EdgeInsets.all(0.0),
      color: Colors.white,
      child: Padding(
         padding: EdgeInsets.all(4.0),
         child: ConstrainedBox(
            constraints: BoxConstraints(
            maxHeight: 140.0,
            minHeight: 45.0),
            child: rr)));
}

Widget
makeRefChatMsgWidget(
   BuildContext ctx,
   Chat ch,
   int i,
   Color cc)
{
   print('===> ${ch.msgs.length} $i');
   Text body = Text(ch.msgs[i].msg,
      maxLines: 3,
      overflow: TextOverflow.clip,
      style: Theme.of(ctx).textTheme.caption);

   Text title = Text(ch.nick,
      maxLines: 1,
      overflow: TextOverflow.clip,
      style: TextStyle(fontSize: stl.mainFontSize,
             fontWeight: FontWeight.bold,
             color: cc));

   Column col = Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>
      [ Padding(
           child: title,
           padding: const EdgeInsets.symmetric(vertical: 3.0))
      , body
      ]);

   return col;
}

Widget
makeChatScreen(BuildContext ctx,
               Function onWillPopScope,
               Chat ch,
               TextEditingController ctrl,
               Function onChatSendPressed,
               ScrollController scrollCtrl,
               Function onChatMsgLongPressed,
               int nLongPressed,
               Function onFwdChatMsg,
               Function onDragChatMsg,
               FocusNode chatFocusNode,
               Function onChatMsgReply,
               String postSummary,
               Function onAttachment,
               int dragedIdx,
               Function onCancelFwdLPChatMsg)
{
   IconButton sendButton =
      IconButton(
         icon: Icon(Icons.send),
         onPressed: onChatSendPressed,
         color: Colors.grey);

   // Either Icons.attachment or Icons.add_a_photo
   IconButton attachmentButton =
      IconButton(icon: Icon(Icons.add_a_photo),
                 onPressed: onAttachment,
                 color: Colors.grey);

   List<Widget> editButtons = List<Widget>();
   //if (ctrl.text.isEmpty) // Let this for later.
   editButtons.add(attachmentButton);
   editButtons.add(sendButton);

   Row buttons = Row(
      mainAxisSize: MainAxisSize.min,
      children: editButtons);

   TextField tf = TextField(
       style: Theme.of(ctx).textTheme.body1,
       controller: ctrl,
       //textInputAction: TextInputAction.go,
       //onSubmitted: onTextFieldPressed,
       keyboardType: TextInputType.multiline,
       maxLines: null,
       maxLength: null,
       focusNode: chatFocusNode,
       decoration:
          InputDecoration.collapsed(hintText: txt.chatTextFieldHintStr));

   Scrollbar sb = Scrollbar(
       child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          reverse: true,
          child: tf));

   Card card = makeChatScreenBotCard(null, null, sb, null, null);

   ListView list = makeChatMsgListView(
         ctx,
         scrollCtrl,
         ch,
         onChatSendPressed,
         onChatMsgLongPressed,
         onDragChatMsg);

   List<Widget> cols = List<Widget>();
   cols.add(Expanded(child: list));
   if (dragedIdx != -1) {
      Color co1 = selectColor(int.parse(ch.peer));
      Icon w1 = Icon(Icons.forward, color: Colors.grey);

      // It looks like there is not maxlines option on TextSpan, so
      // for now I wont be able to show the date at the end.
      Widget w2 = Padding(
         padding: const EdgeInsets.symmetric(horizontal: 5.0),
         child: makeRefChatMsgWidget(ctx, ch, dragedIdx, co1),
      );

      IconButton w4 = IconButton(
         icon: Icon(Icons.clear, color: Colors.grey),
         onPressed: onCancelFwdLPChatMsg);

      SizedBox sb = SizedBox(
         width: 4.0,
         height: 60.0,
         child: DecoratedBox(
           decoration: BoxDecoration(
             color: co1)));

      Card c1 = makeChatScreenBotCard(w1, sb, w2, null, w4);
      cols.add(c1);
      cols.add(Divider(color: Colors.deepOrange, height: 0.0));
   }

   cols.add(card);

   Stack mainCol = Stack(children: <Widget>
   [ Column(children: cols)
   , Positioned(child: buttons, bottom: 1.0, right: 1.0)
   ]);

   List<Widget> actions = List<Widget>();
   Widget title = null;

   if (nLongPressed == 1) {
      IconButton reply = IconButton(
         icon: Icon(Icons.reply, color: Colors.white),
         onPressed: () {onChatMsgReply(ctx);});

      actions.add(reply);
   }

   if (nLongPressed > 0) {
      IconButton forward = IconButton(
         icon: Icon(Icons.forward, color: Colors.white),
         onPressed: onFwdChatMsg);

      actions.add(forward);

      title = Text('$nLongPressed',
            maxLines: 1,
            overflow: TextOverflow.clip,
            style: Theme.of(ctx).appBarTheme.textTheme.title);
   } else {
      title = ListTile(
          leading: CircleAvatar(
              child: txt.unknownPersonIcon,
              backgroundColor: selectColor(int.parse(ch.peer))),
          title: Text(ch.getChatDisplayName(),
                maxLines: 1,
                overflow: TextOverflow.clip,
                style: Theme.of(ctx).appBarTheme.textTheme.title),
          dense: true,
          subtitle:
             Text(postSummary,
                maxLines: 1,
                overflow: TextOverflow.clip,
                style: Theme.of(ctx).appBarTheme.textTheme.subtitle)
       );
   }

   return WillPopScope(
          onWillPop: () async { return onWillPopScope();},
          child: Scaffold(
             appBar : AppBar(
                titleSpacing: 0.0,
                actions: actions,
                title: title,
                backgroundColor: Theme.of(ctx).primaryColor,
                leading: IconButton(
                   icon: Icon(
                      Icons.arrow_back,
                      color: Theme.of(ctx).appBarTheme.iconTheme.color),
                 onPressed: onWillPopScope)
             ),
          body: mainCol,
          backgroundColor: Colors.grey[300],
       )
    );
}

Widget makeTabWidget(BuildContext ctx, int n, String title, double opacity)
{
   if (n == 0)
      return Text(title);

   List<Widget> widgets = List<Widget>(2);
   widgets[0] = Text(title);

   // See: https://docs.flutter.io/flutter/material/TabBar/labelColor.html
   // for opacity values.
   widgets[1] =
      Opacity( child: makeCircleUnreadMsgs(ctx, n, Colors.white,
                      stl.primaryColor)
             , opacity: opacity);

   return Row(children: widgets);
}

CircleAvatar makeCircleAvatar(Widget child, Color bgcolor)
{
   return CircleAvatar(child: child, backgroundColor: bgcolor);
}

CircleAvatar
makeChatListTileLeading(Widget child, Color bgcolor,
                        Function onLeadingPressed)
{
   Stack st = Stack(children: <Widget>
   [ Center(child: child)
   , OutlineButton(child: Text(''),
                   borderSide: BorderSide(
                      style: BorderStyle.none),
                   onPressed: onLeadingPressed,
                   shape: CircleBorder())]);
   return CircleAvatar(child: st, backgroundColor: bgcolor);
}

String makeStrAbbrev(final String str)
{
   if (str.length < 2)
      return str;

   return str.substring(0, 2);
}

RichText
makeFilterListTileTitleWidget(
   String str1,
   String str2,
   TextStyle stl1,
   TextStyle stl2)
{
   return RichText(
      text: TextSpan(
         text: str1,
         style: stl1,
         children: <TextSpan>
         [TextSpan(text: str2, style: stl2)]));
}

/*
 *  To support the "select all" buttom in the menu checkbox we have to
 *  add some complex logic.  First we note that the "Todos" checkbox
 *  should appear in all screens that present checkboxes, namely, when
 *  
 *  1. makeLeaf is true, or
 *  2. isLeaf is true for more than one node.
 *
 *  In those cases the builder will go through all node children
 *  otherwise the first should be skipped.
 */
ListView createFilterListView(BuildContext ctx,
                              MenuNode o,
                              Function onLeafPressed,
                              Function onNodePressed,
                              bool makeLeaf)
{
   // TODO: We should check all children and not only the last.
   int shift = 0;
   if (makeLeaf || o.children.last.isLeaf())
      shift = 1;

   return ListView.builder(
      //padding: const EdgeInsets.all(8.0),
      itemCount: o.children.length + shift,
      itemBuilder: (BuildContext ctx, int i)
      {
         if (shift == 1 && i == 0) {
            // Handles the *select all* button.
            return ListTile(
                leading: Icon(
                   Icons.select_all,
                   size: 35.0,
                   color: Theme.of(ctx).primaryColor),
                title: Text(
                   txt.menuSelectAllStr,
                   style: Theme.of(ctx).textTheme.subhead,
                ),
                dense: true,
                onTap: () { onLeafPressed(0); },
                enabled: true,);
         }

         if (shift == 1) {
            MenuNode child = o.children[i - 1];
            Widget icon = Icon(Icons.check_box_outline_blank);
            if (child.leafReach > 0)
               icon = Icon(Icons.check_box);

            Widget subtitle = null;
            if (!child.isLeaf()) {
               subtitle =  Text(
                   child.getChildrenNames(),
                   style: Theme.of(ctx).textTheme.subtitle,
                   maxLines: 2,
                   overflow: TextOverflow.clip);
            }

            Color cc = Colors.grey;
            if (child.leafReach > 0)
               cc = Theme.of(ctx).primaryColor;

            String s = '';
            if (child.leafCounter > 1)
               s = ' (${child.leafCounter})';

            RichText title = RichText(
               text: TextSpan(
                  text: child.name,
                  style: Theme.of(ctx).textTheme.subhead,
                  children: <TextSpan>
                  [ TextSpan(
                       text: s,
                       style: Theme.of(ctx).textTheme.caption,
                    ),
                  ]
               )
            );

            // Notice we do not subtract -1 on onLeafPressed so that
            // this function can diferentiate the Todos button case.
            final String abbrev = makeStrAbbrev(child.name);
            return ListTile(
                leading: makeCircleAvatar(
                   Text(abbrev, style: TextStyle(color: Colors.white)),
                   cc
                ),
                title: title,
                dense: true,
                subtitle: subtitle,
                trailing: icon,
                contentPadding: EdgeInsets.symmetric(horizontal: 10.0),
                onTap: () { onLeafPressed(i);},
                enabled: true,
                selected: child.leafReach > 0,
                isThreeLine: !child.isLeaf());
         }

         final int c = o.children[i].leafReach;
         final int cs = o.children[i].leafCounter;

         final String subtitle = o.children[i].getChildrenNames();
         final String titleStr = '${o.children[i].name}';
         Color cc = Colors.grey;
         if (c != 0)
            cc = Theme.of(ctx).primaryColor;

         RichText title = RichText(
            text: TextSpan(
               text: titleStr,
               style: Theme.of(ctx).textTheme.subhead,
               children: <TextSpan>
               [TextSpan(
                  text: ' ($c/$cs)',
                  style: Theme.of(ctx).textTheme.caption),
               ]
            )
         );
               
         return
            ListTile(
                leading: makeCircleAvatar(
                   Text(makeStrAbbrev(o.children[i].name),
                        style: TextStyle(color: Colors.white)), cc),
                title: title,
                dense: true,
                subtitle: Text(
                   subtitle,
                   style: Theme.of(ctx).textTheme.subtitle,
                   maxLines: 2,
                   overflow: TextOverflow.clip),
                trailing: Icon(Icons.keyboard_arrow_right),
                contentPadding: EdgeInsets.symmetric(horizontal: 10.0),
                onTap: () { onNodePressed(i); },
                enabled: true,
                selected: c != 0,
                isThreeLine: true,
                );
      },
   );
}

Widget
createSendButton(Function onPressed,
                 final String txt,
                 Color color)
{
   RaisedButton but =
      RaisedButton(
         child: Text(txt,
            style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: stl.mainFontSize)),
         color: color,
         onPressed: onPressed);

   return Center(child: ButtonTheme(minWidth: 100.0, child: but));
}

// Study how to convert this into an elipsis like whatsapp.
Container makeCircleUnreadMsgs(BuildContext ctx,
      int n, Color bgColor, Color textColor)
{
   final Text txt =
      Text("${n}",
           style: TextStyle(
              color: textColor,
              fontSize: Theme.of(ctx).textTheme.caption.fontSize));
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

Card makePostElemSimple(Icon ic, Widget cols)
{
   List<Widget> r = List<Widget>();
   r.add(Padding(child: Center(child: ic), padding: EdgeInsets.all(4.0)));
   r.add(cols);

   // Padding needed to show the text inside the post element with some
   // distance from the border.
   Padding leftWidget = Padding(
         padding: EdgeInsets.all(stl.postElemTextPadding),
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
      margin: EdgeInsets.all(stl.postInnerMargin),
      elevation: 0.0,
   );
}

Card makePostElem2( BuildContext ctx
                  , List<String> values
                  , List<String> keys
                  , Icon ic)
{
   List<Widget> list = List<Widget>();

   for (int i = 0; i < values.length; ++i) {
      RichText left = RichText(
         text: TextSpan(
            text: keys[i] + ': ',
            style: Theme.of(ctx).textTheme.subhead,
         )
      );

      RichText right = RichText(
         text: TextSpan(
            text: values[i],
            style: Theme.of(ctx).textTheme.body1
         ),
      );
      Row row = Row(
         mainAxisSize: MainAxisSize.min,
         mainAxisAlignment: MainAxisAlignment.start,
         children: <Widget>
         [ ConstrainedBox(
            constraints: BoxConstraints(
               maxWidth: 100.0,
               minWidth: 100.0),
            child: left)
         ,  ConstrainedBox(
            constraints: BoxConstraints(
               maxWidth: 250.0,
               minWidth: 250.0),
            child: right)
         ]);

      list.add(row);
   }

   Column col = Column(children: list);

   return makePostElemSimple(ic, col);
}

Card makePostDetailElem(BuildContext ctx, int filter)
{
   List<Widget> leftList = List<Widget>();

   for (int i = 0; i < txt.postDetails.length; ++i) {
      final bool b = (filter & (1 << i)) == 0;
      if (b)
         continue;

      Icon icTmp = Icon(Icons.check, color: stl.postFrameColor);
      Text text = Text(
         ' ${txt.postDetails[i]}',
         style: Theme.of(ctx).textTheme.body1,
      );
      Row row = Row(children: <Widget>[icTmp, text]); 
      leftList.add(row);
   }

   Column col =
      Column( children: leftList
            , crossAxisAlignment: CrossAxisAlignment.start);

   Icon ic = Icon(Icons.details, color: stl.postFrameColor);
   return makePostElemSimple(ic, col);
}

List<Card>
makeMenuInfoCards(BuildContext ctx,
                  Post data,
                  List<MenuItem> menus,
                  Color color)
{
   List<Card> list = List<Card>();

   for (int i = 0; i < data.channel.length; ++i) {
      List<String> names =
            loadNames(menus[i].root.first, data.channel[i][0]);

      Card card = makePostElem2(
                     ctx,
                     names,
                     txt.menuDepthNames[i],
                     Icon( txt.newPostTabIcons[i]
                         , color: stl.postFrameColor));

      list.add(card);
   }

   return list;
}

// Will assemble menu information and the description in cards
List<Card> postTextAssembler(BuildContext ctx,
                            Post post,
                            List<MenuItem> menus,
                            Color color)
{
   List<Card> list = makeMenuInfoCards(ctx, post, menus, color);
   DateTime date = DateTime.fromMillisecondsSinceEpoch(post.date);
   DateFormat format = DateFormat.yMd().add_jm();
   String dateString = format.format(date);

   List<String> values1 = List<String>();
   values1.add(post.nick);
   values1.add('${post.from}');
   values1.add('${post.id}');
   values1.add(dateString);

   Card dc1 = makePostElem2(
      ctx, values1, txt.descList,
      Icon(Icons.description,
           color: stl.postFrameColor));

   list.add(dc1);

   if (!post.description.isEmpty) {
      ConstrainedBox t = ConstrainedBox(
            constraints: BoxConstraints(
               maxWidth: 300.0,
               minWidth: 300.0),
            child: Text(post.description));

      list.add(makePostElemSimple(Icon(Icons.clear), t));
   }

   list.add(makePostDetailElem(ctx, post.filter));

   return list;
}

String makePostSummaryStr(MenuNode root, Post post)
{
   final List<String> names = loadNames(root, post.channel[1][0]);
   return names.join('/');
}

ThemeData makeExpTileThemeData()
{
   return ThemeData(
      accentColor: stl.expTileSelectedColor,
      unselectedWidgetColor: stl.expTileUnselectedColor,
      textTheme: TextTheme(
         subhead: TextStyle(
            color: stl.expTileUnselectedColor,
         ),
      ),
   );
}

Card makeChatEntry(BuildContext ctx,
                   Post post,
                   List<MenuItem> menus,
                   Widget chats,
                   Function onLeadingPressed,
                   IconData ic)
{
   List<Card> textCards = postTextAssembler(ctx, post, menus,
                                       stl.postFrameColor);


   final String postSummaryStr =
      makePostSummaryStr(menus[1].root.first, post);

   Widget card = Theme(
         data: makeExpTileThemeData(),
         child: ExpansionTile(
             backgroundColor: stl.expTileExpColor,
             leading: IconButton(
                icon: Icon(ic),
                onPressed: onLeadingPressed,
             ),
             key: PageStorageKey<int>(2 * post.id),
             title: Text(
                postSummaryStr,
                maxLines: 1,
                overflow: TextOverflow.clip,
             ),
             children: ListTile.divideTiles(
                        context: ctx,
                        tiles: textCards,
                        color: Colors.grey).toList()
          ),
      );

   List<Widget> cards = List<Widget>();
   cards.add(card);

   cards.add(
      Padding(
         padding: const EdgeInsets.only(bottom: 5.0),
         child: chats,
      ),
   );

   return Card(
      margin: const EdgeInsets.only(left: 1.5, right: 1.5, top: 4.0),
      child: Column(children: cards),
      color: stl.postFrameColor,
      elevation: 0.0,
      shape: RoundedRectangleBorder(
         borderRadius: BorderRadius.all(Radius.circular(10.0)),
      ),
   );
}

Card makePostWidget(BuildContext ctx,
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
                         color: Theme.of(ctx).primaryColor,
                         iconSize: 30.0);

   Row row = Row(children: <Widget>[
                Expanded(child: icon1),
                Expanded(child: icon2)]);

   Card c4 = Card(
      child: row,
      color: color,
      margin: EdgeInsets.all(stl.postInnerMargin),
      elevation: 0.0,
   );

   cards.add(c4);

   Column col = Column(
      mainAxisSize: MainAxisSize.min,
      children: cards);

   final double padding = stl.outerPostCardPadding;
   return Card(
      child: Padding(child: col, padding: EdgeInsets.all(padding)),
      color: color,
      margin: EdgeInsets.all(stl.postMarging),
      elevation: 5.0,
   );
}

Card makeCard(Widget widget, Color color)
{
   return Card(
      child: Padding(child: widget,
         padding: EdgeInsets.all(stl.postElemTextPadding)),
      color: color,
      margin: EdgeInsets.all(stl.postInnerMargin),
      elevation: 0.0,
   );
}

ListView
makePostTabListView(BuildContext ctx,
                    List<Post> posts,
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
         Color color = stl.postFrameColor;
         //if (i > lastSeenPostIdx)
         //   color = txt.newReceivedPostColor; 

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
             txt.favIcon,
             color);
      });
}

ListView createPostMenuListView(BuildContext ctx, MenuNode o,
      Function onLeafPressed, Function onNodePressed)
{
   return ListView.builder(
      itemCount: o.children.length,
      itemBuilder: (BuildContext ctx, int i)
      {
         final int c = o.children[i].leafReach;
         final int cs = o.children[i].leafCounter;

         final String names = o.children[i].getChildrenNames();

         MenuNode child = o.children[i];
         if (child.isLeaf()) {
            return ListTile(
                leading: makeCircleAvatar(
                   Text(makeStrAbbrev(child.name),
                        style: TextStyle(color: Colors.white)),
                   Colors.grey),
                title: Text(
                   child.name,
                   style: Theme.of(ctx).textTheme.subhead
                ),
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
                         style: TextStyle(color: Colors.white)),
                   Colors.grey),
                title: Text(
                   o.children[i].name,
                   style: Theme.of(ctx).textTheme.subhead,
                ),
                dense: true,
                subtitle: Text(
                   names,
                   style: Theme.of(ctx).textTheme.subtitle,
                   maxLines: 2,
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
Widget chooseMsgStatusIcon(Chat ch, int i)
{
   final double s = 20.0;

   Icon icon = Icon(Icons.clear, color: Colors.grey, size: s);

   if (i < ch.appAckReadEnd)
      icon = Icon(Icons.done_all, color: Colors.green, size: s);
   else if (i < ch.appAckReceivedEnd) {
      icon = Icon(Icons.done_all, color: Colors.grey, size: s);
   } else if (i < ch.serverAckEnd) {
      icon = Icon(Icons.check, color: Colors.grey, size: s);
   }

   return Padding(
      child: icon,
      padding: const EdgeInsets.symmetric(horizontal: 2.0));
}

Widget makeChatTileSubtitle(BuildContext ctx, final Chat ch)
{
   String str = ch.lastChatItem.msg;
   if (str.isEmpty) {
      return Text(
         txt.defaultChatTileSubtile,
         maxLines: 1,
         overflow: TextOverflow.clip,
         style: TextStyle(
            color: Colors.grey,
            fontStyle: FontStyle.italic,
            fontSize: Theme.of(ctx).textTheme.subtitle.fontSize
         ),
      );
   }

   if (ch.nUnreadMsgs > 0 || !ch.lastChatItem.isFromThisApp())
      return Text(
         str,
         style: Theme.of(ctx).textTheme.subtitle,
         maxLines: 1,
         overflow: TextOverflow.clip);

   return Row(children: <Widget>
   [ chooseMsgStatusIcon(ch, ch.chatLength - 1)
   , Expanded(
      child: Text(
         str,
         style: Theme.of(ctx).textTheme.subtitle,
         maxLines: 1, overflow: TextOverflow.clip))]);
}

String makeDateString(int date)
{
   DateTime dateObj = DateTime.fromMillisecondsSinceEpoch(date);
   DateFormat format = DateFormat.Hm();
   return format.format(dateObj);
}

Widget
makeChatListTileTrailingWidget(
   BuildContext ctx,
   int nUnreadMsgs,
   int date,
   int pinDate,
   int now,
   bool isFwdChatMsgs)
{
   if (isFwdChatMsgs)
      return null;

   Text dateText = Text(
      makeDateString(date),
      style: Theme.of(ctx).textTheme.caption,
   );

   if (nUnreadMsgs != 0 && pinDate != 0) {
      Row row = Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>
      [ Icon(Icons.place)
      , makeCircleUnreadMsgs(
          ctx, nUnreadMsgs, stl.newMsgCircleColor,
                             Colors.white)]);
      
      return Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget> [dateText, row]);
   } 
   
   if (nUnreadMsgs == 0 && pinDate != 0) {
      return Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget> [dateText, Icon(Icons.place)]);
   }
   
   if (nUnreadMsgs != 0 && pinDate == 0) {
      return Column(
         mainAxisSize: MainAxisSize.min,
         children: <Widget>
         [ dateText
         , makeCircleUnreadMsgs(ctx, nUnreadMsgs, stl.newMsgCircleColor,
                                Colors.white)
         ]);
   }

   return dateText;
}

Color selectColor(int n)
{
   final int v = n % 14;
   switch (v) {
      case 0: return Colors.yellow[500];
      case 1: return Colors.pink;
      case 2: return Colors.pink;
      case 3: return Colors.pinkAccent;
      case 4: return Colors.redAccent;
      case 5: return Colors.deepOrange;
      case 6: return Colors.teal;
      case 7: return Colors.orange;
      case 8: return Colors.orangeAccent;
      case 9: return Colors.amberAccent;
      case 10: return Colors.lightGreen;
      case 11: return Colors.deepOrange[300];
      case 12: return Colors.teal[100];
      case 13: return Colors.green[500];
      case 14: return Colors.green[400];
      default: return Colors.grey;
   }
}

Widget makePostChatCol(
   BuildContext ctx,
   List<Chat> ch,
   Function onPressed,
   Function onLongPressed,
   Post post,
   bool isFwdChatMsgs,
   Function onLeadingPressed,
   int now,
   Function onPinPost,
   bool isFav)
{
   List<Widget> list = List<Widget>(ch.length);

   int nUnredChats = 0;
   for (int i = 0; i < list.length; ++i) {
      final int n = ch[i].nUnreadMsgs;
      if (n > 0)
         ++nUnredChats;

      Widget widget;
      Color bgColor;
      if (ch[i].isLongPressed) {
         widget = Icon(Icons.check);
         bgColor = stl.chatLongPressendColor;
      } else {
         widget = txt.unknownPersonIcon;
         bgColor = Colors.white;
      }

      Widget trailing = makeChatListTileTrailingWidget(
         ctx, n, ch[i].lastChatItem.date, ch[i].pinDate, now,
         isFwdChatMsgs);

      list[i] = Padding(
         padding: EdgeInsets.only(
            left: stl.postInnerMargin,
            right: stl.postInnerMargin,
            top: 1.5,
            bottom: 0.0,
         ),
         child: Container(
            margin: const EdgeInsets.only(bottom: 3.0),
            decoration: BoxDecoration(
               borderRadius: BorderRadius.all(Radius.circular(10.0)),
               color: bgColor),
            child: ListTile(
               dense: false,
               enabled: true,
               leading: makeChatListTileLeading(
                  widget,
                  selectColor(int.parse(ch[i].peer)),
                  (){onLeadingPressed(ctx, post.id, i);}
               ),
               trailing: trailing,
               title: Text(
                  ch[i].getChatDisplayName(),
                  maxLines: 1,
                  overflow: TextOverflow.clip,
                  style: Theme.of(ctx).textTheme.subhead,
               ),
               subtitle: makeChatTileSubtitle(ctx, ch[i]),
               //contentPadding: EdgeInsets.symmetric(horizontal: 10.0),
               onTap: () { onPressed(i); },
               onLongPress: () { onLongPressed(i); }
            ),
          )
       );
   }

  if (isFav)
     return Column(children: list);

   String str = '${ch.length} conversa(s)';
   if (nUnredChats != 0)
      str = '${ch.length} conversas / $nUnredChats nao lidas';

   IconData pinIcon =
      post.pinDate == 0 ? Icons.place : Icons.pin_drop;

   final bool expState = ch.length <= 5 || nUnredChats != 0;
   return Theme(
      data: makeExpTileThemeData(),
      child: ExpansionTile(
         backgroundColor: stl.expTileExpColor,
         initiallyExpanded: expState,
         leading: IconButton(icon: Icon(pinIcon), onPressed: onPinPost),
         key: PageStorageKey<int>(2 * post.id + 1),
         title: Text(str),
         children: list,
      ),
   );
}

Widget makeChatTab(
   BuildContext ctx,
   List<Post> posts,
   Function onPressed,
   Function onLongPressed,
   List<MenuItem> menus,
   Function onDelPost,
   Function onPinPost,
   bool isFwdChatMsgs,
   Function onUserInfoPressed,
   bool isFav)
{
   return ListView.builder(
      padding: const EdgeInsets.all(0.0),
      itemCount: posts.length,
      itemBuilder: (BuildContext ctx, int i)
      {
         Function onPinPost2 = () {onPinPost(i);};

         Function onDelPost2 = () {onDelPost(i);};
         IconData ic = Icons.delete_forever;
         if (isFav) {
            onDelPost2 = onPinPost2;
            if (posts[i].pinDate == 0)
               ic = Icons.place;
            else
               ic = Icons.pin_drop;
         }

         if (isFwdChatMsgs) {
            onUserInfoPressed = (var a, var b, var c){};
            onPinPost2 = (){};
            onDelPost2 = (){};
         }

         final int now = DateTime.now().millisecondsSinceEpoch;
         return makeChatEntry(
             ctx,
             posts[i],
             menus,
             makePostChatCol(
                ctx,
                posts[i].chats,
                (j) {onPressed(i, j);},
                (j) {onLongPressed(i, j);},
                posts[i],
                isFwdChatMsgs,
                onUserInfoPressed,
                now,
                onPinPost2,
                isFav),
             onDelPost2, ic);
      },
   );
}

//_____________________________________________________________________

class DialogWithOp extends StatefulWidget {
   DialogWithOp( this.idx
               , this.getValueFunc
               , this.setValueFunc
               , this.onPostSelection
               , this.title
               , this.body);

   int idx = 0;
   Function getValueFunc;
   Function setValueFunc;
   Function onPostSelection;
   String title;
   String body;

   @override
   DialogWithOpState createState() => DialogWithOpState();
}

class DialogWithOpState extends State<DialogWithOp> {
   int _idx = 0;
   Function _getValueFunc;
   Function _setValueFunc;
   Function _onPostSelection;
   String _title;
   String _body;
   
   @override
   void initState()
   {
      _idx = widget.idx;
      _getValueFunc = widget.getValueFunc;
      _setValueFunc = widget.setValueFunc;
      _onPostSelection = widget.onPostSelection;
      _title = widget.title;
      _body = widget.body;

      super.initState();
   }

   @override
   Widget build(BuildContext ctx)
   {
      final SimpleDialogOption ok =
         SimpleDialogOption(
            child:
               Text('Ok'
                   , style: TextStyle( color: Colors.blue
                                     , fontSize: 16.0)),
            onPressed: () async
            {
               await _onPostSelection();
               Navigator.of(ctx).pop();
            });

      final SimpleDialogOption cancel =
         SimpleDialogOption(
            child:
               Text('Cancelar'
                   , style: TextStyle( color: Colors.blue
                                     , fontSize: 16.0)),
            onPressed: ()
            {
               Navigator.of(ctx).pop();
            });

      List<SimpleDialogOption> actions =
            List<SimpleDialogOption>(2);
      actions[0] = cancel;
      actions[1] = ok;

      Row row =
         Row(children: <Widget>
            [Icon(Icons.check_circle_outline, color: Colors.red)]);

      CheckboxListTile tile = CheckboxListTile(
                title: Text('Nao mostrar novamente'),
                value: !_getValueFunc(),
                onChanged: (bool v)
                           {
                              print(v);
                              _setValueFunc(!v);
                              setState(() { });
                           },
                controlAffinity: ListTileControlAffinity.leading
                );

      return SimpleDialog(
             title: Text(_title),
             children: <Widget>
             [ Padding( child: Center(child:
                           Text( _body
                               , style: TextStyle(fontSize: 16.0)))
                      , padding: EdgeInsets.all(25.0))
             , tile
             , Padding( child: Row(children: actions)
                      , padding: EdgeInsets.only(left: 105.0))
                           
             ]);
   }
}

//_____________________________________________________________________

class MenuChat extends StatefulWidget {
  MenuChat();

  @override
  MenuChatState createState() => MenuChatState();
}

class MenuChatState extends State<MenuChat>
      with SingleTickerProviderStateMixin {
   Config cfg = Config();

   // Array with the length equal to the number of menus there
   // are. Used both on the filter and on the *new post* screens.
   List<MenuItem> _menu = List<MenuItem>();

   // The temporary variable used to store the post the user sends or
   // the post the current chat screen belongs to, if any.
   Post _post = null;

   // The list of posts received from the server. Our own posts that the
   // server echoes back to us (if we are subscribed to the channel)
   // will be filtered out.
   List<Post> _posts = List<Post>();

   // The list of posts the user has selected in the posts screen.
   // They are moved from _posts to here.
   List<Post> _favPosts = List<Post>();

   // Posts the user wrote itself and sent to the server. One issue we
   // have to observe is that if the user is subscribed to the channel
   // the post belongs to, it will be received back and shouldn't be
   // displayed or duplicated on this list. The posts received from
   // the server will not be inserted in _posts.
   //
   // The only posts inserted here are those that have been acked with
   // ok by the server, before that they will live in _outPostsQueue
   List<Post> _ownPosts = List<Post>();

   // Posts sent to the server that haven't been acked yet.
   Queue<Post> _outPostsQueue = Queue<Post>();

   // Stores chat messages that cannot be lost in case the connection
   // to the server is lost. 
   Queue<ChatMsgOutQueueElem> _outChatMsgsQueue =
         Queue<ChatMsgOutQueueElem>();

   // A flag that is set to true when the floating button (new post)
   // is clicked. It must be carefully set to false when that screen
   // are left.
   bool _newPostPressed = false;

   // Similar to _newPostPressed but for the filter screen.
   bool _newFiltersPressed = false;

   // The index of the tab we are currently in in the *new
   // post* or *Filters* screen. For example 0 for the localization
   // menu, 1 for the models menu etc.
   int _botBarIdx = 0;

   // The current chat, if any.
   Chat _chat = null;

   // The last post id seen by the user.
   int _lastSeenPostIdx = -1;

   // Whether or not to show the dialog informing the user what
   // happens to selected or deleted posts in the posts screen.
   List<bool> _dialogPrefs = List<bool>(2);

   // Full path to files.
   String _unreadPostsFileFullPath = '';

   // This list will store the posts in _fav or _own chat screens that
   // have been long pressed by the user. However, once one post is
   // long pressed to select the others is enough to perform a simple
   // click.
   List<Coord> _lpChats = List<Coord>();

   // The menu details filter.
   int _filter = 0;

   // A temporary variable used to store forwarded chat messages.
   List<Coord> _lpChatMsgs = List<Coord>();

   Queue<dynamic> _wsMsgQueue = Queue<dynamic>();

   // When the user is on a chat screen and dragged a message or
   // clicked reply on a long-pressed message this index will be set
   // to the index that leads to the message. It will be set back to
   // -1 when
   //
   // 1. The message is sent
   // 2. The user cancels the operation.
   // 3. The user leaves the chat screen.
   int _dragedIdx = -1;

   TabController _tabCtrl;
   ScrollController _scrollCtrl = ScrollController();
   ScrollController _chatScrollCtrl = ScrollController();

   // The *new post* text controler
   TextEditingController _txtCtrl;
   FocusNode _chatFocusNode;

   IOWebSocketChannel channel;
   
   Database _db;

   @override
   void initState()
   {
      super.initState();
      _tabCtrl = TabController(vsync: this, initialIndex: 1, length: 3);
      _txtCtrl = TextEditingController();
      _tabCtrl.addListener(_tabCtrlChangeHandler);
      _chatFocusNode = FocusNode();
      _dragedIdx = -1;
   }

   @override
   void dispose()
   {
      _txtCtrl.dispose();
      _tabCtrl.dispose();
      _scrollCtrl.dispose();
      _chatScrollCtrl.dispose();
      _chatFocusNode.dispose();

      super.dispose();
   }

   bool _isOnOwn()
   {
      return _tabCtrl.index == 0;
   }

   bool _previousWasOwn()
   {
      return _tabCtrl.previousIndex == 0;
   }

   bool isOnPosts()
   {
      return _tabCtrl.index == 1;
   }

   bool _isOnFav()
   {
      return _tabCtrl.index == 2;
   }

   bool _previousWasFav()
   {
      return _tabCtrl.previousIndex == 2;
   }

   bool isOnFavChat()
   {
      return _isOnFav() && _post != null && _chat != null;
   }

   bool isOnOwnChat()
   {
      return _isOnOwn() && _post != null && _chat != null;
   }

   bool hasSwitchedTab()
   {
      return _tabCtrl.indexIsChanging;
   }

   List<double> getNewMsgsOpacities()
   {
      List<double> opacities = List<double>(3);

      double onFocusOp = 1.0;
      double notOnFocusOp = 0.7;

      opacities[0] = notOnFocusOp;
      if (_isOnOwn())
         opacities[0] = onFocusOp;

      opacities[1] = notOnFocusOp;
      if (isOnPosts())
         opacities[1] = onFocusOp;

      opacities[2] = notOnFocusOp;
      if (_isOnFav())
         opacities[2] = onFocusOp;

      return opacities;
   }

   MenuChatState()
   {
      _newPostPressed = false;
      _newFiltersPressed = false;
      _botBarIdx = 0;

      getApplicationDocumentsDirectory().then((Directory docDir) async
      {
         glob.docDir = docDir.path;
         _load(docDir.path);
      });
   }

   Future<void> _onCreateDb(Database db, int version) async
   {
      await db.execute(sql.createPostsTable);
      await db.execute(sql.createConfig);
      await db.execute(sql.createChats);
      await db.execute(sql.createChatStatus);
      await db.execute(sql.creatOutChatTable);
      await db.execute(sql.createMenuTable);

      // When the database is created, we also have to create the
      // default menu table.
      _menu = menuReader(jsonDecode(Consts.menus));

      List<MenuElem> elems = List<MenuElem>();
      for (int i = 0; i < _menu.length; ++i)
         elems.addAll(makeMenuElems(_menu[i].root.first, i));

      Batch batch = db.batch();

      elems.forEach((MenuElem me)
      {
         batch.insert('menu', menuElemToMap(me));
      });

      await batch.commit(noResult: true, continueOnError: true);
   }

   Future<void> _load(final String docDir) async
   {
      _db = await openDatabase(
         p.join(await getDatabasesPath(), 'main.db'),
         readOnly: false,
         onCreate: _onCreateDb,
         version: 1);

      try {
         final List<Config> configs = await loadConfig(_db);
         if (!configs.isEmpty)
            cfg = configs.first;
      } catch (e) {
         print(e);
      }

      _dialogPrefs[0] = cfg.showDialogOnDelPost == 'yes';
      _dialogPrefs[1] = cfg.showDialogOnSelectPost == 'yes';

      if (_menu.isEmpty) {
         // Here we have to load the menu table, load all leaf
         // counters and leaf reach. NOTE: When the user selects a
         // specific menu item in the filters screen, we save only
         // that specific item's leaf reach on the database, the
         // corrections in the leaf reach of parent nodes are kept in
         // memory, that is why we have to load them here.

         final List<MenuElem> elems = await loadMenu(_db);

         _menu = List<MenuItem>(2);
         _menu[0] = MenuItem();
         _menu[1] = MenuItem();

         _menu[0].filterDepth = Consts.filterDepths[0];
         _menu[1].filterDepth = Consts.filterDepths[1];

         _menu[0].version = Consts.versions[0];
         _menu[1].version = Consts.versions[1];

         List<List<MenuElem>> tmp = List<List<MenuElem>>(2);
         tmp[0] = List<MenuElem>();
         tmp[1] = List<MenuElem>();
         elems.forEach((MenuElem me) {tmp[me.index].add(me);});

         for (int i = 0; i < tmp.length; ++i) {
            final int menuDepth = findMenuDepth(tmp[i]);
            if (menuDepth != 0) {
               MenuNode node = parseTree(tmp[i], menuDepth);
               loadLeafCounters(node);
               loadLeafReaches(node, _menu[i].filterDepth);
               _menu[i].root.add(node);
            }
         }
      }

      try {
         final List<Post> posts = await loadPosts(_db);
         for (Post p in posts) {
            if (p.status == 0) {
               _ownPosts.add(p);
               for (Post o in _ownPosts)
                  o.chats = await loadChats(_db, o.id);
            } else if (p.status == 1) {
               _posts.add(p);
            } else if (p.status == 2) {
               _favPosts.add(p);
               for (Post o in _favPosts)
                  o.chats = await loadChats(_db, o.id);
            } else if (p.status == 3) {
               _outPostsQueue.add(p);
            } else {
               assert(false);
            }
         }

         _ownPosts.sort(CompPosts);
         _favPosts.sort(CompPosts);
      } catch (e) {
         print(e);
      }

      // TODO: The _posts array is expected to be sorted on its
      // ids, so we could perform a binary search here instead.
      final int i = _posts.indexWhere((e)
         { return e.id == cfg.lastSeenPostId; });

      if (i != -1)
         _lastSeenPostIdx = i;

      List<ChatMsgOutQueueElem> tmp = await loadOutChatMsg(_db);

      _outChatMsgsQueue = Queue<ChatMsgOutQueueElem>.from(tmp.reversed);

      // WARNING: localhost or 127.0.0.1 is the emulator or the phone
      // address. If the phone is connected (via USB) to a computer
      // the computer can be found on 10.0.2.2.
      //final String host = 'ws://10.0.2.2:80';

      // My public ip.
      final String host = 'ws://37.24.165.216:80';

      channel = IOWebSocketChannel.connect(host);
      channel.stream.listen(onWSData, onError: onWSError, onDone: onWSDone);

      final List<int> versions = makeMenuVersions(_menu);
      final String cmd = _makeConnCmd(versions);
      channel.sink.add(cmd);

      print('Last post id: ${cfg.lastPostId}.');
      print('Last post id seen: ${cfg.lastSeenPostId}.');
      print('Menu versions: ${versions}');
      print('Login: ${cfg.appId}:${cfg.appPwd}.');
      setState(() { });
   }

   String _makeConnCmd(final List<int> versions)
   {
      if (cfg.appId.isEmpty) {
         // This is the first time we are connecting to the server (or
         // the login file is corrupted, etc.)
         return jsonEncode({'cmd': 'register'});
      }

      // We are already registered in the server.
      var loginCmd = {
         'cmd': 'login',
         'user': cfg.appId,
         'password': cfg.appPwd,
         'menu_versions': versions,
      };

      return jsonEncode(loginCmd);
   }

   Future<void> _setDialogPref(final int i, bool v) async
   {
      _dialogPrefs[i] = v;

      final String str = v ? 'yes' : 'no';

      if (i == 0)
         await _db.execute(sql.updateShowDialogOnDelPost, [str]);
      else
         await _db.execute(sql.updateShowDialogOnSelectPost, [str]);
   }

   Future<void>
   _alertUserOnselectPost(BuildContext ctx, int i, int fav) async
   {
      if (!_dialogPrefs[fav]) {
         await _onPostSelection(i, fav);
         return;
      }

      showDialog(
         context: ctx,
         builder: (BuildContext ctx)
         {
            return DialogWithOp(
               fav,
               () {return _dialogPrefs[fav];},
               (bool v) async {await _setDialogPref(fav, v);},
               () async {await _onPostSelection(i, fav);},
               txt.dialTitleStrs[fav],
               txt.dialBodyStrs[fav]);
            
         },
      );
   }

   Future<void> _onPostSelection(int i, int fav) async
   {
      assert(isOnPosts());

      if (fav == 1) {
         _posts[i].status = 2;
         final int j =
            _posts[i].createChatEntryForPeer(_posts[i].from,
                                             _posts[i].nick);

         Batch batch = _db.batch();
         batch.rawInsert(sql.insertChatStOnPost,
            makeChatUpdateSql(_posts[i].chats[j],
                              _posts[i].id));

         batch.execute(sql.updatePostStatus, [2, _posts[i].id]);

         await batch.commit(noResult: true, continueOnError: true);

         _favPosts.add(_posts[i]);
         _favPosts.sort(CompPosts);

      } else {
         await _db.execute(sql.deletePost, [_posts[i].id]);
      }

      _posts.removeAt(i);

      if (i <= _lastSeenPostIdx)
         --_lastSeenPostIdx;

      setState(() { });
   }

   void _onNewPost()
   {
      _newPostPressed = true;
      _post = Post();
      _menu[0].restoreMenuStack();
      _menu[1].restoreMenuStack();
      _botBarIdx = 0;
      setState(() { });
   }

   void _onNewFilters()
   {
      _newFiltersPressed = true;
      _menu[0].restoreMenuStack();
      _menu[1].restoreMenuStack();
      _botBarIdx = 0;
      setState(() { });
   }

   bool _onWillPopMenu()
   {
      // We may want to  split this function in two: One for the
      // filters and one for the new post screen.
      if (_botBarIdx >= _menu.length) {
         --_botBarIdx;
         setState(() { });
         return false;
      }

      if (_menu[_botBarIdx].root.length == 1) {
         if (_botBarIdx == 0){
            _newPostPressed = false;
            _newFiltersPressed = false;
         } else {
            --_botBarIdx;
         }

         setState(() { });
         return false;
      }

      _menu[_botBarIdx].root.removeLast();
      setState(() { });
      return false;
   }

   void _cleanUpLpOnSwitchTab()
   {
      _lpChats.forEach((e){toggleLPChat(e.chat);});
      _lpChatMsgs.forEach((e){toggleLPChatMsg(e.chat.msgs[e.msgIdx]);});

      _lpChats.clear();
      _lpChatMsgs.clear();
   }

   Future<void> _onFwdSendButton() async
   {
      final int now = DateTime.now().millisecondsSinceEpoch;
      for (Coord c1 in _lpChats) {
         for (Coord c2 in _lpChatMsgs) {
            ChatItem ci = ChatItem(
               type: 3,
               msg: c2.chat.msgs[c2.msgIdx].msg,
               date: now,
            );
            if (_isOnFav()) {
               await _onSendChatMsgImpl(
                  _favPosts, c1.post.id, c1.chat.peer, false, ci);
            } else {
               await _onSendChatMsgImpl(
                  _ownPosts, c1.post.id, c1.chat.peer, true, ci);
            }
         }
      }

      _lpChats.forEach((e){toggleLPChat(e.chat);});
      _lpChatMsgs.forEach((e){toggleLPChatMsg(e.chat.msgs[e.msgIdx]);});

      _post = _lpChatMsgs.first.post;
      _chat = _lpChatMsgs.first.chat;

      _lpChats.clear();
      _lpChatMsgs.clear();

      setState(() { });
   }

   Future<bool> _onPopChat() async
   {
      await _db.rawUpdate(sql.updateNUnreadMsgs,
                         [0, _post.id, _chat.peer]);

      _dragedIdx = -1;
      _chat.nUnreadMsgs = 0;
      _lpChatMsgs.forEach((e){toggleLPChatMsg(_chat.msgs[e.msgIdx]);});

      final bool isEmpty = _lpChatMsgs.isEmpty;
      _lpChatMsgs.clear();

      if (isEmpty) {
         _post = null;
         _chat = null;
      }

      setState(() { });
      return false;
   }

   void _onCancelFwdLPChatMsg()
   {
      _dragedIdx = -1;
      setState(() { });
   }

   Future<void> _onSendChatMsg() async
   {
      final int now = DateTime.now().millisecondsSinceEpoch;
      List<Post> posts = _ownPosts;
      bool isSenderPost = true;

      if (_isOnFav()) {
         posts = _favPosts;
         isSenderPost = false;
      }

      await _onSendChatMsgImpl(
         posts,
         _post.id,
         _chat.peer,
         isSenderPost,
         ChatItem(
            type: 2,
            msg: _txtCtrl.text,
            date: now,
            refersTo: _dragedIdx,
         ),
      );

      _txtCtrl.clear();
      _dragedIdx = -1;

      setState(()
      {
         SchedulerBinding.instance.addPostFrameCallback((_)
         {
            _chatScrollCtrl.animateTo(
               _chatScrollCtrl.position.maxScrollExtent,
               duration: const Duration(milliseconds: 300),
               curve: Curves.easeOut);
         });
      });
   }

   void _onFwdChatMsg()
   {
      assert(!_lpChatMsgs.isEmpty);

      _post = null;
      _chat = null;

      setState(() { });
   }

   void _onDragChatMsg(BuildContext ctx, int k, DragStartDetails d)
   {
      _dragedIdx = k;
      FocusScope.of(ctx).requestFocus(_chatFocusNode);
      setState(() { });
   }

   void _onChatMsgReply(BuildContext ctx)
   {
      assert(_lpChatMsgs.length == 1);

      _dragedIdx = _lpChatMsgs.first.msgIdx;

      assert(_dragedIdx != -1);

      _lpChatMsgs.forEach((e){toggleLPChatMsg(e.chat.msgs[e.msgIdx]);});
      _lpChatMsgs.clear();
      FocusScope.of(ctx).requestFocus(_chatFocusNode);
      setState(() { });
   }

   Future<void> _onChatAttachment() async
   {
      print('_onChatAttachment.');
      var image =
         await ImagePicker.pickImage(source: ImageSource.gallery);

       setState(() { });
   }

   void _onBotBarTapped(int i)
   {
      if (_botBarIdx < _menu.length)
         _menu[_botBarIdx].restoreMenuStack();

      setState(() { _botBarIdx = i; });
   }

   void _onNewPostBotBarTapped(int i)
   {
      print('====> index $i');
      // We allow the user to tap backwards to a new tab but not
      // forward.  This is to avoid complex logic of avoid the
      // publication of imcomplete posts.
      if (i >= _botBarIdx)
         return;

      // The desired tab is *i* the current tab is _botBarIdx. For any
      // tab we land on or walk through we have to restore the menu
      // stack, except for the last two tabs.

      if (i == 2) {
         _botBarIdx = 2;
         setState(() { });
         return;
      }

      _botBarIdx = i + 1;

      do {
         --_botBarIdx;
         _menu[_botBarIdx].restoreMenuStack();
      } while (_botBarIdx != i);

      setState(() { });
   }

   void _onPostLeafPressed(int i)
   {
      MenuNode o = _menu[_botBarIdx].root.last.children[i];
      _menu[_botBarIdx].root.add(o);
      _onPostLeafReached();
      setState(() { });
   }

   void _onPostLeafReached()
   {
      _post.channel[_botBarIdx][0] = _menu[_botBarIdx].root.last.code;
      _menu[_botBarIdx].restoreMenuStack();
      _botBarIdx = postIndexHelper(_botBarIdx);
   }

   void _onPostNodePressed(int i)
   {
      // We continue pushing on the stack if the next screen will have
      // only one menu option.
      do {
         MenuNode o = _menu[_botBarIdx].root.last.children[i];
         _menu[_botBarIdx].root.add(o);
         i = 0;
      } while (_menu[_botBarIdx].root.last.children.length == 1);

      final int length = _menu[_botBarIdx].root.last.children.length;

      assert(length != 1);

      if (length == 0) {
         _onPostLeafReached();
      }

      setState(() { });
   }

   void _onFilterNodePressed(int i)
   {
      MenuNode o = _menu[_botBarIdx].root.last.children[i];
      _menu[_botBarIdx].root.add(o);

      setState(() { });
   }

   Future<void> _onFilterLeafNodePressed(int k) async
   {
      // k = 0 means the *check all fields*.
      if (k == 0) {
         Batch batch = _db.batch();
         _menu[_botBarIdx].updateLeafReachAll(batch, _botBarIdx);
         await batch.commit(noResult: true, continueOnError: true);
         setState(() { });
         return;
      }

      --k; // Accounts for the Todos index.

      Batch batch = _db.batch();
      _menu[_botBarIdx].updateLeafReach(k, batch, _botBarIdx);
      await batch.commit(noResult: true, continueOnError: true);
      setState(() { });
   }

   Future<void> _sendPost(Post post) async
   {
      final bool isEmpty = _outPostsQueue.isEmpty;

      // We add it here in our own list of posts and keep in mind it
      // will be echoed back to us if we are subscribed to its
      // channel. It has to be filtered out from _posts since that
      // list should not contain our own posts.

      final int dbId = 
         await _db.insert('posts', postToMap(post),
                          conflictAlgorithm:
                             ConflictAlgorithm.replace);

      print('What is this $dbId');
      post.dbId = dbId;
      _outPostsQueue.add(post);

      if (!isEmpty)
         return;

      // The queue was empty before we inserted the new post.
      // Therefore we are not waiting for an ack.

      final String payload = makePostPayload(_outPostsQueue.first);
      print(payload);
      channel.sink.add(payload);
   }

   void sendOfflinePosts()
   {
      if (_outPostsQueue.isEmpty)
         return;

      final String payload = makePostPayload(_outPostsQueue.first);
      channel.sink.add(payload);
   }

   Future<void> handlePublishAck(final int id, final int date) async
   {
      try {
         assert(!_outPostsQueue.isEmpty);
         Post post = _outPostsQueue.removeFirst();
         if (id == -1) {
            // FIXME: Remove the post from the db.
            print("Publish failed.");
            return;
         }

         // When working with the simulator I found out that it
         // replies on my machine before the post could be moved from
         // the output queue to the _ownPosts. In normal cases users
         // won't be so fast. But since this is my test condition, I
         // will cope with that by inserting the post in _ownPosts and
         // only after that removing from the queue.
         // TODO: I think this does not hold anymore after I
         // introduced a message queue.
         post.id = id;
         post.date = date;
         post.status = 0;
         post.pinDate = 0;
         _ownPosts.add(post);
         _ownPosts.sort(CompPosts);

         print('receiving a publish ack $id for ${post.dbId}.');
         await _db.execute(sql.updatePostOnAck,
                           [0, id, date, post.dbId]);

         if (_outPostsQueue.isEmpty)
            return;

         final String payload = makePostPayload(_outPostsQueue.first);
         channel.sink.add(payload);
      } catch (e) {
      }
   }

   Future<void> _onRemovePost(int i) async
   {
      if (_isOnFav()) {
         await _db.execute(sql.deletePost, [_favPosts[i].id]);
         _favPosts.removeAt(i);
      } else {
         await _db.execute(sql.deletePost, [_ownPosts[i].id]);
         print('Deleting post ${_ownPosts[i].id}');
         _ownPosts.removeAt(i);
      }

      setState(() { });
   }

   Future<void> _onPinPost(int i) async
   {
      if (_isOnFav()) {
         await onPinPost(_favPosts, i, _db);
      } else {
         await onPinPost(_ownPosts, i, _db);
      }
      setState(() { });
   }

   Future<void>
   _onSendNewPostPressed(BuildContext ctx, final int i) async
   {
      _newPostPressed = false;

      if (i == 0) {
         _post = null;
         setState(() { });
         return;
      }

      _botBarIdx = 0;
      _post.description = _txtCtrl.text;
      _txtCtrl.clear();

      _post.from = cfg.appId;
      _post.nick = cfg.nick;
      _post.status = 3;
      await _sendPost(_post.clone());
      _post = null;
      setState(() { });

      // If the user cancels the operation we do not show the dialog.
      if (i == 1)
         _showSimpleDial(ctx, (){},
                         txt.dialTitleStrs[3],
                         txt.dialBodyStrs[3]);
   }

   void _removePostDialog(BuildContext ctx, int i)
   {
      _showSimpleDial(ctx, () async { await _onRemovePost(i);},
                      txt.dialTitleStrs[4],
                      txt.dialBodyStrs[4]);
   }

   void _onCancelNewFilter()
   {
      print('Canceling new filter');
      _newFiltersPressed = false;
      setState(() { });
   }

   Future<void>
   _onChatPressedImpl(List<Post> posts,
                      bool isSenderPost, int i, int j) async
   {
      if (!_lpChats.isEmpty || !_lpChatMsgs.isEmpty) {
         _onChatLPImpl(posts, i, j);
         setState(() { });
         return;
      }

      _post = posts[i];
      _chat = posts[i].chats[j];

      if (!_chat.isLoaded())
         _chat.loadMsgs(_post.id);
      
      if (posts[i].chats[j].nUnreadMsgs != 0) {
         var msgMap = {
            'cmd': 'message',
            'type': 'app_ack_read',
            'to': posts[i].chats[j].peer,
            'post_id': posts[i].id,
            'is_sender_post': isSenderPost,
         };

         final String payload = jsonEncode(msgMap);
         await sendChatMsg(payload, 0);
      }

      setState(() {
         SchedulerBinding.instance.addPostFrameCallback((_)
         {
            _chatScrollCtrl.jumpTo(_chatScrollCtrl.position.maxScrollExtent);
         });
      });
   }

   Future<void> _onChatPressed(int i, int j) async
   {
      if (_isOnFav())
         await _onChatPressedImpl(_favPosts, false, i, j);
      else
         await _onChatPressedImpl(_ownPosts, true, i, j);
   }

   void _onUserInfoPressed(BuildContext ctx, int postId, int j)
   {
      List<Post> posts;
      if (_isOnFav()) {
         posts = _favPosts;
      } else {
         posts = _ownPosts;
      }

      final int i = posts.indexWhere((e) { return e.id == postId;});
      assert(i != -1);
      assert(j < posts[i].chats.length);

      final String content = 'Id: ${posts[i].chats[j].peer}';
      _showSimpleDial(ctx, (){}, txt.userInfo, content);
   }

   void _onChatLPImpl(List<Post> posts, int i, int j)
   {
      final Coord tmp = Coord(post: posts[i], chat: posts[i].chats[j]);

      handleLPChats(
         _lpChats,
         toggleLPChat(posts[i].chats[j]),
         tmp, CompPostIdAndPeer
      );
   }

   void _onChatLP(int i, int j)
   {
      if (_isOnFav()) {
         _onChatLPImpl(_favPosts, i, j);
      } else {
         _onChatLPImpl(_ownPosts, i, j);
      }

      setState(() { });
   }

   Future<void> sendChatMsg(final String payload, int isChat) async
   {
      final bool isEmpty = _outChatMsgsQueue.isEmpty;
      ChatMsgOutQueueElem tmp = ChatMsgOutQueueElem(
         rowid: -1,
         isChat: isChat,
         payload: payload,
         sent: false
      );

      _outChatMsgsQueue.add(tmp);

      final int rowid =
         await _db.rawInsert(sql.insertOutChatMsg, [isChat, payload]);

      tmp.rowid = rowid;

      if (isEmpty) {
         assert(!_outChatMsgsQueue.first.sent);
         _outChatMsgsQueue.first.sent = true;
         channel.sink.add(_outChatMsgsQueue.first.payload);
      }
   }

   void sendOfflineChatMsgs()
   {
      if (!_outChatMsgsQueue.isEmpty) {
         assert(!_outChatMsgsQueue.first.sent);
         _outChatMsgsQueue.first.sent = true;
         channel.sink.add(_outChatMsgsQueue.first.payload);
      }
   }

   void _toggleLPChatMsgs(int k, bool isTap)
   {
      assert(_post != null);
      assert(_chat != null);

      if (isTap && _lpChatMsgs.isEmpty)
         return;

      final Coord tmp = Coord(
         post: _post,
         chat: _chat,
         msgIdx: k
      );

      handleLPChats(_lpChatMsgs,
                    toggleLPChatMsg(_chat.msgs[k]),
                    tmp, CompPeerAndChatIdx);

      setState((){});
   }

   Future<void>
   _onSendChatMsgImpl(List<Post> posts,
                      int postId,
                      String peer,
                      bool isSenderPost,
                      ChatItem ci) async
   {
      try {
         if (ci.msg.isEmpty)
            return;

         final int i = posts.indexWhere((e) { return e.id == postId;});
         assert(i != -1);

         // We have to make sure every unread msg is marked as read
         // before we receive any reply.
         final int j = posts[i].getChatHistIdx(peer);
         assert(j != -1);

         posts[i].chats[j].addChatItem(ci, postId);

         await _db.transaction((txn) async {
            Batch batch = txn.batch();

            // Perhaps we should update only the last chat item here
            // for performance?
            batch.rawInsert(sql.insertOrReplaceChatOnPost,
               makeChatUpdateSql(posts[i].chats[j], postId));
            batch.rawInsert(sql.insertChatMsg,
                [postId, peer, 1, ci.date, ci.msg]);
            await batch.commit(noResult: true, continueOnError: true);
         });

         posts[i].chats.sort(CompChats);
         posts.sort(CompPosts);

         final String type = convertChatMsgTypeToString(ci.type);
         var msgMap = {
            'cmd': 'message',
            'type': type,
            'to': peer,
            'msg': ci.msg,
            'refers_to': ci.refersTo,
            'post_id': postId,
            'is_sender_post': isSenderPost,
            'nick': cfg.nick
         };

         await sendChatMsg(jsonEncode(msgMap), 1);

      } catch(e) {
         print(e);
      }
   }

   void _chatServerAckHandler(Map<String, dynamic> ack, Batch batch)
   {
      try {
         assert(_outChatMsgsQueue.first.sent);
         assert(!_outChatMsgsQueue.isEmpty);
         final String res = ack['result'];

         batch.rawDelete(sql.deleteOutChatMsg,
                         [_outChatMsgsQueue.first.rowid]);

         final bool isChat = _outChatMsgsQueue.first.isChat == 1;
         _outChatMsgsQueue.removeFirst();

         if (res == 'ok' && isChat) {
            _chatAppAckHandler(ack, 1, batch);
            setState(() { });
         }

         if (!_outChatMsgsQueue.isEmpty) {
            assert(!_outChatMsgsQueue.first.sent);
            _outChatMsgsQueue.first.sent = true;
            channel.sink.add(_outChatMsgsQueue.first.payload);
         }
      } catch (e) {
         print(e);
      }
   }

   Future<void>
   _chatMsgHandler(Map<String, dynamic> ack, int type) async
   {
      final int postId = ack['post_id'];
      final bool isSenderPost = ack['is_sender_post'];
      final String to = ack['to'];
      final String msg = ack['msg'];
      final String peer = ack['from'];
      final String nick = ack['nick'];
      final int refersTo = ack['refers_to'];

      if (to != cfg.appId) {
         print("Server bug caught. Please report.");
         return;
      }

      List<Post> posts;
      if (isSenderPost)
         posts = _favPosts;
      else
         posts = _ownPosts;

      await _chatMsgHandlerImpl(to, postId, msg, peer,
                                nick, isSenderPost, posts,
                                type, refersTo);
   }

   Future<void>
   _chatMsgHandlerImpl(String to,
                       int postId,
                       String msg,
                       String peer,
                       String nick,
                       bool isSenderPost,
                       List<Post> posts,
                       int type,
                       int refersTo) async
   {
      final int i = posts.indexWhere((e) { return e.id == postId;});
      if (i == -1) {
         print('Ignoring message to postId $postId.');
         return;
      }

      final int j = posts[i].getChatHistIdxOrCreate(peer, nick);
      if (j == -1) {
         print('Ignoring message to (postId, peer) = ($postId, $peer)');
         return;
      }

      final int now = DateTime.now().millisecondsSinceEpoch;
      posts[i].chats[j].addChatItem(
         ChatItem(
            type: type,
            msg: msg,
            date: now,
            refersTo: refersTo),
         postId);

      // If we are in the screen having chat with the user we can ack
      // it with app_ack_read and skip app_ack_received.
      final bool isOnPost = _post != null && _post.id == postId; 
      final bool isOnChat = _chat != null && _chat.peer == peer; 

      String ack;
      if (isOnPost && isOnChat) {
         posts[i].chats[j].nUnreadMsgs = 0;
         ack = 'app_ack_read';
      } else {
         ++posts[i].chats[j].nUnreadMsgs;
         ack = 'app_ack_received';
      }

      final Chat chat = posts[i].chats[j];

      posts[i].chats.sort(CompChats);
      posts.sort(CompPosts);

      var msgMap = {
         'cmd': 'message',
         'type': ack,
         'to': peer,
         'post_id': postId,
         'is_sender_post': !isSenderPost,
      };

      // Generating the payload before the async operation to avoid
      // problems.
      final String payload = jsonEncode(msgMap);
      print(payload);

      await _db.transaction((txn) async {
         Batch batch = txn.batch();
         batch.rawInsert(sql.insertOrReplaceChatOnPost,
            makeChatUpdateSql(chat, postId));
         batch.rawInsert(sql.insertChatMsg,
                        [postId, peer, 0, now, msg]);
         await batch.commit(noResult: true, continueOnError: true);
      });

      // TODO: Include this in the transaction above.
      await sendChatMsg(payload, 0);
   }

   void _chatAppAckHandler(Map<String, dynamic> ack,
                           final int status,
                           Batch batch)
   {
      final String from = ack['from'];
      final int postId = ack['post_id'];
      final bool isSenderPost = ack['is_sender_post'];

      if (isSenderPost) {
         findAndMarkChatApp(_favPosts, from, postId, status, batch);
      } else {
         findAndMarkChatApp(_ownPosts, from, postId, status, batch);
      }
   }

   Future<void> _onMessage(Map<String, dynamic> ack) async
   {
      Batch batch = _db.batch();

      final String type = ack['type'];
      if (type == 'server_ack') {
         _chatServerAckHandler(ack, batch);
      } else if (type == 'chat') {
         _chatMsgHandler(ack, 0);
      }  else if (type == 'chat_redirected') {
         _chatMsgHandler(ack, 1);
      } else if (type == 'app_ack_received') {
         _chatAppAckHandler(ack, 2, batch);
      } else if (type == 'app_ack_read') {
         _chatAppAckHandler(ack, 3, batch);
      }

      await batch.commit(noResult: true, continueOnError: true);

      setState((){});
   }

   Future<void>
   _onRegisterAck(Map<String, dynamic> ack, final String msg) async
   {
      final String res = ack["result"];
      if (res == 'fail') {
         print("register_ack: fail.");
         return;
      }

      print('register_ack: ok.');

      cfg.appId = ack["id"];
      cfg.appPwd = ack["password"];

      print('register_ack: Persisting the login.');
      await _db.insert(
         'config',
         configToMap(cfg),
         conflictAlgorithm: ConflictAlgorithm.replace);

      // TODO: Check for menu updates and apply them.
   }

   Future<void>
   _onLoginAck(Map<String, dynamic> ack, final String msg) async
   {
      final String res = ack["result"];

      // I still do not know how a failed login should be handled.
      // Perhaps send a new register command? It can only happen if
      // the server is blocking this user.
      if (res == 'fail') {
         print("login_ack: fail.");
         return;
      }

      // We are loggen in and can send the channels we are
      // subscribed to to receive posts sent while we were offline.
      _subscribeToChannels();

      // Sends any chat messages that may have been written while
      // the app were offline.
      sendOfflineChatMsgs();

      // The same for posts.
      sendOfflinePosts();

      // TODO: Check for menu updates and apply them.
   }

   void _onSubscribeAck(Map<String, dynamic> ack)
   {
      final String res = ack["result"];
      if (res == 'fail') {
         print("subscribe_ack: $res");
         return;
      }
   }

   Future<void> _onPost(Map<String, dynamic> ack) async
   {
      Batch batch = _db.batch();
      for (var item in ack['items']) {
         Post post = readPostData(item);
         post.status = 1;

         // Just in case the server sends us posts out of order I
         // will check. It should however be considered a server
         // error.
         if (post.id > cfg.lastPostId)
            cfg.lastPostId = post.id;

         if (post.from == cfg.appId)
            continue;

         batch.insert('posts', postToMap(post),
            conflictAlgorithm: ConflictAlgorithm.replace);

         _posts.add(post);
      }

      batch.execute(sql.updateLastPostId, [cfg.lastPostId]);
      await batch.commit(noResult: true, continueOnError: true);

      setState(() { });
   }

   Future<void> _onPublishAck(Map<String, dynamic> ack) async
   {
      final String res = ack['result'];
      if (res == 'ok')
         await handlePublishAck(ack['id'], ack['date']);
      else
         await handlePublishAck(-1, -1);
   }

   Future<void> onWSDataImpl() async
   {
      while (!_wsMsgQueue.isEmpty) {
         var msg = _wsMsgQueue.removeFirst();

         Map<String, dynamic> ack = jsonDecode(msg);
         final String cmd = ack["cmd"];

         if (cmd == "message") {
            await _onMessage(ack);
         } else if (cmd == "login_ack") {
            await _onLoginAck(ack, msg);
         } else if (cmd == "subscribe_ack") {
            _onSubscribeAck(ack);
         } else if (cmd == "post") {
            await _onPost(ack);
         } else if (cmd == "publish_ack") {
            await _onPublishAck(ack);
         } else if (cmd == "register_ack") {
            await _onRegisterAck(ack, msg);
         } else {
            print('Unhandled message received from the server:\n$msg.');
         }
      }
   }

   Future<void> onWSData(msg) async
   {
      final bool isEmpty = _wsMsgQueue.isEmpty;
      _wsMsgQueue.add(msg);
      if (isEmpty)
         await onWSDataImpl();
   }

   void onWSError(error)
   {
      print(error);
   }

   void onWSDone()
   {
      print("Communication closed by peer.");
   }

   void _onOkDialAfterSendFilters()
   {
      _tabCtrl.index = 1;
      _botBarIdx = 0;
      setState(() { });
   }

   void
   _showSimpleDial(BuildContext ctx,
                   Function onOk,
                   String title,
                   String content)
   {
      showDialog(
         context: ctx,
         builder: (BuildContext ctx)
         {
            final FlatButton ok = FlatButton(
               child: Text('Ok'),
               onPressed: ()
               {
                  onOk();
                  Navigator.of(ctx).pop();
               });

            List<FlatButton> actions = List<FlatButton>(1);
            actions[0] = ok;

            return AlertDialog( title: Text(title)
                              , content: Text(content)
                              , actions: actions);
         },
      );
   }

   Future<void> _onSendFilters(BuildContext ctx) async
   {
      _newFiltersPressed = false;

      // First send the hashes then show the dialog.
      _subscribeToChannels();

      _showSimpleDial(ctx,
                      _onOkDialAfterSendFilters,
                      txt.dialTitleStrs[2],
                      txt.dialBodyStrs[2]);
   }

   void _subscribeToChannels()
   {
      List<List<List<int>>> channels = List<List<List<int>>>();
      for (MenuItem item in _menu) {
         List<List<int>> hashCodes =
            readHashCodes(item.root.first, item.filterDepth);

         if (hashCodes.isEmpty) {
            print("Menu channels hash is empty. Nothing to do ...");
            return;
         }

         channels.add(hashCodes);
      }

      var subCmd = {
         'cmd': 'subscribe',
         'last_post_id': cfg.lastPostId,
         'channels': channels,
         'filter': _filter
      };

      final String payload = jsonEncode(subCmd);
      print('====> $payload');
      channel.sink.add(payload);
   }

   // Called when the main tab changes.
   void _tabCtrlChangeHandler()
   {
      // This function is meant to change the tab widgets when we
      // switch tab. This is needed to show the number of unread
      // messages.
      setState(() { });
   }

   int _getNUnreadFavChats()
   {
      int i = 0;
      for (Post post in _favPosts)
         i += post.getNumberOfUnreadChats();

      return i;
   }

   int _getNUnreadOwnChats()
   {
      int i = 0;
      for (Post post in _ownPosts)
         i += post.getNumberOfUnreadChats();

      return i;
   }

   bool _onChatsBackPressed()
   {
      if (_hasLPChatMsgs()) {
         _onBackFromChatMsgRedirect();
         return false;
      }

      if (_hasLPChats()) {
         _unmarkLPChats();
         setState(() { });
         return false;
      }

      if (_post != null) {
         _post = null;
         setState(() { });
         return false;
      }

      setState(() { });
      return true;
   }

   bool _hasLPChats()
   {
      return !_lpChats.isEmpty;
   }

   bool _hasLPChatMsgs()
   {
      return !_lpChatMsgs.isEmpty;
   }

   void _unmarkLPChats()
   {
      _lpChats.forEach((e){toggleLPChat(e.chat);});
      _lpChats.clear();
   }

   void _onAppBarVertPressed(ConfigActions ca)
   {
      if (ca == ConfigActions.ChangeNick)
         cfg.nick = '';

      setState(() {});
   }

   Future<void> _pinChats() async
   {
      assert(_isOnFav() || _isOnOwn());

      if (_lpChats.isEmpty)
         return;

      _lpChats.forEach((e){toggleChatPinDate(e.chat);});
      _lpChats.forEach((e){toggleLPChat(e.chat);});
      _lpChats.first.post.chats.sort(CompChats);
      _lpChats.clear();

      // TODO: Sort _favPosts and _ownPosts. Beaware that the array
      // Coord many have entries from chats from different posts and
      // they may be out of order. So care should be taken to not sort
      // the arrays multiple times.

      setState(() { });
   }

   Future<void> _removeLPChats() async
   {
      assert(_isOnFav() || _isOnOwn());

      if (_lpChats.isEmpty)
         return;

      // FIXME: For _fav chats we can directly delete the post since
      // it will only have one chat element.

      _lpChats.forEach((e) async {removeLpChat(e, _db);});

      if (_isOnFav()) {
         for (Post o in _favPosts)
            if (o.chats.isEmpty)
               await _db.execute(sql.deletePost, [o.id]);

         _favPosts.removeWhere((e) { return e.chats.isEmpty; });
      } else {
         _ownPosts.sort(CompPosts);
      }

      _lpChats.clear();
      setState(() { });
   }

   void _deleteChatDialog(BuildContext ctx)
   {
      showDialog(
         context: ctx,
         builder: (BuildContext ctx)
         {
            final FlatButton ok = FlatButton(
                     child: Text(
                        txt.devChatOkStr,
                        style: TextStyle(color: stl.accentColor)),
                     onPressed: () async
                     {
                        await _removeLPChats();
                        Navigator.of(ctx).pop();
                     });

            final FlatButton cancel = FlatButton(
               child: Text(
                  txt.delChatCancelStr,
                  style: TextStyle(color: stl.accentColor)),
               onPressed: ()
               {
                  Navigator.of(ctx).pop();
               });

            List<FlatButton> actions = List<FlatButton>(2);
            actions[0] = cancel;
            actions[1] = ok;

            Text text = Text(
               txt.delOwnChatTitleStr,
               style: TextStyle(color: Colors.black));

            if (_isOnFav()) {
               text = Text(
                  txt.delFavChatTitleStr,
                  style: TextStyle(color: Colors.black));
            }

            return AlertDialog(
                  title: text,
                  content: Text(""),
                  actions: actions);
         },
      );
   }

   void _onBackFromChatMsgRedirect()
   {
      assert(!_lpChatMsgs.isEmpty);

      if (_lpChats.isEmpty) {
         // All items int _lpChatMsgs should have the same post id and
         // peer so we can use the first.
         _post = _lpChatMsgs.first.post;
         _chat = _lpChatMsgs.first.chat;
      } else {
         _unmarkLPChats();
      }

      setState(() { });
   }

   Future<void> _onNickPressed() async
   {
      try {
         cfg.nick = _txtCtrl.text;
         await _db.execute(sql.updateNick, [cfg.nick]);
         setState(()
         {
            _txtCtrl.clear();
         });
      } catch (e) {
         print(e);
      }
   }

   Future<void> _updateLastSeenPostIdx(int i) async
   {
      if (i <= _lastSeenPostIdx)
         return;

      _lastSeenPostIdx = i;

      await _db.execute(sql.updateLastSeenPostId,
                        [_posts[i].id]);

      SchedulerBinding.instance.addPostFrameCallback((_)
      {
         setState(() { });
      });
   }

   void _onNewPostDetail(int i)
   {
      if (i == txt.postDetails.length) {
         _botBarIdx = 3;
         setState(() { });
         return;
      }

      //_post.filter ^= 1 << i;
      _post.filter = 1 << i;
      setState(() { });
   }

   void _onFilterDetail(int i)
   {
      _filter ^= 1 << i;
      setState(() { });
   }

   @override
   Widget build(BuildContext ctx)
   {
      // Just for safety if we did not load the menu fast enough.
      if (_menu.isEmpty)
         return makeWaitMenuScreen(ctx);

      if (cfg.nick.isEmpty) {
         return makeNickRegisterScreen(
            ctx,
            _txtCtrl,
            _onNickPressed,
            txt.appName
         );
      }

      if (hasSwitchedTab())
         _cleanUpLpOnSwitchTab();

      if (_newPostPressed) {
         return
            makeNewPostScreens(
               ctx,
               _post,
               _menu,
               _txtCtrl,
               _onSendNewPostPressed,
               _botBarIdx,
               _onNewPostDetail,
               _onPostLeafPressed,
               _onPostNodePressed,
               _onWillPopMenu,
               _onNewPostBotBarTapped);
      }

      if (_newFiltersPressed)
         return
            makeNewFiltersScreens(
               ctx,
               _onSendFilters,
               _onFilterDetail,
               _onFilterNodePressed,
               _onWillPopMenu,
               _onBotBarTapped,
               _onFilterLeafNodePressed,
               _menu,
               _filter,
               _botBarIdx,
               _onCancelNewFilter);

      if (isOnFavChat() || isOnOwnChat()) {
         String postSummary =
            makePostSummaryStr(_menu[1].root.first, _post);
         return makeChatScreen(
            ctx,
            _onPopChat,
            _chat,
            _txtCtrl,
            _onSendChatMsg,
            _chatScrollCtrl,
            _toggleLPChatMsgs,
            _lpChatMsgs.length,
            _onFwdChatMsg,
            _onDragChatMsg,
            _chatFocusNode,
            _onChatMsgReply,
            postSummary,
            _onChatAttachment,
            _dragedIdx,
            _onCancelFwdLPChatMsg);
      }

      List<Function> onWillPops = List<Function>(txt.tabNames.length);
      onWillPops[0] = _onChatsBackPressed;
      onWillPops[1] = (){return false;};
      onWillPops[2] = _onChatsBackPressed;

      String appBarTitle = txt.appName;

      List<FloatingActionButton> fltButtons =
            List<FloatingActionButton>(txt.tabNames.length);

      fltButtons[0] = makeFaButton(
         _onNewPost,
         _onFwdSendButton,
         _lpChats.length,
         _lpChatMsgs.length);

      fltButtons[1] = makeFiltersFaButton(_onNewFilters, Icons.filter_list);

      fltButtons[2] = makeFaButton(
         null,
         _onFwdSendButton,
         _lpChats.length,
         _lpChatMsgs.length);

      List<Widget> bodies = List<Widget>(txt.tabNames.length);
      bodies[0] = makeChatTab(
         ctx,
         _ownPosts,
         _onChatPressed,
         _onChatLP,
         _menu,
         (int i) { _removePostDialog(ctx, i);},
         _onPinPost,
         !_lpChatMsgs.isEmpty,
         _onUserInfoPressed,
         false);

      bodies[1] = makePostTabListView(
         ctx,
         _posts,
         _alertUserOnselectPost,
         _menu,
         _updateLastSeenPostIdx);

      bodies[2] = makeChatTab(
         ctx,
         _favPosts,
         _onChatPressed,
         _onChatLP,
         _menu,
         (int i) { _removePostDialog(ctx, i);},
         _onPinPost,
         !_lpChatMsgs.isEmpty,
         _onUserInfoPressed,
         true);

      List<Widget> actions = List<Widget>();
      Widget appBarLeading = null;
      if (_isOnFav() || _isOnOwn()) {
         if (_hasLPChatMsgs()) {
            appBarTitle = txt.chatMsgRedirectText;
            appBarLeading = IconButton(
               icon: Icon(
                  Icons.arrow_back,
                  color: Theme.of(ctx).appBarTheme.iconTheme.color),
               onPressed: _onBackFromChatMsgRedirect);
         }

         if (_hasLPChats() && !_hasLPChatMsgs()) {
            actions =
               makeOnLongPressedActions(
                  ctx,
                  _deleteChatDialog,
                  _pinChats);
         }
      }

      actions.add(makeAppBarVertAction(_onAppBarVertPressed));

      List<int> newMsgsCounters = List<int>(txt.tabNames.length);
      newMsgsCounters[0] = _getNUnreadOwnChats();
      newMsgsCounters[1] = _posts.length - _lastSeenPostIdx - 1;
      newMsgsCounters[2] = _getNUnreadFavChats();

      List<double> opacities = getNewMsgsOpacities();

      return WillPopScope(
          onWillPop: () async { return onWillPops[_tabCtrl.index]();},
          child: Scaffold(
              body: NestedScrollView(
                 controller: _scrollCtrl,
                 headerSliverBuilder: (BuildContext ctx, bool innerBoxIsScrolled) {
                   return <Widget>[
                     SliverAppBar(
                       title: Text(
                          appBarTitle,
                          style: Theme.of(ctx).appBarTheme.textTheme.title),
                       pinned: true,
                       floating: true,
                       forceElevated: innerBoxIsScrolled,
                       bottom: makeTabBar(
                          ctx,
                          newMsgsCounters,
                          _tabCtrl,
                          opacities,
                          _hasLPChatMsgs(),
                       ),
                       actions: actions,
                       leading: appBarLeading
                     ),
                   ];
                 },
                 body: TabBarView(controller: _tabCtrl,
                             children: bodies),
                ),
                backgroundColor: Colors.white,
                floatingActionButton: fltButtons[_tabCtrl.index],
              )
        );
   }
}

