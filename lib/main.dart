import 'dart:async' show Future, Timer;
import 'dart:convert';
import 'dart:io';
import 'dart:collection';
import 'dart:developer';

import 'dart:io'
       if (dart.library.io)
          'package:web_socket_channel/io.dart'
       if (dart.library.html)
          'package:web_socket_channel/html.dart';

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
import 'package:occase/appstate.dart';

typedef OnPressedF00 = void Function();
typedef OnPressedF01 = void Function(int);
typedef OnPressedF02 = void Function(BuildContext, int);
typedef OnPressedF03 = void Function(int, int);
typedef OnPressedF04 = void Function(BuildContext);
typedef OnPressedF05 = void Function(BuildContext, String, int);
typedef OnPressedF06 = void Function(int i, double);
typedef OnPressedF07 = bool Function();
typedef OnPressedF08 = void Function(int, double);
typedef OnPressedF09 = void Function(String);
typedef OnPressedF10 = void Function(int, bool);
typedef OnPressedF11 = void Function(BuildContext, int, DragStartDetails);
typedef OnPressedF12 = void Function(List<int>, int);
typedef OnPressedF13 = void Function(bool, int);
typedef OnPressedF14 = void Function(List<int>);
typedef OnPressedF15 = void Function(ConfigActions);
typedef OnPressedF16 = void Function(String, int);

bool isWideScreenImpl(double w)
{
   return w > (3 * cts.tabDefaultWidth);
}

double makeTabWidthImpl(double w, int tab)
{
   if (isWideScreenImpl(w))
      return cts.tabWidthRates[tab] * w;

   return w;
}

double makeTabWidth(BuildContext ctx, int tab)
{
   final double w = MediaQuery.of(ctx).size.width;
   return makeTabWidthImpl(w, tab);
}

