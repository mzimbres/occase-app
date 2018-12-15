import 'package:flutter/material.dart';
import 'package:menu_chat/menu_tree.dart';
import 'package:menu_chat/constants.dart';

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
                    fontSize: Consts.mainFontSize )
              ),
        dense: true,
        subtitle: Text(
              msg,
              style: TextStyle(
                    fontSize: Consts.subFontSize)
              )
        );
  }
}

class Menu extends StatefulWidget {
  @override
  MenuState createState() => new MenuState();
}

class MenuState extends State<Menu> {
   int _selectedIndex = 0;
   List<MenuTree> menus;

   @override
   void initState()
   {
      super.initState();
   }


   MenuState()
   {
      menus = List<MenuTree>();
      menus.add(LocationFactory());
      menus.add(ModelsFactory());
   }

   @override
   Widget build(BuildContext context) {
      return WillPopScope(
            onWillPop: () async {
               //Navigator.of(context).pop();
               if (menus[_selectedIndex].st.length == 1) {
                  return true;
               }

               menus[_selectedIndex].st.removeLast();
               setState(() { });
               return false;
            },
            child: createScreen(context),
      );
   }

   void _onItemTapped(int index) {
      setState(() {
         _selectedIndex = index;
      });
   }

   Widget scaffIt(Widget w)
   {
      return Scaffold(
            body: w,
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

   Widget createScreen(BuildContext context)
   {
      if (_selectedIndex == 2) {
         return scaffIt(Center(child:RaisedButton(
                           child: Text( "Enviar",
                           style: TextStyle(
                                 fontWeight: FontWeight.bold,
                                 fontSize: Consts.mainFontSize )
                           ),
                           onPressed: () {
                              print("Sending hashes to server");
                           },
                           //color: const Color(0xFFFFFF),
                           //highlightColor: const Color(0xFFFFFF)
         )
         ));
      }

      return scaffIt(createScreenMenu(context, menus[_selectedIndex]));
      
   }

   Widget createScreenMenu(BuildContext context, MenuTree tree)
   {
      List<Widget> items = new List<Widget>();
      for (MenuNode o in tree.st.last.children) {
         Widget w;
         if (o.isLeaf()) {
            w = CheckboxListTile(
                  title: Text(
                        o.name,
                        style: TextStyle(
                              fontSize: Consts.mainFontSize
                        )
                  ),
                  //subtitle: Text(" Inscritos"),
                  value: o.status,
                  onChanged: (bool newValue){
                     String code = o.code;
                     o.status = newValue;
                     print('$code ===> $newValue');
                     setState(() { });
                  }
            );

         } else {
            w = FlatButton(
                  child: TreeItem(o.name, o.children.length),
                  onPressed: () {
                       print("I am calling non leaf on pressed");
                       menus[_selectedIndex].st.add(o);
                       setState(() { }); // Triggers redraw with new value.
                  },
                  color: const Color(0xFFFFFF),
                  highlightColor: const Color(0xFFFFFF)
            );
         }
         items.add(w);
      }
      
      return ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.all(20.0),
            children: items,
      );
   }
}


