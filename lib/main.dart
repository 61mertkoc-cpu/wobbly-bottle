import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'multiplayer/models/room_models.dart';
import 'multiplayer/services/room_service.dart';
import 'multiplayer/screens/room_join_screen.dart';
import 'multiplayer/screens/room_lobby_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  try {
    await MobileAds.instance.initialize();
  } catch (_) {}
  runApp(const WobblyBottleApp());
}

class WobblyBottleApp extends StatelessWidget {
  const WobblyBottleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wobbly Bottle',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF020611),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00F2FE),
          secondary: Color(0xFFFF0844),
          surface: Color(0xFF051725),
        ),
      ),
      home: const MainGameScreen(),
    );
  }
}

class Player {
  final String name;
  final Color color;
  final String emoji;
  Player({required this.name, required this.color, this.emoji = '🥳'});
}

class WobblyBottleAppGame {
  static const List<String> partyEmojis = [
    '🥳', '😎', '😈', '💋', '🍻', '🤪', '🔥', '👑',
    '💀', '🤡', '🤠', '🦄', '👻', '👽', '🦊', '🐱',
    '🐶', '🦁', '🐼', '🐸', '🐵', '💃', '🕺', '🚀',
    '⚡', '💎', '🍕', '🍾',
  ];

  static const List<Color> playerColors = [
    Color(0xFF00F2FE), // 1. Cyan
    Color(0xFFFF0844), // 2. Pink/Red
    Color(0xFFFF9500), // 3. Orange
    Color(0xFFAF52DE), // 4. Purple
    Color(0xFFFFCC00), // 5. Yellow
    Color(0xFF34C759), // 6. Green
    Color(0xFF3B82F6), // 7. Electric Blue
    Color(0xFFFF2E93), // 8. Hot Magenta
    Color(0xFFA8FF00), // 9. Neon Lime
    Color(0xFFFF6B4A), // 10. Neon Coral
  ];

  static const List<List<String>> langFlags = [
    ["🇬🇧", "EN", "English"],
    ["🇹🇷", "TR", "Türkçe"],
    ["🇩🇪", "DE", "Deutsch"],
    ["🇪🇸", "ES", "Español"],
    ["🇫🇷", "FR", "Français"],
    ["🇷🇺", "RU", "Русский"],
  ];

  static String getObjectName(int index, int langIdx) {
    switch (index) {
      case 0:
        return getLoc(langIdx, "Funny Soda Bottle", "Komik Gazoz Şişesi", "Lustige Limo-Flasche", "Botella de Refresco Divertida", "Bouteille de Soda Drôle", "Весёлая Бутылка Газировки");
      case 1:
        return getLoc(langIdx, "Squeaky Chicken", "Bipleyen Tavuk", "Quietsche-Huhn", "Pollo Chillón", "Poulet Qui Couine", "Пищащая Курица");
      case 2:
        return getLoc(langIdx, "Wobbly Pickle", "Sallanan Turşu", "Wackel-Gurke", "Pepinillo Tambaleante", "Cornichon Vacillant", "Качающийся Огурчик");
      case 3:
        return getLoc(langIdx, "Flying Slipper", "Uçan Terlik", "Fliegender Hausschuh", "Zapatilla Voladora", "Pantoufle Volante", "Летающий Тапок");
      case 4:
        return getLoc(langIdx, "Golden Champagne", "Altın Şampanya", "Goldener Champagner", "Champán Dorado", "Champagne Doré", "Золотое Шампанское");
      default:
        return "";
    }
  }

  static String getPackName(int index, int langIdx) {
    switch (index) {
      case 0:
        return getLoc(langIdx, "PARTY AND FUN", "PARTİ VE EĞLENCE", "PARTY UND SPASS", "FIESTA Y DIVERSIÓN", "SOIRÉE ET FUN", "ВЕЧЕРИНКА И ВЕСЕЛЬЕ");
      case 1:
        return getLoc(langIdx, "DEEP CONFESSIONS", "DERİN İTİRAFLAR", "TIEFE GESTÄNDNISSE", "CONFESIONES PROFUNDAS", "CONFESSIONS PROFONDES", "ГЛУБОКИЕ ПРИЗНАНИЯ");
      case 2:
        return getLoc(langIdx, "BOLD CHALLENGES / DARES", "CESUR GÖREVLER / MEYDAN OKUMA", "MUTIGE HERAUSFORDERUNGEN", "DESAFÍOS ATREVIDOS", "DÉFIS AUDACIEUX", "СМЕЛЫЕ ЗАДАНИЯ / ВЫЗОВ");
      case 3:
        return getLoc(langIdx, "FLIRT AND COUPLES", "FLÖRT VE ÇİFTLER", "FLIRT UND PÄRCHEN", "COQUETEO Y PAREJAS", "FLIRT ET COUPLES", "ФЛИРТ И ПАРЫ");
      case 4:
        return getLoc(langIdx, "+18 SPICY", "+18 BAHARATLI", "+18 SCHARF", "+18 PICANTE", "+18 ÉPICÉ", "+18 ПИКАНТНО");
      case 5:
        return getLoc(langIdx, "FREE MODE / ASK OURSELVES", "SERBEST MOD / KENDİMİZ SORALIM", "FREIER MODUS", "MODO LIBRE", "MODE LIBRE", "СВОБОДНЫЙ РЕЖИМ");
      default:
        return "";
    }
  }

  static const Map<String, String> _frUiMap = {
    "SPONSORED VIDEO": "VIDÉO SPONSORISÉE",
    "Remove all ads & unlock Golden Champagne + 18+ Spicy Pack with VIP!": "Supprimez les pubs et débloquez le Champagne Doré + Pack +18 avec VIP !",
    "👑 Wobbly VIP Activated! All features unlocked!": "👑 Wobbly VIP Activé ! Tout est débloqué !",
    "Purchase failed or canceled.": "Achat échoué ou annulé.",
    "Connecting to App Store... Please try again in a moment.": "Connexion à la boutique... Réessayez dans un instant.",
    "Premium Party Upgrade": "Mise à Niveau Soirée Premium",
    "Golden Champagne Bottle": "Bouteille de Champagne Doré",
    "🔥 +18 Spicy Secret Pack": "🔥 Pack Secret +18 Épicé",
    "Instant In-Game Switching": "Changement Instantané en Jeu",
    "ACTIVATE VIP": "ACTIVER VIP",
    "Restore Purchase": "Restaurer les achats",
    "Cancel": "Annuler",
    "Maximum 10 players!": "Maximum 10 joueurs !",
    "Player": "Joueur",
    "EDIT PLAYER": "MODIFIER LE JOUEUR",
    "Enter player name...": "Entrez le nom du joueur...",
    "CANCEL": "ANNULER",
    "SAVE": "ENREGISTRER",
    "FREE QUESTION": "QUESTION LIBRE",
    "What is the most memorable party moment in your life?": "Quel est le moment de fête le plus mémorable de ta vie ?",
    "Do your best 10-second funny dance right now!": "Fais ta danse la plus drôle pendant 10 secondes maintenant !",
    "DONE / NEXT ROUND": "TERMINÉ / TOUR SUIVANT",
    "ADD PLAYERS (MIN 2 - MAX 10)": "AJOUTER JOUEURS (2 - 10)",
    "Enter name or tap + to quick add...": "Entrez un nom ou appuyez sur +...",
    "PICK COLOR:": "COULEUR :",
    "No players added yet.\nAdd at least 2 players to start!": "Aucun joueur ajouté.\nAjoutez au moins 2 joueurs pour commencer !",
    "CONTINUE TO OBJECTS": "CONTINUER AUX OBJETS",
    "PLAYERS": "JOUEURS",
    "CHOOSE YOUR OBJECT": "CHOISIS TON OBJET",
    "SELECTED": "SÉLECTIONNÉ",
    "WATCH AD": "VOIR PUB",
    "UNLOCKED": "DÉBLOQUÉ",
    "Unlock as VIP": "Débloquer en VIP",
    "Unlock with 1 Video": "Débloquer avec 1 Vidéo",
    "CONTINUE TO PACKS": "CONTINUER AUX PACKS",
    "CHOOSE YOUR PACKS": "CHOISIS TES PACKS",
    "START GAME": "LANCER LA PARTIE",
    "⚡ MAKE YOUR CHOICE": "⚡ FAIS TON CHOIX",
    "Truth, Dare, or Ask Yourselves?": "Action, Vérité ou Question Libre ?",
    "TRUTH": "VÉRITÉ",
    "DARE": "ACTION",
    "CUSTOM": "LIBRE",
    "WOBBLING...": "ÇA TOURNE...",
    "SPIN BOTTLE!": "TOURNER LA BOUTEILLE !",
    "HOME": "ACCUEIL",
    "PROFILE": "PROFIL",
    "👑 VIP MEMBER": "👑 MEMBRE VIP",
    "👑 GO VIP": "👑 PASSER VIP",
    "All premium content is unlocked": "Tout le contenu premium est débloqué",
    "Unlock Golden Champagne + Spicy pack": "Débloquez Champagne Doré + Pack +18 Épicé",
    "ACTIVE": "ACTIF",
    "VIEW OFFER": "VOIR L'OFFRE",
    "CHANGE OBJECT NOW": "CHANGER D'OBJET",
    "CHOOSE": "CHOISIR",
    "AD": "PUB",
    "ACTIVE PACKS": "PACKS ACTIFS",
    "NO CONNECTION": "PAS DE CONNEXION",
    "Wobbly Bottle requires an active internet connection.": "Wobbly Bottle nécessite une connexion Internet active.",
    "Connect to Wi-Fi or mobile data to continue.": "Connectez-vous au Wi-Fi ou aux données mobiles pour continuer.",
    "WAITING FOR NETWORK...": "EN ATTENTE DU RÉSEAU...",
  };

  static const Map<String, String> _ruUiMap = {
    "SPONSORED VIDEO": "РЕКЛАМНОЕ ВИДЕО",
    "Remove all ads & unlock Golden Champagne + 18+ Spicy Pack with VIP!": "Уберите всю рекламу и откройте Золотое Шампанское + Набор 18+ с VIP!",
    "👑 Wobbly VIP Activated! All features unlocked!": "👑 Wobbly VIP Активирован! Все возможности открыты!",
    "Purchase failed or canceled.": "Покупка не удалась или была отменена.",
    "Connecting to App Store... Please try again in a moment.": "Подключение к магазину... Пожалуйста, повторите попытку через минуту.",
    "Premium Party Upgrade": "Премиум Обновление для Вечеринки",
    "Golden Champagne Bottle": "Бутылка Золотого Шампанского",
    "🔥 +18 Spicy Secret Pack": "🔥 Секретный Пикантный Набор 18+",
    "💋 +18 Spicy Secret Pack": "💋 Секретный Пикантный Набор 18+",
    "Instant In-Game Switching": "Мгновенное переключение в игре",
    "ACTIVATE VIP": "АКТИВИРОВАТЬ VIP",
    "Restore Purchase": "Восстановить покупки",
    "Cancel": "Отмена",
    "Maximum 10 players!": "Максимум 10 игроков!",
    "Player": "Игрок",
    "EDIT PLAYER": "ИЗМЕНИТЬ ИГРОКА",
    "Enter player name...": "Введите имя игрока...",
    "CANCEL": "ОТМЕНА",
    "SAVE": "СОХРАНИТЬ",
    "FREE QUESTION": "СВОБОДНЫЙ ВОПРОС",
    "What is the most memorable party moment in your life?": "Какой самый запоминающийся момент вечеринки в твоей жизни?",
    "Do your best 10-second funny dance right now!": "Исполни свой самый смешной танец на 10 секунд прямо сейчас!",
    "DONE / NEXT ROUND": "ГОТОВО / СЛЕДУЮЩИЙ РАУНД",
    "ADD PLAYERS (MIN 2 - MAX 10)": "ДОБАВИТЬ ИГРОКОВ (ОТ 2 ДО 10)",
    "Enter name or tap + to quick add...": "Введите имя или нажмите +, чтобы добавить...",
    "PICK COLOR:": "ВЫБЕРИТЕ ЦВЕТ:",
    "No players added yet.\nAdd at least 2 players to start!": "Игроки еще не добавлены.\nДобавьте минимум 2 игроков для старта!",
    "CONTINUE TO OBJECTS": "ПЕРЕЙТИ К ПРЕДМЕТАМ",
    "PLAYERS": "ИГРОКИ",
    "CHOOSE YOUR OBJECT": "ВЫБЕРИТЕ ПРЕДМЕТ",
    "SELECTED": "ВЫБРАНО",
    "WATCH AD": "СМОТРЕТЬ РЕКЛАМУ",
    "UNLOCKED": "РАЗБЛОКИРОВАНО",
    "Unlock as VIP": "Открыть с VIP",
    "Unlock with 1 Video": "Открыть за 1 видео",
    "CONTINUE TO PACKS": "ПЕРЕЙТИ К НАБОРАМ",
    "CHOOSE YOUR PACKS": "ВЫБЕРИТЕ НАБОРЫ",
    "START GAME": "НАЧАТЬ ИГРУ",
    "⚡ MAKE YOUR CHOICE": "⚡ СДЕЛАЙТЕ ВЫБОР",
    "? MAKE YOUR CHOICE": "⚡ СДЕЛАЙТЕ ВЫБОР",
    "Truth, Dare, or Ask Yourselves?": "Правда, Действие или Свой вопрос?",
    "TRUTH": "ПРАВДА",
    "DARE": "ДЕЙСТВИЕ",
    "CUSTOM": "ОСОБЫЙ",
    "WOBBLING...": "КРУТИТСЯ...",
    "SPIN BOTTLE!": "КРУТИТЬ БУТЫЛОЧКУ!",
    "HOME": "ГЛАВНАЯ",
    "PROFILE": "ПРОФИЛЬ",
    "👑 VIP MEMBER": "👑 VIP УЧАСТНИК",
    "👑 GO VIP": "👑 СТАТЬ VIP",
    "♛ VIP MEMBER": "♛ VIP УЧАСТНИК",
    "♛ GO VIP": "♛ СТАТЬ VIP",
    "All premium content is unlocked": "Весь премиум-контент разблокирован",
    "Unlock Golden Champagne + Spicy pack": "Разблокируйте Золотое Шампанское + Набор 18+",
    "ACTIVE": "АКТИВНО",
    "VIEW OFFER": "ПОСМОТРЕТЬ ПРЕДЛОЖЕНИЕ",
    "CHANGE OBJECT NOW": "СМЕНИТЬ ПРЕДМЕТ",
    "CHOOSE": "ВЫБРАТЬ",
    "AD": "РЕКЛАМА",
    "ACTIVE PACKS": "АКТИВНЫЕ НАБОРЫ",
    "NO CONNECTION": "НЕТ ПОДКЛЮЧЕНИЯ",
    "Wobbly Bottle requires an active internet connection.": "Для игры требуется подключение к интернету.",
    "Connect to Wi-Fi or mobile data to continue.": "Подключитесь к Wi-Fi или мобильной сети, чтобы продолжить.",
    "WAITING FOR NETWORK...": "ОЖИДАНИЕ СЕТИ...",
    "CHOOSE GAME MODE": "ВЫБЕРИТЕ РЕЖИМ ИГРЫ",
    "TABLE MODE (SINGLE PHONE)": "НА ОДНОМ ТЕЛЕФОНЕ (ЗА СТОЛОМ)",
    "Pass & play on a single phone. Place it in the center & spin!": "Играйте всей компанией на одном телефоне. Положите в центр и крутите!",
    "HOUSE PARTY (IN-PERSON)": "ДОМАШНЯЯ ВЕЧЕРИНКА (ВМЕСТЕ)",
    "Everyone joins on their own phone! Dares, kisses & close-contact fun!": "Каждый заходит со своего телефона! Задания, флирт и безумное веселье!",
    "REMOTE PARTY (ONLINE)": "ОНЛАЙН-ВЕЧЕРИНКА (НА РАССТОЯНИИ)",
    "Play from different cities/homes! Live confessions, screenshots & photo dares!": "Играйте из разных домов и городов! Признания, скриншоты и фото-задания!",
    "Host is choosing the bottle... ⏳": "Хост выбирает бутылочку... ⏳",
    "Host is choosing packs... ⏳": "Хост выбирает наборы вопросов... ⏳",
    "is choosing Truth or Dare... ⏳": "выбирает Правду или Действие... ⏳",
    "DID IT! ✅": "ВЫПОЛНЕНО! ✅",
    "PENALTY! 💀": "ШТРАФ! 💀",
    "Notice": "Уведомление",
    "What is your biggest secret in this room?": "Какой твой самый главный секрет в этой комнате?",
    "Complete the dare or face the group's penalty!": "Выполни задание или прими наказание от компании!",
    "You are a VIP member! Ad break skipped. Waiting for other players... ✨": "Вы VIP-участник! Рекламная пауза пропущена. Ожидание других игроков... ✨",
  };

  static String getLoc(int langIdx, String en, String tr, String de, String es, [String? fr, String? ru]) {
    switch (langIdx) {
      case 1:
        return tr;
      case 2:
        return de;
      case 3:
        return es;
      case 4:
        if (fr != null) return fr;
        if (_frUiMap.containsKey(en)) return _frUiMap[en]!;
        if (en.startsWith("TRUTH FOR ")) {
          return "VÉRITÉ POUR ${en.substring("TRUTH FOR ".length)}";
        }
        if (en.startsWith("DARE FOR ")) {
          return "ACTION POUR ${en.substring("DARE FOR ".length)}";
        }
        if (en.startsWith("🎉 Unlocked: ")) {
          return "🎉 Débloqué : ${en.substring("🎉 Unlocked: ".length)}";
        }
        if (en.startsWith("Unlocking ")) {
          return "Déblocage en cours...";
        }
        if (en.startsWith("Reward granted in ")) {
          final secs = en.replaceAll(RegExp(r'[^0-9]'), '');
          return "Récompense dans $secs secondes...";
        }
        if (en.startsWith("Game resumes in ")) {
          final secs = en.replaceAll(RegExp(r'[^0-9]'), '');
          return "Reprise dans $secs secondes...";
        }
        if (en.contains(" asks any question or gives any challenge to ")) {
          final parts = en.split(" asks any question or gives any challenge to ");
          final asker = parts[0];
          final target = parts[1].replaceAll("!", "");
          return "$asker pose n'importe quelle question ou lance un défi à $target !";
        }
        return en;
      case 5:
        if (ru != null) return ru;
        if (_ruUiMap.containsKey(en)) return _ruUiMap[en]!;
        if (en.startsWith("TRUTH FOR ")) {
          return "ПРАВДА ДЛЯ ${en.substring("TRUTH FOR ".length)}";
        }
        if (en.startsWith("DARE FOR ")) {
          return "ДЕЙСТВИЕ ДЛЯ ${en.substring("DARE FOR ".length)}";
        }
        if (en.startsWith("🎉 Unlocked: ")) {
          return "🎉 Разблокировано: ${en.substring("🎉 Unlocked: ".length)}";
        }
        if (en.startsWith("Unlocking ")) {
          return "Разблокировка...";
        }
        if (en.startsWith("Reward granted in ")) {
          final secs = en.replaceAll(RegExp(r'[^0-9]'), '');
          return "Награда через $secs сек...";
        }
        if (en.startsWith("Game resumes in ")) {
          final secs = en.replaceAll(RegExp(r'[^0-9]'), '');
          return "Игра продолжится через $secs сек...";
        }
        if (en.contains(" asks any question or gives any challenge to ")) {
          final parts = en.split(" asks any question or gives any challenge to ");
          final asker = parts[0];
          final target = parts[1].replaceAll("!", "");
          return "$asker задает любой вопрос или дает задание $target!";
        }
        if (en.endsWith(" is completing the task...")) {
          final target = en.replaceAll(" is completing the task...", "");
          return "$target выполняет задание...";
        }
        return en;
      default:
        return en;
    }
  }
}

class MainGameScreen extends StatefulWidget {
  const MainGameScreen({super.key});

  @override
  State<MainGameScreen> createState() => _MainGameScreenState();
}

