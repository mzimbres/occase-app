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

// These are the main colors we will use. Taken from material palette tool.
// Idea taken from https://visme.co/blog/color-combinations/
// See ../android/app/src/main/res/values/colors.xml
// Tool: https://material.io/resources/color/#!/?view.left=0&view.right=1&primary.color=36688d
const Color primaryColor = Color(0xff36688d);
const Color primaryLightColor = Color(0xff6796bd);
const Color primaryDarkColor = Color(0xff003e5f);
const Color secondaryColor = Color(0xfff49f05);
const Color secondaryLightColor = Color(0xffffd04a);
const Color secondaryDarkColor = Color(0xffbc7000);
const Color primaryTextColor = Color(0xffffffff);
const Color secondaryTextColor = Color(0xff000000);

// Colors
final Color chatLongPressedColor = Colors.grey[350]; 
final Color neutralColor = Colors.grey[600]; 
final Color textColor = Colors.grey[800]; 

//const Color postColor = Color(0xfff5f5f5);
const Color postColor = Colors.white;
final Color chatDateColor = Colors.grey[500];
final Color onPrimarySubtitleColor = Colors.white;
const Color infoKeyColor = Colors.black;
const Color infoKeyArrowColor = infoKeyColor;
final Color testimonialColor = secondaryColor;

const ColorScheme cs = const ColorScheme.light(
   primary: primaryColor,
   primaryVariant: primaryDarkColor,
   secondary: secondaryColor,
   secondaryVariant: secondaryDarkColor,
   surface: postColor,
   background: Colors.white,
   error: const Color(0xffb00020),
   onPrimary: primaryTextColor,
   onSecondary: secondaryTextColor,
   onSurface: Colors.black,
   onBackground: Colors.black,
   onError: Colors.white,
   brightness: Brightness.light
);

final TextStyle postModelSty = TextStyle(
   fontSize: bigFontSize,
   color: secondaryDarkColor,
   fontWeight: FontWeight.w700,
);

final TextStyle postLocationSty = TextStyle(
   fontSize: smallFontSize,
   color: neutralColor,
   fontWeight: FontWeight.normal,
);

final TextStyle ltTitleSty = TextStyle(
   fontSize: mainFontSize,
   color: textColor,
   fontWeight: FontWeight.w500,
);

final TextStyle ltSubtitleSty = TextStyle(
   fontSize: smallFontSize,
   color: secondaryDarkColor,
   fontWeight: FontWeight.normal,
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

const TextStyle appBarLtTitle = TextStyle(
   fontSize: largerFontSize,
   color: primaryTextColor,
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