double makeImgHeight(BuildContext ctx, int tab)
{
   return makeTabWidth(ctx, tab) / 1.618033;
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

double makeDialogWidth(BuildContext ctx, int tab)
{
   double w = makeTabWidth(ctx, tab);
   return 0.98 * w;
}

double makeDialogHeight(BuildContext ctx, int tab)
{
   double w = makeTabWidth(ctx, tab);
   return 0.98 * w;
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

Future<void> fcmOnBackgroundMessage(Map<String, dynamic> message) async
{
  log("onBackgroundMessage: $message");
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

   Coord(
   { this.post
   , this.chat
   , this.msgIdx = -1
   });
}

void myprint(Coord c, String prefix)
{
   log('$prefix ===> (${c.post.id}, ${c.chat.peer}, ${c.msgIdx})');
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

Future<void> removeLpChat(Coord c, AppState appState) async
{
   // removeWhere could also be used, but that traverses all elements
   // always and we know there is only one element to remove.

   final bool ret = c.post.chats.remove(c.chat);
   assert(ret);

   final int n = await appState.deleteChatStElem(c.post.id, c.chat.peer);
   assert(n == 1);
}

Future<Null> main() async
{
  runApp(MyApp());
}

enum ConfigActions
{ ChangeNick
, Notifications
, Information
}

Widget makeAppBarVertAction(OnPressedF15 onSelected)
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

List<Widget> makeOnLongPressedActions(
   OnPressedF00 deleteChatEntryDialog,
   OnPressedF00 pinChat,
) {
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
      appBar: AppBar(
         title: Text(g.param.shareSubject,
            style: TextStyle(color: stl.colorScheme.onPrimary),
         ),
      ),
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
      onPageChanged: (int i){ log('===> New index: $i');},
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

Widget makeRegisterScreen({
   TextEditingController emailCtrl,
   TextEditingController nickCtrl,
   Function onContinue,
   String title,
   String previousEmail,
   String previousNick,
   double maxWidth,
   OnPressedF07 onWillPopScope,
}) {
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

   return makeConfigScaffold(
      title: title,
      onWillPopScope: onWillPopScope,
      body: Center(
         child: Padding(
            child: body,
            padding: EdgeInsets.symmetric(horizontal: 20.0),
         ),
      ),
   );
}

Widget makeNtfScreen({
   BuildContext ctx,
   Function onChange,
   final String title,
   final NtfConfig ntfConfig,
   final List<String> titleDescription,
   OnPressedF07 onWillPopScope,
}) {
   assert(titleDescription.length >= 2);

   CheckboxListTile chat = CheckboxListTile(
      dense: true,
      title: Text(titleDescription[0], style: stl.ltTitle),
      subtitle: Text(titleDescription[1], style: stl.ltSubtitle),
      value: ntfConfig.chat,
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

   return makeConfigScaffold(
      title: title,
      onWillPopScope: onWillPopScope,
      body: Padding(
         child: Center(child: tmp),
         padding: EdgeInsets.symmetric(vertical: 20.0),
      ),
   );
}

Widget makeHiddenButton(OnPressedF00 onHiddenButtonLP, Color color)
{
   return FlatButton(
      onPressed: onHiddenButtonLP,
      child: Text(''),
      color: color,
      textColor: color,
      disabledTextColor: color,
      disabledColor: color,
      focusColor: color,
      hoverColor: color,
      highlightColor: color,
      splashColor: color,
   );
}

Widget makeConfigScaffold({
   String title,
   OnPressedF07 onWillPopScope,
   Widget body,
}) {
   return WillPopScope(
      onWillPop: () async { return onWillPopScope();},
      child: Scaffold(
	 backgroundColor: Colors.white,
	 appBar: AppBar(
	    title: Text(title,
	       style: TextStyle(color: stl.colorScheme.onPrimary),
	    ),
	    leading: IconButton(
	       padding: EdgeInsets.all(0.0),
	       icon: Icon(Icons.arrow_back, color: stl.colorScheme.onPrimary),
	       onPressed: onWillPopScope,
	    ),
	 ),
	 body: body,
      ),
   );
}

Widget makeInfoScreen(
   BuildContext ctx,
   OnPressedF07 onWillPopScope,
   OnPressedF00 onSendEmail,
   OnPressedF00 onHiddenButtonLP,
) {
   final double width = makeTabWidth(ctx, cts.ownIdx);

   Column col = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>
      [ makeHiddenButton(onHiddenButtonLP, Colors.white),
        RaisedButton(
	    onPressed: onSendEmail,
	    child: Text(g.param.supportEmail,
	       style: TextStyle(
		  fontSize: 20.0,
		  color: stl.colorScheme.primary,
		  fontWeight: FontWeight.normal,
	       ),
	    ),
	 ),
	 makeHiddenButton((){}, Colors.white),
      ],
   );

   return makeConfigScaffold(
      title: g.param.shareSubject,
      onWillPopScope: onWillPopScope,
      body: Padding(
	 child: Center(child: col),
	 padding: EdgeInsets.symmetric(vertical: 20.0),
      ),
   );
}

Widget makeNetImgBox({
   double width,
   double height,
   String url,
   BoxFit boxFit,
}) {
   return CachedNetworkImage(
      imageUrl: url,
      width: width,
      height: height,
      fit: boxFit,
      placeholder: (ctx, url) => CircularProgressIndicator(),
      errorWidget: (ctx, url, error) {
         log('====> $error $url $error');
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
   Widget w,
) {
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
Widget makeImgListView({
   BuildContext ctx,
   final double width,
   final double height,
   Post post,
   BoxFit boxFit,
   List<PickedFile> imgFiles,
   OnPressedF01 onExpandImg,
   OnPressedF02 addImg,
}) {
   final int l1 = post.images.length;
   final int l2 = imgFiles.length;

   if (l1 == 0 && l2 == 0)
      return makeImgPlaceholder(
	 width,
	 height,
	 makeImgTextPlaceholder(g.param.addImgMsg),
      );

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
         //      width: width,
         //      height: height,
         //   ),
         //);

	 Widget imgCounter = makeTextWdg(text: '${i + 1}/$l');

	 List<Widget> wdgs = List<Widget>();

	 if (post.images.isNotEmpty) {
	    Widget tmp = makeNetImgBox(
	       width: width,
	       height: height,
	       url: post.images[l - i - 1],
	       boxFit: boxFit,
	    );
	    wdgs.add(tmp);
	    wdgs.add(Positioned(child: makeWdgOverImg(imgCounter), top: 4.0));
	 } else if (imgFiles.isNotEmpty) {
	    Widget tmp = getImage(
	       path: imgFiles[i].path,
	       width: width,
	       height: height,
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
              style: stl.newPostSubtitleLT.copyWith(
		 color: stl.colorScheme.primary,
		 fontSize: stl.ltTitleFontSize,
	      ),
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
   final OnPressedF13 onChanged,
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
   final Node locRootNode,
   final Node prodRootNode,
   final Node exDetailsRootNode,
   final Node inDetailsRootNode,
   final List<PickedFile> imgFiles,
   final OnPressedF02 onAddPhoto,
   final OnPressedF04 onPublishPost,
   final OnPressedF04 onRemovePost,
}) {

   // NOTE: This ListView is used to provide a new context, so that
   // it is possible to show the snackbar using the scaffold.of on
   // the new context.

   Widget w0 = PostWidget(
      tab: cts.ownIdx,
      post: post,
      exDetailsRootNode: exDetailsRootNode,
      inDetailsRootNode: inDetailsRootNode,
      locRootNode: locRootNode,
      prodRootNode: prodRootNode,
      imgFiles: imgFiles,
      onAddPhoto: onAddPhoto,
      onExpandImg: (int j){ log('Noop00'); },
      onAddPostToFavorite: () { log('Noop01'); },
      onDelPost: () { log('Noop02');},
      onSharePost: () { log('Noop03');},
      onReportPost: () { log('Noop05');},
      onPinPost: () { log('Noop06');},
      onVisualization: (var s) {log('Noop07');},
      onClick: (var s) {log('Noop08');},
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
   int tab,
   bool newPostPressed,
   bool hasLPChats,
   bool hasLPChatMsgs,
   OnPressedF00 deleteChatDialog,
   OnPressedF00 pinChats,
   OnPressedF00 onClearPostsDialog,
}) {
   final bool fav = tab == cts.favIdx;
   final bool own = tab == cts.ownIdx;
   final bool search = tab == cts.searchIdx;

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
   OnPressedF00 onSearchPressed,
   OnPressedF00 onNewPost,
   OnPressedF15 onAppBarVertPressed,
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
   OnPressedF00 onSearchPressed,
   OnPressedF00 onNewPost,
   OnPressedF15 onAppBarVertPressed,
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
   final OnPressedF00 onWillLeaveSearch,
   final OnPressedF00 onWillLeaveNewPost,
   final OnPressedF00 onBackFromChatMsgRedirect,
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
   Widget defaultWdg,
}) {
   final bool fav = tab == cts.favIdx;
   final bool own = tab == cts.ownIdx;
   final bool search = tab == cts.searchIdx;

   if ((fav || own) && hasLpChatMsgs)
      return Text(g.param.msgOnRedirectingChat);

   if (own && newPostPressed)
      return makeSearchAppBar(title: g.param.newPostAppBarTitle);

   if (search && newSearchPressed && !isWide)
      return makeSearchAppBar(title: g.param.filterAppBarTitle);

   if (fav && (newSearchPressed || hasNoFavPosts) && isWide)
      return makeSearchAppBar(title: g.param.filterAppBarTitle);

   return defaultWdg;
}

Widget makeNewPostLT({
   final String title,
   final String subTitle,
   final IconData icon,
   OnPressedF00 onTap,
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
	     style: stl.newPostSubtitleLT.copyWith(
		color: stl.colorScheme.primary,
		fontSize: stl.ltTitleFontSize,
	     ),
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
   final OnPressedF14 onSetTreeCode,
}) {
   String subtitle = root.name(g.param.langIdx);
   if (defaultCode.isNotEmpty)
      subtitle = loadNames(root, defaultCode, g.param.langIdx).join(', ');

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
   final OnPressedF01 onSetInDetail,
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
   final Node locRootNode,
   final Node prodRootNode,
   final Node exDetailsRootNode,
   final Node inDetailsRootNode,
   final Post post,
   final OnPressedF12 onSetTreeCode,
   final OnPressedF03 onSetExDetail,
   final OnPressedF03 onSetInDetail,
   final OnPressedF06 onNewPostValueChanged,
}) {
   List<Widget> list = List<Widget>();

   {  // Location
      Widget location = makeChooseTreeNodeDialog(
	 ctx: ctx,
	 tab: tab,
	 title: g.param.newPostTabNames[0],
	 defaultCode: post.location,
	 root: locRootNode,
	 //iconData: Icons.edit_location,
	 onSetTreeCode: (var code) { onSetTreeCode(code, 0);},
      );

      list.add(Padding(padding: EdgeInsets.only(left: stl.leftIndent), child: location));
      list.add(stl.newPostDivider);
   }

   {  // Product
      Widget product = makeChooseTreeNodeDialog(
	 ctx: ctx,
	 tab: tab,
	 title: g.param.newPostTabNames[1],
	 defaultCode: post.product,
	 root: prodRootNode,
	 //iconData: Icons.directions_car,
	 onSetTreeCode: (var code) { onSetTreeCode(code, 1);},
      );

      list.add(Padding(padding: EdgeInsets.only(left: stl.leftIndent), child: product));
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
	 names: g.param.postValueTitles,
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

Widget makeNewPostScreenWdgs({
   BuildContext ctx,
   final bool sendingPost,
   final Node locRootNode,
   final Node prodRootNode,
   final Node exDetailsRootNode,
   final Node inDetailsRootNode,
   final Post post,
   final List<PickedFile> imgFiles,
   final OnPressedF12 onSetTreeCode,
   final OnPressedF03 onSetExDetail,
   final OnPressedF03 onSetInDetail,
   final OnPressedF02 onAddPhoto,
   final OnPressedF04 onPublishPost,
   final OnPressedF04 onRemovePost,
   final OnPressedF08 onRangeValueChanged,
   final OnPressedF06 onNewPostValueChanged,
   final OnPressedF09 onSetPostDescription,
}) {
   List<Widget> list = makeNewPostWdgs(
      ctx: ctx,
      tab: cts.ownIdx,
      locRootNode: locRootNode,
      prodRootNode: prodRootNode,
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
		     return PostDescription(description: post.description);
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
	    locRootNode: locRootNode,
	    prodRootNode: prodRootNode,
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

   if (!sendingPost)
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

Widget makeSearchAppBar({final String title})
{
   return ListTile(
      dense: true,
      title: Text(title,
	 maxLines: 1,
	 overflow: TextOverflow.ellipsis,
	 style: stl.appBarLtTitle.copyWith(color: Colors.white),
      ),
   );
}

List<Widget> makeValueSliders({
   final Post post,
   final List<int> ranges,
   final List<int> divisions,
   final List<String> names,
   final OnPressedF06 onValueChanged,
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
	 name: names[i],
	 value: '$value',
	 separator: ': ',
      );

      sliders.add(Padding(padding: EdgeInsets.only(top: stl.leftIndent, left: stl.leftIndent), child: rt));
      sliders.add(Padding(padding: EdgeInsets.only(left: stl.leftIndent), child: slider));
      sliders.add(stl.newPostDivider);
   }

   return sliders;
}

Widget makeSearchScreenWdg({
   BuildContext ctx,
   final int state,
   String numberOfMatchingPosts,
   final Node locRootNode,
   final Node prodRootNode,
   final Node exDetailsRootNode,
   final Post post,
   final List<int> ranges,
   final List<int> divisions,
   final OnPressedF01 onSearchPressed,
   final OnPressedF01 onSearchDetail,
   final OnPressedF06 onValueChanged,
   final OnPressedF14 onSetLocationCode,
   final OnPressedF14 onSetProductCode,
}) {
   List<Widget> foo = List<Widget>();

   {  // Location
      Widget location = makeChooseTreeNodeDialog(
	 ctx: ctx,
	 tab: cts.searchIdx,
	 title: g.param.newPostTabNames[0],
	 defaultCode: post.location,
	 root: locRootNode,
	 //iconData: Icons.edit_location,
	 onSetTreeCode: onSetLocationCode,
      );

      foo.add(Padding(padding: EdgeInsets.only(left: stl.leftIndent), child: location));
      foo.add(stl.newPostDivider);
   }

   {  // Product
      Widget product = makeChooseTreeNodeDialog(
	 ctx: ctx,
	 tab: cts.searchIdx,
	 defaultCode: post.product,
	 title: g.param.newPostTabNames[1],
	 root: prodRootNode,
	 //iconData: Icons.directions_car,
	 onSetTreeCode: onSetProductCode,
      );

      foo.add(Padding(padding: EdgeInsets.only(left: stl.leftIndent), child: product));
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
	 names: g.param.postSearchValueTitles,
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

      String buttonTitle = '${g.param.filterAppBarTitle}';
      if (numberOfMatchingPosts.isNotEmpty)
	 buttonTitle += ': $numberOfMatchingPosts';

      Widget w2 = createRaisedButton(
         () {onSearchPressed(2);},
         buttonTitle,
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
         supportedLocales:
	 [
            const Locale('de'),
            const Locale('pt'),
            const Locale('es'),
            const Locale('fr'),
            const Locale('en'),
         ],
      );
   }
}

Widget makeAppScaffoldWdg({
   OnPressedF07 onWillPops,
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
   OnPressedF07 onWillPopScope,
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
   OnPressedF00 onNewPost,
   OnPressedF00 onFwdChatMsg,
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
   final OnPressedF00 onNewPost,
   final OnPressedF01 onFwdSendButton,
   final OnPressedF00 onSearch,
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
   final OnPressedF00 onSearch,
}) {
   //log('$onSearchScreen $isWide $hasFavPosts');
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
   ChatMetadata chatMetadata,
   int i,
   Function onChatMsgLongPressed,
   Function onDragChatMsg,
   bool isNewMsg,
   String ownNick,
) {
   Color txtColor = Colors.black;
   Color color = Color(0xFFFFFFFF);
   Color onSelectedMsgColor = Colors.grey[300];
   if (chatMetadata.msgs[i].isFromThisApp()) {
      color = Colors.lime[100];
   } else if (isNewMsg) {
      //txtColor = stl.colorScheme.onPrimary;
      //color = Color(0xFF0080CF);
   }

   if (chatMetadata.msgs[i].isLongPressed) {
      onSelectedMsgColor = Colors.blue[200];
      color = Colors.blue[100];
      txtColor = Colors.black;
   }

   RichText msgAndDate = RichText(
      text: TextSpan(
         text: chatMetadata.msgs[i].message,
         style: stl.textField.copyWith(color: txtColor),
         children: <TextSpan>
         [ TextSpan(
              text: '  ${makeDateString(chatMetadata.msgs[i].date)}',
              style: Theme.of(ctx).textTheme.caption.copyWith(
                 color: Colors.grey[700],
              ),
           ),
         ]
      ),
   );

   // Unfortunately TextSpan still does not support general
   // widgets so I have to put the message status in a row instead
   // of simply appending it to the richtext as I do for the
   // date. Hopefully this will be fixed this later.
   Widget msgAndStatus;
   if (chatMetadata.msgs[i].isFromThisApp()) {
      msgAndStatus = Row(
         mainAxisSize: MainAxisSize.min,
         mainAxisAlignment: MainAxisAlignment.end,
         children: <Widget>
      [ Flexible(child: Padding(
            padding: EdgeInsets.all(stl.chatMsgPadding),
            child: msgAndDate))
      , Padding(
            padding: EdgeInsets.all(2.0),
            child: chooseMsgStatusIcon(chatMetadata.msgs[i].status))
      ]);
   } else {
      msgAndStatus = Padding(
            padding: EdgeInsets.all(stl.chatMsgPadding),
            child: msgAndDate);
   }

   Widget ww = msgAndStatus;
   if (chatMetadata.msgs[i].redirected()) {
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
   } else if (chatMetadata.msgs[i].refersToOther()) {
      Widget refWidget = makeRefChatMsgWidget(
         ctx: ctx,
         chatMetadata: chatMetadata,
         dragedIdx: chatMetadata.msgs[i].refersTo,
	 titleColor: selectColor(chatMetadata.peer),
         isNewMsg: isNewMsg,
         ownNick: ownNick,
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
         children: <Widget>[refMsg, msgAndStatus],
      );
   }

   double marginLeft = 10.0;
   double marginRight = 0.0;
   if (chatMetadata.msgs[i].isFromThisApp()) {
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
   if (chatMetadata.msgs[i].isFromThisApp()) {
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
   ChatMetadata chatMetadata,
   Function onChatMsgLongPressed,
   Function onDragChatMsg,
   String ownNick,
) {
   final int nMsgs = chatMetadata.msgs.length;
   final int shift = chatMetadata.divisorUnreadMsgs == 0 ? 0 : 1;

   return ListView.builder(
      controller: scrollCtrl,
      reverse: false,
      padding: const EdgeInsets.only(bottom: 3.0, top: 3.0),
      itemCount: nMsgs + shift,
      itemBuilder: (BuildContext ctx, int i)
      {
         if (shift == 1) {
            if (i == chatMetadata.divisorUnreadMsgsIdx) {
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
                            '${chatMetadata.divisorUnreadMsgs}',
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

            if (i > chatMetadata.divisorUnreadMsgsIdx) {
	       log('$i ${chatMetadata.divisorUnreadMsgsIdx}');
               i -= 1; // For the shift
	    }
         }

         final bool isNewMsg =
            shift == 1 &&
            i >= chatMetadata.divisorUnreadMsgsIdx &&
            i < chatMetadata.divisorUnreadMsgsIdx + chatMetadata.divisorUnreadMsgs;
                               
         Card chatMsgWidget = makeChatMsgWidget(
            ctx,
	    tab,
            chatMetadata,
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

Widget makeRefChatMsgWidget({
   BuildContext ctx,
   bool isNewMsg,
   int dragedIdx,
   String ownNick,
   ChatMetadata chatMetadata,
   Color titleColor,
}) {
   if (isNewMsg)
      titleColor = stl.colorScheme.secondary;

   Text body = Text(chatMetadata.msgs[dragedIdx].message,
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(ctx).textTheme.caption.copyWith(
         color: Colors.black,
      ),
   );

   String nick = chatMetadata.nick;
   if (chatMetadata.msgs[dragedIdx].isFromThisApp())
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
        ),
        body
      ],
   );

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

Widget makeChatScreen({
   BuildContext ctx,
   bool showChatJumpDownButton,
   int tab,
   int nLongPressed,
   int dragedIdx,
   String postSummary,
   String avatar,
   String ownNick,
   ChatMetadata chatMetadata,
   TextEditingController editCtrl,
   ScrollController scrollCtrl,
   FocusNode chatFocusNode,
   OnPressedF07 onWillPopScope,
   OnPressedF00 onSendChatMsg,
   OnPressedF10 onChatMsgLongPressed,
   OnPressedF00 onFwdChatMsg,
   OnPressedF11 onDragChatMsg,
   OnPressedF04 onChatMsgReply,
   OnPressedF00 onAttachment,
   OnPressedF00 onCancelFwdLPChatMsg,
   OnPressedF00 onChatJumpDown,
   OnPressedF09 onWritingChat,
}) {
   Column secondLayer = makeChatSecondLayer(
      ctx,
      editCtrl.text.isEmpty ? null : onSendChatMsg,
      onAttachment,
   );

   TextField tf = TextField(
       style: stl.textField,
       controller: editCtrl,
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
      chatMetadata,
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

      if (chatMetadata.nUnreadMsgs > 0) {
         Widget jumDownButton = Positioned(
            bottom: 53.0,
            right: 23.0,
            child: makeUnreadMsgsCircle(
               ctx,
               chatMetadata.nUnreadMsgs,
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
      Color co1 = selectColor(chatMetadata.peer);
      Icon w1 = Icon(Icons.forward, color: Colors.grey);

      // It looks like there is not maxlines option on TextSpan, so
      // for now I wont be able to show the date at the end.
      Widget w2 = Padding(
         padding: const EdgeInsets.symmetric(horizontal: 5.0),
         child: makeRefChatMsgWidget(
            ctx: ctx,
            chatMetadata: chatMetadata,
            dragedIdx: dragedIdx,
            titleColor: co1,
            isNewMsg: false,
            ownNick: ownNick,
         ),
      );

      IconButton w4 = IconButton(
         icon: Icon(Icons.clear, color: Colors.grey),
         onPressed: onCancelFwdLPChatMsg);

      // C0001
      // NOTE: At the moment I do not know how to add the division bar
      // without fixing the height. That means on some rather short
      // text msgs there will be too much empty vertical space, that
      // doesn't look good. I will leave this out untill I find a
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
         chatMetadata,
         postSummary,
         stl.onPrimarySubtitleColor,
      );

      title = ListTile(
          contentPadding: EdgeInsets.all(0.0),
          leading: CircleAvatar(
              child: child,
              backgroundImage: backgroundImage,
              backgroundColor: selectColor(chatMetadata.peer),
          ),
          title: Text(chatMetadata.getChatDisplayName(),
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

Widget makePayPriceListTile({
   BuildContext ctx,
   String price,
   String title,
   String subtitle,
   Color priceColor,
   OnPressedF00 onTap,
}) {
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
      color: priceColor,
      elevation: 0.0,
      shape: RoundedRectangleBorder(
         borderRadius: BorderRadius.all(Radius.circular(10.0)),
      ),
      child: Padding(
         padding: EdgeInsets.all(10.0),
         child: Text(price, style: TextStyle(color: Colors.white)),
      ),
   );

   return ListTile(
       leading: leading,
       title: titleW,
       dense: false,
       subtitle: subtitleW,
       trailing: Icon(Icons.keyboard_arrow_right),
       contentPadding: EdgeInsets.symmetric(horizontal: 2),
       onTap: onTap,
       enabled: true,
       selected: false,
       isThreeLine: true,
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
//   log(result.nonce);
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
         ctx: ctx,
         price: g.param.payments0[i],
         title: g.param.payments1[i],
         subtitle: g.param.payments2[i],
         priceColor: stl.priceColors[i],
         onTap: payments[i],
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

Widget createRaisedButton(
   OnPressedF00 onPressed,
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
	 //textAlign: TextAlign.center,
      ),
      color: color,
      onPressed: onPressed,
   );

   return Center(child: ButtonTheme(minWidth: stl.minButtonWidth, child: but));
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
      [ Icon(Icons.check, color: Colors.green[600])
      , text
      ]); 

      list.add(row);
   }

   return list;
}

Widget makePostSectionTitle(String str)
{
   return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
         padding: EdgeInsets.all(stl.postSectionPadding),
         child: Text(str,
            style: stl.ltTitle.copyWith(color: stl.infoValueColor),
         ),
      ),
   );
}

// Assembles the menu information.
List<Widget> makeTreeInfo(
   BuildContext ctx,
   final Node rootNode,
   final List<int> code,
   final String title,
   List<String> menuDepthNames,
) {
   List<Widget> ret = <Widget>[];
   ret.add(makePostSectionTitle(title));
   List<String> names = loadNames(rootNode, code, g.param.langIdx);

   List<Widget> tmp = List<Widget>.generate(names.length, (int j)
   {
      return makePostRowElem(ctx, menuDepthNames[j], names[j]);
   });

   ret.addAll(tmp);
   return ret;
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
   List<Widget> list = <Widget>[];

   list.add(makePostSectionTitle(g.param.rangesTitle));

   List<Widget> items = List.generate(g.param.rangeDivs.length, (int i)
      { return makePostRowElem(ctx, g.param.postValueTitles[i], makeRangeStr(post, i)); });

   list.addAll(items); // The menu info.

   return list;
}

List<Widget> makePostViews({
   BuildContext ctx,
   Post post,
   final List<String> titleAndFields,
}) {
   List<Widget> list = <Widget>[];

   list.add(makePostSectionTitle(titleAndFields[0]));
   list.add(makePostRowElem(ctx, titleAndFields[1], '${post.onSearch}'));
   list.add(makePostRowElem(ctx, titleAndFields[2], '${post.views}'));
   list.add(makePostRowElem(ctx, titleAndFields[3], '${post.clicks}'));

   return list;
}

List<Widget> makePostExDetails(BuildContext ctx, Post post, Node exDetailsRootNode)
{
   // Post details varies according to the first index of the products
   // entry in the menu.
   final int idx = post.getProductDetailIdx();
   if (idx == -1)
      return List<Widget>();

   List<Widget> list = List<Widget>();
   list.add(makePostSectionTitle(g.param.postExDetailsTitle));

   final int l1 = exDetailsRootNode.children[idx].children.length;
   for (int i = 0; i < l1; ++i) {
      final int n = exDetailsRootNode.children[idx].children[i].children.length;
      final int k = post.exDetails[i];
      if (k == -1 || k >= n)
	 continue;
      
      list.add(
         makePostRowElem(ctx,
            exDetailsRootNode.children[idx].children[i].name(g.param.langIdx),
            exDetailsRootNode.children[idx].children[i].children[k].name(g.param.langIdx),
         ),
      );
   }

   list.add(makePostSectionTitle(g.param.postRefSectionTitle));

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

List<Widget> makePostInDetails(Post post, Node inDetailsRootNode)
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

Widget makePostDescription(BuildContext ctx, int tab, String desc)
{
   final double width = makeMaxWidth(ctx, tab);

   return ConstrainedBox(
      constraints: BoxConstraints(
         maxWidth: stl.infoWidthFactor * width,
         minWidth: stl.infoWidthFactor * width,
      ),
      child: Text(
         desc,
         //overflow: TextOverflow.ellipsis,
         style: stl.textField,
      ),
   );
}

List<Widget> assemblePostRows({
   BuildContext ctx,
   final int tab,
   final Post post,
   final Node locRootNode,
   final Node prodRootNode,
   final Node exDetailsRootNode,
   final Node inDetailsRootNode,
}) {
   List<Widget> all = List<Widget>();

   all.addAll(makePostViews(
	 ctx: ctx,
	 post: post,
	 titleAndFields: g.param.statsTitleAndFields,
      ),
   );

   all.addAll(makePostValues(ctx, post));

   all.addAll(makeTreeInfo(ctx, locRootNode, post.location, g.param.newPostTabNames[0], g.param.menuDepthNames0));
   all.addAll(makeTreeInfo(ctx, prodRootNode, post.product, g.param.newPostTabNames[1], g.param.menuDepthNames1));

   all.addAll(makePostExDetails(ctx, post, exDetailsRootNode));
   all.addAll(makePostInDetails(post, inDetailsRootNode));

   if (post.description.isNotEmpty) {
      all.add(makePostSectionTitle(g.param.postDescTitle));
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

Widget makeTextWdg({
   String text,
   EdgeInsets edgeInsets = const EdgeInsets.all(3.0),
   FontWeight fontWeight = FontWeight.normal,
   Color backgroundColor = const Color(0xFFFFFFFF),
   Color textColor = const Color(0xFF000000),
   double fontSize = stl.subtitleFontSize,
}) {
   Widget w = Padding(
      child: Text(text,
         style: TextStyle(
            color: textColor,
	    fontSize: fontSize,
	    fontWeight: fontWeight,
            //backgroundColor: backgroundColor,
         ),
         overflow: TextOverflow.ellipsis,
      ),
      padding: edgeInsets,
   );

   return w;
}

Widget makeAddOrRemoveWidget({
   OnPressedF00 onPressed,
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
   OnPressedF00 onDelPost,
   OnPressedF00 onSharePost,
   OnPressedF00 onPinPost,
}) {
   BoxConstraints bc = const BoxConstraints(
      maxWidth: 15.0,
      maxHeight: 15.0,
   );
   IconButton remove = IconButton(
      padding: EdgeInsets.all(0.0),
      //constraints: bc,
      onPressed: onDelPost,
      icon: Icon(
         Icons.clear,
         color: stl.colorScheme.primary,
      ),
   );

   IconButton share = IconButton(
      padding: EdgeInsets.all(0.0),
      onPressed: onSharePost,
      color: stl.colorScheme.primary,
      //constraints: bc,
      icon: Icon(Icons.share,
         color: stl.colorScheme.secondary,
      ),
   );

   IconData pinIcon = pinDate == 0 ? Icons.place : Icons.pin_drop;

   IconButton pin = IconButton(
      padding: EdgeInsets.all(0.0),
      //constraints: bc,
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
   final EdgeInsets insetPadding = const EdgeInsets.symmetric(horizontal: stl.alertDialogInsetPadding, vertical: stl.alertDialogInsetPadding),
}) {
   Column col = Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: list,
   );

   //ListView col = ListView.builder(
   //   scrollDirection: Axis.vertical,
   //   //shrinkWrap: true,
   //   padding: const EdgeInsets.all(0.0),
   //   itemCount: list.length,
   //   itemBuilder: (BuildContext ctx, int i) { return list[i]; },
   //);

   Widget content = Container(
      //child: col,
      child: SingleChildScrollView(
         scrollDirection: Axis.vertical,
         reverse: false,
         child: col
      ),
      constraints: BoxConstraints(
	 maxHeight: height,
	 maxWidth: width,
      ),
      decoration: BoxDecoration(
	 color: Colors.white,
	 shape: BoxShape.rectangle,
	 borderRadius: BorderRadius.all(const Radius.circular(stl.cornerRadius)),
      ),
   );

   return AlertDialog(
      title: title,
      contentPadding: EdgeInsets.all(indent),
      actions: actions,
      insetPadding: insetPadding,
      backgroundColor: Colors.grey[200],
      content: content,
      shape: RoundedRectangleBorder(
	 borderRadius: BorderRadius.all(
	    Radius.circular(0.0),
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

      return makeNewPostDialogWdg(
	 width: makeDialogWidth(ctx, cts.ownIdx),
	 height: makeDialogHeight(ctx, cts.ownIdx),
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

      return makeNewPostDialogWdg(
	 width: makeDialogWidth(ctx, cts.ownIdx),
	 height: makeDialogHeight(ctx, cts.ownIdx),
	 title: Text(widget.title, style: stl.newPostTitleLT),
	 indent: stl.newPostPadding,
	 list: exDetails,
	 actions: <FlatButton>[ok],
      );
   }
}

//---------------------------------------------------------------

class PostDescription extends StatefulWidget {
   String description;

   @override
   PostDescriptionState createState() => PostDescriptionState();
   PostDescription({this.description = ''});
}

class PostDescriptionState extends State<PostDescription> with TickerProviderStateMixin {
   TextEditingController _txtCtrl;

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
      _txtCtrl = TextEditingController(text: widget.description);
   }

   @override
   Widget build(BuildContext ctx)
   {
      String hint = widget.description.isEmpty ? g.param.newPostTextFieldHist : widget.description;
      TextField tf = TextField(
	 autofocus: true,
	 controller: _txtCtrl,
	 keyboardType: TextInputType.multiline,
	 maxLines: null,
	 maxLength: 1000,
	 style: stl.textField,
	 decoration: InputDecoration.collapsed(hintText: hint),
      );

      Padding content = Padding(
	 padding: EdgeInsets.all(10.0),
	 child: tf,
      );

      final FlatButton ok = FlatButton(
	 child: Text(g.param.ok),
	 onPressed: () { Navigator.pop(ctx, _txtCtrl.text); });

      EdgeInsets insetPadding;

      if (isWideScreen(ctx)) {
	 final double width = makeTabWidth(ctx, cts.ownIdx);
	 insetPadding = EdgeInsets.symmetric(
	    horizontal: width,
	    vertical: stl.alertDialogInsetPadding,
	 );
      } else {
	 insetPadding = EdgeInsets.symmetric(
	    horizontal: stl.alertDialogInsetPadding,
	    vertical: stl.alertDialogInsetPadding,
	 );
      }

      return AlertDialog(
	 contentPadding: EdgeInsets.all(stl.newPostPadding),
	 insetPadding: insetPadding,
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

      return makeNewPostDialogWdg(
	 width: makeDialogWidth(ctx, cts.ownIdx),
	 height: makeDialogHeight(ctx, cts.ownIdx),
	 title: titleWdg,
	 indent: stl.newPostPadding,
	 list: locWdgs,
	 actions: <FlatButton>[back, cancel, ok],
      );
   }
}

//---------------------------------------------------------------------

List<Widget> makeDetailsTextWdgs({
   List<String> fields,
   Color backgroundColor,
   Color textColor,
   double fontSize,
}) {
   return List<Widget>.generate(fields.length, (int i) {
      return Card(
	    elevation: 0.0,
	    color: backgroundColor,
	    margin: EdgeInsets.all(0.0),
	    child: Padding(
	       padding: const EdgeInsets.symmetric(horizontal: 3.0),
               child: Text(fields[i],
	          style: TextStyle(
	             fontSize: fontSize,
	             fontWeight: FontWeight.normal,
	             color: textColor,
	          ),
	       ),
	    ),
	 );
      },
   );
}

class PostWidget extends StatefulWidget {
   int tab;
   Post post;
   Node locRootNode;
   Node prodRootNode;
   Node exDetailsRootNode;
   Node inDetailsRootNode;
   List<PickedFile> imgFiles;
   OnPressedF02 onAddPhoto;
   OnPressedF01 onExpandImg;
   OnPressedF00 onAddPostToFavorite;
   OnPressedF00 onDelPost;
   OnPressedF00 onSharePost;
   OnPressedF00 onReportPost;
   OnPressedF00 onPinPost;
   OnPressedF09 onVisualization;
   OnPressedF09 onClick;

   @override
   PostWidgetState createState() => PostWidgetState();

   PostWidget(
   { @required this.tab
   , @required this.post
   , @required this.locRootNode
   , @required this.prodRootNode
   , @required this.exDetailsRootNode
   , @required this.inDetailsRootNode
   , @required this.imgFiles
   , @required this.onAddPhoto
   , @required this.onExpandImg
   , @required this.onAddPostToFavorite
   , @required this.onDelPost
   , @required this.onSharePost
   , @required this.onReportPost
   , @required this.onPinPost
   , @required this.onVisualization
   , @required this.onClick
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
      widget.onClick(widget.post.id);

      final int code = await showDialog<int>(
	 context: ctx,
	 builder: (BuildContext ctx2)
	 {
	    final int tab = cts.searchIdx;
	    Widget detailsWdg = makePostDetailsWdg(
	       ctx: ctx2,
	       tab: tab,
	       post: widget.post,
	       locRootNode: widget.locRootNode,
	       prodRootNode: widget.prodRootNode,
	       exDetailsRootNode: widget.exDetailsRootNode,
	       inDetailsRootNode: widget.inDetailsRootNode,
	       imgFiles: widget.imgFiles,
	       onAddPhoto: widget.onAddPhoto,
	       onExpandImg: widget.onExpandImg,
	       onReportPost: () 
	       {
		  Navigator.of(ctx).pop();
		  widget.onReportPost();
	       },
	       onSharePost: () 
	       {
		  Navigator.of(ctx).pop();
		  widget.onSharePost();
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

	    const double margin = 0.0;
	    const double insetPadding = 0.0;
	    final double height = makeMaxHeight(ctx);

	    Widget ret = makeNewPostDialogWdg(
	       width: width,
	       height: height,
               title: null,
	       indent: margin,
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
		         top: margin + insetPadding,
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
      widget.onVisualization(widget.post.id);
      const double postFontSize = 14.0;

      final List<Widget> buttons = makePostButtons(
	 pinDate: widget.post.pinDate,
	 onDelPost: widget.onDelPost,
	 onSharePost: widget.onSharePost,
	 onPinPost: widget.onPinPost,
      );

      // TODO: Change this to a shorter form.
      final String dateStr = makeDateString2(widget.post.date);
      final double dateFontSize = 12.0;

      Widget dateWdg = makeTextWdg(
	 text: '${dateStr}',
	 edgeInsets: const EdgeInsets.only(left: 0.0, top: 0.0, bottom: 0.0),
	 backgroundColor: null,
	 textColor: Colors.grey,
	 fontSize: dateFontSize,
      );

      final int onSearch = widget.post.onSearch;
      final int views = widget.post.views;
      final int clicks = widget.post.clicks;

      Widget viewsWdg = makeTextWdg(
	 text: '${onSearch}/${views}/${clicks}',
	 edgeInsets: const EdgeInsets.only(left: 5.0, top: 0.0, bottom: 0.0),
	 backgroundColor: null,
	 textColor: Colors.grey,
	 fontSize: dateFontSize,
      );

      final double imgAvatarWidth = makeImgAvatarWidth(ctx, widget.tab);

      Widget imgWdg;
      if (widget.post.images.isNotEmpty) {
	 Container img = Container(
	    //margin: const EdgeInsets.only(top: 10.0),
	    margin: const EdgeInsets.all(0.0),
	    child: makeNetImgBox(
	       width: imgAvatarWidth,
	       height: imgAvatarWidth,
	       url: widget.post.images.first,
	       boxFit: BoxFit.cover,
	    ),
	 );

	 Widget kmText = makeTextWdg(
	    text: makeRangeStr(widget.post, 2),
	    backgroundColor: null,
	 );

	 Widget priceText = makeTextWdg(
	    text: makeRangeStr(widget.post, 0),
	    backgroundColor: null,
	 );

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
	      ),
	    ],
	 );

	 row1List.add(st);
      } else {
	 row1List.add(imgWdg);
      }

      final String locationStr =
         makeTreeItemStr(widget.locRootNode, widget.post.location);
      final String modelStr =
	 makeTreeItemStr(widget.prodRootNode, widget.post.product);

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

      Padding modelTitle = Padding(
	 padding: const EdgeInsets.only(left: 5.0, top: 3.0),
	 child: RichText(
	    overflow: TextOverflow.ellipsis,
	    text: TextSpan(
	       text: '$modelStr ',
	       style: TextStyle(
		  color: Colors.black,
		  fontSize: postFontSize,
		  fontWeight: FontWeight.normal,
	       ),
	       children: <TextSpan>
	       [ TextSpan(
		    text: locationStr,
		    style: TextStyle(
		       color: Colors.grey,
		       fontSize: 12.0,
		       fontWeight: FontWeight.normal,
		    ),
		 ),
	       ],
	    ),
	 ),
      );

      Widget location = makeTextWdg(
	 text: locationStr,
      );

      List<Widget> exWdgs = makeDetailsTextWdgs(
	 fields: exDetailsNames,
	 backgroundColor: Colors.blueGrey[100],
	 textColor: Colors.black,
	 fontSize: postFontSize,
      );

      List<Widget> inWdgs = makeDetailsTextWdgs(
	 fields: inDetailsNames,
	 backgroundColor: Colors.brown[100],
	 textColor: Colors.black,
	 fontSize: postFontSize,
      );

      const double spacing = 10.0;
      const double runSpacing = 3.0;

      Widget s1 = Padding(
	 padding: EdgeInsets.all(3.0),
	 child: Wrap(
	    children: exWdgs,
	    spacing: spacing,
	    runSpacing: runSpacing,
	 ),
      );

      Widget s2 = Padding(
	 padding: EdgeInsets.all(3.0),
	 child: Wrap(
	    children: inWdgs,
	    spacing: spacing,
	    runSpacing: runSpacing,
	 ),
      );

      final double h1 = imgAvatarWidth * 2.0 / 12.0;
      double h2 = imgAvatarWidth * 4.0 / 12.0;
      if (h2 > 43)
	 h2 = 43;
      final double h3 = imgAvatarWidth * 2.0 / 12.0;
      final double postTxtWidth = makePostTextWidth(ctx, widget.tab);

      Column infoWdg = Column(children: <Widget>
      [ SizedBox(width: postTxtWidth, height: h1, child: modelTitle)
      , SizedBox(width: postTxtWidth, height: h2, child: s1)
      , SizedBox(width: postTxtWidth, height: h2, child: s2)
      , Expanded(child: SizedBox(width: postTxtWidth, child: Row(children: <Widget>[viewsWdg, Spacer(), dateWdg])))
      ]);

      row1List.add(SizedBox(height: imgAvatarWidth, child: infoWdg));

      return RaisedButton(
	 color: Colors.white,
	 onPressed: () {_onShowDetails(ctx);},
	 elevation: 2.0,
	 child: Row(children: row1List),
	 padding: const EdgeInsets.all(0.0),
	 onLongPress: widget.onDelPost,
      );
   }
}

Widget makePostDetailsWdg({
   BuildContext ctx,
   final int tab,
   final Post post,
   final Node locRootNode,
   final Node prodRootNode,
   final Node exDetailsRootNode,
   final Node inDetailsRootNode,
   final List<PickedFile> imgFiles,
   OnPressedF02 onAddPhoto,
   OnPressedF01 onExpandImg,
   OnPressedF00 onReportPost,
   OnPressedF00 onSharePost,
}) {
   List<Widget> rows = List<Widget>();

   Widget lv = makeImgListView(
      ctx: ctx,
      width: makeTabWidth(ctx, tab),
      height: makeImgHeight(ctx, tab),
      post: post,
      boxFit: BoxFit.cover,
      imgFiles: imgFiles,
      onExpandImg: (int j){ onExpandImg(j); },
      addImg: onAddPhoto,
   );

   rows.add(lv);

   IconButton share = IconButton(
      icon: Icon(
	 Icons.share,
	 color: stl.colorScheme.primary,
      ),
      onPressed: onSharePost,
   );

   rows.add(share);

   List<Widget> tmp = assemblePostRows(
      ctx: ctx,
      tab: tab,
      post: post,
      locRootNode: locRootNode,
      prodRootNode: prodRootNode,
      exDetailsRootNode: exDetailsRootNode,
      inDetailsRootNode: inDetailsRootNode,
   );

   rows.add(putPostElemOnCard(tmp, 4.0));

   return putPostElemOnCard(rows, 0.0);
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
   final OnPressedF00 onPressed,
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
   final Node locRootNode,
   final Node prodRootNode,
   final Node exDetailsRootNode,
   final Node inDetailsRootNode,
   final List<Post> posts,
   final OnPressedF03 onExpandImg,
   final OnPressedF02 onAddPostToFavorite,
   final OnPressedF02 onDelPost,
   final OnPressedF02 onSharePost,
   final OnPressedF02 onReportPost,
   final OnPressedF09 onPostVisualization,
   final OnPressedF09 onPostClick,
}) {
   // No controller should be assigned to this listview. This will break the
   // automatic hiding of the tabbar
   return ListView.separated(
      //key: PageStorageKey<String>('aaaaaaa'),
      padding: const EdgeInsets.all(0.0),
      itemCount: posts.length,
      separatorBuilder: (BuildContext context, int index)
      {
	 return Divider(color: Colors.black, height: 5.0);
      },
      itemBuilder: (BuildContext ctx, int i)
      {
         return PostWidget(
	    tab: cts.searchIdx,
            post: posts[i],
            exDetailsRootNode: exDetailsRootNode,
            inDetailsRootNode: inDetailsRootNode,
	    locRootNode: locRootNode,
	    prodRootNode: prodRootNode,
            imgFiles: List<PickedFile>(),
            onAddPhoto: (var ctx, var i) {log('Error: Please fix.');},
            onExpandImg: (int k) {onExpandImg(i, k);},
            onAddPostToFavorite: () {onAddPostToFavorite(ctx, i);},
	    onDelPost: () {onDelPost(ctx, i);},
	    onSharePost: () {onSharePost(ctx, i);},
	    onReportPost: () {onReportPost(ctx, i);},
	    onPinPost: (){log('Noop20');},
	    onVisualization: onPostVisualization,
	    onClick: onPostClick,
         );
      },
   );
}

ListTile makeNewPostTreeWdg({
   Node child,
   OnPressedF00 onLeafPressed,
   OnPressedF00 onNodePressed,
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
	    child.getChildrenNames(g.param.langIdx, 4),
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
   OnPressedF01 onLeafPressed,
   OnPressedF01 onNodePressed,
}) {
   List<Widget> list = List<Widget>();

   for (int i = 0; i < node.children.length; ++i) {
      Node child = node.children[i];
      Widget o =  makeNewPostTreeWdg(
	 child: child,
	 onLeafPressed: () {onLeafPressed(i);},
	 onNodePressed: () {onNodePressed(i);},
      );
      //list.add(SizedBox(width: makeMaxWidth(ctx, tab), child: o));
      list.add(o);
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

   final bool moreRecent = cm.lastPresenceReceived > cm.getLastChatMsgDate();

   if (moreRecent && now < last) {
      return ChatPresenceSubtitle(
         subtitle: g.param.typing,
         color: stl.colorScheme.onSecondary,
      );
   }

   return ChatPresenceSubtitle(
      subtitle: str,
      color: color,
   );
}

Widget makeChatTileSubtitle(BuildContext ctx, final ChatMetadata ch)
{
   String str = ch.getLastChatMsg();

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

   if (ch.nUnreadMsgs > 0 || !ch.isLastChatMsgFromThisApp())
      return Text(
         cps.subtitle,
         style: Theme.of(ctx).textTheme.subtitle.copyWith(
	    fontWeight: FontWeight.normal,
	    color: cps.color,
	 ),
         maxLines: 1,
         overflow: TextOverflow.ellipsis
      );

   return Row(children: <Widget>
   [ chooseMsgStatusIcon(ch.getLastChatMsgStatus())
   , Expanded(
        child: Text(cps.subtitle,
           maxLines: 1,
           overflow: TextOverflow.ellipsis,
           style: Theme.of(ctx).textTheme.subtitle.copyWith(
              fontWeight: FontWeight.normal,
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

Color selectColor(String peer)
{
   final int v = peer.length % 14;
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
   OnPressedF00 onChatLeadingPressed,
   OnPressedF00 onChatLongPressed,
   OnPressedF00 onStartChatPressed,
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
      chat.getLastChatMsgDate(),
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
         selectColor(chat.peer),
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
   OnPressedF01 onPressed,
   OnPressedF01 onLongPressed,
   OnPressedF16 onLeadingPressed,
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
   final int tab,
   final Node locRootNode,
   final Node prodRootNode,
   final Node exDetailsRootNode,
   final Node inDetailsRootNode,
   final List<Post> posts,
   final OnPressedF03 onPressed,
   final OnPressedF03 onLongPressed,
   final OnPressedF01 onDelPost1,
   final OnPressedF01 onPinPost1,
         OnPressedF05 onUserInfoPressed,
   final OnPressedF03 onExpandImg1,
   final OnPressedF01 onSharePost,
   final OnPressedF00 onPost,
}) {
   if (posts.length == 0) {
      if (tab == cts.ownIdx)
	 return makeOwnEmptyScreenWidget(
            onPressed: onPost,
	 );

      if (tab == cts.favIdx)
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
         OnPressedF00 onPinPost = () {onPinPost1(i);};
         OnPressedF00 onDelPost = () {onDelPost1(i);};
         OnPressedF01 onExpandImg = (int j) {onExpandImg1(i, j);};

         if (isFwdChatMsgs) {
            onUserInfoPressed = (var a, var b, var c){};
            onPinPost = (){};
            onDelPost = (){};
         }

         Widget title = Text(makeTreeItemStr(locRootNode, posts[i].location),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
         );

         // If the post contains no images, which should not happen,
         // we provide no expand image button.
         if (posts[i].images.isEmpty)
            onExpandImg = (int j){log('Error: post.images is empty.');};

	 Widget bbb = PostWidget(
	    tab: tab,
            post: posts[i],
	    locRootNode: locRootNode,
	    prodRootNode: prodRootNode,
            exDetailsRootNode: exDetailsRootNode,
            inDetailsRootNode: inDetailsRootNode,
            imgFiles: List<PickedFile>(),
            onAddPhoto: (var a, var b) {log('Noop10');},
            onExpandImg: onExpandImg,
            onAddPostToFavorite:() {log('Noop14');},
	    onDelPost: onDelPost,
	    onSharePost: () {onSharePost(i);},
	    onReportPost:() {log('Noop18');},
	    onPinPost: onPinPost,
	    onVisualization: (String) {log('Noop19');},
	    onClick: (String) {log('Noop20');},
	 );

         Widget chatExpansion = makeChatsExp(
            ctx,
            tab == cts.favIdx,
            isFwdChatMsgs,
            DateTime.now().millisecondsSinceEpoch,
            posts[i],
            posts[i].chats,
            (int j) {onPressed(i, j);},
            (int j) {onLongPressed(i, j);},
            (String a, int b) {onUserInfoPressed(ctx, a, b);},
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

class Occase extends StatefulWidget {
  Occase();

  @override
  OccaseState createState() => OccaseState();
}

class OccaseState extends State<Occase>
   with SingleTickerProviderStateMixin, WidgetsBindingObserver
{
   Node _locRootNode;
   Node _prodRootNode;
   Node _exDetailsRoot;
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

   int _hiddenButtonCounter = 0;
   int _hiddenButtonDate = 0;
   String _deletePostPwd = '';

   bool _sendingPost = false;

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

   // The date the last search started.
   int _searchBeginDate = 0;

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

   // The number of posts that match the search criteria.
   String _numberOfMatchingPosts = '';

   // Used in the final new post screen to store the files while the
   // user chooses the images.
   List<PickedFile> _imgFiles = List<PickedFile>();

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
      //     log("onMessage: $message");
      //   },
      //   //onBackgroundMessage: fcmOnBackgroundMessage,
      //   onLaunch: (Map<String, dynamic> message) async {
      //     log("onLaunch: $message");
      //   },
      //   onResume: (Map<String, dynamic> message) async {
      //     log("onResume: $message");
      //   },
      //);

      _firebaseMessaging.getToken().then((String token) {
         if (_fcmToken != null)
            _fcmToken = token;

         log('Token: $token');
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
         log('Trying to reconnect.');
         _stablishNewConnection(_fcmToken);
      }
   }

   Future<void> _init() async
   {
      final String text = await rootBundle.loadString('data/parameters.txt');
      g.param = Parameters.fromJson(jsonDecode(text));
      await initializeDateFormatting(g.param.localeName, null);

      final String locTreeStr = await rootBundle.loadString('data/locations.comp.tree');
      _locRootNode = makeTree(locTreeStr);

      final String prodTreeStr = await rootBundle.loadString('data/products.comp.tree');
      _prodRootNode = makeTree(prodTreeStr);

      final String exDetailsStr = await rootBundle.loadString('data/ex_details.comp.tree');
      _exDetailsRoot = makeTree(exDetailsStr);

      final String inDetailsStr = await rootBundle.loadString('data/in_details.comp.tree');
      _inDetailsRoot = makeTree(inDetailsStr);

      await _appState.load();

      _nNewPosts = 0;
      _goToRegScreen = _appState.cfg.nick.isEmpty;
      prepareNewPost(cts.ownIdx);
      prepareNewPost(cts.searchIdx);
      _stablishNewConnection(_fcmToken);
      _numberOfMatchingPosts = await _searchPosts(cts.dbCountPostsUrl);
      log(_numberOfMatchingPosts);
      await _searchPosts2();
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
      //   log('Trying to reconnect.');
      //   _stablishNewConnection(_fcmToken);
      //}
   }

   int _tabIndex()
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

   void _stablishNewConnection(String fcmToken)
   {
      try {
	 // For the web
	 websocket = HtmlWebSocketChannel.connect(cts.dbWebsocketUrl);
	 //websocket = IOWebSocketChannel.connect(cts.dbWebsocketUrl);
	 websocket.stream.listen(
	    _onWSData,
	    onError: _onWSError,
	    onDone: _onWSDone,
	 );

	 final String cmd = makeConnCmd(
	    user: _appState.cfg.user,
	    key: _appState.cfg.key,
	    fcmToken: fcmToken,
	    //_appState.cfg.notifications.getFlag(),
	 );

	 log(cmd);

	 websocket.sink.add(cmd);
      } catch (e) {
	 log('Unable to stablish ws connection to server.');
	 log(e);
      }
   }

   Future<void> _setDialogPref(int i, bool v) async
   {

      if (i == 0)
	 return;

      _appState.setDialogPreferences(i, v);
   }

   Future<void> _alertUserOnPressed(BuildContext ctx, int i, int j) async
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
            PickedFile img = await _picker.getImage(
               source: ImageSource.gallery,
               maxWidth: cts.imgWidth,
               maxHeight: cts.imgHeight,
               imageQuality: cts.imgQuality,
            );

            if (img == null)
               return;

            setState((){_imgFiles.add(img); });
         } else {
            setState((){_imgFiles.removeAt(i); });
         }
      } catch (e) {
         log(e);
      }
   }

   // i = index in _appState.posts, _appState.favPosts, _own_posts.
   // j = image index in the post.
   void _onExpandImg(int i, int j, int k)
   {
      //log('Expand image clicked with $i $j.');

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
         Share.share(g.param.share, subject: g.param.shareSubject);
         return;
      }
   }

   Future<void> _onMovePostToFav(int i) async
   {
      final int h = await _appState.movePostToFav(i);

      // We should be using the animate function below, but there is no way
      // one can wait until the animation is ready. The is needed to be able to call
      // _onChatPressed(i, 0) correctly. I will let it commented out for now.

      // Use _tabCtrlChangeHandler() as listener
      //_tabCtrl.animateTo(2, duration: Duration(seconds: 2));
      _tabCtrl.index = cts.favIdx;

      // The chat index in the fav screen is always zero.
      await _onChatPressed(cts.favIdx, h, 0);
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
         await _onRemovePost(cts.searchIdx, i);
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
      });
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
               message: c2.chat.msgs[c2.msgIdx].message,
               date: now,
            );

	    await _onSendChatImpl(
	       postId: c1.post.id,
	       to: c1.chat.peer,
	       chatItem: ci,
	    );
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
         postId: _posts[i].id,
         to: _chats[i].peer,
         chatItem: ChatItem(
            isRedirected: 0,
            message: _txtCtrl.text,
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
      log(payload);
      websocket.sink.add(payload);
   }

   void _chatScrollListener(int i)
   {
      if (i != _tabIndex()) {
	 // The control listener seems to be bound to all screens, thats why I
	 // have to filter it here.
	 log('Ignoring ---> $i');
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

   Future<void> _sendPost() async
   {
      _posts[cts.ownIdx].from = _appState.cfg.userId;
      _posts[cts.ownIdx].nick = _appState.cfg.nick;
      _posts[cts.ownIdx].avatar = emailToGravatarHash(_appState.cfg.email);
      _posts[cts.ownIdx].status = 3;
      _appState.outPost = _posts[cts.ownIdx].clone();

      // We add it here in our own list of posts and keep in mind it may be
      // echoed back to us. It has to be filtered out from _appState.posts
      // since that list should not contain our own posts.

      var pubMap =
      { 'cmd': 'publish'
      , 'post': _appState.outPost
      };

      final String payload = jsonEncode(pubMap);
      log(payload);
      websocket.sink.add(payload);
   }

   Future<void> deletePostFromServer(Post post) async
   {
      var map =
      { 'from': post.from
      , 'post_id': post.id
      , 'delete_key': post.delete_key
      , 'master_delete_key': _deletePostPwd
      };

      var resp = await http.post(cts.dbDeletePostUrl, body: jsonEncode(map));
      if (resp.statusCode != 200)
	 log('Error on _onRemovePost:  ${resp.statusCode}');
   }

   Future<void> _onRemovePost(int tab, int i) async
   {
      if (tab == cts.favIdx) {
         await _appState.delFavPost(i);
      } else if (tab == cts.ownIdx) {
         final Post post = await _appState.delOwnPost(i);
	 await deletePostFromServer(post);
      } else if (tab == cts.searchIdx) {
         final Post post = await _appState.delSearchPost(i);
	 await deletePostFromServer(post);
      }

      setState(() { });
   }

   Future<void> _onPinPost(int tab, int i) async
   {
      await _appState.setPinPostDate(i, tab == cts.favIdx);
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

         log('=====> Path $path');
         log('=====> Image name $basename');
         log('=====> Image extention $extension');
         log('=====> New name $newname');
         log('=====> Http target $newname');

         var response = await http.post(newname,
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

   Future<void> _requestFilenames() async
   {
      try {
	 setState(() {_sendingPost = true;});
	 var resp = await http.post(cts.dbUploadCreditUrl, body: '');
	 if (resp.statusCode != 200) {
	    log('Error: _requestFilenames ${resp.statusCode}');
	    setState(() { _leaveNewPostScreen(); });
	 }

	 if (resp.body.isEmpty) {
	    _leaveNewPostScreen();
	    _newPostErrorCode = 0;
	    log('Error: _requestFilenames, empty body.');
	    return; // TODO: Perhaps show a dialog with an error message?
	 }

	 var map = jsonDecode(resp.body);
	 List<dynamic> names = map["credit"];
	 List<String> fnames = List.generate(names.length, (i) {
	    return names[i];
	 });

	 _newPostErrorCode = await _uploadImgs(fnames);

	 if (_newPostErrorCode == -1)
	    await _sendPost();

      } catch (e) {
         //print(e);
         print('Error: _requestFilenames');
      }

      setState(() {
	 _sendingPost = false;
	 _leaveNewPostScreen();
      });
   }

   Future<void> _onSendNewPost(BuildContext ctx, int i) async
   {
      // When the user sends a post, we start a timer and a circular
      // progress indicator on the screen. To prevent the user from
      // interacting with the screen after clicking we use a modal
      // barrier.

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
               (BuildContext ctx) async
               {
                  Navigator.of(ctx).pop();
                  await _requestFilenames();
               },
            );
         },
      );
   }

   void _removePostDialog(BuildContext ctx, int tab, int i)
   {
      _showSimpleDialog(
         ctx,
         () async { await _onRemovePost(tab, i);},
         g.param.dialogTitles[4],
         Text(g.param.dialogBodies[4]),
      );
   }

   Future<void> _onChatPressedImpl(
      List<Post> posts,
      int i,
      int j,
      int tab,
   ) async {
      if (_lpChats[tab].isNotEmpty || _lpChatMsgs[i].isNotEmpty) {
         _onChatLPImpl(posts, i, j, tab);
         setState(() { });
         return;
      }

      _showChatJumpDownButtons[tab] = false;
      Post post = posts[i];
      ChatMetadata chat = posts[i].chats[j];

      // These variables must be set after the chats are loaded. Otherwise
      // chat.msgs may be called on null if a message arrives. 
      _posts[tab] = post;
      _chats[tab] = chat;

      if (_chats[tab].nUnreadMsgs != 0) {
         _chats[tab].divisorUnreadMsgsIdx = _chats[tab].msgs.length - _chats[tab].nUnreadMsgs;

         // We know the number of unread messages, now we have to generate
         // the array with the messages peer rowid.

         var msgMap =
         { 'cmd': 'message'
         , 'type': 'chat_ack_read'
         , 'to': posts[i].chats[j].peer
         , 'post_id': posts[i].id
         , 'id': -1
         , 'ack_ids': makeAckIds(_chats[tab].msgs.length, _chats[tab].nUnreadMsgs)
         };

         await _sendAppMsg(jsonEncode(msgMap), 0);
      }

      setState(() {
         SchedulerBinding.instance.addPostFrameCallback((_)
         {
            _chatScrollCtrl[tab].jumpTo(_chatScrollCtrl[tab].position.maxScrollExtent);
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

   Future<void> _onChatPressed(int tab, int j, int k) async
   {
      if (tab == cts.favIdx)
         await _onChatPressedImpl(_appState.favPosts, j, k, tab);
      else
         await _onChatPressedImpl(_appState.ownPosts, j, k, tab);
   }

   void _onUserInfoPressed(BuildContext ctx, String postId, int j)
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
      final String title = nick;

      final String avatar =
         _isOnFav() ? posts[i].avatar : posts[i].chats[j].avatar;

      final String url = cts.gravatarUrl + avatar + '.jpg';

      _showSimpleDialog(
         ctx,
         (){},
         title,
         makeNetImgBox(
            width: cts.onClickAvatarWidth,
            height: cts.onClickAvatarWidth,
            url: url,
            boxFit: BoxFit.contain,
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

   void _onChatLP(int i, int j, int k)
   {
      if (i == cts.favIdx) {
         _onChatLPImpl(_appState.favPosts, j, k, cts.favIdx);
      } else {
         _onChatLPImpl(_appState.ownPosts, j, k, cts.ownIdx);
      }

      setState(() { });
   }

   Future<void> _sendAppMsg(String payload, int isChat) async
   {
      final bool isEmpty = _appState.appMsgQueue.isEmpty;

      await _appState.insertOutChatMsg(payload, isChat);

      if (isEmpty)
         websocket.sink.add(_appState.appMsgQueue.first.payload);
   }

   void _sendOfflineChatMsgs()
   {
      if (_appState.appMsgQueue.isNotEmpty)
         websocket.sink.add(_appState.appMsgQueue.first.payload);
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

   Future<void> _onSendChatImpl({
      String postId,
      String to,
      ChatItem chatItem,
   }) async {
      try {
	 if (chatItem.message.isEmpty)
	    return;

	 final int id = await _appState.setChatMessage(
	    postId,
	    to,
	    chatItem,
	    _isOnFav(),
	 );

         var msgMap =
         { 'cmd': 'message'
         , 'type': 'chat'
         , 'is_redirected': chatItem.isRedirected
         , 'to': to
         , 'message': chatItem.message
         , 'refers_to': chatItem.refersTo
         , 'post_id': postId
         , 'nick': _appState.cfg.nick
         , 'id': id
         , 'avatar': emailToGravatarHash(_appState.cfg.email)
         };

         final String payload = jsonEncode(msgMap);
         await _sendAppMsg(payload, 1);

      } catch(e) {
         log(e);
      }
   }

   Future<void> _onPostVisualization(String postId) async
   {
      // Visualizations that occurr while the user is offline will be
      // lost. This can be fixes later.
      try {
	 var response = await http.put(cts.dbVisualizationUrl,
	    body: jsonEncode({'post_ids': <String>[postId]}),
	 );

	 if (response.statusCode != 200)
	    print('Error: Unable to put visualization.');

      } catch (e) {
	 print(e);
      }
   }

   Future<void> _onPostClick(String postId) async
   {
      try {
	 var response = await http.put(cts.dbClickUrl,
	    body: jsonEncode({'post_id': postId}),
	 );

	 if (response.statusCode != 200)
	    print('Error: Unable to put click.');

      } catch (e) {
	 print(e);
      }
   }

   Future<void> _onChat({
      final String to,
      final String peer,
      final String postId,
      final String message,
      final String nick,
      final String avatar,
      final int refersTo,
      final int peerMsgId,
      final int isRedirected,
   }) async {
      if (to != _appState.cfg.userId) {
         log("Server bug caught. Please report.");
         return;
      }

      final int favIdx = _appState.favPosts.indexWhere((e) {
         return e.id == postId;
      });

      List<Post> posts;
      if (favIdx != -1)
         posts = _appState.favPosts;
      else
         posts = _appState.ownPosts;

      await _onChatImpl(
         to: to,
         postId: postId,
         message: message,
         peer: peer,
         nick: nick,
         avatar: avatar,
         posts: posts,
         isRedirected: isRedirected,
         refersTo: refersTo,
         peerMsgId: peerMsgId,
	 isFav: favIdx != -1,
      );
   }

   Future<void> _onChatImpl({
      bool isFav,
      int isRedirected,
      int refersTo,
      int peerMsgId,
      String to,
      String postId,
      String message,
      String peer,
      String nick,
      String avatar,
      List<Post> posts,
   }) async {
      final int i = posts.indexWhere((e) { return e.id == postId;});
      if (i == -1) {
         log('Ignoring message to postId $postId.');
         return;
      }

      final int j = posts[i].getChatHistIdxOrCreate(peer, nick, avatar);
      final int now = DateTime.now().millisecondsSinceEpoch;

      final ChatItem ci = ChatItem(
         isRedirected: isRedirected,
         message: message,
         date: now,
         refersTo: refersTo,
         peerId: peerMsgId,
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
         final int l = posts[i].chats[j].msgs.length;
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
      , 'ack_ids': <int>[peerMsgId]
      };

      // Generating the payload before the async operation to avoid
      // problems.
      final String payload = jsonEncode(msgMap);

      await _appState.insertChatOnPost3(postId, chat, peer, ci, isFav);
      await _sendAppMsg(payload, 0);
   }

   void _onPresence({
      final String peer,
      final String postId,
   }) {
      if (peer.isEmpty || postId.isEmpty)
	 return;

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
      // to call setState so that we can stop showing the *is writing*
      // message after some time.
      Timer(Duration(milliseconds: cts.presenceInterval), () { setState((){}); });
      setState((){});
   }

   Future<void> _onRegisterAck({
      final String result,
      final String user,
      final String key,
      final String userId,
   }) async {
      if (result == 'fail') {
         log("register_ack: fail.");
         return;
      }

      await _appState.setCredentials(user, key, userId);

      // Retrieves some posts for the newly registered user.
      _subscribeToPosts();
   }

   void _onLoginAck({
      final String result,
   }) {
      // I still do not know how a failed login should be handled.
      // Perhaps send a new register command? It can only happen if
      // the server is blocking this user.
      if (result == 'fail') {
         log("login_ack: fail.");
         return;
      }

      _lastDisconnect = -1;

      // We are loggen in and can subscribe to receive posts sent while we were
      // offline.
      _subscribeToPosts();

      // Sends any chat messages that may have been written while
      // the app were offline.
      _sendOfflineChatMsgs();
   }

   void _onSubscribeAck({
      final String result,
   }) {
      if (result == 'fail') {
         log("subscribe_ack: $result");
         return;
      }
   }

   void _onPost(Map<String, dynamic> ack)
   {
      for (var item in ack['posts']) {
         try {
            Post post = Post.fromJson(item, g.param.rangeDivs.length);
            post.status = 1;

            if (post.from == _appState.cfg.userId)
               continue;

            _appState.posts.add(post);
         } catch (e) {
            log("Error: Invalid post detected.");
         }
      }

      _appState.posts.sort(compPostByDate);

      setState(() {
	 _nNewPosts = _appState.posts.length;
      });
   }

   Future<void> _onPublishAck({
      final String result,
      final String postId,
      final int date,
   }) async {
      int errorCode = 0;
      if (result == 'ok' && postId.isNotEmpty && date != -1) {
         await _appState.addOwnPost(postId, date);
	 await _onChatImpl(
	    to: _appState.cfg.userId,
	    postId: postId,
	    message: g.param.adminChatMsg,
	    peer: g.param.adminId,
	    nick: g.param.adminNick,
	    avatar: emailToGravatarHash(cts.occaseEmail),
	    posts: _appState.ownPosts,
	    isRedirected: 0,
	    refersTo: -1,
	    peerMsgId: 0,
	    isFav: false,
	 );

	 errorCode = 1;
      }

      setState(() {_newPostErrorCode = errorCode;});
   }

   Future<void> _onWSDataImpl() async
   {
      while (_wsMsgQueue.isNotEmpty) {
	 try {
	    var payload = _wsMsgQueue.removeFirst();
	    Map<String, dynamic> map = jsonDecode(payload);
	    final String cmd = map["cmd"] ?? '';
	    if (cmd == "presence") {
	       _onPresence(
		  peer: map['from'] ?? '',
		  postId: map['post_id'] ?? '',
	       );
	    } else if (cmd == "message") {
	       final String from = map['from'] ?? '';
	       final String type = map['type'] ?? '';
	       final String postId = map['post_id'] ?? '';

	       if (type == 'chat') {
		  await _onChat(
		     to: map['to'] ?? '',
		     message: map['message'] ?? '',
		     nick: map['nick'] ?? '',
		     peer: from,
		     postId: postId,
		     isRedirected: map['is_redirected'] ?? 0,
		     avatar: map['avatar'] ?? '',
		     refersTo: map['refers_to'] ?? -1,
		     peerMsgId: map['id'] ?? 0,
		  );
	       } else if (type == 'server_ack') {
		  assert(_appState.appMsgQueue.isNotEmpty);

		  final String result = map['result'] ?? 'fail';
		  final bool isChat = await _appState.deleteOutChatMsg();
		  final int ack_id = map['ack_id'] ?? -1;

		  if (result == 'ok' && isChat && ack_id != -1)
		     await _appState.setChatAckStatus(
			from: from,
			postId: postId,
			ackIds: <int>[ack_id],
			status: 1,
		     );

		  if (_appState.appMsgQueue.isNotEmpty)
		     websocket.sink.add(_appState.appMsgQueue.first.payload);

	       } else if (type == 'chat_ack_received') {
		  await _appState.setChatAckStatus(
		     from: from,
		     postId: postId,
		     ackIds: decodeList(0, 0, map['ack_ids']),
		     status: 2,
		  );
	       } else if (type == 'chat_ack_read') {
		  final List<int> ackIds = decodeList(0, 0, map['ack_ids']);
		  await _appState.setChatAckStatus(
                     from: from,
		     postId: postId,
		     ackIds: ackIds,
		     status: 3,
		  );
	       }

	       setState((){});

	    } else if (cmd == "login_ack") {
	       _onLoginAck(
		  result: map["result"] ?? 'fail',
	       );
	    } else if (cmd == "subscribe_ack") {
	       _onSubscribeAck(
		  result: map["result"] ?? 'fail',
	       );
	    } else if (cmd == "post") {
	       _onPost(map);
	    } else if (cmd == "publish_ack") {
	       await _onPublishAck(
		  result: map['result'] ?? 'fail',
		  postId: map['id'] ?? '',
		  date: map['date'] ?? -1,
	       );
	    } else if (cmd == "register_ack") {
	       await _onRegisterAck(
		  result: map["result"] ?? 'fail',
		  user: map["user"] ?? '',
		  key: map["key"] ?? '',
		  userId: map["user_id"] ?? '',
	       );
	    } else {
	       log('Unhandled message received from the server:\n$payload.');
	    }
	 } catch (e) {
	    print('Exception on _onWSDataImpl');
	 }
      }
   }

   Future<void> _onWSData(payload) async
   {
      print(payload);
      bool isEmpty = _wsMsgQueue.isEmpty;
      _wsMsgQueue.add(payload);
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

   // The variable i can assume the following values
   // 0: Leaves the screen.
   //
   Future<void> _onSearch(BuildContext ctx, int i) async
   {
      try {
	 if (!isWideScreen(ctx))
	    setState(() {_newSearchPressed = false;});

	 if (i == 0) {
	    setState(() { });
	    return;
	 }

	 setState(() {
	    _searchBeginDate = DateTime.now().millisecondsSinceEpoch;
	 });

	 await _searchPosts2();

	 setState(() { _searchBeginDate = 0; });
      } catch (e) {
	 log(e);
      }
   }

   void _subscribeToPosts()
   {
      websocket.sink.add(jsonEncode({ 'cmd': 'subscribe' }));
   }

   // Called when the main tab changes.
   void _tabCtrlChangeHandler()
   {
      // This function is meant to change the tab widgets when we
      // switch tab. This is needed to show the number of unread
      // messages.
      setState(() { log('Tab changed');});
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
      if (_lpChats[i].isEmpty)
         return;

      // FIXME: For _fav chats we can directly delete the post since
      // it will only have one chat element.

      _lpChats[i].forEach((e) async {removeLpChat(e, _appState);});

      if (_isOnFav()) {
	 await _appState.removeFavWithNoChats();
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
         log(e);
      }
   }

   bool _onWillLeaveInfoScreen()
   {
      setState(() {_goToInfoScreen = false;});
      return false;
   }

   Future<void> _onHiddenButtonLp(BuildContext ctx) async
   {
      ++_hiddenButtonCounter;

      int lastDate = DateTime.now().millisecondsSinceEpoch;
      if ((lastDate - _hiddenButtonDate) > 1000)
	 _hiddenButtonCounter = 0;

      _hiddenButtonDate = lastDate;

      if (_hiddenButtonCounter == 6) {
	 final String pwd = await showDialog<String>(
	    context: ctx,
	    builder: (BuildContext ctx2) { return PostDescription(description: ''); },
	 );

	 if (pwd == null)
	    return; 

	 setState(() {
	    _deletePostPwd = pwd;
	    _goToInfoScreen = false;
	 });
      }
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
         log('Unable to send email.');
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
         log(e);
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

   Future<String> _searchPosts(String url) async
   {
      try {
	 // TODO: Set a timeout on the http request.

	 var response = await http.post(url,
	    body: jsonEncode(_posts[cts.searchIdx].toJson()),
	 );

	 if (response.statusCode == 200)
	    return response.body;

	 log('Error: Unable to find search matches.');
	 return '';
      } catch (e) {
	 print(e);
      }

      return '';
   }

   Future<void> _searchPosts2() async
   {
      try {
	 _nNewPosts = 0;
	 await _appState.clearPosts();

	 _posts[cts.ownIdx] = Post(rangesMinMax: g.param.rangesMinMax);
	 final String body = await _searchPosts(cts.dbSearchPostsUrl);
	 if (body.isEmpty)
	    return; // Perhaps show a dialog with an error message?

	 _onPost(jsonDecode(body));
      } catch (e) {
      }
   }

   Future<void> _onSetSearchLocationCode(List<int> code) async
   {
      if (code.isEmpty)
	 return;

      _posts[cts.searchIdx].location = code;
      _numberOfMatchingPosts = await _searchPosts(cts.dbCountPostsUrl);

      setState(() { });
   }

   Future<void> _onSetSearchProductCode(List<int> code) async
   {
      if (code.isEmpty)
	 return;

      _posts[cts.searchIdx].product = code;
      _numberOfMatchingPosts = await _searchPosts(cts.dbCountPostsUrl);

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

   Widget _makeChatScreen(BuildContext ctx, int tab)
   {
      return makeChatScreen(
	 ctx: ctx,
	 tab: tab,
	 chatMetadata: _chats[tab],
	 editCtrl: _txtCtrl,
	 scrollCtrl: _chatScrollCtrl[tab],
	 nLongPressed: _lpChatMsgs[tab].length,
	 chatFocusNode: _chatFocusNodes[tab],
	 postSummary: makeTreeItemStr(_locRootNode, _posts[tab].product),
	 dragedIdx: _dragedIdxs[tab],
	 showChatJumpDownButton: _showChatJumpDownButtons[tab],
	 avatar: _isOnFavChat() ? _posts[tab].avatar : _chats[tab].avatar,
	 ownNick: _appState.cfg.nick,
	 onWillPopScope: () { _onPopChat(tab);},
	 onSendChatMsg: () {_onSendChat(tab);},
	 onChatMsgLongPressed: (int a, bool b) {_toggleLPChatMsgs(a, b, tab);},
	 onFwdChatMsg: () {_onFwdChatMsg(tab);},
	 onDragChatMsg: (var a, var b, var d) {_onDragChatMsg(a, b, d, tab);},
	 onChatMsgReply: (var a) {_onChatMsgReply(a, tab);},
	 onAttachment: _onChatAttachment,
	 onCancelFwdLPChatMsg: () {_onCancelFwdLpChat(tab);},
	 onChatJumpDown: () {_onChatJumpDown(tab);},
	 onWritingChat: (var s) {_onWritingChat(s, tab);},
      );
   }

   Widget _makeNewPostScreenWdgs(BuildContext ctx)
   {
      return makeNewPostScreenWdgs(
	 ctx: ctx,
	 sendingPost: _sendingPost,
	 locRootNode: _locRootNode,
	 prodRootNode: _prodRootNode,
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

   Widget _makeSearchScreenWdg(BuildContext ctx)
   {
      return makeSearchScreenWdg(
	 ctx: ctx,
	 state: _posts[cts.searchIdx].exDetails[0],
	 numberOfMatchingPosts: _numberOfMatchingPosts,
	 locRootNode: _locRootNode,
	 prodRootNode: _prodRootNode,
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

   Widget _makeSearchResultTab()
   {
      Widget w = makeNewPostLv(
	 nNewPosts: _nNewPosts,
	 locRootNode: _locRootNode,
	 prodRootNode: _prodRootNode,
	 exDetailsRootNode: _exDetailsRoot,
	 inDetailsRootNode: _inDetailsRoot,
	 posts: _appState.posts,
	 onExpandImg: (int i, int j) {_onExpandImg(i, j, cts.searchIdx);},
	 onAddPostToFavorite: (var a, int j) {_alertUserOnPressed(a, j, 1);},
	 onDelPost: (var a, int j) {_alertUserOnPressed(a, j, 0);},
	 onSharePost: (var a, int j) {_alertUserOnPressed(a, j, 3);},
	 onReportPost: (var a, int j) {_alertUserOnPressed(a, j, 2);},
         onPostVisualization: _onPostVisualization,
         onPostClick: _onPostClick,
      );

      if (_searchBeginDate == 0)
	 return w;

      List<Widget> ret = <Widget>[w];

      ModalBarrier mb = ModalBarrier(
	 color: Colors.grey.withOpacity(0.4),
	 dismissible: false,
      );

      ret.add(mb);
      ret.add(Center(child: CircularProgressIndicator()));

      return Stack(children: ret);
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
	 tab: i,
	 locRootNode: _locRootNode,
	 prodRootNode: _prodRootNode,
	 exDetailsRootNode: _exDetailsRoot,
	 inDetailsRootNode: _inDetailsRoot,
	 posts: posts,
	 onPressed: (int j, int k) {_onChatPressed(i, j, k);},
	 onLongPressed: (int j, int k) {_onChatLP(i, j, k);},
	 onDelPost1: (int j) { _removePostDialog(ctx, i, j);},
	 onPinPost1: (int j) {_onPinPost(i, j);},
	 onUserInfoPressed: _onUserInfoPressed,
	 onExpandImg1: (int i, int j) {_onExpandImg(i, j, i);},
	 onSharePost: (int i) {_onClickOnPost(i, 1);},
	 onPost: _onNewPost,
      );
   }

   List<Widget> _makeTabActions(BuildContext ctx, int i)
   {
      return makeTabActions(
         tab: i,
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
	 defaultWdg: defaultWdg,
      );
   }

   List<int> _newMsgsCounters()
   {
      List<int> ret = List<int>(g.param.tabNames.length);
      ret[cts.ownIdx] = _getNUnreadOwnChats();
      //ret[cts.searchIdx] = _nNewPosts; // Let this out for the moment.
      ret[cts.searchIdx] = 0;
      ret[cts.favIdx] = _getNUnreadFavChats();
      return ret;
   }

   List<Widget> _makeAppBodies(BuildContext ctx)
   {
      final bool isWide = isWideScreen(ctx);

      List<Widget> ret = List<Widget>(g.param.tabNames.length);

      if (_newPostPressed) {
	 ret[cts.ownIdx] = _makeNewPostScreenWdgs(ctx);
      } else {
	 ret[cts.ownIdx] = _makeChatTab(ctx, cts.ownIdx);
      }

      if (_newSearchPressed && !isWide) {
	 ret[cts.searchIdx] = _makeSearchScreenWdg(ctx);
      } else {
	 ret[cts.searchIdx] = _makeSearchResultTab();
      }

      if ((_newSearchPressed || _appState.favPosts.isEmpty) && isWide) {
	 ret[cts.favIdx] = _makeSearchScreenWdg(ctx);
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
	 (_locRootNode   == null) ||
	 (_prodRootNode  == null) ||
         (_exDetailsRoot == null) ||
         (_inDetailsRoot == null) ||
         (g.param == null);

      if (mustWait)
         return makeWaitMenuScreen();

      Locale locale = Localizations.localeOf(ctx);
      g.param.setLang(locale.languageCode);

      if (_goToRegScreen) {
         return makeRegisterScreen(
            emailCtrl: _txtCtrl2,
            nickCtrl: _txtCtrl,
            onContinue: (){_onRegisterContinue(ctx);},
            title: g.param.changeNickAppBarTitle,
            previousEmail: _appState.cfg.email,
            previousNick: _appState.cfg.nick,
	    maxWidth: makeMaxWidth(ctx, cts.ownIdx),
	    onWillPopScope: () {setState(() {_goToRegScreen = false;});},
         );
      }

      if (_goToNtfScreen) {
         return makeNtfScreen(
	    ctx: ctx,
            onChange: _onChangeNtf,
            title: g.param.changeNtfAppBarTitle,
            ntfConfig: _appState.cfg.notifications,
            titleDescription: g.param.ntfTitleDesc,
	    onWillPopScope: () {setState(() {_goToNtfScreen = false;});},
         );
      }

      if (_goToInfoScreen)
         return makeInfoScreen(
            ctx,
	    _onWillLeaveInfoScreen,
	    _onSendEmailToSupport,
	    () {_onHiddenButtonLp(ctx);},
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

      final int screenIdx = _tabIndex();
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
	    () { _onExpandImg(-1, -1, _tabIndex()); return false;},
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
               title: Text(g.param.shareSubject,
		  style: TextStyle(color: stl.colorScheme.onPrimary),
	       ),
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
	 scrollCtrl: _scrollCtrl[_tabIndex()],
	 appBarTitle: _makeAppBarTitleWdg(
            isWide,
	    screenIdx,
	    Text(g.param.shareSubject,
	       style: TextStyle(color: stl.colorScheme.onPrimary),
	    ),
	 ),
	 appBarLeading: _makeAppBarLeading(isWide, screenIdx),
	 floatBut: fltButtons[_tabCtrl.index],
	 body: TabBarView(controller: _tabCtrl, children: bodies),
	 tabBar: makeTabBar(ctx, newMsgCounters, _tabCtrl, opacities, _hasLPChatMsgs(screenIdx)),
	 actions: actions,
      );
   }
}

