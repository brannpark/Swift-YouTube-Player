//
//  VideoPlayerView.swift
//  YouTubePlayer
//
//  Created by Giles Van Gruisen on 12/21/14.
//  Copyright (c) 2014 Giles Van Gruisen. All rights reserved.
//

import UIKit
import WebKit

public enum PlayerState: String {
    case unstarted = "-1"
    case ended = "0"
    case playing = "1"
    case paused = "2"
    case buffering = "3"
    case queued = "4"
}

public enum PlaybackQuality: String {
    case small
    case medium
    case large
    case hd720
    case hd1080
    case highres
}

private enum PlayerEvents: String {
    case ready = "onReady"
    case error = "onError"
    case stateChange = "onStateChange"
    case playbackQualityChange = "onPlaybackQualityChange"
}

public protocol YouTubePlayerDelegate: class {
    func playerReady(_ videoPlayer: YouTubePlayerView)
    func playerDidEndError(_ videoPlayer: YouTubePlayerView, error: PlayerError)
    func playerStateChanged(_ videoPlayer: YouTubePlayerView, playerState: PlayerState)
    func playerQualityChanged(_ videoPlayer: YouTubePlayerView, playbackQuality: PlaybackQuality)
}

// Make delegate methods optional by providing default implementations
public extension YouTubePlayerDelegate {
    func playerReady(_ videoPlayer: YouTubePlayerView) {}
    func playerDidEndError(_ videoPlayer: YouTubePlayerView, error: PlayerError) {}
    func playerStateChanged(_ videoPlayer: YouTubePlayerView, playerState: PlayerState) {}
    func playerQualityChanged(_ videoPlayer: YouTubePlayerView, playbackQuality: PlaybackQuality) {}
}

/** Embed and control YouTube videos */
open class YouTubePlayerView: UIView {
    
    lazy private var webView: UIWebView = {
        let webView = UIWebView(frame: bounds)
        webView.allowsInlineMediaPlayback = true
        webView.isOpaque = false
        webView.backgroundColor = .black
        webView.delegate = self
        webView.scrollView.isScrollEnabled = false
        return webView
    }()
    
    /** The current state of the video player */
    private(set) open var playerState = PlayerState.unstarted {
        didSet {
            delegate?.playerStateChanged(self, playerState: playerState)
        }
    }
    
    /** The current playback quality of the video player */
    private(set) open var playbackQuality = PlaybackQuality.small {
        didSet {
            delegate?.playerQualityChanged(self, playbackQuality: playbackQuality)
        }
    }
    
    /** Used to configure the player */
    open var playerParams = PlayerParameters()
    
    /** Used to respond to player events */
    open weak var delegate: YouTubePlayerDelegate?
    
    open var allowChangeURL: Bool = true
    
    // MARK: Various methods for initialization
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
        addWebViewAndAnchorToEdges(webView)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        addWebViewAndAnchorToEdges(webView)
    }
    
    private func addWebViewAndAnchorToEdges(_ webView: UIWebView) {
        addSubview(webView)
        webView.translatesAutoresizingMaskIntoConstraints = false
        
        // Connect/"anchor" all edges
        leadingAnchor.constraint(equalTo: webView.leadingAnchor).isActive = true
        trailingAnchor.constraint(equalTo: webView.trailingAnchor).isActive = true
        topAnchor.constraint(equalTo: webView.topAnchor).isActive = true
        bottomAnchor.constraint(equalTo: webView.bottomAnchor).isActive = true
    }
    
    
    // MARK: Load player
    
    open func loadVideoURL(_ videoURL: URL) {
        if let videoID = videoURL.youtubeID {
            loadVideoID(videoID)
        } else {
            printLog("Incorrect URL passed: \(videoURL)")
        }
    }
    
    open func loadVideoID(_ videoID: String) {
        playerParams.videoId = videoID
        loadWebView(with: playerParams)
    }
    
    open func loadPlaylistID(_ playlistID: String) {
        playerParams.list = playlistID
        loadWebView(with: playerParams)
    }
    
    
    // MARK: Player setup
    
    private func loadWebView(with parameters: PlayerParameters) {
        // Get JSON / HTML strings
        guard
            let encoded = try? JSONEncoder().encode(parameters),
            let jsonParameters = String(data: encoded, encoding: .utf8),
            let path = Bundle(for: YouTubePlayerView.self).path(forResource: "YTPlayer", ofType: "html"),
            let rawHTMLString = try? String(contentsOfFile: path)
            else {
                printLog("Can't load HTML file or encode parameters")
                return
        }
        
        let htmlString = rawHTMLString.replacingOccurrences(of: "%@", with: jsonParameters)
        webView.loadHTMLString(htmlString, baseURL: URL(string: "https://www.youtube.com"))
    }
    
    
    // MARK: JS Event Handling
    
    private func handleJSEvent(_ eventURL: URL) {
        guard let host = eventURL.host, let event = PlayerEvents(rawValue: host) else { return }
        
        switch event {
        case .ready:
            delegate?.playerReady(self)

        case .error:
            if let data = eventURL.queryParams["data"], let error = PlayerError(rawValue: data) {
                delegate?.playerDidEndError(self, error: error)
            } else {
                delegate?.playerDidEndError(self, error: .unexpected)
            }

        case .stateChange:
            if let data = eventURL.queryParams["data"], let newState = PlayerState(rawValue: data) {
                playerState = newState
            }
            
        case .playbackQualityChange:
            if let data = eventURL.queryParams["data"], let newQuality = PlaybackQuality(rawValue: data) {
                playbackQuality = newQuality
            }
        }
    }
}

