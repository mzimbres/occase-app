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
   bool isLongPressed = false;

   ChatHistory(this.peer);

   void moveToReadHistory()
   {
      msgs.addAll(unreadMsgs);
      unreadMsgs.clear();
   }

   String getLastUnreadMsg()
   {
      if (unreadMsgs.isEmpty)
         return '';

      return unreadMsgs.last.msg;
   }

   int getNumberOfUnreadMsgs()
   {
      if (unreadMsgs.isEmpty)
         return 0;

      return unreadMsgs.length;
   }

   String getLastReadMsg()
   {
      if (msgs.isEmpty)
         return '';

      return msgs.last.msg;
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

   void createChatEntryForPeer(String peer)
   {
      ChatHistory history = ChatHistory(peer);
      chats.add(history);
   }

   ChatHistory getChatHistory(String peer)
   {
      final int i = chats.indexWhere((e) {return e.peer == peer;});

      if (i == -1) {
         // This is the first message with this user (peer).
         createChatEntryForPeer(peer);
         return chats.last;
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

   // This function will return true if there is any chat marked as
   // long pressed. It will traverse the AdvData array and stop at the
   // first AdvData::chats that has isLongPressed true.
   bool hasLongPressed()
   {
      for (ChatHistory ch in chats)
         if (ch.isLongPressed)
            return true;

      return false;
   }
}

bool hasLongPressed(final List<AdvData> advs)
{
   for (AdvData adv in advs)
      if (adv.hasLongPressed())
         return true;

   return false;
}

// Study how to convert this into an elipsis like whatsapp.
CircleAvatar makeCircleUnreadMsgs(int n,
                                  Color backgroundColor,
                                  Color textColor)
{
   if (n == 0)
      return CircleAvatar(backgroundColor: backgroundColor,
                maxRadius: 10.0);

   return CircleAvatar(
            child: Text("${n}",
                  style: TextStyle(
                  //fontWeight: FontWeight.bold,
                  fontSize: 11.0, color: textColor)),
            maxRadius: 10.0,
            backgroundColor: backgroundColor);
}

Card advElemFactory(BuildContext context,
                    List<String> values,
                    List<String> keys,
                    String title)
{
   List<Widget> r = List<Widget>();
   Text t = Text(title, style: TextConsts.menuTitleStl);
   r.add(Padding(
            child: Center(child: t),
            padding: EdgeInsets.all(4.0)));

   for (int i = 0; i < values.length; ++i) {
      RichText rt = RichText(
            text: TextSpan(
                  text: keys[i] + ': ',
                  style: TextConsts.menuTitleStl,
                  children: <TextSpan>[
                     TextSpan(text: values[i],
                              style: TextConsts.valueTextStl),
                  ],
            ),
         );

      r.add(rt);
   }

   // Padding needed to show the text inside the adv element with some
   // distance from the border.
   Padding padd = Padding(
         padding: EdgeInsets.all(TextConsts.advElemTextPadding),
         child: Column(
               crossAxisAlignment: CrossAxisAlignment.stretch,
               children: r,
            )
         );

   // Here we need another padding to make the adv inner element have
   // some distance to the outermost card.
   return Card(
            child: padd,
            color: Consts.advLocHeaderColor,
            margin: EdgeInsets.all(Consts.advInnerMargin),
            elevation: 0.0,
   );
}

List<Card>
makeMenuInfoCards(BuildContext context,
                  AdvData data,
                  List<MenuItem> menus,
                  Color color)
{
   List<Card> list = List<Card>();

   for (int i = 0; i < data.codes.length; ++i) {
      List<String> names =
            loadNames(menus[i].root.first, data.codes[i][0]);

      Card card = advElemFactory(
                  context,
                  names,
                  TextConsts.menuDepthNames[i],
                  TextConsts.newAdvTabNames[i]);

      list.add(card);
   }

   return list;
}

// Will assemble menu information and the description in cards
List<Card> advTextAssembler(BuildContext context,
                            AdvData data,
                            List<MenuItem> menus,
                            Color color)
{
   List<Card> list = makeMenuInfoCards(context, data, menus, color);

   Card descCard = advElemFactory(context,
                      <String>[data.description],
                      <String>[TextConsts.descriptionText],
                      "Detalhes do anunciante");

   list.add(descCard);

   return list;
}

Card makeTextSeparator(BuildContext context)
{
   return Card(
         child: Icon(Icons.message, color: Colors.white),
         color: Theme.of(context).primaryColor,
         elevation: 0.0);
}

Text makeChatSubStrWidget(ChatHistory ch)
{
   final String subTitle = ch.getLastUnreadMsg();

   if (subTitle.isEmpty) // There is no unread message.
      return createMenuItemSubStrWidget(ch.getLastReadMsg(),
                FontWeight.normal);

   return createMenuItemSubStrWidget(subTitle, FontWeight.bold);
}

Card createChatEntry(BuildContext context,
                     AdvData adv,
                     List<MenuItem> menus,
                     Widget chats)
{
   List<Card> cards = advTextAssembler(context, adv, menus,
                                       Theme.of(context).primaryColor);
   
   cards.add(makeTextSeparator(context));

   Card chatCard = Card(child: chats,
                        color: Theme.of(context).primaryColor,
                        margin: EdgeInsets.all(Consts.advInnerMargin),
                        elevation: 0.0);

   cards.add(chatCard);

   Column col = Column(children: cards);

   final double padding = TextConsts.outerAdvCardPadding;
   return Card(
      child: Padding(child: col, padding: EdgeInsets.all(padding)),
      color: Theme.of(context).primaryColor,
      margin: EdgeInsets.all(Consts.advMarging),
      elevation: 0.0,
   );
}

Card makeAdvWidget(BuildContext context,
                   List<Card> cards,
                   Function onPressed,
                   Icon icon,
                   Color color)
{
   IconButton icon1 = IconButton(
                         icon: Icon(Icons.clear, color: Colors.white),
                         iconSize: 30.0,
                         onPressed: () {onPressed(false);});

   IconButton icon2 = IconButton(
                         icon: icon,
                         onPressed: () {onPressed(true);},
                         color: Theme.of(context).primaryColor,
                         iconSize: 30.0);

   Row row = Row(children: <Widget>[
                Expanded(child: icon1),
                Expanded(child: icon2)]);

   Card c4 = Card(
      child: row,
      color: color,
      margin: EdgeInsets.all(Consts.advInnerMargin),
      elevation: 0.0,
   );

   cards.add(c4);

   Column col = Column(children: cards);

   final double padding = TextConsts.outerAdvCardPadding;
   return Card(
      child: Padding(child: col, padding: EdgeInsets.all(padding)),
      color: color,
      margin: EdgeInsets.all(Consts.advMarging),
      elevation: 0.0,
   );
}

Card makeTextInputFieldCard(TextEditingController ctrl)
{
   // TODO: Set a max length.
   return Card(
         child: Padding(
               child: TextField(
                  controller: ctrl,
                  //textInputAction: TextInputAction.go,
                  //onSubmitted: onTextFieldPressed,
                  keyboardType: TextInputType.multiline,
                  maxLines: null,
                  decoration: InputDecoration(
                        hintText: TextConsts.newAdvDescDeco)),
               padding: EdgeInsets.all(
                     TextConsts.advElemTextPadding)
            ),
         color: Consts.advLocHeaderColor,
         margin: EdgeInsets.all(Consts.advInnerMargin),
         elevation: 0.0,
   );
}

Widget makeAdvTab(BuildContext context,
                  List<AdvData> advs,
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
                  Color color = Theme.of(context).primaryColor;
                  if (i < numberOfNewAdvs)
                     color = TextConsts.newReceivedAdvColor; 

                  List<Card> cards = advTextAssembler(
                                        context,
                                        advs[i],
                                        menus,
                                        Theme.of(context).primaryColor);
   
                  return makeAdvWidget(
                            context,
                            cards,
                            (fav) {onAdvSelection(advs[idx], fav);},
                            Icon(Icons.star, color: Colors.amber), color);
               },
         ),

         backgroundColor: Consts.scaffoldBackground,
         floatingActionButton: FloatingActionButton(
               backgroundColor: Theme.of(context).primaryColor,
               child: Icon( TextConsts.newAdvIcon,
                            color: Colors.white),
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
         final String firstLetter = getFirstLetter(child.name);
         final String subStr = makeSubItemsString(child.leafCounter);
         if (child.isLeaf()) {
            return createListViewItem(
                         context,
                         child.name,
                         createMenuItemSubStrWidget(
                               subStr,
                               FontWeight.normal),
                         null,
                         Theme.of(context).primaryColor,
                         () { onLeafPressed(i);},
                         (){},
                         Text(firstLetter,
                              style: TextConsts.firstLetterStl));
         }
         
         return createListViewItem(
                         context,
                         child.name,
                         createMenuItemSubStrWidget(
                               subStr,
                               FontWeight.normal),
                         null,
                         Theme.of(context).primaryColor,
                         () { onNodePressed(i); },
                         (){},
                         Text(firstLetter,
                              style: TextConsts.firstLetterStl));
      },
   );
}

