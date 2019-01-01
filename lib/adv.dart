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
     bool saved;

     AdvData()
     {
        print("---------");
        int length = TextConsts.advAppBarMsg.length;
        infos = List<List<KeyValuePair>>(length);
        for (int i = 0; i < length; ++i)
           infos[i] = List<KeyValuePair>();

        saved = false;
     }

     AdvData clone()
     {
         AdvData ret = AdvData();
         for (int i = 0; i < this.infos.length; ++i) {
            for (int j = 0; j < this.infos[i].length; ++j) {
               ret.infos[i].add(this.infos[i][j].clone());
            }
         }

         ret.saved = this.saved;
         return ret;
     }
}

AdvData SimulateAdvData()
{
   List<KeyValuePair> locHeaderList = List<KeyValuePair>();
   locHeaderList.add(KeyValuePair("Estado: ",      "Sao Paulo"));
   locHeaderList.add(KeyValuePair("Cidade: ",     "Atibaia"));

   List<KeyValuePair> prodHeaderList = List<KeyValuePair>();
   prodHeaderList.add(KeyValuePair("Marca: ",      "Volkswagen"));
   prodHeaderList.add(KeyValuePair("Modelo: ",     "Brasilia"));
   prodHeaderList.add(KeyValuePair("Ano: ",        "1985/86"));
   prodHeaderList.add(KeyValuePair("Preco Fipe: ", "1200"));
   prodHeaderList.add(KeyValuePair("Anunciante: ", "Paulinho Nascimento"));

   String msg = "Carro em bom estado de conservacao. Único dono. ";
   msg += "Documentos em dia. ";
   msg += "Guarantia de um mês.";

   List<KeyValuePair> descList = List<KeyValuePair>();
   descList.add(KeyValuePair("Descricao: ", msg));

   AdvData advData = AdvData();
   advData.infos[0] = locHeaderList;
   advData.infos[1] = prodHeaderList;
   advData.infos[2] = descList;

   return advData;
}

RichText createHeaderLine(BuildContext context, KeyValuePair pair)
{
   return RichText(
         text: TextSpan(
               text: pair.key,
               //style: DefaultTextStyle.of(context).style,
               style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: Consts.mainFontSize),
               children: <TextSpan>[
                  TextSpan(text: pair.value, style: TextStyle(fontWeight: FontWeight.normal)),
               ],
         ),
   );
}

Padding headerFactory(BuildContext context,
                      List<KeyValuePair> entries)
{
   List<RichText> r = List<RichText>();
   for (KeyValuePair o in entries) {
      r.add(createHeaderLine(context, o));
   }

   return Padding( padding: EdgeInsets.all(4.0),
         child: Column( crossAxisAlignment: CrossAxisAlignment.stretch,
               children: r,
         ));
}

Card advAssembler(BuildContext context, AdvData data, Widget button)
{
   List<Card> list = List<Card>();
   for (List<KeyValuePair> o in data.infos) {
      Card c = Card(
            child: headerFactory(context, o),
            color: Consts.advLocHeaderColor,
            margin: EdgeInsets.all(Consts.advInnerMarging),
            elevation: 0.0,
      );

      list.add(c);
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

Card createAdvWidget(BuildContext context, AdvData data,
                     Function onAdvSelection)
{

   CheckboxListTile save = CheckboxListTile(
         title: Text( TextConsts.advButtonText,
               style: TextStyle(
                     fontWeight: FontWeight.bold,
                     fontSize: Consts.mainFontSize
               )
         ),
         //subtitle: Text(" Inscritos"),
         //secondary: const Icon(Icons.save),
         value: data.saved,
         onChanged: (bool newValue) {onAdvSelection(newValue, data);}
   );

   Card c4 = Card(
         child:  save,
         color: Consts.advProdHeaderColor,
         margin: EdgeInsets.all(Consts.advInnerMarging),
         elevation: 0.0,
   );

   return advAssembler(context, data, c4);
}

Card createNewAdvWidget(BuildContext context, AdvData data,
                        Function onPressed)
{
   RaisedButton b = RaisedButton(
      child: Text(TextConsts.newAdvButtonText),
      //color: const Color(0xFFFFFF),
      //highlightColor: const Color(0xFFFFFF),
      onPressed: onPressed,
   );

   Card c4 = Card(
      child:  b,
      color: Consts.advProdHeaderColor,
      margin: EdgeInsets.all(Consts.advInnerMarging),
      elevation: 0.0,
   );

   return advAssembler(context, data, c4);
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
                  return createAdvWidget(context, data[i], onAdvSelection);
               },
         ),

         backgroundColor: Consts.scaffoldBackground,
         floatingActionButton: FloatingActionButton(
               backgroundColor: Theme.of(context).accentColor,
               child: Icon(Icons.message, color: Colors.white),
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
                  child: TreeItem(child.name, child.children.length),
                  color: const Color(0xFFFFFF),
                  highlightColor: const Color(0xFFFFFF),
                  onPressed: () { onLeafPressed(i);},
            );
         }
         
         return FlatButton(
               child: TreeItem(child.name, child.children.length - 1),
               color: const Color(0xFFFFFF),
               highlightColor: const Color(0xFFFFFF),
               onPressed: () { onNodePressed(i); },
         );
      },
   );
}

Widget createChatTab(BuildContext context, List<AdvData> data,
      Function onChat)
{
   return ListView.builder(
         padding: const EdgeInsets.all(0.0),
         itemCount: data.length,
         itemBuilder: (BuildContext context, int i)
         {
            return createNewAdvWidget(context, data[i], onChat);
         },
   );
}

