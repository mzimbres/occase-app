import 'dart:async' show Future, Timer;
import 'dart:convert';
import 'dart:io';
import 'dart:collection';

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
//import 'package:image/image.dart' as imglib;
//import 'package:cached_network_image/cached_network_image.dart';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
//import 'package:photo_view/photo_view_gallery.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:share/share.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart';

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
typedef OnPressedF17 = void Function(DateTime);

//--------------------------------------------
// HTTP

Future<String> searchPosts(String url, Post post) async
{
   try {
      var response = await http.post(
	 Uri.parse(url),
	 body: jsonEncode({'post': post}),
      );

      if (response.statusCode == 200)
	 return response.body;
      return '';
   } catch (e) {
      print(e);
   }

   return '';
}

//--------------------------------------------


String makeChatMsg({
   String to,
   String body,
   String postId,
   String nick = '',
   String type = 'chat',
   String avatar = '',
   int id,
   int isRedirected = 0,
   int refersTo = -1,
})
{
   var msgMap =
   { 'cmd': 'message'
   , 'type': type
   , 'is_redirected': isRedirected
   , 'to': to
   , 'body': body
   , 'refers_to': refersTo
   , 'post_id': postId
   , 'nick': nick
   , 'id': id
   , 'avatar': avatar
   };

   return jsonEncode(msgMap);
}

double makeMaxWidgetWidth(double screenWidth)
{
   final double ret = screenWidth / 3 - 20;

   if (ret > cts.maxWidgetWidth)
      return cts.maxWidgetWidth;

   if (ret < cts.minWidgetWidth)
      return cts.minWidgetWidth;

   return ret;
}

bool isWideScreenImpl(double w)
{
   return (w - 14) > (3 * cts.minWidgetWidth);
}

double makeTabWidthImpl(double w)
{
   if (isWideScreenImpl(w))
      return 0.333333 * w;

   return w;
}

double makeTabWidth(BuildContext ctx)
{
   final double w = MediaQuery.of(ctx).size.width;
   return makeTabWidthImpl(w);
}

double makeWidgetWidth(BuildContext ctx)
{
   final double width = MediaQuery.of(ctx).size.width;
   final double max = makeMaxWidgetWidth(width);

   return width > max ?  max : width;
}

double makeImgHeight(BuildContext ctx)
{
   return makeWidgetWidth(ctx) / cts.goldenRatio;
}

bool isWideScreen(BuildContext ctx)
{
   final double w = MediaQuery.of(ctx).size.width;
   return isWideScreenImpl(w);
}

// ------------------
// Use flexible factor instead.
double makePostAvatarWidth(BuildContext ctx)
{
   final double w = makeWidgetWidth(ctx);
   return w / (1 + cts.goldenRatio);
}

double makePostInfoWidth(BuildContext ctx)
{
   final double w = makeWidgetWidth(ctx);
   final double A = makePostAvatarWidth(ctx);
   return w - A - 12 - stl.basePadding;
}
// ------------------

double makeMaxHeight(BuildContext ctx)
{
   return MediaQuery.of(ctx).size.height;
}

Future<void> fcmOnBackgroundMessage(Map<String, dynamic> message) async
{
  debugPrint("onBackgroundMessage: $message");
}

