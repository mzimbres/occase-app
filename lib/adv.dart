import 'package:flutter/material.dart';
import 'package:menu_chat/constants.dart';
import 'package:menu_chat/menu_tree.dart';
import 'package:menu_chat/menu.dart';
import 'package:menu_chat/text_constants.dart';

class KeyValuePair {
   String key;
   String value;
   KeyValuePair(this.key, this.value);

   KeyValuePair clone()
   {
      return KeyValuePair(this.key, this.value);
   }
}

class AdvData {
     List<List<KeyValuePair>> infos;

     AdvData()
     {
        int length = TextConsts.advAppBarMsg.length;
        infos = List<List<KeyValuePair>>(length);
        for (int i = 0; i < length; ++i)
           infos[i] = List<KeyValuePair>();
     }

     AdvData clone()
     {
         AdvData ret = AdvData();
         for (int i = 0; i < this.infos.length; ++i) {
            for (int j = 0; j < this.infos[i].length; ++j) {
               ret.infos[i].add(this.infos[i][j].clone());
            }
         }

         return ret;
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

Padding headerFactory(BuildContext context,
                      List<KeyValuePair> values,
                      List<String> keys)
{
   print("${keys.length} != ${values.length}");

   List<RichText> r = List<RichText>();
   for (int i = 0; i < values.length; ++i) {
      r.add(createHeaderLine(context, keys[i + 1], values[i].value));
   }

   return Padding( padding: EdgeInsets.all(4.0),
         child: Column( crossAxisAlignment: CrossAxisAlignment.stretch,
               children: r,
         ));
}

Card advAssembler(BuildContext context, AdvData data,
                  Widget button, TextEditingController newAdvTextCtrl)
{
   // This function assumes the description fields is the last in the
   // array.
   List<Card> list = List<Card>();

   int length = data.infos.length;
   if (newAdvTextCtrl != null)
      --length;

   //assert(data.infos.length == TextConsts.menuDepthNames.length);

   for (int i = 0; i < length; ++i) {
      Card c = Card(
            child: headerFactory(context,
                  data.infos[i], TextConsts.menuDepthNames[i]),
            color: Consts.advLocHeaderColor,
            margin: EdgeInsets.all(Consts.advInnerMarging),
            elevation: 0.0,
      );

      list.add(c);
   }

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
                        TextEditingController newAdvTextCtrl)
{
   RaisedButton b = RaisedButton(
      child: Text(label),
      color: Theme.of(context).accentColor,
      highlightColor: const Color(0xff075E54),
      onPressed: onPressed,
   );

   Card c4 = Card(
      child: b,
      color: Consts.advMsgColor,
      margin: EdgeInsets.all(Consts.advInnerMarging),
      elevation: 0.0,
   );

   return advAssembler(context, data, c4, newAdvTextCtrl);
}

Widget createAdvTab(BuildContext context, List<AdvData> data,
                    Function onAdvSelection,
                    Function onNewAdv)
{
   return Scaffold( body:
         ListView.builder(
               padding: const EdgeInsets.all(0.0),
               itemCount: data.length,
               itemBuilder: (BuildContext context, int i)
               {
                  return createNewAdvWidget(context, data[i],
                        () {onAdvSelection(data[i]);},
                        TextConsts.advButtonText, null);
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
      itemCount: o.children.length - 1,
      itemBuilder: (BuildContext context, int i)
      {
         ++i;
         MenuNode child = o.children[i];
         if (child.isLeaf()) {
            return FlatButton(
                  child: createListViewItem(child.name,
                     child.leafCounter, null),
                  color: const Color(0xFFFFFF),
                  highlightColor: const Color(0xFFFFFF),
                  onPressed: () { onLeafPressed(i);},
            );
         }
         
         return FlatButton(
               child: createListViewItem(child.name,
                  child.leafCounter, null),
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
         String buttonText)
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
                      null);
         },
   );
}

