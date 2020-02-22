import 'package:occase/constants.dart' as cts;
import 'dart:convert';

List<T> decodeList2<T>(List<dynamic> l)
{
   return List.generate(l.length, (int i) { return l[i]; });
}

List<List<T>> decodeList3<T>(List<dynamic> l)
{
   return List.generate(l.length, (int i) {
      return decodeList2<T>(l[i]);
   });
}

class Parameters {
   int _langIdx = 0;
   String appName;
   List<String> _delOwnChatTitleStr = <String>[''];
   List<String> _delFavChatTitleStr = <String>[''];
   List<String> _devChatOkStr = <String>[''];
   List<String> _delChatCancelStr = <String>[''];
   List<String> _newPostAppBarTitle = <String>[''];
   List<String> _filterAppBarTitle = <String>[''];
   List<String> _postRefSectionTitle = <String>[''];
   List<String> _postExDetailsTitle = <String>[''];
   List<String> _postDescTitle = <String>[''];
   List<String> _newPostTextFieldHist = <String>[''];
   List<String> _chatTextFieldHint = <String>[''];
   List<String> _nickHint = <String>[''];
   List<String> _emailHint = <String>[''];
   List<String> _msgOnRedirectingChat = <String>[''];
   List<String> _msgOnRedirectedChat = <String>[''];
   List<String> _msgOnEmptyChat = <String>[''];
   List<String> _deleteChat = <String>[''];
   List<String> _pinChat = <String>[''];
   List<String> _clearPosts = <String>[''];
   List<String> _notificationsButton = <String>[''];
   List<String> _unknownNick = <String>[''];
   List<String> _selectAll = <String>[''];
   List<String> _changeNickHint = <String>[''];
   List<String> _changeNotifications = <String>[''];
   List<String> _dissmissedPost = <String>[''];
   List<String> _dismissedChat = <String>[''];
   List<String> _ok = <String>[''];
   List<String> _cancel = <String>[''];
   List<String> _cancelNewPost = <String>[''];
   List<String> _doNotShowAgain = <String>[''];
   List<String> _next = <String>[''];
   List<String> _rangesTitle = <String>[''];
   List<String> _paymentTitle = <String>[''];
   List<String> _onEmptyNickTitle = <String>[''];
   List<String> _onEmptyNickContent = <String>[''];
   List<String> _addImgMsg = <String>[''];
   List<String> _unreachableImgError = <String>[''];
   List<String> _clearPostsTitle = <String>[''];
   List<String> _clearPostsContent = <String>[''];
   List<String> _localeName = <String>[''];
   List<String> _typing = <String>[''];
   List<String> _cancelPost = <String>[''];
   List<String> _cancelPostContent = <String>[''];
   List<String> _numberOfChatsSuffix = <String>[''];
   List<String> _numberOfUnreadChatsSuffix = <String>[''];
   List<String> _postMinImgs = <String>[''];
   List<String> _postMinImgsContent = <String>[''];
   List<String> _changeNickAppBarTitle = <String>[''];
   List<String> _changeNtfAppBarTitle = <String>[''];

   List<List<String>> _tabNames = <List<String>>[<String>['' ,'' , '']];
   List<List<String>> _newPostTabNames = <List<String>>[<String>['', '', '', '']];
   List<List<String>> _filterTabNames = <List<String>>[<String>['', '', '', '']];
   List<List<String>> _descList =  <List<String>>[<String>['', '', '', '', '']];
   List<List<String>> _dialogTitles =  <List<String>>[<String>['' ,'' ,'' ,'' , '']];
   List<List<String>> _dialogBodies =  <List<String>>[<String>['', '', '', '', '']];
   List<List<String>> _rangePrefixes =  <List<String>>[<String>['','' ,'' ]];
   List<List<String>> _rangeUnits =  <List<String>>[<String>['', '', '', '', '', '']];
   List<List<String>> _newPostErrorTitles = <List<String>>[<String>[ '', '']];
   List<List<String>> _newPostErrorBodies = <List<String>> [<String>['' , '']];
   List<List<String>> _newFiltersFinalScreenButton = <List<String>>[<String>['', '', '']];
   List<List<String>> _ntfTitleDesc =  <List<String>>[<String>['', '']];

   List<List<String>> menuDepthNames;
   List<List<String>> payments;

   List<int> filterDepths;
   List<int> rangesMinMax;
   List<int> rangeDivs;
   List<List<int>> discreteRanges;

