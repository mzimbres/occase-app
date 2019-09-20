import 'package:flutter/material.dart';

final Color chatLongPressendColor = Colors.grey[400]; 

final double mainFontSize = 16.0;

// Margin used so that the post card boarder has some distance from
// the screen border or whatever widget it happens to be inside of.
final double postMarging = 4.0;

// Marging user to separate the post element cards from the
// outermost cards.
final double postInnerMargin = 8.0;

final double listTileSubtitleFontSize = 14.0;

// The padding used for the text inside the post element.
final double postElemTextPadding = 7.0;

final double outerPostCardPadding = 1.0;

// The padding of chat messages inside ist box.
final double chatMsgPadding = 5.0;
final double postSectionPadding = 10.0;

const ColorScheme colorScheme = ColorScheme.light(
      primary: Color(0xFF434b79),
      primaryVariant: Color(0xFF434b79),
      secondary: Color(0xFFffa32c),
      secondaryVariant: Color(0xFFff5635),
      onSecondary: Color(0xFF434b79),
);

const TextTheme tt = TextTheme(
   title: TextStyle(fontSize: 20.0),
);

// The padding used around the posts and likes screens.
const double postListViewTopPadding = 2.0;
const double postListViewSidePadding = 0.0;

const double postCardSideMargin = 4.0;
const double postCardBottomMargin = 10.0;

const double cornerRadius = 8.0;
const double cardPostMargin = postCardSideMargin;

const chatTilePadding = cardPostMargin;

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
, Icons.send
];

const IconData newPostIcon = Icons.add;

const double imgInfoWidgetPadding = 10.0;

const double imgLvBorderWidth = 2.0;

const double newPostIconSize = 35.0;

List<Color> priceColors = <Color>
[ Colors.blueGrey[800]
, Colors.teal[800]
, Colors.yellow[900]
];

