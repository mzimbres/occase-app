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

   ChatHistory(this.peer);
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
      ChatHistory history = GetChatHistory(peer);
      history.msgs.add(ChatItem(thisApp, msg));
   }

   ChatHistory GetChatHistory(String peer)
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
}

RichText createHeaderLine(BuildContext context, String key, String value)
{
   return RichText(
         text: TextSpan(
               text: key + ': ',
               //style: DefaultTextStyle.of(context).style,
               style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: Consts.mainFontSize),
               children: <TextSpan>[
                  TextSpan(text: value, style: TextStyle(fontWeight: FontWeight.normal)),
               ],
         ),
   );
}

Card advInnerCardFactory(BuildContext context,
      List<String> values, List<String> keys, String title)
{
   List<Widget> r = List<Widget>();
   if (title != null) {
       Text t = Text( title,
          style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 17.0,
                color: Colors.black,
             )
          );

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

Card advAssembler(BuildContext context, AdvData data,
                  Widget button, TextEditingController newAdvTextCtrl,
                  List<MenuItem> menus)
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
         color: Consts.advMsgColor,
         margin: EdgeInsets.all(Consts.advMarging),
         elevation: 0.0,
   );

   return adv1;
}


Card createNewAdvWidget(BuildContext context, AdvData data,
                        Function onPressed, String label,
                        TextEditingController newAdvTextCtrl,
                        List<MenuItem> menus)
{
   RaisedButton b = RaisedButton(
      child: Text(label),
      color: Theme.of(context).accentColor,
      highlightColor: const Color(0xff075E54),
      onPressed: onPressed,
   );

   // With an icon does not look very good.
   //CircleAvatar b = CircleAvatar( child: IconButton(
   //               icon: Icon(Icons.send),
   //               onPressed: onPressed,
   //               color: Theme.of(context).accentColor),
   //               backgroundColor: Theme.of(context).primaryColor
   //            );

   Card c4 = Card(
      child: b,
      color: Consts.advMsgColor,
      margin: EdgeInsets.all(Consts.advInnerMarging),
      elevation: 0.0,
   );

   return advAssembler(context, data, c4, newAdvTextCtrl, menus);
}

Widget createAdvTab(BuildContext context, List<AdvData> data,
                    Function onAdvSelection,
                    Function onNewAdv,
                    List<MenuItem> menus)
{
   return Scaffold( body:
         ListView.builder(
               padding: const EdgeInsets.all(0.0),
               itemCount: data.length,
               itemBuilder: (BuildContext context, int i)
               {
                  return createNewAdvWidget(context, data[i],
                        () {onAdvSelection(data[i]);},
                        TextConsts.advButtonText, null, menus);
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
               child: createListViewItem(child.name, subStr,
                     null, TextConsts.menuItemCircleColor),
               color: const Color(0xFFFFFF),
               highlightColor: const Color(0xFFFFFF),
               onPressed: () { onLeafPressed(i);},
            );
         }
         
         return FlatButton(
               child: createListViewItem(child.name, subStr,
                     null, TextConsts.menuItemCircleColor),
               color: const Color(0xFFFFFF),
               highlightColor: const Color(0xFFFFFF),
               onPressed: () { onNodePressed(i); },
         );
      },
   );
}

Widget createChatTab(
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
            return createNewAdvWidget(
                      context,
                      data[i],
                      () {onChat(i);},
                      buttonText,
                      null, menus);
         },
   );
}

ListView createOwnAdvInterestedListView(
            BuildContext context,
            List<ChatHistory> interested,
            Function onPressed)
{
   return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: interested.length,
      itemBuilder: (BuildContext context, int i)
      {
         return FlatButton(
               child: createListViewItem(
                     interested[i].peer, null, null,
                     TextConsts.menuItemCircleColor),
               color: const Color(0xFFFFFF),
               highlightColor: const Color(0xFFFFFF),
               onPressed: () { onPressed(interested[i].peer); },
         );
      },
   );
}

