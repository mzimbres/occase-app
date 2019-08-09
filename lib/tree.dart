import 'dart:convert';
import 'dart:math';
import 'package:menu_chat/constants.dart';
import 'package:sqflite/sqflite.dart';
import 'package:menu_chat/sql.dart' as sql;

class MenuElem {
   String code;
   String name;
   int depth;
   int leafReach;
   int index;

   MenuElem({this.code = '',
             this.name = '',
             this.depth = -1,
             this.leafReach = -1,
             this.index = -1,
   });
}

Map<String, dynamic> menuElemToMap(MenuElem me)
{
   return {
      'code': me.code,
      'depth': me.depth,
      'leaf_reach': me.leafReach,
      'name': me.name,
      'idx': me.index,
   };
}

Future<List<MenuElem>> loadMenu(Database db) async
{
  final List<Map<String, dynamic>> maps = await db.query('menu');

  return List.generate(maps.length, (i)
  {
     MenuElem me = MenuElem(
        code: maps[i]['code'],
        depth: maps[i]['depth'],
        leafReach: maps[i]['leaf_reach'],
        name: maps[i]['name'],
        index: maps[i]['idx'],
     );

     return me;

  });
}

class MenuNode {
   String name;
   List<int> code;
   int leafCounter;
   int leafReach;

   List<MenuNode> children;

   MenuNode({this.name = '',
             this.leafReach = 0,
             this.code,
             this.leafCounter = 0})
   {
      children = List<MenuNode>();
   }

   @override
   String toString()
   {
      return name;
   }

