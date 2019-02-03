import 'package:flutter/material.dart';
import 'package:menu_chat/constants.dart';
import 'package:menu_chat/menu_tree.dart';
import 'package:menu_chat/menu.dart';
import 'package:menu_chat/text_constants.dart';

class ChatItem {
   bool thisApp; 
   String msg = '';
   ChatItem(this.thisApp, this.msg) { }
}

class ChatHistory {
   String peer = '';
   List<ChatItem> msgs = List<ChatItem>();
   List<ChatItem> unreadMsgs = List<ChatItem>();

   ChatHistory(this.peer);

   void moveToReadHistory()
   {
      msgs.addAll(unreadMsgs);
      unreadMsgs.clear();
   }

   // TODO: Change this to return Text so that it is possible to
   // return bold if unread.
   String getLastMsg()
   {
      if (unreadMsgs.length != 0)
         return unreadMsgs.last.msg;
      if (msgs.length != 0)
         return msgs.last.msg;

      return '';
   }
}

class AdvData {
   // The person that published this adv.
   String from = '';

   // Together with *from* this is a unique identifier for this adv.
   // This value is sent by the server.
   int id;

   // Contains channel codes in the form
   //
   //  [[[1, 2]], [[3, 2]], [[3, 2, 1, 1]]]
   //
   List<List<List<int>>> codes;

   // The string *description* inputed when user writes an adv.
   String description = '';

   List<ChatHistory> chats = List<ChatHistory>();

   AdvData()
   {
      codes = List<List<List<int>>>(TextConsts.menuDepthNames.length);
      for (int i = 0; i < codes.length; ++i) {
         codes[i] = List<List<int>>(1);
         codes[i][0] = List<int>();
      }
   }

   AdvData clone()
   {
      AdvData ret = AdvData();
      ret.codes = List<List<List<int>>>.from(this.codes);
      ret.description = this.description;
      ret.chats = List<ChatHistory>.from(this.chats);
      return ret;
   }

   void addMsg(String peer, String msg, bool thisApp)
   {
      ChatHistory history = getChatHistory(peer);
      history.msgs.add(ChatItem(thisApp, msg));
   }

   void addUnreadMsg(String peer, String msg, bool thisApp)
   {
      ChatHistory history = getChatHistory(peer);
      history.unreadMsgs.add(ChatItem(thisApp, msg));
   }

   ChatHistory getChatHistory(String peer)
   {
      final int i = chats.indexWhere((e) {return e.peer == peer;});

      if (i == -1) {
         // This is the first message with this user (peer).
         ChatHistory history = ChatHistory(peer);
         chats.add(history);
         return history;
      }

      return chats[i];
   }

   int getNumberOfUnreadChats()
   {
      int i = 0;
      for (ChatHistory h in chats)
         if (!h.unreadMsgs.isEmpty)
            ++i;

      return i;
   }
}

RichText createHeaderLine(BuildContext context, String key, String value)
{
   return RichText(
         text: TextSpan(
               text: key + ': ',
               style: Theme.of(context).textTheme.body1,
               children: <TextSpan>[
                  TextSpan(text: value, style:
                        Theme.of(context).textTheme.body2),
               ],
         ),
   );
}

Card advInnerCardFactory(BuildContext context,
      List<String> values, List<String> keys, String title)
{
   List<Widget> r = List<Widget>();
   if (title != null) {
       Text t = Text(title, style:
             Theme.of(context).textTheme.title);
       r.add(Center(child:t));
   }

   for (int i = 0; i < values.length; ++i) {
      r.add(createHeaderLine(context, keys[i], values[i]));
   }

   Padding padd = Padding( padding: EdgeInsets.all(4.0),
         child: Column(
               crossAxisAlignment: CrossAxisAlignment.stretch,
               children: r,
            )
         );

   return Card(
            child: padd,
            color: Consts.advLocHeaderColor,
            margin: EdgeInsets.all(Consts.advInnerMarging),
            elevation: 0.0,
   );
}

