import 'package:flutter/material.dart';

final Color chatLongPressendColor = Colors.grey[350]; 

const double bigFontSize = 20.0;
const double mainFontSize = 16.0;
const double smallFontSize = 14.0;
const double delImgWidgOpacity = 0.5;

// The padding of chat messages inside ist box.
const double chatMsgPadding = 5.0;
const double postSectionPadding = 5.0;

const Color primaryColor = Color(0xFF434b79);
const Color onPrimaryColor = Colors.white;

const ColorScheme colorScheme = const ColorScheme.light(
      primary: primaryColor,
      primaryVariant: Color(0xFF434b79),
      secondary: Color(0xFFffa32c),
      secondaryVariant: Color(0xFFff5635),
      onSecondary: Color(0xFF434b79),
      onPrimary: onPrimaryColor,
);

const Color infoKeyColor = Colors.black;
const Color infoKeyArrowColor = infoKeyColor;

const TextTheme tt = TextTheme(
   title: TextStyle(fontSize: bigFontSize),
   subhead: TextStyle(fontSize: mainFontSize),
);

const TextStyle tsMainPrimary = TextStyle(
   fontSize: mainFontSize,
   color: primaryColor,
);

const TextStyle tsMainBlack = TextStyle(
   fontSize: mainFontSize,
   color: Colors.black,
);

const TextStyle tsMainBlackBold = TextStyle(
   fontSize: mainFontSize,
   color: Colors.black,
   fontWeight: FontWeight.w500,
);

final TextStyle newPostSubtitleLT = TextStyle(
   fontSize: smallFontSize,
   color: Colors.grey,
   fontWeight: FontWeight.normal,
);

final TextStyle ltSubtitle = TextStyle(
   fontSize: smallFontSize,
   color: Colors.grey[700],
   fontWeight: FontWeight.w300,
);

final Color onPrimarySubtitleColor = Colors.white;

final TextStyle ltSubtitleOnPrimary = TextStyle(
   fontSize: smallFontSize,
   color: onPrimarySubtitleColor,
   fontWeight: FontWeight.normal,
);

const TextStyle appBarLtTitle = TextStyle(
   fontSize: 18.0,
   color: onPrimaryColor,
   fontWeight: FontWeight.w500,
);

final TextStyle appBarLtSubtitle = TextStyle(
   fontSize: smallFontSize,
   color: onPrimarySubtitleColor,
   fontWeight: FontWeight.normal,
);

//-------------------------------------------------------------------------

// Text style of TextFields.
const TextStyle textField = TextStyle(
   fontSize: 15.0,
   color: Colors.black,
);

//-------------------------------------------------------------------------

// The padding used around the posts and likes screens.
const double postListViewTopPadding = 2.0;
const double postListViewSidePadding = 0.0;
const double chatListTilePadding = 6.0;

const double cornerRadius = 8.0;

const chatTilePadding = 4.0;

const Icon unknownPersonIcon = Icon(
   Icons.person,
   color: Colors.white,
   size: 30.0,
);

const Icon favIcon = Icon(Icons.chat, color: Colors.lightGreen);

const IconData newPostIcon = Icons.add;

const double imgInfoWidgetPadding = 10.0;

const double imgLvBorderWidth = 2.0;

const double newPostIconSize = 35.0;

List<Color> priceColors = <Color>
[ Colors.blueGrey[700]
, Colors.teal[800]
, Colors.yellow[900]
];

// This color is used to show the chat message date both on primary
// color and white backckground. It is also used for the title and
// forward arrow in redirected messages.
final Color chatDateColor = Colors.grey[500];

const double infoWidthFactor = 0.94;

final Color expTileCardColor = Colors.grey[200];

final
Divider alertDivider = Divider(
   color: Colors.grey,
   height: 1.0,
   thickness: 1.0,
   indent: 17.0,
   endIndent: 17.0,
);

const double leftIndent = 10.0;

final Divider newPostDivider = Divider(
   color: Colors.grey,
   height: 1.0,
   indent: leftIndent,
   endIndent: leftIndent,
   thickness: 1.0,
);

const double newPostPadding = 5.0;
const double alertDialogInsetPadding = 3.0;
const double minButtonWidth = 100.0;

