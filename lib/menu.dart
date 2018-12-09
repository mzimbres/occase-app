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

  int _selectedIndex = 1;

  @override
  void initState()
  {
    super.initState();
    _marcas = new List<Widget>();
    for (String o in _brands) {
       _marcas.add(RaisedButton(
                   child: BrandItem(o),
                   onPressed: () {setState(update);},
                   color: const Color(0xFFFFFF),
                   highlightColor: const Color(0xFFFFFF)
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
     return Scaffold(
           body: ListView(
                 shrinkWrap: true,
                 padding: const EdgeInsets.all(20.0),
                 children: this._marcas
           ),
           bottomNavigationBar: BottomNavigationBar(
               items: <BottomNavigationBarItem>[
               BottomNavigationBarItem(
                     icon: Icon(Icons.home), title: Text('Localizacao')),
               BottomNavigationBarItem(
                     icon: Icon(Icons.business), title: Text('Modelos')),
           ],
           currentIndex: _selectedIndex,
           fixedColor: Colors.deepPurple,
           onTap: _onItemTapped,
           ),
           );
  }
   void _onItemTapped(int index) {
   setState(() {
     _selectedIndex = index;
   });
 }
}


