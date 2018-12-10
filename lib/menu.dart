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

class MenuScreen extends StatelessWidget {
   List<String> _items;
   MenuScreen(this._items);

   @override
   Widget build(BuildContext context)
   {
      List<Widget> _brands = new List<Widget>();
      for (String o in this._items) {
         _brands.add(RaisedButton(
                     child: BrandItem(o),
                     onPressed: () {
                        print("pressed3");
                        Navigator.of(context).push( MaterialPageRoute(builder: (context) => MenuScreen(<String>[
                                 "Uno mil",
                                 "Palio",
                              ])),
                        );
                     },
                     color: const Color(0xFFFFFF),
                     highlightColor: const Color(0xFFFFFF)
         ));
      }
      return ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.all(20.0),
            children: _brands
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

  List<String> _models = <String>[
     "Uno mil",
     "Palio",
  ];

  int _selectedIndex = 1;

  @override
  void initState()
  {
     super.initState();
     //_marcas = new List<Widget>();
     //for (String o in _brands) {
     //   _marcas.add(RaisedButton(
     //               child: BrandItem(o),
     //               onPressed: update,
     //               color: const Color(0xFFFFFF),
     //               highlightColor: const Color(0xFFFFFF)
     //   ));
     //}
     //_marcas = _brands;
  }

  //void update()
  //{
  //   setState(() {
  //      //_marcas.clear();
  //      //for (String o in _models) {
  //      //   _marcas.add(RaisedButton(
  //      //               child: BrandItem(o),
  //      //               onPressed: () {print("nada");},
  //      //               color: const Color(0xFFFFFF),
  //      //               highlightColor: const Color(0xFFFFFF)
  //      //   ));
  //      //}
  //      //print("pressed2");
  //   });
  //}

  @override
  Widget build(BuildContext context) {
     return Scaffold(
           body: MenuScreen(this._brands),
           //body: ListView(
           //      shrinkWrap: true,
           //      padding: const EdgeInsets.all(20.0),
           //      children: this._marcas
           //),
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


