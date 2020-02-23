import 'dart:async' show Future, Timer;
import 'dart:convert';
import 'dart:io';
import 'dart:collection';

import 'package:web_socket_channel/io.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/scheduler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:photo_view/photo_view_gallery.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:flutter/material.dart';
import 'package:occase/post.dart';
import 'package:occase/tree.dart';
import 'package:occase/constants.dart' as cts;
import 'package:occase/parameters.dart';
import 'package:occase/globals.dart' as g;
import 'package:occase/sql.dart' as sql;
import 'package:occase/stl.dart' as stl;

Future<List<MenuItem>> readMenuItemsFromAsset() async
{
   // When the database is created, we also have to create the
   // default menu table.
   List<MenuItem> l = List<MenuItem>(2);

   final String menu0 = await rootBundle.loadString('data/menu0.txt');
   l[0] = menuReader(jsonDecode(menu0)).first;

   final String menu1 = await rootBundle.loadString('data/menu1.txt');
   l[1] = menuReader(jsonDecode(menu1)).first;

   return l;
}

String emailToGravatarHash(String email)
{
   email = email.replaceAll(' ', '');
   email = email.toLowerCase();
   List<int> bytes = utf8.encode(email);
   return md5.convert(bytes).toString();
}

class Coord {
   Post post;
   ChatMetadata chat;
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

void toggleChatPinDate(ChatMetadata chat)
{
   if (chat.pinDate == 0)
      chat.pinDate = DateTime.now().millisecondsSinceEpoch;
   else
      chat.pinDate = 0;
}

bool compPostIdAndPeer(Coord a, Coord b)
{
   return a.post.id == b.post.id && a.chat.peer == b.chat.peer;
}

bool compPeerAndChatIdx(Coord a, Coord b)
{
   return a.chat.peer == b.chat.peer && a.msgIdx == b.msgIdx;
}

void handleLPChats(
   List<Coord> pairs,
   bool old,
   Coord coord,
   Function comp,
) {
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

   posts.sort(compPosts);
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
, Notifications
}

Widget makeAppBarVertAction(Function onSelected)
{
   return PopupMenuButton<ConfigActions>(
     icon: Icon(Icons.more_vert, color: Colors.white),
     onSelected: onSelected,
     itemBuilder: (BuildContext ctx)
     {
        return <PopupMenuEntry<ConfigActions>>
        [ PopupMenuItem<ConfigActions>(
             value: ConfigActions.ChangeNick,
             child: Text(g.param.changeNickHint),
          ),
          PopupMenuItem<ConfigActions>(
             value: ConfigActions.Notifications,
             child: Text(g.param.changeNotifications),
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
      tooltip: g.param.pinChat,
      onPressed: pinChat);

   actions.add(pinChatBut);

   IconButton delChatBut = IconButton(
      icon: Icon(Icons.delete_forever, color: Colors.white),
      tooltip: g.param.deleteChat,
      onPressed: () { deleteChatEntryDialog(ctx); });

   actions.add(delChatBut);

   return actions;
}

Scaffold makeWaitMenuScreen(BuildContext ctx)
{
   return Scaffold(
      appBar: AppBar(title: Text(g.param.appName)),
      body: Center(child: CircularProgressIndicator()),
      backgroundColor: Theme.of(ctx).colorScheme.background,
   );
}

Widget makeImgExpandScreen(
   BuildContext ctx,
   Function onWillPopScope,
   Post post)
{
   //final double width = MediaQuery.of(ctx).size.width;
   //final double height = MediaQuery.of(ctx).size.height;

   final int l = post.images.length;

   Widget foo = PhotoViewGallery.builder(
      scrollPhysics: const BouncingScrollPhysics(),
      itemCount: post.images.length,
      //loadingChild: Container(
      //         width: 30.0,
      //         height: 30.0,
      //),
      reverse: true,
      //backgroundDecoration: widget.backgroundDecoration,
      //pageController: widget.pageController,
      onPageChanged: (int i){ print('===> New index: $i');},
      builder: (BuildContext context, int i) {
         // No idea why this is showing in reverse order, I will have
         // to manually reverse the indexes.
         final int idx = l - i - 1;
         return PhotoViewGalleryPageOptions(
            //imageProvider: AssetImage(widget.galleryItems[idx].image),
            imageProvider: CachedNetworkImageProvider(post.images[idx]),
            //initialScale: PhotoViewComputedScale.contained * 0.8,
            //minScale: PhotoViewComputedScale.contained * 0.8,
            //maxScale: PhotoViewComputedScale.covered * 1.1,
            //heroAttributes: HeroAttributes(tag: galleryItems[idx].id),
         );
      },
   );

   return WillPopScope(
      onWillPop: () async { return onWillPopScope();},
      child: Scaffold(
         //appBar: AppBar(title: Text(g.param.appName)),
         body: Center(child: foo),
         backgroundColor: Theme.of(ctx).colorScheme.primary,
      ),
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

   Color enabledColor = focusedColor;

   return TextField(
      style: stl.textField,
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
      cts.emailMaxLength, g.param.emailHint,
   );

   if (previousNick.isNotEmpty)
      nickCtrl.text = previousNick;

   TextField nickTf = makeNickTxtField(
      ctx, nickCtrl, Icon(Icons.person),
      cts.nickMaxLength, g.param.nickHint,
   );

   Widget button = createRaisedButton(
      ctx,
      onContinue,
      g.param.next,
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

Scaffold makeNtfScreen(
   BuildContext ctx,
   Function onChange,
   final String appBarTitle,
   final NtfConfig conf,
   final List<String> titleDesc)
{
   assert(titleDesc.length >= 2);

   CheckboxListTile chat = CheckboxListTile(
      dense: true,
      title: Text(titleDesc[0], style: stl.ltTitle),
      subtitle: Text(titleDesc[1], style: stl.ltSubtitle),
      value: conf.chat,
      onChanged: (bool v) { onChange(0, v); },
      activeColor: stl.colorScheme.primary,
      isThreeLine: true,
   );

   Column col = Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>
      [ Padding(
           child: chat,
           padding: EdgeInsets.only(bottom: 30.0),
        ),
        createRaisedButton(
           ctx,
           () {onChange(-1, false);},
           g.param.ok,
        ),
      ]
   );

   return Scaffold(
      appBar: AppBar(title: Text(appBarTitle)),
      body: Padding(
         child: col,
         padding: EdgeInsets.symmetric(vertical: 20.0),
      ),
   );
}

Widget makeNetImgBox(
   double width,
   double height,
   String url,
   BoxFit bf)
{
   return CachedNetworkImage(
      imageUrl: url,
      width: width,
      height: height,
      fit: bf,
      placeholder: (ctx, url) => CircularProgressIndicator(),
      errorWidget: (ctx, url, error) {
         print('====> $error $url $error');
         //Icon ic = Icon(Icons.error, color: stl.colorScheme.primary);
         Widget w = Text(g.param.unreachableImgError,
            overflow: TextOverflow.clip,
            style: TextStyle(
               color: stl.colorScheme.background,
               fontSize: stl.tt.title.fontSize,
            ),
         );

         return makeImgPlaceholder(width, height, w);
      },
   );
}

Widget makeImgPlaceholder(
   double width,
   double height,
   Widget w)
{
   return SizedBox(
      width: width,
      height: height,
      child: Card(
         elevation: 0.0,
         margin: EdgeInsets.all(0.0),
         color: Colors.grey,
         child: Center(
            child: Padding(
               padding: const EdgeInsets.symmetric(horizontal: 15.0),
               child: w,
            ),
         ),
         shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(0.0)),
            //side: BorderSide(
            //   width: stl.imgLvBorderWidth,
            //   color: stl.colorScheme.background,
            //),
         ),
      ),
   );
}

Widget constrainBox(double width, double height, Widget lv)
{
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

// Generates the image list view of a post.
Widget makeImgListView2(
   double width,
   double height,
   Post post,
   Function onExpandImg,
   BoxFit bf)
{
   final int l = post.images.length;

   ListView lv = ListView.builder(
      scrollDirection: Axis.horizontal,
      shrinkWrap: true,
      padding: const EdgeInsets.all(0.0),
      itemCount: l,
      itemBuilder: (BuildContext ctx, int i)
      {
         FlatButton b = FlatButton(
            onPressed: (){onExpandImg(i);},
            child: Container(
               width: width * 0.9,
               height: height * 0.9,
            ),
         );

         Widget counters2 = Padding(
            padding: const EdgeInsets.all(2.0),
            child: Text('$i/$l',
               style: stl.tt.subhead.copyWith(
                  color: Theme.of(ctx).colorScheme.onPrimary,
               ),
            ),
         );

         return Stack(
            alignment: Alignment(0.0, 0.0),
            children: <Widget>
            [ makeNetImgBox(width, height, post.images[i], bf)
            , b
            , Column(children: <Widget>[counters2, Spacer()]),
            ],
         );
      },
   );

   return constrainBox(width, height, lv);
}

Widget makeImgListView(
   double width,
   double height,
   Function onAddPhoto,
   List<File> imgFiles,
   Post post)
{
   int l = 1;
   if (imgFiles.isNotEmpty)
      l = imgFiles.length;

   ListView lv = ListView.builder(
      scrollDirection: Axis.horizontal,
      shrinkWrap: true,
      padding: const EdgeInsets.all(0.0),
      itemCount: l,
      itemBuilder: (BuildContext ctx, int i)
      {
         Widget img = Image.file(imgFiles[i],
            width: width,
            height: height,
            fit: BoxFit.cover,
            filterQuality: FilterQuality.high,
         );

         Widget delPhotoWidget = makeAddOrRemoveWidget(
            () {onAddPhoto(ctx, i);},
            Icons.clear,
            stl.colorScheme.secondaryVariant,
         );

         return Stack(children: <Widget>[img, delPhotoWidget]);
      },
   );

   return constrainBox(width, height, lv);
}

int searchBitOn(int o, int n)
{
   assert(n <= 64);

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
         style: stl.tsSubheadOnPrimary,
         children: <TextSpan>
         [ TextSpan(
              text: second,
              style: stl.tt.subhead.copyWith(color: color),
           ),
         ],
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
   //Key key = UniqueKey();

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
   Function onInDetail,
   Node titleNode,
   int state,
   String strDisplay)
{
   List<Widget> bar =
      makeNewPostDetailElemList(
         ctx,
         onInDetail,
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

List<Widget> makeSliderList({
   double value,
   double min,
   double max,
   int divisions,
   Function onValueChanged})
{
   final int d = (max - min).round();

   if (d <= divisions) {
      Slider sld = Slider(
         value: value,
         min: min,
         max: max,
         divisions: divisions,
         onChanged: onValueChanged,
      );

      return <Widget>[sld];
   }

   final double max2 = max / divisions;

   final double value2 = value % max2;

   Slider sld1 = Slider(
      value: value,
      min: min,
      max: max,
      divisions: divisions,
      onChanged: (double v) {
         double vv = v + value2;
         if (vv > max)
            vv = max;
         onValueChanged(vv);
      },
   );

   final double offset = value - value2;

   Slider sld2 = Slider(
      value: value2,
      min: 0,
      max: max2,
      divisions: divisions,
      onChanged: (double v) {
         double vv = offset + v;
         if (vv > max)
            vv = max;
         onValueChanged(vv);
      },
   );

   return <Widget>[sld2, sld1];
}

List<Widget> makeNewPostDetailScreen(
   BuildContext ctx,
   Function onExDetail,
   Function onInDetail,
   Post post,
   Node exDetailsTree,
   Node inDetailsTree,
   TextEditingController txtCtrl,
   Function onRangeValueChanged)
{
   final int idx = post.getProductDetailIdx();

   List<Widget> all = List<Widget>();

   final int l1 = exDetailsTree.children[idx].children.length;
   for (int i = 0; i < l1; ++i) {

      final int k = searchBitOn(
         post.exDetails[i],
         exDetailsTree.children[idx].children[i].children.length
      );

      Widget foo = makeNewPostDetailExpTile(
         ctx,
         (int j) {onExDetail(i, j);},
         exDetailsTree.children[idx].children[i],
         post.exDetails[i],
         exDetailsTree.children[idx].children[i].children[k].name,
      );

      all.add(foo);
   }

   final int l2 = inDetailsTree.children[idx].children.length;
   for (int i = 0; i < l2; ++i) {
      final int nBitsSet = counterBitsSet(post.inDetails[i]);
      Widget foo = makeNewPostDetailExpTile(
         ctx,
         (int j) {onInDetail(i, j);},
         inDetailsTree.children[idx].children[i],
         post.inDetails[i],
         '$nBitsSet items',
      );

      all.add(foo);
   }

   for (int i = 0; i < g.param.rangeDivs.length; ++i) {
      final int j = 2 * i;

      List<Widget> col = makeSliderList(
         value: post.rangeValues[i].toDouble(),
         min: g.param.rangesMinMax[j + 0].toDouble(),
         max: g.param.rangesMinMax[j + 1].toDouble(),
         divisions: g.param.rangeDivs[i],
         onValueChanged: (double v) {onRangeValueChanged(i, v);}
      );

      Column sliderCol = Column(children: col);

      all.add(wrapOnDetailExpTitle(
            ctx,
            makeExpTileTitle(
               ctx,
               g.param.rangePrefixes[i],
               post.rangeValues[i].toString(),
               ':',
               false,
            ),
            <Widget>[wrapDetailRowOnCard(ctx, sliderCol)],
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
      style: stl.textField,
      decoration: InputDecoration.collapsed(
         hintText: g.param.newPostTextFieldHist,
      ),
   );

   Padding pad = Padding(
      padding: EdgeInsets.all(10.0),
      child: tf,
   );

   all.add(wrapOnDetailExpTitle(
         ctx,
         Text(g.param.postDescTitle),
         <Widget>[wrapDetailRowOnCard(ctx, pad)],
         false,
      ),
   );

   all.add(
      createRaisedButton(
         ctx,
         (){onExDetail(-1, -1);},
         g.param.next,
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
   Function onExDetail,
   Function onPostLeafPressed,
   Function onPostNodePressed,
   Function onWillPopMenu,
   Function onNewPostBotBarTapped,
   Function onInDetail,
   Node exDetailsTree,
   Node inDetailsTree,
   Function onRangeValueChanged,
   Function onAddPhoto,
   List<File> imgFiles,
   bool filenamesTimerActive)
{
   Widget wid;
   Widget appBarTitleWidget = Text(
      g.param.newPostAppBarTitle,
      style: stl.appBarLtTitle,
   );

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

            return makeNewPost(
               ctx,
               post,
               (int j) { onSendNewPost(ctx, j); },
               menu,
               exDetailsTree,
               inDetailsTree,
               stl.pubIcon,
               g.param.cancelNewPost,
               onAddPhoto,
               imgFiles,
               (int j){ print('Error. abab');},
            );
         },
      );
   } else if (screen == 2) {
      final List<Widget> widgets = makeNewPostDetailScreen(
         ctx,
         onExDetail,
         onInDetail,
         post,
         exDetailsTree,
         inDetailsTree,
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
            g.param.newPostAppBarTitle,
            maxLines: 1,
            overflow: TextOverflow.clip,
            style: stl.appBarLtTitle,
         ),
         dense: true,
         subtitle: Text(menu[screen].getStackNames(),
            maxLines: 1,
            overflow: TextOverflow.clip,
            style: stl.appBarLtSubtitle,
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

   List<Widget> ww = <Widget>[wid];
   if (filenamesTimerActive) {
      ModalBarrier mb = ModalBarrier(
         color: Colors.grey.withOpacity(0.4),
         dismissible: false,
      );
      ww.add(mb);
      ww.add(Center(child: CircularProgressIndicator()));
   }

   Stack stack = Stack(children: ww);

   return WillPopScope(
      onWillPop: () async { return onWillPopMenu();},
      child: Scaffold(
          appBar: appBar,
          body: stack,
          bottomNavigationBar: makeBottomBarItems(
             stl.newPostTabIcons,
             g.param.newPostTabNames,
             onNewPostBotBarTapped,
             screen,
          ),
       ),
   );
}

Widget makeNewFiltersEndWidget(BuildContext ctx, Function onPressed)
{
   // See the comment in _onPostSelection for why I removed the middle
   // button for now.
   return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      //mainAxisSize: MainAxisSize.min,
      children: <Widget>
      [ Padding(
          padding: const EdgeInsets.symmetric(vertical: 40.0),
          child: createRaisedButton(
             ctx,
             () {onPressed(ctx, 0);},
             g.param.newFiltersFinalScreenButton[0],
          ))
      //, Padding(
      //    padding: const EdgeInsets.symmetric(vertical: 40.0),
      //    child: createRaisedButton(
      //       ctx,
      //       () {onPressed(ctx, 1);},
      //       g.param.newFiltersFinalScreenButton[1],
      //    ))
      , Padding(
          padding: const EdgeInsets.symmetric(vertical: 40.0),
          child: createRaisedButton(
             ctx,
             () {onPressed(ctx, 2);},
             g.param.newFiltersFinalScreenButton[2],
          ))
      ]
   );
}

WillPopScope makeFiltersScreen(
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
   Node exDetailsFilterNodes,
   List<int> ranges,
   Function onRangeChanged)
{
   Widget wid;
   Widget appBarTitleWidget = Text(
      g.param.filterAppBarTitle,
      style: stl.appBarLtTitle,
   );

   if (screen == 3) {
      wid = makeNewFiltersEndWidget(ctx, onSendFilters);
   } else if (screen == 2) {
      List<Widget> foo = List<Widget>();

      final Widget vv = makeNewPostDetailExpTile(
         ctx,
         onFilterDetail,
         exDetailsFilterNodes,
         filter,
         '',
      );

      foo.add(vv);

      for (int i = 0; i < g.param.discreteRanges.length; ++i) {
         final int vmin = ranges[2 * i + 0];
         final int vmax = ranges[2 * i + 1];

         final int l = g.param.discreteRanges[i].length - 1;

         final Widget rs = RangeSlider(
            min: 0,
            max: l.toDouble(),
            divisions: g.param.discreteRanges[i].length,
            onChanged: (RangeValues rv) {onRangeChanged(i, rv);},
            values: RangeValues(vmin.toDouble(), vmax.toDouble()),
         );

         final int vmin2 = g.param.discreteRanges[i][vmin];
         final int vmax2 = g.param.discreteRanges[i][vmax];

         final String rangeTitle = '$vmin2 - $vmax2';
         final RichText rt = makeExpTileTitle(
            ctx,
            g.param.rangePrefixes[i],
            rangeTitle,
            ':',
            false,
         );

         foo.add(wrapOnDetailExpTitle(ctx, rt, <Widget>[rs], false));
      }

      wid = ListView.builder(
         padding: const EdgeInsets.all(3.0),
         itemCount: foo.length,
         itemBuilder: (BuildContext ctx, int i) { return foo[i]; },
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
            g.param.filterAppBarTitle,
            maxLines: 1,
            overflow: TextOverflow.clip,
            style: stl.appBarLtTitle,
         ),
         subtitle: Text(menu[screen].getStackNames(),
            maxLines: 1,
            overflow: TextOverflow.clip,
            style: stl.appBarLtSubtitle,
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
              g.param.filterTabNames,
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
   List<Node> list)
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
         title: Text(list[i].name, style: stl.ltTitle),
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
      title: g.param.appName,
      theme: ThemeData(
          colorScheme: stl.colorScheme,
          brightness: stl.colorScheme.brightness,
          primaryColor: stl.colorScheme.primary,
          accentColor: stl.colorScheme.secondary,
      ),
      debugShowCheckedModeBanner: false,
      home: Occase(),
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

   List<Widget> tabs = List<Widget>(g.param.tabNames.length);

   for (int i = 0; i < tabs.length; ++i) {
      tabs[i] = Tab(
         child: makeTabWidget(ctx,
            counters[i],
            g.param.tabNames[i],
            opacity[i]
         ),
      );
   }

   return TabBar(controller: tabCtrl,
                 indicatorColor: Colors.white,
                 tabs: tabs);
}

BottomNavigationBar makeBottomBarItems(
   List<IconData> icons,
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
         backgroundColor: Theme.of(ctx).colorScheme.secondary,
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
      backgroundColor: Theme.of(ctx).colorScheme.secondary,
      child: Icon(id,
         color: Theme.of(ctx).colorScheme.onSecondary,
      ),
      onPressed: onNewPost);
}

Widget makeFAButtonMiddleScreen(
   BuildContext ctx,
   Function onLoadNewPosts,
   Function onSearch,
   int nNewPosts,
   int nPosts,
) {
   if (nPosts == 0) { // Implies nNewPosts = 0.
      return FloatingActionButton(
         onPressed: onSearch,
         backgroundColor: stl.colorScheme.secondary,
         child: Icon(
            Icons.search,
            color: stl.colorScheme.onSecondary,
         ),
      );
   }

   if (nNewPosts == 0)
      return null;

   return FloatingActionButton(
      //mini: true,
      //heroTag: null,
      onPressed: onLoadNewPosts,
      backgroundColor: Theme.of(ctx).colorScheme.secondary,
      child: Icon(
         Icons.file_download,
         color: Theme.of(ctx).colorScheme.onSecondary,
      ),
   );
}

int postIndexHelper(int i)
{
   if (i == 0) return 1;
   if (i == 1) return 2;
   if (i == 2) return 3;
   return 1;
}

Widget putRefMsgInBorder(Widget w, Color borderColor)
{
   return Card(
      color: Colors.grey[200],
      elevation: 0.7,
      margin: const EdgeInsets.all(4.0),
      //shape: RoundedRectangleBorder(
      //   borderRadius: BorderRadius.all(Radius.circular(stl.cornerRadius)),
      //),
      child: Center(
         widthFactor: 1.0,
         child: Padding(
            child: w,
            padding: EdgeInsets.all(4.0),
         )
      ),
   );
}

Card makeChatMsgWidget(
   BuildContext ctx,
   ChatMetadata ch,
   int i,
   Function onChatMsgLongPressed,
   Function onDragChatMsg,
   bool isNewMsg,
   String ownNick,
) {
   Color txtColor = Colors.black;
   Color color = Color(0xFFFFFFFF);
   Color onSelectedMsgColor = Colors.grey[300];
   if (ch.msgs[i].isFromThisApp()) {
      color = Colors.lime[100];
   } else if (isNewMsg) {
      txtColor = stl.colorScheme.onPrimary;
      color = Color(0xFF0080CF);
   }

   if (ch.msgs[i].isLongPressed) {
      onSelectedMsgColor = Colors.blue[200];
      color = Colors.blue[100];
      txtColor = Colors.black;
   }

   RichText msgAndDate = RichText(
      text: TextSpan(
         text: ch.msgs[i].msg,
         style: stl.textField.copyWith(color: txtColor),
         children: <TextSpan>
         [ TextSpan(
              text: '  ${makeDateString(ch.msgs[i].date)}',
              style: Theme.of(ctx).textTheme.caption.copyWith(
                 color: Colors.grey[700],
              ),
           ),
         ]
      ),
   );

   // Unfortunately TextSpan still does not support general
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
            child: chooseMsgStatusIcon(ch.msgs[i].status))
      ]);
   } else {
      msgAndStatus = Padding(
            padding: EdgeInsets.all(stl.chatMsgPadding),
            child: msgAndDate);
   }

   Widget ww = msgAndStatus;
   if (ch.msgs[i].redirected()) {
      final Color redirTitleColor =
         isNewMsg ? stl.colorScheme.secondary : Colors.blueGrey;

      Row redirWidget = Row(
         mainAxisSize: MainAxisSize.min,
         mainAxisAlignment: MainAxisAlignment.start,
         crossAxisAlignment: CrossAxisAlignment.center,
         textBaseline: TextBaseline.alphabetic,
         children: <Widget>
         [ Icon(Icons.forward, color: stl.chatDateColor)
         , Text(g.param.msgOnRedirectedChat,
            style: TextStyle(color: redirTitleColor,
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

      Widget refWidget = makeRefChatMsgWidget(
         ctx,
         ch,
         refersTo,
         c1,
         isNewMsg,
         ownNick,
      );

      Row refMsg = Row(
         mainAxisSize: MainAxisSize.min,
         crossAxisAlignment: CrossAxisAlignment.start,
         children: <Widget>
         [ Flexible(child: putRefMsgInBorder(refWidget, stl.chatDateColor)),
         ],
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

   final double screenWidth = MediaQuery.of(ctx).size.width;
   Card w1 = Card(
      margin: EdgeInsets.only(
            left: marginLeft,
            top: 2.0,
            right: marginRight,
            bottom: 0.0),
      elevation: 0.7,
      color: color,
      child: Center(
         widthFactor: 1.0,
         child: ConstrainedBox(
            constraints: BoxConstraints(
               maxWidth: 0.75 * screenWidth,
               minWidth: 0.20 * screenWidth,
            ),
            child: ww)));

   Row r;
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
   ChatMetadata ch,
   Function onChatMsgLongPressed,
   Function onDragChatMsg,
   String ownNick,)
{
   final int nMsgs = ch.msgs.length;
   final int shift = ch.divisorUnreadMsgs == 0 ? 0 : 1;

   return ListView.builder(
      controller: scrollCtrl,
      reverse: false,
      padding: const EdgeInsets.only(bottom: 3.0, top: 3.0),
      itemCount: nMsgs + shift,
      itemBuilder: (BuildContext ctx, int i)
      {
         if (shift == 1) {
            if (i == ch.divisorUnreadMsgsIdx) {
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
                            '${ch.divisorUnreadMsgs}',
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

            if (i > ch.divisorUnreadMsgsIdx)
               i -= 1; // For the shift
         }

         final bool isNewMsg =
            shift == 1 &&
            i >= ch.divisorUnreadMsgsIdx &&
            i < ch.divisorUnreadMsgsIdx + ch.divisorUnreadMsgs;
                               
         Card chatMsgWidget = makeChatMsgWidget(
            ctx,
            ch,
            i,
            onChatMsgLongPressed,
            onDragChatMsg,
            isNewMsg,
            ownNick,
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

Widget makeRefChatMsgWidget(
   BuildContext ctx,
   ChatMetadata ch,
   int i,
   Color cc,
   bool isNewMsg,
   String ownNick,
) {
   Color titleColor = cc;
   Color bodyTxtColor = Colors.black;
   
   if (isNewMsg) {
      titleColor = stl.colorScheme.secondary;
      //bodyTxtColor = Colors.grey[300];
   }

   Text body = Text(ch.msgs[i].msg,
      maxLines: 3,
      overflow: TextOverflow.clip,
      style: Theme.of(ctx).textTheme.caption.copyWith(
         color: bodyTxtColor,
      ),
   );

   String nick = ch.nick;
   if (ch.msgs[i].isFromThisApp())
      nick = ownNick;

   Text title = Text(nick,
      maxLines: 1,
      overflow: TextOverflow.clip,
      style: TextStyle(
         fontSize: stl.mainFontSize,
         fontWeight: FontWeight.bold,
         color: titleColor,
      ),
   );

   Column col = Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>
      [ Padding(
           child: title,
           padding: const EdgeInsets.symmetric(vertical: 3.0)
        )
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
      color: stl.colorScheme.primary,
   );

   IconButton attachmentButton = IconButton(
      icon: Icon(Icons.add_a_photo),
      onPressed: onAttachment,
      color: stl.colorScheme.primary,
   );

   // At the moment we do not support sending of multimedia files
   // through the chat, so I will remove the button attachmentButton.
   return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[Row(
         mainAxisSize: MainAxisSize.min,
         children: <Widget>[sendButton],
      )],
   );
}

Widget makeChatScreen(
   BuildContext ctx,
   Function onWillPopScope,
   ChatMetadata ch,
   TextEditingController ctrl,
   Function onSendChatMsg,
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
   String avatar,
   Function onWritingChat,
   String ownNick,
) {
   Column secondLayer = makeChatSecondLayer(
      ctx,
      ctrl.text.isEmpty ? null : onSendChatMsg,
      onAttachment,
   );

   TextField tf = TextField(
       style: stl.textField,
       controller: ctrl,
       keyboardType: TextInputType.multiline,
       maxLines: null,
       maxLength: null,
       focusNode: chatFocusNode,
       onChanged: onWritingChat,
       decoration:
          InputDecoration.collapsed(hintText: g.param.chatTextFieldHint),
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
      ownNick,
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
         child: makeRefChatMsgWidget(
            ctx,
            ch,
            dragedIdx,
            co1,
            false,
            ownNick,
         ),
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
   Widget title;

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

      ChatPresenceSubtitle cps = makeLTPresenceSubtitle(
         ch,
         postSummary,
         stl.onPrimarySubtitleColor,
      );

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
             style: stl.appBarLtTitle,
          ),
          dense: true,
          subtitle:
             Text(cps.subtitle,
                maxLines: 1,
                overflow: TextOverflow.clip,
                style: stl.appBarLtSubtitle.copyWith(color: cps.color),
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

Widget makeTabWidget(
   BuildContext ctx,
   int n,
   String title,
   double opacity
) {
   if (n == 0)
      return Text(title);

   List<Widget> widgets = List<Widget>(2);
   widgets[0] = Text(title);

   // See: https://docs.flutter.io/flutter/material/TabBar/labelColor.html
   // for opacity values.
   widgets[1] = Opacity(
      child: makeUnreadMsgsCircle(
         ctx,
         n,
         stl.colorScheme.secondary,
         stl.colorScheme.onSecondary,
      ),
      opacity: opacity,
   );

   return Row(children: widgets);
}

CircleAvatar makeChatListTileLeading(
   bool isLongPressed,
   String avatar,
   Color bgcolor,
   Function onLeadingPressed)
{
   List<Widget> l = List<Widget>();

   ImageProvider bgImg;
   if (avatar.isEmpty) {
      l.add(Center(child: stl.unknownPersonIcon));
   } else {
      final String url = cts.gravatarUrl + avatar + '.jpg';
      bgImg = CachedNetworkImageProvider(url);
   }

   l.add(OutlineButton(
         child: Text(''),
         borderSide: BorderSide(style: BorderStyle.none),
         onPressed: onLeadingPressed,
         shape: CircleBorder()
      ),
   );

   if (isLongPressed) {
      Positioned p = Positioned(
         bottom: 0.0,
         right: 0.0,
         child: Container(
            height: 20,
            width: 20,
            child: Icon(Icons.check,
               color: Colors.white,
               size: 15,
            ),
            decoration: BoxDecoration(
               color: stl.primaryColor,
               shape: BoxShape.circle,
            ),
         ),
      );

      l.add(p);
   }

   return CircleAvatar(
      child: Stack(children: l),
      backgroundColor: bgcolor,
      backgroundImage: bgImg,
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
   Node node,
   String title,
   Function onTap,
) {
   return ListTile(
       leading: Icon(
          Icons.select_all,
          size: 35.0,
          color: Theme.of(ctx).colorScheme.secondaryVariant
       ),
       title: makeListTileTreeTitle(ctx, node, title),
       subtitle: makeListTileTreeSubtitle(node),
       dense: true,
       onTap: onTap,
       enabled: true,
       isThreeLine: true,
    );
}

Widget makePayPriceListTile(
   BuildContext ctx,
   String price,
   String title,
   String subtitle,
   Function onTap,
   Color color)
{
   Text subtitleW = Text(subtitle,
      maxLines: 2,
      overflow: TextOverflow.clip,
      style: stl.ltSubtitle,
   );

   Text titleW = Text(title,
      maxLines: 1,
      overflow: TextOverflow.clip,
      style: stl.ltTitle,
   );

   Widget leading = Card(
      margin: const EdgeInsets.all(0.0),
      color: color,
      elevation: 0.0,
      shape: RoundedRectangleBorder(
         borderRadius: BorderRadius.all(Radius.circular(10.0)),
      ),
      child: Padding(
         padding: EdgeInsets.all(10.0),
         child: Text(price, style: TextStyle(color: Colors.white),),
      ),
   );

   return ListTile(
       leading: leading,
       title: titleW,
       dense: true,
       subtitle: subtitleW,
       trailing: Icon(Icons.keyboard_arrow_right),
       contentPadding: EdgeInsets.symmetric(horizontal: 10.0),
       onTap: onTap,
       enabled: true,
       selected: false,
       isThreeLine: false,
    );
}

//void pay()
//{
//   InAppPayments.setSquareApplicationId('APPLICATION_ID');
//   InAppPayments.startCardEntryFlow(
//      onCardEntryCancel: (){},
//      onCardNonceRequestSuccess: cardNonceRequestSuccess,
//   );
//}
//
//void cardNonceRequestSuccess(sq.CardDetails result)
//{
//   // Use this nonce from your backend to pay via Square API
//   print(result.nonce);
//
//   final bool invalidZipCode = false;
//
//   if (invalidZipCode) {
//      // Stay in the card flow and show an error:
//      InAppPayments.showCardNonceProcessingError('Invalid ZipCode');
//   }
//
//   InAppPayments.completeCardEntry(
//      onCardEntryComplete: (){},
//   );
//}

Widget makePaymentChoiceWidget(
   BuildContext ctx,
   Function freePayment)
{
   List<Widget> widgets = List<Widget>();
   Widget title = Padding(
      padding: EdgeInsets.all(10.0),
      child: Text(g.param.paymentTitle, style: stl.tsSubheadPrimary),
   );

   widgets.add(title);

   // Depending on the length of the text, change the function ListTile.
   // dense: true,
   // isThreeLine: false,
   List<Function> payments = <Function>
   [ () { freePayment(ctx); }
   , (){print('===> pay1');}
   , (){print('===> pay2');}
   ];
   for (int i = 0; i < g.param.payments.length; ++i) {
      Widget p = makePayPriceListTile(
         ctx,
         g.param.payments[i][0],
         g.param.payments[i][1],
         g.param.payments[i][2],
         payments[i],
         stl.priceColors[i],

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

Widget makeListTileTreeTitle(
   BuildContext ctx,
   Node node,
   String title,
) {
   final int c = node.leafReach;
   final int cs = node.leafCounter;

   String s = ' ($c/$cs)';
   TextStyle counterTxtStl = Theme.of(ctx).textTheme.caption;
   if (node.isLeaf() && node.leafCounter > 1) {
      s = ' (${node.leafCounter})';
      counterTxtStl = Theme.of(ctx).textTheme.caption.copyWith(
         color: Theme.of(ctx).colorScheme.primary,
      );
   }

   return RichText(
      text: TextSpan(
         text: title,
         style: stl.ltTitle,
         children: <TextSpan>
         [ TextSpan(text: s, style: counterTxtStl),
         ]
      )
   );
}

Widget makeListTileTreeSubtitle(Node node)
{
   if (!node.isLeaf())
      return Text(
          node.getChildrenNames(),
          style: stl.ltSubtitle,
          maxLines: 2,
          overflow: TextOverflow.clip,
      );

   Widget subtitle;
   return subtitle;
}

ListTile makeFilterListTitle(
   BuildContext ctx,
   Node child,
   Function onTap,
   Icon trailing)
{
   Color avatarBgColor = Theme.of(ctx).colorScheme.secondary;
   Color avatarTxtColor = Theme.of(ctx).colorScheme.onSecondary;

   if (child.leafReach != 0) {
      avatarBgColor = Theme.of(ctx).colorScheme.primary;
      avatarTxtColor = Theme.of(ctx).colorScheme.onPrimary;
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
          title: makeListTileTreeTitle(ctx, child, child.name),
          dense: true,
          subtitle: makeListTileTreeSubtitle(child),
          trailing: trailing,
          contentPadding: EdgeInsets.symmetric(horizontal: 10.0),
          onTap: onTap,
          enabled: true,
          selected: child.leafReach != 0,
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
   Node o,
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
               ctx,
               o,
               g.param.selectAll,
               () { onLeafPressed(0); },
            );

         if (shift == 1) {
            Node child = o.children[i - 1];

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
      Text("$n",
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

//ababab
Row makePostRowElem(BuildContext ctx, String key, String value)
{
   RichText left = RichText(
      text: TextSpan(
         text: key + ': ',
         style: stl.ltTitle.copyWith(
            color: stl.infoKeyColor,
            fontWeight: FontWeight.normal,
         ),
         children: <TextSpan>
         [ TextSpan(
              text: value,
              style: stl.ltTitle.copyWith(
                 color: stl.infoValueColor
              ),
           ),
         ],
      ),
   );

   final double width = MediaQuery.of(ctx).size.width;
   return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: <Widget>
      [ Icon(Icons.arrow_right, color: stl.infoKeyArrowColor)
      , ConstrainedBox(
         constraints: BoxConstraints(
            maxWidth: 0.80 * width,
            minWidth: 0.80 * width,
         ),
         child: left)
      ]
   );
}

//ababab
List<Widget> makePostInRows(
   BuildContext ctx,
   List<Node> nodes,
   int state)
{
   List<Widget> list = List<Widget>();

   for (int i = 0; i < nodes.length; ++i) {
      if ((state & (1 << i)) == 0)
         continue;

      Text text = Text(' ${nodes[i].name}',
         style: stl.tt.subhead.copyWith(
            color: stl.infoValueColor,
         ),
      );

      Row row = Row(children: <Widget>
      [ Icon(Icons.check, color: Theme.of(ctx).colorScheme.primaryVariant)
      , text
      ]); 

      list.add(row);
   }

   return list;
}

Widget makePostSectionTitle(
   BuildContext ctx,
   String str)
{
   return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
         padding: EdgeInsets.all(stl.postSectionPadding),
         child: Text(str,
            style: TextStyle(
               fontSize: stl.subheadFontSize,
               color: stl.primaryColor,
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
      list.add(makePostSectionTitle(ctx, g.param.newPostTabNames[i]));

      List<String> names = loadNames(
         menus[i].root.first,
         post.channel[i][0],
      );

      List<Widget> items = List.generate(names.length, (int j)
      {
         assert(i == 0 || i == 1);

         List<String> menuDepthNames;
         if (i == 0)
            menuDepthNames = g.param.menuDepthNames0;
         else 
            menuDepthNames = g.param.menuDepthNames1;

         return makePostRowElem(
            ctx,
            menuDepthNames[j],
            names[j],
         );
      });

      list.addAll(items); // The menu info.
   }

   return list;
}

String makeRangeStr(Post post, int i)
{
   assert(i < post.rangeValues.length);

   final int j = 2 * i;

   assert((j + 1) < g.param.rangeUnits.length);

   return g.param.rangeUnits[j + 0]
        + post.rangeValues[i].toString()
        + g.param.rangeUnits[j + 1];
}

List<Widget> makePostValues(BuildContext ctx, Post post)
{
   List<Widget> list = List<Widget>();

   list.add(makePostSectionTitle(ctx, g.param.rangesTitle));

   List<Widget> items = List.generate(g.param.rangeDivs.length, (int i)
   {

      return makePostRowElem(
         ctx,
         g.param.rangePrefixes[i],
         makeRangeStr(post, i),
      );
   });

   list.addAll(items); // The menu info.

   return list;
}

List<Widget> makePostExDetails(
   BuildContext ctx,
   Post post,
   Node exDetailsTree,
) {
   // Post details varies according to the first index of the products
   // entry in the menu.
   final int idx = post.getProductDetailIdx();

   List<Widget> list = List<Widget>();
   list.add(makePostSectionTitle(ctx, g.param.postExDetailsTitle));

   final int l1 = exDetailsTree.children[idx].children.length;
   for (int i = 0; i < l1; ++i) {
      final int j = searchBitOn(
         post.exDetails[i],
         exDetailsTree.children[idx].children[i].children.length
      );
      
      list.add(
         makePostRowElem(
            ctx,
            exDetailsTree.children[idx].children[i].name,
            exDetailsTree.children[idx].children[i].children[j].name,
         ),
      );
   }

   list.add(makePostSectionTitle(ctx, g.param.postRefSectionTitle));

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

   DateFormat df = Intl(g.param.localeName).date().add_yMEd().add_jm();
   values.add(df.format(date));

   for (int i = 0; i < values.length; ++i)
      list.add(makePostRowElem(ctx, g.param.descList[i], values[i]));

   return list;
}

List<Widget> makePostInDetails(
   BuildContext ctx,
   Post post,
   Node inDetailsTree)
{
   List<Widget> all = List<Widget>();

   final int i = post.getProductDetailIdx();
   final int l1 = inDetailsTree.children[i].children.length;
   for (int j = 0; j < l1; ++j) {
      List<Widget> foo = makePostInRows(
         ctx,
         inDetailsTree.children[i].children[j].children,
         post.inDetails[j],
      );

      if (foo.length != 0) {
         all.add(makePostSectionTitle(
               ctx,
               inDetailsTree.children[i].children[j].name,
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
      //color: Theme.of(ctx).colorScheme.background,
      color: Colors.white,
      margin: EdgeInsets.all(0.0),
      child: Padding(
         child: col,
         padding: EdgeInsets.only(
            top: 8.0,
            bottom: 8.0,
            left: 8.0,
         ),
      ),
      shape: RoundedRectangleBorder(
         borderRadius: BorderRadius.all(
            Radius.circular(0.0)
         ),
      ),
   );
}

Widget makePostDescription(BuildContext ctx, String desc)
{
   final double width = MediaQuery.of(ctx).size.width;

   return ConstrainedBox(
      constraints: BoxConstraints(
         maxWidth: stl.infoWidthFactor * width,
         minWidth: stl.infoWidthFactor * width,
      ),
      child: Text(
         desc,
         overflow: TextOverflow.clip,
         style: stl.textField,
      ),
   );
}

List<Widget> assemblePostRows(
   BuildContext ctx,
   Post post,
   List<MenuItem> menu,
   Node exDetailsTree,
   Node inDetailsTree,
) {
   List<Widget> all = List<Widget>();
   all.addAll(makePostValues(ctx, post));
   all.addAll(makeMenuInfo(ctx, post, menu));
   all.addAll(makePostExDetails(ctx, post, exDetailsTree));
   all.addAll(makePostInDetails(ctx, post, inDetailsTree));
   if (post.description.isNotEmpty) {
      all.add(makePostSectionTitle(ctx, g.param.postDescTitle));
      all.add(makePostDescription(ctx, post.description));
   }

   return all;
}

String makePostSummaryStr(List<MenuItem> menu, Post post)
{
   assert(menu.length == 2);

   final List<String> names0 = loadNames(
      menu[0].root.first,
      post.channel[0][0],
   );

   final int l0 = names0.length;
   assert(l0 >= 2);

   final List<String> names1 = loadNames(
      menu[1].root.first,
      post.channel[1][0],
   );

   final int l1 = names1.length;
   assert(names1.length >= 2);

   final String a = names1[l1 - 2];
   final String b = names1[l1 - 1];

   final String c = names0[l0 - 2];
   final String d = names0[l0 - 1];

   return '$a - $b, $c - $d';
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
   Widget leading,
   int postId)
{
   return Theme(
      data: makeExpTileThemeData(ctx),
      child: ExpansionTile(
          backgroundColor: Theme.of(ctx).colorScheme.primary,
          leading: leading,
          //key: GlobalKey(),
          //key: PageStorageKey<int>(postId),
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

Widget makeIgmInfoWidget(BuildContext ctx, String str)
{
   return Padding(
      child: Text(str,
         style: Theme.of(ctx).textTheme.headline.copyWith(
            color: Theme.of(ctx).colorScheme.onPrimary,
         ),
      ),
      padding: const EdgeInsets.all(stl.imgInfoWidgetPadding),
   );
}

Widget makeAddOrRemoveWidget(
   Function add,
   IconData id,
   Color color)
{
   return Padding(
      padding: const EdgeInsets.all(stl.imgInfoWidgetPadding),
      child: IconButton(
         onPressed: add,
         icon: Icon(id,
            color: color,
            size: 30.0,
         ),
      )
   );
}

Widget makeImgTextPlaceholder(final String str)
{
   return Text(str,
      overflow: TextOverflow.clip,
      style: TextStyle(
         color: stl.colorScheme.background,
         fontSize: stl.tt.title.fontSize,
      ),
   );
}

double makeImgWidth(BuildContext ctx)
{
   return MediaQuery.of(ctx).size.width * cts.imgWidthFactor;
}

double makeImgHeight(BuildContext ctx)
{
   final double width = MediaQuery.of(ctx).size.width * cts.imgWidthFactor;
   return width * cts.imgHeightFactor;
}

Widget makeNewPostImpl(
   BuildContext ctx,
   Widget card,
   Function onPressed,
   Icon icon,
   Post post,
   Function onAddPhoto,
   List<File> imgFiles,
   Function onExpandImg)
{
   IconButton inapropriate = IconButton(
      iconSize: stl.newPostIconSize,
      padding: EdgeInsets.all(0.0),
      onPressed: () {onPressed(2);},
      //color: stl.colorScheme.primary,
      icon: Icon(
         Icons.report,
         color: Colors.red[400],
      ),
   );

   IconButton icon1 = IconButton(
      iconSize: stl.newPostIconSize,
      padding: EdgeInsets.all(0.0),
      onPressed: () {onPressed(0);},
      icon: Icon(
         Icons.cancel,
         color: Colors.grey,
      ),
   );

   IconButton icon2 = IconButton(
      iconSize: stl.newPostIconSize,
      padding: EdgeInsets.all(0.0),
      icon: icon,
      onPressed: () {onPressed(1);},
      color: Theme.of(ctx).colorScheme.primary,
   );

   Row row = Row(children: <Widget>
   [ Expanded(child: inapropriate)
   , Expanded(child: icon1)
   , Expanded(child: icon2)
   ]);

   Card c4 = Card(
      child: row,
      color: Theme.of(ctx).colorScheme.primary,
      margin: EdgeInsets.all(stl.postInnerMargin),
      elevation: 0.0,
   );

   Widget imgLv;
   if (post.images.isNotEmpty) {
      Widget tmp = makeImgListView2(
         makeImgWidth(ctx),
         makeImgHeight(ctx),
         post,
         onExpandImg,
         BoxFit.cover,
      );

      imgLv = Container(
         //margin: const EdgeInsets.only(top: 10.0),
         margin: const EdgeInsets.all(0.0),
         child: tmp,
      );
   } else if (imgFiles.isNotEmpty) {
      imgLv = makeImgListView(
         makeImgWidth(ctx),
         makeImgHeight(ctx),
         onAddPhoto,
         imgFiles,
         post,
      );
   } else {
      Widget w = makeImgTextPlaceholder(g.param.addImgMsg);
      imgLv = makeImgPlaceholder(
         makeImgWidth(ctx),
         makeImgHeight(ctx),
         w,
      );
   }

   List<Widget> row1List = List<Widget>();
   row1List.add(Spacer());

   // The add a photo buttom should appear only when this function is
   // called on the new posts screen. We determine that in the
   // following way.
   final bool isNewPost = post.images.isEmpty;

   if (isNewPost && (imgFiles.length < cts.maxImgsPerPost)) {
      Widget addImgWidget = makeAddOrRemoveWidget(
         () {onAddPhoto(ctx, -1);},
         Icons.add_a_photo,
         stl.colorScheme.primary,
      );

      row1List.add(addImgWidget);
   }

   Row row1 = Row(children: row1List);

   Row rowMiddle = Row(children: <Widget>
   [ Icon(Icons.keyboard_arrow_left, color: stl.colorScheme.secondary)
   , Spacer()
   , Icon(Icons.keyboard_arrow_right, color: stl.colorScheme.secondary)
   ]);

   Widget priceText = makeIgmInfoWidget(ctx, makeRangeStr(post, 0));
   Widget kmText = makeIgmInfoWidget(ctx, makeRangeStr(post, 2));

   Row row2 = Row(
      children: <Widget>[priceText, Spacer(), kmText]
   );

   Column col = Column(
      children: <Widget>[row1, Spacer(), rowMiddle,  Spacer(), row2]
   );

   SizedBox sb2 = SizedBox(
      width: makeImgWidth(ctx),
      height: makeImgHeight(ctx),
      child: Center(child: col),
   );

   Widget images = Stack(children: <Widget>[imgLv, sb2]);

   Widget cc = putPostOnFinalCard(ctx, <Widget>[card, images, c4]);

   return Padding(
      child: cc,
      padding: EdgeInsets.only(
         top: 10.0,
         right: 0.0,
         bottom: 10.0,
         left: 0.0,
      ),
   );
}

Widget makeNewPost(
   BuildContext ctx,
   Post post,
   Function onPostSelection,
   List<MenuItem> menu,
   Node exDetailsTree,
   Node inDetailsTree,
   Icon ic,
   String snackbarStr,
   Function onAddPhoto,
   List<File> imgFiles,
   Function onExpandImg)
{
   Widget title = Text(
      makePostSummaryStr(menu, post),
      maxLines: 1,
      overflow: TextOverflow.clip,
   );

   List<Widget> rows = assemblePostRows(
      ctx,
      post,
      menu,
      exDetailsTree,
      inDetailsTree,
   );

   Widget infoExpansion = makePostInfoExpansion(
      ctx,
      putPostElemOnCard(ctx, rows),
      title,
      null,
      post.id,
   );

   Widget w = makeNewPostImpl(
      ctx,
      infoExpansion,
      onPostSelection,
      ic,
      post,
      onAddPhoto,
      imgFiles,
      onExpandImg,
   );

   return w;
   //return Dismissible(
   //   key: GlobalKey(),
   //   onDismissed: (direction) {
   //      onPostSelection(0);
   //      Scaffold.of(ctx).showSnackBar(
   //            SnackBar(content: Text(snackbarStr))
   //      );
   //   },

   //   background: Container(color: Colors.red),
   //   child: w,
   //);
}

Widget makeEmptyScreenWidget()
{
   return Center(
      child: Text(g.param.appName,
         style: TextStyle(
            color: Colors.grey,
            fontSize: 30.0,
         ),
      ),
   );
}

Widget makeNewPostLv(
   BuildContext ctx,
   List<Post> posts,
   Function onPostSelection,
   List<MenuItem> menu,
   Node exDetailsTree,
   Node inDetailsTree,
   int nNewPosts,
   Function onExpandImg,
) {
   final int l = posts.length - nNewPosts;
   if (l == 0)
      return makeEmptyScreenWidget();

   // No controller should be assigned to this listview. This will
   // break the automatic hiding of the tabbar
   return ListView.builder(
      //key: PageStorageKey<String>('aaaaaaa'),
      padding: const EdgeInsets.all(0.0),
      itemCount: l,
      itemBuilder: (BuildContext ctx, int i)
      {
         final int j = l - i - 1;
         return makeNewPost(
            ctx,
            posts[j],
            (int fav) {onPostSelection(ctx, j, fav);},
            menu,
            exDetailsTree,
            inDetailsTree,
            stl.favIcon,
            g.param.dissmissedPost,
            (BuildContext dummy, int i) {print('Error: Please fix aaab');},
            List<File>(),
            (int k) {onExpandImg(j, k);},
         );
      },
   );
}

ListView makeNewPostMenuListView(
   BuildContext ctx,
   Node o,
   Function onLeafPressed,
   Function onNodePressed)
{
   return ListView.builder(
      itemCount: o.children.length,
      itemBuilder: (BuildContext ctx, int i)
      {
         Node child = o.children[i];

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
               title: Text(child.name, style: stl.ltTitle),
               dense: true,
               onTap: () { onLeafPressed(i);},
               enabled: true,
               onLongPress: (){},
            );
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
               title: Text(o.children[i].name, style: stl.ltTitle),
               dense: true,
               subtitle: Text(
                  o.children[i].getChildrenNames(),
                  maxLines: 2,
                  overflow: TextOverflow.clip,
                  style: stl.ltSubtitle,
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
Widget chooseMsgStatusIcon(int status)
{
   final double s = 20.0;

   Icon icon = Icon(Icons.clear, color: Colors.grey, size: s);

   if (status == 3) {
      icon = Icon(Icons.done_all, color: Colors.green, size: s);
   } else if (status == 2) {
      icon = Icon(Icons.done_all, color: Colors.grey, size: s);
   } else if (status == 1) {
      icon = Icon(Icons.check, color: Colors.grey, size: s);
   }

   return Padding(
      child: icon,
      padding: const EdgeInsets.symmetric(horizontal: 2.0));
}

class ChatPresenceSubtitle {
   String subtitle;
   Color color;
   ChatPresenceSubtitle({this.subtitle = '', this.color = Colors.white});
}

ChatPresenceSubtitle makeLTPresenceSubtitle(
   final ChatMetadata cm,
   String str,
   Color color,
) {
   final int now = DateTime.now().millisecondsSinceEpoch;
   final int last = cm.lastPresenceReceived + cts.presenceInterval;

   final bool moreRecent =
      cm.lastPresenceReceived > cm.lastChatItem.date;

   if (moreRecent && now < last) {
      return ChatPresenceSubtitle(
         subtitle: g.param.typing,
         color: stl.colorScheme.secondary,
      );
   }

   return ChatPresenceSubtitle(
      subtitle: str,
      color: color,
   );
}

Widget makeChatTileSubtitle(BuildContext ctx, final ChatMetadata ch)
{
   String str = ch.lastChatItem.msg;

   // Chats that are empty have always prevalence
   if (str.isEmpty) {
      return Text(
         g.param.msgOnEmptyChat,
         maxLines: 1,
         overflow: TextOverflow.clip,
         style: Theme.of(ctx).textTheme.subtitle.copyWith(
            color: Theme.of(ctx).colorScheme.secondary,
            //fontWeight: FontWeight.w500,
            fontStyle: FontStyle.italic,
         ),
      );
   }

   ChatPresenceSubtitle cps = makeLTPresenceSubtitle(
      ch,
      str,
      Colors.grey,
   );

   if (ch.nUnreadMsgs > 0 || !ch.lastChatItem.isFromThisApp())
      return Text(
         cps.subtitle,
         style: Theme.of(ctx).textTheme.subtitle.copyWith(
            color: cps.color,
         ),
         maxLines: 1,
         overflow: TextOverflow.clip
      );

   return Row(children: <Widget>
   [ chooseMsgStatusIcon(ch.lastChatItem.status)
   , Expanded(
        child: Text(cps.subtitle,
           maxLines: 1,
           overflow: TextOverflow.clip,
           style: Theme.of(ctx).textTheme.subtitle.copyWith(
              color: cps.color,
           ),
        ),
     ),
   ]);
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
   ChatMetadata chat,
   int now,
   Function onLeadingPressed,
   Function onLongPress,
   Function onPressed,
   bool isFwdChatMsgs,
   String avatar,
) {
   Color bgColor;
   if (chat.isLongPressed) {
      bgColor = stl.chatLongPressendColor;
   } else {
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
         chat.isLongPressed,
         avatar,
         selectColor(int.parse(chat.peer)),
         onLeadingPressed,
      ),
      title: Text(
         chat.getChatDisplayName(),
         maxLines: 1,
         overflow: TextOverflow.clip,
         style: stl.ltTitle,
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
   List<ChatMetadata> ch,
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

   int nUnreadChats = 0;
   for (int i = 0; i < list.length; ++i) {
      final int n = ch[i].nUnreadMsgs;
      if (n > 0)
         ++nUnreadChats;

      Card card = makeChatListTile(
         ctx,
         ch[i],
         now,
         (){onLeadingPressed(ctx, post.id, i);},
         () { onLongPressed(i); },
         () { onPressed(i); },
         isFwdChatMsgs,
         isFav ? post.avatar : ch[i].avatar,
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

  if (isFav) {
     return Padding(
        child: Column(children: list),
        padding: EdgeInsets.only(top: stl.chatTilePadding),
     );
  }

  Widget title;
   if (nUnreadChats == 0) {
      title = Text('${ch.length} ${g.param.numberOfChatsSuffix}');
   } else {
      title = makeExpTileTitle(
         ctx,
         '${ch.length} ${g.param.numberOfChatsSuffix}',
         '$nUnreadChats ${g.param.numberOfUnreadChatsSuffix}',
         ', ',
         false,
      );
   }

   IconData pinIcon =
      post.pinDate == 0 ? Icons.place : Icons.pin_drop;

   bool expState = (ch.length < 6 && ch.length > 0)
                       || nUnreadChats != 0;

   // I have observed that if the post has no chats and a chat
   // arrives, the chat expansion will continue collapsed independent
   // whether expState is true or not. This is undesireble, so I will
   // add a special case to handle it below.
   if (nUnreadChats == 0)
      expState = true;

   return Theme(
      data: makeExpTileThemeData(ctx),
      child: ExpansionTile(
         backgroundColor: Theme.of(ctx).colorScheme.primary,
         initiallyExpanded: expState,
         leading: IconButton(icon: Icon(pinIcon), onPressed: onPinPost),
         //key: GlobalKey(),
         //key: PageStorageKey<int>(post.id),
         title: title,
         children: list,
      ),
   );
}

Widget putPostOnFinalCard(
   BuildContext ctx,
   List<Widget> wlist)
{
   return Card(
      elevation: 0.0,
      color: Theme.of(ctx).colorScheme.primary,
      child: Column(children: wlist),
      shape: RoundedRectangleBorder(
         borderRadius: BorderRadius.all(
            Radius.circular(stl.cornerRadius)
         ),
      ),
      margin: const EdgeInsets.only(
         left: stl.postMargin,
         right: stl.postMargin,
         bottom: stl.postCardBottomMargin,
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
   Node exDetailsTree,
   Node inDetailsTree,
   Function onExpandImg,
) {
   if (posts.length == 0)
      return makeEmptyScreenWidget();

   // No controller should be assigned to this listview. This will
   // break the automatic hiding of the tabbar
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
            makePostSummaryStr(menu, posts[i]),
            maxLines: 1,
            overflow: TextOverflow.clip,
         );

         List<Widget> foo = List<Widget>();

         // If the post contains no images, which should not happen,
         // we provide no expand image button.
         Function onExpandImg2 = (int j) {onExpandImg(i, j);};
         if (posts[i].images.isEmpty)
            onExpandImg2 = (int j){print('Error: post.images is empty.');};

         foo.add(makeImgListView2(
               makeImgWidth(ctx),
               makeImgHeight(ctx),
               posts[i],
               onExpandImg2,
               BoxFit.cover,
            ),
         );

         List<Widget> rows = assemblePostRows(
            ctx,
            posts[i],
            menu,
            exDetailsTree,
            inDetailsTree,
         );

         foo.addAll(rows);

         Widget infoExpansion = makePostInfoExpansion(
            ctx,
            putPostElemOnCard(ctx, foo),
            title,
            leading,
            posts[i].id
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

         Widget w = putPostOnFinalCard(ctx, expansions);

         return w;
      },
   );
}

//_____________________________________________________________________

class DialogWithOp extends StatefulWidget {
   DialogWithOp(
      this.getValueFunc,
      this.setValueFunc,
      this.onPostSelection,
      this.title,
      this.body,
   );

   final Function getValueFunc;
   final Function setValueFunc;
   final Function onPostSelection;
   final String title;
   final String body;

   @override
   DialogWithOpState createState() => DialogWithOpState();
}

class DialogWithOpState extends State<DialogWithOp> {
   Function _getValueFunc;
   Function _setValueFunc;
   Function _onPostSelection;
   String _title;
   String _body;
   
   @override
   void initState()
   {
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
         child: Text(g.param.ok,
            style: TextStyle(color: Colors.blue, fontSize: 16.0),
         ),
         onPressed: () async
         {
            await _onPostSelection();
            Navigator.of(ctx).pop();
         },
      );

      final SimpleDialogOption cancel = SimpleDialogOption(
         child: Text(g.param.cancel,
            style: TextStyle(color: Colors.blue, fontSize: 16.0),
         ),
         onPressed: () { Navigator.of(ctx).pop(); },
      );

      List<SimpleDialogOption> actions = List<SimpleDialogOption>(2);
      actions[0] = cancel;
      actions[1] = ok;

      //Row row = Row(children:
      //   <Widget> [Icon(Icons.check_circle_outline, color: Colors.red)],
      //);

      CheckboxListTile tile = CheckboxListTile(
         title: Text(g.param.doNotShowAgain),
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
                  , padding: EdgeInsets.only(left: 70.0))
         ]);
   }
}

//_____________________________________________________________________

class Occase extends StatefulWidget {
  Occase();

  @override
  OccaseState createState() => OccaseState();
}

class OccaseState extends State<Occase>
   with SingleTickerProviderStateMixin, WidgetsBindingObserver
{
   Config _cfg = Config();

   // The trees holding the locations and products trees.
   List<MenuItem> _trees = List<MenuItem>();

   // The ex details tree root node.
   Node _exDetailsRoot;

   // The in details tree root node.
   Node _inDetailsRoot;

   // Will be set to true if the user scrolls up a chat screen so that
   // the jump down button can be used
   bool _showChatJumpDownButton = true;

   // Set to true when the user wants to change his email or nick or on
   // the first time the user opens the app.
   bool _goToRegScreen = false;

   // Set to true when the user wants to change his notification
   // settings.
   bool _goToNtfScreen = false;

   // The temporary variable used to store the post the user sends or
   // the post the current chat screen belongs to, if any.
   Post _post;

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

   // Posts sent to the server that haven't been acked yet. At the
   // moment this queue will contain only one element. It is needed if
   // to handle the case where we go offline between a publish and a
   // publish_ack.
   Queue<Post> _outPostsQueue = Queue<Post>();

   // Stores chat messages that cannot be lost in case the connection
   // to the server is lost. 
   Queue<AppMsgQueueElem> _appMsgQueue = Queue<AppMsgQueueElem>();

   // A flag that is set to true when the floating button (new post)
   // is clicked. It must be carefully set to false when that screen
   // are left.
   bool _newPostPressed = false;

   // This error code assumes the following values
   // -1: No error, nothing to do.
   //  0: There was an error uploading the images.
   //  1: The post was sent to the server.
   int _newPostErrorCode = -1;

   // Similar to _newPostPressed but for the filter screen.
   bool _newFiltersPressed = false;

   // The index of the tab we are currently in in the *new
   // post* or *Filters* screen. For example 0 for the localization
   // menu, 1 for the models menu etc.
   int _botBarIdx = 0;

   // The current chat, if any.
   ChatMetadata _chat;

   // The last post id seen by the user.
   int _nNewPosts = 0;

   // Whether or not to show the dialog informing the user what
   // happens to selected or deleted posts in the posts screen.
   List<bool> _dialogPrefs = List<bool>(3);

   // This list will store the posts in _fav or _own chat screens that
   // have been long pressed by the user. However, once one post is
   // long pressed to select the others is enough to perform a simple
   // click.
   List<Coord> _lpChats = List<Coord>();

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

   // This variable is set to the last time the app was disconnected
   // from the server, a value of -1 means we still did not get
   // disconnected since startup..
   int _lastDisconnect = -1;

   // Used in the final new post screen to store the files while the
   // user chooses the images.
   List<File> _imgFiles = List<File>();

   Timer _filenamesTimer = Timer(Duration(seconds: 0), (){});

   // These indexes will be set to values different from -1 when the
   // user clics on an image to expand it.
   int _expPostIdx = -1;
   int _expImgIdx = -1;

   // Used to cache to fcmToken.
   String _fcmToken = '';

   final FirebaseMessaging _firebaseMessaging = FirebaseMessaging();

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
      _lastDisconnect = -1;
      WidgetsBinding.instance.addObserver(this);

      _firebaseMessaging.configure(
         onMessage: (Map<String, dynamic> message) async {
           print("onMessage: $message");
         },
         onLaunch: (Map<String, dynamic> message) async {
           print("onLaunch: $message");
         },
         onResume: (Map<String, dynamic> message) async {
           print("onResume: $message");
         },
      );

      _firebaseMessaging.getToken().then((String token) {
         if (_fcmToken != null)
            _fcmToken = token;

         print('Token: $token');
      });
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
      // We should not try to reconnect if disconnection happened just
      // a couples of seconds ago. This is needed because it may
      // haven't been a clean disconnect with a close websocket frame.
      // The server will wait until the pong answer times out.  To
      // solve this we compare _lastDisconnect with the current time.

      bool doConnect = false;
      if (_lastDisconnect != -1) {
         final int now = DateTime.now().millisecondsSinceEpoch;
         final int interval = now - _lastDisconnect;
         doConnect = interval > cts.pongTimeout;
      }

      if (state == AppLifecycleState.resumed && doConnect) {
         print('Trying to reconnect.');
         _stablishNewConnection(_fcmToken);
      }
   }

   bool _isOnOwn()
   {
      return _tabCtrl.index == 0;
   }

   bool _isOnPosts()
   {
      return _tabCtrl.index == 1;
   }

   bool _isOnFav()
   {
      return _tabCtrl.index == 2;
   }

   bool _isOnFavChat()
   {
      return _isOnFav() && _post != null && _chat != null;
   }

   bool _isOnOwnChat()
   {
      return _isOnOwn() && _post != null && _chat != null;
   }

   bool _onTabSwitch()
   {
      return _tabCtrl.indexIsChanging;
   }

   List<double> _getNewMsgsOpacities()
   {
      List<double> opacities = List<double>(3);

      double onFocusOp = 1.0;
      double notOnFocusOp = 0.7;

      opacities[0] = notOnFocusOp;
      if (_isOnOwn())
         opacities[0] = onFocusOp;

      opacities[1] = notOnFocusOp;
      if (_isOnPosts())
         opacities[1] = onFocusOp;

      opacities[2] = notOnFocusOp;
      if (_isOnFav())
         opacities[2] = onFocusOp;

      return opacities;
   }

   OccaseState()
   {
      _newPostPressed = false;
      _newFiltersPressed = false;
      _botBarIdx = 0;

      getApplicationDocumentsDirectory().then((Directory docDir) async
      {
         g.docDir = docDir.path;
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
      _trees = await readMenuItemsFromAsset();

      List<MenuElem> elems = List<MenuElem>();
      for (int i = 0; i < _trees.length; ++i) {
         elems.addAll(makeMenuElems(
               _trees[i].root.first,
               i,
               1000, // Large enough to include nodes at all depths.
            ),
         );
      }

      Batch batch = db.batch();

      batch.insert(
         'config',
         configToMap(_cfg),
         conflictAlgorithm: ConflictAlgorithm.replace,
      );

      elems.forEach((MenuElem me) {
         batch.insert('menu', menuElemToMap(me));
      });

      await batch.commit(noResult: true, continueOnError: true);

      _goToRegScreen = true;
   }

   void sendOfflinePosts()
   {
      if (_outPostsQueue.isEmpty)
         return;
       
      final String payload = makePostPayload(_outPostsQueue.first);
      channel.sink.add(payload);
   }

   Future<void> _load(final String docDir) async
   {
      try {
         final String text =
            await rootBundle.loadString('data/parameters.txt');
         g.param = Parameters.fromJson(jsonDecode(text));

         await initializeDateFormatting(g.param.localeName, null);

         // Warining: The construction of Config depends on the
         // parameters that have been load above, but where not loaded
         // by the time it was inititalized. Ideally we would remove
         // the use of global variable from withing its constructor,
         // for now I will construct it again before it is used to
         // initialize the db.
         _cfg = Config();
         _db = await openDatabase(
            p.join(await getDatabasesPath(), 'main.db'),
            readOnly: false,
            onCreate: _onCreateDb,
            version: 1);

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
         if (configs.isNotEmpty)
            _cfg = configs.first;
      } catch (e) {
         print(e);
      }

      _goToRegScreen = _cfg.nick.isEmpty;

      _dialogPrefs[0] = _cfg.showDialogOnDelPost == 'yes';
      _dialogPrefs[1] = _cfg.showDialogOnSelectPost == 'yes';
      _dialogPrefs[2] = _cfg.showDialogOnReportPost == 'yes';

      if (_trees.isEmpty)
         _trees = loadMenuItems(
            await loadMenu(_db),
            g.param.filterDepths,
         );

      try {
         final List<Post> posts =
            await loadPosts(_db, g.param.rangesMinMax);
         for (Post p in posts) {
            if (p.status == 0) {
               _ownPosts.add(p);
               for (Post o in _ownPosts)
                  o.chats = await loadChatMetadata(_db, o.id);
            } else if (p.status == 1) {
               _posts.add(p);
            } else if (p.status == 2) {
               _favPosts.add(p);
               for (Post o in _favPosts)
                  o.chats = await loadChatMetadata(_db, o.id);
            } else if (p.status == 3) {
               _outPostsQueue.add(p);
            } else {
               assert(false);
            }
         }

         _ownPosts.sort(compPosts);
         _favPosts.sort(compPosts);
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

      _stablishNewConnection(_fcmToken);

      print('Last post id: ${_cfg.lastPostId}.');
      print('Last post id seen: ${_cfg.lastSeenPostId}.');
      print('Login: ${_cfg.appId}:${_cfg.appPwd}');
      setState(() { });
   }

   void _stablishNewConnection(String fcmToken)
   {
      channel = IOWebSocketChannel.connect(cts.dbHost);
      channel.stream.listen(
         _onWSData,
         onError: _onWSError,
         onDone: _onWSDone,
      );

      final String cmd = makeConnCmd(
         _cfg.appId,
         _cfg.appPwd,
         fcmToken,
         _cfg.notifications.getFlag(),
      );

      channel.sink.add(cmd);
   }

   Future<void> _setDialogPref(final int i, bool v) async
   {
      _dialogPrefs[i] = v;

      final String str = v ? 'yes' : 'no';

      if (i == 0)
         await _db.execute(sql.updateShowDialogOnDelPost, [str]);
      else if (i == 1)
         await _db.execute(sql.updateShowDialogOnSelectPost, [str]);
      else 
         await _db.execute(sql.updateShowDialogOnReportPost, [str]);
   }

   Future<void>
   _alertUserOnPressed(BuildContext ctx, int i, int fav) async
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
               () {return _dialogPrefs[fav];},
               (bool v) async {await _setDialogPref(fav, v);},
               () async {await _onPostSelection(i, fav);},
               g.param.dialogTitles[fav],
               g.param.dialogBodies[fav]);
            
         },
      );
   }

   Future<void> _clearPosts() async
   {
      await _db.execute(sql.clearPosts, [1]);

      setState((){
         _posts = List<Post>();
         _nNewPosts = 0;
      });
   }

   void _clearPostsDialog(BuildContext ctx)
   {
      _showSimpleDialog(
         ctx,
         () async { await _clearPosts(); },
         g.param.clearPostsTitle,
         Text(g.param.clearPostsContent),
      );
   }

   // Used to either add or remove a photo from the new post.
   // i = -1 ==> add
   // i != -1 ==> remove, in this case i is the index to remove.
   Future<void> _onAddPhoto(BuildContext ctx, int i) async
   {
      try {
         // It looks like we do not need to show any dialog here to
         // inform the maximum number of photos has been reached.
         if (i == -1) {
            File img = await ImagePicker.pickImage(
               source: ImageSource.gallery,
               maxWidth: 2 * makeImgWidth(ctx),
               maxHeight: 2 * makeImgHeight(ctx),
               //imageQuality: cts.imgQuality,
            );

            if (img == null)
               return;

            setState((){_imgFiles.add(img); });
         } else {
            setState((){_imgFiles.removeAt(i); });
         }
      } catch (e) {
         print(e);
      }
   }

   // i = index in _posts, _favPosts, _own_posts.
   // j = image index in the post.
   void _onExpandImg(int i, int j)
   {
      //print('Expand image clicked with $i $j.');

      //_nNewPosts

      setState((){
         _expPostIdx = i;
         _expImgIdx = j;
      });
   }

   void _onRangeValueChanged(int i, double v)
   {
      setState((){_post.rangeValues[i] = v.round();});
   }

   Future<void> _onRangeChanged(int i, RangeValues rv) async
   {
      setState(()
      {
         _cfg.ranges[2 * i + 0] = rv.start.round();
         _cfg.ranges[2 * i + 1] = rv.end.round();
      });

      await _db.execute(sql.updateRanges, [_cfg.ranges.join(' ')]);
   }

   Future<void> _onPostSelection(int i, int fav) async
   {
      assert(_isOnPosts());

      if (fav == 1) {
         // We have to prevent the user from adding a chat twice. This can
         // happen when he makes a new search, since in that case the
         // lastPostId will be updated to 0.
         final int k = _favPosts.indexWhere((e)
            { return e.id == _posts[i].id; });

         if (k == -1) {
            _posts[i].status = 2;

            final int j = _posts[i].addChat(
               _posts[i].from,
               _posts[i].nick,
               _posts[i].avatar,
            );

            Batch batch = _db.batch();

            batch.rawInsert(
               sql.insertChatStOnPost,
               makeChatMetadataSql(_posts[i].chats[j], _posts[i].id),
            );

            batch.execute(sql.updatePostStatus, [2, _posts[i].id]);

            await batch.commit(noResult: true, continueOnError: true);

            _favPosts.add(_posts[i]);
            _favPosts.sort(compPosts);
         }

      } else {
         await _db.execute(sql.delPostWithId, [_posts[i].id]);
         // TODO: Send command to server to report if fav = 2.
      }

      _posts.removeAt(i);

      setState(() { });
   }

   void _onNewPost()
   {
      _newPostPressed = true;
      _post = Post(rangesMinMax: g.param.rangesMinMax);
      _post.images = List<String>(); // TODO: remove this later.
      _trees[0].restoreMenuStack();
      _trees[1].restoreMenuStack();
      _botBarIdx = 0;
      setState(() { });
   }

   Future<void> _onShowNewPosts() async
   {
      // The number of posts that will be shown to the user when he
      // clicks the download button. It is at most maxPostsOnDownload.
      // If it is less than that number we show all.
      final int n = _nNewPosts >= cts.maxPostsOnDownload
            ? cts.maxPostsOnDownload : _nNewPosts;

      _nNewPosts -= n;

      final int l = _posts.length;

      assert(l >= _nNewPosts);

      // The index of the last post already shown to the user.
      final int idx = l == _nNewPosts ? 0 : l - _nNewPosts - 1;

      if (_posts.isEmpty) {
         print('===> This should not happen');
      } else {
         await _db.execute(sql.updateLastSeenPostId, [_posts[idx].id]);
      }

      setState(() { });
   }

   bool _onWillPopMenu(
      final List<MenuItem> menu,
      int leaveIdx,
   ) {
      // We may want to  split this function in two: One for the
      // filters and one for the new post screen.
      if (_botBarIdx >= menu.length) {
         --_botBarIdx;
         setState(() { });
         return false;
      }

      if (menu[_botBarIdx].root.length == 1) {
         if (_botBarIdx <= leaveIdx){
            _newPostPressed = false;
            _newFiltersPressed = false;
         } else {
            --_botBarIdx;
         }

         setState(() { });
         return false;
      }

      menu[_botBarIdx].root.removeLast();
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
               isRedirected: 1,
               msg: c2.chat.msgs[c2.msgIdx].msg,
               date: now,
            );
            if (_isOnFav()) {
               print('1 Setting');
               await _onSendChatImpl(
                  _favPosts, c1.post.id, c1.chat.peer, ci);
            } else {
               await _onSendChatImpl(
                  _ownPosts, c1.post.id, c1.chat.peer, ci);
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
      await _db.rawUpdate(
         sql.updateNUnreadMsgs,
         [0, _post.id, _chat.peer],
      );

      _showChatJumpDownButton = false;
      _dragedIdx = -1;
      _chat.nUnreadMsgs = 0;
      _chat.divisorUnreadMsgs = 0;
      _chat.divisorUnreadMsgsIdx = -1;
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

   void _onCancelFwdLpChat()
   {
      _dragedIdx = -1;
      setState(() { });
   }

   Future<void> _onSendChat() async
   {
      final int now = DateTime.now().millisecondsSinceEpoch;
      List<Post> posts = _ownPosts;
      if (_isOnFav())
         posts = _favPosts;

      _chat.nUnreadMsgs = 0;
      await _onSendChatImpl(
         posts,
         _post.id,
         _chat.peer,
         ChatItem(
            isRedirected: 0,
            msg: _txtCtrl.text,
            date: now,
            refersTo: _dragedIdx,
            status: 0,
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

   // Called when the user changes text in the chat text field.
   void _onWritingChat(String v)
   {
      assert(_chat != null);
      assert(_post != null);

      // When the chat input text field was empty and the user types
      // in some text, we have to call set state to enable the send
      // button. If the user erases all the text we have to disable
      // the button. To simplify the implementation I will call
      // setState on every change, since this does not significantly
      // decreases performance.
      setState((){});

      final int now = DateTime.now().millisecondsSinceEpoch;
      final int last = _chat.lastPresenceSent + cts.presenceInterval;

      if (now < last)
         return;

      _chat.lastPresenceSent = now;

      var subCmd = {
         'cmd': 'presence',
         'to': _chat.peer,
         'type': 'writing',
         'post_id': _post.id,
      };

      final String payload = jsonEncode(subCmd);
      print(payload);
      channel.sink.add(payload);
   }

   void _chatScrollListener()
   {
      final double offset = _chatScrollCtrl.offset;
      final double max = _chatScrollCtrl.position.maxScrollExtent;

      final double tol = 40.0;

      final bool old = _showChatJumpDownButton;

      if (_showChatJumpDownButton && !(offset < max))
         setState(() {_showChatJumpDownButton = false;});

      if (!_showChatJumpDownButton && (offset < (max - tol)))
         setState(() {_showChatJumpDownButton = true;});

      if (!old && _showChatJumpDownButton)
         _chat.nUnreadMsgs = 0;
   }

   void _onFwdChatMsg()
   {
      assert(_lpChatMsgs.isNotEmpty);

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
      if (_botBarIdx < _trees.length)
         _trees[_botBarIdx].restoreMenuStack();

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
         _trees[_botBarIdx].restoreMenuStack();
      } while (_botBarIdx != i);

      setState(() { });
   }

   void _onPostLeafPressed(int i)
   {
      Node o = _trees[_botBarIdx].root.last.children[i];
      _trees[_botBarIdx].root.add(o);
      _onPostLeafReached();
      setState(() { });
   }

   void _onPostLeafReached()
   {
      _post.channel[_botBarIdx][0] = _trees[_botBarIdx].root.last.code;
      _trees[_botBarIdx].restoreMenuStack();
      _botBarIdx = postIndexHelper(_botBarIdx);
   }

   void _onPostNodePressed(int i)
   {
      // We continue pushing on the stack if the next screen will have
      // only one menu option.
      do {
         Node o = _trees[_botBarIdx].root.last.children[i];
         _trees[_botBarIdx].root.add(o);
         i = 0;
      } while (_trees[_botBarIdx].root.last.children.length == 1);

      final int length = _trees[_botBarIdx].root.last.children.length;

      assert(length != 1);

      if (length == 0) {
         _onPostLeafReached();
      }

      setState(() { });
   }

   void _onFilterNodePressed(int i)
   {
      Node o = _trees[_botBarIdx].root.last.children[i];
      _trees[_botBarIdx].root.add(o);

      setState(() { });
   }

   Future<void> _onFilterLeafNodePressed(int k) async
   {
      // k = 0 means the *check all fields*.
      if (k == 0) {
         Batch batch = _db.batch();
         _trees[_botBarIdx].updateLeafReachAll(batch, _botBarIdx);
         await batch.commit(noResult: true, continueOnError: true);
         setState(() { });
         return;
      }

      --k; // Accounts for the Todos index.

      Batch batch = _db.batch();
      _trees[_botBarIdx].updateLeafReach(k, batch, _botBarIdx);
      await batch.commit(noResult: true, continueOnError: true);
      setState(() { });
   }

   Future<void> _sendPost() async
   {
      _post.from = _cfg.appId;
      _post.nick = _cfg.nick;
      _post.avatar = emailToGravatarHash(_cfg.email);
      _post.status = 3;

      Post post = _post.clone();

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

   void _handlePublishAck(final int id, final int date, Batch batch)
   {
      try {
         assert(_outPostsQueue.isNotEmpty);
         Post post = _outPostsQueue.removeFirst();
         if (id == -1) {
            batch.execute(sql.delPostWithRowid, [post.dbId]);
            setState(() {_newPostErrorCode = 0;});
            return;
         }

         // When working with the simulator I noticed on my machine
         // that it replies before the post could be moved from the
         // output queue to the . In normal cases users won't
         // be so fast. But since this is my test condition, I will
         // cope with that by inserting the post in _ownPosts and only
         // after that removing from the queue.
         // TODO: I think this does not hold anymore after I
         // introduced a message queue.

         post.id = id;
         post.date = date;
         post.status = 0;
         post.pinDate = 0;
         _ownPosts.add(post);
         _ownPosts.sort(compPosts);

         batch.execute(sql.updatePostOnAck, [0, id, date, post.dbId]);

         setState(() {_newPostErrorCode = 1;});

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
         await _db.execute(sql.delPostWithId, [_favPosts[i].id]);
         _favPosts.removeAt(i);
      } else {
         await _db.execute(sql.delPostWithId, [_ownPosts[i].id]);
         final Post delPost = _ownPosts.removeAt(i);

         var msgMap = {
            'cmd': 'delete',
            'id': delPost.id,
            'to': toChannelHashCode(
               delPost.channel[1][0],
               g.param.filterDepths[1]
            ),
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

   Future<int> _uploadImgs(List<String> fnames) async
   {
      // TODO: Add timeouts.

      final int l1 = fnames.length;
      final int l2 = _imgFiles.length;

      final int l = l1 < l2 ? l1 : l2; // min

      for (int i = 0; i < l; ++i) {
         final String path = _imgFiles[i].path;
         final String basename = p.basename(path);
         final String extension = p.extension(basename);
         //String newname = fnames[i] + '.' + extension;
         final String newname = fnames[i] + '.jpg';

         print('=====> Path $path');
         print('=====> Image name $basename');
         print('=====> Image extention $extension');
         print('=====> New name $newname');
         print('=====> Http target $newname');

         //var headers = {'Accept-Encoding': 'identity'};

         var response = await http.post(newname,
            //headers: headers,
            body: await _imgFiles[i].readAsBytes(),
         );

         final int stCode = response.statusCode;
         if (stCode != 200) {
            _imgFiles = List<File>();
            return 0;
         }

         _post.images.add(newname);
      }

      _imgFiles = List<File>();
      return -1;
   }

   void _requestFilenames()
   {
      // Consider: Check if the app is online before sending.

      var cmd = {
         'cmd': 'filenames',
      };

      String payload = jsonEncode(cmd);
      print(payload);
      channel.sink.add(payload);

      _filenamesTimer = Timer(
         Duration(seconds: cts.filenamesTimeout),
         () {
            _leaveNewPostScreen();
            _newPostErrorCode = 0;
         },
      );

      setState(() { });
   }

   Future<void> _onSendNewPost(BuildContext ctx, int i) async
   {
      // When the user sends a post, we start a timer and a circular
      // progress indicator on the screen. To prevent the user from
      // interacting with the screen after clicking we use a modal
      // barrier.

      if (_filenamesTimer.isActive)
         return;

      if (i == 2) {
         // The report button is dummy in the new posts screen.
         return;
      }

      if (i == 0) {
         _showSimpleDialog(
            ctx,
            (){
               _newPostPressed = false;
               _post = null;
               setState((){});
            },
            g.param.cancelPost,
            Text(g.param.cancelPostContent),
         );
         return;
      }

      if (_imgFiles.length < cts.minImgsPerPost) {
         _showSimpleDialog(
            ctx,
            (){ },
            g.param.postMinImgs,
            Text(g.param.postMinImgsContent),
         );
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
                  _requestFilenames();
               },
            );
         },
      );
   }

   void _removePostDialog(BuildContext ctx, int i)
   {
      _showSimpleDialog(
         ctx,
         () async { await _onRemovePost(i);},
         g.param.dialogTitles[4],
         Text(g.param.dialogBodies[4]),
      );
   }

   Future<void> _onChatPressedImpl(
      List<Post> posts,
      int i,
      int j) async
   {
      if (_lpChats.isNotEmpty || _lpChatMsgs.isNotEmpty) {
         _onChatLPImpl(posts, i, j);
         setState(() { });
         return;
      }

      _showChatJumpDownButton = false;
      Post post = posts[i];
      ChatMetadata chat = posts[i].chats[j];

      if (!chat.isLoaded())
         await chat.loadMsgs(post.id, chat.peer,  _db);
      
      // These variables must be set after the chats are loaded. Otherwise
      // chat.msgs may be called on null if a message arrives. 
      _post = post;
      _chat = chat;

      if (_chat.nUnreadMsgs != 0) {
         _chat.divisorUnreadMsgsIdx =
            _chat.msgs.length - _chat.nUnreadMsgs;

         // We know the number of unread messages, now we have to generate
         // the array with the messages peer rowid.

         var msgMap =
         { 'cmd': 'message'
         , 'type': 'chat_ack_read'
         , 'to': posts[i].chats[j].peer
         , 'post_id': posts[i].id
         , 'id': -1
         , 'ack_ids': readPeerRowIdsToAck(_chat.msgs, _chat.nUnreadMsgs)
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
         await _onChatPressedImpl(_favPosts, i, j);
      else
         await _onChatPressedImpl(_ownPosts, i, j);
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

      final String avatar =
         _isOnFav() ? posts[i].avatar : posts[i].chats[j].avatar;

      final String url = cts.gravatarUrl + avatar + '.jpg';

      _showSimpleDialog(
         ctx,
         (){},
         title,
         makeNetImgBox(
            cts.onClickAvatarWidth,
            cts.onClickAvatarWidth,
            url,
            BoxFit.contain,
         ),
      );
   }

   void _onChatLPImpl(List<Post> posts, int i, int j)
   {
      final Coord tmp = Coord(post: posts[i], chat: posts[i].chats[j]);

      handleLPChats(
         _lpChats,
         toggleLPChat(posts[i].chats[j]),
         tmp, compPostIdAndPeer
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

   void _sendOfflineChatMsgs()
   {
      if (_appMsgQueue.isNotEmpty) {
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
                    tmp, compPeerAndChatIdx);

      setState((){});
   }

   Future<void> _onSendChatImpl(
      List<Post> posts,
      int postId,
      String peer,
      ChatItem ci,
   ) async {
      try {
         if (ci.msg.isEmpty)
            return;

         final int i = posts.indexWhere((e) { return e.id == postId;});
         assert(i != -1);

         // We have to make sure every unread msg is marked as read
         // before we receive any reply.
         final int j = posts[i].getChatHistIdx(peer);
         assert(j != -1);

         final int rowid = await _db.insert(
            'chats',
            makeChatItemToMap(postId, peer, ci),
            conflictAlgorithm: ConflictAlgorithm.replace,
         );

         ci.rowid = rowid;
         posts[i].chats[j].addChatItem(ci);

         await _db.rawInsert(
            sql.insertOrReplaceChatOnPost,
            makeChatMetadataSql(posts[i].chats[j], postId),
         );

         posts[i].chats.sort(compChats);
         posts.sort(compPosts);

         // At a certain point in the future, I want to stop sending
         // the user avatar on every message and deduced it from the
         // user id instead.
         var msgMap =
         { 'cmd': 'message'
         , 'type': 'chat'
         , 'is_redirected': ci.isRedirected
         , 'to': peer
         , 'msg': ci.msg
         , 'refers_to': ci.refersTo
         , 'post_id': postId
         , 'nick': _cfg.nick
         , 'id': rowid
         , 'avatar': emailToGravatarHash(_cfg.email)
         };

         final
         String payload = jsonEncode(msgMap);
         await _sendAppMsg(payload, 1);

      } catch(e) {
         print(e);
      }
   }

   void _onServerAck(Map<String, dynamic> ack, Batch batch)
   {
      try {
         assert(_appMsgQueue.first.sent);
         assert(_appMsgQueue.isNotEmpty);

         final String res = ack['result'];

         batch.rawDelete(
            sql.deleteOutChatMsg,
            [_appMsgQueue.first.rowid],
         );

         final bool isChat = _appMsgQueue.first.isChat == 1;
         _appMsgQueue.removeFirst();

         if (res == 'ok' && isChat) {
            _onChatAck(
               ack['from'],
               ack['post_id'],
               <int>[ack['ack_id']],
               1,
               batch,
            );
            setState(() { });
         }

         if (_appMsgQueue.isNotEmpty) {
            assert(!_appMsgQueue.first.sent);
            _appMsgQueue.first.sent = true;
            channel.sink.add(_appMsgQueue.first.payload);
         }
      } catch (e) {
         print(e);
      }
   }

   Future<void> _onChat(
      final Map<String, dynamic> ack,
      final String peer,
      final int postId,
      int isRedirected,
   ) async {
      final String to = ack['to'];
      if (to != _cfg.appId) {
         print("Server bug caught. Please report.");
         return;
      }

      final String msg = ack['msg'];
      final String nick = ack['nick'];
      final String avatar = ack['avatar'] ?? '';
      final int refersTo = ack['refers_to'];
      final int peerRowid = ack['id'];

      final int favIdx = _favPosts.indexWhere((e) {
         return e.id == postId;
      });

      List<Post> posts;
      if (favIdx != -1)
         posts = _favPosts;
      else
         posts = _ownPosts;

      await _onChatImpl(
         to,
         postId,
         msg,
         peer,
         nick,
         avatar,
         posts,
         isRedirected,
         refersTo,
         peerRowid,
      );
   }

   Future<void> _onChatImpl(
      String to,
      int postId,
      String msg,
      String peer,
      String nick,
      String avatar,
      List<Post> posts,
      int isRedirected,
      int refersTo,
      int peerRowid,
   ) async {
      final int i = posts.indexWhere((e) { return e.id == postId;});
      if (i == -1) {
         print('Ignoring message to postId $postId.');
         return;
      }

      final int j = posts[i].getChatHistIdxOrCreate(peer, nick, avatar);
      final int now = DateTime.now().millisecondsSinceEpoch;

      final ChatItem ci = ChatItem(
         isRedirected: isRedirected,
         msg: msg,
         date: now,
         refersTo: refersTo,
         peerRowid: peerRowid,
      );

      posts[i].chats[j].addChatItem(ci);
      if (avatar.isNotEmpty)
         posts[i].chats[j].avatar = avatar;

      // If we are in the screen having chat with the user we can ack
      // it with chat_ack_read and skip chat_ack_received.
      final bool isOnPost = _post != null && _post.id == postId; 
      final bool isOnChat = _chat != null && _chat.peer == peer; 

      ++posts[i].chats[j].nUnreadMsgs;

      String ack;
      if (isOnPost && isOnChat) {
         // We are in the chat screen with the peer.
         ack = 'chat_ack_read';

         // We are not currently showing the jump down button and can
         // animate to the bottom.
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
         ack = 'chat_ack_received';
         final int n = posts[i].chats[j].nUnreadMsgs;
         posts[i].chats[j].divisorUnreadMsgs = n;
         final int l = posts[i].chats[j].chatLength;
         posts[i].chats[j].divisorUnreadMsgsIdx = l - n;
      }

      final ChatMetadata chat = posts[i].chats[j];

      posts[i].chats.sort(compChats);
      posts.sort(compPosts);

      var msgMap =
      { 'cmd': 'message'
      , 'type': ack
      , 'to': peer
      , 'post_id': postId
      , 'id': -1
      , 'ack_ids': <int>[peerRowid]
      };

      // Generating the payload before the async operation to avoid
      // problems.
      final String payload = jsonEncode(msgMap);

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

         final List<dynamic> aaa = await batch.commit(
            noResult: false,
            continueOnError: true,
         );
      });

      await _sendAppMsg(payload, 0);
   }

   void _onPresence(Map<String, dynamic> ack)
   {
      final String peer = ack['from'];
      final int postId = ack['post_id'];

      // We have to perform the following action
      //
      // 1. Search the chat from user from
      // 2. Set the presence timestamp.
      // 3. Call setState.
      //
      // We do not know if the post belongs to the sender or receiver, so
      // we have to try both.

      final bool b = markPresence(_favPosts, peer, postId);
      if (!b)
         markPresence(_ownPosts, peer, postId);

      // A timer that is launched after presence arrives. It is used
      // to call setState so that presence e.g. typing messages are
      // not shown after some time
      Timer(
         Duration(milliseconds: cts.presenceInterval),
         () { setState((){}); },
      );

      setState((){});
   }

   void _onChatAck(
      final String from,
      final int postId,
      final List<int> rowids,
      final int status,
      Batch batch,
   ) {
      for (int rowid in rowids) {
         bool b = findAndMarkChatApp(
            _favPosts,
            from,
            postId,
            status,
            rowid,
            batch,
         );

         if (!b) {
            b = findAndMarkChatApp(
               _ownPosts,
               from,
               postId,
               status,
               rowid,
               batch,
            );
         }

         if (!b)
            print('Chat not found: from = $from, postId = $postId');
      }
   }

   void _onMessage(Map<String, dynamic> ack, Batch batch)
   {
      final String from = ack['from'];
      final String type = ack['type'];
      final int postId = ack['post_id'];

      if (type == 'chat') {
         _onChat(ack, from, postId, ack['is_redirected']);
      } else if (type == 'server_ack') {
         _onServerAck(ack, batch);
      } else if (type == 'chat_ack_received') {
         final List<int> rowids = decodeList(0, 0, ack['ack_ids']);
         _onChatAck(from, postId, rowids, 2, batch);
      } else if (type == 'chat_ack_read') {
         final List<int> rowids = decodeList(0, 0, ack['ack_ids']);
         _onChatAck(from, postId, rowids, 3, batch);
      }

      setState((){});
   }

   void _onRegisterAck(
      Map<String, dynamic> ack,
      final String msg,
      Batch batch,
   ) {
      final String res = ack["result"];
      if (res == 'fail') {
         print("register_ack: fail.");
         return;
      }

      String appId = ack["id"];
      String appPwd = ack["password"];

      if (appId == null || appPwd == null)
         return;

      _cfg.appId = ack["id"];
      _cfg.appPwd = ack["password"];

      _db.execute(sql.updateAppCredentials,
                  [_cfg.appId, _cfg.appPwd]);

      // Retrieves some posts for the newly registered user.
      _subscribeToChannels(0);
   }

   void _leaveNewPostScreen()
   {
      setState((){
         _newPostPressed = false;
         _botBarIdx = 0;
         _post = null;
      });
   }

   Future<void> _onFilenamesAck(Map<String, dynamic> ack) async
   {
      try {
         final String res = ack["result"];
         if (res == 'fail') {
            _newPostErrorCode = 0;
         } else if (_filenamesTimer.isActive) {
            _filenamesTimer.cancel();

            List<dynamic> names = ack["names"];
            List<String> fnames = List.generate(names.length, (i) {
               return names[i];
            });

            _newPostErrorCode = await _uploadImgs(fnames);

            if (_newPostErrorCode == -1)
               await _sendPost();
         }
      } catch (e) {
         print(e);
      }

      _leaveNewPostScreen();
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

      // We are loggen in and can send the channels we are
      // subscribed to to receive posts sent while we were offline.
      _subscribeToChannels(_cfg.lastPostId);

      // Sends any chat messages that may have been written while
      // the app were offline.
      _sendOfflineChatMsgs();

      // The same for posts.
      sendOfflinePosts();
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
      // When we are receiving new posts here as a result of the user
      // clicking the search buttom, we have to clear all old posts before
      // showing the new posts to the user.
      if (_cfg.lastPostId == 0) {
         batch.execute(sql.clearPosts, [1]);
         _posts.clear();
      }

      for (var item in ack['items']) {
         try {
            Post post = Post.fromJson(item, g.param.rangeDivs.length);
            post.status = 1;

            // Just in case the server sends us posts out of order I
            // will check. It should however be considered a server
            // error.
            if (post.id > _cfg.lastPostId)
               _cfg.lastPostId = post.id;

            if (post.from == _cfg.appId)
               continue;

            batch.insert('posts', postToMap(post),
               conflictAlgorithm: ConflictAlgorithm.ignore);

            _posts.add(post);
            ++_nNewPosts;
         } catch (e) {
            print("Error: Invalid post detected.");
         }
      }

      batch.execute(sql.updateLastPostId, [_cfg.lastPostId]);
      setState(() { });
   }

   void _onPublishAck(Map<String, dynamic> ack, Batch batch)
   {
      final String res = ack['result'];
      if (res == 'ok') {
         // The server sends the post date in seconds.
         _handlePublishAck(
            ack['id'],
            1000 * ack['date'],
            batch,
         );
      } else {
         _handlePublishAck(-1, -1, batch);
      }
   }

   Future<void> _onWSDataImpl(Batch batch) async
   {
      while (_wsMsgQueue.isNotEmpty) {
         var msg = _wsMsgQueue.removeFirst();

         Map<String, dynamic> ack = jsonDecode(msg);
         final String cmd = ack["cmd"];
         if (cmd == "presence") {
            _onPresence(ack);
         } else if (cmd == "message") {
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
            _onServerAck(ack, batch);
         } else if (cmd == "register_ack") {
            _onRegisterAck(ack, msg, batch);
         } else if (cmd == "filenames_ack") {
            await _onFilenamesAck(ack);
         } else {
            print('Unhandled message received from the server:\n$msg.');
         }
      }
   }

   Future<void> _onWSData(msg) async
   {
      print(msg);
      final bool isEmpty = _wsMsgQueue.isEmpty;
      _wsMsgQueue.add(msg);
      if (isEmpty) {
         Batch batch = _db.batch();
         await _onWSDataImpl(batch);
         await batch.commit(noResult: true, continueOnError: true);
      }
   }

   void _onWSError(error)
   {
      print("Error: _onWSError $error");
      _lastDisconnect = DateTime.now().millisecondsSinceEpoch;
   }

   void _onWSDone()
   {
      print("Communication closed by peer.");
      _lastDisconnect = DateTime.now().millisecondsSinceEpoch;
   }

   void _onOkDialAfterSendFilters()
   {
      _tabCtrl.index = 1;
      _botBarIdx = 0;
      setState(() { });
   }

   void _showSimpleDialog(
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

  /* The variable i can assume the following values
   * 0: Only leaves the screen.
   * 1: Retrieve all posts from the server. (I think we do not need this
   *    option).
   * 2: Notifications: When the user presses search we will zero the
   *    lastPostId and search.
   */
   Future<void>
   _onSendFilters(BuildContext ctx, int i) async
   {
      _newFiltersPressed = false;
      if (i == 0) {
         setState(() { });
         return;
      }

      //final int lastPostId = i == 1 ? 0 : _cfg.lastPostId;
      //final int lastPostId = _cfg.lastPostId;

      // I changed my mind in 8.12.2019 and decided it is less confusing to
      // the user if we always search for all posts not only for those that
      // have a more recent post id than what is stored in the app. For
      // that we rely on the fact that
      //
      // 1. When the user moves a post to the chats screen it will not be
      //    added twice.
      // 2. Old posts will be cleared when we receive the answer to this
      //    request.

      _cfg.lastPostId = 0;
      _nNewPosts = 0;

      await _db.execute(sql.updateLastPostId, [0]);

      _subscribeToChannels(0);

      _showSimpleDialog(
         ctx,
         _onOkDialAfterSendFilters,
         g.param.dialogTitles[3],
         Text(g.param.dialogBodies[3]),
      );
   }

   void _subscribeToChannels(int lastPostId)
   {
      List<List<int>> channels = List<List<int>>();

      // An empty channels list means we do not want any filter for
      // that menu item.
      for (MenuItem item in _trees)
         channels.add(readHashCodes(item.root.first, item.filterDepth));

      assert(channels.length == 2);

      var subCmd =
      { 'cmd': 'subscribe'
      , 'last_post_id': lastPostId
      , 'filters': channels[0]
      , 'channels': channels[1]
      , 'any_of_features': _cfg.anyOfFeatures
      , 'ranges': convertToValues(_cfg.ranges)
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
      return _lpChats.isNotEmpty;
   }

   bool _hasLPChatMsgs()
   {
      return _lpChatMsgs.isNotEmpty;
   }

   void _unmarkLPChats()
   {
      _lpChats.forEach((e){toggleLPChat(e.chat);});
      _lpChats.clear();
   }

   void _onAppBarVertPressed(ConfigActions ca)
   {
      if (ca == ConfigActions.ChangeNick) {
         setState(() {
            _goToRegScreen = true;
         });
      }

      if (ca == ConfigActions.Notifications) {
         setState(() {
            _goToNtfScreen = true;
         });
      }
   }

   void _onSearchPressed()
   {
      setState(() {
         _newFiltersPressed = true;
         _trees[0].restoreMenuStack();
         _trees[1].restoreMenuStack();
         // If you changes this, also change the index _onWillPopMenu
         // will be called with.
         _botBarIdx = 1;
      });
   }

   Future<void> _pinChats() async
   {
      assert(_isOnFav() || _isOnOwn());

      if (_lpChats.isEmpty)
         return;

      _lpChats.forEach((e){toggleChatPinDate(e.chat);});
      _lpChats.forEach((e){toggleLPChat(e.chat);});
      _lpChats.first.post.chats.sort(compChats);
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
               await _db.execute(sql.delPostWithId, [o.id]);

         _favPosts.removeWhere((e) { return e.chats.isEmpty; });
      } else {
         _ownPosts.sort(compPosts);
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
                        g.param.devChatOkStr,
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
               child: Text(g.param.delChatCancelStr,
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
               g.param.delOwnChatTitleStr,
               style: TextStyle(color: Colors.black));

            if (_isOnFav()) {
               text = Text(
                  g.param.delFavChatTitleStr,
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
      assert(_lpChatMsgs.isNotEmpty);

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

   Future<void> _onRegisterContinue(BuildContext ctx) async
   {
      try {
         if (_txtCtrl.text.length < cts.nickMinLength) {
            _showSimpleDialog(
               ctx,
               (){},
               g.param.onEmptyNickTitle,
               Text(g.param.onEmptyNickContent),
            );
            return;
         }

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

   Future<void> _onChangeNtf(int i, bool v) async
   {
      try {
         if (i == 0)
            _cfg.notifications.chat = v;

         if (i == 1)
            _cfg.notifications.post = v;

         final String str = jsonEncode(_cfg.notifications.toJson());
         await _db.execute(sql.updateNotifications, [str]);

         if (i == -1)
            _goToNtfScreen = false;

         setState(() { });
      } catch (e) {
         print(e);
      }
   }

   void _onExDetails(int i, int j)
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

   Future<void> _onFilterDetail(int i) async
   {
      _cfg.anyOfFeatures ^= 1 << i;

      final String str = _cfg.anyOfFeatures.toString();

      await _db.execute(sql.updateAnyOfFeatures, [str]);
      setState(() { });
   }

   @override
   Widget build(BuildContext ctx)
   {
      final bool mustWait =
         _trees.isEmpty    ||
         _trees.isEmpty     ||
         (_exDetailsRoot == null) ||
         (_inDetailsRoot == null) ||
         (g.param == null);

      if (mustWait)
         return makeWaitMenuScreen(ctx);

      Locale locale = Localizations.localeOf(ctx);
      g.param.setLang(locale.languageCode);
      //print('-----> ${locale.languageCode}');

      if (_goToRegScreen) {
         return makeRegisterScreen(
            ctx,
            _txtCtrl2,
            _txtCtrl,
            (){_onRegisterContinue(ctx);},
            g.param.changeNickAppBarTitle,
            _cfg.email,
            _cfg.nick,
         );
      }

      if (_goToNtfScreen) {
         return makeNtfScreen(
            ctx,
            _onChangeNtf,
            g.param.changeNtfAppBarTitle,
            _cfg.notifications,
            g.param.ntfTitleDesc,
         );
      }

      if (_onTabSwitch())
         _cleanUpLpOnSwitchTab();

      if (_newPostErrorCode != -1) {
         SchedulerBinding.instance.addPostFrameCallback((_)
         {
            String title = g.param.newPostErrorTitles[_newPostErrorCode];
            String body = g.param.newPostErrorBodies[_newPostErrorCode];
            _showSimpleDialog(ctx, (){},
               title,
               Text(body)
            );
            _newPostErrorCode = -1;
         });
      }

      if (_newPostPressed) {
         return makeNewPostScreens(
            ctx,
            _post,
            _trees,
            _txtCtrl,
            _onSendNewPost,
            _botBarIdx,
            _onExDetails,
            _onPostLeafPressed,
            _onPostNodePressed,
            () { return _onWillPopMenu(_trees, 0);},
            _onNewPostBotBarTapped,
            _onNewPostInDetail,
            _exDetailsRoot,
            _inDetailsRoot,
            _onRangeValueChanged,
            _onAddPhoto,
            _imgFiles,
            _filenamesTimer.isActive,
         );
      }

      if (_newFiltersPressed) {
         // Below we use txt.exDetails[0][0], because the filter is
         // common to all products.
         return makeFiltersScreen(
            ctx,
            _onSendFilters,
            _onFilterDetail,
            _onFilterNodePressed,
            () { return _onWillPopMenu(_trees, 1);},
            _onBotBarTapped,
            _onFilterLeafNodePressed,
            _trees,
            _cfg.anyOfFeatures,
            _botBarIdx,
            _exDetailsRoot.children[0].children[0],
            _cfg.ranges,
            _onRangeChanged,
         );
      }

      if (_expPostIdx != -1 && _expImgIdx != -1) {
         Post post;
         if (_isOnOwn())
            post = _ownPosts[_expPostIdx];
         else if (_isOnPosts())
            post = _posts[_expPostIdx];
         else if (_isOnFav())
            post = _favPosts[_expPostIdx];
         else
            assert(false);

         return makeImgExpandScreen(
            ctx,
            () {_onExpandImg(-1, -1); return false;},
            post,
         );
      }

      if (_isOnFavChat() || _isOnOwnChat()) {
         return makeChatScreen(
            ctx,
            _onPopChat,
            _chat,
            _txtCtrl,
            _onSendChat,
            _chatScrollCtrl,
            _toggleLPChatMsgs,
            _lpChatMsgs.length,
            _onFwdChatMsg,
            _onDragChatMsg,
            _chatFocusNode,
            _onChatMsgReply,
            makePostSummaryStr(_trees, _post),
            _onChatAttachment,
            _dragedIdx,
            _onCancelFwdLpChat,
            _showChatJumpDownButton,
            _onChatJumpDown,
            _isOnFavChat() ? _post.avatar : _chat.avatar,
            _onWritingChat,
            _cfg.nick,
         );
      }

      List<Function> onWillPops = List<Function>(g.param.tabNames.length);
      onWillPops[0] = _onChatsBackPressed;
      onWillPops[1] = (){return true;};
      onWillPops[2] = _onChatsBackPressed;

      String appBarTitle = g.param.appName;

      List<Widget> fltButtons = List<Widget>(g.param.tabNames.length);

      fltButtons[0] = makeFaButton(
         ctx,
         _onNewPost,
         _onFwdSendButton,
         _lpChats.length,
         _lpChatMsgs.length
      );

      fltButtons[1] = makeFAButtonMiddleScreen(
         ctx,
         _onShowNewPosts,
         _onSearchPressed,
         _nNewPosts,
         _posts.length,
      );

      fltButtons[2] = makeFaButton(
         ctx,
         null,
         _onFwdSendButton,
         _lpChats.length,
         _lpChatMsgs.length
      );

      List<Widget> bodies = List<Widget>(g.param.tabNames.length);

      bodies[0] = makeChatTab(
         ctx,
         _ownPosts,
         _onChatPressed,
         _onChatLP,
         _trees,
         (int i) { _removePostDialog(ctx, i);},
         _onPinPost,
         _lpChatMsgs.isNotEmpty,
         _onUserInfoPressed,
         false,
         _exDetailsRoot,
         _inDetailsRoot,
         _onExpandImg,
      );

      bodies[1] = makeNewPostLv(
         ctx,
         _posts,
         _alertUserOnPressed,
         _trees,
         _exDetailsRoot,
         _inDetailsRoot,
         _nNewPosts,
         _onExpandImg,
      );

      bodies[2] = makeChatTab(
         ctx,
         _favPosts,
         _onChatPressed,
         _onChatLP,
         _trees,
         (int i) { _removePostDialog(ctx, i);},
         _onPinPost,
         _lpChatMsgs.isNotEmpty,
         _onUserInfoPressed,
         true,
         _exDetailsRoot,
         _inDetailsRoot,
         _onExpandImg,
      );

      Widget appBarLeading;
      if ((_isOnFav() || _isOnOwn()) && _hasLPChatMsgs()) {
         appBarTitle = g.param.msgOnRedirectingChat;
         appBarLeading = IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: _onBackFromChatMsgRedirect
         );
      }

      List<Widget> actions = List<Widget>();
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
            tooltip: g.param.deleteChat,
            onPressed: () { _deleteChatDialog(ctx); }
         );

         actions.add(delChatBut);
      } else if (_isOnPosts()) {
         IconButton clearPosts = IconButton(
            icon: Icon(
               Icons.delete_forever,
               color: Theme.of(ctx).colorScheme.onPrimary,
            ),
            tooltip: g.param.clearPosts,
            onPressed: () { _clearPostsDialog(ctx); }
         );

         actions.add(clearPosts);
      }

      // We only add the global action buttons if
      // 1. There is no chat selected for selection.
      // 2. We are not forwarding a message.
      if (!_hasLPChats() && !_hasLPChatMsgs()) {
         IconButton searchButton = IconButton(
            icon: Icon(
               Icons.search,
               color: stl.colorScheme.onPrimary,
            ),
            tooltip: g.param.notificationsButton,
            onPressed: () { _onSearchPressed(); }
         );

         IconButton publishButton = IconButton(
            icon: Icon(
               stl.newPostIcon,
               color: stl.colorScheme.onPrimary,
            ),
            onPressed: () { _onNewPost(); },
         );

         actions.add(publishButton);
         actions.add(searchButton);
         actions.add(makeAppBarVertAction(_onAppBarVertPressed));
      }

      List<int> newMsgsCounters = List<int>(g.param.tabNames.length);
      newMsgsCounters[0] = _getNUnreadOwnChats();
      newMsgsCounters[1] = _nNewPosts;
      newMsgsCounters[2] = _getNUnreadFavChats();

      List<double> opacities = _getNewMsgsOpacities();

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

