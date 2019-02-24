import 'dart:convert';
import 'package:menu_chat/constants.dart';

class MenuNode {
   String name;
   List<int> code;
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

// Given a leaf code and the menu it corresponds to produces an array
// with the names of the parent up until the root direct child.
List<String> loadNames(MenuNode root, List<int> leafCode)
{
   if (leafCode.isEmpty)
      return List<String>();

   List<String> names = List<String>();
   MenuNode iter = root;
   for (int idx in leafCode) {
      MenuNode next = iter.children[idx];
      names.add(next.name);
      iter = next;
   }

   return names;
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

   return maxDepth;
}

// Currently we do not need this function.
String genCode(List<int> codes, int depth)
{
   if (depth == 0) {
      return '';
   }

   if (depth == 1) {
      return codes.first.toRadixString(16).padLeft(3, '0');
   }

   String code = '';
   for (int i = 0; i < depth - 1; ++i)
      code += codes[i].toRadixString(16).padLeft(3, '0') + '.';

   code += codes[depth - 1].toRadixString(16).padLeft(3, '0');
   return code;
}

MenuNode parseTree(String dataRaw)
{
   final int maxDepth = getMenuDepth(dataRaw);
   if (maxDepth == 0)
      return null;

   List<int> codes = List<int>(maxDepth);
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

      List<int> code = List<int>.from(codes);
      code.removeWhere((o) => o == -1);

      if (depth > lastDepth) {
         if (lastDepth + 1 != depth)
            return MenuNode();

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

   bool isFilterLeaf()
   {
      //print('${root.length} == ${filterDepth}');
      return root.length == filterDepth;
   }

   void restoreMenuStack()
   {
      if (root.isEmpty)
         return;

      while (root.length != 1)
         root.removeLast();
   }
}

/* Counts all leaf counters of the children. If the leaf counter of a
 * child is zero she is itself a leaf and contributes with one.
 */
int accumulateLeafCounters(MenuNode node)
{
   if (node.children.isEmpty)
      return 0;

   int c = 0;
   for (int i = 0; i < node.children.length; ++i) {
      if (node.children[i].children.isEmpty)
         c += 1;
      else
         c += node.children[i].leafCounter;
   }

   return c;
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
      current.leafCounter = accumulateLeafCounters(current);
      current = iter.nextNode();
   }
}

List<MenuItem> menuReader(Map<String, dynamic> menusMap)
{
   List<dynamic> rawMenus = menusMap['menus'];

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

List<List<int>> readHashCodes(MenuNode root, int depth)
{
   MenuTraversal iter = MenuTraversal(root, depth);
   MenuNode current = iter.advanceToLeaf();
   List<List<int>> hashCodes = List<List<int>>();
   while (current != null) {
      if (current.status)
         hashCodes.add(current.code);

      current = iter.nextLeafNode();
   }

   return hashCodes;
}

// Serialize the menu in a way that it can be user as input in
// parseTree.
class MenuTraversal2 {
   List<List<MenuNode>> st = List<List<MenuNode>>();

   MenuTraversal2(MenuNode root)
   {
      if (root != null)
         st.add(<MenuNode>[root]);
   }

   MenuNode advance()
   {
      MenuNode node = st.last.last;
      st.last.removeLast();
      if (!node.children.isEmpty)
         st.add(node.children);

      return node;
   }

   MenuNode next()
   {
      while (st.last.isEmpty) {
         st.removeLast();
         if (st.isEmpty)
            return null;
      }

      return advance();
   }

   int getDepth()
   {
      return st.length - 1;
   }
}

String serializeMenuToStr(MenuNode root)
{
   MenuTraversal2 iter = MenuTraversal2(root);
   MenuNode current = iter.advance();
   String menu = "";
   while (current != null) {
      final int depth = iter.getDepth();
      menu += "${depth};${current.name};${current.status}=";
      current = iter.next();
   }

   return menu;
}

