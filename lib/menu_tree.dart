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
            st.last.children.add(MenuNode('Todos', '001.001'));
         }

         // We found the child of the last node pushed on the stack.
         MenuNode p = MenuNode(name, '001.002');
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
         MenuNode p = MenuNode(name, '001.003');
         st.last.children.add(p);
         st.add(p);

         last_depth = depth;
      } else {
         st.removeLast();
         MenuNode p = MenuNode(name, '001.004');
         st.last.children.add(p);
         st.add(p);
         // Last depth stays equal.
      }
   }

   return root;
}

class MenuItem {
   int filterDepth;
   int version;
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
   List<dynamic> rawMenus = menusMap['menus'];

   print('Received menus with length ${rawMenus.length}');

   List<MenuItem> menus = List<MenuItem>();

   for (var raw in rawMenus) {
      MenuItem item = MenuItem();
      item.filterDepth = raw["depth"];
      item.version = raw["version"];
      MenuNode root = buildTree(raw["data"]);
      item.root.add(root);
      menus.add(item);
   }

   return menus;
}

class MenuTraversal {
   List<List<MenuNode>> st = List<List<MenuNode>>();
   int depth;

   MenuTraversal(MenuNode root, int depth_)
   {
      depth = depth_;

      if (root != null)
         st.add(<MenuNode>[root]);
   }

   MenuNode advanceToLeaf()
   {
      while (!st.last.last.children.isEmpty && st.length <= depth) {
         List<MenuNode> childrenCopy = List<MenuNode>();
         for (MenuNode o in st.last.last.children)
            childrenCopy.add(o);
         st.add(childrenCopy);
      }

      MenuNode tmp = st.last.last;
      st.last.removeLast();
      return tmp;
   }

   MenuNode nextInternal()
   {
      st.removeLast();
      if (st.isEmpty)
         return null;
      MenuNode tmp = st.last.last;
      st.last.removeLast();
      return tmp;
   }

   MenuNode nextLeafNode()
   {
      while (st.last.isEmpty)
         if (nextInternal() == null)
            return null;

      return advanceToLeaf();
   }

   MenuNode nextNode()
   {
      if (st.last.isEmpty)
         return nextInternal();

      return advanceToLeaf();
   }

   int getDepth()
   {
      return st.length;
   }
}

List<String> readHashCodes(MenuNode root, int depth)
{
   MenuTraversal iter = MenuTraversal(root, depth);
   MenuNode current = iter.advanceToLeaf();
   List<String> hashCodes = List<String>();
   while (current != null) {
      hashCodes.add(current.code);
      current = iter.nextLeafNode();
   }

   return hashCodes;
}

