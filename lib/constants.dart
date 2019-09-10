import 'package:flutter/material.dart';

const List<int> filterDepths = <int>[3, 3];
const List<int> versions = <int>[3, 3];
const double imgBoxWidth = 395.0;
const double imgBoxHeight = 300.0;

// In the array below the range min is followed by the range max.
const List<int> rangesMinMax = <int>
[    0, 1000000 // Price
, 1930,    2030 // Year.
,    0, 1000000 // km.
];

const List<int> rangeDivs = <int>
[ 100 // price
, 100 // year
, 100 // km
];

const int nickMaxLength = 20;
const int emailMaxLength = 50;

// This constant should be set to the maximum number of exclusive
// details among all pruducts. At the moment this is 6 for cars and I
// see no reason for it being much more than that. This value will
// be used to initialize the corresponding array in the Post class. At
// the moment of post creation we do not know which product it will
// carry and therefore we also do not know the size we need. For
// backward compatibility it may be a good idea to make room for
// further expansion.
const int maxExDetailSize = 10;

// See the comment in maxExDetailSize
const int maxInDetailSize = 5;

const String chatFilePrefix = 'chat';

const String gravatarUrl = 'https://www.gravatar.com/avatar/';

const double onClickAvatarWidth = 200.0;

// WARNING: localhost or 127.0.0.1 is the emulator or the phone
// address. If the phone is connected (via USB) to a computer
// the computer can be found on 10.0.2.2.
//final String wshost = 'ws://10.0.2.2:80';

// My public ip.
//const String wshost = 'ws://37.24.165.216:80';
const String wshost = 'ws://10.0.2.2:81';
const String httphost = 'http://10.0.2.2:8888';

const int maxImgsPerPost = 6;

// The time we are willing to wait for the server to send us the
// filenames.
const int filenamesTimeout = 5;

