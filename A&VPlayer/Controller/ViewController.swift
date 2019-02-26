//
//  ViewController.swift
//  A&VPlayer
//
//  Created by can.khac.nguyen on 2/21/19.
//  Copyright © 2019 can.khac.nguyen. All rights reserved.
//

import UIKit
import AVKit

class ViewController: UIViewController {

    @IBOutlet weak var watchVideoButton: UIButton!
    @IBOutlet weak var minimizePlayerView: UIView!

    override func viewDidLoad() {
        super.viewDidLoad()
        minimizePlayerView.isHidden = true
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        watchVideoButton.layer.cornerRadius = watchVideoButton.bounds.height / 2
        watchVideoButton.layer.borderColor = UIColor.white.cgColor
        watchVideoButton.layer.borderWidth = 1
        watchVideoButton.clipsToBounds = true
    }

    private func prapareToVideoView() {
        guard let path = Bundle.main.path(forResource: "kPop", ofType: "mp4") else {
            return
        }
        let videoUrl_1 = URL(fileURLWithPath: path)
        guard let videoUrl_2 = URL(string: "http://mirror.cessen.com/blender.org/peach/trailer/trailer_iphone.m4v") else {
            return
        }
        let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "VideoPlayerController") as! VideoPlayerController
        PlayerManager.shared.playlistUrls = [videoUrl_1, videoUrl_2]
        viewController.delegate = self
        present(viewController, animated: true, completion: nil)
    }

    @IBAction func onWatchVideoButtonClicked(_ sender: UIButton) {
        prapareToVideoView()
    }

    @IBAction func onMinimizePlayerClicked(_ sender: UITapGestureRecognizer) {
        prapareToVideoView()
    }
}

extension ViewController: VideoPlayerControllerDelegate {
    
    func onMinimizePlayer() {
        minimizePlayerView.isHidden = false
        minimizePlayerView.dropShadow()
        guard let avlayer = PlayerManager.shared.avPlayerLayer else { return }
        minimizePlayerView.layer.addSublayer(avlayer)
        avlayer.frame = CGRect(x: 0, y: 0, width: minimizePlayerView.bounds.width,
                               height: minimizePlayerView.bounds.height)

    }

}
