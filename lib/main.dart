import 'dart:async';
import 'dart:convert';
import 'dart:io' show File, FileMode, Directory;
import 'dart:collection';

import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:device_info/device_info.dart';
import 'package:flutter/scheduler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:intl/intl.dart';
import 'package:image_picker_modern/image_picker_modern.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:crypto/crypto.dart';
import 'package:square_in_app_payments/in_app_payments.dart';
import 'package:square_in_app_payments/models.dart' as sq;
import 'package:dio/dio.dart';

import 'package:flutter/material.dart';
import 'package:menu_chat/post.dart';
import 'package:menu_chat/tree.dart';
import 'package:menu_chat/constants.dart' as cts;
import 'package:menu_chat/txt_pt.dart' as txt;
import 'package:menu_chat/globals.dart' as glob;
import 'package:menu_chat/sql.dart' as sql;
import 'package:menu_chat/stl.dart' as stl;

String emailToGravatarHash(String email)
{
   // Removes spaces.
   email = email.replaceAll(' ', '');
   email = email.toLowerCase();
   List<int> bytes = utf8.encode(email);
   return md5.convert(bytes).toString();
}

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

Future<void> onPinPost(List<Post> posts, int i, Database db) async
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

class AppMsgQueueElem {
   int rowid;
   int isChat;
   String payload;
   bool sent; // Used for debugging.
   AppMsgQueueElem({
      this.rowid = 0,
      this.isChat = 0,
      this.payload = '',
      this.sent = false,
   });
}

Future<List<AppMsgQueueElem>> loadOutChatMsg(Database db) async
{
  final List<Map<String, dynamic>> maps =
     await db.rawQuery(sql.loadOutChats);

  return List.generate(maps.length, (i)
  {
     return AppMsgQueueElem(
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
             child: Text(txt.changeNichHint),
           ),
           const PopupMenuItem<ConfigActions>(
             value: ConfigActions.ChangeProfilePhoto,
             child: Text(txt.changePhoto),
           ),
        ];
     }
   );
}

List<Widget> makeOnLongPressedActions(
   BuildContext ctx,
   Function deleteChatEntryDialog,
   Function pinChat)
{
   List<Widget> actions = List<Widget>();

   IconButton pinChatBut = IconButton(
      icon: Icon(Icons.place, color: Colors.white),
      tooltip: txt.pinChat,
      onPressed: pinChat);

   actions.add(pinChatBut);

   IconButton delChatBut = IconButton(
      icon: Icon(Icons.delete_forever, color: Colors.white),
      tooltip: txt.deleteChat,
      onPressed: () { deleteChatEntryDialog(ctx); });

   actions.add(delChatBut);

   return actions;
}

Scaffold makeWaitMenuScreen(BuildContext ctx)
{
   return Scaffold(
      appBar: AppBar(title: Text(txt.appName)),
      body: Center(child: CircularProgressIndicator()),
      backgroundColor: Theme.of(ctx).colorScheme.background,
   );
}

TextField makeNickTxtField(
   BuildContext ctx,
   TextEditingController txtCtrl,
   Icon icon,
   int fieldMaxLength,
   String hint)
{
   Color focusedColor = Theme.of(ctx).colorScheme.primary;

   Color enabledColor = Colors.red;
   if (txtCtrl.text.isNotEmpty)
      enabledColor = focusedColor;

   return TextField(
      controller: txtCtrl,
      maxLines: 1,
      maxLength: fieldMaxLength,
      decoration: InputDecoration(
         hintText: hint,
         focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(
               Radius.circular(stl.cornerRadius),
            ),
            borderSide: BorderSide(
               color: focusedColor,
               width: 2.5
            ),
         ),
         enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(
               Radius.circular(stl.cornerRadius),
            ),
            borderSide: BorderSide(
               color: enabledColor,
               width: 2.5,
            ),
         ),
         prefixIcon: icon,
      ),
   );
}

Scaffold makeRegisterScreen(
   BuildContext ctx,
   TextEditingController emailCtrl,
   TextEditingController nickCtrl,
   Function onContinue,
   String appBarTitle,
   String previousEmail,
   String previousNick)
{
   if (previousEmail.isNotEmpty)
      emailCtrl.text = previousEmail;

   TextField emailTf = makeNickTxtField(
      ctx, emailCtrl, Icon(Icons.email),
      cts.emailMaxLength, txt.emailHint,
   );

   if (previousNick.isNotEmpty)
      nickCtrl.text = previousNick;

   TextField nickTf = makeNickTxtField(
      ctx, nickCtrl, Icon(Icons.person),
      cts.nickMaxLength, txt.nickHint,
   );

   Widget button = createRaisedButton(
      ctx, onContinue,
      txt.next,
   );

   Column col = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>
      [ Padding(
           child: emailTf,
           padding: EdgeInsets.only(bottom: 30.0),
        )
      , Padding(
           child: nickTf,
           padding: EdgeInsets.only(bottom: 30.0),
        )
      , button
      ]
   );

   return Scaffold(
      appBar: AppBar(title: Text(appBarTitle)),
      body: Center(
         child: Padding(
            child: col,
            padding: EdgeInsets.symmetric(horizontal: 20.0),
         ),
      ),
   );
}

Widget makeNetImgBox(
   double width,
   double height,
   String url)
{
   Widget img = CachedNetworkImage(
      imageUrl: url,
      imageBuilder: (ctx, imageProvider) => Container(
        decoration: BoxDecoration(
           image: DecorationImage(
              image: imageProvider,
              fit: BoxFit.cover,
           ),
        ),
      ),
      placeholder: (ctx, url) => CircularProgressIndicator(),
      errorWidget: (ctx, url, error) {
         // TODO: Replace this with a proper widget.
         print('====> $error $url');
         return Icon(Icons.error);
      },
   );

   return FlatButton(
      onPressed: (){print('===> ');},
      child: SizedBox(
         width: width,
         height: height,
         child: Center(child: img),
      ),
   );
}

Widget makeAddImgBox(
   double width,
   double height,
   Function onAddPhoto)
{
   return SizedBox(
      width: width,
      height: height,
      child: Card(
         color: Colors.grey[500],
         child: Center(
            child: IconButton(
               onPressed: () {onAddPhoto(0);},
               icon: Icon(Icons.add_a_photo,
                  color: stl.colorScheme.primary,
                  size: 30.0,
               ),
            ),
         ),
      ),
   );
}

Widget makeImgListView(
   double width,
   double height,
   Function onAddPhoto,
   List<File> imgFiles,
   Post post)
{
   int l = 1;
   if (post.images.isNotEmpty) {
      l = post.images.length;
   } else if (imgFiles.isNotEmpty) {
      l = imgFiles.length;
   }

   ListView lv = ListView.builder(
      scrollDirection: Axis.horizontal,
      shrinkWrap: true,
      padding: const EdgeInsets.all(4.0),
      itemCount: l,
      itemBuilder: (BuildContext ctx, int i)
      {
         if (post.images.isNotEmpty) {
            return makeNetImgBox(
               width,
               height,
               post.images[i],
            );
         }

         if (imgFiles.isNotEmpty) {
            // FIXME: Use a stack to superpose the images and the add
            // a photo buttom. 
            return Image.file(imgFiles[i],
               width: width,
               height: height,
            );
         }

         return makeAddImgBox(
            width,
            height,
            onAddPhoto,
         );
      },
   );

   return ConstrainedBox(
      constraints: BoxConstraints(
         maxWidth: width,
         minWidth: width,
         maxHeight: height,
         minHeight: height,
      ),
      child: SingleChildScrollView(
         scrollDirection: Axis.horizontal,
         reverse: true,
         child: lv
      ),
   );
}

int searchBitOn(int o, int n)
{
   assert(n < 64);

   while (--n > 0) {
      if (o & (1 << n) != 0)
         return n;
   }

   return 0;
}

RichText makeExpTileTitle(
   BuildContext ctx,
   String first,
   String second,
   String sep,
   bool changeColor)
{
   Color color = changeColor
               ? Theme.of(ctx).colorScheme.secondaryVariant
               : Theme.of(ctx).colorScheme.secondary;

   return RichText(
      text: TextSpan(
         text: '$first$sep ',
         style: TextStyle(
             //fontWeight: FontWeight.w500,
             color: Theme.of(ctx).colorScheme.onPrimary,
             fontSize: Theme.of(ctx).textTheme.subhead.fontSize,
         ),
         children: <TextSpan>
         [ TextSpan(
              text: second,
              style: TextStyle(
                  fontWeight: FontWeight.normal,
                  color: color,
                  fontSize: Theme.of(ctx).textTheme.subhead.fontSize,
              ),
           )
         ]
      ),
   );
}

Widget wrapOnDetailExpTitle(
   BuildContext ctx,
   Widget title,
   List<Widget> children,
   bool initiallyExpanded)
{
   // Passing a global key has the effect that an expansion tile will
   // collapse after setState is called, but without animation not in
   // an nice way.
   Key key = UniqueKey();

   return Card(
      color: Theme.of(ctx).colorScheme.primary,
      shape: RoundedRectangleBorder(
         borderRadius: BorderRadius.all(Radius.circular(10.0)),
      ),
      child: Theme(
         data: makeExpTileThemeData(ctx),
         child: ExpansionTile(
             //key: key,
             backgroundColor: Theme.of(ctx).colorScheme.primary,
             title: title,
             children: children,
             initiallyExpanded: initiallyExpanded,
         ),
      ),
   );
}

Widget makeNewPostDetailExpTile(
   BuildContext ctx,
   Function onNewPostInDetails,
   MenuNode titleNode,
   int state,
   String strDisplay)
{
   List<Widget> bar =
      makeNewPostDetailElemList(
         ctx,
         onNewPostInDetails,
         state,
         titleNode.children,
      );

   final RichText richTitle = makeExpTileTitle(
      ctx,
      titleNode.name,
      strDisplay,
      ':',
      state == 0,
   );

   return wrapOnDetailExpTitle(ctx, richTitle, bar, false);
}

int counterBitsSet(int v)
{
   // See https://graphics.stanford.edu/~seander/bithacks.html#CountBitsSetKernighan
   int c; // c accumulates the total bits set in v
   for (c = 0; v != 0; c++)
     v &= v - 1;

   return c;
}

