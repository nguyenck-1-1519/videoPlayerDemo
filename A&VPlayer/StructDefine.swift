//
//  StructDefine.swift
//  A&VPlayer
//
//  Created by can.khac.nguyen on 2/26/19.
//  Copyright © 2019 can.khac.nguyen. All rights reserved.
//

import AVKit

struct Track {
    var playerItem: AVPlayerItem
    var index: Int
    var state: TrackState

    init(url: URL, index: Int) {
        let asset = AVURLAsset(url: url)
        let item = AVPlayerItem(asset: asset)
        playerItem = item
        self.index = index
        self.state = .loading
    }
}

struct Constant {
    static let loadTimeRangedKey = "loadedTimeRanges"
}
