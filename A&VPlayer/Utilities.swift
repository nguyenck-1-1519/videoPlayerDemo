//
//  Utilities.swift
//  A&VPlayer
//
//  Created by can.khac.nguyen on 2/21/19.
//  Copyright © 2019 can.khac.nguyen. All rights reserved.
//

import Foundation
import UIKit

enum DeviceOrientation {
    case portrait
    case landscape
}

class Utilities {
    static func getDeviceOrientation(screenSize: CGSize = UIScreen.main.bounds.size) -> DeviceOrientation {
        return screenSize.width < screenSize.height ? .portrait : .landscape
    }
}
