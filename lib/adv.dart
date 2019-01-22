import 'package:flutter/material.dart';
import 'package:menu_chat/constants.dart';
import 'package:menu_chat/menu_tree.dart';
import 'package:menu_chat/menu.dart';
import 'package:menu_chat/text_constants.dart';

class AdvData {
     List<List<String>> codes;

     // Stores the string *description* inputed when user writes an
     // adv.
     String description = '';

     AdvData()
     {
        final int length = TextConsts.advAppBarMsg.length - 1;
        codes = List<List<String>>(length);
        for (int i = 0; i < length; ++i)
           codes[i] = List<String>();
     }

     AdvData clone()
     {
         AdvData ret = AdvData();
         ret.codes = List<List<String>>.from(this.codes);
         ret.description = this.description;
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
                      List<String> values,
                      List<String> keys)
{
   print("${keys} != ${values}");

   List<RichText> r = List<RichText>();
   for (int i = 0; i < values.length; ++i) {
      r.add(createHeaderLine(context, keys[i + 1], values[i]));
   }

   return Padding( padding: EdgeInsets.all(4.0),
         child: Column( crossAxisAlignment: CrossAxisAlignment.stretch,
               children: r,
         ));
}

Card advInnerCardFactory(BuildContext context,
      List<String> values, List<String> keys)
{
   return Card(
         child: headerFactory(context, values, keys),
         color: Consts.advLocHeaderColor,
         margin: EdgeInsets.all(Consts.advInnerMarging),
         elevation: 0.0,
   );
}

Card advAssembler(BuildContext context, AdvData data,
                  Widget button, TextEditingController newAdvTextCtrl)
{
   List<Card> list = List<Card>();

   print("=====> ${data.codes.length}");
   final int length = data.codes.length;
   for (int i = 0; i < length; ++i)
      list.add(advInnerCardFactory(context,
                  data.codes[i], TextConsts.menuDepthNames[i]));

   if (newAdvTextCtrl == null)
      list.add(advInnerCardFactory(context,
                  <String>[data.description],
                  <String>["Dummy", TextConsts.descriptionText]));

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

