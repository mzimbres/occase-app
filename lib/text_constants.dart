import 'package:flutter/material.dart';

class TextConsts {
   static final String appName = "CarMenu";

   // Text used for the main tabs.
   static final List<String> tabNames =
         <String>["FILTROS", "ANUNCIOS", "CONVERSAS"];

   //______________

   // Text used in the *new advertisement screens* on the bottom
   // navigation bar.
   static final List<String> newAdvTab =
         <String>['Localizacao', 'Modelos', 'Salvar/Enviar'];

   static List<IconData> newAdvTabIcons =
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
      <String>["Pais",   "Estado", "Cidade", "Bairro"],
      <String>["Carros", "Marca",  "Tipo", "Modelo", "Ano", "Combustivel", "Preco Fipe"],
      <String>["Dummy", "Descricao"]
   ];

   // Text used in the adv screen to save the adv for chat.
   static final String advButtonText = "Mover para favoritos";
   static final String newAdvButtonText = "Enviar";
   static final String chatButtonText = "Conversar";
   static final String ownAdvButtonText = "Ver interessados";

   static final String newAdvDescDeco = "Digite aqui informacoes adicionais";

   static final IconData newAdvIcon = Icons.mode_edit;

   static final String hintTextChat = "Digite sua mensagem";
}

