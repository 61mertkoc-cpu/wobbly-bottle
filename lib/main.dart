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
    Color(0xFF00F2FE), // Cyan
    Color(0xFFFF0844), // Pink/Red
    Color(0xFFFF9500), // Orange
    Color(0xFFAF52DE), // Purple
    Color(0xFFFFCC00), // Yellow
    Color(0xFF34C759), // Green
  ];

  static const List<List<String>> langFlags = [
    ["🇬🇧", "EN", "English"],
    ["🇹🇷", "TR", "Türkçe"],
    ["🇩🇪", "DE", "Deutsch"],
    ["🇪🇸", "ES", "Español"],
  ];

  static String getObjectName(int index, int langIdx) {
    switch (index) {
      case 0:
        return getLoc(langIdx, "Funny Soda Bottle", "Komik Gazoz Şişesi", "Lustige Limo-Flasche", "Botella de Refresco Divertida");
      case 1:
        return getLoc(langIdx, "Squeaky Chicken", "Bipleyen Tavuk", "Quietsche-Huhn", "Pollo Chillón");
      case 2:
        return getLoc(langIdx, "Wobbly Banana", "Sallanan Muz", "Wackel-Banane", "Plátano Tambaleante");
      case 3:
        return getLoc(langIdx, "Flying Slipper", "Uçan Terlik", "Fliegender Hausschuh", "Zapatilla Voladora");
      case 4:
        return getLoc(langIdx, "Golden Champagne", "Altın Şampanya", "Goldener Champagner", "Champán Dorado");
      default:
        return "";
    }
  }

  static String getPackName(int index, int langIdx) {
    switch (index) {
      case 0:
        return getLoc(langIdx, "PARTY AND FUN", "PARTİ VE EĞLENCE", "PARTY UND SPASS", "FIESTA Y DIVERSIÓN");
      case 1:
        return getLoc(langIdx, "DEEP CONFESSIONS", "DERİN İTİRAFLAR", "TIEFE GESTÄNDNISSE", "CONFESIONES PROFUNDAS");
      case 2:
        return getLoc(langIdx, "BOLD CHALLENGES / DARES", "CESUR GÖREVLER / MEYDAN OKUMA", "MUTIGE HERAUSFORDERUNGEN", "DESAFÍOS ATREVIDOS");
      case 3:
        return getLoc(langIdx, "FLIRT AND COUPLES", "FLÖRT VE ÇİFTLER", "FLIRT UND PÄRCHEN", "COQUETEO Y PAREJAS");
      case 4:
        return getLoc(langIdx, "+18 SPICY", "+18 BAHARATLI", "+18 SCHARF", "+18 PICANTE");
      case 5:
        return getLoc(langIdx, "FREE MODE / ASK OURSELVES", "SERBEST MOD / KENDİMİZ SORALIM", "FREIER MODUS", "MODO LIBRE");
      default:
        return "";
    }
  }

  static String getLoc(int langIdx, String en, String tr, String de, String es) {
    switch (langIdx) {
      case 1:
        return tr;
      case 2:
        return de;
      case 3:
        return es;
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
    with TickerProviderStateMixin {
  // Navigation: 0 = Splash, 1 = Setup, 2 = Objects, 3 = Packs, 4 = Arena
  int currentScreen = 0;

  // Settings
  bool isMuted = false;
  int _currentLangIndex = 0; // 0: EN, 1: TR, 2: DE, 3: ES

  // Players
  final List<Player> _players = [];
  final TextEditingController _nameController = TextEditingController();
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

  // AdMob Rewarded Ad
  RewardedAd? _rewardedAd;
  bool _isAdLoading = false;
  int _adTargetObject = -1;

  // AdMob Interstitial Ad (Every 5 spins)
  InterstitialAd? _interstitialAd;
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

  @override
  void initState() {
    super.initState();
    _loadQuestions();
    _loadPackSheet();
    _loadRewardedAd();
    _loadInterstitialAd();
    _initInAppPurchase();

    _wobbleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3800),
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
    _wobbleController.dispose();
    _spinController.dispose();
    _nameController.dispose();
    _rewardedAd?.dispose();
    _interstitialAd?.dispose();
    _iapSubscription?.cancel();
    super.dispose();
  }

  String _loc(String en, String tr, String de, String es) {
    return WobblyBottleAppGame.getLoc(_currentLangIndex, en, tr, de, es);
  }

  String get _currentLangKey {
    switch (_currentLangIndex) {
      case 1:
        return 'TR';
      case 2:
        return 'DE';
      case 3:
        return 'ES';
      default:
        return 'EN';
    }
  }

  // --- ADMOB REWARDED AD ---
  void _loadRewardedAd() {
    if (_isAdLoading) return;
    _isAdLoading = true;
    RewardedAd.load(
      adUnitId: _rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isAdLoading = false;
        },
        onAdFailedToLoad: (error) {
          _rewardedAd = null;
          _isAdLoading = false;
        },
      ),
    );
  }

  void _startRewardedAd(int objectIndex) {
    _adTargetObject = objectIndex;

    if (_rewardedAd != null) {
      _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _rewardedAd = null;
          _loadRewardedAd();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          ad.dispose();
          _rewardedAd = null;
          _loadRewardedAd();
        },
      );

      _rewardedAd!.show(
        onUserEarnedReward: (adWithoutView, reward) {
          setState(() {
            _unlockedObjects[_adTargetObject] = true;
            _selectedObjectIndex = _adTargetObject;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: const Color(0xFF34C759),
              content: Text(
                _loc(
                  "🎉 Unlocked: ${WobblyBottleAppGame.getObjectName(_adTargetObject, _currentLangIndex)}!",
                  "🎉 Açıldı: ${WobblyBottleAppGame.getObjectName(_adTargetObject, _currentLangIndex)}!",
                  "🎉 Freigeschaltet!",
                  "🎉 ¡Desbloqueado!",
                ),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          );
        },
      );
    } else {
      // Ad is still loading, try loading again and inform user
      _loadRewardedAd();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFBF4FFF),
          content: Text(
            _loc(
              "Loading video ad, please try again in a moment...",
              "Video reklam yükleniyor, lütfen birkaç saniye sonra tekrar deneyin...",
              "Video-Werbung lädt, bitte gleich noch einmal versuchen...",
              "Cargando anuncio, inténtalo de nuevo en unos segundos...",
            ),
          ),
        ),
      );
    }
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
          _isInterstitialLoading = false;
        },
      ),
    );
  }

  void _showInterstitialAdIfNeeded() {
    if (_vip) return; // VIP users never see ads!

    _spinCounter++;
    if (_spinCounter >= 5) {
      _spinCounter = 0; // Reset counter
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
          },
        );
        _interstitialAd!.show();
      } else {
        _loadInterstitialAd();
      }
    }
  }

  // --- APPLE / GOOGLE IN-APP PURCHASE ---
  Future<void> _initInAppPurchase() async {
    final bool available = await _iap.isAvailable();
    if (!available) return;

    _iapSubscription = _iap.purchaseStream.listen(
      (List<PurchaseDetails> purchaseDetailsList) {
        _handlePurchases(purchaseDetailsList);
      },
      onDone: () {
        _iapSubscription?.cancel();
      },
      onError: (error) {},
    );

    const Set<String> kIds = {_vipProductId};
    final ProductDetailsResponse response =
        await _iap.queryProductDetails(kIds);
    if (response.notFoundIDs.isEmpty) {
      setState(() {
        _products = response.productDetails;
      });
    }

    // Restore prior purchases if user already purchased
    await _iap.restorePurchases();
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
        } else if (purchase.status == PurchaseStatus.error) {
          setState(() => _isPurchasing = false);
          if (mounted) {
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

  void _buyVip() {
    ProductDetails? vipProduct;
    for (var p in _products) {
      if (p.id == _vipProductId) {
        vipProduct = p;
        break;
      }
    }

    if (vipProduct != null) {
      setState(() => _isPurchasing = true);
      final PurchaseParam purchaseParam =
          PurchaseParam(productDetails: vipProduct);
      _iap.buyNonConsumable(purchaseParam: purchaseParam);
    } else {
      // If products query isn't returned yet, query again & notify
      _iap.queryProductDetails({_vipProductId}).then((response) {
        if (response.productDetails.isNotEmpty) {
          setState(() {
            _products = response.productDetails;
            _isPurchasing = true;
          });
          _iap.buyNonConsumable(
            purchaseParam:
                PurchaseParam(productDetails: response.productDetails.first),
          );
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  _loc(
                    "Connecting to App Store... Please try again.",
                    "App Store'a bağlanılıyor... Lütfen tekrar deneyin.",
                    "Verbindung zum App Store wird hergestellt...",
                    "Conectando a App Store...",
                  ),
                ),
              ),
            );
          }
        }
      });
    }
  }

  // --- VIP OFFER MODAL ---
  void _openVipModal() {
    ProductDetails? vipProd;
    for (var p in _products) {
      if (p.id == _vipProductId) vipProd = p;
    }
    final priceLabel = vipProd?.price ?? "";

    showDialog(
      context: context,
      builder: (ctx) {
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
                      : () {
                          Navigator.of(ctx).pop();
                          _buyVip();
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFCC00),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    elevation: 10,
                  ),
                  child: Text(
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
  void _addPlayer() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    if (_players.length >= 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_loc("Maximum 8 players!", "Maksimum 8 oyuncu!", "Maximal 8 Spieler!", "¡Máximo 8 jugadores!")),
        ),
      );
      return;
    }
    setState(() {
      _players.add(Player(
        name: name,
        color: WobblyBottleAppGame.playerColors[_selectedColorIndex],
      ));
      _nameController.clear();
      _selectedColorIndex = (_selectedColorIndex + 1) % WobblyBottleAppGame.playerColors.length;
    });
  }

  void _removePlayer(int index) {
    setState(() {
      _players.removeAt(index);
    });
  }

  // --- BOTTLE SPIN & BEND ALGORITHM ---
  void _spinBottle() {
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
                    _showInterstitialAdIfNeeded();
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

  // SCREEN 0: SPLASH SCREEN
  Widget _buildSplashScreen() {
    return Center(
      key: const ValueKey(0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _wobbleController,
            builder: (context, child) {
              final wobble = math.sin(_wobbleController.value * 2 * math.pi) * 0.15;
              return Transform.rotate(
                angle: wobble,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00F2FE).withValues(alpha: 0.65),
                        blurRadius: 35,
                        spreadRadius: 10,
                      )
                    ],
                  ),
                  child: Image.asset(
                    'assets/bent_0_0.png',
                    fit: BoxFit.contain,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 30),
          const Text(
            "WOBBLY BOTTLE",
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w900,
              color: Color(0xFFFFCC00),
              letterSpacing: 2.0,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _loc("FUNNY PARTY GAME", "EĞLENCELİ PARTİ OYUNU", "LUSTIGES PARTY-SPIEL", "DIVERTIDO JUEGO DE FIESTA"),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF00F2FE),
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 48),
          ElevatedButton(
            onPressed: () => setState(() => currentScreen = 1),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF0844),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: 12,
            ),
            child: Text(
              _loc("TAP TO START", "BAŞLAMAK İÇİN DOKUN", "TIPPEN ZUM STARTEN", "TOCA PARA EMPEZAR"),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }

  // SCREEN 1: ADD PLAYERS (2-Column Grid matching Android)
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
            _loc("ADD PLAYERS (MIN 2)", "OYUNCU EKLE (MİN 2)", "SPIELER HINZUFÜGEN (MIN 2)", "AÑADIR JUGADORES (MÍN 2)"),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF00F2FE),
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 10),

          // Player Input Field with Yellow '+' inside
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
                      hintText: _loc("Enter player name...", "Oyuncu adı girin...", "Spielername eingeben...", "Nombre del jugador..."),
                      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
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

          // Color Picker row
          Row(
            children: [
              Text(
                _loc("PICK COLOR:", "RENK SEÇ:", "FARBE WÄHLEN:", "COLOR:"),
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white70),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    for (int i = 0; i < WobblyBottleAppGame.playerColors.length; i++)
                      GestureDetector(
                        onTap: () => setState(() => _selectedColorIndex = i),
                        child: Container(
                          width: 28,
                          height: 28,
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
                                      color: WobblyBottleAppGame.playerColors[i].withValues(alpha: 0.8),
                                      blurRadius: 10,
                                    )
                                  ]
                                : null,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Players List (2-column Grid matching Android)
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
                      childAspectRatio: 2.2,
                    ),
                    itemCount: _players.length,
                    itemBuilder: (ctx, idx) {
                      final p = _players[idx];
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
                            Icon(Icons.sentiment_satisfied_alt, color: p.color, size: 26),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                p.name,
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            GestureDetector(
                              onTap: () => _removePlayer(idx),
                              child: const Icon(Icons.close, color: Colors.white54, size: 18),
                            ),
                          ],
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

                        return Positioned(
                          left: px - 35,
                          top: py - 35,
                          child: Column(
                            children: [
                              Container(
                                width: 52,
                                height: 52,
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
                                    size: 32,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _players[i].name,
                                style: TextStyle(
                                  fontSize: 13,
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

          // Bottom Bar (Home & Profile)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                icon: const Icon(Icons.home, color: Color(0xFF00F2FE), size: 28),
                onPressed: () => setState(() => currentScreen = 1),
              ),
              IconButton(
                icon: const Icon(Icons.workspace_premium, color: Color(0xFFFFCC00), size: 28),
                onPressed: _openVipModal,
              ),
            ],
          ),
        ],
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
