import 'package:flutter/material.dart';
import 'package:menu_chat/constants.dart';
import 'package:menu_chat/menu.dart';

class KeyValuePair {
   String key;
   String value;
   KeyValuePair(this.key, this.value);
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

class AdvData {
     List<KeyValuePair> locHeaderList;
     List<KeyValuePair> prodHeaderList;
     List<KeyValuePair> descList;
     bool saved;

     AdvData(this.locHeaderList, this.prodHeaderList,
           this.descList, this.saved);
}

class Adv extends StatefulWidget {
  @override
  AdvState createState() => new AdvState();
}

class AdvState extends State<Adv> {
   AdvData data1;

   AdvState()
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

      data1 = AdvData(locHeaderList, prodHeaderList, descList, false);
   }

   @override
   void initState()
   {
   }

   Card createAdvWidget(BuildContext context, AdvData data)
   {
      Card c1 = Card(
            child: headerFactory(context, data.locHeaderList),
            color: Consts.advLocHeaderColor,
            margin: EdgeInsets.all(Consts.advInnerMarging),
            elevation: 0.0,
      );

      Card c2 = Card(
            child: headerFactory(context, data.prodHeaderList),
            color: Consts.advProdHeaderColor,
            margin: EdgeInsets.all(Consts.advInnerMarging),
            elevation: 0.0,
      );

      Card c3 = Card(
            child: headerFactory(context, data.descList),
            color: Consts.advProdHeaderColor,
            margin: EdgeInsets.all(Consts.advInnerMarging),
            elevation: 0.0,
      );

      CheckboxListTile save = CheckboxListTile(
            title: Text( "Salvar",
                  style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: Consts.mainFontSize
                  )
            ),
            //subtitle: Text(" Inscritos"),
            //secondary: const Icon(Icons.save),
            value: data.saved,
            onChanged: (bool newValue){
               print('Anuncio salvo');
               data.saved = newValue;
               setState(() { });
            }
      );

      Card c4 = Card(
            child:  save,
            color: Consts.advProdHeaderColor,
            margin: EdgeInsets.all(Consts.advInnerMarging),
            elevation: 0.0,
      );

      Column h1 = Column(crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[c1, c2, c3, c4],);

      Card adv1 = Card(
            child: h1,
            color: Consts.advMsgColor,
            margin: EdgeInsets.all(Consts.advMarging),
            elevation: 0.0,
      );

      return adv1;
   }

  @override
  Widget build(BuildContext context)
  {
     return Scaffold( body:
           ListView.builder(
                 padding: const EdgeInsets.all(0.0),
                 //itemCount: cards.length
                 itemBuilder: (BuildContext context, int index) {
                    return createAdvWidget(context, data1);
                 },
           ),
           backgroundColor: Consts.scaffoldBackground,

           floatingActionButton: FloatingActionButton(
                 backgroundColor: Theme.of(context).accentColor,
                 child: Icon(
                       Icons.message,
                       color: Colors.white,
                 ),
                 onPressed: () => print("open chats"),
           ),
     );
  }
}