Card advAssembler(BuildContext context,
                  AdvData data,
                  Widget button,
                  TextEditingController newAdvTextCtrl,
                  List<MenuItem> menus,
                  Color color)
{
   List<Card> list = List<Card>();
   final int length = data.codes.length;
   for (int i = 0; i < length; ++i) {
      List<String> names =
            loadNames(menus[i].root.first, data.codes[i][0]);
      list.add(advInnerCardFactory(context, names,
                  TextConsts.menuDepthNames[i],
                  TextConsts.newAdvTabNames[i]),
            );
   }

   if (newAdvTextCtrl == null)
      list.add(advInnerCardFactory(context,
                  <String>[data.description],
                  <String>[TextConsts.descriptionText], null));

   if (newAdvTextCtrl != null) {
      // TODO: Set a max length.
      Card textInput = Card(
            child: TextField(
               controller: newAdvTextCtrl,
               //textInputAction: TextInputAction.go,
               //onSubmitted: onTextFieldPressed,
               keyboardType: TextInputType.multiline,
               maxLines: null,
               decoration: InputDecoration(
                     hintText: TextConsts.newAdvDescDeco),
               ),
            color: Consts.advLocHeaderColor,
            margin: EdgeInsets.all(Consts.advInnerMarging),
            elevation: 0.0,
      );
      list.add(textInput);
   }

   list.add(button);

   Card adv1 = Card(
         child: Column(crossAxisAlignment: CrossAxisAlignment.stretch,
            children: list),
         color: color,
         margin: EdgeInsets.all(Consts.advMarging),
         elevation: 0.0,
   );

   return adv1;
}

Card createFavAdvWidget(BuildContext context,
                        AdvData adv,
                        Function onPressed,
                        List<MenuItem> menus)
{
   final String subTitle = adv.getChatHistory(adv.from).getLastMsg();
   FlatButton button = FlatButton(
         child: createListViewItem(
               context,
               adv.from,
               subTitle,
               null,
               Theme.of(context).primaryColor),
         color: const Color(0xFFFFFF),
         highlightColor: const Color(0xFFFFFF),
         onPressed: onPressed,
   );

   Card c4 = Card(
      child: button,
      color: Colors.white,
      margin: EdgeInsets.all(Consts.advInnerMarging),
      elevation: 0.0,
   );

   Color color = Theme.of(context).accentColor;
   return advAssembler(context, adv, c4, null, menus, color);
}

Card createAdvWidget(BuildContext context, AdvData data,
                     Function onPressed, String label,
                     TextEditingController newAdvTextCtrl,
                     List<MenuItem> menus,
                     Icon i1, Icon i2, Color newAdvColor)
{
   IconButton icon1 = IconButton(
                     icon: i1,
                     iconSize: 30.0,
                     onPressed: () {onPressed(false);},
                  );

   IconButton  icon2 = IconButton(
                     icon: i2,
                     onPressed: () {onPressed(true);},
                     color: Theme.of(context).primaryColor,
                     iconSize: 30.0
                  );

   Row r = Row(children: <Widget>[Expanded(child: icon1),
         Expanded(child: icon2)]);

   Card c4 = Card(
      child: r,
      color: newAdvColor,
      margin: EdgeInsets.all(Consts.advInnerMarging),
      elevation: 0.0,
   );

   return advAssembler(context, data, c4, newAdvTextCtrl,
         menus, newAdvColor);
}

ListView createOwnAdvInterestedListView(
            BuildContext context,
            List<ChatHistory> interested,
            Function onPressed)
{
   return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: interested.length,
      shrinkWrap: true,
      itemBuilder: (BuildContext context, int i)
      {
         return FlatButton(
               child: createListViewItem(
                     context,
                     interested[i].peer,
                     interested[i].getLastMsg(),
                     null,
                     Theme.of(context).primaryColor),
               color: const Color(0xFFFFFF),
               highlightColor: const Color(0xFFFFFF),
               onPressed: () { onPressed(i); },
         );
      },
   );
}

Card createOwnAdvWidget(BuildContext context,
                        AdvData adv,
                        Function onPressed,
                        String label,
                        TextEditingController newAdvTextCtrl,
                        List<MenuItem> menus,
                        Icon i1)
{
   ListView lv = createOwnAdvInterestedListView(
               context,
               adv.chats,
               onPressed);

   Card card = Card(
      child: lv,
      color: Colors.white,
      margin: EdgeInsets.all(Consts.advInnerMarging),
      elevation: 0.0,
   );

   Color color = Theme.of(context).accentColor;
   return advAssembler(context, adv, card, newAdvTextCtrl,
         menus, color);
}

