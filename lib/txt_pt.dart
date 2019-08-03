import 'package:flutter/material.dart';

const String appName = "CarMenu";

// Text used for the main tabs.
const List<String> tabNames = <String>
[ "POSTS"
, "NOVOS"
, "LIKES"
];

//______________

// Text used in the *new post screens* on the bottom navigation bar.
const List<String> newPostTabNames = <String>
[ 'Localizacao'
, 'Veículo'
, 'Detalhes'
, 'Publicar'
];

const List<IconData> newPostTabIcons = <IconData>
[ Icons.home
, Icons.directions_car
, Icons.details
, Icons.publish
];

//______________

const String delOwnChatTitleStr = 'Remover conversas?';
const String delFavChatTitleStr = 'Remover de Favoritos?';
const String devChatOkStr = 'Remover';
const String delChatCancelStr = 'Cancelar';
const String userInfo = 'Informacoes do usuário';

//______________

const String newPostAppBarTitle = 'Publicar novo post';
const String filterAppBarTitle = 'Escolha seus filtros';

const List<String> filterTabNames = <String>
[ 'Localizacao'
, 'Veículo'
, 'Condicoes'
, 'Enviar'
];

const List<IconData> filterTabIcons = <IconData>
[ Icons.home
, Icons.directions_car
, Icons.filter_list
, Icons.send
];

//______________

// Text used in the chat screen.
const List<String> chatIconTexts = <String>
[ 'Meus posts'
, 'Favoritos'
];

const List<IconData> chatIcons = <IconData>
[ Icons.list
, Icons.star
];

const Icon favIcon = Icon(Icons.star, color: Colors.amber);

//______________

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

// This constant should be set to the maximum number of exclusing
// details among all pruducts. At the moment this is 6 for cars and I
// see no reason for it being much more than that. This value will
// be used to initialize the corresponding array in the Post class. At
// the moment of post creation we do not know which product it will
// carry and therefore we also do not know the size we need. For
// backward compatibility it may be a good idea to make room for
// further expansion.
const int maxExDetailSize = 10;

const String postRefSectionTitle = 'Referências do post';

// NOTE: The strings in the array must have size at least two. I
// won't check that in code.

// Consider inserting dummy entries in the array for future expansion.

// This is the title that will be used to present the exclusive
// details in the post
const String postExDetailsTitle = 'Detalhes Adicionais';
const String postDescTitle = 'Mensagem do usuário';

// Exclusive options. The size of this array has to match the number
// of elements in the second menu item.
const List<List<String>> exDetailTitles = <List<String>>
[ <String> // Carros
  [ 'Condicao'
  , 'Combustível'
  , 'Câmbio'
  , 'Portas'
  , 'Cor'
  , 'Anunciante'
  ]
, <String> // Motos
  [ 'Condicao'
  , 'Alimentacao'
  , 'Refrigeracao'
  , 'Motor'
  , 'Freio'
  , 'Cor'
  , 'Quantidade de marchas'
  ]
, <String> // Caminhoes.
  [ 'Condicao'
  , 'Tracao'
  , 'Carroceria'
  , 'Transmissao'
  , 'Cor'
  ]
];

// The size of this array has to match the size of exDetailTitles.
// The size of each item in this array has to match the size of
// exDetailTitles.
const List<List<List<String>>> exDetails = <List<List<String>>>
[ <List<String>> // Carros
  [ <String> // Must be equal for all products. Its a filter.
    [ 'Novo'
    , 'Usado'
    , 'Troca'
    , 'Repasse'
    ] 
  , <String>
    [ 'Nao informado'
    , 'Gasolina'
    , 'Alcool'
    , 'Diesel'
    , 'Gás natural'
    , 'Gazolina e álcool'
    , 'Gazolina e gás natural'
    , 'Álcool e gás natural'
    , 'Gazolina álcool e gás natural'
    , 'Gazolina álcool, gás natural e benzina'
    , 'Gazolina e elétrico'
    ]
  , <String>
    [ 'Nao informado'
    , 'Automático'
    , 'Automatizado'
    , 'Automatizado DCT'
    , 'Automático sequêncial'
    , 'Cvt'
    , 'Manual'
    , 'Semi automático'
    ]
  , <String>
    [ 'Nao informado'
    , '0 porta'
    , '2 Portas'
    , '3 Portas'
    , '4 Portas'
    ]
  , <String>
    [ 'Nao informado'
    , 'Amarelo'
    , 'Azul'
    , 'Bege'
    , 'Branco'
    , 'Bronze'
    , 'Cinza'
    , 'Dourado'
    , 'Laranja'
    , 'Marrom'
    , 'Prata'
    , 'Preto'
    , 'Rosa'
    , 'Roxo'
    , 'Verde'
    , 'Vermelho'
    , 'Vinho'
    ]
  , <String>
    [ 'Nao informado'
    , 'Concessionária'
    , 'Loja'
    , 'Pessoa física'
    ]
  ]
, <List<String>> // Motos
  [ <String>
    [ 'Nova'
    , 'Usada'
    , 'Troca'
    , 'Repasse'
    ] 
  , <String>
    [ 'Carburador'
    , 'Injecao eletrônica'
    ]
  , <String>
    [ 'Ar'
    , 'Líquida'
    ]
  , <String>
    [ '2 tempos'
    , '4 tempos'
    , 'Elétrico de corrent contínua'
    ]
  , <String>
    [ 'Disco/disco'
    , 'Disco/tambor'
    , 'Tambor/disco'
    , 'Tambor/tambor'
    ]
  , <String>
    [ 'Nao informado'
    , 'Amarelo'
    , 'Azul'
    , 'Bege'
    , 'Branco'
    , 'Bronze'
    , 'Cinza'
    , 'Dourado'
    , 'Laranja'
    , 'Marrom'
    , 'Prata'
    , 'Preto'
    , 'Rosa'
    , 'Roxo'
    , 'Verde'
    , 'Vermelho'
    , 'Vinho'
    ]
  , <String>
    [ 'Automático'
    , '2'
    , '3'
    , '4'
    , '5'
    , '6'
    , '7'
    , '8'
    ]
  ]
, <List<String>> // Caminhoes.
  [ <String>
    [ 'Novo'
    , 'Usado'
    , 'Troca'
    , 'Repasse'
    ] 
  , <String>
    [ 'Bitruck 8 x 2'
    , 'Bitruck 8 x 4'
    , 'Toco 4 x 2'
    , 'Toco 4 x 4'
    , 'Truck 6 x 2'
    , 'Truck 6 x 4'
    ]
  , <String>
    [ 'Baú bebidas'
    , 'Baú frigorífico'
    , 'Baú furgao'
    , 'Baú sider'
    , 'Baú Térmico'
    , 'Betoneira'
    , 'Boiadeiro'
    , 'Bomba de concreto'
    , 'Cacamba basculante'
    , 'Cacamba cabine'
    , 'Carga seca'
    , 'Carroceria cabine'
    ]
  , <String>
    [ 'Manual'
    , 'Automática'
    , 'Semi automática'
    , 'Sequencial'
    ]
  , <String>
    [ 'Nao informado'
    , 'Amarelo'
    , 'Azul'
    , 'Bege'
    , 'Branco'
    , 'Bronze'
    , 'Cinza'
    , 'Dourado'
    , 'Laranja'
    , 'Marrom'
    , 'Prata'
    , 'Preto'
    , 'Rosa'
    , 'Roxo'
    , 'Verde'
    , 'Vermelho'
    , 'Vinho'
    ]
  ]
];

