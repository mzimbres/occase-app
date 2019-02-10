import 'package:flutter/material.dart';

final Color primaryColor = Colors.deepOrange[900];
final Color accentColor = Colors.deepOrange[50];
final Color newReceivedAdvColor = Colors.brown[200]; 

final String appName = "CarMenu";

// Text used for the main tabs.
final List<String> tabNames =
   <String>["FILTROS", "POSTS", "CHATS"];

//______________

// Text used in the *new advertisement screens* on the bottom
// navigation bar.
final List<String> newAdvTabNames =
      <String>['Localizacao', 'Modelos', 'Publicar'];

List<IconData> newAdvTabIcons =
      <IconData>[Icons.home, Icons.directions_car, Icons.publish];

final List<String> filterTabNames =
      <String>['Localizacao', 'Modelos', 'Salvar'];

List<IconData> filterTabIcons =
      <IconData>[Icons.home, Icons.directions_car, Icons.send];
//______________

// Text used in the chat screen.
final List<String> chatIconTexts =
      <String>['Meus anúncios', 'Favoritos'];

List<IconData> chatIcons =
      <IconData>[ Icons.list,
                  Icons.star];

//______________

// The text shown on the app bar for each tab on the *new
// advertisement screen.*
final List<String> advAppBarMsg =
   <String>["Escolha uma localizacao", "Escolha um modelo",
            "Verificacao e envio"];

// The name of the fields at each menu depth.
final List<List<String>> menuDepthNames =
<List<String>>[
   <String>["Estado", "Cidade", "Bairro"],
   <String>["Marca",  "Tipo", "Modelo", "Ano", "Combustivel", "Preco Fipe"],
];

// The text in the adv description field.
final List<String> descList =
      <String>['Anunciante', 'Data', "Descricao"];

final String newAdvDescDeco = "Digite aqui informacoes adicionais";

final IconData newAdvIcon = Icons.publish;

final String hintTextChat = "Digite sua mensagem";

// The padding used for the text inside the adv element.
final double advElemTextPadding = 4.0;

final double outerAdvCardPadding = 1.0;

final String deleteChatStr = "Remover conversa";

final TextStyle firstLetterStl =
      TextStyle(color: Colors.white);

final TextStyle menuTitleStl =
          TextStyle(fontSize: 17.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.black);

final TextStyle valueTextStl =
          TextStyle(fontSize: 17.0,
                    fontWeight: FontWeight.normal,
                    color: Colors.black);

