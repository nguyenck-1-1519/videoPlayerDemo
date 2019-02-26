//
//  AVPlayer+Ext.swift
//  A&VPlayer
//
//  Created by can.khac.nguyen on 2/21/19.
//  Copyright © 2019 can.khac.nguyen. All rights reserved.
//

import AVKit

extension AVPlayer {
    var isPlaying: Bool {
        return self.rate != 0 && self.error == nil
    }
}
