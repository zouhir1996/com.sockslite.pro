// ignore_for_file: prefer_const_constructors

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import '../../core/ad_callbacks.dart';
import '../../core/ads_base.dart';
import '../../core/log.dart';
import '../../models/multiads_config.dart';
import 'facebook_data.dart';

class FacebookAD extends Ads {
  static const MethodChannel _channel = MethodChannel(
    'com.multiads/facebook_ads',
  );

  final FacebookData _facebookData;
  final MultiAdsConfig _config;

  FacebookAD(this._facebookData, this._config);

  // ---------------------------------------------------------------------------
  // INDEXES
  // ---------------------------------------------------------------------------

  int _bannerIndex = -1;
  int _interIndex = -1;
  int _rewardIndex = -1;
  int _nativeIndex = -1;
  int _nativeBannerIndex = -1;

  // ---------------------------------------------------------------------------
  // STATES
  // ---------------------------------------------------------------------------

  bool _interLoaded = false;
  bool _rewardLoaded = false;

  bool _interLoading = false;
  bool _rewardLoading = false;

  // ---------------------------------------------------------------------------
  // READY STATES
  // ---------------------------------------------------------------------------

  final Map<Key, bool> _bannerReady = {};
  final Map<Key, bool> _nativeReady = {};
  final Map<Key, bool> _nativeBannerReady = {};

  // ---------------------------------------------------------------------------
  // CACHED WIDGETS
  // ---------------------------------------------------------------------------

  final Map<Key, Widget> _bannerWidgets = {};
  final Map<Key, Widget> _nativeWidgets = {};
  final Map<Key, Widget> _nativeBannerWidgets = {};

  // ---------------------------------------------------------------------------
  // LOADING TRACKERS
  // ---------------------------------------------------------------------------

  final Set<Key> _bannerLoading = {};
  final Set<Key> _nativeLoading = {};
  final Set<Key> _nativeBannerLoading = {};

  // ---------------------------------------------------------------------------
  // CALLBACKS
  // ---------------------------------------------------------------------------

  Function? _rewardCallback;

  // ---------------------------------------------------------------------------
  // HELPERS
  // ---------------------------------------------------------------------------

  bool _isPlaceholder(String id) {
    return id.isEmpty || id.contains("YOUR_PLACEMENT_ID");
  }

  int _nextIndex(int current, int length) {
    if (length <= 0) return 0;

    return (current + 1) % length;
  }

  String _nextBannerId() {
    _bannerIndex = _nextIndex(_bannerIndex, _facebookData.bannerIds.length);

    return _facebookData.bannerIds[_bannerIndex];
  }

  String _nextInterstitialId() {
    _interIndex = _nextIndex(_interIndex, _facebookData.interIds.length);

    return _facebookData.interIds[_interIndex];
  }

  String _nextRewardId() {
    _rewardIndex = _nextIndex(_rewardIndex, _facebookData.rewardIds.length);

    return _facebookData.rewardIds[_rewardIndex];
  }

  String _nextNativeId() {
    _nativeIndex = _nextIndex(_nativeIndex, _facebookData.nativeIds.length);

    return _facebookData.nativeIds[_nativeIndex];
  }

  String _nextNativeBannerId() {
    _nativeBannerIndex = _nextIndex(
      _nativeBannerIndex,
      _facebookData.nativeBannerIds.length,
    );

    return _facebookData.nativeBannerIds[_nativeBannerIndex];
  }

  // ---------------------------------------------------------------------------
  // INIT
  // ---------------------------------------------------------------------------

  @override
  Future<void> init() async {
    try {
      await _channel.invokeMethod('init', {
        'testingId': _config.facebookTestingId ?? '',
        'iOSTrackingEnabled': _config.facebookiOSTrackingEnabled ?? true,
      });

      Log.log("Facebook >> Initialized successfully");
    } catch (e) {
      Log.log("Facebook >> Init error: $e");
    }
  }

  // ---------------------------------------------------------------------------
  // APP OPEN
  // ---------------------------------------------------------------------------

  @override
  Future<void> loadAppOpenAd() async {
    Log.log("Facebook >> App Open Ads not supported");
  }

  @override
  void showAdIfAvailableOpenAds() {
    Log.log("Facebook >> App Open Ads not supported");
  }

  // ---------------------------------------------------------------------------
  // BANNER
  // ---------------------------------------------------------------------------

  @override
  Future<void> loadBannerAd(Function? onLoaded, Key key) async {
    if (_facebookData.bannerIds.isEmpty) {
      Log.log("Facebook >> No banner IDs");
      return;
    }

    if (_bannerReady[key] == true || _bannerLoading.contains(key)) {
      onLoaded?.call();
      return;
    }

    final placementId = _nextBannerId();

    if (_isPlaceholder(placementId)) {
      Log.log("Facebook >> Invalid banner placement ID");
      return;
    }

    _bannerLoading.add(key);

    Log.log("Facebook >> Loading banner: $placementId");

    _bannerReady[key] = true;

    _bannerLoading.remove(key);

    onLoaded?.call();
  }

