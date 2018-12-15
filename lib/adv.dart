import 'package:flutter/material.dart';
import 'package:menu_chat/constants.dart';

class Adv extends StatefulWidget {
  @override
  AdvState createState() => new AdvState();
}

Text createText(String str)
{
   return Text(str,
         textAlign: TextAlign.left,
         overflow: TextOverflow.ellipsis,
         style: TextStyle(
               fontWeight: FontWeight.bold,
               fontSize: Consts.mainFontSize
         )
   );
}

List<Text> headerFactory()
{
   List<Text> r = List<Text>();
   r.add(createText("Marca: Volkswagen"));
   r.add(createText("Modelo: Brasilia"));
   r.add(createText("Ano: 1985/86"));
   r.add(createText("Preco Fipe: 1200"));
   r.add(createText("Anunciante: Paulinho Nacimento"));
   return r;
}

class AdvState extends State<Adv> {
   final Card header1 = new Card(
         child: Column(
               crossAxisAlignment: CrossAxisAlignment.stretch,
               children: headerFactory(),
         ),
   );

   final Card header2 = new Card(
         child: new Column(
               crossAxisAlignment: CrossAxisAlignment.stretch,
               children: headerFactory(),
         ),
   );

   final List<Card> cards = new List<Card>();

  @override
  void initState()
  {
     this.cards.add(this.header1);
     this.cards.add(this.header2);
  }

  @override
  Widget build(BuildContext context)
  {
     return Scaffold(body:ListView(
                 shrinkWrap: true,
                 padding: const EdgeInsets.all(20.0),
                 children: this.cards
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
