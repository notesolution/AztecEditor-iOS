import UIKit
import Aztec

// IMPORTANT: if you're seeing a warning with this import, keep in mind it's marked as a Swift
// bug.  I wasn't able to get any of the workarounds to work.
//
// Ref: https://bugs.swift.org/browse/SR-3801
import RNTAztecView

@objc
public class Gutenberg: NSObject {
    public lazy var rootView: UIView = {
        return RCTRootView(bridge: bridge, moduleName: "gutenberg", initialProperties: initialProps)
    }()

    public var delegate: GutenbergBridgeDelegate? {
        get {
            return bridgeModule.delegate
        }
        set {
            bridgeModule.delegate = newValue
        }
    }

    public var isLoaded: Bool {
        return !bridge.isLoading
    }

    private let bridgeModule = RNReactNativeGutenbergBridge()
    private unowned let dataSource: GutenbergBridgeDataSource

    private lazy var bridge: RCTBridge = {
        return RCTBridge(delegate: self, launchOptions: [:])
    }()

    private var initialProps: [String: String]? {
        var initialProps = [String: String]()
        
        if let initialContent = dataSource.gutenbergInitialContent() {
            initialProps["initialData"] = initialContent
        }
        
        if let initialTitle = dataSource.gutenbergInitialTitle() {
            initialProps["initialTitle"] = initialTitle
        }
        
        return initialProps
    }

    public init(dataSource: GutenbergBridgeDataSource) {
        self.dataSource = dataSource
    }

    public func invalidate() {
        bridge.invalidate()
    }

    public func requestHTML() {
        bridgeModule.sendEvent(withName: EventName.requestHTML, body: nil)
    }

    public func toggleHTMLMode() {
        bridgeModule.sendEvent(withName: EventName.toggleHTMLMode, body: nil)
    }
    
    public func setTitle(_ title: String) {
        bridgeModule.sendEvent(withName: EventName.setTitle, body: ["title": title])
    }
    
    public func updateHtml(_ html: String) {
        bridgeModule.sendEvent(withName: EventName.updateHtml, body: ["html": html])
    }
    
    public func mediaUploadUpdate(id: Int32, state: MediaUploadState, progress: Float, url: URL?, serverID: Int32?) {
        var data: [String: Any] = ["mediaId": id, "state": state.rawValue, "progress": progress];
        if let url = url {
            data["mediaUrl"] = url.absoluteString
        }
        if let serverID = serverID {
            data["mediaServerId"] = serverID
        }
        bridgeModule.sendEventIfNeeded(name: EventName.mediaUpload, body: data)
    }
}

extension Gutenberg: RCTBridgeDelegate {
    public func sourceURL(for bridge: RCTBridge!) -> URL! {
        return RCTBundleURLProvider.sharedSettings()?.jsBundleURL(forBundleRoot: "index", fallbackResource: "")
    }

    public func extraModules(for bridge: RCTBridge!) -> [RCTBridgeModule]! {
        let aztecManager = RCTAztecViewManager()
        aztecManager.attachmentDelegate = dataSource.aztecAttachmentDelegate()

        return [bridgeModule, aztecManager]
    }
}

extension Gutenberg {
    
    enum EventName {
        static let requestHTML = "requestGetHtml"
        static let setTitle = "setTitle"
        static let toggleHTMLMode = "toggleHTMLMode"
        static let updateHtml = "updateHtml"
        static let mediaUpload = "mediaUpload"
    }
    
    public enum MediaUploadState: Int {
        case uploading = 1
        case succeeded = 2
        case failed = 3
        case reset = 4
    }
    
}