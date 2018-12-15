
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

MenuTree LocationFactory()
{

   MenuNode root = MenuNode("Brasil", "");

   MenuNode c1 = MenuNode("Sao Paulo", "00");
   c1.children.add(MenuNode("Atibaia", "00.00"));
   c1.children.add(MenuNode("Braganca", "00.01"));
   root.children.add(c1);

   MenuNode c2 = MenuNode("Amazonas", "01");
   c2.children.add(MenuNode("Outras", "01.00"));
   root.children.add(c2);

   MenuNode c3 = MenuNode("Amapa", "02");
   c3.children.add(MenuNode("Macapa", "02.00"));
   c3.children.add(MenuNode("Outras", "02.01"));
   root.children.add(c3);

   MenuNode c4 = MenuNode("Pernambuco", "03");
   c4.children.add(MenuNode("Outras", "03.00"));
   root.children.add(c4);

   MenuNode c5 = MenuNode("Rio Grande do Sul", "04");
   c5.children.add(MenuNode("Outras", "04.00"));
   root.children.add(c5);

   MenuNode c6 = MenuNode("Santa Catarina", "05");
   c6.children.add(MenuNode("Outras", "05.00"));
   root.children.add(c6);

   return MenuTree(root);
}

MenuTree ModelsFactory()
{

   MenuNode root = MenuNode("Carros", "");

   MenuNode c1 = MenuNode("Fiat", "00");
   c1.children.add(MenuNode("Palio", "00.00"));
   c1.children.add(MenuNode("Fiat 147", "00.01"));
   c1.children.add(MenuNode("Uno", "00.02"));
   root.children.add(c1);

   MenuNode c2 = MenuNode("Ford", "01");
   c2.children.add(MenuNode("Corsa", "01.00"));
   c2.children.add(MenuNode("Todos", "01.00"));
   root.children.add(c2);

   MenuNode c3 = MenuNode("Volkswagen", "02");
   c3.children.add(MenuNode("Fusca", "02.00"));
   c3.children.add(MenuNode("Saveiro", "02.01"));
   root.children.add(c3);

   MenuNode c4 = MenuNode("Chevrolet", "03");
   c4.children.add(MenuNode("Fiesta", "03.00"));
   root.children.add(c4);

   MenuNode c5 = MenuNode("Honda", "04");
   c5.children.add(MenuNode("Hyunday", "04.00"));
   root.children.add(c5);

   return MenuTree(root);
}
