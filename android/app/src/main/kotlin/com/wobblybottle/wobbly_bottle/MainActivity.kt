package com.wobblybottle.wobbly_bottle

import android.media.AudioAttributes
import android.media.MediaPlayer
import android.media.SoundPool
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.wobblybottle/audio"
    private var bgmPlayer: MediaPlayer? = null
    private var isBgmPreparing: Boolean = false
    private var soundPool: SoundPool? = null
    private var clickSoundId: Int = 0
    private var cardSoundId: Int = 0
    @Volatile private var isMuted: Boolean = false
    private val audioExecutor = Executors.newSingleThreadExecutor()
    private val mainHandler = Handler(Looper.getMainLooper())

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        initAudioAsync()

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startBgm" -> {
                    startBgmIfNeeded()
                    result.success(true)
                }
                "setMuted" -> {
                    val muted = call.argument<Boolean>("muted") ?: false
                    isMuted = muted
                    try {
                        if (isMuted) {
                            if (bgmPlayer?.isPlaying == true) {
                                bgmPlayer?.pause()
                            }
                        } else {
                            startBgmIfNeeded()
                        }
                    } catch (_: Exception) {}
                    result.success(true)
                }
                "playClick" -> {
                    if (!isMuted && clickSoundId != 0) {
                        try {
                            soundPool?.play(clickSoundId, 1.0f, 1.0f, 1, 0, 1.0f)
                        } catch (_: Exception) {}
                    }
                    result.success(true)
                }
                "playCard" -> {
                    if (!isMuted && cardSoundId != 0) {
                        try {
                            soundPool?.play(cardSoundId, 1.0f, 1.0f, 1, 0, 1.0f)
                        } catch (_: Exception) {}
                    }
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun initAudioAsync() {
        audioExecutor.execute {
            try {
                val attrs = AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_GAME)
                    .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                    .build()
                val sp = SoundPool.Builder()
                    .setMaxStreams(6)
                    .setAudioAttributes(attrs)
                    .build()

                val clickRes = resources.getIdentifier("btn_click", "raw", packageName)
                if (clickRes != 0) {
                    clickSoundId = sp.load(this, clickRes, 1)
                }
                val cardRes = resources.getIdentifier("sound_card", "raw", packageName)
                if (cardRes != 0) {
                    cardSoundId = sp.load(this, cardRes, 1)
                }
                soundPool = sp
            } catch (_: Exception) {}
        }
    }

    private fun startBgmIfNeeded() {
        if (isMuted) return
        try {
            val existing = bgmPlayer
            if (existing != null) {
                if (!existing.isPlaying) {
                    existing.setVolume(1.0f, 1.0f)
                    existing.start()
                }
                return
            }
            if (isBgmPreparing) return
            isBgmPreparing = true
            audioExecutor.execute {
                try {
                    val bgmRes = resources.getIdentifier("bgm_party", "raw", packageName)
                    if (bgmRes != 0) {
                        val mp = MediaPlayer.create(applicationContext, bgmRes)
                        mp?.isLooping = true
                        mp?.setVolume(1.0f, 1.0f)
                        mainHandler.post {
                            isBgmPreparing = false
                            bgmPlayer = mp
                            if (!isMuted) {
                                try {
                                    mp?.start()
                                } catch (_: Exception) {}
                            }
                        }
                    } else {
                        isBgmPreparing = false
                    }
                } catch (_: Exception) {
                    isBgmPreparing = false
                }
            }
        } catch (_: Exception) {
            isBgmPreparing = false
        }
    }

    override fun onPause() {
        super.onPause()
        try {
            if (bgmPlayer?.isPlaying == true) {
                bgmPlayer?.pause()
            }
        } catch (_: Exception) {}
    }

    override fun onResume() {
        super.onResume()
        if (!isMuted) {
            startBgmIfNeeded()
        }
    }

    override fun onDestroy() {
        try {
            bgmPlayer?.stop()
            bgmPlayer?.release()
            bgmPlayer = null
            soundPool?.release()
            soundPool = null
            audioExecutor.shutdownNow()
        } catch (_: Exception) {}
        super.onDestroy()
    }
}
