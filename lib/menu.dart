import 'package:flutter/material.dart';
import 'package:menu_chat/menu_tree.dart';
import 'package:menu_chat/constants.dart';

ListTile createListViewItem(String name, int n, Icon trailing)
{
   Text subtitle = null;
   if (n != 0) {
      final String msg = '${n} items';
      subtitle = Text( msg,
            style: TextStyle( fontSize: Consts.subFontSize));
   }

   return ListTile(
         leading: CircleAvatar(child: Text(name[0])),
         title: Text( name,
               style: TextStyle(
                     fontWeight: FontWeight.bold,
                     fontSize: Consts.mainFontSize )
         ),
         dense: false,
         subtitle: subtitle,
         trailing: trailing
      );
}

/*
 *  To support the "Todos" field in the menu checkbox we have to add
 *  some relatively complex logic.  First we note that the "Todos"
 *  checkbox should appear in all screens that present checkboxes,
 *  namely, when
 *  
 *  1. makeLeaf is true, or
 *  2. isLeaf is true for more than one node.
 *
 *  In those cases the builder will go through all node children
 *  otherwise the first should be skipped.
 */
ListView createFilterListView(BuildContext context, MenuNode o,
      Function onLeafPressed, Function onNodePressed, bool makeLeaf)
{
   // TODO: We should check all children and not only the last.
   int shift = 0;
   if (makeLeaf || o.children.last.isLeaf())
      shift = 1;

   return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: o.children.length + shift,
      itemBuilder: (BuildContext context, int i)
      {
         // Handles the *Marcar todos* button.
         if (shift == 1 && i == 0) {
            return FlatButton(
                  child: createListViewItem("Marcar todos", 0, null),
                  color: const Color(0xFFFFFF),
                  highlightColor: const Color(0xFFFFFF),
                  onPressed: () { onLeafPressed(0); },
            );
         }

         if (shift == 1) {
            MenuNode child = o.children[i - 1];
            Widget icon = null;
            if (child.status)
               icon = Icon(Icons.done, color: Colors.green);
            else
               icon = Icon(Icons.clear, color: Colors.red);

            // Notice we do not subtract -1 on onLeafPressed so that
            // this function can diferentiate the Todos button case.
            return FlatButton(
                  child: createListViewItem(child.name,
                        child.leafCounter, icon),
                  color: const Color(0xFFFFFF),
                  highlightColor: const Color(0xFFFFFF),
                  onPressed: () { onLeafPressed(i); },
            );
         }

         MenuNode child = o.children[i];
         return FlatButton(
               child: createListViewItem(child.name, child.leafCounter, null),
               color: const Color(0xFFFFFF),
               highlightColor: const Color(0xFFFFFF),
               onPressed: () { onNodePressed(i); },
         );
      },
   );
}

Center createSendScreen(Function sendHahesToServer)
{
   return Center(child:RaisedButton(
               child: Text( "Enviar",
                     style: TextStyle(
                           fontWeight: FontWeight.bold,
                           fontSize: Consts.mainFontSize )
               ),
               onPressed: sendHahesToServer,
               //color: const Color(0xFFFFFF),
               //highlightColor: const Color(0xFFFFFF)
         )
   );
}