Card createNewAdvWidget(BuildContext context, AdvData data,
                        Function onPressed, String label,
                        TextEditingController newAdvTextCtrl,
                        List<MenuItem> menus, Icon i1)
{
   IconButton publish = IconButton(
                     icon: i1,
                     onPressed: onPressed,
                     color: Theme.of(context).primaryColor,
                     iconSize: 35.0
                  );

   Color color = Theme.of(context).accentColor;
   Card c4 = Card(
      child: publish,
      color: color,
      margin: EdgeInsets.all(Consts.advInnerMarging),
      elevation: 0.0,
   );

   return advAssembler(context, data, c4, newAdvTextCtrl,
         menus, color);
}

Widget createAdvTab(BuildContext context, List<AdvData> advs,
                    Function onAdvSelection,
                    Function onNewAdv,
                    List<MenuItem> menus,
                    int numberOfNewAdvs)
{
   final int advsLength = advs.length;

   return Scaffold( body:
         ListView.builder(
               padding: const EdgeInsets.all(0.0),
               itemCount: advsLength,
               itemBuilder: (BuildContext context, int i)
               {
                  // Advs are shown in reverse order.
                  final int idx = advsLength - i - 1;

                  // New advs are shown with a different color.
                  Color color = Theme.of(context).accentColor;
                  if (i < numberOfNewAdvs)
                     color = Colors.brown[200]; 

                  return createAdvWidget(
                        context,
                        advs[i],
                        (fav) {onAdvSelection(advs[idx], fav);},
                        TextConsts.advButtonText,
                        null, menus,
                        Icon(Icons.clear, color: Colors.red),
                        Icon(Icons.star), color);
               },
         ),

         backgroundColor: Consts.scaffoldBackground,
         floatingActionButton: FloatingActionButton(
               backgroundColor: Theme.of(context).accentColor,
               child: Icon(TextConsts.newAdvIcon, color: Colors.white),
               onPressed: onNewAdv,
         ),
   );
}

ListView createAdvMenuListView(BuildContext context, MenuNode o,
      Function onLeafPressed, Function onNodePressed)
{
   return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: o.children.length,
      itemBuilder: (BuildContext context, int i)
      {
         MenuNode child = o.children[i];
         final String subStr = makeSubItemsString(child.leafCounter);
         if (child.isLeaf()) {
            return FlatButton(
               child: createListViewItem(context, child.name, subStr,
                     null,
                     Theme.of(context).primaryColor),
               color: const Color(0xFFFFFF),
               highlightColor: const Color(0xFFFFFF),
               onPressed: () { onLeafPressed(i);},
            );
         }
         
         return FlatButton(
               child: createListViewItem(context, child.name, subStr,
                     null,
                     Theme.of(context).primaryColor),
               color: const Color(0xFFFFFF),
               highlightColor: const Color(0xFFFFFF),
               onPressed: () { onNodePressed(i); },
         );
      },
   );
}

Widget createOwnAdvChatTab(
         BuildContext context,
         List<AdvData> data,
         Function onChat,
         String buttonText,
         List<MenuItem> menus)
{
   return ListView.builder(
         padding: const EdgeInsets.all(0.0),
         itemCount: data.length,
         itemBuilder: (BuildContext context, int i)
         {
            return createOwnAdvWidget(
                      context,
                      data[i],
                      (j) {onChat(i, j);},
                      buttonText,
                      null,
                      menus,
                      Icon(Icons.group));
         },
   );
}

Widget createFavChatTab(
         BuildContext context,
         List<AdvData> data,
         Function onChat,
         List<MenuItem> menus)
{
   return ListView.builder(
         padding: const EdgeInsets.all(0.0),
         itemCount: data.length,
         itemBuilder: (BuildContext context, int i)
         {
            return createFavAdvWidget(
                      context,
                      data[i],
                      () {onChat(i);},
                      menus);
         },
   );
}