  @override
  Widget getBannerAdWidget(Key key) {
    if (_bannerReady[key] != true) return const SizedBox.shrink();

    if (_bannerWidgets.containsKey(key)) return _bannerWidgets[key]!;

    final index = _bannerIndex < 0 ? 0 : _bannerIndex;
    if (index >= _facebookData.bannerIds.length) return const SizedBox.shrink();

    final placementId = _facebookData.bannerIds[index];
    Log.log("Facebook >> Building banner widget: $placementId");

    final widget = RepaintBoundary(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: double.infinity,
          minHeight: 50,
          maxHeight: 50,  // ← force exact height on iOS
        ),
        child: SizedBox(
        width: double.infinity,
        height: 50,
        child: LayoutBuilder( // ← add LayoutBuilder to get actual width
          builder: (context, constraints) {
            return _platformView(
              uniqueKey: key,
              viewType: 'com.multiads/facebook_banner',
              params: {
                'placementId': placementId,
                'width': constraints.maxWidth,  // ← pass actual width
                'height': 50.0,
              },
            );
          },
        ),
      ),
      ),
    );

    _bannerWidgets[key] = widget;
    return widget;
  }

  @override
  Future<void> disposeBanner(Key key) async {
    _bannerReady.remove(key);

    _bannerLoading.remove(key);

    _bannerWidgets.remove(key);

    Log.log("Facebook >> Banner disposed");
  }

  // ---------------------------------------------------------------------------
  // INTERSTITIAL
  // ---------------------------------------------------------------------------

  @override
  Future<void> loadInterstitialAd() async {
    if (_interLoading || _interLoaded) {
      return;
    }

    if (_facebookData.interIds.isEmpty) {
      Log.log("Facebook >> No interstitial IDs");
      return;
    }

    final placementId = _nextInterstitialId();

    if (_isPlaceholder(placementId)) {
      Log.log("Facebook >> Invalid interstitial ID");
      return;
    }

    _interLoading = true;

    try {
      Log.log("Facebook >> Loading interstitial: $placementId");

      await _channel.invokeMethod('loadInterstitial', {
        'placementId': placementId,
      });

      _interLoaded = true;

      Log.log("Facebook >> Interstitial loaded");
    } catch (e) {
      _interLoaded = false;

      Log.log("Facebook >> Interstitial error: $e");
    }

    _interLoading = false;
  }

  @override
  void showInterstitialAd() {
    if (!_interLoaded) {
      Log.log("Facebook >> Interstitial not ready");

      loadInterstitialAd();

      isInterShowed = false;
      final done = AdCallbacks.onInterstitialDismissed;
      AdCallbacks.onInterstitialDismissed = null;
      done?.call();
      return;
    }

    isInterShowed = true;

    _interLoaded = false;

    _channel
        .invokeMethod('showInterstitial')
        .then((_) {
          Log.log("Facebook >> Interstitial shown");

          Future.delayed(const Duration(seconds: 1), loadInterstitialAd);
          isInterShowed = false;
          final done = AdCallbacks.onInterstitialDismissed;
          AdCallbacks.onInterstitialDismissed = null;
          done?.call();
        })
        .catchError((e) {
          Log.log("Facebook >> Show interstitial error: $e");

          _interLoaded = false;
          isInterShowed = false;
          final done = AdCallbacks.onInterstitialDismissed;
          AdCallbacks.onInterstitialDismissed = null;
          done?.call();
        });
  }

  // ---------------------------------------------------------------------------
  // REWARDED
  // ---------------------------------------------------------------------------

  @override
  Future<void> loadRewardAd() async {
    if (_rewardLoading || _rewardLoaded) {
      return;
    }

    if (_facebookData.rewardIds.isEmpty) {
      Log.log("Facebook >> No rewarded IDs");
      return;
    }

    final placementId = _nextRewardId();

    if (_isPlaceholder(placementId)) {
      Log.log("Facebook >> Invalid rewarded ID");
      return;
    }

    _rewardLoading = true;

    try {
      Log.log("Facebook >> Loading rewarded: $placementId");

      await _channel.invokeMethod('loadRewarded', {'placementId': placementId});

      _rewardLoaded = true;

      Log.log("Facebook >> Rewarded loaded");
    } catch (e) {
      _rewardLoaded = false;

      Log.log("Facebook >> Rewarded error: $e");
    }

    _rewardLoading = false;
  }

  @override
  void showRewardAd(Function rewarded) {
    if (!_rewardLoaded) {
      Log.log("Facebook >> Rewarded not ready");

      loadRewardAd();

      return;
    }

    _rewardCallback = rewarded;

    isInterShowed = true;

    _rewardLoaded = false;

    _channel
        .invokeMethod('showRewarded')
        .then((_) {
          Log.log("Facebook >> Rewarded shown");

          _rewardCallback?.call();

          _rewardCallback = null;

          Future.delayed(const Duration(seconds: 2), loadRewardAd);
        })
        .catchError((e) {
          Log.log("Facebook >> Rewarded show error: $e");

          _rewardLoaded = false;
        });
  }

  // ---------------------------------------------------------------------------
  // NATIVE
  // ---------------------------------------------------------------------------

  @override
  Future<void> loadNativeAd(
    Function? onLoaded,
    Key key,
    dynamic templateType,
  ) async {
    if (_facebookData.nativeIds.isEmpty) {
      return;
    }

    if (_nativeReady[key] == true || _nativeLoading.contains(key)) {
      onLoaded?.call();
      return;
    }

    final placementId = _nextNativeId();

    if (_isPlaceholder(placementId)) {
      Log.log("Facebook >> Invalid native ID");
      return;
    }

    _nativeLoading.add(key);

    Log.log("Facebook >> Loading native: $placementId");

    _nativeReady[key] = true;

    _nativeLoading.remove(key);

    onLoaded?.call();
  }

  @override
  Widget getNativeAdWidget(Key key, double height) {
    if (_nativeReady[key] != true) {
      return const SizedBox.shrink();
    }

    if (_nativeWidgets.containsKey(key)) {
      return _nativeWidgets[key]!;
    }

    final placementId =
        _facebookData.nativeIds[_nativeIndex < 0 ? 0 : _nativeIndex];

    final widget = RepaintBoundary(
      child: SizedBox(
        width: double.infinity,
        height: height,
        child: _platformView(
          uniqueKey: key,
          viewType: 'com.multiads/facebook_native',
          params: {'placementId': placementId, 'height': height},
        ),
      ),
    );

    _nativeWidgets[key] = widget;

    return widget;
  }

  @override
  Future<void> disposeNative(Key key) async {
    _nativeReady.remove(key);

    _nativeLoading.remove(key);

    _nativeWidgets.remove(key);

    Log.log("Facebook >> Native disposed");
  }

  // ---------------------------------------------------------------------------
  // NATIVE BANNER
  // ---------------------------------------------------------------------------

  Future<void> loadNativeBannerAd(Function? onLoaded, Key key) async {
    if (_facebookData.nativeBannerIds.isEmpty) {
      return;
    }

    if (_nativeBannerReady[key] == true || _nativeBannerLoading.contains(key)) {
      onLoaded?.call();
      return;
    }

    final placementId = _nextNativeBannerId();

    if (_isPlaceholder(placementId)) {
      Log.log("Facebook >> Invalid native banner ID");
      return;
    }

    _nativeBannerLoading.add(key);

    Log.log("Facebook >> Loading native banner: $placementId");

    _nativeBannerReady[key] = true;

    _nativeBannerLoading.remove(key);

    onLoaded?.call();
  }

  Widget getNativeBannerAdWidget(Key key, {double height = 100}) {
    if (_nativeBannerReady[key] != true) {
      return const SizedBox.shrink();
    }

    if (_nativeBannerWidgets.containsKey(key)) {
      return _nativeBannerWidgets[key]!;
    }

    final placementId = _facebookData
        .nativeBannerIds[_nativeBannerIndex < 0 ? 0 : _nativeBannerIndex];

    final widget = RepaintBoundary(
      child: SizedBox(
        width: double.infinity,
        height: height,
        child: _platformView(
          uniqueKey: key,
          viewType: 'com.multiads/facebook_native_banner',
          params: {'placementId': placementId, 'height': height},
        ),
      ),
    );

    _nativeBannerWidgets[key] = widget;

    return widget;
  }

  Future<void> disposeNativeBanner(Key key) async {
    _nativeBannerReady.remove(key);

    _nativeBannerLoading.remove(key);

    _nativeBannerWidgets.remove(key);

    Log.log("Facebook >> Native banner disposed");
  }

  // ---------------------------------------------------------------------------
  // PLATFORM VIEW
  // ---------------------------------------------------------------------------
  Widget _platformView({
    required Key uniqueKey,
    required String viewType,
    required Map<String, dynamic> params,
  }) {
    final viewKey = ValueKey("$viewType-${params['placementId']}");

    if (Platform.isAndroid) {
      return PlatformViewLink(
        key: viewKey,
        viewType: viewType,
        surfaceFactory: (context, controller) {
          return AndroidViewSurface(
            controller: controller as AndroidViewController,
            hitTestBehavior: PlatformViewHitTestBehavior.transparent,
            gestureRecognizers: const <Factory<OneSequenceGestureRecognizer>>{},
          );
        },
        onCreatePlatformView: (PlatformViewCreationParams creationParams) {
          final controller = PlatformViewsService.initSurfaceAndroidView(
            id: creationParams.id,
            viewType: viewType,
            layoutDirection: TextDirection.ltr,
            creationParams: Map<String, dynamic>.from(params), // ✅ SAFE COPY
            creationParamsCodec: const StandardMessageCodec(),
          );

          controller
            ..addOnPlatformViewCreatedListener(
              creationParams.onPlatformViewCreated,
            )
            ..create();

          return controller;
        },
      );
    }

    if (Platform.isIOS) {
      return UiKitView(
        key: viewKey,
        viewType: viewType,
        creationParams: Map<String, dynamic>.from(params), // ✅ SAFE COPY
        creationParamsCodec: const StandardMessageCodec(),
      );
    }

    return const SizedBox.shrink();
  }
}