class _MainGameScreenState extends State<MainGameScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  // Navigation: 0 = 3-Mode Selection, 1 = Setup, 2 = Objects, 3 = Packs, 4 = Arena, 5 = RoomJoin, 6 = RoomLobby
  int currentScreen = 0; // Starts on the 3-Mode Selection Screen!
  WobblyGameMode _activeGameMode = WobblyGameMode.table;
  StreamSubscription<RoomState>? _multiplayerSub;

  // Settings
  bool isMuted = false;
  int _currentLangIndex = 0; // 0: EN, 1: TR, 2: DE, 3: ES, 4: FR

  // Right-Side Slide-Over Profile / Quick Switch Drawer
  bool _profileDrawerOpen = false;

  // Mandatory Online Connectivity State
  bool _isOnline = true;
  bool _isCheckingNet = false;
  Timer? _netTimer;

  // Players
  final List<Player> _players = [];
  final TextEditingController _nameController = TextEditingController();
  final ScrollController _colorScrollController = ScrollController();
  int _selectedColorIndex = 0;
  String _selectedEmoji = '🥳';
  bool _userPickedCustomEmoji = false;

  // Objects & Unlocks
  int _selectedObjectIndex = 0;
  final List<bool> _unlockedObjects = [true, false, false, false, false];
  bool _vip = false;
  bool _isPermanentVip = false;
  int _vipExpiryMs = 0;
  NetworkPlayer? _pendingGiftRecipient;
  BuildContext? _activeSyncedCardCtx;

  // Packs
  final List<bool> _selectedPacks = [true, false, false, false, false, false];

  // Spritesheet for Packs
  ui.Image? _packSheetImage;

  // Questions Database
  Map<String, dynamic> _questionsDb = {};
  bool _questionsLoaded = false;
  final Set<String> _usedQuestionKeys = {}; // Smart infinite deck: non-repeating cycle tracking

  // Spin & Arena Animation
  late AnimationController _spinController;
  late Animation<double> _spinAnimation;
  double _currentAngle = 0.0;
  double _startAngle = 0.0;
  double _targetAngle = 0.0;
  bool _isSpinning = false;

  int _questionerIndex = -1;
  int _answererIndex = -1;
  String _currentBendVariant = "0"; // "0", "l", "r"

  // AdMob Multi-Format Ads (RewardedInterstitialAd + RewardedAd + InterstitialAd)
  RewardedInterstitialAd? _rewardedInterstitialAd;
  RewardedAd? _rewardedAd;
  bool _isAdLoading = false;
  int _adTargetObject = -1;

  // AdMob Interstitial Ad (Every 5 spins)
  InterstitialAd? _interstitialAd;
  RewardedInterstitialAd? _spinRewardedInterstitialAd;
  bool _isInterstitialLoading = false;
  int _spinCounter = 0;

  // AdMob Persistent Bottom Banner Ad
  BannerAd? _bannerAd;
  bool _isBannerAdLoaded = false;
  int _totalSpinsForRating = 0;

  // In-App Purchase
  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _iapSubscription;
  List<ProductDetails> _products = [];
  bool _isPurchasing = false;

  // Splash wobble
  late AnimationController _wobbleController;

  static const String _iosRewardedAdUnitId = 'ca-app-pub-7561629034641721/3183849849';
  static const String _androidRewardedAdUnitId = 'ca-app-pub-7561629034641721/2336738850';

  static const String _iosInterstitialAdUnitId = 'ca-app-pub-7561629034641721/1266289633';
  static const String _androidInterstitialAdUnitId = 'ca-app-pub-7561629034641721/2604957857';

  static const String _iosBannerAdUnitId = 'ca-app-pub-7561629034641721/6725175426';
  static const String _androidBannerAdUnitId = 'ca-app-pub-7561629034641721/5614264572';

  static const String _vipProductId = 'wobbly_vip';
  static const String _vip24hProductId = 'wobbly_vip_24h';
  static const String _vipGiftProductId = 'wobbly_gift_vip';

  String get _rewardedAdUnitId =>
      Platform.isIOS ? _iosRewardedAdUnitId : _androidRewardedAdUnitId;

  String get _interstitialAdUnitId =>
      Platform.isIOS ? _iosInterstitialAdUnitId : _androidInterstitialAdUnitId;

  String get _bannerAdUnitId =>
      Platform.isIOS ? _iosBannerAdUnitId : _androidBannerAdUnitId;

  void _initDeviceLanguage() {
    try {
      final localeCode =
          ui.PlatformDispatcher.instance.locale.languageCode.toLowerCase();
      if (localeCode.startsWith('tr')) {
        _currentLangIndex = 1; // TR - Türkçe
      } else if (localeCode.startsWith('de')) {
        _currentLangIndex = 2; // DE - Deutsch
      } else if (localeCode.startsWith('es')) {
        _currentLangIndex = 3; // ES - Español
      } else if (localeCode.startsWith('fr')) {
        _currentLangIndex = 4; // FR - Français
      } else if (localeCode.startsWith('ru')) {
        _currentLangIndex = 5; // RU - Русский
      } else {
        _currentLangIndex = 0; // EN - English (default for EN & other regions)
      }
    } catch (_) {
      _currentLangIndex = 0;
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initDeviceLanguage();
    _loadVipStatus();
    _checkInternetConnectivity();
    _netTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _checkInternetConnectivity();
    });

    _loadQuestions();
    _loadPackSheet();
    _loadRewardedAd();
    _loadInterstitialAd();
    _loadBannerAd();
    _initInAppPurchase();
    _initMultiplayerListener();

    _wobbleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    // 20% faster bottle spin duration (3800ms -> 3040ms)
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3040),
    );

    _spinAnimation = CurvedAnimation(
      parent: _spinController,
      curve: Curves.decelerate,
    )..addListener(() {
        setState(() {
          final t = _spinAnimation.value;
          _currentAngle = _startAngle + (_targetAngle - _startAngle) * t;

          // Wobble bottle while spinning fast
          if (_isSpinning) {
            final cycle = math.sin(t * 35.0);
            if (cycle < -0.3) {
              _currentBendVariant = "l";
            } else if (cycle > 0.3) {
              _currentBendVariant = "r";
            } else {
              _currentBendVariant = "0";
            }
          }
        });
      })..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _onSpinFinished();
        }
      });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      RoomService().handleAppResumed();
      _checkInternetConnectivity();
      if (_rewardedInterstitialAd == null && _rewardedAd == null) {
        _loadRewardedAd();
      }
      if (_interstitialAd == null && _spinRewardedInterstitialAd == null) {
        _loadInterstitialAd();
      }
    } else if (state == AppLifecycleState.paused) {
      RoomService().handleAppPaused();
    }
  }

  Future<bool> _checkInternetConnectivity() async {
    if (_isCheckingNet) return _isOnline;
    _isCheckingNet = true;
    bool connected = false;
    final hosts = ['google.com', 'apple.com', 'cloudflare.com'];
    for (final host in hosts) {
      try {
        final result = await InternetAddress.lookup(host)
            .timeout(const Duration(seconds: 2));
        if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
          connected = true;
          break;
        }
      } catch (_) {}
    }
    _isCheckingNet = false;
    if (mounted && _isOnline != connected) {
      setState(() {
        _isOnline = connected;
      });
      if (connected) {
        // Reload ads right when connection is restored
        _loadRewardedAd();
        _loadInterstitialAd();
      }
    }
    return connected;
  }

  Future<void> _loadQuestions() async {
    try {
      final jsonString =
          await rootBundle.loadString('assets/questions.json');
      final data = json.decode(jsonString);
      if (mounted) {
        setState(() {
          _questionsDb = data;
          _questionsLoaded = true;
        });
      }
    } catch (_) {}
  }

  Future<void> _loadPackSheet() async {
    try {
      final bytes = await rootBundle.load('assets/pack_sheet.png');
      final codec = await ui.instantiateImageCodec(bytes.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      if (mounted) {
        setState(() {
          _packSheetImage = frame.image;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _multiplayerSub?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _netTimer?.cancel();
    _wobbleController.dispose();
    _spinController.dispose();
    _nameController.dispose();
    _colorScrollController.dispose();
    _rewardedInterstitialAd?.dispose();
    _rewardedAd?.dispose();
    _interstitialAd?.dispose();
    _spinRewardedInterstitialAd?.dispose();
    _bannerAd?.dispose();
    _iapSubscription?.cancel();
    super.dispose();
  }

  String _loc(String en, String tr, String de, String es, [String? fr, String? ru]) {
    return WobblyBottleAppGame.getLoc(_currentLangIndex, en, tr, de, es, fr, ru);
  }

  String get _currentLangKey {
    switch (_currentLangIndex) {
      case 1:
        return 'TR';
      case 2:
        return 'DE';
      case 3:
        return 'ES';
      case 4:
        return 'FR';
      case 5:
        return 'RU';
      default:
        return 'EN';
    }
  }

  void _unlockTargetObject(int objIdx) {
    if (objIdx < 0 || objIdx >= _unlockedObjects.length) return;
    if (!mounted) return;
    setState(() {
      _unlockedObjects[objIdx] = true;
      _selectedObjectIndex = objIdx;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF34C759),
        content: Text(
          _loc(
            "🎉 Unlocked: ${WobblyBottleAppGame.getObjectName(objIdx, _currentLangIndex)}!",
            "🎉 Açıldı: ${WobblyBottleAppGame.getObjectName(objIdx, _currentLangIndex)}!",
            "🎉 Freigeschaltet!",
            "🎉 ¡Desbloqueado!",
          ),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // --- ADMOB REWARDED AD (Multi-format: RewardedInterstitialAd -> RewardedAd -> Fallback) ---
  void _loadRewardedAd() {
    if (_isAdLoading) return;
    _isAdLoading = true;

    // 1. Try RewardedInterstitialAd first (matches original MainActivity.java setup)
    RewardedInterstitialAd.load(
      adUnitId: _rewardedAdUnitId,
      request: const AdRequest(),
      rewardedInterstitialAdLoadCallback: RewardedInterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedInterstitialAd = ad;
          _isAdLoading = false;
        },
        onAdFailedToLoad: (error) {
          _rewardedInterstitialAd = null;
          // 2. Fallback to standard RewardedAd
          RewardedAd.load(
            adUnitId: _rewardedAdUnitId,
            request: const AdRequest(),
            rewardedAdLoadCallback: RewardedAdLoadCallback(
              onAdLoaded: (ad) {
                _rewardedAd = ad;
                _isAdLoading = false;
              },
              onAdFailedToLoad: (err2) {
                _rewardedAd = null;
                // 3. Also try secondary ad unit ID as RewardedAd / RewardedInterstitialAd
                RewardedAd.load(
                  adUnitId: _interstitialAdUnitId,
                  request: const AdRequest(),
                  rewardedAdLoadCallback: RewardedAdLoadCallback(
                    onAdLoaded: (ad) {
                      _rewardedAd = ad;
                      _isAdLoading = false;
                    },
                    onAdFailedToLoad: (_) {
                      _isAdLoading = false;
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _startRewardedAd(int objectIndex) async {
    final online = await _checkInternetConnectivity();
    if (!online) return;

    _adTargetObject = objectIndex;

    if (_rewardedInterstitialAd != null) {
      bool rewarded = false;
      _rewardedInterstitialAd!.fullScreenContentCallback =
          FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _rewardedInterstitialAd = null;
          _loadRewardedAd();
          if (rewarded) {
            _unlockTargetObject(_adTargetObject);
          }
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          ad.dispose();
          _rewardedInterstitialAd = null;
          _loadRewardedAd();
          _showSponsoredVideoAdDialog(
              isRewarded: true, targetObject: _adTargetObject);
        },
      );
      _rewardedInterstitialAd!.show(
        onUserEarnedReward: (adWithoutView, reward) {
          rewarded = true;
          _unlockTargetObject(_adTargetObject);
        },
      );
      return;
    }

    if (_rewardedAd != null) {
      bool rewarded = false;
      _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _rewardedAd = null;
          _loadRewardedAd();
          if (rewarded) {
            _unlockTargetObject(_adTargetObject);
          }
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          ad.dispose();
          _rewardedAd = null;
          _loadRewardedAd();
          _showSponsoredVideoAdDialog(
              isRewarded: true, targetObject: _adTargetObject);
        },
      );
      _rewardedAd!.show(
        onUserEarnedReward: (adWithoutView, reward) {
          rewarded = true;
          _unlockTargetObject(_adTargetObject);
        },
      );
      return;
    }

    if (_interstitialAd != null) {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _interstitialAd = null;
          _loadInterstitialAd();
          _unlockTargetObject(_adTargetObject);
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          ad.dispose();
          _interstitialAd = null;
          _loadInterstitialAd();
          _showSponsoredVideoAdDialog(
              isRewarded: true, targetObject: _adTargetObject);
        },
      );
      _interstitialAd!.show();
      return;
    }

    // If AdMob has no fill yet (e.g. newly approved iOS app warming up),
    // show the 5-second Sponsored Video Ad modal so the user is NEVER stuck!
    _loadRewardedAd();
    _loadInterstitialAd();
    _showSponsoredVideoAdDialog(
        isRewarded: true, targetObject: _adTargetObject);
  }

  // --- ADMOB INTERSTITIAL AD (EVERY 5 SPINS) ---
  void _loadInterstitialAd() {
    if (_isInterstitialLoading || _vip) return;
    _isInterstitialLoading = true;
    InterstitialAd.load(
      adUnitId: _interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialLoading = false;
        },
        onAdFailedToLoad: (error) {
          _interstitialAd = null;
          // Try RewardedInterstitialAd on the same or primary unit as backup
          RewardedInterstitialAd.load(
            adUnitId: _rewardedAdUnitId,
            request: const AdRequest(),
            rewardedInterstitialAdLoadCallback:
                RewardedInterstitialAdLoadCallback(
              onAdLoaded: (ad) {
                _spinRewardedInterstitialAd = ad;
                _isInterstitialLoading = false;
              },
              onAdFailedToLoad: (_) {
                _spinRewardedInterstitialAd = null;
                _isInterstitialLoading = false;
              },
            ),
          );
        },
      ),
    );
  }

  void _showInterstitialAdIfNeeded() {
    _totalSpinsForRating++;
    if (_totalSpinsForRating == 6) {
      Future.delayed(const Duration(milliseconds: 600), () {
        _checkAndShowRateDialog();
      });
    }

    if (_vip) return; // VIP users never see ads!

    _spinCounter++;
    if (_spinCounter >= 5) {
      _spinCounter = 0; // Reset counter every 5 spins
      if (_interstitialAd != null) {
        _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
          onAdDismissedFullScreenContent: (ad) {
            ad.dispose();
            _interstitialAd = null;
            _loadInterstitialAd();
          },
          onAdFailedToShowFullScreenContent: (ad, error) {
            ad.dispose();
            _interstitialAd = null;
            _loadInterstitialAd();
            _showSponsoredVideoAdDialog(isRewarded: false, targetObject: -1);
          },
        );
        _interstitialAd!.show();
      } else if (_spinRewardedInterstitialAd != null) {
        _spinRewardedInterstitialAd!.fullScreenContentCallback =
            FullScreenContentCallback(
          onAdDismissedFullScreenContent: (ad) {
            ad.dispose();
            _spinRewardedInterstitialAd = null;
            _loadInterstitialAd();
          },
          onAdFailedToShowFullScreenContent: (ad, error) {
            ad.dispose();
            _spinRewardedInterstitialAd = null;
            _loadInterstitialAd();
            _showSponsoredVideoAdDialog(isRewarded: false, targetObject: -1);
          },
        );
        _spinRewardedInterstitialAd!.show(
          onUserEarnedReward: (_, reward) {},
        );
      } else if (_rewardedInterstitialAd != null) {
        _rewardedInterstitialAd!.fullScreenContentCallback =
            FullScreenContentCallback(
          onAdDismissedFullScreenContent: (ad) {
            ad.dispose();
            _rewardedInterstitialAd = null;
            _loadRewardedAd();
          },
          onAdFailedToShowFullScreenContent: (ad, error) {
            ad.dispose();
            _rewardedInterstitialAd = null;
            _loadRewardedAd();
            _showSponsoredVideoAdDialog(isRewarded: false, targetObject: -1);
          },
        );
        _rewardedInterstitialAd!.show(
          onUserEarnedReward: (_, reward) {},
        );
      } else {
        _loadInterstitialAd();
        _showSponsoredVideoAdDialog(isRewarded: false, targetObject: -1);
      }
    }
  }

  // --- INTERNAL 5-SECOND SPONSORED VIDEO AD FALLBACK (Matches GameView.java drawRewardedAd) ---
  void _showSponsoredVideoAdDialog({
    required bool isRewarded,
    required int targetObject,
  }) {
    int secondsLeft = 5;
    Timer? countdownTimer;
    bool timerStarted = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            if (!timerStarted) {
              timerStarted = true;
              countdownTimer =
                  Timer.periodic(const Duration(seconds: 1), (timer) {
                if (!dialogCtx.mounted) {
                  timer.cancel();
                  return;
                }
                if (secondsLeft > 1) {
                  setDialogState(() {
                    secondsLeft--;
                  });
                } else {
                  timer.cancel();
                  if (Navigator.of(dialogCtx).canPop()) {
                    Navigator.of(dialogCtx).pop();
                  }
                  if (isRewarded && targetObject >= 0) {
                    _unlockTargetObject(targetObject);
                  }
                }
              });
            }

            final progress = (5 - secondsLeft) / 5.0;
            final objPreviewIdx = targetObject >= 0 ? targetObject : 4;

            return PopScope(
              canPop: false,
              child: Dialog(
                backgroundColor: const Color(0xFF0A0F1D),
                insetPadding: const EdgeInsets.symmetric(
                    horizontal: 20.0, vertical: 24.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                  side: const BorderSide(color: Color(0xFFBF4FFF), width: 3),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24.0, vertical: 28.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Top Ad Badge + Countdown
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFBF4FFF)
                                  .withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                              border:
                                  Border.all(color: const Color(0xFFBF4FFF)),
                            ),
                            child: Text(
                              _loc("SPONSORED VIDEO", "SPONSORLU VİDEO",
                                  "GESPONSERTES VIDEO", "VIDEO PATROCINADO"),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFFBF4FFF),
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                              "${secondsLeft}s",
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFFFFCC00),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),

                      // Animated Bottle/VIP Preview inside Video Frame
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            vertical: 24, horizontal: 16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF150A2A), Color(0xFF061A2E)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color:
                                const Color(0xFF00F2FE).withValues(alpha: 0.4),
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          children: [
                            SizedBox(
                              height: 110,
                              child: Image.asset(
                                'assets/bent_${objPreviewIdx}_0.png',
                                fit: BoxFit.contain,
                              ),
                            ),
                            const SizedBox(height: 14),
                            const Text(
                              "WOBBLY VIP PARTY",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFFFFCC00),
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              isRewarded
                                  ? _loc(
                                      "Unlocking ${WobblyBottleAppGame.getObjectName(targetObject, _currentLangIndex)}...",
                                      "${WobblyBottleAppGame.getObjectName(targetObject, _currentLangIndex)} kilidi açılıyor...",
                                      "Wird freigeschaltet...",
                                      "Desbloqueando...",
                                    )
                                  : _loc(
                                      "Remove all ads & unlock Golden Champagne + 18+ Spicy Pack with VIP!",
                                      "VIP ile tüm reklamları kaldır, Altın Şampanya ve +18 Paketi aç!",
                                      "Alle Werbung entfernen mit VIP!",
                                      "¡Elimina todos los anuncios con VIP!",
                                    ),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.white70,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Progress Bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 10,
                          backgroundColor: Colors.white12,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFF00F2FE)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        isRewarded
                            ? _loc(
                                "Reward granted in $secondsLeft seconds...",
                                "Ödül $secondsLeft saniye içinde veriliyor...",
                                "Belohnung in $secondsLeft Sekunden...",
                                "Recompensa en $secondsLeft segundos...",
                              )
                            : _loc(
                                "Game resumes in $secondsLeft seconds...",
                                "Oyun $secondsLeft saniye içinde devam ediyor...",
                                "Weiter in $secondsLeft Sekunden...",
                                "El juego continúa en $secondsLeft segundos...",
                              ),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF00F2FE),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    ).then((_) {
      countdownTimer?.cancel();
    });
  }

  // --- ADMOB BOTTOM BANNER AD ---
  void _loadBannerAd() {
    if (_vip) return;
    _bannerAd?.dispose();
    _bannerAd = BannerAd(
      adUnitId: _bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (mounted) {
            setState(() {
              _isBannerAdLoaded = true;
            });
          }
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('BannerAd failed to load: $error');
          ad.dispose();
          _bannerAd = null;
          if (mounted) {
            setState(() {
              _isBannerAdLoaded = false;
            });
          }
        },
      ),
    )..load();
  }

  // --- 5-STAR RATING POPUP DIALOG ---
  Future<void> _checkAndShowRateDialog() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bool hasRated = prefs.getBool('wb_has_rated_v1') ?? false;
      if (!hasRated && mounted) {
        _show5StarRatingDialog();
      }
    } catch (e) {
      debugPrint('Rate dialog check error: $e');
    }
  }

  void _show5StarRatingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1B1B3A), Color(0xFF0F0F1E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: Colors.amberAccent.withValues(alpha: 0.6),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.amberAccent.withValues(alpha: 0.25),
                  blurRadius: 30,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    5,
                    (i) => const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(Icons.star_rounded, color: Colors.amberAccent, size: 36),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _loc(
                    "ENJOYING WOBBLY BOTTLE?",
                    "WOBBLY BOTTLE'I SEVDİN Mİ?",
                    "GEFÄLLT DIR WOBBLY BOTTLE?",
                    "¿TE GUSTA WOBBLY BOTTLE?",
                    "TU AIMES WOBBLY BOTTLE?",
                    "НРАВИТСЯ WOBBLY BOTTLE?",
                  ),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _loc(
                    "Having fun with your friends? Support our indie developer team with a quick 5-star rating on the store! It helps us add more crazy objects & packs!",
                    "Arkadaşlarınla eğleniyor musun? Bağımsız geliştiricimize mağazada 5 yıldız vererek destek olmak ister misin? Yeni çılgın nesneler ve soru paketleri eklememize çok yardımcı olur!",
                    "Hast du Spaß mit deinen Freunden? Unterstütze unser Indie-Team mit einer 5-Sterne-Bewertung im Store! Es hilft uns, mehr verrückte Objekte hinzuzufügen!",
                    "¿Te estás divirtiendo con tus amigos? ¡Apoya a nuestro equipo indie con una calificación de 5 estrellas en la tienda! ¡Nos ayuda a crear más objetos locos!",
                    "Tu t'amuses avec tes amis ? Soutiens notre équipe indépendante avec une note de 5 étoiles sur le store ! Cela nous aide à ajouter de nouveaux objets fous !",
                    "Веселитесь с друзьями? Поддержите нашу инди-команду оценкой 5 звёзд в магазине! Это поможет нам добавлять ещё больше безумных предметов и наборов!",
                  ),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.of(ctx).pop();
                      try {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setBool('wb_has_rated_v1', true);
                      } catch (_) {}
                      _openStoreRating();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amberAccent,
                      foregroundColor: Colors.black,
                      elevation: 8,
                      shadowColor: Colors.amberAccent.withValues(alpha: 0.6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      _loc(
                        "⭐ RATE 5 STARS",
                        "⭐ 5 YILDIZ VER",
                        "⭐ 5 STERNE BEWERTEN",
                        "⭐ CALIFICAR 5 ESTRELLAS",
                        "⭐ NOTER 5 ÉTOILES",
                        "⭐ ОЦЕНИТЬ НА 5 ЗВЁЗД",
                      ),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(
                    _loc(
                      "MAYBE LATER",
                      "BELKİ DAHA SONRA",
                      "SPÄTER VIELLEICHT",
                      "TAL VEZ MÁS TARDE",
                      "PEUT-ÊTRE PLUS TARD",
                      "ПОЗЖЕ",
                    ),
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openStoreRating() async {
    final Uri storeUri = Platform.isIOS
        ? Uri.parse('https://apps.apple.com/app/id6794894168?action=write-review')
        : Uri.parse('market://details?id=com.wobblybottle.game');

    try {
      if (await canLaunchUrl(storeUri)) {
        await launchUrl(storeUri, mode: LaunchMode.externalApplication);
      } else {
        final webFallback = Platform.isIOS
            ? Uri.parse('https://apps.apple.com/app/id6794894168')
            : Uri.parse('https://play.google.com/store/apps/details?id=com.wobblybottle.game');
        await launchUrl(webFallback, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Error launching store rating: $e');
    }
  }

  // --- VIP PERSISTENCE & ACTIVATION (24H RENTAL + LIFETIME) ---
  Future<void> _loadVipStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isPerm = prefs.getBool('wb_vip_permanent') ?? false;
      final expiryMs = prefs.getInt('wb_vip_expiry_ms') ?? 0;
      final nowMs = DateTime.now().millisecondsSinceEpoch;

      if (isPerm || expiryMs > nowMs) {
        if (mounted) {
          setState(() {
            _vip = true;
            _isPermanentVip = isPerm;
            _vipExpiryMs = expiryMs;
            _unlockedObjects[4] = true;
            _selectedPacks[4] = true;
            _bannerAd?.dispose();
            _bannerAd = null;
            _isBannerAdLoaded = false;
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _activateVip({required bool permanent}) async {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final expiry = permanent
        ? 0
        : nowMs + const Duration(hours: 24).inMilliseconds;

    try {
      final prefs = await SharedPreferences.getInstance();
      if (permanent) {
        await prefs.setBool('wb_vip_permanent', true);
      } else {
        await prefs.setInt('wb_vip_expiry_ms', expiry);
      }
    } catch (_) {}

    if (!mounted) return;
    setState(() {
      _vip = true;
      if (permanent) {
        _isPermanentVip = true;
      } else {
        _vipExpiryMs = expiry;
      }
      _unlockedObjects[4] = true;
      _selectedPacks[4] = true;
      _isPurchasing = false;
      _bannerAd?.dispose();
      _bannerAd = null;
      _isBannerAdLoaded = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFFFFCC00),
        content: Text(
          permanent
              ? _loc(
                  "👑 Lifetime Wobbly VIP Activated! All features unlocked forever!",
                  "👑 Ömür Boyu Wobbly VIP Aktif Edildi! Tüm kilitler sonsuza dek açıldı!",
                  "👑 Lifetime Wobbly VIP Aktiviert!",
                  "👑 ¡Wobbly VIP de por vida Activado!",
                  "👑 Wobbly VIP à vie Activé !",
                  "👑 Пожизненный Wobbly VIP Активирован!",
                )
              : _loc(
                  "⏳ 24-Hour Party VIP Pass Activated! Enjoy the party!",
                  "⏳ 24 Saatlik Parti VIP Pasaportu Aktif Edildi! İyi eğlenceler!",
                  "⏳ 24-Stunden Party VIP-Pass Aktiviert!",
                  "⏳ ¡Pase VIP de 24 Horas Activado!",
                  "⏳ Pass VIP 24 Heures Activé !",
                  "⏳ VIP-пропуск на 24 часа активирован!",
                ),
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  String _getDefaultPriceLabel({required bool isLifetime}) {
    switch (_currentLangIndex) {
      case 1: // TR
        return isLifetime ? "299.99 ₺" : "99.99 ₺";
      case 2: // DE
      case 3: // ES
      case 4: // FR
        return isLifetime ? "8,99 €" : "2,99 €";
      case 5: // RU
        return isLifetime ? "799 ₽" : "249 ₽";
      default: // EN
        return isLifetime ? "\$8.99" : "\$2.99";
    }
  }

  // --- APPLE / GOOGLE IN-APP PURCHASE ---
  Future<void> _initInAppPurchase() async {
    final bool available = await _iap.isAvailable();
    if (!available) return;

    _iapSubscription?.cancel();
    _iapSubscription = _iap.purchaseStream.listen(
      (List<PurchaseDetails> purchaseDetailsList) {
        _handlePurchases(purchaseDetailsList);
      },
      onDone: () {
        _iapSubscription?.cancel();
      },
      onError: (error) {
        if (mounted) setState(() => _isPurchasing = false);
      },
    );

    await _fetchProducts();

    // Restore prior purchases if user already purchased
    try {
      await _iap.restorePurchases();
    } catch (_) {}
  }

  Future<void> _fetchProducts() async {
    try {
      const Set<String> kIds = {
        _vipProductId,
        _vip24hProductId,
        _vipGiftProductId,
      };
      final ProductDetailsResponse response =
          await _iap.queryProductDetails(kIds);
      if (response.productDetails.isNotEmpty) {
        if (mounted) {
          setState(() {
            _products = response.productDetails;
          });
        }
      }
    } catch (_) {}
  }

  void _handlePurchases(List<PurchaseDetails> purchaseDetailsList) {
    for (var purchase in purchaseDetailsList) {
      if (purchase.productID == _vipProductId ||
          purchase.productID == _vip24hProductId ||
          purchase.productID == _vipGiftProductId) {
        if (purchase.status == PurchaseStatus.purchased ||
            purchase.status == PurchaseStatus.restored) {
          setState(() => _isPurchasing = false);
          if (_pendingGiftRecipient != null) {
            final recipient = _pendingGiftRecipient!;
            _pendingGiftRecipient = null;
            RoomService().broadcastVipGift(
              targetPlayerId: recipient.id,
              targetPlayerName: recipient.name,
              isLifetime: purchase.productID == _vipProductId,
            );
          } else {
            final isPerm = purchase.productID == _vipProductId;
            _activateVip(permanent: isPerm);
          }
        } else if (purchase.status == PurchaseStatus.error ||
            purchase.status == PurchaseStatus.canceled) {
          setState(() {
            _isPurchasing = false;
            _pendingGiftRecipient = null;
          });
          if (mounted && purchase.status == PurchaseStatus.error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  _loc(
                    "Purchase failed or canceled.",
                    "Satın alma başarısız oldu veya iptal edildi.",
                    "Kauf fehlgeschlagen.",
                    "La compra falló.",
                    "Achat échoué ou annulé.",
                    "Покупка не удалась или была отменена.",
                  ),
                ),
              ),
            );
          }
        }
        if (purchase.pendingCompletePurchase) {
          _iap.completePurchase(purchase);
        }
      }
    }
  }

  Future<void> _buyVipTier({
    required String productId,
    required bool isPermanent,
    NetworkPlayer? giftRecipient,
    void Function(void Function())? setModalState,
    BuildContext? dialogCtx,
  }) async {
    ProductDetails? targetProduct;
    for (var p in _products) {
      if (p.id == productId) {
        targetProduct = p;
        break;
      }
    }

    if (targetProduct == null) {
      if (setModalState != null) {
        setModalState(() => _isPurchasing = true);
      } else {
        setState(() => _isPurchasing = true);
      }

      try {
        final response = await _iap.queryProductDetails({productId});
        if (response.productDetails.isNotEmpty) {
          targetProduct = response.productDetails.first;
          if (mounted) {
            setState(() {
              _products = [..._products, ...response.productDetails];
            });
          }
        }
      } catch (_) {}
    }

    if (targetProduct != null) {
      _pendingGiftRecipient = giftRecipient;
      if (setModalState != null) {
        setModalState(() => _isPurchasing = true);
      } else {
        setState(() => _isPurchasing = true);
      }

      final PurchaseParam purchaseParam =
          PurchaseParam(productDetails: targetProduct);
      if (productId == _vipProductId && giftRecipient == null) {
        _iap.buyNonConsumable(purchaseParam: purchaseParam);
      } else {
        _iap.buyConsumable(purchaseParam: purchaseParam);
      }
    } else {
      // Emulator / Store Test Fallback when Play Billing or new SKU is not yet registered
      if (setModalState != null) {
        setModalState(() => _isPurchasing = false);
      } else {
        setState(() => _isPurchasing = false);
      }
      if (dialogCtx != null && dialogCtx.mounted && Navigator.of(dialogCtx).canPop()) {
        Navigator.of(dialogCtx).pop();
      }
      if (giftRecipient != null) {
        RoomService().broadcastVipGift(
          targetPlayerId: giftRecipient.id,
          targetPlayerName: giftRecipient.name,
          isLifetime: isPermanent,
        );
      } else {
        await _activateVip(permanent: isPermanent);
      }
    }
  }

  // --- DECOY PRICING VIP OFFER MODAL (24-HOUR PASS vs LIFETIME VIP) ---
  void _openVipModal() {
    _fetchProducts(); // Pre-fetch if not ready

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            ProductDetails? vipLifetimeProd;
            ProductDetails? vip24hProd;
            for (var p in _products) {
              if (p.id == _vipProductId) vipLifetimeProd = p;
              if (p.id == _vip24hProductId) vip24hProd = p;
            }
            final lifetimePrice = vipLifetimeProd?.price.isNotEmpty == true
                ? vipLifetimeProd!.price
                : _getDefaultPriceLabel(isLifetime: true);
            final pass24hPrice = vip24hProd?.price.isNotEmpty == true
                ? vip24hProd!.price
                : _getDefaultPriceLabel(isLifetime: false);

            return Dialog(
              backgroundColor: const Color(0xFF0E0B18),
              insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
                side: const BorderSide(color: Color(0xFFFFCC00), width: 2.8),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 22.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFFFCC00).withValues(alpha: 0.15),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFFCC00).withValues(alpha: 0.3),
                            blurRadius: 18,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.workspace_premium, size: 46, color: Color(0xFFFFCC00)),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "👑 WOBBLY VIP CLUB",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFFFFCC00),
                        letterSpacing: 1.6,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _loc(
                        "Unlock All Premium Perks & Remove Ads",
                        "Tüm Premium Özellikleri Aç & Reklamları Kaldır",
                        "Alle Premium-Vorteile & Keine Werbung",
                        "Desbloquea Todo el Contenido VIP Sin Anuncios",
                        "Débloquez Tout le Contenu VIP Sans Pubs",
                        "Откройте все VIP-возможности без рекламы",
                      ),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70, fontSize: 12.5),
                    ),
                    const SizedBox(height: 16),
                    _buildVipFeature(
                      Icons.wine_bar,
                      _loc("Golden Champagne Bottle", "Altın Şampanya Şişesi", "Goldener Champagner", "Champán Dorado", "Bouteille de Champagne Doré", "Бутылка Золотого Шампанского"),
                    ),
                    const SizedBox(height: 8),
                    _buildVipFeature(
                      Icons.favorite,
                      _loc("💋 +18 Spicy Secret Pack", "💋 +18 Baharatlı Gizli Paket", "💋 +18 Scharf-Paket", "💋 +18 Paquete Picante", "💋 Pack Secret +18 Épicé", "💋 Секретный Пикантный Набор 18+"),
                    ),
                    const SizedBox(height: 8),
                    _buildVipFeature(
                      Icons.block,
                      _loc("100% Ad-Free + VIP Crown in Online Rooms", "%100 Reklamsız Oyun + Online Odalarda 👑 VIP Tacı", "100% Werbefrei + VIP-Krone in Räumen", "100% Sin Anuncios + Corona VIP Online", "100% Sans Pub + Couronne VIP en Ligne", "100% Без рекламы + Корона 👑 VIP в комнатах"),
                    ),
                    if (_vip) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF10B981)),
                        ),
                        child: Text(
                          _isPermanentVip
                              ? _loc("👑 Lifetime VIP Active", "👑 Ömür Boyu VIP Aktif", "👑 Lifetime VIP Aktiv", "👑 VIP de por vida Activo", "👑 VIP à vie Actif", "👑 Пожизненный VIP Активен")
                              : "⏳ VIP Pass (${((_vipExpiryMs - DateTime.now().millisecondsSinceEpoch) / 3600000).clamp(1, 24).ceil()}h)",
                          style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),

                    // TIER 1: 24-HOUR PARTY PASS (DECOY OPTION)
                    GestureDetector(
                      onTap: _isPurchasing
                          ? null
                          : () => _buyVipTier(
                                productId: _vip24hProductId,
                                isPermanent: false,
                                setModalState: setDialogState,
                                dialogCtx: dialogCtx,
                              ),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF141D2E),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFF00F2FE).withValues(alpha: 0.7), width: 1.8),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF00F2FE).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text("⏳", style: TextStyle(fontSize: 22)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _loc(
                                      "24-HOUR PARTY PASS",
                                      "24 SAATLİK PARTİ PASAPORTU",
                                      "24-STUNDEN PARTY-PASS",
                                      "PASE DE FIESTA 24 HORAS",
                                      "PASS SOIRÉE 24 HEURES",
                                      "ТУСОВОЧНЫЙ ПРОПУСК НА 24 ЧАСА",
                                    ),
                                    style: const TextStyle(
                                      color: Color(0xFF00F2FE),
                                      fontWeight: FontWeight.w900,
                                      fontSize: 13.5,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _loc(
                                      "Full VIP access for tonight's party (24h)",
                                      "Bu geceki parti için 24 saat tam VIP erişim",
                                      "Voller VIP-Zugang für heute Abend (24h)",
                                      "Acceso VIP completo por 24 horas",
                                      "Accès VIP complet pendant 24 heures",
                                      "Полный VIP-доступ на сегодняшнюю вечеринку (24ч)",
                                    ),
                                    style: const TextStyle(color: Colors.white60, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF00F2FE),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                pass24hPrice,
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // TIER 2: LIFETIME VIP (HERO / ANCHOR OPTION)
                    GestureDetector(
                      onTap: _isPurchasing
                          ? null
                          : () => _buyVipTier(
                                productId: _vipProductId,
                                isPermanent: true,
                                setModalState: setDialogState,
                                dialogCtx: dialogCtx,
                              ),
                      child: Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.topCenter,
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.fromLTRB(14, 18, 14, 14),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF2E2105), Color(0xFF1F122B)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFFFFCC00), width: 2.5),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFFCC00).withValues(alpha: 0.35),
                                  blurRadius: 16,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFCC00).withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text("👑", style: TextStyle(fontSize: 24)),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _loc(
                                          "LIFETIME VIP (FOREVER)",
                                          "ÖMÜR BOYU VIP (SINIRSIZ)",
                                          "LIFETIME VIP (DAUERHAFT)",
                                          "VIP DE POR VIDA (ILIMITADO)",
                                          "VIP À VIE (ILLIMITÉ)",
                                          "ПОЖИЗНЕННЫЙ VIP (НАВСЕГДА)",
                                        ),
                                        style: const TextStyle(
                                          color: Color(0xFFFFCC00),
                                          fontWeight: FontWeight.w900,
                                          fontSize: 14.5,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        _loc(
                                          "Pay once, own forever! Best value for unlimited parties",
                                          "Tek sefer öde, sonsuza dek senin olsun! Sınırsız parti!",
                                          "Einmal zahlen, für immer behalten! Bester Deal!",
                                          "¡Paga una vez, tuyo para siempre! El mejor valor",
                                          "Payez une fois, gardez à vie ! Meilleure offre",
                                          "Заплати один раз — пользуйся вечно! Лучший выбор",
                                        ),
                                        style: const TextStyle(color: Colors.white, fontSize: 11.5),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFFFFCC00), Color(0xFFFF9500)],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    lifetimePrice,
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Positioned(
                            top: -10,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF0844),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFFFFCC00), width: 1.2),
                              ),
                              child: Text(
                                _loc(
                                  "🔥 MOST POPULAR • BEST VALUE",
                                  "🔥 EN POPÜLER • EN AVANTAJLI SEÇİM",
                                  "🔥 AM BELIEBTESTEN • BESTER WERT",
                                  "🔥 MÁS POPULAR • MEJOR VALOR",
                                  "🔥 LE PLUS POPULAIRE • MEILLEURE OFFRE",
                                  "🔥 САМЫЙ ПОПУЛЯРНЫЙ • ВЫГОДНО",
                                ),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 9.5,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (_isPurchasing) ...[
                      const SizedBox(height: 14),
                      const CircularProgressIndicator(color: Color(0xFFFFCC00)),
                    ],

                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        TextButton(
                          onPressed: () {
                            _iap.restorePurchases();
                            Navigator.of(ctx).pop();
                          },
                          child: Text(
                            _loc("Restore Purchase", "Satın Alımı Geri Yükle", "Käufe wiederherstellen", "Restaurar compra", "Restaurer les achats", "Восстановить покупки"),
                            style: const TextStyle(color: Color(0xFF00F2FE), fontSize: 12.5),
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: Text(
                            _loc("Cancel", "Vazgeç", "Abbrechen", "Cancelar", "Annuler", "Отмена"),
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 12.5),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // --- GIFT VIP TO ANY PLAYER IN ONLINE ROOMS ---
  void _openGiftVipModal(NetworkPlayer recipient) {
    _fetchProducts();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            ProductDetails? vipLifetimeProd;
            ProductDetails? vip24hProd;
            for (var p in _products) {
              if (p.id == _vipGiftProductId || p.id == _vipProductId) vipLifetimeProd = p;
              if (p.id == _vip24hProductId) vip24hProd = p;
            }
            final lifetimePrice = vipLifetimeProd?.price.isNotEmpty == true
                ? vipLifetimeProd!.price
                : _getDefaultPriceLabel(isLifetime: true);
            final pass24hPrice = vip24hProd?.price.isNotEmpty == true
                ? vip24hProd!.price
                : _getDefaultPriceLabel(isLifetime: false);

            return Dialog(
              backgroundColor: const Color(0xFF0E0B18),
              insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
                side: const BorderSide(color: Color(0xFFFFCC00), width: 2.5),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("🎁👑", style: TextStyle(fontSize: 42)),
                    const SizedBox(height: 8),
                    Text(
                      _loc(
                        "GIFT VIP TO ${recipient.name.toUpperCase()}",
                        "${recipient.name.toUpperCase()} İÇİN VIP HEDİYE ET",
                        "VIP AN ${recipient.name.toUpperCase()} SCHENKEN",
                        "REGALAR VIP A ${recipient.name.toUpperCase()}",
                        "OFFRIR VIP À ${recipient.name.toUpperCase()}",
                        "ПОДАРИТЬ VIP ИГРОКУ ${recipient.name.toUpperCase()}",
                      ),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFFFFCC00),
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _loc(
                        "Surprise ${recipient.emoji} ${recipient.name} with the Golden VIP Crown! The entire room will see a live celebration & unlock VIP Room perks!",
                        "${recipient.emoji} ${recipient.name} adlı arkadaşına Altın VIP Tacı hediye et! Tüm odada canlı kutlama çıkacak ve odanız anında VIP Odaya dönüşecek!",
                        "Überrasche ${recipient.emoji} ${recipient.name} mit der goldenen VIP-Krone! Der ganze Raum feiert mit!",
                        "¡Sorprende a ${recipient.emoji} ${recipient.name} con la Corona VIP! ¡Toda la sala lo celebrará en vivo!",
                        "Surprenez ${recipient.emoji} ${recipient.name} avec la Couronne VIP ! Toute la salle fêtera ça en direct !",
                        "Подарите ${recipient.emoji} ${recipient.name} Золотую VIP-корону! Вся комната увидит праздничное шоу и получит статус VIP-комнаты!",
                      ),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70, fontSize: 12.5, height: 1.35),
                    ),
                    const SizedBox(height: 18),

                    // Gift 24-Hour VIP
                    GestureDetector(
                      onTap: _isPurchasing
                          ? null
                          : () => _buyVipTier(
                                productId: _vip24hProductId,
                                isPermanent: false,
                                giftRecipient: recipient,
                                setModalState: setDialogState,
                                dialogCtx: dialogCtx,
                              ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF141D2E),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF00F2FE), width: 1.8),
                        ),
                        child: Row(
                          children: [
                            const Text("⏳", style: TextStyle(fontSize: 22)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _loc(
                                  "Gift 24-Hour Party VIP Pass",
                                  "24 Saatlik Parti VIP Hediye Et",
                                  "24-Stunden Party-VIP schenken",
                                  "Regalar Pase VIP 24 Horas",
                                  "Offrir Pass VIP 24 Heures",
                                  "Подарить VIP на 24 часа",
                                ),
                                style: const TextStyle(color: Color(0xFF00F2FE), fontWeight: FontWeight.w900, fontSize: 13),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF00F2FE),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                pass24hPrice,
                                style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Gift Lifetime VIP
                    GestureDetector(
                      onTap: _isPurchasing
                          ? null
                          : () => _buyVipTier(
                                productId: _vipGiftProductId,
                                isPermanent: true,
                                giftRecipient: recipient,
                                setModalState: setDialogState,
                                dialogCtx: dialogCtx,
                              ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF2E2105), Color(0xFF1F122B)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFFFCC00), width: 2.2),
                        ),
                        child: Row(
                          children: [
                            const Text("👑", style: TextStyle(fontSize: 24)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _loc(
                                  "Gift Lifetime VIP (Forever)",
                                  "Ömür Boyu VIP Hediye Et",
                                  "Lifetime VIP schenken",
                                  "Regalar VIP de por Vida",
                                  "Offrir VIP à Vie",
                                  "Подарить Пожизненный VIP",
                                ),
                                style: const TextStyle(color: Color(0xFFFFCC00), fontWeight: FontWeight.w900, fontSize: 13.5),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFCC00),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                lifetimePrice,
                                style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: Text(
                        _loc("Cancel", "Vazgeç", "Abbrechen", "Cancelar", "Annuler", "Отмена"),
                        style: const TextStyle(color: Colors.white54),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showVipGiftCelebrationDialog({
    required String senderName,
    required String recipientName,
    required bool isForMe,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: const Color(0xFF0E0B18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: const BorderSide(color: Color(0xFFFFCC00), width: 3),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("🎉👑🎁", style: TextStyle(fontSize: 48)),
              const SizedBox(height: 12),
              Text(
                isForMe
                    ? _loc(
                        "YOU RECEIVED A VIP GIFT!",
                        "SANA VIP HEDİYE EDİLDİ!",
                        "DU HAST EIN VIP-GESCHENK ERHALTEN!",
                        "¡RECIBISTE UN REGALO VIP!",
                        "VOUS AVEZ REÇU UN CADEAU VIP !",
                        "ВАМ ПОДАРИЛИ VIP-СТАТУС!",
                      )
                    : _loc(
                        "VIP GIFT IN THE ROOM!",
                        "ODADA VIP SÜRPRİZİ!",
                        "VIP-GESCHENK IM RAUM!",
                        "¡REGALO VIP EN LA SALA!",
                        "CADEAU VIP DANS LA SALLE !",
                        "VIP-ПОДАРОК В КОМНАТЕ!",
                      ),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFFFFCC00),
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _loc(
                  "$senderName gifted 👑 VIP to $recipientName! Golden Champagne & +18 Spicy Pack are now unlocked for this room!",
                  "$senderName, $recipientName adlı oyuncuya 👑 VIP hediye etti! Altın Şampanya ve +18 Baharatlı Paket bu oda için açıldı!",
                  "$senderName hat $recipientName 👑 VIP geschenkt! Alle VIP-Vorteile sind jetzt im Raum aktiv!",
                  "¡$senderName le regaló 👑 VIP a $recipientName! ¡Beneficios VIP desbloqueados para toda la sala!",
                  "$senderName a offert 👑 VIP à $recipientName ! Les avantages VIP sont débloqués pour la salle !",
                  "$senderName подарил(а) 👑 VIP игроку $recipientName! Золотое Шампанское и набор 18+ открыты для всей комнаты!",
                ),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFCC00),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(
                  _loc("AWESOME! 🥳", "HARİKA! 🥳", "MEGA! 🥳", "¡GENIAL! 🥳", "GÉNIAL ! 🥳", "СУПЕР! 🥳"),
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- FIRST-TIME PLAY ONBOARDING POP-UPS (SETUP, OBJECTS, PACKS) ---
  Future<void> _checkAndShowOnboarding(int screenIdx) async {
    String prefKey = '';
    if (screenIdx == 1) {
      prefKey = 'wb_onboard_setup_v1';
    } else if (screenIdx == 2) {
      prefKey = 'wb_onboard_objects_v1';
    } else if (screenIdx == 3) {
      prefKey = 'wb_onboard_packs_v1';
    } else {
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final alreadyShown = prefs.getBool(prefKey) ?? false;
      if (!alreadyShown && mounted) {
        await prefs.setBool(prefKey, true);
        if (mounted) {
          _showOnboardingModal(screenIdx);
        }
      }
    } catch (_) {}
  }

  void _showOnboardingModal(int screenIdx) {
    String icon = "🥳";
    String title = "";
    String step1 = "";
    String step2 = "";
    String step3 = "";
    Color accentColor = const Color(0xFF00F2FE);

    if (screenIdx == 1) {
      icon = "👥";
      accentColor = const Color(0xFF00F2FE);
      title = _loc(
        "HOW TO ADD PLAYERS?",
        "OYUNCULAR NASIL EKLENİR?",
        "SPIELER HINZUFÜGEN",
        "¿CÓMO AÑADIR JUGADORES?",
        "COMMENT AJOUTER DES JOUEURS ?",
        "КАК ДОБАВИТЬ ИГРОКОВ?",
      );
      step1 = _loc(
        "✍️ Type a player's name in the box and tap [+] to add them to the table.",
        "✍️ İsim kutusuna oyuncu adını yazıp [+] butonuna basarak masaya ekleyebilirsin.",
        "✍️ Gib einen Namen ein und tippe auf [+], um den Spieler hinzuzufügen.",
        "✍️ Escribe el nombre del jugador y toca [+] para añadirlo.",
        "✍️ Entrez le prénom du joueur et appuyez sur [+] pour l'ajouter.",
        "✍️ Введите имя игрока в поле и нажмите [+], чтобы добавить его за стол.",
      );
      step2 = _loc(
        "⚡ QUICK START TIP: Don't want to type names? Leave the box blank and just tap [+] repeatedly to add 'Player 1, Player 2...' in 1 second!",
        "⚡ HIZLI BAŞLATMA İPUCU: İsim yazmak istemiyor musun? Kutuyu boş bırakıp direkt [+] butonuna art arda basarak 'Oyuncu 1, Oyuncu 2...' diye anında oyuna başlayabilirsin!",
        "⚡ SCHNELLSTART: Keine Lust Namen einzutippen? Lass das Feld leer und tippe einfach auf [+], um sofort 'Spieler 1, Spieler 2...' hinzuzufügen!",
        "⚡ INICIO RÁPIDO: ¿No quieres escribir nombres? ¡Deja el cuadro vacío y toca [+] para añadir 'Jugador 1, Jugador 2...' al instante!",
        "⚡ DÉMARRAGE RAPIDE : Pas envie d'écrire ? Laissez le champ vide et appuyez sur [+] pour ajouter 'Joueur 1, Joueur 2...' instantanément !",
        "⚡ БЫСТРЫЙ СТАРТ: Не хотите вводить имена? Оставьте поле пустым и просто нажимайте [+], чтобы мгновенно добавить «Игрок 1, Игрок 2...»!",
      );
      step3 = _loc(
        "🥳 Tap the Emoji icon or any player card to pick your free Party Emoji & Neon Color!",
        "🥳 Sol taraftaki Emoji butonuna veya oyuncu kartlarına dokunarak ücretsiz Profil Emojini ve Neon Rengini seçebilirsin!",
        "🥳 Tippe auf das Emoji-Symbol oder eine Spielerkarte, um dein Party-Emoji & deine Neonfarbe zu wählen!",
        "🥳 ¡Toca el icono de Emoji o cualquier tarjeta para elegir tu Emoji de Fiesta y Color Neón gratis!",
        "🥳 Touchez l'icône Émoji ou la carte d'un joueur pour choisir votre Émoji et Couleur Néon !",
        "🥳 Нажмите на кнопку с эмодзи или карточку игрока, чтобы бесплатно выбрать эмодзи профиля и неоновый цвет!",
      );
    } else if (screenIdx == 2) {
      icon = "🍾";
      accentColor = const Color(0xFFFFCC00);
      title = _loc(
        "CHOOSE YOUR SPINNING OBJECT!",
        "DÖNECEK NESNENİ SEÇ!",
        "WÄHLE DEIN DREH-OBJEKT!",
        "¡ELIGE TU OBJETO GIRATORIO!",
        "CHOISIS TON OBJET TOURNANT !",
        "ВЫБЕРИТЕ ПРЕДМЕТ ДЛЯ ВРАЩЕНИЯ!",
      );
      step1 = _loc(
        "🌀 Pick the bottle or crazy party object that will spin and bend in the center of your screen!",
        "🌀 Oyun ekranının ortasında dönecek, esneyecek ve oyuncuları seçecek olan şişeni veya çılgın nesneni buradan seç!",
        "🌀 Wähle die Flasche oder das verrückte Party-Objekt, das sich in der Mitte des Bildschirms dreht!",
        "🌀 ¡Elige la botella o el objeto loco que girará en el centro de tu pantalla!",
        "🌀 Choisissez la bouteille ou l'objet fou qui tournera au centre de l'écran !",
        "🌀 Выберите бутылочку или безумный предмет, который будет крутиться в центре экрана!",
      );
      step2 = _loc(
        "🎬 Watch 1 short video to unlock fun objects like Squeaky Chicken, Wobbly Pickle, or Flying Slipper for your session!",
        "🎬 Bipleyen Tavuk, Sallanan Turşu veya Uçan Terlik gibi eğlenceli nesneleri tek bir kısa video ile hemen açabilirsin!",
        "🎬 Schau 1 kurzes Video, um Quietsche-Huhn, Wackel-Gurke oder Hausschuh freizuschalten!",
        "🎬 ¡Mira 1 video corto para desbloquear el Pollo Chillón, el Pepinillo o la Zapatilla Voladora!",
        "🎬 Regardez 1 courte vidéo pour débloquer le Poulet, le Cornichon ou la Pantoufle !",
        "🎬 Посмотрите 1 короткое видео, чтобы открыть Пищащую Курицу, Огурчик или Летающий Тапок!",
      );
      step3 = _loc(
        "👑 Unlock the prestigious Golden Champagne anytime with Wobbly VIP!",
        "👑 Prestijli Altın Şampanya şişesini ise VIP ile anında açabilirsin!",
        "👑 Schalte den Goldenen Champagner jederzeit mit Wobbly VIP frei!",
        "👑 ¡Desbloquea el prestigioso Champán Dorado con Wobbly VIP!",
        "👑 Débloquez le prestigieux Champagne Doré avec Wobbly VIP !",
        "👑 А роскошное Золотое Шампанское доступно с подпиской Wobbly VIP!",
      );
    } else if (screenIdx == 3) {
      icon = "🃏";
      accentColor = const Color(0xFFFF0844);
      title = _loc(
        "MIX & MATCH QUESTION PACKS!",
        "SORU PAKETLERİNİ SEÇ!",
        "FRAGENPAKETE KOMBINIEREN!",
        "¡ELIGE TUS PAQUETES DE PREGUNTAS!",
        "CHOISIS TES PACKS DE QUESTIONS !",
        "ВЫБЕРИТЕ НАБОРЫ ВОПРОСОВ!",
      );
      step1 = _loc(
        "✅ You can select 1 pack OR select multiple packs at the same time!",
        "✅ Buradan sadece 1 paketi VEYA istediğin kadar paketi aynı anda seçebilirsin!",
        "✅ Du kannst 1 Paket ODER beliebig viele Pakete gleichzeitig auswählen!",
        "✅ ¡Puedes elegir 1 paquete O seleccionar varios paquetes al mismo tiempo!",
        "✅ Vous pouvez sélectionner 1 seul pack OU plusieurs packs en même temps !",
        "✅ Вы можете выбрать 1 набор ИЛИ сразу несколько наборов одновременно!",
      );
      step2 = _loc(
        "🔥 All Truth & Dare questions inside your selected packs will be shuffled together during the game.",
        "🔥 Seçtiğin tüm paketlerin içindeki Doğruluk ve Cesaret soruları harmanlanarak oyun içinde karşına çıkacak.",
        "🔥 Alle Wahrheit- & Pflicht-Fragen deiner gewählten Pakete werden im Spiel gemischt.",
        "🔥 Todas las preguntas de Verdad y Reto de los paquetes elegidos se mezclarán en el juego.",
        "🔥 Toutes les questions Action & Vérité des packs choisis seront mélangées pendant la partie.",
        "🔥 Все вопросы Правды и Действия из выбранных вами наборов будут перемешаны в игре.",
      );
      step3 = _loc(
        "💡 You can also switch packs or bottles anytime mid-game from the bottom 'Profile' menu!",
        "💡 Oyun başladıktan sonra bile alt bardaki 'Profil' menüsünden paketleri ve şişeni anında değiştirebilirsin!",
        "💡 Du kannst Pakete und Flaschen auch jederzeit während des Spiels im 'Profil'-Menü wechseln!",
        "💡 ¡También puedes cambiar paquetes o botellas en medio del juego desde el menú 'Perfil'!",
        "💡 Vous pourrez aussi changer de pack ou de bouteille en pleine partie via le menu 'Profil' !",
        "💡 Вы также сможете менять наборы и бутылочки прямо во время игры через меню «Профиль»!",
      );
    }

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: const Color(0xFF0A1424),
        insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: BorderSide(color: accentColor, width: 2.5),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accentColor.withValues(alpha: 0.15),
                  border: Border.all(color: accentColor, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.35),
                      blurRadius: 16,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(icon, style: const TextStyle(fontSize: 32)),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: accentColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(step1, style: const TextStyle(color: Colors.white, fontSize: 13.5, height: 1.35)),
                    const SizedBox(height: 10),
                    Text(step2, style: const TextStyle(color: Color(0xFFFFCC00), fontSize: 13.5, fontWeight: FontWeight.w600, height: 1.35)),
                    const SizedBox(height: 10),
                    Text(step3, style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.35)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: accentColor == const Color(0xFFFF0844) ? Colors.white : Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(
                    _loc("GOT IT, LET'S GO! 🚀", "ANLADIM, BAŞLAYALIM! 🚀", "VERSTANDEN, LOS GEHT'S! 🚀", "¡ENTENDIDO, VAMOS! 🚀", "COMPRIS, C'EST PARTI ! 🚀", "ПОНЯТНО, ПОГНАЛИ! 🚀"),
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14.5, letterSpacing: 0.8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVipFeature(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFFFFCC00), size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
        const Icon(Icons.check_circle, color: Color(0xFF34C759), size: 18),
      ],
    );
  }

  // --- PLAYERS MANAGEMENT ---
  void _scrollColorPaletteToIndex(int index) {
    if (!_colorScrollController.hasClients) return;
    final maxScroll = _colorScrollController.position.maxScrollExtent;
    final targetOffset = (index * 40.0 - 80.0).clamp(0.0, maxScroll);
    _colorScrollController.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  void _addPlayer() {
    if (_players.length >= 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_loc(
            "Maximum 10 players!",
            "Maksimum 10 oyuncu!",
            "Maximal 10 Spieler!",
            "¡Máximo 10 jugadores!",
          )),
        ),
      );
      return;
    }

    String name = _nameController.text.trim();
    if (name.isEmpty) {
      int num = _players.length + 1;
      final prefix = _loc("Player", "Oyuncu", "Spieler", "Jugador");
      while (_players.any(
          (p) => p.name.toLowerCase() == "$prefix $num".toLowerCase())) {
        num++;
      }
      name = "$prefix $num";
    }

    final emojiToUse = _userPickedCustomEmoji
        ? _selectedEmoji
        : WobblyBottleAppGame.partyEmojis[
            _players.length % WobblyBottleAppGame.partyEmojis.length];

    setState(() {
      _players.add(Player(
        name: name,
        color: WobblyBottleAppGame.playerColors[_selectedColorIndex],
        emoji: emojiToUse,
      ));
      _nameController.clear();
      _selectedColorIndex =
          (_selectedColorIndex + 1) % WobblyBottleAppGame.playerColors.length;
      _userPickedCustomEmoji = false;
      _selectedEmoji = WobblyBottleAppGame.partyEmojis[
          _players.length % WobblyBottleAppGame.partyEmojis.length];
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollColorPaletteToIndex(_selectedColorIndex);
    });
  }

  void _openQuickEmojiPicker() {
    final activeColor = WobblyBottleAppGame.playerColors[_selectedColorIndex];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
          border: Border.all(color: activeColor, width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              _loc(
                "CHOOSE YOUR AVATAR EMOJI (FREE)",
                "PROFİL EMOJİNİ SEÇ (ÜCRETSİZ)",
                "WÄHLE DEIN EMOJI (GRATIS)",
                "ELIGE TU EMOJI (GRATIS)",
                "CHOISIS TON ÉMOJI (GRATUIT)",
                "ВЫБЕРИТЕ ЭМОДЗИ ПРОФИЛЯ (БЕСПЛАТНО)",
              ),
              style: const TextStyle(
                color: Color(0xFFFFCC00),
                fontSize: 15,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: WobblyBottleAppGame.partyEmojis.map((emoji) {
                final isSelected = _selectedEmoji == emoji;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedEmoji = emoji;
                      _userPickedCustomEmoji = true;
                    });
                    Navigator.pop(ctx);
                  },
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected
                          ? activeColor.withValues(alpha: 0.3)
                          : Colors.white.withValues(alpha: 0.06),
                      border: Border.all(
                        color: isSelected ? activeColor : Colors.white24,
                        width: isSelected ? 2.5 : 1,
                      ),
                    ),
                    child: Center(
                      child: Text(emoji, style: const TextStyle(fontSize: 23)),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _editPlayerDialog(int index) {
    if (index < 0 || index >= _players.length) return;
    final editController = TextEditingController(text: _players[index].name);
    editController.selection = TextSelection(
      baseOffset: 0,
      extentOffset: editController.text.length,
    );
    Color tempColor = _players[index].color;
    String tempEmoji = _players[index].emoji;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            void saveChanges() {
              String updatedName = editController.text.trim();
              if (updatedName.isEmpty) {
                updatedName = _players[index].name;
              }
              setState(() {
                _players[index] = Player(
                  name: updatedName,
                  color: tempColor,
                  emoji: tempEmoji,
                );
              });
              Navigator.of(dialogCtx).pop();
            }

            return Dialog(
              backgroundColor: const Color(0xFF0A1828),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: BorderSide(color: tempColor, width: 2.5),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 22.0, vertical: 24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(tempEmoji, style: const TextStyle(fontSize: 24)),
                        const SizedBox(width: 8),
                        Text(
                          _loc("EDIT PLAYER", "OYUNCUYU DÜZENLE",
                              "SPIELER BEARBEITEN", "EDITAR JUGADOR"),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: tempColor,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF051725),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: tempColor, width: 2),
                      ),
                      child: TextField(
                        controller: editController,
                        autofocus: true,
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                        decoration: InputDecoration(
                          hintText: _loc(
                              "Enter player name...",
                              "Oyuncu adı girin...",
                              "Spielername eingeben...",
                              "Nombre del jugador..."),
                          hintStyle: TextStyle(
                              color: Colors.white.withValues(alpha: 0.45)),
                          border: InputBorder.none,
                        ),
                        onSubmitted: (_) => saveChanges(),
                      ),
                    ),
                    const SizedBox(height: 14),
                    // Emoji Selector Row
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: [
                          for (final emoji in WobblyBottleAppGame.partyEmojis)
                            Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: GestureDetector(
                                onTap: () => setDialogState(() => tempEmoji = emoji),
                                child: Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: tempEmoji == emoji
                                        ? tempColor.withValues(alpha: 0.28)
                                        : Colors.white.withValues(alpha: 0.06),
                                    border: Border.all(
                                      color: tempEmoji == emoji ? tempColor : Colors.white24,
                                      width: tempEmoji == emoji ? 2.5 : 1,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(emoji, style: const TextStyle(fontSize: 19)),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    // Color Selector Row
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (int i = 0;
                              i < WobblyBottleAppGame.playerColors.length;
                              i++)
                            Padding(
                              padding: const EdgeInsets.only(right: 10.0),
                              child: GestureDetector(
                                onTap: () => setDialogState(() => tempColor =
                                    WobblyBottleAppGame.playerColors[i]),
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: WobblyBottleAppGame.playerColors[i],
                                    border: Border.all(
                                      color: tempColor ==
                                              WobblyBottleAppGame
                                                  .playerColors[i]
                                          ? Colors.white
                                          : Colors.transparent,
                                      width: 3,
                                    ),
                                    boxShadow: tempColor ==
                                            WobblyBottleAppGame.playerColors[i]
                                        ? [
                                            BoxShadow(
                                              color: WobblyBottleAppGame
                                                  .playerColors[i]
                                                  .withValues(alpha: 0.8),
                                              blurRadius: 10,
                                            )
                                          ]
                                        : null,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.of(dialogCtx).pop(),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: Text(
                              _loc("CANCEL", "İPTAL", "ABBRECHEN", "CANCELAR"),
                              style: const TextStyle(
                                color: Colors.white70,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: saveChanges,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: tempColor,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Text(
                              _loc("SAVE", "KAYDET", "SPEICHERN", "GUARDAR"),
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _removePlayer(int index) {
    setState(() {
      _players.removeAt(index);
    });
  }

  // --- BOTTLE SPIN & BEND ALGORITHM ---
  void _spinBottle() {
    if (!_isOnline) {
      _checkInternetConnectivity();
      return;
    }
    if (_isSpinning || _players.length < 2) return;

    final rand = math.Random();
    final rotations = 4 + rand.nextInt(3); // 4-6 full spins
    final randomTarget = rand.nextDouble() * 2 * math.pi;
    final startAngle = _currentAngle;
    final targetAngle = _currentAngle + (rotations * 2 * math.pi) + randomTarget;

    if (RoomService().isInRoom) {
      RoomService().spinBottle(
        startAngle: startAngle,
        targetAngle: targetAngle,
        bendVariant: "0",
        answererIndex: -1,
        questionerIndex: -1,
      );
    } else {
      setState(() {
        _isSpinning = true;
        _startAngle = startAngle;
        _targetAngle = targetAngle;
        _questionerIndex = -1;
        _answererIndex = -1;
        _currentBendVariant = "0";
      });

      _spinController.reset();
      _spinController.forward();
    }
  }

  void _onSpinFinished() {
    final count = _players.length;
    final rand = math.Random();

    // 1. Determine Questioner by nearest player at base of bottle
    final baseAngle = (_currentAngle + (math.pi / 2)) % (2 * math.pi);

    int nearestPlayer(double targetAngle) {
      double minDiff = double.infinity;
      int best = 0;
      for (int i = 0; i < count; i++) {
        final pAngle = (-math.pi / 2 + (i * 2 * math.pi / count)) % (2 * math.pi);
        double diff = (targetAngle - pAngle).abs();
        if (diff > math.pi) diff = (2 * math.pi) - diff;
        if (diff < minDiff) {
          minDiff = diff;
          best = i;
        }
      }
      return best;
    }

    final questioner = nearestPlayer(baseAngle);

    // 2. Pick Answerer (different from questioner)
    final List<int> candidates = [];
    for (int i = 0; i < count; i++) {
      if (i != questioner) candidates.add(i);
    }
    final answerer = candidates[rand.nextInt(candidates.length)];

    // 3. Align base with Questioner and neck with Answerer
    final basePlayerAngle = -math.pi / 2 + (questioner * 2 * math.pi / count);
    final oppositeAngle = basePlayerAngle + math.pi; // straight across from questioner
    final answererAngle = -math.pi / 2 + (answerer * 2 * math.pi / count);

    // 4. Calculate signed delta angle to Answerer
    double delta = (answererAngle - oppositeAngle) % (2 * math.pi);
    if (delta > math.pi) delta -= 2 * math.pi;
    if (delta < -math.pi) delta += 2 * math.pi;

    // 5. Select BEND SPRITE based on angle delta!
    String bendVariant = "0";
    if (delta < -0.15) {
      bendVariant = "l"; // Bends Left towards Answerer
    } else if (delta > 0.15) {
      bendVariant = "r"; // Bends Right towards Answerer
    } else {
      bendVariant = "0"; // Straight
    }

    // 6. Point neck directly at Answerer and base at Questioner!
    final finalBottleAngle = oppositeAngle + (math.pi / 2) + (delta * 0.35);

    setState(() {
      _isSpinning = false;
      _questionerIndex = questioner;
      _answererIndex = answerer;
      _currentAngle = finalBottleAngle;
      _currentBendVariant = bendVariant;
    });

    if (RoomService().isInRoom) {
      RoomService().syncSpinResult(
        angle: finalBottleAngle,
        bendVariant: bendVariant,
        answererIndex: answerer,
        questionerIndex: questioner,
      );
    }

    if (!RoomService().isInRoom) {
      // Show interstitial ad every 5 bottle spins in single device mode!
      _showInterstitialAdIfNeeded();
    }
  }

  // --- CARD & QUESTION PICKING ---
  void _showCard(String mode) {
    if (_players.isEmpty) return;
    if (_answererIndex < 0 || _answererIndex >= _players.length) {
      _answererIndex = 0;
    }
    if (_questionerIndex < 0 || _questionerIndex >= _players.length) {
      _questionerIndex = _players.length > 1 ? 1 : 0;
    }
    final targetName = _players[_answererIndex].name;
    final askerName = _players[_questionerIndex].name;

    String promptText = "";
    String cardTitle = "";

    if (mode == 'FREE') {
      cardTitle = _loc("FREE QUESTION", "SERBEST SORU", "FREIE FRAGE", "PREGUNTA LIBRE", "QUESTION LIBRE", "СВОБОДНЫЙ ВОПРОС");
      promptText = _loc(
        "$askerName asks any question or gives any challenge to $targetName!",
        "$askerName, $targetName adlı oyuncuya dilediği soruyu sorar veya meydan okur!",
        "$askerName stellt $targetName eine beliebige Frage!",
        "¡$askerName le hace cualquier pregunta o reto a $targetName!",
        "$askerName pose une question ou donne un défi à $targetName !",
        "$askerName задает вопрос veya дает задание игроку $targetName!",
      );
      if (RoomService().isInRoom) {
        RoomService().publishCard(
          mode: mode,
          packIndex: null,
          questionIndex: null,
          promptOverride: null, // Let each device localize the prompt in its own language
          answererIndex: _answererIndex,
          questionerIndex: _questionerIndex,
        );
        return;
      }
    } else {
      cardTitle = mode == 'TRUTH'
          ? _loc("TRUTH FOR $targetName", "$targetName İÇİN DOĞRULUK", "WAHRHEIT FÜR $targetName", "VERDAD PARA $targetName")
          : _loc("DARE FOR $targetName", "$targetName İÇİN CESARET", "PFLICHT FÜR $targetName", "RETO PARA $targetName");

      final List<Map<String, dynamic>> candidateCards = [];
      final langKey = _currentLangKey;
      int? pickedPackIdx;
      int? pickedQIdx;

      if (_questionsLoaded && _questionsDb.isNotEmpty) {
        final packKeys = ["pack0_party", "pack1_deep", "pack2_challenge", "pack3_flirt", "pack4_spicy"];
        for (int p = 0; p < packKeys.length; p++) {
          if (_selectedPacks[p] && _questionsDb.containsKey(packKeys[p])) {
            final list = _questionsDb[packKeys[p]] as List<dynamic>;
            for (int q = 0; q < list.length; q++) {
              final item = list[q];
              if (item is Map) {
                final itemType = item['type']?.toString().toUpperCase();
                // Strictly filter: TRUTH items only for TRUTH mode, DARE items only for DARE mode!
                if (itemType != null && itemType != mode) {
                  continue;
                }
                candidateCards.add({
                  'packIndex': p,
                  'questionIndex': q,
                  'text': item[langKey]?.toString() ?? item['TR']?.toString() ?? '',
                });
              }
            }
          }
        }
      }

      if (candidateCards.isNotEmpty) {
        // Smart Infinite Deck: filter out already used questions in this session
        var freshCards = candidateCards
            .where((c) => !_usedQuestionKeys.contains("${c['packIndex']}_${c['questionIndex']}"))
            .toList();

        // Reshuffle threshold: if 85%+ of deck is played or fresh pool exhausted, silently reset for infinite cycle
        if (freshCards.length <= (candidateCards.length * 0.15).ceil() || freshCards.isEmpty) {
          _usedQuestionKeys.clear();
          freshCards = List.from(candidateCards);
        }

        final rand = math.Random();
        final picked = freshCards[rand.nextInt(freshCards.length)];
        promptText = picked['text'] as String;
        pickedPackIdx = picked['packIndex'] as int;
        pickedQIdx = picked['questionIndex'] as int;

        _usedQuestionKeys.add('${pickedPackIdx}_$pickedQIdx');
      } else {
        promptText = mode == 'TRUTH'
            ? _loc("What is the most memorable party moment in your life?", "Hayatındaki en unutulmaz parti anın neydi?", "Was war dein verrücktester Partymoment?", "¿Cuál ha sido tu momento de fiesta más loco?")
            : _loc("Do your best 10-second funny dance right now!", "Şu an en komik dansını 10 saniye boyunca yap!", "Mache 10 Sekunden lang deinen lustigsten Tanz!", "¡Haz tu baile más divertido durante 10 segundos!");
      }

      if (RoomService().isInRoom) {
        RoomService().publishCard(
          mode: mode,
          packIndex: pickedPackIdx,
          questionIndex: pickedQIdx,
          promptOverride: null, // Let each device localize the exact question from its own database
          answererIndex: _answererIndex,
          questionerIndex: _questionerIndex,
        );
        return;
      }
    }

    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: const Color(0xFF0F172A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
            side: BorderSide(
              color: mode == 'TRUTH'
                  ? const Color(0xFF00F2FE)
                  : (mode == 'DARE' ? const Color(0xFFFF0844) : const Color(0xFFFFCC00)),
              width: 3,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 30.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  cardTitle,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: mode == 'TRUTH'
                        ? const Color(0xFF00F2FE)
                        : (mode == 'DARE' ? const Color(0xFFFF0844) : const Color(0xFFFFCC00)),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    promptText,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, height: 1.4),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00F2FE),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(
                    _loc("DONE / NEXT ROUND", "TAMAM / SIRADAKİ TUR", "FERTIG / NÄCHSTE RUNDE", "HECHO / SIGUIENTE RONDA"),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- HEADER CONTROLS ---
  Widget _buildHeaderControls() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Sound Mute Toggle
        GestureDetector(
          onTap: () => setState(() => isMuted = !isMuted),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF0A1828),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isMuted ? const Color(0xFFFF0844) : const Color(0xFF00F2FE),
                width: 2,
              ),
            ),
            child: Icon(
              isMuted ? Icons.volume_off : Icons.volume_up,
              color: isMuted ? const Color(0xFFFF0844) : const Color(0xFF00F2FE),
              size: 22,
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Language Dropdown
        PopupMenuButton<int>(
          onSelected: (idx) => setState(() => _currentLangIndex = idx),
          color: const Color(0xFF0A1828),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFFFCC00), width: 2),
          ),
          itemBuilder: (ctx) {
            return List.generate(WobblyBottleAppGame.langFlags.length, (idx) {
              final item = WobblyBottleAppGame.langFlags[idx];
              return PopupMenuItem<int>(
                value: idx,
                child: Row(
                  children: [
                    Text(item[0], style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 10),
                    Text(item[2], style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              );
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF0A1828),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFFFCC00), width: 2),
            ),
            child: Row(
              children: [
                Text(WobblyBottleAppGame.langFlags[_currentLangIndex][0], style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_drop_down, color: Color(0xFFFFCC00), size: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // =========================================================
  // SCREENS
  // =========================================================

  // SCREEN 0: 3-MODE SELECTION SCREEN (Masa Modu / Ev Partisi / Uzaktan Mod)
  Widget _buildSplashScreen() {
    return Padding(
      key: const ValueKey(0),
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Header: Logo + Controls (Mute, Language, VIP Profile)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Image.asset(
                'assets/wobbly_logo.png',
                height: 64,
                fit: BoxFit.contain,
              ),
              _buildHeaderControls(),
            ],
          ),
          const SizedBox(height: 12),

          // Dynamic Wobbling Bottles Showcase (Endless Animated Loop of 5 Objects)
          Center(
            child: Column(
              children: [
                WobblyBottleShowcase(
                  currentLangIndex: _currentLangIndex,
                ),
                const SizedBox(height: 8),
                Text(
                  _loc("CHOOSE GAME MODE", "OYUN MODUNU SEÇİN", "SPIELMODUS WÄHLEN", "ELIGE MODO DE JUEGO", "CHOISIR LE MODE DE JEU", "ВЫБЕРИТЕ РЕЖИМ ИГРЫ"),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF00F2FE),
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // 1. MASA MODU (Tek Telefon)
          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              children: [
                _buildModeCard(
                  icon: "🛋️",
                  title: _loc("TABLE MODE (SINGLE PHONE)", "MASA MODU (TEK TELEFON)", "TISCHMODUS (1 HANDY)", "MODO MESA (1 MÓVIL)", "MODE TABLE (1 TÉLÉPHONE)", "НА ОДНОМ ТЕЛЕФОНЕ (ЗА СТОЛОМ)"),
                  desc: _loc("Pass & play on a single phone. Place it in the center & spin!",
                             "Tek telefondan tüm masa oynar. Ortaya koyun ve sırayla çevirin!",
                             "Alle spielen an einem Handy. In die Mitte legen & drehen!",
                             "Todos juegan en un solo móvil. ¡Al centro y a girar!",
                             "Tous sur un seul téléphone. Posez-le au centre et tournez !",
                             "Играйте всей компанией на одном телефоне. Положите в центр и крутите!"),
                  accentColor: const Color(0xFF00F2FE),
                  onTap: () {
                    setState(() {
                      _activeGameMode = WobblyGameMode.table;
                      currentScreen = 1; // Setup screen
                    });
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _checkAndShowOnboarding(1);
                    });
                  },
                ),
                const SizedBox(height: 12),

                // 2. EV PARTİSİ (Aynı Odadayız)
                _buildModeCard(
                  icon: "🎉",
                  title: _loc("HOUSE PARTY (IN-PERSON)", "EV PARTİSİ (AYNI ODADAYIZ)", "HAUSPARTY (VOR ORT)", "FIESTA EN CASA", "SOIRÉE MAISON", "ДОМАШНЯЯ ВЕЧЕРИНКА (ВМЕСТЕ)"),
                  desc: _loc("Everyone joins on their own phone! Dares, kisses & close-contact fun!",
                             "Herkes kendi telefonuyla bağlansın! Yakın temas, flört ve çılgın cezalar havada uçuşsun!",
                             "Jeder tritt mit dem eigenen Handy bei! Aufgaben, Küsse & Spaß!",
                             "¡Cada uno con su móvil! ¡Retos, besos y diversión íntima!",
                             "Chacun rejoint avec son téléphone ! Gages, bisous et contacts intimes !",
                             "Каждый заходит со своего телефона! Задания, флирт и безумное веселье!"),
                  accentColor: const Color(0xFFFFCC00),
                  onTap: () {
                    setState(() {
                      _activeGameMode = WobblyGameMode.party;
                      currentScreen = 5; // RoomJoinScreen
                    });
                  },
                ),
                const SizedBox(height: 12),

                // 3. UZAKTAN MOD (Farklı Evlerdeyiz)
                _buildModeCard(
                  icon: "🌍",
                  title: _loc("REMOTE PARTY (ONLINE)", "UZAKTAN MOD (FARKLI EVLERDEYİZ)", "ONLINE-PARTY (REMOTE)", "FIESTA A DISTANCIA", "SOIRÉE À DISTANCE", "ОНЛАЙН-ВЕЧЕРИНКА (НА РАССТОЯНИИ)"),
                  desc: _loc("Play from different cities/homes! Live confessions, screenshots & photo dares!",
                             "Farklı evlerden / şehirlerden oynayın! Anlık ifşalar, fotoğraflar ve sırlar!",
                             "Online aus verschiedenen Städten! Screenshots, Fotos & Geheimnisse!",
                             "¡Juega a distancia! ¡Capturas de pantalla, fotos y secretos!",
                             "Jouez à distance ! Captures d'écran, photos et révélations en direct !",
                             "Играйте из разных домов и городов! Признания, скриншоты и фото-задания!"),
                  accentColor: const Color(0xFFFF0844),
                  onTap: () {
                    setState(() {
                      _activeGameMode = WobblyGameMode.remote;
                      currentScreen = 5; // RoomJoinScreen
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeCard({
    required String icon,
    required String title,
    required String desc,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: accentColor.withValues(alpha: 0.8), width: 2),
          boxShadow: [
            BoxShadow(
              color: accentColor.withValues(alpha: 0.25),
              blurRadius: 16,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: accentColor, width: 1.5),
              ),
              child: Center(
                child: Text(icon, style: const TextStyle(fontSize: 26)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: accentColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    desc,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11.5,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: accentColor, size: 16),
          ],
        ),
      ),
    );
  }

  // SCREEN 1: ADD PLAYERS (2-Column Grid matching Android, up to 10 Players)
  Widget _buildSetupScreen() {
    return Padding(
      key: const ValueKey(1),
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF00F2FE), size: 22),
                onPressed: () => setState(() => currentScreen = 0),
              ),
              Expanded(
                child: Center(
                  child: Image.asset(
                    'assets/wobbly_logo.png',
                    height: 54,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              _buildHeaderControls(),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Text(
                  _loc("ADD PLAYERS (MIN 2 - MAX 10)", "OYUNCU EKLE (MİN 2 - MAKS 10)", "SPIELER HINZUFÜGEN (2 - 10)", "AÑADIR JUGADORES (2 - 10)"),
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF00F2FE),
                    letterSpacing: 1.1,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => _showOnboardingModal(1),
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF00F2FE).withValues(alpha: 0.15),
                    border: Border.all(color: const Color(0xFF00F2FE), width: 1.5),
                  ),
                  child: const Center(
                    child: Icon(Icons.question_mark_rounded, color: Color(0xFF00F2FE), size: 17),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Player Input Field with Emoji Picker on Left + Yellow '+' on Right (works with or without typing a name)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF051725),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFF00F2FE), width: 2),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: _openQuickEmojiPicker,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: WobblyBottleAppGame.playerColors[_selectedColorIndex].withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: WobblyBottleAppGame.playerColors[_selectedColorIndex],
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_selectedEmoji, style: const TextStyle(fontSize: 20)),
                        const SizedBox(width: 2),
                        const Icon(Icons.arrow_drop_down, color: Colors.white70, size: 16),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      hintText: _loc("Enter name or tap + to quick add...", "İsim yazın veya hızlı eklemek için + basın...", "Name eingeben oder + tippen...", "Escribe nombre o toca +..."),
                      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13.5),
                      border: InputBorder.none,
                    ),
                    onSubmitted: (_) => _addPlayer(),
                  ),
                ),
                GestureDetector(
                  onTap: _addPlayer,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFCC00),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.add, color: Colors.black, size: 24),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Single-Row Horizontal Scrollable 10-Color Picker
          Row(
            children: [
              Text(
                _loc("PICK COLOR:", "RENK SEÇ:", "FARBE WÄHLEN:", "COLOR:"),
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white70),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SingleChildScrollView(
                  controller: _colorScrollController,
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                  child: Row(
                    children: [
                      for (int i = 0; i < WobblyBottleAppGame.playerColors.length; i++)
                        Padding(
                          padding: const EdgeInsets.only(right: 10.0),
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedColorIndex = i),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 160),
                              width: _selectedColorIndex == i ? 32 : 28,
                              height: _selectedColorIndex == i ? 32 : 28,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: WobblyBottleAppGame.playerColors[i],
                                border: Border.all(
                                  color: _selectedColorIndex == i ? Colors.white : Colors.transparent,
                                  width: 3,
                                ),
                                boxShadow: _selectedColorIndex == i
                                    ? [
                                        BoxShadow(
                                          color: WobblyBottleAppGame.playerColors[i].withValues(alpha: 0.85),
                                          blurRadius: 10,
                                          spreadRadius: 1,
                                        )
                                      ]
                                    : null,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Players List (2-column Grid matching Android, with Emoji + Pencil Edit + Remove icons)
          Expanded(
            child: _players.isEmpty
                ? Center(
                    child: Text(
                      _loc("No players added yet.\nAdd at least 2 players to start!", "Henüz oyuncu eklenmedi.\nBaşlamak için en az 2 oyuncu ekleyin!", "Noch keine Spieler hinzugefügt.", "Aún no hay jugadores añadidos."),
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 14),
                    ),
                  )
                : GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 10,
                      childAspectRatio: 2.35,
                    ),
                    itemCount: _players.length,
                    itemBuilder: (ctx, idx) {
                      final p = _players[idx];
                      return GestureDetector(
                        onTap: () => _editPlayerDialog(idx),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0A1828),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: p.color, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: p.color.withValues(alpha: 0.25),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: p.color.withValues(alpha: 0.22),
                                  border: Border.all(color: p.color, width: 1.5),
                                ),
                                child: Center(
                                  child: Text(p.emoji, style: const TextStyle(fontSize: 18)),
                                ),
                              ),
                              const SizedBox(width: 7),
                              Expanded(
                                child: Text(
                                  p.name,
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              GestureDetector(
                                onTap: () => _editPlayerDialog(idx),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  child: Icon(Icons.edit, color: p.color.withValues(alpha: 0.9), size: 17),
                                ),
                              ),
                              const SizedBox(width: 2),
                              GestureDetector(
                                onTap: () => _removePlayer(idx),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  child: const Icon(Icons.close, color: Colors.white54, size: 18),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // Continue Button
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFFFCC00), width: 2),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFCC00).withValues(alpha: 0.3),
                  blurRadius: 15,
                )
              ],
            ),
            child: ElevatedButton(
              onPressed: _players.length >= 2
                  ? () {
                      setState(() => currentScreen = 2);
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _checkAndShowOnboarding(2);
                      });
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF051725),
                foregroundColor: const Color(0xFFFFCC00),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    _loc("CONTINUE TO OBJECTS", "NESNELERE DEVAM ET", "WEITER ZU OBJEKTEN", "CONTINUAR A OBJETOS"),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "${_players.length} ${_loc("PLAYERS", "OYUNCU", "SPIELER", "JUGADORES")}",
                    style: const TextStyle(fontSize: 11, color: Color(0xFF00F2FE), fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // SCREEN 2: CHOOSE OBJECT (5 Horizontal Neon Cards matching Android)
  Widget _buildObjectsScreen() {
    return Padding(
      key: const ValueKey(2),
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        if (RoomService().isInRoom) {
                          if (RoomService().isHost) {
                            RoomService().setStatus(RoomStatus.lobby);
                          }
                          setState(() => currentScreen = 6);
                        } else {
                          setState(() => currentScreen = 1);
                        }
                      },
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0A1828),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFF00F2FE), width: 2),
                        ),
                        child: const Icon(Icons.arrow_back, color: Color(0xFF00F2FE), size: 22),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        _loc("CHOOSE YOUR OBJECT", "NESNENİ SEÇ", "WÄHLE DEIN OBJEKT", "ELIGE TU OBJETO"),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFFFFCC00),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _showOnboardingModal(2),
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFFFCC00).withValues(alpha: 0.15),
                          border: Border.all(color: const Color(0xFFFFCC00), width: 1.5),
                        ),
                        child: const Center(
                          child: Icon(Icons.question_mark_rounded, color: Color(0xFFFFCC00), size: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              _buildHeaderControls(),
            ],
          ),
          const SizedBox(height: 14),

          // 5 Horizontal Cards
          Expanded(
            child: ListView.builder(
              itemCount: 5,
              itemBuilder: (ctx, idx) {
                final isSelected = _selectedObjectIndex == idx;
                final isUnlocked = _unlockedObjects[idx] || (idx == 4 && _vip);
                final isVipItem = idx == 4;
                final objName = WobblyBottleAppGame.getObjectName(idx, _currentLangIndex);

                Color borderColor;
                if (isSelected) {
                  borderColor = const Color(0xFF34C759); // Green when selected
                } else if (isVipItem) {
                  borderColor = const Color(0xFFFFCC00); // Gold for VIP
                } else if (!isUnlocked) {
                  borderColor = const Color(0xFFBF4FFF); // Purple for Ad-locked
                } else {
                  borderColor = const Color(0xFF00F2FE); // Cyan for unlocked
                }

                return GestureDetector(
                  onTap: () {
                    if (RoomService().isInRoom && !RoomService().isHost) {
                      return; // Guest only watches host
                    }
                    if (isVipItem && !_vip) {
                      _openVipModal();
                    } else if (!isUnlocked) {
                      _startRewardedAd(idx);
                    } else {
                      setState(() => _selectedObjectIndex = idx);
                      if (RoomService().isInRoom && RoomService().isHost) {
                        RoomService().updateBottleObject(idx);
                      }
                    }
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A1828),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: borderColor, width: isSelected ? 3 : 2),
                      boxShadow: [
                        BoxShadow(
                          color: borderColor.withValues(alpha: isSelected ? 0.4 : 0.15),
                          blurRadius: isSelected ? 12 : 6,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Left: Tilted horizontal object preview
                        SizedBox(
                          width: 80,
                          height: 60,
                          child: Transform.rotate(
                            angle: -0.3,
                            child: Image.asset(
                              'assets/bent_${idx}_0.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),

                        // Center: Object name & status
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                objName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              if (isSelected)
                                Row(
                                  children: [
                                    const Icon(Icons.check, color: Color(0xFF34C759), size: 16),
                                    const SizedBox(width: 4),
                                    Text(
                                      _loc("SELECTED", "SEÇİLDİ", "AUSGEWÄHLT", "SELECCIONADO"),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFF34C759),
                                      ),
                                    ),
                                  ],
                                )
                              else if (!isUnlocked && isVipItem)
                                Row(
                                  children: [
                                    const Icon(Icons.workspace_premium, color: Color(0xFFFFCC00), size: 16),
                                    const SizedBox(width: 4),
                                    Text(
                                      "VIP",
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFFFFCC00),
                                      ),
                                    ),
                                  ],
                                )
                              else if (!isUnlocked)
                                Row(
                                  children: [
                                    const Icon(Icons.play_arrow, color: Color(0xFFFF9500), size: 16),
                                    const SizedBox(width: 4),
                                    Text(
                                      _loc("WATCH AD", "REKLAM İZLE", "WERBUNG SEHEN", "VER ANUNCIO"),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFFFF9500),
                                      ),
                                    ),
                                  ],
                                )
                              else
                                Text(
                                  _loc("UNLOCKED", "AÇILDI", "FREIGESCHALTET", "DESBLOQUEADO"),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF00F2FE),
                                  ),
                                ),
                            ],
                          ),
                        ),

                        // Right: Subtitle
                        if (!isUnlocked && isVipItem)
                          Text(
                            _loc("Unlock as VIP", "VIP ile Aç", "Als VIP öffnen", "Desbloquear VIP"),
                            style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.6)),
                          )
                        else if (!isUnlocked)
                          Text(
                            _loc("Unlock with 1 Video", "1 Reklamla Aç", "Mit 1 Video öffnen", "1 Anuncio"),
                            style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.6)),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Continue Button / Guest Waiting Banner
          if (RoomService().isInRoom && !RoomService().isHost)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF0A1828),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF00F2FE).withValues(alpha: 0.5)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(color: Color(0xFF00F2FE), strokeWidth: 2.5),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _loc("Host is choosing the bottle... ⏳", "Oda kurucusu şişeyi seçiyor... ⏳", "Host wählt die Flasche... ⏳", "El anfitrión elige el objeto... ⏳", "L'hôte choisit l'objet... ⏳", "Хост выбирает бутылочку... ⏳"),
                    style: const TextStyle(color: Color(0xFF00F2FE), fontWeight: FontWeight.bold, fontSize: 13.5),
                  ),
                ],
              ),
            )
          else
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFFFCC00), width: 2),
              ),
              child: ElevatedButton(
                onPressed: () {
                  if (RoomService().isInRoom) {
                    RoomService().proceedToPacks(selectedObjectIndex: _selectedObjectIndex);
                  }
                  setState(() => currentScreen = 3);
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _checkAndShowOnboarding(3);
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF051725),
                  foregroundColor: const Color(0xFFFFCC00),
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Text(
                  _loc("CONTINUE TO PACKS", "PAKETLERE DEVAM ET", "WEITER ZU PAKETEN", "CONTINUAR A PAQUETES"),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // SCREEN 3: CHOOSE PACKS (2x3 Grid with pack_sheet.png illustrations matching Android)
  Widget _buildPacksScreen() {
    return Padding(
      key: const ValueKey(3),
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        if (RoomService().isInRoom) {
                          if (RoomService().isHost) {
                            RoomService().setStatus(RoomStatus.objects);
                          }
                          setState(() => currentScreen = 2);
                        } else {
                          setState(() => currentScreen = 2);
                        }
                      },
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0A1828),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFF00F2FE), width: 2),
                        ),
                        child: const Icon(Icons.arrow_back, color: Color(0xFF00F2FE), size: 22),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        _loc("CHOOSE YOUR PACKS", "PAKETLERİNİ SEÇ", "WÄHLE DEINE PAKETE", "ELIGE TUS PAQUETES"),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFFFFCC00),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _showOnboardingModal(3),
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFFF0844).withValues(alpha: 0.15),
                          border: Border.all(color: const Color(0xFFFF0844), width: 1.5),
                        ),
                        child: const Center(
                          child: Icon(Icons.question_mark_rounded, color: Color(0xFFFF0844), size: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              _buildHeaderControls(),
            ],
          ),
          const SizedBox(height: 14),

          // 2x3 Grid of Packs with pack_sheet.png sliced illustrations
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.85,
              ),
              itemCount: 6,
              itemBuilder: (ctx, idx) {
                final isSel = _selectedPacks[idx];
                final isVipPack = idx == 4;
                final packName = WobblyBottleAppGame.getPackName(idx, _currentLangIndex);

                Color borderColor = isSel ? const Color(0xFFFFCC00) : const Color(0xFF1E293B);

                return GestureDetector(
                  onTap: () {
                    if (RoomService().isInRoom && !RoomService().isHost) {
                      return; // Guest only watches host
                    }
                    if (isVipPack && !_vip) {
                      _openVipModal();
                    } else {
                      setState(() {
                        _selectedPacks[idx] = !_selectedPacks[idx];
                        if (!_selectedPacks.contains(true)) {
                          _selectedPacks[idx] = true;
                        }
                      });
                      if (RoomService().isInRoom && RoomService().isHost) {
                        RoomService().updatePacks(_selectedPacks);
                      }
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A1828),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: borderColor, width: isSel ? 3 : 1.5),
                      boxShadow: isSel
                          ? [
                              BoxShadow(
                                color: const Color(0xFFFFCC00).withValues(alpha: 0.35),
                                blurRadius: 10,
                              )
                            ]
                          : null,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Sliced Pack Illustration
                        Expanded(
                          child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                            child: _packSheetImage != null
                                ? CustomPaint(
                                    painter: PackSpritePainter(_packSheetImage!, idx),
                                  )
                                : Container(
                                    color: Colors.black26,
                                    child: const Center(
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                  ),
                          ),
                        ),
                        // Pack Title Banner
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSel
                                ? const Color(0xFFFFCC00).withValues(alpha: 0.15)
                                : Colors.black.withValues(alpha: 0.4),
                            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(18)),
                          ),
                          child: Text(
                            packName,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: isSel ? const Color(0xFFFFCC00) : Colors.white70,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Start Game Button / Guest Waiting Banner
          if (RoomService().isInRoom && !RoomService().isHost)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF0A1828),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF00F2FE).withValues(alpha: 0.5)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(color: Color(0xFF00F2FE), strokeWidth: 2.5),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _loc("Host is choosing packs... ⏳", "Oda kurucusu paketleri seçiyor... ⏳", "Host wählt die Pakete... ⏳", "El anfitrión elige los paquetes... ⏳", "L'hôte choisit les packs... ⏳"),
                    style: const TextStyle(color: Color(0xFF00F2FE), fontWeight: FontWeight.bold, fontSize: 13.5),
                  ),
                ],
              ),
            )
          else
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFFFCC00), width: 2),
              ),
              child: ElevatedButton(
                onPressed: () {
                  if (RoomService().isInRoom) {
                    RoomService().proceedToArena(selectedPacks: _selectedPacks);
                    _startMultiplayerGame();
                  } else {
                    setState(() => currentScreen = 4);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF051725),
                  foregroundColor: const Color(0xFFFFCC00),
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Text(
                  _loc("START GAME", "OYUNU BAŞLAT", "SPIEL STARTEN", "INICIAR JUEGO"),
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // SCREEN 4: GAME ARENA (Connecting Ring, Glowing Players & Wobbly Bending Bottle)
  Widget _buildArenaScreen() {
    final count = _players.length;
    if (!_isSpinning && count >= 2) {
      if (_answererIndex < 0 || _answererIndex >= count) {
        _answererIndex = 0;
      }
      if (_questionerIndex < 0 || _questionerIndex >= count) {
        _questionerIndex = 1;
      }
    }

    return Padding(
      key: const ValueKey(4),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Column(
        children: [
          // Header Bar: Back Button + Enlarged Logo near back button + Spacer + Controls
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  if (RoomService().isInRoom) {
                    setState(() => currentScreen = 6); // Return to lobby
                  } else {
                    setState(() => currentScreen = 3);
                  }
                },
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A1828),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF00F2FE), width: 2),
                  ),
                  child: const Icon(Icons.arrow_back, color: Color(0xFF00F2FE), size: 22),
                ),
              ),
              const SizedBox(width: 10),
              Image.asset(
                'assets/wobbly_logo.png',
                height: 52,
                fit: BoxFit.contain,
              ),
              const Spacer(),
              _buildHeaderControls(),
            ],
          ),

          // Central Arena with Players in Circle & Bending Bottle
          Expanded(
            child: LayoutBuilder(
              builder: (ctx, constraints) {
                final center = Offset(constraints.maxWidth / 2, constraints.maxHeight / 2);
                final ringRadius = (math.min(constraints.maxWidth, constraints.maxHeight) / 2) - 55;

                return Stack(
                  alignment: Alignment.center,
                  children: [
                    // Circular connecting line
                    CustomPaint(
                      size: Size(constraints.maxWidth, constraints.maxHeight),
                      painter: RingLinePainter(center, ringRadius),
                    ),

                    // Players placed along ring
                    for (int i = 0; i < count; i++) ...[
                      () {
                        final pAngle = -math.pi / 2 + (i * 2 * math.pi / count);
                        final px = center.dx + ringRadius * math.cos(pAngle);
                        final py = center.dy + ringRadius * math.sin(pAngle);
                        final isQ = _questionerIndex == i;
                        final isA = _answererIndex == i;
                        final double avatarSize = count > 8 ? 44.0 : 52.0;
                        final double iconSize = count > 8 ? 26.0 : 32.0;

                        return Positioned(
                          left: px - 38,
                          top: py - (avatarSize / 2 + 6),
                          width: 76,
                          child: GestureDetector(
                            onTap: () {
                              if (RoomService().isInRoom) {
                                final roomPlayers = RoomService().currentRoom?.players ?? [];
                                if (i < roomPlayers.length) {
                                  final netP = roomPlayers[i];
                                  if (netP.id != RoomService().myPlayerId && !netP.isVip) {
                                    _openGiftVipModal(netP);
                                  }
                                }
                              } else {
                                _editPlayerDialog(i);
                              }
                            },
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Stack(
                                  clipBehavior: Clip.none,
                                  alignment: Alignment.center,
                                  children: [
                                    Container(
                                      width: avatarSize,
                                      height: avatarSize,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: _players[i].color.withValues(alpha: 0.28),
                                        border: Border.all(
                                          color: isA
                                              ? const Color(0xFFFF0844)
                                              : (isQ ? const Color(0xFF00F2FE) : _players[i].color),
                                          width: (isA || isQ) ? 4 : 2.5,
                                        ),
                                        boxShadow: (isA || isQ)
                                            ? [
                                                BoxShadow(
                                                  color: isA ? const Color(0xFFFF0844) : const Color(0xFF00F2FE),
                                                  blurRadius: 20,
                                                  spreadRadius: 6,
                                                )
                                              ]
                                            : [
                                                BoxShadow(
                                                  color: _players[i].color.withValues(alpha: 0.35),
                                                  blurRadius: 8,
                                                )
                                              ],
                                      ),
                                      child: Center(
                                        child: Text(
                                          _players[i].emoji,
                                          style: TextStyle(
                                            fontSize: iconSize * 0.85,
                                          ),
                                        ),
                                      ),
                                    ),
                                    // Floating Golden Crown: STRICTLY FOR VIP ONLY
                                    if (RoomService().isInRoom
                                        ? (i < (RoomService().currentRoom?.players.length ?? 0) &&
                                            RoomService().currentRoom!.players[i].isVip)
                                        : (_vip && i == 0))
                                      const Positioned(
                                        top: -13,
                                        child: Text(
                                          "👑",
                                          style: TextStyle(fontSize: 15),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  _players[i].name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: count > 8 ? 11.5 : 13,
                                    fontWeight: FontWeight.bold,
                                    color: isA
                                        ? const Color(0xFFFF0844)
                                        : (isQ ? const Color(0xFF00F2FE) : Colors.white),
                                  ),
                                ),
                                if (RoomService().isInRoom &&
                                    i < (RoomService().currentRoom?.players.length ?? 0)) ...[
                                  () {
                                    final p = RoomService().currentRoom!.players[i];
                                    String? badge;
                                    Color badgeColor = const Color(0xFF00F2FE);
                                    if (p.isHost && p.isVip) {
                                      badge = "VIP HOST";
                                      badgeColor = const Color(0xFFFFCC00);
                                    } else if (p.isHost) {
                                      badge = "HOST";
                                      badgeColor = const Color(0xFF00F2FE);
                                    } else if (p.isVip) {
                                      badge = "VIP";
                                      badgeColor = const Color(0xFFFFCC00);
                                    }
                                    if (badge == null) return const SizedBox.shrink();
                                    return Container(
                                      margin: const EdgeInsets.only(top: 2),
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: badgeColor.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(color: badgeColor, width: 0.8),
                                      ),
                                      child: Text(
                                        badge,
                                        style: TextStyle(
                                          fontSize: 8,
                                          fontWeight: FontWeight.w900,
                                          color: badgeColor,
                                        ),
                                      ),
                                    );
                                  }(),
                                ],
                              ],
                            ),
                          ),
                        );
                      }(),
                    ],

                    // CENTER WOBBLY BOTTLE
                    Positioned(
                      left: center.dx - 110,
                      top: center.dy - 110,
                      child: GestureDetector(
                        onTap: _isSpinning ? null : _spinBottle,
                        child: Transform.rotate(
                          angle: _currentAngle,
                          child: Container(
                            width: 220,
                            height: 220,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: (_selectedObjectIndex == 4
                                          ? const Color(0xFFFFCC00)
                                          : const Color(0xFF00F2FE))
                                      .withValues(alpha: _isSpinning ? 0.65 : 0.3),
                                  blurRadius: _isSpinning ? 40 : 20,
                                  spreadRadius: _isSpinning ? 10 : 4,
                                ),
                              ],
                            ),
                            child: Center(
                              child: Image.asset(
                                'assets/bent_${_selectedObjectIndex}_$_currentBendVariant.png',
                                width: 190,
                                height: 190,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // Bottom Control Panel: CONCEPT 4 HOLOGRAM NEON DECK
          Container(
            padding: const EdgeInsets.all(2.5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              gradient: const LinearGradient(
                colors: [Color(0xFFFF0844), Color(0xFFBF4FFF), Color(0xFF00F2FE)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFBF4FFF).withValues(alpha: 0.35),
                  blurRadius: 16,
                  spreadRadius: 1,
                ),
                BoxShadow(
                  color: const Color(0xFF00F2FE).withValues(alpha: 0.25),
                  blurRadius: 12,
                ),
              ],
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF060D1A),
                borderRadius: BorderRadius.circular(23.5),
                border: Border.all(
                  color: const Color(0xFF00F2FE).withValues(alpha: 0.75),
                  width: 1.5,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_answererIndex >= 0 && _questionerIndex >= 0 && !_isSpinning) ...[
                    if (RoomService().isInRoom &&
                        _answererIndex < _players.length &&
                        _players[_answererIndex].name != RoomService().myPlayerName) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(color: Color(0xFF00F2FE), strokeWidth: 2),
                            ),
                            const SizedBox(width: 10),
                            Flexible(
                              child: Text(
                                "${_players[_answererIndex].emoji} ${_players[_answererIndex].name} ${_loc("is choosing Truth or Dare... ⏳", "Doğruluk veya Cesaret seçiyor... ⏳", "wählt Wahrheit oder Pflicht... ⏳", "está eligiendo Verdad o Reto... ⏳", "choisit Vérité ou Défi... ⏳", "выбирает Правду или Действие... ⏳")}",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFF00F2FE),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      // Top Matchup Header: [SORAN] ──⚡──► [CEVAPLAYAN]
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                              decoration: BoxDecoration(
                                color: const Color(0xFF00F2FE).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFF00F2FE), width: 1.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF00F2FE).withValues(alpha: 0.25),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(_players[_questionerIndex].emoji, style: const TextStyle(fontSize: 13)),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      "${_loc("ASKER", "SORAN", "FRAGER", "PREGUNTA", "POSEUR", "ВОПРОС")}: ${_players[_questionerIndex].name.toUpperCase()}",
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFF00F2FE),
                                        letterSpacing: 0.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6.0),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 10,
                                  height: 2,
                                  color: const Color(0xFF00F2FE),
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 2.0),
                                  child: Icon(Icons.bolt_rounded, color: Color(0xFFFFCC00), size: 18),
                                ),
                                const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFFFF0844), size: 12),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF0844).withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFFFF0844), width: 1.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFFF0844).withValues(alpha: 0.25),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(_players[_answererIndex].emoji, style: const TextStyle(fontSize: 13)),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      "${_loc("TARGET", "CEVAPLAYAN", "ANTWORT", "RESPONDE", "CIBLE", "ОТВЕТ")}: ${_players[_answererIndex].name.toUpperCase()}",
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFFFF0844),
                                        letterSpacing: 0.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Middle Row: 3 Hologram Neon Icon Cards (DOĞRULUK | CESARET | ÖZEL)
                      Row(
                        children: [
                          // 1. DOĞRULUK (Cyan Neon Card with Eye Icon)
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _showCard('TRUTH'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      const Color(0xFF00F2FE).withValues(alpha: 0.20),
                                      const Color(0xFF071426),
                                    ],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: const Color(0xFF00F2FE), width: 2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF00F2FE).withValues(alpha: 0.35),
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.remove_red_eye_outlined,
                                      color: Color(0xFF00F2FE),
                                      size: 22,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _loc("TRUTH", "DOĞRULUK", "WAHRHEIT", "VERDAD", "VÉRITÉ", "ПРАВДА"),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 12,
                                        letterSpacing: 0.6,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),

                          // 2. CESARET (Magenta/Pink Neon Card with Flame Icon)
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _showCard('DARE'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      const Color(0xFFFF0844).withValues(alpha: 0.24),
                                      const Color(0xFF1F0818),
                                    ],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: const Color(0xFFFF0844), width: 2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFFF0844).withValues(alpha: 0.38),
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.local_fire_department_rounded,
                                      color: Color(0xFFFF0844),
                                      size: 22,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _loc("DARE", "CESARET", "PFLICHT", "RETO", "ACTION", "ДЕЙСТВИЕ"),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 12,
                                        letterSpacing: 0.6,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),

                          // 3. ÖZEL (Gold Neon Card with Star Icon)
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _showCard('FREE'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      const Color(0xFFFFCC00).withValues(alpha: 0.22),
                                      const Color(0xFF1F1806),
                                    ],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: const Color(0xFFFFCC00), width: 2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFFFCC00).withValues(alpha: 0.35),
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.star_border_rounded,
                                      color: Color(0xFFFFCC00),
                                      size: 22,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _loc("CUSTOM", "ÖZEL", "EIGENE", "PROPIO", "LIBRE", "ОСОБЫЙ"),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 12,
                                        letterSpacing: 0.6,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 9),
                    ],
                  ],

                  // Bottom Row: Wide Double-Neon Pill Button (ŞİŞEYİ ÇEVİR!)
                  GestureDetector(
                    onTap: _isSpinning ? null : _spinBottle,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: _isSpinning
                              ? [const Color(0xFF475569), const Color(0xFF334155)]
                              : [const Color(0xFFFFDC46), const Color(0xFFFF9500)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: _isSpinning ? Colors.white24 : const Color(0xFF00F2FE),
                          width: 2,
                        ),
                        boxShadow: _isSpinning
                            ? null
                            : [
                                BoxShadow(
                                  color: const Color(0xFFFFCC00).withValues(alpha: 0.45),
                                  blurRadius: 14,
                                  spreadRadius: 1,
                                ),
                                BoxShadow(
                                  color: const Color(0xFF00F2FE).withValues(alpha: 0.30),
                                  blurRadius: 8,
                                ),
                              ],
                      ),
                      child: Center(
                        child: Text(
                          _isSpinning
                              ? _loc("WOBBLING...", "DÖNÜYOR...", "DREHT SICH...", "GIRANDO...", "ÇA TOURNE...", "КРУТИТСЯ...")
                              : _loc("SPIN BOTTLE!", "ŞİŞEYİ ÇEVİR!", "FLASCHE DREHEN!", "¡GIRAR BOTELLA!", "TOURNER LA BOUTEILLE !", "КРУТИТЬ БУТЫЛОЧКУ!"),
                          style: TextStyle(
                            fontSize: 16.5,
                            fontWeight: FontWeight.w900,
                            color: _isSpinning ? Colors.white70 : Colors.black,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Unified Wide Bottom Navigation Bar (Home & Profile/VIP)
          Container(
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFF0A1828),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF00F2FE).withValues(alpha: 0.6),
                width: 1.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00F2FE).withValues(alpha: 0.2),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Row(
              children: [
                // HOME Section
                Expanded(
                  child: InkWell(
                    borderRadius: const BorderRadius.horizontal(left: Radius.circular(18)),
                    onTap: () async {
                      if (RoomService().isInRoom) {
                        await RoomService().leaveRoom();
                      }
                      setState(() => currentScreen = 0);
                    },
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.home_rounded, color: Color(0xFF00F2FE), size: 24),
                          const SizedBox(width: 8),
                          Text(
                            _loc("HOME", "ANA SAYFA", "START", "INICIO", "ACCUEIL"),
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Sleek Vertical Divider
                Container(
                  width: 1.5,
                  height: 28,
                  color: Colors.white.withValues(alpha: 0.2),
                ),

                // PROFILE / VIP Section
                Expanded(
                  child: InkWell(
                    borderRadius: const BorderRadius.horizontal(right: Radius.circular(18)),
                    onTap: () => setState(() => _profileDrawerOpen = true),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.workspace_premium_rounded, color: Color(0xFFFFCC00), size: 24),
                          const SizedBox(width: 8),
                          Text(
                            _loc("PROFILE", "PROFİL", "PROFIL", "PERFIL", "PROFIL"),
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFFFFCC00),
                              letterSpacing: 1.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // RIGHT-SIDE SLIDE-OVER PROFILE / VIP QUICK DRAWER (Matches GameView.java drawProfile)
  Widget _buildProfileDrawer() {
    return Positioned.fill(
      child: Row(
        children: [
          // Left translucent backdrop (tapping closes the panel)
          Expanded(
            flex: 22,
            child: GestureDetector(
              onTap: () => setState(() => _profileDrawerOpen = false),
              child: Container(
                color: Colors.black.withValues(alpha: 0.75),
              ),
            ),
          ),

          // Right Slide-Over Panel (VIP Card + Instant Bottle Switcher + Active Packs)
          Expanded(
            flex: 78,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0A0B20), Color(0xFF041522)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                border: Border(
                  left: BorderSide(color: Color(0xFF00F2FE), width: 2),
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Drawer Header: Close Button + PROFILE Title
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => setState(() => _profileDrawerOpen = false),
                            child: Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white38, width: 1.5),
                              ),
                              child: const Icon(Icons.close, color: Colors.white, size: 22),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              _loc("PROFILE", "PROFİL", "PROFIL", "PERFIL"),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFF00F2FE),
                                letterSpacing: 1.5,
                                shadows: [
                                  Shadow(
                                    color: const Color(0xFF00F2FE).withValues(alpha: 0.65),
                                    blurRadius: 12,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 38),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // 1. TOP: VIP Activation Card
                      GestureDetector(
                        onTap: _openVipModal,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xE62D1E05),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFFFCC00), width: 2.5),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFFCC00).withValues(alpha: 0.35),
                                blurRadius: 14,
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Text(
                                _vip
                                    ? _loc("♛ VIP MEMBER", "♛ VIP ÜYE", "♛ VIP MITGLIED", "♛ MIEMBRO VIP")
                                    : _loc("♛ GO VIP", "♛ VIP OL", "♛ VIP WERDEN", "♛ SER VIP"),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFFFFDC46),
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _vip
                                    ? _loc(
                                        "All premium content is unlocked",
                                        "Tüm premium içerikler açık",
                                        "Alle Premium-Inhalte freigeschaltet",
                                        "Todo el contenido premium desbloqueado",
                                      )
                                    : _loc(
                                        "Unlock Golden Champagne + Spicy pack",
                                        "Altın Şampanya + +18 Baharatlı paketi aç",
                                        "Goldener Champagner + Spicy-Paket freischalten",
                                        "Desbloquea Champán Dorado + Paquete Picante",
                                      ),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFCC00).withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  _vip
                                      ? _loc("ACTIVE", "AKTİF", "AKTIV", "ACTIVO")
                                      : _loc("VIEW OFFER", "TEKLİFİ GÖR", "ANGEBOT SEHEN", "VER OFERTA"),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFFFFDC46),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // 2. MIDDLE: Instant Bottle / Object Switching
                      Text(
                        _loc("CHANGE OBJECT NOW", "ŞİMDİ NESNE DEĞİŞTİR", "OBJEKT JETZT ÄNDERN", "CAMBIAR OBJETO AHORA"),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 8),

                      Expanded(
                        flex: 56,
                        child: ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          itemCount: 5,
                          itemBuilder: (ctx, i) {
                            final available = _unlockedObjects[i] || (i == 4 && _vip);
                            final isSelected = _selectedObjectIndex == i;
                            final Color borderColor = isSelected
                                ? const Color(0xFF50FF8C)
                                : (i == 4 ? const Color(0xFFFFCC00) : const Color(0xFF824EBE));

                            final String statusLabel = available
                                ? (isSelected
                                    ? _loc("SELECTED", "SEÇİLDİ", "AUSGEWÄHLT", "SELECCIONADO")
                                    : _loc("CHOOSE", "SEÇ", "WÄHLEN", "ELEGIR"))
                                : (i == 4 ? "VIP" : _loc("AD", "REKLAM", "WERBUNG", "ANUNCIO"));

                            return GestureDetector(
                              onTap: () {
                                if (i == 4 && !_vip) {
                                  _openVipModal();
                                } else if (!_unlockedObjects[i]) {
                                  _startRewardedAd(i);
                                } else {
                                  setState(() {
                                    _selectedObjectIndex = i;
                                  });
                                  if (RoomService().isInRoom && RoomService().isHost) {
                                    RoomService().updateBottleObject(i);
                                  }
                                }
                              },
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 7),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xBE0C1222),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: borderColor,
                                    width: isSelected ? 2.5 : 1.5,
                                  ),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: borderColor.withValues(alpha: 0.3),
                                            blurRadius: 8,
                                          )
                                        ]
                                      : null,
                                ),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 44,
                                      height: 36,
                                      child: Transform.rotate(
                                        angle: -0.25,
                                        child: Image.asset(
                                          'assets/bent_${i}_0.png',
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        WobblyBottleAppGame.getObjectName(i, _currentLangIndex),
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      statusLabel,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w900,
                                        color: borderColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 6),

                      // 3. BOTTOM: Active Packs 2x3 Quick Toggle Grid
                      Text(
                        _loc("ACTIVE PACKS", "AKTİF PAKETLER", "AKTIVE PAKETE", "PAQUETES ACTIVOS"),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 8),

                      Expanded(
                        flex: 36,
                        child: GridView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                            childAspectRatio: 2.55,
                          ),
                          itemCount: 6,
                          itemBuilder: (ctx, i) {
                            final isSel = _selectedPacks[i];
                            final isVipPack = i == 4 && !_vip;
                            final borderColor = isSel
                                ? const Color(0xFFFFCC00)
                                : const Color(0xFF37465F);

                            return GestureDetector(
                              onTap: () {
                                if (isVipPack) {
                                  _openVipModal();
                                } else {
                                  setState(() {
                                    _selectedPacks[i] = !_selectedPacks[i];
                                    if (!_selectedPacks.contains(true)) {
                                      _selectedPacks[i] = true;
                                    }
                                  });
                                  if (RoomService().isInRoom && RoomService().isHost) {
                                    RoomService().updatePacks(_selectedPacks);
                                  }
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xD20B101E),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: borderColor,
                                    width: isSel ? 2.2 : 1.2,
                                  ),
                                  boxShadow: isSel
                                      ? [
                                          BoxShadow(
                                            color: const Color(0xFFFFCC00).withValues(alpha: 0.25),
                                            blurRadius: 6,
                                          )
                                        ]
                                      : null,
                                ),
                                child: Center(
                                  child: Text(
                                    isVipPack
                                        ? "♛ ${WobblyBottleAppGame.getPackName(i, _currentLangIndex)}"
                                        : WobblyBottleAppGame.getPackName(i, _currentLangIndex),
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w900,
                                      color: isSel ? const Color(0xFFFFCC00) : Colors.white70,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // MANDATORY ONLINE CHECK OVERLAY (Matches GameView.java drawOffline)
  Widget _buildOfflineOverlay() {
    return Positioned.fill(
      child: AbsorbPointer(
        absorbing: true,
        child: Container(
          color: const Color(0xF50A0A14),
          padding: const EdgeInsets.symmetric(horizontal: 28.0),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFFF0055).withValues(alpha: 0.15),
                    border:
                        Border.all(color: const Color(0xFFFF0055), width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF0055).withValues(alpha: 0.45),
                        blurRadius: 25,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.wifi_off_rounded,
                      size: 56,
                      color: Color(0xFFFF0055),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  _loc("NO CONNECTION", "BAĞLANTI YOK", "KEINE VERBINDUNG",
                      "SIN CONEXIÓN"),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFFFF0055),
                    letterSpacing: 2.0,
                    shadows: [
                      Shadow(
                        color: const Color(0xFFFF0055).withValues(alpha: 0.6),
                        blurRadius: 15,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _loc(
                    "Wobbly Bottle requires an active internet connection.",
                    "Wobbly Bottle aktif bir internet bağlantısı gerektirir.",
                    "Wobbly Bottle erfordert eine aktive Internetverbindung.",
                    "Wobbly Bottle requiere una conexión activa a Internet.",
                  ),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _loc(
                    "Connect to Wi-Fi or mobile data to continue.",
                    "Devam etmek için Wi-Fi veya mobil veriye bağlanın.",
                    "Mit WLAN oder mobilen Daten verbinden, um fortzufahren.",
                    "Conéctate a Wi-Fi o datos móviles para continuar.",
                  ),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFFAAAAAA),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 32),
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A2E),
                    borderRadius: BorderRadius.circular(22),
                    border:
                        Border.all(color: const Color(0xFFFF0055), width: 2),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Color(0xFFFF0055),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Text(
                        _loc("WAITING FOR NETWORK...", "AĞ BEKLENİYOR...",
                            "WARTE AUF NETZWERK...", "ESPERANDO RED..."),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _initMultiplayerListener() {
    final rs = RoomService();
    rs.onToast = (msg) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: const Color(0xFF00F2FE),
          behavior: SnackBarBehavior.floating,
        ),
      );
    };

    rs.onRequestGiftPurchase = (player) {
      if (!mounted) return;
      _openGiftVipModal(player);
    };

    rs.onVipGifted = (senderName, recipientId, recipientName, isLifetime) {
      if (!mounted) return;
      final isForMe = recipientId == rs.myPlayerId;
      if (isForMe) {
        _activateVip(permanent: isLifetime);
      }
      _showVipGiftCelebrationDialog(
        senderName: senderName,
        recipientName: recipientName,
        isForMe: isForMe,
      );
    };

    rs.onKicked = (reason) {
      if (!mounted) return;
      setState(() => currentScreen = 0);
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF0F172A),
          title: Text(_loc("Notice", "Bilgi", "Hinweis", "Aviso", "Information", "Уведомление")),
          content: Text(reason),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("OK", style: TextStyle(color: Color(0xFF00F2FE))),
            ),
          ],
        ),
      );
    };

    _multiplayerSub = rs.roomStateStream.listen((room) {
      if (!mounted) return;

      // Sync player emojis & names if in Arena
      if (rs.isInRoom && _players.length == room.players.length) {
        for (int i = 0; i < room.players.length; i++) {
          if (_players[i].emoji != room.players[i].emoji ||
              _players[i].name != room.players[i].name) {
            setState(() {
              _players[i] = Player(
                name: room.players[i].name,
                color: room.players[i].color,
                emoji: room.players[i].emoji,
              );
            });
          }
        }
      }

      // Sync settings to client
      if (rs.isInRoom && !rs.isHost) {
        if (_selectedObjectIndex != room.selectedObjectIndex) {
          setState(() => _selectedObjectIndex = room.selectedObjectIndex);
        }
        bool packsDiff = false;
        if (_selectedPacks.length == room.selectedPacks.length) {
          for (int i = 0; i < _selectedPacks.length; i++) {
            if (_selectedPacks[i] != room.selectedPacks[i]) {
              packsDiff = true;
              break;
            }
          }
        } else {
          packsDiff = true;
        }
        if (packsDiff) {
          setState(() {
            _selectedPacks.clear();
            _selectedPacks.addAll(room.selectedPacks);
          });
        }
      }

      // Synchronized Screen Transitions
      if (rs.isInRoom) {
        if (room.status == RoomStatus.lobby && currentScreen != 6 && currentScreen != 5) {
          setState(() => currentScreen = 6);
        } else if (room.status == RoomStatus.objects && currentScreen != 2) {
          setState(() => currentScreen = 2);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _checkAndShowOnboarding(2);
          });
        } else if (room.status == RoomStatus.packs && currentScreen != 3) {
          setState(() => currentScreen = 3);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _checkAndShowOnboarding(3);
          });
        } else if (room.status != RoomStatus.lobby &&
                   room.status != RoomStatus.objects &&
                   room.status != RoomStatus.packs &&
                   currentScreen != 4) {
          _startMultiplayerGame();
        }
      }

      if (currentScreen == 4 && rs.isInRoom) {
        if (room.status != RoomStatus.cardOpen && _activeSyncedCardCtx != null) {
          if (_activeSyncedCardCtx!.mounted && Navigator.of(_activeSyncedCardCtx!).canPop()) {
            Navigator.of(_activeSyncedCardCtx!).pop();
          }
          _activeSyncedCardCtx = null;
        }
        if (room.status == RoomStatus.spinning && !_isSpinning) {
          setState(() {
            _isSpinning = true;
            _startAngle = room.currentAngle;
            _targetAngle = room.targetAngle;
            _questionerIndex = room.questionerIndex;
            _answererIndex = room.answererIndex;
            _currentBendVariant = room.bendVariant;
          });
          _spinController.reset();
          _spinController.forward();
        } else if (room.status == RoomStatus.decisionPending) {
          setState(() {
            _isSpinning = false;
            if (room.answererIndex >= 0) _answererIndex = room.answererIndex;
            if (room.questionerIndex >= 0) _questionerIndex = room.questionerIndex;
            if (room.targetAngle != 0) _currentAngle = room.targetAngle;
            _currentBendVariant = room.bendVariant;
          });
        } else if (room.status == RoomStatus.cardOpen && room.activeMode != null) {
          _showSyncedMultiplayerCard(room);
        } else if (room.status == RoomStatus.adBreak) {
          _showSyncedAdBreak(room);
        }
      }
    });
  }

  void _startMultiplayerGame() {
    final room = RoomService().currentRoom;
    if (room == null || room.players.length < 2) return;

    setState(() {
      _players.clear();
      for (var p in room.players) {
        _players.add(Player(name: p.name, color: p.color, emoji: p.emoji));
      }
      _selectedPacks.clear();
      _selectedPacks.addAll(room.selectedPacks);
      _selectedObjectIndex = room.selectedObjectIndex;
      currentScreen = 4; // Arena
    });
  }

  void _showSyncedMultiplayerCard(RoomState room) {
    if (_players.isEmpty && room.players.isNotEmpty) {
      for (var p in room.players) {
        _players.add(Player(name: p.name, color: p.color, emoji: p.emoji));
      }
    }
    int ansIdx = room.answererIndex;
    if (ansIdx < 0 || ansIdx >= _players.length) {
      ansIdx = (_answererIndex >= 0 && _answererIndex < _players.length) ? _answererIndex : 0;
    }
    int askIdx = room.questionerIndex;
    if (askIdx < 0 || askIdx >= _players.length) {
      askIdx = (_questionerIndex >= 0 && _questionerIndex < _players.length) ? _questionerIndex : 0;
    }
    final targetName = _players.isNotEmpty ? _players[ansIdx].name : "Player";
    final askerName = _players.isNotEmpty ? _players[askIdx].name : "Player";
    final isMe = _players.isNotEmpty &&
        _players[ansIdx].name == RoomService().myPlayerName;
    final mode = room.activeMode ?? 'TRUTH';

    String cardTitle = mode == 'TRUTH'
        ? _loc("TRUTH FOR $targetName", "$targetName İÇİN DOĞRULUK", "WAHRHEIT FÜR $targetName", "VERDAD PARA $targetName", "VÉRITÉ POUR $targetName", "ПРАВДА ДЛЯ $targetName")
        : (mode == 'DARE'
            ? _loc("DARE FOR $targetName", "$targetName İÇİN CESARET", "PFLICHT FÜR $targetName", "RETO PARA $targetName", "DÉFI POUR $targetName", "ДЕЙСТВИЕ ДЛЯ $targetName")
            : _loc("FREE QUESTION FOR $targetName", "$targetName İÇİN SERBEST SORU", "FREIE FRAGE FÜR $targetName", "PREGUNTA LIBRE PARA $targetName", "QUESTION LIBRE POUR $targetName", "СВОБОДНЫЙ ВОПРОС ДЛЯ $targetName"));

    String promptText = "";

    // 1. Fetch from questions database in THIS device's own selected language
    if (room.activePackIndex != null &&
        room.activeQuestionIndex != null &&
        _questionsLoaded) {
      _usedQuestionKeys.add("${room.activePackIndex}_${room.activeQuestionIndex}");
      final packKeys = ["pack0_party", "pack1_deep", "pack2_challenge", "pack3_flirt", "pack4_spicy"];
      if (room.activePackIndex! >= 0 && room.activePackIndex! < packKeys.length) {
        final list = _questionsDb[packKeys[room.activePackIndex!]] as List<dynamic>?;
        if (list != null && room.activeQuestionIndex! < list.length) {
          final item = list[room.activeQuestionIndex!] as Map<String, dynamic>;
          promptText = item[_currentLangKey]?.toString() ??
              item['EN']?.toString() ??
              item['TR']?.toString() ??
              "";
        }
      }
    }

    // 2. If FREE mode, format prompt dynamically in THIS device's own language
    if (promptText.isEmpty && mode == 'FREE') {
      promptText = _loc(
        "$askerName asks any question or gives any challenge to $targetName!",
        "$askerName, $targetName adlı oyuncuya dilediği soruyu sorar veya meydan okur!",
        "$askerName stellt $targetName eine beliebige Frage!",
        "¡$askerName le hace cualquier pregunta o reto a $targetName!",
        "$askerName pose une question ou donne un défi à $targetName !",
        "$askerName задает любой вопрос или дает задание игроку $targetName!",
      );
    }

    // 3. Fallback to activePromptOverride if non-empty
    if (promptText.isEmpty && room.activePromptOverride != null && room.activePromptOverride!.isNotEmpty) {
      promptText = room.activePromptOverride!;
    }

    // 4. Ultimate fallback in local device language
    if (promptText.isEmpty) {
      promptText = mode == 'TRUTH'
          ? _loc("What is your biggest secret in this room?", "Bu odadaki en büyük sırrın nedir?", "Was ist dein größtes Geheimnis?", "¿Cuál es tu mayor secreto?", "Quel est ton plus grand secret ?", "Какой твой самый большой секрет в этой комнате?")
          : _loc("Complete the dare or face the group's penalty!", "Görevi tamamla veya grubun verdiği cezayı çek!", "Erfülle die Aufgabe oder trage die Strafe der Gruppe!", "¡Cumple el reto o acepta el castigo del grupo!", "Fais le gage ou accepte la punition du groupe !", "Выполни задание или прими штраф от группы!");
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        _activeSyncedCardCtx = ctx;
        return Dialog(
          backgroundColor: const Color(0xFF0F172A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
            side: BorderSide(
              color: mode == 'TRUTH'
                  ? const Color(0xFF00F2FE)
                  : (mode == 'DARE' ? const Color(0xFFFF0844) : const Color(0xFFFFCC00)),
              width: 3,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 26.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  cardTitle,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: mode == 'TRUTH'
                        ? const Color(0xFF00F2FE)
                        : const Color(0xFFFF0844),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    promptText,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 22),
                if (isMe || !RoomService().isInRoom) ...[
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            if (RoomService().isInRoom) {
                              RoomService().completeTurn(tookPenalty: false);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF34C759),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            _loc("DID IT! ✅", "YAPTIM! ✅", "ERLEDIGT! ✅", "¡HECHO! ✅", "FAIT ! ✅", "СДЕЛАНО! ✅"),
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            if (RoomService().isInRoom) {
                              RoomService().completeTurn(tookPenalty: true);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF0844),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            _loc("PENALTY! 💀", "CEZAMI ÇEKERİM! 💀", "STRAFE! 💀", "¡CASTIGO! 💀", "GAGE ! 💀", "ШТРАФ! 💀"),
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(color: Color(0xFF00F2FE), strokeWidth: 2),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          _loc("$targetName is completing the task...",
                               "$targetName görevi tamamlıyor...",
                               "$targetName erfüllt die Aufgabe...",
                               "$targetName está completando la tarea...",
                               "$targetName est en train de faire le gage...",
                               "$targetName выполняет задание..."),
                          style: const TextStyle(
                            color: Color(0xFF00F2FE),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    ).then((_) {
      _activeSyncedCardCtx = null;
    });
  }

  void _showSyncedAdBreak(RoomState room) {
    if (_vip) {
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF0F172A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0xFFFFCC00), width: 2),
          ),
          title: const Row(
            children: [
              Text("👑", style: TextStyle(fontSize: 22)),
              SizedBox(width: 8),
              Text("VIP BENEFIT", style: TextStyle(color: Color(0xFFFFCC00), fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text(
            _loc("You are a VIP member! Ad break skipped. Waiting for other players... ✨",
                 "VIP üyesiniz! Reklam molası atlandı. Diğer oyuncular bekleniyor... ✨",
                 "Du bist VIP-Mitglied! Werbepause übersprungen. Warte auf andere... ✨",
                 "¡Eres miembro VIP! Pausa publicitaria omitida. Esperando a otros... ✨",
                 "Vous êtes membre VIP ! Pause publicitaire ignorée. En attente des autres... ✨"),
            style: const TextStyle(color: Colors.white70),
          ),
        ),
      );
      return;
    }

    _showInterstitialAdIfNeeded();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: (!_vip && _isBannerAdLoaded && _bannerAd != null)
          ? Container(
              color: Colors.black,
              width: _bannerAd!.size.width.toDouble(),
              height: _bannerAd!.size.height.toDouble(),
              alignment: Alignment.center,
              child: AdWidget(ad: _bannerAd!),
            )
          : null,
      body: Stack(
        children: [
          // Background Neon Party Atmosphere Image
          Positioned.fill(
            child: Image.asset(
              'assets/game_bg.png',
              fit: BoxFit.cover,
            ),
          ),
          // Dark ambient overlay for crisp readability
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.60),
            ),
          ),
          // Screen Content
          SafeArea(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: () {
                switch (currentScreen) {
                  case 0:
                    return _buildSplashScreen();
                  case 1:
                    return _buildSetupScreen();
                  case 2:
                    return _buildObjectsScreen();
                  case 3:
                    return _buildPacksScreen();
                  case 4:
                    return _buildArenaScreen();
                  case 5:
                    return RoomJoinScreen(
                      initialMode: _activeGameMode,
                      isVip: _vip,
                      currentLangIndex: _currentLangIndex,
                      loc: (en, tr, de, es, fr, [ru]) => _loc(en, tr, de, es, fr, ru),
                      onBackToMenu: () => setState(() => currentScreen = 0),
                      onRoomCreatedOrJoined: () => setState(() => currentScreen = 6),
                    );
                  case 6:
                    return RoomLobbyScreen(
                      isVip: _vip,
                      currentLangIndex: _currentLangIndex,
                      loc: (en, tr, de, es, fr, [ru]) => _loc(en, tr, de, es, fr, ru),
                      onStartGame: () => setState(() {
                        RoomService().proceedToObjects();
                        currentScreen = 2; // Move to Objects selection step
                      }),
                      onLeaveRoom: () async {
                        await RoomService().leaveRoom();
                        setState(() => currentScreen = 0);
                      },
                    );
                  default:
                    return _buildSplashScreen();
                }
              }(),
            ),
          ),
          // Right-Side Slide-Over Profile / Quick Switch Drawer
          if (_profileDrawerOpen) _buildProfileDrawer(),
          // Mandatory Online Connection Blocker Overlay
          if (!_isOnline) _buildOfflineOverlay(),
        ],
      ),
    );
  }
}

