import 'package:flutter/material.dart';
import 'package:menu_chat/constants.dart';

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

   return Padding( padding: EdgeInsets.all(8.0),
         child: Column( crossAxisAlignment: CrossAxisAlignment.stretch,
               children: r,
         ));
}

class AdvData {
     List<KeyValuePair> headerEntries;
     String msg;
     bool saved;

     AdvData(this.headerEntries, this.msg, this.saved);
}

class Adv extends StatefulWidget {
  @override
  AdvState createState() => new AdvState();
}

class AdvState extends State<Adv> {
   AdvData data1;

   AdvState()
   {
      List<KeyValuePair> headerEntries = List<KeyValuePair>();
      headerEntries.add(KeyValuePair("Marca: ",      "Volkswagen"));
      headerEntries.add(KeyValuePair("Modelo: ",     "Brasilia"));
      headerEntries.add(KeyValuePair("Ano: ",        "1985/86"));
      headerEntries.add(KeyValuePair("Preco Fipe: ", "1200"));
      headerEntries.add(KeyValuePair("Anunciante: ", "Paulinho Nascimento"));

      String msg = "Carro em bom estado de conservacao. Único dono. ";
      msg += "Documentos em dia (Paulinho garante). ";
      msg += "Guarantia de um mês.";

      data1 = AdvData(headerEntries, msg, false);
   }

   @override
   void initState()
   {
   }

   Card createAdvWidget(BuildContext context, AdvData data)
   {
      Card c1 = Card(
            child: headerFactory(context, data.headerEntries),
            color: Consts.advHeaderColor,
            margin: EdgeInsets.all(Consts.advInnerMarging),
            elevation: 0.0,
      );

      Card c2 = Card(
            child: createHeaderLine(context,
                  KeyValuePair("Descricao: ", data.msg)),
            color: Consts.advMsgColor,
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

      Card c3 = Card(
            child:  save,
            color: Consts.advHeaderColor,
            margin: EdgeInsets.all(Consts.advInnerMarging),
            elevation: 0.0,
      );

      Column h1 = Column(crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[c1, c2, c3],
      );

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
                 padding: const EdgeInsets.all(8.0),
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
