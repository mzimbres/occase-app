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

import 'package:flutter/material.dart';
import 'package:menu_chat/post.dart';
import 'package:menu_chat/tree.dart';
import 'package:menu_chat/constants.dart';
import 'package:menu_chat/text_constants.dart' as cts;
import 'package:menu_chat/globals.dart' as glob;

class Coord {
   Post post = null;
   Chat chat = null;
   int msgIdx = -1;
   Coord(this.post, this.chat, this.msgIdx);
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

   final int n =
      await db.rawDelete(cts.deleteChatStElem,
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

   await db.execute(cts.updatePostPinDate,
                    [posts[i].pinDate, posts[i].id]);

   posts.sort(CompPosts);
}

Future<void> onCreateDb(Database db, int version) async
{
   print('====> Creating posts table.');
   await db.execute(cts.createPostsTable);
   print('====> Creating config table.');
   await db.execute(cts.createConfig);
   print('====> Inserting the default menu.');
   await db.execute(cts.updateMenu, [Consts.menus]);
   print('====> Creating chats table.');
   await db.execute(cts.createChats);
   print('====> Creating chat-status table.');
   await db.execute(cts.createChatStatus);
   print('====> Creating out-chat table.');
   await db.execute(cts.creatOutChatTable);
}

Future<Null> main() async
{
  runApp(MyApp());
}

class ChatMsgOutQueueElem {
   int rowid = 0;
   int isChat = 0;
   String payload = '';
   bool sent = false; // Used for debugging.
   ChatMsgOutQueueElem(this.rowid, this.isChat, this.payload, this.sent);
}

Future<List<ChatMsgOutQueueElem>>
loadOutChatMsg(Database db, String tableName) async
{
  final List<Map<String, dynamic>> maps =
     await db.query(tableName);

  return List.generate(maps.length, (i)
  {
     final int rowid = maps[i]['rowid'];
     final int isChat = maps[i]['is_chat'];
     final String payload = maps[i]['payload'];

     return ChatMsgOutQueueElem(rowid, isChat, payload, false);
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

List<Widget>
makeOnLongPressedActions(BuildContext ctx,
                         Function deleteChatEntryDialog,
                         Function pinChat)
{
   List<Widget> actions = List<Widget>();

   IconButton pinChatBut = IconButton(
      icon: Icon(Icons.place, color: Colors.white),
      tooltip: cts.pinChatStr,
      onPressed: pinChat);

   actions.add(pinChatBut);

   IconButton delChatBut = IconButton(
      icon: Icon(Icons.delete_forever, color: Colors.white),
      tooltip: cts.deleteChatStr,
      onPressed: () { deleteChatEntryDialog(ctx); });

   actions.add(delChatBut);

   // Block user button.
   //IconButton blockUserBut = IconButton(
   //   icon: Icon(Icons.block, color: Colors.white),
   //   tooltip: cts.blockUserChatStr,
   //   onPressed: () { print('Kabuff'); });

   //actions.add(blockUserBut);

   return actions;
}

Scaffold
makeNickRegisterScreen( TextEditingController txtCtrl
                      , Function onNickPressed)
{
   TextField tf =
      makeTextInputFieldCard(
         txtCtrl,
         null,
         InputDecoration(
            hintText: cts.nichTextFieldHintStr,
            hintStyle: TextStyle(fontSize: 25.0,
              fontWeight: FontWeight.normal)));

   Padding padd =
      Padding( child: tf
             , padding: EdgeInsets.all(20.0));

   RaisedButton but =
      RaisedButton(
         child: Text( 'Continuar'
                    , style: TextStyle(
                         color: Colors.white,
                         fontWeight: FontWeight.bold,
                         fontSize: 18.0)),
         color: Colors.blue,
         onPressed: onNickPressed
         );

   Column col =
      Column( mainAxisAlignment: MainAxisAlignment.center
            , crossAxisAlignment: CrossAxisAlignment.center
            , children: <Widget>
              [ padd
              , but
              ]);

   return Scaffold(body: Center(child: col));
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

   cards.add(makePostDetailElem(post.filter));
   cards.add(
      makeCard(
         makeTextInputFieldCard(
            txtCtrl,
            null,
            InputDecoration.collapsed(
               hintText: cts.newPostTextFieldHistStr)),
         cts.postLocHeaderColor));

   Widget widget_tmp =
      makePostWidget( ctx
                    , cards
                    , (final int add) { onSendNewPostPressed(ctx, add); }
                    , Icon(Icons.publish, color: Colors.white)
                    , cts.postFrameColor);

   // FIXME: I added this ListView to prevent widget_tmp from
   // extending the whole screen. Inside the ListView it appears
   // compact. Remove this later.
   return ListView(
      shrinkWrap: true,
      //padding: const EdgeInsets.all(20.0),
      children: <Widget>[widget_tmp]
   );
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
         cts.filterTabNames[screen],
         style: TextStyle(
            color: Colors.white,
            fontSize: 19.0));

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
                     style: TextStyle(
                         color: Colors.white,
                         fontSize: 14.0)));
   }

   AppBar appBar = AppBar(
         title: appBarTitleWidget,
         elevation: 0.7,
         toolbarOpacity : 1.0,
         leading: IconButton( icon: Icon( Icons.arrow_back
                                        , color: Colors.white)
                            , onPressed: onWillPopMenu)
   );

