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

Center createSendScreen()
{
   return Center(child:RaisedButton(
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
   );
}

class Menu extends StatefulWidget {
   List<MenuTree> _menus;

   Menu(this._menus);

   @override
   MenuState createState() => MenuState(_menus);
}

class MenuState extends State<Menu> {
   int _BotBarIdx = 0;
   List<MenuTree> _menus;

   @override
   void initState()
   {
      super.initState();
   }

   MenuState(this._menus);

   @override
   Widget build(BuildContext context)
   {
      Widget w;
      if (_BotBarIdx == 2) {
         w = createSendScreen();
      } else {
         w = createMenuListView(
                  context,
                  _menus[_BotBarIdx].st.last,
                  _onLeafPressed,
                  _onNodePressed);
      }

      return WillPopScope(
            onWillPop: () async { return _onWillPop();},
            child: wrappOnScaff(w, _onBotBarTapped, _BotBarIdx),
      );
   }

   bool _onWillPop()
   {
      if (_menus[_BotBarIdx].st.length == 1) {
         return true;
      }

      _menus[_BotBarIdx].st.removeLast();
      setState(() { });
      return false;
   }

   void _onBotBarTapped(int index)
   {
      setState(() { _BotBarIdx = index; });
   }

   void _onLeafPressed(bool newValue, int i)
   {
      MenuNode o = _menus[_BotBarIdx].st.last.children[i];
      String code = o.code;
      print('$code ===> $newValue');
      o.status = newValue;
      setState(() { });
   }

   void _onNodePressed(int i)
   {
      print("I am calling a non leaf onPressed");
      MenuNode o = _menus[_BotBarIdx].st.last.children[i];
      _menus[_BotBarIdx].st.add(o);
      setState(() { });
   }
}

