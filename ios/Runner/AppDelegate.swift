import AVFoundation
import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private let channelName = "com.wobblybottle/audio"
  private var audioChannel: FlutterMethodChannel?
  private var pluginRegistrar: FlutterPluginRegistrar?
  private var bgmPlayer: AVAudioPlayer?
  private var clickPlayer: AVAudioPlayer?
  private var cardPlayer: AVAudioPlayer?
  private var isMuted: Bool = false
  private var observersRegistered: Bool = false

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    registerLifecycleObservers()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    self.pluginRegistrar = engineBridge.pluginRegistry.registrar(forPlugin: "WobblyAudioPlugin")
    setupAudioChannel(messenger: engineBridge.applicationRegistrar.messenger())
    initAudio()
  }

  private func setupAudioChannel(messenger: FlutterBinaryMessenger) {
    guard audioChannel == nil else { return }
    let channel = FlutterMethodChannel(name: channelName, binaryMessenger: messenger)
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self = self else {
        result(false)
        return
      }
      switch call.method {
      case "startBgm":
        self.startBgmIfNeeded()
        result(self.bgmPlayer != nil)
      case "loadAudioBytes":
        if let args = call.arguments as? [String: Any] {
          self.loadAudioFromBytes(args)
        }
        result(self.bgmPlayer != nil)
      case "setMuted":
        let args = call.arguments as? [String: Any]
        let muted = args?["muted"] as? Bool ?? false
        self.isMuted = muted
        if self.isMuted {
          if self.bgmPlayer?.isPlaying == true {
            self.bgmPlayer?.pause()
          }
        } else {
          self.startBgmIfNeeded()
        }
        result(true)
      case "playClick":
        if !self.isMuted {
          self.configureAudioSession()
          if self.clickPlayer == nil {
            self.initAudio()
          }
          if let player = self.clickPlayer {
            player.currentTime = 0
            player.volume = 1.0
            player.play()
          }
        }
        result(true)
      case "playCard":
        if !self.isMuted {
          self.configureAudioSession()
          if self.cardPlayer == nil {
            self.initAudio()
          }
          if let player = self.cardPlayer {
            player.currentTime = 0
            player.volume = 1.0
            player.play()
          }
        }
        result(true)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    self.audioChannel = channel
  }

  private func configureAudioSession() {
    do {
      let session = AVAudioSession.sharedInstance()
      try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
      try session.setActive(true)
    } catch {
      // Ignore audio session configuration errors
    }
  }

  private func resolveAssetUrl(_ name: String, ext: String = "mp3") -> URL? {
    let assetKeyPath = "assets/\(name).\(ext)"
    if let registrar = self.pluginRegistrar {
      let key = registrar.lookupKey(forAsset: assetKeyPath)
      if let path = Bundle.main.path(forResource: key, ofType: nil) {
        return URL(fileURLWithPath: path)
      }
    }
    let key = FlutterDartProject.lookupKey(forAsset: assetKeyPath)
    if let path = Bundle.main.path(forResource: key, ofType: nil) {
      return URL(fileURLWithPath: path)
    }
    let directFrameworkPath = Bundle.main.bundleURL
      .appendingPathComponent("Frameworks/App.framework/flutter_assets/assets/\(name).\(ext)").path
    if FileManager.default.fileExists(atPath: directFrameworkPath) {
      return URL(fileURLWithPath: directFrameworkPath)
    }
    if let path = Bundle.main.path(forResource: name, ofType: ext) {
      return URL(fileURLWithPath: path)
    }
    return nil
  }

  private func initAudio() {
    configureAudioSession()
    if clickPlayer == nil, let clickUrl = resolveAssetUrl("btn_click") {
      clickPlayer = try? AVAudioPlayer(contentsOf: clickUrl)
      clickPlayer?.volume = 1.0
      clickPlayer?.prepareToPlay()
    }
    if cardPlayer == nil, let cardUrl = resolveAssetUrl("sound_card") {
      cardPlayer = try? AVAudioPlayer(contentsOf: cardUrl)
      cardPlayer?.volume = 1.0
      cardPlayer?.prepareToPlay()
    }
    startBgmIfNeeded()
  }

  private func loadAudioFromBytes(_ args: [String: Any]) {
    configureAudioSession()
    if clickPlayer == nil, let clickData = (args["click"] as? FlutterStandardTypedData)?.data {
      clickPlayer = try? AVAudioPlayer(data: clickData)
      clickPlayer?.volume = 1.0
      clickPlayer?.prepareToPlay()
    }
    if cardPlayer == nil, let cardData = (args["card"] as? FlutterStandardTypedData)?.data {
      cardPlayer = try? AVAudioPlayer(data: cardData)
      cardPlayer?.volume = 1.0
      cardPlayer?.prepareToPlay()
    }
    if bgmPlayer == nil, let bgmData = (args["bgm"] as? FlutterStandardTypedData)?.data {
      bgmPlayer = try? AVAudioPlayer(data: bgmData)
      bgmPlayer?.numberOfLoops = -1
      bgmPlayer?.volume = 1.0
      bgmPlayer?.prepareToPlay()
    }
    startBgmIfNeeded()
  }

  private func startBgmIfNeeded() {
    if isMuted { return }
    configureAudioSession()
    if bgmPlayer == nil {
      if let bgmUrl = resolveAssetUrl("bgm_party") {
        if let player = try? AVAudioPlayer(contentsOf: bgmUrl) {
          player.numberOfLoops = -1
          player.volume = 1.0
          player.prepareToPlay()
          player.play()
          bgmPlayer = player
        }
      }
    } else if bgmPlayer?.isPlaying == false {
      bgmPlayer?.volume = 1.0
      bgmPlayer?.play()
    }
  }

  private func registerLifecycleObservers() {
    guard !observersRegistered else { return }
    observersRegistered = true

    NotificationCenter.default.addObserver(
      self,
      selector: #selector(handleWillResignActive),
      name: UIApplication.willResignActiveNotification,
      object: nil
    )
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(handleDidBecomeActive),
      name: UIApplication.didBecomeActiveNotification,
      object: nil
    )
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(handleAudioInterruption(_:)),
      name: AVAudioSession.interruptionNotification,
      object: AVAudioSession.sharedInstance()
    )
  }

  @objc private func handleWillResignActive() {
    if bgmPlayer?.isPlaying == true {
      bgmPlayer?.pause()
    }
  }

  @objc private func handleDidBecomeActive() {
    if !isMuted {
      startBgmIfNeeded()
    }
  }

  @objc private func handleAudioInterruption(_ notification: Notification) {
    guard let userInfo = notification.userInfo,
          let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
          let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
      return
    }
    if type == .began {
      if bgmPlayer?.isPlaying == true {
        bgmPlayer?.pause()
      }
    } else if type == .ended {
      if !isMuted {
        startBgmIfNeeded()
      }
    }
  }
}