   return WillPopScope(
       onWillPop: () async { return onWillPopMenu();},
       child: Scaffold(
           appBar: appBar,
           body: wid,
           bottomNavigationBar:
              makeBottomBarItems(
                 cts.newPostTabIcons,
                 cts.newPostTabNames,
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
                                  cts.postFrameColor))]);
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
      cts.filterTabNames[screen],
      maxLines: 1,
      overflow: TextOverflow.clip,
      style: cts.appBarTitleStl);

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
            style: cts.appBarSubtitleStl));
   }

   AppBar appBar = AppBar(
         title: appBarTitleWidget,
         elevation: 0.7,
         toolbarOpacity : 1.0,
         leading: IconButton( icon: Icon( Icons.arrow_back
                                        , color: Colors.white)
                            , onPressed: onWillPopMenu)
   );

   return WillPopScope(
       onWillPop: () async { return onWillPopMenu();},
       child: Scaffold(
           appBar: appBar,
           body: wid,
           bottomNavigationBar: makeBottomBarItems(
              cts.filterTabIcons,
              cts.filterTabNames,
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
      itemCount: cts.postDetails.length + shift,
      itemBuilder: (BuildContext ctx, int i)
      {
         if (i == cts.postDetails.length)
            return createSendButton((){proceed(i);},
                                    'Continuar',
                                    cts.postFrameColor);

         bool v = ((filter & (1 << i)) != 0);
         Color color = cts.selectedMenuColor;
         if (v)
            color = Theme.of(ctx).primaryColor;

         return CheckboxListTile(
            dense: true,
            secondary:
               makeCircleAvatar(
                  Text( cts.postDetails[i].substring(0, 2)
                      , style: cts.abbrevStl),
                  color),
            title: Text(cts.postDetails[i], style: cts.listTileTitleStl),
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
      title: cts.appName,
      theme: ThemeData(
                brightness: Brightness.light,
                primaryColor: cts.primaryColor,
                accentColor: cts.accentColor,
      ),
      debugShowCheckedModeBanner: false,
      home: MenuChat(),
    );
  }
}

TabBar
makeTabBar(List<int> counters,
           TabController tabCtrl,
           List<double> opacity,
           bool isFwd)
{
   if (isFwd)
      return null;

   List<Widget> tabs = List<Widget>(cts.tabNames.length);

   for (int i = 0; i < tabs.length; ++i) {
      tabs[i] = Tab(
         child: makeTabWidget(
            counters[i], cts.tabNames[i], opacity[i]));
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
             backgroundColor: cts.coral,
             child: Icon(id, color: Colors.white),
             onPressed: onNewPost);
}

FloatingActionButton
makeFaButton(Function onNewPost,
             Function onFwdChatMsg,
             int lpChats,
             int lpChatMsgs)
{
   if (lpChats == 0 && lpChatMsgs != 0)
      return null;

   IconData id = cts.newPostIcon;
   if (lpChats != 0 && lpChatMsgs != 0) {
      return FloatingActionButton(
         backgroundColor: cts.coral,
         child: Icon(Icons.send, color: Colors.white),
         onPressed: onFwdChatMsg);
   }

   if (lpChats != 0)
      return null;

   if (onNewPost == null)
      return null;

   return FloatingActionButton(
      backgroundColor: cts.darkYellow,
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

Card makeUnreadMsgsInfoWidget(int n)
{
   return Card(
      color: cts.postFrameColor,
      margin: const EdgeInsets.all(12.0),
      child: Center(
          child: Text('$n nao lidas.',
                      style: TextStyle(fontSize: 17.0))));
}

ListView
makeChatMsgListView(
   BuildContext ctx,
   ScrollController scrollCtrl,
   Chat ch,
   onChatSendPressed,
   onChatMsgLongPressed,
   onDragChatMsg)
{
   final int nMsgs = ch.msgs.length;
   final int shift = ch.nUnreadMsgs == 0 ? 0 : 1;

   return ListView.builder(
      controller: scrollCtrl,
      reverse: false,
      padding: const EdgeInsets.all(0.0),
      itemCount: nMsgs + shift,
      itemBuilder: (BuildContext ctx, int i)
      {
         if (shift == 1) {
            if (i == nMsgs - ch.nUnreadMsgs)
               return makeUnreadMsgsInfoWidget(ch.nUnreadMsgs);

            if (i > (nMsgs - ch.nUnreadMsgs))
               i -= 1; // For the shift
         }

         Alignment align = Alignment.bottomLeft;
         Color color = Color(0xFFFFFFFF);
         Color onSelectedMsgColor = Colors.grey[300];
         if (ch.msgs[i].thisApp) {
            align = Alignment.bottomRight;
            color = Colors.lightGreenAccent[100];
         }

         if (ch.msgs[i].isLongPressed)
            onSelectedMsgColor = Colors.blue[100];

         RichText msgAndDate = 
            makeFilteListTileTitleWidget(
               ch.msgs[i].msg,
               '  ${makeDateString(ch.msgs[i].date)}',
               cts.defaultTextStl,
               TextStyle(
                  fontSize: cts.listTileSubtitleFontSize,
                  color: Colors.grey));

         // Unfoutunately TextSpan sill does not support general
         // widgets so I have to put the msg status in a row instead
         // of simply appending it to the richtext as I do for the
         // date. Perhaps they will fix this later.
         Widget msgAndStatus;
         if (ch.msgs[i].thisApp) {
            msgAndStatus = Row(
               mainAxisSize: MainAxisSize.min,
               mainAxisAlignment: MainAxisAlignment.end,
               children: <Widget>
            [ Flexible(child: Padding(
                  padding: EdgeInsets.all(cts.chatMsgPadding),
                  child: msgAndDate))
            , Padding(
                  padding: EdgeInsets.all(2.0),
                  child: chooseMsgStatusIcon(ch, i))
            ]);
         } else {
            msgAndStatus = Padding(
                  padding: EdgeInsets.all(cts.chatMsgPadding),
                  child: msgAndDate);
         }

         double marginLeft = 10.0;
         double marginRight = 0.0;
         if (ch.msgs[i].thisApp) {
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
                  child: msgAndStatus)));

         Row r = null;
         if (ch.msgs[i].thisApp) {
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

         return GestureDetector(
            onLongPress: () {onChatMsgLongPressed(i, false);},
            onTap: () {onChatMsgLongPressed(i, true);},
            onPanStart: (DragStartDetails d) {onDragChatMsg(ctx, i, d);},
            child: Card(child: r,
               color: onSelectedMsgColor,
               elevation: 0.0,
               margin: const EdgeInsets.all(0.0),
               shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(0.0))))
            );
      },
   );
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
               String postSummary)
{
   IconButton sendButCol =
      IconButton(
         icon: Icon(Icons.send),
         onPressed: onChatSendPressed,
         color: Theme.of(ctx).primaryColor);

   TextField tf = TextField(
       style: cts.defaultTextStl,
       controller: ctrl,
       //textInputAction: TextInputAction.go,
       //onSubmitted: onTextFieldPressed,
       keyboardType: TextInputType.multiline,
       maxLines: null,
       maxLength: null,
       focusNode: chatFocusNode,
       decoration:
          InputDecoration.collapsed(hintText: cts.chatTextFieldHintStr));

   Padding placeholder = Padding(
      child: Icon(Icons.send, color: Colors.white),
         padding: EdgeInsets.all(10.0));

   Row rr = Row(children: <Widget>
   [ placeholder
   , Expanded(child:
       Scrollbar( child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          reverse: true,
          child: tf)))
   , placeholder
   ]);

   Card card = Card(
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

   ListView list = makeChatMsgListView(
         ctx,
         scrollCtrl,
         ch,
         onChatSendPressed,
         onChatMsgLongPressed,
         onDragChatMsg);

   Stack mainCol = Stack(children: <Widget>
   [ Column(children: <Widget>
     [Expanded(child: list), card])
   , Positioned(
      child: sendButCol,
      bottom: 4.0,
      right: 4.0)
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
            style: cts.appBarTitleStl);
   } else {
      title = ListTile(
          leading: CircleAvatar(
              child: cts.unknownPersonIcon,
              backgroundColor: Colors.grey),
          title: Text(ch.getChatDisplayName(),
                maxLines: 1,
                overflow: TextOverflow.clip,
                style: cts.appBarTitleStl),
          dense: true,
          subtitle:
             Text(postSummary,
                maxLines: 1,
                overflow: TextOverflow.clip,
                style: cts.appBarSubtitleStl)
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
                   icon: Icon(Icons.arrow_back,
                              color: Colors.white),
                 onPressed: onWillPopScope)
             ),
          body: mainCol,
          backgroundColor: Colors.grey[300],
       )
    );
}

