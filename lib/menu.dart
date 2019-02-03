import 'package:flutter/material.dart';
import 'package:menu_chat/menu_tree.dart';
import 'package:menu_chat/constants.dart';
import 'package:menu_chat/text_constants.dart';

String makeSubItemsString(int n)
{
   if (n != 0) {
      return '${n} items';
   }

   return null;
}

ListTile createListViewItem(
      String name,
      String subItemStr,
      Icon trailing,
      Color circleColor)
{
   Text subItemText = null;
   if (subItemStr != null)
      subItemText = Text( subItemStr,
                          style: TextStyle(fontSize: Consts.subFontSize));

   return ListTile( leading: CircleAvatar(
                      child: Text(name[0]),
                      backgroundColor: circleColor),
         title: Text( name,
               style: TextStyle(
                     fontWeight: FontWeight.bold,
                     fontSize: Consts.mainFontSize )
         ),
         dense: false,
         subtitle: subItemText,
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
            final String title = "Marcar todos (${o.leafCounter} items)";
            return FlatButton(
                  child: createListViewItem(title, null,
                        null, TextConsts.allMenuItemCircleColor),
                  color: const Color(0xFFFFFF),
                  highlightColor: const Color(0xFFFFFF),
                  onPressed: () { onLeafPressed(0); },
            );
         }

         if (shift == 1) {
            MenuNode child = o.children[i - 1];
            Widget icon = null;
            if (child.status) {
               icon = Icon(Icons.check_box,
                     color: Theme.of(context).primaryColor);
            } else {
               icon = Icon(Icons.check_box_outline_blank,
                     color: Theme.of(context).primaryColor);
            }

            final String subStr = makeSubItemsString(child.leafCounter);

            // Notice we do not subtract -1 on onLeafPressed so that
            // this function can diferentiate the Todos button case.
            return FlatButton(
                  child: createListViewItem(child.name, subStr,
                        icon, TextConsts.menuItemCircleColor),
                  color: const Color(0xFFFFFF),
                  highlightColor: const Color(0xFFFFFF),
                  onPressed: () { onLeafPressed(i); },
            );
         }

         MenuNode child = o.children[i];
         final String subStr = makeSubItemsString(child.leafCounter);
         return FlatButton(
               child: createListViewItem(child.name, subStr,
                     null, TextConsts.menuItemCircleColor),
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

