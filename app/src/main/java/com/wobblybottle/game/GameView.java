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
    private int selectedLanguage = LANG_EN; // Default to EN (English) as requested!

    private static final String[] LANG_NAMES = {
        "🇬🇧 English",
        "🇹🇷 Türkçe",
        "🇩🇪 Deutsch",
        "🇫🇷 Français",
        "🇪🇸 Español"
    };

    public boolean isTurkish() { return selectedLanguage == LANG_TR; }
    private boolean isTR() { return selectedLanguage == LANG_TR; }

    private String getObjectName(int index) {
        if (isTR()) {
            switch (index) {
                case 0: return "Komik Gazoz Şişesi";
                case 1: return "Öten Tavuk";
                case 2: return "Çıtır Turşu";
                case 3: return "Çılgın Terlik";
                case 4: return "Şampanya Şişesi";
            }
        }
        return OBJECT_NAMES[index];
    }

    private String getPackName(int index) {
        if (isTR()) {
            switch (index) {
                case 0: return "PARTİ VE EĞLENCE";
                case 1: return "DERİN İTİRAFLAR";
                case 2: return "CESUR GÖREVLER";
                case 3: return "FLÖRT VE ÇİFTLER";
                case 4: return "+18 ATEŞLİ";
                case 5: return "SERBEST MOD";
            }
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

    public GameView(Context context) {
        super(context);
        setLayerType(View.LAYER_TYPE_SOFTWARE, null);
        objectSheet = BitmapFactory.decodeResource(getResources(), R.drawable.object_sheet_alpha);
        packSheet = BitmapFactory.decodeResource(getResources(), R.drawable.pack_sheet);
        bgBitmap = BitmapFactory.decodeResource(getResources(), R.drawable.game_bg);
        sliceObjectSheet();
        loadBentSprites();
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
            "Parti veya arkadaş ortamında başından geçen en komik veya utanç verici anın nedir?",
            "Bu odadaki biriyle 1 günlüğüne hayatını değiştirecek olsan kiminle değiştirirdin?",
            "Kimse bakmıyorken yaptığın en garip alışkanlığın nedir?",
            "Ciddi bir yüz ifadesiyle söylediğin en büyük yalan neydi?",
            "Çocukken sana takılan en komik lakap neydi?",
            "Bir anlık gazla satın aldığın en saçma şey neydi?",
            "Son yaptığın utanç verici Google aramasını göster.",
            "Şimdiye kadar aldığın en kötü hediye neydi?",
            "Şu an çantanda/ceplerinde olan en tuhaf şey ne?",
            "Telefonundaki en gereksiz ama yine de silmediğin uygulama hangisi?",
            "Başkalarının bilmediği en büyük gizli yeteneğim ne?",
            "Okuduğum bölümle hiç alakası olmasa bile, sence ben ne iş yapmalıyım?",
            "Arkadaş grubumuz bir sitcom olsaydı, senin rolün ne olurdu? (Bilge, dram kraliçesi, unutulan...)",
            "Birlikte seyahat ederken yaptığım en sinir bozucu şey ne?",
            "Hayatını buradaki biriyle bir haftalığına değiştirebilseydin, bu kim olurdu ve ilk ne yapardın?",
            "Çocukluğundan/ergenliğinden utanç verici bir anını anlat."
        },
        { // 1: Derin İtiraflar
            "Neredeyse kimseye anlatmadığın en gizli hayalin veya hedefin nedir?",
            "Soran kişi hakkındaki İLK izlenimin neydi, şu an ne değişti?",
            "Hayatının akışını en çok değiştiren tek bir karar hangisiydi?",
            "Yaptığın ve sana büyük bir hayat dersi veren en büyük hatan neydi?",
            "İnsanların fark etmediği ama senin çok değer verdiğin bir özelliğin nedir?",
            "Asla anlayamayacağın moda akımı hangisi?",
            "Sadece günlük hayatını kolaylaştırmak için hangi süper güce sahip olmak isterdin?",
            "Bir parfüm yaratacak olsan adı ve kokusu ne olurdu?",
            "Benim için en uzun süre sakladığın sır neydi?",
            "Tanıştığımızda benimle ilgili gerçekten ilk izlenimin neydi?",
            "Sana bu soruyu soran kişiye tek bir hayat tavsiyesi verecek olsan, bu ne olurdu?",
            "Bendeki hangi huyuna en çok sinir oluyorsun?",
            "Birlikte yaşadığımız anılardan sadece birini tekrar yaşayabilseydin, hangisini seçerdin?",
            "Beni korumak için söylediğin en garip yalan neydi?"
        },
        { // 2: Cesur Görevler
            "Bir cesaret oyunu uğruna yaptığın en çılgınca şey neydi?",
            "Başarıyla üstesinden geldiğin en büyük korkun nedir?",
            "Bir sınavda veya oyunda kopya çekip yakalanmadığın oldu mu?",
            "Ölmeden önce yapılacaklar listendeki en çılgın şey nedir?",
            "Yaptığımı gördüğün en cesurca şey neydi?"
        },
        { // 3: Flört ve Çiftler
            "Bir insanda seni en çok etkileyen 3 özellik nedir?",
            "Hayatındaki ilk çocukluk veya gençlik aşkın nasıldı?",
            "Hayalindeki en romantik buluşmayı tek cümleyle tarif et.",
            "Birinin senin için yaptığı en tatlı ve unutulmaz jest neydi?",
            "Sevgili seçme konusundaki becerimi 10 üzerinden puanlaman gerekseydi, kaç verirdin? Neden?",
            "Bana veya gruptaki başka birine hiç 'crush' oldun mu?",
            "Bir date için bir ünlü seçmen gerekseydi, bu kim olurdu?",
            "Gizli bir tanışma uygulamasında hangi takma adı kullanırdın?",
            "Seksi bir kıyafet giymen gerekseydi, bu ne olurdu?",
            "Bu oyunu oynarken hiç flört ettin mi? Anlat!",
            "Crush'ın bu odada olsaydı, ona hangi görevi verirdin?",
            "En son ne zaman bir date'ten kaçmak için yalan söyledin?"
        },
        { // 4: +18 Ateşli
            "Seni romantik veya tutkulu anlamda en çok ne etkiler?",
            "Gizli kalmasını istediğin en romantik veya iddialı anın nedir?",
            "Attığın en iddialı veya cesur mesaj neydi?",
            "Unutulmaz bir uyum senin için ne anlama gelir?",
            "Vücudunun en seksi bulduğun yeri neresi?",
            "Buradaki tek bir kişiyle yatman gerekseydi, bu kim olurdu?",
            "Birini öptüğün en sıra dışı yer neresiydi?",
            "Kendini ne zaman en çekici hissediyorsun?",
            "En büyük fantezin ne?",
            "Duymayı hayal ettiğin en cüretkar iltifat ne?",
            "Buradaki kaç kişiyle yatabilirdin?",
            "Ne kadar sürede orgazm olursun?",
            "Sevişirken rahatsız edilmek için en kötü an hangisi?",
            "Hangi şarkı seni kesinlikle erotik moda sokar?",
            "Eski sevgilinin adını taşıyan bir kokteyl yapsan içinde ne olurdu?"
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
            "Kendi etrafında 10 kez dön ve sonra düz bir çizgide yürümeye çalış."
        },
        { // 1: Derin İtiraflar
            "Çamberdeki HERKESE içten ve samimi bir övgü söyle.",
            "Soran kişinin gözlerinin içine hiç gülmeden 15 saniye boyunca bak.",
            "Suçluluk duyduğun küçük bir şeyi komik bir ses tonuyla itiraf et.",
            "Soran kişinin sana sormak istediği 1 serbest soruya dürüstçe cevap ver.",
            "Buradaki her kişiye çok spesifik bir iltifat et.",
            "Ailenden birini ara ve hiçbir neden yokken onu sevdiğini söyle."
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
            "Bir dakika boyunca tamamen donmuş bir manken gibi dur (mümkünse gözlerini kırpmadan!)."
        },
        { // 3: Flört ve Çiftler
            "Soran kişiye en samimi ve etkileyici övgünü yap.",
            "Soran kişinin kulağına komik bir tavlama cümlesi fısılda.",
            "Sağındaki kişinin elini sonraki tura kadar tut!",
            "Meşhur bir romantik film sahnesini soran kişiyle canlandır.",
            "Birinin gözlerinin içine bakarak bir aşk şarkısı söyle."
        },
        { // 4: +18 Ateşli
            "Soran kişiye en çekici göz kırpmanı ve gülümsemeni yap.",
            "Bir klipteymişsin gibi 15 saniye boyunca kendi kendine dans et.",
            "Solundaki kişinin kulağına iddialı bir sır fısılda.",
            "Soran kişiye o anda 2 satırlık tatlı bir şiir uydur!",
            "Pantolonunu veya üstünü başka bir oyuncuyla değiştir (tabii o da kabul ederse!). Ve bir sonraki turuna kadar öyle kal.",
            "Crush'ına (veya cesaretin varsa eski sevgiline!) nasıl olduğunu soran bir sesli mesaj gönder."
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
            "Share your most embarrassing story from your childhood or teenage years!"
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
            "What is the weirdest lie you ever told to protect me?"
        },
        { // 2: Bold Challenges
            "What is the boldest thing you have ever done on a dare?",
            "What is a fear you have successfully overcome?",
            "Have you ever cheated in a game or test and gotten away with it?",
            "What is something wild on your bucket list?",
            "What is the bravest thing you have ever seen me do?"
        },
        { // 3: Flirt and Couples
            "What three qualities do you find most attractive in someone?",
            "What was your very first crush like?",
            "Describe your ideal romantic date in one sentence.",
            "What is the sweetest gesture someone has ever done for you?",
            "If you had to rate my taste in partners out of 10, what score would you give and why?",
            "Have you ever had a secret crush on me or anyone else in this group?"
        },
        { // 4: +18 Spicy (VIP)
            "What makes romantic chemistry unforgettable to you?",
            "What is your secret romantic guilty pleasure?",
            "What is the boldest romantic text you have ever sent?",
            "Describe your idea of perfect passion."
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
            "Spin around in a circle 10 times then try to walk a straight line!"
        },
        { // 1: Deep Confessions
            "Share a genuine, heartfelt compliment with every person in the circle.",
            "Look into the questioner's eyes for 15 seconds without laughing.",
            "Confess one small thing you feel guilty about in a funny voice.",
            "Let the questioner ask you ONE extra free question that you must answer.",
            "Give a super specific and unique compliment to every single person in the room.",
            "Call a family member right now and tell them you love them for no reason!"
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
            "Freeze completely like a mannequin for 1 full minute without moving!"
        },
        { // 3: Flirt and Couples
            "Give the questioner your best sincere romantic compliment.",
            "Whisper a funny pickup line into the questioner's ear.",
            "Hold hands with the person on your right for the next turn!",
            "Reenact a famous movie romantic scene with the questioner!",
            "Sing a passionate love song while looking straight into someone's eyes!"
        },
        { // 4: +18 Spicy (VIP)
            "Give your most charming wink and smile to the questioner.",
            "Slow dance by yourself for 15 seconds like you are in a music video.",
            "Whisper a spicy secret to the person on your left.",
            "Make up a romantic 2-line poem on the spot for the questioner!"
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
        drawnCardType = isTruth ? (isTR() ? "DOĞRULUK" : "TRUTH") : (isTR() ? "CESARETLİK" : "DARE");

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

        String[] pool = isTruth ? PACK_TRUTHS[chosenPack] : PACK_DARES[chosenPack];
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
