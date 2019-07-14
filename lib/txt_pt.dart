import 'package:flutter/material.dart';

final String appName = "CarMenu";

// Text used for the main tabs.
final List<String> tabNames = <String>
[ "POSTS"
, "NOVOS"
, "LIKES"
];

//______________

// Text used in the *new post screens* on the bottom navigation bar.
final List<String> newPostTabNames = <String>
[ 'Localizacao'
, 'Produto'
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

final String delOwnChatTitleStr = 'Remover conversas?';
final String delFavChatTitleStr = 'Remover de Favoritos?';
final String devChatOkStr = 'Remover';
final String delChatCancelStr = 'Cancelar';
final String userInfo = 'Informacoes do usuário';

//______________

final String newPostAppBarTitle = 'Publicar novo post';
final String filterAppBarTitle = 'Escolha seus filtros';

final List<String> filterTabNames = <String>
[ 'Localizacao'
, 'Modelos'
, 'Adicionais'
, 'Enviar'
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
, "Escolha um produto"
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
//, 'Encosto de cabeca trazeiro'
//, 'Freio ABS'
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
final String nickTextFieldHintStr = "Digite seu nome";

final int nickMaxLength = 10;

final IconData newPostIcon = Icons.add;

final String hintTextChat = "Digite sua mensagem";
final String chatMsgRedirectText = 'Redirecionando ...';
final String chatMsgRedirectedText = 'Redirecionada';
final String defaultChatTileSubtile = 'Conversa ainda nao iniciada ...';

final String deleteChatStr = "Remover conversa";
final String blockUserChatStr = "Bloquear usuário";
final String pinChatStr = "Fixar conversa";

final String chatFilePrefix = 'chat';

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

final String unknownNick = 'Desconhecido';

final String menuSelectAllStr = 'Selecionar todos';

final Icon unknownPersonIcon =
   Icon(Icons.person, color: Colors.white, size: 30.0);