// See the comment in maxExDetailSize
const int maxInDetailSize = 5;

// Inclusive options.
const List<List<String>> inDetailTitles = <List<String>>
[ <String>
  [ 'Opcionais'
  , 'Condicoes'
  ]
, <String> 
  [ 'Opcionais'
  , 'Características'
  , 'Partida'
  ]
, <String>
  [ 'Opcionais'
  , 'Suplementar'
  ]
];

const List<List<List<String>>> inDetails = <List<List<String>>>
[ <List<String>>
  [ <String>
    [ 'Airbag'
    , 'Alarme'
    , 'Ar quente'
    , 'Ar condicionado'
    , 'CD Player'
    , 'Direcao hidraulica'
    , 'Freio ABS'
    , 'Player'
    , 'CD Player'
    , 'Banco com regulagem de altura'
    , 'Computador de bordo'
    , 'Desembacador traseiro'
    , 'Encosto de cabeca trazeiro'
    , 'Freio ABS'
    , 'Controle automatico de velocidade'
    , 'Rodas de liga leve'
    , 'Sensor de chuva'
    , 'Sensor de estacionamento'
    , 'Teto solar'
    , 'Retrovisor fotocrômico'
    , 'Travas elétricas'
    , 'Vidros elétricos'
    , 'Volante com regulagen de altura'
    , 'Farol de xenônio'
    , 'Direcao hidráulica'
    ]
  , <String>
    [ 'Único dono'
    , 'IPVA pago'
    , 'Nao aceito troca'
    , 'Veículo financiado'
    , 'Licenciado'
    , 'Garantia de fábrica'
    , 'Veículo de colecionador'
    , 'Todas as revis~oes em concessionária'
    , 'Adaptada para pessoas com deficiência'
    , 'Blindado'
    ]
  ]
, <List<String>>
  [ <String>
    [ 'ABS'
    , 'Amortecedor de direcao'
    , 'Bolsa/Baú/Bauleto'
    , 'Computador de bordo'
    , 'Contrapeso no guidon'
    , 'Alarme'
    , 'Escapamento esportivo'
    , 'Faróis de neblina'
    , 'GPS'
    , 'Som'
    ]
  , <String>
    [ 'Automático'
    , 'Único dono'
    , 'IPVA pago'
    , 'Nao aceita troca'
    , 'Licenciado'
    , 'Garantia de fábrica'
    , 'Todas as revisoes em concessionária'
    , 'Blindado'
    ]
  , <String>
    [ 'Pedal'
    , 'Elétrica'
    ]
  ]
, <List<String>>
  [ <String>
    [ 'ABS'
    , 'Ar condicionado'
    , 'Alarme'
    , 'Travas elétricas de portas'
    , 'Vidros elétricos'
    ]
  , <String>
    [ 'Cavalo mecânico'
    , 'Cegonha'
    , 'Chassis'
    , 'Coletor de lixo'
    , 'Comboio'
    , 'Espargidor'
    , 'Gaiola de gás'
    , 'Graneleiro'
    , 'Guíncho Munck'
    , 'Plataforma guincho'
    , 'Poli guindaste'
    , 'Roll on/off'
    , 'Silo'
    , 'Tanque aco'
    , 'Tanque inox'
    , 'Tanque isotérmico'
    , 'Tanque pipa'
    , 'Tora florestal'
    , 'Transbordo canaveiro'
    , 'Trio elétrico'
    ]
  ]
];

const String newPostTextFieldHistStr = 'Adicione aqui outras informacoes';
const String chatTextFieldHintStr = "Mensagem";
const String nickTextFieldHintStr = "Digite seu nome";

const int nickMaxLength = 10;

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

const Icon unknownPersonIcon = Icon(
   Icons.person,
   color: Colors.white, size: 30.0
);

const String changeNickStr = 'Alterar apelido';
const String changePhoto = 'Alterar foto';

