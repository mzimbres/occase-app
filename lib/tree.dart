import 'dart:async' show Future;
import 'package:sqflite/sqflite.dart';
import 'package:occase/sql.dart' as sql;
import 'package:occase/constants.dart' as cts;

class NodeInfo {
   int depth;
   String name;

   NodeInfo({
      this.depth = -1,
      this.name = '',
   });
}

// To avoid using global variable for the language index I will will
// set them lazily as they are used. Unfourtunately we cannot store
// the index only once as the toString method has no argument.
class Node {
   List<String> _name = <String>[''];
   List<int> _code = List<int>();
   int leafCounter;
   int leafReach;

   List<Node> children;

   int _langIdx = 0;

   Node(String rawName, // In the form a:b:c
   { this.leafReach = 0
   , List<int> code
   , this.leafCounter = 0
   })
   {
      _code = code;
      _name = rawName.split(':');
      children = List<Node>();
   }

   List<int> get code
   {
      _code.removeWhere((o) => o == -1);
      return _code;
   }

   String makeRawName()
   {
      final String ret = _name.join(':');
      assert(ret != null);
      return ret;
   }

   void setName(String rawName)
   {
      _name = rawName.split(':');
   }

   void setLangIdx(int langIdx)
   {
      _langIdx = langIdx;

      // Find a way to specify a default language.
      if (_langIdx >= _name.length)
         _langIdx = 0;
   }

   String name(int langIdx)
   {
      setLangIdx(langIdx);
      return _name[_langIdx];
   }

   @override
   String toString()
   {
      return _name[_langIdx];
   }

   void setLangIdxOnChildren()
   {
      children.forEach((Node node) { node.setLangIdx(_langIdx); });
   }

   String getChildrenNames(int langIdx, int sizeLimit)
   {
      setLangIdx(langIdx);
      setLangIdxOnChildren();

      if (children.isEmpty)
	 return '';

      String res = '';
      if (children.length <= sizeLimit)
	 return children.join(', ');

      final int max =
	 sizeLimit < children.length ? sizeLimit : children.length;

      for (int i = 0; i < max - 1; ++i)
	 res += children[i].toString() + ', ';

      res += children[sizeLimit - 1].toString() + ', ...';
      return res;
   }

   bool isLeaf()
   {
      return children.isEmpty;
   }

   Node at1(int i)
   {
      if (i >= children.length)
	 return Node('');

      return children[i];
   }

   Node at(int i, int j)
   {
      if (i >= children.length)
	 return Node('');

      if (j >= children[i].children.length)
	 return Node('');

      return children[i].children[j];
   }
}

// Given a node code and the menu it corresponds to produces an array
// with the names of the parent up until the root node direct child.
//
// Loads only names with depth greater than or equal to fromDepth.
//
List<String> loadNames({
   Node rootNode,
   List<int> code,
   int languageIndex,
   int fromDepth = 0,
}) {
   if (code.isEmpty)
      return List<String>();

   List<String> names = List<String>();
   bool missing = false;
   for (int i = 0; i < code.length; ++i) {
      if (code[i] >= rootNode.children.length || missing) {
         missing = true;
	 if (i >= fromDepth)
	    names.add('');
         continue;
      }

      if (code[i] == -1)
	 return names;

      Node next = rootNode.children[code[i]];
      if (i >= fromDepth)
	 names.add(next.name(languageIndex));

      rootNode = next;
   }

   return names;
}

