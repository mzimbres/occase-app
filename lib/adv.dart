import 'package:flutter/material.dart';

class Adv extends StatefulWidget {
  @override
  AdvState createState() => new AdvState();
}

class AdvState extends State<Adv> {
   final Card header = new Card(
         child: new Column(
               crossAxisAlignment: CrossAxisAlignment.stretch,
               children: <Widget>[
                  new Text("Marca: Volkswagen"),
                  new Text("Modelo: Brasilia"),
                  new Text("Ano: 1985/86"),
                  new Text("Preco Fipe: 1200"),
                  new Text("Anunciante: Paulinho Nacimento",
                        textAlign: TextAlign.left,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                              fontWeight: FontWeight.bold),),
               ],
         ),
   );

   final List<Card> cards = new List<Card>();

  @override
  void initState()
  {
     this.cards.add(this.header);
  }

  @override
  Widget build(BuildContext context)
  {
     return ListView(
           shrinkWrap: true,
           padding: const EdgeInsets.all(20.0),
           children: this.cards
     );
  }
}