// Custom Painter for Slicing pack_sheet.png (2 columns, 3 rows)
class PackSpritePainter extends CustomPainter {
  final ui.Image image;
  final int index; // 0 to 5
  PackSpritePainter(this.image, this.index);

  @override
  void paint(Canvas canvas, Size size) {
    final cellW = image.width / 2.0;
    final cellH = image.height / 3.0;
    final col = index % 2;
    final row = index ~/ 2;

    final src = Rect.fromLTWH(col * cellW, row * cellH, cellW, cellH);
    final dst = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawImageRect(image, src, dst, Paint()..filterQuality = FilterQuality.high);
  }

  @override
  bool shouldRepaint(covariant PackSpritePainter oldDelegate) =>
      oldDelegate.image != image || oldDelegate.index != index;
}

// Custom Painter for Arena Connecting Ring Line
class RingLinePainter extends CustomPainter {
  final Offset center;
  final double radius;
  RingLinePainter(this.center, this.radius);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00F2FE).withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant RingLinePainter oldDelegate) =>
      oldDelegate.center != center || oldDelegate.radius != radius;
}

// =========================================================================
// DYNAMIC WOBBLY BOTTLES SHOWCASE (Endless Animated Carousel of 5 Objects)
// =========================================================================
class WobblyBottleShowcase extends StatefulWidget {
  final int currentLangIndex;
  final VoidCallback? onTap;

