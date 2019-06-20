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
final Color chatLongPressendColor = Colors.grey[400]; 

final double mainFontSize = 15.0;
final Color postLocHeaderColor = Color(0xFFFFFFFF);
final Color selectedMenuColor = Colors.blueGrey[400];
final Color postFrameColor = Colors.blueGrey[400];

// Margin used so that the post card boarder has some distance from
// the screen border or whatever widget it happens to be inside of.
final double postMarging = 7.0;

// Marging user to separate the post element cards from the
// outermost cards.
final double postInnerMargin = 3.0;

final String appName = "CarMenu";

// Text used for the main tabs.
final List<String> tabNames = <String>
[ "POSTS"
, "NOVOS"
, "LIKES"
];

//______________

// Text used in the *new postertisement screens* on the bottom
// navigation bar.
final List<String> newPostTabNames = <String>
[ 'Localizacao'
, 'Modelos'
, 'Detalhes'
, 'Publicar'
];

List<IconData> newPostTabIcons = <IconData>
[ Icons.home
, Icons.directions_car
, Icons.details
, Icons.publish
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

final List<String> filterTabNames = <String>
[ 'Localizacao'
, 'Modelos'
, 'Detalhes'
, 'Aplicar'
];

List<IconData> filterTabIcons = <IconData>
[ Icons.home
, Icons.directions_car
, Icons.filter_list
, Icons.send
];

//______________

// Text used in the chat screen.
final List<String> chatIconTexts = <String>
[ 'Meus posts'
, 'Favoritos'
];

List<IconData> chatIcons = <IconData>
[ Icons.list
, Icons.star
];

final Icon favIcon = Icon(Icons.star, color: Colors.amber);

//______________

// The text shown on the app bar for each tab on the *new
// postertisement screen.*
final List<String> postAppBarMsg = <String>
[ "Escolha uma localizacao"
, "Escolha um modelo"
, "Adicione detalhes"
, "Verificacao e envio"
];

// The name of the fields at each menu depth.
final List<List<String>> menuDepthNames = <List<String>>
[
   <String>["Estado", "Cidade", "Bairro"],
   <String>["Marca",  "Tipo", "Modelo", "Ano", "Combustivel", "Preco Fipe"],
];

// The text in the post description field.
final List<String> descList = <String>
[ 'Anunciante'
, 'Id do anunc.'
, 'Id do post'
, 'Data'
, "Descricao"
];

// WARNING: These strings must have size at least two. I won't check
// that in code.
final List<String> postDetails = <String>
[ 'Airbag'
, 'Alarme'
, 'Ar quente'
, 'Ar condicionado'
, 'Banco com regulagem de altura'
, 'Computador de bordo'
, 'Desembacador traseiro'
, 'Encosto de cabeca trazeiro'
, 'Freio ABS'
//, 'Controle automatico de velocidade'
//, 'Rodas de liga leve'
//, 'Sensor de chuva'
//, 'Sensor de estacionamento'
//, 'Teto solar'
//, 'Retrovisor fotocrômico'
//, 'Travas elétricas'
//, 'Vidros elétricos'
//, 'Volante com regulagen de altura'
//, 'Farol de xenônio'
//, 'Direcao hidráulica'
];

final String newPostTextFieldHistStr = "Informacoes adicionais";
final String chatTextFieldHintStr = "Mensagem";
final String nichTextFieldHintStr = "Digite seu nome";

final int nickMaxLength = 10;

final IconData newPostIcon = Icons.add;

final String hintTextChat = "Digite sua mensagem";

// The padding used for the text inside the post element.
final double postElemTextPadding = 7.0;

final double outerPostCardPadding = 1.0;

final String deleteChatStr = "Remover conversa";
final String blockUserChatStr = "Bloquear usuário";

final TextStyle abbrevStl = TextStyle(color: Colors.white);

final TextStyle menuTitleStl =
   TextStyle(fontSize: 15.0,
             fontWeight: FontWeight.bold,
             color: Colors.black);

final TextStyle postTitleStl =
   TextStyle(fontSize: 15.0,
             fontWeight: FontWeight.bold,
             color: Colors.grey[800]);


final TextStyle valueTextStl =
          TextStyle(fontSize: 15.0,
                    fontWeight: FontWeight.normal,
                    color: Colors.black);

final TextStyle postValueTextStl =
          TextStyle(fontSize: 15.0,
                    fontWeight: FontWeight.normal,
                    color: Colors.grey[800]);

final TextStyle expTileStl =
          TextStyle(fontSize: 15.0,
                    fontWeight: FontWeight.normal,
                    color: Colors.white);

final String menuFileName = 'menu.txt';
final String loginFileName = 'login.txt';
final String lastPostIdFileName = 'last_post_id.txt';
final String postsFileName = 'posts.txt';
final String favPostsFileName = 'favorite_posts.txt';
final String outPostsFileName = 'out_posts_queue.txt';
final String outChatMsgsFileName = 'out_chat_msgs_queue.txt';
final String chatFilePrefix = 'chat';
final String dialogPrefsFullPath = 'dialog_prefs.txt';
final String nickFullPath = 'nick.txt';

// The texts showed on the dialog in the *Posts* screen
final List<String> dialTitleStrs = <String>
[ 'Deletar post?'
, 'Mover para chats?'
, 'Alteracoes aplicadas'
, 'Post enviado.'
, 'Remover Post?'
];

final List<String> dialBodyStrs = <String>
[ 'O post será deletado definitivamente.'
, 'O post será movido para a tela de chats para que vocês possam iniciar uma conversa.'
, 'Novos posts serao encaminhados automaticamente pra você.'
, 'Seu post pode ser encontrado agora na tela \"Chats\" na aba \"Menus posts\".'
, 'Seu post será removido definitivamente.'
];

final String postTimePrefix = 'Detalhes do post';
final String unknownNick = 'Desconhecido';

final String menuSelectAllStr = 'Selecionar todos';

// WARNING: localhost or 127.0.0.1 is the emulator or the phone
// address. If the phone is connected (via USB) to a computer
// the computer can be found on 10.0.2.2.
//final String host = 'ws://10.0.2.2:80';

// My public ip.
final String host = 'ws://37.24.165.216:80';

final Icon unknownPersonIcon =
   Icon(Icons.person, color: Colors.white, size: 30.0);

