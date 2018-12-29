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

MenuNode makeNode(String state, List<String> cities)
{
   MenuNode node = MenuNode(state, "00.02");

   for (String s in cities) {
      node.children.add(MenuNode(s, "00.01.09"));
   }

   return node;
}

MenuNode buildTree(String dataRaw)
{
   List<String> data = dataRaw.split("=");
   List<MenuNode> st = List<MenuNode>();
   int last_depth = 0;
   MenuNode root;
   for (String line in data) {
      if (line.isEmpty)
         continue;

      List<String> fields = line.split(";");

      int depth = int.parse(fields.first);
      String name = fields.last;

      if (root == null) {
         root = MenuNode(name);
         st.add(root);
         continue;
      }

      if (depth > last_depth) {
         if (last_depth + 1 != depth)
            return null;

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

List<MenuNode> ModelsFactory()
{
   Map<String, dynamic> menu = jsonDecode(Consts.menu);
   String dataRaw = menu["data"];
   MenuNode root = buildTree(dataRaw);
   List<MenuNode> ret = List<MenuNode>();
   ret.add(root);
   return ret;
}

List<MenuNode> LocationFactory()
{
   MenuNode root = MenuNode("Brasil", "");
   root.children.add(makeNode("Acre", <String>["Porto Velho", "Cruzeiro do Sul", "Sena Madureira", "Tarauacá", "Feijó", "Outras"]));
   root.children.add(makeNode("Alagoas", <String>["Maceio", "Arapiraca", "Rio Largo", "Palmeira dos Índios", "União dos Palmares", "Outras"]));
   root.children.add(makeNode("Amapa", <String>["Macapa", "Santana", "Laranjal do Jari", "Oiapoque", "Mazagão", "Outras"]));
   root.children.add(makeNode("Amazonas", <String>["Manaus", "Parintins", "Itacoatiara", "Manacapuru", "Coari", "Outras"]));
   root.children.add(makeNode("Bahia", <String>["Salvador", "Feira de Santana", "Vitória da Conquista", "Camaçari", "Itabuna", "Outras"]));
   root.children.add(makeNode("Ceará", <String>["Fortaleza", "Caucaia", "Juazeiro do Norte", "Maracanaú", "Sobral", "Outras"]));
   root.children.add(makeNode("Distrito Federal", <String>["Brasilia"]));
   root.children.add(makeNode("Espirito Santo", <String>["Vitoria", "Vila Velha", "Cariacica", "Serra", "Outras"]));
   root.children.add(makeNode("Goias", <String>["Goiânia", "Outras"]));
   root.children.add(makeNode("Maranhao", <String>["Sao Luis", "Outras"]));
   root.children.add(makeNode("Mato Grosso", <String>["Cuiaba", "Outras"]));
   root.children.add(makeNode("Mato Grosso do Sul", <String>["Campo Grande", "Outras"]));
   root.children.add(makeNode("Minas Gerais", <String>["Belo Horizonte", "Outras"]));
   root.children.add(makeNode("Pará", <String>["Belém", "Outras"]));
   root.children.add(makeNode("Paraíba", <String>["Joao Pessoa", "Outras"]));
   root.children.add(makeNode("Pernambuco", <String>["Recife", "Outras"]));
   root.children.add(makeNode("Piaui", <String>["Terizina", "Outras"]));
   root.children.add(makeNode("Rio de Janeiro", <String>["Rio de Janeiro", "Outras"]));
   root.children.add(makeNode("Rio Grande do Norte", <String>["Natal", "Outras"]));
   root.children.add(makeNode("Rio Grande do Sul", <String>["Porto Alegre", "Outras"]));
   root.children.add(makeNode("Rondônia", <String>["Porto Velho", "Outras"]));
   root.children.add(makeNode("Rorâima", <String>["Boa Vista", "Outras"]));
   root.children.add(makeNode("Santa Catarina", <String>["Florianópolis", "Outras"]));
   root.children.add(makeNode("Sao Paulo", <String>["Sao Paulo", "Outras"]));
   root.children.add(makeNode("Sergipe", <String>["Aracaju", "Outras"]));
   root.children.add(makeNode("Tocantins", <String>["Palmas", "Outras"]));
   List<MenuNode> ret = List<MenuNode>();
   ret.add(root);
   return ret;
}