List<Widget> makeNewPostDetailScreen(
   BuildContext ctx,
   Function onNewPostExDetails,
   Function onNewPostInDetails,
   Post post,
   MenuNode exDetailsMenu,
   MenuNode inDetailsMenu,
   TextEditingController txtCtrl,
   Function onRangeValueChanged)
{
   final int idx = post.getProductDetailIdx();

   List<Widget> all = List<Widget>();

   final int l1 = exDetailsMenu.children[idx].children.length;
   for (int i = 0; i < l1; ++i) {

      final int k = searchBitOn(
         post.exDetails[i],
         exDetailsMenu.children[idx].children[i].children.length
      );

      Widget foo = makeNewPostDetailExpTile(
         ctx,
         (int j) {onNewPostExDetails(i, j);},
         exDetailsMenu.children[idx].children[i],
         post.exDetails[i],
         exDetailsMenu.children[idx].children[i].children[k].name,
      );

      all.add(foo);
   }

   final int l2 = inDetailsMenu.children[idx].children.length;
   for (int i = 0; i < l2; ++i) {
      final int nBitsSet = counterBitsSet(post.inDetails[i]);
      Widget foo = makeNewPostDetailExpTile(
         ctx,
         (int j) {onNewPostInDetails(i, j);},
         inDetailsMenu.children[idx].children[i],
         post.inDetails[i],
         '$nBitsSet items',
      );

      all.add(foo);
   }

   for (int i = 0; i < cts.rangeDivs.length; ++i) {
      final int j = 2 * i;
      Slider rangeSld = Slider(
         value: post.rangeValues[i].toDouble(),
         min: cts.rangesMinMax[j + 0].toDouble(),
         max: cts.rangesMinMax[j + 1].toDouble(),
         divisions: cts.rangeDivs[i],
         onChanged: (double v) {onRangeValueChanged(i, v);},
      );

      all.add(wrapOnDetailExpTitle(
            ctx,
            makeExpTileTitle(
               ctx,
               txt.rangePrefixes[i],
               post.rangeValues[i].toString(),
               ':',
               false,
            ),
            <Widget>[wrapDetailRowOnCard(ctx, rangeSld)],
            false,
         ),
      );
   }

   // __________________________________________________
   TextField tf = TextField(
      controller: txtCtrl,
      keyboardType: TextInputType.multiline,
      maxLines: null,
      maxLength: 200,
      style: Theme.of(ctx).textTheme.subhead,
      decoration: InputDecoration.collapsed(
         hintText: txt.newPostTextFieldHist,
      ),
   );

   Padding pad = Padding(
      padding: EdgeInsets.all(10.0),
      child: tf,
   );

   all.add(wrapOnDetailExpTitle(
         ctx,
         Text(txt.postDescTitle),
         <Widget>[wrapDetailRowOnCard(ctx, pad)],
         false,
      ),
   );

   all.add(
      createRaisedButton(
         ctx,
         (){onNewPostExDetails(-1, -1);},
         txt.next,
      ),
   );

   return all;
}

WillPopScope makeNewPostScreens(
   BuildContext ctx,
   Post post,
   final List<MenuItem> menu,
   TextEditingController txtCtrl,
   Function onSendNewPost,
   int screen,
   Function onNewPostExDetails,
   Function onPostLeafPressed,
   Function onPostNodePressed,
   Function onWillPopMenu,
   Function onNewPostBotBarTapped,
   Function onNewPostInDetails,
   MenuNode exDetailsMenu,
   MenuNode inDetailsMenu,
   Function onRangeValueChanged,
   Function onAddPhoto,
   List<File> imgFiles)
{
   Widget wid;
   Widget appBarTitleWidget = Text(txt.newPostAppBarTitle);

   if (screen == 3) {
      // NOTE: This ListView is used to provide a new context, so that
      // it is possible to show the snackbar using the scaffold.of on
      // the new context.
      wid = ListView.builder(
         shrinkWrap: true,
         padding: const EdgeInsets.all(0.0),
         itemCount: 1,
         itemBuilder: (BuildContext ctx, int i)
         {
            assert(i == 0);

            return makePostPubWidget(
               ctx,
               post,
               (int add) { onSendNewPost(ctx, add); },
               menu,
               exDetailsMenu,
               inDetailsMenu,
               stl.pubIcon,
               txt.cancelNewPost,
               onAddPhoto,
               imgFiles,
            );
         },
      );
   } else if (screen == 2) {
      final List<Widget> widgets = makeNewPostDetailScreen(
         ctx,
         onNewPostExDetails,
         onNewPostInDetails,
         post,
         exDetailsMenu,
         inDetailsMenu,
         txtCtrl,
         onRangeValueChanged,
      );

      // Consider changing this to column.
      wid = ListView.builder(
         padding: const EdgeInsets.only(
            left: stl.postListViewSidePadding,
            right: stl.postListViewSidePadding,
            top: stl.postListViewTopPadding,
         ),
         itemCount: widgets.length,
         itemBuilder: (BuildContext ctx, int i)
         {
            return widgets[i];
         },
      );
   } else {
      wid = makeNewPostMenuListView(
         ctx,
         menu[screen].root.last,
         onPostLeafPressed,
         onPostNodePressed);

      appBarTitleWidget = ListTile(
         title: Text(
            txt.newPostAppBarTitle,
            maxLines: 1,
            overflow: TextOverflow.clip,
            style: Theme.of(ctx).primaryTextTheme.title.copyWith(
               fontWeight: FontWeight.normal
            ),
         ),
         dense: true,
         subtitle: Text(menu[screen].getStackNames(),
            maxLines: 1,
            overflow: TextOverflow.clip,
            style: Theme.of(ctx).primaryTextTheme.subtitle,
         ),
      );
   }

   AppBar appBar = AppBar(
      title: appBarTitleWidget,
      elevation: 0.7,
      leading: IconButton(
         icon: Icon(Icons.arrow_back),
         onPressed: onWillPopMenu
      ),
   );

   return WillPopScope(
      onWillPop: () async { return onWillPopMenu();},
      child: Scaffold(
          appBar: appBar,
          body: wid,
          bottomNavigationBar: makeBottomBarItems(
             stl.newPostTabIcons,
             txt.newPostTabNames,
             onNewPostBotBarTapped,
             screen,
          ),
       ),
   );
}

Widget
makeNewFiltersEndWidget(
   BuildContext ctx,
   Function onSendNewFilters,
   Function onCancelNewFilters)
{
   return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      //mainAxisSize: MainAxisSize.min,
      children: <Widget>
      [ Padding(
          padding: const EdgeInsets.symmetric(vertical: 40.0),
          child: createRaisedButton(
             ctx,
             onCancelNewFilters,
             'Cancelar',
          ))
      , Padding(
          padding: const EdgeInsets.symmetric(vertical: 40.0),
          child: createRaisedButton(
             ctx,
             onSendNewFilters,
             'Enviar',
          ))
      ]);
}

WillPopScope makeNewFiltersScreens(
   BuildContext ctx,
   Function onSendFilters,
   Function onFilterDetail,
   Function onFilterNodePressed,
   Function onWillPopMenu,
   Function onBotBarTaped,
   Function onFilterLeafNodePressed,
   final List<MenuItem> menu,
   int filter,
   int screen,
   Function onCancelNewFilters,
   MenuNode exDetailsFilterNodes,
   List<int> ranges,
   Function onRangeChanged)
{
   Widget wid;
   Widget appBarTitleWidget = Text(txt.filterAppBarTitle);

   if (screen == 3) {
      wid = makeNewFiltersEndWidget(
         ctx,
         (){onSendFilters(ctx);},
         onCancelNewFilters,
      );
   } else if (screen == 2) {
      List<Widget> foo = List<Widget>();

      final Widget vv = makeNewPostDetailExpTile(
         ctx,
         onFilterDetail,
         exDetailsFilterNodes,
         filter,
         ''
      );

      foo.add(vv);

      for (int i = 0; i < cts.rangeDivs.length; ++i) {
         final int j = 2 * i;
         final int v1 = ranges[j + 0];
         final int v2 = ranges[j + 1];
         final Widget rs = RangeSlider(
            min: cts.rangesMinMax[j + 0].toDouble(),
            max: cts.rangesMinMax[j + 1].toDouble(),
            divisions: cts.rangeDivs[i],
            onChanged: (RangeValues rv) {onRangeChanged(i, rv);},
            values: RangeValues(v1.toDouble(), v2.toDouble()),
         );

         final RichText rt = makeExpTileTitle(
            ctx,
            txt.rangePrefixes[i],
            '$v1 ' + txt.rangeSep + ' $v2',
            ':',
            false,
         );

         foo.add(wrapOnDetailExpTitle(ctx, rt, <Widget>[rs], false));
      }

      wid = ListView.builder(
         padding: const EdgeInsets.all(3.0),
         itemCount: foo.length,
         itemBuilder: (BuildContext ctx, int i)
         {
            return foo[i];
         },
      );
   } else {
      wid = makeNewFilterListView(
         ctx,
         menu[screen].root.last,
         onFilterLeafNodePressed,
         onFilterNodePressed,
         menu[screen].isFilterLeaf());

      appBarTitleWidget = ListTile(
         dense: true,
         title: Text(
            txt.filterAppBarTitle,
            maxLines: 1,
            overflow: TextOverflow.clip,
            style: Theme.of(ctx).primaryTextTheme.title.copyWith(
               fontWeight: FontWeight.w500,
            ),
         ),
         subtitle: Text(menu[screen].getStackNames(),
            maxLines: 1,
            overflow: TextOverflow.clip,
            style: Theme.of(ctx).primaryTextTheme.subtitle,
         ),
      );
   }

   AppBar appBar = AppBar(
      title: appBarTitleWidget,
      leading: IconButton(
         icon: Icon(Icons.arrow_back),
         onPressed: onWillPopMenu
      ),
   );

   return WillPopScope(
       onWillPop: () async { return onWillPopMenu();},
       child: Scaffold(
           appBar: appBar,
           body: wid,
           bottomNavigationBar: makeBottomBarItems(
              stl.filterTabIcons,
              txt.filterTabNames,
              onBotBarTaped,
              screen)));
}

Widget wrapDetailRowOnCard(BuildContext ctx, Widget body)
{
   return Card(
      margin: const EdgeInsets.only(
       left: 1.5, right: 1.5, top: 0.0, bottom: 0.0
      ),
      color: Theme.of(ctx).colorScheme.background,
      child: body,
      elevation: 0.0,
      shape: RoundedRectangleBorder(
         borderRadius: BorderRadius.all(Radius.circular(0.0)),
      ),
   );
}

