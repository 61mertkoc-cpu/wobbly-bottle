import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/room_models.dart';
import '../services/room_service.dart';

class RoomJoinScreen extends StatefulWidget {
  final WobblyGameMode initialMode;
  final bool isVip;
  final int currentLangIndex;
  final Function(String en, String tr, String de, String es, String fr) loc;
  final VoidCallback onBackToMenu;
  final VoidCallback onRoomCreatedOrJoined;

  const RoomJoinScreen({
    super.key,
    required this.initialMode,
    required this.isVip,
    required this.currentLangIndex,
    required this.loc,
    required this.onBackToMenu,
    required this.onRoomCreatedOrJoined,
  });

  @override
  State<RoomJoinScreen> createState() => _RoomJoinScreenState();
}

class _RoomJoinScreenState extends State<RoomJoinScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();

  int _selectedColorIndex = 0;
  bool _isLoading = false;
  String? _errorMessage;

  late WobblyGameMode _selectedMode;

  static const List<Color> _playerColors = [
    Color(0xFF00F2FE), // Cyan
    Color(0xFFFF0844), // Pink/Red
    Color(0xFFFF9500), // Orange
    Color(0xFFAF52DE), // Purple
    Color(0xFFFFCC00), // Yellow
    Color(0xFF34C759), // Green
    Color(0xFF3B82F6), // Electric Blue
    Color(0xFFFF2E93), // Hot Magenta
    Color(0xFFA8FF00), // Neon Lime
    Color(0xFFFF6B4A), // Neon Coral
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _selectedMode = widget.initialMode;
    // Default PIN: 4-digit random
    _pinController.text = (1000 + (DateTime.now().microsecond % 9000)).toString();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _codeController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  String _t(String en, String tr, String de, String es, String fr) {
    return widget.loc(en, tr, de, es, fr);
  }

  Future<void> _handleCreateRoom() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _errorMessage = _t("Please enter your name!", "Lütfen isminizi girin!", "Bitte gib deinen Namen ein!", "¡Por favor ingresa tu nombre!", "Veuillez entrer votre nom !"));
      return;
    }
    final pin = _pinController.text.trim();
    if (pin.length < 4) {
      setState(() => _errorMessage = _t("PIN must be 4 digits!", "Şifre 4 haneli olmalıdır!", "PIN muss 4-stellig sein!", "¡El PIN debe tener 4 dígitos!", "Le code PIN doit comporter 4 chiffres !"));
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final roomCode = RoomService.generateRoomCode();
    final roomService = RoomService();
    roomService.initPlayer(
      name: name,
      colorIndex: _selectedColorIndex,
      isVip: widget.isVip,
    );

    final success = await roomService.createRoom(
      roomCode: roomCode,
      pin: pin,
      mode: _selectedMode,
      selectedPacks: [true, false, false, false, false, false],
    );

    setState(() => _isLoading = false);

    if (success) {
      widget.onRoomCreatedOrJoined();
    } else {
      setState(() => _errorMessage = _t("Failed to create room. Please check internet connection.", "Oda kurulamadı. Lütfen internet bağlantınızı kontrol edin.", "Raum konnte nicht erstellt werden.", "Error al crear sala.", "Échec de création de la salle."));
    }
  }

  Future<void> _handleJoinRoom() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _errorMessage = _t("Please enter your name!", "Lütfen isminizi girin!", "Bitte gib deinen Namen ein!", "¡Por favor ingresa tu nombre!", "Veuillez entrer votre nom !"));
      return;
    }
    final code = _codeController.text.trim().replaceAll(" ", "");
    if (code.length != 6) {
      setState(() => _errorMessage = _t("Room code must be 6 digits!", "Oda kodu 6 haneli olmalıdır!", "Raumcode muss 6-stellig sein!", "¡El código de sala debe ser de 6 dígitos!", "Le code de salle doit comporter 6 chiffres !"));
      return;
    }
    final pin = _pinController.text.trim();
    if (pin.length < 4) {
      setState(() => _errorMessage = _t("Please enter the 4-digit PIN!", "Lütfen 4 haneli oda şifresini girin!", "Bitte gib die 4-stellige PIN ein!", "¡Introduce el PIN de 4 dígitos!", "Veuillez entrer le code PIN à 4 chiffres !"));
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final roomService = RoomService();
    roomService.initPlayer(
      name: name,
      colorIndex: _selectedColorIndex,
      isVip: widget.isVip,
    );

    final err = await roomService.joinRoom(
      roomCode: code,
      pin: pin,
    );

    setState(() => _isLoading = false);

    if (err == null) {
      widget.onRoomCreatedOrJoined();
    } else {
      setState(() => _errorMessage = err);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF030712),
      body: Stack(
        children: [
          // Background matching game theme
          Positioned.fill(
            child: Image.asset(
              'assets/game_bg.png',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.82),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22.0, vertical: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF00F2FE)),
                        onPressed: widget.onBackToMenu,
                      ),
                      const Spacer(),
                      Text(
                        _selectedMode == WobblyGameMode.party
                            ? _t("HOUSE PARTY ROOM", "EV PARTİSİ ODASI", "HAUSPARTY-RAUM", "SALA DE FIESTA", "SALLE DE SOIRÉE")
                            : _t("REMOTE PARTY ROOM", "UZAKTAN PARTİ ODASI", "ONLINE-PARTY-RAUM", "SALA A DISTANCIA", "SALLE À DISTANCE"),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFFFFCC00),
                          letterSpacing: 1.5,
                        ),
                      ),
                      const Spacer(),
                      const SizedBox(width: 48),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Tab Selector: Full-Width 50% / 50% Glowing Switch
                  Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF00F2FE).withValues(alpha: 0.3), width: 1.5),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.transparent,
                      indicator: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF00F2FE), Color(0xFF0090FF)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00F2FE).withValues(alpha: 0.4),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      labelColor: Colors.black,
                      unselectedLabelColor: Colors.white70,
                      labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5),
                      tabs: [
                        Tab(text: _t("CREATE ROOM (HOST)", "ODA KUR (HOST)", "RAUM ERSTELLEN", "CREAR SALA", "CRÉER SALLE")),
                        Tab(text: _t("JOIN ROOM", "ODAYA KATIL", "BEITRETEN", "UNIRSE", "REJOINDRE")),
                      ],
                    ),
                  ),
              const SizedBox(height: 16),

              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildCreateTab(),
                    _buildJoinTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
        ],
      ),
    );
  }

  Widget _buildCreateTab() {
    return ListView(
      physics: const BouncingScrollPhysics(),
      children: [
        _buildCommonPlayerInputs(),
        const SizedBox(height: 16),

        // Room PIN input
        Text(
          _t("ROOM PIN / PASSWORD (4 DIGITS)", "ODA ŞİFRESİ (4 HANELİ PIN)", "RAUM-PIN (4 ZIFFERN)", "PIN DE SALA (4 DÍGITOS)", "CODE PIN DE SALLE (4 CHIFFRES)"),
          style: const TextStyle(color: Color(0xFF00F2FE), fontSize: 13, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _pinController,
          keyboardType: TextInputType.number,
          maxLength: 4,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 4),
          decoration: InputDecoration(
            counterText: "",
            hintText: "1234",
            hintStyle: const TextStyle(color: Colors.white30),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.06),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            prefixIcon: const Icon(Icons.lock, color: Color(0xFFFFCC00)),
          ),
        ),
        const SizedBox(height: 14),

        // VIP Room Perk Banner
        if (widget.isVip)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                const Color(0xFFFFCC00).withValues(alpha: 0.25),
                const Color(0xFFFF9500).withValues(alpha: 0.15),
              ]),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFFFCC00), width: 1.5),
            ),
            child: Row(
              children: [
                const Text("👑", style: TextStyle(fontSize: 22)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _t("VIP ROOM ACTIVATED: +18 Spicy & Golden Champagne unlocked for all players in your room!",
                       "VIP ODA AKTİF: +18 Baharatlı ve Altın Şampanya odanızdaki herkese hediye açıldı!",
                       "VIP-RAUM AKTIV: +18 Scharf & Champagner für alle freigeschaltet!",
                       "¡SALA VIP ACTIVA: +18 Picante y Champán desbloqueados para todos!",
                       "SALLE VIP ACTIVÉE : +18 Épicé et Champagne débloqués pour tous !"),
                    style: const TextStyle(color: Color(0xFFFFCC00), fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 20),

        if (_errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Text(
              _errorMessage!,
              style: const TextStyle(color: Color(0xFFFF0844), fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),

        ElevatedButton(
          onPressed: _isLoading ? null : _handleCreateRoom,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00F2FE),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            elevation: 8,
            shadowColor: const Color(0xFF00F2FE).withValues(alpha: 0.5),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(color: Colors.black, strokeWidth: 3),
                )
              : Text(
                  _t("CREATE ROOM 🚀", "ODAYI OLUŞTUR 🚀", "RAUM ERSTELLEN 🚀", "CREAR SALA 🚀", "CRÉER LA SALLE 🚀"),
                  style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.2),
                ),
        ),
      ],
    );
  }

  Widget _buildJoinTab() {
    return ListView(
      physics: const BouncingScrollPhysics(),
      children: [
        _buildCommonPlayerInputs(),
        const SizedBox(height: 16),

        // Room Code Input (6 digits)
        Text(
          _t("6-DIGIT ROOM CODE", "6 HANELİ ODA KODU", "6-STELLIGER RAUMCODE", "CÓDIGO DE SALA DE 6 DÍGITOS", "CODE DE SALLE À 6 CHIFFRES"),
          style: const TextStyle(color: Color(0xFF00F2FE), fontSize: 13, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _codeController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20, letterSpacing: 8),
          decoration: InputDecoration(
            counterText: "",
            hintText: "849201",
            hintStyle: const TextStyle(color: Colors.white30, letterSpacing: 8),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.06),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            prefixIcon: const Icon(Icons.tag, color: Color(0xFF00F2FE)),
          ),
        ),
        const SizedBox(height: 14),

        // Room PIN Input (4 digits)
        Text(
          _t("ROOM PIN / PASSWORD (4 DIGITS)", "ODA ŞİFRESİ (4 HANELİ PIN)", "RAUM-PIN (4 ZIFFERN)", "PIN DE SALA (4 DÍGITOS)", "CODE PIN DE SALLE (4 CHIFFRES)"),
          style: const TextStyle(color: Color(0xFF00F2FE), fontSize: 13, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _pinController,
          keyboardType: TextInputType.number,
          maxLength: 4,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 4),
          decoration: InputDecoration(
            counterText: "",
            hintText: "PIN",
            hintStyle: const TextStyle(color: Colors.white30),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.06),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            prefixIcon: const Icon(Icons.lock, color: Color(0xFFFFCC00)),
          ),
        ),
        const SizedBox(height: 20),

        if (_errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Text(
              _errorMessage!,
              style: const TextStyle(color: Color(0xFFFF0844), fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),

        ElevatedButton(
          onPressed: _isLoading ? null : _handleJoinRoom,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF0844),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            elevation: 8,
            shadowColor: const Color(0xFFFF0844).withValues(alpha: 0.5),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                )
              : Text(
                  _t("JOIN ROOM 🎮", "ODAYA BAĞLAN 🎮", "RAUM BEITRETEN 🎮", "UNIRSE A SALA 🎮", "REJOINDRE LA SALLE 🎮"),
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.2),
                ),
        ),
      ],
    );
  }

  Widget _buildCommonPlayerInputs() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Name input
        Text(
          _t("YOUR NAME / NICKNAME", "İSMİNİZ / NICK", "DEIN NAME", "TU NOMBRE", "VOTRE NOM"),
          style: const TextStyle(color: Color(0xFF00F2FE), fontSize: 13, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _nameController,
          maxLength: 14,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            counterText: "",
            hintText: _t("e.g. Alex", "Örn. Ayşe", "z.B. Max", "ej. Carlos", "ex. Thomas"),
            hintStyle: const TextStyle(color: Colors.white30),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.06),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            prefixIcon: const Icon(Icons.person, color: Color(0xFF00F2FE)),
          ),
        ),
        const SizedBox(height: 14),

        // Color selector
        Text(
          _t("CHOOSE YOUR NEON COLOR", "NEON RENGİNİ SEÇ", "NEON-FARBE WÄHLEN", "ELIGE TU COLOR NEÓN", "CHOISISSEZ VOTRE COULEUR NÉON"),
          style: const TextStyle(color: Color(0xFF00F2FE), fontSize: 13, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 48,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: _playerColors.length,
            itemBuilder: (ctx, idx) {
              final color = _playerColors[idx];
              final isSelected = _selectedColorIndex == idx;
              return GestureDetector(
                onTap: () => setState(() => _selectedColorIndex = idx),
                child: Container(
                  width: 44,
                  height: 44,
                  margin: const EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color,
                    border: Border.all(
                      color: isSelected ? Colors.white : Colors.transparent,
                      width: 3.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: isSelected ? 0.9 : 0.4),
                        blurRadius: isSelected ? 16 : 8,
                        spreadRadius: isSelected ? 2 : 0,
                      )
                    ],
                  ),
                  child: isSelected ? const Icon(Icons.check, color: Colors.black, size: 22) : null,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