// This function should have the same behaviour as its corresponding
// C++ implementation.
int findTreeDepth(List<NodeInfo> elems)
{
   int maxDepth = 0;
   for (NodeInfo o in elems)
      if (maxDepth < o.depth)
         maxDepth = o.depth;

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

NodeInfo parseFields(String line)
{
   final List<String> fields = line.split("\t");

   assert(fields.length == 2);

   return NodeInfo(
      name: fields[1],
      depth: int.parse(fields[0]),
   );
}

Node parseTree(List<String> lines)
{
   // Make sure cts.maxTreeDepth is enough.
   const int maxTreeDepth = 8;
   List<int> codes = List.filled(maxTreeDepth, -1);

   List<Node> st = <Node>[];
   int lastDepth = 0;
   Node root = Node('');
   for (String line in lines) {
      if (line.isEmpty)
	 continue;

      NodeInfo ni = parseFields(line);
      if (st.isEmpty) {
         root.setName(ni.name);
         st.add(root);
         continue;
      }

      codes[ni.depth - 1] += 1;
      for (int i = ni.depth; i < codes.length; ++i)
         codes[i] = -1;

      List<int> code = List<int>.from(codes.getRange(1, codes.length));

      // TODO: The implementation in C++ uses push_front in the deque.
      // We should do the same here, otherwise the nodes appear in the
      // wrong order.
      if (ni.depth > lastDepth) {
         if (lastDepth + 1 != ni.depth) {
            print('Error on node: $lastDepth -- ${ni.depth};${ni.name}');
            return Node('');
         }

         // We found the child of the last node pushed on the stack.
         Node p = Node(ni.name, code: code);

         st.last.children.add(p);
         st.add(p);
         ++lastDepth;
      } else if (ni.depth < lastDepth) {
         // Now we have to pop that number of nodes from the stack
         // until we get to the node that should be the parent of the
         // current line.
         int deltaDepth = lastDepth - ni.depth;
         for (int i = 0; i < deltaDepth; ++i)
            st.removeLast();

         st.removeLast();

         // Now we can add the new node.
         Node p = Node(ni.name, code: code);
         st.last.children.add(p);
         st.add(p);

         lastDepth = ni.depth;
      } else {
         st.removeLast();
         Node p = Node(ni.name, code: code);
         st.last.children.add(p);
         st.add(p);
         // Last depth stays equal.
      }
   }

   return root;
}

// Counts all leaf counters of the children. If the leaf counter of a child is
// zero it is itself a leaf and contributes with one.
int accumulateLeafCounters(Node node)
{
   if (node.children.isEmpty)
      return 1;

   int c = 0;
   for (int i = 0; i < node.children.length; ++i)
      c += node.children[i].leafCounter;

   return c;
}

// Traverses the tree and loads each node with number of leaf nodes it is
// parent from. 
void loadLeafCounters(Node root)
{
   // Uses a depth that is big enough.
   TreeTraversal iter = TreeTraversal(root, 1000);
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

// Traverses the tree accumulating the leaf reaches.
void loadLeafReaches(Node root, int depth)
{
   TreeTraversal iter = TreeTraversal(root, depth - 1);
   Node current = iter.advanceToLeaf();
   while (current != null) {
      current.leafReach = accumulateLeafReach(current);
      current = iter.nextNode();
   }
}

class TreeTraversal {
   List<List<Node>> st = List<List<Node>>();
   int depth;

   TreeTraversal(Node root, int d)
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
   if (c.length < 4)
      return 0;

   //assert(c.length >= 4);

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
   if (c.length < 3)
      return 0;

   //assert(c.length >= 3);

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
   if (c.length < 2)
      return 0;

   //assert(c.length >= 2);

   int ca = c[0];
   int cb = c[1];

   const int shift = 32;

   ca <<= shift;
   return ca | cb;
}

int toChannelHashCodeD1(final List<int> c)
{
   if (c.length < 1)
      return 0;

   //assert(c.length >= 1);

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
   TreeTraversal iter = TreeTraversal(root, depth);
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
class TreeTraversal2 {
   List<List<Node>> st = List<List<Node>>();

   TreeTraversal2(final Node root)
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

String serializeTreeToStr(final Node root)
{
   TreeTraversal2 iter = TreeTraversal2(root);
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

List<NodeInfo>
makeMenuElems(final Node root, int index, int maxDepth)
{
   // TODO: The depth is taken from the lenght of the code. Maybe we
   // should consider removing the depth from sqlite to avoid
   // redundancy. This may be difficult however if we do not use fixed
   // size fields.
   List<NodeInfo> elems = List<NodeInfo>();
   TreeTraversal2 iter = TreeTraversal2(root);
   Node current = iter.advance();
   while (current != null) {
      if (current.code.length <= maxDepth) {
         NodeInfo me = NodeInfo(
            name: current.makeRawName(),
            depth: current.code.length, 
         );
         elems.add(me);
      }
      current = iter.next();
   }

   return elems;
}

// Return a list of all ex details for the given product i.
List<String> makeExDetailsNamesAll(Node root, List<int> exDetails, int i, int lang)
{
   if (i == -1 || i >= root.children.length)
      return List<String>();

   List<String> list = List<String>();
   final int l = root.children[i].children.length;
   for (int j = 0; j < l; ++j) {
      final int n = root.children[i].children[j].children.length;
      final int k = exDetails[j];
      if (k == -1 || k >= n)
	 continue;

      String str = root.children[i].children[j].children[k].name(lang);
      list.add(str);
   }

   return list;
}

List<String> makeInDetailNamesAll(Node root, List<int> inDetails, int i, int lang)
{
   if (i == -1 || i >= root.children.length)
      return <String>[];

   final int l1 = root.children[i].children.length;
   final int l2 = inDetails.length;
   final int l = l1 > l2 ? l2 : l1;

   List<String> ret = List<String>();
   for (int j = 0; j < l; ++j) {
      final int state = inDetails[j];
      final Node node = root.children[i].children[j];
      List<String> names = makeInDetailNames(
	 root: root,
	 state: state,
	 productIndex: i,
	 detailIndex: j,
	 languageIndex: lang,
      );
      ret.addAll(names);
   }

   return ret;
}

List<String> makeInDetailNames({
   Node root,
   int state,
   int productIndex,
   int detailIndex,
   int languageIndex,
}) {
   if (productIndex == -1 || root.children.isEmpty)
      return <String>[];

   List<String> ret = List<String>();
   final Node node = root.children[productIndex].children[detailIndex];

   for (int k = 0; k < node.children.length; ++k)
      if ((state & (1 << k)) != 0)
	 ret.add(node.children[k].name(languageIndex));

   return ret;
}

int getNumberOfProductDetails(Node root, int productIndex)
{
   return root.children[productIndex].children.length;
}

int productDetailLength(Node root, int productIndex, int detailIndex)
{
   return root.children[productIndex].children[detailIndex].children.length;
}

List<String> listAllDetails({
   Node root,
   int productIndex,
   int detailIndex,
   int languageIndex,
}) {
   if (productIndex >= root.children.length)
      return List<String>();

   Node productNode = root.children[productIndex];

   if (detailIndex >= productNode.children.length)
      return List<String>();

   Node detailNode = productNode.children[detailIndex];

   List<String> ret = List<String>();

   for (int i = 0; i < detailNode.children.length; ++i)
      ret.add(detailNode.children[i].name(languageIndex));

   return ret;
}