   Parameters(
   { this.appName = 'Occase'
   , this.filterDepths = const <int>[3, 3]
   , this.rangesMinMax = const <int>[0, 256000, 0, 2030, 0, 100000]
   , this.rangeDivs = const <int>[100, 100, 100]
   , this.menuDepthNames = const <List<String>>
   [ <String> [ '' , '' , '' , '' ]
   , <String> [ '' , '' , '' , '' , '' , '' , '' ]
   ]
   , this.payments = const <List<String>>
   [ <String>[ '', '', '' ]
   , <String>[ '', '', '.']
   , <String>[ '', '', '']
   ]
   , this.discreteRanges = const <List<int>>
   [ <int>[0, 1000, 2000, 4000, 8000, 16000, 32000, 64000, 128000, 256000]
   , <int>[0, 1990, 2000, 2010, 2015, 2018, 2030]
   , <int>[0, 5000, 10000, 20000, 40000, 80000, 100000]
   ]
   });

   void setLang(String code)
   {
      _langIdx = 1;
   }

   String get delOwnChatTitleStr        => _delOwnChatTitleStr[_langIdx];
   String get delFavChatTitleStr        => _delFavChatTitleStr[_langIdx];
   String get devChatOkStr              => _devChatOkStr[_langIdx];
   String get delChatCancelStr          => _delChatCancelStr[_langIdx];
   String get newPostAppBarTitle        => _newPostAppBarTitle[_langIdx];
   String get filterAppBarTitle         => _filterAppBarTitle[_langIdx];
   String get postRefSectionTitle       => _postRefSectionTitle[_langIdx];
   String get postExDetailsTitle        => _postExDetailsTitle[_langIdx];
   String get postDescTitle             => _postDescTitle[_langIdx];
   String get newPostTextFieldHist      => _newPostTextFieldHist[_langIdx];
   String get chatTextFieldHint         => _chatTextFieldHint[_langIdx];
   String get nickHint                  => _nickHint[_langIdx];
   String get emailHint                 => _emailHint[_langIdx];
   String get msgOnRedirectingChat      => _msgOnRedirectingChat[_langIdx];
   String get msgOnRedirectedChat       => _msgOnRedirectedChat[_langIdx];
   String get msgOnEmptyChat            => _msgOnEmptyChat[_langIdx];
   String get deleteChat                => _deleteChat[_langIdx];
   String get pinChat                   => _pinChat[_langIdx];
   String get clearPosts                => _clearPosts[_langIdx];
   String get notificationsButton       => _notificationsButton[_langIdx];
   String get unknownNick               => _unknownNick[_langIdx];
   String get selectAll                 => _selectAll[_langIdx];
   String get changeNickHint            => _changeNickHint[_langIdx];
   String get changeNotifications       => _changeNotifications[_langIdx];
   String get dissmissedPost            => _dissmissedPost[_langIdx];
   String get dismissedChat             => _dismissedChat[_langIdx];
   String get ok                        => _ok[_langIdx];
   String get cancel                    => _cancel[_langIdx];
   String get cancelNewPost             => _cancelNewPost[_langIdx];
   String get doNotShowAgain            => _doNotShowAgain[_langIdx];
   String get next                      => _next[_langIdx];
   String get rangesTitle               => _rangesTitle[_langIdx];
   String get paymentTitle              => _paymentTitle[_langIdx];
   String get onEmptyNickTitle          => _onEmptyNickTitle[_langIdx];
   String get onEmptyNickContent        => _onEmptyNickContent[_langIdx];
   String get addImgMsg                 => _addImgMsg[_langIdx];
   String get unreachableImgError       => _unreachableImgError[_langIdx];
   String get clearPostsTitle           => _clearPostsTitle[_langIdx];
   String get clearPostsContent         => _clearPostsContent[_langIdx];
   String get localeName                => _localeName[_langIdx];
   String get typing                    => _typing[_langIdx];
   String get cancelPost                => _cancelPost[_langIdx];
   String get cancelPostContent         => _cancelPostContent[_langIdx];
   String get numberOfChatsSuffix       => _numberOfChatsSuffix[_langIdx];
   String get numberOfUnreadChatsSuffix => _numberOfUnreadChatsSuffix[_langIdx];
   String get postMinImgs               => _postMinImgs[_langIdx];
   String get postMinImgsContent        => _postMinImgsContent[_langIdx];
   String get changeNickAppBarTitle     => _changeNickAppBarTitle[_langIdx];
   String get changeNtfAppBarTitle      => _changeNtfAppBarTitle[_langIdx];

