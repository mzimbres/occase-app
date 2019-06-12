import 'package:flutter/material.dart';
import 'package:menu_chat/menu_tree.dart';
import 'package:menu_chat/constants.dart';
import 'package:menu_chat/text_constants.dart' as cts;

Text createMenuItemSubStrWidget(String str, FontWeight fw)
{
   if (str == null)
      return null;

   return Text(str, style: TextStyle(fontSize: 14.0, fontWeight: fw),
               maxLines: 1,
               overflow: TextOverflow.clip);
}

CircleAvatar makeCircleAvatar(Widget child, Color bgcolor)
{
   return CircleAvatar(child: child, backgroundColor: bgcolor);
}

String makeStrAbbrev(final String str)
{
   if (str.length < 2)
      return str;

   return str.substring(0, 2);
}

/*
 *  To support the "select all" buttom in the menu checkbox we have to
 *  add some complex logic.  First we note that the "Todos" checkbox
 *  should appear in all screens that present checkboxes, namely, when
 *  
 *  1. makeLeaf is true, or
 *  2. isLeaf is true for more than one node.
 *
 *  In those cases the builder will go through all node children
 *  otherwise the first should be skipped.
 */
ListView createFilterListView(BuildContext context,
                              MenuNode o,
                              Function onLeafPressed,
                              Function onNodePressed,
                              bool makeLeaf)
{
   // TODO: We should check all children and not only the last.
   int shift = 0;
   if (makeLeaf || o.children.last.isLeaf())
      shift = 1;

   return ListView.builder(
      //padding: const EdgeInsets.all(8.0),
      itemCount: o.children.length + shift,
      itemBuilder: (BuildContext context, int i)
      {
         if (shift == 1 && i == 0) {
            // Handles the *select all* button.
            return ListTile(
                leading: Icon(
                   Icons.select_all,
                   size: 35.0,
                   color: Theme.of(context).primaryColor),
                title: Text(cts.menuSelectAllStr,
                          style: cts.menuTitleStl),
                dense: true,
                onTap: () { onLeafPressed(0); },
                enabled: true,);
         }

         if (shift == 1) {
            MenuNode child = o.children[i - 1];
            Widget icon = Icon(Icons.check_box_outline_blank);
            if (child.status)
               icon = Icon(Icons.check_box);

            Widget subtitle = null;
            if (!child.isLeaf()) {
               final int lc = child.leafCounter;
               final String names = child.getChildrenNames();
               subtitle =  Text(
                   '($lc) $names',
                   style: TextStyle(fontSize: 14.0), maxLines: 2,
                                    overflow: TextOverflow.clip);
            }

            Color cc = Colors.grey;
            if (child.status)
               cc = Theme.of(context).primaryColor;

            // Notice we do not subtract -1 on onLeafPressed so that
            // this function can diferentiate the Todos button case.
            final String abbrev = makeStrAbbrev(child.name);
            return ListTile(
                leading: 
                   makeCircleAvatar(
                      Text(abbrev, style: cts.abbrevStl),
                      cc),
                title: Text(child.name, style: cts.menuTitleStl),
                dense: true,
                subtitle: subtitle,
                trailing: icon,
                contentPadding: EdgeInsets.symmetric(horizontal: 10.0),
                onTap: () { onLeafPressed(i);},
                enabled: true,
                selected: child.status,
                isThreeLine: !child.isLeaf()
                );
         }

         final int c = o.children[i].getCounterOfFilterChildren();
         final int cs = o.children[i].getChildrenSize();

         final String names = o.children[i].getChildrenNames();
         final String subtitle = '($c/$cs) $names';
         Color cc = Colors.grey;
         if (c != 0)
            cc = Theme.of(context).primaryColor;

         return
            ListTile(
                leading: makeCircleAvatar(
                   Text(makeStrAbbrev(o.children[i].name), style: cts.abbrevStl), cc),
                title: Text(o.children[i].name, style: cts.menuTitleStl),
                dense: true,
                subtitle: Text(
                   subtitle,
                   style: TextStyle(fontSize: 14.0), maxLines: 2,
                                    overflow: TextOverflow.clip),
                trailing: Icon(Icons.keyboard_arrow_right),
                contentPadding: EdgeInsets.symmetric(horizontal: 10.0),
                onTap: () { onNodePressed(i); },
                enabled: true,
                selected: c != 0,
                isThreeLine: true,
                );
      },
   );
}

Center
createSendScreen( Function onPressed
                , final String txt)
{
   RaisedButton but =
      RaisedButton(
         child: Text(txt,
            style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: cts.mainFontSize)),
         color: cts.postFrameColor,
         onPressed: onPressed);

   return Center(child: but);
}

