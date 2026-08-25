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
    Color(0xFF00F2FE),
    Color(0xFFFF0844),
    Color(0xFFFF9500),
    Color(0xFFAF52DE),
    Color(0xFFFFCC00),
    Color(0xFF34C759),
  ];

  static const List<String> objectNames = [
    "Funny Soda Bottle",
    "Squeaky Chicken",
    "Crunchy Pickle",
    "Silly Slipper",
    "Champagne Bottle"
  ];

  static const List<String> packNames = [
    "PARTY AND FUN",
    "DEEP CONFESSIONS",
    "BOLD CHALLENGES / DARES",
    "FLIRT AND COUPLES",
    "💋 +18 SPICY",
    "FREE MODE / ASK OURSELVES"
  ];

  static const Map<String, List<String>> truthQuestions = {
    'EN': [
      "What is your biggest secret?",
      "Who was your first crush?",
      "What is the most embarrassing thing you've ever done?",
      "Have you ever lied to a friend in this room?",
      "What is a guilty pleasure you haven't told anyone?",
      "What is your worst habit?",
    ],
    'TR': [
      "En büyük sırrın nedir?",
      "İlk aşkın kimdi?",
      "Şimdiye kadar yaptığın en utanç verici şey nedir?",
      "Bu odadaki bir arkadaşına hiç yalan söyledin mi?",
      "Gizli tuttuğun en garip alışkanlığın nedir?",
      "En kötü huyun nedir?",
    ],
  };

  static const Map<String, List<String>> dareQuestions = {
    'EN': [
      "Do your best dance move right now for 15 seconds!",
      "Imitate someone in this room until someone guesses who it is!",
      "Speak in a funny accent for the next 2 rounds!",
      "Sing the chorus of your favorite song out loud!",
      "Let the group redesign your hair for the next round!",
    ],
    'TR': [
      "15 saniye boyunca en iyi dans figürünü sergile!",
      "Odadaki birini taklit et, bilene kadar devam et!",
      "Gelecek 2 tur boyunca komik bir şiveyle konuş!",
      "En sevdiğin şarkının nakaratını yüksek sesle söyle!",
      "Grup üyelerinin saçını yeniden şekillendirmesine izin ver!",
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
  final List<bool> _unlockedObjects = [true, true, true, true, true];
  final List<bool> _selectedPacks = [true, false, false, false, false, false];

  String _selectedLang = 'EN';

  // Spin & Arena Animation
  late AnimationController _spinController;
  late Animation<double> _spinAnimation;
  late AnimationController _wobbleController;

  double _currentAngle = 0.0;
  bool _isSpinning = false;
  int _questionerIndex = -1;
  int _answererIndex = -1;

  String _currentPrompt = "Tap SPIN to start!";
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
      _currentPrompt = "Spinning...";
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
          _currentPrompt =
              "${_players[_questionerIndex].name} asks ${_players[_answererIndex].name}!";
        });
      }
    });
  }

  void _showCard(String type) {
    if (_questionerIndex < 0 || _answererIndex < 0) return;
    final questions = type == 'TRUTH'
        ? (WobblyBottleAppGame.truthQuestions[_selectedLang] ??
            WobblyBottleAppGame.truthQuestions['EN']!)
        : (WobblyBottleAppGame.dareQuestions[_selectedLang] ??
            WobblyBottleAppGame.dareQuestions['EN']!);

    final rand = math.Random();
    final q = questions[rand.nextInt(questions.length)];

    setState(() {
      _cardTitle = "$type FOR ${_players[_answererIndex].name.toUpperCase()}";
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
            child: const Text(
              "NEXT SPIN",
              style: TextStyle(color: Color(0xFFFFCC00), fontSize: 16),
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _buildCurrentScreen(),
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
                    errorBuilder: (ctx, _, __) => const Icon(
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
          const Text(
            "FUNNY PARTY GAME",
            style: TextStyle(
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
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
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
              DropdownButton<String>(
                value: _selectedLang,
                dropdownColor: const Color(0xFF0A1828),
                items: const [
                  DropdownMenuItem(value: 'EN', child: Text("🇬🇧 EN")),
                  DropdownMenuItem(value: 'TR', child: Text("🇹🇷 TR")),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _selectedLang = val);
                },
              )
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            "ADD PLAYERS (MIN 2)",
            style: TextStyle(
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
                    hintText: "Enter player name...",
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
          const SizedBox(height: 16),
          // Player Chips Grid
          Expanded(
            child: _players.isEmpty
                ? Center(
                    child: Text(
                      "No players added yet.\nAdd at least 2 players to start!",
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
            child: const Text(
              "NEXT: CHOOSE OBJECT",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
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
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Color(0xFF00F2FE)),
                onPressed: () => setState(() => currentScreen = 1),
              ),
              const Text(
                "CHOOSE YOUR OBJECT",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFFCC00),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.9,
              ),
              itemCount: WobblyBottleAppGame.objectNames.length,
              itemBuilder: (ctx, idx) {
                final selected = _selectedObjectIndex == idx;
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
                        Text(
                          WobblyBottleAppGame.objectNames[idx],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: selected ? Colors.white : Colors.white70,
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
            child: const Text(
              "NEXT: CHOOSE PACKS",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
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
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Color(0xFF00F2FE)),
                onPressed: () => setState(() => currentScreen = 2),
              ),
              const Text(
                "CHOOSE GAME PACKS",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFFCC00),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: WobblyBottleAppGame.packNames.length,
              itemBuilder: (ctx, idx) {
                final sel = _selectedPacks[idx];
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
                            WobblyBottleAppGame.packNames[idx],
                            style: const TextStyle(
                              fontSize: 16,
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
            child: const Text(
              "START GAME ARENA",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }

  // --- SCREEN 4: GAME ARENA ---
  Widget _buildArenaScreen() {
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
              Text(
                _currentPrompt,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFFCC00),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh, color: Color(0xFFFF0844)),
                onPressed: _startSpin,
              ),
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
                                errorBuilder: (ctx, _, __) => const Icon(
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
                        child: const Text(
                          "TRUTH",
                          style: TextStyle(
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
                        child: const Text(
                          "DARE",
                          style: TextStyle(
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
                  _isSpinning ? "SPINNING..." : "SPIN BOTTLE!",
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
