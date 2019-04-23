import 'package:flutter/material.dart';

final Color whatsAppPrimaryColor = Color(0xff075E54);
final Color whatsAppAccentColor = Color(0xff25D366);

final Color coral = Color(0xFFE18A07);
final Color darkYellow = Color(0xFF999900);
final Color fireBrick = Color(0xFFB22222);
final Color seaGreen = Color(0xFF2E8B57);
final Color oliveDrab = Color(0xFF6B8E23);
//final Color primaryColor = Colors.blueGrey;
final Color primaryColor = whatsAppPrimaryColor;
//final Color accentColor = Colors.grey;
final Color accentColor = whatsAppAccentColor;
final Color newReceivedPostColor = Colors.brown[200]; 

final String appName = "CarMenu";

// Text used for the main tabs.
final List<String> tabNames = <String>[
   "FILTROS",
   "POSTS",
   "CHATS"
];

//______________

// Text used in the *new postertisement screens* on the bottom
// navigation bar.
final List<String> newPostTabNames = <String>[
   'Localizacao',
   'Modelos',
   'Publicar'
];

List<Icon> newPostTabIcons = <Icon>[
   Icon(Icons.home),
   Icon(Icons.directions_car),
   Icon(Icons.publish)
];

//______________

final Text delOwnChatTitleText =
   Text("Remover conversas?", style: TextStyle(color: Colors.black));

final Text delFavChatTitleText =
   Text("Remover de Favoritos?", style: TextStyle(color: Colors.black));

final Text deleteChatOkText =
   Text("Remover", style: TextStyle(color: coral));

final Text deleteChatCancelText =
   Text("Cancelar", style: TextStyle(color: coral));

//______________

final List<String> filterTabNames = <String>[
   'Localizacao',
   'Modelos',
   'Salvar'
];

List<Icon> filterTabIcons = <Icon>[
   Icon(Icons.home),
   Icon(Icons.directions_car),
   Icon(Icons.send)
];

//______________

// Text used in the chat screen.
final List<String> chatIconTexts = <String>[
   'Meus anúncios',
   'Favoritos'
];

List<Icon> chatIcons = <Icon>[
   Icon(Icons.list),
   Icon(Icons.star)
];

final Icon favIcon = Icon(Icons.star, color: Colors.amber);
final Icon personIcon = Icon(Icons.person);

//______________

// The text shown on the app bar for each tab on the *new
// postertisement screen.*
final List<String> postAppBarMsg = <String>[
   "Escolha uma localizacao",
   "Escolha um modelo",
   "Verificacao e envio"
];

// The name of the fields at each menu depth.
final List<List<String>> menuDepthNames = <List<String>>[
   <String>["Estado", "Cidade", "Bairro"],
   <String>["Marca",  "Tipo", "Modelo", "Ano", "Combustivel", "Preco Fipe"],
];

// The text in the post description field.
final List<String> descList = <String>[
   'Anunciante',
   'Data',
   "Descricao"];

final String newPostDescDeco = "Digite aqui informacoes adicionais";

final IconData newPostIcon = Icons.publish;

final String hintTextChat = "Digite sua mensagem";

// The padding used for the text inside the post element.
final double postElemTextPadding = 4.0;

final double outerPostCardPadding = 1.0;

final String deleteChatStr = "Remover conversa";

final TextStyle firstLetterStl =
      TextStyle(color: Colors.white);

final TextStyle menuTitleStl =
          TextStyle(fontSize: 15.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.black);

final TextStyle valueTextStl =
          TextStyle(fontSize: 15.0,
                    fontWeight: FontWeight.normal,
                    color: Colors.black);

final TextStyle expTileStl =
          TextStyle(fontSize: 15.0,
                    fontWeight: FontWeight.normal,
                    color: Colors.white);

final String menuFileName = 'menu.txt';
final String loginFileName = 'login.txt';
final String lastPostIdFileName = 'last_post_id.txt';

