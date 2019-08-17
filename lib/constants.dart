import 'package:flutter/material.dart';

const List<int> filterDepths = <int>[3, 3];
const List<int> versions = <int>[3, 3];
const double imgBoxWidth = 395.0;
const double imgBoxHeight = 300.0;

const List<List<int>> valueRanges = <List<int>>
[ <int>[5000, 200000] // Price
, <int>[1990, 2040]   // Year.
, <int>[0, 1000000]   // km.
];

const List<int> divisions = <int>
[ 100 // price
, 50  // year
, 200 // km
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