List<Widget> makeNewPostDetailElemList(
   BuildContext ctx,
   Function proceed,
   int filter,
   List<MenuNode> list)
{
   List<Widget> widgets = List<Widget>();

   for (int i = 0; i < list.length; ++i) {
      bool v = ((filter & (1 << i)) != 0);

      Color avatarBgColor = Theme.of(ctx).colorScheme.secondary;
      Color avatarTxtColor = Theme.of(ctx).colorScheme.onSecondary;
      if (v) {
         avatarBgColor = Theme.of(ctx).colorScheme.primary;
         avatarTxtColor = Theme.of(ctx).colorScheme.onPrimary;
      }

       CheckboxListTile cblt = CheckboxListTile(
         dense: true,
         secondary: CircleAvatar(
            child: Text(makeStrAbbrev(list[i].name),
               style: TextStyle(color: avatarTxtColor)
            ),
            backgroundColor: avatarBgColor
         ),
         title: Text(
            list[i].name,
            style: Theme.of(ctx).textTheme.subhead.copyWith(
               fontWeight: FontWeight.w500,
            ),
         ),
         value: v,
         onChanged: (bool v) { proceed(i); },
         activeColor: Theme.of(ctx).colorScheme.primary,
      );

       widgets.add(wrapDetailRowOnCard(ctx, cblt));
   }

   return widgets;
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext ctx) {
    return MaterialApp(
      title: txt.appName,
      theme: ThemeData(
          colorScheme: stl.colorScheme,
          brightness: stl.colorScheme.brightness,
          primaryColor: stl.colorScheme.primary,
          accentColor: stl.colorScheme.secondary,
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

FloatingActionButton makeFaButton(
   BuildContext ctx,
   Function onNewPost,
   Function onFwdChatMsg,
   int lpChats,
   int lpChatMsgs)
{
   if (lpChats == 0 && lpChatMsgs != 0)
      return null;

   IconData id = stl.newPostIcon;
   if (lpChats != 0 && lpChatMsgs != 0) {
      return FloatingActionButton(
         backgroundColor: Theme.of(ctx).colorScheme.secondaryVariant,
         child: Icon(
            Icons.send,
            color: Theme.of(ctx).colorScheme.onSecondary,
         ),
         onPressed: onFwdChatMsg,
      );
   }

   if (lpChats != 0)
      return null;

   if (onNewPost == null)
      return null;

   return FloatingActionButton(
      backgroundColor: Theme.of(ctx).colorScheme.secondaryVariant,
      child: Icon(id,
         color: Theme.of(ctx).colorScheme.onSecondary,
      ),
      onPressed: onNewPost);
}

Widget makeFAButtonMiddleScreen(
   BuildContext ctx,
   Function onNewFilters,
   Function onLoadNewPosts,
   int nNewPosts)
{
   FloatingActionButton filters = FloatingActionButton(
      onPressed: onNewFilters,
      backgroundColor: Theme.of(ctx).colorScheme.secondaryVariant,
      child: Icon(
         Icons.filter_list,
         color: Theme.of(ctx).colorScheme.onSecondary,
      ),
   );

   if (nNewPosts == 0)
      return filters;

   FloatingActionButton loadNewPosts = FloatingActionButton(
      mini: true,
      heroTag: null,
      onPressed: onLoadNewPosts,
      backgroundColor: Colors.blue,
      child: Icon(
         Icons.file_download,
         color: Theme.of(ctx).colorScheme.onPrimary,
      ),
   );

   return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[loadNewPosts, filters]
   );
}

int postIndexHelper(int i)
{
   if (i == 0) return 1;
   if (i == 1) return 2;
   if (i == 2) return 3;
   return 1;
}

Card makeChatMsgWidget(
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

   if (ch.msgs[i].isLongPressed) {
      onSelectedMsgColor = Colors.blue[200];
      color = Colors.blue[100];
   }

   RichText msgAndDate = RichText(
      text: TextSpan(
         text: ch.msgs[i].msg,
         style: Theme.of(ctx).textTheme.body1,
         children: <TextSpan>
         [ TextSpan(
            text: '  ${makeDateString(ch.msgs[i].date)}',
            style: Theme.of(ctx).textTheme.caption),
         ]
      ),
   );

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
         , Text(txt.msgOnRedirectedChat,
            style: TextStyle(color: Colors.blueGrey,
               fontSize: stl.listTileSubtitleFontSize,
               fontStyle: FontStyle.italic),
           )
         ]
      );

      ww = Column( children: <Widget>
         [ Padding(
              padding: EdgeInsets.all(3.0),
              child: redirWidget)
         , msgAndStatus
         ]);
   } else if (ch.msgs[i].refersToOther()) {
      final int refersTo = ch.msgs[i].refersTo;
      final Color c1 = selectColor(int.parse(ch.peer));

      // See comment on C0001 for why I commented this out.
      //SizedBox sb = SizedBox(
      //   width: 4.0,
      //   height: 60.0,
      //   child: DecoratedBox(
      //     decoration: BoxDecoration(
      //       color: c1)));

      Row refMsg = Row(
         mainAxisSize: MainAxisSize.min,
         crossAxisAlignment: CrossAxisAlignment.start,
         children: <Widget>
         [ //Padding(
           //   padding: const EdgeInsets.all(5.0),
           //   child: sb,
           //) , 
         Flexible(
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

ListView makeChatMsgListView(
   BuildContext ctx,
   ScrollController scrollCtrl,
   Chat ch,
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
                               color:
                               Theme.of(ctx).colorScheme.primary,
                            ),
                         )
                      ),
                   ),
               );
            }

            if (i > (nMsgs - ch.nUnreadMsgs))
               i -= 1; // For the shift
         }

         Card chatMsgWidget = makeChatMsgWidget(
            ctx,
            ch,
            i,
            onChatMsgLongPressed,
            onDragChatMsg
         );

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

Widget makeChatSecondLayer(
   BuildContext ctx,
   Function onChatSend,
   Function onAttachment)
{
   IconButton sendButton = IconButton(
      icon: Icon(Icons.send),
      onPressed: onChatSend,
      color: Colors.grey,
   );

   IconButton attachmentButton = IconButton(
      icon: Icon(Icons.add_a_photo),
      onPressed: onAttachment,
      color: Colors.grey,
   );

   return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[Row(
         mainAxisSize: MainAxisSize.min,
         children: <Widget>[attachmentButton, sendButton],
      )],
   );
}

Widget makeChatScreen(
   BuildContext ctx,
   Function onWillPopScope,
   Chat ch,
   TextEditingController ctrl,
   Function onChatSend,
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
   Function onCancelFwdLPChatMsg,
   bool showChatJumpDownButton,
   Function onChatJumpDown,
   String avatar)
{
   Column secondLayer = makeChatSecondLayer(
      ctx,
      onChatSend,
      onAttachment,
   );

   TextField tf = TextField(
       style: Theme.of(ctx).textTheme.body1,
       controller: ctrl,
       keyboardType: TextInputType.multiline,
       maxLines: null,
       maxLength: null,
       focusNode: chatFocusNode,
       decoration:
          InputDecoration.collapsed(hintText: txt.chatTextFieldHint),
    );

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
      onChatMsgLongPressed,
      onDragChatMsg,
   );

   List<Widget> cols = List<Widget>();

   List<Widget> foo = List<Widget>();
   foo.add(list);

   if (showChatJumpDownButton) {
      Widget jumDownButton = Positioned(
         bottom: 20.0,
         right: 15.0,
         child: FloatingActionButton(
            mini: true,
            onPressed: onChatJumpDown,
            backgroundColor: Theme.of(ctx).colorScheme.secondary,
            child: Icon(Icons.expand_more,
               color: Theme.of(ctx).colorScheme.onSecondary,
            ),
         ),
      );

      foo.add(jumDownButton);

      if (ch.nUnreadMsgs > 0) {
         Widget jumDownButton = Positioned(
            bottom: 53.0,
            right: 23.0,
            child: makeUnreadMsgsCircle(
               ctx,
               ch.nUnreadMsgs,
               Theme.of(ctx).colorScheme.secondaryVariant,
               Theme.of(ctx).colorScheme.onSecondary,
            ),
         );

         foo.add(jumDownButton);
      }
   }

   Stack chatMsgStack = Stack(children: foo);

   cols.add(Expanded(child: chatMsgStack));

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

      // C0001
      // NOTE: At the moment I do not know how to add the division bar
      // without fixing the height. That means on some rather short
      // text msgs there will be too much empty vertical space, that
      // do not look good. I will leave this out untill I find a
      // solution.
      //SizedBox sb = SizedBox(
      //   width: 4.0,
      //   height: 60.0,
      //   child: DecoratedBox(
      //     decoration: BoxDecoration(
      //       color: co1)));

      Card c1 = makeChatScreenBotCard(w1, null, w2, null, w4);
      cols.add(c1);
      cols.add(Divider(color: Colors.deepOrange, height: 0.0));
   }

   cols.add(card);

   Stack mainCol = Stack(children: <Widget>
   [ Column(children: cols)
   , Positioned(child: secondLayer, bottom: 1.0, right: 1.0)
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
      );
   } else {
      Widget child;
      ImageProvider backgroundImage;
      if (avatar.isNotEmpty) {
         final String url = cts.gravatarUrl + avatar + '.jpg';
         backgroundImage = CachedNetworkImageProvider(url);
      } else {
         child = stl.unknownPersonIcon;
      }
      title = ListTile(
          contentPadding: EdgeInsets.all(0.0),
          leading: CircleAvatar(
              child: child,
              backgroundImage: backgroundImage,
              backgroundColor: selectColor(int.parse(ch.peer)),
          ),
          title: Text(ch.getChatDisplayName(),
                maxLines: 1,
                overflow: TextOverflow.clip,
                style: Theme.of(ctx).primaryTextTheme.title.copyWith(
                   fontWeight: FontWeight.normal
                ),
          ),
          dense: true,
          subtitle:
             Text(postSummary,
                maxLines: 1,
                overflow: TextOverflow.clip,
                style: Theme.of(ctx).primaryTextTheme.subtitle
             ),
       );
   }

   return WillPopScope(
          onWillPop: () async { return onWillPopScope();},
          child: Scaffold(
             appBar : AppBar(
                actions: actions,
                title: title,
                leading: IconButton(
                   padding: EdgeInsets.all(0.0),
                   icon: Icon(Icons.arrow_back),
                   onPressed: onWillPopScope
                ),
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
   widgets[1] = Opacity(
      child: makeUnreadMsgsCircle(
         ctx, n, Colors.white, Theme.of(ctx).colorScheme.primary
      ),
      opacity: opacity,
   );

   return Row(children: widgets);
}

CircleAvatar makeChatListTileLeading(
   Widget child,
   ImageProvider backgroundImage,
   Color bgcolor,
   Function onLeadingPressed)
{
   Stack st = Stack(children: <Widget>
   [ Center(child: child)
   , OutlineButton(
        child: Text(''),
        borderSide: BorderSide(style: BorderStyle.none),
        onPressed: onLeadingPressed,
        shape: CircleBorder()
     ),
   ]);

   return CircleAvatar(
      child: st,
      backgroundColor: bgcolor,
      backgroundImage: backgroundImage,
   );
}

String makeStrAbbrev(final String str)
{
   if (str.length < 2)
      return str;

   return str.substring(0, 2);
}

RichText makeFilterListTileTitleWidget(
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

ListTile makeFilterSelectAllItem(
   BuildContext ctx,
   String title,
   Function onTap)
{
   // Handles the *select all* button.
   return ListTile(
       leading: Icon(
          Icons.select_all,
          size: 35.0,
          color: Theme.of(ctx).colorScheme.secondaryVariant),
       title: Text(
          title,
          style: Theme.of(ctx).textTheme.subhead,
       ),
       dense: true,
       onTap: onTap,
       enabled: true,
    );
}

Widget makePayPriceListTile(
   BuildContext ctx,
   String price,
   String title,
   String subtitle,
   Function onTap)
{
   Color primary = Theme.of(ctx).colorScheme.primary;
   Color secondary = Theme.of(ctx).colorScheme.secondary;
   Color onSecondary = Theme.of(ctx).colorScheme.onSecondary;
   Color background = Theme.of(ctx).colorScheme.background;

   Text subtitleW = Text(subtitle,
      maxLines: 2,
      overflow: TextOverflow.clip,
      style: Theme.of(ctx).textTheme.subtitle.copyWith(
         fontWeight: FontWeight.normal,
         color: Colors.grey[700],
      ),
   );

   Text titleW = Text(title,
      maxLines: 1,
      overflow: TextOverflow.clip,
      style: Theme.of(ctx).textTheme.subhead.copyWith(
         fontWeight: FontWeight.w500,
         color: primary,
      ),
   );

   Widget leading = Card(
      margin: const EdgeInsets.all(0.0),
      color: secondary,
      elevation: 0.0,
      shape: RoundedRectangleBorder(
         borderRadius: BorderRadius.all(Radius.circular(10.0)),
      ),
      child: Padding(
         padding: EdgeInsets.all(10.0),
         child: Text(price, style: TextStyle(color: onSecondary),),
      ),
   );

   return ListTile(
       leading: leading,
       title: titleW,
       dense: false,
       subtitle: subtitleW,
       trailing: Icon(Icons.keyboard_arrow_right),
       contentPadding: EdgeInsets.symmetric(horizontal: 10.0),
       onTap: onTap,
       enabled: true,
       selected: false,
       isThreeLine: true,
    );
}

void pay()
{
   InAppPayments.setSquareApplicationId('APPLICATION_ID');
   InAppPayments.startCardEntryFlow(
      onCardEntryCancel: (){},
      onCardNonceRequestSuccess: cardNonceRequestSuccess,
   );
}

void cardNonceRequestSuccess(sq.CardDetails result)
{
   // Use this nonce from your backend to pay via Square API
   print(result.nonce);

   final bool invalidZipCode = false;

   if (invalidZipCode) {
      // Stay in the card flow and show an error:
      InAppPayments.showCardNonceProcessingError('Invalid ZipCode');
   }

   InAppPayments.completeCardEntry(
      onCardEntryComplete: (){},
   );
}

Widget makePaymentChoiceWidget(
   BuildContext ctx,
   Function freePayment)
{
   List<Widget> widgets = List<Widget>();
   Widget title = Padding(
      padding: EdgeInsets.all(10.0),
      child: Text(txt.paymentTitle,
         style: Theme.of(ctx).textTheme.subhead.copyWith(
             color: Theme.of(ctx).colorScheme.primary,
             //fontWeight: FontWeight.w500,
          ),
       ),
   );

   widgets.add(title);

   List<Function> payments = <Function>
   [ () { freePayment(ctx); }
   , pay
   , pay
   ];
   for (int i = 0; i < txt.payments.length; ++i) {
      Widget p = makePayPriceListTile(
         ctx,
         txt.payments[i][0],
         txt.payments[i][1],
         txt.payments[i][2],
         payments[i],
      );

      widgets.add(p);
   }

   return Card(
      margin: const EdgeInsets.only(
       left: 1.5, right: 1.5, top: 0.0, bottom: 0.0
      ),
      color: Theme.of(ctx).colorScheme.background,
      //elevation: 0.0,
      shape: RoundedRectangleBorder(
         borderRadius: BorderRadius.only(
           topLeft: Radius.circular(20.0),
           topRight: Radius.circular(20.0),
         ),
      ),
      child: Column(
         mainAxisSize: MainAxisSize.min,
         children: widgets
      ),
   );
}

ListTile makeFilterListTitle(
   BuildContext ctx,
   MenuNode child,
   Function onTap,
   Icon trailing)
{
   final int c = child.leafReach;
   final int cs = child.leafCounter;

   String s = ' ($c/$cs)';
   TextStyle counterTxtStl = Theme.of(ctx).textTheme.caption;
   if (child.isLeaf() && child.leafCounter > 1) {
      s = ' (${child.leafCounter})';
      counterTxtStl = Theme.of(ctx).textTheme.caption.copyWith(
         color: Theme.of(ctx).colorScheme.primary,
      );
   }

   RichText title = RichText(
      text: TextSpan(
         text: child.name,
         style: Theme.of(ctx).textTheme.subhead.copyWith(
            fontWeight: FontWeight.w500,
         ),
         children: <TextSpan>
         [ TextSpan(text: s, style: counterTxtStl),
         ]
      )
   );
         
   Color avatarBgColor = Theme.of(ctx).colorScheme.secondary;
   Color avatarTxtColor = Theme.of(ctx).colorScheme.onSecondary;
   TextStyle subtitleTxtStl = Theme.of(ctx).textTheme.subtitle.copyWith(
      fontWeight: FontWeight.normal,
      color: Colors.grey[700],
   );

   if (c != 0) {
      avatarBgColor = Theme.of(ctx).colorScheme.primary;
      avatarTxtColor = Theme.of(ctx).colorScheme.onPrimary;
      subtitleTxtStl = Theme.of(ctx).textTheme.subtitle.copyWith(
         fontWeight: FontWeight.normal,
         color: avatarBgColor,
      );
   }

   Widget subtitle = null;
   if (!child.isLeaf()) {
      subtitle = Text(
          child.getChildrenNames(),
          style: subtitleTxtStl,
          maxLines: 2,
          overflow: TextOverflow.clip,
       );
   }

   return
      ListTile(
          leading: CircleAvatar(
             child: Text(
                makeStrAbbrev(child.name),
                style: TextStyle(color: avatarTxtColor),
             ),
             backgroundColor: avatarBgColor,
          ),
          title: title,
          dense: true,
          subtitle: subtitle,
          trailing: trailing,
          contentPadding: EdgeInsets.symmetric(horizontal: 10.0),
          onTap: onTap,
          enabled: true,
          selected: c != 0,
          isThreeLine: !child.isLeaf(),
       );
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
ListView makeNewFilterListView(
   BuildContext ctx,
   MenuNode o,
   Function onLeafPressed,
   Function onNodePressed,
   bool makeLeaf)
{
   int shift = 0;
   if (makeLeaf || o.children.last.isLeaf())
      shift = 1;

   return ListView.builder(
      //padding: const EdgeInsets.all(8.0),
      itemCount: o.children.length + shift,
      itemBuilder: (BuildContext ctx, int i)
      {
         if (shift == 1 && i == 0)
            return makeFilterSelectAllItem(
               ctx, txt.selectAll,
               () { onLeafPressed(0); },
            );

         if (shift == 1) {
            MenuNode child = o.children[i - 1];

            Widget icon = Icon(Icons.check_box_outline_blank);
            if (child.leafReach > 0)
               icon = Icon(Icons.check_box);

            return makeFilterListTitle(
               ctx,
               child,
               () { onLeafPressed(i);},
               icon,
            );
         }

         return makeFilterListTitle(
            ctx,
            o.children[i],
            () { onNodePressed(i); },
            Icon(Icons.keyboard_arrow_right),
         );
      },
   );
}

Widget createRaisedButton(
   BuildContext ctx,
   Function onPressed,
   final String txt)
{
   RaisedButton but = RaisedButton(
      child: Text(txt,
         style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: stl.mainFontSize,
            color: Theme.of(ctx).colorScheme.onSecondary,
         ),
      ),
      color: Theme.of(ctx).colorScheme.secondary,
      onPressed: onPressed,
   );

   return Center(child: ButtonTheme(minWidth: 100.0, child: but));
}

// Study how to convert this into an elipsis like whatsapp.
Container makeUnreadMsgsCircle(
   BuildContext ctx,
   int n,
   Color bgColor,
   Color textColor)
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
          maxHeight: 21.0, maxWidth: 40.0
       ),
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
                   bottomRight: rd
                )
             ),
      child: Center(widthFactor: 1.0, child: txt)
   );
}

