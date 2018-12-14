
class MenuNode {
   String name;
   String code;
   List<MenuNode> children = List<MenuNode>();

   MenuNode(this.name, this.code);

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
   MenuNode cc1 = new MenuNode("Atibaia", "00.00");
   MenuNode cc2 = new MenuNode("Braganca", "00.01");

   MenuNode root = new MenuNode("Brasil", "");

   MenuNode c1 = new MenuNode("Sao Paulo", "00");
   c1.children.add(cc1);
   root.children.add(c1);

   MenuNode c2 = new MenuNode("Amazonas", "01");
   c2.children.add(cc1);
   root.children.add(c2);

   MenuNode c3 = new MenuNode("Amapa", "02");
   c3.children.add(cc1);
   root.children.add(c3);

   MenuNode c4 = new MenuNode("Pernambuco", "03");
   c4.children.add(cc1);
   root.children.add(c3);

   MenuNode c5 = new MenuNode("Rio Grande do Sul", "04");
   c5.children.add(cc1);
   root.children.add(c5);

   MenuNode c6 = new MenuNode("Santa Catarina", "05");
   c6.children.add(cc1);
   root.children.add(c6);

   return MenuTree(root);
}