Widget makeTabWidget(int n, String title, double opacity)
{
   if (n == 0)
      return Text(title);

   List<Widget> widgets = List<Widget>(2);
   widgets[0] = Text(title);

   // See: https://docs.flutter.io/flutter/material/TabBar/labelColor.html
   // for opacity values.
   widgets[1] =
      Opacity( child: makeCircleUnreadMsgs(n, Colors.white,
                      cts.primaryColor)
             , opacity: opacity);

   return Row(children: widgets);
}

Text createMenuItemSubStrWidget(String str)
{
   if (str == null)
      return null;

   return Text(str, style: cts.listTileSubtitleStl,
               maxLines: 1, overflow: TextOverflow.clip);
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
makeFilteListTileTitleWidget(
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
ListView createFilterListView(BuildContext context,
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
      itemBuilder: (BuildContext context, int i)
      {
         if (shift == 1 && i == 0) {
            // Handles the *select all* button.
            return ListTile(
                leading: Icon(
                   Icons.select_all,
                   size: 35.0,
                   color: Theme.of(context).primaryColor),
                title: Text(cts.menuSelectAllStr,
                            style: cts.listTileTitleStl),
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
                   style: cts.listTileSubtitleStl,
                   maxLines: 2,
                   overflow: TextOverflow.clip);
            }

            Color cc = Colors.grey;
            if (child.leafReach > 0)
               cc = Theme.of(context).primaryColor;

            RichText title = 
               makeFilteListTileTitleWidget(
                  child.name,
                  ' (${child.leafCounter})',
                  cts.listTileTitleStl,
                  TextStyle(
                     fontSize: cts.listTileSubtitleFontSize,
                     color: Colors.grey));

            // Notice we do not subtract -1 on onLeafPressed so that
            // this function can diferentiate the Todos button case.
            final String abbrev = makeStrAbbrev(child.name);
            return ListTile(
                leading: 
                   makeCircleAvatar(
                      Text(abbrev, style: cts.abbrevStl),
                      cc),
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
            cc = Theme.of(context).primaryColor;

         RichText title = 
            makeFilteListTileTitleWidget(
               titleStr,
               ' ($c/$cs)',
               cts.listTileTitleStl,
               TextStyle(
                  fontSize: cts.listTileSubtitleFontSize,
                  color: Colors.grey));
               
         return
            ListTile(
                leading: makeCircleAvatar(
                   Text(makeStrAbbrev(o.children[i].name),
                        style: cts.abbrevStl), cc),
                title: title,
                dense: true,
                subtitle: Text(
                   subtitle,
                   style: cts.listTileSubtitleStl,
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
                  fontSize: cts.mainFontSize)),
         color: color,
         onPressed: onPressed);

   return Center(child: ButtonTheme(minWidth: 100.0, child: but));
}

// Study how to convert this into an elipsis like whatsapp.
Container makeCircleUnreadMsgs(int n, Color bgColor, Color textColor)
{
   final Text txt =
      Text("${n}",
           style: TextStyle(
              color: textColor,
              fontSize: cts.listTileSubtitleFontSize));
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
                                , style: cts.listTileTitleStl));
      leftList.add(left);

      RichText right =
         RichText(text: TextSpan( text: values[i]
                                , style: cts.defaultTextStl));
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
                     , style: cts.defaultTextStl);
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
                  Post data,
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
                            Post post,
                            List<MenuItem> menus,
                            Color color)
{
   List<Card> list = makeMenuInfoCards(context, post, menus, color);
   DateTime date = DateTime.fromMillisecondsSinceEpoch(post.date);
   DateFormat format = DateFormat.yMd().add_jm();
   String dateString = format.format(date);

   List<String> values = List<String>();
   values.add(post.nick);
   values.add('${post.from}');
   values.add('${post.id}');
   values.add(dateString);
   values.add(post.description);

   Card dc1 =
      makePostElem( context, values, cts.descList
                  , Icon( Icons.description
                        , color: cts.postFrameColor));

   list.add(dc1);
   list.add(makePostDetailElem(post.filter));

   return list;
}

