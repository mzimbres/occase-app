import 'package:flutter/material.dart';

class TextConsts {
   static final String appName = "CarMenu";

   // Text used for the main tabs.
   static final List<String> tabNames =
         <String>["FILTROS", "POSTS", "CHATS"];

   //______________

   // Text used in the *new advertisement screens* on the bottom
   // navigation bar.
   static final List<String> newAdvTabNames =
         <String>['Localizacao', 'Modelos', 'Publicar'];

   static List<IconData> newAdvTabIcons =
         <IconData>[Icons.home, Icons.directions_car, Icons.publish];

   static final List<String> filterTabNames =
         <String>['Localizacao', 'Modelos', 'Salvar'];

   static List<IconData> filterTabIcons =
         <IconData>[Icons.home, Icons.directions_car, Icons.send];
   //______________

   // Text used in the chat screen.
   static final List<String> chatIconTexts =
         <String>['Meus anúncios', 'Favoritos'];

   static List<IconData> chatIcons =
         <IconData>[Icons.list, Icons.star_border];

   //______________

   // The text shown on the app bar for each tab on the *new
   // advertisement screen.*
   static final List<String> advAppBarMsg =
      <String>["Escolha uma localizacao", "Escolha um modelo",
               "Verificacao e envio"];

   // The name of the fields at each menu depth.
   static final List<List<String>> menuDepthNames =
   <List<String>>[
      <String>["Estado", "Cidade", "Bairro"],
      <String>["Marca",  "Tipo", "Modelo", "Ano", "Combustivel", "Preco Fipe"],
   ];

   // The text in the adv description field.
   static final String descriptionText = "Descricao";

   // Text used in the adv screen to save the adv for chat.
   static final String ownAdvButtonText = "Ver interessados";

   static final String newAdvDescDeco = "Digite aqui informacoes adicionais";

   static final IconData newAdvIcon = Icons.publish;

   static final String hintTextChat = "Digite sua mensagem";

   static final Color allMenuItemCircleColor = Colors.brown;

   // The padding used for the text inside the adv element.
   static final double advElemTextPadding = 4.0;

   static Color favChatButtonColor = Colors.white; 

   // New received advs color.
   static Color newReceivedAdvColor = Colors.brown[200]; 

   static final double outerAdvCardPadding = 2.0;
}

