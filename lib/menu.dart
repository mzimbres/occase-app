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

ListView createMenuListView(BuildContext context, MenuNode o,
      Function onLeafPressed, Function onNodePressed, bool makeLeaf)
{
   return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: o.children.length,
      itemBuilder: (BuildContext context, int i)
      {
         MenuNode child = o.children[i];
         if (child.isLeaf() || makeLeaf) {
            return CheckboxListTile(
                  title: Text( child.name,
                        style: TextStyle(fontSize: Consts.mainFontSize)
                  ),
                  value: child.status,
                  onChanged: (bool newValue) { onLeafPressed(newValue, i);},
            );
         }
         
         return FlatButton(
               child: TreeItem(child.name, child.children.length),
               color: const Color(0xFFFFFF),
               highlightColor: const Color(0xFFFFFF),
               onPressed: () { onNodePressed(i); },
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

