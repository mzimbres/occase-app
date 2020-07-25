import 'dart:async' show Future, Timer;
import 'dart:convert';
import 'dart:io';
import 'dart:collection';

import 'dart:io'
       if (dart.library.io)
          'package:web_socket_channel/io.dart'
       if (dart.library.html)
          'package:web_socket_channel/html.dart';

import 'dart:io'
       if (dart.library.io)
          'package:occase/persistency_app.dart'
       if (dart.library.html)
          'package:occase/persistency_web.dart';

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
import 'package:share/share.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:url_launcher/url_launcher.dart';

import 'package:flutter/material.dart';
import 'package:occase/post.dart';
import 'package:occase/tree.dart';
import 'package:occase/constants.dart' as cts;
import 'package:occase/parameters.dart';
import 'package:occase/globals.dart' as g;
import 'package:occase/stl.dart' as stl;

typedef OnPressedFn0 = void Function();
typedef OnPressedFn1 = void Function(int);
typedef OnPressedFn2 = void Function(BuildContext, int);
typedef OnPressedFn3 = void Function(int, int);
typedef OnPressedFn4 = void Function(BuildContext);
typedef OnPressedFn5 = void Function(BuildContext, int, int);
typedef OnPressedFn6 = void Function(int i, double);
typedef OnPressedFn7 = bool Function();
typedef OnPressedFn8 = void Function(int, double);
typedef OnPressedFn9 = void Function(String);
typedef OnPressedFn10 = void Function(int, bool);
typedef OnPressedFn11 = void Function(BuildContext, int, DragStartDetails);
typedef OnPressedFn12 = void Function(List<int>, int);
typedef OnPressedFn13 = void Function(bool, int);
typedef OnPressedFn14 = void Function(List<int>);
typedef OnPressedFn15 = void Function(ConfigActions);

bool isWideScreenImpl(double w)
{
   return w > (3 * cts.tabDefaultWidth);
}

double makeTabWidthImpl(double w, int tab)
{
   if (isWideScreenImpl(w)) {
      return cts.tabWidthRates[tab] * w;
   }

   return w;
}

double makeTabWidth(BuildContext ctx, int tab)
{
   final double w = MediaQuery.of(ctx).size.width;
   return makeTabWidthImpl(w, tab);
}

bool isWideScreen(BuildContext ctx)
{
   final double w = MediaQuery.of(ctx).size.width;
   return isWideScreenImpl(w);
}

double makeImgAvatarWidth(BuildContext ctx, int tab)
{
   final double w = MediaQuery.of(ctx).size.width;
   if (isWideScreenImpl(w))
      return cts.postImgAvatarTabWidthRate * cts.tabDefaultWidth;

   if (w > cts.tabDefaultWidth)
      return cts.postImgAvatarTabWidthRate * cts.tabDefaultWidth;

   return cts.postImgAvatarTabWidthRate * w;
}

double makePostTextWidth(BuildContext ctx, int tab)
{
   final double tabWidth = makeTabWidth(ctx, tab);
   final double imgWidth = makeImgAvatarWidth(ctx, tab);
   return tabWidth - imgWidth - 10.00;
}

double makeDialogWidthHeight(BuildContext ctx, int tab)
{
   double w = makeTabWidth(ctx, tab);
   return 0.90 * w;
}

double makeMaxWidth(BuildContext ctx, int tab)
{
   final double w = MediaQuery.of(ctx).size.width;

   if (isWideScreenImpl(w))
      return makeTabWidthImpl(w, tab);

   final double max = w > cts.tabDefaultWidth ? cts.tabDefaultWidth : w;
   return max;
}

double makeMaxHeight(BuildContext ctx)
{
   return MediaQuery.of(ctx).size.height;
}

Future<List<Tree>> readTreeFromAsset() async
{
   // When the database is created, we also have to create the
   // default tree table.
   List<Tree> l = List<Tree>(2);

   final String tree0 = await rootBundle.loadString('data/menu0.txt');
   l[0] = treeReader(jsonDecode(tree0)).first;

   final String tree1 = await rootBundle.loadString('data/menu1.txt');
   l[1] = treeReader(jsonDecode(tree1)).first;

   return l;
}

Future<void> fcmOnBackgroundMessage(Map<String, dynamic> message) async
{
  print("onBackgroundMessage: $message");
}

String emailToGravatarHash(String email)
{
   if (email.isEmpty)
      return '';

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

Future<void> removeLpChat(Coord c, Persistency p) async
{
   // removeWhere could also be used, but that traverses all elements
   // always and we know there is only one element to remove.

   final bool ret = c.post.chats.remove(c.chat);
   assert(ret);

   final int n = await p.deleteChatStElem(c.post.id, c.chat.peer);
   assert(n == 1);
}

Future<Null> main() async
{
  runApp(MyApp());
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
, Information
}

Widget makeAppBarVertAction(OnPressedFn15 onSelected)
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
          PopupMenuItem<ConfigActions>(
             value: ConfigActions.Information,
             child: Text(g.param.information),
          ),
        ];
     }
   );
}

List<Widget> makeOnLongPressedActions(OnPressedFn0 deleteChatEntryDialog, OnPressedFn0 pinChat)
{
   List<Widget> actions = List<Widget>();

   IconButton pinChatBut = IconButton(
      icon: Icon(Icons.place, color: Colors.white),
      tooltip: g.param.pinChat,
      onPressed: pinChat,
   );

   actions.add(pinChatBut);

   IconButton delChatBut = IconButton(
      icon: Icon(Icons.delete_forever, color: Colors.white),
      tooltip: g.param.deleteChat,
      onPressed: deleteChatEntryDialog,
   );

   actions.add(delChatBut);

   return actions;
}

Scaffold makeWaitMenuScreen()
{
   return Scaffold(
      appBar: AppBar(title: Text(g.param.appName)),
      body: Center(child: CircularProgressIndicator()),
      backgroundColor: stl.colorScheme.background,
   );
}

Widget makeImgExpandScreen(Function onWillPopScope, Post post)
{
   //final double width = makeMaxWidth(ctx, tab);
   //final double height = makeMaxHeight(ctx);

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
         backgroundColor: stl.colorScheme.primary,
      ),
   );
}

TextField makeNickTxtField(
   TextEditingController txtCtrl,
   Icon icon,
   int fieldMaxLength,
   String hint,
) {
   Color focusedColor = stl.colorScheme.primary;

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
   TextEditingController emailCtrl,
   TextEditingController nickCtrl,
   Function onContinue,
   String appBarTitle,
   String previousEmail,
   String previousNick,
   double maxWidth,
) {
   if (previousEmail.isNotEmpty)
      emailCtrl.text = previousEmail;

   TextField emailTf = makeNickTxtField(
      emailCtrl,
      Icon(Icons.email),
      cts.emailMaxLength,
      g.param.emailHint,
   );

   if (previousNick.isNotEmpty)
      nickCtrl.text = previousNick;

   TextField nickTf = makeNickTxtField(
      nickCtrl,
      Icon(Icons.person),
      cts.nickMaxLength,
      g.param.nickHint,
   );

   Widget button = createRaisedButton(
      onContinue,
      g.param.next,
      stl.colorScheme.secondary,
      stl.colorScheme.onSecondary,
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

   // TODO: Use ConstrainedBox
   Widget body = col;
   if (!isWideScreenImpl(maxWidth))
      body = SizedBox(width: maxWidth, child: col);

   return Scaffold(
      appBar: AppBar(title: Text(appBarTitle)),
      body: Center(
         child: Padding(
            child: body,
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
   final List<String> titleDesc,
) {
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
           () {onChange(-1, false);},
           g.param.ok,
	   stl.colorScheme.secondary,
	   stl.colorScheme.onSecondary,
        ),
      ]
   );

   final double width = makeTabWidth(ctx, cts.ownIdx);

   Widget tmp = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: width),
      child: col,
   );

   return Scaffold(
      appBar: AppBar(title: Text(appBarTitle)),
      body: Padding(
         child: Center(child: tmp),
         padding: EdgeInsets.symmetric(vertical: 20.0),
      ),
   );
}

