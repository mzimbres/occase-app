import 'dart:async' show Future;
import 'package:sqflite/sqflite.dart';
import 'package:occase/sql.dart' as sql;
import 'package:occase/constants.dart' as cts;

class MenuElem {
   String code;
   String name;
   int depth;
   int leafReach;
   int index;

   MenuElem({
      this.code = '',
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

class Node {
   String name;
   List<int> code;
   int leafCounter;
   int leafReach;

   List<Node> children;

   Node(
   { this.name = ''
   , this.leafReach = 0
   , this.code
   , this.leafCounter = 0
   })
   {
      children = List<Node>();
   }

   @override
   String toString()
   {
      return name;
   }

   String getChildrenNames()
   {
      String res = children.join(', ');
      if (children.isNotEmpty)
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
List<String> loadNames(Node root, List<int> leafCode)
{
   if (leafCode.isEmpty)
      return List<String>();

   List<String> names = List<String>();
   bool missing = false;
   for (int i in leafCode) {
      // An app that has not been updated may not contains some menu
      // items so we have to check boundaries.
      if (i >= root.children.length || missing) {
         missing = true;
         names.add('');
         continue;
      }

      Node next = root.children[i];
      names.add(next.name);
      root = next;
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
   if (fields.length != 3) {
      print('=====> $line');
   }

   assert(fields.length == 3);

   return MenuElem(
      name: fields[1],
      depth: int.parse(fields.first),
      leafReach: int.parse(fields[2]), // Remove this later.
   );
}

Node parseTree(List<MenuElem> elems, int menuDepth)
{
   List<int> codes = List<int>(menuDepth);
   for (int i = 0; i < codes.length; ++i)
      codes[i] = -1;

   List<Node> st = List<Node>();
   int lastDepth = 0;
   Node root = Node();
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
            print('Error on node: $lastDepth -- ${me.depth};${me.name};${me.leafReach}');
            return Node();
         }

         // We found the child of the last node pushed on the stack.
         Node p = Node(
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
         int deltaDepth = lastDepth - me.depth;
         for (int i = 0; i < deltaDepth; ++i)
            st.removeLast();

         st.removeLast();

         // Now we can add the new node.
         Node p = Node(
            name: me.name,
            code: code,
            leafReach: me.leafReach,
         );

         st.last.children.add(p);
         st.add(p);

         lastDepth = me.depth;
      } else {
         st.removeLast();
         Node p = Node(
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

   // The list below is used as a stack whose first element is the
   // menu root node. When a menu entries is selected it is pushed on
   // the stack and the element is treated a the root of the subtree.
   List<Node> root;

   MenuItem({this.filterDepth = 0}) {
      root = List<Node>();
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
      Node node = root.last.children[k];
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
         //int j = root.length - i - 1; // Index of the last element.
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
      root = List<Node>();

      final String rawMenu = map["data"];
      List<String> lines = rawMenu.split("=");
      lines.removeWhere((String o) {return o.isEmpty;});
      final List<MenuElem> elems = List.generate(lines.length,
         (int i) { return parseFields(lines[i]); });

      final int menuDepth = findMenuDepth(elems);
      if (menuDepth != 0) {
         Node node = parseTree(elems, menuDepth);
         loadLeafCounters(node);
         root.add(node);
      }
   }

   Map<String, dynamic> toJson()
   {
      return
      {
         'depth': filterDepth,
         'data': serializeMenuToStr(root.first),
      };
   }
}

/* Counts all leaf counters of the children. If the leaf counter of a
 * child is zero it is itself a leaf and contributes with one.
 */
int accumulateLeafCounters(Node node)
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
void loadLeafCounters(Node root)
{
   // Here I will choose a depth that is big enough.
   MenuTraversal iter = MenuTraversal(root, 1000);
   Node current = iter.advanceToLeaf();
   while (current != null) {
      current.leafCounter = accumulateLeafCounters(current);
      current = iter.nextNode();
   }
}

int accumulateLeafReach(Node node)
{
   int c = 0;
   for (int i = 0; i < node.children.length; ++i)
      c += node.children[i].leafReach;

   return c;
}

/* Traverses the tree accumulating the leaf reaches.
 */
void loadLeafReaches(Node root, int filterDepth)
{
   MenuTraversal iter = MenuTraversal(root, filterDepth - 1);
   Node current = iter.advanceToLeaf();
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
   List<List<Node>> st = List<List<Node>>();
   int depth;

   MenuTraversal(Node root, int d)
   {
      depth = d;

      if (root != null)
         st.add(<Node>[root]);
   }

   Node advanceToLeaf()
   {
      while (st.last.last.children.isNotEmpty && st.length <= depth) {
         List<Node> childrenCopy = List<Node>();
         for (Node o in st.last.last.children)
            childrenCopy.add(o);
         st.add(childrenCopy);
      }

      Node tmp = st.last.last;
      st.last.removeLast();
      return tmp;
   }

   Node nextInternal()
   {
      st.removeLast();
      if (st.isEmpty)
         return null;
      Node tmp = st.last.last;
      st.last.removeLast();
      return tmp;
   }

   Node nextLeafNode()
   {
      while (st.last.isEmpty)
         if (nextInternal() == null)
            return null;

      return advanceToLeaf();
   }

   Node nextNode()
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

int toChannelHashCodeD4(final List<int> c)
{
   assert(c.length >= 4);

   int ca = c[0];
   int cb = c[1];
   int cc = c[2];
   int cd = c[3];

   const int shift = 16;

   ca <<= 3 * shift;
   cb <<= 2 * shift;
   cc <<= 1 * shift;

   return ca | cb | cc | cd;
}

int toChannelHashCodeD3(final List<int> c)
{
   assert(c.length >= 3);

   int ca = c[0];
   int cb = c[1];
   int cc = c[2];

   const int shift = 21;

   ca <<= 2 * shift;
   cb <<= 1 * shift;

   return ca | cb | cc;
}

int toChannelHashCodeD2(final List<int> c)
{
   assert(c.length >= 2);

   int ca = c[0];
   int cb = c[1];

   const int shift = 32;

   ca <<= shift;
   return ca | cb;
}

int toChannelHashCodeD1(final List<int> c)
{
   assert(c.length >= 1);
   return c[0];
}

// NOTE: Keep this in sync with server code.
int toChannelHashCode(final List<int> code, final int depth)
{
   switch (depth) {
      case 1: return toChannelHashCodeD1(code);
      case 2: return toChannelHashCodeD2(code);
      case 3: return toChannelHashCodeD3(code);
      case 4: return toChannelHashCodeD4(code);
      default: return 0;
   }
}

List<int> readHashCodes(Node root, int depth)
{
   MenuTraversal iter = MenuTraversal(root, depth);
   Node current = iter.advanceToLeaf();
   List<int> hashCodes = List<int>();
   while (current != null) {
      if (current.leafReach > 0)
         hashCodes.add(toChannelHashCode(current.code, depth));

      current = iter.nextLeafNode();
   }

   hashCodes.sort();
   return hashCodes;
}

// Serialize the menu in a way that it can be used as input in
// parseTree.
class MenuTraversal2 {
   List<List<Node>> st = List<List<Node>>();

   MenuTraversal2(final Node root)
   {
      if (root != null)
         st.add(<Node>[root]);
   }

   Node advance()
   {
      final Node node = st.last.last;
      st.last.removeLast();
      if (node.children.isNotEmpty) {
         // TODO: See the TODO in parseTree for why I am adding the
         // nodes here in reverse order. Once that function is fixed
         // the nodes have be added in same order they appear in the
         // childrem array.
         List<Node> childrenCopy = List<Node>();
         // This is correct.
         //for (Node o in node.children)
         //   childrenCopy.add(o);

         // Workaround, should be fixed once parseTree has been fixed.
         for (int i = 0; i < node.children.length; ++i)
            childrenCopy.add(node.children[node.children.length - i - 1]);
         st.add(childrenCopy);
      }

      return node;
   }

   Node next()
   {
      while (st.last.isEmpty) {
         st.removeLast();
         if (st.isEmpty)
            return null;
      }

      return advance();
   }
}

String serializeMenuToStr(final Node root)
{
   MenuTraversal2 iter = MenuTraversal2(root);
   Node current = iter.advance();
   String menu = "";
   while (current != null) {
      final int depth = current.code.length;
      final String line =
         "$depth;${current.name};${current.leafReach}=";
      menu += line;
      current = iter.next();
   }

   return menu;
}

List<MenuElem>
makeMenuElems(final Node root, int index, int maxDepth)
{
   // TODO: The depth is taken from the lenght of the code. Maybe we
   // should consider removing the depth from sqlite to avoid
   // redundancy. This may be difficult however if we do not use fixed
   // size fields.
   List<MenuElem> elems = List<MenuElem>();
   MenuTraversal2 iter = MenuTraversal2(root);
   Node current = iter.advance();
   while (current != null) {
      if (current.code.length <= maxDepth) {
         MenuElem me = MenuElem(
            code: current.code.join('.'),
            name: current.name,
            depth: current.code.length, 
            leafReach: current.leafReach, 
            index: index, 
         );
         elems.add(me);
      }
      current = iter.next();
   }

   return elems;
}

List<MenuItem> loadMenuItems(
   final List<MenuElem> elems,
   final List<int> filterDepths,
) {
   // Here we have to load all leaf counters and leaf reach.
   //
   // NOTE: When the user selects a specific tree node in the filters
   // screen, we save only that specific node's leaf reach on the
   // database, the corrections in the leaf reach of parent nodes are
   // kept in memory, that is why we have to load them here.

   List<MenuItem> menu = List<MenuItem>(2);
   menu[0] = MenuItem();
   menu[1] = MenuItem();

   menu[0].filterDepth = filterDepths[0];
   menu[1].filterDepth = filterDepths[1];

   List<List<MenuElem>> tmp = List<List<MenuElem>>(2);
   tmp[0] = List<MenuElem>();
   tmp[1] = List<MenuElem>();

   elems.forEach((MenuElem me) {tmp[me.index].add(me);});

   for (int i = 0; i < tmp.length; ++i) {
      final int menuDepth = findMenuDepth(tmp[i]);
      if (menuDepth != 0) {
         Node node = parseTree(tmp[i], menuDepth);
         loadLeafCounters(node);
         loadLeafReaches(node, menu[i].filterDepth);
         menu[i].root.add(node);
      }
   }

   return menu;
}

