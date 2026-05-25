package com.example.multiads

import android.content.Context
import android.graphics.Color
import android.util.Log
import android.view.View
import android.widget.FrameLayout
import com.facebook.ads.*
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

class MultiadsPlugin : FlutterPlugin,
    MethodChannel.MethodCallHandler,
    ActivityAware {

    companion object {
        private const val TAG = "MultiAds"
        private const val CHANNEL = "com.multiads/facebook_ads"
    }

    private lateinit var channel: MethodChannel

    private var context: Context? = null
    private var activityBinding: ActivityPluginBinding? = null

    private var interstitialAd: InterstitialAd? = null
    private var rewardedAd: RewardedVideoAd? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {

        context = binding.applicationContext

        channel = MethodChannel(binding.binaryMessenger, CHANNEL)
        channel.setMethodCallHandler(this)

        binding.platformViewRegistry.registerViewFactory(
            "com.multiads/facebook_banner",
            FacebookBannerFactory(context!!)
        )

        binding.platformViewRegistry.registerViewFactory(
            "com.multiads/facebook_native",
            FacebookNativeFactory(context!!)
        )

        binding.platformViewRegistry.registerViewFactory(
            "com.multiads/facebook_native_banner",
            FacebookNativeBannerFactory(context!!)
        )
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)

        interstitialAd?.destroy()
        rewardedAd?.destroy()

        interstitialAd = null
        rewardedAd = null
    }

    override fun onMethodCall(
        call: MethodCall,
        result: MethodChannel.Result
    ) {

        when (call.method) {

            "init" -> {

                val testingId =
                    call.argument<String>("testingId") ?: ""

                val activity = activityBinding?.activity

                if (activity == null) {
                    result.error(
                        "NO_ACTIVITY",
                        "Activity not attached",
                        null
                    )
                    return
                }

                AudienceNetworkAds.initialize(activity)

                if (testingId.isNotEmpty()) {
                    AdSettings.addTestDevice(testingId)
                }

                Log.d(TAG, "Facebook initialized")

                result.success(null)
            }

            "loadInterstitial" -> {

                val placementId =
                    call.argument<String>("placementId")

                if (placementId.isNullOrEmpty()) {
                    result.error(
                        "INVALID_ID",
                        "Placement ID missing",
                        null
                    )
                    return
                }

                loadInterstitial(placementId, result)
            }

            "showInterstitial" -> {

                if (interstitialAd != null &&
                    interstitialAd!!.isAdLoaded
                ) {

                    interstitialAd!!.show()
                    result.success(null)

                } else {

                    result.error(
                        "NOT_READY",
                        "Interstitial not loaded",
                        null
                    )
                }
            }

            "loadRewarded" -> {

                val placementId =
                    call.argument<String>("placementId")

                if (placementId.isNullOrEmpty()) {
                    result.error(
                        "INVALID_ID",
                        "Placement ID missing",
                        null
                    )
                    return
                }

                loadRewarded(placementId, result)
            }

            "showRewarded" -> {

                if (rewardedAd != null &&
                    rewardedAd!!.isAdLoaded
                ) {

                    rewardedAd!!.show()
                    result.success(null)

                } else {

                    result.error(
                        "NOT_READY",
                        "Rewarded not loaded",
                        null
                    )
                }
            }

            else -> result.notImplemented()
        }
    }

    // ------------------------------------------------------------------------
    // INTERSTITIAL
    // ------------------------------------------------------------------------

    private fun loadInterstitial(
        placementId: String,
        result: MethodChannel.Result
    ) {

        val activity = activityBinding?.activity

        if (activity == null) {
            result.error(
                "NO_ACTIVITY",
                "Activity unavailable",
                null
            )
            return
        }

        interstitialAd?.destroy()

        interstitialAd =
            InterstitialAd(activity, placementId)

        val listener = object : InterstitialAdListener {

            override fun onInterstitialDisplayed(ad: Ad?) {
                Log.d(TAG, "Interstitial displayed")
            }

            override fun onInterstitialDismissed(ad: Ad?) {
                Log.d(TAG, "Interstitial dismissed")
            }

            override fun onError(
                ad: Ad?,
                error: AdError?
            ) {

                Log.e(
                    TAG,
                    "Interstitial error: ${error?.errorMessage}"
                )

                result.error(
                    "LOAD_ERROR",
                    error?.errorMessage,
                    null
                )
            }

            override fun onAdLoaded(ad: Ad?) {

                Log.d(TAG, "Interstitial loaded")

                result.success(null)
            }

            override fun onAdClicked(ad: Ad?) {
                Log.d(TAG, "Interstitial clicked")
            }

            override fun onLoggingImpression(ad: Ad?) {
                Log.d(TAG, "Interstitial impression")
            }
        }

        interstitialAd?.loadAd(
            interstitialAd
                ?.buildLoadAdConfig()
                ?.withAdListener(listener)
                ?.build()
        )
    }

    // ------------------------------------------------------------------------
    // REWARDED
    // ------------------------------------------------------------------------

    private fun loadRewarded(
        placementId: String,
        result: MethodChannel.Result
    ) {

        val activity = activityBinding?.activity

        if (activity == null) {
            result.error(
                "NO_ACTIVITY",
                "Activity unavailable",
                null
            )
            return
        }

        rewardedAd?.destroy()

        rewardedAd =
            RewardedVideoAd(activity, placementId)

        val listener =
            object : RewardedVideoAdListener {

                override fun onRewardedVideoCompleted() {
                    Log.d(TAG, "Reward completed")
                }

                override fun onRewardedVideoClosed() {
                    Log.d(TAG, "Reward closed")
                }

                override fun onError(
                    ad: Ad?,
                    error: AdError?
                ) {

                    Log.e(
                        TAG,
                        "Reward error: ${error?.errorMessage}"
                    )

                    result.error(
                        "LOAD_ERROR",
                        error?.errorMessage,
                        null
                    )
                }

                override fun onAdLoaded(ad: Ad?) {

                    Log.d(TAG, "Reward loaded")

                    result.success(null)
                }

                override fun onAdClicked(ad: Ad?) {
                    Log.d(TAG, "Reward clicked")
                }

                override fun onLoggingImpression(ad: Ad?) {
                    Log.d(TAG, "Reward impression")
                }
            }

        rewardedAd?.loadAd(
            rewardedAd
                ?.buildLoadAdConfig()
                ?.withAdListener(listener)
                ?.build()
        )
    }

    // ------------------------------------------------------------------------
    // ACTIVITY
    // ------------------------------------------------------------------------

    override fun onAttachedToActivity(
        binding: ActivityPluginBinding
    ) {
        activityBinding = binding
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activityBinding = null
    }

    override fun onReattachedToActivityForConfigChanges(
        binding: ActivityPluginBinding
    ) {
        activityBinding = binding
    }

    override fun onDetachedFromActivity() {
        activityBinding = null
    }
}