Widget makeInfoScreen(
   BuildContext ctx,
   OnPressedFn7 onWillPopScope,
   OnPressedFn0 onSendEmail,
) {
   final double width = makeTabWidth(ctx, cts.ownIdx);

   Widget tmp = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: width),
      child: Center(
         child: RaisedButton(
	    onPressed: onSendEmail,
	    child: Text(g.param.supportEmail,
	       style: TextStyle(
		  fontSize: 20.0,
		  color: stl.colorScheme.primary,
		  fontWeight: FontWeight.normal,
	       ),
	    ),
	 ),
      ),
   );

   return WillPopScope(
      onWillPop: () async { return onWillPopScope();},
      child: Scaffold(
	 appBar: AppBar(
	    title: Text(g.param.appName),
	    leading: IconButton(
	       padding: EdgeInsets.all(0.0),
	       icon: Icon(Icons.arrow_back, color: stl.colorScheme.onPrimary),
	       onPressed: onWillPopScope,
	    ),
	 ),
	 body: Padding(
	    child: Center(child: tmp),
	    padding: EdgeInsets.symmetric(vertical: 20.0),
	 ),
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
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
               color: stl.colorScheme.background,
               fontSize: stl.tt.headline6.fontSize,
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

Widget makeWdgOverImg(Widget wdg)
{
   return Padding(
      padding: const EdgeInsets.all(2.0),
      child: Card(child: wdg,
	    elevation: 0.0,
	    color: Colors.white.withOpacity(0.7),
	    margin: EdgeInsets.all(5.0),
      ),
   );
}

Image getImage({
   String path,
   double width,
   double height,
   BoxFit fit,
   FilterQuality filterQuality,
}) {
   if (kIsWeb)
      return Image.network(
         path,
	 width: width,
	 height: height,
	 fit: fit,
	 filterQuality: filterQuality,
      );

   return Image.file(
      File(path),
      width: width,
      height: height,
      fit: fit,
      filterQuality: filterQuality,
   );
}

// Generates the image list view of a post.
Widget makeImgListView2({
   BuildContext ctx,
   final double width,
   Post post,
   BoxFit boxFit,
   List<PickedFile> imgFiles,
   OnPressedFn1 onExpandImg,
   OnPressedFn2 addImg,
}) {
   final int l1 = post.images.length;
   final int l2 = imgFiles.length;

   if (l1 == 0 && l2 == 0) {
      Widget w = makeImgTextPlaceholder(g.param.addImgMsg);
      return makeImgPlaceholder(width, width, w);
   }

   final int l = l1 == 0 ? l2 : l1;

   ListView lv = ListView.builder(
      scrollDirection: Axis.horizontal,
      shrinkWrap: true,
      padding: const EdgeInsets.all(0.0),
      itemCount: l,
      itemBuilder: (BuildContext ctx, int i)
      {
         //FlatButton b = FlatButton(
         //   onPressed: (){onExpandImg(l -i -1);},
         //   child: Container(
         //      width: width * 0.9,
         //      height: width * 0.9,
         //   ),
         //);

	 Widget imgCounter = makeTextWdg('${i + 1}/$l', 3.0, 3.0, 3.0, 3.0, FontWeight.normal);

	 List<Widget> wdgs = List<Widget>();

	 if (post.images.isNotEmpty) {
	    Widget tmp = makeNetImgBox(width, width, post.images[l -i -1], boxFit);
	    wdgs.add(tmp);
	    wdgs.add(Positioned(child: makeWdgOverImg(imgCounter), top: 4.0));
	 } else if (imgFiles.isNotEmpty) {
	    Widget tmp = getImage(
	       path: imgFiles[i].path,
	       width: width,
	       height: width,
	       fit: BoxFit.cover,
	       filterQuality: FilterQuality.high,
	    );

	    wdgs.add(tmp);

	    IconButton add = IconButton(
	       onPressed: (){addImg(ctx, -1);},
	       icon: Icon(Icons.add_a_photo, color: stl.colorScheme.primary),
	    );

	    Widget addWdg = makeWdgOverImg(add);
	    wdgs.add(Positioned(child: addWdg, bottom: 4.0, right: 4.0));

	    IconButton remove = IconButton(
	       onPressed: (){addImg(ctx, i);},
	       icon: Icon(Icons.cancel, color: stl.colorScheme.primary),
	    );

	    Widget removeWdg = makeWdgOverImg(remove);
	    wdgs.add(Positioned(child: removeWdg, top: 4.0, right: 4.0));
	    wdgs.add(Positioned(child: makeWdgOverImg(imgCounter), top: 4.0, left: 4.0));
	 } else {
	    assert(false);
	 }

         return Stack(children: wdgs);
      },
   );

   return constrainBox(width, width, lv);
}

Widget makeImgListView(
   double width,
   double height,
   Function onAddPhoto,
   List<PickedFile> imgFiles,
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
         Widget img = getImage(
	    path: imgFiles[i].path,
            width: width,
            height: height,
            fit: BoxFit.cover,
            filterQuality: FilterQuality.high,
         );

         Widget delPhotoWidget = makeAddOrRemoveWidget(
            onPressed: () {onAddPhoto(ctx, i);},
            icon: Icons.clear,
            color: stl.colorScheme.secondaryVariant,
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
   String first,
   String second,
   String sep,
   bool changeColor,
) {
   Color color = changeColor
               ? stl.colorScheme.secondaryVariant
               : stl.colorScheme.secondary;

   return RichText(
      text: TextSpan(
         text: '$first$sep ',
         style: stl.tsSubheadOnPrimary,
         children: <TextSpan>
         [ TextSpan(
              text: second,
              style: stl.tt.subtitle1.copyWith(color: color),
           ),
         ],
      ),
   );
}

RichText makeSearchTitle({
   String name,
   String value,
   String separator,
}) {
   return RichText(
      text: TextSpan(
         text: '$name$separator',
         style: stl.newPostTitleLT.copyWith(fontSize: stl.ltTitleFontSize),
         children: <TextSpan>
         [ TextSpan(
              text: value,
              style: stl.newPostSubtitleLT.copyWith(fontSize: stl.ltTitleFontSize),
           ),
         ],
      ),
   );
}

List<Widget> makeSliderList({
   double value,
   double min,
   double max,
   int divisions,
   Function onValueChanged,
}) {
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

List<Widget> makeCheckBoxes(
      final int state,
      final List<String> items,
      final OnPressedFn13 onChanged,
) {
   List<Widget> ret = List<Widget>();

   for (int i = 0; i < items.length; ++i) {
      final bool v = ((state & (1 << i)) != 0);
      CheckboxListTile tmp = CheckboxListTile(
         dense: true,
         title: Text(items[i], style: stl.newPostTitleLT),
         value: v,
         onChanged: (bool v) { onChanged(v, i); },
         activeColor: stl.colorScheme.primary,
	 isThreeLine: false,
      );

      ret.add(tmp);
   }

   return ret;
}

Widget makeNewPostFinalScreen({
   BuildContext ctx,
   final Post post,
   final List<Tree> trees,
   final Node exDetailsRootNode,
   final Node inDetailsRootNode,
   final List<PickedFile> imgFiles,
   final OnPressedFn2 onAddPhoto,
   final OnPressedFn4 onPublishPost,
   final OnPressedFn4 onRemovePost,
}) {

   // NOTE: This ListView is used to provide a new context, so that
   // it is possible to show the snackbar using the scaffold.of on
   // the new context.

   Widget w0 = makeNewPost(
      screen: cts.ownIdx,
      post: post,
      exDetailsRootNode: exDetailsRootNode,
      inDetailsRootNode: inDetailsRootNode,
      trees: trees,
      imgFiles: imgFiles,
      onAddPhoto: onAddPhoto,
      onExpandImg: (int j){ print('Noop00'); },
      onAddPostToFavorite: () { print('Noop01'); },
      onDelPost: () { print('Noop02');},
      onSharePost: () { print('Noop03');},
      onReportPost: () { print('Noop05');},
      onPinPost: () { print('Noop06');},
   );

   Widget w1 = createRaisedButton(
      () {onRemovePost(ctx);},
      g.param.cancel,
      stl.expTileCardColor,
      Colors.black,
   );

   Widget w2 = createRaisedButton(
      () { onPublishPost(ctx); },
      g.param.newPostAppBarTitle,
      stl.colorScheme.secondary,
      stl.colorScheme.onSecondary,
   );

   Row r = Row(children: <Widget>[Expanded(child: w1), Expanded(child: w2)]);

   Widget tmp = Padding(
      padding: EdgeInsets.only(top: 30.0, bottom: 30.0),
      child: r,
   );

   return Column(children: <Widget>[w0, tmp]);
}

List<Widget> makeTabActions({
   int screen,
   bool newPostPressed,
   bool hasLPChats,
   bool hasLPChatMsgs,
   OnPressedFn0 deleteChatDialog,
   OnPressedFn0 pinChats,
   OnPressedFn0 onClearPostsDialog,
}) {
   final bool fav = screen == cts.favIdx;
   final bool own = screen == cts.ownIdx;
   final bool search = screen == cts.searchIdx;

   List<Widget> ret = List<Widget>();
   if (own) {
      if (newPostPressed) {
      } else if (hasLPChats && !hasLPChatMsgs) {
	 ret = makeOnLongPressedActions(deleteChatDialog, pinChats);
      }
   } else if (fav) {
      if (hasLPChats && !hasLPChatMsgs) {
	 IconButton delChatBut = IconButton(
	    icon: Icon(
	       Icons.delete_forever,
	       color: stl.colorScheme.onPrimary,
	    ),
	    tooltip: g.param.deleteChat,
	    onPressed: deleteChatDialog,
	 );

	 ret.add(delChatBut);
      }
   } else if (search) {
      //IconButton clearPosts = IconButton(
      //   icon: Icon(
      //      Icons.delete_forever,
      //      color: stl.colorScheme.onPrimary,
      //   ),
      //   tooltip: g.param.clearPosts,
      //   onPressed: onClearPostsDialog,
      //);

      //ret.add(clearPosts);
   }

   return ret;
}

List<Widget> makeGlobalActionsWeb({
   OnPressedFn0 onSearchPressed,
   OnPressedFn0 onNewPost,
   OnPressedFn15 onAppBarVertPressed,
}) {
   List<Widget> ret = List<Widget>();

   IconButton searchButton = IconButton(
      icon: Icon(
	 Icons.search,
	 color: stl.colorScheme.onPrimary,
      ),
      tooltip: g.param.notificationsButton,
      onPressed: onSearchPressed,
   );

   IconButton publishButton = IconButton(
      icon: Icon(
	 stl.newPostIcon,
	 color: stl.colorScheme.onPrimary,
      ),
      onPressed: onNewPost,
   );

   //ret.add(publishButton);
   //ret.add(searchButton);
   ret.add(makeAppBarVertAction(onAppBarVertPressed));

   return ret;
}

List<Widget> makeGlobalActionsApp({
   bool hasLPChats,
   bool hasLPChatMsgs,
   OnPressedFn0 onSearchPressed,
   OnPressedFn0 onNewPost,
   OnPressedFn15 onAppBarVertPressed,
}) {
   // We only add the global action buttons if
   // 1. There is no chat selected for selection.
   // 2. We are not forwarding a message.
   if (!hasLPChats && !hasLPChatMsgs)
      return makeGlobalActionsWeb(
	 onSearchPressed: onSearchPressed,
	 onNewPost: onNewPost,
	 onAppBarVertPressed: onAppBarVertPressed,
      );

   return List<Widget>();
}

Widget makeAppBarLeading({
   final bool hasLpChats,
   final bool hasLpChatMsgs,
   final bool newPostPressed,
   final bool newSearchPressed,
   final bool isWide,
   final bool hasNoFavPosts,
   final int tab,
   final OnPressedFn0 onWillLeaveSearch,
   final OnPressedFn0 onWillLeaveNewPost,
   final OnPressedFn0 onBackFromChatMsgRedirect,
}) {
   final bool own = tab == cts.ownIdx;
   final bool search = tab == cts.searchIdx;
   final bool fav = tab == cts.favIdx;

   if ((fav || own) && hasLpChatMsgs)
      return IconButton(
	 icon: Icon(Icons.arrow_back),
	 onPressed: onBackFromChatMsgRedirect,
      );

   if (own && newPostPressed)
      return IconButton(
	 icon: Icon(Icons.arrow_back, color: Colors.white),
	 onPressed: onWillLeaveNewPost,
      );

   if (search && newSearchPressed && !isWide)
      return IconButton(
	 icon: Icon(Icons.arrow_back),
	 onPressed: onWillLeaveSearch,
      );

   if (fav && (newSearchPressed || hasNoFavPosts) && newSearchPressed)
      return IconButton(
	 icon: Icon(Icons.arrow_back),
	 onPressed: onWillLeaveSearch,
      );

   return null;
}

Widget makeAppBarWdg({
   bool hasLpChatMsgs,
   bool newPostPressed,
   bool newSearchPressed,
   bool isWide,
   bool hasNoFavPosts,
   final int tab,
   final List<Tree> trees,
   Widget defaultWdg,
}) {
   final bool fav = tab == cts.favIdx;
   final bool own = tab == cts.ownIdx;
   final bool search = tab == cts.searchIdx;

   if ((fav || own) && hasLpChatMsgs)
      return Text(g.param.msgOnRedirectingChat);

   if (own && newPostPressed)
      return makeSearchAppBar(
	 trees: trees,
	 title: g.param.newPostAppBarTitle,
      );

   if (search && newSearchPressed && !isWide)
      return makeSearchAppBar(
	 trees: trees,
	 title: g.param.filterAppBarTitle,
      );

   if (fav && (newSearchPressed || hasNoFavPosts) && isWide)
      return makeSearchAppBar(
	 trees: trees,
	 title: g.param.filterAppBarTitle,
      );

   return defaultWdg;
}

Widget makeNewPostLT({
   final String title,
   final String subTitle,
   final IconData icon,
   OnPressedFn0 onTap,
}) {
   Widget leading;
   if (icon != null)
      leading = CircleAvatar(
	  child: Icon(icon,
	     color: stl.colorScheme.primary,
	  ),
          backgroundColor: Colors.white,
      );
      
   return ListTile(
       contentPadding: EdgeInsets.all(3.0),
       leading: leading,
       title: Text(title,
	  maxLines: 1,
	  overflow: TextOverflow.ellipsis,
	  style: stl.newPostTitleLT,
       ),
       dense: true,
       subtitle:
	  Text(subTitle,
	     maxLines: 1,
	     overflow: TextOverflow.ellipsis,
	     style: stl.newPostSubtitleLT.copyWith(fontSize: stl.ltTitleFontSize),
	  ),
       onTap: onTap,
       enabled: true,
       isThreeLine: false,
    );
}

ListView makeNewPostListView(List<Widget> list)
{
   return ListView.builder(
      itemCount: list.length,
      itemBuilder: (BuildContext ctx, int i)
      {
	 return list[i];
      },
   );
}

Widget makeChooseTreeNodeDialog({
   BuildContext ctx,
   final int tab,
   final String title,
   final List<int> defaultCode,
   final Node root,
   final IconData iconData,
   final OnPressedFn14 onSetTreeCode,
}) {
   String subtitle = root.name(g.param.langIdx);
   if (defaultCode.isNotEmpty) {
      subtitle = loadNames(
         root,
	 defaultCode,
	 g.param.langIdx,
      ).join(', ');
   }

   return makeNewPostLT(
      title: title,
      subTitle: subtitle,
      icon: iconData,
      onTap: () async
      {
	 final
	 List<int> code = await showDialog<List<int>>(
	    context: ctx,
	    builder: (BuildContext ctx2)
	    {
	       return TreeView(root: root, tab: tab);
	    },
	 );

	 if (code != null)
	    onSetTreeCode(code);
      },
   );
}

Widget makeNewPostInDetailLT({
   BuildContext ctx,
   final int state,
   final String title,
   final String subtitle,
   final List<String> details,
   final OnPressedFn1 onSetInDetail,
}) {
   return makeNewPostLT(
      title: title,
      subTitle: subtitle,
      icon: null,
      onTap: () async
      {
	 final int state2 = await showDialog<int>(
	    context: ctx,
	    builder: (BuildContext ctx2)
	    {
	       return InDetailsView(
		     state: state,
		     title: title,
		     names: details,
	       );
	    },
	 );

	 if (state2 != null)
	    onSetInDetail(state2);
      },
   );
}

List<Widget> makeNewPostWdgs({
   BuildContext ctx,
   final int tab,
   final Tree locationTree,
   final Tree productTree,
   final Node exDetailsRootNode,
   final Node inDetailsRootNode,
   final Post post,
   final OnPressedFn12 onSetTreeCode,
   final OnPressedFn3 onSetExDetail,
   final OnPressedFn3 onSetInDetail,
   final OnPressedFn6 onNewPostValueChanged,
}) {
   List<Widget> list = List<Widget>();

   {  // Location
      final Node locRootNode = locationTree.root.first;
      Widget location = makeChooseTreeNodeDialog(
	 ctx: ctx,
	 tab: tab,
	 title: g.param.newPostTabNames[0],
	 defaultCode: post.location,
	 root: locRootNode,
	 iconData: Icons.edit_location,
	 onSetTreeCode: (var code) { onSetTreeCode(code, 0);},
      );

      list.add(location);
      list.add(stl.newPostDivider);
   }

   {  // Product
      final Node productRootNode = productTree.root.first;
      Widget product = makeChooseTreeNodeDialog(
	 ctx: ctx,
	 tab: tab,
	 title: g.param.newPostTabNames[1],
	 defaultCode: post.product,
	 root: productRootNode,
	 iconData: Icons.directions_car,
	 onSetTreeCode: (var code) { onSetTreeCode(code, 1);},
      );

      list.add(product);
      list.add(stl.newPostDivider);
   }

   // ---------------------------------------------------

   if (post.product.isEmpty)
      return list;

   final int productIdx = post.getProductDetailIdx();
   if (productIdx == -1)
      return list;

   {  // Price, kilometer, year
      final List<Widget> values = makeValueSliders(
         post: post,
	 ranges: g.param.rangesMinMax,
	 divisions: g.param.rangeDivs,
	 onValueChanged: onNewPostValueChanged,
      );

      list.addAll(values);
   }

   {  // exDetails
      final int nDetails = getNumberOfProductDetails(exDetailsRootNode, productIdx);
      for (int i = 0; i < nDetails; ++i) {
	 final int length = productDetailLength(exDetailsRootNode, productIdx, i);
	 final int k = post.exDetails[i] < length ? post.exDetails[i] : 0;

	 final List<String> names = loadNames(
	    exDetailsRootNode,
	    <int>[productIdx, i, k],
	    g.param.langIdx,
	 );

	 final List<String> detailStrs = listAllDetails(
	    root: exDetailsRootNode,
	    productIndex: productIdx,
	    detailIndex: i,
	    languageIndex: g.param.langIdx,
	 );

	 Widget exDetailWdg = makeNewPostLT(
	    title: names[1],
	    subTitle: names[2],
	    icon: null,
	    onTap: () async
	    {
	       final int state = await showDialog<int>(
		  context: ctx,
		  builder: (BuildContext ctx2)
		  {
		     return ExDetailsView(
			title: names[1],
			names: detailStrs,
			onIdx: k,
		     );
		  },
	       );

	       if (state != null)
		  onSetExDetail(i, state);
	    },
	 );

	 list.add(Padding(padding: EdgeInsets.only(left: stl.leftIndent), child: exDetailWdg));
	 list.add(stl.newPostDivider);
      }
   }

   {  // inDetails
      final int nDetails = inDetailsRootNode.children[productIdx].children.length;
      for (int i = 0; i < nDetails; ++i) {
	 final List<String> details = listAllDetails(
	    root: inDetailsRootNode,
	    productIndex: productIdx,
	    detailIndex: i,
	    languageIndex: g.param.langIdx,
	 );

	 List<String> subtitles = makeInDetailNames(
	    root: inDetailsRootNode,
	    state: post.inDetails[i],
	    productIndex: productIdx,
	    detailIndex: i,
	    languageIndex: g.param.langIdx,
	 );

	 Widget inDetailWdg = makeNewPostInDetailLT(
	    ctx: ctx,
	    state: post.inDetails[i],
	    title: inDetailsRootNode.children[productIdx].children[i].name(g.param.langIdx),
	    subtitle: subtitles.join(', '),
	    details: details,
	    onSetInDetail: (var state) {onSetInDetail(i, state);},
	 );

	 list.add(Padding(padding: EdgeInsets.only(left: stl.leftIndent), child: inDetailWdg));
	 list.add(stl.newPostDivider);
      }
   }

   return list;
}

Widget makeNewPostScreenWdgs2({
   BuildContext ctx,
   final bool filenamesTimerActive,
   final Tree locationTree,
   final Tree productTree,
   final Node exDetailsRootNode,
   final Node inDetailsRootNode,
   final Post post,
   final List<PickedFile> imgFiles,
   final OnPressedFn12 onSetTreeCode,
   final OnPressedFn3 onSetExDetail,
   final OnPressedFn3 onSetInDetail,
   final OnPressedFn2 onAddPhoto,
   final OnPressedFn4 onPublishPost,
   final OnPressedFn4 onRemovePost,
   final OnPressedFn8 onRangeValueChanged,
   final OnPressedFn6 onNewPostValueChanged,
   final OnPressedFn9 onSetPostDescription,
}) {
   List<Widget> list = makeNewPostWdgs(
      ctx: ctx,
      tab: cts.ownIdx,
      locationTree: locationTree,
      productTree: productTree,
      exDetailsRootNode: exDetailsRootNode,
      inDetailsRootNode: inDetailsRootNode,
      post: post,
      onSetTreeCode: onSetTreeCode,
      onSetExDetail: onSetExDetail,
      onSetInDetail: onSetInDetail,
      onNewPostValueChanged: onNewPostValueChanged,
   );

   if (list.length < 5)
      return makeNewPostListView(list);

   if (list.length > 2) {
      {  // Description
	 Widget descWidget = makeNewPostLT(
	    title: g.param.postDescTitle,
	    subTitle: post.description,
	    icon: null,
	    onTap: () async
	    {
	       final String description = await showDialog<String>(
		  context: ctx,
		  builder: (BuildContext ctx2)
		  {
		     return PostDescription();
		  },
	       );

	       if (description != null)
		  onSetPostDescription(description);
	    },
	 );

	 list.add(Padding(padding: EdgeInsets.only(left: stl.leftIndent), child: descWidget));
	 list.add(stl.newPostDivider);
      }

      // ---------------------------------------------------

      { // Title
	 Text pageTitle = Text(g.param.reviewAndSend,
	    style: TextStyle(
	       fontSize: 18.0,
	       color: stl.colorScheme.primary,
	       fontWeight: FontWeight.w500,
	    ),
	 );

	 Padding tmp = Padding(
	    child: pageTitle,
	   padding: EdgeInsets.only(top: 20.0, bottom: 20.0),
	 );

	 list.add(Center(child: tmp));
      }

   // ----------------------------------

      { // final
	 Widget finalScreen = makeNewPostFinalScreen(
	    ctx: ctx,
	    post: post,
	    trees: <Tree>[locationTree, productTree],
	    exDetailsRootNode: exDetailsRootNode,
	    inDetailsRootNode: inDetailsRootNode,
	    imgFiles: imgFiles,
	    onAddPhoto: onAddPhoto,
	    onPublishPost: onPublishPost,
	    onRemovePost: onRemovePost,
	 );

	 //Card c = Card(
	 //   margin: const EdgeInsets.all(0.0),
	 //   color: Colors.white,
	 //   child: finalScreen,
	 //   elevation: 2.0,
	 //   shape: RoundedRectangleBorder(
	 //      borderRadius: BorderRadius.all(Radius.circular(0.0)),
	 //   ),
	 //);

	 list.add(finalScreen);
      }

   } // ------------------------

   final Widget lv = makeNewPostListView(list);

   if (!filenamesTimerActive)
      return lv;

   List<Widget> ret = List<Widget>();
   ret.add(lv);

   ModalBarrier mb = ModalBarrier(
      color: Colors.grey.withOpacity(0.4),
      dismissible: false,
   );

   ret.add(mb);
   ret.add(Center(child: CircularProgressIndicator()));

   return Stack(children: ret);
}

Widget makeSearchAppBar({
   final List<Tree> trees,
   final String title,
}) {
   return ListTile(
      dense: true,
      title: Text(title,
	 maxLines: 1,
	 overflow: TextOverflow.ellipsis,
	 style: stl.appBarLtTitle.copyWith(color: Colors.white),
      ),
      //subtitle: Text(trees[screen].getStackNames(),
      //   maxLines: 1,
      //   overflow: TextOverflow.ellipsis,
      //   style: stl.appBarLtSubtitle,
      //),
   );
}

List<Widget> makeValueSliders({
   final Post post,
   final List<int> ranges,
   final List<int> divisions,
   final OnPressedFn6 onValueChanged,
}) {
   List<Widget> sliders = List<Widget>();

   for (int i = 0; i < divisions.length; ++i) {
      final int value = post.rangeValues[i];
      Slider slider = Slider(
	 value: value.toDouble(),
	 min: ranges[2 * i + 0].toDouble(),
	 max: ranges[2 * i + 1].toDouble(),
	 divisions: divisions[i],
	 onChanged: (double v) {onValueChanged(i, v);},
      );

      final RichText rt = makeSearchTitle(
	 name: g.param.rangePrefixes[i],
	 value: '$value',
	 separator: ': ',
      );

      sliders.add(Padding(padding: EdgeInsets.only(top: stl.leftIndent, left: stl.leftIndent), child: rt));
      sliders.add(Padding(padding: EdgeInsets.only(left: stl.leftIndent), child: slider));
      sliders.add(stl.newPostDivider);
   }

   return sliders;
}

Widget makeSearchScreenWdg2({
   BuildContext ctx,
   final int state,
   final Node locationRootNode,
   final Node productRootNode,
   final Node exDetailsRootNode,
   final Post post,
   final List<int> ranges,
   final List<int> divisions,
   final OnPressedFn1 onSearchPressed,
   final OnPressedFn1 onSearchDetail,
   final OnPressedFn6 onValueChanged,
   final OnPressedFn14 onSetLocationCode,
   final OnPressedFn14 onSetProductCode,
}) {
   List<Widget> foo = List<Widget>();

   {  // Location
      Widget location = makeChooseTreeNodeDialog(
	 ctx: ctx,
	 tab: cts.searchIdx,
	 title: g.param.newPostTabNames[0],
	 defaultCode: post.location,
	 root: locationRootNode,
	 iconData: Icons.edit_location,
	 onSetTreeCode: onSetLocationCode,
      );

      foo.add(location);
      foo.add(stl.newPostDivider);
   }

   {  // Product
      Widget product = makeChooseTreeNodeDialog(
	 ctx: ctx,
	 tab: cts.searchIdx,
	 defaultCode: post.product,
	 title: g.param.newPostTabNames[1],
	 root: productRootNode,
	 iconData: Icons.directions_car,
	 onSetTreeCode: onSetProductCode,
      );

      foo.add(product);
      foo.add(stl.newPostDivider);
   }

   {  // Details
      const int productIndex = 0;
      const int detailIndex = 0;

      List<String> subtitles = makeInDetailNames(
	 state: state,
	 root: exDetailsRootNode,
	 productIndex: productIndex,
	 detailIndex: detailIndex,
	 languageIndex: g.param.langIdx,
      );

      List<String> details = listAllDetails(
	 root: exDetailsRootNode,
	 productIndex: productIndex,
	 detailIndex: detailIndex,
	 languageIndex: g.param.langIdx,
      );

      Widget detail = makeNewPostInDetailLT(
	 ctx: ctx,
	 state: state,
	 title: exDetailsRootNode.children[productIndex].children[detailIndex].name(g.param.langIdx),
	 subtitle: subtitles.join(', '),
	 details: details,
	 onSetInDetail: onSearchDetail,
      );

      foo.add(Padding(padding: EdgeInsets.only(left: stl.leftIndent), child: detail));
      foo.add(stl.newPostDivider);
   }

   {  // Values
      final List<Widget> values = makeValueSliders(
         post: post,
	 ranges: ranges,
	 divisions: divisions,
	 onValueChanged: onValueChanged,
      );

      foo.addAll(values);
   }

   { // Send cancel
      //Widget w1 = createRaisedButton(
      //   () {onSearchPressed(0);},
      //   g.param.cancel,
      //   stl.expTileCardColor,
      //   Colors.black,
      //);

      Widget w2 = createRaisedButton(
	 () {onSearchPressed(2);},
	 g.param.filterAppBarTitle,
	 stl.colorScheme.secondary,
	 stl.colorScheme.onSecondary,
      );

      //Row r = Row(children: <Widget>[Expanded(child: w1), Expanded(child: w2)]);
      foo.add(Padding(padding: EdgeInsets.only(top: stl.leftIndent), child: w2));
   }

   return ListView.builder(
      padding: const EdgeInsets.all(3.0),
      itemCount: foo.length,
      itemBuilder: (BuildContext ctx, int i) { return foo[i]; },
   );
}

Widget wrapDetailRowOnCard(Widget body)
{
   return Card(
      margin: const EdgeInsets.only(
       left: 1.5, right: 1.5, top: 0.0, bottom: 0.0
      ),
      color: stl.colorScheme.background,
      child: body,
      elevation: 0.0,
      shape: RoundedRectangleBorder(
         borderRadius: BorderRadius.all(Radius.circular(0.0)),
      ),
   );
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
            localizationsDelegates: [
               GlobalMaterialLocalizations.delegate,
               GlobalWidgetsLocalizations.delegate,
               GlobalCupertinoLocalizations.delegate,
            ],
         supportedLocales: [
            const Locale('de'),
            const Locale('pt'),
            const Locale('es'),
            const Locale('fr'),
         ],
      );
   }
}

Widget makeAppScaffoldWdg({
   OnPressedFn7 onWillPops,
   ScrollController scrollCtrl,
   Widget appBarTitle,
   Widget appBarLeading,
   Widget floatBut,
   Widget body,
   TabBar tabBar,
   List<Widget> actions,
}) {
   return WillPopScope(
      onWillPop: () async { return onWillPops();},
      child: Scaffold(
	 body: NestedScrollView(
	    controller: scrollCtrl,
	    body: body,
	    headerSliverBuilder: (BuildContext ctx, bool innerBoxIsScrolled)
	    {
	       return <Widget>[
		  SliverAppBar(
		     title: appBarTitle,
		     pinned: true,
		     floating: true,
		     forceElevated: innerBoxIsScrolled,
		     bottom: tabBar,
		     actions: actions,
		     leading: appBarLeading,
		  ),
	       ];
	    },
	 ),
	 backgroundColor: Colors.white,
	 floatingActionButton: floatBut,
      ),
   );
}

Widget makeWebScaffoldWdg({
   Widget body,
   Widget appBar,
   OnPressedFn7 onWillPopScope,
}) {
   return WillPopScope(
         onWillPop: () async { return onWillPopScope();},
         child: Scaffold(
            appBar : appBar,
            body: body,
            backgroundColor: Colors.white,
      ),
   );
}

List<Widget> makeTabWdgs({
   BuildContext ctx,
   List<int> counters,
   List<double> opacities,
}) {
   List<Widget> list = List<Widget>();

   for (int i = 0; i < g.param.tabNames.length; ++i) {
      Widget w = makeTabWidget(
	 ctx,
	 counters[i],
	 g.param.tabNames[i],
	 opacities[i]
      );

      list.add(w);
   }

   return list;
}

TabBar makeTabBar(
   BuildContext ctx,
   List<int> counters,
   TabController tabCtrl,
   List<double> opacities,
   bool isFwd,
) {
   if (isFwd)
      return null;

   List<Widget> wdgs = makeTabWdgs(
      ctx: ctx,
      counters: counters,
      opacities: opacities,
   );

   List<Widget> tabs = List<Widget>();
   for (int i = 0; i < wdgs.length; ++i)
      tabs.add(Tab(child: wdgs[i]));

   return TabBar(
      controller: tabCtrl,
      indicatorColor: Colors.white,
      tabs: tabs,
   );
}

Widget makeFaButton(
   int nOwnPosts,
   OnPressedFn0 onNewPost,
   OnPressedFn0 onFwdChatMsg,
   int lpChats,
   int lpChatMsgs,
) {
   if (nOwnPosts != -1 && nOwnPosts == 0)
      return SizedBox.shrink();

   if (lpChats == 0 && lpChatMsgs != 0)
      return SizedBox.shrink();

   IconData id = stl.newPostIcon;
   if (lpChats != 0 && lpChatMsgs != 0) {
      return FloatingActionButton(
         backgroundColor: stl.colorScheme.secondary,
	 mini: false,
         child: Icon(
            Icons.send,
            color: stl.colorScheme.onSecondary,
         ),
         onPressed: onFwdChatMsg,
      );
   }

   if (lpChats != 0)
      return SizedBox.shrink();

   if (onNewPost == null)
      return SizedBox.shrink();

   return FloatingActionButton(
      backgroundColor: stl.colorScheme.secondary,
      mini: false,
      child: Icon(id,
         color: stl.colorScheme.onSecondary,
      ),
      onPressed: onNewPost,
   );
}

List<Widget> makeFaButtons({
   final bool isWide,
   final bool hasFavPosts,
   final int nOwnPosts,
   final bool newSearchPressed,
   final List<List<Coord>> lpChats,
   final List<List<Coord>> lpChatMsgs,
   final OnPressedFn0 onNewPost,
   final OnPressedFn1 onFwdSendButton,
   final OnPressedFn0 onSearch,
}) {
   List<Widget> ret = List<Widget>(g.param.tabNames.length);

   ret[0] = makeFaButton(
      nOwnPosts,
      onNewPost,
      () {onFwdSendButton(0);},
      lpChats[0].length,
      lpChatMsgs[0].length
   );

   ret[1] = makeFAButtonMiddleScreen(
      onSearchScreen: newSearchPressed,
      isWide: isWide,
      hasFavPosts: hasFavPosts,
      onSearch: onSearch,
   );

   ret[2] = makeFaButton(
      -1,
      null,
      () {onFwdSendButton(2);},
      lpChats[2].length,
      lpChatMsgs[2].length,
   );

   return ret;
}

Widget makeFAButtonMiddleScreen({
   final bool onSearchScreen,
   final bool isWide,
   final bool hasFavPosts,
   final OnPressedFn0 onSearch,
}) {
   //print('$onSearchScreen $isWide $hasFavPosts');
   if (onSearchScreen || (isWide && !hasFavPosts))
      return SizedBox.shrink();

   return FloatingActionButton(
      onPressed: onSearch,
      backgroundColor: stl.colorScheme.secondary,
      mini: false,
      child: Icon(
	 Icons.search,
	 color: stl.colorScheme.onSecondary,
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
   int tab,
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

   final double screenWidth = makeMaxWidth(ctx, tab);
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
   int tab,
   ScrollController scrollCtrl,
   ChatMetadata ch,
   Function onChatMsgLongPressed,
   Function onDragChatMsg,
   String ownNick,
) {
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
                               stl.colorScheme.primary,
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
	    tab,
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
      overflow: TextOverflow.ellipsis,
      style: Theme.of(ctx).textTheme.caption.copyWith(
         color: bodyTxtColor,
      ),
   );

   String nick = ch.nick;
   if (ch.msgs[i].isFromThisApp())
      nick = ownNick;

   Text title = Text(nick,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
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

   //IconButton attachmentButton = IconButton(
   //   icon: Icon(Icons.add_a_photo),
   //   onPressed: onAttachment,
   //   color: stl.colorScheme.primary,
   //);

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
   int tab,
   ChatMetadata ch,
   TextEditingController ctrl,
   ScrollController scrollCtrl,
   int nLongPressed,
   FocusNode chatFocusNode,
   String postSummary,
   int dragedIdx,
   bool showChatJumpDownButton,
   String avatar,
   String ownNick,
   OnPressedFn7 onWillPopScope,
   OnPressedFn0 onSendChatMsg,
   OnPressedFn10 onChatMsgLongPressed,
   OnPressedFn0 onFwdChatMsg,
   OnPressedFn11 onDragChatMsg,
   OnPressedFn4 onChatMsgReply,
   OnPressedFn0 onAttachment,
   OnPressedFn0 onCancelFwdLPChatMsg,
   OnPressedFn0 onChatJumpDown,
   OnPressedFn9 onWritingChat,
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
      tab,
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
            mini: false,
            onPressed: onChatJumpDown,
            backgroundColor: stl.colorScheme.secondary,
            child: Icon(Icons.expand_more,
               color: stl.colorScheme.onSecondary,
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
               stl.colorScheme.secondaryVariant,
               stl.colorScheme.onSecondary,
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
         onPressed: onFwdChatMsg,
      );

      actions.add(forward);

      title = Text('$nLongPressed',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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
             overflow: TextOverflow.ellipsis,
             style: stl.appBarLtTitle.copyWith(color: stl.colorScheme.onSecondary),
          ),
          dense: true,
          subtitle:
             Text(cps.subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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
	       backgroundColor: stl.colorScheme.secondary,
               leading: IconButton(
                  padding: EdgeInsets.all(0.0),
                  icon: Icon(Icons.arrow_back, color: stl.colorScheme.onSecondary),
                  onPressed: onWillPopScope,
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
   double opacity,
) {
   if (n == 0)
      return Center(child: Text(title));

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
          color: stl.colorScheme.secondaryVariant
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
      overflow: TextOverflow.ellipsis,
      style: stl.ltSubtitle,
   );

   Text titleW = Text(title,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
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
   [ () { freePayment(ctx);   }
   , () { print('===> pay1'); }
   , () { print('===> pay2'); }
   ];
   for (int i = 0; i < g.param.payments0.length; ++i) {
      Widget p = makePayPriceListTile(
         ctx,
         g.param.payments0[i],
         g.param.payments1[i],
         g.param.payments2[i],
         payments[i],
         stl.priceColors[i],
      );

      widgets.add(p);
   }

   return Card(
      margin: const EdgeInsets.only(
       left: 1.5, right: 1.5, top: 0.0, bottom: 0.0
      ),
      color: stl.colorScheme.background,
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
         color: stl.colorScheme.primary,
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
          node.getChildrenNames(g.param.langIdx),
          style: stl.ltSubtitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
      );

   Widget subtitle;
   return subtitle;
}

ListTile makeFilterListTitle(
   BuildContext ctx,
   Node child,
   Function onTap,
   Icon trailing,
) {
   Color avatarBgColor = stl.colorScheme.secondary;
   Color avatarTxtColor = stl.colorScheme.onSecondary;

   if (child.leafReach != 0) {
      avatarBgColor = stl.colorScheme.primary;
      avatarTxtColor = stl.colorScheme.onPrimary;
   }

   return
      ListTile(
          leading: CircleAvatar(
             child: Text(
                makeStrAbbrev(child.name(g.param.langIdx)),
                style: TextStyle(color: avatarTxtColor),
             ),
             backgroundColor: avatarBgColor,
          ),
          title: makeListTileTreeTitle(ctx, child,
                child.name(g.param.langIdx)),
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

Widget createRaisedButton(
   OnPressedFn0 onPressed,
   final String txt,
   Color color,
   Color textColor,
) {
   RaisedButton but = RaisedButton(
      child: Text(txt,
         style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: stl.mainFontSize,
            color: textColor,
         ),
      ),
      color: color,
      onPressed: onPressed,
   );

   return Center(child: ButtonTheme(minWidth: 100.0, child: but));
}

// Study how to convert this into an elipsis like whatsapp.
Container makeUnreadMsgsCircle(
   BuildContext ctx,
   int n,
   Color bgColor,
   Color textColor,
) {
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

   final double width = makeTabWidth(ctx, cts.ownIdx);
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

List<Widget> makePostInRows(
   List<Node> nodes,
   int state,
) {
   List<Widget> list = List<Widget>();

   for (int i = 0; i < nodes.length; ++i) {
      if ((state & (1 << i)) == 0)
         continue;

      Text text = Text(' ${nodes[i].name(g.param.langIdx)}',
         style: stl.tt.subtitle1.copyWith(
            color: stl.infoValueColor,
         ),
      );

      Row row = Row(children: <Widget>
      [ Icon(Icons.check, color: stl.colorScheme.primaryVariant)
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
               fontSize: stl.subtitleFontSize,
               color: Colors.grey[500],
            ),
         ),
      ),
   );
}

// Assembles the menu information.
List<Widget> makeTreeInfo(
   BuildContext ctx,
   Post post,
   List<Tree> trees,
) {
   List<Widget> list = List<Widget>();

   for (int i = 0; i < 2; ++i) {
      List<int> tmp = post.location;
      if (i == 1)
	 tmp = post.product;

      list.add(makePostSectionTitle(ctx, g.param.newPostTabNames[i]));
      List<String> names = loadNames(trees[i].root.first, tmp, g.param.langIdx);

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
   Node exDetailsRootNode,
) {
   // Post details varies according to the first index of the products
   // entry in the menu.
   final int idx = post.getProductDetailIdx();
   if (idx == -1)
      return List<Widget>();

   List<Widget> list = List<Widget>();
   list.add(makePostSectionTitle(ctx, g.param.postExDetailsTitle));

   final int l1 = exDetailsRootNode.children[idx].children.length;
   for (int i = 0; i < l1; ++i) {
      final int n = exDetailsRootNode.children[idx].children[i].children.length;
      final int k = post.exDetails[i];
      if (k == -1 || k >= n)
	 continue;
      
      list.add(
         makePostRowElem(
            ctx,
            exDetailsRootNode.children[idx].children[i].name(g.param.langIdx),
            exDetailsRootNode.children[idx].children[i].children[k].name(g.param.langIdx),
         ),
      );
   }

   list.add(makePostSectionTitle(ctx, g.param.postRefSectionTitle));

   List<String> values = List<String>();
   values.add(post.nick);
   values.add('${post.from}');

   int date;
   if (post.id == -1) {
      // We are publishing.
      values.add('');
      date = DateTime.now().millisecondsSinceEpoch;
   } else {
      values.add('${post.id}');
      date = post.date;
   }

   values.add(makeDateString2(date));

   for (int i = 0; i < values.length; ++i)
      list.add(makePostRowElem(ctx, g.param.descList[i], values[i]));

   return list;
}

List<Widget> makePostInDetails(
   BuildContext ctx,
   Post post,
   Node inDetailsRootNode)
{
   List<Widget> all = List<Widget>();

   final int i = post.getProductDetailIdx();
   if (i == -1)
      return List<Widget>();

   final int l1 = inDetailsRootNode.children[i].children.length;
   for (int j = 0; j < l1; ++j) {
      List<Widget> foo = makePostInRows(
         inDetailsRootNode.children[i].children[j].children,
         post.inDetails[j],
      );

      if (foo.length != 0) {
         all.add(makePostSectionTitle(
               ctx,
               inDetailsRootNode.children[i].children[j].name(g.param.langIdx),
            ),
         );
         all.addAll(foo);
      }
   }

   return all;
}

Card putPostElemOnCard(List<Widget> list, double padding)
{
   Column col = Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      children: list,
   );

   return Card(
      elevation: 0.0,
      //color: stl.colorScheme.background,
      color: Colors.white,
      margin: EdgeInsets.all(0.0),
      child: Padding(
         child: col,
         padding: EdgeInsets.all(padding),
      ),
      shape: RoundedRectangleBorder(
         borderRadius: BorderRadius.all(
            Radius.circular(0.0)
         ),
      ),
   );
}

Widget makePostDescription(
   BuildContext ctx,
   int tab,
   String desc,
) {
   final double width = makeMaxWidth(ctx, tab);

   return ConstrainedBox(
      constraints: BoxConstraints(
         maxWidth: stl.infoWidthFactor * width,
         minWidth: stl.infoWidthFactor * width,
      ),
      child: Text(
         desc,
         overflow: TextOverflow.ellipsis,
         style: stl.textField,
      ),
   );
}

List<Widget> assemblePostRows(
   BuildContext ctx,
   int tab,
   Post post,
   List<Tree> menu,
   Node exDetailsRootNode,
   Node inDetailsRootNode,
) {
   List<Widget> all = List<Widget>();
   all.addAll(makePostValues(ctx, post));
   all.addAll(makeTreeInfo(ctx, post, menu));
   all.addAll(makePostExDetails(ctx, post, exDetailsRootNode));
   all.addAll(makePostInDetails(ctx, post, inDetailsRootNode));
   if (post.description.isNotEmpty) {
      all.add(makePostSectionTitle(ctx, g.param.postDescTitle));
      all.add(makePostDescription(ctx, tab, post.description));
   }

   return all;
}

String makeTreeItemStr(Node root, List<int> nodeCoordinate)
{
   if (nodeCoordinate.isEmpty)
      return '';

   final List<String> names = loadNames(
      root,
      nodeCoordinate,
      g.param.langIdx,
   );

   final int l = names.length;

   if (l == 1)
      return names.first;

   final String a = names[l - 2];
   final String b = names[l - 1];

   return '$a - $b';
}

ThemeData makeExpTileThemeData()
{
   return ThemeData(
      accentColor: Colors.black,
      unselectedWidgetColor: stl.colorScheme.primary,
      textTheme: TextTheme(
         subtitle1: TextStyle(
            color: Colors.black,
         ),
      ),
   );
}

String makePriceStr(int price)
{
   final String s = price.toString();
   return 'R\$$s';
}

Widget makeTextWdg(
   String str,
   double paddingTop,
   double paddingBot,
   double paddingLeft,
   double paddingRight,
   FontWeight fw,
) {
   return Padding(
      child: Text(str,
         style: TextStyle(
            color: Colors.black,
	    fontSize: stl.subtitleFontSize,
	    fontWeight: fw,
         ),
         overflow: TextOverflow.ellipsis,
      ),
      padding: EdgeInsets.only(right: paddingRight, left: paddingLeft, top: paddingTop, bottom: paddingBot),
   );
}

Widget makeAddOrRemoveWidget({
   OnPressedFn0 onPressed,
   IconData icon,
   Color color,
}) {
   return Padding(
      padding: const EdgeInsets.all(stl.imgInfoWidgetPadding),
      child: IconButton(
         onPressed: onPressed,
	 padding: EdgeInsets.all(0.0),
         icon: Icon(icon,
            color: color,
            //size: 30.0,
         ),
      ),
   );
}

Widget makeImgTextPlaceholder(final String str)
{
   return Text(str,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
         color: stl.colorScheme.background,
         fontSize: stl.tt.headline6.fontSize,
      ),
   );
}

List<Widget> makePostButtons({
   int pinDate,
   OnPressedFn0 onDelPost,
   OnPressedFn0 onSharePost,
   OnPressedFn0 onPinPost,
}) {
   IconButton remove = IconButton(
      padding: EdgeInsets.all(0.0),
      onPressed: onDelPost,
      icon: Icon(
         Icons.clear,
         color: Colors.grey,
      ),
   );

   IconButton share = IconButton(
      padding: EdgeInsets.all(0.0),
      onPressed: onSharePost,
      color: stl.colorScheme.primary,
      icon: Icon(Icons.share,
         color: stl.colorScheme.secondary,
      ),
   );

   IconData pinIcon = pinDate == 0 ? Icons.place : Icons.pin_drop;

   IconButton pin = IconButton(
      padding: EdgeInsets.all(0.0),
      onPressed: onPinPost,
      icon: Icon(
         pinIcon,
         color: Colors.brown,
      ),
   );

   return <Widget>[remove, share, pin];
}

Widget makeNewPostDialogWdg({
   final double width,
   final double height,
   final Widget title,
   final double indent,
   final List<Widget> list,
   final List<Widget> actions,
   final EdgeInsets insetPadding = const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
}) {
   ListView lv = ListView.separated(
      separatorBuilder: (BuildContext context, int index)
	 { return stl.alertDivider; },
      itemCount: list.length,
      itemBuilder: (BuildContext ctx, int i)
	 { return list[i]; }
   );

   return AlertDialog(
      title: title,
      contentPadding: EdgeInsets.all(indent),
      actions: actions,
      insetPadding: insetPadding,
      backgroundColor: Colors.grey[200],
      content: Container(
	 constraints: BoxConstraints(maxHeight: height, maxWidth: width),
         width: width,
         height: height,
         child: lv,
	 decoration: BoxDecoration(
	    color: Colors.white,
	    shape: BoxShape.rectangle,
            borderRadius: BorderRadius.all(const Radius.circular(stl.cornerRadius)),
	 ),
      ),
      shape: RoundedRectangleBorder(
	 borderRadius: BorderRadius.all(
	    Radius.circular(stl.cornerRadius)
	 ),
	 //side: BorderSide(width: 1.0, color: Colors.grey),
      ),
   );
}

//------------------------------------------------------------------------------------
class InDetailsView extends StatefulWidget {
   int state;
   final String title;
   final List<String> names;

   @override
   InDetailsViewState createState() => InDetailsViewState();
   InDetailsView(
   { @required this.state
   , @required this.title
   , @required this.names
   });
}

class InDetailsViewState extends State<InDetailsView> with TickerProviderStateMixin {

   @override
   void dispose()
   {
      super.dispose();
   }

   @override
   void initState()
   {
      super.initState();
   }

   void _onPressed(bool v, int i)
   {
      setState(() {widget.state ^= 1 << i;});
   }

   void _onOkPressed(BuildContext ctx)
   {
      Navigator.pop(ctx, widget.state);
   }

   @override
   Widget build(BuildContext ctx)
   {
      final FlatButton ok = FlatButton(
	 child: Text(g.param.ok, style: TextStyle(color: stl.colorScheme.primary)),
	 onPressed: () {_onOkPressed(ctx);},
      );

      List<Widget> list = makeCheckBoxes(
	 widget.state,
	 widget.names,
	 _onPressed,
      );

      final double width = makeDialogWidthHeight(ctx, cts.ownIdx);
      return makeNewPostDialogWdg(
	 width: width,
	 height: width,
	 title: Text(widget.title, style: stl.newPostTitleLT),
	 indent: stl.newPostPadding,
	 list: list,
	 actions: <FlatButton>[ok],
      );
   }
}

//--------------------------------------------------------------------------------------
class ExDetailsView extends StatefulWidget {
   final String title;
   final List<String> names;
   final int onIdx;

   @override
   ExDetailsViewState createState() => ExDetailsViewState();
   ExDetailsView(
   { @required this.title
   , @required this.names
   , @required this.onIdx
   });
}

class ExDetailsViewState extends State<ExDetailsView> with TickerProviderStateMixin {

   @override
   void dispose()
   {
      super.dispose();
   }

   @override
   void initState()
   {
      super.initState();
   }

   void _onPressed(BuildContext ctx, bool v, int i)
   {
      Navigator.pop(ctx, v ? i : -1);
   }

   void _onOkPressed(BuildContext ctx)
   {
      Navigator.pop(ctx);
   }

   @override
   Widget build(BuildContext ctx)
   {
      List<Widget> exDetails = List<Widget>();
      for (int i = 0; i < widget.names.length; ++i) {
	 CheckboxListTile cb = CheckboxListTile(
	    dense: true,
	    title: Text(widget.names[i], style: stl.newPostTitleLT),
	    value: i == widget.onIdx,
	    onChanged: (bool v) { _onPressed(ctx, v, i); },
	    activeColor: stl.colorScheme.primary,
	    isThreeLine: false,
	 );

	 Align a = Align(alignment: Alignment.centerLeft, child: cb);
	 exDetails.add(a);
      }

      final FlatButton ok = FlatButton(
	 child: Text(g.param.ok, style: TextStyle(color: stl.colorScheme.primary)),
	 onPressed: () {_onOkPressed(ctx);},
      );

      final double width = makeDialogWidthHeight(ctx, cts.ownIdx);
      return makeNewPostDialogWdg(
	 width: width,
	 height: width,
	 title: Text(widget.title, style: stl.newPostSubtitleLT),
	 indent: stl.newPostPadding,
	 list: exDetails,
	 actions: <FlatButton>[ok],
      );
   }
}

//---------------------------------------------------------------

class PostDescription extends StatefulWidget {
   @override
   PostDescriptionState createState() => PostDescriptionState();
   PostDescription();
}

class PostDescriptionState extends State<PostDescription> with TickerProviderStateMixin {
   TextEditingController _txtCtrl = TextEditingController();

   @override
   void dispose()
   {
      _txtCtrl.dispose();
      super.dispose();
   }

   @override
   void initState()
   {
      super.initState();
   }

   @override
   Widget build(BuildContext ctx)
   {
      TextField tf = TextField(
	 autofocus: true,
	 controller: _txtCtrl,
	 keyboardType: TextInputType.multiline,
	 maxLines: null,
	 maxLength: 1000,
	 style: stl.textField,
	 decoration: InputDecoration.collapsed(
	    hintText: g.param.newPostTextFieldHist,
	 ),
      );

      Padding content = Padding(
	 padding: EdgeInsets.all(10.0),
	 child: tf,
      );

      final FlatButton ok = FlatButton(
	 child: Text(g.param.ok),
	 onPressed: ()
	 {
	    Navigator.pop(ctx, _txtCtrl.text);
	 });

      return AlertDialog(
	 contentPadding: EdgeInsets.all(stl.newPostPadding),
	 title: Text(
            g.param.postDescTitle,
	    style: stl.newPostTitleLT,
	 ),
	 content: content,
	 actions: <Widget>[ok],
      );
   }
}

//---------------------------------------------------------------------

class TreeView extends StatefulWidget {
   final Node root;
   final int tab;

   @override
   TreeViewState createState() => TreeViewState();

   TreeView({@required this.root, @required this.tab});
}

class TreeViewState extends State<TreeView> with TickerProviderStateMixin {
   List<Node> _stack = List<Node>();

   @override
   void dispose()
   {
      super.dispose();
   }

   @override
   void initState()
   {
      super.initState();
      _stack = <Node>[widget.root];
   }

   void _onPostLeafPressed(BuildContext ctx, int i)
   {
      _stack.add(_stack.last.children[i]);
      _onOk(ctx);
      setState(() { });
   }

   void _onOk(BuildContext ctx)
   {
      List<int> code = <int>[];
      if (_stack.last.code.isNotEmpty)
	 code = _stack.last.code;

      Navigator.pop(ctx, code);
      _stack = <Node>[widget.root];
   }

   void _onPostNodePressed(BuildContext ctx, int i)
   {
      // We continue pushing on the stack if the next screen will have
      // only one menu option.
      do {
         Node o = _stack.last.children[i];
         _stack.add(o);
         i = 0;
      } while (_stack.last.children.length == 1);

      final int length = _stack.last.children.length;

      assert(length != 1);

      if (length == 0)
         _onOk(ctx);

      setState(() { });
   }

   void _onBack(BuildContext ctx)
   {
      setState((){
	 _stack.removeLast();
	 if (_stack.isEmpty)
	    Navigator.pop(ctx);
      });
   }

   void _onCancel(BuildContext ctx)
   {
      setState((){ Navigator.pop(ctx); });
   }

   @override
   Widget build(BuildContext ctx)
   {
      if (_stack.isEmpty)
	 return SizedBox.shrink();

      List<Widget> locWdgs = makeNewPostTreeWdgs(
	 ctx: ctx,
	 tab: widget.tab,
	 node: _stack.last,
	 onLeafPressed: (int i) {_onPostLeafPressed(ctx, i);},
	 onNodePressed: (int i) {_onPostNodePressed(ctx, i);},
      );

      final String titleStr = _stack.join(', ');

      Widget titleWdg = RichText(
	 text: TextSpan(
	    text: '${g.param.newPostTabNames[0]}: ',
	    style: stl.newPostTitleLT,
	    children: <TextSpan>
	    [ TextSpan(
		 text: titleStr,
		 style: stl.newPostTitleLT.copyWith(color: stl.colorScheme.secondary),
	      ),
	    ],
	 ),
      );

      FlatButton back =  FlatButton(
	 child: Text(g.param.newFiltersFinalScreenButton[0],
	    style: TextStyle(color: stl.colorScheme.primary),
	 ),
	 onPressed: () {_onBack(ctx);},
      );

      FlatButton cancel =  FlatButton(
	 child: Text(g.param.cancel,
	    style: TextStyle(color: stl.colorScheme.primary),
	 ),
	 onPressed: () {_onCancel(ctx);},
      );

      FlatButton ok =  FlatButton(
	 child: Text(g.param.ok,
	    style: TextStyle(color: stl.colorScheme.primary),
	 ),
	 onPressed: () {_onOk(ctx);},
      );

      final double width = makeDialogWidthHeight(ctx, cts.ownIdx);
      return makeNewPostDialogWdg(
	 width: width,
	 height: width,
	 title: titleWdg,
	 indent: stl.newPostPadding,
	 list: locWdgs,
	 actions: <FlatButton>[back, cancel, ok],
      );
   }
}

//---------------------------------------------------------------------

class PostWidget extends StatefulWidget {
   int tab;
   Post post;
   Node exDetailsRootNode;
   Node inDetailsRootNode;
   List<PickedFile> imgFiles;
   List<Tree> trees;
   OnPressedFn2 onAddPhoto;
   OnPressedFn1 onExpandImg;
   OnPressedFn0 onAddPostToFavorite;
   OnPressedFn0 onDelPost;
   OnPressedFn0 onSharePost;
   OnPressedFn0 onReportPost;
   OnPressedFn0 onPinPost;

   @override
   PostWidgetState createState() => PostWidgetState();

   PostWidget(
   { @required this.tab
   , @required this.post
   , @required this.exDetailsRootNode
   , @required this.inDetailsRootNode
   , @required this.imgFiles
   , @required this.trees
   , @required this.onAddPhoto
   , @required this.onExpandImg
   , @required this.onAddPostToFavorite
   , @required this.onDelPost
   , @required this.onSharePost
   , @required this.onReportPost
   , @required this.onPinPost
   });
}

class PostWidgetState extends State<PostWidget> with TickerProviderStateMixin {

   @override
   void dispose()
   {
      super.dispose();
   }

   @override
   void initState()
   {
      super.initState();
   }

   Future<void> _onShowDetails(BuildContext ctx) async
   {
      final int code = await showDialog<int>(
	 context: ctx,
	 builder: (BuildContext ctx2)
	 {
	    final int tab = cts.searchIdx;
	    Widget detailsWdg = makePostDetailsWdg(
	       ctx: ctx2,
	       tab: tab,
	       post: widget.post,
	       exDetailsRootNode: widget.exDetailsRootNode,
	       inDetailsRootNode: widget.inDetailsRootNode,
	       trees: widget.trees,
	       imgFiles: widget.imgFiles,
	       onAddPhoto: widget.onAddPhoto,
	       onExpandImg: widget.onExpandImg,
	       onReportPost: () 
	          {
		     Navigator.of(ctx).pop();
		     widget.onReportPost();
		  },
	    );

            final
	    FlatButton ok = FlatButton(
	       child: Text(g.param.newFiltersFinalScreenButton[0]),
	       onPressed: () { Navigator.of(ctx).pop(); },
	    );

	    List<Widget> actions = List<Widget>();

	    final double width = makeTabWidth(ctx, tab);
	    if (widget.tab == cts.searchIdx) {
	       ChatMetadata cm = ChatMetadata(
		 peer: widget.post.from,
		 nick: widget.post.nick,
		 avatar: widget.post.avatar,
		 date: DateTime.now().millisecondsSinceEpoch,
		 lastChatItem: ChatItem(),
	       );

	       Widget tmp = makeChatListTile(
		  ctx: ctx,
		  chat: cm,
		  now: 0,
		  isFwdChatMsgs: false,
		  avatar: '',
		  padding: stl.chatListTilePadding,
		  elevation: 2.0,
		  onChatLeadingPressed: () {},
		  onChatLongPressed: () {},
		  onStartChatPressed: () { Navigator.of(ctx).pop(); widget.onAddPostToFavorite(); },
	       );
               
	       actions.add(SizedBox(width: width, child: tmp));
	    }

	    const double insetPadding = 10.0;
	    final double height = makeMaxHeight(ctx);
	    Widget ret = makeNewPostDialogWdg(
	       width: width,
	       height: height,
               title: null,
	       indent: stl.newPostPadding,
	       list: <Widget>[detailsWdg],
               actions: actions,
	       insetPadding: const EdgeInsets.only(
	          left: 0.0,
		  right: 0.0,
		  top: insetPadding,
		  bottom: insetPadding,
	       ),
	    );

	    return Stack(children: <Widget>
               [ ret
	       , Positioned(
		   right: 0.0,
		   top: 0.0,
		   child: Card(
		      elevation: 0.0,
		      color: Colors.white.withOpacity(0.3),
		      margin: EdgeInsets.only(
		         top: stl.newPostPadding + insetPadding,
		         right: insetPadding,
		      ),
		      child: IconButton(
		         onPressed:  () {Navigator.of(ctx).pop();},
		         //padding: EdgeInsets.all(0.0),
		         icon: Icon(Icons.clear, color: Colors.black),
		      ),
		    ),
		 ),
	       ],
	    );
	 },
      );
   }

   @override
   Widget build(BuildContext ctx)
   {
      //Text owner = Text(
      //   widget.post.nick,
      //   maxLines: 1,
      //   overflow: TextOverflow.ellipsis,
      //   style: TextStyle(
      //      fontSize: stl.listTileSubtitleFontSize,
      //      color: Colors.grey[600],
      //      fontWeight: FontWeight.normal,
      //   ),
      //);

      final List<Widget> buttons = makePostButtons(
	 pinDate: widget.post.pinDate,
	 onDelPost: widget.onDelPost,
	 onSharePost: widget.onSharePost,
	 onPinPost: widget.onPinPost,
      );

      final String dateStr = makeDateString2(widget.post.date);
      Widget dateWdg = makeTextWdg(dateStr, 0.0, 0.0, 0.0, 0.0, FontWeight.normal);
      List<Widget> buttonWdgs = List<Widget>();
      //buttonWdgs.add(Expanded(child: Padding(child: owner, padding: const EdgeInsets.only(left: 10.0))));
      buttonWdgs.add(Expanded(child: Padding(child: dateWdg, padding: const EdgeInsets.only(left: 10.0))));

      if (widget.tab == cts.searchIdx) {
	 if (!kIsWeb)
	    buttonWdgs.add(buttons[1]);
	 //buttonWdgs.add(Expanded(child: buttons[2]));
      } else {
	 if (!kIsWeb)
	    buttonWdgs.add(Expanded(child: buttons[1]));
	 buttonWdgs.add(Expanded(child: buttons[2]));
      }

      Row buttonsRow = Row(children: buttonWdgs);

      final double imgAvatarWidth = makeImgAvatarWidth(ctx, widget.tab);

      Widget imgWdg;
      if (widget.post.images.isNotEmpty) {
	 Container img = Container(
	    //margin: const EdgeInsets.only(top: 10.0),
	    margin: const EdgeInsets.all(0.0),
	    child: makeNetImgBox(
	       imgAvatarWidth,
	       imgAvatarWidth,
	       widget.post.images.first,
	       BoxFit.cover,
	    ),
	 );

	 Widget kmText = makeTextWdg(makeRangeStr(widget.post, 2), 3.0, 3.0, 3.0, 3.0, FontWeight.normal);
	 Widget priceText = makeTextWdg(makeRangeStr(widget.post, 0), 3.0, 3.0, 3.0, 3.0, FontWeight.normal);

	 imgWdg = Stack(
	    //alignment: Alignment.topLeft,
	    children: <Widget>
	    [ img
	    , Positioned(
		 left: 0.0,
		 bottom: 0.0,
		 child: Card(child: kmText,
		    elevation: 0.0,
		    color: Colors.white.withOpacity(0.7),
		    margin: EdgeInsets.all(5.0),
		 ),
	      )
	    , Positioned(
		 left: 0.0,
		 top: 0.0,
		 child: Card(child: priceText,
		    elevation: 0.0,
		    color: Colors.white.withOpacity(0.7),
		    margin: EdgeInsets.all(5.0),
		 ),
	      )
	    ],
	 );
      } else if (widget.imgFiles.isNotEmpty) {
	 imgWdg = getImage(
	    path: widget.imgFiles.last.path,
	    width: imgAvatarWidth,
	    height: imgAvatarWidth,
	    fit: BoxFit.cover,
	    filterQuality: FilterQuality.high,
	 );
      } else {
	 Widget w = makeImgTextPlaceholder(g.param.addImgMsg);
	 imgWdg = makeImgPlaceholder(
	    imgAvatarWidth,
	    imgAvatarWidth,
	    w,
	 );
      }

      List<Widget> row1List = List<Widget>();

      // The add a photo button should appear only when this function is
      // called on the new posts tab. We determine that in the
      // following way.
      if (widget.post.images.isEmpty && (widget.imgFiles.length < cts.maxImgsPerPost)) {
	 Widget addImgWidget = makeAddOrRemoveWidget(
	    onPressed: () {widget.onAddPhoto(ctx, -1);},
	    icon: Icons.add_a_photo,
	    color: stl.colorScheme.primary,
	 );

	 Stack st = Stack(
	    alignment: Alignment(0.0, 0.0),
	    children: <Widget>
	    [ imgWdg
	    , Card(child: addImgWidget,
		    elevation: 0.0,
		    color: Colors.white.withOpacity(0.7),
		    margin: EdgeInsets.all(0.0),
		 )
	    ],
	 );

	 row1List.add(st);
      } else {
	 row1List.add(imgWdg);
      }

      final String locationStr =
         makeTreeItemStr(widget.trees[0].root.first, widget.post.location);
      final String modelStr =
	 makeTreeItemStr(widget.trees[1].root.first, widget.post.product);

      List<String> exDetailsNames = makeExDetailsNamesAll(
         widget.exDetailsRootNode,
	 widget.post.exDetails,
	 widget.post.getProductDetailIdx(),
	 g.param.langIdx,
      );

      List<String> inDetailsNames = makeInDetailNamesAll(
         widget.inDetailsRootNode,
	 widget.post.inDetails,
	 widget.post.getProductDetailIdx(),
	 g.param.langIdx,
      );

      Widget modelTitle = makeTextWdg(modelStr, 3.0, 3.0, 3.0, 3.0, FontWeight.w500);
      Widget location = makeTextWdg(locationStr, 0.0, 0.0, 0.0, 0.0, FontWeight.normal);

      Widget s1 = makeTextWdg(exDetailsNames.join(', '), 0.0, 0.0, 0.0, 0.0, FontWeight.normal);
      Widget s2 = makeTextWdg(inDetailsNames.join(', '), 0.0, 0.0, 0.0, 0.0, FontWeight.normal);

      final double widthCol2 = makePostTextWidth(ctx, widget.tab);

      Column infoWdg = Column(children: <Widget>
      [ Flexible(child: SizedBox(width: widthCol2, child: Padding(child: modelTitle, padding: EdgeInsets.only(left: 5.0))))
      , Flexible(child: SizedBox(width: widthCol2, child: Row(children: <Widget>[Icon(Icons.arrow_right, color: stl.infoKeyArrowColor), Expanded(child: s1)])))
      , Flexible(child: SizedBox(width: widthCol2, child: Row(children: <Widget>[Icon(Icons.arrow_right, color: stl.infoKeyArrowColor), Expanded(child: s2)])))
      , Flexible(child: SizedBox(width: widthCol2, child: Row(children: <Widget>[Icon(Icons.arrow_right, color: stl.infoKeyArrowColor), Expanded(child: location)])))
      //, Flexible(child: SizedBox(width: widthCol2, child: Row(children: <Widget>[Icon(Icons.arrow_right, color: stl.infoKeyArrowColor), Expanded(child: dateWdg)])))
      , Expanded(child: SizedBox(width: widthCol2, child: buttonsRow))
      ]);

      row1List.add(SizedBox(height: imgAvatarWidth, child: infoWdg));

      return RaisedButton(
	 color: Colors.white,
	 onPressed: () {_onShowDetails(ctx);},
	 elevation: 0.0,
	 child: Row(children: row1List),
	 padding: const EdgeInsets.all(0.0),
      );
   }
}

Widget makePostDetailsWdg({
   BuildContext ctx,
   int tab,
   final Post post,
   final Node exDetailsRootNode,
   final Node inDetailsRootNode,
   final List<Tree> trees,
   final List<PickedFile> imgFiles,
   OnPressedFn2 onAddPhoto,
   OnPressedFn1 onExpandImg,
   OnPressedFn0 onReportPost,
}) {
   List<Widget> rows = List<Widget>();

   Widget lv = makeImgListView2(
      ctx: ctx,
      width: makeTabWidth(ctx, tab),
      post: post,
      boxFit: BoxFit.cover,
      imgFiles: imgFiles,
      onExpandImg: (int j){onExpandImg(j);},
      addImg: onAddPhoto,
   );

   rows.add(lv);

   IconButton inapropriate = IconButton(
      padding: EdgeInsets.all(0.0),
      onPressed: onReportPost,
      icon: Icon(
         Icons.report,
         color: stl.colorScheme.primary,
      ),
   );

   rows.add(inapropriate);

   List<Widget> tmp = assemblePostRows(
      ctx,
      tab,
      post,
      trees,
      exDetailsRootNode,
      inDetailsRootNode,
   );

   rows.add(putPostElemOnCard(tmp, 4.0));

   return putPostElemOnCard(rows, 0.0);
}

Widget makeNewPost({
   final int screen,
   final Post post,
   final Node exDetailsRootNode,
   final Node inDetailsRootNode,
   final List<Tree> trees,
   final List<PickedFile> imgFiles,
   OnPressedFn2 onAddPhoto,
   OnPressedFn1 onExpandImg,
   OnPressedFn0 onAddPostToFavorite,
   OnPressedFn0 onDelPost,
   OnPressedFn0 onSharePost,
   OnPressedFn0 onReportPost,
   OnPressedFn0 onPinPost,
}) {
   return PostWidget(
     tab: screen,
     post: post,
     exDetailsRootNode: exDetailsRootNode,
     inDetailsRootNode: inDetailsRootNode,
     imgFiles: imgFiles,
     trees: trees,
     onAddPhoto: onAddPhoto,
     onExpandImg: onExpandImg,
     onAddPostToFavorite: onAddPostToFavorite,
     onDelPost: onDelPost,
     onSharePost: onSharePost,
     onReportPost: onReportPost,
     onPinPost: onPinPost,
   );
}

Widget makeEmptyTabText(String msg)
{
   return Padding(
      padding: EdgeInsets.all(20.0),
      child: Text(msg,
	 style: TextStyle(
	    fontSize: 16.0,
	    color: stl.colorScheme.primary,
	 ),
      ),
   );
}

Widget makeOwnEmptyScreenWidget({
   final OnPressedFn0 onPressed,
}) {
   Widget text = makeEmptyTabText(g.param.newPostMessage);

   Widget button = createRaisedButton(
      onPressed,
      g.param.newPostAppBarTitle,
      stl.colorScheme.secondary,
      stl.colorScheme.onSecondary,
   );

   return Center(
      child: Column(
	 mainAxisAlignment: MainAxisAlignment.center,
         children: <Widget>[text, button],
      ),
   );
}

Widget makeFavEmptyScreenWidget()
{
   Widget text = makeEmptyTabText(g.param.emptyFavMessage);
   return Center(child: text);
}

Widget makeNewPostLv({
   final int nNewPosts,
   final Node exDetailsRootNode,
   final Node inDetailsRootNode,
   final List<Post> posts,
   final List<Tree> trees,
   final OnPressedFn3 onExpandImg,
   final OnPressedFn2 onAddPostToFavorite,
   final OnPressedFn2 onDelPost,
   final OnPressedFn2 onSharePost,
   final OnPressedFn2 onReportPost,
   final OnPressedFn0 onNext,
}) {
   final int l = posts.length - nNewPosts;
   if (l == 0)
      return makeFavEmptyScreenWidget();

   final int shift = nNewPosts == 0 ? 0 : 1;
   // No controller should be assigned to this listview. This will
   // break the automatic hiding of the tabbar
   return ListView.separated(
      //key: PageStorageKey<String>('aaaaaaa'),
      padding: const EdgeInsets.all(0.0),
      itemCount: l + shift,
      separatorBuilder: (BuildContext context, int index)
      {
	 return Divider(color: Colors.black, height: 5.0);
      },
      itemBuilder: (BuildContext ctx, int i)
      {
         final int j = l - i - 1;
	 if (i == l) {
	    Widget ret = createRaisedButton(
	       onNext,
	       '+$nNewPosts', //g.param.next,
	       stl.colorScheme.secondary,
	       stl.colorScheme.onSecondary,
	    );

	    return Padding(
	       child: ret,
	       padding: const EdgeInsets.only(top: 20.0, bottom: 20.0),
	    );
	 }

         return makeNewPost(
	    screen: cts.searchIdx,
            post: posts[j],
            exDetailsRootNode: exDetailsRootNode,
            inDetailsRootNode: inDetailsRootNode,
            trees: trees,
            imgFiles: List<PickedFile>(),
            onAddPhoto: (var ctx, var i) {print('Error: Please fix.');},
            onExpandImg: (int k) {onExpandImg(j, k);},
            onAddPostToFavorite: () {onAddPostToFavorite(ctx, j);},
	    onDelPost: () {onDelPost(ctx, j);},
	    onSharePost: () {onSharePost(ctx, j);},
	    onReportPost: () {onReportPost(ctx, j);},
	    onPinPost: (){print('Noop20');},
         );
      },
   );
}

ListTile makeNewPostTreeWdg({
   Node child,
   OnPressedFn0 onLeafPressed,
   OnPressedFn0 onNodePressed,
}) {
   if (child.isLeaf()) {
      return ListTile(
	 //leading: CircleAvatar(
	 //   child: Text(makeStrAbbrev(child.name(g.param.langIdx)),
	 //      style: TextStyle(color: stl.colorScheme.onSecondary),
	 //   ),
	 //   backgroundColor: stl.colorScheme.secondary,
	 //),
	 title: Text(child.name(g.param.langIdx), style: stl.newPostTitleLT),
	 dense: true,
	 onTap: onLeafPressed,
	 enabled: true,
	 onLongPress: (){},
      );
   }
   
   return
      ListTile(
	 //leading: CircleAvatar(
	 //   child: Text(makeStrAbbrev(child.name(g.param.langIdx)),
	 //      style: TextStyle(
	 //         color: stl.colorScheme.onSecondary
	 //      ),
	 //   ),
	 //   backgroundColor: stl.colorScheme.secondary,
	 //),
	 title: Text(child.name(g.param.langIdx), style: stl.newPostTitleLT),
	 dense: true,
	 subtitle: Text(
	    child.getChildrenNames(g.param.langIdx),
	    maxLines: 1,
	    overflow: TextOverflow.ellipsis,
	    style: stl.newPostSubtitleLT,
	 ),
	 trailing: Icon(Icons.keyboard_arrow_right, color: stl.colorScheme.primary),
	 onTap: onNodePressed,
	 enabled: true,
	 isThreeLine: false,
      );
}

List<Widget> makeNewPostTreeWdgs({
   BuildContext ctx,
   int tab,
   Node node,
   OnPressedFn1 onLeafPressed,
   OnPressedFn1 onNodePressed,
}) {
   List<Widget> list = List<Widget>();

   for (int i = 0; i < node.children.length; ++i) {
      Node child = node.children[i];
      Widget o =  makeNewPostTreeWdg(
	 child: child,
	 onLeafPressed: () {onLeafPressed(i);},
	 onNodePressed: () {onNodePressed(i);},
      );
      list.add(SizedBox(width: makeMaxWidth(ctx, tab), child: o));
   }

   return list;
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
         overflow: TextOverflow.ellipsis,
         style: Theme.of(ctx).textTheme.subtitle.copyWith(
            color: stl.colorScheme.secondary,
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
         overflow: TextOverflow.ellipsis
      );

   return Row(children: <Widget>
   [ chooseMsgStatusIcon(ch.lastChatItem.status)
   , Expanded(
        child: Text(cps.subtitle,
           maxLines: 1,
           overflow: TextOverflow.ellipsis,
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

String makeDateString2(int date)
{
   date *= 1000;
   DateTime dateObj = DateTime.fromMillisecondsSinceEpoch(date);
   DateFormat format = Intl(g.param.localeName).date().add_yMEd().add_jm();
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
          stl.colorScheme.secondary,
          stl.colorScheme.onSecondary,
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
             stl.colorScheme.secondary,
             stl.colorScheme.onSecondary,
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

Widget makeChatListTile({
   BuildContext ctx,
   ChatMetadata chat,
   int now,
   bool isFwdChatMsgs,
   String avatar,
   double padding,
   double elevation,
   OnPressedFn0 onChatLeadingPressed,
   OnPressedFn0 onChatLongPressed,
   OnPressedFn0 onStartChatPressed,
}) {
   Color bgColor;
   if (chat.isLongPressed) {
      bgColor = stl.chatLongPressendColor;
   } else {
      bgColor = stl.colorScheme.background;
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
      onTap: onStartChatPressed,
      onLongPress: onChatLongPressed,
      subtitle: makeChatTileSubtitle(ctx, chat),
      leading: makeChatListTileLeading(
         chat.isLongPressed,
         avatar,
         selectColor(chat.peer.length),
         onChatLeadingPressed,
      ),
      title: Text(
         chat.getChatDisplayName(),
         maxLines: 1,
         overflow: TextOverflow.ellipsis,
         style: stl.ltTitle,
      ),
   );

   return Padding(
	 padding: EdgeInsets.all(padding),
	 child: Card(
	    child: lt,
	    color: bgColor,
	    margin: EdgeInsets.all(0.0),
	    elevation: elevation,
	    shape: RoundedRectangleBorder(
	       borderRadius: BorderRadius.all(
		  Radius.circular(stl.cornerRadius)
	       ),
	       //side: BorderSide(width: 1.0, color: Colors.grey),
	    ),
	 ),
   );
}

Widget makeChatsExp(
   BuildContext ctx,
   bool isFav,
   bool isFwdChatMsgs,
   int now,
   Post post,
   List<ChatMetadata> ch,
   OnPressedFn1 onPressed,
   OnPressedFn1 onLongPressed,
   OnPressedFn3 onLeadingPressed,
   Function onPinPost,
) {
   List<Widget> list = List<Widget>(ch.length);

   int nUnreadChats = 0;
   for (int i = 0; i < list.length; ++i) {
      final int n = ch[i].nUnreadMsgs;
      if (n > 0)
         ++nUnreadChats;

      Widget card = makeChatListTile(
         ctx: ctx,
         chat: ch[i],
         now: now,
         isFwdChatMsgs: isFwdChatMsgs,
         avatar: isFav ? post.avatar : ch[i].avatar,
	 padding: 0.0,
	 elevation: 0.0,
         onChatLeadingPressed: (){onLeadingPressed(post.id, i);},
         onChatLongPressed: () { onLongPressed(i); },
         onStartChatPressed: () { onPressed(i); },
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

  if (ch.length < 5) {
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
         '${ch.length} ${g.param.numberOfChatsSuffix}',
         '$nUnreadChats ${g.param.numberOfUnreadChatsSuffix}',
         ', ',
         false,
      );
   }

   bool expState = (ch.length < 6 && ch.length > 0)
                       || nUnreadChats != 0;

   // I have observed that if the post has no chats and a chat
   // arrives, the chat expansion will continue collapsed independent
   // whether expState is true or not. This is undesireble, so I will
   // add a special case to handle it below.
   if (nUnreadChats == 0)
      expState = true;

   return Theme(
      data: makeExpTileThemeData(),
      child: ExpansionTile(
         backgroundColor: stl.expTileCardColor,
         initiallyExpanded: expState,
         leading: stl.favIcon,
         //key: GlobalKey(),
         //key: PageStorageKey<int>(post.id),
         title: title,
         children: list,
      ),
   );
}

Widget wrapPostOnButton(
   BuildContext ctx,
   List<Widget> wlist,
   double elevation,
   Function onPressed)
{
   return RaisedButton(
      color: Colors.white,
      onPressed: onPressed,
      elevation: elevation,
      child: Column(children: wlist),
      padding: const EdgeInsets.all(0.0),
   );
}

Widget makeChatTab({
   final bool isFwdChatMsgs,
   final int screen,
   final Node exDetailsRootNode,
   final Node inDetailsRootNode,
   final List<Post> posts,
   final List<Tree> trees,
   final OnPressedFn3 onPressed,
   final OnPressedFn3 onLongPressed,
   final OnPressedFn1 onDelPost1,
   final OnPressedFn1 onPinPost1,
   OnPressedFn5 onUserInfoPressed,
   final OnPressedFn3 onExpandImg1,
   final OnPressedFn1 onSharePost,
   final OnPressedFn0 onPost,
}) {
   if (posts.length == 0) {
      if (screen == cts.ownIdx)
	 return makeOwnEmptyScreenWidget(
            onPressed: onPost,
	 );

      if (screen == cts.favIdx)
	 return makeFavEmptyScreenWidget();
   }

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
         OnPressedFn0 onPinPost = () {onPinPost1(i);};
         OnPressedFn0 onDelPost = () {onDelPost1(i);};
         OnPressedFn1 onExpandImg = (int j) {onExpandImg1(i, j);};

         if (isFwdChatMsgs) {
            onUserInfoPressed = (var a, var b, var c){};
            onPinPost = (){};
            onDelPost = (){};
         }

         Widget title = Text(
            makeTreeItemStr(trees[0].root.first, posts[i].location),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
         );

         // If the post contains no images, which should not happen,
         // we provide no expand image button.
         if (posts[i].images.isEmpty)
            onExpandImg = (int j){print('Error: post.images is empty.');};

	 Widget bbb = makeNewPost(
	    screen: screen,
            post: posts[i],
            exDetailsRootNode: exDetailsRootNode,
            inDetailsRootNode: inDetailsRootNode,
            trees: trees,
            imgFiles: List<PickedFile>(),
            onAddPhoto: (var a, var b) {print('Noop10');},
            onExpandImg: onExpandImg,
            onAddPostToFavorite:() {print('Noop14');},
	    onDelPost: onDelPost,
	    onSharePost: () {onSharePost(i);},
	    onReportPost:() {print('Noop18');},
	    onPinPost: onPinPost,
	 );

         Widget chatExpansion = makeChatsExp(
            ctx,
            screen == cts.favIdx,
            isFwdChatMsgs,
            DateTime.now().millisecondsSinceEpoch,
            posts[i],
            posts[i].chats,
            (int j) {onPressed(i, j);},
            (int j) {onLongPressed(i, j);},
            (int a, int b) {onUserInfoPressed(ctx, a, b);},
            onPinPost,
         );

         return Card(
            elevation: 2.0,
	    margin: EdgeInsets.only(bottom: 15.0),
	    color: Colors.grey[300],
	    child: Column(children: <Widget> [bbb, chatExpansion ]),
	 );
      },
   );
}

//_____________________________________________________________________

class DialogWithOp extends StatefulWidget {
   final Function getValueFunc;
   final Function setValueFunc;
   final Function onPostSelection;
   final String title;
   final String body;

   DialogWithOp(
      this.getValueFunc,
      this.setValueFunc,
      this.onPostSelection,
      this.title,
      this.body,
   );

   @override
   DialogWithOpState createState() => DialogWithOpState();
}

class DialogWithOpState extends State<DialogWithOp> {
   @override
   void initState()
   {
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
            await widget.onPostSelection();
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
         value: !widget.getValueFunc(),
         onChanged: (bool v) { setState(() {widget.setValueFunc(!v);}); },
         controlAffinity: ListTileControlAffinity.leading,
      );

      return SimpleDialog(
         title: Text(widget.title),
         children: <Widget>
         [ Padding(
              padding: EdgeInsets.all(25.0),
              child: Center(
                 child: Text(widget.body,
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

class AppState {
   Config cfg = Config();

   // The list of posts received from the server. Our own posts that the
   // server echoes back to us will be filtered out.
   List<Post> posts = List<Post>();

   // The list of posts the user has selected in the posts screen.
   // They are moved from posts to here.
   List<Post> favPosts = List<Post>();

   // Posts the user wrote itself and sent to the server. One issue we have to
   // observe is that if the post is received back it shouldn't be displayed
   // or duplicated on this list. The posts received from the server will not
   // be inserted in posts.
   //
   // The only posts inserted here are those that have been acked with
   // ok by the server, before that they will live in outPostsQueue
   List<Post> ownPosts = List<Post>();

   // Posts sent to the server that haven't been acked yet. At the
   // moment this queue will contain only one element. It is needed if
   // to handle the case where we go offline between a publish and a
   // publish_ack.
   Queue<Post> outPostsQueue = Queue<Post>();

   // Stores chat messages that cannot be lost in case the connection
   // to the server is lost. 
   Queue<AppMsgQueueElem> appMsgQueue = Queue<AppMsgQueueElem>();

   Persistency persistency = Persistency();

   AppState();

   Future<void> load() async
   {
      try {
	 await persistency.open();
      } catch (e) {
         print(e);
      }

      try {
         // Warning: The construction of Config depends on the
         // parameters that have been load above, but where not loaded
         // by the time it was inititalized. Ideally we would remove
         // the use of global variable from within its constructor,
         // for now I will construct it again before it is used to
         // initialize the db.
	 cfg = await persistency.loadConfig();
      } catch (e) {
         print(e);
      }

      try {
         final List<Post> posts = await persistency.loadPosts(g.param.rangesMinMax);
         for (Post p in posts) {
            if (p.status == 0) {
               ownPosts.add(p);
               for (Post o in ownPosts)
                  o.chats = await persistency.loadChatMetadata(o.id);
            } else if (p.status == 1) {
               posts.add(p);
            } else if (p.status == 2) {
               favPosts.add(p);
               for (Post o in favPosts)
                  o.chats = await persistency.loadChatMetadata(o.id);
            } else if (p.status == 3) {
               outPostsQueue.add(p);
            } else {
	       print('Wrong post status ${p.status}');
            }
         }

         ownPosts.sort(compPosts);
         favPosts.sort(compPosts);
      } catch (e) {
         print(e);
      }

      List<AppMsgQueueElem> tmp = await persistency.loadOutChatMsg();

      appMsgQueue = Queue<AppMsgQueueElem>.from(tmp.reversed);

      print('Login: ${cfg.appId}:${cfg.appPwd}');
   }

   Future<void> clearPosts() async
   {
      posts = List<Post>();
      await persistency.clearPosts();
   }

   Future<void> setDialogPreferences(int i, bool v) async
   {
      cfg.dialogPreferences[i] = v;
      await persistency.updateConfig(cfg);
   }

   Future<void> updateConfig() async
   {
      await persistency.updateConfig(cfg);
   }

   // Return the index where the post in located in favPosts.
   Future<int> moveToFavorite(int i) async
   {
      // i refers to a post in the posts array.  We have to prevent the user
      // from adding a chat twice. This can happen when he makes a new search,
      // since in that case the lastPostId will be updated to 0.

      Post post = posts[i];
      posts.removeAt(i);

      var f = (e) { return e.id == post.id; };

      final int a = favPosts.indexWhere(f);
      if (a != -1)
	 return a;
      
      post.status = 2;
      final int k = post.addChat(post.from, post.nick, post.avatar);
      await persistency.insertPost(post, ConflictAlgorithm.ignore);
      await persistency.insertChatOnPost2(post.id, post.chats[k]);

      favPosts.add(post);
      favPosts.sort(compPosts);

      return favPosts.indexWhere(f);
   }

   Future<void> delPostWithId(int i) async
   {
      await persistency.delPostWithId(posts[i].id);
      posts.removeAt(i);
   }

   Future<void>
   setChatAckStatus(String from, int postId, List<int> rowids, int status) async
   {
      List<Post> list = favPosts;
      IdxPair p = findChat(list, from, postId);
      if (IsInvalidPair(p)) {
	 list = ownPosts;
	 p = findChat(ownPosts, from, postId);
      }

      if (IsInvalidPair(p)) {
	 print('Chat not found: from = $from, postId = $postId');
	 return;
      }

      for (int rowid in rowids) {
	 final ChatMetadata cm = list[p.i].chats[p.j];
	 cm.setAckStatus(rowid, status);
	 cm.lastChatItem.status = status;

	 // Typically there won't be many rowids in this loop so it is fine to
	 // use await here. The ideal case however is to offer a List<ChatItem>
	 // interface in Persistency and use batch there.

	 await persistency.updateAckStatus(cm.lastChatItem, status, rowid, postId, from);
      }
   }

   Future<void>
   setCredentials(String id, String password) async
   {
      cfg.appId = id;
      cfg.appPwd = password;
      await persistency.updateConfig(cfg);
   }

   Future<int>
   setChatMessage(int postId, String peer, ChatItem ci, bool fav) async
   {
      List<Post> list = ownPosts;
      if (fav)
	 list = favPosts;

      final int i = list.indexWhere((e) { return e.id == postId;});
      assert(i != -1);

      Post post = list[i];
      // We have to make sure every unread msg is marked as read
      // before we receive any reply.
      final int j = post.getChatHistIdx(peer);
      assert(j != -1);

      final int rowid = await persistency.insertChatMsg(postId, peer, ci);
      ci.rowid = rowid;
      post.chats[j].addChatItem(ci);

      await persistency.insertChatOnPost(postId, post.chats[j]);

      post.chats.sort(compChats);
      list.sort(compPosts);
      return rowid;
   }

   Future<void> setNUnreadMsgs(int id, String from) async
   {
      await persistency.updateNUnreadMsgs(id, from);
   }

   Future<void> setPinPostDate(int i, bool fav) async
   {
      List<Post> list = ownPosts;
      if (fav)
	 list = favPosts;

      Post post = list[i];
      await persistency.updatePostPinDate(post.pinDate, post.id);
      post.pinDate = post.pinDate == 0 ? DateTime.now().millisecondsSinceEpoch : 0;
      list.sort(compPosts);
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
   // The trees holding the locations and product trees.
   List<Tree> _trees = List<Tree>();

   // The ex details tree root node.
   Node _exDetailsRoot;

   // The in details tree root node.
   Node _inDetailsRoot;

   AppState _appState = AppState();

   // Will be set to true if the user scrolls up a chat screen so that
   // the jump down button can be used
   List<bool> _showChatJumpDownButtons = List<bool>.filled(3, true);

   // Set to true when the user wants to change his email or nick or on
   // the first time the user opens the app.
   bool _goToRegScreen = false;

   // Set to true when the user wants to change his notification
   // settings.
   bool _goToNtfScreen = false;

   bool _goToInfoScreen = false;

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
   bool _newSearchPressed = false;

   // The temporary variable used to store the post the user sends or
   // the post the current chat screen is open, if any.
   List<Post> _posts = List<Post>(3);

   // The current chat, if any.
   List<ChatMetadata> _chats = List<ChatMetadata>(3);

   // The number of posts in the _appState.posts array that hasn't been seen
   // yet by the user.
   int _nNewPosts = 0;

   // This list will store the posts in _fav or _own chat screens that
   // have been long pressed by the user. However, once one post is
   // long pressed to select the others is enough to perform a simple
   // click.
   List<List<Coord>> _lpChats = List<List<Coord>>.filled(3, List<Coord>());

   // A temporary variable used to store forwarded chat messages.
   List<List<Coord>> _lpChatMsgs = List<List<Coord>>.filled(3, List<Coord>());

   Queue<dynamic> _wsMsgQueue = Queue<dynamic>();

   // When the user is on a chat screen and dragged a message or
   // clicked reply on a long-pressed message this index will be set
   // to the index that leads to the message. It will be set back to
   // -1 when
   //
   // 1. The message is sent
   // 2. The user cancels the operation.
   // 3. The user leaves the chat screen.
   List<int> _dragedIdxs = List<int>.filled(3, -1);

   TabController _tabCtrl;

   // Each tab gets one scroll controller.
   List<ScrollController> _scrollCtrl = List<ScrollController>.filled(3, ScrollController());

   List<ScrollController> _chatScrollCtrl = List<ScrollController>.filled(3, ScrollController());

   // Used for every screen that offers text input.
   TextEditingController _txtCtrl;

   // Used in some cases where two text fields are required.
   TextEditingController _txtCtrl2;
   List<FocusNode> _chatFocusNodes = List<FocusNode>.filled(3, FocusNode());

   HtmlWebSocketChannel websocket;
   //IOWebSocketChannel websocket;

   // This variable is set to the last time the app was disconnected
   // from the server, a value of -1 means we are connected.
   int _lastDisconnect = -1;

   // Used in the final new post screen to store the files while the
   // user chooses the images.
   List<PickedFile> _imgFiles = List<PickedFile>();

   // When the user clicks to send the post, we first request the image
   // filenames from the websocket server. This timer sets a limit on how long
   // we are willing to wait. During this time, the screen remains blocked for
   // the user. This will be changed when we implement filename requests over
   // HTTP and not websocket. The timer can be set differently in this case.
   Timer _filenamesTimer = Timer(Duration(seconds: 0), (){});

   // These indexes will be set to values different from -1 when the
   // user clics on an image to expand it.
   List<int> _expPostIdxs = List<int>.filled(3, -1);
   List<int> _expImgIdxs = List<int>.filled(3, -1);

   // Used to cache the fcm token.
   String _fcmToken = '';

   final FirebaseMessaging _firebaseMessaging = FirebaseMessaging();

   final ImagePicker _picker = ImagePicker();

   @override
   void initState()
   {
      super.initState();

      _tabCtrl = TabController(vsync: this, initialIndex: 1, length: 3);
      _txtCtrl = TextEditingController();
      _txtCtrl2 = TextEditingController();
      _tabCtrl.addListener(_tabCtrlChangeHandler);

      _chatScrollCtrl[cts.ownIdx].addListener(() {_chatScrollListener(cts.ownIdx);});
      _chatScrollCtrl[cts.favIdx].addListener(() {_chatScrollListener(cts.favIdx);});

      Timer.periodic(Duration(seconds: cts.pongTimeoutSeconds), _reconnectCallback);

      WidgetsBinding.instance.addObserver(this);

      //_firebaseMessaging.configure(
      //   onMessage: (Map<String, dynamic> message) async {
      //     print("onMessage: $message");
      //   },
      //   //onBackgroundMessage: fcmOnBackgroundMessage,
      //   onLaunch: (Map<String, dynamic> message) async {
      //     print("onLaunch: $message");
      //   },
      //   onResume: (Map<String, dynamic> message) async {
      //     print("onResume: $message");
      //   },
      //);

      _firebaseMessaging.getToken().then((String token) {
         if (_fcmToken != null)
            _fcmToken = token;

         print('Token: $token');
      });

      WidgetsBinding.instance.addPostFrameCallback((_) async { _init(); });
   }

   bool _tryNewWSConnection()
   {
      // We should not try to reconnect if disconnection happened just
      // a couples of seconds ago. This is needed because it may
      // haven't been a clean disconnect with a close websocket frame.
      // The server will wait until the pong answer times out.  To
      // solve this we compare _lastDisconnect with the current time.

      if (_lastDisconnect != -1) {
         final int now = DateTime.now().millisecondsSinceEpoch;
         final int interval = now - _lastDisconnect;
         return interval > cts.pongTimeoutMilliseconds;
      }

      return false;
   }

   void _reconnectCallback(Timer timer)
   {
      if (_tryNewWSConnection()) {
         print('Trying to reconnect.');
         _stablishNewConnection(_fcmToken);
      }
   }

   Future<void> _init() async
   {
      final String text = await rootBundle.loadString('data/parameters.txt');
      g.param = Parameters.fromJson(jsonDecode(text));
      await initializeDateFormatting(g.param.localeName, null);

      _trees = await readTreeFromAsset();

      final String exDetailsStr = await rootBundle.loadString('data/ex_details_menu.txt');
      _exDetailsRoot = treeReader(jsonDecode(exDetailsStr)).first.root.first;

      final String inDetailsStr = await rootBundle.loadString('data/in_details_menu.txt');
      _inDetailsRoot = treeReader(jsonDecode(inDetailsStr)).first.root.first;

      await _appState.load();

      _nNewPosts = 0;
      _goToRegScreen = _appState.cfg.nick.isEmpty;
      prepareNewPost(cts.ownIdx);
      prepareNewPost(cts.searchIdx);
      _stablishNewConnection(_fcmToken);
      setState(() { });
   }

   @override
   void dispose()
   {
      _txtCtrl.dispose();
      _txtCtrl2.dispose();
      _tabCtrl.dispose();
      _scrollCtrl[0].dispose();
      _scrollCtrl[1].dispose();
      _scrollCtrl[2].dispose();
      _chatScrollCtrl[cts.ownIdx].dispose();
      _chatScrollCtrl[cts.favIdx].dispose();
      _chatFocusNodes[0].dispose();
      _chatFocusNodes[1].dispose();
      _chatFocusNodes[2].dispose();
      WidgetsBinding.instance.removeObserver(this);

      super.dispose();
   }

   @override
   void didChangeAppLifecycleState(AppLifecycleState state)
   {
      //final bool tryWsReconnect = _tryNewWSConnection();
      //if (state == AppLifecycleState.resumed && tryWsReconnect) {
      //   print('Trying to reconnect.');
      //   _stablishNewConnection(_fcmToken);
      //}
   }

   int _screenIdx()
   {
      return _isOnOwn() ? cts.ownIdx :
	     _isOnFav() ? cts.favIdx :
	                  cts.searchIdx;
   }

   bool _isOnOwn()
   {
      return _tabCtrl.index == cts.ownIdx;
   }

   bool _isOnSearch()
   {
      return _tabCtrl.index == cts.searchIdx;
   }

   bool _isOnFav()
   {
      return _tabCtrl.index == cts.favIdx;
   }

   bool _isOnFavChat()
   {
      return _isOnFav() && _posts[cts.favIdx] != null && _chats[cts.favIdx] != null;
   }

   bool _isOnOwnChat()
   {
      return _isOnOwn() && _posts[cts.ownIdx] != null && _chats[cts.ownIdx] != null;
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
      if (_isOnSearch())
         opacities[1] = onFocusOp;

      opacities[2] = notOnFocusOp;
      if (_isOnFav())
         opacities[2] = onFocusOp;

      return opacities;
   }

   OccaseState();

   void sendOfflinePosts()
   {
      if (_appState.outPostsQueue.isEmpty)
         return;
       
      final String payload = makePostPayload(_appState.outPostsQueue.first);
      websocket.sink.add(payload);
   }

   void _stablishNewConnection(String fcmToken)
   {
      try {
	 // For the web
	 websocket = HtmlWebSocketChannel.connect(cts.dbHost);
	 //websocket = IOWebSocketChannel.connect(cts.dbHost);
	 websocket.stream.listen(
	    _onWSData,
	    onError: _onWSError,
	    onDone: _onWSDone,
	 );

	 final String cmd = makeConnCmd(
	    _appState.cfg.appId,
	    _appState.cfg.appPwd,
	    fcmToken,
	    _appState.cfg.notifications.getFlag(),
	 );

	 websocket.sink.add(cmd);
      } catch (e) {
	 print('Unable to stablish ws connection to server.');
	 print(e);
      }
   }

   Future<void> _setDialogPref(int i, bool v) async
   {
      _appState.setDialogPreferences(i, v);
   }

   Future<void>
   _alertUserOnPressed(BuildContext ctx, int i, int j) async
   {
      if (!_appState.cfg.dialogPreferences[j]) {
         await _onPostSelection(i, j);
         return;
      }

      showDialog(
         context: ctx,
         builder: (BuildContext ctx)
         {
            return DialogWithOp(
               () {return _appState.cfg.dialogPreferences[j];},
               (bool v) async {await _setDialogPref(j, v);},
               () async {await _onPostSelection(i, j);},
               g.param.dialogTitles[j],
               g.param.dialogBodies[j]);
         },
      );
   }

   Future<void> _clearPosts() async
   {
      await _appState.clearPosts();
      setState((){ _nNewPosts = 0; });
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
	    print('1 ------------');
            PickedFile img = await _picker.getImage(
               source: ImageSource.gallery,
               //maxWidth: makeMaxWidth(ctx),
               //maxHeight: makeMaxWidth(ctx),
               //imageQuality: cts.imgQuality,
            );
	    print('2 ------------');

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

   // i = index in _appState.posts, _appState.favPosts, _own_posts.
   // j = image index in the post.
   void _onExpandImg(int i, int j, int k)
   {
      //print('Expand image clicked with $i $j.');

      //_nNewPosts

      setState((){
         _expPostIdxs[k] = i;
         _expImgIdxs[k] = j;
      });
   }

   void _onRangeValueChanged(int i, double v)
   {
      setState((){_posts[cts.ownIdx].rangeValues[i] = v.round();});
   }

   void _onSearchValueChanged(int i, double v)
   {
      setState(() {
	 _posts[cts.searchIdx].rangeValues[i] = v.round();
      });
   }

   void _onNewPostValueChanged(int i, double v)
   {
      setState(() {
	 _posts[cts.ownIdx].rangeValues[i] = v.round();
      });
   }

   void _onSetPostDescription(String description)
   {
      setState(() {
	 _posts[cts.ownIdx].description = description;
      });
   }

   void _onClickOnPost(int i, int j)
   {
      if (j == 1) {
	 print('Sharing post $i');
         Share.share(g.param.share, subject: g.param.shareSubject);
         return;
      }
   }

   Future<void> _onMovePostToFav(int i) async
   {
      final int h = await _appState.moveToFavorite(i);

      assert(h != -1);

      // We should be using the animate function below, but there is no way
      // one can wait until the animation is ready. The is needed to be able to call
      // _onChatPressed(i, 0) correctly. I will let it commented out for now.

      // Use _tabCtrlChangeHandler() as listener
      //_tabCtrl.animateTo(2, duration: Duration(seconds: 2));
      _tabCtrl.index = cts.favIdx;

      // The chat index in the fav screen is always zero.
      await _onChatPressed(h, 0);
   }

   // For the meaning of the index j see makeNewPostImpl.
   //
   // j = 0: Ignore post.
   // j = 1: Move to favorite.
   // j = 2: Report inapropriate.
   // j = 3: Share.
   Future<void> _onPostSelection(int i, int j) async
   {
      if (j == 3) {
         Share.share(g.param.share, subject: g.param.shareSubject);
         return;
      }

      if (j == 1) {
	 await _onMovePostToFav(i);
      } else {
         await _appState.delPostWithId(i);
         // TODO: Send command to server to report if j = 2.
      }

      setState(() { });
   }

   void prepareNewPost(int i)
   {
      _posts[i] = Post(rangesMinMax: g.param.rangesMinMax);
      _posts[i].reset();
   }

   void _onNewPost()
   {
      setState(() {
	 _newPostPressed = true;
	 prepareNewPost(cts.ownIdx);
	 _trees[0].restoreMenuStack();
	 _trees[1].restoreMenuStack();
      });
   }

   // This function has a side effect. It updates _nNewPosts.
   int _updateNumberOfNewPosts()
   {
      assert(_nNewPosts >= 0);

      // The number of posts that will be shown to the user when he
      // clicks the download button. It is at most maxPostsOnDownload.
      // If it is less than that number we show all.
      int n = _nNewPosts;
      if (n > cts.maxPostsOnDownload)
         n = cts.maxPostsOnDownload;

      _nNewPosts -= n;
   }

   Future<void> _onShowNewPosts() async
   {
      setState((){_updateNumberOfNewPosts();});
   }

   bool _onWillPopSearchTab()
   {
      setState(() { _newSearchPressed = false; });
      return false;
   }

   bool _onWillPopNewPostTab()
   {
      setState(() { _newPostPressed = false; });
      return false;
   }

   void _cleanUpLpOnSwitchTab(int i)
   {
      _lpChats[i].forEach((e){toggleLPChat(e.chat);});
      _lpChatMsgs[i].forEach((e){toggleLPChatMsg(e.chat.msgs[e.msgIdx]);});

      _lpChats[i].clear();
      _lpChatMsgs[i].clear();
   }

   // Called with
   //
   // i = 0: own
   // i = 2: fav
   //
   Future<void> _onFwdSendButton(int i) async
   {
      final int now = DateTime.now().millisecondsSinceEpoch;
      for (Coord c1 in _lpChats[i]) {
         for (Coord c2 in _lpChatMsgs[i]) {
            ChatItem ci = ChatItem(
               isRedirected: 1,
               msg: c2.chat.msgs[c2.msgIdx].msg,
               date: now,
            );

	    await _onSendChatImpl(c1.post.id, c1.chat.peer, ci);
         }
      }

      _lpChats[i].forEach((e){toggleLPChat(e.chat);});
      _lpChatMsgs[i].forEach((e){toggleLPChatMsg(e.chat.msgs[e.msgIdx]);});

      _posts[i] = _lpChatMsgs[i].first.post;
      _chats[i] = _lpChatMsgs[i].first.chat;

      _lpChats[i].clear();
      _lpChatMsgs[i].clear();

      setState(() { });
   }

   Future<bool> _onPopChat(int i) async
   {
      await _appState.setNUnreadMsgs(_posts[i].id, _chats[i].peer);

      _newSearchPressed = false; // Needed only in wide mode.
      _showChatJumpDownButtons[i] = false;
      _dragedIdxs[i] = -1;
      _chats[i].nUnreadMsgs = 0;
      _chats[i].divisorUnreadMsgs = 0;
      _chats[i].divisorUnreadMsgsIdx = -1;
      _lpChatMsgs[i].forEach((e){toggleLPChatMsg(_chats[i].msgs[e.msgIdx]);});

      final bool isEmpty = _lpChatMsgs[i].isEmpty;
      _lpChatMsgs[i].clear();

      if (isEmpty) {
         _posts[i] = null;
         _chats[i] = null;
      }

      setState(() { });
      return false;
   }

   void _onCancelFwdLpChat(int i)
   {
      _dragedIdxs[i] = -1;
      setState(() { });
   }

   Future<void> _onSendChat(int i) async
   {
      _chats[i].nUnreadMsgs = 0;
      await _onSendChatImpl(
         _posts[i].id,
         _chats[i].peer,
         ChatItem(
            isRedirected: 0,
            msg: _txtCtrl.text,
            date: DateTime.now().millisecondsSinceEpoch,
            refersTo: _dragedIdxs[i],
            status: 0,
         ),
      );

      _txtCtrl.clear();
      _dragedIdxs[i] = -1;

      setState(()
      {
         SchedulerBinding.instance.addPostFrameCallback((_)
         {
            _chatScrollCtrl[i].animateTo(
               _chatScrollCtrl[i].position.maxScrollExtent,
               duration: const Duration(milliseconds: 300),
               curve: Curves.easeOut);
         });
      });
   }

   // Called when the user changes text in the chat text field.
   void _onWritingChat(String v, int i)
   {
      assert(_chats[i] != null);
      assert(_posts[i] != null);

      // When the chat input text field was empty and the user types
      // in some text, we have to call set state to enable the send
      // button. If the user erases all the text we have to disable
      // the button. To simplify the implementation I will call
      // setState on every change, since this does not significantly
      // decreases performance.
      setState((){});

      final int now = DateTime.now().millisecondsSinceEpoch;
      final int last = _chats[i].lastPresenceSent + cts.presenceInterval;

      if (now < last)
         return;

      _chats[i].lastPresenceSent = now;

      var subCmd = {
         'cmd': 'presence',
         'to': _chats[i].peer,
         'type': 'writing',
         'post_id': _posts[i].id,
      };

      final String payload = jsonEncode(subCmd);
      print(payload);
      websocket.sink.add(payload);
   }

   void _chatScrollListener(int i)
   {
      if (i != _screenIdx()) {
	 // The control listener seems to be bound to all screens, thats why I
	 // have to filter it here.
	 print('Ignoring ---> $i');
	 return;
      }

      final double offset = _chatScrollCtrl[i].offset;
      final double max = _chatScrollCtrl[i].position.maxScrollExtent;

      final double tol = 40.0;

      final bool old = _showChatJumpDownButtons[i];

      if (_showChatJumpDownButtons[i] && !(offset < max))
         setState(() {_showChatJumpDownButtons[i] = false;});

      if (!_showChatJumpDownButtons[i] && (offset < (max - tol)))
         setState(() {_showChatJumpDownButtons[i] = true;});

      if (!old && _showChatJumpDownButtons[i])
         _chats[i].nUnreadMsgs = 0;
   }

   void _onFwdChatMsg(int i)
   {
      assert(_lpChatMsgs[i].isNotEmpty);

      _posts[i] = null;
      _chats[i] = null;

      setState(() { });
   }

   void _onDragChatMsg(BuildContext ctx, int k, DragStartDetails d, int i)
   {
      _dragedIdxs[i] = k;
      FocusScope.of(ctx).requestFocus(_chatFocusNodes[i]);
      setState(() {});
   }

   void _onChatMsgReply(BuildContext ctx, int i)
   {
      assert(_lpChatMsgs[i].length == 1);

      _dragedIdxs[i] = _lpChatMsgs[i].first.msgIdx;

      assert(_dragedIdxs[i] != -1);

      _lpChatMsgs[i].forEach((e){toggleLPChatMsg(e.chat.msgs[e.msgIdx]);});
      _lpChatMsgs[i].clear();
      FocusScope.of(ctx).requestFocus(_chatFocusNodes[i]);
      setState(() { });
   }

   Future<void> _onChatAttachment() async
   {
      //var image =
      //   await ImagePicker.pickImage(source: ImageSource.gallery);

       setState(() { });
   }

   Future<void> _onTreeLeafNodePressed(int k) async
   {
      print('Dummy');
      setState(() { });
   }

   Future<void> _sendPost() async
   {
      _posts[cts.ownIdx].from = _appState.cfg.appId;
      _posts[cts.ownIdx].nick = _appState.cfg.nick;
      _posts[cts.ownIdx].avatar = emailToGravatarHash(_appState.cfg.email);
      _posts[cts.ownIdx].status = 3;

      Post post = _posts[cts.ownIdx].clone();

      final bool isEmpty = _appState.outPostsQueue.isEmpty;

      // We add it here in our own list of posts and keep in mind it may be
      // echoed back to us. It has to be filtered out from _appState.posts
      // since that list should not contain our own posts.

      post.dbId = await _appState.persistency.insertPost(post, ConflictAlgorithm.replace);
      _appState.outPostsQueue.add(post);

      if (!isEmpty)
         return;

      // The queue was empty before we inserted the new post.
      // Therefore we are not waiting for an ack.

      final String payload = makePostPayload(_appState.outPostsQueue.first);
      print(payload);
      websocket.sink.add(payload);
   }

   Future<void> _handlePublishAck(final int id, final int date) async
   {
      try {
         assert(_appState.outPostsQueue.isNotEmpty);
         Post post = _appState.outPostsQueue.removeFirst();
         if (id == -1) {
	    await _appState.persistency.delPostWithRowid(post.dbId);
            setState(() {_newPostErrorCode = 0;});
            return;
         }

         // When working with the simulator I noticed on my machine
         // that it replies before the post could be moved from the
         // output queue to the . In normal cases users won't
         // be so fast. But since this is my test condition, I will
         // cope with that by inserting the post in _appState.ownPosts and only
         // after that removing from the queue.
         // TODO: I think this does not hold anymore after I
         // introduced a message queue.

         post.id = id;
         post.date = date;
         post.status = 0;
         post.pinDate = 0;
         _appState.ownPosts.add(post);
         _appState.ownPosts.sort(compPosts);

         await _appState.persistency.updatePostOnAck(0, id, date, post.dbId);

         setState(() {_newPostErrorCode = 1;});

         if (_appState.outPostsQueue.isEmpty)
            return;

         final String payload = makePostPayload(_appState.outPostsQueue.first);
	 print(payload);
         websocket.sink.add(payload);
      } catch (e) {
         print(e);
      }
   }

   Future<void> _onRemovePost(int i) async
   {
      if (_isOnFav()) {
         await _appState.persistency.delPostWithId(_appState.favPosts[i].id);
         _appState.favPosts.removeAt(i);
      } else {
         await _appState.persistency.delPostWithId(_appState.ownPosts[i].id);
         final Post delPost = _appState.ownPosts.removeAt(i);

         var msgMap = {
            'cmd': 'delete',
            'id': delPost.id,
            'to': 0,
         };

         await _sendAppMsg(jsonEncode(msgMap), 0);
      }

      setState(() { });
   }

   Future<void> _onPinPost(int i) async
   {
      await _appState.setPinPostDate(i, _isOnFav());
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
            _imgFiles = List<PickedFile>();
            return 0;
         }

         _posts[cts.ownIdx].images.add(newname);
      }

      _imgFiles = List<PickedFile>();
      return -1;
   }

   void _leaveNewPostScreen()
   {
      _newPostPressed = false;
      _posts[cts.ownIdx] = null;
   }

   void _requestFilenames()
   {
      // Consider: Check if the app is online before sending.

      var cmd = {
         'cmd': 'filenames',
      };

      String payload = jsonEncode(cmd);
      print(payload);
      websocket.sink.add(payload);

      _filenamesTimer = Timer(
         Duration(seconds: cts.filenamesTimeout), () {
	    setState((){
	       _leaveNewPostScreen();
	       _newPostErrorCode = 0;
	    });
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

      assert(i != 2);

      if (i == 0) {
         _showSimpleDialog(
            ctx,
            (){
               _newPostPressed = false;
               _posts[cts.ownIdx] = null;
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
      int j,
      int k,
   ) async {
      if (_lpChats[k].isNotEmpty || _lpChatMsgs[i].isNotEmpty) {
         _onChatLPImpl(posts, i, j, k);
         setState(() { });
         return;
      }

      _showChatJumpDownButtons[k] = false;
      Post post = posts[i];
      ChatMetadata chat = posts[i].chats[j];

      if (!chat.isLoaded())
         chat.msgs = await _appState.persistency.loadChatMsgs(post.id, chat.peer);
      
      // These variables must be set after the chats are loaded. Otherwise
      // chat.msgs may be called on null if a message arrives. 
      _posts[k] = post;
      _chats[k] = chat;

      if (_chats[k].nUnreadMsgs != 0) {
         _chats[k].divisorUnreadMsgsIdx = _chats[k].msgs.length - _chats[k].nUnreadMsgs;

         // We know the number of unread messages, now we have to generate
         // the array with the messages peer rowid.

         var msgMap =
         { 'cmd': 'message'
         , 'type': 'chat_ack_read'
         , 'to': posts[i].chats[j].peer
         , 'post_id': posts[i].id
         , 'id': -1
         , 'ack_ids': readPeerRowIdsToAck(_chats[k].msgs, _chats[k].nUnreadMsgs)
         };

         await _sendAppMsg(jsonEncode(msgMap), 0);
      }

      setState(() {
         SchedulerBinding.instance.addPostFrameCallback((_)
         {
            _chatScrollCtrl[k].jumpTo(_chatScrollCtrl[k].position.maxScrollExtent);
         });
      });
   }

   void _onChatJumpDown(int k)
   {
      setState(()
      {
         _chatScrollCtrl[k].jumpTo(_chatScrollCtrl[k].position.maxScrollExtent);
      });
   }

   Future<void> _onChatPressed(int i, int j) async
   {
      if (_isOnFav())
         await _onChatPressedImpl(_appState.favPosts, i, j, cts.favIdx);
      else
         await _onChatPressedImpl(_appState.ownPosts, i, j, cts.ownIdx);
   }

   void _onUserInfoPressed(BuildContext ctx, int postId, int j)
   {
      List<Post> posts;
      if (_isOnFav()) {
         posts = _appState.favPosts;
      } else {
         posts = _appState.ownPosts;
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

   void _onChatLPImpl(List<Post> posts, int i, int j, int k)
   {
      final Coord tmp = Coord(post: posts[i], chat: posts[i].chats[j]);

      handleLPChats(
         _lpChats[k],
         toggleLPChat(posts[i].chats[j]),
         tmp,
	 compPostIdAndPeer,
      );
   }

   void _onChatLP(int i, int j)
   {
      if (_isOnFav()) {
         _onChatLPImpl(_appState.favPosts, i, j, cts.favIdx);
      } else {
         _onChatLPImpl(_appState.ownPosts, i, j, cts.ownIdx);
      }

      setState(() { });
   }

   Future<void> _sendAppMsg(String payload, int isChat) async
   {
      final bool isEmpty = _appState.appMsgQueue.isEmpty;
      AppMsgQueueElem tmp = AppMsgQueueElem(
         rowid: -1,
         isChat: isChat,
         payload: payload,
         sent: false
      );

      _appState.appMsgQueue.add(tmp);

      tmp.rowid = await _appState.persistency.insertOutChatMsg(isChat, payload);

      if (isEmpty) {
         assert(!_appState.appMsgQueue.first.sent);
         _appState.appMsgQueue.first.sent = true;
         print(_appState.appMsgQueue.first.payload);
         websocket.sink.add(_appState.appMsgQueue.first.payload);
      }
   }

   void _sendOfflineChatMsgs()
   {
      if (_appState.appMsgQueue.isNotEmpty) {
         assert(!_appState.appMsgQueue.first.sent);
         _appState.appMsgQueue.first.sent = true;
         websocket.sink.add(_appState.appMsgQueue.first.payload);
      }
   }

   void _toggleLPChatMsgs(int k, bool isTap, int i)
   {
      assert(_posts[i] != null);
      assert(_chats[i] != null);

      if (isTap && _lpChatMsgs[i].isEmpty)
         return;

      final Coord tmp = Coord(
         post: _posts[i],
         chat: _chats[i],
         msgIdx: k
      );

      handleLPChats(_lpChatMsgs[i],
                    toggleLPChatMsg(_chats[i].msgs[k]),
                    tmp, compPeerAndChatIdx);

      setState((){});
   }

   Future<void> _onSendChatImpl(
      int postId,
      String peer,
      ChatItem ci,
   ) async {
      try {
	 if (ci.msg.isEmpty)
	    return;

	 final int rowid = 
	    await _appState.setChatMessage(postId, peer, ci, _isOnFav());

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
         , 'nick': _appState.cfg.nick
         , 'id': rowid
         , 'avatar': emailToGravatarHash(_appState.cfg.email)
         };

         final String payload = jsonEncode(msgMap);
         await _sendAppMsg(payload, 1);

      } catch(e) {
         print(e);
      }
   }

   Future<void> _onServerAck(Map<String, dynamic> ack) async
   {
      try {
         assert(_appState.appMsgQueue.first.sent);
         assert(_appState.appMsgQueue.isNotEmpty);

         final String res = ack['result'];

         await _appState.persistency.deleteOutChatMsg(_appState.appMsgQueue.first.rowid);

         final bool isChat = _appState.appMsgQueue.first.isChat == 1;
         _appState.appMsgQueue.removeFirst();

         if (res == 'ok' && isChat) {
            await _onChatAck(ack['from'], ack['post_id'], <int>[ack['ack_id']], 1);
            setState(() { });
         }

         if (_appState.appMsgQueue.isNotEmpty) {
            assert(!_appState.appMsgQueue.first.sent);
            _appState.appMsgQueue.first.sent = true;
	    print(_appState.appMsgQueue.first.payload);
            websocket.sink.add(_appState.appMsgQueue.first.payload);
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
      if (to != _appState.cfg.appId) {
         print("Server bug caught. Please report.");
         return;
      }

      final String msg = ack['msg'];
      final String nick = ack['nick'];
      final String avatar = ack['avatar'] ?? '';
      final int refersTo = ack['refers_to'];
      final int peerRowid = ack['id'];

      final int favIdx = _appState.favPosts.indexWhere((e) {
         return e.id == postId;
      });

      List<Post> posts;
      if (favIdx != -1)
         posts = _appState.favPosts;
      else
         posts = _appState.ownPosts;

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
      final bool isOnOwnPost = _posts[cts.ownIdx] != null && _posts[cts.ownIdx].id == postId; 
      final bool isOnFavPost = _posts[cts.favIdx] != null && _posts[cts.favIdx].id == postId; 

      final bool isOnOwnChat = _chats[cts.ownIdx] != null && _chats[cts.ownIdx].peer == peer; 
      final bool isOnFavChat = _chats[cts.favIdx] != null && _chats[cts.favIdx].peer == peer; 

      ++posts[i].chats[j].nUnreadMsgs;

      String ack;
      if ((isOnOwnPost && isOnOwnChat) || (isOnFavPost && isOnFavChat)) {
         // We are in the chat screen with the peer.
         ack = 'chat_ack_read';

	 final int k = isOnOwnPost ? cts.ownIdx : cts.favIdx;

         // We are not currently showing the jump down button and can
         // animate to the bottom.
         if (!_showChatJumpDownButtons[k]) {
            setState(()
            {
               posts[i].chats[j].nUnreadMsgs = 0;
               SchedulerBinding.instance.addPostFrameCallback((_)
               {
                  _chatScrollCtrl[k].animateTo(
                     _chatScrollCtrl[k].position.maxScrollExtent,
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
      await _appState.persistency.insertChatOnPost3(postId, chat, peer, ci);
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

      final bool b = markPresence(_appState.favPosts, peer, postId);
      if (!b)
         markPresence(_appState.ownPosts, peer, postId);

      // A timer that is launched after presence arrives. It is used
      // to call setState so that presence e.g. typing messages are
      // not shown after some time
      Timer(
         Duration(milliseconds: cts.presenceInterval),
         () { setState((){}); },
      );

      setState((){});
   }

   Future<void> _onChatAck(
      String from,
      int postId,
      List<int> rowids,
      int status,
   ) async {
      _appState.setChatAckStatus(from, postId, rowids, status);
   }

   Future<void> _onMessage(Map<String, dynamic> ack) async
   {
      final String from = ack['from'];
      final String type = ack['type'];
      final int postId = ack['post_id'];

      if (type == 'chat') {
         await _onChat(ack, from, postId, ack['is_redirected']);
      } else if (type == 'server_ack') {
         await _onServerAck(ack);
      } else if (type == 'chat_ack_received') {
         final List<int> rowids = decodeList(0, 0, ack['ack_ids']);
         await _onChatAck(from, postId, rowids, 2);
      } else if (type == 'chat_ack_read') {
         final List<int> rowids = decodeList(0, 0, ack['ack_ids']);
         await _onChatAck(from, postId, rowids, 3);
      }

      setState((){});
   }

   Future<void> _onRegisterAck(
      Map<String, dynamic> ack,
      final String msg,
   ) async {
      final String res = ack["result"];
      if (res == 'fail') {
         print("register_ack: fail.");
         return;
      }

      String id = ack["id"];
      String pwd = ack["password"];

      if (id == null || pwd == null)
         return;

      await _appState.setCredentials(id, pwd);

      // Retrieves some posts for the newly registered user.
      _search();
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

      _lastDisconnect = -1;

      // We are loggen in and can subscribe to receive posts sent while we were
      // offline.
      _search();

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

   Future<void> _onPost(Map<String, dynamic> ack) async
   {
      // When we are receiving new posts here as a result of the user
      // clicking the search buttom, we have to clear all old posts before
      // showing the new posts to the user.
      final bool showPosts = _appState.posts.isEmpty;
      for (var item in ack['items']) {
         try {
            Post post = Post.fromJson(item, g.param.rangeDivs.length);
            post.status = 1;

            if (post.from == _appState.cfg.appId)
               continue;

	    //await _appState.persistency.insertPost(post, ConflictAlgorithm.ignore);

            _appState.posts.add(post);
            ++_nNewPosts;
         } catch (e) {
            print("Error: Invalid post detected.");
         }
      }

      if (showPosts)
         _updateNumberOfNewPosts();

      setState(() { });
   }

   Future<void>
   _onPublishAck(Map<String, dynamic> ack) async
   {
      final String res = ack['result'];
      if (res == 'ok') {
         await _handlePublishAck(ack['id'], 1000 * ack['date']);
      } else {
         await _handlePublishAck(-1, -1);
      }
   }

   Future<void> _onWSDataImpl() async
   {
      while (_wsMsgQueue.isNotEmpty) {
         var msg = _wsMsgQueue.removeFirst();

         Map<String, dynamic> ack = jsonDecode(msg);
         final String cmd = ack["cmd"];
         if (cmd == "presence") {
            _onPresence(ack);
         } else if (cmd == "message") {
            await _onMessage(ack);
         } else if (cmd == "login_ack") {
            _onLoginAck(ack, msg);
         } else if (cmd == "subscribe_ack") {
            _onSubscribeAck(ack);
         } else if (cmd == "post") {
            await _onPost(ack);
         } else if (cmd == "publish_ack") {
            await _onPublishAck(ack);
         } else if (cmd == "delete_ack") {
            await _onServerAck(ack);
         } else if (cmd == "register_ack") {
            await _onRegisterAck(ack, msg);
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
      if (isEmpty)
         await _onWSDataImpl();
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

   void _showSimpleDialog(
      BuildContext ctx,
      Function onOk,
      String title,
      Widget content,
   ) {
      showDialog(
         context: ctx,
         builder: (BuildContext ctx)
         {
            final FlatButton ok = FlatButton(
               child: Text(g.param.ok),
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
   * 0: Leaves the screen.
   * 1: Retrieve all posts from the server. (I think we do not need this
   *    option).
   * 2: Notifications: When the user presses search we will zero the
   *    lastPostId and search.
   */
   Future<void> _onSearch(BuildContext ctx, int i) async
   {
      if (!isWideScreen(ctx))
	 setState(() {_newSearchPressed = false;});

      if (i == 0) {
         setState(() { });
         return;
      }

      // I changed my mind in 8.12.2019 and decided it is less confusing to
      // the user if we always search for all posts not only for those that
      // have a more recent post id than what is stored in the app. For
      // that we rely on the fact that
      //
      // 1. When the user moves a post to the chats screen it will not be
      //    added twice.
      // 2. Old posts will be cleared when we receive the answer to this
      //    request.

      _nNewPosts = 0;
      await _appState.clearPosts();
      _search();

      // I believe we do not need this dialog anymore.
      //_showSimpleDialog(
      //   ctx,
      //   () { setState(() { }); }
      //   g.param.dialogTitles[3],
      //   Text(g.param.dialogBodies[3]),
      //);
   }

   void _search()
   {
      var subCmd =
      { 'cmd': 'subscribe'
      , 'last_post_id': 0
      , 'filters': <int>[]
      , 'channels': <int>[]
      , 'any_of_features': _posts[cts.searchIdx].exDetails[0]
      , 'ranges': <int>[]
      };

      final String payload = jsonEncode(subCmd);
      print(payload);
      websocket.sink.add(payload);
   }

   // Called when the main tab changes.
   void _tabCtrlChangeHandler()
   {
      // This function is meant to change the tab widgets when we
      // switch tab. This is needed to show the number of unread
      // messages.
      setState(() { print('Tab changed');});
   }

   int _getNUnreadFavChats()
   {
      int i = 0;
      for (Post post in _appState.favPosts)
         i += post.getNumberOfUnreadChats();

      return i;
   }

   int _getNUnreadOwnChats()
   {
      int i = 0;
      for (Post post in _appState.ownPosts)
         i += post.getNumberOfUnreadChats();

      return i;
   }

   bool _onChatsBackPressed(int i)
   {
      if (_hasLPChatMsgs(i)) {
         _onBackFromChatMsgRedirect(i);
         return false;
      }

      if (_hasLPChats(i)) {
         _unmarkLPChats(i);
         setState(() { });
         return false;
      }

      if (_posts[i] != null) {
         _posts[i] = null;
         setState(() { });
         return false;
      }

      _tabCtrl.animateTo(1, duration: Duration(seconds: 1));
      setState(() { });
      return false;
   }

   bool _hasLPChats(int i)
   {
      return _lpChats[i].isNotEmpty;
   }

   bool _hasLPChatMsgs(int i)
   {
      return _lpChatMsgs[i].isNotEmpty;
   }

   void _unmarkLPChats(int i)
   {
      _lpChats[i].forEach((e){toggleLPChat(e.chat);});
      _lpChats[i].clear();
   }

   void _onAppBarVertPressed(ConfigActions c)
   {
      if (c == ConfigActions.ChangeNick) {
         setState(() {
            _goToRegScreen = true;
         });
      }

      if (c == ConfigActions.Notifications) {
         setState(() {
            _goToNtfScreen = true;
         });
      }

      if (c == ConfigActions.Information) {
         setState(() {
            _goToInfoScreen = true;
         });
      }
   }

   void _onSearchPressed()
   {
      setState(() {
	 prepareNewPost(cts.searchIdx);
	 _newSearchPressed = true;
      });
   }

   Future<void> _pinChats(int i) async
   {
      assert(_isOnFav() || _isOnOwn());

      if (_lpChats[i].isEmpty)
         return;

      _lpChats[i].forEach((e){toggleChatPinDate(e.chat);});
      _lpChats[i].forEach((e){toggleLPChat(e.chat);});
      _lpChats[i].first.post.chats.sort(compChats);
      _lpChats[i].clear();

      // TODO: Sort _appState.favPosts and _appState.ownPosts. Beaware that the array
      // Coord many have entries from chats from different posts and
      // they may be out of order. So care should be taken to not sort
      // the arrays multiple times.

      setState(() { });
   }

   Future<void> _removeLPChats(int i) async
   {
      assert(_isOnFav() || _isOnOwn());

      if (_lpChats[i].isEmpty)
         return;

      // FIXME: For _fav chats we can directly delete the post since
      // it will only have one chat element.

      _lpChats[i].forEach((e) async {removeLpChat(e, _appState.persistency);});

      if (_isOnFav()) {
         for (Post o in _appState.favPosts)
            if (o.chats.isEmpty)
	       await _appState.persistency.delPostWithId(o.id);

         _appState.favPosts.removeWhere((e) { return e.chats.isEmpty; });
      } else {
         _appState.ownPosts.sort(compPosts);
      }

      _lpChats[i].clear();
      setState(() { });
   }

   void _deleteChatDialog(BuildContext ctx, int i)
   {
      showDialog(
         context: ctx,
         builder: (BuildContext ctx)
         {
            final FlatButton ok = FlatButton(
	       child: Text(g.param.devChatOkStr,
		  style: TextStyle(color: stl.colorScheme.secondary),
	       ),
	       onPressed: () async
	       {
		  await _removeLPChats(i);
		  Navigator.of(ctx).pop();
	       },
	    );

            final FlatButton cancel = FlatButton(
               child: Text(g.param.delChatCancelStr,
                  style: TextStyle(color: stl.colorScheme.secondary),
               ),
               onPressed: () { Navigator.of(ctx).pop(); });

            List<FlatButton> actions = List<FlatButton>(2);
            actions[0] = cancel;
            actions[1] = ok;

            Text text = Text(g.param.delOwnChatTitleStr,
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

   void _onBackFromChatMsgRedirect(int i)
   {
      assert(_lpChatMsgs[i].isNotEmpty);

      if (_lpChats[i].isEmpty) {
         // All items int _lpChatMsgs should have the same post id and
         // peer so we can use the first.
         _posts[i] = _lpChatMsgs[i].first.post;
         _chats[i] = _lpChatMsgs[i].first.chat;
      } else {
         _unmarkLPChats(i);
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
            _appState.cfg.email = _txtCtrl2.text;
	    await _appState.updateConfig();
         }

         _appState.cfg.nick = _txtCtrl.text;
         await _appState.updateConfig();

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

   bool _onWillLeaveInfoScreen()
   {
      setState(() {_goToInfoScreen = false;});
      return false;
   }

   Future<void> _onSendEmailToSupport() async
   {
      // The email must have the form:
      //
      //   mailto:<email address>?subject=<subject>&body=<body>
      //

      final String email = g.param.supportEmail;
      final String subject = g.param.supportEmailSubject;
      final String body = '';

      final String url = 'mailto:${email}?subject=${subject}&body=${body}';

      if (await canLaunch(url)) {
         await launch(url);
      } else {
         print('Unable to send email.');
      }
   }

   Future<void> _onChangeNtf(int i, bool v) async
   {
      try {
         if (i == 0)
            _appState.cfg.notifications.chat = v;

         if (i == 1)
            _appState.cfg.notifications.post = v;

         await _appState.updateConfig();

         if (i == -1)
            _goToNtfScreen = false;

         setState(() { });
      } catch (e) {
         print(e);
      }
   }

   void _onSearchDetail(int i, int state)
   {
      setState(() {
	 final int a = _posts[cts.searchIdx].exDetails[i];
	 _posts[cts.searchIdx].exDetails[i] = state;
      });
   }

   void _onNewPostSetTreeCode(List<int> code, int i)
   {
      if (i == 0)
	 _posts[cts.ownIdx].location = code;

      if (i == 1)
	 _posts[cts.ownIdx].product = code;

      setState(() {});
   }

   void _onSetSearchLocationCode(List<int> code)
   {
      if (code.isEmpty)
	 return;

      _posts[cts.searchIdx].location = code;

      setState(() {});
   }

   void _onSetSearchProductCode(List<int> code)
   {
      if (code.isEmpty)
	 return;

      _posts[cts.searchIdx].product = code;

      setState(() {});
   }

   void _onSetExDetail(int detailIdx, int index)
   {
      setState(() {_posts[cts.ownIdx].exDetails[detailIdx] = index;});
   }

   void _onSetInDetail(int detailIdx, int state)
   {
      setState(() { _posts[cts.ownIdx].inDetails[detailIdx] = state; });
   }

   // Widget factories.
   //
   // tab: screen index.
   //
   Widget _makeChatScreen(BuildContext ctx, int tab)
   {
      return makeChatScreen(
	 ctx,
	 tab,
	 _chats[tab],
	 _txtCtrl,
	 _chatScrollCtrl[tab],
	 _lpChatMsgs[tab].length,
	 _chatFocusNodes[tab],
	 makeTreeItemStr(_trees[0].root.first, _posts[tab].product),
	 _dragedIdxs[tab],
	 _showChatJumpDownButtons[tab],
	 _isOnFavChat() ? _posts[tab].avatar : _chats[tab].avatar,
	 _appState.cfg.nick,
	 () { _onPopChat(tab);},
	 () {_onSendChat(tab);},
	 (int a, bool b) {_toggleLPChatMsgs(a, b, tab);},
	 () {_onFwdChatMsg(tab);},
	 (var a, var b, var d) {_onDragChatMsg(a, b, d, tab);},
	 (var a) {_onChatMsgReply(a, tab);},
	 _onChatAttachment,
	 () {_onCancelFwdLpChat(tab);},
	 () {_onChatJumpDown(tab);},
	 (var s) {_onWritingChat(s, tab);},
      );
   }

   Widget _makeNewPostScreenWdgs2(BuildContext ctx)
   {
      return makeNewPostScreenWdgs2(
	 ctx: ctx,
	 filenamesTimerActive: _filenamesTimer.isActive,
	 locationTree: _trees[0],
	 productTree: _trees[1],
	 exDetailsRootNode: _exDetailsRoot,
	 inDetailsRootNode: _inDetailsRoot,
	 post: _posts[cts.ownIdx],
	 onSetTreeCode: _onNewPostSetTreeCode,
	 onSetExDetail: _onSetExDetail,
	 onSetInDetail: _onSetInDetail,
	 imgFiles: _imgFiles,
	 onAddPhoto: _onAddPhoto,
	 onPublishPost: (var a) { _onSendNewPost(a, 1); },
	 onRemovePost: (var a) { _onSendNewPost(a, 0); },
	 onNewPostValueChanged: _onNewPostValueChanged,
	 onSetPostDescription: _onSetPostDescription,
      );
   }

   Widget _makeSearchScreenWdg2(BuildContext ctx)
   {
      // Below we use txt.exDetails[0][0], because the filter is
      // common to all products.
      return makeSearchScreenWdg2(
	 ctx: ctx,
	 state: _posts[cts.searchIdx].exDetails[0],
	 locationRootNode: _trees[0].root.first,
	 productRootNode: _trees[1].root.first,
	 exDetailsRootNode: _exDetailsRoot,
	 post: _posts[cts.searchIdx],
	 ranges: g.param.rangesMinMax,
	 divisions: g.param.rangeDivs,
	 onSearchPressed: (int i) {_onSearch(ctx, i);},
	 onSearchDetail: (int j) {_onSearchDetail(0, j);},
	 onValueChanged: _onSearchValueChanged,
	 onSetLocationCode: _onSetSearchLocationCode,
	 onSetProductCode: _onSetSearchProductCode,
      );
   }

   Widget _makeNewPostLv()
   {
      return makeNewPostLv(
	nNewPosts: _nNewPosts,
	exDetailsRootNode: _exDetailsRoot,
	inDetailsRootNode: _inDetailsRoot,
	posts: _appState.posts,
	trees: _trees,
	onExpandImg: (int i, int j) {_onExpandImg(i, j, cts.searchIdx);},
	onAddPostToFavorite: (var a, int j) {_alertUserOnPressed(a, j, 1);},
	onDelPost: (var a, int j) {_alertUserOnPressed(a, j, 0);},
	onSharePost: (var a, int j) {_alertUserOnPressed(a, j, 3);},
	onReportPost: (var a, int j) {_alertUserOnPressed(a, j, 2);},
	onNext: _onShowNewPosts,
      );
   }

   List<Widget> _makeFaButtons(BuildContext ctx)
   {
      final bool isWide = isWideScreen(ctx);

      return makeFaButtons(
	 isWide: isWide,
	 hasFavPosts: _appState.favPosts.isNotEmpty,
	 nOwnPosts: _appState.ownPosts.length,
	 newSearchPressed: _newSearchPressed,
	 lpChats: _lpChats,
	 lpChatMsgs: _lpChatMsgs,
	 onNewPost: _newPostPressed ? null : _onNewPost,
	 onFwdSendButton: _onFwdSendButton,
	 onSearch: _onSearchPressed,
      );
   }

   Widget _makeChatTab(BuildContext ctx, int i)
   {
      List<Post> posts = _appState.ownPosts;
      if (i == cts.favIdx)
	 posts = _appState.favPosts;

      return makeChatTab(
	 isFwdChatMsgs: _lpChatMsgs[i].isNotEmpty,
	 screen: i,
	 exDetailsRootNode: _exDetailsRoot,
	 inDetailsRootNode: _inDetailsRoot,
	 posts: posts,
	 trees: _trees,
	 onPressed: _onChatPressed,
	 onLongPressed: _onChatLP,
	 onDelPost1: (int i) { _removePostDialog(ctx, i);},
	 onPinPost1: _onPinPost,
	 onUserInfoPressed: _onUserInfoPressed,
	 onExpandImg1: (int i, int j) {_onExpandImg(i, j, i);},
	 onSharePost: (int i) {_onClickOnPost(i, 1);},
	 onPost: _onNewPost,
      );
   }

   List<Widget> _makeTabActions(BuildContext ctx, int i)
   {
      return makeTabActions(
         screen: i,
	 newPostPressed: _newPostPressed,
	 hasLPChats: _hasLPChats(i),
	 hasLPChatMsgs: _hasLPChatMsgs(i),
	 deleteChatDialog: () {_deleteChatDialog(ctx, i);},
	 pinChats: () {_pinChats(i);},
	 onClearPostsDialog: () { _clearPostsDialog(ctx); },
      );
   }

   List<Widget> _makeGlobalActionsApp(BuildContext ctx, int i)
   {
      // In the web version we do not need to hide anything if there are long
      // pressed chats.
      return makeGlobalActionsApp(
	 hasLPChats: _hasLPChats(i),
	 hasLPChatMsgs: _hasLPChatMsgs(i),
	 onSearchPressed: _onSearchPressed,
	 onNewPost: _onNewPost,
	 onAppBarVertPressed: _onAppBarVertPressed,
      );
   }

   List<Widget> _makeGlobalActionsWeb(BuildContext ctx)
   {
      // In the web version we do not need to hide anything if there are long
      // pressed chats.
      return makeGlobalActionsWeb(
	 onSearchPressed: _onSearchPressed,
	 onNewPost: _onNewPost,
	 onAppBarVertPressed: _onAppBarVertPressed,
      );
   }


   Widget _makeAppBarLeading(bool isWide, int i)
   {
      return makeAppBarLeading(
	 hasLpChats: _hasLPChats(i),
	 hasLpChatMsgs: _hasLPChatMsgs(i),
	 newPostPressed: _newPostPressed,
	 newSearchPressed: _newSearchPressed,
	 isWide: isWide,
	 hasNoFavPosts: _appState.favPosts.isEmpty,
	 tab: i,
	 onWillLeaveSearch: _onWillPopSearchTab,
	 onWillLeaveNewPost: _onWillPopNewPostTab,
	 onBackFromChatMsgRedirect: () { _onBackFromChatMsgRedirect(i);},
      );
   }

   Widget _makeAppBarTitleWdg(bool isWide, int i, Widget defaultWdg)
   {
      return makeAppBarWdg(
	 hasLpChatMsgs: _hasLPChatMsgs(i),
	 newPostPressed: _newPostPressed,
	 newSearchPressed: _newSearchPressed,
	 isWide: isWide,
	 hasNoFavPosts: _appState.favPosts.isEmpty,
	 tab: i,
	 trees: _trees,
	 defaultWdg: defaultWdg,
      );
   }

   List<int> _newMsgsCounters()
   {
      List<int> ret = List<int>(g.param.tabNames.length);
      ret[cts.ownIdx] = _getNUnreadOwnChats();
      ret[cts.searchIdx] = _nNewPosts;
      ret[cts.favIdx] = _getNUnreadFavChats();
      return ret;
   }

   List<Widget> _makeAppBodies(BuildContext ctx)
   {
      final bool isWide = isWideScreen(ctx);

      List<Widget> ret = List<Widget>(g.param.tabNames.length);

      if (_newPostPressed) {
	 ret[cts.ownIdx] = _makeNewPostScreenWdgs2(ctx);
      } else {
	 ret[cts.ownIdx] = _makeChatTab(ctx, cts.ownIdx);
      }

      if (_newSearchPressed && !isWide) {
	 ret[cts.searchIdx] = _makeSearchScreenWdg2(ctx);
      } else {
	 ret[cts.searchIdx] = _makeNewPostLv();
      }

      if ((_newSearchPressed || _appState.favPosts.isEmpty) && isWide) {
	 ret[cts.favIdx] = _makeSearchScreenWdg2(ctx);
      } else {
	 ret[cts.favIdx] = _makeChatTab(ctx, cts.favIdx);
      }

      return ret;
   }

   bool _makeOnWillPop(int i)
   {
      if (i == cts.ownIdx) {
	 if (_newPostPressed)
	    return _onWillPopNewPostTab();

	 return _onChatsBackPressed(cts.ownIdx);
      };

      if (i == cts.searchIdx) {
	 if (_newSearchPressed)
	    return _onWillPopSearchTab();

	 setState((){});
	 return true;
      }

      //i == cts.favIdx
      return _onChatsBackPressed(cts.favIdx);
   }

   @override
   Widget build(BuildContext ctx)
   {
      final bool mustWait =
         _trees.isEmpty    ||
         (_exDetailsRoot == null) ||
         (_inDetailsRoot == null) ||
         (g.param == null);

      if (mustWait)
         return makeWaitMenuScreen();

      Locale locale = Localizations.localeOf(ctx);
      g.param.setLang(locale.languageCode);

      if (_goToRegScreen) {
         return makeRegisterScreen(
            _txtCtrl2,
            _txtCtrl,
            (){_onRegisterContinue(ctx);},
            g.param.changeNickAppBarTitle,
            _appState.cfg.email,
            _appState.cfg.nick,
	    makeMaxWidth(ctx, cts.ownIdx),
         );
      }

      if (_goToNtfScreen) {
         return makeNtfScreen(
	    ctx,
            _onChangeNtf,
            g.param.changeNtfAppBarTitle,
            _appState.cfg.notifications,
            g.param.ntfTitleDesc,
         );
      }

      if (_goToInfoScreen)
         return makeInfoScreen(
            ctx,
	    _onWillLeaveInfoScreen,
	    _onSendEmailToSupport,
	 );

      if (_onTabSwitch()) {
         _cleanUpLpOnSwitchTab(cts.ownIdx);
         _cleanUpLpOnSwitchTab(cts.favIdx);
      }

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

      final int screenIdx = _screenIdx();
      if (_expPostIdxs[screenIdx] != -1 && _expImgIdxs[screenIdx] != -1) {
         Post post;
         if (_isOnOwn())
            post = _appState.ownPosts[_expPostIdxs[screenIdx]];
         else if (_isOnSearch())
            post = _appState.posts[_expPostIdxs[screenIdx]];
         else if (_isOnFav())
            post = _appState.favPosts[_expPostIdxs[screenIdx]];
         else
            assert(false);

         return makeImgExpandScreen(
	    () { _onExpandImg(-1, -1, _screenIdx()); return false;},
	    post,
	 );
      }

      List<Widget> fltButtons = _makeFaButtons(ctx);
      List<Widget> bodies = _makeAppBodies(ctx);
      List<int> newMsgCounters = _newMsgsCounters();

      final bool isWide = isWideScreen(ctx);
      if (isWide) {
	 const double sep = 3.0;
	 Divider div = Divider(height: sep, thickness: sep, indent: 0.0, color: Colors.grey);

	 List<Widget> tabWdgs = makeTabWdgs(
	    ctx: ctx,
	    counters: newMsgCounters,
	    opacities: cts.newMsgsOpacitiesWeb,
	 );

	 Widget ownTopBar = AppBar(
	    actions: _makeTabActions(ctx, cts.ownIdx),
	    title: _makeAppBarTitleWdg(isWide, cts.ownIdx, tabWdgs[cts.ownIdx]),
	    leading: _makeAppBarLeading(isWide, cts.ownIdx),
	 );

	 Widget own;
	 if (_isOnOwnChat())
	    own = Column(children: <Widget>[div, Expanded(child: _makeChatScreen(ctx, cts.ownIdx)), div]);
	 else
	    own = Column(children: <Widget>[div, ownTopBar, Expanded(child: bodies[cts.ownIdx]), div]);

	 Widget searchTopBar = AppBar(
	    actions: _makeTabActions(ctx, cts.searchIdx),
	    title: _makeAppBarTitleWdg(isWide, cts.searchIdx, tabWdgs[cts.searchIdx]),
	    leading: _makeAppBarLeading(isWide, cts.searchIdx),
	 );

	 Widget search = Column(
	    children: <Widget>
	    [ div
	    , searchTopBar
	    , Expanded(child: bodies[cts.searchIdx])
	    , div
	    ]
	 );

	 Widget favTopBar = AppBar(
	    actions: _makeTabActions(ctx, cts.favIdx),
	    title: _makeAppBarTitleWdg(isWide, cts.favIdx, tabWdgs[cts.favIdx]),
	    leading: _makeAppBarLeading(isWide, cts.favIdx),
	 );

         Widget fav;
	 if (_isOnFavChat())
	    fav = Column(children: <Widget>[div, Expanded(child: _makeChatScreen(ctx, cts.favIdx)), div]);
	 else
	    fav = Column(children: <Widget>[div, favTopBar, Expanded(child: bodies[cts.favIdx]), div]);

	 VerticalDivider vdiv = VerticalDivider(width: sep, thickness: sep, indent: 0.0, color: Colors.grey);
	 Widget body = Row(children: <Widget>
	    [ vdiv
	    , Expanded(flex: cts.tabFlexValues[cts.ownIdx], child: Stack(children: <Widget>[own, Positioned(bottom: 20.0, right: 20.0, child: fltButtons[cts.ownIdx])]))
	    , vdiv
	    , Expanded(flex: cts.tabFlexValues[cts.searchIdx], child: Stack(children: <Widget>[search, Positioned(bottom: 20.0, right: 20.0, child: fltButtons[cts.searchIdx])]))
	    , vdiv
	    , Expanded(flex: cts.tabFlexValues[cts.favIdx], child: Stack(children: <Widget>[fav, Positioned(bottom: 20.0, right: 20.0, child: fltButtons[cts.favIdx])]))
	    , vdiv
	    ],
	 );

	 return makeWebScaffoldWdg(
	    body: body,
	    appBar: AppBar(
               title: Text(g.param.appName),
	       elevation: 0.0,
	       actions: _makeGlobalActionsWeb(ctx),
	    ),
	    onWillPopScope: () {return true;},
	 );
      }

      if (_isOnFavChat() || _isOnOwnChat())
         return _makeChatScreen(ctx, screenIdx);

      List<Widget> actions = _makeTabActions(ctx, screenIdx);
      actions.addAll(_makeGlobalActionsApp(ctx, screenIdx));
      List<double> opacities = _getNewMsgsOpacities();

      return makeAppScaffoldWdg(
	 onWillPops: () {return _makeOnWillPop(_tabCtrl.index);},
	 scrollCtrl: _scrollCtrl[_screenIdx()],
	 appBarTitle: _makeAppBarTitleWdg(isWide, screenIdx, Text(g.param.appName)),
	 appBarLeading: _makeAppBarLeading(isWide, screenIdx),
	 floatBut: fltButtons[_tabCtrl.index],
	 body: TabBarView(controller: _tabCtrl, children: bodies),
	 tabBar: makeTabBar(ctx, newMsgCounters, _tabCtrl, opacities, _hasLPChatMsgs(screenIdx)),
	 actions: actions,
      );
   }
}

