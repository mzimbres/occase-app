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
   String appName;
   String delOwnChatTitleStr;
   String delFavChatTitleStr;
   String devChatOkStr;
   String delChatCancelStr;
   String newPostAppBarTitle;
   String filterAppBarTitle;
   String postRefSectionTitle;
   String postExDetailsTitle;
   String postDescTitle;
   String newPostTextFieldHist;
   String chatTextFieldHint;
   String nickHint;
   String emailHint;
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
   , this.delOwnChatTitleStr = ''
   , this.delFavChatTitleStr = ''
   , this.devChatOkStr = ''
   , this.delChatCancelStr = ''
   , this.newPostAppBarTitle = ''
   , this.filterAppBarTitle = ''
   , this.postRefSectionTitle = ''
   , this.postExDetailsTitle = ''
   , this.postDescTitle = ''
   , this.newPostTextFieldHist = ''
   , this.chatTextFieldHint = ''
   , this.nickHint = ''
   , this.emailHint = ''
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

   Parameters.fromJson(Map<String, dynamic> map)
   {
      appName                     = map['appName'];
      delOwnChatTitleStr          = map['delOwnChatTitleStr'];
      delFavChatTitleStr          = map['delFavChatTitleStr'];
      devChatOkStr                = map['devChatOkStr'];
      delChatCancelStr            = map['delChatCancelStr'];
      newPostAppBarTitle          = map['newPostAppBarTitle'];
      filterAppBarTitle           = map['filterAppBarTitle'];
      postRefSectionTitle         = map['postRefSectionTitle'];
      postExDetailsTitle          = map['postExDetailsTitle'];
      postDescTitle               = map['postDescTitle'];
      newPostTextFieldHist        = map['newPostTextFieldHist'];
      chatTextFieldHint           = map['chatTextFieldHint'];
      nickHint                    = map['nickHint'];
      emailHint                   = map['emailHint'];
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
         'delOwnChatTitleStr':          delOwnChatTitleStr,
         'delFavChatTitleStr':          delFavChatTitleStr,
         'devChatOkStr':                devChatOkStr,
         'delChatCancelStr':            delChatCancelStr,
         'newPostAppBarTitle':          newPostAppBarTitle,
         'filterAppBarTitle':           filterAppBarTitle,
         'postRefSectionTitle':         postRefSectionTitle,
         'postExDetailsTitle':          postExDetailsTitle,
         'postDescTitle':               postDescTitle,
         'newPostTextFieldHist':        newPostTextFieldHist,
         'chatTextFieldHint':           chatTextFieldHint,
         'nickHint':                    nickHint,
         'emailHint':                   emailHint,
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

