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

      int depth = int.parse(fields.first);
      String name = fields.last;

      if (st.isEmpty) {
         root.name = name;
         st.add(root);
         continue;
      }

      if (depth > last_depth) {
         if (last_depth + 1 != depth)
            return MenuNode();

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

List<MenuNode> menuReader(String jdata)
{
   Map<String, dynamic> menu = jsonDecode(jdata);
   String dataRaw = menu["data"];
   MenuNode root = buildTree(dataRaw);
   List<MenuNode> ret = List<MenuNode>();
   ret.add(root);
   return ret;
}

