
// Quality of the image, see
// https://pub.dev/documentation/image_picker/latest/image_picker/ImagePicker/pickImage.html
const int imgQuality = 75;
const int nickMaxLength = 20;
const int nickMinLength = 3;
const int emailMaxLength = 50;

// This constant should be set to the maximum number of exclusive
// details among all pruducts. At the moment this is 6 for cars and I
// see no reason for it being much more than that. This value will
// be used to initialize the corresponding array in the Post class. At
// the moment of post creation we do not know which product it will
// carry and therefore we also do not know the size we need. For
// backward compatibility it may be a good idea to make room for
// further expansion.
const int maxExDetailSize = 20;

// See the comment in maxExDetailSize
const int maxInDetailSize = 20;

const String gravatarUrl = 'https://www.gravatar.com/avatar/';

// Use media query instead of this.
const double onClickAvatarWidth = 200.0;

const String dbHost = 'db.occase.de';

// The localhost or 127.0.0.1 is the emulator or the phone address. If
// the phone is connected (via USB) to a computer the computer can be
// found on 10.0.2.2.
//const String dbWebsocketUrl = 'ws://10.0.2.2:80';

// This domain points to the production servers.
const String dbWebsocketUrl = 'wss://' + dbHost;

// This domain points to my home public ip address.
//const String dbWebsocketUrl = 'wss://occase.de';

const String dbHttpUrl = 'https://' + dbHost;

const String dbCountPostsUrl =   dbHttpUrl + '/posts/count';
const String dbSearchPostsUrl =  dbHttpUrl + '/posts/search';
const String dbUploadCreditUrl = dbHttpUrl + '/posts/upload-credit';
const String dbDeletePostUrl =   dbHttpUrl + '/posts/delete';
const String dbPostUrl =         dbHttpUrl + '/posts/publish';

const int maxImgsPerPost = 6;
const int minImgsPerPost = 1;

// The pong timeout used by the server.
const int pongTimeoutSeconds = 30;
const int pongTimeoutMilliseconds = pongTimeoutSeconds * 1000;

// Interval used to send presence messages to the peer in
// milliseconds.
const int presenceInterval = 5 * 1000;

// The number of that are shown to the user when he clicks the
// download button. 
const int maxPostsOnDownload = 10;

const int ownIdx = 0;
const int searchIdx = 1;
const int favIdx = 2;

const double tabDefaultWidth = 350.0;
const List<double> tabWidthRates = const <double>[0.291, 0.42, 0.291];
const List<int> tabFlexValues = const <int>[29, 42, 29];
const double postImgAvatarTabWidthRate = 0.40;
const double postWidth = 0.58;

const List<double> newMsgsOpacitiesWeb = const <double>[1.0, 1.0, 1.0];

const double imgWidgth = tabDefaultWidth;
