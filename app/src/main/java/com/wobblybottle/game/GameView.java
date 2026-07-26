package com.wobblybottle.game;

import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.BlurMaskFilter;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.LinearGradient;
import android.graphics.Matrix;
import android.graphics.Paint;
import android.graphics.Path;
import android.graphics.Rect;
import android.graphics.RectF;
import android.graphics.Shader;
import android.os.SystemClock;
import android.view.MotionEvent;
import android.view.View;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Locale;
import java.util.Random;

public class GameView extends View {
    public static final int SCREEN_SETUP = 0;
    public static final int SCREEN_OBJECTS = 1;
    public static final int SCREEN_PACKS = 2;
    public static final int SCREEN_ARENA = 3;

    public interface NameProvider {
        String getName();
        void clearName();
        void focusName();
    }
    public interface ScreenListener { void onScreenChanged(int screen); }

    private static final float VW = 1080f;
    private static final float VH = 1920f;
    private static final int[] PLAYER_COLORS = {
            Color.rgb(0, 242, 254), Color.rgb(255, 8, 68), Color.rgb(255, 149, 0),
            Color.rgb(175, 82, 222), Color.rgb(255, 204, 0), Color.rgb(52, 199, 89)
    };
    private static final String[] OBJECT_NAMES = {
            "Funny Soda Bottle", "Squeaky Chicken", "Crunchy Pickle",
            "Silly Slipper", "Champagne Bottle"
    };
    private static final String[] PACK_NAMES = {
            "PARTY AND FUN", "DEEP CONFESSIONS", "BOLD CHALLENGES\n/ DARES",
            "FLIRT AND COUPLES", "💋  +18 SPICY", "FREE MODE\n/ ASK OURSELVES"
    };

    private final Paint p = new Paint(Paint.ANTI_ALIAS_FLAG | Paint.FILTER_BITMAP_FLAG);
    private final Paint glow = new Paint(Paint.ANTI_ALIAS_FLAG);
    private final Random random = new Random();
    private final List<Player> players = new ArrayList<>();
    private final boolean[] unlockedObjects = {true, false, false, false, false};
    private final boolean[] selectedPacks = {true, false, false, false, false, false};
    private final float[] starX = new float[64];
    private final float[] starY = new float[64];
    private final float[] starR = new float[64];

    private NameProvider nameProvider;
    private ScreenListener screenListener;
    private Bitmap objectSheet;
    private Bitmap packSheet;
    private Bitmap bgBitmap;
    private Bitmap[] objectIcons = new Bitmap[5];
    // Pre-generated bent sprites: [objectIndex][directionIndex]
    // Directions: 0 (Up), ur (+45°), r (+90°), dr (+135°), ul (-45°), l (-90°), dl (-135°)
    private Bitmap[][] bentIcons;
    private static final String[] BEND_CODES = {"0", "ur", "r", "dr", "ul", "l", "dl"};
    private static final float[] BEND_ANGLES_DEG = {0f, 45f, 90f, 135f, -45f, -90f, -135f};
    private static final int BENT_SIZE = 800; // OUT_SIZE from BendGen (800x800)
    private int screen = SCREEN_SETUP;
    private int selectedColor = 0;
    private int selectedObject = 0;
    private boolean online;
    private boolean running = true;
    private boolean profileOpen;
    private boolean vip;
    private boolean vipOfferOpen;

    private boolean adActive;
    private long adStarted;
    private int adUnlockIndex = -1;

    private boolean spinning;
    private long spinStarted;
    private long spinDuration;
    private float startAngle;
    private float targetAngle;
    private float currentAngle = -25;
    private float bendAmount;
    private float bendPhase;
    private long nextBendChange;
    private int questioner = -1;
    private int answerer = -1;
    private int selectedQ = -1;
    private int selectedA = -1;

    // Dynamic Language System
    public static final int LANG_EN = 0;
    public static final int LANG_TR = 1;
    public static final int LANG_DE = 2;
    public static final int LANG_FR = 3;
    public static final int LANG_ES = 4;
    public static final int LANG_RU = 5;
    private int selectedLanguage = LANG_EN; // Default to EN (English) as requested!

    private static final String[] LANG_NAMES = {
        "🇬🇧 English",
        "🇹🇷 Türkçe",
        "🇩🇪 Deutsch",
        "🇫🇷 Français",
        "🇪🇸 Español",
        "🇷🇺 Русский"
    };

    public boolean isTurkish() { return selectedLanguage == LANG_TR; }
    private boolean isTR() { return selectedLanguage == LANG_TR; }

    private String getObjectName(int index) {
        switch (selectedLanguage) {
            case LANG_TR:
                switch (index) {
                    case 0: return "Komik Gazoz Şişesi";
                    case 1: return "Öten Tavuk";
                    case 2: return "Çıtır Turşu";
                    case 3: return "Çılgın Terlik";
                    case 4: return "Şampanya Şişesi";
                }
                break;
            case LANG_DE:
                switch (index) {
                    case 0: return "Lustige Flasche";
                    case 1: return "Quietsche-Huhn";
                    case 2: return "Knackige Gurke";
                    case 3: return "Verrückter Hausschuh";
                    case 4: return "Champagnerflasche";
                }
                break;
            case LANG_FR:
                switch (index) {
                    case 0: return "Bouteille Rigolote";
                    case 1: return "Poulet Cuineur";
                    case 2: return "Cornichon Croustillant";
                    case 3: return "Chaussons Rigolos";
                    case 4: return "Bouteille de Champagne";
                }
                break;
            case LANG_ES:
                switch (index) {
                    case 0: return "Botella Divertida";
                    case 1: return "Pollo Chillón";
                    case 2: return "Pepinillo Crujiente";
                    case 3: return "Pantufla Loca";
                    case 4: return "Botella de Champán";
                }
                break;
            case LANG_RU:
                switch (index) {
                    case 0: return "Смешная бутылка";
                    case 1: return "Пищащая курица";
                    case 2: return "Хрустящий огурчик";
                    case 3: return "Безумный тапочек";
                    case 4: return "Бутылка шампанского";
                }
                break;
        }
        return OBJECT_NAMES[index];
    }

    private String getPackName(int index) {
        switch (selectedLanguage) {
            case LANG_TR:
                switch (index) {
                    case 0: return "PARTİ VE EĞLENCE";
                    case 1: return "DERİN İTİRAFLAR";
                    case 2: return "CESUR GÖREVLER";
                    case 3: return "FLÖRT VE ÇİFTLER";
                    case 4: return "+18 ATEŞLİ";
                    case 5: return "SERBEST MOD";
                }
                break;
            case LANG_DE:
                switch (index) {
                    case 0: return "PARTY & SPASS";
                    case 1: return "TIEFE GESTÄNDNISSE";
                    case 2: return "MUTPROBEN";
                    case 3: return "FLIRT & PÄRCHEN";
                    case 4: return "+18 HEISS";
                    case 5: return "FREIER MODUS";
                }
                break;
            case LANG_FR:
                switch (index) {
                    case 0: return "FÊTE ET AMUSEMENT";
                    case 1: return "CONFESSIONS PROFONDES";
                    case 2: return "DÉFIS AUDACIEUX";
                    case 3: return "FLIRT ET COUPLES";
                    case 4: return "+18 ÉROTIQUE";
                    case 5: return "MODE LIBRE";
                }
                break;
            case LANG_ES:
                switch (index) {
                    case 0: return "FIESTA Y DIVERSIÓN";
                    case 1: return "CONFESIONES PROFUNDAS";
                    case 2: return "RETOS ATREVIDOS";
                    case 3: return "FLIRT Y PAREJAS";
                    case 4: return "+18 PICANTE";
                    case 5: return "MODO LIBRE";
                }
                break;
            case LANG_RU:
                switch (index) {
                    case 0: return "ВЕЧЕРИНКА И ВЕСЕЛЬЕ";
                    case 1: return "ГЛУБОКИЕ ПРИЗНАНИЯ";
                    case 2: return "СМЕЛЫЕ ВЫЗОВЫ";
                    case 3: return "ФЛИРТ И ПАРЫ";
                    case 4: return "+18 ГОРЯЧО";
                    case 5: return "СВОБОДНЫЙ РЕЖИМ";
                }
                break;
        }
        return PACK_NAMES[index].replace("\n", " ");
    }

    // Truth & Dare Deck System
    private boolean typeChoiceModalOpen = false;
    private boolean drawnCardModalOpen = false;
    private String drawnCardType = "TRUTH";
    private String drawnCardPackName = "PARTY AND FUN";
    private String drawnCardText = "";
    private String currentPrompt = "Tap the object to spin!";

    private float drawScale = 1f;
    private float drawOffsetX;
    private float drawOffsetY;

    // SoundPool Custom Audio Effects System
    private android.media.SoundPool soundPool;
    private int[] soundObjects = new int[5]; // 0: soda, 1: chicken, 2: pickle, 3: slipper, 4: champagne
    private int soundCard;

