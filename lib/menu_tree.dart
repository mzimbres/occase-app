import 'dart:convert';
import 'package:menu_chat/constants.dart';

class MenuNode {
   String name;
   String code;
   bool status;
   List<MenuNode> children = List<MenuNode>();

   MenuNode(this.name, this.code)
   {
      status = false;
   }

   bool isLeaf()
   {
      return children.isEmpty;
   }
}

class MenuTree {
   List<MenuNode> st = List<MenuNode>();

   MenuTree(MenuNode root)
   {
      st.add(root);
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

void buildTree(String msg)
{
   //MenuNode rootNode = MenuNode();

   Map<String, dynamic> menu = jsonDecode(msg);

   List<dynamic> arr = menu["menu"];
   //print("Menu array size: ${arr.length}");

   //while (arr != null) {
      for (var o in arr) {
         Map<String, dynamic> sub = o;
         MenuNode node = MenuNode(sub["name"], sub["hash"]);
         //rootNode.children.add(node);
         print("${node.name} ===> ${node.code}");
      }
   //}

   //root.forEach((k, v) => print(v));


   //Map<String, dynamic> root = jsonDecode(arr.first);
   //var root = jsonDecode(arr.first);
   //print("Root sub size: ${root.length}");
}

MenuTree LocationFactory()
{
   buildTree(Consts.menu);

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
   return MenuTree(root);
}

MenuTree ModelsFactory()
{
   MenuNode root = MenuNode("Brasil", "");
   root.children.add(makeNode("Acura", <String>["Porto Velho", "Cruzeiro do Sul", "Sena Madureira", "Tarauacá", "Feijó", "Outras"]));
   root.children.add(makeNode("Agrale", <String>["Maceio", "Arapiraca", "Rio Largo", "Palmeira dos Índios", "União dos Palmares", "Outras"]));
   root.children.add(makeNode("Alpha Romeo", <String>["Macapa", "Santana", "Laranjal do Jari", "Oiapoque", "Mazagão", "Outras"]));
   root.children.add(makeNode("AM Gen", <String>["Manaus", "Parintins", "Itacoatiara", "Manacapuru", "Coari", "Outras"]));
   root.children.add(makeNode("Asia Motors", <String>["Salvador", "Feira de Santana", "Vitória da Conquista", "Camaçari", "Itabuna", "Outras"]));
   root.children.add(makeNode("Aston Martin", <String>["Fortaleza", "Caucaia", "Juazeiro do Norte", "Maracanaú", "Sobral", "Outras"]));
   root.children.add(makeNode("Audi", <String>["Brasilia"]));
   root.children.add(makeNode("Baby", <String>["Vitoria", "Vila Velha", "Cariacica", "Serra", "Outras"]));
   root.children.add(makeNode("BMW", <String>["Goiânia", "Outras"]));
   root.children.add(makeNode("BRM", <String>["Sao Luis", "Outras"]));
   root.children.add(makeNode("Bugre", <String>["Cuiaba", "Outras"]));
   root.children.add(makeNode("Cadilac", <String>["Campo Grande", "Outras"]));
   root.children.add(makeNode("CBT Jipe", <String>["Belo Horizonte", "Outras"]));
   root.children.add(makeNode("Chana", <String>["Belém", "Outras"]));
   root.children.add(makeNode("Changan", <String>["Joao Pessoa", "Outras"]));
   root.children.add(makeNode("Chery", <String>["Recife", "Outras"]));
   root.children.add(makeNode("Chrysler", <String>["Terizina", "Outras"]));
   root.children.add(makeNode("Citroen", <String>["Rio de Janeiro", "Outras"]));
   root.children.add(makeNode("Cross Lander", <String>["Natal", "Outras"]));
   root.children.add(makeNode("Daewoo", <String>["Porto Alegre", "Outras"]));
   root.children.add(makeNode("Daihatsu", <String>["Porto Velho", "Outras"]));
   root.children.add(makeNode("Dodge", <String>["Boa Vista", "Outras"]));
   root.children.add(makeNode("Effa", <String>["Florianópolis", "Outras"]));
   root.children.add(makeNode("Engesa", <String>["Sao Paulo", "Outras"]));
   root.children.add(makeNode("Envemo", <String>["Aracaju", "Outras"]));
   root.children.add(makeNode("Fiat", <String>["Palmas", "Outras"]));
   root.children.add(makeNode("Fibravam", <String>["Palmas", "Outras"]));
   root.children.add(makeNode("Ford", <String>["Palmas", "Outras"]));
   root.children.add(makeNode("Foton", <String>["Palmas", "Outras"]));
   root.children.add(makeNode("Fyber", <String>["Palmas", "Outras"]));
   root.children.add(makeNode("Geely", <String>["Palmas", "Outras"]));
   root.children.add(makeNode("GM - Chevrolet", <String>["Palmas", "Outras"]));
   root.children.add(makeNode("Greate Wall", <String>["Palmas", "Outras"]));
   root.children.add(makeNode("Gurgel", <String>["Palmas", "Outras"]));
   root.children.add(makeNode("Hafei", <String>["Palmas", "Outras"]));
   root.children.add(makeNode("Honda", <String>["Palmas", "Outras"]));
   root.children.add(makeNode("Hyunday", <String>["Palmas", "Outras"]));
   root.children.add(makeNode("Isuzu", <String>["Palmas", "Outras"]));
   root.children.add(makeNode("Iveco", <String>["Palmas", "Outras"]));
   root.children.add(makeNode("Jaca", <String>["Palmas", "Outras"]));
   root.children.add(makeNode("Jaguar", <String>["Palmas", "Outras"]));
   root.children.add(makeNode("Jeep", <String>["Palmas", "Outras"]));
   root.children.add(makeNode("Jinbey", <String>["Palmas", "Outras"]));
   return MenuTree(root);
}
