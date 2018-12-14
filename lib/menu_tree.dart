
class MenuNode {
   String name;
   List<MenuNode> children;
}

class MenuTree {
   MenuNode root;
   List<MenuNode> st;
}

List<List<String>> LocationFactory()
{
   List<String> _brands = <String>[
      "Alfa Romeo",
      "BMW",
      "Fiat",
      "Volkswagen",
      "Mercedes",
      "Ford",
      "Chevrolet",
      "Citroen",
      "Peugeot",
      "Ferrari",
      "Dodge",
      "Rolls Roice",
   ];

   List<String> _models = <String>[
      "Uno mil",
      "Palio",
      "Premio",
   ];

   List<List<String>> a1 = new List<List<String>>();
   a1.add(_brands);
   a1.add(_models);

   return a1;
}

