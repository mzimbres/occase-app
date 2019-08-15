import 'package:flutter/material.dart';

const String appName = "CarMenu";

// Text used for the main tabs.
const List<String> tabNames = <String>
[ "POSTS"
, "NOVOS"
, "LIKES"
];

// Text used in the *new post screens* on the bottom navigation bar.
const List<String> newPostTabNames = <String>
[ 'Localizacao'
, 'Veículo'
, 'Detalhes'
, 'Publicar'
];

const String delOwnChatTitleStr = 'Remover conversas?';
const String delFavChatTitleStr = 'Remover de Favoritos?';
const String devChatOkStr = 'Remover';
const String delChatCancelStr = 'Cancelar';
const String userInfo = 'Usuário';
const String newPostAppBarTitle = 'Publicar novo post';
const String filterAppBarTitle = 'Escolha seus filtros';

const List<String> filterTabNames = <String>
[ 'Localizacao'
, 'Veículo'
, 'Condicoes'
, 'Enviar'
];

// Text used in the chat screen.
const List<String> chatIconTexts = <String>
[ 'Meus posts'
, 'Favoritos'
];

// The text shown on the app bar for each tab on the *new
// post screen.*
const List<String> postAppBarMsg = <String>
[ "Escolha uma localizacao"
, "Escolha um veículo"
, "Adicione detalhes"
, "Verificacao e envio"
];

// The name of the fields at each menu depth.
const List<List<String>> menuDepthNames = <List<String>>
[
   <String>['Regiao', 'Estado', 'Cidade', 'Bairro'],
   <String>['Veículo', 'Marca',  'Tipo', 'Modelo'],
];

// The text in the post description field.
const List<String> descList = <String>
[ 'Anunciante'
, 'Id do anunc.'
, 'Id do post'
, 'Data'
, "Descricao"
];

const String postRefSectionTitle = 'Referências do post';

// NOTE: The strings in the array must have size at least two. I
// won't check that in code.

// Consider inserting dummy entries in the array for future expansion.

// This is the title that will be used to present the exclusive
// details in the post
const String postExDetailsTitle = 'Detalhes Adicionais';
const String postDescTitle = 'Mensagem do usuário';

const String newPostTextFieldHistStr = 'Adicione aqui outras informacoes';
const String chatTextFieldHintStr = "Mensagem";
const String nickTextFieldHintStr = "Digite seu nome";

const IconData newPostIcon = Icons.add;

const String hintTextChat = "Digite sua mensagem";
const String chatMsgRedirectText = 'Redirecionando ...';
const String chatMsgRedirectedText = 'Redirecionada';
const String defaultChatTileSubtile = 'Conversa ainda nao iniciada ...';

const String deleteChatStr = "Remover conversa";
const String blockUserChatStr = "Bloquear usuário";
const String pinChatStr = "Fixar conversa";

const String chatFilePrefix = 'chat';

// The texts showed on the dialog in the *Posts* screen
const List<String> dialTitleStrs = <String>
[ 'Deletar post?'
, 'Mover para chats?'
, 'Alteracoes aplicadas'
, 'Post enviado.'
, 'Remover Post?'
];

const List<String> dialBodyStrs = <String>
[ 'O post será deletado definitivamente.'
, 'O post será movido para a tela de chats para que vocês possam iniciar uma conversa.'
, 'Novos posts serao encaminhados automaticamente pra você.'
, 'Seu post pode ser encontrado agora na tela \"Chats\" na aba \"Menus posts\".'
, 'Seu post será removido definitivamente.'
];

const String unknownNick = 'Desconhecido';
const String menuSelectAllStr = 'Selecionar todos';
const String changeNickStr = 'Alterar apelido';
const String changePhoto = 'Alterar foto';
const String dismissedPostStr = 'Post removido';
const String cancelNewPostStr = 'Operacao cancelada';
const String pricePrefix = 'Preco';
const String dismissedChatStr = 'Chat removido';