// MARK: - Controls

extension YouTubePlayerView {
    
    // MARK: Player controls
    
    open func mute() {
        evaluatePlayerCommand(#function)
    }
    
    open func unMute() {
        evaluatePlayerCommand(#function)
    }
    
    open func isMuted(completion: @escaping (Bool) -> Void) {
        evaluatePlayerCommand("isMuted()", completion: { response in
            if response == "true" {
                completion(true)
            } else {
                completion(false)
            }
        })
    }
    
    open func playVideo() {
        evaluatePlayerCommand(#function)
    }
    
    open func pauseVideo() {
        evaluatePlayerCommand(#function)
    }
    
    open func stopVideo() {
        evaluatePlayerCommand(#function)
    }
    
    open func clearVideo() {
        evaluatePlayerCommand(#function)
    }
    
    open func seekTo(_ seconds: Float, seekAhead: Bool) {
        evaluatePlayerCommand("seekTo(\(seconds), \(seekAhead))")
    }
    
    open func getDuration(completion: @escaping ((String?) -> Void)) {
        evaluatePlayerCommand("getDuration()", completion: completion)
    }
    
    open func getCurrentTime(completion: @escaping ((String?) -> Void)) {
        evaluatePlayerCommand("getCurrentTime()", completion: completion)
    }
    
    // MARK: Playlist controls
    
    open func previousVideo() {
        evaluatePlayerCommand(#function)
    }
    
    open func nextVideo() {
        evaluatePlayerCommand(#function)
    }
    
    // MARK: Helper
    
    private func evaluatePlayerCommand(_ command: String, completion: ((String?) -> Void)? = nil) {
        let fullCommand = "player." + command + ";"
        let response = webView.stringByEvaluatingJavaScript(from: fullCommand)
        completion?(response)
    }
}

// MARK: - WebKit Navigation Delegate

extension YouTubePlayerView: UIWebViewDelegate {
    public func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        if let url = request.url,
            let scheme = url.scheme {
            
            if scheme == "ytplayer" {
                handleJSEvent(url)
                return false
            }
            if let host = url.host {
                if !host.contains("youtube.com") { // do not allow other hosts except youtube.com
                    return false
                }
                if url.path == "/" { // allow "/" path for initial html load
                    return true
                }
                // If playsInline options is enabed, then do not allow video url does not have "embed" path
                if playerParams.playsInline, !url.absoluteString.contains("/embed") {
                    if UIApplication.shared.canOpenURL(url) {
                        UIApplication.shared.openURL(url)
                    }
                    return false
                }
            }
        }
        return true
    }
}

// MARK: - Web View Helpers

private extension YouTubePlayerView {
    private var wkConfigs: WKWebViewConfiguration {
        let configs = WKWebViewConfiguration()
        configs.userContentController = self.wkUController
        return configs
    }
    
    /// WKWebView equivalent for UIWebView's scalesPageToFit
    private var wkUController: WKUserContentController {
        // http://stackoverflow.com/questions/26295277/wkwebview-equivalent-for-uiwebviews-scalespagetofit
        var jscript = "var meta = document.createElement('meta');"
        jscript += "meta.name='viewport';"
        jscript += "meta.content='width=device-width';"
        jscript += "document.getElementsByTagName('head')[0].appendChild(meta);"
        
        let userScript = WKUserScript(source: jscript, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        let wkUController = WKUserContentController()
        wkUController.addUserScript(userScript)
        
        return wkUController
    }
}

private func printLog(_ strings: CustomStringConvertible...) {
    let toPrint = ["[YouTubePlayer]"] + strings
    print(toPrint, separator: " ", terminator: "\n")
    assertionFailure()
}