  const WobblyBottleShowcase({
    super.key,
    required this.currentLangIndex,
    this.onTap,
  });

  @override
  State<WobblyBottleShowcase> createState() => _WobblyBottleShowcaseState();
}

class _WobblyBottleShowcaseState extends State<WobblyBottleShowcase>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  Timer? _cycleTimer;
  late AnimationController _wobbleController;

  static const List<Color> _bottleColors = [
    Color(0xFF00F2FE), // 0: Cyan Soda Bottle
    Color(0xFFFF9500), // 1: Orange Squeaky Chicken
    Color(0xFF34C759), // 2: Green Wobbly Pickle (Sallanan Turşu)
    Color(0xFFBF4FFF), // 3: Purple Flying Slipper
    Color(0xFFFFCC00), // 4: Gold Golden Champagne (VIP)
  ];

  static const List<String> _bottleIcons = [
    "🍾",
    "🐔",
    "🥒",
    "🩴",
    "✨",
  ];

  @override
  void initState() {
    super.initState();
    // Continuous smooth wobble rocking physics (sine wave animation)
    _wobbleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    // Automatically cycle through all 5 objects in an endless loop
    _cycleTimer = Timer.periodic(const Duration(milliseconds: 2400), (_) {
      if (mounted) {
        setState(() {
          _currentIndex = (_currentIndex + 1) % 5;
        });
      }
    });
  }

  @override
  void dispose() {
    _cycleTimer?.cancel();
    _wobbleController.dispose();
    super.dispose();
  }

  void _nextBottle() {
    HapticFeedback.lightImpact();
    setState(() {
      _currentIndex = (_currentIndex + 1) % 5;
    });
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = _bottleColors[_currentIndex];
    final bottleName = WobblyBottleAppGame.getObjectName(_currentIndex, widget.currentLangIndex);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: _nextBottle,
          child: AnimatedBuilder(
            animation: _wobbleController,
            builder: (context, child) {
              final sineVal = math.sin(_wobbleController.value * 2 * math.pi);
              final tiltAngle = sineVal * 0.16; // Gentle tilt angle in radians

              // Signature Wobbly bend physics: tilts left -> bends left ('l'), tilts right -> bends right ('r')
              String bendSuffix = '0';
              if (sineVal < -0.32) {
                bendSuffix = 'l';
              } else if (sineVal > 0.32) {
                bendSuffix = 'r';
              }

              return AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                width: 106,
                height: 106,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(26),
                  gradient: const RadialGradient(
                    center: Alignment(0, -0.2),
                    radius: 0.9,
                    colors: [
                      Color(0xFF1E293B),
                      Color(0xFF0A0E1A),
                    ],
                  ),
                  border: Border.all(
                    color: activeColor,
                    width: 2.6,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: activeColor.withValues(alpha: 0.55),
                      blurRadius: 28,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Radial color aura behind the bottle
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              activeColor.withValues(alpha: 0.32),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                      // Wobbling Animated Bottle with live bend & tilt (Scaled up to fill box)
                      Transform.rotate(
                        angle: tiltAngle,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 350),
                          transitionBuilder: (child, anim) {
                            return ScaleTransition(
                              scale: Tween<double>(begin: 0.84, end: 1.0).animate(
                                CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
                              ),
                              child: FadeTransition(opacity: anim, child: child),
                            );
                          },
                          child: KeyedSubtree(
                            key: ValueKey("showcase_obj_$_currentIndex"),
                            child: Transform.scale(
                              scale: 1.34,
                              child: Image.asset(
                                'assets/bent_${_currentIndex}_$bendSuffix.png',
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                      ),
                      // VIP Crown badge for Golden Champagne (Index 4)
                      if (_currentIndex == 4)
                        const Positioned(
                          top: 6,
                          right: 8,
                          child: Text("👑", style: TextStyle(fontSize: 14)),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 6),
        // 5 Mini Glowing Dots Indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (dotIdx) {
            final isActive = dotIdx == _currentIndex;
            final dotColor = _bottleColors[dotIdx];
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 2.5),
              width: isActive ? 14 : 5,
              height: 5,
              decoration: BoxDecoration(
                color: isActive ? dotColor : Colors.white24,
                borderRadius: BorderRadius.circular(3),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: dotColor.withValues(alpha: 0.8),
                          blurRadius: 5,
                        ),
                      ]
                    : null,
              ),
            );
          }),
        ),
        const SizedBox(height: 4),
        // Active Bottle Name Badge
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: Text(
            "${_bottleIcons[_currentIndex]} $bottleName",
            key: ValueKey("name_$_currentIndex"),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: activeColor,
              letterSpacing: 0.5,
              shadows: [
                Shadow(color: activeColor.withValues(alpha: 0.6), blurRadius: 6),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
