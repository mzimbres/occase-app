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

// Study how to convert this into an elipsis like whatsapp.
CircleAvatar makeCircleUnreadMsgs(int n, Color backgroundColor)
{
   if (n == 0)
      return CircleAvatar(backgroundColor: backgroundColor,
                maxRadius: 10.0);

   return CircleAvatar(
            child: Text("${n}",
                  style: TextStyle(
                  //fontWeight: FontWeight.bold,
                  fontSize: 11.0 )),
            maxRadius: 10.0,
            backgroundColor: backgroundColor);
}

Card advElemFactory(BuildContext context,
                    List<String> values,
                    List<String> keys,
                    String title)
{
   List<Widget> r = List<Widget>();
   Text t = Text(title, style: Theme.of(context).textTheme.subhead);
   r.add(Center(child:t));

   for (int i = 0; i < values.length; ++i) {
      RichText rt = RichText(
            text: TextSpan(
                  text: keys[i] + ': ',
                  style: Theme.of(context).textTheme.body2,
                  children: <TextSpan>[
                     TextSpan(text: values[i], style:
                           Theme.of(context).textTheme.body1),
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
         child: Icon(Icons.message),
         color: Theme.of(context).accentColor,
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

FlatButton makeChatItemButton(BuildContext context,
                              ChatHistory ch,
                              Function onPressed)
{
   // This adv should have only one chat history since it is not our
   // own adv.
   final Color bgColor = const Color(0xFFFFFF);
   final int n = ch.getNumberOfUnreadMsgs();
   Color cc = Theme.of(context).accentColor;
   if (n == 0)
      cc = bgColor;

   ListTile lt = createListViewItem(
                    context,
                    ch.peer,
                    makeChatSubStrWidget(ch),
                    makeCircleUnreadMsgs(n, cc),
                    Theme.of(context).primaryColor);

   return FlatButton(
             child: lt,
             color: TextConsts.favChatButtonColor,
             highlightColor: bgColor,
             onPressed: onPressed,
   );
}

Card createChatEntry(BuildContext context,
                     AdvData adv,
                     List<MenuItem> menus,
                     Widget chats)
{
   List<Card> cards = advTextAssembler(context, adv, menus,
                                       Theme.of(context).accentColor);
   
   cards.add(makeTextSeparator(context));

   Card chatCard = Card(child: chats,
                        color: Theme.of(context).accentColor,
                        margin: EdgeInsets.all(Consts.advInnerMargin),
                        elevation: 0.0);

   cards.add(chatCard);

   Column col = Column(children: cards);

   final double padding = TextConsts.outerAdvCardPadding;
   return Card(
      child: Padding(child: col, padding: EdgeInsets.all(padding)),
      color: Theme.of(context).accentColor,
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
                         icon: Icon(Icons.clear, color: Colors.red),
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
                  Color color = Theme.of(context).accentColor;
                  if (i < numberOfNewAdvs)
                     color = TextConsts.newReceivedAdvColor; 

                  List<Card> cards = advTextAssembler(
                                        context,
                                        advs[i],
                                        menus,
                                        Theme.of(context).accentColor);
   
                  return makeAdvWidget(
                            context,
                            cards,
                            (fav) {onAdvSelection(advs[idx], fav);},
                            Icon(Icons.star, color: Colors.amber), color);
               },
         ),

         backgroundColor: Consts.scaffoldBackground,
         floatingActionButton: FloatingActionButton(
               backgroundColor: Theme.of(context).accentColor,
               child: Icon( TextConsts.newAdvIcon,
                            color: Theme.of(context).primaryColor),
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
               child: createListViewItem(
                         context,
                         child.name,
                         createMenuItemSubStrWidget(
                               subStr,
                               FontWeight.normal),
                         null,
                         Theme.of(context).primaryColor),
               color: const Color(0xFFFFFF),
               highlightColor: const Color(0xFFFFFF),
               onPressed: () { onLeafPressed(i);},
            );
         }
         
         return FlatButton(
               child: createListViewItem(
                         context,
                         child.name,
                         createMenuItemSubStrWidget(
                               subStr,
                               FontWeight.normal),
                         null,
                         Theme.of(context).primaryColor),
               color: const Color(0xFFFFFF),
               highlightColor: const Color(0xFFFFFF),
               onPressed: () { onNodePressed(i); },
         );
      },
   );
}

Column createOwnAdvInterestedListView(
            BuildContext context,
            List<ChatHistory> ch,
            Function onPressed)
{
   List<Widget> list = List<Widget>(ch.length);

   for (int i = 0; i < list.length; ++i)
      list[i] = makeChatItemButton(
                   context,
                   ch[i],
                   () { onPressed(i); });

   return Column(children: list);
}

Widget createOwnAdvChatTab(
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
            return createChatEntry(
                      context,
                      data[i],
                      menus,
                      createOwnAdvInterestedListView(
                            context,
                            data[i].chats,
                            (j) {onChat(i, j);}));
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
            return createChatEntry(
                      context,
                      data[i],
                      menus,
                      makeChatItemButton(
                            context,
                            data[i].getChatHistory(data[i].from),
                            () {onChat(i);}));
         },
   );
}

