import 'package:flutter/material.dart';

class BrandItem extends StatelessWidget {
  final String _brand;

  BrandItem(this._brand);

  @override
  Widget build(BuildContext context) {
    return new ListTile(
        leading: new CircleAvatar(child: new Text("M")),
        title: new Text(_brand),
        dense: true,
        //subtitle: new Text("What can we do")
        );
  }
}

class MenuNode {
   String name;
   List<MenuNode> children;
}

class MenuTree {
   MenuNode root;
   List<MenuNode> st;
}

class MenuScreen extends StatefulWidget {
  List<List<String>> _items;
  int _index;
  MenuScreen(this._items, this._index);
  @override
  MenuScreenState createState() => new MenuScreenState(_items, _index);
}

class MenuScreenState extends State<MenuScreen> {
   List<List<String>> _items;
   int _index;
   MenuScreenState(this._items, this._index);

   @override
   void initState()
   {
      super.initState();
   }

   @override
   Widget build(BuildContext context)
   {
      List<Widget> _brands = new List<Widget>();
      for (String o in this._items[_index]) {
         _brands.add(RaisedButton(
                     child: BrandItem(o),
                     onPressed: () {
                        if (_index == 0) {
                           Navigator.of(context).push(
                                 MaterialPageRoute(
                                       builder: (context) {
                                          return MenuScreen(_items, 1);
                                       }
                                 ),
                           );
                        } else {
                           Navigator.pop(context);
                        }
                     },
                     color: const Color(0xFFFFFF),
                     //highlightColor: const Color(0xFFFFFF)
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
   List<MenuScreen> screens;
   int _selectedIndex = 1;

   @override
   void initState()
   {
      super.initState();
   }


   MenuState()
   {
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
         "Premio",
      ];

      List<List<String>> a1 = new List<List<String>>();
      a1.add(_brands);
      a1.add(_models);

      screens = new List<MenuScreen>();
      screens.add(MenuScreen(a1, 0));
      screens.add(MenuScreen(a1, 0));
   }

   @override
   Widget build(BuildContext context) {
      return Scaffold(
            body: new Stack(
                    children: List<Widget>.generate(screens.length, (int index) {
                      return IgnorePointer(
                        ignoring: index != _selectedIndex,
                        child: Opacity(
                          opacity: _selectedIndex == index ? 1.0 : 0.0,
                          child: Navigator(
                            onGenerateRoute: (RouteSettings settings) {
                              return MaterialPageRoute(
                                builder: (_) => screens[index],
                              );
                            },
                          ),
                        ),
                      );
                    }),
                  ),

            
            bottomNavigationBar: BottomNavigationBar(
                  items: <BottomNavigationBarItem>[
                     BottomNavigationBarItem(
                           icon: Icon(Icons.home), title: Text('Localizacao')),
                     BottomNavigationBarItem(
                           icon: Icon(Icons.business), title: Text('Modelos')),
                     BottomNavigationBarItem(
                           icon: Icon(Icons.business), title: Text('Salvar')),
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


