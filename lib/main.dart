import 'dart:async';
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
        return getLoc(langIdx, "Squeaky Chicken", "Bipleyen Tavuk", "Quietsche-Huhn", "Pollo Chillon");
      case 2:
        return getLoc(langIdx, "Wobbly Banana", "Sallanan Muz", "Wackel-Banane", "Platano Tambaleante");
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
        return getLoc(langIdx, "PARTY AND FUN", "PARTİ VE EĞLENCE", "PARTY UND SPASS", "FIESTA Y DIVERSION");
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

  static const Map<String, List<String>> truthQuestions = {
    'EN': [
      "What is your biggest secret?",
      "Who was your first crush?",
      "What is the most embarrassing thing you've ever done?",
      "Have you ever lied to a friend in this room?",
      "What is a guilty pleasure you haven't told anyone?",
      "What is a secret dream you rarely tell anyone?",
      "Which decision changed your life the most?",
      "Name three qualities you admire in the answerer.",
      "What makes a kiss unforgettable?",
    ],
    'TR': [
      "En büyük sırrın nedir?",
      "İlk aşkın kimdi?",
      "Şimdiye kadar yaptığın en utanç verici şey nedir?",
      "Bu odadaki bir arkadaşına hiç yalan söyledin mi?",
      "Gizli tuttuğun en garip alışkanlığın nedir?",
      "Neredeyse kimseye söylemediğin gizli hayalin nedir?",
      "Hangi karar hayatını en çok değiştirdi?",
      "Cevaplayan kişide hayran olduğun üç özelliği söyle.",
      "Bir öpücüğü unutulmaz kılan nedir?",
    ],
    'DE': [
      "Was ist dein größtes Geheimnis?",
      "Wer war dein erster Schwarm?",
      "Was ist das Peinlichste, das du je getan hast?",
      "Hast du jemals einen Freund in diesem Raum angelogen?",
      "Was ist deine heimliche Leidenschaft?",
      "Was ist ein geheimer Traum, den du selten erzählst?",
      "Welche Entscheidung hat dein Leben am meisten verändert?",
      "Nenne drei Eigenschaften, die du am Antworter bewunderst.",
      "Was macht einen Kuss unvergesslich?",
    ],
    'ES': [
      "¿Cuál es tu mayor secreto?",
      "¿Quién fue tu primer amor?",
      "¿Qué es lo más vergonzoso que has hecho?",
      "¿Alguna vez le has mentido a un amigo en este grupo?",
      "¿Cuál es un placer culpable que no le has contado a nadie?",
      "¿Cuál es un sueño secreto que raras veces cuentas?",
      "¿Qué decisión cambió más tu vida?",
      "Menciona tres cualidades que admiras en la persona que responde.",
      "¿Qué hace que un beso sea inolvidable?",
    ],
  };

  static const Map<String, List<String>> dareQuestions = {
    'EN': [
      "Do your best dance move right now for 15 seconds!",
      "Imitate someone in this room until someone guesses who it is!",
      "Speak in a funny accent for the next 2 rounds!",
      "Sing the chorus of your favorite song out loud!",
      "Do your funniest dance for 10 seconds!",
      "Speak in a dramatic movie voice until the next spin.",
      "Let the answerer choose a silly pose for you.",
      "Tell a joke without smiling.",
      "Describe your idea of perfect chemistry.",
    ],
    'TR': [
      "15 saniye boyunca en iyi dans figürünü sergile!",
      "Odadaki birini taklit et, bilene kadar devam et!",
      "Gelecek 2 tur boyunca komik bir şiveyle konuş!",
      "En sevdiğin şarkının nakaratını yüksek sesle söyle!",
      "10 saniye boyunca en komik dansını yap!",
      "Sonraki çevirmeye kadar dramatik bir film sesiyle konuş.",
      "Cevaplayanın senin için komik bir poz seçmesine izin ver.",
      "Gülümsemeden bir fıkra/şaka anlat.",
      "Mükemmel kimya fikrini anlat.",
    ],
    'DE': [
      "Zeige 15 Sekunden lang deinen besten Tanzschritt!",
      "Ahme jemanden in diesem Raum nach, bis jemand es errät!",
      "Sprich die nächsten 2 Runden mit einem lustigen Akzent!",
      "Singe den Refrain deines Lieblingssongs laut vor!",
      "Tanz 10 Sekunden lang deinen lustigsten Tanz!",
      "Sprich bis zum nächsten Drehen mit dramatischer Filmstimme.",
      "Lass den Antworter eine alberne Pose für dich aussuchen.",
      "Erzähle einen Witz ohne zu lächeln.",
      "Beschreibe deine Vorstellung von perfekter Chemie.",
    ],
    'ES': [
      "¡Haz tu mejor paso de baile durante 15 segundos!",
      "¡Imita a alguien de este grupo hasta que lo adivinen!",
      "¡Habla con un acento divertido durante las próximas 2 rondas!",
      "¡Canta el estribillo de tu canción favorita en voz alta!",
      "¡Haz tu baile más divertido durante 10 segundos!",
      "Habla con voz dramática de película hasta el próximo giro.",
      "Deja que la persona que responde elija una pose divertida para ti.",
      "Cuenta un chiste sin sonreír.",
      "Describe tu idea de la química perfecta.",
    ],
  };
}

