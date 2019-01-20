import 'dart:convert';
import 'package:menu_chat/constants.dart';

class MenuNode {
   String name;
   String code;
   bool status;
   int leafCounter;

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

// This function should have the same behaviour as its corresponding
// C++ implementation.
int getMenuDepth(String rawMenu)
{
   int maxDepth = 0;
   List<String> lines = rawMenu.split("=");
   for (String line in lines) {
      if (line.isEmpty)
         continue;

      List<String> fields = line.split(";");
      if (fields.isEmpty)
         continue;

      int depth = int.parse(fields.first);
      if (maxDepth < depth)
         maxDepth = depth;
   }

   return 1 + maxDepth;
}

String genCode(List<int> codes, int depth)
{

   if (depth == 0) {
      //print("1) Depth: $depth ==> ${codes} ==> ");
      return '';
   }

   if (depth == 1) {
      //print("2) Depth: $depth ==> ${codes} ==> ${codes.first}");
      return codes.first.toRadixString(16).padLeft(3, '0');
   }

   String code = '';
   for (int i = 0; i < depth - 1; ++i)
      code += codes[i].toRadixString(16).padLeft(3, '0') + '.';

   code += codes[depth - 1].toRadixString(16).padLeft(3, '0');
   //print("3) Depth: $depth ==> ${codes} ==> ${code}");
   return code;
}

MenuNode parseTree(String dataRaw)
{
   final int maxDepth = getMenuDepth(dataRaw);
   if (maxDepth == 0)
      return null;

   print("Menu depth: $maxDepth");

   List<int> codes = List<int>(maxDepth - 1);
   for (int i = 0; i < codes.length; ++i)
      codes[i] = -1;

   List<String> lines = dataRaw.split("=");
   List<MenuNode> st = List<MenuNode>();
   int lastDepth = 0;
   MenuNode root = MenuNode();
   for (String line in lines) {
      if (line.isEmpty)
         continue;

      List<String> fields = line.split(";");
      assert(fields.length == 3);

      int depth = int.parse(fields.first);
      String name = fields[1];

      if (st.isEmpty) {
         root.name = name;
         st.add(root);
         continue;
      }

      codes[depth - 1] += 1;
      for (int i = depth; i < codes.length; ++i)
         codes[i] = -1;

      final String code = genCode(codes, depth);
      //print(code);

      if (depth > lastDepth) {
         if (lastDepth + 1 != depth)
            return MenuNode();

         if (st.last.children.isEmpty) {
            st.last.children.add(MenuNode('Marcar Todos', ''));
         }

         // We found the child of the last node pushed on the stack.
         MenuNode p = MenuNode(name, code);
         st.last.children.add(p);
         st.add(p);
         ++lastDepth;
      } else if (depth < lastDepth) {
         // Now we have to pop that number of nodes from the stack
         // until we get to the node that should be the parent of the
         // current line.
         int delta_depth = lastDepth - depth;
         for (int i = 0; i < delta_depth; ++i)
            st.removeLast();

         st.removeLast();

         // Now we can add the new node.
         MenuNode p = MenuNode(name, code);
         st.last.children.add(p);
         st.add(p);

         lastDepth = depth;
      } else {
         st.removeLast();
         MenuNode p = MenuNode(name, code);
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

/* Traverses the tree and loads each node with number of leaf nodes it
 * is parent from. 
 */
void loadLeafCounters(MenuNode root)
{
   // TODO: Give more serious treatment for the max depth. Here I will
   // choose a depth that is big enough.

   MenuTraversal iter = MenuTraversal(root, 1000);
   MenuNode current = iter.advanceToLeaf();
   while (current != null) {
      int counter = 0;
      if (!current.children.isEmpty) {
         assert(current.children.length > 1);
         int c = 0;
         for (int i = 1; i < current.children.length; ++i) {
            if (current.children[i].children.isEmpty)
               c += 1;
            else
               c += current.children[i].leafCounter;
         }
         counter = c;
      }

      current.leafCounter = counter;
      current = iter.nextNode();
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
      MenuNode root = parseTree(raw["data"]);
      loadLeafCounters(root);
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
   // TODO: Skip the *Todos* hash code.
   MenuTraversal iter = MenuTraversal(root, depth);
   MenuNode current = iter.advanceToLeaf();
   List<String> hashCodes = List<String>();
   while (current != null) {
      //print('${current.code} ===> ${current.status}');
      if (current.status) {
         print(current.code);
         hashCodes.add(current.code);
         print('${current.code} ===> ${current.status}');
      }
      current = iter.nextLeafNode();
   }

   return hashCodes;
}