Row makePostRowElem(BuildContext ctx, String key, String value)
{
   RichText left = RichText(
      text: TextSpan(
         text: key + ': ',
         style: Theme.of(ctx).textTheme.subhead.copyWith(
            fontWeight: FontWeight.w500,
            color: Theme.of(ctx).colorScheme.primaryVariant,
         ),
         children: <TextSpan>
         [ TextSpan(
              text: value,
              style: Theme.of(ctx).textTheme.subhead.copyWith(
                 color: Theme.of(ctx).colorScheme.secondary,
              ),
           ),
         ],
      ),
   );

   return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: <Widget>
      [ Icon(
           Icons.arrow_right,
           color: Theme.of(ctx).colorScheme.primary,
        )
      , ConstrainedBox(
         constraints: BoxConstraints(
            maxWidth: 300.0,
            minWidth: 300.0),
         child: left)
      ]
   );
}

List<Widget> makePostInRows(
   BuildContext ctx,
   List<MenuNode> nodes,
   int state)
{
   List<Widget> list = List<Widget>();

   for (int i = 0; i < nodes.length; ++i) {
      if ((state & (1 << i)) == 0)
         continue;

      Text text = Text(' ${nodes[i].name}',
         style: Theme.of(ctx).textTheme.subhead.copyWith(
           color: Theme.of(ctx).colorScheme.secondary,
         ),
      );

      Row row = Row(children: <Widget>
      [ Icon(Icons.check,
           color: Theme.of(ctx).colorScheme.primary,
        )
      , text
      ]); 

      list.add(row);
   }

   return list;
}

Widget makePostSectionTitle(BuildContext ctx, String str)
{
   return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
         padding: EdgeInsets.all(stl.postSectionPadding),
         child: Text(str,
            style: Theme.of(ctx).textTheme.title.copyWith(
               color: Theme.of(ctx).colorScheme.primary,
               fontWeight: FontWeight.w500,
            ),
         ),
      ),
   );
}

// Assembles the menu information.
List<Widget> makeMenuInfo(
   BuildContext ctx,
   Post post,
   List<MenuItem> menus)
{
   List<Widget> list = List<Widget>();

   for (int i = 0; i < post.channel.length; ++i) {
      list.add(makePostSectionTitle(ctx, txt.newPostTabNames[i]));

      List<String> names = loadNames(
         menus[i].root.first,
         post.channel[i][0],
      );

      List<Widget> items = List.generate(names.length, (int j)
      {
         return makePostRowElem(
            ctx,
            txt.menuDepthNames[i][j],
            names[j],
         );
      });

      list.addAll(items); // The menu info.
   }

   return list;
}

List<Widget> makePostValues(
   BuildContext ctx,
   Post post)
{
   List<Widget> list = List<Widget>();

   list.add(makePostSectionTitle(ctx, txt.rangesTitle));

   List<Widget> items = List.generate(cts.rangeDivs.length, (int i)
   {
      final int j = 2 * i;
      final String str = txt.rangeUnits[j + 0]
                       + post.rangeValues[i].toString()
                       + txt.rangeUnits[j + 1];

      return makePostRowElem(
         ctx,
         txt.rangePrefixes[i],
         str,
      );
   });

   list.addAll(items); // The menu info.

   return list;
}

List<Widget> makePostExDetails(
   BuildContext ctx,
   Post post,
   MenuNode exDetailsMenu)
{
   // Post details varies according to the first index of the products
   // entry in the menu.
   final int idx = post.getProductDetailIdx();

   List<Widget> list = List<Widget>();
   list.add(makePostSectionTitle(ctx, txt.postExDetailsTitle));

   final int l1 = exDetailsMenu.children[idx].children.length;
   for (int i = 0; i < l1; ++i) {
      final int j = searchBitOn(
         post.exDetails[i],
         exDetailsMenu.children[idx].children[i].children.length
      );
      
      list.add(
         makePostRowElem(
            ctx,
            exDetailsMenu.children[idx].children[i].name,
            exDetailsMenu.children[idx].children[i].children[j].name,
         ),
      );
   }

   list.add(makePostSectionTitle(ctx, txt.postRefSectionTitle));

   List<String> values = List<String>();
   values.add(post.nick);
   values.add('${post.from}');

   DateTime date;
   if (post.id == -1) {
      // We are publishing.
      values.add('');
      final int now = DateTime.now().millisecondsSinceEpoch;
      date = DateTime.fromMillisecondsSinceEpoch(now);
   } else {
      values.add('${post.id}');
      date = DateTime.fromMillisecondsSinceEpoch(post.date);
   }

   values.add(DateFormat.yMEd().add_jm().format(date));

   for (int i = 0; i < values.length; ++i)
      list.add(makePostRowElem(ctx, txt.descList[i], values[i]));

   return list;
}

List<Widget> makePostInDetails(
   BuildContext ctx,
   Post post,
   MenuNode inDetailsMenu)
{
   List<Widget> all = List<Widget>();

   final int i = post.getProductDetailIdx();
   final int l1 = inDetailsMenu.children[i].children.length;
   for (int j = 0; j < l1; ++j) {
      List<Widget> foo = makePostInRows(
         ctx,
         inDetailsMenu.children[i].children[j].children,
         post.inDetails[j],
      );

      if (foo.length != 0) {
         all.add(makePostSectionTitle(
               ctx,
               inDetailsMenu.children[i].children[j].name,
            ),
         );
         all.addAll(foo);
      }
   }

   return all;
}