   String getChildrenNames()
   {
      String res = children.join(', ');
      if (!children.isEmpty)
         return res + '.';

      return res;
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
int findMenuDepth(List<MenuElem> elems)
{
   int maxDepth = 0;
   for (MenuElem me in elems)
      if (maxDepth < me.depth)
         maxDepth = me.depth;

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

// This function does not fill all fields of menuElem.
MenuElem parseFields(String line)
{
   List<String> fields = line.split(";");
   assert(fields.length == 3);

   return MenuElem(
      name: fields[1],
      depth: int.parse(fields.first),
      leafReach: int.parse(fields[2]), // Remove this later.
   );
}

MenuNode parseTree(List<MenuElem> elems, int menuDepth)
{
   List<int> codes = List<int>(menuDepth);
   for (int i = 0; i < codes.length; ++i)
      codes[i] = -1;

   List<MenuNode> st = List<MenuNode>();
   int lastDepth = 0;
   MenuNode root = MenuNode();
   for (MenuElem me in elems) {
      //print('${me.depth}; ${me.name}; ${me.code}; ${me.leafReach}; ${me.index}');
      if (st.isEmpty) {
         root.name = me.name;
         root.code = List<int>();
         root.leafReach = 0;
         st.add(root);
         continue;
      }

      codes[me.depth - 1] += 1;
      for (int i = me.depth; i < codes.length; ++i)
         codes[i] = -1;

      List<int> code = List<int>.from(codes);
      code.removeWhere((o) => o == -1);

      // TODO: The implementation in C++ uses push_front in the deque.
      // We should do the same here, otherwise the nodes appear in the
      // wrong order.
      if (me.depth > lastDepth) {
         if (lastDepth + 1 != me.depth) {
            print('Error on node: ${lastDepth} -- ${me.depth};${me.name};${me.leafReach}');
            return MenuNode();
         }

         // We found the child of the last node pushed on the stack.
         MenuNode p = MenuNode(
            name: me.name,
            code: code,
            leafReach: me.leafReach,
         );

         st.last.children.add(p);
         st.add(p);
         ++lastDepth;
      } else if (me.depth < lastDepth) {
         // Now we have to pop that number of nodes from the stack
         // until we get to the node that should be the parent of the
         // current line.
         int delta_depth = lastDepth - me.depth;
         for (int i = 0; i < delta_depth; ++i)
            st.removeLast();

         st.removeLast();

         // Now we can add the new node.
         MenuNode p = MenuNode(
            name: me.name,
            code: code,
            leafReach: me.leafReach,
         );

         st.last.children.add(p);
         st.add(p);

         lastDepth = me.depth;
      } else {
         st.removeLast();
         MenuNode p = MenuNode(
            name: me.name,
            code: code,
            leafReach: me.leafReach,
         );

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

   // The list below is used as a stack whose first element is the
   // menu root node. When a menu entries is selected it is pushed on
   // the stack and the element is treated a the root of the subtree.
   List<MenuNode> root;

   MenuItem({this.filterDepth = 0,
             this.version = 0})
   {
      root = List<MenuNode>();
   }

   // Returns the name of each node in the menu stack. 
   String getStackNames()
   {
      return root.join(', ');
   }

   // It is assumed that this function will be called when the last
   // node in the stack is the parent of a leaf and k will be the
   // index of the leaf int the array of children of the top node.
   void updateLeafReach(int k, Batch batch, int idx)
   {
      int d = 0;
      MenuNode node = root.last.children[k];
      if (node.leafReach > 0) {
         d = - node.leafCounter;
         node.leafReach = 0;
      } else {
         d = node.leafCounter;
         node.leafReach = node.leafCounter;
      }

      // d contains how much we have to increase or decrease the
      // parent nodes.

      for (int i = 0; i < root.length; ++i) {
         int j = root.length - i - 1; // Index of the last element.
         root[i].leafReach += d;
      }

      final String code = node.code.join('.');
      batch.rawUpdate(sql.updateLeafReach,
                      [node.leafReach, code, idx]);
   }

   void updateLeafReachAll(Batch batch, int idx)
   {
      final int l = root.last.children.length;
      for (int i = 0; i < l; ++i)
         updateLeafReach(i, batch, idx);
   }

   bool isFilterLeaf()
   {
      return root.length == filterDepth;
   }

   void restoreMenuStack()
   {
      if (root.isEmpty)
         return;

      while (root.length != 1)
         root.removeLast();
   }

   MenuItem.fromJson(Map<String, dynamic> map)
   {
      filterDepth = map["depth"];
      version = map["version"];
      root = List<MenuNode>();

      final String rawMenu = map["data"];
      List<String> lines = rawMenu.split("=");
      lines.removeWhere((String o) {return o.isEmpty;});
      final List<MenuElem> elems = List.generate(lines.length,
         (int i) { return parseFields(lines[i]); });

      final int menuDepth = findMenuDepth(elems);
      if (menuDepth != 0) {
         MenuNode node = parseTree(elems, menuDepth);
         loadLeafCounters(node);
         root.add(node);
      }
   }

   Map<String, dynamic> toJson()
   {
      return
      {
         'depth': filterDepth,
         'version': version,
         'data': serializeMenuToStr(root.first),
      };
   }
}

/* Counts all leaf counters of the children. If the leaf counter of a
 * child is zero it is itself a leaf and contributes with one.
 */
int accumulateLeafCounters(MenuNode node)
{
   if (node.children.isEmpty)
      return 1;

   int c = 0;
   for (int i = 0; i < node.children.length; ++i)
      c += node.children[i].leafCounter;

   return c;
}

/* Traverses the tree and loads each node with number of leaf nodes it
 * is parent from. 
 */
void loadLeafCounters(MenuNode root)
{
   // Here I will choose a depth that is big enough.
   MenuTraversal iter = MenuTraversal(root, 1000);
   MenuNode current = iter.advanceToLeaf();
   while (current != null) {
      current.leafCounter = accumulateLeafCounters(current);
      current = iter.nextNode();
   }
}

int accumulateLeafReach(MenuNode node)
{
   int c = 0;
   for (int i = 0; i < node.children.length; ++i)
      c += node.children[i].leafReach;

   return c;
}

/* Traverses the tree accumulating the leaf reaches.
 */
void loadLeafReaches(MenuNode root, int filterDepth)
{
   MenuTraversal iter = MenuTraversal(root, filterDepth - 1);
   MenuNode current = iter.advanceToLeaf();
   while (current != null) {
      current.leafReach = accumulateLeafReach(current);
      current = iter.nextNode();
   }
}

List<MenuItem> menuReader(Map<String, dynamic> menusMap)
{
   List<dynamic> rawMenus = menusMap['menus'];

   List<MenuItem> menus = List<MenuItem>();

   for (var raw in rawMenus) {
      MenuItem item = MenuItem.fromJson(raw);
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
      if (current.leafReach > 0)
         hashCodes.add(current.code);

      current = iter.nextLeafNode();
   }

   return hashCodes;
}

// Serialize the menu in a way that it can be user as input in
// parseTree.
class MenuTraversal2 {
   List<List<MenuNode>> st = List<List<MenuNode>>();

   MenuTraversal2(final MenuNode root)
   {
      if (root != null)
         st.add(<MenuNode>[root]);
   }

   MenuNode advance()
   {
      final MenuNode node = st.last.last;
      st.last.removeLast();
      if (!node.children.isEmpty) {
         // TODO: See the TODO in parseTree for why I am adding the
         // nodes here in reverse order. Once that function is fixed
         // the nodes have be added in same order they appear in the
         // childrem array.
         List<MenuNode> childrenCopy = List<MenuNode>();
         // This is correct.
         //for (MenuNode o in node.children)
         //   childrenCopy.add(o);

         // Workaround, should be fixed once parseTree has been fixed.
         for (int i = 0; i < node.children.length; ++i)
            childrenCopy.add(node.children[node.children.length - i - 1]);
         st.add(childrenCopy);
      }

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
}

String serializeMenuToStr(final MenuNode root)
{
   MenuTraversal2 iter = MenuTraversal2(root);
   MenuNode current = iter.advance();
   String menu = "";
   while (current != null) {
      final int depth = current.code.length;
      final String line =
         "${depth};${current.name};${current.leafReach}=";
      menu += line;
      current = iter.next();
   }

   return menu;
}

List<MenuElem> makeMenuElems(final MenuNode root, int index)
{
   // TODO: The depth is taken from the lenght of the code. Maybe we
   // should consider removing the depth from sqlite to avoid
   // redundancy. This may be difficult however if we do not use fixed
   // size fields.
   List<MenuElem> elems = List<MenuElem>();
   MenuTraversal2 iter = MenuTraversal2(root);
   MenuNode current = iter.advance();
   while (current != null) {
      MenuElem me = MenuElem(
         code: current.code.join('.'),
         name: current.name,
         depth: current.code.length, 
         leafReach: current.leafReach, 
         index: index, 
      );
      elems.add(me);
      current = iter.next();
   }

   return elems;
}

List<int> makeMenuVersions(final List<MenuItem> menus)
{
   List<int> versions = List<int>();
   for (MenuItem o in menus)
      versions.add(o.version);

   return versions;
}

