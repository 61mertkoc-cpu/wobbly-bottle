package com.wobblybottle.wobbly_bottle

import android.media.AudioAttributes
import android.media.MediaPlayer
import android.media.SoundPool
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.wobblybottle/audio"
    private var bgmPlayer: MediaPlayer? = null
    private var soundPool: SoundPool? = null
    private var clickSoundId: Int = 0
    private var cardSoundId: Int = 0
    private var isMuted: Boolean = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        initAudio()

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
                        soundPool?.play(clickSoundId, 1.0f, 1.0f, 1, 0, 1.0f)
                    }
                    result.success(true)
                }
                "playCard" -> {
                    if (!isMuted && cardSoundId != 0) {
                        soundPool?.play(cardSoundId, 1.0f, 1.0f, 1, 0, 1.0f)
                    }
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun initAudio() {
        try {
            val attrs = AudioAttributes.Builder()
                .setUsage(AudioAttributes.USAGE_GAME)
                .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                .build()
            soundPool = SoundPool.Builder()
                .setMaxStreams(6)
                .setAudioAttributes(attrs)
                .build()

            val clickRes = resources.getIdentifier("btn_click", "raw", packageName)
            if (clickRes != 0) {
                clickSoundId = soundPool?.load(this, clickRes, 1) ?: 0
            }
            val cardRes = resources.getIdentifier("sound_card", "raw", packageName)
            if (cardRes != 0) {
                cardSoundId = soundPool?.load(this, cardRes, 1) ?: 0
            }
            startBgmIfNeeded()
        } catch (_: Exception) {}
    }

    private fun startBgmIfNeeded() {
        if (isMuted) return
        try {
            if (bgmPlayer == null) {
                val bgmRes = resources.getIdentifier("bgm_party", "raw", packageName)
                if (bgmRes != 0) {
                    bgmPlayer = MediaPlayer.create(this, bgmRes)?.apply {
                        isLooping = true
                        setVolume(1.0f, 1.0f)
                        start()
                    }
                }
            } else if (bgmPlayer?.isPlaying == false) {
                bgmPlayer?.setVolume(1.0f, 1.0f)
                bgmPlayer?.start()
            }
        } catch (_: Exception) {}
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
        } catch (_: Exception) {}
        super.onDestroy()
    }
}
