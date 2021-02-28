
const double goldenRatio = 1.618033;
const double maxWidgetWidth = 550;
const double minWidgetWidth = 450;

//-------------------------------------------------------------------------------

// Quality of the image, see
// https://pub.dev/documentation/image_picker/latest/image_picker/ImagePicker/pickImage.html
const int maxImgsPerPost = 6;
const int minImgsPerPost = 1;

const int nickMaxLength = 20;
const int nickMinLength = 3;
const int emailMaxLength = 80;
const int descriptionMaxLength = 500;

// This constant should be set to the maximum number of exclusive
// details among all pruducts. At the moment this is 6 for cars and I
// see no reason for it being much more than that. This value will be
// used to initialize the corresponding array in the Post class. At
// the moment of post creation we do not know which product it will
// carry and therefore we also do not know the size we need. For
// backward compatibility it may be a good idea to make room for
// further expansion.
const int maxExDetailSize = 20;
// See the comment in maxExDetailSize
const int maxInDetailSize = 20;

const String gravatarUrl = 'https://www.gravatar.com/avatar/';
const String occaseGravatarEmail = 'occase.app@gmail.com';

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

const String dbCountPostsUrl =    dbHttpUrl + '/posts/count';
const String dbSearchPostsUrl =   dbHttpUrl + '/posts/search';
const String dbUploadCreditUrl =  dbHttpUrl + '/posts/upload-credit';
const String dbDeletePostUrl =    dbHttpUrl + '/posts/delete';
const String dbPostUrl =          dbHttpUrl + '/posts/publish';
const String dbVisualizationUrl = dbHttpUrl + '/posts/visualizations';
const String dbClickUrl =         dbHttpUrl + '/posts/click';
const String dbPublishUrl =       dbHttpUrl + '/posts/publish';
const String dbGetIdUrl =         dbHttpUrl + '/get-user-id';

// The pong timeout used by the server.
const int pongTimeoutSeconds = 30;
const int pongTimeoutMilliseconds = pongTimeoutSeconds * 1000;

// Interval used to send presence messages to the peer in
// milliseconds.
const int presenceInterval = 5 * 1000;

const int ownIdx = 0;
const int searchIdx = 1;
const int favIdx = 2;

const List<double> tabWidthRates = const <double>[0.33333, 0.33333, 0.33333];

