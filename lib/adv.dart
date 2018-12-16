import 'package:flutter/material.dart';
import 'package:menu_chat/constants.dart';

class Adv extends StatefulWidget {
  @override
  AdvState createState() => new AdvState();
}

RichText createText(BuildContext context, String key, String value)
{
   //return Text(str,
   //      textAlign: TextAlign.left,
   //      overflow: TextOverflow.ellipsis,
   //      style: TextStyle(
   //            fontWeight: FontWeight.bold,
   //            fontSize: Consts.mainFontSize
   //      )
   //);

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

List<RichText> headerFactory(BuildContext context)
{
   List<RichText> r = List<RichText>();
   r.add(createText(context, "Marca",      ": Volkswagen"));
   r.add(createText(context, "Modelo",     ": Brasilia"));
   r.add(createText(context, "Ano",        ": 1985/86"));
   r.add(createText(context, "Preco Fipe", ": 1200"));
   r.add(createText(context, "Anunciante", ": Paulinho Nacimento"));
   return r;
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
     final Card header1 = new Card(
           child: Column(
                 crossAxisAlignment: CrossAxisAlignment.stretch,
                 children: headerFactory(context),
           ),
     );

     final Card header2 = new Card(
           child: new Column(
                 crossAxisAlignment: CrossAxisAlignment.stretch,
                 children: headerFactory(context),
           ),
     );

     final List<Card> cards = new List<Card>();
     cards.add(header1);
     cards.add(header2);

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
