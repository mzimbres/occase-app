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
   int _langIdx = 1;
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
   String msgOnRedirectingChat;
   String msgOnRedirectedChat;
   String msgOnEmptyChat;
   String deleteChat;
   String pinChat;
   String clearPosts;
   String notificationsButton;
   String unknownNick;
   String selectAll;
   String changeNickHint;
   String changeNotifications;
   String dissmissedPost;
   String dismissedChat;
   String ok;
   String cancel;
   String cancelNewPost;
   String doNotShowAgain;
   String next;
   String rangesTitle;
   String paymentTitle;
   String onEmptyNickTitle;
   String onEmptyNickContent;
   String addImgMsg;
   String unreachableImgError;
   String clearPostsTitle;
   String clearPostsContent;
   String localeName;
   String typing;
   String cancelPost;
   String cancelPostContent;
   String numberOfChatsSuffix;
   String numberOfUnreadChatsSuffix;
   String postMinImgs;
   String postMinImgsContent;
   String changeNickAppBarTitle;
   String changeNtfAppBarTitle;

   List<int> filterDepths;
   List<int> rangesMinMax;
   List<int> rangeDivs;

   List<String> tabNames;
   List<String> newPostTabNames;
   List<String> filterTabNames;
   List<String> descList;
   List<String> dialogTitles;
   List<String> dialogBodies;
   List<String> rangePrefixes;
   List<String> rangeUnits;
   List<String> newPostErrorTitles;
   List<String> newPostErrorBodies;
   List<String> newFiltersFinalScreenButton;
   List<String> ntfTitleDesc;

   List<List<String>> menuDepthNames;
   List<List<String>> payments;
   List<List<int>> discreteRanges;

   Parameters(
   { this.appName = 'Occase'
   , this.msgOnRedirectingChat = ''
   , this.msgOnRedirectedChat = ''
   , this.msgOnEmptyChat = ''
   , this.deleteChat = ''
   , this.pinChat = ''
   , this.clearPosts = ''
   , this.notificationsButton = ''
   , this.unknownNick = ''
   , this.selectAll = ''
   , this.changeNickHint = ''
   , this.changeNotifications = ''
   , this.dissmissedPost = ''
   , this.dismissedChat = ''
   , this.ok = ''
   , this.cancel = ''
   , this.cancelNewPost = ''
   , this.doNotShowAgain = ''
   , this.next = ''
   , this.rangesTitle = ''
   , this.paymentTitle = ''
   , this.onEmptyNickTitle = ''
   , this.onEmptyNickContent = ''
   , this.addImgMsg = ''
   , this.unreachableImgError = ''
   , this.clearPostsTitle = ''
   , this.clearPostsContent = ''
   , this.localeName = ''
   , this.typing = ''
   , this.cancelPost = ''
   , this.cancelPostContent = ''
   , this.numberOfChatsSuffix = ''
   , this.numberOfUnreadChatsSuffix = ''
   , this.postMinImgs = ''
   , this.postMinImgsContent = ''
   , this.changeNickAppBarTitle = ''
   , this.changeNtfAppBarTitle = ''
   , this.filterDepths = const <int>[3, 3]
   , this.rangesMinMax = const <int>[0, 256000, 0, 2030, 0, 100000]
   , this.rangeDivs = const <int>[100, 100, 100]
   , this.tabNames = const <String>['' ,'' , '']
   , this.newPostTabNames = const <String>['', '', '', '']
   , this.filterTabNames = const <String>['', '', '', '']
   , this.descList = const <String>['', '', '', '', '']
   , this.dialogTitles = const <String>['' ,'' ,'' ,'' , '']
   , this.dialogBodies = const <String>['', '', '', '', '']
   , this.rangePrefixes = const <String>['','' ,'' ]
   , this.rangeUnits = const <String>['', '', '', '', '', '']
   , this.newPostErrorTitles = const <String>[ '', '']
   , this.newPostErrorBodies = const <String> ['' , '']
   , this.newFiltersFinalScreenButton = const <String>['', '', '']
   , this.ntfTitleDesc = const <String>['', '']
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
      _langIdx = 0;
   }

   String get delOwnChatTitleStr   => _delOwnChatTitleStr[_langIdx];
   String get delFavChatTitleStr   => _delFavChatTitleStr[_langIdx];
   String get devChatOkStr         => _devChatOkStr[_langIdx];
   String get delChatCancelStr     => _delChatCancelStr[_langIdx];
   String get newPostAppBarTitle   => _newPostAppBarTitle[_langIdx];
   String get filterAppBarTitle    => _filterAppBarTitle[_langIdx];
   String get postRefSectionTitle  => _postRefSectionTitle[_langIdx];
   String get postExDetailsTitle   => _postExDetailsTitle[_langIdx];
   String get postDescTitle        => _postDescTitle[_langIdx];
   String get newPostTextFieldHist => _newPostTextFieldHist[_langIdx];
   String get chatTextFieldHint    => _chatTextFieldHint[_langIdx];
   String get nickHint             => _nickHint[_langIdx];
   String get emailHint            => _emailHint[_langIdx];

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
      msgOnRedirectingChat        = map['msgOnRedirectingChat'];
      msgOnRedirectedChat         = map['msgOnRedirectedChat'];
      msgOnEmptyChat              = map['msgOnEmptyChat'];
      deleteChat                  = map['deleteChat'];
      pinChat                     = map['pinChat'];
      clearPosts                  = map['clearPosts'];
      notificationsButton         = map['notificationsButton'];
      unknownNick                 = map['unknownNick'];
      selectAll                   = map['selectAll'];
      changeNickHint              = map['changeNickHint'];
      changeNotifications         = map['changeNotifications'];
      dissmissedPost              = map['dissmissedPost'];
      dismissedChat               = map['dismissedChat'];
      ok                          = map['ok'];
      cancel                      = map['cancel'];
      cancelNewPost               = map['cancelNewPost'];
      doNotShowAgain              = map['doNotShowAgain'];
      next                        = map['next'];
      rangesTitle                 = map['rangesTitle'];
      paymentTitle                = map['paymentTitle'];
      onEmptyNickTitle            = map['onEmptyNickTitle'];
      onEmptyNickContent          = map['onEmptyNickContent'];
      addImgMsg                   = map['addImgMsg'];
      unreachableImgError         = map['unreachableImgError'];
      clearPostsTitle             = map['clearPostsTitle'];
      clearPostsContent           = map['clearPostsContent'];
      localeName                  = map['localeName'];
      typing                      = map['typing'];
      cancelPost                  = map['cancelPost'];
      cancelPostContent           = map['cancelPostContent'];
      numberOfChatsSuffix         = map['numberOfChatsSuffix'];
      numberOfUnreadChatsSuffix   = map['numberOfUnreadChatsSuffix'];
      postMinImgs                 = map['postMinImgs'];
      postMinImgsContent          = map['postMinImgsContent'];
      changeNickAppBarTitle       = map['changeNickAppBarTitle'];
      changeNtfAppBarTitle        = map['changeNtfAppBarTitle'];
      filterDepths                = decodeList2(map['filterDepths']);
      rangesMinMax                = decodeList2(map['rangesMinMax']);
      rangeDivs                   = decodeList2(map['rangeDivs']);
      tabNames                    = decodeList2(map['tabNames']);
      newPostTabNames             = decodeList2(map['newPostTabNames']);
      filterTabNames              = decodeList2(map['filterTabNames']);
      descList                    = decodeList2(map['descList']);
      dialogTitles                = decodeList2(map['dialogTitles']);
      dialogBodies                = decodeList2(map['dialogBodies']);
      rangePrefixes               = decodeList2(map['rangePrefixes']);
      rangeUnits                  = decodeList2(map['rangeUnits']);
      newPostErrorTitles          = decodeList2(map['newPostErrorTitles']);
      newPostErrorBodies          = decodeList2(map['newPostErrorBodies']);
      newFiltersFinalScreenButton = decodeList2(map['newFiltersFinalScreenButton']);
      ntfTitleDesc                = decodeList2(map['ntfTitleDesc']);
      menuDepthNames              = decodeList3(map['menuDepthNames']);
      payments                    = decodeList3(map['payments']);
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
         'msgOnRedirectingChat':        msgOnRedirectingChat,
         'msgOnRedirectedChat':         msgOnRedirectedChat,
         'msgOnEmptyChat':              msgOnEmptyChat,
         'deleteChat':                  deleteChat,
         'pinChat':                     pinChat,
         'clearPosts':                  clearPosts,
         'notificationsButton':         notificationsButton,
         'unknownNick':                 unknownNick,
         'selectAll':                   selectAll,
         'changeNickHint':              changeNickHint,
         'changeNotifications':         changeNotifications,
         'dissmissedPost':              dissmissedPost,
         'dismissedChat':               dismissedChat,
         'ok':                          ok,
         'cancel':                      cancel,
         'cancelNewPost':               cancelNewPost,
         'doNotShowAgain':              doNotShowAgain,
         'next':                        next,
         'rangesTitle':                 rangesTitle,
         'paymentTitle':                paymentTitle,
         'onEmptyNickTitle':            onEmptyNickTitle,
         'onEmptyNickContent':          onEmptyNickContent,
         'addImgMsg':                   addImgMsg,
         'unreachableImgError':         unreachableImgError,
         'clearPostsTitle':             clearPostsTitle,
         'clearPostsContent':           clearPostsContent,
         'localeName':                  localeName,
         'typing':                      typing,
         'cancelPost':                  cancelPost,
         'cancelPostContent':           cancelPostContent,
         'numberOfChatsSuffix':         numberOfChatsSuffix,
         'numberOfUnreadChatsSuffix':   numberOfUnreadChatsSuffix,
         'postMinImgs':                 postMinImgs,
         'postMinImgsContent':          postMinImgsContent,
         'changeNickAppBarTitle':       changeNickAppBarTitle,
         'changeNtfAppBarTitle':        changeNtfAppBarTitle,
         'filterDepths':                filterDepths,
         'rangesMinMax':                rangesMinMax,
         'rangeDivs':                   rangeDivs,
         'tabNames':                    tabNames,
         'newPostTabNames':             newPostTabNames,
         'filterTabNames':              filterTabNames,
         'descList':                    descList,
         'dialogTitles':                dialogTitles,
         'dialogBodies':                dialogBodies,
         'rangePrefixes':               rangePrefixes,
         'rangeUnits':                  rangeUnits,
         'newPostErrorTitles':          newPostErrorTitles,
         'newPostErrorBodies':          newPostErrorBodies,
         'newFiltersFinalScreenButton': newFiltersFinalScreenButton,
         'ntfTitleDesc':                ntfTitleDesc,
         'menuDepthNames':              menuDepthNames,
         'payments':                    payments,
         'discreteRanges':              discreteRanges,
      };
   }
}

