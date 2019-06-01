import 'package:flutter/material.dart';
import 'package:menu_chat/menu_tree.dart';
import 'package:menu_chat/constants.dart';
import 'package:menu_chat/text_constants.dart' as cts;

String makeLeafCounterString(int n)
{
   if (n != 0) {
      return 'Subitems: ${n}';
   }

   return null;
}

String makeFilterNonLeafSubStr(int n)
{
   return 'Filtros aplicados: ${n}';
}

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

ListTile createListViewItem(BuildContext context,
                            String name,
                            Widget subItemWidget,
                            Widget trailing,
                            Widget leading,
                            Function onTap,
                            Function onLongPress)
{
   return ListTile(
             leading: leading,
             title: Text(name, style: cts.menuTitleStl),
             dense: true,
             subtitle: subItemWidget,
             trailing: trailing,
             contentPadding: EdgeInsets.symmetric(horizontal: 10.0),
             onTap: onTap,
             enabled: true,
             onLongPress: onLongPress);
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
      padding: const EdgeInsets.all(8.0),
      itemCount: o.children.length + shift,
      itemBuilder: (BuildContext context, int i)
      {
         if (shift == 1 && i == 0) {
            // Handles the *Marcar todos* button.
            final String title = cts.menuSelectAllStr;
            final TextStyle fls =
                  TextStyle(color: Theme.of(context).accentColor);
            return
               createListViewItem(
                   context,
                   title,
                   null,
                   null,
                   Icon( Icons.select_all
                       , size: 35.0
                       , color: Theme.of(context).primaryColor),
                   () { onLeafPressed(0); },
                   (){});
         }

         if (shift == 1) {
            MenuNode child = o.children[i - 1];
            Widget icon = null;
            Color color = Theme.of(context).primaryColor;
            if (child.status) {
               color = cts.selectedMenuColor;
               icon = Icon(Icons.check_box, color: color);
            } else {
               icon = Icon(Icons.check_box_outline_blank,
                     color: color);
            }

            final String subStr = makeLeafCounterString(child.leafCounter);

            // Notice we do not subtract -1 on onLeafPressed so that
            // this function can diferentiate the Todos button case.
            final String abbrev = makeStrAbbrev(child.name);
            return 
               createListViewItem(
                   context,
                   child.name,
                   createMenuItemSubStrWidget(
                         subStr,
                         FontWeight.normal),
                   icon,
                   makeCircleAvatar( Text(abbrev, style: cts.abbrevStl)
                                   , color),
                   () { onLeafPressed(i);},
                   (){});
         }

         MenuNode child = o.children[i];
         // Works only if the next level in the tree is its filter
         // depth.
         final int c = child.getCounterOfFilterChildren();
         final String subStr = makeFilterNonLeafSubStr(c);
         final String abbrev = makeStrAbbrev(child.name);

         Color filterNodeParentColor = Theme.of(context).primaryColor;
         if (c != 0)
            filterNodeParentColor = cts.selectedMenuColor;

         return
            createListViewItem(
               context,
               child.name,
               createMenuItemSubStrWidget(subStr, FontWeight.normal),
               null,
               makeCircleAvatar( Text(abbrev, style: cts.abbrevStl)
                               , filterNodeParentColor),
               () { onNodePressed(i); },
               (){});
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

