import 'package:flutter/material.dart';

class BrandItem extends StatelessWidget {
  final String _brand;

  BrandItem(this._brand);

  @override
  Widget build(BuildContext context) {
    return new ListTile(
        leading: new CircleAvatar(child: new Text("M")),
        title: new Text(_brand),
        //subtitle: new Text("What can we do")
        );
  }
}

class Menu extends StatefulWidget {
  @override
  MenuState createState() => new MenuState();
}

class MenuState extends State<Menu> {
  List<Widget> _marcas;
  List<String> _brands = <String>[
                "Alfa Romeo",
                "BMW",
                "Fiat",
                "Volkswagen",
                "Mercedes",
                "Ford",
                "Chevrolet",
                "Citroen",
                "Peugeot",
                "Ferrari",
                "Dodge",
                "Rolls Roice",
             ];

  List<String> _models =
        <String>[ "Uno mil",
                "Palio",
                ];

  @override
  void initState()
  {
    super.initState();
    _marcas = new List<Widget>();
    for (String o in _brands) {
       _marcas.add(RaisedButton(
                   child: BrandItem(o),
                   onPressed: () {setState(update);}
                   ));
    }
    //_marcas = _brands;
  }

  void update()
  {
     print("pressed2");
     //_marcas.clear();
  }

  @override
  Widget build(BuildContext context) {
     return ListView(
                 shrinkWrap: true,
                 padding: const EdgeInsets.all(20.0),
                 children: this._marcas
          );
  }
}


