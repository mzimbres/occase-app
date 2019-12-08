// The image width will be determined by the device screen width times
// this factor.
const double imgWidthFactor = 1.0;

// The image width will be determined by the device screen WIDTH times
// this factor, that means, a factor 1.0 means a square image.
const double imgHeightFactor = 1.0;

// Quality of the image, see
// https://pub.dev/documentation/image_picker/latest/image_picker/ImagePicker/pickImage.html
const int imgQuality = 50;
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
const int maxExDetailSize = 10;

// See the comment in maxExDetailSize
const int maxInDetailSize = 20;

const String gravatarUrl = 'https://www.gravatar.com/avatar/';

// Use media query instead of this.
const double onClickAvatarWidth = 200.0;

// WARNING: localhost or 127.0.0.1 is the emulator or the phone
// address. If the phone is connected (via USB) to a computer
// the computer can be found on 10.0.2.2.

const String wshost = 'wss://occase.de';
//const String wshost = 'ws://10.0.2.2:8080';

const int maxImgsPerPost = 4;

// The time we are willing to wait for the server to send us the
// filenames.
const int filenamesTimeout = 5;

// The pong timeout used by the server. (in milliseconds)
const int pongTimeout = 30 * 1000;

// Interval used to send presence messages to the peer in
// milliseconds.
const int presenceInterval = 5 * 1000;

// The number of that are shown to the user when he clicks the
// download button. 
const int maxPostsOnDownload = 10;

