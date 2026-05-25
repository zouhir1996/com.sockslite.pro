import UIKit
import Flutter
import FBAudienceNetwork

// ─────────────────────────────────────────────────────────────────────────────
// MultiadsPlugin
// ─────────────────────────────────────────────────────────────────────────────

public class MultiadsPlugin: NSObject, FlutterPlugin {

    private var interstitialAd: FBInterstitialAd?
    private var rewardedAd: FBRewardedVideoAd?
    private var loadInterstitialResult: FlutterResult?
    private var loadRewardedResult: FlutterResult?
    private weak var rootViewController: UIViewController?

    // ── Register ──────────────────────────────────────────────────────────────

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "com.multiads/facebook_ads",
            binaryMessenger: registrar.messenger()
        )
        let instance = MultiadsPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)

        registrar.register(
            FacebookBannerViewFactory(),
            withId: "com.multiads/facebook_banner"
        )
        print("MultiAds >> Banner factory registered ✅")
        registrar.register(
            FacebookNativeAdViewFactory(),
            withId: "com.multiads/facebook_native"
        )
        registrar.register(
            FacebookNativeBannerViewFactory(),
            withId: "com.multiads/facebook_native_banner"
        )
    }

    // ── Method handler ────────────────────────────────────────────────────────
    // ✅ args is optional — methods like showInterstitial pass no arguments

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args = call.arguments as? [String: Any] ?? [:]

        rootViewController = UIApplication.shared.windows
            .first(where: { $0.isKeyWindow })?.rootViewController

        switch call.method {
        case "init":           handleInit(args: args, result: result)
        case "loadBanner":     result(nil) // handled by PlatformView
        case "disposeBanner":  result(nil)
        case "loadInterstitial":  handleLoadInterstitial(args: args, result: result)
        case "showInterstitial":  handleShowInterstitial(result: result)
        case "loadRewarded":      handleLoadRewarded(args: args, result: result)
        case "showRewarded":      handleShowRewarded(result: result)
        default:               result(FlutterMethodNotImplemented)
        }
    }

    // ── Init ──────────────────────────────────────────────────────────────────

    private func handleInit(args: [String: Any], result: FlutterResult) {
        let testId = args["testingId"] as? String ?? ""
        let trackingEnabled = args["iOSTrackingEnabled"] as? Bool ?? false

        FBAdSettings.setAdvertiserTrackingEnabled(trackingEnabled)
        if !testId.isEmpty {
            FBAdSettings.addTestDevice(testId)
            print("MultiAds >> Test device added: \(testId)")
        }
        print("MultiAds >> Facebook Audience Network initialized")
        result(nil)
    }

    // ── Interstitial ──────────────────────────────────────────────────────────

    private func handleLoadInterstitial(args: [String: Any], result: @escaping FlutterResult) {
        guard let placementId = args["placementId"] as? String, !placementId.isEmpty else {
            result(FlutterError(code: "INVALID_PLACEMENT",
                                message: "placementId is required", details: nil))
            return
        }
        // Cancel previous pending result if any
        loadInterstitialResult?(FlutterError(code: "CANCELLED",
                                              message: "New load requested", details: nil))
        loadInterstitialResult = result

        interstitialAd = FBInterstitialAd(placementID: placementId)
        interstitialAd?.delegate = self
        interstitialAd?.load()
        print("MultiAds >> Loading interstitial: \(placementId)")
    }

    private func handleShowInterstitial(result: FlutterResult) {
        guard let vc = rootViewController else {
            result(FlutterError(code: "NO_VC",
                                message: "No root view controller found", details: nil))
            return
        }
        guard interstitialAd?.isAdValid == true else {
            result(FlutterError(code: "NOT_LOADED",
                                message: "Interstitial not loaded or expired", details: nil))
            return
        }
        interstitialAd?.show(fromRootViewController: vc)
        result(nil)
        print("MultiAds >> Interstitial shown")
    }

    // ── Rewarded ──────────────────────────────────────────────────────────────

    private func handleLoadRewarded(args: [String: Any], result: @escaping FlutterResult) {
        guard let placementId = args["placementId"] as? String, !placementId.isEmpty else {
            result(FlutterError(code: "INVALID_PLACEMENT",
                                message: "placementId is required", details: nil))
            return
        }
        // Cancel previous pending result if any
        loadRewardedResult?(FlutterError(code: "CANCELLED",
                                         message: "New load requested", details: nil))
        loadRewardedResult = result

        rewardedAd = FBRewardedVideoAd(placementID: placementId)
        rewardedAd?.delegate = self
        rewardedAd?.load()
        print("MultiAds >> Loading rewarded: \(placementId)")
    }

    private func handleShowRewarded(result: FlutterResult) {
        guard let vc = rootViewController else {
            result(FlutterError(code: "NO_VC",
                                message: "No root view controller found", details: nil))
            return
        }
        guard rewardedAd?.isAdValid == true else {
            result(FlutterError(code: "NOT_LOADED",
                                message: "Rewarded ad not loaded or expired", details: nil))
            return
        }
        rewardedAd?.show(fromRootViewController: vc)
        result(nil)
        print("MultiAds >> Rewarded shown")
    }

    // ── Helper ────────────────────────────────────────────────────────────────

    private func errorMessage(from error: Error) -> String {
        let e = error as NSError
        return "[\(e.code)] \(e.localizedDescription) | domain: \(e.domain) | info: \(e.userInfo)"
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// Interstitial Delegate
// ─────────────────────────────────────────────────────────────────────────────

extension MultiadsPlugin: FBInterstitialAdDelegate {

    public func interstitialAdDidLoad(_ interstitialAd: FBInterstitialAd) {
        print("MultiAds >> Interstitial loaded ✅")
        loadInterstitialResult?(nil)
        loadInterstitialResult = nil
    }

    public func interstitialAd(_ interstitialAd: FBInterstitialAd, didFailWithError error: Error) {
        let msg = errorMessage(from: error)
        print("MultiAds >> Interstitial failed ❌ \(msg)")
        loadInterstitialResult?(FlutterError(code: "AD_ERROR", message: msg, details: nil))
        loadInterstitialResult = nil
    }

    public func interstitialAdDidClose(_ interstitialAd: FBInterstitialAd) {
        print("MultiAds >> Interstitial closed")
        self.interstitialAd = nil
    }

    public func interstitialAdWillClose(_ interstitialAd: FBInterstitialAd) {}
    public func interstitialAdDidClick(_ interstitialAd: FBInterstitialAd) {}
    public func interstitialAdWillLogImpression(_ interstitialAd: FBInterstitialAd) {}
}

// ─────────────────────────────────────────────────────────────────────────────
// Rewarded Delegate
// ─────────────────────────────────────────────────────────────────────────────

extension MultiadsPlugin: FBRewardedVideoAdDelegate {

    public func rewardedVideoAdDidLoad(_ rewardedVideoAd: FBRewardedVideoAd) {
        print("MultiAds >> Rewarded loaded ✅")
        loadRewardedResult?(nil)
        loadRewardedResult = nil
    }

    public func rewardedVideoAd(_ rewardedVideoAd: FBRewardedVideoAd, didFailWithError error: Error) {
        let msg = errorMessage(from: error)
        print("MultiAds >> Rewarded failed ❌ \(msg)")
        loadRewardedResult?(FlutterError(code: "AD_ERROR", message: msg, details: nil))
        loadRewardedResult = nil
    }

    public func rewardedVideoAdVideoComplete(_ rewardedVideoAd: FBRewardedVideoAd) {
        print("MultiAds >> Rewarded video completed ✅")
    }

    public func rewardedVideoAdDidClose(_ rewardedVideoAd: FBRewardedVideoAd) {
        print("MultiAds >> Rewarded closed")
        self.rewardedAd = nil
    }

    public func rewardedVideoAdWillLogImpression(_ rewardedVideoAd: FBRewardedVideoAd) {}
    public func rewardedVideoAdDidClick(_ rewardedVideoAd: FBRewardedVideoAd) {}
}

// ─────────────────────────────────────────────────────────────────────────────
// Banner PlatformView
// ─────────────────────────────────────────────────────────────────────────────

class FacebookBannerViewFactory: NSObject, FlutterPlatformViewFactory {
    func create(withFrame frame: CGRect,
                viewIdentifier viewId: Int64,
                arguments args: Any?) -> FlutterPlatformView {
        let params = args as? [String: Any]
        let placementId = params?["placementId"] as? String ?? ""
        return FacebookBannerView(frame: frame, placementId: placementId)
    }
    func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
        return FlutterStandardMessageCodec.sharedInstance()
    }
}
class FacebookBannerView: NSObject, FlutterPlatformView, FBAdViewDelegate {
    private let container: UIView
    private var adView: FBAdView?

