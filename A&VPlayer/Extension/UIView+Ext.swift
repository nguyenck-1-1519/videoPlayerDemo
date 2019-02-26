//
//  UIView+Ext.swift
//  A&VPlayer
//
//  Created by can.khac.nguyen on 2/26/19.
//  Copyright © 2019 can.khac.nguyen. All rights reserved.
//

import UIKit

extension UIView {

    func dropShadow() {
        layer.masksToBounds = false
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.8
        layer.shadowOffset = CGSize(width: 3, height: -3)
        layer.shadowRadius = 5
    }

}