class MainGameScreen extends StatefulWidget {
  const MainGameScreen({super.key});

  @override
  State<MainGameScreen> createState() => _MainGameScreenState();
}

class _MainGameScreenState extends State<MainGameScreen>
    with TickerProviderStateMixin {
  int currentScreen = 0; // 0: Splash, 1: Setup, 2: Objects, 3: Packs, 4: Arena
  final TextEditingController _nameController = TextEditingController();

  final List<Player> _players = [];
  int _selectedColorIndex = 0;
  int _selectedObjectIndex = 0;
  final List<bool> _selectedPacks = [true, false, false, false, false, false];

  int _currentLangIndex = 0; // 0: EN, 1: TR, 2: DE, 3: ES
  bool _isMuted = false;
  bool _langMenuOpen = false;

  // Spin & Arena Animation
  late AnimationController _spinController;
  late Animation<double> _spinAnimation;
  late AnimationController _wobbleController;

  double _currentAngle = 0.0;
  bool _isSpinning = false;
  int _questionerIndex = -1;
  int _answererIndex = -1;

  String _currentPrompt = "";
  String? _cardTitle;
  String? _cardBody;

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    _wobbleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);

    Timer(const Duration(seconds: 2), () {
      if (mounted && currentScreen == 0) {
        setState(() {
          currentScreen = 1;
        });
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _spinController.dispose();
    _wobbleController.dispose();
    super.dispose();
  }

  String _loc(String en, String tr, String de, String es) {
    return WobblyBottleAppGame.getLoc(_currentLangIndex, en, tr, de, es);
  }

  void _addPlayer() {
    final name = _nameController.text.trim();
    if (name.isNotEmpty) {
      setState(() {
        _players.add(Player(
          name: name,
          color: WobblyBottleAppGame.playerColors[_selectedColorIndex],
        ));
        _nameController.clear();
        _selectedColorIndex = (_selectedColorIndex + 1) %
            WobblyBottleAppGame.playerColors.length;
      });
    }
  }

  void _removePlayer(int index) {
    setState(() {
      _players.removeAt(index);
    });
  }

  void _startSpin() {
    if (_players.length < 2 || _isSpinning) return;

    final rand = math.Random();
    final targetQuestioner = rand.nextInt(_players.length);
    int targetAnswerer;
    do {
      targetAnswerer = rand.nextInt(_players.length);
    } while (targetAnswerer == targetQuestioner && _players.length > 1);

    final extraRounds = 5 + rand.nextInt(4);
    final targetAngleRad =
        (targetAnswerer / _players.length) * 2 * math.pi + (extraRounds * 2 * math.pi);

    setState(() {
      _isSpinning = true;
      _currentPrompt = _loc("Spinning...", "Dönüyor...", "Dreht sich...", "Girando...");
      _questionerIndex = targetQuestioner;
      _answererIndex = -1;
      _cardTitle = null;
    });

    _spinAnimation = Tween<double>(
      begin: _currentAngle % (2 * math.pi),
      end: targetAngleRad,
    ).animate(CurvedAnimation(
      parent: _spinController,
      curve: Curves.decelerate,
    ));

    _spinController.forward(from: 0.0).then((_) {
      if (mounted) {
        setState(() {
          _isSpinning = false;
          _currentAngle = targetAngleRad;
          _answererIndex = targetAnswerer;
          final qName = _players[_questionerIndex].name;
          final aName = _players[_answererIndex].name;
          _currentPrompt = _loc(
            "$qName asks $aName!",
            "$qName, $aName kişisine soruyor!",
            "$qName fragt $aName!",
            "¡$qName le pregunta a $aName!",
          );
        });
      }
    });
  }

  void _showCard(String type) {
    if (_questionerIndex < 0 || _answererIndex < 0) return;
    final langKey = WobblyBottleAppGame.langFlags[_currentLangIndex][1];
    final questions = type == 'TRUTH'
        ? (WobblyBottleAppGame.truthQuestions[langKey] ??
            WobblyBottleAppGame.truthQuestions['EN']!)
        : (WobblyBottleAppGame.dareQuestions[langKey] ??
            WobblyBottleAppGame.dareQuestions['EN']!);

    final rand = math.Random();
    final q = questions[rand.nextInt(questions.length)];

    final targetName = _players[_answererIndex].name.toUpperCase();
    final cardLabel = type == 'TRUTH'
        ? _loc("TRUTH FOR $targetName", "$targetName İÇİN DOĞRULUK", "WAHRHEIT FÜR $targetName", "VERDAD PARA $targetName")
        : _loc("DARE FOR $targetName", "$targetName İÇİN CESARET", "PFLICHT FÜR $targetName", "RETO PARA $targetName");

    setState(() {
      _cardTitle = cardLabel;
      _cardBody = q;
    });

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0A1828),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Color(0xFF00F2FE), width: 2),
        ),
        title: Text(
          _cardTitle!,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: type == 'TRUTH'
                ? const Color(0xFF00F2FE)
                : const Color(0xFFFF0844),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          _cardBody!,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 18, color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              _loc("NEXT SPIN", "SONRAKİ ÇEVİRME", "NÄCHSTES DREHEN", "SIGUIENTE GIRO"),
              style: const TextStyle(color: Color(0xFFFFCC00), fontSize: 16),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildHeaderControls() {
    final currentFlag = WobblyBottleAppGame.langFlags[_currentLangIndex][0];
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Sound Mute Toggle Button
        GestureDetector(
          onTap: () {
            setState(() {
              _isMuted = !_isMuted;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xDC0A1020),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _isMuted
                    ? const Color(0xFFFF5064)
                    : const Color(0xFF00F2FE),
                width: 2,
              ),
            ),
            child: Text(
              _isMuted ? "🔇" : "🔊",
              style: const TextStyle(fontSize: 20),
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Language Selector Button
        GestureDetector(
          onTap: () {
            setState(() {
              _langMenuOpen = !_langMenuOpen;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xDC0A1020),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFFFFCC00),
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Text(currentFlag, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 4),
                const Text("▼", style: TextStyle(fontSize: 12, color: Colors.white)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLanguageMenuModal() {
    if (!_langMenuOpen) return const SizedBox.shrink();
    return GestureDetector(
      onTap: () => setState(() => _langMenuOpen = false),
      child: Container(
        color: Colors.black54,
        child: Center(
          child: Container(
            width: 280,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0F1426),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFFFCC00), width: 2),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _loc("SELECT LANGUAGE", "DİL SEÇİN", "SPRACHE WÄHLEN", "SELECCIONAR IDIOMA"),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFFCC00),
                  ),
                ),
                const SizedBox(height: 12),
                for (int i = 0; i < WobblyBottleAppGame.langFlags.length; i++) ...[
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _currentLangIndex = i;
                        _langMenuOpen = false;
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: _currentLangIndex == i
                            ? const Color(0xFF00F2FE).withOpacity(0.2)
                            : const Color(0xFF051725),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _currentLangIndex == i
                              ? const Color(0xFF00F2FE)
                              : Colors.white12,
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(WobblyBottleAppGame.langFlags[i][0], style: const TextStyle(fontSize: 22)),
                          const SizedBox(width: 12),
                          Text(
                            WobblyBottleAppGame.langFlags[i][2],
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: _currentLangIndex == i
                                  ? const Color(0xFF00F2FE)
                                  : Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                ]
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
      body: SafeArea(
        child: Stack(
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _buildCurrentScreen(),
            ),
            _buildLanguageMenuModal(),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentScreen() {
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
        return _buildSetupScreen();
    }
  }

  // --- SCREEN 0: SPLASH ---
  Widget _buildSplashScreen() {
    return Container(
      key: const ValueKey(0),
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          colors: [Color(0xFFFF0844), Color(0xFF00F2FE), Color(0xFF020611)],
          radius: 1.2,
        ),
      ),
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
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00F2FE).withOpacity(0.6),
                        blurRadius: 30,
                        spreadRadius: 10,
                      )
                    ],
                  ),
                  child: Image.asset(
                    'assets/bent_4_l.png',
                    errorBuilder: (ctx, err, stack) => const Icon(
                      Icons.wine_bar,
                      size: 100,
                      color: Color(0xFF00F2FE),
                    ),
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
          const SizedBox(height: 10),
          Text(
            _loc("FUNNY PARTY GAME", "EĞLENCELİ PARTİ OYUNU", "LUSTIGES PARTY-SPIEL", "DIVERTIDO JUEGO DE FIESTA"),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF00F2FE),
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // --- SCREEN 1: SETUP ---
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
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
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
                child: const Icon(Icons.add, size: 28),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Pick Color selector
          Row(
            children: [
              Text(
                _loc("PICK COLOR:", "RENK SEÇ:", "FARBE WÄHLEN:", "COLOR:"),
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
                        )
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Player Chips Grid
          Expanded(
            child: _players.isEmpty
                ? Center(
                    child: Text(
                      _loc(
                        "No players added yet.\nAdd at least 2 players to start!",
                        "Henüz oyuncu eklenmedi.\nBaşlamak için en az 2 oyuncu ekleyin!",
                        "Noch keine Spieler hinzugefügt.\nFüge mindestens 2 Spieler hinzu!",
                        "Aún no hay jugadores.\n¡Añade al menos 2 jugadores para empezar!",
                      ),
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white.withOpacity(0.6)),
                    ),
                  )
                : ListView.builder(
                    itemCount: _players.length,
                    itemBuilder: (ctx, idx) {
                      final p = _players[idx];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0A1828),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: p.color, width: 2),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: p.color,
                              radius: 16,
                              child: Text(
                                p.name[0].toUpperCase(),
                                style: const TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                p.name,
                                style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.red),
                              onPressed: () => _removePlayer(idx),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 12),
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

  // --- SCREEN 2: OBJECTS ---
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
          const SizedBox(height: 16),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.9,
              ),
              itemCount: 5,
              itemBuilder: (ctx, idx) {
                final selected = _selectedObjectIndex == idx;
                final objName = WobblyBottleAppGame.getObjectName(idx, _currentLangIndex);
                return GestureDetector(
                  onTap: () => setState(() => _selectedObjectIndex = idx),
                  child: Container(
                    decoration: BoxDecoration(
                      color: selected
                          ? const Color(0xFF00F2FE).withOpacity(0.2)
                          : const Color(0xFF0A1828),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected
                            ? const Color(0xFF00F2FE)
                            : Colors.white24,
                        width: selected ? 3 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          idx == 0
                              ? Icons.local_drink
                              : idx == 1
                                  ? Icons.cruelty_free
                                  : idx == 2
                                      ? Icons.spa
                                      : idx == 3
                                          ? Icons.do_not_step
                                          : Icons.wine_bar,
                          size: 56,
                          color: selected
                              ? const Color(0xFFFFCC00)
                              : Colors.white70,
                        ),
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text(
                            objName,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: selected ? Colors.white : Colors.white70,
                            ),
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

  // --- SCREEN 3: PACKS ---
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
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: 6,
              itemBuilder: (ctx, idx) {
                final sel = _selectedPacks[idx];
                final packName = WobblyBottleAppGame.getPackName(idx, _currentLangIndex);
                return GestureDetector(
                  onTap: () =>
                      setState(() => _selectedPacks[idx] = !_selectedPacks[idx]),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: sel
                          ? const Color(0xFFFF0844).withOpacity(0.2)
                          : const Color(0xFF0A1828),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: sel ? const Color(0xFFFF0844) : Colors.white24,
                        width: sel ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          sel ? Icons.check_circle : Icons.circle_outlined,
                          color: sel ? const Color(0xFFFF0844) : Colors.white38,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            packName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
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
              _loc("START GAME ARENA", "OYUNA BAŞLA", "SPIEL ARENA STARTEN", "EMPEZAR ARENA"),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }

  // --- SCREEN 4: GAME ARENA ---
  Widget _buildArenaScreen() {
    final promptText = _currentPrompt.isEmpty
        ? _loc("Tap SPIN to start!", "Başlamak için ÇEVİR'e dokunun!", "Tippe DREHEN zum Starten!", "¡Toca GIRAR para empezar!")
        : _currentPrompt;

    return Column(
      key: const ValueKey(4),
      children: [
        // Top Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.settings, color: Color(0xFF00F2FE)),
                onPressed: () => setState(() => currentScreen = 1),
              ),
              Expanded(
                child: Text(
                  promptText,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFFCC00),
                  ),
                ),
              ),
              _buildHeaderControls(),
            ],
          ),
        ),

        // Arena Center Play Field
        Expanded(
          child: LayoutBuilder(
            builder: (ctx, constraints) {
              final center = Offset(
                  constraints.maxWidth / 2, constraints.maxHeight / 2);
              final radius = math.min(constraints.maxWidth, constraints.maxHeight) *
                  0.36;

              return Stack(
                children: [
                  // Player Circles around Arena
                  for (int i = 0; i < _players.length; i++) ...[
                    Builder(builder: (c) {
                      final angle = (i / _players.length) * 2 * math.pi;
                      final px = center.dx + radius * math.sin(angle);
                      final py = center.dy - radius * math.cos(angle);
                      final isQ = i == _questionerIndex;
                      final isA = i == _answererIndex;

                      return Positioned(
                        left: px - 35,
                        top: py - 35,
                        child: Column(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _players[i].color,
                                border: Border.all(
                                  color: isQ
                                      ? const Color(0xFF00F2FE)
                                      : isA
                                          ? const Color(0xFFFF0844)
                                          : Colors.white,
                                  width: (isQ || isA) ? 4 : 2,
                                ),
                                boxShadow: [
                                  if (isQ || isA)
                                    BoxShadow(
                                      color: isQ
                                          ? const Color(0xFF00F2FE)
                                          : const Color(0xFFFF0844),
                                      blurRadius: 15,
                                      spreadRadius: 4,
                                    )
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  _players[i].name[0].toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
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
                                color: isQ
                                    ? const Color(0xFF00F2FE)
                                    : isA
                                        ? const Color(0xFFFF0844)
                                        : Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      );
                    })
                  ],

                  // Center Bottle / Object Animation
                  Positioned(
                    left: center.dx - 75,
                    top: center.dy - 75,
                    child: GestureDetector(
                      onTap: _startSpin,
                      child: AnimatedBuilder(
                        animation: _spinController,
                        builder: (context, child) {
                          final angle = _isSpinning
                              ? _spinAnimation.value
                              : _currentAngle;
                          final wobble = _isSpinning
                              ? math.sin(_spinController.value * 30) * 0.15
                              : 0.0;

                          return Transform.rotate(
                            angle: angle + wobble,
                            child: Container(
                              width: 150,
                              height: 150,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                              ),
                              child: Image.asset(
                                'assets/bent_4_l.png',
                                errorBuilder: (ctx, err, stack) => const Icon(
                                  Icons.wine_bar,
                                  size: 110,
                                  color: Color(0xFF00F2FE),
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

        // Action Buttons: SPIN, TRUTH, DARE
        Padding(
          padding: const EdgeInsets.all(20.0),
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
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          _loc("TRUTH", "DOĞRULUK", "WAHRHEIT", "VERDAD"),
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _showCard('DARE'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF0844),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          _loc("DARE", "CESARET", "PFLICHT", "RETO"),
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
              ElevatedButton(
                onPressed: _isSpinning ? null : _startSpin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFCC00),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 48, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: Text(
                  _isSpinning
                      ? _loc("SPINNING...", "DÖNÜYOR...", "DREHT SICH...", "GIRANDO...")
                      : _loc("SPIN BOTTLE!", "ŞİŞEYİ ÇEVİR!", "FLASCHE DREHEN!", "¡GIRAR BOTELLA!"),
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
