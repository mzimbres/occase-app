import 'package:flutter/material.dart';
import 'package:menu_chat/menu_tree.dart';

class TreeItem extends StatelessWidget {
  final String name;
  String msg;

  TreeItem(this.name, int n)
  {
     msg = '${n} items';
  }

  @override
  Widget build(BuildContext context) {
    return new ListTile(
        leading: CircleAvatar(child: Text("M")),
        title: Text(
              name,
              style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18.0 )
              ),
        dense: true,
        subtitle: Text(
              msg,
              style: TextStyle(
                    fontSize: 15.0)
              )
        );
  }
}

class MenuScreen extends StatefulWidget {
  MenuTree _items;
  MenuScreen(this._items);
  @override
  MenuScreenState createState() => new MenuScreenState(_items);
}

class MenuScreenState extends State<MenuScreen> {
   MenuTree _items;
   MenuScreenState(this._items);

   @override
   void initState()
   {
      super.initState();
   }

   @override
   Widget build(BuildContext context)
   {
      List<Widget> _brands = new List<Widget>();
      for (MenuNode o in this._items.st.last.children) {
         Widget w;
         if (o.isLeaf()) {
            w = CheckboxListTile(
                  title: Text(
                        o.name,
                        style: TextStyle(
                              fontSize: 18.0
                        )
                  ),
                  //subtitle: Text(" Inscritos"),
                  value: o.status,
                  onChanged: (bool newValue){
                     String code = o.code;
                     o.status = newValue;
                     print('$code ===> $newValue');
                     setState(() { }); // Triggers redraw with new value.
                  }
            );

         } else {
            w = FlatButton(
                  child: TreeItem(o.name, o.children.length),
                  onPressed: () {
                     _items.st.add(o);
                     Navigator.of(context).push(
                           MaterialPageRoute(
                                 builder: (context) {
                                    return MenuScreen(_items);
                                 }
                           ),
                     );
                  },
                  color: const Color(0xFFFFFF),
                  //highlightColor: const Color(0xFFFFFF)
            );
         }
         _brands.add(w);
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
      MenuTree tree = LocationFactory();
      screens = new List<MenuScreen>();
      screens.add(MenuScreen(tree));
      screens.add(MenuScreen(tree));
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


