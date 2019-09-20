import 'package:flutter/material.dart';
import 'package:occase/constants.dart' as cts;

const String appName = "Occase";

// Text used for the main tabs.
const List<String> tabNames = <String>
[ "POSTS"
, "NOVOS"
, "LIKES"
];

// Text used in the *new post screens* on the bottom navigation bar.
const List<String> newPostTabNames = <String>
[ 'Localizacao'
, 'Modelo'
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
, 'Modelo'
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
, "Escolha um Modelo"
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

const String newPostTextFieldHist = 'Adicione aqui outras informacoes';
const String chatTextFieldHint = "Mensagem";
const String nickHint = "Nome ou nick";
const String emailHint = "Email gravatar (opcional)";

const String msgOnRedirectingChat = 'Redirecionando ...';
const String msgOnRedirectedChat = 'Redirecionada';
const String msgOnEmptyChat = 'Conversa ainda nao iniciada ...';

const String deleteChat = "Remover conversa";
const String blockUser = "Bloquear usuário";
const String pinChat = "Fixar conversa";

// The texts showed on the dialog in the *Posts* screen
const List<String> dialogTitles = <String>
[ 'Deletar post?'
, 'Mover para chats?'
, 'Conteúdo inapropriado?'
, 'Alteracoes aplicadas'
, 'Remover Post?'
];

const List<String> dialogBodies = <String>
[ 'O post será deletado definitivamente.'
, 'O post será movido para a tela de chats para que vocês possam iniciar uma conversa.'
, 'O post será removido de sua list e um report será criado.'
, 'Novos posts serao encaminhados automaticamente pra você.'
, 'Seu post será removido definitivamente.'
];

const String unknownNick = 'Desconhecido';
const String selectAll = 'Selecionar todos';
const String changeNichHint = 'Alterar apelido';
const String changePhoto = 'Alterar foto';
const String dissmissedPost = 'Post removido';
const String dismissedChat = 'Chat removido';
const String ok = 'Ok';
const String cancel = 'Cancel';
const String cancelNewPost = 'Operacao cancelada';
const String doNotShowAgain = 'Nao mostrar novamente';
const String next = 'Continuar';

const List<String> rangePrefixes = <String>
[ 'Preco'
, 'Ano'
, 'Kilometragem'
];

// The units a prefixed and suffixed to the values.
const List<String> rangeUnits = <String>
[ 'R\$',   ''
,    '',   ''
,    '', 'km'
];

// When displaying e.g. price ranges this word will be used to
// separate the values.
// Ex: *Precos: 22.000 até 33.000*
const String rangeSep = 'até';

// The String shown in the title to price, year, km etc.
const String rangesTitle = 'Dados';

const String paymentTitle = 'Escolha um plano';

// Depending on the length of the text, change the function ListTile.
// dense: true,
// isThreeLine: false,
const List<List<String>> payments =
[ <String>
  [ ' 0R\$'
  , 'Grátis'
  , 'Nossa opcao mais econômica.'
  ]
, <String>
  [ ' 5R\$'
  , 'Prioritário'
  , 'Pra quem precisa de agilidade.'
  ]
, <String>
  [ '10R\$'
  , 'Prioridade máxima'
  , 'O maior alcance para seu anúncio.'
  ]
];

const List<String> newPostErrorTitles = <String>
[ 'Error'
, 'Post enviado.'
];

const List<String> newPostErrorBodies = <String>
[ 'Falha na publicacao. Certifique-se que está conectado a internet e tente novamente.'
, 'Seu post poderá ser encontrado agora na tela \"Chats\" na aba \"Menus posts\" após a confirmacao.'
];

const String onEmptyNickTitle = 'Erro';
const String onEmptyNickContent =
   'Seu apelido deve conter um mínimo de ${cts.nickMinLength} letras.';

const String addImgMsg = 'Adicione imagens do seu produto.';

const String unreachableImgError = 'Imagem indisponível.';

