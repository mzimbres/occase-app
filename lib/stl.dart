import 'package:flutter/material.dart';

final Color chatLongPressendColor = Colors.grey[350]; 

const double mainFontSize = 16.0;

// Margin used so that the post card boarder has some distance from
// the screen border or whatever widget it happens to be inside of.
const double postMargin = 1.0;

// Marging used to separate the post element cards from the
// outermost cards.
const double postInnerMargin = 8.0;

const double listTileSubtitleFontSize = 14.0;

// The padding used for the text inside the post element.
const double postElemTextPadding = 7.0;

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

final Color infoKeyColor = Colors.grey[700];
final Color infoKeyArrowColor = infoKeyColor;
final Color infoValueColor = primaryColor;

const double titleFontSize = 20.0;
const double subheadFontSize = 16.0;
const double subtitleFontSize = 14.0;

const TextTheme tt = TextTheme(
   title: TextStyle(fontSize: titleFontSize),
   subhead: TextStyle(fontSize: subheadFontSize),
);

const TextStyle tsSubheadPrimary = TextStyle(
   fontSize: subheadFontSize,
   color: primaryColor,
);

const TextStyle tsSubheadOnPrimary = TextStyle(
   fontSize: subheadFontSize,
   color: onPrimaryColor,
);

//-------------------------------------------------------------------------
// This section contains some style of ListTiles so that they have a
// uniform appearence on the app.

// All ListTile titles should use the same fontsize. An exception is
// made to those LT that are used on the appBar, they need a larger
// fontSize
const double ltTitleFontSize = subheadFontSize;
const double ltSubtitleFontSize = subtitleFontSize;

const TextStyle ltTitle = TextStyle(
   fontSize: ltTitleFontSize,
   color: Colors.black,
   fontWeight: FontWeight.w500,
);

const TextStyle ltTitleOnPrimary = TextStyle(
   fontSize: ltTitleFontSize,
   color: onPrimaryColor,
   fontWeight: FontWeight.w500,
);

final TextStyle ltSubtitle = TextStyle(
   fontSize: ltSubtitleFontSize,
   color: Colors.grey[600],
   fontWeight: FontWeight.normal,
);

final Color onPrimarySubtitleColor = Colors.grey[300];

final TextStyle ltSubtitleOnPrimary = TextStyle(
   fontSize: ltSubtitleFontSize,
   color: onPrimarySubtitleColor,
   fontWeight: FontWeight.normal,
);

const TextStyle appBarLtTitle = TextStyle(
   fontSize: 18.0,
   color: onPrimaryColor,
   fontWeight: FontWeight.w500,
);

final TextStyle appBarLtSubtitle = TextStyle(
   fontSize: ltSubtitleFontSize,
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

const double postCardSideMargin = 1.0;
const double postCardBottomMargin = 10.0;

const double cornerRadius = 8.0;

const chatTilePadding = 4.0;

const Icon unknownPersonIcon = Icon(
   Icons.person,
   color: Colors.white,
   size: 30.0,
);

const List<IconData> newPostTabIcons = <IconData>
[ Icons.home
, Icons.directions_car
, Icons.details
, Icons.publish
];

const Icon favIcon = Icon(Icons.star, color: Colors.amber);
const Icon pubIcon = Icon(Icons.publish, color: Colors.amber);

const List<IconData> filterTabIcons = <IconData>
[ Icons.home
, Icons.directions_car
, Icons.filter_list
, Icons.search
];

const IconData newPostIcon = Icons.publish;

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

