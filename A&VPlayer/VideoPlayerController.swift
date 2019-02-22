//
//  VideoPlayerController.swift
//  A&VPlayer
//
//  Created by can.khac.nguyen on 2/21/19.
//  Copyright © 2019 can.khac.nguyen. All rights reserved.
//

import UIKit
import AVKit

struct Track {
    var playerItem: AVPlayerItem
    var index: Int

    init(url: URL, index: Int) {
        let asset = AVURLAsset(url: url)
        let item = AVPlayerItem(asset: asset)
        playerItem = item
        self.index = index
    }
}

class VideoPlayerController: UIViewController {
    @IBOutlet weak var minimizeButton: UIButton!
    @IBOutlet weak var previousButton: UIButton!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var timeTrackingSlider: UISlider!
    @IBOutlet weak var playerView: UIView!
    @IBOutlet weak var bottomControlViewConstraint: NSLayoutConstraint!
    @IBOutlet weak var topToolbarConstraint: NSLayoutConstraint!
    
    var urls: [URL]?
    var avPlayer: AVPlayer?
    var avPlayerLayer: AVPlayerLayer?
    var currentTrack: Track?
    var isShowingToolBar = true
    var timeObserver: Any?

    override func viewDidLoad() {
        super.viewDidLoad()
        configPlayer()
        configSeeker()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        guard let avPlayerLayer = avPlayerLayer else {
            return
        }
        let deviceOrientation = Utilities.getDeviceOrientation(screenSize: size)
        avPlayerLayer.videoGravity = deviceOrientation == .portrait ? .resizeAspect : .resizeAspectFill
        avPlayerLayer.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)

        coordinator.animate(alongsideTransition: { [weak self] _ in
            self?.setHiddenToolbar(isHidden: deviceOrientation == .landscape)
        }, completion: nil)
    }

    // MARK: Observer
    override func observeValue(forKeyPath keyPath: String?, of object: Any?,
                               change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == #keyPath(AVPlayerItem.status) {
            var status: AVPlayerItem.Status = .unknown
            if let statusNumber = change?[.newKey] as? NSNumber,
                let newStatus = AVPlayerItem.Status(rawValue: statusNumber.intValue) {
                status = newStatus
            }
            switch status {
            case .readyToPlay:
                play()
            default:
                break
            }
        }
    }

    private func startObserver() {
        let interval = CMTime(seconds: 1.0, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        guard let avPlayer = avPlayer, let durationCMTimeFormat = avPlayer.currentItem?.asset.duration else {
            return
        }
        let duration = CMTimeGetSeconds(durationCMTimeFormat)
        timeObserver = avPlayer.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            self?.timeTrackingSlider.setValue(Float(time.seconds / Double(duration)), animated: true)
//            let loadedTimeRange = avPlayer.currentItem?.loadedTimeRanges
//            let timeRange = loadedTimeRange?[0].timeValue
//            let loadedValue = CMTimeGetSeconds(timeRange ?? CMTime.zero)
        }
        // add KVO
        avPlayer.currentItem?.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.status), options: .new, context: nil)
    }

    private func stopObserver() {
        if let timeObserver = timeObserver {
            avPlayer?.removeTimeObserver(timeObserver)
            avPlayer?.currentItem?.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.status))
            self.timeObserver = nil
        }
    }

    // MARK: Private func
    private func configPlayer() {
        guard let urls = urls else { return }
        currentTrack = Track(url: urls[0], index: 0)
        avPlayer = AVPlayer()
        avPlayerLayer = AVPlayerLayer(player: avPlayer)
        avPlayerLayer?.videoGravity = .resizeAspect
        if let layer = avPlayerLayer {
            playerView.layer.addSublayer(layer)
            layer.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width,
                                 height: UIScreen.main.bounds.height)
        }
        prepareForPlay()
    }

    private func configSeeker() {
        timeTrackingSlider.setThumbImage(#imageLiteral(resourceName: "seekIcon"), for: .normal)
        timeTrackingSlider.setValue(0, animated: false)
        timeTrackingSlider.addTarget(self, action: #selector(handleSliderChangeValue(sender:event:)), for: .allEvents)
        timeTrackingSlider.isHidden = true
    }

    private func setHiddenToolbar(isHidden: Bool) {
        isShowingToolBar = !isHidden
        let toolbarHeight: CGFloat = 30
        let controlViewHeight: CGFloat = 60

        UIView.animate(withDuration: 1) { [weak self] in
            self?.topToolbarConstraint.constant = isHidden ? -toolbarHeight * 2 : 0
            self?.bottomControlViewConstraint.constant = isHidden ? -controlViewHeight : 0
        }
    }

    private func getNextItem() -> Track? {
        guard let urls = urls, let trackIndex = currentTrack?.index, trackIndex >= 0 else { return nil}
        let nextIndex = trackIndex + 1 >= urls.count ? 0 : trackIndex + 1
        return Track(url: urls[nextIndex], index: nextIndex)
    }

    private func getPreviousItem() -> Track? {
        guard let urls = urls, let trackIndex = currentTrack?.index, trackIndex >= 0 else { return nil }
        let previousIndex = trackIndex - 1 < 0 ? 0 : trackIndex - 1
        return Track(url: urls[previousIndex], index: previousIndex)
    }

    // call first at all when open new song
    private func prepareForPlay() {
        stopObserver()
        avPlayer?.replaceCurrentItem(with: currentTrack?.playerItem)
        startObserver()
    }

    private func play() {
        guard let avPlayer = avPlayer else { return }
        avPlayer.play()
        playButton.setImage(#imageLiteral(resourceName: "pauseButton"), for: .normal)
    }

    private func pause() {
        guard let avPlayer = avPlayer else { return }
        avPlayer.pause()
        playButton.setImage(#imageLiteral(resourceName: "playButton"), for: .normal)
    }

    private func playNextItem() {
        currentTrack = getNextItem()
        prepareForPlay()
    }

    private func playPreviousItem() {
        currentTrack = getPreviousItem()
        prepareForPlay()
    }

    @objc private func handleSliderChangeValue(sender: AnyObject, event: UIEvent) {
        guard let handleEvent = event.allTouches?.first else { return }
        switch handleEvent.phase {
        case .began:
            // Do sthg
            print("value begin changed")
        case .ended:
            guard let duration = avPlayer?.currentItem?.asset.duration, let item = avPlayer?.currentItem else { return }
            let valueChanged = Double(timeTrackingSlider.value) * duration.seconds
            let timeIntervalChanged = CMTime(seconds: valueChanged, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
            item.seek(to: timeIntervalChanged, completionHandler: nil)
        default:
            break
        }
    }

    // MARK: Handle ibAction
    @IBAction func onPlayerViewDidTap(_ sender: UITapGestureRecognizer) {
        setHiddenToolbar(isHidden: isShowingToolBar)
    }

    @IBAction func onPlayPauseClicked(_ sender: Any) {
        guard let avPlayer = avPlayer else {
            return
        }
        avPlayer.isPlaying ? pause() : play()
    }

    @IBAction func onNextButtonClicked(_ sender: UIButton) {
        pause()
        playNextItem()
    }

    @IBAction func onPreviousButtonClicked(_ sender: UIButton) {
        pause()
        playPreviousItem()
    }
}