   List<String> get tabNames                     => _tabNames[_langIdx];
   List<String> get newPostTabNames              => _newPostTabNames[_langIdx];
   List<String> get filterTabNames               => _filterTabNames[_langIdx];
   List<String> get descList                     => _descList[_langIdx];
   List<String> get dialogTitles                 => _dialogTitles[_langIdx];
   List<String> get dialogBodies                 => _dialogBodies[_langIdx];
   List<String> get rangePrefixes                => _rangePrefixes[_langIdx];
   List<String> get rangeUnits                   => _rangeUnits[_langIdx];
   List<String> get newPostErrorTitles           => _newPostErrorTitles[_langIdx];
   List<String> get newPostErrorBodies           => _newPostErrorBodies[_langIdx];
   List<String> get newFiltersFinalScreenButton  => _newFiltersFinalScreenButton[_langIdx];
   List<String> get ntfTitleDesc                 => _ntfTitleDesc[_langIdx];

   Parameters.fromJson(Map<String, dynamic> map)
   {
      appName                     = map['appName'];
      _delOwnChatTitleStr          = decodeList2(map['delOwnChatTitleStr']);
      _delFavChatTitleStr          = decodeList2(map['delFavChatTitleStr']);
      _devChatOkStr                = decodeList2(map['devChatOkStr']);
      _delChatCancelStr            = decodeList2(map['delChatCancelStr']);
      _newPostAppBarTitle          = decodeList2(map['newPostAppBarTitle']);
      _filterAppBarTitle           = decodeList2(map['filterAppBarTitle']);
      _postRefSectionTitle         = decodeList2(map['postRefSectionTitle']);
      _postExDetailsTitle          = decodeList2(map['postExDetailsTitle']);
      _postDescTitle               = decodeList2(map['postDescTitle']);
      _newPostTextFieldHist        = decodeList2(map['newPostTextFieldHist']);
      _chatTextFieldHint           = decodeList2(map['chatTextFieldHint']);
      _nickHint                    = decodeList2(map['nickHint']);
      _emailHint                   = decodeList2(map['emailHint']);
      _msgOnRedirectingChat        = decodeList2(map['msgOnRedirectingChat']);
      _msgOnRedirectedChat         = decodeList2(map['msgOnRedirectedChat']);
      _msgOnEmptyChat              = decodeList2(map['msgOnEmptyChat']);
      _deleteChat                  = decodeList2(map['deleteChat']);
      _pinChat                     = decodeList2(map['pinChat']);
      _clearPosts                  = decodeList2(map['clearPosts']);
      _notificationsButton         = decodeList2(map['notificationsButton']);
      _unknownNick                 = decodeList2(map['unknownNick']);
      _selectAll                   = decodeList2(map['selectAll']);
      _changeNickHint              = decodeList2(map['changeNickHint']);
      _changeNotifications         = decodeList2(map['changeNotifications']);
      _dissmissedPost              = decodeList2(map['dissmissedPost']);
      _dismissedChat               = decodeList2(map['dismissedChat']);
      _ok                          = decodeList2(map['ok']);
      _cancel                      = decodeList2(map['cancel']);
      _cancelNewPost               = decodeList2(map['cancelNewPost']);
      _doNotShowAgain              = decodeList2(map['doNotShowAgain']);
      _next                        = decodeList2(map['next']);
      _rangesTitle                 = decodeList2(map['rangesTitle']);
      _paymentTitle                = decodeList2(map['paymentTitle']);
      _onEmptyNickTitle            = decodeList2(map['onEmptyNickTitle']);
      _onEmptyNickContent          = decodeList2(map['onEmptyNickContent']);
      _addImgMsg                   = decodeList2(map['addImgMsg']);
      _unreachableImgError         = decodeList2(map['unreachableImgError']);
      _clearPostsTitle             = decodeList2(map['clearPostsTitle']);
      _clearPostsContent           = decodeList2(map['clearPostsContent']);
      _localeName                  = decodeList2(map['localeName']);
      _typing                      = decodeList2(map['typing']);
      _cancelPost                  = decodeList2(map['cancelPost']);
      _cancelPostContent           = decodeList2(map['cancelPostContent']);
      _numberOfChatsSuffix         = decodeList2(map['numberOfChatsSuffix']);
      _numberOfUnreadChatsSuffix   = decodeList2(map['numberOfUnreadChatsSuffix']);
      _postMinImgs                 = decodeList2(map['postMinImgs']);
      _postMinImgsContent          = decodeList2(map['postMinImgsContent']);
      _changeNickAppBarTitle       = decodeList2(map['changeNickAppBarTitle']);
      _changeNtfAppBarTitle        = decodeList2(map['changeNtfAppBarTitle']);

      _tabNames                    = decodeList3(map['tabNames']);
      _newPostTabNames             = decodeList3(map['newPostTabNames']);
      _filterTabNames              = decodeList3(map['filterTabNames']);
      _descList                    = decodeList3(map['descList']);
      _dialogTitles                = decodeList3(map['dialogTitles']);
      _dialogBodies                = decodeList3(map['dialogBodies']);
      _rangePrefixes               = decodeList3(map['rangePrefixes']);
      _rangeUnits                  = decodeList3(map['rangeUnits']);
      _newPostErrorTitles          = decodeList3(map['newPostErrorTitles']);
      _newPostErrorBodies          = decodeList3(map['newPostErrorBodies']);
      _newFiltersFinalScreenButton = decodeList3(map['newFiltersFinalScreenButton']);
      _ntfTitleDesc                = decodeList3(map['ntfTitleDesc']);

      menuDepthNames              = decodeList3(map['menuDepthNames']);
      payments                    = decodeList3(map['payments']);

      filterDepths                = decodeList2(map['filterDepths']);
      rangesMinMax                = decodeList2(map['rangesMinMax']);
      rangeDivs                   = decodeList2(map['rangeDivs']);
      discreteRanges              = decodeList3(map['discreteRanges']);
   }

