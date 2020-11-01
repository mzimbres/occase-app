import 'package:flutter/material.dart';

// Padding
const double basePadding = 5.0;
const double newPostSectionTitleTopIndent = 25;

// Width
const double buttonMinWidth = 150;
const double infoWidthFactor = 0.94;
const double minButtonWidth = 100.0;

// Corner
const double cornerRadius = 4.0;

// Font size
const double hugeFontSize = 24.0;
const double largeFontSize = 22.0;
const double bigFontSize = 20.0;
const double largerFontSize = 18.0;
const double mainFontSize = 16.0;
const double smallFontSize = 14.0;
const double tinyFontSize = 12.0;
const double delImgWidgOpacity = 0.5;

// Icon size
const double newPostIconSize = 35.0;

// Colors
final Color chatLongPressendColor = Colors.grey[350]; 
const Color primaryColor = Color(0xFF434b79);
const Color onPrimaryColor = Colors.white;
const Color backgroundColor = Color(0xFFEEEEEE);
const Color secondaryColor = Color(0xFFffa32c);
const Color onSecondaryColor = primaryColor;
final Color newPostCardColor = Colors.orange[50];
final Color chatDateColor = Colors.grey[500];
final Color onPrimarySubtitleColor = Colors.white;
const Color infoKeyColor = Colors.black;
const Color infoKeyArrowColor = infoKeyColor;
const Color alertDiagBackgroundColor = Color(0xFFE0E0E0);

const ColorScheme colorScheme = const ColorScheme.light(
      primary: primaryColor,
      primaryVariant: Color(0xFF434b79),
      secondary: Color(0xFFffa32c),
      secondaryVariant: Color(0xFFff5635),
      onSecondary: Color(0xFF434b79),
      onPrimary: onPrimaryColor,
      background: backgroundColor,
);

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
   fontSize: largerFontSize,
   color: Colors.orange[900],
   fontWeight: FontWeight.w500,
);

final TextStyle ltSubtitle = TextStyle(
   fontSize: smallFontSize,
   color: Colors.grey[700],
   fontWeight: FontWeight.w300,
);

final TextStyle ltSubtitleOnPrimary = TextStyle(
   fontSize: smallFontSize,
   color: onPrimarySubtitleColor,
   fontWeight: FontWeight.normal,
);

const TextStyle appBarLtTitle = TextStyle(
   fontSize: largerFontSize,
   color: onPrimaryColor,
   fontWeight: FontWeight.w500,
);

final TextStyle appBarLtSubtitle = TextStyle(
   fontSize: smallFontSize,
   color: onPrimarySubtitleColor,
   fontWeight: FontWeight.normal,
);

const Icon unknownPersonIcon = Icon(
   Icons.person,
   color: Colors.white,
   size: 30.0,
);

const Icon favIcon = Icon(Icons.chat, color: Colors.lightGreen);

const IconData newPostIcon = Icons.add;

List<Color> priceColors = <Color>
[ Colors.blueGrey[700]
, Colors.teal[800]
, Colors.yellow[900]
];

final
Divider alertDivider = Divider(
   color: Colors.grey,
   height: 1.0,
   thickness: 1.0,
   indent: 17.0,
   endIndent: 17.0,
);

final Divider newPostDivider = Divider(
   color: Colors.grey,
   height: 1.0,
   indent: basePadding,
   endIndent: basePadding,
   thickness: 1.0,
);

