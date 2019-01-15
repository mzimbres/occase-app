import 'dart:convert';
import 'package:menu_chat/constants.dart';

class MenuNode {
   String name;
   String code;
   bool status;

   List<MenuNode> children = List<MenuNode>();

   MenuNode([this.name, this.code])
   {
      status = false;
   }

   bool isLeaf()
   {
      return children.isEmpty;
   }
}

MenuNode buildTree(String dataRaw)
{
   List<String> data = dataRaw.split("=");
   List<MenuNode> st = List<MenuNode>();
   int last_depth = 0;
   MenuNode root = MenuNode();
   for (String line in data) {
      if (line.isEmpty)
         continue;

      List<String> fields = line.split(";");
      assert(fields.length == 3);

      int depth = int.parse(fields.first);
      String name = fields[1];
      int leafCounter = int.parse(fields.last);

      if (st.isEmpty) {
         root.name = name;
         //root.leafCounter = leafCounter;
         st.add(root);
         continue;
      }

      if (depth > last_depth) {
         if (last_depth + 1 != depth)
            return MenuNode();

         if (st.last.children.isEmpty) {
            st.last.children.add(MenuNode('Todos'));
         }

         // We found the child of the last node pushed on the stack.
         MenuNode p = MenuNode(name);
         st.last.children.add(p);
         st.add(p);
         ++last_depth;
      } else if (depth < last_depth) {
         // Now we have to pop that number of nodes from the stack
         // until we get to the node that should be the parent of the
         // current line.
         int delta_depth = last_depth - depth;
         for (int i = 0; i < delta_depth; ++i)
            st.removeLast();

         st.removeLast();

         // Now we can add the new node.
         MenuNode p = MenuNode(name);
         st.last.children.add(p);
         st.add(p);

         last_depth = depth;
      } else {
         st.removeLast();
         MenuNode p = MenuNode(name);
         st.last.children.add(p);
         st.add(p);
         // Last depth stays equal.
      }
   }

   return root;
}

// This is a one to one struct that we receive from the server.
class MenuItemRaw {
   int filterDepth;
   int version;
   String data;
}

List<MenuItemRaw> readMenuItemRawFromJson(menus)
{
   List<MenuItemRaw> rawMenus = List<MenuItemRaw>();
   for (int i = 0; i < menus.length; ++i) {
      MenuItemRaw item = MenuItemRaw();
      item.filterDepth = menus[i]["depth"];
      item.version = menus[i]["version"];
      item.data = menus[i]["data"];
      rawMenus.add(item);
      //print("depth $depth, version $version, data ");
   }
   
   return rawMenus;
}

// Built from MenuItemRaw by parsing the menu into a tree.
class MenuItem {
   int filterDepth;
   List<MenuNode> root = List<MenuNode>();

   void restoreMenuStack()
   {
      if (root.isEmpty)
         return;

      while (root.length != 1)
         root.removeLast();
   }
}

List<MenuItem> menuReader(Map<String, dynamic> menusMap)
{
   if (!menusMap.containsKey('menus'))
      return null;

   List<MenuItemRaw> rawMenus =
         readMenuItemRawFromJson(menusMap['menus']);

   print('Received menus with length ${rawMenus.length}');

   List<MenuItem> menus = List<MenuItem>();

   for (MenuItemRaw raw in rawMenus) {
      MenuItem item = MenuItem();
      item.filterDepth = raw.filterDepth;
      MenuNode root = buildTree(raw.data);
      item.root.add(root);
      menus.add(item);
   }

   return menus;
}