Widget imposeWidth({
   Widget child,
   double width,
}) {
   return Center(
      child: ConstrainedBox(
	 constraints: BoxConstraints(
	    maxWidth: width,
	 ),
	 child: child,
      ),
   );
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

Future<void> removeLpChat(Coord c, AppState appState) async
{
   // removeWhere could also be used, but that traverses all elements
   // always and we know there is only one element to remove.

   final bool ret = c.post.chats.remove(c.chat);
   assert(ret);

   final int n = await appState.deleteChatStElem(c.post.id, c.chat.peer);
   assert(n == 1);
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async
{
   print('Handling a background message ${message.messageId}');
}

Future<Null> main() async
{
   WidgetsFlutterBinding.ensureInitialized();

   await Firebase.initializeApp();

   FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

   // Update the iOS foreground notification presentation options to
   // allow heads up notifications.
   await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
   );

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

Widget makeRegisterScreen({
   TextEditingController nickCtrl,
   Function onContinue,
   String title,
   String previousNick,
   double maxWidth,
   OnPressedF07 onWillPopScope,
}) {
   if (previousNick.isNotEmpty)
      nickCtrl.text = previousNick;

   TextField nickTf = makeNickTxtField(
      nickCtrl,
      Icon(Icons.person),
      cts.nickMaxLength,
      g.param.nickHint,
   );

   Widget button = createRaisedButton(
      onPressed: onContinue,
      text: g.param.next,
      color: stl.cs.secondary,
      textColor: stl.cs.onSecondary,
   );

   Column col = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>
      [ Padding(
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

Scaffold makeWaitLoadTreeScreen()
{
   return Scaffold(
      appBar: AppBar(
         title: Text(g.param.shareSubject,
            style: TextStyle(color: stl.cs.onPrimary),
         ),
      ),
      body: Center(child: CircularProgressIndicator()),
      backgroundColor: stl.cs.background,
   );
}

//Widget makeImgExpandScreen(Function onWillPopScope, Post post)
//{
//   //final double width = makeWidgetWidth(ctx, tab);
//   //final double height = makeMaxHeight(ctx);
//
//   final int l = post.images.length;
//
//   Widget foo = PhotoViewGallery.builder(
//      scrollPhysics: const BouncingScrollPhysics(),
//      itemCount: post.images.length,
//      //loadingChild: Container(
//      //         width: 30.0,
//      //         height: 30.0,
//      //),
//      reverse: true,
//      //backgroundDecoration: widget.backgroundDecoration,
//      //pageController: widget.pageController,
//      onPageChanged: (int i){ debugPrint('===> New index: $i');},
//      builder: (BuildContext context, int i) {
//         // No idea why this is showing in reverse order, I will have
//         // to manually reverse the indexes.
//         final int idx = l - i - 1;
//         return PhotoViewGalleryPageOptions(
//            //imageProvider: AssetImage(widget.galleryItems[idx].image),
//	      backgroundImage = NetworkImage(url);
//            //initialScale: PhotoViewComputedScale.contained * 0.8,
//            //minScale: PhotoViewComputedScale.contained * 0.8,
//            //maxScale: PhotoViewComputedScale.covered * 1.1,
//            //heroAttributes: HeroAttributes(tag: galleryItems[idx].id),
//         );
//      },
//   );
//
//   return WillPopScope(
//      onWillPop: () async { return onWillPopScope();},
//      child: Scaffold(
//         //appBar: AppBar(title: Text(g.param.appName)),
//         body: Center(child: foo),
//	 backgroundColor: stl.cs.background,
//      ),
//   );
//}

TextField makeNickTxtField(
   TextEditingController txtCtrl,
   Icon icon,
   int fieldMaxLength,
   String hint,
) {
   Color focusedColor = stl.cs.primary;

   Color enabledColor = focusedColor;

   return TextField(
      style: stl.tsMainBlack,
      controller: txtCtrl,
      maxLines: 1,
      maxLength: fieldMaxLength,
      decoration: InputDecoration(
         hintText: hint,
         focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(
               color: focusedColor,
               width: 2.5
            ),
         ),
         enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(
               color: enabledColor,
               width: 2.5,
            ),
         ),
         prefixIcon: icon,
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
      //dense: false,
      title: Text(titleDescription[0],
	 //style: stl.ltTitleSty,
      ),
      subtitle: Text(titleDescription[1]),
      value: ntfConfig.chat,
      onChanged: (bool v) { onChange(0, v); },
      activeColor: stl.cs.primary,
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
           onPressed: () {onChange(-1, false);},
           text: g.param.ok,
	   color: stl.cs.secondary,
	   textColor: stl.cs.onSecondary,
        ),
      ]
   );

   Widget tmp = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: makeTabWidth(ctx)),
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
	 backgroundColor: stl.cs.background,
	 appBar: AppBar(
	    title: Text(title,
	       style: TextStyle(color: stl.cs.onPrimary),
	    ),
	    leading: IconButton(
	       padding: EdgeInsets.all(0.0),
	       icon: Icon(Icons.arrow_back, color: stl.cs.onPrimary),
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
   Column col = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>
      [ makeHiddenButton(onHiddenButtonLP, stl.cs.background),
        RaisedButton(
	    onPressed: onSendEmail,
	    child: Text(g.param.supportEmail,
	       style: TextStyle(
		  fontSize: stl.bigFontSize,
		  color: stl.cs.primary,
		  fontWeight: FontWeight.normal,
	       ),
	    ),
	 ),
	 Padding(
	    padding: const EdgeInsets.all(stl.basePadding),
	    child: makeHiddenButton((){}, stl.cs.background),
	 ),
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
   final String url,
}) {
   if (url.isEmpty) {
      Widget w = Text(g.param.unreachableImgError,
         overflow: TextOverflow.ellipsis,
         style: TextStyle(
            color: stl.cs.background,
            fontSize: stl.mainFontSize,
         ),
      );

      return makeImgPlaceholder(width, height, w);
   }

   String urlAndQuery = '$url';
   final int w = width.round();
   final int h = width.round();
   urlAndQuery += "?width=$w&height=$h";
   return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
	 image: DecorationImage(
	    fit: BoxFit.cover,
	    alignment: FractionalOffset.center,
	    image: NetworkImage(urlAndQuery),
	 ),
      ),
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
            //   color: stl.cs.background,
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
      child: Card(
	 child: wdg,
	 elevation: 0,
	 color: Colors.white.withOpacity(0.7),
	 margin: EdgeInsets.all(stl.basePadding),
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
   List<List<int>> images = null,
   OnPressedF01 onExpandImg,
   OnPressedF01 onDelImg,
}) {
   final int l1 = post.images.length;

   if (l1 == 0 && images == null)
      return makeImgPlaceholder(
	 width,
	 height,
	 SizedBox.shrink(),
      );

   final int l = l1 == 0 ? images.length : l1;

   ListView lv = ListView.builder(
      scrollDirection: Axis.horizontal,
      shrinkWrap: true,
      itemCount: l,
      itemBuilder: (BuildContext ctx, int i)
      {
	 Widget imgCounter = makeTextWdg(text: '${i + 1}/$l');

	 List<Widget> wdgs = List<Widget>();

	 if (post.images.isNotEmpty) {
	    Widget tmp = makeNetImgBox(
	       width: width,
	       height: height,
	       url: post.images[l - i - 1],
	    );
	    //wdgs.add(InteractiveViewer(minScale: 1, child: tmp));
	    wdgs.add(tmp);
	    wdgs.add(Positioned(child: makeWdgOverImg(imgCounter), top: 4.0));
	 } else if (images != null && images.isNotEmpty) {
	    Widget tmp = Image.memory(
	       images[i],
	       width: width,
	       height: height,
	       fit: boxFit,
	       filterQuality: FilterQuality.high,
	    );

	    //wdgs.add(InteractiveViewer(minScale: 1, child: tmp));
	    wdgs.add(tmp);

	    IconButton delIcon = IconButton(
	       onPressed: (){onDelImg(i);},
	       icon: Icon(Icons.cancel, color: stl.cs.primary),
	    );

	    wdgs.add(Positioned(
		  bottom: 0,
		  right: 0,
                  child: Card(
		     elevation: 0,
		     color: Colors.white.withOpacity(stl.delImgWidgOpacity),
		     margin: EdgeInsets.zero,
		     child: delIcon,
		  ),
	       ),
	    );

	    wdgs.add(Positioned(
		  child: makeWdgOverImg(imgCounter),
		  top: stl.basePadding,
		  left: stl.basePadding,
	       ),
	    );
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
               ? stl.cs.secondaryVariant
               : stl.cs.secondary;

   return RichText(
      text: TextSpan(
         text: '$first$sep ',
         //style: stl.tsMainBlack,
         children: <TextSpan>
         [ TextSpan(
              text: second,
              //style: stl.ltTitleSty.copyWith(color: color),
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
         style: stl.ltTitleSty,
         children: <TextSpan>
         [ TextSpan(
              text: value,
              style: stl.ltTitleSty.copyWith(color: stl.cs.secondaryVariant),
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
         //dense: false,
         title: Text(items[i],
	    //style: stl.ltTitleSty,
	 ),
         value: v,
         onChanged: (bool v) { onChanged(v, i); },
         activeColor: stl.cs.primary,
	 isThreeLine: false,
      );

      ret.add(tmp);
   }

   return ret;
}

Widget makeNewPostSetionTitle({
   String title,
   double topPadding = stl.newPostSectionTitleTopIndent,
   double bottonPadding = stl.basePadding,
}) {
   return Padding(
      padding: EdgeInsets.only(
	 left: stl.basePadding,
	 top: topPadding,
	 bottom: bottonPadding,
      ),
      child: Text(title,
	 style: TextStyle(
	    fontSize: stl.bigFontSize,
	    color: stl.cs.primary,
	    fontWeight: FontWeight.w300,
	 ),
      ),
   );

}

List<Widget> makeNewPostFinalScreen({
   BuildContext ctx,
   final Post post,
   final Node locRootNode,
   final Node prodRootNode,
   final Node exDetailsRootNode,
   final Node inDetailsRootNode,
   final List<List<int>> images,
   final OnPressedF00 onAddImg,
   final OnPressedF01 onDelImg,
   final OnPressedF00 onPublishPost,
   final OnPressedF04 onRemovePost,
   final OnPressedF00 onFreePaymentPressed,
   final OnPressedF00 onStandardPaymentPressed,
   final OnPressedF00 onPremiumPaymentPressed,
}) {
   // NOTE: This ListView is used to provide a new context, so that
   // it is possible to show the snackbar using the scaffold.of on
   // the new context.

   List<Widget> ret = List<Widget>();

   ret.add(makeNewPostSetionTitle(title: g.param.newPostSectionNames[4]));

   Widget postBox = PostWidget(
      tab: cts.ownIdx,
      post: post,
      exDetailsRootNode: exDetailsRootNode,
      inDetailsRootNode: inDetailsRootNode,
      locRootNode: locRootNode,
      prodRootNode: prodRootNode,
      images: images,
      onAddImg: onAddImg,
      onDelImg: onDelImg,
      onExpandImg: (int j){ debugPrint('Noop00'); },
      onAddPostToFavorite: () { debugPrint('Noop01'); },
      onDelPost: () { debugPrint('Noop02');},
      onSharePost: () { debugPrint('Noop03');},
      onReportPost: () { debugPrint('Noop05');},
      onPinPost: () { debugPrint('Noop06');},
      onVisualization: () { debugPrint('Noop07');},
   );

   ret.add(postBox);

   // 24.04.2021: I will remove payment until there is a clear plan.
   // See PAYMENT below also.
   //ret.add(makeNewPostSetionTitle(title: g.param.newPostSectionNames[5]));

   Widget cancelButton = createRaisedButton(
      onPressed: () {onRemovePost(ctx);},
      text: g.param.cancel,
      color: stl.cs.surface,
      textColor: stl.cs.onSurface,
   );

   Widget sendButton = createRaisedButton(
      onPressed: onPublishPost,
      text: g.param.newPostAppBarTitle,
      color: stl.cs.secondary,
      textColor: stl.cs.onSecondary,
   );

   // PAYMENT.
   //Widget payment = Column(
   //   mainAxisSize: MainAxisSize.min,
   //   children: makePaymentPlanOptions(
   //      post: post,
   //      onFreePaymentPressed: onFreePaymentPressed,
   //      onStandardPaymentPressed: onStandardPaymentPressed,
   //      onPremiumPaymentPressed: onPremiumPaymentPressed,
   //   ),
   //);

   //ret.add(payment);

   Widget buttonsRow = Padding(
      padding: EdgeInsets.only(
	 top: stl.newPostSectionTitleTopIndent,
	 bottom: stl.newPostSectionTitleTopIndent,
      ),
      child: Row(children: <Widget>
      [ Expanded(child: cancelButton)
      , Expanded(child: sendButton)
      ]),
   );

   ret.add(buttonsRow);

   return ret;
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
   if (tab == cts.ownIdx) {
      if (newPostPressed) {
      } else if (hasLPChats && !hasLPChatMsgs) {
	 return makeOnLongPressedActions(deleteChatDialog, pinChats);
      }
   }

   if (tab == cts.favIdx) {
      if (hasLPChats && !hasLPChatMsgs) {
	 IconButton delChatBut = IconButton(
	    icon: Icon(
	       Icons.delete_forever,
	       color: stl.cs.onPrimary,
	    ),
	    tooltip: g.param.deleteChat,
	    onPressed: deleteChatDialog,
	 );

	 return <Widget>[delChatBut];
      }
   }

   return <Widget>[];
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
      return makeSearchAppBar(title: g.param.searchAppBarTitle);

   if (fav && (newSearchPressed || hasNoFavPosts) && isWide)
      return makeSearchAppBar(title: g.param.searchAppBarTitle);

   return defaultWdg;
}

Widget makeNewPostCards(Widget child)
{
   return Card(child: child);
}

Widget makeNewPostLT({
   final String title,
   final String subTitle,
   final IconData icon,
   final bool missingSubtitle = false,
   OnPressedF00 onTap,
}) {
   Widget leading;
   if (icon != null)
      leading = CircleAvatar(
	  child: Icon(icon,
	     color: stl.cs.primary,
	  ),
          backgroundColor: Colors.white,
      );
      
   TextStyle subtitleTs = stl.ltSubtitleSty;
   if (missingSubtitle)
      subtitleTs = stl.ltSubtitleSty.copyWith(color: Colors.grey);

   Widget lt = ListTile(
       //contentPadding: EdgeInsets.only(left: stl.basePadding),
       leading: leading,
       title: Text(title,
	  maxLines: 1,
	  overflow: TextOverflow.ellipsis,
	  style: stl.ltTitleSty,
       ),
       //dense: true,
       subtitle: Text(subTitle,
	  maxLines: 1,
	  overflow: TextOverflow.ellipsis,
	  style: subtitleTs,
       ),
       onTap: onTap,
       enabled: true,
       isThreeLine: false,
   );

   return makeNewPostCards(lt);
}

ListView makeNewPostListView(List<Widget> list)
{
   return ListView.builder(
      itemCount: list.length,
      itemBuilder: (BuildContext ctx, int i) { return list[i]; },
   );
}

Widget makeChooseTreeNodeDialog({
   BuildContext ctx,
   final int tab,
   final int fromDepth,
   final String title,
   final List<int> defaultCode,
   final Node root,
   final IconData iconData,
   final OnPressedF14 onSetTreeCode,
}) {
   String subtitle = '';
   if (defaultCode.isNotEmpty) {
      subtitle = loadNames(
	 rootNode: root,
	 code: defaultCode,
	 languageIndex: g.param.langIdx,
	 fromDepth: fromDepth,
      ).join(', ');
   } else {
      subtitle = root.getChildrenNames(g.param.langIdx, 100);
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

Widget makeNewPostProdDateWdg({
   BuildContext ctx,
   final String title,
   final String date,
   final DateTime initialDate,
   final OnPressedF17 onSetProdDate,
}) {
   return makeNewPostLT(
      title: title,
      subTitle: date,
      icon: null,
      onTap: () async
      {
	 final DateTime picked = await showDatePicker(
	    context: ctx,
	    initialDate: initialDate,
	    firstDate: DateTime(1900),
	    lastDate: DateTime(2030)
	 );

	 if (picked != null && picked != initialDate)
	    onSetProdDate(picked);
      },
   );
}

Widget makeNewPostStrInput({
   BuildContext ctx,
   final String title,
   final String subtitle,
   final String diagTitle,
   final String diagContent,
   final String diagHint,
   final int diagMaxLength,
   final OnPressedF09 onOk,
}) {
   return makeNewPostLT(
      title: title,
      subTitle: subtitle.isEmpty ? diagHint : subtitle,
      missingSubtitle: subtitle.isEmpty,
      icon: null,
      onTap: () async
      {
	 final String result = await showDialog<String>(
	    context: ctx,
	    builder: (BuildContext ctx2)
	    {
	       return TextInput(
		  title: diagTitle,
		  description: diagContent,
		  descriptionHint: diagHint,
		  maxLength: diagMaxLength,
	       );
	    },
	 );

	 if (result != null)
	    onOk(result);
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
   final OnPressedF17 onProdDateChanged,
   final OnPressedF09 onPriceChanged,
   final OnPressedF09 onKmChanged,
}) {
   List<Widget> list = List<Widget>();

   {  // Location
      Widget location = makeChooseTreeNodeDialog(
	 ctx: ctx,
	 tab: tab,
	 fromDepth: 0,
	 title: g.param.newPostTabNames[0],
	 defaultCode: post.location,
	 root: locRootNode,
	 //iconData: Icons.edit_location,
	 onSetTreeCode: (var code) { onSetTreeCode(code, 0);},
      );

      list.add(location);
   }

   {  // Product
      Widget product = makeChooseTreeNodeDialog(
	 ctx: ctx,
	 tab: tab,
	 fromDepth: 0,
	 title: g.param.newPostTabNames[1],
	 defaultCode: post.product,
	 root: prodRootNode,
	 //iconData: Icons.directions_car,
	 onSetTreeCode: (var code) { onSetTreeCode(code, 1);},
      );

      list.add(product);
   }

   if (post.product.isEmpty)
      return list;

   final int productIdx = post.getProductDetailIdx();
   if (productIdx == -1)
      return list;

   { // Price
      Widget priceWdg = makeNewPostStrInput(
	 ctx: ctx,
	 title: g.param.postValueTitles[0],
	 subtitle: makeRangeStr(post, 0),
	 diagTitle: g.param.postValueTitles[0],
	 diagContent: '',
	 diagHint: '3000',
	 diagMaxLength: 10,
	 onOk: onPriceChanged,
      );

      list.add(priceWdg);
   }

   {  // Date
      Widget prodDate = makeNewPostProdDateWdg(
	 ctx: ctx,
	 title: g.param.postValueTitles[1],
	 date: makeDateString3(post.date),
	 initialDate: DateTime.now(),
	 onSetProdDate: onProdDateChanged,
      );

      list.add(prodDate);
   }

   {  // Km
      Widget kmWdg = makeNewPostStrInput(
	 ctx: ctx,
	 title: g.param.postValueTitles[2],
	 subtitle: makeRangeStr(post, 2),
	 diagTitle: g.param.postValueTitles[2],
	 diagContent: '',
	 diagHint: '100000',
	 diagMaxLength: 10,
	 onOk: onKmChanged,
      );

      list.add(kmWdg);
   }

   {  // exDetails
      list.add(makeNewPostSetionTitle(title: g.param.newPostSectionNames[1]));
      final int nDetails = getNumberOfProductDetails(exDetailsRootNode, productIdx);
      for (int i = 0; i < nDetails; ++i) {
	 final int length = productDetailLength(exDetailsRootNode, productIdx, i);
	 final int k = post.exDetails[i] < length ? post.exDetails[i] : 0;

	 final List<String> names = loadNames(
	    rootNode: exDetailsRootNode,
	    code: <int>[productIdx, i, k],
	    languageIndex: g.param.langIdx,
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

	 list.add(exDetailWdg);
      }
   }

   {  // inDetails
      list.add(makeNewPostSetionTitle(title: g.param.newPostSectionNames[2]));
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

	 list.add(inDetailWdg);
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
   final List<List<int>> images,
   final OnPressedF12 onSetTreeCode,
   final OnPressedF03 onSetExDetail,
   final OnPressedF03 onSetInDetail,
   final OnPressedF00 onAddImg,
   final OnPressedF01 onDelImg,
   final OnPressedF04 onPublishPost,
   final OnPressedF04 onRemovePost,
   final OnPressedF08 onRangeValueChanged,
   final OnPressedF06 onNewPostValueChanged,
   final OnPressedF17 onProdDateChanged,
   final OnPressedF09 onPriceChanged,
   final OnPressedF09 onKmChanged,
   final OnPressedF09 onSetPostDescription,
   final OnPressedF09 onSetEmail,
   final OnPressedF09 onSetNick,
   final OnPressedF00 onFreePaymentPressed,
   final OnPressedF00 onStandardPaymentPressed,
   final OnPressedF00 onPremiumPaymentPressed,
}) {
   List<Widget> list = <Widget>[];
   list.add(makeNewPostSetionTitle(title: g.param.newPostSectionNames[0]));

   List<Widget> mainWidgets = makeNewPostWdgs(
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
      onProdDateChanged: onProdDateChanged,
      onPriceChanged: onPriceChanged,
      onKmChanged: onKmChanged,
   );

   list.addAll(mainWidgets);

   if (list.length < 7) {
      List<Widget> finalScreen = makeNewPostFinalScreen(
	 ctx: ctx,
	 post: post,
	 locRootNode: locRootNode,
	 prodRootNode: prodRootNode,
	 exDetailsRootNode: exDetailsRootNode,
	 inDetailsRootNode: inDetailsRootNode,
	 images: images,
	 onAddImg: onAddImg,
	 onDelImg: onDelImg,
	 onPublishPost: null,
	 onRemovePost: onRemovePost,
	 onFreePaymentPressed: onFreePaymentPressed,
	 onStandardPaymentPressed: onStandardPaymentPressed,
	 onPremiumPaymentPressed: onPremiumPaymentPressed,
      );

      list.addAll(finalScreen);

      return makeNewPostListView(list);
   }

   list.add(makeNewPostSetionTitle(title: g.param.newPostSectionNames[3]));

   if (list.length > 2) {
      {  // Description
	 Widget descWidget = makeNewPostStrInput(
	    ctx: ctx,
	    title: g.param.postDescTitle,
	    subtitle: post.description,
	    diagTitle: g.param.postDescTitle,
	    diagContent: post.description,
	    diagHint: g.param.newPostTextFieldHist,
	    diagMaxLength: cts.descriptionMaxLength,
	    onOk: onSetPostDescription,
	 );

	 list.add(descWidget);
      }

      {  // email
	 Widget emailWdg = makeNewPostStrInput(
	    ctx: ctx,
	    title: 'Email',
	    subtitle: post.email,
	    diagTitle: 'Email',
	    diagContent: post.email,
	    diagHint: 'user@example.de',
	    diagMaxLength: cts.descriptionMaxLength,
	    onOk: onSetEmail,
	 );

	 list.add(emailWdg);
      }

      {  // Nick
	 Widget nickWdg = makeNewPostStrInput(
	    ctx: ctx,
	    title: g.param.changeNickHint,
	    subtitle: post.nick,
	    diagTitle: g.param.changeNickHint,
	    diagContent: post.nick,
	    diagHint: g.param.advertiser,
	    diagMaxLength: 20,
	    onOk: onSetNick,
	 );

	 list.add(nickWdg);
      }

      {  // final
         List<Widget> finalScreen = makeNewPostFinalScreen(
	    ctx: ctx,
	    post: post,
	    locRootNode: locRootNode,
	    prodRootNode: prodRootNode,
	    exDetailsRootNode: exDetailsRootNode,
	    inDetailsRootNode: inDetailsRootNode,
	    images: images,
	    onAddImg: onAddImg,
	    onDelImg: onDelImg,
	    onPublishPost: () {onPublishPost(ctx);},
	    onRemovePost: onRemovePost,
	    onFreePaymentPressed: onFreePaymentPressed,
	    onStandardPaymentPressed: onStandardPaymentPressed,
	    onPremiumPaymentPressed: onPremiumPaymentPressed,
	 );

	 list.addAll(finalScreen);
      }
   }

   // ------------------------

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
      //dense: true,
      title: Text(title,
	 maxLines: 1,
	 overflow: TextOverflow.ellipsis,
	 style: stl.appBarLtTitle.copyWith(color: Colors.white),
      ),
   );
}

Widget makeSearchScreenWdg({
   BuildContext ctx,
   final int state,
   String numberOfMatchingPosts,
   final Node locRootNode,
   final Node prodRootNode,
   final Node exDetailsRootNode,
   final Post post,
   final OnPressedF01 onSearchPressed,
   final OnPressedF01 onSearchDetail,
   final OnPressedF06 onValueChanged,
   final OnPressedF14 onSetLocationCode,
   final OnPressedF14 onSetProductCode,
   final OnPressedF17 onSetProdDate,
   final OnPressedF09 onPriceChanged,
   final OnPressedF09 onKmChanged,
}) {
   List<Widget> foo = List<Widget>();

   {  // Location
      Widget location = makeChooseTreeNodeDialog(
	 ctx: ctx,
	 tab: cts.searchIdx,
	 fromDepth: 0,
	 title: g.param.newPostTabNames[0],
	 defaultCode: post.location,
	 root: locRootNode,
	 //iconData: Icons.edit_location,
	 onSetTreeCode: onSetLocationCode,
      );

      foo.add(location);
   }

   {  // Product
      Widget product = makeChooseTreeNodeDialog(
	 ctx: ctx,
	 tab: cts.searchIdx,
	 fromDepth: 0,
	 defaultCode: post.product,
	 title: g.param.newPostTabNames[1],
	 root: prodRootNode,
	 //iconData: Icons.directions_car,
	 onSetTreeCode: onSetProductCode,
      );

      foo.add(product);
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
	 title: exDetailsRootNode.at(productIndex, detailIndex).name(g.param.langIdx),
	 subtitle: subtitles.join(', '),
	 details: details,
	 onSetInDetail: onSearchDetail,
      );

      foo.add(detail);
   }

   { // Price
      Widget priceWdg = makeNewPostStrInput(
	 ctx: ctx,
	 title: g.param.postSearchValueTitles[0],
	 subtitle: makeRangeStr(post, 0),
	 diagTitle: g.param.postSearchValueTitles[0],
	 diagContent: '100000',
	 diagHint: '100000',
	 diagMaxLength: 10,
	 onOk: onPriceChanged,
      );

      foo.add(priceWdg);
   }

   {  // Date
      Widget prodDate = makeNewPostProdDateWdg(
	 ctx: ctx,
	 title: g.param.postSearchValueTitles[1],
	 date: makeDateString3(post.date),
	 initialDate: DateTime.now(),
	 onSetProdDate: onSetProdDate,
      );

      foo.add(prodDate);
   }

   {  // Km
      Widget kmWdg = makeNewPostStrInput(
	 ctx: ctx,
	 title: g.param.postSearchValueTitles[2],
	 subtitle: makeRangeStr(post, 2),
	 diagTitle: g.param.postSearchValueTitles[2],
	 diagContent: '',
	 diagHint: '100000',
	 diagMaxLength: 10,
	 onOk: onKmChanged,
      );

      foo.add(kmWdg);
   }

   { // Send cancel
      //Widget w1 = createRaisedButton(
      //   () {onSearchPressed(0);},
      //   g.param.cancel,
      //   stl.backgroundColor,
      //   Colors.black,
      //);

      String buttonTitle = '${g.param.searchAppBarTitle}';
      if (numberOfMatchingPosts.isNotEmpty)
	 buttonTitle += ': $numberOfMatchingPosts';

      Widget w2 = createRaisedButton(
         onPressed: () {onSearchPressed(2);},
         text: buttonTitle,
         color: stl.cs.secondary,
         textColor: stl.cs.onSecondary,
      );

      //Row r = Row(children: <Widget>[Expanded(child: w1), Expanded(child: w2)]);
      foo.add(Padding(padding: EdgeInsets.only(top: stl.basePadding), child: w2));
   }

   return ListView.builder(
      itemCount: foo.length,
      itemBuilder: (BuildContext ctx, int i) { return foo[i]; },
   );
}

Widget wrapDetailRowOnCard(Widget body)
{
   return Card(
      margin: const EdgeInsets.only(
	 left: 1.5,
	 right: 1.5,
	 top: 0.0,
	 bottom: 0.0,
      ),
      color: stl.cs.surface,
      child: body,
      elevation: 0,
      shape: RoundedRectangleBorder(
         borderRadius: BorderRadius.all(Radius.circular(0)),
      ),
   );
}

//---------------------------------------------

class ScreenArguments {
   final String title;
   final String message;
   ScreenArguments(this.title, this.message);
}

class SomeNamedRouteWidget extends StatelessWidget {
   @override
   Widget build(BuildContext context) {
      // Extract the arguments from the current ModalRoute
      // settings and cast them as ScreenArguments.
      final args =
	 ModalRoute.of(context).settings.arguments as ScreenArguments;
      return Scaffold(
	 appBar: AppBar(
	    title: Text('Title'),
	 ),
	 body: Center(
	    child:
	    Text('Message'),
	 ),
      );
   }
}

//---------------------------------------------

class MyApp extends StatelessWidget {
   Node _locRootNode = Node('');
   Node _prodRootNode = Node('');
   Node _exDetailsRoot = Node('');
   Node _inDetailsRoot = Node('');

   @override
   Widget build(BuildContext ctx) {
      return MaterialApp(
         title: g.param.appName,
         theme: ThemeData(
            colorScheme: stl.cs,
            brightness: stl.cs.brightness,
            primaryColor: stl.cs.primary,
            accentColor: stl.cs.secondary,
         ),
         debugShowCheckedModeBanner: false,
         home: Occase(
	    locRootNode: _locRootNode,
	    prodRootNode: _prodRootNode,
	    exDetailsRoot: _exDetailsRoot,
	    inDetailsRoot: _inDetailsRoot,
	 ),
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
	 routes: { '/test': (context) => SomeNamedRouteWidget(), },
	 onGenerateRoute: (settings) {
	    print('--------> $settings');
	    // If you push the PassArguments route
	    if (settings.name == '/posts') {
	       print('-------->');
	       // Cast the arguments to the correct
	       // type: ScreenArguments.
	       //final args = settings.arguments as ScreenArguments;

	       // Then, extract the required data from
	       // the arguments and pass the data to the
	       // correct screen.
	       return MaterialPageRoute(
	          builder: (context)
	          {
		     return Occase(
			locRootNode: _locRootNode,
			prodRootNode: _prodRootNode,
			exDetailsRoot: _exDetailsRoot,
			inDetailsRoot: _inDetailsRoot,
		     );
	          },
	       );
	    }
	    // The code only supports
	    // /posts right now.
	    // Other values need to be implemented if we
	    // add them. The assertion here will help remind
	    // us of that higher up in the call stack, since
	    // this assertion would otherwise fire somewhere
	    // in the framework.
	    assert(false, 'Need to implement ${settings.name}');
	    return null;
	 },
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
	 backgroundColor: stl.cs.background,
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
	    backgroundColor: stl.cs.background,
      ),
   );
}

List<Widget> makeTabWdgs({
   List<int> counters,
   List<double> opacities,
   Color textColor = stl.secondaryTextColor,
}) {
   List<Widget> list = List<Widget>();

   for (int i = 0; i < g.param.tabNames.length; ++i) {
      Widget w = makeTabWidget(
	 nUnread: counters[i],
	 title: g.param.tabNames[i],
	 opacity: opacities[i],
	 backgroundColor: stl.cs.surface,
	 textColor: textColor,
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

Widget makeFaButton({
   final int nOwnPosts,
   final int lpChats,
   final int lpChatMsgs,
   final IconData icon,
   final OnPressedF00 onNewPostPressed,
   final OnPressedF00 onFwdChatMsg,
}) {
   if (nOwnPosts != -1 && nOwnPosts == 0)
      return SizedBox.shrink();

   if (lpChats == 0 && lpChatMsgs != 0)
      return SizedBox.shrink();

   if (lpChats != 0 && lpChatMsgs != 0) {
      return FloatingActionButton(
         backgroundColor: stl.cs.secondary,
	 mini: false,
         child: Icon(Icons.send, color: stl.cs.onSecondary),
         onPressed: onFwdChatMsg,
      );
   }

   if (lpChats != 0)
      return SizedBox.shrink();

   if (onNewPostPressed == null)
      return SizedBox.shrink();

   return FloatingActionButton(
      backgroundColor: stl.cs.secondary,
      mini: false,
      child: Icon(icon, color: stl.cs.onSecondary),
      onPressed: onNewPostPressed,
   );
}

List<Widget> makeFaButtons({
   final bool isWide,
   final bool isOnOwnChat,
   final bool hasFavPosts,
   final int nPosts,
   final int nOwnPosts,
   final bool newSearchPressed,
   final List<List<Coord>> lpChats,
   final List<List<Coord>> lpChatMsgs,
   final OnPressedF00 onNewPost,
   final OnPressedF01 onFwdSendButton,
   final OnPressedF00 onGoToSearch,
}) {
   List<Widget> ret = List<Widget>(g.param.tabNames.length);

   if (isOnOwnChat) {
      ret[cts.ownIdx] = SizedBox.shrink();
   } else {
      ret[cts.ownIdx] = makeFaButton(
	 nOwnPosts: nOwnPosts,
	 onNewPostPressed: onNewPost,
	 onFwdChatMsg: () {onFwdSendButton(0);},
	 lpChats: lpChats[0].length,
	 lpChatMsgs: lpChatMsgs[0].length,
	 icon: stl.newPostIcon,
      );
   }

   ret[cts.searchIdx] = makeFaButtonFav(
      newSearchPressed: newSearchPressed,
      isWide: isWide,
      hasFavPosts: hasFavPosts,
      hasPosts: nPosts != 0,
      onGoToSearch: onGoToSearch,
   );

   ret[cts.favIdx] = makeFaButton(
      nOwnPosts: -1,
      onNewPostPressed: isWide ? null : onGoToSearch,
      onFwdChatMsg: () {onFwdSendButton(2);},
      lpChats: lpChats[2].length,
      lpChatMsgs: lpChatMsgs[2].length,
      icon: Icons.search,
   );

   return ret;
}

Widget makeFaButtonFav({
   final bool newSearchPressed,
   final bool isWide,
   final bool hasFavPosts,
   final bool hasPosts,
   final OnPressedF00 onGoToSearch,
}) {
   if (!isWide && (newSearchPressed || !hasPosts))
      return SizedBox.shrink();

   if (isWide && newSearchPressed)
      return SizedBox.shrink();

   if (isWide && !hasFavPosts)
      return SizedBox.shrink();

   return FloatingActionButton(
      onPressed: onGoToSearch,
      backgroundColor: stl.cs.secondary,
      mini: false,
      child: Icon(
	 Icons.search,
	 color: stl.cs.onSecondary,
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
      color: stl.chatScreenBgColor,
      margin: const EdgeInsets.all(stl.basePadding),
      child: Center(
         widthFactor: 1,
         child: Padding(
            child: w,
            padding: EdgeInsets.all(stl.basePadding),
         )
      ),
   );
}

Card makeChatMsgWidget(
   BuildContext ctx,
   ChatMetadata chatMetadata,
   int i,
   Function onChatMsgLongPressed,
   Function onDragChatMsg,
   bool isNewMsg,
   String ownNick,
) {
   Color color = Color(0xFFFFFFFF);
   Color onSelectedMsgColor = stl.chatScreenBgColor;
   if (chatMetadata.msgs[i].isFromThisApp()) {
      color = Colors.lime[100];
   } else if (isNewMsg) {
      //color = Color(0xFF0080CF);
   }

   if (chatMetadata.msgs[i].isLongPressed) {
      onSelectedMsgColor = Colors.blue[200];
      color = Colors.blue[100];
   }

   RichText msgAndDate = RichText(
      text: TextSpan(
         text: chatMetadata.msgs[i].body,
         style: stl.tsMainBlack,
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
            padding: EdgeInsets.all(stl.basePadding),
            child: msgAndDate))
      , Padding(
            padding: EdgeInsets.all(2.0),
            child: chooseMsgStatusIcon(chatMetadata.msgs[i].status))
      ]);
   } else {
      msgAndStatus = Padding(
            padding: EdgeInsets.all(stl.basePadding),
            child: msgAndDate);
   }

   Widget ww = msgAndStatus;
   if (chatMetadata.msgs[i].redirected()) {
      final Color redirTitleColor =
         isNewMsg ? stl.cs.secondary : Colors.blueGrey;

      Row redirWidget = Row(
         mainAxisSize: MainAxisSize.min,
         mainAxisAlignment: MainAxisAlignment.start,
         crossAxisAlignment: CrossAxisAlignment.center,
         textBaseline: TextBaseline.alphabetic,
         children: <Widget>
         [ Icon(Icons.forward, color: stl.chatDateColor)
         , Text(g.param.msgOnRedirectedChat,
            style: TextStyle(color: redirTitleColor,
               fontSize: stl.smallFontSize,
               fontStyle: FontStyle.italic,
	    ),
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

   final double screenWidth = makeWidgetWidth(ctx);
   Card w1 = Card(
      margin: EdgeInsets.only(
            left: marginLeft,
            top: 2.0,
            right: marginRight,
            bottom: 0.0),
      color: color,
      child: Center(
         widthFactor: 1,
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
      elevation: 0,
      margin: const EdgeInsets.all(0),
      shape: RoundedRectangleBorder(
         borderRadius: BorderRadius.all(Radius.circular(0)),
      ),
   );
}

ListView makeChatMsgListView(
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
      padding: const EdgeInsets.only(bottom: stl.basePadding, top: stl.basePadding),
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
                         padding: EdgeInsets.all(stl.basePadding),
                         child: Text(
                            '${chatMetadata.divisorUnreadMsgs}',
                            style: TextStyle(
                               fontSize: stl.largerFontSize,
                               fontWeight: FontWeight.normal,
                               color: stl.cs.primary,
                            ),
                         )
                      ),
                   ),
               );
            }

            if (i > chatMetadata.divisorUnreadMsgsIdx) {
               i -= 1; // For the shift
	    }
         }

         final bool isNewMsg =
            shift == 1 &&
            i >= chatMetadata.divisorUnreadMsgsIdx &&
            i < chatMetadata.divisorUnreadMsgsIdx + chatMetadata.divisorUnreadMsgs;
                               
         Card chatMsgWidget = makeChatMsgWidget(
            ctx,
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
      elevation: 0,
      shape: RoundedRectangleBorder(
         borderRadius: BorderRadius.all(Radius.circular(0)),
      ),
      margin: EdgeInsets.all(0),
      color: Colors.white,
      child: Padding(
         padding: EdgeInsets.all(stl.basePadding),
	    child: ConstrainedBox(
	       constraints: BoxConstraints(
		  maxHeight: 140.0,
		  minHeight: 45.0,
	       ),
	       child: rr,
	    ),
	 ),
      );
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
      titleColor = stl.cs.secondary;

   Text body = Text(chatMetadata.msgs[dragedIdx].body,
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
      color: stl.cs.primary,
   );

   //IconButton attachmentButton = IconButton(
   //   icon: Icon(Icons.add_a_photo),
   //   onPressed: onAttachment,
   //   color: stl.cs.primary,
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
            backgroundColor: stl.cs.secondary,
            child: Icon(Icons.expand_more,
               color: stl.cs.onSecondary,
            ),
         ),
      );

      foo.add(jumDownButton);

      if (chatMetadata.nUnreadMsgs > 0) {
         Widget jumDownButton = Positioned(
            bottom: 53.0,
            right: 23.0,
            child: makeUnreadMsgsCircle(
               unread: chatMetadata.nUnreadMsgs,
               backgroundColor: stl.cs.secondaryVariant,
               textColor: stl.cs.onSecondary,
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
         padding: const EdgeInsets.symmetric(horizontal: stl.basePadding),
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
      cols.add(Divider(color: Colors.grey, height: 0.0));
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
         final String url = cts.gravatarUrl + avatar + '.jpeg';
         backgroundImage = NetworkImage(url);
      } else {
         child = stl.unknownPersonIcon;
      }

      ChatPresenceSubtitle cps = makeLTPresenceSubtitle(
         chatMetaData: chatMetadata,
         text: postSummary,
	 color: stl.secondaryDarkColor,
      );

      title = ListTile(
          contentPadding: EdgeInsets.all(0),
          leading: CircleAvatar(
              child: child,
              backgroundImage: backgroundImage,
              backgroundColor: selectColor(chatMetadata.peer),
          ),
          title: Text(chatMetadata.getChatDisplayName(),
             maxLines: 1,
             overflow: TextOverflow.ellipsis,
             style: stl.appBarLtTitle,
          ),
          //dense: true,
          subtitle:
             Text(cps.subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: stl.appBarLtTitle.copyWith(
		   fontSize: stl.smallFontSize,
		   fontWeight: FontWeight.normal,
		),
             ),
       );
   }

   final double tw = makeTabWidth(ctx);
   final double ww =  makeWidgetWidth(ctx);
   final double bw = 4;
   final double boderWidth = ((tw - bw) > ww) ? bw : 0;

   return WillPopScope(
         onWillPop: () async { return onWillPopScope();},
         child: Scaffold(
            appBar : AppBar(
               actions: actions,
               title: title,
	       //backgroundColor: stl.cs.secondary,
               leading: IconButton(
                  padding: EdgeInsets.all(0),
                  icon: Icon(Icons.arrow_back, color: stl.primaryTextColor),
                  onPressed: onWillPopScope,
               ),
            ),
	 backgroundColor: stl.cs.background,
         body: Container(
            child: mainCol,
	    decoration: BoxDecoration(
	       color: stl.chatScreenBgColor,
	       shape: BoxShape.rectangle,
	       border: Border.all(width: boderWidth, color: stl.primaryColor),
	    ),
	 ),
      )
   );
}

Widget makeTabWidget({
   int nUnread,
   String title,
   double opacity,
   Color backgroundColor,
   Color textColor,
}) {
   if (nUnread == 0)
      return Center(child: Text(title));

   List<Widget> widgets = List<Widget>(2);
   widgets[0] = Text(title);

   // See: https://docs.flutter.io/flutter/material/TabBar/labelColor.html
   // for opacity values.
   widgets[1] = Opacity(
      child: makeUnreadMsgsCircle(
         unread: nUnread,
         backgroundColor: backgroundColor,
         textColor: textColor,
      ),
      opacity: opacity,
   );

   return Row(
      children: widgets,
      mainAxisAlignment: MainAxisAlignment.center,
   );
}

CircleAvatar makeChatListTileLeading({
   bool isLongPressed,
   String avatarUrl,
   String nick,
   Color bgcolor,
   OnPressedF00 onLeadingPressed,
})
{
   List<Widget> l = List<Widget>();

   ImageProvider bgImg;
   if (avatarUrl.isEmpty) {
      //l.add(Center(child: stl.unknownPersonIcon));
      Widget outlineW = OutlineButton(
	 child: Text(makeStrAbbrev(nick)),
	 borderSide: BorderSide(style: BorderStyle.none),
	 onPressed: onLeadingPressed,
	 shape: CircleBorder()
      );

      l.add(outlineW);
   } else {
      bgImg = NetworkImage(avatarUrl);
   }

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
   bool selected,
   String price,
   String title,
   String subtitle,
   Color priceColor,
   OnPressedF00 onTap,
}) {
   Text subtitleW = Text(subtitle,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
   );

   Text titleW = Text(title,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
   );

   IconData icon = selected ? Icons.check_box : Icons.check_box_outline_blank;
   Color backgroundColor = selected ? Colors.amber[100] : null;

   return Card(
      color: backgroundColor,
      child: ListTile(
         leading: Icon(icon),
         title: titleW,
         //dense: false,
         subtitle: subtitleW,
         trailing: Text(price),
         onTap: onTap,
         enabled: true,
         selected: selected,
         isThreeLine: false,
      ),
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
//   debugPrint(result.nonce);
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

List<Widget> makePaymentPlanOptions({
   Post post, 
   OnPressedF00 onFreePaymentPressed,
   OnPressedF00 onStandardPaymentPressed,
   OnPressedF00 onPremiumPaymentPressed,
}) {
   List<OnPressedF00> payments = <OnPressedF00>
   [ onFreePaymentPressed
   , onStandardPaymentPressed
   , onPremiumPaymentPressed
   ];

   List<Widget> list = <Widget>[];

   for (int i = 0; i < g.param.paymentValues.length; ++i) {
      Widget p = makePayPriceListTile(
	 selected: post.priority == i,
         price: g.param.paymentValues[i],
         title: g.param.paymentValueTitles[i],
         subtitle: g.param.paymentValueSubtitles[i],
         priceColor: stl.priceColors[i],
         onTap: payments[i],
      );

      list.add(p);
   }

   return list;
}

Widget makePaymentOptions({
   String title,
   String subtitle,
   OnPressedF00 onTap,
}) {
   Text subtitleW = Text(subtitle,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      //style: stl.ltSubtitleSty,
   );

   Text titleW = Text(title,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      //style: stl.ltTitleSty,
   );

   return Card(
      margin: const EdgeInsets.symmetric(vertical: stl.basePadding),
      color: stl.cs.background,
      child: ListTile(
         title: titleW,
         subtitle: subtitleW,
         contentPadding: EdgeInsets.symmetric(horizontal: stl.basePadding),
         onTap: onTap,
         enabled: true,
         isThreeLine: false,
      ),
   );
}

Widget makePaymentChoiceWidget({
   OnPressedF00 onFreePaymentPressed,
   OnPressedF00 onStandardPaymentPressed,
   OnPressedF00 onPremiumPaymentPressed,
}) {
   List<Widget> list = <Widget>[];

   Widget title = Padding(
      padding: EdgeInsets.all(stl.basePadding),
      child: Text(g.param.paymentTitle,
	 //style: stl.tsMainPrimary,
      ),
   );

   list.add(title);

   Widget paypal = makePaymentOptions(
      title: 'PayPal',
      subtitle: 'ksksk sksksk',
      onTap: onFreePaymentPressed,
   );

   list.add(paypal);

   Widget creditCard = makePaymentOptions(
      title: 'Credit Card',
      subtitle: '',
      onTap: onFreePaymentPressed,
   );

   list.add(creditCard);

   return Card(
      child: Column(
         mainAxisSize: MainAxisSize.min,
         children: list
      ),
   );
}

Widget createRaisedButton({
   OnPressedF00 onPressed,
   final String text,
   Color color,
   Color textColor,
   double minWidth = stl.minButtonWidth,
}) {
   RaisedButton but = RaisedButton(
      child: Text(text,
	 style: TextStyle(
	    color: textColor,
	    fontSize: stl.largerFontSize,
	 ),
	 //textAlign: TextAlign.center,
      ),
      color: color,
      onPressed: onPressed,
   );

   return Center(child: ButtonTheme(minWidth: minWidth, child: but));
}

// Study how to convert this into an elipsis like whatsapp.
Container makeUnreadMsgsCircle({
   int unread,
   Color backgroundColor,
   Color textColor,
}) {
   final
   Text txt = Text("$unread",
      style: TextStyle(
	 color: textColor,
	 fontSize: stl.smallFontSize,
      ),
   );

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
       decoration: BoxDecoration(
	  color: backgroundColor,
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

Widget makeStatsText({
   String key,
   String value,
   String prefix =  ' • ',
}) {
   return Text(prefix + key + ' ' + value,
      style: TextStyle(
	 fontSize: stl.mainFontSize,
	 color: stl.primaryDarkColor,
	 fontWeight: FontWeight.normal,
      ),
   );
}

Widget makePostRowElem({
   BuildContext ctx,
   String key,
   String value,
   String prefix = ' • ',
   Color keyTextColor = stl.postDetailColor,
   Color valueTextColor = stl.secondaryDarkColor,
}) {

   Text keyWdg = Text(prefix + key,
      style: stl.tsMainBlack.copyWith(color: keyTextColor),
   );

   Text valueWdg = Text(value,
	style: stl.tsMainBlackBold.copyWith(
	   color: valueTextColor,
	),
	overflow: TextOverflow.ellipsis,
   );

   Row w = Row(
      //mainAxisSize: MainAxisSize.min,
      //mainAxisAlignment: MainAxisAlignment.start,
      //crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>
      [ Expanded(child: Padding(
	    padding:  const EdgeInsets.only(left: 0),
	    child: keyWdg,
         ),
      )
      , Expanded(child: valueWdg)
      ],
   );

   return imposeWidth(
      width: makeTabWidth(ctx),
      child: w,
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

      Text text = Text(' • ${nodes[i].name(g.param.langIdx)}',
	 style: stl.tsMainBlack.copyWith(color: stl.postDetailColor),
      );

      list.add(text);
   }

   return list;
}

// Assembles the menu information.
List<Widget> makeTreeInfo(
   BuildContext ctx,
   final Node rootNode,
   final List<int> code,
   final String title,
   List<String> treeDepthNames,
) {
   List<Widget> ret = <Widget>[];
   ret.add(makeNewPostSetionTitle(title: title));
   List<String> names = loadNames(
      rootNode: rootNode,
      code: code,
      languageIndex: g.param.langIdx,
   );

   List<Widget> tmp = List<Widget>.generate(names.length, (int j)
   {
      return makePostRowElem(
	 ctx: ctx,
	 key: treeDepthNames[j],
	 value: names[j],
      );
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

   list.add(makeNewPostSetionTitle(title: g.param.rangesTitle));

   List<Widget> items = List.generate(g.param.rangeDivs.length, (int i)
   {
      return makePostRowElem(
	 ctx: ctx,
	 key: g.param.postValueTitles[i],
	 value: makeRangeStr(post, i),
      );
   });

   list.addAll(items); // The tree info.

   return list;
}

List<Widget> makePostExDetails(BuildContext ctx, Post post, Node exDetailsRootNode)
{
   // Post details varies according to the first index of the products
   // entry in the tree.
   final int idx = post.getProductDetailIdx();
   if (idx == -1)
      return List<Widget>();

   List<Widget> list = List<Widget>();
   list.add(makeNewPostSetionTitle(title: g.param.postExDetailsTitle));

   final int l1 = exDetailsRootNode.at1(idx).children.length;
   final int l2 = post.exDetails.length;
   final int l = l1 > l2 ? l2 : l1;
   for (int i = 0; i < l; ++i) {
      final int n = exDetailsRootNode.children[idx].children[i].children.length;
      final int k = post.exDetails[i];
      if (k == -1 || k >= n)
	 continue;
      
      list.add(
         makePostRowElem(
	    ctx: ctx,
            key: exDetailsRootNode.at(idx, i).name(g.param.langIdx),
            value: exDetailsRootNode.at(idx, i).children[k].name(g.param.langIdx),
         ),
      );
   }

   list.add(makeNewPostSetionTitle(title: g.param.postRefSectionTitle));

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
      list.add(makePostRowElem(
            ctx: ctx,
	    key: g.param.descList[i],
	    value: values[i],
	 ),
      );

   return list;
}

List<Widget> makePostInDetails(Post post, Node inDetailsRootNode)
{
   List<Widget> all = List<Widget>();

   final int i = post.getProductDetailIdx();
   if (i == -1)
      return List<Widget>();

   final int l1 = inDetailsRootNode.at1(i).children.length;
   final int l2 = post.inDetails.length;
   final int l = l1 > l2 ? l2 : l1;
   for (int j = 0; j < l; ++j) {
      List<Widget> foo = makePostInRows(
         inDetailsRootNode.at(i, j).children,
         post.inDetails[j],
      );

      if (foo.length != 0) {
         all.add(makeNewPostSetionTitle(
	       title: inDetailsRootNode.at(i, j).name(g.param.langIdx),
            ),
         );
         all.addAll(foo);
      }
   }

   return all;
}

Card putPostElemOnCard({
   List<Widget> list,
   Color backgroundColor = stl.postColor, 
   double margin = stl.basePadding,
   double padding = 0,
}) {
   Column col = Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: list,
   );

   return Card(
      elevation: 0,
      //color: stl.cs.background,
      color: backgroundColor,
      margin: EdgeInsets.all(margin),
      shape: RoundedRectangleBorder(
         borderRadius: BorderRadius.all(
            Radius.circular(0)
         ),
      ),
      child: Padding(
	 padding: EdgeInsets.symmetric(vertical: padding),
	 child: col,
      ),
   );
}

Widget makePostDescription(BuildContext ctx, String desc)
{
   return Padding(
      padding: EdgeInsets.all(stl.basePadding),
      child: Text(desc),
   );
}

List<Widget> assemblePostRows({
   BuildContext ctx,
   final Post post,
   final Node locRootNode,
   final Node prodRootNode,
   final Node exDetailsRootNode,
   final Node inDetailsRootNode,
}) {
   List<Widget> all = <Widget>[];
   all.addAll(makePostValues(ctx, post));
   all.addAll(makeTreeInfo(ctx, locRootNode, post.location, g.param.newPostTabNames[0], g.param.locationTreeDepthNames));
   all.addAll(makeTreeInfo(ctx, prodRootNode, post.product, g.param.newPostTabNames[1], g.param.productTreeDepthNames));
   all.addAll(makePostExDetails(ctx, post, exDetailsRootNode));
   all.addAll(makePostInDetails(post, inDetailsRootNode));

   if (post.description.isNotEmpty) {
      all.add(makeNewPostSetionTitle(title: g.param.postDescTitle));
      all.add(makePostDescription(ctx, post.description));
   }

   return all;
}

String makeTreeItemStr(Node root, List<int> nodeCoordinate)
{
   if (nodeCoordinate.isEmpty)
      return '';

   final List<String> names = loadNames(
      rootNode: root,
      code: nodeCoordinate,
      languageIndex: g.param.langIdx,
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
      unselectedWidgetColor: stl.cs.primary,
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
   Color textColor = const Color(0xFF000000),
   double fontSize = stl.mainFontSize,
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
      padding: const EdgeInsets.all(stl.basePadding),
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

Widget makeNewPostDialogWdg({
   final Widget title,
   final EdgeInsets contentPadding = const EdgeInsets.only(left: 24, right: 24, top: 20),
   final List<Widget> list,
   final List<Widget> actions,
   final EdgeInsets insetPadding = const EdgeInsets.symmetric(horizontal: 40.0, vertical: 24.0),
   final Color backgroundColor = Colors.white,
}) {
   Column col = Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: list,
   );

   Widget content = Container(
      child: SingleChildScrollView(
         scrollDirection: Axis.vertical,
         reverse: false,
         child: col,
      ),
   );

   return AlertDialog(
      title: title,
      contentPadding: contentPadding,
      actions: actions,
      insetPadding: insetPadding,
      backgroundColor: backgroundColor,
      content: content,
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
	 child: Text(g.param.ok),
	 onPressed: () {_onOkPressed(ctx);},
      );

      List<Widget> list = makeCheckBoxes(
	 widget.state,
	 widget.names,
	 _onPressed,
      );

      return makeNewPostDialogWdg(
	 title: Text(widget.title),
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
	    //dense: true,
	    title: Text(widget.names[i],
	       //style: stl.ltTitleSty,
	    ),
	    value: i == widget.onIdx,
	    onChanged: (bool v) { _onPressed(ctx, v, i); },
	    activeColor: stl.cs.primary,
	    isThreeLine: false,
	 );

	 Align a = Align(alignment: Alignment.centerLeft, child: cb);
	 exDetails.add(a);
      }

      final FlatButton ok = FlatButton(
	 child: Text(g.param.ok, style: TextStyle(color: stl.cs.primary)),
	 onPressed: () {_onOkPressed(ctx);},
      );

      return makeNewPostDialogWdg(
	 title: Text(widget.title),
	 list: exDetails,
	 actions: <FlatButton>[ok],
      );
   }
}

//---------------------------------------------------------------

class TextInput extends StatefulWidget {
   String title;
   String description;
   String descriptionHint;
   int maxLength;

   @override
   PostDescriptionState createState() => PostDescriptionState();
   TextInput({
      this.title = '',
      this.description = '',
      this.descriptionHint = '',
      this.maxLength = 100,
   });
}

class PostDescriptionState extends State<TextInput> with TickerProviderStateMixin {
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
      final String hint = widget.description.isEmpty ?
	 widget.descriptionHint : widget.description;

      TextField tf = TextField(
	 autofocus: true,
	 controller: _txtCtrl,
	 keyboardType: TextInputType.multiline,
	 maxLines: null,
	 maxLength: widget.maxLength,
	 //style: stl.tsMainBlack,
	 decoration: InputDecoration.collapsed(hintText: hint),
      );

      Padding content = Padding(
	 padding: EdgeInsets.all(stl.basePadding),
	 child: tf,
      );

      final TextButton ok = TextButton(
	 autofocus: true,
         child: Text(g.param.ok),
         onPressed: ()
         {
	    if (_txtCtrl.text.isNotEmpty)
	       Navigator.pop(ctx, _txtCtrl.text);
         });

      Widget w = AlertDialog(
	 title: Text(widget.title),
	 content: tf,
	 actions: <Widget>[ok],
      );

      return imposeWidth(
	 child: w,
	 width: makeWidgetWidth(ctx),
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
      // only one tree option.
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

      FlatButton back =  FlatButton(
	 child: Text(g.param.usefulWords[0]),
	 onPressed: () {_onBack(ctx);},
      );

      FlatButton cancel =  FlatButton(
	 child: Text(g.param.cancel),
	 onPressed: () {_onCancel(ctx);},
      );

      FlatButton ok =  FlatButton(
	 child: Text(g.param.ok),
	 onPressed: () {_onOk(ctx);},
      );

      return makeNewPostDialogWdg(
	 title: Text(widget.root.name(g.param.langIdx)),
	 list: locWdgs,
	 actions: <FlatButton>[back, cancel, ok],
      );
   }
}

//---------------------------------------------------------------------

List<Widget> makeDetailsTextWdgs({
   List<String> fields,
   Color textColor = stl.postColor,
   double fontSize = stl.smallFontSize,
   FontWeight fontWeight = FontWeight.w500,
}) {
   return List<Widget>.generate(fields.length, (int i) {
      return Card(
	    elevation: 0,
	    color: Colors.grey[300],
	    margin: EdgeInsets.all(0),
	    child: Padding(
	       padding: const EdgeInsets.symmetric(horizontal: stl.basePadding),
               child: Text(fields[i],
	          style: TextStyle(
	             fontSize: fontSize,
	             color: Colors.grey[800],
		     fontWeight: FontWeight.w200,
	          ),
	       ),
	    ),
	 );
      },
   );
}

class PostDetailsWidget extends StatefulWidget {
   int tab;
   Post post;
   Node locRootNode;
   Node prodRootNode;
   Node exDetailsRootNode;
   Node inDetailsRootNode;
   List<List<int>> images;
   OnPressedF00 onAddImg;
   OnPressedF01 onDelImg;
   OnPressedF01 onExpandImg;
   OnPressedF00 onAddPostToFavorite;
   OnPressedF00 onDelPost;
   OnPressedF00 onSharePost;
   OnPressedF00 onReportPost;

   @override
   PostDetailsWidgetState createState() => PostDetailsWidgetState();

   PostDetailsWidget(
   { @required this.tab
   , @required this.post
   , @required this.locRootNode
   , @required this.prodRootNode
   , @required this.exDetailsRootNode
   , @required this.inDetailsRootNode
   , this.images = null
   , @required this.onAddImg
   , @required this.onDelImg
   , @required this.onExpandImg
   , @required this.onAddPostToFavorite
   , @required this.onDelPost
   , @required this.onSharePost
   , @required this.onReportPost
   });
}

class PostDetailsWidgetState extends State<PostDetailsWidget> with TickerProviderStateMixin {
   @override
   void dispose()
      { super.dispose(); }

   @override
   void initState()
      { super.initState(); }

   Future<void> _onAddImg() async
   {
      await widget.onAddImg();
      setState(() {});
   }

   void _onDelImg(int i)
   {
      setState(() {widget.onDelImg(i);});
   }

   @override
   Widget build(BuildContext ctx)
   {
      final int tab = cts.searchIdx;
      Widget detailsWdg = makePostDetailsWdg(
	 ctx: ctx,
	 post: widget.post,
	 locRootNode: widget.locRootNode,
	 prodRootNode: widget.prodRootNode,
	 exDetailsRootNode: widget.exDetailsRootNode,
	 inDetailsRootNode: widget.inDetailsRootNode,
	 images: widget.images,
	 onDelImg: _onDelImg,
	 onExpandImg: widget.onExpandImg,
	 onReportPost: () 
	 {
	    Navigator.of(ctx).pop();
	    widget.onReportPost();
	 },
      );

      final
      FlatButton ok = FlatButton(
	 child: Text(g.param.usefulWords[0]),
	 onPressed: () { Navigator.of(ctx).pop(); },
      );

      List<Widget> actions = List<Widget>();

      final double width = makeTabWidth(ctx);
      if (widget.tab == cts.searchIdx) {

	 final
	 String avatar =
	    widget.post.images.isNotEmpty ? widget.post.images.first : '';

	 String nick = widget.post.nick;
	 if (widget.post.nick.isEmpty)
	    nick = g.param.advertiser;

	 ChatMetadata cm = ChatMetadata(
	   peer: widget.post.from,
	   nick: nick,
	   avatar: avatar,
	   date: DateTime.now().millisecondsSinceEpoch,
	 );

	 Widget tmp = makeChatListTile(
	    ctx: ctx,
	    chatMetadata: cm,
	    avatarUrl: avatar,
	    onChatLeadingPressed: () {},
	    onChatLongPressed: () {},
	    onStartChatPressed: () {
	       Navigator.of(ctx).pop();
	       widget.onAddPostToFavorite();
	    },
	 );
	 
	 actions.add(SizedBox(width: width, child: tmp));
      }

      Widget ret = makeNewPostDialogWdg(
	 title: null,
	 contentPadding: const EdgeInsets.all(0),
	 list: <Widget>[detailsWdg],
	 actions: actions,
	 backgroundColor: stl.cs.primary,
	 insetPadding: const EdgeInsets.all(0),
      );

      Widget leaveDetails = IconButton(
         onPressed: () { Navigator.of(ctx).pop(); },
         icon: Icon(Icons.clear, color: Colors.black),
      );

      IconButton icon;
      if (widget.images != null)
	 icon = IconButton(
	    onPressed: _onAddImg,
	    icon: Icon(Icons.add_a_photo, color: stl.cs.primary),
	 );
      else {
	 icon = IconButton(
	    icon: Icon(Icons.share, color: stl.cs.primary),
	    onPressed: (){print('aaaaaaaaaaa');},
            //() {
            //  Navigator.of(ctx).pop();
            //  widget.onSharePost();
            //}
	 );
      }

      return Stack(children: <Widget>
      [ ret
      , Positioned(
          right: 0,
          top: 0,
          child: Card(
             elevation: 0,
             color: Colors.white.withOpacity(stl.delImgWidgOpacity),
             margin: EdgeInsets.all(0),
             child: Column(children: <Widget>[leaveDetails, icon]),
          ),
       ),
      ]);
   }
}

int compStringForPostWdg(String a, String b)
{
   final bool c1 = a.length > 4 && a.length < 9;
   final bool c2 = b.length > 4 && b.length < 9;

   return ( c1 && !c2) ? -1
	: (!c1 &&  c2) ? 1 : 0;
}

class PostWidget extends StatefulWidget {
   int tab;
   Post post;
   Node locRootNode;
   Node prodRootNode;
   Node exDetailsRootNode;
   Node inDetailsRootNode;
   List<List<int>> images;
   OnPressedF00 onAddImg;
   OnPressedF01 onDelImg;
   OnPressedF01 onExpandImg;
   OnPressedF00 onAddPostToFavorite;
   OnPressedF00 onDelPost;
   OnPressedF00 onSharePost;
   OnPressedF00 onReportPost;
   OnPressedF00 onPinPost;
   OnPressedF00 onVisualization;

   @override
   PostWidgetState createState() => PostWidgetState();

   PostWidget(
   { @required this.tab
   , @required this.post
   , @required this.locRootNode
   , @required this.prodRootNode
   , @required this.exDetailsRootNode
   , @required this.inDetailsRootNode
   , this.images = null
   , @required this.onAddImg
   , @required this.onDelImg
   , @required this.onExpandImg
   , @required this.onAddPostToFavorite
   , @required this.onDelPost
   , @required this.onSharePost
   , @required this.onReportPost
   , @required this.onPinPost
   , @required this.onVisualization
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

   Future<int> _onShowDetails(BuildContext ctx) async
   {
      widget.onVisualization();

      Navigator.of(ctx).push(
	 PageRouteBuilder(
	    opaque: false,
	    pageBuilder: (context, __, ___)
	    {
	       Widget w = PostDetailsWidget(
		  tab: widget.tab,
		  post: widget.post,
		  locRootNode: widget.locRootNode,
		  prodRootNode: widget.prodRootNode,
		  exDetailsRootNode: widget.exDetailsRootNode,
		  inDetailsRootNode: widget.inDetailsRootNode,
		  images: widget.images,
		  onAddImg: widget.onAddImg,
		  onDelImg: widget.onDelImg,
		  onExpandImg: widget.onExpandImg,
		  onDelPost: widget.onDelPost,
		  onSharePost: widget.onSharePost,
		  onReportPost: widget.onReportPost,
		  onAddPostToFavorite: () {
		     widget.onAddPostToFavorite();
		  },
	       );

	       return imposeWidth(
		  child: w,
		  width: makeWidgetWidth(context),
	       );
	    },
            transitionsBuilder:
	       (context, animation, secondaryAnimation, child)
	       {
		  var begin = Offset(0.0, 1.0);
		  var end = Offset.zero;
		  var curve = Curves.easeOut;
		  var tween = Tween(begin: begin, end: end)
			.chain(CurveTween(curve: curve));

		  return SlideTransition(
		     position: animation.drive(tween),
                     child: child,
		  );
	       },
	 ),
      );
   }

   Widget makeImgWdg(double postImgWidth, double postImgHeight)
   {
      Widget imgWdg;
      if (widget.post.images.isNotEmpty) {
	 Widget img = makeNetImgBox(
	    width: postImgWidth,
	    height: postImgHeight,
	    url: widget.post.images.first,
	 );

	 Widget kmText = makeTextWdg(
	    text: makeRangeStr(widget.post, 2),
	    fontWeight: FontWeight.w700,
	    textColor: Colors.black,
	    fontSize: stl.smallFontSize,
	 );

	 Widget priceText = makeTextWdg(
	    text: makeRangeStr(widget.post, 0),
	    fontWeight: FontWeight.w700,
	    textColor: Colors.black,
	    fontSize: stl.smallFontSize,
	 );

	 imgWdg = Stack(
	    //alignment: Alignment.topLeft,
	    children: <Widget>
	    [ img
	    , Positioned(
		 right: 0,
		 top: 0,
		 child: Card(child: kmText,
		    elevation: 0,
		    color: stl.cs.surface,
		    margin: EdgeInsets.all(stl.basePadding),
		 ),
	      )
	    , Positioned(
		 left: 0,
		 top: 0,
		 child: Card(child: priceText,
		    elevation: 0,
		    color: stl.cs.surface,
		    margin: EdgeInsets.all(stl.basePadding),
		 ),
	      )
	    ],
	 );
      } else if (widget.images != null && widget.images.isNotEmpty) {
	 imgWdg = Image.memory(
	    widget.images.last,
	    width: postImgWidth,
	    height: postImgHeight,
	    fit: BoxFit.cover,
	    filterQuality: FilterQuality.high,
	 );
	 assert(imgWdg != null);
      } else {
	 Widget w = SizedBox.shrink();
	 imgWdg = makeImgPlaceholder(
	    postImgWidth,
	    postImgHeight,
	    w,
	 );
      }

      // The add a photo button should appear only when this function is
      // called on the new posts tab. We determine that in the
      // following way.
      if (widget.images != null) {
	 Widget addImgWidget = makeAddOrRemoveWidget(
	    onPressed: widget.onAddImg,
	    icon: Icons.add_a_photo,
	    color: stl.cs.primary,
	 );

	 assert(addImgWidget != null);
	 assert(imgWdg != null);

	 Stack st = Stack(
	    alignment: Alignment(0, 0),
	    children: <Widget>
	    [ imgWdg
	    , Card(child: addImgWidget,
		 elevation: 0,
		 color: Colors.white.withOpacity(0.7),
		 margin: EdgeInsets.all(0),
	      ),
	    ],
	 );

	 return st;
      } else {
	 return imgWdg;
      }
   }

   Widget makeInfoWdg(double postInfoWidth)
   {
      final String locationStr =
         makeTreeItemStr(widget.locRootNode, widget.post.location);
      final String modelStr =
	 makeTreeItemStr(widget.prodRootNode, widget.post.product);

      List<String> detailsNames = makeExDetailsNamesAll(
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

      detailsNames.addAll(inDetailsNames);
      detailsNames.sort(compStringForPostWdg);

      int n = 17;
      if (postInfoWidth < 160)
	 n = 3;
      else if (postInfoWidth < 210)
	 n = 4;
      else if (postInfoWidth < 230)
	 n = 6;
      else if (postInfoWidth < 260)
	 n = 7;
      else if (postInfoWidth < 300)
	 n = 8;

      if (detailsNames.length > n)
	 detailsNames.removeRange(n, detailsNames.length);

      Padding modelTitle = Padding(
	 padding: const EdgeInsets.all(stl.basePadding),
	 child: RichText(
	    overflow: TextOverflow.ellipsis,
	    text: TextSpan(
	       text: '$modelStr\n',
	       style: stl.postModelSty,
	       children: <TextSpan>
	       [ TextSpan(
		    text: locationStr,
		    style: stl.postLocationSty,
		 ),
	       ],
	    ),
	 ),
      );

      Widget location = makeTextWdg(
	 text: locationStr,
      );

      List<Widget> detailWdgs = makeDetailsTextWdgs(
	 fields: detailsNames,
      );

      const double spacing = stl.basePadding;
      const double runSpacing = stl.basePadding;

      Widget detailsWrap = Padding(
	 padding: const EdgeInsets.all(stl.basePadding),
	 child: Wrap(
	    children: detailWdgs,
	    spacing: spacing,
	    runSpacing: runSpacing,
	 ),
      );

      final int visualizations = widget.post.visualizations;
      final String name = g.param.statsTitleAndFields[2];
      final String date = makeDateString3(widget.post.date);

      Widget statsWdgs = makeTextWdg(
	 text: '$name: ${visualizations} • ${date}',
	 edgeInsets: const EdgeInsets.all(stl.basePadding),
	 textColor: stl.neutralColor,
	 fontSize: stl.smallFontSize,
	 fontWeight: FontWeight.normal,
      );

      return Column(children: <Widget>
      [ SizedBox(width: postInfoWidth, child: modelTitle)
      , Expanded(
	   child: SizedBox(
	      width: postInfoWidth,
	      child: Align(
		 alignment: Alignment.centerLeft,
		 child: detailsWrap,
	      ),
	   ),
	)
      , SizedBox(width: postInfoWidth, child: statsWdgs)
      ]);
   }

   @override
   Widget build(BuildContext ctx)
   {
      final double postAvatarImgWidth = makePostAvatarWidth(ctx);
      final double postAvatarImgHeight = postAvatarImgWidth;
      final double postAvatarInfoWidth = makePostInfoWidth(ctx);
      final double postAvatarInfoHeight = postAvatarImgHeight;

      double postImgWidth = postAvatarImgWidth;
      double postImgHeight = postAvatarImgHeight;
      double postInfoWidth = postAvatarInfoWidth;
      double postInfoHeight = postAvatarInfoHeight;

      if (widget.tab == cts.searchIdx) {
	 final double maxWidth = makeWidgetWidth(ctx);
	 postImgWidth = maxWidth;
	 postImgHeight = maxWidth / cts.goldenRatio;
	 postInfoWidth = maxWidth;
	 postInfoHeight = postImgHeight / cts.goldenRatio;
      }

      List<Widget> row1List = List<Widget>();

      Widget imgWdg = makeImgWdg(postImgWidth, postImgHeight);
      row1List.add(imgWdg);

      Widget infoWdg = makeInfoWdg(postInfoWidth);
      row1List.add(SizedBox(height: postInfoHeight, child: infoWdg));

      Widget child;
      if (widget.tab == cts.searchIdx) {
	 child = Column(children: row1List);
      } else {
	 child = Row(children: row1List);
      }

      return Padding(
	 padding: EdgeInsets.all(stl.basePadding),
         child: RaisedButton(
	    color: stl.cs.surface,
	    onPressed: () {_onShowDetails(ctx);},
	    child: child,
	    padding: const EdgeInsets.all(0),
	    onLongPress: widget.onDelPost,
	 ),
      );
   }
}

Widget makePostDetailsWdg({
   BuildContext ctx,
   final Post post,
   final Node locRootNode,
   final Node prodRootNode,
   final Node exDetailsRootNode,
   final Node inDetailsRootNode,
   final List<List<int>> images,
   final OnPressedF01 onDelImg,
   final OnPressedF01 onExpandImg,
   final OnPressedF00 onReportPost,
}) {
   List<Widget> rows = <Widget>[];

   final double imgWidth = makeWidgetWidth(ctx);
   Widget listView = makeImgListView(
      ctx: ctx,
      width: imgWidth,
      height: imgWidth,
      //height: makeImgHeight(ctx),
      post: post,
      boxFit: BoxFit.cover,
      images: images,
      onExpandImg: (int j){ onExpandImg(j); },
      onDelImg: onDelImg,
   );

   rows.add(listView);

   Widget statW = makeStatsText(
      key: g.param.statsTitleAndFields[2],
      value: '${post.visualizations}',
   );

   Widget stats = putPostElemOnCard(
      padding: stl.basePadding,
      backgroundColor: stl.secondaryLightColor,
      margin: 0,
      list: <Widget>
      [ Padding(
	   padding: const EdgeInsets.all(stl.basePadding),
	   child: Row(
	      mainAxisAlignment: MainAxisAlignment.start,
	      children: <Widget>[statW],
	   ),
        ),
      ],
   );

   rows.add(stats);

   List<Widget> tmp = assemblePostRows(
      ctx: ctx,
      post: post,
      locRootNode: locRootNode,
      prodRootNode: prodRootNode,
      exDetailsRootNode: exDetailsRootNode,
      inDetailsRootNode: inDetailsRootNode,
   );

   rows.add(putPostElemOnCard(list: tmp));

   //--------------------------------------------------------------------------

   return putPostElemOnCard(
      list: rows,
      margin: 0,
   );
}

Widget makeDefaultTextWidget({
   String text,
   Color color = stl.primaryTextColor,
   FontWeight fontWeight = FontWeight.normal,
   FontStyle fontStyle = FontStyle.normal,
}) {
   return Text(text,
      textAlign: TextAlign.start,
      style: TextStyle(
	 fontSize: stl.largeFontSize,
	 color: color,
	 fontWeight: fontWeight,
	 fontStyle: fontStyle,
      ),
   );
}

Column makeCol(List<Widget> list)
{
   return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: list,
   );
}

Widget makeDefaultWidgetCard({
   bool isWide,
   double width = stl.buttonMinWidth,
   String buttonName,
   String description,
   String testimonial,
   final OnPressedF00 onPressed,
})
{
   const double padding = 15;
   const double sep = 20;

   Widget testmonialW = Padding(
	 padding: const EdgeInsets.only(bottom: sep),
	 child: makeDefaultTextWidget(
	    text: testimonial,
	    color: stl.testimonialColor,
	    fontWeight: FontWeight.w500,
	    fontStyle: FontStyle.italic,
      ),
   );

   Widget descriptionW = makeDefaultTextWidget(text: description);

   Widget button = ButtonTheme(
      child: RaisedButton(
	 child: makeDefaultTextWidget(
	    text: buttonName,
	    color: stl.secondaryTextColor,
	    fontWeight: FontWeight.normal,
	 ),
	 color: stl.secondaryColor,
	 onPressed: onPressed,
      ),
   );

   Widget a = makeCol(<Widget>[testmonialW, descriptionW]);

   Widget b = Padding(
      padding: EdgeInsets.only(top: sep),
      child: button,
   );

   Widget card = ConstrainedBox(
      constraints: BoxConstraints(
	 //minHeight: 0,
	 maxWidth: 350,
      ),
      child: Card(
	 color: stl.cs.primary,
	 margin: EdgeInsets.only(top: padding, bottom: 0, left: padding, right: padding),
	 elevation: 0,
	 child: Padding(
	    padding: EdgeInsets.all(padding),
	    child: Column(
	       mainAxisAlignment: MainAxisAlignment.center,
	       crossAxisAlignment: CrossAxisAlignment.center,
	       mainAxisSize: MainAxisSize.min,
	       children: <Widget>[a, b],
	    ),
	 ),
      ),
   );

   return Center(
      child: card,
   );
}

Widget makeSearchInitTab({
   final bool isWide,
   final List<String> msgs,
   final List<String> buttonNames,
   final List<String> testimonials,
   final OnPressedF00 onCreateAd,
   final OnPressedF00 onGoToSearch,
   final OnPressedF00 onLastestPostsPressed,
}) {
   if (isWide) {
      return makeDefaultWidgetCard(
	 isWide: isWide,
	 description: msgs[cts.searchIdx],
	 buttonName: buttonNames[cts.searchIdx],
	 testimonial: '\"${testimonials[cts.searchIdx]}\"',
	 onPressed: onLastestPostsPressed,
      );
   }

   Widget w0 = makeDefaultWidgetCard(
      isWide: isWide,
      description: msgs[cts.ownIdx],
      buttonName: buttonNames[cts.ownIdx],
      testimonial: '\"${testimonials[cts.ownIdx]}\"',
      onPressed: onCreateAd,
   );

   // Removes this to make less text.
   //Widget w1 = makeDefaultWidgetCard(
   //   isWide: isWide,
   //   description: msgs[cts.searchIdx],
   //   buttonName: buttonNames[cts.searchIdx],
   //   testimonial: '\"${testimonials[cts.searchIdx]}\"',
   //   onPressed: onLastestPostsPressed,
   //);

   Widget w2 = makeDefaultWidgetCard(
      isWide: isWide,
      description: msgs[cts.favIdx],
      buttonName: buttonNames[cts.favIdx],
      testimonial: '\"${testimonials[cts.favIdx]}\"',
      onPressed: onGoToSearch,
   );

   return ListView(
      children: <Widget>[w0, w2],
   );
}

Widget makeSearchResultPosts({
   final bool isWide,
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
   final OnPressedF09 onPostPressed,
   final OnPressedF00 onCreateAd,
   final OnPressedF00 onGoToSearch,
   final OnPressedF00 onLatestPostsPressed,
}) {
   if (posts.isEmpty)
      return makeSearchInitTab(
	 isWide: isWide,
	 msgs: g.param.msgOnEmptyTab,
	 buttonNames: g.param.buttonNamesOnEmptyTab,
	 testimonials: g.param.testimonials,
	 onCreateAd: isWide ? null : onCreateAd,
	 onGoToSearch: onGoToSearch,
	 onLastestPostsPressed: onLatestPostsPressed,
      );

   // No controller should be assigned to this listview. This will break the
   // automatic hiding of the tabbar
   return ListView.builder(
      //key: PageStorageKey<String>('aaaaaaa'),
      itemCount: posts.length,
      //separatorBuilder: (BuildContext context, int index)
      //{
      //   return Divider(color: Colors.black, height: stl.basePadding);
      //},
      itemBuilder: (BuildContext ctx, int i)
      {
	 return PostWidget(
	    tab: cts.searchIdx,
	    post: posts[i],
	    exDetailsRootNode: exDetailsRootNode,
	    inDetailsRootNode: inDetailsRootNode,
	    locRootNode: locRootNode,
	    prodRootNode: prodRootNode,
	    onAddImg: () {debugPrint('Error: Please fix.');},
	    onDelImg: (int i) {debugPrint('Error: Please fix.');},
	    onExpandImg: (int k) {onExpandImg(i, k);},
	    onAddPostToFavorite: () {onAddPostToFavorite(ctx, i);},
	    onDelPost: () {onDelPost(ctx, i);},
	    onSharePost: () {onSharePost(ctx, i);},
	    onReportPost: () {onReportPost(ctx, i);},
	    onPinPost: (){debugPrint('Noop20');},
	    onVisualization: () {onPostPressed(posts[i].id);},
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
	 title: Text(
	    child.name(g.param.langIdx),
	    //style: stl.ltTitleSty,
	 ),
	 onTap: onLeafPressed,
	 enabled: true,
	 onLongPress: (){},
      );
   }
   
   return ListTile(
      title: Text(
	 child.name(g.param.langIdx),
	 style: stl.ltTitleSty,
      ),
      subtitle: Text(
	 child.getChildrenNames(g.param.langIdx, 4),
	 maxLines: 1,
	 overflow: TextOverflow.ellipsis,
	 style: stl.ltSubtitleSty,
      ),
      trailing: Icon(Icons.keyboard_arrow_right, color: stl.cs.primary),
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
      Widget o =  makeNewPostTreeWdg(
	 child: node.children[i],
	 onLeafPressed: () {onLeafPressed(i);},
	 onNodePressed: () {onNodePressed(i);},
      );
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
   ChatPresenceSubtitle(
   { this.subtitle = ''
   , this.color = stl.secondaryDarkColor,
   });
}

ChatPresenceSubtitle makeLTPresenceSubtitle({
   final ChatMetadata chatMetaData,
   String text,
   Color color,
}) {
   final int now = DateTime.now().millisecondsSinceEpoch;
   final int last = chatMetaData.lastPresenceReceived + cts.presenceInterval;

   final bool moreRecent = chatMetaData.lastPresenceReceived >
	 chatMetaData.getLastChatMsgDate();

   if (moreRecent && now < last) {
      return ChatPresenceSubtitle(
         subtitle: g.param.typing,
         color: stl.cs.onSecondary,
      );
   }

   return ChatPresenceSubtitle(
      subtitle: text,
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
         style: stl.ltSubtitleSty.copyWith(
            fontStyle: FontStyle.italic,
         ),
      );
   }

   ChatPresenceSubtitle cps = makeLTPresenceSubtitle(
      chatMetaData: ch,
      text: str,
      color: stl.secondaryDarkColor,
   );

   if (ch.nUnreadMsgs > 0 || !ch.isLastChatMsgFromThisApp())
      return Text(
         cps.subtitle,
	 //style: stl.ltSubtitleSty,
         maxLines: 1,
         overflow: TextOverflow.ellipsis
      );

   return Row(children: <Widget>
   [ chooseMsgStatusIcon(ch.getLastChatMsgStatus())
   , Expanded(
        child: Text(cps.subtitle,
           maxLines: 1,
           overflow: TextOverflow.ellipsis,
	   //style: stl.ltSubtitleSty,
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

String makeDateString3(int date)
{
   date *= 1000;
   DateTime dateObj = DateTime.fromMillisecondsSinceEpoch(date);
   DateFormat format = Intl(g.param.localeName).date().add_yMEd();
   return format.format(dateObj);
}

String makeDateString4(int date)
{
   date *= 1000;
   DateTime dateObj = DateTime.fromMillisecondsSinceEpoch(date);
   DateFormat format = Intl(g.param.localeName).date().add_m().add_y();
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
          unread: nUnreadMsgs,
          backgroundColor: stl.cs.secondary,
          textColor: stl.cs.onSecondary,
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
             unread: nUnreadMsgs,
             backgroundColor: stl.cs.secondary,
             textColor: stl.cs.onSecondary,
           )
         ]);
   }

   return dateText;
}

Color selectColor(String peer)
{
   final int v = peer.hashCode % 14;
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
   ChatMetadata chatMetadata,
   int now = 0,
   bool isFwdChatMsgs = false,
   String avatarUrl = '',
   double padding = stl.basePadding,
   OnPressedF00 onChatLeadingPressed,
   OnPressedF00 onChatLongPressed,
   OnPressedF00 onStartChatPressed,
}) {
   Color bgColor = stl.cs.surface;
   if (chatMetadata.isLongPressed)
      bgColor = stl.chatLongPressedColor;

   Widget trailing = makeChatListTileTrailingWidget(
      ctx,
      chatMetadata.nUnreadMsgs,
      chatMetadata.getLastChatMsgDate(),
      chatMetadata.pinDate,
      now,
      isFwdChatMsgs
   );

   ListTile lt =  ListTile(
      enabled: true,
      trailing: trailing,
      onTap: onStartChatPressed,
      onLongPress: onChatLongPressed,
      subtitle: makeChatTileSubtitle(ctx, chatMetadata),
      leading: makeChatListTileLeading(
         isLongPressed: chatMetadata.isLongPressed,
         avatarUrl: avatarUrl,
         nick: chatMetadata.nick,
         bgcolor: selectColor(chatMetadata.peer),
         onLeadingPressed: onChatLeadingPressed,
      ),
      title: Text(chatMetadata.getChatDisplayName(),
         maxLines: 1,
         overflow: TextOverflow.ellipsis,
      ),
   );

   return Card(
      child: lt,
      color: bgColor,
      margin: EdgeInsets.all(0),
   );
}

Widget makeChatsExp({
   BuildContext ctx,
   bool isFav,
   bool isFwdChatMsgs,
   int now,
   Post post,
   List<ChatMetadata> chatItem,
   OnPressedF01 onPressed,
   OnPressedF01 onLongPressed,
   OnPressedF16 onLeadingPressed,
}) {
   List<Widget> list = List<Widget>(chatItem.length);

   int nUnreadChats = 0;
   for (int i = 0; i < list.length; ++i) {
      final int n = chatItem[i].nUnreadMsgs;
      if (n > 0)
         ++nUnreadChats;

      String avatarUrl;
      if (isFav) {
	 if (post.images.isEmpty) {
	    // Shouldn't happen in production as all posts will be
	    // required to have an image. In the tests we have to
	    // handle it.
	    avatarUrl = '';
	 } else {
	    // There is only one chat in the ListTile in the fav
	    // screen. To avoid using the same image as the post
	    // avatar we use here the last post image.
	    avatarUrl = post.images.last;
	    //avatarUrl = '';
	 }
      } else {
	 avatarUrl = '';
      }

      list[i] = Padding(
         padding: const EdgeInsets.all(stl.basePadding),
         child: makeChatListTile(
	    ctx: ctx,
	    chatMetadata: chatItem[i],
	    now: now,
	    isFwdChatMsgs: isFwdChatMsgs,
	    avatarUrl: avatarUrl,
	    padding: 0,
	    onChatLeadingPressed: (){onLeadingPressed(post.id, i);},
	    onChatLongPressed: () { onLongPressed(i); },
	    onStartChatPressed: () { onPressed(i); },
         ),
      );
   }

  //if (chatItem.length < 5) {
  if (true)
     return Column(children: list);

  Widget title;
   if (nUnreadChats == 0) {
      title = Text('${chatItem.length} ${g.param.numberOfChatsSuffix}');
   } else {
      title = makeExpTileTitle(
         '${chatItem.length} ${g.param.numberOfChatsSuffix}',
         '$nUnreadChats ${g.param.numberOfUnreadChatsSuffix}',
         ', ',
         false,
      );
   }

   bool expState =
      (chatItem.length < 6 && chatItem.length > 0) || nUnreadChats != 0;

   // I have observed that if the post has no chats and a chat
   // arrives, the chat expansion will continue collapsed independent
   // whether expState is true or not. This is undesireble, so I will
   // add a special case to handle it below.
   if (nUnreadChats == 0)
      expState = true;

   return Theme(
      data: makeExpTileThemeData(),
      child: ExpansionTile(
         //backgroundColor: stl.backgroundColor,
         initiallyExpanded: expState,
         leading: stl.favIcon,
         //key: GlobalKey(),
         //key: PageStorageKey<int>(post.id),
         title: title,
         children: list,
      ),
   );
}

Widget makeTabDefaultWidget({
   final bool isWide,
   final int tab,
   final OnPressedF00 onCreateAd,
   final OnPressedF00 onGoToSearch,
   final OnPressedF00 onLatestPostsPressed,
}) {
   if (isWide) {
      if (tab == cts.ownIdx)
	 return makeDefaultWidgetCard(
	    isWide: isWide,
	    description: g.param.msgOnEmptyTab[cts.ownIdx],
	    buttonName: g.param.buttonNamesOnEmptyTab[cts.ownIdx],
	    testimonial: '\"${g.param.testimonials[cts.ownIdx]}\"',
	    onPressed: onCreateAd,
	 );

      if (tab == cts.favIdx)
	 return makeDefaultWidgetCard(
	    isWide: isWide,
	    description: g.param.msgOnEmptyTab[cts.favIdx],
	    buttonName: g.param.buttonNamesOnEmptyTab[cts.favIdx],
	    testimonial: '\"${g.param.testimonials[cts.favIdx]}\"',
	    onPressed: onGoToSearch,
	 );
   } else {
      return makeSearchInitTab(
	 isWide: isWide,
	 msgs: g.param.msgOnEmptyTab,
	 buttonNames: g.param.buttonNamesOnEmptyTab,
	 testimonials: g.param.testimonials,
	 onCreateAd: onCreateAd,
	 onGoToSearch: onGoToSearch,
	 onLastestPostsPressed: onLatestPostsPressed,
      );
   }
}

Widget makeChatTab({
   final bool isWide,
   final bool isFwdChatMsgs,
   final int tab,
   final Node locRootNode,
   final Node prodRootNode,
   final Node exDetailsRootNode,
   final Node inDetailsRootNode,
   final List<Post> posts,
   final OnPressedF03 onChatPressed,
   final OnPressedF03 onChatLongPressed,
   final OnPressedF01 onDelPost,
   final OnPressedF01 onPinPost,
         OnPressedF05 onUserInfoPressed,
   final OnPressedF03 onExpandImg,
   final OnPressedF01 onSharePost,
   final OnPressedF00 onCreateAd,
   final OnPressedF00 onGoToSearch,
   final OnPressedF00 onLatestPostsPressed,
}) {
   if (posts.isEmpty)
      return makeTabDefaultWidget(
	 isWide: isWide,
	 tab: tab,
	 onCreateAd: onCreateAd,
	 onGoToSearch: onGoToSearch,
	 onLatestPostsPressed: onLatestPostsPressed,
      );

   // No controller should be assigned to this listview. This will
   // break the automatic hiding of the tabbar
   return ListView.builder(
      itemCount: posts.length,
      itemBuilder: (BuildContext ctx, int i)
      {
         OnPressedF00 onPinPost2 = () {onPinPost(i);};
         OnPressedF00 onDelPost2 = () {onDelPost(i);};
         OnPressedF01 onExpandImg2 = (int j) {onExpandImg(i, j);};

         if (isFwdChatMsgs) {
            onUserInfoPressed = (var a, var b, var c){};
            onPinPost2 = (){};
            onDelPost2 = (){};
         }

         Widget title = Text(makeTreeItemStr(locRootNode, posts[i].location),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
         );

         // If the post contains no images, which should not happen,
         // we provide no expand image button.
         if (posts[i].images.isEmpty)
            onExpandImg2 = (int j){debugPrint('Error: post.images is empty.');};

	 Widget postBox = PostWidget(
	    tab: tab,
	    post: posts[i],
	    locRootNode: locRootNode,
	    prodRootNode: prodRootNode,
	    exDetailsRootNode: exDetailsRootNode,
	    inDetailsRootNode: inDetailsRootNode,
	    images: null,
	    onAddImg: () {debugPrint('Noop10');},
	    onDelImg: (int i) {debugPrint('Noop10');},
	    onExpandImg: onExpandImg2,
	    onAddPostToFavorite:() {debugPrint('Noop14');},
	    onDelPost: onDelPost2,
	    onSharePost: () {onSharePost(i);},
	    onReportPost:() {debugPrint('Noop18');},
	    onPinPost: onPinPost2,
	    onVisualization: () {debugPrint('Noop19');},
	 );

	 Widget chatExp = makeChatsExp(
	    ctx: ctx,
	    isFav: tab == cts.favIdx,
	    isFwdChatMsgs: isFwdChatMsgs,
	    now: DateTime.now().millisecondsSinceEpoch,
	    post: posts[i],
	    chatItem: posts[i].chats,
	    onPressed: (int j) {onChatPressed(i, j);},
	    onLongPressed: (int j) {onChatLongPressed(i, j);},
	    onLeadingPressed: (String a, int b) {onUserInfoPressed(ctx, a, b);},
	 );

	 return Padding(
	    padding: const EdgeInsets.symmetric(vertical: stl.basePadding),
	    child: Column(children: <Widget> [postBox, chatExp])
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
            style: TextStyle(
	       color: stl.cs.primary,
	       fontSize: stl.mainFontSize,
	    ),
         ),
         onPressed: () async
         {
            await widget.onPostSelection();
            Navigator.of(ctx).pop();
         },
      );

      final SimpleDialogOption cancel = SimpleDialogOption(
         child: Text(g.param.cancel,
            style: TextStyle(
	       color: stl.cs.primary,
	       fontSize: stl.mainFontSize,
	    ),
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
         title: Text(g.param.doNotShowAgain,
	    //style: stl.ltTitleSty,
	 ),
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
                    style: TextStyle(fontSize: stl.mainFontSize),
                 ),
              ),
           )
         , tile
         , Padding(
	       child: Row(children: actions),
	       padding: EdgeInsets.only(left: 70.0),
	   )
         ]);
   }
}

//_____________________________________________________________________

class Occase extends StatefulWidget {
   Node locRootNode = Node('');
   Node prodRootNode = Node('');
   Node exDetailsRoot = Node('');
   Node inDetailsRoot = Node('');

  Occase({
     @required this.locRootNode,
     @required this.prodRootNode,
     @required this.exDetailsRoot,
     @required this.inDetailsRoot,
  });

  @override
  OccaseState createState() => OccaseState();
}

class OccaseState extends State<Occase>
   with SingleTickerProviderStateMixin, WidgetsBindingObserver
{
   AppState _appState;

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

   // This list will store the posts in _fav or _own chat screens that
   // have been long pressed by the user. However, once one post is
   // long pressed to select the others is enough to perform a simple
   // click.
   List<List<Coord>> _lpChats = List<List<Coord>>(3);

   // A temporary variable used to store forwarded chat messages.
   List<List<Coord>> _lpChatMsgs = List<List<Coord>>(3);

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

   List<FocusNode> _chatFocusNodes = List<FocusNode>.filled(3, FocusNode());

   HtmlWebSocketChannel _websocket;
   //IOWebSocketChannel _websocket;

   // This variable is set to the last time the app was disconnected
   // from the server, a value of -1 means we are connected.
   int _lastDisconnect = -1;

   // The number of posts that match the search criteria.
   String _numberOfMatchingPosts = '';

   // Used in the final new post screen to store the files while the
   // user chooses the images.
   List<List<int>> _images = List<List<int>>();

   // These indexes will be set to values different from -1 when the
   // user clics on an image to expand it.
   List<int> _expPostIdxs = List<int>.filled(3, -1);
   List<int> _expImgIdxs = List<int>.filled(3, -1);

   // Used to cache the fcm token.
   String _fcmToken = '';

   final ImagePicker _picker = ImagePicker();

   @override
   void initState()
   {
      super.initState();

      _tabCtrl = TabController(vsync: this, initialIndex: 1, length: 3);
      _txtCtrl = TextEditingController();
      _tabCtrl.addListener(_tabCtrlChangeHandler);

      _chatScrollCtrl[cts.ownIdx].addListener(() {_chatScrollListener(cts.ownIdx);});
      _chatScrollCtrl[cts.favIdx].addListener(() {_chatScrollListener(cts.favIdx);});

      Timer.periodic(Duration(seconds: cts.pongTimeoutSeconds), _reconnectCallback);
      _lpChats[0] = List<Coord>();
      _lpChats[1] = List<Coord>();
      _lpChats[2] = List<Coord>();

      _lpChatMsgs[0] = List<Coord>();
      _lpChatMsgs[1] = List<Coord>();
      _lpChatMsgs[2] = List<Coord>();

      WidgetsBinding.instance.addObserver(this);

      _appState = AppState(_onCrossTabWrite);

      FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage message)
      {
	 if (message != null)
	    debugPrint('Firebase: Initial message received');
      });

      FirebaseMessaging.onMessage.listen((RemoteMessage message)
      {
	 RemoteNotification notification = message.notification;
         //print('Message ID ${message.messageId}');
         //print('Sender ID ${message.senderId}');
         //print('Category ${message.category}');
         //print('Collapse Key ${message.collapseKey}');
         //print('Content Available ${message.contentAvailable.toString()}');
         //print('Data ${message.data.toString()}');
         //print('From ${message.from}');
         //print('Message ID ${message.messageId}');
         //print('Sent Time ${message.sentTime?.toString()}');
         //print('Thread ID ${message.threadId}');
         //print('Time to Live (TTL) ${message.ttl?.toString()}');

         if (notification != null) {
	    print('Title ${notification.title}');
	    print('Body ${notification.body}');
	 }
      });

      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
	 print('A new onMessageOpenedApp event was published!');
      });

      WidgetsBinding.instance.addPostFrameCallback((_) async { _init(); });
   }

   Future<void> _onCrossTabWrite(MessageEvent) async
   {
      await _appState.load();
      setState((){});
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
         debugPrint('Trying to reconnect.');
         _stablishNewConnection(_fcmToken);
      }
   }

   Future<void> _initTrees() async
   {
      final bool a = widget.locRootNode.children.isNotEmpty;
      final bool b = widget.prodRootNode.children.isNotEmpty;
      final bool c = widget.exDetailsRoot.children.isNotEmpty;
      final bool d = widget.inDetailsRoot.children.isNotEmpty;

      if (a || b || c || d)
	 return;

      final String configTree = await rootBundle.loadString('data/config.comp.tree.txt');
      Node node = parseTree(configTree.split('\n'));
      assert(node.children.length == 4);

      widget.locRootNode = node.children[0];
      widget.prodRootNode = node.children[1];
      widget.exDetailsRoot = node.children[2];
      widget.inDetailsRoot = node.children[3];
   }

   void _onFcmToken(final String token)
   {
      if (token != null)
	 _fcmToken = token; 

      debugPrint('FB token: $_fcmToken');

      if (_appState.cfg.user.isEmpty) {
	 // This condition will hold only once.
	 http.post(Uri.parse(cts.dbGetIdUrl)).then(_setCred);
      } else {
	 // Stablishes the web socket connection regardless of whether
	 // a token is available. In the future we may want to delay
	 // the connection until the user clicks on the chat. This is
	 // important to avoid battery and bandwidth consumption.
         _stablishNewConnection(_fcmToken);
      }

   }

   Future<void> _setCred(final http.Response resp) async
   {
      if (resp.statusCode == 200) {
	 assert(resp.body != null);
	 Map<String, dynamic> map = jsonDecode(resp.body);

	 final String result = map["result"] ?? 'fail';
	 if (result == 'ok') {
	    await _appState.setCredentials(
	       map["user"] ?? '',
	       map["key"] ?? '',
	       map["user_id"] ?? '',
	    );

	    _stablishNewConnection(_fcmToken);

	 } else {
	    // We have to deal with this error.
	    debugPrint('_init(): result != ok');
	 }
      } else {
	 // We have to deal with this error.
	 debugPrint('_init(): /get-user-id:  ${resp.statusCode}');
      }
   }

   Future<void> _init() async
   {
      final String text = await rootBundle.loadString('data/parameters.txt');
      g.param = Parameters.fromJson(jsonDecode(text));
      await initializeDateFormatting(g.param.localeName, null);

      await _appState.load();

      prepareNewPost(cts.ownIdx);
      prepareNewPost(cts.searchIdx);

      FirebaseMessaging.instance.getToken().then(_onFcmToken);

      // Do not await for the async op to complete to avoid blocking
      // the init and consequently the page loading time.
      _loadMatchingPostsCounter();

      // In wide mode we want to show some posts when the user opens
      // the webpage. We cannot however await here, we just launch the
      // async operation whithout waiting for it to complete.
      //_searchImpl(Post(rangesMinMax: g.param.rangesMinMax));

      if (_appState.favPosts.isNotEmpty || _appState.ownPosts.isNotEmpty)
	 await _initTrees();

      setState(() { });
   }

   @override
   void dispose()
   {
      _txtCtrl.dispose();
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
      if (state == AppLifecycleState.resumed) {
	 setState((){print('Trying to reconnect.');});
      }
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

   bool _isOnFavChat(int tab)
   {
      return tab == cts.favIdx && _posts[cts.favIdx] != null && _chats[cts.favIdx] != null;
   }

   bool _isOnOwnChat(int tab)
   {
      return tab == cts.ownIdx && _posts[cts.ownIdx] != null && _chats[cts.ownIdx] != null;
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
	 _websocket = HtmlWebSocketChannel.connect(cts.dbWebsocketUrl);
	 //_websocket = IOWebSocketChannel.connect(cts.dbWebsocketUrl);
	 _websocket.stream.listen(
	    _onWSData,
	    onError: _onWSError,
	    onDone: _onWSDone,
	 );

	 final String cmd = jsonEncode(
	 { 'cmd': 'login'
	 , 'user': _appState.cfg.user
	 , 'key': _appState.cfg.key
	 , 'token': fcmToken
	 });

	 debugPrint(cmd);

	 _websocket.sink.add(cmd);
      } catch (e) {
	 debugPrint('Unable to stablish ws connection to server.');
	 debugPrint(e);
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
      // Added to stop showing the dialog when the user clicks to
      // start a chat with the car owner. This is the easy way of
      // doing it.
      if (j == 1)
	 _appState.cfg.dialogPreferences[j] = false;

      if (j == 1 && (_appState.cfg.nick == g.param.unknownNick)) {
	 final String result = await showDialog<String>(
	    barrierDismissible: false,
	    context: ctx,
	    builder: (BuildContext ctx2)
	    {
	       return TextInput(
		  title: g.param.changeNickHint,
		  description: '',
		  descriptionHint: g.param.unknownNick,
		  maxLength: 20,
	       );
	    },
	 );

	 if (result != null) {
	    _appState.cfg.nick = result;
	    await _appState.updateConfig();
	 }
      }

      if (!_appState.cfg.dialogPreferences[j]) {
         await _onPostSelection(i, j);
         return;
      }

      showDialog(
         context: ctx,
         builder: (BuildContext ctx)
         {
            Widget w = DialogWithOp(
               () {return _appState.cfg.dialogPreferences[j];},
               (bool v) async {await _setDialogPref(j, v);},
               () async {await _onPostSelection(i, j);},
               g.param.dialogTitles[j],
               g.param.dialogBodies[j],
	    );

	    return imposeWidth(
	       child: w,
	       width: makeWidgetWidth(ctx),
	    );
         },
      );
   }

   Future<void> _clearPosts() async
   {
      await _appState.clearPosts();
      setState((){ });
   }

   void _clearPostsDialog(BuildContext ctx)
   {
      _showSimpleDialog(
         ctx: ctx,
         onOk: () async { await _clearPosts(); },
         title: g.param.clearPostsTitle,
         content: Text(g.param.clearPostsContent),
      );
   }

   Future<void> _onAddImg() async
   {
      try {
	 // It looks like we don't need to show any dialog here to
	 // inform the maximum number of photos has been reached.
	 PickedFile img = await _picker.getImage(
	    source: ImageSource.gallery,
	 );

	 if (img == null)
	    return;

	 final List<int> bytes = await img.readAsBytes();

	 //imglib.Image rawImg = imglib.decodeImage(bytes);
	 //assert(rawImg != null);

	 //imglib.Image thumbnail = imglib.copyResize(
	 //   rawImg,
	 //   width: cts.minWidgetWidth.round(),
	 //);
	 //assert(thumbnail != null);

	 //setState((){_images.add(imglib.encodeJpg(thumbnail)); });
	 setState((){_images.add(bytes);});
      } catch (e) {
         debugPrint(e);
      }
   }

   void _onDelImg(int i)
   {
      setState((){_images.removeAt(i); });
   }

   // i = index in _appState.posts, _appState.favPosts, _own_posts.
   // j = image index in the post.
   void _onExpandImg(int i, int j, int tab)
   {
      //log('Expand image clicked with $i $j.');

      setState((){
         _expPostIdxs[tab] = i;
         _expImgIdxs[tab] = j;
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

   void _onSetPrice(String v, int tab, int i)
   {
      int value = _posts[tab].rangeValues[i];
      try {
	 value = int.parse(v);

	 setState(() {
	    _posts[tab].rangeValues[i] = value;
	 });
      } catch (e) {
	 print(e);
      }
   }

   Future<void> _onSetProdDate(DateTime picked, int tab) async
   {
      assert(picked != null);

      setState(() {
	 _posts[tab].date = (picked.toUtc().millisecondsSinceEpoch / 1000).round();
      });
   }

   void _onSetPostDescription(String description)
   {
      setState(() {
	 _posts[cts.ownIdx].description = description;
      });
   }

   void _onSetEmail(String email)
   {
      setState(() async {
	 _posts[cts.ownIdx].email = email;
	 _appState.cfg.email = email;
         await _appState.updateConfig();
      });
   }

   void _onSetNick(String nick)
   {
      setState(() async {
	 _posts[cts.ownIdx].nick = nick;
	 _appState.cfg.nick = nick;
         await _appState.updateConfig();
      });
   }

   void _onSetPostPriority(int prio)
   {
      setState(() {
	 _posts[cts.ownIdx].priority = prio;
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

      // We should be using the animate function below, but there is
      // no way one can wait until the animation is ready. The is
      // needed to be able to call _onChatPressed(i, 0) correctly. I
      // will let it commented out for now.

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
   // j = 4: Admin delete.
   Future<void> _onPostSelection(int i, int j) async
   {
      if (j == 3) {
         Share.share(g.param.share, subject: g.param.shareSubject);
         return;
      }

      if (j == 1) {
	 await _onMovePostToFav(i);
      } else if (j == 2) {
         // TODO: Send command to server to report.
      } else if (j == 4) {
	 await _onRemovePost(cts.searchIdx, i);
      }

      setState(() { });
   }

   void prepareNewPost(int i)
   {
      _posts[i] = Post(rangesMinMax: g.param.rangesMinMax);
      _posts[i].reset();
      if (i == cts.searchIdx) {
	 _posts[i].date = 0;
	 _posts[i].rangeValues[0] = 100000;
      }

      if (i == cts.ownIdx) {
	 _posts[i].date = 0;
	 _posts[i].rangeValues[0] = 3000;
      }
   }

   Future<void> _onCreateAd() async
   {
      await _initTrees();

      setState(() {
	 _newPostPressed = true;
	 prepareNewPost(cts.ownIdx);
      });

      // Needed only in the mobile view.
      _tabCtrl.animateTo(cts.ownIdx, duration: Duration(milliseconds: 700));
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
   Future<void> _onFwdSendButton(int tab) async
   {
      final int now = DateTime.now().millisecondsSinceEpoch;
      for (Coord c1 in _lpChats[tab]) {
         for (Coord c2 in _lpChatMsgs[tab]) {
            ChatItem ci = ChatItem(
               isRedirected: 1,
               body: c2.chat.msgs[c2.msgIdx].body,
               date: now,
            );

	    await _onSendChatImpl(
	       tab: tab,
	       postId: c1.post.id,
	       to: c1.chat.peer,
	       chatItem: ci,
	    );
         }
      }

      _lpChats[tab].forEach((e){toggleLPChat(e.chat);});
      _lpChatMsgs[tab].forEach((e){toggleLPChatMsg(e.chat.msgs[e.msgIdx]);});

      _posts[tab] = _lpChatMsgs[tab].first.post;
      _chats[tab] = _lpChatMsgs[tab].first.chat;

      _lpChats[tab].clear();
      _lpChatMsgs[tab].clear();

      setState((){});
   }

   Future<bool> _onPopChat(int tab) async
   {
      _chats[tab].nUnreadMsgs = 0;
      _chats[tab].divisorUnreadMsgs = 0;
      _chats[tab].divisorUnreadMsgsIdx = -1;

      await _appState.updateNUnreadMsgs(
	 isFav: tab == cts.favIdx,
	 postId: _posts[tab].id,
	 peer: _chats[tab].peer,
      );

      _newSearchPressed = false; // Needed only in wide mode.
      _showChatJumpDownButtons[tab] = false;
      _dragedIdxs[tab] = -1;
      _lpChatMsgs[tab].forEach((e){toggleLPChatMsg(_chats[tab].msgs[e.msgIdx]);});

      final bool isEmpty = _lpChatMsgs[tab].isEmpty;
      _lpChatMsgs[tab].clear();

      if (isEmpty) {
         _posts[tab] = null;
         _chats[tab] = null;
      }

      setState(() { });
      return false;
   }

   void _onCancelFwdLpChat(int i)
   {
      _dragedIdxs[i] = -1;
      setState(() { });
   }

   Future<void> _onSendChat(int tab) async
   {
      _chats[tab].nUnreadMsgs = 0;

      await _onSendChatImpl(
	 tab: tab,
         postId: _posts[tab].id,
         to: _chats[tab].peer,
         chatItem: ChatItem(
            isRedirected: 0,
            body: _txtCtrl.text,
            date: DateTime.now().millisecondsSinceEpoch,
            refersTo: _dragedIdxs[tab],
            status: 0,
         ),
      );

      _txtCtrl.clear();
      _dragedIdxs[tab] = -1;

      setState(()
      {
         SchedulerBinding.instance.addPostFrameCallback((_)
         {
            _chatScrollCtrl[tab].animateTo(
               _chatScrollCtrl[tab].position.maxScrollExtent,
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
      debugPrint(payload);
      _websocket.sink.add(payload);
   }

   void _chatScrollListener(int i)
   {
      if (i != _tabIndex()) {
	 // The control listener seems to be bound to all screens, thats why I
	 // have to filter it here.
	 debugPrint('Ignoring ---> $i');
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
      _posts[cts.ownIdx].from = '';
      if (_posts[cts.ownIdx].nick.isEmpty)
	 _posts[cts.ownIdx].nick = g.param.advertiser;

      _posts[cts.ownIdx].avatar = emailToGravatarHash(_appState.cfg.email);
      _posts[cts.ownIdx].status = 3;
      _appState.outPost = _posts[cts.ownIdx].clone();

      // We add it here in our own list of posts and keep in mind it may be
      // echoed back to us. It has to be filtered out from _appState.posts
      // since that list should not contain our own posts.

      var map =
      { 'cmd': 'publish'
      , 'user': _appState.cfg.user
      , 'key': _appState.cfg.key
      , 'post': _appState.outPost
      };

      //print(map);
      var resp = await http.post(Uri.parse(cts.dbPublishUrl),
	 body: jsonEncode(map),
      );

      debugPrint('Publish response status: ${resp.statusCode}');
      if (resp.statusCode != 200) {
	 // TODO: Show dialog.
	 debugPrint('Error on _sendPost:  ${resp.statusCode}');
	 setState(() {_newPostErrorCode = 0;});
	 return;
      }

      debugPrint('Publish response body:  ${resp.body}');
      Map<String, dynamic> respMap = jsonDecode(resp.body);
      final String result = respMap['result'] ?? 'fail';
      final String postId = respMap['id'] ?? '';
      final String adminId = respMap['admin_id'] ?? g.param.adminId;
      final int date = respMap['date'] ?? -1;

      int errorCode = 0;
      if (result == 'ok' && postId.isNotEmpty && date != -1) {
         await _appState.addOwnPost(postId, date);
	 await _onChatImpl(
	    to: _appState.cfg.userId,
	    postId: postId,
	    body: g.param.adminChatMsg,
	    peer: adminId,
	    nick: g.param.adminNick,
	    avatar: emailToGravatarHash(cts.occaseGravatarEmail),
	    posts: _appState.ownPosts,
	    isRedirected: 0,
	    refersTo: -1,
	    peerMsgId: 0,
	    isFav: false,
	 );

         final String payload = makeChatMsg(
	    to: adminId,
	    body: 'New post',
	    postId: postId,
	    id: -1,
	 );

         await _sendAppMsg(payload, 1);

	 errorCode = 1;
      }

      setState(() {
	 debugPrint('Setting error code:  ${errorCode}');
	 _newPostErrorCode = errorCode;
      });
   }

   Future<void> _deletePostFromServer(Post post) async
   {
      var map =
      { 'user': _appState.cfg.user
      , 'key': _appState.cfg.key
      , 'post_id': post.id
      , 'admin_delete_key': _deletePostPwd
      };

      var resp = await http.post(Uri.parse(cts.dbDeletePostUrl),
	 body: jsonEncode(map),
      );

      if (resp.statusCode != 200)
	 debugPrint('Error on _onRemovePost:  ${resp.statusCode}');
   }

   Future<void> _onRemovePost(int tab, int i) async
   {
      if (tab == cts.favIdx) {
         await _appState.delFavPost(i);
      } else if (tab == cts.ownIdx) {
         final Post post = await _appState.delOwnPost(i);
	 await _deletePostFromServer(post);
      } else if (tab == cts.searchIdx) {
         final Post post = await _appState.delSearchPost(i);
	 await _deletePostFromServer(post);
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
      final int l2 = _images.length;

      final int l = l1 < l2 ? l1 : l2; // min

      for (int i = 0; i < l; ++i) {
         final String newname = fnames[i];
         debugPrint('Upload image target: $newname');
         var response = await http.post(Uri.parse(newname),
            body: _images[i],
         );
         final int stCode = response.statusCode;
         debugPrint('Upload response status: ${stCode}');
         if (stCode != 200) {
            _images = List<List<int>>();
            return 0;
         }

	 final int index = newname.indexOf('?');
	 final String url = newname.substring(0, index);
         debugPrint('Post url: ${url}');
         _posts[cts.ownIdx].images.add(url);
      }

      _images = List<List<int>>();
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

	 var body =
	 { 'user': _appState.cfg.user
	 , 'key': _appState.cfg.key
	 };

	 var resp = await http.post(Uri.parse(cts.dbUploadCreditUrl),
	    body: jsonEncode(body),
	 );

	 if (resp.statusCode != 200) {
	    debugPrint('Error: _requestFilenames ${resp.statusCode}');
	    setState(() { _leaveNewPostScreen(); });
	 }

	 if (resp.body.isEmpty) {
	    _leaveNewPostScreen();
	    _newPostErrorCode = 0;
	    debugPrint('Error: _requestFilenames, empty body.');
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
         debugPrint('Error: _requestFilenames $e');
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
            ctx: ctx,
            onOk: (){
               _newPostPressed = false;
               _posts[cts.ownIdx] = null;
               setState((){});
            },
	    title: g.param.cancelPost,
            content: Text(g.param.cancelPostContent),
         );
         return;
      }

      if (_images.length < cts.minImgsPerPost) {
         _showSimpleDialog(
            ctx: ctx,
            onOk: (){ },
            title: g.param.postMinImgs,
            content: Text(g.param.postMinImgsContent),
         );
         return;
      }

      // Remove the two lines to add payment options again.
      await _requestFilenames();
      return;

      if (_posts[cts.ownIdx].priority == 0) {
	 await _requestFilenames();
      } else {
	 await showModalBottomSheet<void>(
	    context: ctx,
	    backgroundColor: Colors.white,
	    builder: (BuildContext ctx)
	    {
	       return makePaymentChoiceWidget(
		  onFreePaymentPressed: () async
		  {
		     Navigator.of(ctx).pop();
		     await _requestFilenames();
		  },
		  onStandardPaymentPressed: (){},
		  onPremiumPaymentPressed: (){},
	       );
	    },
	 );
      }
   }

   void _removePostDialog(BuildContext ctx, int tab, int i)
   {
      _showSimpleDialog(
         ctx: ctx,
         onOk: () async { await _onRemovePost(tab, i);},
         title: g.param.dialogTitles[4],
         content: Text(g.param.dialogBodies[4]),
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
            _chatScrollCtrl[tab]
		  .jumpTo(_chatScrollCtrl[tab]
			.position.maxScrollExtent);
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

   void _onUserInfoPressed(BuildContext ctx, String postId, int j, int tab)
   {
      List<Post> posts;
      bool isOnFav = tab == cts.favIdx;
      if (isOnFav) {
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
         isOnFav ? posts[i].avatar : posts[i].chats[j].avatar;

      final String url = cts.gravatarUrl + avatar + '.jpg';

      _showSimpleDialog(
         ctx: ctx,
         onOk: (){},
         title: title,
         content: makeNetImgBox(
            width: cts.onClickAvatarWidth,
            height: cts.onClickAvatarWidth,
            url: url,
         ),
      );
   }

   void _onChatLPImpl(List<Post> posts, int i, int j, int k)
   {
      handleLPChats(
         _lpChats[k],
         toggleLPChat(posts[i].chats[j]),
	 Coord(post: posts[i], chat: posts[i].chats[j]),
	 compPostIdAndPeer,
      );
   }

   void _onChatLongPressed(int tab, int j, int k)
   {
      if (tab == cts.favIdx) {
         _onChatLPImpl(_appState.favPosts, j, k, cts.favIdx);
      } else {
         _onChatLPImpl(_appState.ownPosts, j, k, cts.ownIdx);
      }

      setState(() { });
   }

   Future<void> _sendAppMsg(String payload, int isChat) async
   {
      print(payload);
      final String msg =
	 await _appState.addAppMsgToQueueAndGetNext(payload, isChat);
      if (msg.isNotEmpty)
         _websocket.sink.add(msg);
   }

   void _sendOfflineChatMsgs()
   {
      if (_appState.appMsgQueue.isNotEmpty)
         _websocket.sink.add(_appState.appMsgQueue.first.payload);
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

      handleLPChats(
	 _lpChatMsgs[i],
         toggleLPChatMsg(_chats[i].msgs[k]),
	 tmp,
	 compPeerAndChatIdx,
      );

      setState((){});
   }

   Future<void> _onSendChatImpl({
      int tab,
      String postId,
      String to,
      ChatItem chatItem,
   }) async {
      try {
	 if (chatItem.body.isEmpty)
	    return;

	 final int id = await _appState.addChatMessage(
	    postId: postId,
	    peer: to,
	    chatItem: chatItem,
	    isFav: tab == cts.favIdx,
	 );

         final String payload = makeChatMsg(
	    isRedirected: chatItem.isRedirected,
	    to: to,
	    body: chatItem.body,
	    refersTo: chatItem.refersTo,
	    postId: postId,
	    nick: _appState.cfg.nick,
	    id: id,
	    avatar: emailToGravatarHash(_appState.cfg.email),
	 );

         await _sendAppMsg(payload, 1);

      } catch(e) {
         debugPrint(e);
      }
   }

   void _onPostVisualization(String postId)
   {
      try {
	 var map =
	 { 'cmd': 'visualization'
	 , 'post_id': postId
	 };

	 http.post(Uri.parse(cts.dbVisualizationUrl),
	    body: jsonEncode(map),
	 ).then((var response){
	    if (response.statusCode != 200)
	       print('Error: Unable to post visualization.');
	 });
      } catch (e) {
	 print(e);
      }
   }

   Future<void> _onChat({
      final String to,
      final String peer,
      final String postId,
      final String body,
      final String nick,
      final String avatar,
      final int refersTo,
      final int peerMsgId,
      final int isRedirected,
   }) async {
      if (to != _appState.cfg.userId) {
         debugPrint("Server bug caught. Please report.");
         return;
      }

      final int ownIdx = _appState.ownPosts.indexWhere((e) {
         return e.id == postId;
      });

      List<Post> posts;
      if (ownIdx != -1)
         posts = _appState.ownPosts;
      else
         posts = _appState.favPosts;

      await _onChatImpl(
         to: to,
         postId: postId,
         body: body,
         peer: peer,
         nick: nick,
         avatar: avatar,
         posts: posts,
         isRedirected: isRedirected,
         refersTo: refersTo,
         peerMsgId: peerMsgId,
	 isFav: ownIdx == -1,
      );
   }

   Future<void> _onChatImpl({
      bool isFav,
      int isRedirected,
      int refersTo,
      int peerMsgId,
      String to,
      String postId,
      String body,
      String peer,
      String nick,
      String avatar,
      List<Post> posts,
   }) async {
      int i = posts.indexWhere((e) { return e.id == postId;});
      if (i == -1) {
	 // We are receiving a message to a post we don't have. This
	 // can happen in the following situations
	 // 
	 //   1. this is an admin app, in which case the posts
	 //      parameter must be the fav posts.
	 //
	 //   2. a user deleter a post and receives a message for it.
	 //
	 // We want to deal only with 1. and will use that are
	 // available.

	 if (!isFav) {
	    debugPrint('Ignoring message to postId $postId.');
	    return;
	 }

	 // Later we may want to send a request to retrieve this post
	 // from the server. For now lets create an empty post with
	 // the right id.
	 Post post = Post(
	    id: postId,
	    from: peer,
	    rangesMinMax: g.param.rangesMinMax,
	 );

	 final int l = _appState.posts.length;
	 _appState.posts.add(post);
	 i = await _appState.movePostToFav(l);
      }

      final int j = posts[i].getChatHistIdxOrCreate(peer, nick, avatar);
      final int now = DateTime.now().millisecondsSinceEpoch;

      final ChatItem ci = ChatItem(
         isRedirected: isRedirected,
         body: body,
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

   void _onLoginAck({
      final String result,
   }) {
      // I still do not know how a failed login should be handled.
      // Perhaps send a new register command? It can only happen if
      // the server is blocking this user.
      if (result == 'fail') {
         debugPrint("login_ack: fail.");
         return;
      }

      _lastDisconnect = -1;

      // Sends any chat messages that may have been written while
      // the app were offline.
      _sendOfflineChatMsgs();
   }

   void _onSubscribeAck({
      final String result,
   }) {
      if (result == 'fail') {
         debugPrint("subscribe_ack: $result");
         return;
      }
   }

   int _onPosts(Map<String, dynamic> ack)
   {
      for (var item in ack['posts']) {
         try {
            Post post = Post.fromJson(item, g.param.rangeDivs.length);
            post.status = 1;
            _appState.posts.add(post);
         } catch (e) {
            debugPrint("Error: Invalid post detected.");
         }
      }
      
      setState(() {
	 _appState.posts.sort(compPostByDate);
      });

      return _appState.posts.length;
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
		     body: map['body'] ?? '',
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
		     _websocket.sink.add(_appState.appMsgQueue.first.payload);

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
	       _onPosts(map);
	    } else {
	       debugPrint('Unhandled message received from the server:\n$payload.');
	    }
	 } catch (e) {
	    print('Exception on _onWSDataImpl $e');
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

   void _showSimpleDialog({
      BuildContext ctx,
      Function onOk,
      String title,
      Widget content,
   }) {
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

            Widget w = AlertDialog(
               title: Text(title),
               content: content,
               actions: actions,
            );

	    return imposeWidth(
	       child: w,
	       width: makeWidgetWidth(ctx),
	    );
         },
      );
   }

   // The variable i can assume the following values
   // 0: Leaves the screen.
   //
   Future<void> _onSearch(bool isWide, int i) async
   {
      try {
	 if (!isWide)
	    setState(() {_newSearchPressed = false;});

	 if (i == 0) {
	    setState(() { });
	    return;
	 }

	 setState(() {
	    _searchBeginDate = DateTime.now().millisecondsSinceEpoch;
	 });

	 final int n = await _searchImpl(_posts[cts.searchIdx]);

	 setState(() {
	    if (n == 0)
	       _newSearchPressed = true;

	    _searchBeginDate = 0;
	 });
      } catch (e) {
	 debugPrint(e);
      }
   }

   // Called when the main tab changes.
   void _tabCtrlChangeHandler()
   {
      // This function is meant to change the tab widgets when we
      // switch tab. This is needed to show the number of unread
      // messages.
      setState(() { debugPrint('Tab changed');});
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

   bool _hasLPChats(int tab)
   {
      return _lpChats[tab].isNotEmpty;
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

   Future<void> _onGoToSearch() async
   {
      await _initTrees();

      _tabCtrl.animateTo(
	 cts.searchIdx,
	 duration: Duration(milliseconds: 700));

      setState(() {
	 prepareNewPost(cts.searchIdx);
	 _newSearchPressed = true;
      });
   }

   Future<void> _onLatestPostsPressed(bool isWide) async
   {
      await _initTrees();

      _tabCtrl.animateTo(
	 cts.searchIdx,
	 duration: Duration(milliseconds: 700));

      if (isWide)
	 _newSearchPressed = true;
      prepareNewPost(cts.searchIdx);
      _onSearch(isWide, 10);
      setState(() { });
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
	       child: Text(g.param.delChatTitle),
	       onPressed: () async
	       {
		  await _removeLPChats(i);
		  Navigator.of(ctx).pop();
	       },
	    );

            final FlatButton cancel = FlatButton(
               child: Text(g.param.delChatCancelStr),
               onPressed: () { Navigator.of(ctx).pop(); });

            List<FlatButton> actions = List<FlatButton>(2);
            actions[0] = cancel;
            actions[1] = ok;

            Text text = Text(g.param.delChatTitle);
            return AlertDialog(
	       title: text,
	       content: Text(""),
	       actions: actions,
	    );
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
               ctx: ctx,
               onOk: (){},
               title: g.param.onEmptyNickTitle,
               content: Text(g.param.onEmptyNickContent),
            );
            return;
         }

         _appState.cfg.nick = _txtCtrl.text;
         await _appState.updateConfig();

         setState(()
         {
            _txtCtrl.clear();
            _goToRegScreen = false;
         });

      } catch (e) {
         debugPrint(e);
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
	    builder: (BuildContext ctx2)
	       { return TextInput(description: ''); },
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
         debugPrint('Unable to send email.');
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
         debugPrint(e);
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

   Future<int> _searchImpl(Post post) async
   {
      try {
	 final String body = await searchPosts(cts.dbSearchPostsUrl, post);
	 if (body.isEmpty) {
	    print('Error: _searchImpl.');
	    return 0;
	 }

	 await _appState.clearPosts();
	 return _onPosts(jsonDecode(body));
      } catch (e) {
	 print('Error $e');
      }

      return 0;
   }

   void _loadMatchingPostsCounter()
   {
      searchPosts(cts.dbCountPostsUrl, _posts[cts.searchIdx])
      .then((String n){
	 setState((){_numberOfMatchingPosts = n;});
      });
   }

   void _onSetSearchLocationCode(List<int> code)
   {
      if (code.isEmpty)
	 return;

      _posts[cts.searchIdx].location = code;
      _loadMatchingPostsCounter();
   }

   void _onSetSearchProductCode(List<int> code)
   {
      if (code.isEmpty)
	 return;

      _posts[cts.searchIdx].product = code;
      _loadMatchingPostsCounter();
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
	 chatMetadata: _chats[tab],
	 editCtrl: _txtCtrl,
	 scrollCtrl: _chatScrollCtrl[tab],
	 nLongPressed: _lpChatMsgs[tab].length,
	 chatFocusNode: _chatFocusNodes[tab],
	 postSummary: makeTreeItemStr(widget.locRootNode, _posts[tab].product),
	 dragedIdx: _dragedIdxs[tab],
	 showChatJumpDownButton: _showChatJumpDownButtons[tab],
	 avatar: _isOnFavChat(tab) ? _posts[tab].avatar : _chats[tab].avatar,
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
	 locRootNode: widget.locRootNode,
	 prodRootNode: widget.prodRootNode,
	 exDetailsRootNode: widget.exDetailsRoot,
	 inDetailsRootNode: widget.inDetailsRoot,
	 post: _posts[cts.ownIdx],
	 onSetTreeCode: _onNewPostSetTreeCode,
	 onSetExDetail: _onSetExDetail,
	 onSetInDetail: _onSetInDetail,
	 images: _images,
	 onAddImg: _onAddImg,
	 onDelImg: _onDelImg,
	 onPublishPost: (var a) { _onSendNewPost(a, 1); },
	 onRemovePost: (var a) { _onSendNewPost(a, 0); },
	 onNewPostValueChanged: _onNewPostValueChanged,
	 onProdDateChanged: (var v) {_onSetProdDate(v, cts.ownIdx);},
	 onPriceChanged: (var price) {_onSetPrice(price, cts.ownIdx, 0);},
	 onKmChanged: (var km) {_onSetPrice(km, cts.ownIdx, 2);},
	 onSetPostDescription: _onSetPostDescription,
	 onSetEmail: _onSetEmail,
	 onSetNick: _onSetNick,
	 onFreePaymentPressed: () { _onSetPostPriority(0);},
	 onStandardPaymentPressed: () { _onSetPostPriority(1);},
	 onPremiumPaymentPressed: () { _onSetPostPriority(2);},
      );
   }

   Widget _makeSearchScreenWdg(BuildContext ctx)
   {
      final bool isWide = isWideScreen(ctx);
      return makeSearchScreenWdg(
	 ctx: ctx,
	 state: _posts[cts.searchIdx].exDetails[0],
	 numberOfMatchingPosts: _numberOfMatchingPosts,
	 locRootNode: widget.locRootNode,
	 prodRootNode: widget.prodRootNode,
	 exDetailsRootNode: widget.exDetailsRoot,
	 post: _posts[cts.searchIdx],
	 onSearchPressed: (int i) {_onSearch(isWide, i);},
	 onSearchDetail: (int j) {_onSearchDetail(0, j);},
	 onValueChanged: _onSearchValueChanged,
	 onSetLocationCode: _onSetSearchLocationCode,
	 onSetProductCode: _onSetSearchProductCode,
	 onSetProdDate: (var v) {_onSetProdDate(v, cts.searchIdx);},
	 onPriceChanged: (var price) {_onSetPrice(price, cts.searchIdx, 0);},
	 onKmChanged: (var km) {_onSetPrice(km, cts.searchIdx, 2);},
      );
   }

   Widget _makeSearchResultTab(BuildContext ctx)
   {
      final bool isWide = isWideScreen(ctx);
      Widget sb = makeSearchResultPosts(
	 isWide: isWide,
	 locRootNode: widget.locRootNode,
	 prodRootNode: widget.prodRootNode,
	 exDetailsRootNode: widget.exDetailsRoot,
	 inDetailsRootNode: widget.inDetailsRoot,
	 posts: _appState.posts,
	 onExpandImg: (int i, int j) {_onExpandImg(i, j, cts.searchIdx);},
	 onAddPostToFavorite: (var a, int j) {_alertUserOnPressed(a, j, 1);},
	 onDelPost: (var a, int j) {_alertUserOnPressed(a, j, 4);},
	 onSharePost: (var a, int j) {_alertUserOnPressed(a, j, 3);},
	 onReportPost: (var a, int j) {_alertUserOnPressed(a, j, 2);},
	 onPostPressed: _onPostVisualization,
	 onCreateAd: _onCreateAd,
	 onGoToSearch: _onGoToSearch,
	 onLatestPostsPressed: () {_onLatestPostsPressed(isWide);},
      );

      if (_searchBeginDate == 0)
	 return sb;

      ModalBarrier mb = ModalBarrier(
	 color: Colors.grey.withOpacity(0.4),
	 dismissible: false,
      );

      return Stack(children: <Widget>
      [ sb
      , mb
      , Center(child: CircularProgressIndicator())
      ]);
   }

   List<Widget> _makeFaButtons(BuildContext ctx)
   {
      return makeFaButtons(
	 isOnOwnChat: _isOnOwnChat(cts.ownIdx),
	 isWide: isWideScreen(ctx),
	 hasFavPosts: _appState.favPosts.isNotEmpty,
	 nOwnPosts: _appState.ownPosts.length,
	 newSearchPressed: _newSearchPressed,
	 lpChats: _lpChats,
	 lpChatMsgs: _lpChatMsgs,
	 onNewPost: _newPostPressed ? null : _onCreateAd,
	 onFwdSendButton: _onFwdSendButton,
	 onGoToSearch: _onGoToSearch,
	 nPosts: _appState.posts.length,
      );
   }

   Widget _makeChatTab(BuildContext ctx, int tab)
   {
      List<Post> posts = _appState.ownPosts;
      if (tab == cts.favIdx)
	 posts = _appState.favPosts;

      final bool isWide = isWideScreen(ctx);
      return makeChatTab(
	 isWide: isWide,
	 isFwdChatMsgs: _lpChatMsgs[tab].isNotEmpty,
	 tab: tab,
	 locRootNode: widget.locRootNode,
	 prodRootNode: widget.prodRootNode,
	 exDetailsRootNode: widget.exDetailsRoot,
	 inDetailsRootNode: widget.inDetailsRoot,
	 posts: posts,
	 onChatPressed: (int j, int k) {_onChatPressed(tab, j, k);},
	 onChatLongPressed: (int j, int k) {_onChatLongPressed(tab, j, k);},
	 onDelPost: (int j) { _removePostDialog(ctx, tab, j);},
	 onPinPost: (int j) {_onPinPost(tab, j);},
	 onUserInfoPressed: (var ctx, var str, int j) {_onUserInfoPressed(ctx, str, j, tab);},
	 onExpandImg: (int i, int j) {_onExpandImg(i, j, tab);},
	 onSharePost: (int tab) {_onClickOnPost(tab, 1);},
	 onCreateAd: _onCreateAd,
	 onGoToSearch: _onGoToSearch,
	 onLatestPostsPressed: () {_onLatestPostsPressed(isWide);},
      );
   }

   List<Widget> _makeTabActions(BuildContext ctx, int tab)
   {
      return makeTabActions(
         tab: tab,
	 newPostPressed: _newPostPressed,
	 hasLPChats: _hasLPChats(tab),
	 hasLPChatMsgs: _hasLPChatMsgs(tab),
	 deleteChatDialog: () {_deleteChatDialog(ctx, tab);},
	 pinChats: () {_pinChats(tab);},
	 onClearPostsDialog: () { _clearPostsDialog(ctx); },
      );
   }

   List<Widget> _makeGlobalActionsApp(BuildContext ctx, int tab)
   {
      // In the web version we do not need to hide anything if there are long
      // pressed chats.

      // We only add the global action buttons if
      // 1. There is no chat selected for selection.
      // 2. We are not forwarding a message.
      if (!_hasLPChats(tab) && !_hasLPChatMsgs(tab))
	 return <Widget>[makeAppBarVertAction(_onAppBarVertPressed)];

      return <Widget>[];
   }

   List<Widget> _makeGlobalActionsWeb(BuildContext ctx)
   {
      // In the web version we do not need to hide anything if there are long
      // pressed chats.
      return <Widget>[makeAppBarVertAction(_onAppBarVertPressed)];
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

      final bool emptyPosts = _appState.posts.isEmpty;
      final bool emptyFav = _appState.favPosts.isEmpty;

      if (_newSearchPressed && !isWide) {
	 ret[cts.searchIdx] = _makeSearchScreenWdg(ctx);
      } else {
	 ret[cts.searchIdx] = _makeSearchResultTab(ctx);
      }

      if (_newSearchPressed && isWide) {
	 ret[cts.favIdx] = _makeSearchScreenWdg(ctx);
      } else {
	 ret[cts.favIdx] = _makeChatTab(ctx, cts.favIdx);
      }

      return List<Widget>.generate(
	 ret.length,
	 (int i) { return imposeWidth(child: ret[i], width: makeWidgetWidth(ctx)); },
         growable: false,
      );
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
      Locale locale = Localizations.localeOf(ctx);
      g.param.setLang(locale.languageCode);

      if (_goToRegScreen) {
         return makeRegisterScreen(
            nickCtrl: _txtCtrl,
            onContinue: (){_onRegisterContinue(ctx);},
            title: g.param.changeNickAppBarTitle,
            previousNick: _appState.cfg.nick,
	    maxWidth: makeWidgetWidth(ctx),
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
            _showSimpleDialog(
	       ctx: ctx,
	       onOk: (){},
               title: title,
               content: Text(body)
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

         //return makeImgExpandScreen(
	 //   () { _onExpandImg(-1, -1, _tabIndex()); return false;},
	 //   post,
	 //);
      }

      List<Widget> fltButtons = _makeFaButtons(ctx);
      List<Widget> bodies = _makeAppBodies(ctx);
      List<int> newMsgCounters = _newMsgsCounters();

      final bool isWide = isWideScreen(ctx);
      if (isWide) {
	 const double sep = 3.0;
	 Divider div = Divider(
	    height: sep,
	    thickness: sep,
	    indent: 0.0,
	    color: stl.cs.background,
	 );

	 List<Widget> tabWdgs = makeTabWdgs(
	    counters: newMsgCounters,
	    opacities: const <double>[1, 1, 1],
	 );

	 Widget ownTmp;
	 if (_isOnOwnChat(cts.ownIdx)) {
	    ownTmp = Column(children: <Widget>
	    [ div
	    , Expanded(child: _makeChatScreen(ctx, cts.ownIdx))
	    , div
	    ]);
	 } else {
	    List<Widget> local = <Widget>[];
            local.add(div);

	    if (_newPostPressed || _appState.ownPosts.isNotEmpty) {
	       Widget ownTopBar = AppBar(
		  actions: _makeTabActions(ctx, cts.ownIdx),
		  leading: _makeAppBarLeading(isWide, cts.ownIdx),
		  title: _makeAppBarTitleWdg(isWide, cts.ownIdx, tabWdgs[cts.ownIdx]),
		  backgroundColor: stl.cs.primary,
		  primary: false,
	       );
	       local.add(ownTopBar);
	    }

            local.add(Expanded(child: bodies[cts.ownIdx]));
            local.add(div);

	    ownTmp = Column(children: local);
	 }

	 Widget own = imposeWidth(
	    child: ownTmp,
	    width: makeWidgetWidth(ctx),
	 );

	 Widget search = Column(
	    children: <Widget>
	    [ div
	    , Expanded(child: bodies[cts.searchIdx])
	    , div
	    ]
	 );

         Widget favTmp;
	 if (_isOnFavChat(cts.favIdx)) {
	    favTmp = Column(children: <Widget>
	    [ div
	    , Expanded(child: _makeChatScreen(ctx, cts.favIdx))
	    , div
	    ]);
	 } else {
	    List<Widget> local = <Widget>[];
            local.add(div);

	    if (_newSearchPressed || _appState.favPosts.isNotEmpty) {
	       Widget favTopBar = AppBar(
		  actions: _makeTabActions(ctx, cts.favIdx),
		  title: _makeAppBarTitleWdg(isWide, cts.favIdx, tabWdgs[cts.favIdx]),
		  leading: _makeAppBarLeading(isWide, cts.favIdx),
		  backgroundColor: stl.cs.primary,
		  primary: false,
	       );
	       local.add(favTopBar);
	    }

	    local.add(Expanded(child: bodies[cts.favIdx]));
            local.add(div);

	    favTmp = Column(children: local);
	 }

	 Widget fav = imposeWidth(
	    child: favTmp,
	    width: makeWidgetWidth(ctx),
	 );

	 VerticalDivider vdiv = VerticalDivider(
	    width: sep,
	    thickness: sep,
	    indent: 0.0,
	    color: stl.cs.background,
	 );

	 Widget body = Row(children: <Widget>
	    [ vdiv
	    , Expanded(child: Stack(children: <Widget>[own, Positioned(bottom: 20.0, right: 20.0, child: fltButtons[cts.ownIdx])]))
	    , vdiv
	    , Expanded(child: Stack(children: <Widget>[search, Positioned(bottom: 20.0, right: 20.0, child: fltButtons[cts.searchIdx])]))
	    , vdiv
	    , Expanded(child: Stack(children: <Widget>[fav, Positioned(bottom: 20.0, right: 20.0, child: fltButtons[cts.favIdx])]))
	    , vdiv
	    ],
	 );

	 return makeWebScaffoldWdg(
	    body: body,
	    appBar: AppBar(
               title: Text(g.param.shareSubject),
	       actions: _makeGlobalActionsWeb(ctx),
	    ),
	    onWillPopScope: () {return true;},
	 );
      }

      if (_isOnFavChat(screenIdx) || _isOnOwnChat(screenIdx))
	 return imposeWidth(
	    child: _makeChatScreen(ctx, screenIdx),
	    width: makeWidgetWidth(ctx),
	 );

      List<Widget> actions = _makeTabActions(ctx, screenIdx);
      actions.addAll(_makeGlobalActionsApp(ctx, screenIdx));
      List<double> opacities = _getNewMsgsOpacities();

      return makeAppScaffoldWdg(
	 onWillPops: () {return _makeOnWillPop(_tabCtrl.index);},
	 scrollCtrl: _scrollCtrl[_tabIndex()],
	 appBarTitle: _makeAppBarTitleWdg(
            isWide,
	    screenIdx,
	    Text(g.param.shareSubject),
	 ),
	 appBarLeading: _makeAppBarLeading(isWide, screenIdx),
	 floatBut: fltButtons[_tabCtrl.index],
	 body: TabBarView(controller: _tabCtrl, children: bodies),
	 tabBar: makeTabBar(ctx, newMsgCounters, _tabCtrl, opacities, _hasLPChatMsgs(screenIdx)),
	 actions: actions,
      );
   }
}