    private void initSounds(Context context) {
        try {
            if (android.os.Build.VERSION.SDK_INT >= 21) {
                android.media.AudioAttributes attrs = new android.media.AudioAttributes.Builder()
                        .setUsage(android.media.AudioAttributes.USAGE_GAME)
                        .setContentType(android.media.AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .build();
                soundPool = new android.media.SoundPool.Builder()
                        .setMaxStreams(6)
                        .setAudioAttributes(attrs)
                        .build();
            } else {
                soundPool = new android.media.SoundPool(6, android.media.AudioManager.STREAM_MUSIC, 0);
            }
            soundObjects[0] = soundPool.load(context, R.raw.sound_soda, 1);
            soundObjects[1] = soundPool.load(context, R.raw.sound_chicken, 1);
            soundObjects[2] = soundPool.load(context, R.raw.sound_pickle, 1);
            soundObjects[3] = soundPool.load(context, R.raw.sound_slipper, 1);
            soundObjects[4] = soundPool.load(context, R.raw.sound_champagne, 1);
            soundCard = soundPool.load(context, R.raw.sound_card, 1);
        } catch (Exception ignored) {}
    }

    private void playObjectSound(int index) {
        if (soundPool != null && index >= 0 && index < 5 && soundObjects[index] != 0) {
            soundPool.play(soundObjects[index], 1.0f, 1.0f, 1, 0, 1.0f);
        }
    }

    private void playCardSound() {
        if (soundPool != null && soundCard != 0) {
            soundPool.play(soundCard, 1.0f, 1.0f, 1, 0, 1.0f);
        }
    }

    public GameView(Context context) {
        super(context);
        setLayerType(View.LAYER_TYPE_SOFTWARE, null);
        objectSheet = BitmapFactory.decodeResource(getResources(), R.drawable.object_sheet_alpha);
        packSheet = BitmapFactory.decodeResource(getResources(), R.drawable.pack_sheet);
        bgBitmap = BitmapFactory.decodeResource(getResources(), R.drawable.game_bg);
        sliceObjectSheet();
        loadBentSprites();
        initSounds(context);
        for (int i = 0; i < starX.length; i++) {
            starX[i] = random.nextFloat() * VW;
            starY[i] = random.nextFloat() * VH;
            starR[i] = 1f + random.nextFloat() * 3.5f;
        }
        p.setTypeface(android.graphics.Typeface.create("sans", android.graphics.Typeface.NORMAL));
    }

    private void sliceObjectSheet() {
        if (objectSheet == null) return;
        int cell = objectSheet.getWidth() / 5;
        for (int i = 0; i < 5; i++) {
            int x = i * cell;
            int w = i == 4 ? objectSheet.getWidth() - x : cell;
            objectIcons[i] = Bitmap.createBitmap(objectSheet, x, 0, w, objectSheet.getHeight());
        }
    }

    private void loadBentSprites() {
        bentIcons = new Bitmap[5][BEND_CODES.length];
        for (int obj = 0; obj < 5; obj++) {
            for (int ai = 0; ai < BEND_CODES.length; ai++) {
                String code = BEND_CODES[ai];
                String name = "bent_" + obj + "_" + code;
                int resId = getResources().getIdentifier(
                        name, "drawable", getContext().getPackageName());
                if (resId != 0) {
                    bentIcons[obj][ai] = BitmapFactory.decodeResource(getResources(), resId);
                }
            }
        }
    }

    public void setNameProvider(NameProvider provider) { nameProvider = provider; }
    public void setScreenListener(ScreenListener listener) { screenListener = listener; }
    public int getScreen() { return screen; }
    public void setOnline(boolean value) { online = value; invalidate(); }
    public void pauseAnimation() { running = false; }
    public void resumeAnimation() { running = true; postInvalidateOnAnimation(); }

    private void goTo(int target) {
        screen = target;
        profileOpen = false;
        vipOfferOpen = false;
        if (screenListener != null) screenListener.onScreenChanged(target);
        invalidate();
    }

    @Override
    protected void onSizeChanged(int w, int h, int oldw, int oldh) {
        drawScale = Math.min(w / VW, h / VH);
        drawOffsetX = (w - VW * drawScale) / 2f;
        drawOffsetY = (h - VH * drawScale) / 2f;
    }

    @Override
    protected void onDraw(Canvas canvas) {
        super.onDraw(canvas);
        canvas.drawColor(Color.rgb(2, 6, 17));
        canvas.save();
        canvas.translate(drawOffsetX, drawOffsetY);
        canvas.scale(drawScale, drawScale);
        drawBackground(canvas);
        if (screen == SCREEN_SETUP) drawSetup(canvas);
        else if (screen == SCREEN_OBJECTS) drawObjects(canvas);
        else if (screen == SCREEN_PACKS) drawPacks(canvas);
        else drawArena(canvas);

        if (profileOpen) drawProfile(canvas);
        if (vipOfferOpen) drawVipOffer(canvas);
        if (adActive) drawRewardedAd(canvas);
        if (!online) drawOffline(canvas);
        canvas.restore();

        if (running && (spinning || adActive || screen == SCREEN_ARENA)) {
            postInvalidateOnAnimation();
        }
    }

    private void drawBackground(Canvas c) {
        p.clearShadowLayer();
        p.setShader(null);
        if (bgBitmap != null) {
            c.drawBitmap(bgBitmap, null, new RectF(0, 0, VW, VH), p);
            return;
        }
        p.setShader(new LinearGradient(0, 0, VW, VH,
                new int[]{Color.rgb(1, 10, 24), Color.rgb(11, 6, 25), Color.rgb(1, 8, 20)},
                null, Shader.TileMode.CLAMP));
        c.drawRect(0, 0, VW, VH, p);
        p.setShader(null);

        for (int i = 0; i < starX.length; i++) {
            int color = (i % 5 == 0) ? Color.rgb(255, 204, 0)
                    : (i % 3 == 0 ? Color.rgb(255, 8, 160) : Color.rgb(0, 242, 254));
            p.setColor(withAlpha(color, 75 + (i % 4) * 22));
            c.drawCircle(starX[i], starY[i], starR[i], p);
        }
        p.setColor(Color.argb(30, 0, 242, 254));
        for (int y = 1400; y < 1920; y += 70) c.drawLine(0, y, VW, y, p);
        for (int x = -400; x < 1480; x += 120) c.drawLine(540, 1310, x, 1920, p);
    }

    private void drawLogo(Canvas c, float y, boolean multicolor) {
        String top = "WOBBLY";
        String bottom = "BOTTLE";
        if (!multicolor) {
            neonText(c, top, 540, y, 104, Color.rgb(255, 204, 0), Paint.Align.CENTER);
            neonText(c, bottom, 540, y + 105, 104, Color.rgb(0, 242, 254), Paint.Align.CENTER);
        } else {
            int[] cols = {0xFF70FF67, 0xFFFF4ED8, 0xFFFFD83D, 0xFF00F2FE};
            drawRainbowWord(c, top, 540, y, 86, cols);
            drawRainbowWord(c, bottom, 540, y + 90, 86, new int[]{cols[1], cols[2], cols[0], cols[3]});
        }
    }

    private void drawRainbowWord(Canvas c, String text, float centerX, float y, float size, int[] colors) {
        p.setTypeface(android.graphics.Typeface.DEFAULT_BOLD);
        p.setTextSize(size);
        float total = p.measureText(text);
        float x = centerX - total / 2f;
        for (int i = 0; i < text.length(); i++) {
            String ch = String.valueOf(text.charAt(i));
            int col = colors[i % colors.length];
            p.setColor(col);
            p.setStyle(Paint.Style.STROKE);
            p.setStrokeWidth(5);
            p.setShadowLayer(16, 0, 0, col);
            c.drawText(ch, x, y, p);
            p.setStyle(Paint.Style.FILL);
            p.setColor(Color.rgb(10, 20, 32));
            c.drawText(ch, x, y, p);
            x += p.measureText(ch);
        }
        p.clearShadowLayer();
        p.setTypeface(android.graphics.Typeface.DEFAULT);
    }

    private void drawSetup(Canvas c) {
        drawLogo(c, 155, false);
        neonText(c, isTR() ? "OYUNCU EKLE" : "ADD PLAYERS", 100, 318, 42, Color.WHITE, Paint.Align.LEFT);
        neonRoundRect(c, new RectF(78, 330, 1002, 545), 34,
                Color.rgb(0, 242, 254), Color.argb(140, 4, 25, 38), 4, 18);

        // Circular Neon '+' Add Button centered at (645, 430)
        float plusCx = 645, plusCy = 430, plusR = 42;
        p.setColor(Color.argb(160, 8, 22, 38));
        p.setStyle(Paint.Style.FILL);
        c.drawCircle(plusCx, plusCy, plusR, p);

        p.setStyle(Paint.Style.STROKE);
        p.setStrokeWidth(4);
        p.setColor(Color.rgb(0, 242, 254));
        p.setShadowLayer(16, 0, 0, Color.rgb(0, 242, 254));
        c.drawCircle(plusCx, plusCy, plusR, p);
        p.clearShadowLayer();
        p.setStyle(Paint.Style.FILL);

        neonText(c, "+", plusCx, plusCy + 22, 64, Color.rgb(255, 224, 55), Paint.Align.CENTER);

        // Right Color Palette centered at x = 835
        p.setTextSize(24);
        p.setTypeface(android.graphics.Typeface.DEFAULT_BOLD);
        p.setTextAlign(Paint.Align.CENTER);
        p.setColor(Color.rgb(155, 245, 255));
        c.drawText(isTR() ? "RENK SEÇİN" : "PICK COLOR", 835, 365, p);
        for (int i = 0; i < PLAYER_COLORS.length; i++) {
            float x = 760 + (i % 3) * 75;
            float y = 412 + (i / 3) * 65;
            p.setColor(PLAYER_COLORS[i]);
            p.setShadowLayer(i == selectedColor ? 22 : 9, 0, 0, PLAYER_COLORS[i]);
            c.drawCircle(x, y, i == selectedColor ? 23 : 18, p);
            if (i == selectedColor) {
                p.setStyle(Paint.Style.STROKE);
                p.setStrokeWidth(5);
                p.setColor(Color.WHITE);
                c.drawCircle(x, y, 28, p);
                p.setStyle(Paint.Style.FILL);
            }
        }
        p.clearShadowLayer();

        if (players.isEmpty()) {
            p.setColor(Color.argb(145, 200, 225, 235));
            p.setTextAlign(Paint.Align.CENTER);
            p.setTypeface(android.graphics.Typeface.DEFAULT_BOLD);
            p.setTextSize(38);
            c.drawText(isTR() ? "OYUNCU LİSTENİZ BOŞ" : "YOUR PLAYER LIST IS EMPTY", 540, 780, p);
            p.setTypeface(android.graphics.Typeface.DEFAULT);
            p.setTextSize(28);
            p.setColor(Color.argb(120, 170, 210, 220));
            c.drawText(isTR() ? "Devam etmek için en az 2 oyuncu ekleyin" : "Add at least 2 players to continue", 540, 832, p);
            drawEmptyFaces(c);
        } else {
            for (int i = 0; i < players.size(); i++) {
                int col = i % 2;
                int row = i / 2;
                float left = 78 + col * 506;
                float top = 585 + row * 190;
                drawPlayerCard(c, players.get(i), new RectF(left, top, left + 448, top + 145));
            }
        }

        boolean enabled = players.size() >= 2;
        drawActionButton(c, new RectF(120, 1640, 960, 1785),
                isTR() ? "NESNELERE GEÇ" : "CONTINUE TO OBJECTS", enabled,
                enabled ? Color.rgb(255, 204, 0) : Color.rgb(75, 90, 105));
        p.setTextAlign(Paint.Align.CENTER);
        p.setTextSize(24);
        p.setColor(enabled ? Color.rgb(130, 230, 235) : Color.rgb(85, 100, 110));
        c.drawText(players.size() + (isTR() ? " OYUNCU" : " PLAYER" + (players.size() == 1 ? "" : "S")), 540, 1825, p);
    }

    private void drawEmptyFaces(Canvas c) {
        for (int i = 0; i < 3; i++) {
            float x = 390 + i * 150;
            float y = 960 + (i % 2) * 40;
            p.setStyle(Paint.Style.STROKE);
            p.setStrokeWidth(4);
            p.setColor(Color.argb(75, 0, 242, 254));
            c.drawCircle(x, y, 47, p);
            p.setStyle(Paint.Style.FILL);
            p.setTextSize(43);
            p.setTextAlign(Paint.Align.CENTER);
            p.setColor(Color.argb(80, 255, 255, 255));
        drawMinimalFace(c, x, y, 47);
        }
    }

    private void drawMinimalFace(Canvas c, float cx, float cy, float r) {
        p.setStyle(Paint.Style.FILL);
        p.setColor(Color.argb(220, 10, 16, 30));

        // Eyes
        float eyeR = r * 0.12f;
        float eyeY = cy - r * 0.12f;
        c.drawCircle(cx - r * 0.30f, eyeY, eyeR, p);
        c.drawCircle(cx + r * 0.30f, eyeY, eyeR, p);

        // Smile Arc
        p.setStyle(Paint.Style.STROKE);
        p.setStrokeWidth(r * 0.11f);
        p.setStrokeCap(Paint.Cap.ROUND);
        RectF mouth = new RectF(cx - r * 0.34f, cy - r * 0.22f, cx + r * 0.34f, cy + r * 0.32f);
        c.drawArc(mouth, 25, 130, false, p);
        p.setStyle(Paint.Style.FILL);
    }

    private void drawPlayerCard(Canvas c, Player player, RectF r) {
        neonRoundRect(c, r, 28, player.color, Color.argb(180, 13, 18, 33), 4, 18);
        p.setColor(player.color);
        p.setShadowLayer(20, 0, 0, player.color);
        c.drawCircle(r.left + 78, r.centerY(), 47, p);
        p.clearShadowLayer();
        drawMinimalFace(c, r.left + 78, r.centerY(), 47);
        neonText(c, ellipsize(player.name, 9), r.left + 148, r.centerY() + 16,
                37, player.color, Paint.Align.LEFT);
        neonText(c, "✕", r.right - 42, r.centerY() + 14, 36, Color.rgb(255, 80, 100), Paint.Align.CENTER);
    }

    private void drawObjects(Canvas c) {
        drawLogo(c, 120, true);
        neonText(c, isTR() ? "NESNENİ SEÇ" : "CHOOSE YOUR OBJECT", 540, 290, 54, Color.WHITE, Paint.Align.CENTER);
        float top = 330;
        for (int i = 0; i < 5; i++) {
            RectF card = new RectF(84, top + i * 235, 996, top + i * 235 + 204);
            boolean selected = selectedObject == i;
            boolean locked = !unlockedObjects[i] && !(i == 4 && vip);
            int border = selected ? Color.rgb(70, 255, 142)
                    : (i == 4 ? Color.rgb(255, 204, 0) : locked ? Color.rgb(190, 79, 255) : Color.rgb(115, 145, 255));
            neonRoundRect(c, card, 28, border, Color.argb(205, 13, 20, 40), selected ? 7 : 3, selected ? 26 : 13);
            drawObjectIcon(c, i, new RectF(card.left + 15, card.top + 12, card.left + 225, card.bottom - 12), false);
            neonText(c, getObjectName(i), card.left + 245, card.top + 75, 42, Color.WHITE, Paint.Align.LEFT);
            if (i == 0 || unlockedObjects[i] || (i == 4 && vip)) {
                neonText(c, selected ? (isTR() ? "✓  SEÇİLİ" : "✓  SELECTED") : (isTR() ? "✓  AÇIK" : "✓  UNLOCKED"), card.left + 245,
                        card.top + 145, 34, Color.rgb(80, 255, 145), Paint.Align.LEFT);
            } else if (i == 4) {
                neonText(c, "♛  VIP", card.left + 245, card.top + 145, 38,
                        Color.rgb(255, 204, 0), Paint.Align.LEFT);
                text(c, isTR() ? "VIP Üyelik ile Aç" : "Unlock as VIP Member", card.right - 28, card.top + 145, 25,
                        Color.rgb(230, 205, 150), Paint.Align.RIGHT, false);
            } else {
                neonText(c, isTR() ? "▣  REKLAM İZLE" : "▣  WATCH AD", card.left + 245, card.top + 137, 35,
                        Color.rgb(255, 195, 53), Paint.Align.LEFT);
                text(c, isTR() ? "1 Video Reklam ile Aç" : "Unlock with 1 Video Ad", card.right - 28, card.top + 176, 24,
                        Color.rgb(220, 215, 235), Paint.Align.RIGHT, false);
            }
        }
        drawActionButton(c, new RectF(130, 1570, 950, 1710),
                isTR() ? "PAKETLERE GEÇ" : "CONTINUE TO PACKS", true, Color.rgb(255, 204, 0));
    }

    private void drawPacks(Canvas c) {
        drawLogo(c, 130, false);
        neonText(c, isTR() ? "PAKETLERİNİ SEÇ" : "CHOOSE YOUR PACKS", 540, 275, 48, Color.WHITE, Paint.Align.CENTER);
        for (int i = 0; i < 6; i++) {
            int col = i % 2, row = i / 2;
            RectF card = new RectF(55 + col * 515, 305 + row * 435,
                    510 + col * 515, 705 + row * 435);
            int border = selectedPacks[i] ? Color.rgb(255, 214, 65) : Color.rgb(70, 79, 110);
            neonRoundRect(c, card, 25, border, Color.rgb(11, 16, 31), selectedPacks[i] ? 7 : 3,
                    selectedPacks[i] ? 25 : 5);
            drawPackImage(c, i, new RectF(card.left + 14, card.top + 14, card.right - 14, card.bottom - 80));

            neonRoundRect(c, new RectF(card.left + 14, card.bottom - 74, card.right - 14, card.bottom - 12),
                    14, Color.TRANSPARENT, Color.argb(200, 5, 10, 20), 0, 0);

            text(c, getPackName(i), card.centerX(), card.bottom - 36,
                    22, selectedPacks[i] ? Color.rgb(255, 224, 75) : Color.WHITE, Paint.Align.CENTER, true);
        }

        boolean enabled = anyPackSelected();
        drawActionButton(c, new RectF(72, 1580, 1008, 1725),
                isTR() ? "OYUNU BAŞLAT" : "START GAME", enabled,
                enabled ? Color.rgb(0, 242, 254) : Color.rgb(75, 90, 105));
    }

    private void drawArena(Canvas c) {
        long now = SystemClock.uptimeMillis();
        updateSpin(now);
        float cx = 540, cy = 710, radius = players.size() <= 4 ? 350 : 405;
        p.setStyle(Paint.Style.STROKE);
        p.setStrokeWidth(5);
        p.setColor(Color.rgb(40, 62, 85));
        c.drawCircle(cx, cy, radius, p);
        p.setStyle(Paint.Style.FILL);

        neonText(c, spinning ? (isTR() ? "ŞİŞE DÖNÜYOR..." : "WOBBLY SPIN...") : (questioner >= 0 ? (isTR() ? "ŞİŞE DİYOR Kİ..." : "BOTTLE SAYS...") : (isTR() ? "ÇEVİRMEK İÇİN DOKUN" : "TAP TO SPIN")),
                540, 215, 47, Color.WHITE, Paint.Align.CENTER);

        for (int i = 0; i < players.size(); i++) {
            double a = -Math.PI / 2 + i * Math.PI * 2 / players.size();
            float x = cx + (float)Math.cos(a) * radius;
            float y = cy + (float)Math.sin(a) * radius;
            boolean active = i == questioner || i == answerer;
            drawAvatar(c, players.get(i), x, y, active);
        }
        drawArenaObject(c, cx, cy, now);

        RectF info = new RectF(50, 1245, 1030, 1600);
        neonRoundRect(c, info, 35, Color.rgb(45, 80, 105), Color.argb(235, 9, 17, 31), 3, 6);
        if (questioner < 0) {
            neonText(c, isTR() ? "HAZIR MIYIZ?" : "READY?", 540, 1345, 54, Color.rgb(0, 242, 254), Paint.Align.CENTER);
            text(c, isTR() ? "Nesneye dokunun — şişe çevrilerek eşleşme sağlanır." : "Tap the object to spin and pick players.", 540, 1415,
                    27, Color.WHITE, Paint.Align.CENTER, false);
            drawActionButton(c, new RectF(210, 1470, 870, 1565),
                    isTR() ? "ŞİŞEYİ ÇEVİR" : "SPIN NOW", !spinning, Color.rgb(0, 242, 254));
        } else {
            Player q = players.get(questioner), a = players.get(answerer);
            text(c, (isTR() ? "SORAN: " : "QUESTIONER: ") + q.name.toUpperCase(Locale.ROOT), 540, 1305,
                    31, q.color, Paint.Align.CENTER, true);
            text(c, (isTR() ? "CEVAPLAYAN: " : "ANSWERER: ") + a.name.toUpperCase(Locale.ROOT), 540, 1349,
                    31, a.color, Paint.Align.CENTER, true);

            boolean isFreeMode = selectedPacks[5];
            if (isFreeMode) {
                drawWrappedCentered(c, isTR() ? "İstediğiniz soruyu sesli olarak sorun!" : "Ask any question you want out loud!", 540, 1405, 800, 27, Color.rgb(180, 230, 255), 36);
                drawActionButton(c, new RectF(210, 1485, 870, 1575),
                        isTR() ? "ŞİŞEYİ ÇEVİR" : "SPIN BOTTLE", !spinning, Color.rgb(0, 242, 254));
            } else {
                drawWrappedCentered(c, isTR() ? "Bir mod seçin: kendiniz sorun veya seçilen destelerden çekin." : "Choose a dynamic: ask yourselves or draw from the selected decks.", 540, 1405, 800, 27, Color.rgb(180, 230, 255), 35);
                drawActionButton(c, new RectF(100, 1498, 510, 1575),
                        isTR() ? "KENDİMİZ SORACAĞIZ" : "ASK OURSELVES", true, Color.rgb(120, 255, 65));
                drawActionButton(c, new RectF(570, 1498, 980, 1575),
                        isTR() ? "DESTEDEN ÇEK" : "DRAW FROM DECK", true, Color.rgb(230, 47, 191));
            }
        }
        drawNavbar(c);

        if (typeChoiceModalOpen) drawTypeChoiceModal(c);
        if (drawnCardModalOpen) drawDrawnCardModal(c);
    }

    private void drawAvatar(Canvas c, Player player, float x, float y, boolean active) {
        long now = SystemClock.uptimeMillis();
        float pulse = active ? 1f + 0.05f * (float)Math.sin(now * 0.008) : 1f;
        float r = (active ? 78 : 66) * pulse;

        if (active) {
            p.setStyle(Paint.Style.FILL);
            p.setColor(withAlpha(player.color, 90));
            p.setShadowLayer(55, 0, 0, player.color);
            c.drawCircle(x, y, r + 16, p);

            p.setStyle(Paint.Style.STROKE);
            p.setStrokeWidth(9);
            p.setColor(player.color);
            p.setShadowLayer(40, 0, 0, player.color);
            c.drawCircle(x, y, r + 10, p);

            p.setStrokeWidth(4);
            p.setColor(Color.WHITE);
            p.setShadowLayer(22, 0, 0, Color.WHITE);
            c.drawCircle(x, y, r + 2, p);

            p.setStrokeWidth(12);
            p.setColor(player.color);
            p.setShadowLayer(35, 0, 0, player.color);
            c.drawCircle(x, y, r, p);
            p.clearShadowLayer();
            p.setStyle(Paint.Style.FILL);
        } else {
            p.setColor(withAlpha(player.color, 60));
            p.setShadowLayer(20, 0, 0, player.color);
            c.drawCircle(x, y, r, p);
            p.clearShadowLayer();
            p.setStyle(Paint.Style.STROKE);
            p.setStrokeWidth(6);
            p.setColor(player.color);
            c.drawCircle(x, y, r, p);
            p.setStyle(Paint.Style.FILL);
        }

        drawMinimalFace(c, x, y, r);
        neonText(c, ellipsize(player.name, 10), x, y + r + 48, 27, Color.WHITE, Paint.Align.CENTER);
    }

    private void drawArenaObject(Canvas c, float cx, float cy, long now) {
        Bitmap icon = objectIcons[selectedObject];
        if (icon == null) return;
        c.save();
        c.translate(cx, cy);

        float pulse = spinning ? 1f + 0.04f * (float)Math.sin(now * .025) : 1f;
        c.scale(pulse, pulse);

        // Always rotate by currentAngle+90f so visual matches the selection system
        c.rotate(currentAngle + 90f);

        if (spinning || questioner < 0 || answerer < 0) {
            // During spin: large wobble bend so spin looks lively
            drawBentBottle(c, icon, bendAmount);
        } else {
            // Settled: use pre-generated directional bent sprite.
            // Delta = angle of answerer relative to cap's natural direction (currentAngle).
            double aRad = -Math.PI / 2 + answerer * Math.PI * 2 / players.size();
            double currentRad = Math.toRadians(currentAngle);
            double delta = aRad - currentRad;
            while (delta >  Math.PI) delta -= 2 * Math.PI;
            while (delta < -Math.PI) delta += 2 * Math.PI;
            float deltaDeg = (float) Math.toDegrees(delta);

            // Find closest directional bend state
            int bestIdx = 0; // default = 0 (straight up)
            float bestDist = Float.MAX_VALUE;
            for (int i = 0; i < BEND_ANGLES_DEG.length; i++) {
                float dist = Math.abs(deltaDeg - BEND_ANGLES_DEG[i]);
                if (dist > 180f) dist = 360f - dist;
                if (dist < bestDist) { bestDist = dist; bestIdx = i; }
            }

            // Draw the pre-generated directional bent sprite (centered at local origin)
            Bitmap bent = (bentIcons != null) ? bentIcons[selectedObject][bestIdx] : null;
            if (bent != null) {
                // 800x800 sprite centered at (0, 0) arena center
                c.drawBitmap(bent, -400f, -400f, p);
            } else {
                drawBentBottle(c, icon, 0f);
            }
        }

        c.restore();
    }

    // Bottle is drawn CENTERED at local origin (0,0) = screen center of player circle.
    // v=0 → BASE (bottom of sprite), v=1 → CAP (top of sprite).
    // py = BOTTLE_H*(0.5 - v): base at +BOTTLE_H/2 (local +Y), cap at -BOTTLE_H/2 (local -Y).
    private static final float BOTTLE_H = 560f;
    private static final float BOTTLE_W = 315f;

    private void drawBentBottle(Canvas c, Bitmap bitmap, float bendPx) {
        int meshW = 8, meshH = 16;
        float[] verts = new float[(meshW + 1) * (meshH + 1) * 2];
        int index = 0;

        for (int y = 0; y <= meshH; y++) {
            // v=0 at BASE (bottom of image), v=1 at CAP (top of image)
            float v = 1f - (y / (float) meshH);

            // CENTERED: middle of bottle is at local origin (screen center)
            // base (v=0) → py = +BOTTLE_H/2  (local +Y = toward questioner)
            // cap  (v=1) → py = -BOTTLE_H/2  (local -Y = toward answerer side)
            float py = BOTTLE_H * (0.5f - v);

            // Spin wobble ripple - multiplied by v so base (v=0) never moves
            float ripple = spinning
                    ? v * (float) Math.sin(v * Math.PI * 3.0 + bendPhase) * bendAmount * 0.12f
                    : 0f;

            // Bending: 0 at base (v=0), full at cap (v=1) — disabled for now (bendPx=0)
            float curve = v * v * bendPx;

            for (int x = 0; x <= meshW; x++) {
                float u = x / (float) meshW;
                float px = (-0.5f + u) * BOTTLE_W + curve + ripple;

                verts[index++] = px;
                verts[index++] = py;
            }
        }

        c.drawBitmapMesh(bitmap, meshW, meshH, verts, 0, null, 0, p);
    }

    private void updateSpin(long now) {
        if (!spinning) {
            bendAmount *= .88f;
            return;
        }
        float t = Math.min(1f, (now - spinStarted) / (float)spinDuration);
        float eased = 1f - (float)Math.pow(1f - t, 4);
        currentAngle = startAngle + (targetAngle - startAngle) * eased;
        if (now >= nextBendChange) {
            bendAmount = (random.nextFloat() * 2f - 1f) * (60 + 80 * (1f - t));
            bendPhase = random.nextFloat() * 6.28f;
            nextBendChange = now + 100 + random.nextInt(140);
        }
        if (t >= 1f) {
            spinning = false;
            currentAngle = normalizeAngle(currentAngle);
            questioner = selectedQ;
            answerer = selectedA;
            currentPrompt = "Choose a dynamic: ask yourselves or draw from the selected decks.";
        }
    }

    private void resolvePlayers() {
        float baseAngle = normalizeAngle(currentAngle + 180f);
        questioner = nearestPlayerForAngle(baseAngle);

        float bendOffset = (bendAmount / 80f) * 45f;
        float tipAngle = normalizeAngle(currentAngle + bendOffset);
        answerer = nearestPlayerForAngle(tipAngle);

        if (questioner == answerer && players.size() > 1) {
            // Find second nearest player to prevent questioner == answerer without bias
            answerer = secondNearestPlayerForAngle(tipAngle, questioner);
        }
        currentPrompt = "Choose a dynamic: ask yourselves or draw from the selected decks.";
    }

    private int secondNearestPlayerForAngle(float degrees, int exclude) {
        double target = Math.toRadians(degrees);
        int best = (exclude + 1) % players.size();
        double bestDiff = Double.MAX_VALUE;
        for (int i = 0; i < players.size(); i++) {
            if (i == exclude) continue;
            double a = -Math.PI / 2 + i * Math.PI * 2 / players.size();
            double d = Math.abs(Math.atan2(Math.sin(target - a), Math.cos(target - a)));
            if (d < bestDiff) { bestDiff = d; best = i; }
        }
        return best;
    }

    private int nearestPlayerForAngle(float degrees) {
        double target = Math.toRadians(degrees);
        int best = 0;
        double bestDiff = Double.MAX_VALUE;
        for (int i = 0; i < players.size(); i++) {
            double a = -Math.PI / 2 + i * Math.PI * 2 / players.size();
            double d = Math.abs(Math.atan2(Math.sin(target - a), Math.cos(target - a)));
            if (d < bestDiff) { bestDiff = d; best = i; }
        }
        return best;
    }

    private void startSpin() {
        if (players.size() < 2 || spinning) return;
        playObjectSound(selectedObject);
        spinning = true;
        questioner = -1;
        answerer = -1;
        currentPrompt = "Wobbling...";
        spinStarted = SystemClock.uptimeMillis();
        spinDuration = 3000 + random.nextInt(1800);
        startAngle = currentAngle;

        // 100% Fair Uniform Random Selection for Questioner and Answerer
        int numPlayers = players.size();
        selectedQ = random.nextInt(numPlayers); // Equal 1/N probability for every player

        selectedA = random.nextInt(numPlayers - 1);
        if (selectedA >= selectedQ) selectedA++; // Equal 1/(N-1) probability for every other player (including immediate neighbors!)

        // Player angles: player i is at angledeg = -90 + i * (360 / N)
        // Base points to Questioner => baseAngle = currentAngle + 180 = playerQ_angle
        // So targetCurrentAngle = playerQ_angle - 180 = 90 + selectedQ * (360 / N)
        float playerQAngle = -90f + selectedQ * (360f / numPlayers);
        float baseTargetAngle = playerQAngle - 180f;

        // Add 4 to 8 full 360-degree rotations for a lively spin animation
        float rotations = (4 + random.nextInt(5)) * 360f;
        targetAngle = startAngle + rotations + (normalizeAngle(baseTargetAngle - startAngle));

        nextBendChange = spinStarted;
        invalidate();
    }

    private void drawNavbar(Canvas c) {
        neonRoundRect(c, new RectF(0, 1665, 1080, 1920), 42,
                Color.rgb(35, 70, 96), Color.argb(245, 2, 10, 24), 3, 6);
        neonText(c, "⌂", 240, 1775, 78, Color.rgb(210, 245, 255), Paint.Align.CENTER);
        text(c, isTR() ? "ANA SAYFA" : "HOME", 240, 1835, 27, Color.WHITE, Paint.Align.CENTER, true);
        drawProfileIcon(c, 840, 1765, vip ? Color.rgb(255, 204, 0) : Color.rgb(0, 242, 254));
        text(c, isTR() ? "PROFİL" : "PROFILE", 840, 1835, 27, vip ? Color.rgb(255, 220, 80) : Color.WHITE,
                Paint.Align.CENTER, true);
    }

    private void drawProfileIcon(Canvas c, float cx, float cy, int color) {
        p.setColor(color);
        p.setShadowLayer(15, 0, 0, color);
        p.setStyle(Paint.Style.FILL);
        // Head circle
        c.drawCircle(cx, cy - 12, 20, p);
        // Shoulder arc
        RectF shoulder = new RectF(cx - 32, cy + 4, cx + 32, cy + 54);
        c.drawArc(shoulder, 195, 150, true, p);
        p.clearShadowLayer();
    }

    private void drawProfile(Canvas c) {
        p.setColor(Color.argb(190, 0, 0, 0));
        c.drawRect(0, 0, 270, VH, p);
        p.setShader(new LinearGradient(270, 0, 1080, 0,
                Color.rgb(10, 11, 32), Color.rgb(4, 21, 34), Shader.TileMode.CLAMP));
        c.drawRect(270, 0, 1080, VH, p);
        p.setShader(null);
        neonText(c, "×", 320, 105, 65, Color.WHITE, Paint.Align.CENTER);
        neonText(c, isTR() ? "PROFİL" : "PROFILE", 650, 112, 48, Color.rgb(0, 242, 254), Paint.Align.CENTER);

        RectF vipCard = new RectF(320, 170, 1030, 420);
        neonRoundRect(c, vipCard, 36, Color.rgb(255, 204, 0),
                Color.argb(230, 45, 30, 5), 6, 28);
        neonText(c, vip ? (isTR() ? "♛ VIP ÜYE" : "♛ VIP MEMBER") : "♛ GO VIP", 675, 255, 55,
                Color.rgb(255, 220, 70), Paint.Align.CENTER);
        text(c, vip ? (isTR() ? "Tüm içerikler açık" : "All premium content is unlocked") : (isTR() ? "Şampanya + Spicy paket kilitlerini aç" : "Unlock Golden Champagne + Spicy pack"),
                675, 316, 27, Color.WHITE, Paint.Align.CENTER, false);
        text(c, vip ? (isTR() ? "AKTİF" : "ACTIVE") : (isTR() ? "İNCELE" : "VIEW OFFER"), 675, 374, 28,
                Color.rgb(255, 220, 70), Paint.Align.CENTER, true);

        // Language Selector Box at (320, 445, 1030, 535)
        RectF langCard = new RectF(320, 445, 1030, 535);
        neonRoundRect(c, langCard, 22, Color.rgb(0, 242, 254), Color.argb(190, 10, 22, 38), 3, 12);
        neonText(c, isTR() ? "DİL" : "LANGUAGE", langCard.left + 35, langCard.centerY() + 10, 26, Color.WHITE, Paint.Align.LEFT);

        // Arrows & Selected Language
        neonText(c, "◀", 590, langCard.centerY() + 10, 32, Color.rgb(0, 242, 254), Paint.Align.CENTER);
        text(c, LANG_NAMES[selectedLanguage], 760, langCard.centerY() + 10, 27, Color.rgb(255, 220, 80), Paint.Align.CENTER, true);
        neonText(c, "▶", 930, langCard.centerY() + 10, 32, Color.rgb(0, 242, 254), Paint.Align.CENTER);

        neonText(c, isTR() ? "NESNEYİ DEĞİŞTİR" : "CHANGE OBJECT NOW", 330, 575, 29, Color.WHITE, Paint.Align.LEFT);
        for (int i = 0; i < 5; i++) {
            float y = 605 + i * 110;
            RectF row = new RectF(320, y, 1030, y + 98);
            boolean available = unlockedObjects[i] || (i == 4 && vip);
            int border = selectedObject == i ? Color.rgb(80, 255, 140)
                    : (i == 4 ? Color.rgb(255, 204, 0) : Color.rgb(130, 78, 190));
            neonRoundRect(c, row, 22, border, Color.argb(190, 12, 18, 34), selectedObject == i ? 5 : 2, 10);
            drawObjectIcon(c, i, new RectF(row.left + 5, row.top + 4, row.left + 115, row.bottom - 4), false);
            text(c, getObjectName(i), row.left + 130, row.centerY() + 10, 27,
                    Color.WHITE, Paint.Align.LEFT, true);
            text(c, available ? (selectedObject == i ? (isTR() ? "SEÇİLİ" : "SELECTED") : (isTR() ? "SEÇ" : "CHOOSE"))
                            : (i == 4 ? "VIP" : "REKLAM"),
                    row.right - 25, row.centerY() + 10, 24, border, Paint.Align.RIGHT, true);
        }

        neonText(c, isTR() ? "AKTİF PAKETLER" : "ACTIVE PACKS", 330, 1175, 29, Color.WHITE, Paint.Align.LEFT);
        for (int i = 0; i < 6; i++) {
            int col = i % 2, row = i / 2;
            RectF r = new RectF(320 + col * 365, 1205 + row * 105,
                    662 + col * 365, 1293 + row * 105);
            int border = selectedPacks[i] ? Color.rgb(255, 204, 0) : Color.rgb(55, 70, 95);
            neonRoundRect(c, r, 20, border, Color.argb(210, 11, 16, 30), selectedPacks[i] ? 4 : 2, 10);
            text(c, ellipsize(getPackName(i), 17), r.centerX(), r.centerY() + 8, 20,
                    Color.WHITE, Paint.Align.CENTER, true);
        }
    }

    private void drawVipOffer(Canvas c) {
        p.setColor(Color.argb(225, 0, 0, 0));
        c.drawRect(0, 0, VW, VH, p);
        RectF box = new RectF(115, 430, 965, 1380);
        neonRoundRect(c, box, 50, Color.rgb(255, 204, 0), Color.rgb(19, 16, 25), 7, 36);
        neonText(c, "♛", 540, 580, 110, Color.rgb(255, 204, 0), Paint.Align.CENTER);
        neonText(c, "WOBBLY VIP", 540, 690, 63, Color.rgb(255, 220, 80), Paint.Align.CENTER);
        text(c, "Premium party upgrade", 540, 750, 31, Color.WHITE, Paint.Align.CENTER, false);
        drawCheck(c, 250, 850, "Golden Champagne");
        drawCheck(c, 250, 930, "+18 Spicy Pack");
        drawCheck(c, 250, 1010, "Instant in-game switching");
        drawActionButton(c, new RectF(210, 1120, 870, 1240),
                vip ? "VIP IS ACTIVE" : "ACTIVATE VIP • DEMO", !vip, Color.rgb(255, 204, 0));
        text(c, "Demo build: no real payment is charged.", 540, 1305, 23,
                Color.rgb(175, 180, 195), Paint.Align.CENTER, false);
        neonText(c, "×", 900, 500, 60, Color.WHITE, Paint.Align.CENTER);
    }

    private void drawCheck(Canvas c, float x, float y, String label) {
        neonText(c, "✓", x, y, 43, Color.rgb(80, 255, 140), Paint.Align.CENTER);
        text(c, label, x + 55, y, 31, Color.WHITE, Paint.Align.LEFT, true);
    }

    private void drawRewardedAd(Canvas c) {
        long elapsed = SystemClock.uptimeMillis() - adStarted;
        if (elapsed >= 5200) {
            unlockedObjects[adUnlockIndex] = true;
            selectedObject = adUnlockIndex;
            adActive = false;
            adUnlockIndex = -1;
            invalidate();
            return;
        }
        p.setColor(Color.argb(238, 0, 0, 0));
        c.drawRect(0, 0, VW, VH, p);
        RectF ad = new RectF(100, 380, 980, 1470);
        neonRoundRect(c, ad, 45, Color.rgb(190, 79, 255), Color.rgb(12, 9, 28), 6, 28);
        neonText(c, "REWARDED VIDEO", 540, 510, 52, Color.rgb(215, 105, 255), Paint.Align.CENTER);
        text(c, "Online sponsored break", 540, 565, 27, Color.WHITE, Paint.Align.CENTER, false);
        float progress = Math.min(1f, elapsed / 5000f);
        p.setColor(Color.rgb(15, 22, 45));
        c.drawRoundRect(new RectF(190, 650, 890, 1050), 34, 34, p);
        for (int i = 0; i < 9; i++) {
            float a = (float)(i * Math.PI * 2 / 9 + elapsed * .0015);
            p.setColor(i % 2 == 0 ? Color.rgb(0, 242, 254) : Color.rgb(255, 8, 160));
            p.setShadowLayer(20, 0, 0, p.getColor());
            c.drawCircle(540 + (float)Math.cos(a) * 120, 850 + (float)Math.sin(a) * 120, 18, p);
        }
        p.clearShadowLayer();
        neonText(c, "▶", 540, 875, 90, Color.WHITE, Paint.Align.CENTER);
        p.setColor(Color.rgb(35, 40, 60));
        c.drawRoundRect(new RectF(190, 1140, 890, 1190), 25, 25, p);
        p.setColor(Color.rgb(190, 79, 255));
        c.drawRoundRect(new RectF(190, 1140, 190 + 700 * progress, 1190), 25, 25, p);
        int remaining = Math.max(0, 5 - (int)(elapsed / 1000));
        neonText(c, remaining > 0 ? "REWARD IN " + remaining : "REWARD EARNED!",
                540, 1285, 38, Color.rgb(255, 210, 80), Paint.Align.CENTER);
        text(c, "Keep the app online until the video completes.", 540, 1360,
                25, Color.rgb(200, 205, 220), Paint.Align.CENTER, false);
    }

    private void drawOffline(Canvas c) {
        p.setColor(Color.argb(244, 1, 4, 12));
        c.drawRect(0, 0, VW, VH, p);
        neonText(c, "NO CONNECTION", 540, 690, 65, Color.rgb(255, 8, 68), Paint.Align.CENTER);
        neonText(c, "⌁", 540, 850, 120, Color.rgb(255, 8, 68), Paint.Align.CENTER);
        text(c, "Wobbly Bottle requires an active internet connection.", 540, 980,
                31, Color.WHITE, Paint.Align.CENTER, true);
        text(c, "Connect to Wi-Fi or mobile data to continue.", 540, 1035,
                27, Color.rgb(170, 190, 205), Paint.Align.CENTER, false);
        neonRoundRect(c, new RectF(260, 1110, 820, 1215), 30,
                Color.rgb(255, 8, 68), Color.rgb(24, 8, 20), 4, 18);
        text(c, "WAITING FOR NETWORK...", 540, 1177, 28,
                Color.rgb(255, 120, 150), Paint.Align.CENTER, true);
    }

    private void drawBack(Canvas c) {
        neonRoundRect(c, new RectF(42, 48, 142, 148), 22,
                Color.rgb(75, 95, 125), Color.rgb(16, 22, 38), 3, 8);
        text(c, "‹", 91, 119, 75, Color.WHITE, Paint.Align.CENTER, false);
    }

    private void drawObjectIcon(Canvas c, int index, RectF dst, boolean arena) {
        Bitmap b = objectIcons[index];
        if (b == null) return;
        p.clearShadowLayer();
        c.drawBitmap(b, null, dst, p);
    }

    private void drawPackImage(Canvas c, int index, RectF dst) {
        if (packSheet == null) return;
        int cellW = packSheet.getWidth() / 2;
        int cellH = packSheet.getHeight() / 3;
        int col = index % 2, row = index / 2;
        int left = col * cellW;
        int top = row * cellH;
        Rect src = new Rect(left, top,
                col == 1 ? packSheet.getWidth() : left + cellW,
                row == 2 ? packSheet.getHeight() : top + cellH);
        c.drawBitmap(packSheet, src, dst, p);
    }

    private void drawActionButton(Canvas c, RectF r, String label, boolean enabled, int color) {
        int border = enabled ? color : Color.rgb(70, 78, 90);
        neonRoundRect(c, r, 32, border, enabled ? Color.rgb(12, 20, 28) : Color.rgb(18, 20, 26),
                enabled ? 7 : 3, enabled ? 28 : 0);
        text(c, label, r.centerX(), r.centerY() + (r.height() > 100 ? 18 : 11),
                r.height() > 100 ? 43 : 28,
                enabled ? Color.WHITE : Color.rgb(95, 102, 112), Paint.Align.CENTER, true);
    }

    private void neonRoundRect(Canvas c, RectF r, float radius, int border, int fill,
                               float stroke, float shadow) {
        p.setStyle(Paint.Style.FILL);
        p.setColor(fill);
        p.clearShadowLayer();
        c.drawRoundRect(r, radius, radius, p);
        p.setStyle(Paint.Style.STROKE);
        p.setStrokeWidth(stroke);
        p.setColor(border);
        if (shadow > 0) p.setShadowLayer(shadow, 0, 0, border);
        c.drawRoundRect(r, radius, radius, p);
        p.clearShadowLayer();
        p.setStyle(Paint.Style.FILL);
    }

    private void neonText(Canvas c, String s, float x, float y, float size, int color, Paint.Align align) {
        p.setTypeface(android.graphics.Typeface.DEFAULT_BOLD);
        p.setTextSize(size);
        p.setTextAlign(align);
        p.setColor(color);
        p.setStyle(Paint.Style.FILL);
        p.setShadowLayer(Math.max(8, size * .22f), 0, 0, color);
        c.drawText(s, x, y, p);
        p.clearShadowLayer();
        p.setTypeface(android.graphics.Typeface.DEFAULT);
    }

    private void text(Canvas c, String s, float x, float y, float size, int color,
                      Paint.Align align, boolean bold) {
        p.clearShadowLayer();
        p.setShader(null);
        p.setStyle(Paint.Style.FILL);
        p.setTypeface(bold ? android.graphics.Typeface.DEFAULT_BOLD : android.graphics.Typeface.DEFAULT);
        p.setTextSize(size);
        p.setTextAlign(align);
        p.setColor(color);
        c.drawText(s, x, y, p);
    }

    private void drawMultilineCentered(Canvas c, String value, float x, float y,
                                       float size, int color, float lineHeight) {
        String[] lines = value.split("\\n");
        float start = y - (lines.length - 1) * lineHeight / 2f;
        for (int i = 0; i < lines.length; i++) {
            text(c, lines[i], x, start + i * lineHeight, size, color, Paint.Align.CENTER, true);
        }
    }

    private void drawWrappedCentered(Canvas c, String value, float x, float y, float maxWidth,
                                     float size, int color, float lineHeight) {
        p.setTypeface(android.graphics.Typeface.DEFAULT);
        p.setTextSize(size);
        String[] words = value.split(" ");
        List<String> lines = new ArrayList<>();
        String current = "";
        for (String word : words) {
            String test = current.isEmpty() ? word : current + " " + word;
            if (p.measureText(test) > maxWidth && !current.isEmpty()) {
                lines.add(current);
                current = word;
            } else current = test;
        }
        if (!current.isEmpty()) lines.add(current);
        for (int i = 0; i < lines.size() && i < 2; i++) {
            text(c, lines.get(i), x, y + i * lineHeight, size, color, Paint.Align.CENTER, false);
        }
    }

    private boolean anyPackSelected() {
        for (boolean b : selectedPacks) if (b) return true;
        return false;
    }

    @Override
    public boolean onTouchEvent(MotionEvent event) {
        if (event.getAction() != MotionEvent.ACTION_UP) return true;
        if (!online || adActive) return true;
        float x = (event.getX() - drawOffsetX) / drawScale;
        float y = (event.getY() - drawOffsetY) / drawScale;
        if (x < 0 || x > VW || y < 0 || y > VH) return true;

        if (vipOfferOpen) {
            if (hit(x, y, 830, 430, 965, 570)) vipOfferOpen = false;
            else if (!vip && hit(x, y, 210, 1120, 870, 1240)) {
                vip = true;
                unlockedObjects[4] = true;
                vipOfferOpen = false;
            }
            invalidate();
            return true;
        }
        if (typeChoiceModalOpen) {
            handleTypeChoiceTouch(x, y);
            invalidate();
            return true;
        }
        if (drawnCardModalOpen) {
            handleDrawnCardTouch(x, y);
            invalidate();
            return true;
        }
        if (profileOpen) {
            handleProfileTouch(x, y);
            invalidate();
            return true;
        }

        if (screen == SCREEN_SETUP) handleSetupTouch(x, y);
        else if (screen == SCREEN_OBJECTS) handleObjectTouch(x, y);
        else if (screen == SCREEN_PACKS) handlePackTouch(x, y);
        else handleArenaTouch(x, y);
        invalidate();
        return true;
    }

    private void handleSetupTouch(float x, float y) {
        if (distance(x, y, 645, 430) < 55) addPlayer();
        for (int i = 0; i < PLAYER_COLORS.length; i++) {
            float cx = 760 + (i % 3) * 75;
            float cy = 412 + (i / 3) * 65;
            if (distance(x, y, cx, cy) < 38) {
                selectedColor = i;
                if (nameProvider != null) nameProvider.focusName();
                return;
            }
        }
        for (int i = 0; i < players.size(); i++) {
            int col = i % 2;
            int row = i / 2;
            float left = 78 + col * 506;
            float top = 585 + row * 190;
            if (hit(x, y, left, top, left + 448, top + 145)) {
                players.remove(i);
                return;
            }
        }
        if (players.size() >= 2 && hit(x, y, 120, 1640, 960, 1785)) goTo(SCREEN_OBJECTS);
    }

    private void addPlayer() {
        if (nameProvider == null || players.size() >= 8) return;
        String name = nameProvider.getName();
        if (name.isEmpty()) {
            nameProvider.focusName();
            return;
        }
        players.add(new Player(ellipsize(name, 14), PLAYER_COLORS[selectedColor]));
        nameProvider.clearName();
        selectedColor = (selectedColor + 1) % PLAYER_COLORS.length;
    }

    private void handleObjectTouch(float x, float y) {
        for (int i = 0; i < 5; i++) {
            float top = 330 + i * 235;
            if (hit(x, y, 84, top, 996, top + 204)) {
                if (i == 4 && !vip) {
                    vipOfferOpen = true;
                } else if (!unlockedObjects[i]) {
                    startRewardedAd(i);
                } else selectedObject = i;
                return;
            }
        }
        if (hit(x, y, 130, 1570, 950, 1710)) goTo(SCREEN_PACKS);
    }

    private void startRewardedAd(int index) {
        adActive = true;
        adUnlockIndex = index;
        adStarted = SystemClock.uptimeMillis();
    }

    private void handlePackTouch(float x, float y) {
        if (hit(x, y, 42, 48, 142, 148)) {
            goTo(SCREEN_OBJECTS);
            return;
        }
        for (int i = 0; i < 6; i++) {
            int col = i % 2, row = i / 2;
            float left = 55 + col * 515;
            float top = 205 + row * 435;
            if (hit(x, y, left, top, left + 455, top + 400)) {
                if (i == 4 && !vip) vipOfferOpen = true;
                else if (i == 5) {
                    // Free Mode: uncheck all card packs 0..4
                    Arrays.fill(selectedPacks, false);
                    selectedPacks[5] = true;
                } else {
                    // Card Pack: uncheck Free Mode (5)
                    selectedPacks[5] = false;
                    selectedPacks[i] = !selectedPacks[i];
                    if (!anyPackSelected()) selectedPacks[i] = true;
                }
                return;
            }
        }
        if (anyPackSelected() && hit(x, y, 72, 1580, 1008, 1725)) goTo(SCREEN_ARENA);
    }

    private void handleArenaTouch(float x, float y) {
        if (hit(x, y, 0, 1665, 540, 1920)) {
            goTo(SCREEN_SETUP);
            return;
        }
        if (hit(x, y, 540, 1665, 1080, 1920)) {
            profileOpen = true;
            return;
        }
        if (distance(x, y, 540, 710) < 320) {
            startSpin();
            return;
        }
        if (questioner < 0) {
            if (hit(x, y, 210, 1470, 870, 1565)) startSpin();
            return;
        }

        boolean isFreeMode = selectedPacks[5];
        if (isFreeMode) {
            if (hit(x, y, 210, 1485, 870, 1575)) startSpin();
        } else {
            if (hit(x, y, 100, 1498, 510, 1575)) {
                currentPrompt = players.get(questioner).name + " asks any question they want out loud!";
            } else if (hit(x, y, 570, 1498, 980, 1575)) {
                typeChoiceModalOpen = true;
            }
        }
    }

    private void handleProfileTouch(float x, float y) {
        if (x < 300 || hit(x, y, 270, 40, 380, 150)) {
            profileOpen = false;
            return;
        }
        if (hit(x, y, 320, 170, 1030, 420)) {
            vipOfferOpen = true;
            return;
        }
        // Language Selector Arrows Touch
        if (hit(x, y, 540, 445, 630, 535)) {
            selectedLanguage = (selectedLanguage + LANG_NAMES.length - 1) % LANG_NAMES.length;
            return;
        }
        if (hit(x, y, 890, 445, 970, 535)) {
            selectedLanguage = (selectedLanguage + 1) % LANG_NAMES.length;
            return;
        }

        for (int i = 0; i < 5; i++) {
            float top = 605 + i * 110;
            if (hit(x, y, 320, top, 1030, top + 98)) {
                if (i == 4 && !vip) vipOfferOpen = true;
                else if (!unlockedObjects[i]) startRewardedAd(i);
                else selectedObject = i;
                return;
            }
        }
        for (int i = 0; i < 6; i++) {
            int col = i % 2, row = i / 2;
            float left = 320 + col * 365;
            float top = 1205 + row * 105;
            if (hit(x, y, left, top, left + 342, top + 88)) {
                if (i == 4 && !vip) vipOfferOpen = true;
                else {
                    selectedPacks[i] = !selectedPacks[i];
                    if (!anyPackSelected()) selectedPacks[i] = true;
                }
                return;
            }
        }
    }

    // --- TRUTH & DARE PACK QUESTIONS (0..4) ---
    private static final String[][] PACK_TRUTHS_TR = {
        { // 0: Parti ve Eğlence
            "Kalabalık bir ortamda başından geçen en eğlenceli ya da utanç verici anı bizimle paylaş!",
            "Şu an bu odadaki birisiyle 1 günlüğüne hayatını takas edebilseydin, kimi seçerdin?",
            "Yalnızken yaptığın ama kimselere söyleyemediğin en tuhaf alışkanlığın ne?",
            "Ciddiyetini hiç bozmadan söylediğin en büyük yalan neydi?",
            "Küçükken arkadaş grubunda sana takılan en eğlenceli takma ad neydi?",
            "Bir anlık heyecanla satın aldığın en lüzumsuz şey neydi?",
            "Arama geçmişindeki en son utanç verici Google aramanı göster bakalım!",
            "Bugüne dek sana verilen en anlamsız ya da kötü hediye neydi?",
            "Çantanda veya ceplerinde şu an taşıdığın en tuhaf nesne nedir?",
            "Cihazındaki en gereksiz duran ama bir türlü silmeye kıyamadığın uygulama hangisi?",
            "Çevrendekilerin henüz keşfetmediği en gizli ve işe yaramaz yeteneğin ne?",
            "Şu anki mesleğin veya okuduğun alan ne olursa olsun, sence sen asıl ne iş yapmalıydın?",
            "Arkadaş grubumuz bir dizi olsaydı, senin karakterin hangi rolde olurdu?",
            "Birlikte tatile veya seyahate çıktığımızda yaptığım en sinir bozucu hareketim ne?",
            "Bir haftalığına buradaki birinin yerine geçebilseydin, bu kim olurdu ve ilk işin ne olurdu?",
            "Ergenlik veya çocukluk döneminden hatırladığın en utanç verici anını anlat!",
            "Tam 1 saatliğine görünmezlik gücün olsaydı ilk ne yapmak isterdin?",
            "Odadaki birinin adını vücuduna dövme yaptırmak zorunda kalsan, kimin adını seçerdin?",
            "Toplum içinde ailenin yaptığı bir hareket yüzünden hiç utandığın oldu mu?",
            "Küçük de olsa hayatında hiç habersiz bir şey aldığın oldu mu (çakmak, kalem vs.)?",
            "Sosyal medyada en son kimin profiline gizlice baktın (stalk yaptın)?",
            "Bugüne kadar tadına baktığın en garip ve çılgın yiyecek neydi?",
            "Bir taksi yolculuğunda başından geçen en tuhaf olay neydi?",
            "Yakın bir dostunun yanındayken yaşadığın en utanç verici an neydi?",
            "Bir günlüğüne köpek olarak doğsaydın, hangi cins olmak isterdin ve nedeni ne?",
            "Kendi yaptığın bir hatayı başkasının üzerine attığın oldu mu hiç?",
            "Bugüne kadar sana takılan en tuhaf takma adın hikayesi nedir?",
            "Arama motorunda en son arattığın kelime veya cümle neydi?",
            "Kendi hayatını bir komedi filmine benzetsen, bu hangi film olurdu?",
            "Seni ne olursa olsun her zaman kahkahaya boğan şey nedir?",
            "Zihninde yer eden en garip veya kafa karıştırıcı rüya neydi?",
            "WhatsApp mesajlaşmanda en son gönderdiğin mesajı gruba sesli oku!",
            "WhatsApp uygulamasında sana gelen en son mesajı sesli şekilde oku!",
            "Tarayıcı geçmişinde açık kalan son üç sekmeyi bizlere göster!",
            "Ailenden birine gönderdiğin en son mesajı sesli oku!",
            "Eski sevgilinin sosyal medyadan bulabileceğin güncel bir fotoğrafını gruba göster!",
            "Galeri uygulamandaki en son 10 fotoğrafı hızlıca göster bakalım!",
            "Galerinde sakladığın en utanç verici veya komik fotoğraf hangisi?"
        },
        { // 1: Derin İtiraflar
            "Neredeyse hiç kimseyle paylaşmadığın en derin hayalin veya hedefin nedir?",
            "Soruyu soran kişiyle ilk karşılaştığındaki fikrin neydi, zamanla ne değişti?",
            "Hayatının gidişatını baştan aşağı değiştiren o tek karar hangisiydi?",
            "Yaptığın ve sana büyük bir ders olan en büyük tecrüben/hatan neydi?",
            "Dışarıdan pek fark edilmeyen ama senin çok önem verdiğin bir özelliğin nedir?",
            "Asla mantığını kavrayamadığın moda akımı veya giyim tarzı hangisi?",
            "Günlük rutinini kolaylaştırmak adına hangi pratik süper güce sahip olmak isterdin?",
            "Kendi parfüm markanı çıkarsan, adı ve ana kokusu ne olurdu?",
            "Benim hakkımda bildiğin ama uzun süre gizlediğin sır neydi?",
            "İlk tanıştığımız an benimle ilgili aklından geçen gerçek düşünce neydi?",
            "Şu an sana bu soruyu yönelten kişiye vereceğin en altın değerindeki tavsiye ne olurdu?",
            "Kişiliğimde veya davranışlarımda seni en çok zorlayan huyum nedir?",
            "Birlikte geçirdiğimiz tüm anılardan sadece birini yeniden yaşama şansın olsa, hangisini seçerdin?",
            "Beni korumak ya da üzmemek adına söylediğin en tuhaf yalan neydi?",
            "Hayatının sonlanacağı tarihi önceden bilme imkanın olsaydı, bilmeyi seçer miydin?",
            "Bir kanunu 24 saatliğine kaldırma yetkin olsaydı, hangi kuralı kaldırırdın?",
            "Bu odada duygusal olarak en az bağ kurabildiğin kişi kim?",
            "Mantık dışı olduğunu bilsen de engel olamadığın en büyük korkun ne?",
            "Ailenin kesinlikle öğrenmesini istemediğin gizli durum nedir?",
            "İzlediğin yapımlardan kendini en çok özdeşleştirdiğin karakter hangisi?",
            "Kendi kişiliğinde dürüstçe kabul ettiğin en belirgin 'Kırmızı Bayrak' (Red Flag) nedir?",
            "Hayatında yanlışlıkla ya da düşünmeden gönderdiğin en utandırıcı mesaj neydi?",
            "Gruba kendinle ilgili bir doğru bir de yanlış bilgi ver, hangisinin gerçek olduğunu tahmin edelim!",
            "Geçmişinden herkesi güldürecek komik bir anını anlat bakalım!",
            "Odadaki herkesin bundan 5 yıl sonra ne yapıyor olacağını tahmin et!",
            "Baş başa bir andayken başına gelen en utandırıcı kazayı anlat!",
            "Geçmiş tecrübelerin veya ilişkin hakkında hiç küçük bir yalan söyledin mi?",
            "Şu anki romantik ve tutkulu hayatına 10 üzerinden kaç puan verirsin?",
            "Bugüne kadar kaç özel ve anlamlı ilişkin oldu?",
            "Şimdiye kadar bir oyunda sana yöneltilen en iddialı soru neydi?"
        },
        { // 2: Cesur Görevler
            "Bir iddia veya oyun uğruna bugüne dek kalkıştığın en çılgınca şey neydi?",
            "Geçmişte seni çok korkutan ama artık aştığın bir çekincen var mı?",
            "Bir sınavda ya da yarışta yakalanmadan kopya çektiğin oldu mu hiç?",
            "Ölmeden önce mutlaka gerçekleştirmek istediğin o çılgın hayal nedir?",
            "Bugüne kadar şahit olduğun en cesurca hareketim neydi?",
            "Instagram'da en son kimin hesabını arattığını duraksamadan göster!",
            "Mutfaktan seçeceğimiz bir baharattan dolu bir çay kaşığı ye!",
            "Bir buz küpünü tamamen eriyip bitene kadar ağzının içinde tut!",
            "Instagram akışında karşına çıkan ilk 10 paylaşımı beğen!",
            "Önümüzdeki 5 dakika boyunca konuşurken sadece fısılda!",
            "Önümüzdeki 5 dakika boyunca tüm cümlelerini yüksek sesle söyle!",
            "Instagram hikayende nostaljik bir fotoğrafını 'tbt' notuyla paylaş!",
            "Seçtiğin popüler bir şarkının nakarat kısmını yüksek sesle söyle!",
            "Odadaki her oyuncunun hangi ünlüye benzediğini söyle ve gerekçesini açıkla!",
            "Odadaki bir oyuncunun koluna tükenmez kalemle geçici bir çizim/dövme yapmasına izin ver!",
            "Grupça bir selfie çekip hikayende 'Harika bir gece' notuyla paylaş!",
            "Sosyal medya akışındaki ilk 3 hikayeye hemen bir yanıt yaz!",
            "Bir dakika boyunca seçilen bir yoga duruşunda dengede kal!",
            "Masadaki 3 farklı içeceği tek bir bardakta karıştırıp iç!",
            "Odadaki 3 farklı kişiye gizemli ve tatlı bir iltifat et!",
            "Instagram akışında gördüğün ilk 3 tanıdık fotoğrafa alev emojisiyle yorum yap!",
            "Kendini en çekici ve özgüvenli hissettiğin anlar hangileridir?",
            "Özel anlarda özgüvenini tepe noktaya çıkaran şey nedir?",
            "Kendi arzuların hakkında keşfettiğin en önemli gerçek ne oldu?",
            "İlişkide asla geçmeyeceğin ve kabul etmeyeceğin mutlak sınırın nedir?"
        },
        { // 3: Flört ve Çiftler
            "Karşı cinste seni ilk anda büyüleyen 3 temel özellik nedir?",
            "Hayatında iz bırakan ilk gençlik veya çocukluk aşkın nasıldı?",
            "Hayallerini süsleyen mükemmel romantik buluşmayı tarif et.",
            "Birinin seni etkilemek için yaptığı en unutulmaz ve zarif jest neydi?",
            "İlişki ve partner tercihlerimi 10 üzerinden puanlasan kaç verirdin ve nedeni ne?",
            "Bana ya da bu gruptan birine karşı hiç gizli bir ilgi (crush) duydun mu?",
            "Bir akşam yemeği için dünyaca ünlü birini seçecek olsan bu kim olurdu?",
            "Gizli bir flört uygulamasında profil açsaydın kullanıcı adın ne olurdu?",
            "Özel bir akşamda çekici görünmek için nasıl bir kıyafet tercih ederdin?",
            "Bu oyunu oynarken odadan biriyle flörtleştiğin oldu mu? İtiraf et!",
            "İlgi duyduğun kişi bu odada olsaydı ona şu an hangi görevi verirdin?",
            "Kötü geçen bir buluşmadan kaçmak için uydurduğun son bahane neydi?",
            "Aynı zaman diliminde iki farklı kişiye ilgi duyduğun oldu mu hiç?",
            "Partnerinin telefonunu gizlice kurcaladığın oldu mu?",
            "Aşk ve tutku uğruna yaptığın en düşüncesizce şey neydi?",
            "Çekici bulduğun birinde gözünün ilk takıldığı fiziksel detay nedir?",
            "Potansiyel bir partnerde en hayran kaldığın fiziksel özellik nedir?",
            "Romantik ilişkilerde eğlenceli aksesuarlar kullanma fikrine nasıl bakıyorsun?",
            "Aşk ve duygu uğruna kalkıştığın en çılgınca adım neydi?",
            "Görür görmez büyülendiğin o ünlü isim kimdir?",
            "Çocukken veya ergenken hayran olduğun ilk ünlü kimdi?",
            "Geçmişte yaşadığın en felaket buluşma deneyimi nasıldı?",
            "Hayatındaki ilk ciddi buluşmanı tüm detaylarıyla anlat!",
            "Bu odada sana göre en çekici duruşa ve fiziğe sahip kişi kim?",
            "Flörtleşme anında seni anında etkisi altına alan detay nedir?",
            "Birini etkilemek istediğinde ilk olarak ne giymeyi seçersin?",
            "Odadaki iki kişinin saç kokusunu karşılaştırıp hangisinin daha iyi olduğunu seç!",
            "Odadakilerin parfüm kokularını değerlendirip en iyi kokuyu ilan et!",
            "Bir oyuncunun seni yanağından veya boynundan nazikçe öpmesine izin ver!",
            "Gruptan seçeceğin biriyle 1 dakika boyunca hiç gözlerini kaçırmadan bakış!",
            "Kimsenin bilmesini istemediğin en iddialı romantik anın nedir?",
            "Birine attığın en cesur ve flörtöz mesaj neydi?",
            "Birini öptüğün en alışılmadık veya sürpriz lokasyon neresiydi?",
            "Duymaktan en çok keyif alacağın iddialı iltifat nedir?",
            "Eski sevgilinin adını taşıyan bir kokteyl hazırlasan içine ne koyardın?",
            "Seni anında romantik moda sokan o özel şarkı hangisi?",
            "Hayalindeki mükemmel öpücüğü anlat: Nerede, nasıl ve hangi atmosferde?",
            "Hangi dünyaca ünlü isim seni romantik hayallere sürüklüyor?",
            "Hangi film sahnesi seni anında tutkulu bir moda sokar?",
            "Seni anında kızartacak ve utandıracak o detay nedir?",
            "İç giyim tercihin: Şık ve çekici mi, rahat mı yoksa ikisi mi?",
            "Sende anında kıvılcım çakan o 'küçük detay' nedir (koku, bakış, kelime)?",
            "Romantik bir ortam yaratmak için çalacağın o mükemmel şarkı hangisi?",
            "Seni anında soğutan ve hevesini kıran o en büyük hata (turn-off) nedir?",
            "Klasik alanlar dışında başkalarında çekici bulduğun vücut detayı nedir?",
            "İlk adımı atıp yakınlaşmayı başlatan taraf hiç sen oldun mu?",
            "Kendi tarzına ve tipine hiç uymayan birine aniden çekildiğin oldu mu?",
            "Hangi parfüm veya ten kokusu seni adeta büyülüyor?",
            "Dünyadaki herhangi biriyle 1 gece geçirme şansın olsa kimi seçerdin?",
            "Partnerine hissettirmekten hoşlandığın en zarif ve duyusal jest nedir?",
            "Hangi ünlüyle unutulmaz romantik bir gece geçirmek isterdin?",
            "Şu an bu odadan kiminle özel bir öpücük paylaşmak isterdin?",
            "Açık havada yaşadığın en son romantik an neredeydi?",
            "Başından geçen en eğlenceli ve komik romantik tecrübe neydi?",
            "Seni ortamda en hızlı şekilde etki altına alan detay nedir?",
            "Bu odada romantik anlarda en başarılı olduğunu düşündüğün kişi kim?",
            "Bir yakınlaşma öncesinde seni anında etkileyen 3 şeyi say!"
        },
        { // 4: +18 Ateşli
            "Tutku ve romantizm dolu anlarda seni en çok ne etkiler?",
            "Unutulmaz bir ten uyumu senin için ne ifade ediyor?",
            "Kendi fiziğinde en beğendiğin ve seksi bulduğun nokta neresidir?",
            "Sadece tek bir kişiyle özel bir gece geçirme şansın olsa odadan kimi seçerdin?",
            "Zihnini meşgul eden en büyük romantik fantezin nedir?",
            "Bu odadan kaç kişiyle romantik bir yakınlaşma yaşayabilirdin?",
            "Özel anlarda çekim gücünün tepe noktasına ulaşması ne kadar sürer?",
            "Romantik bir anda bölünmek için en talihsiz zaman hangisidir?",
            "Hatırladığın en sürreal ve iddialı rüya neydi?",
            "Bu odadan biriyle baş başa kalmak zorunda olsaydın kimi seçerdin?",
            "Yakınlaşma anında yaşadığın en komik veya utandırıcı olay neydi?",
            "Bir arkadaşının partnerine karşı hiç anlık bir çekim hissettin mi?",
            "Birine hiç iddialı veya özel bir fotoğraf gönderdin mi?",
            "Burada dürüstçe paylaşabileceğin en özel fantezin nedir?",
            "Öptüğün veya öpmek istediğin en sıra dışı nokta neresiydi?",
            "Anlık bir yakınlaşma deneyimin oldu mu? Nasıl bir tecrübeydi?",
            "Tutku uğruna göze alabileceğin en cesurca adım nedir?",
            "Uzun ve duyusal bir yakınlaşma mı yoksa hızlı bir başlangıç mı?",
            "Hayatında aldığın en unutulmaz ve çekici iltifat neydi?",
            "Hiç flörtöz veya özel bir fotoğraf/mesaj attın mı?",
            "Loş ve romantik bir ışık mı yoksa tam karanlık mı? Neden?",
            "Bu odadaki birini hiç romantik bir hayalinde veya rüyanda gördün mü?",
            "Sadece yakınlık odaklı bir arkadaşlık (friends with benefits) yaşadın mı?",
            "Özel anlarda senin için en kritik unsur nedir (bağ, duygu, uyum)?",
            "Romantik bir andayken hiç beklenmedik şekilde yakalandın mı?",
            "Vücudunda öpülmekten en çok keyif aldığın özel nokta neresidir?",
            "Şu anki enerjini ve libidonu bir hayvanla simgeleyen hangisi olurdu?",
            "Mutluluk vermek mi, almak mı yoksa ortak bir denge mi?",
            "Kulağına fısıldandığında seni büyüleyecek en etkileyici cümle nedir?",
            "Hiç karşı tarafı kırmamak için orgazm taklidi yaptın mı?",
            "En çok keyif aldığın masaj türü hangisidir (rahatlatıcı, duyusal, enerjik)?",
            "En rahat ettiğin pozisyon hangisidir (uyurken veya özel anlarda)?",
            "Hayatında en çok deneyimlemek istediğin popüler fantezi nedir?",
            "Romantik önlemler konusunda yaşadığın komik bir anı var mı?",
            "Senin için ideal bir yakınlaşma seansının süresi ne kadar olmalı?",
            "Özel anlarda iddialı konuşmalar (dirty talk) hakkında ne düşünüyorsun?",
            "Sürpriz veya yarı açık bir mekanda romantik bir deneyimin oldu mu?",
            "Romantik anlara tatlı yiyecekler (çikolata, krema) dahil ettin mi hiç?",
            "Denemek isteyip de dile getirmeye çekindiğin özel bir detay var mı?",
            "Başından geçen en sıra dışı veya unutulmaz yakınlaşma mekanı neresiydi?",
            "Bir daha asla tekrarlamayacağın o yakınlaşma mekanı neresi?",
            "Özel hayatında dahi ettiğin en çılgınca tecrübe neydi?",
            "İlk tutkulu yakınlaşmanı yaşadığında kaç yaşındaydın?",
            "Hayatındaki ilk özel yakınlaşma deneyimin nasıl geçti?",
            "En sevdiğin ve rahat ettiğin romantik duruş hangisi?",
            "Özel anlarda kendinizi harika hissettiren ana unsur nedir?",
            "Romantik ve eğlenceli aksesuarlar hakkında ne düşünüyorsun?",
            "Hangi rol yapma (roleplay) senaryosunu oldukça çekici buluyorsun?",
            "Hayalindeki ideal ön sevişme senaryosu nasıl olmalı?",
            "Hiç tutkulu bir andayken beklenmedik şekilde basıldın mı?",
            "Zihninde yer eden en iddialı ve tutkulu rüya hangisiydi?",
            "Ne tür içerikler veya filmler seni anında moda sokar?",
            "Solundaki oyuncunun kulağına çok iddialı ve flörtöz bir cümle fısılda!",
            "Sağındaki oyuncunun kolunu koklayarak eğlenceli bir yorum yap!",
            "Kendi rızası olan bir oyuncunun ceket/gömlek düğmesini ağzınla açmaya çalış!",
            "Turdan bir oyuncunun kulağına 10 saniye boyunca tatlı şeyler fısılda!",
            "Hayatının en unutulmaz ve heyecanlı gecesinden tatlı detaylar paylaş!",
            "Rehberinden seçeceğin birine iddialı ve flörtöz bir mesaj at!",
            "Ciddiyetini bozmadan ve gülmeden romantik bir şiir/metin oku!",
            "Bir romantik ürün satıcısı gibi davranıp elindeki eşyayı gruba pazarla!",
            "Dört satırlık romantik ve iddialı bir şiir yazıp grupta oku!",
            "Çalacak bir müzik eşliğinde 30 saniye boyunca özgüvenli bir dans sergile!"
        }
    };

    private static final String[][] PACK_DARES_TR = {
        { // 0: Parti ve Eğlence
            "Müzik olmadan 10 saniye boyunca en komik dansını yap!",
            "Gruptan birinin taklidini yap, kim olduğunu tahmin edene kadar devam et.",
            "Hiç gülmeden ve ciddiyetini bozmadan komik bir şey anlat.",
            "Cevaplayan kişi 2 tur boyunca saçını istediği gibi şekillendirsin!",
            "Odada ağır çekimde podyum yürüyüşü yap!",
            "Çocukluğundan bir çizgi filmin jenerik müziğini söyle. Son ses!",
            "En işe yaramaz gizli yeteneğin ne? Göster bakalım!",
            "Sadece senin komik bulduğun bir fıkra anlat. Biz karar veririz.",
            "En sevdiğin yemeği bir sanat eseriymiş gibi anlat.",
            "Karşındaki kişiyle bakışma kapışması yap. İlk gülen kaybeder!",
            "Hayali bir kulaklık tak ve oyunu bir futbol maçı gibi anlat.",
            "Bardaktan bir şey içmeye çalışan bir T-Rex gibi davran.",
            "3 metre boyunca moonwalk yap. Ya da en azından onurlu bir deneme.",
            "Birinin sana saçma sapan bir saç modeli yapmasına izin ver. Fotoğraf şart.",
            "Bir cipsi veya bisküviyi ellerini kullanmadan ye.",
            "Solundaki kişiye ultra karmaşık bir 'çak bir beşlik' hareketi öner.",
            "30 saniye boyunca bir yengeç gibi ses çıkar ve yürü. Uyarıyorum, zor bir görev.",
            "Telefonunu istediğin bir kişiye ver. YouTube veya TikTok geçmişine bakmak için 30 saniyesi var.",
            "Solundaki kişinin sana gecenin geri kalanı için yeni bir takma ad vermesine izin ver ve kendinden bahsederken bu adı kullan.",
            "Aşırı karmaşık bir dans figürü uydur ve 30 saniyede iki kişiye öğret.",
            "Atıştırmalık tabağından bir yiyeceği ellerini kullanmadan ye.",
            "Arkadaşlarının etrafta buldukları şeylerle sana komik bir saç modeli yapmalarına izin ver. Selfie şart.",
            "Gönderdiğin son mesajı (SMS, WhatsApp, Insta...) sesli oku.",
            "Birinin telefonundan utanç verici bir fotoğraf seçmesine izin ver ve gruba göster.",
            "Grubun bir Instagram/Snapchat filtresi seçmesine izin ver ve onunla bir selfie çek. Grupta paylaş.",
            "Oyunun sonuna kadar biriyle bir aksesuar (yüzük, bileklik, şapka...) değiştir.",
            "Bir müzik aç ve 30 saniye boyunca olabildiğince saçma bir şekilde dans et.",
            "Sosyal medyanda gizemli bir durum/hikaye paylaş (mesela 'Bunu beklemiyordum...').",
            "Hiç hakim olmadığın bir konuda röportaj veriyormuş gibi yap.",
            "Telefonunu sağındaki komşuna ver, rehberindeki ilk kişiye (zararsız!) bir emoji göndersin.",
            "Kendi etrafında 10 kez dön ve sonra düz bir çizgide yürümeye çalış.",
            "Kollarını vücuduna yapıştırıp tiny T-Rex kollarıyla masadan su içmeye çalış!",
            "Sonraki tura kadar gruptaki her olaya ve cümleye aşırı dramatik bir pembe dizi oyuncusu gibi tepki ver!",
            "30 saniye boyunca pili biten bir robot gibi yavaşlayarak ve konuşman bozularak hareket et!",
            "80'ler disko dans figürü uydur ve 20 saniye boyunca hiç durmadan dans et!",
            "Odada kurbağa gibi zıplayarak bir tur at ve her zıplayışta 'Vırak!' de!",
            "Bir sonraki tura kadar sana ne sorulursa sorulsun 'Arama sonuçlarını buldum...' diyerek robotik sesle cevap ver!",
            "Gruptan seçeceğin birine parmağını doğrultup uydurma bir büyü söyle ve ona 1 tur boyunca komik bir kural koy!",
            "Bir sonraki turuna kadar konuştuğun her cümlenin sonuna 'Miyav!' ekle!",
            "Odadaki en hafif eşyayı sanki 200 kilo halter kaldırıyormuş gibi abartılı şekilde havaya kaldır!",
            "Yanındaki kişinin cebinden veya çantasından rastgele çıkaracağı bir şeyi harika bir gurme gibi koklayıp yorumla!",
            "Gruptan birinin parmağıyla yüzüne hayali komik bir resim çizmesine izin ver ve öyle dur!",
            "30 saniye içinde sanki uzaylılar tarafından kaçırılmışsın gibi heyecanlı bir hikaye uydur!",
            "Emziği elinden alınmış bir bebek gibi 15 saniye boyunca komik bir şekilde ağlama taklidi yap!",
            "Solundaki kişinin gözlerinin içine bakarak 'Om...' sesleriyle 20 saniye meditasyon yap!",
            "Kollarını kanat yapıp tavuk gibi gıdaklayarak masanın etrafında bir tur dön!",
            "Son 5 dakikada oyunda yaşanan olayları bir ana haber bülteni spikeri gibi ciddi ciddi sun!",
            "Sanki arkanda dev bir aksiyon patlaması oluyormuş gibi ağır çekimde odanın diğer ucuna koş!",
            "Çömelerek ördek yürüyüşü yap ve odada bir tur at!",
            "Başına hayali bir taç koy ve 2 tur boyunca odadakilere 'Sadık kullarım' diye hitap et!",
            "Odadaki bir eşyayı Gizli Ajan gibi sürünerek veya saklanarak gidip masaya getir!",
            "Yanındaki kişi senin telefonunla en komik ve çirkin açından bir selfie çeksin!",
            "Gruptakilerin belirleyeceği 1 kelimeyi sonraki 3 tur boyunca konuşurken asla kullanma!",
            "Sana söylenecek zor bir Türkçe tekerlemeyi takılmadan 3 kere üst üste söyle!",
            "Yanındaki kişinin elini koklayıp hangi lezzetli yemeği anımsattığını söyle!",
            "Ağzınla 15 saniye boyunca komik bir beatbox ritmi ve ritim şov yap!"
        },
        { // 1: Derin İtiraflar
            "Çemberdeki HERKESE içten ve samimi bir övgü söyle.",
            "Soran kişinin gözlerinin içine hiç gülmeden 15 saniye boyunca bak.",
            "Suçluluk duyduğun küçük bir şeyi komik bir ses tonuyla itiraf et.",
            "Soran kişinin sana sormak istediği 1 serbest soruya dürüstçe cevap ver.",
            "Buradaki her kişiye çok spesifik bir iltifat et.",
            "Ailenden birini ara ve hiçbir neden yokken onu sevdiğini söyle.",
            "Hayatında kimseye söylemediğin en utanç verici anını soran kişinin kulağına fısılda!",
            "Rehberinde kayıtlı uzun süredir konuşmadığın bir arkadaşına 'Sadece nasılsın demek istedim' mesajı at!",
            "Hayatındaki ilk aşkının adını ve ona karşı hissettiğin en komik düşünceyi anlat!",
            "Geçmişte birine haksızlık yapıp pişman olduğun bir olayı anlat ve dersini paylaş!",
            "Odadaki herkes için 'Bence senin en güçlü kişilik özelliğin şu' diyerek samimi yorum yap!",
            "Solundaki kişinin elini tut ve 1 dakika boyunca bir arkadaş olarak ona minnettar olduğun bir şeyi söyle!",
            "Ergenlik döneminde havalı görünmek için yaptığın en saçma hareketi itiraf et!",
            "Odadaki birini seç ve onun 5 yıl sonra nerede, nasıl bir hayat yaşayacağını duygusal şekilde tahmin et!",
            "Seni en kolay ağlatan veya duygusallaştıran şeyin ne olduğunu grupla paylaş!",
            "Telefonunda 'Aşk' veya 'Eski' kelimesini aratıp çıkan ilk masum mesajı sesli oku!",
            "Odadaki en çekingen duran oyuncuya 30 saniye boyunca dürüst ve içten övgüler yağdır!",
            "Odadaki birine 'Seninle ilgili ilk tanıştığımızda yanıldığım tek şey şuydu...' de!",
            "Seni en çok duygulandıran bir şarkının 1 kıtasını mırıldan veya sesli söyle!",
            "Rehberinde kayıtlı en garip veya komik isimli kişiyi gruba göster ve hikayesini anlat!",
            "Hayatında aldığın ve 'İyi ki bu kararı vermişim' dediğin dönüm noktanı anlat!",
            "Galerinden hiç düzenlenmemiş, en doğal ve filtresiz bir halini gruptakilere göster!",
            "Odadaki birine önümüzdeki 1 ay içinde yapacağın ortak bir etkinlik için kesin söz ver!",
            "İnsanlarla arana mesafe koymana neden olan en büyük hata veya hareketi paylaş!"
        },
        { // 2: Cesur Görevler
            "Bir sonraki tura kadar bir film kötüsü gibi dramatik bir sesle konuş!",
            "Grubun senin için seçeceği komik bir pozu 15 saniye boyunca bozmadan dur.",
            "Hayvan sesleri çıkararak 10 şınav veya 15 jumping-jack yap!",
            "Grubun seçeceği ünlü birinin taklidini yap.",
            "Bu oyun için tamamen saçma yeni bir kural uydur.",
            "Bir ünlünün sesine sahip olabilseydin, kimi seçerdin? (Taklidini yap!)",
            "İnsan duygularını yeni keşfeden bir robotmuş gibi davran.",
            "Bir sonraki turuna kadar Karadeniz şivesiyle konuş (Zor, değil mi?).",
            "Ünlü bir video oyunu karakterinin (Mario, Sonic...) sesini çıkar.",
            "Odanın etrafında tek ayak üzerinde seke seke ve alfabeyi tersten söyleyerek bir tur at.",
            "Bir dakika boyunca tamamen donmuş bir manken gibi dur (mümkünse gözlerini kırpmadan!).",
            "45 saniye boyunca dirsekler üzerinde plank yap ve pes etme!",
            "Avucunun içine bir buz küpü al ve eriyene kadar sıkıca tut!",
            "Mutfaktan acı sos veya bol karabiberli bir yudum su iç!",
            "Rehberinden rastgele seçilecek birini ara ve 'Sadece acil bir şey yok, sesini duymak istedim' deyip kapat!",
            "Odada müziksiz 30 saniye boyunca en enerjik dans performansını sergile!",
            "Yanındaki kişiyi sırtına al (piggyback) ve odada 5 adım at!",
            "Pencereyi/balkonu açıp dışarı doğru 'Harika bir gece!' diye bağır!",
            "WhatsApp veya Instagram hikayene 1 saatliğine en komik yüz pozunu koy!",
            "Gözlerini bağla ve gruptan birinin eline dokunarak kim olduğunu tahmin et!",
            "Sırtını duvara daya ve 45 saniye 'Wall-Sit' (sanki sandalyede oturuyormuş gibi) pozisyonunda dur!",
            "Bir sonraki tura kadar bildiğin bir yabancı dilde veya uydurma bir dilde konuş!",
            "Bir limon dilimini yüzünü hiç ekşitmeden çiğne ve yut!",
            "Masadaki 2 farklı içeceği karıştırıp tek dikişte iç!",
            "Yanındaki oyuncuyla bilek güreşi yap, kazanan diğerine 1 komik kural koysun!",
            "Odadaki birini seç ve onun yürüyüşünü ve konuşmasını 30 saniye birebir taklit et!",
            "Hiç durmadan 15 şınav çek!",
            "Odadaki kapalı bir çantadan gözün kapalı bir eşya çek ve ne olduğunu tahmin et!",
            "Bir sonraki turuna kadar konuştuğun her cümleyi yüksek sesle bağırarak söyle!",
            "Tek ayak üzerinde dururken gözlerini kapat ve 30 saniye dengeni koru!",
            "Odadaki herkesin seninle birlikte komik ve dramatik bir film afişi pozu vermesini sağla!",
            "Banyoya gidip ellerini yıkarken herkesin duyacağı sesle şarkı söyle!",
            "Koridorda veya odada 5 kere hızlıca git-gel yap!",
            "Odadakilere konuşmadan sadece mimiklerle popüler bir film adını anlattır!",
            "Bir sonraki turuna kadar sadece komşunun kulağına fısıldayarak iletişim kur!",
            "Sırtına 10 saniye boyunca bir buz küpü koydur!"
        },
        { // 3: Flört ve Çiftler
            "Soran kişiye en samimi ve etkileyici övgünü yap.",
            "Soran kişinin kulağına komik bir tavlama cümlesi fısılda.",
            "Sağındaki kişinin elini sonraki tura kadar tut!",
            "Meşhur bir romantik film sahnesini soran kişiyle canlandır.",
            "Birinin gözlerinin içine bakarak bir aşk şarkısı söyle.",
            "Odadan seçtiğin birine en komik veya en tatlı tavlama cümleni söylerken gözlerinin içine bak!",
            "Odadaki birine bakarak romantik bir şarkının nakaratını yüksek sesle söyle!",
            "Yanındaki oyuncunun elinin üstüne nazik ve centilmence bir öpücük kondur!",
            "Seçtiğin biriyle 15 saniye boyunca müziksiz romantik bir slow dans yap!",
            "Solundaki kişinin kulağına seni anında tebessüm ettirecek tatlı bir cümle fısılda!",
            "Odadan seçtiğin biriyle sanki romantik bir çiftmişsiniz gibi tatlı poz verip selfie çek!",
            "Masadaki bir nesneyi kırmızı bir gülmüş gibi romantik bir edayla birine takdim et!",
            "Bir sonraki tura kadar seçtiğin birine 'Prensesim' veya 'Prensim' diye hitap et!",
            "Yanındaki kişinin boyun veya omuz kokusunu koklayıp hangi çiçeği anımsattığını söyle!",
            "Yanındaki kişiye 30 saniye boyunca rahatlatıcı bir omuz masajı yap!",
            "Yere tek dizinin üzerine çök ve gruptan birine aşırı abartılı komik bir evlenme teklifi yap!",
            "Yanındaki oyuncuyla kollarınızı birbirine dolayarak birer yudum içecek iç!",
            "Yanındaki kişinin el falına bakıyormuş gibi yapıp ona romantik ve komik bir gelecek oku!",
            "Seçtiğin bir oyuncunun saçını nazikçe tara veya parmaklarınla düzelt!",
            "Odadaki her oyuncunun çekici bulduğun 1 özelliğini sırayla söyle!",
            "Yanındaki oyuncunun yanağına veya şakağına 5 saniyelik masum bir öpücük kondur!",
            "Rehberindeki birine 'Şu an aklımdasın, harika bir gün geçir' mesajı at!",
            "Telefonunun flaşını yakıp masanın ortasına koy ve 1 tur loş atmosferde oynayın!",
            "Seçtiğin bir oyuncuyla ellerinizle ortak bir kalp sembolü yapıp poz verin!",
            "Yanındaki kişiye ellerinle küçük bir atıştırmalık veya çikolata ikram et!",
            "Karşındaki kişiye 15 saniye boyunca tutkulu ama utangaç bakışlar at!",
            "Yanındaki kişiyle 1 tur boyunca aynı kulaklıktan aynı romantik şarkıyı dinleyin!",
            "Yanındaki kişinin elinin üzerine tükenmez kalemle küçük bir kalp çiz!",
            "Yanındaki kişiye bakarak meşhur bir aşk şiirinden iki satır oku!",
            "Bir sonraki tura kadar yanındaki oyuncuyla parmaklarınızı kenetleyerek durun!"
        },
        { // 4: +18 Ateşli
            "Soran kişiye en çekici göz kırpmanı ve gülümsemeni yap.",
            "Bir klipteymişsin gibi 15 saniye boyunca kendi kendine dans et.",
            "Solundaki kişinin kulağına iddialı bir sır fısılda.",
            "Soran kişiye o anda 2 satırlık tatlı bir şiir uydur!",
            "Pantolonunu veya üstünü başka bir oyuncuyla değiştir (tabii o da kabul ederse!). Ve bir sonraki turuna kadar öyle kal.",
            "Crush'ına (veya cesaretin varsa eski sevgiline!) nasıl olduğunu soran bir sesli mesaj gönder.",
            "En iddialı ve seksi dansını 15 saniye boyunca sergile!",
            "Solundaki komşunun kulağına ateşli bir cümle fısılda.",
            "Sağındaki komşuna en tutkulu bakışını at ve yanağından öp.",
            "Solundaki komşuna açıkça yürü ve etkilemeye çalış.",
            "Abartılı ve tutkulu sesler çıkararak 10 şınav çek!",
            "En kötü ayrılığını sadece şarkı isimleri kullanarak anlat.",
            "Gruptaki her kişiye çok imalı ve seksi bir iltifat et.",
            "Üstündeki bir kıyafeti solundaki komşunla değiştir.",
            "Eski sevgiline sadece 'Biliyor musun? Düşünüyorum da...' diyen bir sesli mesaj gönder ve hemen kapat.",
            "30 saniye boyunca boşluğa nasıl öpüştüğünü göster.",
            "Gruptakileri kahkahaya boğacak müstehcen bir fıkra anlat.",
            "İzlediğin en ateşli veya romantik film sahnesini anlat.",
            "Komşunun kolunu koklayarak seksi bir parfüm eleştirisi yap.",
            "Üzerinden istediğin 2-3 parça aksesuarı veya kıyafeti çıkar.",
            "Gece yarısı verilen en saçma ve iddialı bahaneyi uydur.",
            "'Özel bir an' sırasında telefona cevap veriyormuş gibi yap.",
            "Bir muzu veya çikolatayı olabilecek en seksi şekilde ye.",
            "Gönderdiğin son ateşli veya iddialı mesajı sesli oku.",
            "Atıştırmalık bir yiyeceği olabilecek en erotik şekilde ye.",
            "Olabildiğince iddialı ve abartılı bir tutku sahnesini tek başına canlandır!",
            "Solundaki oyuncunun gözlerinin içine hiç gözünü kaçırmadan ve dudaklarını ısırarak 20 saniye boyunca tutkuyla bak!",
            "Ağzına küçük bir buz parçası al ve gruptan kabul eden bir oyuncunun yanağına/boynuna buz gibi bir buseli dokunuş yap!",
            "Sandalyede oturan bir oyuncunun önünde 15 saniye boyunca müzik eşliğinde büyüleyici ve seksi bir dans yap!",
            "Yanındaki kişinin kulağına tüylerini diken diken edecek kadar arzulu ve iddialı bir fısıltıda bulun!",
            "Sağındaki oyuncuya bakarak 10 saniye boyunca olabilecek en iddialı ve seksi tavırla dudaklarını ısır!",
            "Gözlerini kapat, gruptan birinin parmağını tutup elinin sırtını arzulu bir şekilde öp!",
            "Bir sonraki tura kadar konuştuğun tüm cümleleri fısıltılı, buğulu ve arzulu bir ses tonuyla söyle!",
            "Rehberindeki iddialı birine 'Uykum kaçtı, zihnimi meşgul ediyorsun...' mesajı atıp ekranı göster!",
            "Yanındaki oyuncuya gözleri kapalıyken ellerinle bir meyve/çikolata dilimi yedir!",
            "Bir sonraki tura kadar sağındaki oyuncuya 'Efendim' diye hitap et ve onun vereceği masum 1 emri yerine getir!",
            "Kabul eden bir oyuncunun boyun kısmına parmak ucunla 10 saniye boyunca nazikçe dokun!",
            "Kameraya veya gruba bakarak en iddialı, cazibeli ve flörtöz gülüşünü sergile!",
            "Yanındaki oyuncunun şakaklarına veya ellerine 30 saniye boyunca hipnotize edici bir masaj yap!",
            "Yanındaki oyuncunun kulağına 5 saniye boyunca ılık nefesini hissettirerek yaklaş!",
            "Gruptakilerin gözü önünde bir meyveyi gözlerini kapatıp tadını çıkararak yavaşça ye!",
            "Odadaki bir aynanın veya camın karşısına geçip 15 saniye boyunca kendine büyüleyici bir biçimde dans et!",
            "Odada romantik hayatında en başarılı bulduğun kişinin tutkulu yürüyüşünü taklit et!",
            "Solundaki oyuncunun vücudunda en çok çekici bulduğun noktayı iddialı cümlelerle öv!",
            "Yanındaki oyuncunun nabız noktasına (bileğine) tutkulu ve yavaş bir öpücük kondur!",
            "Yanındaki oyuncunun kulağına dibinden fısıldayarak ateşli iki satır şiir oku!",
            "Gruptan birinin yüzüne çok yakın durarak 10 saniye boyunca hiç konuşmadan göz göze kal!"
        }
    };

    private static final String[][] PACK_TRUTHS = {
        { // 0: Party and Fun
            "What is your most hilarious or embarrassing party memory?",
            "If you could trade lives with anyone in this room for a day, who and why?",
            "What is the weirdest habit you have when no one is watching?",
            "What is the biggest lie you ever told with a straight face?",
            "What is a funny nickname you had as a kid?",
            "What is the most ridiculous thing you bought on an impulse?",
            "Show the most embarrassing recent Google search you did.",
            "What is the worst gift you have ever received?",
            "What is the weirdest thing currently in your bag or pockets?",
            "Which app on your phone is totally useless but you still haven't deleted?",
            "What is my biggest hidden talent that most people don't know about?",
            "Regardless of my degree or job, what career do you secretly think I am built for?",
            "If our friend group were a sitcom, what would your character trope be?",
            "What is the most annoying thing I do when we travel together?",
            "If you could swap lives with someone here for a week, who would it be and what would you do first?",
            "Share your most embarrassing story from your childhood or teenage years!",
            "If you were completely invisible for one hour, what would you do?",
            "If you had to tattoo someone's name from this room, whose name would it be?",
            "Have you ever felt embarrassed by your family in public?",
            "Have you ever stolen anything, even something small like a lighter?",
            "Who were you stalking on Instagram most recently?",
            "What is the crazy food item you have ever eaten?",
            "What is the wild thing that ever happened to you in a taxi?",
            "What is the most embarrassing moment in front of a friend?",
            "If you were a dog, what breed would you be and why?",
            "Have you ever done something wrong and blamed someone else?",
            "What is the weirdest nickname you ever had? Tell the story!",
            "What was the very last thing you searched on Google?",
            "Which comedy movie most resembles your life?",
            "What never fails to make you laugh out loud?",
            "What is the strangest dream you remember?",
            "Read the last text message you sent on WhatsApp out loud.",
            "Read the last text message you received on WhatsApp out loud.",
            "Show the last three open tabs in your browser history.",
            "Read the last text message you sent to a parent.",
            "Show everyone a recent photo of your ex from social media.",
            "Show the last 10 photos in your phone gallery.",
            "Show the most embarrassing photo stored on your phone."
        },
        { // 1: Deep Confessions
            "What is a secret dream or goal you rarely share with anyone?",
            "What first impression did you really have of the questioner?",
            "Which single decision changed the path of your life the most?",
            "What is a mistake you made that taught you a major life lesson?",
            "What is something you deeply care about that most people ignore?",
            "Which fashion trend will you never understand?",
            "Which practical superpower would you want just to make daily life easier?",
            "If you were to create a perfume, what would its name and scent be?",
            "What was the longest secret you kept hidden from me?",
            "What was your honest first impression of me when we first met?",
            "If you could give the questioner just one single piece of life advice, what would it be?",
            "Which habit or trait of mine annoys you the most?",
            "If you could relive just one memory we shared together, which one would you choose?",
            "What is the weirdest lie you ever told to protect me?",
            "If you could find out the exact date of your death, would you want to know?",
            "If you could legalize one crime for 24 hours, which would it be?",
            "Who in this room do you honestly get along with the least?",
            "What is your biggest irrational fear?",
            "What is something you hope your family never finds out?",
            "Which movie/TV character do you identify with most?",
            "What is your honest biggest Red Flag about yourself?",
            "What is the most embarrassing text message you ever sent?",
            "Tell the group one lie and one truth about yourself and let them guess!",
            "Tell a funny story about yourself that will make everyone laugh.",
            "Predict what everyone in the group will be doing in 5 years.",
            "What is the most embarrassing accident that happened during an intimate moment?",
            "Have you ever told a white lie about your past relationship experience?",
            "How would you rate your current romantic life out of 10?",
            "How many meaningful relationships have you had so far?",
            "What is the boldest question you've ever been asked in a game?"
        },
        { // 2: Bold Challenges
            "What is the boldest thing you have ever done on a dare?",
            "What is a fear you have successfully overcome?",
            "Have you ever cheated in a game or test and gotten away with it?",
            "What is something wild on your bucket list?",
            "What is the bravest thing you have ever seen me do?",
            "When do you feel at your absolute peak of attractiveness?",
            "What gives you the ultimate confidence during intimate moments?",
            "What is the single most important truth you've learned about your desires?",
            "What is your absolute boundary that you will never cross?"
        },
        { // 3: Flirt and Couples
            "What three qualities do you find most attractive in someone?",
            "What was your very first crush like?",
            "Describe your ideal romantic date in one sentence.",
            "What is the sweetest gesture someone has ever done for you?",
            "If you had to rate my taste in partners out of 10, what score would you give and why?",
            "Have you ever had a secret crush on me or anyone else in this group?",
            "If you could pick any celebrity for a dream date, who would it be?",
            "What username would you use on a secret dating app?",
            "If you had to wear an outfit specifically to look sexy, what would it be?",
            "Have you ever flirted with someone while playing this game? Tell us!",
            "If your crush were in this room, what dare would you give them right now?",
            "When was the last time you made up an excuse to escape a bad date?",
            "Have you ever been in love with two people at the same time?",
            "Have you ever secretly snooped through your partner's phone?",
            "What is the dumbest thing you have ever done for love?",
            "What is the very first physical feature you notice in someone attractive?",
            "What is your absolute favorite physical feature in a potential partner?",
            "What is your opinion on fun adult toys and gadgets?",
            "What is the craziest thing you ever did in the name of love?",
            "Who is your ultimate celebrity crush?",
            "Who was your very first celebrity crush?",
            "What was your absolute worst date experience?",
            "How was your very first date ever? Describe it!",
            "Who has the best physical appearance/vibe in this room?",
            "What do you find completely irresistible when someone flirts?",
            "What would you wear if you wanted to seduce someone?",
            "Test whose hair smells better between two players in the room!",
            "Smell everyone's neck and declare who has the best smelling perfume.",
            "Let someone give you a gentle kiss on your neck.",
            "Look into someone's eyes for 1 full minute without blinking.",
            "What is your secret romantic guilty pleasure?",
            "What is the boldest romantic text you have ever sent?",
            "What is the most unusual or unexpected location where you kissed someone?",
            "What is the boldest, most daring compliment you'd love to hear?",
            "If you named a cocktail after your ex, what ingredients would be in it?",
            "Which song instantly puts you into a romantic or sensual mood?",
            "Describe your ideal kiss in detail. Where, how, and in what atmosphere?",
            "Which celebrity sparks your wildest romantic fantasies?",
            "Which movie or movie scene instantly puts you in a passionate mood?",
            "What makes you blush without fail?",
            "Lingerie/Underwear: Comfortable, sexy, or both?",
            "What subtle thing instantly turns you on?",
            "What is the perfect song to set a romantic sensory mood?",
            "What is your absolute biggest turn-off?",
            "Besides classic areas, what body feature do you find irresistible?",
            "Have you ever taken the first initiative for a kiss or more?",
            "Have you ever been deeply attracted to someone completely outside your type?",
            "Which scent or perfume drives you completely wild?",
            "If you could spend one unforgettable night with anyone in the world, who?",
            "What is your favorite sensory gesture to give your partner?",
            "Which celebrity would you love to spend a romantic night with?",
            "Who in this room would you want to kiss right now?",
            "When and where was the last time you had a romantic outdoor moment?",
            "What was the funniest romantic experience you ever had?",
            "What turns you on the most?",
            "Who in this room do you think is best at romance and why?",
            "Tell 3 things that turn you on before or during romance."
        },
        { // 4: +18 Spicy (VIP)
            "What makes romantic chemistry unforgettable to you?",
            "Unforgettable physical chemistry: what does it mean to you?",
            "Which part of your body do you find the absolute sexiest?",
            "If you had to sleep with just one person in this room, who would it be?",
            "What is your biggest secret fantasy?",
            "How many people in this room would you realistically sleep with?",
            "How long does it usually take you to reach climax?",
            "What is the absolute worst moment to get interrupted while making love?",
            "What is the weirdest erotic dream you've ever had?",
            "If you had to sleep with someone in this room (other than your partner), who would it be?",
            "What is the most embarrassing moment you've ever had in bed?",
            "Have you ever had a crush or hit on a friend's partner?",
            "Have you ever sent a spicy or nude photo to someone?",
            "What is your secret fantasy that you can confess right here?",
            "What is the most unusual place you have ever kissed someone?",
            "Have you ever had a one-night stand? Was it good or bad?",
            "What is the wildest thing you are willing to do for passion?",
            "Long sensual foreplay or getting straight to the point?",
            "What is the absolute sexiest compliment someone ever gave you?",
            "Have you ever sent a naughty text message or photo?",
            "Dim romantic lights or total darkness? Why?",
            "Have you ever had a romantic or steamy dream about anyone in this room?",
            "Have you ever had a friends-with-benefits situation?",
            "What matters most to you during intimacy?",
            "Have you ever been caught red-handed in a passionate moment?",
            "Where on your body do you love being kissed most besides your lips?",
            "If you described your libido as an animal right now, which would it be?",
            "Is giving pleasure better, receiving, or a perfect balance?",
            "What is the absolute sexiest sentence someone could whisper in your ear?",
            "Have you ever faked an orgasm? Why?",
            "What is your favorite type of massage?",
            "What is your favorite position (for sleeping... or otherwise)?",
            "What is a bucket-list fantasy you would love to try?",
            "What is an embarrassing experience you had with romantic safety?",
            "What is your ideal duration for an intimate session?",
            "How do you feel about dirty talk during romantic moments?",
            "Have you ever had a risky romantic experience in a semi-public location?",
            "Have you ever used sweet food like chocolate or cream in romance?",
            "Is there something you secretly want to try but have been too shy to ask?",
            "What was the most unusual location for a passionate moment?",
            "Where is one place you would never have a passionate moment again?",
            "What is the wildest thing you've ever tried in an intimate setting?",
            "How old were you during your very first passionate experience?",
            "How was your very first intimate experience?",
            "Which position is your absolute favorite and why?",
            "What makes you feel best during intimate moments?",
            "Which romantic toy/accessory couldn't you live without?",
            "Which roleplay scenario do you find extremely hot?",
            "What does your ideal foreplay look like?",
            "Have you ever been caught during a passionate moment?",
            "What is the steamiest dream you remember?",
            "What kind of romantic content turns you on?",
            "Whisper a very suggestive/naughty sentence into your left neighbor's ear.",
            "Smell your right neighbor's armpit and react dramatically!",
            "Try to remove an item of clothing from a willing player using only your teeth.",
            "Gently nibble or whisper into someone's ear for 10 seconds.",
            "Share some exciting details about the best, most unforgettable night of your life.",
            "Send a bold, flirtatious text message to someone right now.",
            "Read a passionate or erotic text out loud to the group with a straight face.",
            "Act like a romantic product sales representative and pitch your best product to the group!",
            "Write a four-line romantic, steamy poem and read it to the group.",
            "Twerk or perform a confident 30-second dance to a song of your choice!"
        }
    };

    private static final String[][] PACK_DARES = {
        { // 0: Party and Fun
            "Do your funniest 10-second dance without any music!",
            "Imitate someone in the circle until the group guesses who it is.",
            "Tell a funny joke with a totally serious, unsmiling face.",
            "Let the answerer style your hair for the next round!",
            "Do a dramatic slow-motion catwalk walk across the room.",
            "Sing a cartoon theme song from your childhood at full volume!",
            "What is your most useless secret talent? Show us!",
            "Tell a joke that only you find funny. The group will judge!",
            "Describe your favorite food as if it were a high art masterpiece!",
            "Do a staring contest with the person opposite you. First to laugh loses!",
            "Put on imaginary headphones and commentate the game like a frantic football match!",
            "Act like a T-Rex trying to drink from a cup with tiny arms!",
            "Do a moonwalk for 3 meters. Or at least an honorable attempt!",
            "Let someone give you an absurd hairstyle right now. Photo required!",
            "Eat a chip or cookie using no hands!",
            "Propose an ultra-complex high-five handshake to the person on your left!",
            "Walk sideways and make crab noises for 30 seconds straight!",
            "Hand your phone to someone. They have 30 seconds to inspect your YouTube or TikTok history!",
            "Let the player to your left give you a new nickname for the night that you must use!",
            "Invent an overly complex dance move and teach it to two people in 30 seconds!",
            "Eat a snack from the bowl using absolutely no hands!",
            "Let your friends style your hair with random household items. Selfie required!",
            "Read the last text message you sent out loud to the group!",
            "Let someone pick an embarrassing photo from your gallery and show it to the group!",
            "Let the group pick a hilarious filter for you to take a selfie with!",
            "Swap an accessory (ring, hat, watch) with someone for the rest of the game!",
            "Play music and do your most ridiculous 30-second dance!",
            "Post a mysterious story on your social media right now!",
            "Pretend to give an expert news interview on a topic you know nothing about!",
            "Hand your phone to your right neighbor to send a harmless emoji to a contact!",
            "Spin around in a circle 10 times then try to walk a straight line!",
            "Try drinking water with your elbows glued to your ribs like a tiny T-Rex!",
            "React to everything anyone says like an over-the-top soap opera star until your next turn!",
            "Move and speak in glitchy slow motion for 30 seconds as if your battery is running out!",
            "Invent an 80s disco dance move and dance continuously for 20 seconds!",
            "Hop around the room like a frog and yell 'Ribbit!' on every jump!",
            "For your next turn, answer every question starting with 'I found these search results...'",
            "Point at a player, chant a hilarious fake Latin spell, and give them a funny rule for 1 round!",
            "End every sentence you speak with 'Meow!' until your next turn!",
            "Lift the lightest object in the room as if it weighs 200 kilograms!",
            "Smell and inspect a random item pulled from your neighbor's bag like a Michelin judge!",
            "Let a player trace an imaginary funny drawing on your face with their finger!",
            "Make up a dramatic, thrilling story in 30 seconds about being abducted by aliens!",
            "Pretend to cry hysterically like a toddler whose pacifier was stolen for 15 seconds!",
            "Look into your left neighbor's eyes and chant 'Omm...' for 20 seconds!",
            "Flap your arms like wings and cluck loudly while walking around the table!",
            "Report the last 5 minutes of game events like a serious breaking news anchor!",
            "Run across the room in slow motion as if escaping a massive movie explosion!",
            "Squat down and do a duck walk around the room!",
            "Place an imaginary crown on your head and address everyone as 'My loyal subjects' for 2 rounds!",
            "Crawl like a secret agent under tables to fetch a random object!",
            "Let your neighbor take a selfie using your phone from the most unflattering angle!",
            "Do not use 1 forbidden word chosen by the group for the next 3 turns!",
            "Repeat a difficult tongue twister 3 times out loud without stumbling!",
            "Smell your neighbor's hand and declare what delicious dish it reminds you of!",
            "Perform a funny 15-second beatbox rhythm using only your mouth!"
        },
        { // 1: Deep Confessions
            "Share a genuine, heartfelt compliment with every person in the circle.",
            "Look into the questioner's eyes for 15 seconds without laughing.",
            "Confess one small thing you feel guilty about in a funny voice.",
            "Let the questioner ask you ONE extra free question that you must answer.",
            "Give a super specific and unique compliment to every single person in the room.",
            "Call a family member right now and tell them you love them for no reason!",
            "Whisper the most embarrassing secret you've never told anyone into the questioner's ear!",
            "Send a 'Just wanted to check in and see how you are' text to an old contact on your phone!",
            "Reveal the name of your first crush and the funniest memory or thought you had about them!",
            "Share a past moment where you felt you were unfair to someone and what lesson it taught you!",
            "Tell every person in the room what you honestly think their single strongest personality trait is!",
            "Hold your left neighbor's hand for 1 minute while sharing something you truly appreciate about them!",
            "Confess the most ridiculous thing you ever did during teenage years just to look cool!",
            "Pick someone in the room and make a heartfelt prediction about where they'll be in 5 years!",
            "Share with the group what single thing gets you emotional or makes you cry easiest!",
            "Search your text messages for a word like 'Love' or 'Ex' and read the first innocent result out loud!",
            "Give 30 seconds of genuine, heartfelt praise to the quietest player in the room!",
            "Tell someone in the room one thing you initially misjudged about them when you first met!",
            "Hum or sing one short verse of a song that always touches your heart!",
            "Show the group the weirdest contact name saved in your phone and tell the story behind it!",
            "Share a major life decision you made that you are immensely proud of today!",
            "Show the group an unedited, raw, natural photo from your gallery!",
            "Make a concrete promise to someone in the room to do a fun activity together within the next month!",
            "Share the number one boundary breaker that causes you to distance yourself from people!"
        },
        { // 2: Bold Challenges
            "Speak in a dramatic movie villain voice until the next spin!",
            "Let the group choose a hilarious pose for you and hold it for 15 seconds.",
            "Do 10 push-ups or 15 jumping jacks right now while making animal noises!",
            "Do your best impression of a famous celebrity chosen by the group.",
            "Make up a completely absurd new rule for this game right now!",
            "If you could have any celebrity's voice, who would it be? Do an impression!",
            "Act like a robot who is experiencing human emotions for the very first time!",
            "Speak in a funny regional accent until your next turn!",
            "Make the voice of a famous video game character (Mario, Sonic...)",
            "Hop around the room on one leg while trying to recite the alphabet backwards!",
            "Freeze completely like a mannequin for 1 full minute without moving!",
            "Do a forearm plank for 45 seconds without giving up!",
            "Hold an ice cube tightly in your palm until it melts!",
            "Take a sip of hot sauce or water mixed with heavy black pepper!",
            "Call a random contact, say 'Nothing urgent, just wanted to hear your voice', and hang up!",
            "Perform your most energetic 30-second dance routine with zero music!",
            "Give your neighbor a piggyback ride and walk 5 steps across the room!",
            "Open a window or balcony and shout 'What a wonderful night!' to the outside!",
            "Post the funniest facial expression selfie to your story for 1 hour!",
            "Blindfold yourself and guess who a player is just by touching their hand!",
            "Do a wall-sit against the wall for 45 seconds without dropping!",
            "Speak in a foreign language or hilarious made-up language until your next turn!",
            "Chew and swallow a lemon slice without making any sour face!",
            "Mix two different drinks from the table and down it in one shot!",
            "Arm wrestle with the player next to you; winner sets a funny rule for the loser!",
            "Imitate the walk and speech of someone in the room for 30 seconds straight!",
            "Do 15 push-ups without taking a break!",
            "Draw an object blindly from a bag and guess what it is!",
            "Yell every single sentence you speak until your next turn!",
            "Stand on one leg with your eyes closed for 30 seconds!",
            "Make everyone in the room pose with you for a dramatic movie poster photo!",
            "Sing out loud while washing your hands so everyone can hear you!",
            "Do 5 quick shuttle runs across the hallway or room!",
            "Act out a famous movie title using only charades and gestures!",
            "Communicate only by whispering in your neighbor's ear until your next turn!",
            "Let someone put an ice cube down your back for 10 seconds!"
        },
        { // 3: Flirt and Couples
            "Give the questioner your best sincere romantic compliment.",
            "Whisper a funny pickup line into the questioner's ear.",
            "Hold hands with the person on your right for the next turn!",
            "Reenact a famous movie romantic scene with the questioner!",
            "Sing a passionate love song while looking straight into someone's eyes!",
            "Look into someone's eyes and hit them with your absolute funniest or sweetest cheesy pickup line!",
            "Sing the chorus of a classic love song while maintaining eye contact with a player!",
            "Give your neighbor a gentle, gentlemanly kiss on the back of their hand!",
            "Slow dance with a chosen player for 15 seconds without any music playing!",
            "Whisper a sweet, heartwarming sentence into your left neighbor's ear!",
            "Take a cute or hilarious couple selfie with a player of your choice!",
            "Present a random object from the table to someone as if it were a fresh red rose!",
            "Address a player of your choice as 'My Prince' or 'My Princess' until your next turn!",
            "Smell your neighbor's neck/shoulder area and declare what flower it reminds you of!",
            "Give the player next to you a relaxing 30-second shoulder massage!",
            "Get down on one knee and make an over-the-top, dramatic proposal to someone!",
            "Interlock arms with your neighbor (cheers style) and take a sip of your drink together!",
            "Pretend to read your neighbor's palm and predict a funny romantic future for them!",
            "Gently comb or fix a chosen player's hair with your fingers!",
            "Go around the room and name 1 attractive trait of every single player!",
            "Give your neighbor a gentle 5-second kiss on the cheek or temple!",
            "Send a text saying 'Just thinking of you, hope you have an amazing day' to someone in your contacts!",
            "Turn on your phone flashlight, place it in the center of the table, and play 1 round in dim light!",
            "Form a heart shape with your hands together with a chosen player and pose!",
            "Feed a small piece of snack or chocolate to your neighbor with your hands!",
            "Give the player opposite you a passionate yet shy romantic stare for 15 seconds!",
            "Share one pair of earphones with your neighbor and listen to a love song for 1 round!",
            "Draw a small cute heart on the back of your neighbor's hand with a pen!",
            "Recite two lines of a famous romantic poem while looking at your neighbor!",
            "Hold hands with your fingers intertwined with your neighbor until your next turn!"
        },
        { // 4: +18 Spicy (VIP)
            "Give your most charming wink and smile to the questioner.",
            "Slow dance by yourself for 15 seconds like you are in a music video.",
            "Whisper a spicy secret to the person on your left.",
            "Make up a romantic 2-line poem on the spot for the questioner!",
            "Look into your left neighbor's eyes passionately for 20 seconds while biting your lip!",
            "Hold a small piece of ice in your mouth and give a gentle icy kiss on a consenting player's cheek or neck!",
            "Perform a captivating, sensual 15-second dance in front of a seated player with music!",
            "Whisper a deeply passionate, tantalizing secret into your neighbor's ear!",
            "Bite your lip in the absolute most alluring and seductive way for 10 seconds while looking at your right neighbor!",
            "Close your eyes, hold a player's hand, and give a passionate kiss to the back of their hand!",
            "Speak all your sentences in a sultry, whispered, passionate tone of voice until your next turn!",
            "Send a text saying 'Can't sleep, you're occupying my mind...' to a bold contact and show the screen!",
            "Feed a slice of fruit or chocolate to your neighbor while their eyes are closed!",
            "Address your right neighbor as 'Master' until your next turn and fulfill 1 innocent command from them!",
            "Gently touch the neck area of a consenting player with your fingertips for 10 seconds!",
            "Give your most alluring, seductive, and flirtatious smile into the camera or group!",
            "Give your neighbor a hypnotizing 30-second temple or hand massage!",
            "Lean in close to your neighbor's ear and let them feel your warm breath for 5 seconds!",
            "Eat a piece of fruit slowly with your eyes closed in front of the group!",
            "Dance enticingly in front of a mirror or glass window for 15 seconds!",
            "Imitate the passionate walk of the person you think is best at romance in the room!",
            "Praise the exact physical feature you find most attractive on your left neighbor using bold words!",
            "Place a slow, passionate kiss right on your neighbor's pulse point (inner wrist)!",
            "Whisper two lines of a hot, passionate poem directly into your neighbor's ear!",
            "Stand very close to a player face-to-face for 10 seconds in total silence without breaking eye contact!"
        }
    };

    // --- GERMAN (DE) QUESTIONS ---
    private static final String[][] PACK_TRUTHS_DE = {
        { // 0: Party & Spass
            "Was ist deine lustigste oder peinlichste Partyerinnerung?",
            "Wenn du für einen Tag mit jemandem in diesem Raum das Leben tauschen könntest, wer wäre das?",
            "Was ist die seltsamste Angewohnheit, die du hast, wenn niemand zuschaut?",
            "Was war die größte Lüge, die du je mit ernsthaftem Gesicht erzählt hast?",
            "Was war der lustigste Spitzname, den du als Kind hattest?",
            "Was ist das unnötigste Produkt, das du je im Impuls gekauft hast?",
            "Zeige den peinlichsten letzten Google-Suchverlauf auf deinem Handy!",
            "Was war das schlechteste oder sinnloseste Geschenk, das du je bekommen hast?",
            "Was ist der seltsamste Gegenstand, den du derzeit in deiner Tasche trägst?",
            "Welche App auf deinem Handy nutzt du nie, willst sie aber nicht löschen?",
            "Was ist dein geheimstes, nutzlosestes Talent?",
            "Was wäre dein absoluter Traumberuf, unabhängig von deiner aktuellen Arbeit?",
            "Wenn unsere Gruppe eine TV-Serie wäre, welche Rolle würdest du spielen?",
            "Was ist meine nervigste Eigenschaft, wenn wir zusammen verreisen?",
            "Wer in diesem Raum hat deinen liebsten Style?",
            "Was ist deine peinlichste Jugenderinnerung?",
            "Wenn du für 1 Stunde unsichtbar wärst, was würdest du tun?",
            "Wenn du den Namen von jemandem hier tätowieren müsstest, wer wäre es?",
            "Hast du dich je für eine Aktion deiner Eltern in der Öffentlichkeit geschämt?",
            "Hast du je heimlich etwas Kleines mitgehen lassen (Stift, Feuerzeug)?",
            "Wen hast du zuletzt auf Instagram heimlich gestalkt?",
            "Was ist das verrückteste Essen, das du je probiert hast?",
            "Was war das Seltsamste, das dir je in einem Taxi passiert ist?",
            "Was war dein peinlichster Moment vor einem guten Freund?",
            "Welche Hunderasse wärst du für einen Tag?",
            "Hast du je eigenen Fehler auf jemand anderen geschoben?",
            "Was ist die Geschichte hinter deinem seltsamsten Spitznamen?",
            "Was war das letzte Wort, das du gesucht hast?",
            "Welchem Comedy-Film ähnelt dein Leben am meisten?",
            "Was bringt dich immer garantiert zum Lachen?"
        },
        { // 1: Tiefe Geständnisse
            "Was ist ein geheimer Traum, den du selten mit jemandem teilst?",
            "Welchen ersten Eindruck hattest du wirklich von der Person, die fragt?",
            "Welche einzelne Entscheidung hat dein Leben am meisten verändert?",
            "Welchen Fehler hast du gemacht, der dir eine große Lektion erteilt hat?",
            "Worauf legst du Wert, das die meisten Menschen ignorieren?",
            "Welchen Modetrend wirst du nie verstehen?",
            "Welche praktische Superkraft hättest du gerne im Alltag?",
            "Wenn du ein Parfum kreieren würdest, wie würde es heißen?",
            "Was war das längste Geheimnis, das du vor mir verborgen hast?",
            "Was war dein ehrlichster erster Eindruck von mir?",
            "Welchen einzigen Ratschlag würdest du der fragenden Person geben?",
            "Welche Angewohnheit von mir nervt dich am meisten?",
            "Wenn du eine gemeinsame Erinnerung noch einmal erleben könntest, welche wäre es?",
            "Was war die seltsamste Lüge, die du erzählt hast, um mich zu schützen?",
            "Wenn du das genaue Datum deines Todes erfahren könntest, würdest du es wissen wollen?",
            "Wenn du ein Gesetz für 24 Stunden aufheben könntest, welches wäre es?",
            "Mit wem in diesem Raum verstehst du dich ehrlich gesagt am wenigsten?",
            "Was ist deine größte unbegründete Angst?",
            "Was hoffst du, dass deine Familie nie herausfindet?",
            "Mit welchem Filmcharakter identifizierst du dich am meisten?",
            "Was ist deine ehrlichste 'Rote Flagge' (Red Flag) an dir selbst?",
            "Was war die peinlichste Nachricht, die du je aus Versehen gesendet hast?",
            "Erzähle eine Lüge und eine Wahrheit über dich und lass die Gruppe raten!",
            "Erzähle eine lustige Geschichte aus deiner Vergangenheit."
        },
        { // 2: Mutproben
            "Was ist das Mutigste, das du je bei einer Mutprobe getan hast?",
            "Welche Angst hast du erfolgreich überwunden?",
            "Hast du je bei einem Test oder Spiel geschummelt ohne erwischt zu werden?",
            "Was steht ganz oben auf deiner Bucket-List?",
            "Was ist das Mutigste, das du mich je hast tun sehen?",
            "Wann fühlst du dich auf dem absoluten Höhepunkt deiner Attraktivität?",
            "Was gibt dir das ultimative Selbstvertrauen in intimen Momenten?",
            "Was ist die wichtigste Wahrheit, die du über deine Wünsche gelernt hast?",
            "Was ist deine absolute Grenze, die du niemals überschreiten würdest?"
        },
        { // 3: Flirt & Pärchen
            "Welche drei Eigenschaften findest du bei jemandem am attraktivsten?",
            "Wie war deine allererste Jugendliebe?",
            "Beschreibe dein ideales romantisches Date in einem Satz.",
            "Was war die süßeste Geste, die je jemand für dich gemacht hat?",
            "Wie würdest du meinen Partnergeschmack auf einer Skala von 1-10 bewerten?",
            "Warst du je heimlich in mich oder jemand anderen in dieser Gruppe verliebt?",
            "Wenn du ein Promi-Date wählen könntest, wer wäre es?",
            "Welchen Benutzernamen würdest du auf einer geheimen Dating-App nutzen?",
            "Welches Outfit würdest du tragen, um besonders attraktiv zu wirken?",
            "Hast du während dieses Spiels schon mit jemandem geflirtet?",
            "Wer in diesem Raum hat die attraktivste Ausstrahlung?",
            "Was findest du absolut unwiderstehlich, wenn jemand flirtet?",
            "Welches Parfum oder welcher Duft macht dich völlig verrückt?",
            "Wenn du eine unvergessliche Nacht mit jemandem verbringen könntest, wer wäre es?",
            "Wer in diesem Raum würde am ehesten dein Herz erobern?"
        },
        { // 4: +18 Heiss (VIP)
            "Was macht romantische Anziehung für dich unvergesslich?",
            "Unvergessliche körperliche Chemie: Was bedeutet das für dich?",
            "Welchen Teil deines Körpers findest du am sexyesten?",
            "Wenn du mit nur einer Person in diesem Raum schlafen müsstest, wer wäre es?",
            "Was ist deine größte geheime Fantasie?",
            "Wie viele Personen in diesem Raum findest du attraktiv?",
            "Was war der unpassendste Moment, in dem du je unterbrochen wurdest?",
            "Was war der verrückteste erotische Traum, den du je hattest?",
            "Was war dein peinlichster Moment im Bett?",
            "Hattest du je ein One-Night-Stand? War es gut oder schlecht?",
            "Was ist das Verrückteste, das du für Leidenschaft tun würdest?",
            "Langes sinnliches Vorspiel oder direkt zur Sache?",
            "Was war das sexyeste Kompliment, das dir je gemacht wurde?",
            "Hast du je ein freches Foto oder eine Nachricht gesendet?",
            "Dämmriges romantisches Licht oder völlige Dunkelheit? Warum?",
            "Hattest du je einen intimen Traum von jemandem in diesem Raum?",
            "Hattest du je eine Friends-With-Benefits-Beziehung?",
            "Was ist dir bei Intimität am wichtigsten?",
            "Wo am Körper wirst du am liebsten geküsst?",
            "Welche Fantasie möchtest du unbedingt noch ausprobieren?"
        }
    };

    private static final String[][] PACK_DARES_DE = {
        { // 0: Party & Spass
            "Mache deinen lustigsten 10-Sekunden-Tanz ohne Musik!",
            "Ahme jemanden in der Runde nach, bis die Gruppe rät, wer es ist.",
            "Erzähle einen Witz mit einem völlig ernsten Gesicht.",
            "Lass die Gruppe deine Haare für die nächste Runde stylen!",
            "Mache einen dramatischen Slow-Motion-Walk durch den Raum.",
            "Singe das Titellied einer Serie aus deiner Kindheit laut!",
            "Zeige dein nutzlosestes geheimes Talent!",
            "Trink Wasser wie ein T-Rex mit winzigen Armen!",
            "Mache einen Moonwalk für 3 Meter!",
            "Iss einen Snack ohne deine Hände zu benutzen!",
            "Befolge die Befehle deiner Mitspieler für 1 Minute!"
        },
        { // 1: Tiefe Geständnisse
            "Mache allen Personen in der Runde ein ehrliches Kompliment.",
            "Schaue der fragenden Person 15 Sekunden lang ohne zu lachen in die Augen.",
            "Gestehe eine kleine Sache, wegen der du ein schlechtes Gewissen hast.",
            "Beantworte eine freie Frage der Gruppe absolut ehrlich.",
            "Rufe ein Familienmitglied an und sage einfach, dass du sie lieb hast."
        },
        { // 2: Mutproben
            "Sprich bis zur nächsten Runde wie ein böser Filmbösewicht!",
            "Mache 10 Liegestütze während du Tiergeräusche machst!",
            "Mache eine geglückte Nachahmung eines Prominenten.",
            "Erfinde eine völlig verrückte neue Regel für dieses Spiel!",
            "Stehe für 1 Minute völlig erstarrt wie eine Statue da."
        },
        { // 3: Flirt & Pärchen
            "Flüstere der Person neben dir eine süße Anmachzeile ins Ohr.",
            "Halte die Hand der Person zu deiner Rechten für die nächste Runde!",
            "Tanze 15 Sekunden lang einen langsamen romantischen Tanz ohne Musik.",
            "Mache ein süßes Pärchen-Selfie mit einer Person deiner Wahl.",
            "Gib der Person neben dir einen sanften Kuss auf die Wange."
        },
        { // 4: +18 Heiss (VIP)
            "Zwinkere der fragenden Person auf verführerische Art zu.",
            "Flüstere ein verlockendes Geheimnis ins Ohr deines Nachbarn.",
            "Beisse dir 10 Sekunden lang attraktiv auf die Lippe während du jemanden anschaust.",
            "Gib der Person neben dir eine entspannende 30-Sekunden-Massage.",
            "Halte 10 Sekunden lang intensiven Blickkontakt aus nächster Nähe!"
        }
    };

    // --- FRENCH (FR) QUESTIONS ---
    private static final String[][] PACK_TRUTHS_FR = {
        { // 0: Fête et Amusement
            "Quel est ton souvenir de fête le plus drôle ou le plus embarrassant?",
            "Si tu pouvais échanger de vie avec quelqu'un dans cette pièce pendant un jour, qui ce serait?",
            "Quelle est l'habitude la plus bizarre que tu as quand personne ne regarde?",
            "Quel est le plus grand mensonge que tu as raconté avec un visage très sérieux?",
            "Quel était le surnom le plus marrant qu'on te donnait enfant?",
            "Quel est l'achat impulsif le plus inutile que tu aies jamais fait?",
            "Montre l'historique de recherche Google le plus embarrassant sur ton téléphone!",
            "Quel est le pire cadeau qu'on t'ait jamais offert?",
            "Quel est l'objet le plus bizarre que tu portes dans ton sac en ce moment?",
            "Quelle application sur ton téléphone n'utilises-tu jamais mais refuses de supprimer?",
            "Quel est ton talent caché le plus secret et inutile?",
            "Quel serait le métier de tes rêves absolu?",
            "Si notre groupe était une série télévisée, quel rôle jouerais-tu?",
            "Quel est mon défaut le plus énervant quand on voyage ensemble?",
            "Qui dans cette pièce a ton style préféré?",
            "Quel est ton souvenir d'adolescence le plus embarrassant?",
            "Si tu étais invisible pendant 1 heure, que ferais-tu?",
            "Si tu devais te faire tatouer le prénom de quelqu'un ici, qui choisirais-tu?",
            "T'es-tu déjà senti embarrassé en public à cause de tes parents?",
            "As-tu déjà volé un petit objet discrètement (stylo, briquet)?",
            "Qui as-tu stalké en secret sur Instagram dernièrement?",
            "Quelle est la nourriture la plus bizarre que tu aies goûtée?",
            "Quel est l'événement le plus bizarre qui t'est arrivé dans un taxi?",
            "Quel a été ton moment le plus embarrassant devant un ami?",
            "Quelle race de chien aimerais-tu être pendant 1 journée?",
            "As-tu déjà rejeté ta propre faute sur quelqu'un d'autre?",
            "Quelle est l'histoire derrière ton surnom le plus bizarre?",
            "Quel est le dernier mot que tu as cherché sur internet?",
            "À quel film comique ta vie ressemble-t-elle le plus?",
            "Qu'est-ce qui te fait toujours rire sans faute?"
        },
        { // 1: Confessions Profondes
            "Quel est un rêve secret que tu partages très rarement?",
            "Quelle première impression as-tu réellement eu de la personne qui pose la question?",
            "Quelle décision unique a le plus changé le cours de ta vie?",
            "Quelle erreur as-tu commise et qui t'a enseigné une grande leçon?",
            "À quoi accordes-tu de l'importance alors que la plupart des gens l'ignorent?",
            "Quelle tendance mode ne comprendras-tu jamais?",
            "Quel superpouvoir pratique aimerais-tu avoir au quotidien?",
            "Si tu créais un parfum, quel serait son nom?",
            "Quel est le plus grand secret que tu m'as caché pendant longtemps?",
            "Quelle a été ta toute première impression honnête sur moi?",
            "Quel conseil unique donnerais-tu à la personne qui te pose la question?",
            "Quelle habitude chez moi t'agace le plus?",
            "Si tu pouvais revivre un souvenir ensemble, lequel choisirais-tu?",
            "Quel est le plus bizarre mensonge que tu as dit pour me protéger?",
            "Si tu pouvais connaître la date exacte de ta mort, aimerais-tu la savoir?",
            "Si tu pouvais légaliser un crime pendant 24 heures, lequel ce serait?",
            "Avec qui dans cette pièce t'entends-tu le moins bien honnêtement?",
            "Quelle est ta plus grande peur irrationnelle?",
            "Qu'espères-tu que ta famille ne découvrira jamais?",
            "À quel personnage de film t'identifies-tu le plus?",
            "Quel est ton plus grand 'Red Flag' chez toi-même?",
            "Quel est le message le plus embarrassant que tu aies envoyé par erreur?",
            "Dis un mensonge et une vérité sur toi et laisse le groupe deviner!"
        },
        { // 2: Défis Audacieux
            "Quelle est la chose la plus audacieuse que tu aies faite lors d'un défi?",
            "Quelle peur as-tu surmontée avec succès?",
            "As-tu déjà triché à un test sans te faire attraper?",
            "Qu'y a-t-il au sommet de ta Bucket List?",
            "Quelle est la chose la plus courageuse que tu m'aies vu faire?",
            "Quand te sens-tu au sommet de ton attraction physique?",
            "Qu'est-ce qui te donne une confiance ultime dans les moments intimes?",
            "Quelle est la vérité la plus importante que tu aies apprise sur tes désirs?",
            "Quelle est ta limite absolue que tu ne franchiras jamais?"
        },
        { // 3: Flirt et Couples
            "Quelles sont les trois qualités que tu trouves les plus attirantes chez quelqu'un?",
            "Comment était ton tout premier coup de foudre d'adolescence?",
            "Décris ton rendez-vous romantique idéal en une phrase.",
            "Quelle est la plus douce attention que quelqu'un ait eue pour toi?",
            "Comment noterais-tu mes goûts amoureux sur une échelle de 1 à 10?",
            "As-tu déjà eu un béguin secret pour moi ou quelqu'un du groupe?",
            "Si tu pouvais choisir une célébrité pour un rdv, qui ce serait?",
            "Quel pseudo utiliserais-tu sur une application de rencontre secrète?",
            "Quelle tenue porterais-tu pour être particulièrement séduisant(e)?",
            "As-tu déjà flirté avec quelqu'un pendant ce jeu?",
            "Qui dans cette pièce a le charme le plus irrésistible?",
            "Qu'est-ce que tu trouves irrésistible quand quelqu'un flirte?",
            "Quel parfum te rend complètement fou/folle?",
            "Si tu pouvais passer une nuit inoubliable avec n'importe qui, qui ce serait?",
            "Qui dans cette pièce est le plus susceptible de faire vibrer ton cœur?"
        },
        { // 4: +18 Érotique (VIP)
            "Qu'est-ce qui rend l'attraction romantique inoubliable pour toi?",
            "Une chimie physique inoubliable : qu'est-ce que cela signifie pour toi?",
            "Quelle partie de ton corps trouves-tu la plus sexy?",
            "Si tu devais coucher avec une seule personne dans cette pièce, qui ce serait?",
            "Quel est ton plus grand fantasme secret?",
            "Combien de personnes dans cette pièce trouves-tu physiquement attirantes?",
            "Quel a été le moment le plus inopportun où tu as été interrompu(e)?",
            "Quel est le rêve érotique le plus fou que tu aies fait?",
            "Quel a été ton moment le plus embarrassant au lit?",
            "As-tu déjà eu un coup d'un soir? Était-ce bien ou mauvais?",
            "Quelle est la chose la plus folle que tu ferais par passion?",
            "Longs préliminaires sensuels ou aller droit au but?",
            "Quel est le compliment le plus sexy qu'on t'ait fait?",
            "As-tu déjà envoyé un message ou une photo coquine?",
            "Lumière tamisée romantique ou obscurité totale? Pourquoi?",
            "As-tu déjà fait un rêve intime sur quelqu'un dans cette pièce?",
            "As-tu déjà eu une relation 'Friends with Benefits'?",
            "Qu'est-ce qui compte le plus pour toi dans l'intimité?",
            "Où sur le corps aimes-tu le plus être embrassé(e)?",
            "Quel fantasme aimerais-tu absolument tester?"
        }
    };

    private static final String[][] PACK_DARES_FR = {
        { // 0: Fête et Amusement
            "Fais ta danse de 10 secondes la plus drôle sans musique!",
            "Imite quelqu'un du groupe jusqu'à ce qu'on devine de qui il s'agit.",
            "Raconte une blague avec un visage totalement sérieux.",
            "Laisse le groupe coiffer tes cheveux pour le prochain tour!",
            "Fais une marche au ralenti dramatique à travers la pièce.",
            "Chante le générique d'un dessin animé de ton enfance à plein volume!",
            "Montre ton talent caché le plus inutile!",
            "Bois de l'eau comme un T-Rex avec de tout petits bras!",
            "Fais un moonwalk sur 3 mètres!",
            "Mange un snack sans utiliser tes mains!",
            "Obéis aux ordres de tes amis pendant 1 minute!"
        },
        { // 1: Confessions Profondes
            "Fais un compliment sincère à chaque personne du cercle.",
            "Regarde la personne qui te pose la question dans les yeux pendant 15 secondes sans rire.",
            "Avoue une petite chose pour laquelle tu te sens coupable d'une voix drôle.",
            "Réponds en toute honnêteté à une question libre du groupe.",
            "Appelle un membre de ta famille et dis-lui que tu l'aimes sans aucune raison."
        },
        { // 2: Défis Audacieux
            "Parle comme un méchant de film jusqu'au prochain tour!",
            "Fais 10 pompes tout en faisant des bruits d'animaux!",
            "Fais ta meilleure imitation d'une célébrité.",
            "Invente une règle complètement absurde pour ce jeu!",
            "Reste immobile comme une statue pendant 1 minute complète."
        },
        { // 3: Flirt et Couples
            "Chuchote une phrase de drague marrante à l meilleur de ton voisin.",
            "Tiens la main de la personne à ta droite jusqu au prochain tour!",
            "Danse un slow romantique de 15 secondes sans musique.",
            "Prends un selfie de couple trop mignon avec une personne de ton choix.",
            "Donne un doux baiser sur la joue de ton voisin."
        },
        { // 4: +18 Érotique (VIP)
            "Fais un clin d'œil séducteur à la personne qui pose la question.",
            "Chuchote un secret piquant à l'oreille de ton voisin.",
            "Mords-toi la lèvre de façon très attirante pendant 10 secondes.",
            "Fais un massage des épaules relaxant de 30 secondes à ton voisin.",
            "Maintiens un contact visuel intense de très près pendant 10 secondes!"
        }
    };

    // --- SPANISH (ES) QUESTIONS ---
    private static final String[][] PACK_TRUTHS_ES = {
        { // 0: Fiesta y Diversión
            "¿Cuál es tu recuerdo de fiesta más divertido o vergonzoso?",
            "Si pudieras cambiar de vida con alguien en esta habitación por un día, ¿quién sería?",
            "¿Cuál es el hábito más extraño que tienes cuando nadie te ve?",
            "¿Cuál fue la mentira más grande que dijiste con cara totalmente seria?",
            "¿Cuál era el apodo más divertido que tenías de niño?",
            "¿Cuál es la compra impulsiva más innecesaria que has hecho?",
            "¡Muestra el historial de búsqueda de Google más vergonzoso de tu teléfono!",
            "¿Cuál fue el peor regalo que te han dado?",
            "¿Cuál es el objeto más raro que llevas en tu bolso o bolsillo ahora mismo?",
            "¿Qué aplicación de tu teléfono nunca usas pero te niegas a borrar?",
            "¿Cuál es tu talento oculto más secreto e inútil?",
            "¿Cuál sería el trabajo de tus sueños absoluto?",
            "Si nuestro grupo fuera una serie de televisión, ¿qué papel interpretarías?",
            "¿Cuál es mi defecto más molesto cuando viajamos juntos?",
            "¿Quién en esta habitación tiene tu estilo favorito?",
            "¿Cuál es tu recuerdo de adolescencia más vergonzoso?",
            "Si fueras invisible durante 1 hora, ¿qué harías?",
            "Si tuvieras que tatuarte el nombre de alguien de aquí, ¿quién sería?",
            "¿Alguna vez te has sentido avergonzado en público por culpa de tus padres?",
            "¿Alguna vez has tomado algo pequeño sin permiso (bolígrafo, encendedor)?",
            "¿A quién has cotilleado en secreto en Instagram últimamente?",
            "¿Cuál es la comida más rara que has probado?",
            "¿Qué fue lo más extraño que te pasó en un taxi?",
            "¿Cuál fue tu momento más vergonzoso delante de un amigo?",
            "¿Qué raza de perro serías por un día?",
            "¿Alguna vez has culpado a otra persona de tu propio error?",
            "¿Cuál es la historia detrás de tu apodo más extraño?",
            "¿Cuál fue la última palabra que buscaste en internet?",
            "¿A qué película de comedia se parece más tu vida?",
            "¿Qué es algo que siempre te saca una sonrisa o carcajada?"
        },
        { // 1: Confesiones Profundas
            "¿Cuál es un sueño secreto que rara vez compartes con alguien?",
            "¿Qué primera impresión tuviste realmente de la persona que pregunta?",
            "¿Qué decisión individual cambió más el curso de tu vida?",
            "¿Qué error cometiste que te enseñó una gran lección de vida?",
            "¿A qué le das valor que la mayoría de la gente ignora?",
            "¿Qué tendencia de moda nunca entenderás?",
            "¿Qué superpoder práctico te gustaría tener en el día a día?",
            "Si crearas un perfume, ¿cuál sería su nombre?",
            "¿Cuál fue el secreto más grande que me ocultaste durante mucho tiempo?",
            "¿Cuál fue tu primera impresión sincera sobre mí?",
            "¿Qué único consejo le darías a la persona que te pregunta?",
            "¿Qué hábito mío te molesta más?",
            "Si pudieras revivir un recuerdo juntos, ¿cuál elegirías?",
            "¿Cuál fue la mentira más rara que dijiste para protegerme?",
            "Si pudieras saber la fecha exacta de tu muerte, ¿querrías saberla?",
            "Si pudieras legalizar un delito durante 24 horas, ¿cuál sería?",
            "¿Con quién de esta habitación te llevas peor sinceramente?",
            "¿Cuál es tu mayor miedo irracional?",
            "¿Qué esperas que tu familia nunca descubra?",
            "¿Con qué personaje de película te identificas más?",
            "¿Cuál es tu mayor 'Bandera Roja' (Red Flag) de ti mismo?",
            "¿Cuál fue el mensaje más vergonzoso que enviaste por error?",
            "¡Di una mentira y una verdad sobre ti y deja que el grupo adivine!"
        },
        { // 2: Retos Atrevidos
            "¿Qué es lo más atrevido que has hecho en un reto?",
            "¿Qué miedo has superado con éxito?",
            "¿Alguna vez has copiado en un examen sin que te atraparan?",
            "¿Qué hay en la cima de tu lista de deseos (Bucket List)?",
            "¿Qué es lo más valiente que me has visto hacer?",
            "¿Cuándo te sientes en la cima de tu atractivo físico?",
            "¿Qué te da máxima confianza en momentos íntimos?",
            "¿Cuál es la verdad más importante que has aprendido sobre tus deseos?",
            "¿Cuál es tu límite absoluto que nunca cruzarías?"
        },
        { // 3: Flirt y Parejas
            "¿Qué tres cualidades encuentras más atractivas en alguien?",
            "¿Cómo fue tu primer amor platónico de la infancia?",
            "Describe tu cita romántica ideal en una frase.",
            "¿Cuál ha sido el detalle más dulce que alguien ha tenido contigo?",
            "¿Cómo calificarías mis gustos en parejas del 1 al 10?",
            "¿Alguna vez tuviste un interés secreto por mí o por alguien del grupo?",
            "Si pudieras elegir a un famoso para una cita, ¿quién sería?",
            "¿Qué nombre de usuario usarías en una app de citas secreta?",
            "¿Qué atuendo usarías para lucir especialmente atractivo/a?",
            "¿Has coqueteado con alguien durante este juego?",
            "¿Quién en esta habitación tiene la presencia más atractiva?",
            "¿Qué encuentras irresistible cuando alguien coquetea?",
            "¿Qué perfume o aroma te vuelve completamente loco/a?",
            "Si pudieras pasar una noche inolvidable con cualquiera, ¿quién sería?",
            "¿Quién en esta habitación es más probable que conquiste tu corazón?"
        },
        { // 4: +18 Picante (VIP)
            "¿Qué hace que la atracción romántica sea inolvidable para ti?",
            "Química física inolvidable: ¿qué significa para ti?",
            "¿Qué parte de tu cuerpo encuentras más sexy?",
            "Si tuvieras que acostarte con solo una persona de esta habitación, ¿quién sería?",
            "¿Cuál es tu mayor fantasía secreta?",
            "¿A cuántas personas de esta habitación encuentras atractivas?",
            "¿Cuál fue el momento más inoportuno en el que fuiste interrumpido/a?",
            "¿Cuál fue el sueño erótico más loco que has tenido?",
            "¿Cuál fue tu momento más vergonzoso en la cama?",
            "¿Alguna vez tuviste una aventura de una noche? ¿Fue buena o mala?",
            "¿Qué es lo más loco que harías por pasión?",
            "¿Juegos previos sensuales largos o ir directo al grano?",
            "¿Cuál ha sido el cumplido más sexy que te han dicho?",
            "¿Alguna vez has enviado un mensaje o foto picante?",
            "¿Luz tenue romántica o oscuridad total? ¿Por qué?",
            "¿Alguna vez has tenido un sueño íntimo con alguien de esta habitación?",
            "¿Has tenido alguna vez una relación de amigos con derechos?",
            "¿Qué es lo más importante para ti en la intimidad?",
            "¿En qué parte del cuerpo te gusta más que te besen?",
            "¿Qué fantasía te gustaría probar absolutamente?"
        }
    };

    private static final String[][] PACK_DARES_ES = {
        { // 0: Fiesta y Diversión
            "¡Haz tu baile más divertido de 10 segundos sin música!",
            "Imita a alguien del grupo hasta que adivinen quién es.",
            "Cuenta un chiste con cara totalmente seria.",
            "¡Deja que el grupo peine tu cabello para la siguiente ronda!",
            "Haz una caminata dramática en cámara lenta por la habitación.",
            "¡Canta la canción de una serie animada de tu infancia a todo volumen!",
            "¡Muestra tu talento oculto más inútil!",
            "¡Bebe agua como un T-Rex con brazos diminutos!",
            "¡Haz un moonwalk durante 3 metros!",
            "¡Come un aperitivo sin usar las manos!",
            "¡Obedece las órdenes de tus amigos durante 1 minuto!"
        },
        { // 1: Confesiones Profundas
            "Haz un cumplido sincero a cada persona del círculo.",
            "Mira a la persona que pregunta a los ojos durante 15 segundos sin reírte.",
            "Confiesa una pequeña cosa de la que te sientas culpable con voz divertida.",
            "Responde con total honestidad a una pregunta libre del grupo.",
            "Llama a un familiar y dile que le quieres sin ninguna razón."
        },
        { // 2: Retos Atrevidos
            "¡Habla como un villano de película hasta la siguiente ronda!",
            "¡Haz 10 flexiones mientras haces sonidos de animales!",
            "Haz tu mejor imitación de un famoso.",
            "¡Inventa una regla completamente absurda para este juego!",
            "Quédate completamente inmóvil como una estatua durante 1 minuto."
        },
        { // 3: Flirt y Parejas
            "Susurra una frase divertida de coqueteo al oído de tu vecino.",
            "¡Sujeta la mano de la persona a tu derecha hasta la siguiente ronda!",
            "Baila un slow romántico de 15 segundos sin música.",
            "Tómate un selfie de pareja súper tierno con una persona de tu elección.",
            "Dale un suave beso en la mejilla a tu vecino."
        },
        { // 4: +18 Picante (VIP)
            "Guiña un ojo de forma seductora a la persona que pregunta.",
            "Susurra un secreto picante al oído de tu vecino.",
            "Muérdete el labio de forma muy atractiva durante 10 segundos.",
            "Dale un masaje de hombros relajante de 30 segundos a tu vecino.",
        }
    };

    // --- RUSSIAN (RU) QUESTIONS ---
    private static final String[][] PACK_TRUTHS_RU = {
        { // 0: Вечеринка и Веселье
            "Какое твое самое смешное или неловкое воспоминание с вечеринки?",
            "Если бы ты мог поменяться жизнями с кем-то в этой комнате на один день, кто бы это был?",
            "Какая у тебя самая странная привычка, когда никто не видит?",
            "Какая самая большая ложь, которую ты говорил с абсолютно серьезным лицом?",
            "Какое самое смешное прозвище было у тебя в детстве?",
            "Какая самая бесполезная импульсивная покупка в твоей жизни?",
            "Покажи самую неловкую последнюю историю поиска в Google на телефоне!",
            "Какой самый худший или бесполезный подарок ты получал?",
            "Какой самый странный предмет лежит в твоем кармане прямо сейчас?",
            "Какое приложение на телефоне ты никогда не используешь, но жалко удалить?",
            "Какой твой самый секретный и бесполезный талант?",
            "Какая твоя абсолютная работа мечты?",
            "Если бы наша компания была сериалом, какую роль ты бы играл?",
            "Какая моя самая раздражающая черта в совместных поездках?",
            "У кого в этой комнате твой любимый стиль одежды?",
            "Какое твое самое неловкое воспоминание из подросткового возраста?",
            "Если бы ты стал невидимкой на 1 час, что бы ты сделал?",
            "Если бы тебе пришлось набить тату с именем кого-то из присутствующих, чье имя ты бы выбрал?",
            "Стыдился ли ты когда-нибудь поведения родителей на публике?",
            "Утаскивал ли ты когда-нибудь незаметно чужую вещь (ручку, зажигалку)?",
            "Кого ты тайком подглядывал в Instagram в последнее время?",
            "Какую самую странную еду ты пробовал?",
            "Какая самая странная история случалась с тобой в такси?",
            "Какой был твой самый неловкий момент перед другом?",
            "Какои породои собаки ты хотел бы стать на день?",
            "Сваливал ли ты когда-нибудь свою вину на другого человека?",
            "Какова история твоего самого странного прозвища?",
            "Какое последнее слово ты искал в интернете?",
            "На какую комедию больше всего похожа твоя жизнь?",
            "Что гарантированно всегда заставляет тебя смеяться?"
        },
        { // 1: Глубокие Признания
            "Какая твоя самая секретная мечта, которой ты редко делишься?",
            "Какое первое впечатление о тебе на самом деле было у человека, который спрашивает?",
            "Какое одно решение сильнее всего изменило твою жизнь?",
            "Какую ошибку ты совершил, которая преподнесла тебе главный урок?",
            "Что ты ценишь в людях, что большинство игнорирует?",
            "Какой тренд в моде ты никогда не поймешь?",
            "Какую суперспособность ты хотел бы иметь каждый день?",
            "Если бы ты создавал духи, как бы они назывались?",
            "Какой самый большой секрет ты долго скрывал от меня?",
            "Какое было твое самое первое честное впечатление обо мне?",
            "Какой единственный совет ты бы дал человеку, который спрашивает?",
            "Какая моя привычка больше всего тебя раздражает?",
            "Если бы ты мог заново пережить одно общее воспоминание, какое бы ты выбрал?",
            "Какую самую странную ложь ты сказал, чтобы защитить меня?",
            "Если бы ты мог узнать точную дату своей смерти, хотел бы ты знать?",
            "Если бы ты мог легализовать одно преступление на 24 часа, что бы это было?",
            "С кем из присутствующих ты меньше всего ладишь честно говоря?",
            "Какой твой самый главный иррациональный страх?",
            "Что ты надеешься, твоя семья никогда не узнает?",
            "С каким персонажем кино ты себя больше всего ассоциируешь?",
            "Какой твой самый главный 'Red Flag' в себе самом?",
            "Какое самое неловкое сообщение ты отправлял по ошибке?",
            "Расскажи одну ложь и одну правду о себе, пусть группа угадает!"
        },
        { // 2: Смелые Вызовы
            "Какая самая смелая вещь, которую ты делал на спор?",
            "Какой страх ты успешно преодолел?",
            "Списывал ли ты когда-нибудь на экзамене так, что тебя не поймали?",
            "Что стоит на самом верху твоего списка желаний (Bucket List)?",
            "Какои самый смелый поступок ты видел в моем исполнении?",
            "Когда ты чувствуешь себя на пике привлекательности?",
            "Что дает тебе максимальную уверенность в интимные моменты?",
            "Какую главную правду ты понял о своих желаниях?",
            "Какая твоя абсолютная черта, которую ты никогда не переступишь?"
        },
        { // 3: Флирт и Пары
            "Какие три качества ты находишь самыми привлекательными в человеке?",
            "Каковой была твоя самая первая школьная любовь?",
            "Опиши свое идеальное романтическое свидание одним предложением.",
            "Какой самый милый знак внимания кто-то оказывал тебе?",
            "Как бы ты оценил мой вкус в партнерах от 1 до 10?",
            "Был ли ты тайком влюблен в меня или в кого-то из группы?",
            "Если бы ты мог выбрать знаменитость для свидания, кто бы это был?",
            "Какои никнейм ты бы использовал в секретном приложении знакомств?",
            "Какой наряд ты бы надел, чтобы выглядеть максимально привлекательно?",
            "Флиртовал ли ты с кем-нибудь во время этой игры?",
            "У кого в этой комнате самая привлекательная харизма?",
            "Что ты находишь неотразимым, когда кто-то флиртует?",
            "Какой парфюм или запах сводит тебя с ума?",
            "Если бы ты мог провести незабываемую ночь с кем угодно, кто бы это был?",
            "Кто в этой комнате скорее всего покорил бы твое сердце?"
        },
        { // 4: +18 Горячо (VIP)
            "Что делает романтическое притяжение незабываемым для тебя?",
            "Незабываемая физическая химия: что это значит для тебя?",
            "Какую часть своего тела ты считаешь самой сексуальной?",
            "Если бы тебе пришлось переспать только с одним человеком из этой комнаты, кто бы это был?",
            "Какая твоя самая большая секретная фантазия?",
            "Сколько человек в этой комнате ты находишь привлекательными?",
            "Какой был самый не вовремя случившийся момент, когда вас прервали?",
            "Какой самый сумасшедший эротический сон ты видел?",
            "Какой был твой самый неловкий момент в постели?",
            "Был ли у тебя когда-нибудь секс на одну ночь? Было хорошо или плохо?",
            "На какую самую безумную вещь ты бы пошел ради страсти?",
            "Долгие чувственные прелюдии или сразу к делу?",
            "Какой самый сексуальный комплимент тебе говорили?",
            "Отправлял ли ты когда-нибудь горячие фото или сообщения?",
            "Приглушенный романтический свет или полная темнота? Почему?",
            "Видел ли ты интимный сон о ком-то из этой комнаты?",
            "Были ли у тебя когда-нибудь отношения 'Friends with Benefits'?",
            "Что для тебя самое важное в интимной близости?",
            "В какое место на теле ты больше всего любишь поцелуи?",
            "Какую фантазию ты обязательно хотел бы попробовать?"
        }
    };

    private static final String[][] PACK_DARES_RU = {
        { // 0: Вечеринка и Веселье
            "Сделай свой самый смешной 10-секундный танец без музыки!",
            "Изображай кого-то из группы, пока все не угадают, кто это.",
            "Расскажи шутку с абсолютно серьезным лицом.",
            "Пусть группа сделает тебе прическу на следующий раунд!",
            "Сделай драматичную проходку в слоу-мо по комнате.",
            "Спой заглавную песню мультика из детства во весь голос!",
            "Покажи свой самый бесполезный скрытый талант!",
            "Попей водички как Т-Рекс с крошечными лапками!",
            "Сделай лунную походку на 3 метра!",
            "Съешь закуску без помощи рук!",
            "Выполняй приказы друзей в течение 1 минуты!"
        },
        { // 1: Глубокие Признания
            "Сделай искренний комплимент каждому человеку в кругу.",
            "Смотри в глаза спрашивающему 15 секунд не смеясь.",
            "Признайся в одной маленькой вещи, за которую тебе стыдно, смешным голосом.",
            "Ответь абсолютно честно на любой вопрос группы.",
            "Позвони родственнику и просто скажи, что любишь его."
        },
        { // 2: Смелые Вызовы
            "Разговаривай как злодей из фильма до следующего хода!",
            "Сделай 10 отжиманий, издавая звуки животных!",
            "Сделай свою лучшую пародию на знаменитость.",
            "Придумай абсолютно безумное новое правило для этой игры!",
            "Замри как статуя на 1 целую минуту."
        },
        { // 3: Флирт и Пары
            "Шепни милую пикап-фразу на ухо своему соседу.",
            "Держи за руку человека справа до следующего хода!",
            "Станцуй 15-секундный медленный романтический танец без музыки.",
            "Сделай супер милое парное селфи с выбранным игроком.",
            "Поцелуй соседа нежно в щечку."
        },
        { // 4: +18 Горячо (VIP)
            "Сладостно подмигни человеку, который задает вопрос.",
            "Шепни пикантный секрет на ухо своему соседу.",
            "Прикуси губу максимально соблазнительно на 10 секунд.",
            "Сделай расслабляющий 30-секундный массаж плеч соседу.",
            "Удерживай интенсивный зрительный контакт с очень близкого расстояния 10 секунд!"
        }
    };

    private void handleTypeChoiceTouch(float x, float y) {
        // Modal box: (100, 520, 980, 1120)
        // Close button: top right (900, 540, 960, 600)
        if (hit(x, y, 880, 530, 970, 620)) {
            typeChoiceModalOpen = false;
            return;
        }
        // TRUTH button: (160, 770, 490, 930)
        if (hit(x, y, 160, 770, 490, 930)) {
            selectCardType(true);
            return;
        }
        // DARE button: (590, 770, 920, 930)
        if (hit(x, y, 590, 770, 920, 930)) {
            selectCardType(false);
            return;
        }
    }

    private void selectCardType(boolean isTruth) {
        typeChoiceModalOpen = false;
        playCardSound();
        switch (selectedLanguage) {
            case LANG_TR: drawnCardType = isTruth ? "DOĞRULUK" : "CESARETLİK"; break;
            case LANG_DE: drawnCardType = isTruth ? "WAHRHEIT" : "PFLICHT"; break;
            case LANG_FR: drawnCardType = isTruth ? "VÉRITÉ" : "DÉFI"; break;
            case LANG_ES: drawnCardType = isTruth ? "VERDAD" : "RETO"; break;
            case LANG_RU: drawnCardType = isTruth ? "ПРАВДА" : "ДЕЙСТВИЕ"; break;
            default: drawnCardType = isTruth ? "TRUTH" : "DARE"; break;
        }

        // Collect available active deck indices (Exclude 5: Free Mode)
        List<Integer> activePacks = new ArrayList<>();
        for (int i = 0; i < 5; i++) {
            if (selectedPacks[i]) {
                if (i == 4 && !vip) continue;
                activePacks.add(i);
            }
        }
        if (activePacks.isEmpty()) activePacks.add(0); // Fallback to Party & Fun

        int chosenPack = activePacks.get(random.nextInt(activePacks.size()));
        drawnCardPackName = getPackName(chosenPack);

        String[] pool;
        if (isTruth) {
            switch (selectedLanguage) {
                case LANG_TR: pool = PACK_TRUTHS_TR[chosenPack]; break;
                case LANG_DE: pool = PACK_TRUTHS_DE[chosenPack]; break;
                case LANG_FR: pool = PACK_TRUTHS_FR[chosenPack]; break;
                case LANG_ES: pool = PACK_TRUTHS_ES[chosenPack]; break;
                case LANG_RU: pool = PACK_TRUTHS_RU[chosenPack]; break;
                default: pool = PACK_TRUTHS[chosenPack]; break;
            }
        } else {
            switch (selectedLanguage) {
                case LANG_TR: pool = PACK_DARES_TR[chosenPack]; break;
                case LANG_DE: pool = PACK_DARES_DE[chosenPack]; break;
                case LANG_FR: pool = PACK_DARES_FR[chosenPack]; break;
                case LANG_ES: pool = PACK_DARES_ES[chosenPack]; break;
                case LANG_RU: pool = PACK_DARES_RU[chosenPack]; break;
                default: pool = PACK_DARES[chosenPack]; break;
            }
        }
        drawnCardText = pool[random.nextInt(pool.length)];

        drawnCardModalOpen = true;
    }

    private void handleDrawnCardTouch(float x, float y) {
        // Card modal box: (80, 440, 1000, 1260)
        // Action / Next Spin Button: (220, 1110, 860, 1210)
        if (hit(x, y, 200, 1100, 880, 1230) || hit(x, y, 890, 450, 980, 540)) {
            drawnCardModalOpen = false;
            startSpin();
        }
    }

    private void drawTypeChoiceModal(Canvas c) {
        p.setColor(Color.argb(210, 4, 10, 24));
        c.drawRect(0, 0, VW, VH, p);

        RectF box = new RectF(100, 520, 980, 1120);
        neonRoundRect(c, box, 36, Color.rgb(0, 242, 254), Color.argb(245, 12, 18, 36), 6, 26);

        neonText(c, "✕", 930, 580, 52, Color.WHITE, Paint.Align.CENTER);
        neonText(c, isTR() ? "KART TÜRÜNÜ SEÇ" : "CHOOSE TYPE", 540, 620, 48, Color.rgb(0, 242, 254), Paint.Align.CENTER);

        if (questioner >= 0 && answerer >= 0) {
            String sub = players.get(questioner).name.toUpperCase(Locale.ROOT) + "  ➜  " +
                         players.get(answerer).name.toUpperCase(Locale.ROOT);
            text(c, sub, 540, 680, 31, Color.rgb(255, 204, 0), Paint.Align.CENTER, true);
        }

        drawActionButton(c, new RectF(160, 770, 490, 930), isTR() ? "DOĞRULUK" : "TRUTH", true, Color.rgb(0, 242, 254));
        drawActionButton(c, new RectF(590, 770, 920, 930), isTR() ? "CESARETLİK" : "DARE", true, Color.rgb(245, 50, 120));
    }

    private void drawDrawnCardModal(Canvas c) {
        p.setColor(Color.argb(225, 4, 10, 24));
        c.drawRect(0, 0, VW, VH, p);

        RectF box = new RectF(80, 440, 1000, 1260);
        boolean isTruth = drawnCardType.contains("TRUTH") || drawnCardType.contains("DOĞRULUK");
        int themeColor = isTruth ? Color.rgb(0, 242, 254) : Color.rgb(245, 50, 120);
        neonRoundRect(c, box, 40, themeColor, Color.argb(245, 10, 15, 32), 6, 30);

        neonText(c, "✕", 940, 510, 52, Color.WHITE, Paint.Align.CENTER);

        // Header Pill Badge: TRUTH or DARE / DOĞRULUK veya CESARETLİK
        RectF badge = new RectF(340, 490, 740, 570);
        neonRoundRect(c, badge, 24, themeColor, themeColor, 0, 16);
        neonText(c, drawnCardType, 540, 548, 42, Color.rgb(10, 15, 30), Paint.Align.CENTER);

        // Pack Tag
        text(c, "[ " + drawnCardPackName.toUpperCase(Locale.ROOT) + " ]", 540, 630, 26,
                Color.rgb(180, 230, 255), Paint.Align.CENTER, true);

        // Questioner -> Answerer tag
        if (questioner >= 0 && answerer >= 0) {
            Player q = players.get(questioner), a = players.get(answerer);
            String pair = q.name.toUpperCase(Locale.ROOT) + "  ➔  " + a.name.toUpperCase(Locale.ROOT);
            text(c, pair, 540, 680, 31, Color.rgb(255, 204, 0), Paint.Align.CENTER, true);
        }

        // Question Text (wrapped and centered)
        drawWrappedCentered(c, drawnCardText, 540, 770, 800, 36, Color.WHITE, 50);

        // Done / Next Spin Button
        drawActionButton(c, new RectF(220, 1110, 860, 1210), isTR() ? "SONRAKİ TUR" : "NEXT SPIN", true, themeColor);
    }

    private static boolean hit(float x, float y, float l, float t, float r, float b) {
        return x >= l && x <= r && y >= t && y <= b;
    }
    private static float distance(float x1, float y1, float x2, float y2) {
        float dx = x1 - x2, dy = y1 - y2;
        return (float)Math.sqrt(dx * dx + dy * dy);
    }
    private static int withAlpha(int color, int alpha) {
        return Color.argb(alpha, Color.red(color), Color.green(color), Color.blue(color));
    }
    private static float normalizeAngle(float value) {
        value %= 360f;
        return value < 0 ? value + 360f : value;
    }
    private static String ellipsize(String s, int max) {
        if (s == null) return "";
        return s.length() <= max ? s : s.substring(0, Math.max(1, max - 1)) + "…";
    }

    private static class Player {
        final String name;
        final int color;
        Player(String name, int color) { this.name = name; this.color = color; }
    }
}
