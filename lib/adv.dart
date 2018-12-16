import 'package:flutter/material.dart';
import 'package:menu_chat/constants.dart';

class Adv extends StatefulWidget {
  @override
  AdvState createState() => new AdvState();
}

RichText createText(BuildContext context, String key, String value)
{
   return RichText(
         text: TextSpan(
               text: key,
               //style: DefaultTextStyle.of(context).style,
               style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: Consts.mainFontSize),
               children: <TextSpan>[
                  TextSpan(text: value, style: TextStyle(fontWeight: FontWeight.normal)),
               ],
         ),
   );
}

Column headerFactory(BuildContext context)
{
   List<RichText> r = List<RichText>();
   r.add(createText(context, "Marca: ",      "Volkswagen"));
   r.add(createText(context, "Modelo: ",     "Brasilia"));
   r.add(createText(context, "Ano: ",        "1985/86"));
   r.add(createText(context, "Preco Fipe: ", "1200"));
   r.add(createText(context, "Anunciante: ", "Paulinho Nacimento"));

   return Column( crossAxisAlignment: CrossAxisAlignment.stretch,
         children: r,
   );
}

class AdvState extends State<Adv> {
  //@override
  //void initState()
  //{
  //   cards.add(this.header1);
  //   cards.add(this.header2);
  //}

  @override
  Widget build(BuildContext context)
  {
     Card c1 = Card(
           child: headerFactory(context),
           color: Consts.advHeaderColor,
           margin: EdgeInsets.all(5.0),
           elevation: 0.0,
     );

     String msg = "Carro em bom estado de conservacao. Único dono.";
            msg += "Documentos em dia (Paulinho garante).";

     Card c2 = Card(
           child: createText(context, "Descricao: ", msg),
           color: Consts.advMsgColor,
           margin: EdgeInsets.all(5.0),
           elevation: 0.0,
     );

     Column h1 = Column(crossAxisAlignment: CrossAxisAlignment.stretch,
           children: <Card>[c1, c2],
     );

     Card adv1 = Card(
           child: h1,
           color: Consts.advMsgColor,
           margin: EdgeInsets.all(5.0),
           elevation: 0.0,
     );

     final List<Card> cards = List<Card>();
     cards.add(adv1);
     cards.add(adv1);
     cards.add(adv1);
     cards.add(adv1);
     cards.add(adv1);
     cards.add(adv1);
     cards.add(adv1);
     cards.add(adv1);

     return Scaffold(body:ListView(
                 shrinkWrap: true,
                 padding: const EdgeInsets.all(20.0),
                 children: cards
     ),

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
