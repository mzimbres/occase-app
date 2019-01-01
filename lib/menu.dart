import 'package:flutter/material.dart';
import 'package:menu_chat/menu_tree.dart';
import 'package:menu_chat/constants.dart';

class TreeItem extends StatelessWidget {
   final String name;
   String msg;

   TreeItem(this.name, int n)
   {
      msg = "";
      //if (n != 0 && n != 1)
      if (n != 0)
         msg = '${n} item(s)';
   }

   @override
   Widget build(BuildContext context)
   {
      Text subtitle;
      if (!msg.isEmpty)
         subtitle = Text( msg,
               style: TextStyle( fontSize: Consts.subFontSize));

      return ListTile(
            leading: CircleAvatar(child: Text(name[0])),
            title: Text( name,
                  style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: Consts.mainFontSize )
            ),
            dense: false,
            subtitle: subtitle
         );
   }
}

ListView createMenuListView(BuildContext context, MenuNode o,
      Function onLeafPressed, Function onNodePressed, bool makeLeaf)
{
/*
   To support the "Todos" field in the menu checkbox we have to add
   some relatively complex logic.
   First we note that the "Todos" checkbox should appear in all
   screens that present checkboxes, namely, when
   
   1. makeLeaf is true, or
   2. isLeaf is true for more than one node.

   In those cases the builder will go through all node children
   otherwise the first should be skipped.
*/
   int shift = 1;
   bool useAllChildren = false;
   if (makeLeaf || o.children.last.isLeaf()) {
      shift = 0;
      useAllChildren = true;
   }

   return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: o.children.length - shift,
      itemBuilder: (BuildContext context, int i)
      {
         if (useAllChildren) {
            MenuNode child = o.children[i];
            return CheckboxListTile(
                  title: Text( child.name,
                        style: TextStyle(fontSize: Consts.mainFontSize)
                  ),
                  value: child.status,
                  onChanged: (bool newValue) { onLeafPressed(newValue, i);},
            );
         }
         
         MenuNode child = o.children[i + 1];
         return FlatButton(
               child: TreeItem(child.name, child.children.length - 1),
               color: const Color(0xFFFFFF),
               highlightColor: const Color(0xFFFFFF),
               onPressed: () { onNodePressed(i + 1); },
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