Card putPostElemOnCard(BuildContext ctx, List<Widget> list)
{
   Column col = Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      children: list,
   );

   return Card(
      elevation: 0.0,
      color: Theme.of(ctx).colorScheme.background,
      margin: EdgeInsets.only(
         top: stl.chatTilePadding,
         left: stl.chatTilePadding,
         right: stl.chatTilePadding,
      ),
      child: Padding(
         child: col,
         padding: EdgeInsets.all(stl.postInnerMargin),
      ),
   );
}

Widget makePostDescription(BuildContext ctx, String desc)
{
   // TODO: How to determine the ideal width? If we do not set the
   // width the text overflow is not handled properly. If we do not
   // set the width the text overflow is not handled properly.
   return ConstrainedBox(
      constraints: BoxConstraints(
         maxWidth: 350.0,
         minWidth: 350.0,
      ),
      child: Text(
         desc,
         overflow: TextOverflow.clip,
      ),
   );
}

List<Widget> assemblePostRows(
   BuildContext ctx,
   Post post,
   List<MenuItem> menu,
   MenuNode exDetailsMenu,
   MenuNode inDetailsMenu)
{
   List<Widget> all = List<Widget>();
   all.addAll(makePostValues(ctx, post));
   all.addAll(makeMenuInfo(ctx, post, menu));
   all.addAll(makePostExDetails(ctx, post, exDetailsMenu));
   all.addAll(makePostInDetails(ctx, post, inDetailsMenu));
   if (!post.description.isEmpty) {
      all.add(makePostSectionTitle(ctx, txt.postDescTitle));
      all.add(makePostDescription(ctx, post.description));
   }

   return all;
}

String makePostSummaryStr(MenuNode root, Post post)
{
   final List<String> names = loadNames(root, post.channel[1][0]);
   assert(names.length >= 4);
   return '${names[1]}, ${names[2]} - 2019';
   //return names.join(', ');
}

ThemeData makeExpTileThemeData(BuildContext ctx)
{
   return ThemeData(
      accentColor: Theme.of(ctx).colorScheme.onPrimary,
      unselectedWidgetColor: Theme.of(ctx).colorScheme.onPrimary,
      textTheme: TextTheme(
         subhead: TextStyle(
            color: Theme.of(ctx).colorScheme.onPrimary,
         ),
      ),
   );
}

Widget makePostInfoExpansion(
   BuildContext ctx,
   Widget detailsCard,
   Widget title,
   Widget leading)
{
   return Theme(
      data: makeExpTileThemeData(ctx),
      child: ExpansionTile(
          backgroundColor: Theme.of(ctx).colorScheme.primary,
          leading: leading,
          key: GlobalKey(),
          title: title,
          children: <Widget>[detailsCard],
      ),
   );
}

String makePriceStr(int price)
{
   final String s = price.toString();
   return 'R\$$s';
}

Card makePostWidget(
   BuildContext ctx,
   Widget card,
   Function onPressed,
   Icon icon,
   Post post,
   Function onAddPhoto,
   List<File> imgFiles)
{
   IconButton icon1 = IconButton(
      iconSize: 35.0,
      padding: EdgeInsets.all(0.0),
      onPressed: () {onPressed(0);},
      icon: Icon(
         Icons.cancel,
         color: Theme.of(ctx).colorScheme.secondary,
      ),
   );

   IconButton icon2 = IconButton(
      iconSize: 35.0,
      padding: EdgeInsets.all(0.0),
      icon: icon,
      onPressed: () {onPressed(1);},
      color: Theme.of(ctx).colorScheme.primary,
   );

   Row row = Row(children: <Widget>
   [ Expanded(child: icon1)
   , Expanded(child: icon2)
   ]);

   Card c4 = Card(
      child: row,
      color: Theme.of(ctx).colorScheme.primary,
      margin: EdgeInsets.all(stl.postInnerMargin),
      elevation: 0.0,
   );

   Widget imgLv = makeImgListView(
      cts.imgBoxWidth,
      cts.imgBoxHeight,
      onAddPhoto,
      imgFiles,
      post,
   );

   Widget priceText = Padding(
      child: Text(makePriceStr(post.getPrice()),
         style: Theme.of(ctx).textTheme.headline.copyWith(
            color: Theme.of(ctx).colorScheme.onPrimary,
         ),
      ),
      padding: const EdgeInsets.all(10.0),
   );

   final String km = post.rangeValues[2].toString();
   Widget kmText = Padding(
      child: Text(km + 'km',
         style: Theme.of(ctx).textTheme.headline.copyWith(
            color: Theme.of(ctx).colorScheme.onPrimary,
         ),
      ),
      padding: const EdgeInsets.all(10.0),
   );


   Row row2 = Row(
      children: <Widget>[priceText, Spacer(), kmText]
   );

   Column col = Column(
      children: <Widget>[Spacer(), row2]
   );

   SizedBox sb2 = SizedBox(
      width: cts.imgBoxWidth,
      height: cts.imgBoxHeight,
      child: Center(child: col),
   );

   Widget images = Stack(children: <Widget>[imgLv, sb2]);

   return Card(
      color: Theme.of(ctx).colorScheme.primary,
      margin: EdgeInsets.all(stl.postMarging),
      elevation: 0.0,
      child: Padding(
         padding: EdgeInsets.all(stl.outerPostCardPadding),
         child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[images, card, c4],
         ),
      ),
   );
}

Widget makePostPubWidget(
   BuildContext ctx,
   Post post,
   Function onPostSelection,
   List<MenuItem> menu,
   MenuNode exDetailsMenu,
   MenuNode inDetailsMenu,
   Icon ic,
   String snackbarStr,
   Function onAddPhoto,
   List<File> imgFiles)
{
   Widget title = Text(
      makePostSummaryStr(menu[1].root.first, post),
      maxLines: 1,
      overflow: TextOverflow.clip,
   );

   Widget infoExpansion = makePostInfoExpansion(
      ctx,
      putPostElemOnCard(
         ctx,
         assemblePostRows(
            ctx,
            post,
            menu,
            exDetailsMenu,
            inDetailsMenu,
         ),
      ),
      title,
      null,
   );

   Widget w = makePostWidget(
      ctx,
      infoExpansion,
      onPostSelection,
      ic,
      post,
      onAddPhoto,
      imgFiles,
   );

   return Dismissible(
      key: GlobalKey(),
      onDismissed: (direction) {
         onPostSelection(0);
         Scaffold.of(ctx).showSnackBar(
               SnackBar(content: Text(snackbarStr))
         );
      },

      background: Container(color: Colors.red),
      child: w,
   );
}

ListView makePostTabListView(
   BuildContext ctx,
   List<Post> posts,
   Function onPostSelection,
   List<MenuItem> menu,
   MenuNode exDetailsMenu,
   MenuNode inDetailsMenu,
   int nNewPosts)
{
   final int l = posts.length - nNewPosts;

   return ListView.builder(
      padding: const EdgeInsets.all(0.0),
      itemCount: l,
      itemBuilder: (BuildContext ctx, int i)
      {
         final int j = l - i - 1;
         return makePostPubWidget(
            ctx,
            posts[j],
            (int fav) {onPostSelection(ctx, j, fav);},
            menu,
            exDetailsMenu,
            inDetailsMenu,
            stl.favIcon,
            txt.dissmissedPost,
            (int i){print('Error: Please fix aaab');},
            List<File>(),
         );
      },
   );
}

ListView makeNewPostMenuListView(
   BuildContext ctx,
   MenuNode o,
   Function onLeafPressed,
   Function onNodePressed)
{
   return ListView.builder(
      itemCount: o.children.length,
      itemBuilder: (BuildContext ctx, int i)
      {
         MenuNode child = o.children[i];

         if (child.isLeaf()) {
            return ListTile(
               leading: CircleAvatar(
                  child: Text(makeStrAbbrev(child.name),
                     style: TextStyle(
                        color: Theme.of(ctx).colorScheme.onSecondary
                     ),
                  ),
                  backgroundColor:
                     Theme.of(ctx).colorScheme.secondary,
               ),
               title: Text(
                  child.name,
                  style: Theme.of(ctx).textTheme.subhead.copyWith(
                     fontWeight: FontWeight.w500,
                  ),
               ),
               dense: true,
               onTap: () { onLeafPressed(i);},
               enabled: true,
               onLongPress: (){});
         }
         
         return
            ListTile(
               leading: CircleAvatar(
                  child: Text(makeStrAbbrev(child.name),
                     style: TextStyle(
                        color: Theme.of(ctx).colorScheme.onSecondary
                     ),
                  ),
                  backgroundColor: Theme.of(ctx).colorScheme.secondary,
               ),
               title: Text(
                  o.children[i].name,
                  style: Theme.of(ctx).textTheme.subhead.copyWith(
                     fontWeight: FontWeight.w500,
                  ),
               ),
               dense: true,
               subtitle: Text(
                  o.children[i].getChildrenNames(),
                  maxLines: 2,
                  overflow: TextOverflow.clip,
                  style: Theme.of(ctx).textTheme.subtitle.copyWith(
                     fontWeight: FontWeight.normal,
                     color: Colors.grey[700],
                  ),
               ),
               trailing: Icon(Icons.keyboard_arrow_right),
               onTap: () { onNodePressed(i); },
               enabled: true,
               isThreeLine: true
            );
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
         txt.msgOnEmptyChat,
         maxLines: 1,
         overflow: TextOverflow.clip,
         style: Theme.of(ctx).textTheme.subtitle.copyWith(
            color: Theme.of(ctx).colorScheme.secondary,
            //fontWeight: FontWeight.w500,
            fontStyle: FontStyle.italic,
         ),
      );
   }

   if (ch.nUnreadMsgs > 0 || !ch.lastChatItem.isFromThisApp())
      return Text(
         str,
         style: Theme.of(ctx).textTheme.subtitle.copyWith(
            color: Colors.grey[700],
         ),
         maxLines: 1,
         overflow: TextOverflow.clip
      );

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

Widget makeChatListTileTrailingWidget(
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
      , makeUnreadMsgsCircle(
          ctx,
          nUnreadMsgs,
          Theme.of(ctx).colorScheme.secondary,
          Theme.of(ctx).colorScheme.onSecondary,
        )
      ]);
      
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
         , makeUnreadMsgsCircle(
             ctx,
             nUnreadMsgs,
             Theme.of(ctx).colorScheme.secondary,
             Theme.of(ctx).colorScheme.onSecondary,
           )
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

Card makeChatListTile(
   BuildContext ctx,
   Chat chat,
   int now,
   Function onLeadingPressed,
   Function onLongPress,
   Function onPressed,
   bool isFwdChatMsgs,
   String avatar)
{
   Widget widget;
   ImageProvider backgroundImage;
   Color bgColor;
   if (chat.isLongPressed) {
      widget = Icon(Icons.check);
      bgColor = stl.chatLongPressendColor;
   } else {
      if (avatar.isNotEmpty) {
         final String url = cts.gravatarUrl + avatar + '.jpg';
         backgroundImage = CachedNetworkImageProvider(url);
      } else {
         widget = stl.unknownPersonIcon;
      }

      bgColor = Theme.of(ctx).colorScheme.background;
   }

   Widget trailing = makeChatListTileTrailingWidget(
      ctx,
      chat.nUnreadMsgs,
      chat.lastChatItem.date,
      chat.pinDate,
      now,
      isFwdChatMsgs
   );

   ListTile lt =  ListTile(
      dense: false,
      enabled: true,
      trailing: trailing,
      onTap: onPressed,
      onLongPress: onLongPress,
      subtitle: makeChatTileSubtitle(ctx, chat),
      leading: makeChatListTileLeading(
         widget,
         backgroundImage,
         selectColor(int.parse(chat.peer)),
         onLeadingPressed,
      ),
      title: Text(
         chat.getChatDisplayName(),
         maxLines: 1,
         overflow: TextOverflow.clip,
         style: Theme.of(ctx).textTheme.subhead.copyWith(
            fontWeight: FontWeight.w500,
         ),
      ),
   );

   return Card(
      child: lt,
      color: bgColor,
      margin: EdgeInsets.all(0.0),
      elevation: 0.0,
      shape: RoundedRectangleBorder(
         borderRadius: BorderRadius.all(
            Radius.circular(stl.cornerRadius)
         ),
      ),
   );
}

