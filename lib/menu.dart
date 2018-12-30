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
  Widget build(BuildContext context)
  {
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