// ============================================================================
// BANNER VIEW
// ============================================================================

class FacebookBannerFactory(
    private val context: Context
) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {

    override fun create(
        context: Context,
        viewId: Int,
        args: Any?
    ): PlatformView {

        val params = args as? Map<*, *>

        val placementId =
            params?.get("placementId") as? String ?: ""

        return FacebookBannerView(
            this.context,
            placementId
        )
    }
}

class FacebookBannerView(
    context: Context,
    placementId: String
) : PlatformView {

    private val adView =
        AdView(
            context,
            placementId,
            AdSize.BANNER_HEIGHT_50
        )

    init {

        val listener = object : AdListener {

            override fun onError(
                ad: Ad?,
                error: AdError?
            ) {

                Log.e(
                    "FacebookBanner",
                    "Error: ${error?.errorMessage}"
                )
            }

            override fun onAdLoaded(ad: Ad?) {

                Log.d(
                    "FacebookBanner",
                    "Banner loaded"
                )
            }

            override fun onAdClicked(ad: Ad?) {

                Log.d(
                    "FacebookBanner",
                    "Banner clicked"
                )
            }

            override fun onLoggingImpression(ad: Ad?) {

                Log.d(
                    "FacebookBanner",
                    "Banner impression"
                )
            }
        }

        adView.loadAd(
            adView
                .buildLoadAdConfig()
                .withAdListener(listener)
                .build()
        )
    }

    override fun getView(): View {
        return adView
    }

    override fun dispose() {
        adView.destroy()
    }
}

// ============================================================================
// NATIVE VIEW
// ============================================================================

class FacebookNativeFactory(
    private val context: Context
) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {

    override fun create(
        context: Context,
        viewId: Int,
        args: Any?
    ): PlatformView {

        val params = args as? Map<*, *>

        val placementId =
            params?.get("placementId") as? String ?: ""

        return FacebookNativeAdView(
            this.context,
            placementId
        )
    }
}

class FacebookNativeAdView(
    private val context: Context,
    placementId: String
) : PlatformView, NativeAdListener {

    private val container =
        FrameLayout(context)

    private val nativeAd =
        NativeAd(context, placementId)

    init {

        nativeAd.loadAd(
            nativeAd
                .buildLoadAdConfig()
                .withAdListener(this)
                .build()
        )
    }

    override fun onMediaDownloaded(ad: Ad?) {}

    override fun onError(
        ad: Ad?,
        error: AdError?
    ) {

        Log.e(
            "FacebookNative",
            error?.errorMessage ?: "Unknown"
        )
    }

    override fun onAdLoaded(ad: Ad?) {

        val view = FrameLayout(context)

        view.setBackgroundColor(Color.LTGRAY)

        container.removeAllViews()
        container.addView(view)
    }

    override fun onAdClicked(ad: Ad?) {}

    override fun onLoggingImpression(ad: Ad?) {}

    override fun getView(): View {
        return container
    }

    override fun dispose() {
        nativeAd.destroy()
    }
}

// ============================================================================
// NATIVE BANNER
// ============================================================================

class FacebookNativeBannerFactory(
    private val context: Context
) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {

    override fun create(
        context: Context,
        viewId: Int,
        args: Any?
    ): PlatformView {

        val params = args as? Map<*, *>

        val placementId =
            params?.get("placementId") as? String ?: ""

        return FacebookNativeBannerView(
            this.context,
            placementId
        )
    }
}

class FacebookNativeBannerView(
    private val context: Context,
    placementId: String
) : PlatformView, NativeAdListener {

    private val container =
        FrameLayout(context)

    private val nativeBannerAd =
        NativeBannerAd(context, placementId)

    init {

        nativeBannerAd.loadAd(
            nativeBannerAd
                .buildLoadAdConfig()
                .withAdListener(this)
                .build()
        )
    }

    override fun onMediaDownloaded(ad: Ad?) {}

    override fun onError(
        ad: Ad?,
        error: AdError?
    ) {

        Log.e(
            "FacebookNativeBanner",
            error?.errorMessage ?: "Unknown"
        )
    }

    override fun onAdLoaded(ad: Ad?) {

        val view = FrameLayout(context)

        view.setBackgroundColor(Color.LTGRAY)

        container.removeAllViews()
        container.addView(view)
    }

    override fun onAdClicked(ad: Ad?) {}

    override fun onLoggingImpression(ad: Ad?) {}

    override fun getView(): View {
        return container
    }

    override fun dispose() {
        nativeBannerAd.destroy()
    }
}