Widget makeChatsExp(
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

      Card card = makeChatListTile(
         ctx,
         ch[i],
         now,
         (){onLeadingPressed(ctx, post.id, i);},
         () { onLongPressed(i); },
         () { onPressed(i); },
         isFwdChatMsgs,
         post.avatar,
      );

      list[i] = Padding(
         child: card,
         padding: EdgeInsets.only(
            left: stl.chatTilePadding,
            right: stl.chatTilePadding,
            bottom: stl.chatTilePadding,
         ),
      );
   }

  if (isFav)
     return Column(children: list);

  Widget title;
   if (nUnredChats == 0) {
      title = Text('${ch.length} conversa(s)');
   } else {
      title = makeExpTileTitle(
         ctx,
         '${ch.length} conversas',
         '$nUnredChats nao lidas',
         ', ',
         false, // Any non zero number is enough.
      );
   }

   IconData pinIcon =
      post.pinDate == 0 ? Icons.place : Icons.pin_drop;

   final bool expState = (ch.length < 6 && ch.length > 0)
                       || nUnredChats != 0;
   return Theme(
      data: makeExpTileThemeData(ctx),
      child: ExpansionTile(
         backgroundColor: Theme.of(ctx).colorScheme.primary,
         initiallyExpanded: expState,
         leading: IconButton(icon: Icon(pinIcon), onPressed: onPinPost),
         key: GlobalKey(),
         title: title,
         children: list,
      ),
   );
}

Widget makeChatTab(
   BuildContext ctx,
   List<Post> posts,
   Function onPressed,
   Function onLongPressed,
   List<MenuItem> menu,
   Function onDelPost,
   Function onPinPost,
   bool isFwdChatMsgs,
   Function onUserInfoPressed,
   bool isFav,
   MenuNode exDetailsMenu,
   MenuNode inDetailsMenu)
{
   return ListView.builder(
      padding: const EdgeInsets.only(
         left: stl.postListViewSidePadding,
         right: stl.postListViewSidePadding,
         top: stl.postListViewTopPadding,
      ),
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

         Widget leading = IconButton(
            icon: Icon(ic),
            onPressed: onDelPost2,
         );

         Widget title = Text(
            makePostSummaryStr(menu[1].root.first, posts[i]),
            maxLines: 1,
            overflow: TextOverflow.clip,
         );

         List<Widget> foo = List<Widget>();
         foo.add(makeImgListView(
               cts.imgBoxWidth,
               cts.imgBoxHeight,
               (int i){ print('Error: Please fix aaac');},
               List<File>(),
               posts[i],
            ),
         );

         foo.addAll(assemblePostRows(
               ctx,
               posts[i],
               menu,
               exDetailsMenu,
               inDetailsMenu,
            )
         );

         Widget infoExpansion = makePostInfoExpansion(
            ctx,
            putPostElemOnCard(ctx, foo),
            title,
            leading,
         );

         final int now = DateTime.now().millisecondsSinceEpoch;

         Widget chatExpansion = makeChatsExp(
            ctx,
            posts[i].chats,
            (j) {onPressed(i, j);},
            (j) {onLongPressed(i, j);},
            posts[i],
            isFwdChatMsgs,
            onUserInfoPressed,
            now,
            onPinPost2,
            isFav,
         );

         List<Widget> expansions = <Widget>
         [ infoExpansion
         , chatExpansion
         ];

         Card w = Card(
            elevation: 0.0,
            color: Theme.of(ctx).colorScheme.primary,
            child: Column(children: expansions),
            shape: RoundedRectangleBorder(
               borderRadius: BorderRadius.all(
                  Radius.circular(stl.cornerRadius)
               ),
            ),
            margin: const EdgeInsets.only(
               left: stl.postCardSideMargin,
               right: stl.postCardSideMargin,
               bottom: stl.postCardBottomMargin,
            ),
         );

         return Dismissible(
            key: GlobalKey(),
            onDismissed: (direction) {
               onDelPost(i);
               Scaffold.of(ctx)
                  .showSnackBar(SnackBar(
                     content: Text(txt.dismissedChat)));
            },
            background: Container(color: Colors.red),
            child: w,
         );
      },
   );
}

//_____________________________________________________________________

class DialogWithOp extends StatefulWidget {
   DialogWithOp(
      this.idx,
      this.getValueFunc,
      this.setValueFunc,
      this.onPostSelection,
      this.title,
      this.body,
   );

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
      final SimpleDialogOption ok = SimpleDialogOption(
         child: Text(txt.ok,
            style: TextStyle(color: Colors.blue, fontSize: 16.0),
         ),
         onPressed: () async
         {
            await _onPostSelection();
            Navigator.of(ctx).pop();
         },
      );

      final SimpleDialogOption cancel = SimpleDialogOption(
         child: Text(txt.cancel,
            style: TextStyle(color: Colors.blue, fontSize: 16.0),
         ),
         onPressed: () { Navigator.of(ctx).pop(); },
      );

      List<SimpleDialogOption> actions = List<SimpleDialogOption>(2);
      actions[0] = cancel;
      actions[1] = ok;

      Row row = Row(children:
         <Widget> [Icon(Icons.check_circle_outline, color: Colors.red)],
      );

      CheckboxListTile tile = CheckboxListTile(
         title: Text(txt.doNotShowAgain),
         value: !_getValueFunc(),
         onChanged: (bool v) { setState(() {_setValueFunc(!v);}); },
         controlAffinity: ListTileControlAffinity.leading,
      );

