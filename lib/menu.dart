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
    return ListTile(
        leading: CircleAvatar(child: Text("M")),
        title: Text( name,
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

Widget wrappOnScaff(Widget w, Function onTapped, int i)
{
   return Scaffold(
         body: w,
         bottomNavigationBar: BottomNavigationBar(
               items: <BottomNavigationBarItem>[
                  BottomNavigationBarItem(
                        icon: Icon(Icons.home), title: Text('Localizacao')),
                  BottomNavigationBarItem(
                        icon: Icon(Icons.directions_car), title: Text('Modelos')),
                  BottomNavigationBarItem(
                        icon: Icon(Icons.send), title: Text('Enviar')),
               ],

               currentIndex: i,
               fixedColor: Colors.deepPurple,
               onTap: onTapped,
         ),
   );
}


Widget createMenuItem(BuildContext context, MenuNode o,
      Function onLeafPressed, Function onNodePressed)
{
   if (o.isLeaf()) {
      return CheckboxListTile(
            title: Text( o.name,
                  style: TextStyle(fontSize: Consts.mainFontSize)
            ),
            value: o.status,
            onChanged: onLeafPressed
      );

   }
   
   return FlatButton(
         child: TreeItem(o.name, o.children.length),
         color: const Color(0xFFFFFF),
         highlightColor: const Color(0xFFFFFF),
         onPressed: onNodePressed,
   );
}

ListView createMenuListView(BuildContext context, MenuNode o,
      Function onLeafPressed, Function onNodePressed)
{
   return ListView.builder(
         padding: const EdgeInsets.all(8.0),
         itemCount: o.children.length,
         itemBuilder: (BuildContext context, int i) {
            return createMenuItem( context, o.children[i],
                  (bool newValue) { onLeafPressed(newValue, i);},
                  () { onNodePressed(i); }
            );
         },
   );
}

class Menu extends StatefulWidget {
   List<MenuTree> _menus;

   Menu(this._menus);

   @override
   MenuState createState() => new MenuState(_menus);
}

class MenuState extends State<Menu> {
   int _selectedIndex = 0;
   List<MenuTree> _menus;

   @override
   void initState()
   {
      super.initState();
   }

   MenuState(this._menus);

   @override
   Widget build(BuildContext context) {
      return WillPopScope(
            onWillPop: () async {
               if (_menus[_selectedIndex].st.length == 1) {
                  return true;
               }

               _menus[_selectedIndex].st.removeLast();
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

   Widget createScreen(BuildContext context)
   {
      if (_selectedIndex == 2) {
         return wrappOnScaff(Center(child:RaisedButton(
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
         ), _onItemTapped, _selectedIndex);
      }

      return wrappOnScaff(
            createMenuListView(
                  context,
                  _menus[_selectedIndex].st.last,
                  _onLeafPressed,
                  _onNodePressed),
            _onItemTapped,
            _selectedIndex);
   }

   void _onLeafPressed(bool newValue, int i)
   {
      MenuNode o = _menus[_selectedIndex].st.last.children[i];
      String code = o.code;
      o.status = newValue;
      print('$code ===> $newValue');
      setState(() { });
   }

   void _onNodePressed(int i)
   {
      MenuNode o = _menus[_selectedIndex].st.last.children[i];
      print("I am calling a non leaf onPressed");
      _menus[_selectedIndex].st.add(o);
      setState(() { }); // Triggers redraw.
   }
}

