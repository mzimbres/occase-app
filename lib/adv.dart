import 'package:flutter/material.dart';

class Adv extends StatefulWidget {
  @override
  AdvState createState() => new AdvState();
}

class AdvState extends State<Adv> {
   final Card header1 = new Card(
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

   final Card header2 = new Card(
         child: new Column(
               crossAxisAlignment: CrossAxisAlignment.stretch,
               children: <Widget>[
                  new Text("Marca: Chevrolet"),
                  new Text("Modelo: Belina"),
                  new Text("Ano: 1990/91"),
                  new Text("Preco Fipe: 800R"),
                  new Text("Anunciante: Petrocelis",
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
