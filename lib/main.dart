import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
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
        return getLoc(langIdx, "💋  +18 SPICY", "💋  +18 BAHARATLI", "💋  +18 SCHARF", "💋  +18 PICANTE");
      case 5:
        return getLoc(langIdx, "FREE MODE / ASK OURSELVES", "SERBEST MOD / KENDİMİZ SORALIM", "FREIER MODUS", "MODO LIBRE");
      default:
        return "";
    }
  }

  static String getPackDescription(int index, int langIdx) {
    switch (index) {
      case 0:
        return getLoc(langIdx, "Icebreakers & laugh-out-loud party questions", "Buz kırıcı & kahkaha dolu parti soruları", "Eisbrecher & lustige Partyfragen", "Preguntas divertidas para romper el hielo");
      case 1:
        return getLoc(langIdx, "Secrets, crush reveals & emotional honesty", "Sırlar, ilk aşklar ve samimi itiraflar", "Geheimnisse & emotionale Offenheit", "Secretos y confesiones sinceras");
      case 2:
        return getLoc(langIdx, "Action tasks, funny dares & silly moves", "Aksiyon dolu görevler & komik hareketler", "Mutproben & lustige Aktionen", "Retos audaces y divertidos");
      case 3:
        return getLoc(langIdx, "Sparks, chemistry & sweet romantic prompts", "Kıvılcımlar, çekim ve tatlı flört anları", "Funken, Chemie & süße Flirtfragen", "Chispas, química y momentos coquetos");
      case 4:
        return getLoc(langIdx, "Adult party questions (+18 VIP Only)", "Yetişkin parti soruları (+18 Sadece VIP)", "Heiße Erwachsenen-Fragen (+18 VIP)", "Preguntas candentes para adultos (+18 VIP)");
      case 5:
        return getLoc(langIdx, "Ask anything you want freely", "İstediğiniz soruyu özgürce siz sorun", "Fragt selbst frei nach Belieben", "Preguntad lo que queráis libremente");
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

  // Questions Database
  Map<String, dynamic> _questionsDb = {};
  bool _questionsLoaded = false;

  // Spin & Arena Animation
  late AnimationController _spinController;
  late Animation<double> _spinAnimation;
  double _currentAngle = 0.0;
  double _targetAngle = 0.0;
  bool _isSpinning = false;

  int _questionerIndex = -1;
  int _answererIndex = -1;

  // Rewarded Ad state
  int _adRemainingSeconds = 5;
  int _adTargetObject = -1;
  Timer? _adTimer;

  // Splash wobble
  late AnimationController _wobbleController;

  @override
  void initState() {
    super.initState();
    _loadQuestions();

    _wobbleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    );

    _spinAnimation = CurvedAnimation(
      parent: _spinController,
      curve: Curves.decelerate,
    )..addListener(() {
        setState(() {
          _currentAngle = _currentAngle +
              (_targetAngle - _currentAngle) * _spinController.value;
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
    } catch (_) {
      // Fallback loaded
    }
  }

  @override
  void dispose() {
    _wobbleController.dispose();
    _spinController.dispose();
    _nameController.dispose();
    _adTimer?.cancel();
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

  // --- REWARDED AD SIMULATION ---
  void _startRewardedAd(int objectIndex) {
    setState(() {
      _adTargetObject = objectIndex;
      _adRemainingSeconds = 5;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            _adTimer?.cancel();
            _adTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
              if (_adRemainingSeconds > 1) {
                if (dialogCtx.mounted) {
                  setDialogState(() {
                    _adRemainingSeconds--;
                  });
                }
              } else {
                timer.cancel();
                if (dialogCtx.mounted) {
                  Navigator.of(dialogCtx).pop();
                }
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
                        "🎉 Freigeschaltet: ${WobblyBottleAppGame.getObjectName(_adTargetObject, _currentLangIndex)}!",
                        "🎉 ¡Desbloqueado: ${WobblyBottleAppGame.getObjectName(_adTargetObject, _currentLangIndex)}!",
                      ),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                );
              }
            });

            return Dialog(
              backgroundColor: const Color(0xFF0F0B1E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
                side: const BorderSide(color: Color(0xFFBF4FFF), width: 3),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 30.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.play_circle_fill, size: 64, color: Color(0xFFBF4FFF)),
                    const SizedBox(height: 12),
                    Text(
                      _loc("REWARDED VIDEO", "ÖDÜLLÜ VİDEO", "BELOHNUNGSVIDEO", "VIDEO CON RECOMPENSA"),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFFBF4FFF),
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _loc(
                        "Unlocking ${WobblyBottleAppGame.getObjectName(_adTargetObject, _currentLangIndex)}...",
                        "${WobblyBottleAppGame.getObjectName(_adTargetObject, _currentLangIndex)} açılıyor...",
                        "Wird freigeschaltet...",
                        "Desbloqueando...",
                      ),
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 80,
                          height: 80,
                          child: CircularProgressIndicator(
                            value: (5 - _adRemainingSeconds + 1) / 5.0,
                            strokeWidth: 6,
                            color: const Color(0xFF00F2FE),
                            backgroundColor: Colors.white10,
                          ),
                        ),
                        Text(
                          "$_adRemainingSeconds s",
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFFCC00),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      _loc("Sponsored Ad Simulation", "Sponsorlu Reklam Simülasyonu", "Gesponserte Anzeige", "Anuncio Patrocinado"),
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12),
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

  // --- VIP OFFER MODAL ---
  void _openVipModal() {
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
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    setState(() {
                      _vip = true;
                      _unlockedObjects[4] = true;
                      _selectedPacks[4] = true;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: const Color(0xFFFFCC00),
                        content: Text(
                          _loc(
                            "👑 Wobbly VIP Activated! Enjoy the full experience!",
                            "👑 Wobbly VIP Aktif Edildi! Tüm kilitler açıldı!",
                            "👑 Wobbly VIP Aktiviert!",
                            "👑 ¡Wobbly VIP Activado!",
                          ),
                          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFCC00),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    elevation: 10,
                  ),
                  child: Text(
                    _loc("ACTIVATE VIP", "VIP ETKİNLEŞTİR", "VIP AKTIVIEREN", "ACTIVAR VIP"),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                  ),
                ),
                const SizedBox(height: 12),
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

  // --- SPIN LOGIC ---
  void _spinBottle() {
    if (_isSpinning || _players.length < 2) return;

    final rand = math.Random();
    final rotations = 4 + rand.nextInt(3); // 4-6 full spins
    final randomTarget = rand.nextDouble() * 2 * math.pi;
    final totalTarget = _currentAngle + (rotations * 2 * math.pi) + randomTarget;

    setState(() {
      _isSpinning = true;
      _targetAngle = totalTarget;
      _questionerIndex = -1;
      _answererIndex = -1;
    });

    _spinController.reset();
    _spinController.forward();
  }

  void _onSpinFinished() {
    final finalAngle = _currentAngle % (2 * math.pi);
    final count = _players.length;

    // Head lands at finalAngle - pi/2
    final tipAngle = (finalAngle - (math.pi / 2)) % (2 * math.pi);
    final baseAngle = (tipAngle + math.pi) % (2 * math.pi);

    int nearestToAngle(double angle) {
      double minDiff = double.infinity;
      int best = 0;
      for (int i = 0; i < count; i++) {
        final pAngle = (-math.pi / 2 + (i * 2 * math.pi / count)) % (2 * math.pi);
        double diff = (angle - pAngle).abs();
        if (diff > math.pi) diff = (2 * math.pi) - diff;
        if (diff < minDiff) {
          minDiff = diff;
          best = i;
        }
      }
      return best;
    }

    int answerer = nearestToAngle(tipAngle);
    int questioner = nearestToAngle(baseAngle);

    if (questioner == answerer && count > 1) {
      questioner = (answerer + 1) % count;
    }

    setState(() {
      _isSpinning = false;
      _answererIndex = answerer;
      _questionerIndex = questioner;
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

      // Pick from selected packs in questionsDb
      final List<String> candidateQuestions = [];
      final langKey = _currentLangKey;

      if (_questionsLoaded && _questionsDb.isNotEmpty) {
        final packKeys = ["pack0_party", "pack1_deep", "pack2_bold", "pack3_flirt", "pack4_spicy"];
        for (int p = 0; p < packKeys.length; p++) {
          if (_selectedPacks[p] && _questionsDb.containsKey(packKeys[p])) {
            final list = _questionsDb[packKeys[p]] as List<dynamic>;
            for (var item in list) {
              if (item is Map && item.containsKey(langKey)) {
                candidateQuestions.add(item[langKey].toString());
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
                  onPressed: () => Navigator.of(ctx).pop(),
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

  // --- HEADER CONTROLS (Sound & Lang) ---
  Widget _buildHeaderControls() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Sound Mute Toggle
        GestureDetector(
          onTap: () => setState(() => isMuted = !isMuted),
          child: Container(
            padding: const EdgeInsets.all(10),
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
              size: 20,
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
                const Icon(Icons.arrow_drop_down, color: Color(0xFFFFCC00), size: 18),
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
                  width: 170,
                  height: 170,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00F2FE).withValues(alpha: 0.6),
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

  // SCREEN 1: SETUP
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
              const Text(
                "WOBBLY BOTTLE",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFFFCC00),
                ),
              ),
              _buildHeaderControls(),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _loc("ADD PLAYERS (MIN 2)", "OYUNCU EKLE (MİN 2)", "SPIELER HINZUFÜGEN (MIN 2)", "AÑADIR JUGADORES (MÍN 2)"),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF00F2FE),
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    hintText: _loc("Enter player name...", "Oyuncu adı girin...", "Spielername eingeben...", "Nombre del jugador..."),
                    hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                    filled: true,
                    fillColor: const Color(0xFF051725),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Color(0xFF00F2FE)),
                    ),
                  ),
                  onSubmitted: (_) => _addPlayer(),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _addPlayer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00F2FE),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Icon(Icons.person_add_rounded, size: 28),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Text(
                _loc("COLOR:", "RENK:", "FARBE:", "COLOR:"),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white70),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (int i = 0; i < WobblyBottleAppGame.playerColors.length; i++)
                        GestureDetector(
                          onTap: () => setState(() => _selectedColorIndex = i),
                          child: Container(
                            margin: const EdgeInsets.only(right: 10),
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: WobblyBottleAppGame.playerColors[i],
                              border: Border.all(
                                color: _selectedColorIndex == i ? Colors.white : Colors.transparent,
                                width: 3,
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
          const SizedBox(height: 16),
          Expanded(
            child: _players.isEmpty
                ? Center(
                    child: Text(
                      _loc("No players added yet.\nAdd at least 2 players to start!", "Henüz oyuncu eklenmedi.\nBaşlamak için en az 2 oyuncu ekleyin!", "Noch keine Spieler hinzugefügt.", "Aún no hay jugadores añadidos."),
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 15),
                    ),
                  )
                : ListView.builder(
                    itemCount: _players.length,
                    itemBuilder: (ctx, idx) {
                      final p = _players[idx];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0A1828),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: p.color.withValues(alpha: 0.7), width: 2),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(backgroundColor: p.color, radius: 14),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                p.name,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.white54, size: 20),
                              onPressed: () => _removePlayer(idx),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          ElevatedButton(
            onPressed: _players.length >= 2
                ? () => setState(() => currentScreen = 2)
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFCC00),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: Text(
              _loc("NEXT: CHOOSE OBJECT", "İLERİ: NESNE SEÇ", "WEITER: OBJEKT WÄHLEN", "SIGUIENTE: ELEGIR OBJETO"),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }

  // SCREEN 2: CHOOSE OBJECT
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
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Color(0xFF00F2FE)),
                    onPressed: () => setState(() => currentScreen = 1),
                  ),
                  Text(
                    _loc("CHOOSE OBJECT", "NESNE SEÇİN", "OBJEKT WÄHLEN", "ELEGIR OBJETO"),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFFCC00),
                    ),
                  ),
                ],
              ),
              _buildHeaderControls(),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 0.85,
              ),
              itemCount: 5,
              itemBuilder: (ctx, idx) {
                final isSelected = _selectedObjectIndex == idx;
                final isUnlocked = _unlockedObjects[idx] || (idx == 4 && _vip);
                final isVipItem = idx == 4;
                final objName = WobblyBottleAppGame.getObjectName(idx, _currentLangIndex);

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
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF00F2FE).withValues(alpha: 0.22)
                          : const Color(0xFF0A1828),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: isVipItem
                            ? const Color(0xFFFFCC00)
                            : (isSelected ? const Color(0xFF00F2FE) : Colors.white24),
                        width: isSelected ? 3 : (isVipItem ? 2 : 1),
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: const Color(0xFF00F2FE).withValues(alpha: 0.35),
                                blurRadius: 15,
                                spreadRadius: 2,
                              )
                            ]
                          : null,
                    ),
                    child: Stack(
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Center(
                                child: Image.asset(
                                  'assets/bent_${idx}_0.png',
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              objName,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Colors.white : Colors.white70,
                              ),
                            ),
                            const SizedBox(height: 4),
                            if (isSelected)
                              Text(
                                _loc("SELECTED", "SEÇİLDİ", "AUSGEWÄHLT", "SELECCIONADO"),
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF34C759),
                                ),
                              )
                            else if (!isUnlocked)
                              Text(
                                isVipItem
                                    ? _loc("VIP ONLY", "VIP KİLİTLİ", "NUR VIP", "SÓLO VIP")
                                    : _loc("WATCH AD", "REKLAMLA AÇ", "WERBUNG", "VER ANUNCIO"),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isVipItem ? const Color(0xFFFFCC00) : const Color(0xFFBF4FFF),
                                ),
                              ),
                          ],
                        ),
                        // Badge at top right
                        Positioned(
                          top: 4,
                          right: 4,
                          child: isVipItem
                              ? Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFCC00),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    "👑 VIP",
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.black),
                                  ),
                                )
                              : (!isUnlocked
                                  ? Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFBF4FFF),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text(
                                        "🎬 AD",
                                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                                      ),
                                    )
                                  : const SizedBox.shrink()),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          ElevatedButton(
            onPressed: () => setState(() => currentScreen = 3),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFCC00),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: Text(
              _loc("NEXT: CHOOSE PACKS", "İLERİ: PAKET SEÇ", "WEITER: PAKETE WÄHLEN", "SIGUIENTE: ELEGIR PAQUETES"),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }

  // SCREEN 3: CHOOSE PACKS
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
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Color(0xFF00F2FE)),
                    onPressed: () => setState(() => currentScreen = 2),
                  ),
                  Text(
                    _loc("CHOOSE PACKS", "PAKET SEÇİN", "PAKETE WÄHLEN", "ELEGIR PAQUETES"),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFFCC00),
                    ),
                  ),
                ],
              ),
              _buildHeaderControls(),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              itemCount: 6,
              itemBuilder: (ctx, idx) {
                final isSel = _selectedPacks[idx];
                final isVipPack = idx == 4;
                final packName = WobblyBottleAppGame.getPackName(idx, _currentLangIndex);
                final packDesc = WobblyBottleAppGame.getPackDescription(idx, _currentLangIndex);

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
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isSel
                          ? (isVipPack ? const Color(0xFFFFCC00).withValues(alpha: 0.18) : const Color(0xFFFF0844).withValues(alpha: 0.2))
                          : const Color(0xFF0A1828),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isVipPack
                            ? const Color(0xFFFFCC00)
                            : (isSel ? const Color(0xFFFF0844) : Colors.white24),
                        width: isSel ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isSel ? Icons.check_circle : Icons.circle_outlined,
                          color: isVipPack ? const Color(0xFFFFCC00) : (isSel ? const Color(0xFFFF0844) : Colors.white38),
                          size: 26,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      packName,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: isVipPack ? const Color(0xFFFFCC00) : Colors.white,
                                      ),
                                    ),
                                  ),
                                  if (isVipPack)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFCC00),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text(
                                        "👑 VIP",
                                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.black),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                packDesc,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          ElevatedButton(
            onPressed: () => setState(() => currentScreen = 4),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00F2FE),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: Text(
              _loc("START GAME ARENA", "OYUN ALANINA BAŞLA", "SPIELARENA STARTEN", "INICIAR ARENA DE JUEGO"),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }

  // SCREEN 4: GAME ARENA
  Widget _buildArenaScreen() {
    final count = _players.length;

    return Padding(
      key: const ValueKey(4),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Color(0xFF00F2FE)),
                onPressed: () => setState(() => currentScreen = 3),
              ),
              if (_answererIndex >= 0 && _questionerIndex >= 0 && !_isSpinning)
                Flexible(
                  child: Text(
                    "${_players[_questionerIndex].name} ➔ ${_players[_answererIndex].name}",
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFFFCC00),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                )
              else
                Text(
                  _loc("ARENA", "ARENA", "ARENA", "ARENA"),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFFCC00),
                  ),
                ),
              _buildHeaderControls(),
            ],
          ),

          // Central Arena with Circle of Players & Center Animated Object
          Expanded(
            child: LayoutBuilder(
              builder: (ctx, constraints) {
                final size = math.min(constraints.maxWidth, constraints.maxHeight);
                final center = Offset(constraints.maxWidth / 2, constraints.maxHeight / 2);
                final radius = (size / 2) - 50;

                return Stack(
                  children: [
                    // Players placed along circle
                    for (int i = 0; i < count; i++) ...[
                      () {
                        final pAngle = -math.pi / 2 + (i * 2 * math.pi / count);
                        final px = center.dx + radius * math.cos(pAngle);
                        final py = center.dy + radius * math.sin(pAngle);
                        final isQ = _questionerIndex == i;
                        final isA = _answererIndex == i;

                        return Positioned(
                          left: px - 35,
                          top: py - 35,
                          child: Column(
                            children: [
                              Container(
                                width: 50,
                                height: 50,
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
                                            blurRadius: 18,
                                            spreadRadius: 4,
                                          )
                                        ]
                                      : null,
                                ),
                                child: Center(
                                  child: Text(
                                    _players[i].name.isNotEmpty ? _players[i].name[0].toUpperCase() : "?",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 20,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _players[i].name,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isA
                                      ? const Color(0xFFFF0844)
                                      : (isQ ? const Color(0xFF00F2FE) : Colors.white70),
                                ),
                              ),
                            ],
                          ),
                        );
                      }(),
                    ],

                    // Prominent Center Bottle / Object
                    Positioned(
                      left: center.dx - 100,
                      top: center.dy - 100,
                      child: GestureDetector(
                        onTap: _isSpinning ? null : _spinBottle,
                        child: AnimatedBuilder(
                          animation: _spinAnimation,
                          builder: (context, child) {
                            final wobble = _isSpinning
                                ? math.sin(_spinController.value * 35) * 0.18
                                : 0.0;
                            final angle = _currentAngle + wobble;

                            return Transform.rotate(
                              angle: angle,
                              child: Container(
                                width: 200,
                                height: 200,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: (_selectedObjectIndex == 4
                                              ? const Color(0xFFFFCC00)
                                              : const Color(0xFF00F2FE))
                                          .withValues(alpha: _isSpinning ? 0.6 : 0.25),
                                      blurRadius: _isSpinning ? 35 : 15,
                                      spreadRadius: _isSpinning ? 8 : 2,
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Image.asset(
                                    'assets/bent_${_selectedObjectIndex}_0.png',
                                    width: 170,
                                    height: 170,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // Action Buttons: SPIN, TRUTH, DARE, FREE
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Column(
              children: [
                if (_answererIndex >= 0 && !_isSpinning) ...[
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _showCard('TRUTH'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00F2FE),
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: Text(
                            _loc("TRUTH", "DOĞRULUK", "WAHRHEIT", "VERDAD"),
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _showCard('DARE'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF0844),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: Text(
                            _loc("DARE", "CESARET", "PFLICHT", "RETO"),
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () => _showCard('FREE'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFCC00),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: Text(
                          _loc("FREE", "SERBEST", "FREI", "LIBRE"),
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
                ElevatedButton(
                  onPressed: _isSpinning ? null : _spinBottle,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFCC00),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    elevation: 10,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.refresh, size: 26),
                      const SizedBox(width: 8),
                      Text(
                        _isSpinning
                            ? _loc("WOBBLING...", "DÖNÜYOR...", "DREHT SICH...", "GIRANDO...")
                            : _loc("SPIN BOTTLE!", "ŞİŞEYİ ÇEVİR!", "FLASCHE DREHEN!", "¡GIRAR BOTELLA!"),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                ),
              ],
            ),
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
              color: Colors.black.withValues(alpha: 0.62),
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