Column makeAdvChatCol(BuildContext context,
                      List<ChatHistory> ch,
                      Function onPressed,
                      Function onLongPressed)
{
   List<Widget> list = List<Widget>(ch.length);

   for (int i = 0; i < list.length; ++i) {
      final int n = ch[i].getNumberOfUnreadMsgs();
      Widget widget;
      Color bgColor;
      if (ch[i].isLongPressed) {
         widget = Icon(Icons.check);
         bgColor = Theme.of(context).accentColor;
      } else {
         final String firstLetter = getFirstLetter(ch[i].peer);
         widget = Text(firstLetter, style: TextConsts.firstLetterStl);
         bgColor = Colors.white;
      }

      Color cc = Theme.of(context).primaryColor;
      if (n == 0)
         cc = bgColor;

      ListTile lt = createListViewItem(context,
                        ch[i].peer,
                        makeChatSubStrWidget(ch[i]),
                        makeCircleUnreadMsgs(n, cc, Colors.white),
                        Theme.of(context).primaryColor,
                        () { onPressed(i); },
                        () { onLongPressed(i); },
                        widget);

      list[i] = Container(decoration: BoxDecoration(color: bgColor),
                  child: lt);
   }

   return Column(children: list);
}

Widget makeAdvChatTab(
         BuildContext context,
         List<AdvData> data,
         Function onPressed,
         Function onLongPressed,
         List<MenuItem> menus)
{
   return ListView.builder(
         padding: const EdgeInsets.all(0.0),
         itemCount: data.length,
         itemBuilder: (BuildContext context, int i)
         {
            return createChatEntry(
                      context,
                      data[i],
                      menus,
                      makeAdvChatCol(
                            context,
                            data[i].chats,
                            (j) {onPressed(i, j);},
                            (j) {onLongPressed(i, j);}));
         },
   );
}