    init(frame: CGRect, placementId: String) {
        print("FacebookBanner >> INIT CALLED frame=\(frame) placementId=\(placementId)") // ← add this

        container = UIView(frame: frame)
        container.backgroundColor = .clear
        super.init()

        guard let vc = UIApplication.shared.windows
            .first(where: { $0.isKeyWindow })?.rootViewController else {
            print("FacebookBanner >> No root VC ❌")
            return
        }

        let ad = FBAdView(
            placementID: placementId,
            adSize: kFBAdSizeHeight50Banner,
            rootViewController: vc
        )
        ad.delegate = self
        ad.frame = CGRect(x: 0, y: 0, width: frame.width, height: 50)
        ad.autoresizingMask = [.flexibleWidth]
        container.addSubview(ad)  // ← add to container, don't return ad directly
        ad.loadAd()
        adView = ad
        print("FacebookBanner >> Loading: \(placementId)")
    }

    func view() -> UIView { return container } // ← return container not adView

    func adViewDidLoad(_ adView: FBAdView) {
        print("FacebookBanner >> Loaded ✅")
        DispatchQueue.main.async {
            adView.isHidden = false
            adView.setNeedsLayout()
            adView.layoutIfNeeded()
            self.container.setNeedsLayout()
            self.container.layoutIfNeeded()
        }
    }