      return SimpleDialog(
         title: Text(_title),
         children: <Widget>
         [ Padding(
              padding: EdgeInsets.all(25.0),
              child: Center(
                 child: Text(_body,
                    style: TextStyle(fontSize: 16.0),
                 ),
              ),
           )
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
   with SingleTickerProviderStateMixin, WidgetsBindingObserver
{
   Config _cfg = Config();

   // Array with the length equal to the number of menus there
   // are. Used both on the filter and on the *new post* screens.
   List<MenuItem> _menu = List<MenuItem>();

   // The ex details tree root node.
   MenuNode _exDetailsRoot;

   // The in details tree root node.
   MenuNode _inDetailsRoot;

   // Will be set to true if the user scrolls up a chat screen so that
   // the jump down button can be used
   bool _showChatJumpDownButton = true;

   // Set to true when the user wants to change it email or nick or on
   // the first time the user opens the app
   bool _goToRegScreen = false;

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
   Queue<AppMsgQueueElem> _appMsgQueue = Queue<AppMsgQueueElem>();

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
   int _nNewPosts = 0;

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

   // Investigate if we need two scroll controllers. I think they are
   // never used at the same time and therefore one should be enough.
   ScrollController _scrollCtrl = ScrollController();
   ScrollController _chatScrollCtrl = ScrollController();

   // Used for every screen that offers text input.
   TextEditingController _txtCtrl;

   // Used in some cases where two text fields are required.
   TextEditingController _txtCtrl2;
   FocusNode _chatFocusNode;

   IOWebSocketChannel channel;
   
   Database _db;

   // This variable is set to true when we are able to either login
   // and register.
   bool _isConnected = false;

   // Used in the final new post screen to store the files while the
   // user chooses the images.
   List<File> _imgFiles = List<File>();

   @override
   void initState()
   {
      super.initState();
      _tabCtrl = TabController(vsync: this, initialIndex: 1, length: 3);
      _txtCtrl = TextEditingController();
      _txtCtrl2 = TextEditingController();
      _tabCtrl.addListener(_tabCtrlChangeHandler);
      _chatFocusNode = FocusNode();
      _dragedIdx = -1;
      _chatScrollCtrl.addListener(_chatScrollListener);
      _isConnected = false;
      WidgetsBinding.instance.addObserver(this);
   }

   @override
   void dispose()
   {
      _txtCtrl.dispose();
      _txtCtrl2.dispose();
      _tabCtrl.dispose();
      _scrollCtrl.dispose();
      _chatScrollCtrl.dispose();
      _chatFocusNode.dispose();
      WidgetsBinding.instance.removeObserver(this);

      super.dispose();
   }

   @override
   void didChangeAppLifecycleState(AppLifecycleState state)
   {
      // TODO: We should not try to reconnect if disconnection
      // happened just a couples of seconds ago. This is needed
      // because it may haven't been a clean disconnect with a close
      // websocket frame.  The server will wait until the pong answer
      // times out.  To soulve this just use time stamps instead of a
      // boolean in _isConnected and compare it with the current time.
      // We should also use the server pong-timeout value.
      if (state == AppLifecycleState.resumed && !_isConnected) {
         print('Trying to reconnect.');
         //_stablishNewConnection();
      }
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
      String menuStr = await rootBundle.loadString('data/menu.txt');
      _menu = menuReader(jsonDecode(menuStr));

      List<MenuElem> elems = List<MenuElem>();
      for (int i = 0; i < _menu.length; ++i)
         elems.addAll(makeMenuElems(_menu[i].root.first, i));

      Batch batch = db.batch();

      elems.forEach((MenuElem me)
         { batch.insert('menu', menuElemToMap(me)); });

      await batch.commit(noResult: true, continueOnError: true);

      _goToRegScreen = true;
   }

   Future<void> _load(final String docDir) async
   {
      _db = await openDatabase(
         p.join(await getDatabasesPath(), 'main.db'),
         readOnly: false,
         onCreate: _onCreateDb,
         version: 1);

      try {
         String exDetailsStr =
            await rootBundle.loadString('data/ex_details_menu.txt');
         _exDetailsRoot =
            menuReader(jsonDecode(exDetailsStr)).first.root.first;

         String inDetailsStr =
            await rootBundle.loadString('data/in_details_menu.txt');
         _inDetailsRoot =
            menuReader(jsonDecode(inDetailsStr)).first.root.first;
      } catch (e) {
         print(e);
      }

      try {
         List<Config> configs = await loadConfig(_db);
         if (!configs.isEmpty)
            _cfg = configs.first;
      } catch (e) {
         print(e);
      }

      _dialogPrefs[0] = _cfg.showDialogOnDelPost == 'yes';
      _dialogPrefs[1] = _cfg.showDialogOnSelectPost == 'yes';

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

         _menu[0].filterDepth = cts.filterDepths[0];
         _menu[1].filterDepth = cts.filterDepths[1];

         _menu[0].version = cts.versions[0];
         _menu[1].version = cts.versions[1];

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

      // NOTE: The _posts array is expected to be sorted on its
      // ids, so we could perform a binary search here instead.
      final int i = _posts.indexWhere((e)
         { return e.id == _cfg.lastSeenPostId; });

      if (i != -1)
         _nNewPosts = _posts.length - i - 1;

      List<AppMsgQueueElem> tmp = await loadOutChatMsg(_db);

      _appMsgQueue = Queue<AppMsgQueueElem>.from(tmp.reversed);

      _stablishNewConnection();

      print('Last post id: ${_cfg.lastPostId}.');
      print('Last post id seen: ${_cfg.lastSeenPostId}.');
      print('Login: ${_cfg.appId}:${_cfg.appPwd}.');
      setState(() { });
   }

   void _stablishNewConnection()
   {
      channel = IOWebSocketChannel.connect(cts.wshost);
      channel.stream.listen(
         onWSData,
         onError: _onWSError,
         onDone: _onWSDone,
      );

      final List<int> versions = makeMenuVersions(_menu);
      final String cmd = _makeConnCmd(versions);
      channel.sink.add(cmd);
   }

   String _makeConnCmd(final List<int> versions)
   {
      if (_cfg.appId.isEmpty) {
         // This is the first time we are connecting to the server (or
         // the login file is corrupted, etc.)
         return jsonEncode({'cmd': 'register'});
      }

      // We are already registered in the server.
      var loginCmd = {
         'cmd': 'login',
         'user': _cfg.appId,
         'password': _cfg.appPwd,
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
               txt.dialogTitles[fav],
               txt.dialogBodies[fav]);
            
         },
      );
   }

   // Used to either add or remove a photo from the new post.
   // i = 0 ==> add
   // i != 0 ==> remove.
   //
   Future<void> _onAddPhoto(int i) async
   {
      try {
         if (_imgFiles.length == 5) {
            // TODO: Show dialog if maximum number of images has been
            // achieved.
            print('Maximum number of images has been reached.');
            return;
         }

         File img = await ImagePicker.pickImage(source: ImageSource.gallery);
         if (img == null)
            return;

         setState((){_imgFiles.add(img); });
      } catch (e) {
         print(e);
      }
   }

   void _onRangeValueChanged(int i, double v)
   {
      setState((){_post.rangeValues[i] = v.round();});
   }

   Future<void> _onRangeChanged(int i, RangeValues rv) async
   {
      final int j = 2 * i;

      setState(()
      {
         _cfg.ranges[j + 0] = rv.start.round();
         _cfg.ranges[j + 1] = rv.end.round();
      });

      await _db.execute(sql.updateRanges, [_cfg.ranges.join(' ')]);
   }

   Future<void> _onPostSelection(int i, int fav) async
   {
      assert(isOnPosts());

      if (fav == 1) {
         _posts[i].status = 2;
         final int j = _posts[i].addChat(_posts[i].from, _posts[i].nick);

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

      setState(() { });
   }

   void _onNewPost()
   {
      _newPostPressed = true;
      _post = Post();
      _post.images = List<String>(); // TODO: remove this later.
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

   Future<void> _onShowNewPosts() async
   {
      _nNewPosts = 0;

      if (_posts.isEmpty) {
         print('===> This should not happen');
      } else {
         await _db.execute(sql.updateLastSeenPostId,
                           [_posts.last.id]);
      }

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

      _showChatJumpDownButton = false;
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

      _chat.nUnreadMsgs = 0;
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

   void _chatScrollListener()
   {
      final double offset = _chatScrollCtrl.offset;
      final double max = _chatScrollCtrl.position.maxScrollExtent;

      final double tol = 40.0;

      if (_showChatJumpDownButton && !(offset < max))
         setState(() {_showChatJumpDownButton = false;});

      if (!_showChatJumpDownButton && (offset < (max - tol)))
         setState(() {_showChatJumpDownButton = true;});
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

      final int dbId = await _db.insert(
         'posts',
         postToMap(post),
         conflictAlgorithm: ConflictAlgorithm.replace,
      );

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

   void _handlePublishAck(final int id, final int date, Batch batch)
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

         batch.execute(sql.updatePostOnAck, [0, id, date, post.dbId]);

         // Required to show the publish as soon as its ack arrives.
         setState(() { });

         if (_outPostsQueue.isEmpty)
            return;

         final String payload = makePostPayload(_outPostsQueue.first);
         channel.sink.add(payload);
      } catch (e) {
         print(e);
      }
   }

   Future<void> _onRemovePost(int i) async
   {
      if (_isOnFav()) {
         await _db.execute(sql.deletePost, [_favPosts[i].id]);
         _favPosts.removeAt(i);
      } else {
         await _db.execute(sql.deletePost, [_ownPosts[i].id]);
         final Post delPost = _ownPosts.removeAt(i);

         var msgMap = {
            'cmd': 'delete',
            'id': delPost.id,
            'to': delPost.channel,
         };

         await _sendAppMsg(jsonEncode(msgMap), 0);
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

   Future<void> _onSendFreePost(BuildContext ctx, int i) async
   {
      try {
         // Problem: The server may refuse the post so that means if
         // the images are sent first to S3, we may have the problem.
         // Sending after may also be a problem as the post may become
         // available. Ideally we would send them together.

         //-----------------------------------------------------------
         if (_imgFiles.isNotEmpty) {
            // TODO: Loop on the files.
            String filename = _imgFiles.first.path.split('/').last;

            print('=====> onAddPhoto: Image name $filename');

            FormData formData = FormData.from({
               "image": UploadFileInfo(_imgFiles.first, filename)
            });

            const String httpTarget = cts.httphost + '/image';

            var resp = await Dio().post(
               httpTarget,
               data: formData,
               onSendProgress: (int sent, int total)
               {
                  print("$sent $total");
               },
            );

            // TODO: Check the response was successful.
            _post.images.add(resp.data);
         }

         _imgFiles = List<File>();

         //------------------------------------

         // Expiration was successfull we can send the post.
         _newPostPressed = false;

         _botBarIdx = 0;
         _post.from = _cfg.appId;
         _post.nick = _cfg.nick;
         _post.avatar = emailToGravatarHash(_cfg.email);
         _post.status = 3;

         await _sendPost(_post.clone());

         _post = null;

         setState(() { });

         // If the user cancels the operation we do not show the dialog.
         if (i == 1) {
            _showSimpleDial(
               ctx,
               (){},
               txt.dialogTitles[3],
               Text(txt.dialogBodies[3])
            );
         }
      } catch (e) {
         print(e);
      }
   }

   Future<void> _onSendNewPost(BuildContext ctx, int i) async
   {
      if (i == 0) {
         _newPostPressed = false;
         _post = null;
         setState(() { });
         return;
      }

      await showModalBottomSheet<void>(
         context: ctx,
         backgroundColor: Colors.white,
         elevation: 1.0,
         shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(20.0)),
         ),
         builder: (BuildContext ctx)
         {
            return makePaymentChoiceWidget(
               ctx,
               (BuildContext ctx)
               {
                  Navigator.of(ctx).pop();
                  _onSendFreePost(ctx, i);
               },
            );
         },
      );
   }

   void _removePostDialog(BuildContext ctx, int i)
   {
      _showSimpleDial(
         ctx,
         () async { await _onRemovePost(i);},
         txt.dialogTitles[4],
         Text(txt.dialogBodies[4]),
      );
   }

   void _onCancelNewFilter()
   {
      _newFiltersPressed = false;
      setState(() { });
   }

   Future<void> _onChatPressedImpl(
      List<Post> posts,
      bool isSenderPost,
      int i,
      int j) async
   {
      if (!_lpChats.isEmpty || !_lpChatMsgs.isEmpty) {
         _onChatLPImpl(posts, i, j);
         setState(() { });
         return;
      }

      _showChatJumpDownButton = false;
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

         await _sendAppMsg(jsonEncode(msgMap), 0);
      }

      setState(() {
         SchedulerBinding.instance.addPostFrameCallback((_)
         {
            _chatScrollCtrl.jumpTo(_chatScrollCtrl.position.maxScrollExtent);
         });
      });
   }

   void _onChatJumpDown()
   {
      setState(()
      {
         _chatScrollCtrl.jumpTo(_chatScrollCtrl.position.maxScrollExtent);
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

      final String peer = posts[i].chats[j].peer;
      final String nick = posts[i].chats[j].nick;
      final String title = '$nick: $peer';

      final String url = cts.gravatarUrl + posts[i].avatar + '.jpg';
      _showSimpleDial(
         ctx,
         (){},
         title,
         makeNetImgBox(
            cts.onClickAvatarWidth,
            cts.onClickAvatarWidth,
            url,
         ),
      );
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

   Future<void> _sendAppMsg(String payload, int isChat) async
   {
      final bool isEmpty = _appMsgQueue.isEmpty;
      AppMsgQueueElem tmp = AppMsgQueueElem(
         rowid: -1,
         isChat: isChat,
         payload: payload,
         sent: false
      );

      _appMsgQueue.add(tmp);

      tmp.rowid = await _db.rawInsert(
         sql.insertOutChatMsg,
         [isChat, payload],
      );

      if (isEmpty) {
         assert(!_appMsgQueue.first.sent);
         _appMsgQueue.first.sent = true;
         print(_appMsgQueue.first.payload);
         channel.sink.add(_appMsgQueue.first.payload);
      }
   }

   void sendOfflineChatMsgs()
   {
      if (!_appMsgQueue.isEmpty) {
         assert(!_appMsgQueue.first.sent);
         _appMsgQueue.first.sent = true;
         channel.sink.add(_appMsgQueue.first.payload);
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

   Future<void> _onSendChatMsgImpl(
      List<Post> posts,
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
            'nick': _cfg.nick
         };

         await _sendAppMsg(jsonEncode(msgMap), 1);

      } catch(e) {
         print(e);
      }
   }

   void _onServerAck(Map<String, dynamic> ack, Batch batch)
   {
      try {
         assert(_appMsgQueue.first.sent);
         assert(!_appMsgQueue.isEmpty);
         final String res = ack['result'];

         batch.rawDelete(sql.deleteOutChatMsg,
                         [_appMsgQueue.first.rowid]);

         final bool isChat = _appMsgQueue.first.isChat == 1;
         _appMsgQueue.removeFirst();

         if (res == 'ok' && isChat) {
            _chatAppAckHandler(ack, 1, batch);
            setState(() { });
         }

         if (!_appMsgQueue.isEmpty) {
            assert(!_appMsgQueue.first.sent);
            _appMsgQueue.first.sent = true;
            channel.sink.add(_appMsgQueue.first.payload);
         }
      } catch (e) {
         print(e);
      }
   }

   Future<void> _chatMsgHandler(Map<String, dynamic> ack, int type) async
   {
      final int postId = ack['post_id'];
      final bool isSenderPost = ack['is_sender_post'];
      final String to = ack['to'];
      final String msg = ack['msg'];
      final String peer = ack['from'];
      final String nick = ack['nick'];
      final int refersTo = ack['refers_to'];

      if (to != _cfg.appId) {
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

   Future<void> _chatMsgHandlerImpl(
      String to,
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

      ++posts[i].chats[j].nUnreadMsgs;

      String ack;
      if (isOnPost && isOnChat) {
         ack = 'app_ack_read';

         // If we are on the chat screen with the peer and not
         // currently showing the jump down button we animate to the
         // bottom.
         if (!_showChatJumpDownButton) {
            setState(()
            {
               posts[i].chats[j].nUnreadMsgs = 0;
               SchedulerBinding.instance.addPostFrameCallback((_)
               {
                  _chatScrollCtrl.animateTo(
                     _chatScrollCtrl.position.maxScrollExtent,
                     duration: const Duration(milliseconds: 300),
                     curve: Curves.easeOut,
                  );
               });
            });
         }
      } else {
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
      await _sendAppMsg(payload, 0);
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

   void _onMessage(Map<String, dynamic> ack, Batch batch)
   {
      final String type = ack['type'];
      if (type == 'server_ack') {
         _onServerAck(ack, batch);
      } else if (type == 'chat') {
         _chatMsgHandler(ack, 0);
      }  else if (type == 'chat_redirected') {
         _chatMsgHandler(ack, 1);
      } else if (type == 'app_ack_received') {
         _chatAppAckHandler(ack, 2, batch);
      } else if (type == 'app_ack_read') {
         _chatAppAckHandler(ack, 3, batch);
      }

      // TODO: Move this to the individual functions above.
      setState((){});
   }

   void _onRegisterAck(
      Map<String, dynamic> ack,
      final String msg,
      Batch batch)
   {
      final String res = ack["result"];
      if (res == 'fail') {
         print("register_ack: fail.");
         return;
      }

      _isConnected = true;

      _cfg.appId = ack["id"];
      _cfg.appPwd = ack["password"];

      batch.insert(
         'config',
         configToMap(_cfg),
         conflictAlgorithm: ConflictAlgorithm.replace);

      // Retrieves some posts for the newly registered user.
      _subscribeToChannels();

      // TODO: Check for menu updates and apply them.
   }

   void _onLoginAck(Map<String, dynamic> ack, final String msg)
   {
      final String res = ack["result"];

      // I still do not know how a failed login should be handled.
      // Perhaps send a new register command? It can only happen if
      // the server is blocking this user.
      if (res == 'fail') {
         print("login_ack: fail.");
         return;
      }

      _isConnected = true;

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

   void _onPost(Map<String, dynamic> ack, Batch batch)
   {
      for (var item in ack['items']) {
         Post post = Post.fromJson(item);
         post.status = 1;

         // Just in case the server sends us posts out of order I
         // will check. It should however be considered a server
         // error.
         if (post.id > _cfg.lastPostId)
            _cfg.lastPostId = post.id;

         if (post.from == _cfg.appId)
            continue;

         batch.insert('posts', postToMap(post),
            conflictAlgorithm: ConflictAlgorithm.replace);

         _posts.add(post);
         ++_nNewPosts;
      }

      batch.execute(sql.updateLastPostId, [_cfg.lastPostId]);
      setState(() { });
   }

   void _onPublishAck(Map<String, dynamic> ack, Batch batch)
   {
      final String res = ack['result'];
      if (res == 'ok')
         _handlePublishAck(ack['id'], ack['date'], batch);
      else
         _handlePublishAck(-1, -1, batch);
   }

   void _onWSDataImpl(Batch batch)
   {
      while (!_wsMsgQueue.isEmpty) {
         var msg = _wsMsgQueue.removeFirst();

         Map<String, dynamic> ack = jsonDecode(msg);
         final String cmd = ack["cmd"];

         if (cmd == "message") {
            _onMessage(ack, batch);
         } else if (cmd == "login_ack") {
            _onLoginAck(ack, msg);
         } else if (cmd == "subscribe_ack") {
            _onSubscribeAck(ack);
         } else if (cmd == "post") {
            _onPost(ack, batch);
         } else if (cmd == "publish_ack") {
            _onPublishAck(ack, batch);
         } else if (cmd == "delete_ack") {
            print('delete_ack');
            _onServerAck(ack, batch);
         } else if (cmd == "register_ack") {
            _onRegisterAck(ack, msg, batch);
         } else {
            print('Unhandled message received from the server:\n$msg.');
         }
      }
   }

   Future<void> onWSData(msg) async
   {
      final bool isEmpty = _wsMsgQueue.isEmpty;
      _wsMsgQueue.add(msg);
      if (isEmpty) {
         Batch batch = _db.batch();
         _onWSDataImpl(batch);
         await batch.commit(noResult: true, continueOnError: true);
      }
   }

   void _onWSError(error)
   {
      print("Error: " + error);
      _isConnected = false;
   }

   void _onWSDone()
   {
      print("Communication closed by peer.");
      _isConnected = false;
   }

   void _onOkDialAfterSendFilters()
   {
      _tabCtrl.index = 1;
      _botBarIdx = 0;
      setState(() { });
   }

   void _showSimpleDial(
      BuildContext ctx,
      Function onOk,
      String title,
      Widget content)
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

            return AlertDialog(
               title: Text(title),
               content: content,
               actions: actions,
            );
         },
      );
   }

   Future<void> _onSendFilters(BuildContext ctx) async
   {
      _newFiltersPressed = false;

      // First send the hashes then show the dialog.
      _subscribeToChannels();

      _showSimpleDial(
         ctx,
         _onOkDialAfterSendFilters,
         txt.dialogTitles[2],
         Text(txt.dialogBodies[2]),
      );
   }

   void _subscribeToChannels()
   {
      List<List<int>> channels = List<List<int>>();
      // An empty channels list means we do not want any filter for
      // that menu item.
      for (MenuItem item in _menu)
         channels.add(readHashCodes(item.root.first, item.filterDepth));

      var subCmd = {
         'cmd': 'subscribe',
         'last_post_id': _cfg.lastPostId,
         'channels': channels,
         'filter': _filter,
         'ranges': _cfg.ranges,
      };

      final String payload = jsonEncode(subCmd);
      print(payload);
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
         _goToRegScreen = true;

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
                        style: TextStyle(
                           color: Theme.of(ctx).colorScheme.secondary,
                        ),
                     ),
                     onPressed: () async
                     {
                        await _removeLPChats();
                        Navigator.of(ctx).pop();
                     });

            final FlatButton cancel = FlatButton(
               child: Text(txt.delChatCancelStr,
                  style: TextStyle(
                     color: Theme.of(ctx).colorScheme.secondary,
                  ),
               ),
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

   Future<void> _onRegisterContinue() async
   {
      try {
         if (_txtCtrl2.text.isNotEmpty) {
            _cfg.email = _txtCtrl2.text;
            await _db.execute(sql.updateEmail, [_cfg.email]);
         }

         _cfg.nick = _txtCtrl.text;
         await _db.execute(sql.updateNick, [_cfg.nick]);

         setState(()
         {
            _txtCtrl2.clear();
            _txtCtrl.clear();
            _goToRegScreen = false;
         });

      } catch (e) {
         print(e);
      }
   }

   void _onNewPostExDetails(int i, int j)
   {
      if (j == -1) {
         _post.description = _txtCtrl.text;
         _txtCtrl.clear();
         _botBarIdx = 3;
         setState(() { });
         return;
      }

      _post.exDetails[i] = 1 << j;

      setState(() { });
   }

   void _onNewPostInDetail(int i, int j)
   {
      _post.inDetails[i] ^= 1 << j;
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
      if (_menu.isEmpty)
         return makeWaitMenuScreen(ctx);

      if (_goToRegScreen) {
         return makeRegisterScreen(
            ctx,
            _txtCtrl2,
            _txtCtrl,
            _onRegisterContinue,
            txt.appName,
            _cfg.email,
            _cfg.nick,
         );
      }

      if (hasSwitchedTab())
         _cleanUpLpOnSwitchTab();

      if (_newPostPressed) {
         return makeNewPostScreens(
            ctx,
            _post,
            _menu,
            _txtCtrl,
            _onSendNewPost,
            _botBarIdx,
            _onNewPostExDetails,
            _onPostLeafPressed,
            _onPostNodePressed,
            _onWillPopMenu,
            _onNewPostBotBarTapped,
            _onNewPostInDetail,
            _exDetailsRoot,
            _inDetailsRoot,
            _onRangeValueChanged,
            _onAddPhoto,
            _imgFiles,
         );
      }

      if (_newFiltersPressed) {
         // NOTE: Below we use txt.exDetails[0][0], because the filter
         // is common to all products.
         return makeNewFiltersScreens(
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
            _onCancelNewFilter,
            _exDetailsRoot.children[0].children[0],
            _cfg.ranges,
            _onRangeChanged,
         );
      }

      if (isOnFavChat() || isOnOwnChat()) {
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
            makePostSummaryStr(_menu[1].root.first, _post),
            _onChatAttachment,
            _dragedIdx,
            _onCancelFwdLPChatMsg,
            _showChatJumpDownButton,
            _onChatJumpDown,
            _post.avatar,
         );
      }

      List<Function> onWillPops = List<Function>(txt.tabNames.length);
      onWillPops[0] = _onChatsBackPressed;
      onWillPops[1] = (){return false;};
      onWillPops[2] = _onChatsBackPressed;

      String appBarTitle = txt.appName;

      List<Widget> fltButtons = List<Widget>(txt.tabNames.length);

      fltButtons[0] = makeFaButton(
         ctx,
         _onNewPost,
         _onFwdSendButton,
         _lpChats.length,
         _lpChatMsgs.length
      );

      fltButtons[1] = makeFAButtonMiddleScreen(
         ctx,
         _onNewFilters,
         _onShowNewPosts,
         _nNewPosts,
      );

      fltButtons[2] = makeFaButton(
         ctx,
         null,
         _onFwdSendButton,
         _lpChats.length,
         _lpChatMsgs.length
      );

      List<Widget> bodies = List<Widget>(txt.tabNames.length);

      bodies[0] = makeChatTab(
         ctx,
         _ownPosts,
         _onChatPressed,
         _onChatLP,
         _menu,
         (int i) { _removePostDialog(ctx, i);},
         _onPinPost,
         _lpChatMsgs.isNotEmpty,
         _onUserInfoPressed,
         false,
         _exDetailsRoot,
         _inDetailsRoot,
      );

      bodies[1] = makePostTabListView(
         ctx,
         _posts,
         _alertUserOnselectPost,
         _menu,
         _exDetailsRoot,
         _inDetailsRoot,
         _nNewPosts,
      );

      bodies[2] = makeChatTab(
         ctx,
         _favPosts,
         _onChatPressed,
         _onChatLP,
         _menu,
         (int i) { _removePostDialog(ctx, i);},
         _onPinPost,
         _lpChatMsgs.isNotEmpty,
         _onUserInfoPressed,
         true,
         _exDetailsRoot,
         _inDetailsRoot,
      );

      List<Widget> actions = List<Widget>();
      Widget appBarLeading = null;
      if ((_isOnFav() || _isOnOwn()) && _hasLPChatMsgs()) {
         appBarTitle = txt.msgOnRedirectingChat;
         appBarLeading = IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: _onBackFromChatMsgRedirect
         );
      }

      if (_isOnOwn() && _hasLPChats() && !_hasLPChatMsgs()) {
         actions = makeOnLongPressedActions(
            ctx,
            _deleteChatDialog,
            _pinChats,
         );
      } else if (_isOnFav() && _hasLPChats() && !_hasLPChatMsgs()) {
         IconButton delChatBut = IconButton(
            icon: Icon(
               Icons.delete_forever,
               color: Theme.of(ctx).colorScheme.onPrimary,
            ),
            tooltip: txt.deleteChat,
            onPressed: () { _deleteChatDialog(ctx); }
         );

         actions.add(delChatBut);
      }

      actions.add(makeAppBarVertAction(_onAppBarVertPressed));

      List<int> newMsgsCounters = List<int>(txt.tabNames.length);
      newMsgsCounters[0] = _getNUnreadOwnChats();
      newMsgsCounters[1] = _nNewPosts;
      newMsgsCounters[2] = _getNUnreadFavChats();

      List<double> opacities = getNewMsgsOpacities();

      return WillPopScope(
         onWillPop: () async { return onWillPops[_tabCtrl.index]();},
         child: Scaffold(
            body: NestedScrollView(
               controller: _scrollCtrl,
               headerSliverBuilder: (BuildContext ctx, bool innerBoxIsScrolled)
               {
                  return <Widget>[
                     SliverAppBar(
                        title: Text(appBarTitle),
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
                        leading: appBarLeading,
                     ),
                  ];
               },
               body: TabBarView(
                  controller: _tabCtrl,
                  children: bodies
               ),
            ),
            backgroundColor: Colors.white,
            floatingActionButton: fltButtons[_tabCtrl.index],
         ),
      );
   }
}

