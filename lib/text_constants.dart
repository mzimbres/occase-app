import 'package:flutter/material.dart';

class TextConsts {
   static final String appName = "CarMenu";

   // Text used for the main tabs.
   static final List<String> tabNames =
         <String>["FILTROS", "ANUNCIOS", "CHATS"];

   // Text used in the *new advertisement screens* on the bottom
   // navigation bar.
   static final List<String> newAdvTab =
         <String>['Localizacao', 'Modelos', 'Enviar'];

   static List<IconData> newAdvTabIcons =
         <IconData>[Icons.home, Icons.directions_car, Icons.send];

   // The text shown on the app bar for each tab on the *new
   // advertisement screen.*
   static final List<String> advAppBarMsg =
      <String>["Escolha uma localizacao", "Escolha um modelo",
               "Verificacao e envio"];

   // The name of the fields at each menu depth.
   static final List<List<String>> menuDepthNames =
   <List<String>>[
      <String>["Pais",   "Estado", "Cidade", "Bairro"],
      <String>["Carros", "Marca",  "Modelo", "Ano", "Combustivel", "Preco Fipe"]
   ];

   // Text used in the adv screen to save the adv for chat.
   static final String advButtonText = "Mover para chats";
   static final String newAdvButtonText = "Enviar";
   static final String chatButtonText = "Chat";

   static final String newAdvDescDeco = "Digitar informacoes adicionais";
}

