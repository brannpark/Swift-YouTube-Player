//
//  PlayerVars.swift
//  Pods-YoutubeTest
//
//  Created by Islam Qalandarov on 5/1/18.
//

import Foundation

struct PlayerVars: Encodable {
    var playsInline: Bool {
        get { return playsinline.boolValue }
        set { playsinline = newValue.stringValue }
    }
    
    var showInfo: Bool {
        get { return showinfo.boolValue }
        set { showinfo = newValue.stringValue }
    }
    
    var showControls: String {
        get { return controls }
        set { controls = newValue }
    }
    
    var showRelatedVideosWhenFinished: Bool {
        get { return rel.boolValue }
        set { rel = newValue.stringValue }
    }
    
    var startAt: Int {
        get { return start.intValue }
        set { start = String(newValue) }
    }
    
    var list: String? = nil {
        didSet { listType = "playlist" }
    }
    
    var hideLogo: Bool {
        get { return modestbranding.boolValue }
        set { modestbranding = newValue.stringValue }
    }
    
    // The variables that will be encoded
    private var playsinline = false.stringValue
    private var showinfo = false.stringValue
    private var controls = false.stringValue
    private var rel = false.stringValue
    private var start = String(0)
    private var modestbranding = false.stringValue
    private var listType: String = "playlist"    
        
}

private extension String {
    var boolValue: Bool {
        return self == "1"
    }
    var intValue: Int {
        return Int(self) ?? 0
    }
}

private extension Bool {
    var stringValue: String {
        return self ? "1" : "0"
    }
}

private extension Int {
    var stringValue: String {
        return String(self)
    }
}
