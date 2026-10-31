import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

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
  Player({required this.name, required this.color});
}

class WobblyBottleAppGame {
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
  ];

  static String getObjectName(int index, int langIdx) {
    switch (index) {
      case 0:
        return getLoc(langIdx, "Funny Soda Bottle", "Komik Gazoz Şişesi", "Lustige Limo-Flasche", "Botella de Refresco Divertida", "Bouteille de Soda Drôle");
      case 1:
        return getLoc(langIdx, "Squeaky Chicken", "Bipleyen Tavuk", "Quietsche-Huhn", "Pollo Chillón", "Poulet Qui Couine");
      case 2:
        return getLoc(langIdx, "Wobbly Banana", "Sallanan Muz", "Wackel-Banane", "Plátano Tambaleante", "Banane Vacillante");
      case 3:
        return getLoc(langIdx, "Flying Slipper", "Uçan Terlik", "Fliegender Hausschuh", "Zapatilla Voladora", "Pantoufle Volante");
      case 4:
        return getLoc(langIdx, "Golden Champagne", "Altın Şampanya", "Goldener Champagner", "Champán Dorado", "Champagne Doré");
      default:
        return "";
    }
  }

  static String getPackName(int index, int langIdx) {
    switch (index) {
      case 0:
        return getLoc(langIdx, "PARTY AND FUN", "PARTİ VE EĞLENCE", "PARTY UND SPASS", "FIESTA Y DIVERSIÓN", "SOIRÉE ET FUN");
      case 1:
        return getLoc(langIdx, "DEEP CONFESSIONS", "DERİN İTİRAFLAR", "TIEFE GESTÄNDNISSE", "CONFESIONES PROFUNDAS", "CONFESSIONS PROFONDES");
      case 2:
        return getLoc(langIdx, "BOLD CHALLENGES / DARES", "CESUR GÖREVLER / MEYDAN OKUMA", "MUTIGE HERAUSFORDERUNGEN", "DESAFÍOS ATREVIDOS", "DÉFIS AUDACIEUX");
      case 3:
        return getLoc(langIdx, "FLIRT AND COUPLES", "FLÖRT VE ÇİFTLER", "FLIRT UND PÄRCHEN", "COQUETEO Y PAREJAS", "FLIRT ET COUPLES");
      case 4:
        return getLoc(langIdx, "+18 SPICY", "+18 BAHARATLI", "+18 SCHARF", "+18 PICANTE", "+18 ÉPICÉ");
      case 5:
        return getLoc(langIdx, "FREE MODE / ASK OURSELVES", "SERBEST MOD / KENDİMİZ SORALIM", "FREIER MODUS", "MODO LIBRE", "MODE LIBRE");
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

  static String getLoc(int langIdx, String en, String tr, String de, String es, [String? fr]) {
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
  // Navigation: 0 = Splash, 1 = Setup, 2 = Objects, 3 = Packs, 4 = Arena
  int currentScreen = 1; // Auto-start directly on Setup screen (no mandatory Tap to Start button)

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

  // Objects & Unlocks
  int _selectedObjectIndex = 0;
  final List<bool> _unlockedObjects = [true, false, false, false, false];
  bool _vip = false;

  // Packs
  final List<bool> _selectedPacks = [true, false, false, false, false, false];

  // Spritesheet for Packs
  ui.Image? _packSheetImage;

  // Questions Database
  Map<String, dynamic> _questionsDb = {};
  bool _questionsLoaded = false;

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
  static const String _androidInterstitialAdUnitId = 'ca-app-pub-7561629034641721/1266289633';

  static const String _vipProductId = 'wobbly_vip';

  String get _rewardedAdUnitId =>
      Platform.isIOS ? _iosRewardedAdUnitId : _androidRewardedAdUnitId;

  String get _interstitialAdUnitId =>
      Platform.isIOS ? _iosInterstitialAdUnitId : _androidInterstitialAdUnitId;

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
    _checkInternetConnectivity();
    _netTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _checkInternetConnectivity();
    });

    _loadQuestions();
    _loadPackSheet();
    _loadRewardedAd();
    _loadInterstitialAd();
    _initInAppPurchase();

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
      _checkInternetConnectivity();
      if (_rewardedInterstitialAd == null && _rewardedAd == null) {
        _loadRewardedAd();
      }
      if (_interstitialAd == null && _spinRewardedInterstitialAd == null) {
        _loadInterstitialAd();
      }
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
    _iapSubscription?.cancel();
    super.dispose();
  }

  String _loc(String en, String tr, String de, String es, [String? fr]) {
    return WobblyBottleAppGame.getLoc(_currentLangIndex, en, tr, de, es, fr);
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
      const Set<String> kIds = {_vipProductId};
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
      if (purchase.productID == _vipProductId) {
        if (purchase.status == PurchaseStatus.purchased ||
            purchase.status == PurchaseStatus.restored) {
          setState(() {
            _vip = true;
            _unlockedObjects[4] = true;
            _selectedPacks[4] = true;
            _isPurchasing = false;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: const Color(0xFFFFCC00),
                content: Text(
                  _loc(
                    "👑 Wobbly VIP Activated! All features unlocked!",
                    "👑 Wobbly VIP Aktif Edildi! Tüm kilitler açıldı!",
                    "👑 Wobbly VIP Aktiviert!",
                    "👑 ¡Wobbly VIP Activado!",
                  ),
                  style: const TextStyle(
                      color: Colors.black, fontWeight: FontWeight.bold),
                ),
              ),
            );
          }
        } else if (purchase.status == PurchaseStatus.error ||
            purchase.status == PurchaseStatus.canceled) {
          setState(() => _isPurchasing = false);
          if (mounted && purchase.status == PurchaseStatus.error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  _loc(
                    "Purchase failed or canceled.",
                    "Satın alma başarısız oldu veya iptal edildi.",
                    "Kauf fehlgeschlagen.",
                    "La compra falló.",
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

  Future<void> _buyVip({void Function(void Function())? setModalState}) async {
    ProductDetails? vipProduct;
    for (var p in _products) {
      if (p.id == _vipProductId) {
        vipProduct = p;
        break;
      }
    }

    if (vipProduct == null) {
      if (setModalState != null) {
        setModalState(() => _isPurchasing = true);
      } else {
        setState(() => _isPurchasing = true);
      }

      try {
        final response = await _iap.queryProductDetails({_vipProductId});
        if (response.productDetails.isNotEmpty) {
          vipProduct = response.productDetails.first;
          if (mounted) {
            setState(() {
              _products = response.productDetails;
            });
          }
        }
      } catch (_) {}
    }

    if (vipProduct != null) {
      if (setModalState != null) {
        setModalState(() => _isPurchasing = true);
      } else {
        setState(() => _isPurchasing = true);
      }

      final PurchaseParam purchaseParam =
          PurchaseParam(productDetails: vipProduct);
      _iap.buyNonConsumable(purchaseParam: purchaseParam);
    } else {
      if (setModalState != null) {
        setModalState(() => _isPurchasing = false);
      } else {
        setState(() => _isPurchasing = false);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _loc(
                "Connecting to App Store... Please try again in a moment.",
                "App Store'a bağlanılıyor... Lütfen birazdan tekrar deneyin.",
                "Verbindung zum App Store wird hergestellt...",
                "Conectando a App Store...",
              ),
            ),
          ),
        );
      }
    }
  }

  // --- VIP OFFER MODAL ---
  void _openVipModal() {
    _fetchProducts(); // Pre-fetch if not ready

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            ProductDetails? vipProd;
            for (var p in _products) {
              if (p.id == _vipProductId) vipProd = p;
            }
            final priceLabel = vipProd?.price ?? "";

            return Dialog(
              backgroundColor: const Color(0xFF131019),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
                side: const BorderSide(color: Color(0xFFFFCC00), width: 3),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 28.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFFFCC00).withValues(alpha: 0.15),
                      ),
                      child: const Icon(Icons.workspace_premium, size: 60, color: Color(0xFFFFCC00)),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      "WOBBLY VIP",
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFFFFCC00),
                        letterSpacing: 2,
                      ),
                    ),
                    Text(
                      _loc("Premium Party Upgrade", "Premium Parti Yükseltmesi", "Premium Party-Upgrade", "Mejora de Fiesta Premium"),
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 20),
                    _buildVipFeature(
                      Icons.wine_bar,
                      _loc("Golden Champagne Bottle", "Altın Şampanya Şişesi", "Goldener Champagner", "Champán Dorado"),
                    ),
                    const SizedBox(height: 10),
                    _buildVipFeature(
                      Icons.favorite,
                      _loc("💋 +18 Spicy Secret Pack", "💋 +18 Baharatlı Gizli Paket", "💋 +18 Scharf-Paket", "💋 +18 Paquete Picante"),
                    ),
                    const SizedBox(height: 10),
                    _buildVipFeature(
                      Icons.bolt,
                      _loc("Instant In-Game Switching", "Anında Oyun İçi Değiştirme", "Sofortiges Wechseln", "Cambio Instantáneo"),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isPurchasing
                          ? null
                          : () async {
                              await _buyVip(setModalState: setDialogState);
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFCC00),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        elevation: 10,
                      ),
                      child: _isPurchasing
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.black,
                              ),
                            )
                          : Text(
                              priceLabel.isNotEmpty
                                  ? "${_loc("ACTIVATE VIP", "VIP ETKİNLEŞTİR", "VIP AKTIVIEREN", "ACTIVAR VIP")} ($priceLabel)"
                                  : _loc("ACTIVATE VIP", "VIP ETKİNLEŞTİR", "VIP AKTIVIEREN", "ACTIVAR VIP"),
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                            ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () {
                        _iap.restorePurchases();
                        Navigator.of(ctx).pop();
                      },
                      child: Text(
                        _loc("Restore Purchase", "Satın Alımı Geri Yükle", "Käufe wiederherstellen", "Restaurar compra"),
                        style: const TextStyle(color: Color(0xFF00F2FE), fontSize: 13),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: Text(
                        _loc("Cancel", "Vazgeç", "Abbrechen", "Cancelar"),
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
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

    setState(() {
      _players.add(Player(
        name: name,
        color: WobblyBottleAppGame.playerColors[_selectedColorIndex],
      ));
      _nameController.clear();
      _selectedColorIndex =
          (_selectedColorIndex + 1) % WobblyBottleAppGame.playerColors.length;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollColorPaletteToIndex(_selectedColorIndex);
    });
  }

  void _editPlayerDialog(int index) {
    if (index < 0 || index >= _players.length) return;
    final editController = TextEditingController(text: _players[index].name);
    editController.selection = TextSelection(
      baseOffset: 0,
      extentOffset: editController.text.length,
    );
    Color tempColor = _players[index].color;

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
                _players[index] = Player(name: updatedName, color: tempColor);
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
                        Icon(Icons.edit, color: tempColor, size: 22),
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
                    const SizedBox(height: 18),
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
                    const SizedBox(height: 16),
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
                    const SizedBox(height: 22),
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

    setState(() {
      _isSpinning = true;
      _startAngle = _currentAngle;
      _targetAngle = _currentAngle + (rotations * 2 * math.pi) + randomTarget;
      _questionerIndex = -1;
      _answererIndex = -1;
      _currentBendVariant = "0";
    });

    _spinController.reset();
    _spinController.forward();
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

    // Show interstitial ad every 5 bottle spins!
    _showInterstitialAdIfNeeded();
  }

  // --- CARD & QUESTION PICKING ---
  void _showCard(String mode) {
    if (_answererIndex < 0 || _questionerIndex < 0) return;
    final targetName = _players[_answererIndex].name;
    final askerName = _players[_questionerIndex].name;

    String promptText = "";
    String cardTitle = "";

    if (mode == 'FREE') {
      cardTitle = _loc("FREE QUESTION", "SERBEST SORU", "FREIE FRAGE", "PREGUNTA LIBRE");
      promptText = _loc(
        "$askerName asks any question or gives any challenge to $targetName!",
        "$askerName, $targetName adlı oyuncuya dilediği soruyu sorar veya meydan okur!",
        "$askerName stellt $targetName eine beliebige Frage!",
        "¡$askerName le hace cualquier pregunta o reto a $targetName!",
      );
    } else {
      cardTitle = mode == 'TRUTH'
          ? _loc("TRUTH FOR $targetName", "$targetName İÇİN DOĞRULUK", "WAHRHEIT FÜR $targetName", "VERDAD PARA $targetName")
          : _loc("DARE FOR $targetName", "$targetName İÇİN CESARET", "PFLICHT FÜR $targetName", "RETO PARA $targetName");

      final List<String> candidateQuestions = [];
      final langKey = _currentLangKey;

      if (_questionsLoaded && _questionsDb.isNotEmpty) {
        final packKeys = ["pack0_party", "pack1_deep", "pack2_challenge", "pack3_flirt", "pack4_spicy"];
        for (int p = 0; p < packKeys.length; p++) {
          if (_selectedPacks[p] && _questionsDb.containsKey(packKeys[p])) {
            final list = _questionsDb[packKeys[p]] as List<dynamic>;
            for (var item in list) {
              if (item is Map) {
                final itemType = item['type']?.toString().toUpperCase();
                // Strictly filter: TRUTH items only for TRUTH mode, DARE items only for DARE mode!
                if (itemType != null && itemType != mode) {
                  continue;
                }
                if (item.containsKey(langKey)) {
                  candidateQuestions.add(item[langKey].toString());
                }
              }
            }
          }
        }
      }

      if (candidateQuestions.isNotEmpty) {
        final rand = math.Random();
        promptText = candidateQuestions[rand.nextInt(candidateQuestions.length)];
      } else {
        promptText = mode == 'TRUTH'
            ? _loc("What is the most memorable party moment in your life?", "Hayatındaki en unutulmaz parti anın neydi?", "Was war dein verrücktester Partymoment?", "¿Cuál ha sido tu momento de fiesta más loco?")
            : _loc("Do your best 10-second funny dance right now!", "Şu an en komik dansını 10 saniye boyunca yap!", "Mache 10 Sekunden lang deinen lustigsten Tanz!", "¡Haz tu baile más divertido durante 10 segundos!");
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

  // SCREEN 0: SPLASH SCREEN (Auto-transitions without Tap to Start)
  Widget _buildSplashScreen() {
    return Center(
      key: const ValueKey(0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 190,
            height: 190,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(38),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00F2FE).withValues(alpha: 0.55),
                  blurRadius: 35,
                  spreadRadius: 6,
                )
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(38),
              child: Image.asset(
                'assets/app_icon.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
        ],
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "WOBBLY",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFFFFCC00),
                      letterSpacing: 1.5,
                      shadows: [
                        Shadow(color: const Color(0xFFFFCC00).withValues(alpha: 0.6), blurRadius: 10),
                      ],
                    ),
                  ),
                  Text(
                    "BOTTLE",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF00F2FE),
                      letterSpacing: 1.5,
                      shadows: [
                        Shadow(color: const Color(0xFF00F2FE).withValues(alpha: 0.6), blurRadius: 10),
                      ],
                    ),
                  ),
                ],
              ),
              _buildHeaderControls(),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _loc("ADD PLAYERS (MIN 2 - MAX 10)", "OYUNCU EKLE (MİN 2 - MAKS 10)", "SPIELER HINZUFÜGEN (2 - 10)", "AÑADIR JUGADORES (2 - 10)"),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF00F2FE),
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 10),

          // Player Input Field with Yellow '+' inside (works with or without typing a name)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF051725),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFF00F2FE), width: 2),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      hintText: _loc("Enter name or tap + to quick add...", "İsim yazın veya hızlı eklemek için + basın...", "Name eingeben oder + tippen...", "Escribe nombre o toca +..."),
                      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 14),
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

          // Players List (2-column Grid matching Android, with Pencil Edit + Remove icons)
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
                              Icon(Icons.sentiment_satisfied_alt, color: p.color, size: 24),
                              const SizedBox(width: 6),
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
                  ? () => setState(() => currentScreen = 2)
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
              Row(
                children: [
                  GestureDetector(
                    onTap: () => setState(() => currentScreen = 1),
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
                  const SizedBox(width: 12),
                  Text(
                    _loc("CHOOSE YOUR OBJECT", "NESNENİ SEÇ", "WÄHLE DEIN OBJEKT", "ELIGE TU OBJETO"),
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFFFCC00),
                    ),
                  ),
                ],
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
                    if (isVipItem && !_vip) {
                      _openVipModal();
                    } else if (!isUnlocked) {
                      _startRewardedAd(idx);
                    } else {
                      setState(() => _selectedObjectIndex = idx);
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

          // Continue Button
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFFFCC00), width: 2),
            ),
            child: ElevatedButton(
              onPressed: () => setState(() => currentScreen = 3),
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
              Row(
                children: [
                  GestureDetector(
                    onTap: () => setState(() => currentScreen = 2),
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
                  const SizedBox(width: 12),
                  Text(
                    _loc("CHOOSE YOUR PACKS", "PAKETLERİNİ SEÇ", "WÄHLE DEINE PAKETE", "ELIGE TUS PAQUETES"),
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFFFCC00),
                    ),
                  ),
                ],
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
                    if (isVipPack && !_vip) {
                      _openVipModal();
                    } else {
                      setState(() {
                        _selectedPacks[idx] = !_selectedPacks[idx];
                        if (!_selectedPacks.contains(true)) {
                          _selectedPacks[idx] = true;
                        }
                      });
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

          // Start Game Button
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFFFCC00), width: 2),
            ),
            child: ElevatedButton(
              onPressed: () => setState(() => currentScreen = 4),
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

    return Padding(
      key: const ValueKey(4),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Column(
        children: [
          // Header Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () => setState(() => currentScreen = 3),
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
              Text(
                "BOTTLE SAYS...",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 1.5,
                  shadows: [
                    Shadow(color: const Color(0xFF00F2FE).withValues(alpha: 0.7), blurRadius: 10),
                  ],
                ),
              ),
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
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: avatarSize,
                                height: avatarSize,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _players[i].color,
                                  border: Border.all(
                                    color: isA
                                        ? const Color(0xFFFF0844)
                                        : (isQ ? const Color(0xFF00F2FE) : Colors.white),
                                    width: (isA || isQ) ? 4 : 2,
                                  ),
                                  boxShadow: (isA || isQ)
                                      ? [
                                          BoxShadow(
                                            color: isA ? const Color(0xFFFF0844) : const Color(0xFF00F2FE),
                                            blurRadius: 20,
                                            spreadRadius: 6,
                                          )
                                        ]
                                      : null,
                                ),
                                child: Center(
                                  child: Icon(
                                    Icons.sentiment_satisfied_alt,
                                    color: Colors.black.withValues(alpha: 0.85),
                                    size: iconSize,
                                  ),
                                ),
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
                            ],
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

          // Bottom Control Panel: QUESTIONER, ANSWERER, TRUTH, DARE, CUSTOM
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF0A1828),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFF00F2FE).withValues(alpha: 0.6), width: 2),
            ),
            child: Column(
              children: [
                if (_answererIndex >= 0 && _questionerIndex >= 0 && !_isSpinning) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "QUESTIONER: ${_players[_questionerIndex].name.toUpperCase()}",
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF00F2FE),
                        ),
                      ),
                      Text(
                        "ANSWERER: ${_players[_answererIndex].name.toUpperCase()}",
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFFFF0844),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _loc("? MAKE YOUR CHOICE", "? SEÇİMİNİ YAP", "? WÄHLE DEINE AKTION", "? HAZ TU ELECCIÓN"),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFFFCC00),
                    ),
                  ),
                  Text(
                    _loc("Truth, Dare, or Ask Yourselves?", "Doğruluk, Cesaret veya Kendiniz Sorun?", "Wahrheit, Pflicht oder Frage?", "¿Verdad, Reto o Pregunta?"),
                    style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.6)),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _showCard('TRUTH'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00F2FE),
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: Text(
                            _loc("TRUTH", "DOĞRULUK", "WAHRHEIT", "VERDAD"),
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _showCard('DARE'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF0844),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: Text(
                            _loc("DARE", "CESARET", "PFLICHT", "RETO"),
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () => _showCard('FREE'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: const Color(0xFFFFCC00),
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: const BorderSide(color: Color(0xFFFFCC00), width: 1.5),
                          ),
                        ),
                        child: Text(
                          _loc("CUSTOM", "ÖZEL", "EIGENE", "PROPIO"),
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],

                // Big Spin Bottle Button
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFCC00).withValues(alpha: 0.35),
                        blurRadius: 15,
                      )
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _isSpinning ? null : _spinBottle,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFCC00),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    ),
                    child: Text(
                      _isSpinning
                          ? _loc("WOBBLING...", "DÖNÜYOR...", "DREHT SICH...", "GIRANDO...")
                          : _loc("SPIN BOTTLE!", "ŞİŞEYİ ÇEVİR!", "FLASCHE DREHEN!", "¡GIRAR BOTELLA!"),
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Bottom Bar (Home & Profile / VIP Quick Switch Drawer)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              GestureDetector(
                onTap: () => setState(() => currentScreen = 1),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A1828),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF00F2FE).withValues(alpha: 0.5),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.home, color: Color(0xFF00F2FE), size: 24),
                      const SizedBox(width: 6),
                      Text(
                        _loc("HOME", "ANA SAYFA", "START", "INICIO"),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => setState(() => _profileDrawerOpen = true),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A1828),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFFFCC00).withValues(alpha: 0.75),
                      width: 1.8,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFCC00).withValues(alpha: 0.2),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.workspace_premium, color: Color(0xFFFFCC00), size: 24),
                      const SizedBox(width: 6),
                      Text(
                        _loc("PROFILE", "PROFİL", "PROFIL", "PERFIL"),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFFFFCC00),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