String makePostSummaryStr(MenuNode root, Post post)
{
   final List<String> names = loadNames(root, post.channel[1][0]);
   return names.join('/');
}

Card createChatEntry(BuildContext context,
                     Post post,
                     List<MenuItem> menus,
                     Widget chats,
                     Function onDelPost,
                     int i)
{
   List<Card> textCards = postTextAssembler(context, post, menus,
                                       cts.postFrameColor);

   IconButton leading = IconButton(icon: Icon(Icons.delete_forever),
                onPressed: () {onDelPost(i);});

   final String postSummaryStr =
      makePostSummaryStr(menus[1].root.first, post);

   ExpansionTile et =
      ExpansionTile(
          leading: leading,
          key: PageStorageKey<int>(2 * post.id),
          title: Text(postSummaryStr,
                      maxLines: 2,
                      overflow: TextOverflow.clip,
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
         final int c = o.children[i].leafReach;
         final int cs = o.children[i].leafCounter;

         final String names = o.children[i].getChildrenNames();

         MenuNode child = o.children[i];
         if (child.isLeaf()) {
            return ListTile(
                leading: makeCircleAvatar(
                   Text(makeStrAbbrev(child.name),
                        style: cts.abbrevStl),
                   Colors.grey),
                title: Text(child.name, style: cts.listTileTitleStl),
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
                title: Text(o.children[i].name, style: cts.listTileTitleStl),
                dense: true,
                subtitle: Text(
                   names,
                   style: cts.listTileSubtitleStl,
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

   if (i <= ch.lastAppReadIdx)
      icon = Icon(Icons.done_all, color: Colors.green, size: s);
   else if (i <= ch.lastAppReceivedIdx) {
      icon = Icon(Icons.done_all, color: Colors.grey, size: s);
   } else if (i <= ch.lastServerAckedIdx) {
      icon = Icon(Icons.check, color: Colors.grey, size: s);
   }

   return Padding(
      child: icon,
      padding: const EdgeInsets.symmetric(horizontal: 2.0));
}

Widget makeChatTileSubStr(final Chat ch)
{
   final String str = ch.lastChatItem.msg;

   if (ch.nUnreadMsgs > 0 ||
       ch.lastChatItem.msg.isEmpty ||
       !ch.lastChatItem.thisApp)
      return createMenuItemSubStrWidget(str);

   // FIXME: Here we have to pass the biggest index in Chat class.
   // However it is necessary to incomporate one more index, the last
   // index.
   return Row(children: <Widget>
   [ chooseMsgStatusIcon(ch, 0)
   , Expanded(child: createMenuItemSubStrWidget(str))]);
}

String makeDateString(int date)
{
   DateTime dateObj = DateTime.fromMillisecondsSinceEpoch(date);
   DateFormat format = DateFormat.Hm();
   return format.format(dateObj);
}

Widget
makeChatListTileTrailingWidget(
   int nUnreadMsgs,
   int date,
   int pinDate,
   int now,
   bool isFwdChatMsgs)
{
   if (isFwdChatMsgs)
      return null;

   Text dateText = Text(makeDateString(date),
         style: cts.listTileSubtitleStl);

   if (nUnreadMsgs != 0 && pinDate != 0) {
      Row row = Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>
      [ Icon(Icons.place)
      , makeCircleUnreadMsgs(nUnreadMsgs, cts.newMsgCircleColor,
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
         , makeCircleUnreadMsgs(nUnreadMsgs, cts.newMsgCircleColor,
                                Colors.white)
         ]);
   }

   return dateText;
}

Color selectColor(int n)
{
   switch (n) {
      case 2: return Colors.pink;
      case 3: return Colors.pinkAccent;
      case 4: return Colors.redAccent;
      case 5: return Colors.deepOrange;
      case 6: return Colors.teal;
      case 7: return Colors.orange;
      case 8: return Colors.orangeAccent;
      case 9: return Colors.amberAccent;
      case 10: return Colors.lightGreen;
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
   Function onPinPost)
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
         bgColor = cts.chatLongPressendColor;
      } else {
         widget = cts.unknownPersonIcon;
         bgColor = Colors.white;
      }

      Widget trailing =
         makeChatListTileTrailingWidget(
            n, ch[i].lastChatItem.date,
            ch[i].pinDate, now, isFwdChatMsgs);

      ListTile lt =
         ListTile(
            dense: false,
            enabled: true,
            leading: makeChatListTileLeading(
               widget,
               selectColor(ch[i].nick.length),
               (){onLeadingPressed(ctx, post.id, i);}),
            trailing: trailing,
            title: Text(ch[i].getChatDisplayName(),
               maxLines: 1,
               overflow: TextOverflow.clip,
               style: cts.listTileTitleStl),
            subtitle: makeChatTileSubStr(ch[i]),
            //contentPadding: EdgeInsets.symmetric(horizontal: 10.0),
            onTap: () { onPressed(i); },
            onLongPress: () { onLongPressed(i); });

      list[i] = Container(
         margin: const EdgeInsets.only(bottom: 3.0),
         decoration: BoxDecoration(
            //border: Border.all(color: Colors.black),
            borderRadius: BorderRadius.all(Radius.circular(10.0)),
            color: bgColor),
         child: lt);
   }

  if (list.length == 1)
     return Column(children: list);

   final TextStyle stl =
             TextStyle(fontSize: 15.0,
                       fontWeight: FontWeight.normal,
                       color: Colors.white);

   String str = '${ch.length} conversas';
   if (nUnredChats != 0)
      str = '${ch.length} conversas / $nUnredChats nao lidas';

   IconData pinIcon =
      post.pinDate == 0 ? Icons.place : Icons.pin_drop;

   final bool expState = ch.length <= 5 || nUnredChats != 0;
   return ExpansionTile(
       initiallyExpanded: expState,
       leading: IconButton(icon: Icon(pinIcon), onPressed: onPinPost),
       key: PageStorageKey<int>(2 * post.id + 1),
       title: Text(str, style: cts.expTileStl),
       children: list);
}

Widget makeChatTab(
   BuildContext context,
   List<Post> posts,
   Function onPressed,
   Function onLongPressed,
   List<MenuItem> menus,
   Function onDelPost,
   Function onPinPost,
   bool isFwdChatMsgs,
   Function onLeadingPressed)
{
   return ListView.builder(
         padding: const EdgeInsets.all(0.0),
         itemCount: posts.length,
         itemBuilder: (BuildContext context, int i)
         {
            final int now = DateTime.now().millisecondsSinceEpoch;
            return createChatEntry(
                context,
                posts[i],
                menus,
                makePostChatCol(
                   context,
                   posts[i].chats,
                   (j) {onPressed(i, j);},
                   (j) {onLongPressed(i, j);},
                   posts[i],
                   isFwdChatMsgs,
                   onLeadingPressed,
                   now,
                   () {onPinPost(i);}),
                onDelPost,
                i);
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
   List<MenuItem> _menus = List<MenuItem>();

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

   TabController _tabCtrl;
   ScrollController _scrollCtrl = ScrollController();
   ScrollController _chatScrollCtrl = ScrollController();

   // The *new post* text controler
   TextEditingController _txtCtrl = TextEditingController();
   FocusNode _chatFocusNode;

   IOWebSocketChannel channel;
   
   Database _db;

   @override
   void initState()
   {
      super.initState();
      _tabCtrl = TabController(vsync: this, initialIndex: 1, length: 3);
      _tabCtrl.addListener(_tabCtrlChangeHandler);
      _chatFocusNode = FocusNode();
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

   Future<void> _load(final String docDir) async
   {
      _db = await openDatabase(
         p.join(await getDatabasesPath(), 'main.db'),
         readOnly: false,
         onCreate: onCreateDb,
         version: 1);

      try {
         final List<Config> configs = await loadConfig(_db, 'config');
         if (!configs.isEmpty)
            cfg = configs.first;
      } catch (e) {
         print(e);
      }

      _dialogPrefs[0] = cfg.showDialogOnDelPost == 'yes';
      _dialogPrefs[1] = cfg.showDialogOnSelectPost == 'yes';
      _menus = menuReader(jsonDecode(cfg.menu));

      // We do not need all fields from cfg.menu during runtime. The
      // menu field is big and we should release its memory.
      cfg.menu = '';

      List<String> lines = List<String>();

      try {
         final List<Post> posts = await loadPosts(_db, 'posts');
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
               print('====> ${p.status}');
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

      List<ChatMsgOutQueueElem> tmp =
         await loadOutChatMsg(_db, 'out_chat_msg_queue');

      _outChatMsgsQueue = Queue<ChatMsgOutQueueElem>.from(tmp.reversed);

      channel = IOWebSocketChannel.connect(cts.host);
      channel.stream.listen(onWSData, onError: onWSError, onDone: onWSDone);

      final List<int> versions = makeMenuVersions(_menus);
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
         await _db.execute(cts.updateShowDialogOnDelPost, [str]);
      else
         await _db.execute(cts.updateShowDialogOnSelectPost, [str]);
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
               cts.dialTitleStrs[fav],
               cts.dialBodyStrs[fav]);
            
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
         batch.rawInsert(cts.insertChatStOnPost,
            makeChatUpdateSql(_posts[i].chats[j], _posts[i].id));

         batch.execute(cts.updatePostStatus, [2, _posts[i].id]);

         await batch.commit(noResult: true, continueOnError: true);

         _favPosts.add(_posts[i]);
         _favPosts.sort(CompPosts);

      } else {
         await _db.execute(cts.deletePost, [_posts[i].id]);
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
      _menus[0].restoreMenuStack();
      _menus[1].restoreMenuStack();
      _botBarIdx = 0;
      setState(() { });
   }

   void _onNewFilters()
   {
      _newFiltersPressed = true;
      _menus[0].restoreMenuStack();
      _menus[1].restoreMenuStack();
      _botBarIdx = 0;
      setState(() { });
   }

   bool _onWillPopMenu()
   {
      // We may want to  split this function in two: One for the
      // filters and one for the new post screen.
      if (_botBarIdx >= _menus.length) {
         --_botBarIdx;
         setState(() { });
         return false;
      }

      if (_menus[_botBarIdx].root.length == 1) {
         if (_botBarIdx == 0){
            _newPostPressed = false;
            _newFiltersPressed = false;
         } else {
            --_botBarIdx;
         }

         setState(() { });
         return false;
      }

      _menus[_botBarIdx].root.removeLast();
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
      for (Coord c1 in _lpChats) {
         myprint(c1, '');
         for (Coord c2 in _lpChatMsgs) {
            if (_isOnFav()) {
               await _onSendChatMsgImpl(
                  _favPosts, c1.post.id, c1.chat.peer,
                   false, c2.chat.msgs[c2.msgIdx].msg);
            } else {
               myprint(c2, '   ');
               await _onSendChatMsgImpl(
                  _ownPosts, c1.post.id, c1.chat.peer,
                  true, c2.chat.msgs[c2.msgIdx].msg);
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
      await _db.rawUpdate(cts.updateNUnreadMsgs, [0, _post.id, _chat.peer]);

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

   Future<void> _onSendChatMsg() async
   {
      if (_isOnFav()) {
         await _onSendChatMsgImpl(_favPosts, _post.id,
                                 _chat.peer, false,
                                 _txtCtrl.text);
      } else {
         await _onSendChatMsgImpl(_ownPosts, _post.id,
                                  _chat.peer, true,
                                  _txtCtrl.text);
      }

      _txtCtrl.text = "";

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
      print('Message $k has been dragged.');
      FocusScope.of(ctx).requestFocus(_chatFocusNode);
      setState(() { });
   }

   void _onChatMsgReply(BuildContext ctx)
   {
      print('Reply requested.');
      //_toggleLPChatMsgs(int k, false)
      FocusScope.of(ctx).requestFocus(_chatFocusNode);
      setState(() { });
   }

   void _onBotBarTapped(int i)
   {
      if (_botBarIdx < _menus.length)
         _menus[_botBarIdx].restoreMenuStack();

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
         _menus[_botBarIdx].restoreMenuStack();
      } while (_botBarIdx != i);

      setState(() { });
   }

   void _onPostLeafPressed(int i)
   {
      MenuNode o = _menus[_botBarIdx].root.last.children[i];
      _menus[_botBarIdx].root.add(o);
      _onPostLeafReached();
      setState(() { });
   }

   void _onPostLeafReached()
   {
      _post.channel[_botBarIdx][0] = _menus[_botBarIdx].root.last.code;
      _menus[_botBarIdx].restoreMenuStack();
      _botBarIdx = postIndexHelper(_botBarIdx);
   }

   void _onPostNodePressed(int i)
   {
      // We continue pushing on the stack if the next screen will have
      // only one menu option.
      do {
         MenuNode o = _menus[_botBarIdx].root.last.children[i];
         _menus[_botBarIdx].root.add(o);
         i = 0;
      } while (_menus[_botBarIdx].root.last.children.length == 1);

      final int length = _menus[_botBarIdx].root.last.children.length;

      assert(length != 1);

      if (length == 0) {
         _onPostLeafReached();
      }

      setState(() { });
   }

   void _onFilterNodePressed(int i)
   {
      MenuNode o = _menus[_botBarIdx].root.last.children[i];
      _menus[_botBarIdx].root.add(o);

      setState(() { });
   }

   void _onFilterLeafNodePressed(int k)
   {
      // k = 0 means the *check all fields*.
      if (k == 0) {
         _menus[_botBarIdx].updateLeafReachAll();
         setState(() { });
         return;
      }

      --k; // Accounts for the Todos index.

      _menus[_botBarIdx].updateLeafReach(k);
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
         await _db.execute(cts.updatePostOnAck,
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
         await _db.execute(cts.deletePost, [_favPosts[i].id]);
         _favPosts.removeAt(i);
      } else {
         await _db.execute(cts.deletePost, [_ownPosts[i].id]);
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
      _txtCtrl.text = '';

      _post.from = cfg.appId;
      _post.nick = cfg.nick;
      _post.status = 3;
      await _sendPost(_post.clone());
      _post = null;
      setState(() { });

      // If the user cancels the operation we do not show the dialog.
      if (i == 1)
         _showSimpleDial(ctx, (){},
                         cts.dialTitleStrs[3],
                         cts.dialBodyStrs[3]);
   }

   void _removePostDialog(BuildContext ctx, int i)
   {
      _showSimpleDial(ctx, () async { await _onRemovePost(i);},
                      cts.dialTitleStrs[4],
                      cts.dialBodyStrs[4]);
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

   void _onLeadingPressed(BuildContext ctx, int postId, int j)
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

      print('=====> $postId $i');

      final String content = 'Id: ${posts[i].chats[j].peer}';
      _showSimpleDial(ctx, (){}, cts.userInfo, content);
   }

   void _onChatLPImpl(List<Post> posts, int i, int j)
   {
      final Coord tmp = Coord(posts[i], posts[i].chats[j], -1);

      handleLPChats(
         _lpChats,
         toggleLPChat(posts[i].chats[j]),
         tmp, CompPostIdAndPeer);
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
      ChatMsgOutQueueElem tmp =
         ChatMsgOutQueueElem(-1, isChat, payload, false);

      _outChatMsgsQueue.add(tmp);

      final int rowid =
         await _db.rawInsert(cts.insertOutChatMsg, [isChat, payload]);

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

      final Coord tmp = Coord(_post, _chat, k);

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
                      String msg) async
   {
      try {
         if (msg.isEmpty)
            return;

         final int i = posts.indexWhere((e) { return e.id == postId;});
         assert(i != -1);

         // We have to make sure every unread msg is marked as read
         // before we receive any reply.
         final int j = posts[i].getChatHistIdx(peer);
         assert(j != -1);

         final int now = DateTime.now().millisecondsSinceEpoch;
         final ChatItem item = ChatItem(true, msg, now);
         posts[i].chats[j].lastChatItem = item;
         assert(posts[i].chats[j].isLoaded());
         posts[i].chats[j].msgs.add(item);
         posts[i].chats[j].persistChatMsg(item, postId);

         await _db.transaction((txn) async {
            Batch batch = txn.batch();

            // Perhaps we should update only the last chat item here
            // for performance?
            batch.rawInsert(cts.insertOrReplaceChatOnPost,
               makeChatUpdateSql(posts[i].chats[j], postId));
            batch.rawInsert(cts.insertChatMsg, [postId, peer, 1, now, msg]);
            await batch.commit(noResult: true, continueOnError: true);
         });

         posts[i].chats.sort(CompChats);
         posts.sort(CompPosts);

         var msgMap = {
            'cmd': 'message',
            'type': 'chat',
            'to': peer,
            'msg': msg,
            'post_id': postId,
            'is_sender_post': isSenderPost,
            'nick': cfg.nick
         };

         await sendChatMsg(jsonEncode(msgMap), 1);

      } catch(e) {
      }
   }

   void _chatServerAckHandler(Map<String, dynamic> ack, Batch batch)
   {
      try {
         assert(_outChatMsgsQueue.first.sent);
         assert(!_outChatMsgsQueue.isEmpty);
         final String res = ack['result'];

         batch.rawDelete(cts.deleteOutChatMsg,
                         [_outChatMsgsQueue.first.rowid]);

         final bool isChat = _outChatMsgsQueue.first.isChat == 1;
         _outChatMsgsQueue.removeFirst();

         if (res == 'ok' && isChat)
            _chatAppAckHandler(ack, 1, batch);

         if (!_outChatMsgsQueue.isEmpty) {
            assert(!_outChatMsgsQueue.first.sent);
            _outChatMsgsQueue.first.sent = true;
            channel.sink.add(_outChatMsgsQueue.first.payload);
         }
      } catch (e) {
         print(e);
      }
   }

   Future<void> _chatMsgHandler(Map<String, dynamic> ack) async
   {
      final int postId = ack['post_id'];
      final bool isSenderPost = ack['is_sender_post'];
      final String to = ack['to'];
      final String msg = ack['msg'];
      final String peer = ack['from'];
      final String nick = ack['nick'];

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
                                nick, isSenderPost, posts);
   }

   Future<void>
   _chatMsgHandlerImpl(String to,
                       int postId,
                       String msg,
                       String peer,
                       String nick,
                       bool isSenderPost,
                       List<Post> posts) async
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
      final ChatItem item = ChatItem(false, msg, now);
      posts[i].chats[j].lastChatItem = item;
      if (posts[i].chats[j].isLoaded())
         posts[i].chats[j].msgs.add(item);
      posts[i].chats[j].persistChatMsg(item, postId);

      // If we are in the screen having chat with the user we can ack
      // it with app_ack_read and skip app_ack_received.
      final bool isOnPost = _post != null && _post.id == postId; 
      final bool isOnChat = _chat != null && _chat.peer == peer; 

      String ack;
      if (isOnPost && isOnChat) {
         posts[i].chats[j].nUnreadMsgs = 0;
         ack = 'app_ack_read';
         // TODO: Put an indicator that a new message has arrived
         // if it out of the field of view.
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

      await _db.transaction((txn) async {
         Batch batch = txn.batch();
         batch.rawInsert(cts.insertOrReplaceChatOnPost,
            makeChatUpdateSql(chat, postId));
         batch.rawInsert(cts.insertChatMsg, [postId, peer, 0, now, msg]);
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
         _chatMsgHandler(ack);
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

      _menus = menuReader(ack);
      assert(_menus != null);

      await _persistMenu();
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

      if (ack.containsKey('menus')) {
         // The server has sent us a menu, that means we have to
         // update the current one keeping the status of each
         // field. TODO: Keep the status field.
         _menus = menuReader(ack);
         assert(_menus != null);
         await _persistMenu();
      }
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

      batch.execute(cts.updateLastPostId, [cfg.lastPostId]);
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

   Future<void> _persistMenu() async
   {
      print('====> Updating the menu.');
      try {
         var foo = {'menus': _menus};
         final String str = jsonEncode(foo);
         await _db.execute(cts.updateMenu, [str]);
      } catch (e) {
         print(e);
      }
   }

   Future<void> _onSendFilters(BuildContext ctx) async
   {
      _newFiltersPressed = false;

      // First send the hashes then show the dialog.
      _subscribeToChannels();

      _showSimpleDial(ctx,
                      _onOkDialAfterSendFilters,
                      cts.dialTitleStrs[2],
                      cts.dialBodyStrs[2]);

      // We also have to persist the menu on file here since we may
      // not receive a subscribe_ack if the app is offline.
      await _persistMenu();
   }

   void _subscribeToChannels()
   {
      List<List<List<int>>> channels = List<List<List<int>>>();
      for (MenuItem item in _menus) {
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
      _unmarkLPChats();

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
               await _db.execute(cts.deletePost, [o.id]);

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
                     child: cts.deleteChatOkText,
                     onPressed: () async
                     {
                        await _removeLPChats();
                        Navigator.of(ctx).pop();
                     });

            final FlatButton cancel = FlatButton(
                     child: cts.deleteChatCancelText,
                     onPressed: ()
                     {
                        Navigator.of(ctx).pop();
                     });

            List<FlatButton> actions = List<FlatButton>(2);
            actions[0] = cancel;
            actions[1] = ok;

            Text txt = cts.delOwnChatTitleText;
            if (_isOnFav()) {
               txt = cts.delFavChatTitleText;
            }

            return AlertDialog(
                  title: txt,
                  content: Text(""),
                  actions: actions);
         },
      );
   }

   void _onBackFromChatMsgRedirect()
   {
      assert(!_lpChatMsgs.isEmpty);

      // Unmark any long pressed chats.
      _unmarkLPChats();

      // All items int _lpChatMsgs should have the same post id and
      // peer so we can use the first.
      _post = _lpChatMsgs.first.post;
      _chat = _lpChatMsgs.first.chat;

      setState(() { });
   }

   Future<void> _onNickPressed() async
   {
      cfg.nick = _txtCtrl.text;;
      _txtCtrl.text = '';
      await _db.execute(cts.updateNick, [cfg.nick]);
      setState(() { });
   }

   Future<void> _updateLastSeenPostIdx(int i) async
   {
      if (i <= _lastSeenPostIdx)
         return;

      _lastSeenPostIdx = i;

      await _db.execute(cts.updateLastSeenPostId,
                        [_posts[i].id]);

      SchedulerBinding.instance.addPostFrameCallback((_)
      {
         setState(() { });
      });
   }

   void _onNewPostDetail(int i)
   {
      if (i == cts.postDetails.length) {
         _botBarIdx = 3;
         setState(() { });
         return;
      }

      _post.filter ^= 1 << i;
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
      if (_menus.isEmpty)
         return Scaffold();

      if (cfg.nick.isEmpty)
         return makeNickRegisterScreen(_txtCtrl, _onNickPressed);

      if (hasSwitchedTab())
         _cleanUpLpOnSwitchTab();

      if (_newPostPressed) {
         return
            makeNewPostScreens(
               ctx,
               _post,
               _menus,
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
               _menus,
               _filter,
               _botBarIdx,
               _onCancelNewFilter);

      if (isOnFavChat() || isOnOwnChat()) {
         String postSummary =
            makePostSummaryStr(_menus[1].root.first, _post);
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
            postSummary);
      }

      List<Function> onWillPops = List<Function>(cts.tabNames.length);
      onWillPops[0] = _onChatsBackPressed;
      onWillPops[1] = (){return false;};
      onWillPops[2] = _onChatsBackPressed;

      String appBarTitle = cts.appName;

      List<FloatingActionButton> fltButtons =
            List<FloatingActionButton>(cts.tabNames.length);

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

      List<Widget> bodies = List<Widget>(cts.tabNames.length);
      bodies[0] = makeChatTab(
         ctx,
         _ownPosts,
         _onChatPressed,
         _onChatLP,
         _menus,
         (int i) { _removePostDialog(ctx, i);},
         _onPinPost,
         !_lpChatMsgs.isEmpty,
         _onLeadingPressed);

      bodies[1] = makePostTabListView(
         ctx,
         _posts,
         _alertUserOnselectPost,
         _menus,
         _updateLastSeenPostIdx);

      bodies[2] = makeChatTab(
         ctx,
         _favPosts,
         _onChatPressed,
         _onChatLP,
         _menus,
         (int i) { _removePostDialog(ctx, i);},
         _onPinPost,
         !_lpChatMsgs.isEmpty,
         _onLeadingPressed);

      List<Widget> actions = List<Widget>();
      Widget appBarLeading = null;
      if (_isOnFav() || _isOnOwn()) {
         if (_hasLPChatMsgs()) {
            appBarTitle = 'Redirecionando ...';
            appBarLeading = IconButton(
               icon: Icon(Icons.arrow_back , color: Colors.white),
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

      actions.add(Icon(Icons.more_vert, color: Colors.white));

      List<int> newMsgsCounters = List<int>(cts.tabNames.length);
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
                       title: Text(appBarTitle, style: TextStyle(color: Colors.white)),
                       pinned: true,
                       floating: true,
                       forceElevated: innerBoxIsScrolled,
                       bottom: makeTabBar(newMsgsCounters,
                                         _tabCtrl,
                                         opacities,
                                         _hasLPChatMsgs()),
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