   Map<String, dynamic> toJson()
   {
      return
      {
         'appName':                     appName,
         'delOwnChatTitleStr':          _delOwnChatTitleStr,
         'delFavChatTitleStr':          _delFavChatTitleStr,
         'devChatOkStr':                _devChatOkStr,
         'delChatCancelStr':            _delChatCancelStr,
         'newPostAppBarTitle':          _newPostAppBarTitle,
         'filterAppBarTitle':           _filterAppBarTitle,
         'postRefSectionTitle':         _postRefSectionTitle,
         'postExDetailsTitle':          _postExDetailsTitle,
         'postDescTitle':               _postDescTitle,
         'newPostTextFieldHist':        _newPostTextFieldHist,
         'chatTextFieldHint':           _chatTextFieldHint,
         'nickHint':                    _nickHint,
         'emailHint':                   _emailHint,
         'msgOnRedirectingChat':        _msgOnRedirectingChat,
         'msgOnRedirectedChat':         _msgOnRedirectedChat,
         'msgOnEmptyChat':              _msgOnEmptyChat,
         'deleteChat':                  _deleteChat,
         'pinChat':                     _pinChat,
         'clearPosts':                  _clearPosts,
         'notificationsButton':         _notificationsButton,
         'unknownNick':                 _unknownNick,
         'selectAll':                   _selectAll,
         'changeNickHint':              _changeNickHint,
         'changeNotifications':         _changeNotifications,
         'dissmissedPost':              _dissmissedPost,
         'dismissedChat':               _dismissedChat,
         'ok':                          _ok,
         'cancel':                      _cancel,
         'cancelNewPost':               _cancelNewPost,
         'doNotShowAgain':              _doNotShowAgain,
         'next':                        _next,
         'rangesTitle':                 _rangesTitle,
         'paymentTitle':                _paymentTitle,
         'onEmptyNickTitle':            _onEmptyNickTitle,
         'onEmptyNickContent':          _onEmptyNickContent,
         'addImgMsg':                   _addImgMsg,
         'unreachableImgError':         _unreachableImgError,
         'clearPostsTitle':             _clearPostsTitle,
         'clearPostsContent':           _clearPostsContent,
         'localeName':                  _localeName,
         'typing':                      _typing,
         'cancelPost':                  _cancelPost,
         'cancelPostContent':           _cancelPostContent,
         'numberOfChatsSuffix':         _numberOfChatsSuffix,
         'numberOfUnreadChatsSuffix':   _numberOfUnreadChatsSuffix,
         'postMinImgs':                 _postMinImgs,
         'postMinImgsContent':          _postMinImgsContent,
         'changeNickAppBarTitle':       _changeNickAppBarTitle,
         'changeNtfAppBarTitle':        _changeNtfAppBarTitle,
         'tabNames':                    _tabNames,
         'newPostTabNames':             _newPostTabNames,
         'filterTabNames':              _filterTabNames,
         'descList':                    _descList,
         'dialogTitles':                _dialogTitles,
         'dialogBodies':                _dialogBodies,
         'rangePrefixes':               _rangePrefixes,
         'rangeUnits':                  _rangeUnits,
         'newPostErrorTitles':          _newPostErrorTitles,
         'newPostErrorBodies':          _newPostErrorBodies,
         'newFiltersFinalScreenButton': _newFiltersFinalScreenButton,
         'ntfTitleDesc':                _ntfTitleDesc,
         'menuDepthNames':              menuDepthNames,
         'payments':                    payments,
         'filterDepths':                filterDepths,
         'rangesMinMax':                rangesMinMax,
         'rangeDivs':                   rangeDivs,
         'discreteRanges':              discreteRanges,
      };
   }
}