    func adView(_ adView: FBAdView, didFailWithError error: Error) {
        let e = error as NSError
        print("FacebookBanner >> Failed ❌ [\(e.code)] \(e.localizedDescription)")
    }

    func adViewDidClick(_ adView: FBAdView) {}
    func adViewDidFinishHandlingClick(_ adView: FBAdView) {}
    func adViewWillLogImpression(_ adView: FBAdView) {}

    func viewControllerForPresentingModalView() -> UIViewController {
        return UIApplication.shared.windows
            .first(where: { $0.isKeyWindow })?.rootViewController ?? UIViewController()
    }
}
// ─────────────────────────────────────────────────────────────────────────────
// Native Ad PlatformView
// ─────────────────────────────────────────────────────────────────────────────

class FacebookNativeAdViewFactory: NSObject, FlutterPlatformViewFactory {
    func create(withFrame frame: CGRect,
                viewIdentifier viewId: Int64,
                arguments args: Any?) -> FlutterPlatformView {
        let params = args as? [String: Any]
        let placementId = params?["placementId"] as? String ?? ""
        let height = params?["height"] as? CGFloat ?? 300
        return FacebookNativeAdView(frame: frame, placementId: placementId, height: height)
    }
    func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
        return FlutterStandardMessageCodec.sharedInstance()
    }
}

class FacebookNativeAdView: NSObject, FlutterPlatformView, FBNativeAdDelegate {
    private let container: UIView
    private let nativeAd: FBNativeAd
    private let height: CGFloat

    init(frame: CGRect, placementId: String, height: CGFloat) {
        self.container = UIView(frame: frame)
        self.container.backgroundColor = .clear
        self.nativeAd = FBNativeAd(placementID: placementId)
        self.height = height
        super.init()
        nativeAd.delegate = self
        nativeAd.loadAd()
        print("FacebookNative >> Loading: \(placementId)")
    }

    func view() -> UIView { return container }

    func nativeAdDidLoad(_ nativeAd: FBNativeAd) {
        print("FacebookNative >> Loaded ✅")
        DispatchQueue.main.async {
            // Remove old subviews
            self.container.subviews.forEach { $0.removeFromSuperview() }

            let adView = FBNativeAdView(nativeAd: nativeAd, with: .genericHeight300)
            adView.frame = CGRect(
                x: 0, y: 0,
                width: self.container.bounds.width,
                height: self.height
            )
            adView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            self.container.addSubview(adView)
            self.container.setNeedsLayout()
            self.container.layoutIfNeeded()
        }
    }

    func nativeAd(_ nativeAd: FBNativeAd, didFailWithError error: Error) {
        let e = error as NSError
        print("FacebookNative >> Failed ❌ [\(e.code)] \(e.localizedDescription)")
    }

    func nativeAdDidClick(_ nativeAd: FBNativeAd) {}
    func nativeAdDidFinishHandlingClick(_ nativeAd: FBNativeAd) {}
    func nativeAdWillLogImpression(_ nativeAd: FBNativeAd) {}
}
// ─────────────────────────────────────────────────────────────────────────────
// Native Banner PlatformView
// ─────────────────────────────────────────────────────────────────────────────

class FacebookNativeBannerViewFactory: NSObject, FlutterPlatformViewFactory {
    func create(withFrame frame: CGRect,
                viewIdentifier viewId: Int64,
                arguments args: Any?) -> FlutterPlatformView {
        let params = args as? [String: Any]
        let placementId = params?["placementId"] as? String ?? ""
        let height = params?["height"] as? CGFloat ?? 100
        return FacebookNativeBannerView(frame: frame, placementId: placementId, height: height)
    }
    func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
        return FlutterStandardMessageCodec.sharedInstance()
    }
}
class FacebookNativeBannerView: NSObject, FlutterPlatformView, FBNativeBannerAdDelegate {
    private let container: UIView
    private let nativeBannerAd: FBNativeBannerAd
    private let height: CGFloat

    init(frame: CGRect, placementId: String, height: CGFloat) {
        self.container = UIView(frame: frame)
        self.container.backgroundColor = .clear
        self.nativeBannerAd = FBNativeBannerAd(placementID: placementId)
        self.height = height
        super.init()
        nativeBannerAd.delegate = self
        nativeBannerAd.loadAd()
        print("FacebookNativeBanner >> Loading: \(placementId)")
    }

    func view() -> UIView { return container }

    func nativeBannerAdDidLoad(_ nativeBannerAd: FBNativeBannerAd) {
        print("FacebookNativeBanner >> Loaded ✅")
        DispatchQueue.main.async {
            self.container.subviews.forEach { $0.removeFromSuperview() }

            let adView = FBNativeBannerAdView(
                nativeBannerAd: nativeBannerAd,
                with: .genericHeight100
            )
            adView.frame = CGRect(
                x: 0, y: 0,
                width: self.container.bounds.width,
                height: self.height
            )
            adView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            self.container.addSubview(adView)
            self.container.setNeedsLayout()
            self.container.layoutIfNeeded()
        }
    }

    func nativeBannerAd(_ nativeBannerAd: FBNativeBannerAd, didFailWithError error: Error) {
        let e = error as NSError
        print("FacebookNativeBanner >> Failed ❌ [\(e.code)] \(e.localizedDescription)")
    }

    func nativeBannerAdDidClick(_ nativeBannerAd: FBNativeBannerAd) {}
    func nativeBannerAdWillLogImpression(_ nativeBannerAd: FBNativeBannerAd) {}
}