//
//  VideoPlayerController.swift
//  A&VPlayer
//
//  Created by can.khac.nguyen on 2/21/19.
//  Copyright © 2019 can.khac.nguyen. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation

protocol VideoPlayerControllerDelegate: class {
    func onMinimizePlayer()
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
    @IBOutlet weak var bottomView: UIView!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var speedSegment: UISegmentedControl!

    weak var delegate: VideoPlayerControllerDelegate?
    var urls: [URL]?
    var avPlayer: AVPlayer?
    var avPlayerLayer: AVPlayerLayer?
    var currentTrack: Track?
    var isShowingToolBar = true
    var timeObserver: Any?
    var progressView = UIProgressView()

    override var prefersStatusBarHidden: Bool {
        return true
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configControlView()
        configSpeedSegment()
        PlayerManager.shared.delegate = self
        let isPlaying = PlayerManager.shared.avPlayer != nil
        isPlaying ? PlayerManager.shared.continueAVPlayer(forController: self) :
            PlayerManager.shared.configAVPlayer(forController: self)
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

    deinit {
        PlayerManager.shared.stopObserver(forController: self)
    }

    // MARK: KVO Observer
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
                // time to play
                currentTrack?.state = .readyToPlay
                playButton.setImage(#imageLiteral(resourceName: "pauseButton"), for: .normal)
                PlayerManager.shared.play()
            default:
                break
            }
        } else if keyPath == Constant.loadTimeRangedKey {
            // update buffer display
            onLoadedTimeRangedChanged()
        }
    }

    // MARK: Private func
    private func setTimeLabel(withDuration duration: Double, currentTime: Double) {
        timeLabel.text = Utilities.formatDurationTime(time: Int(currentTime)) + "/" +
            Utilities.formatDurationTime(time: Int(duration))
    }

    private func onLoadedTimeRangedChanged() {
        let duration = avPlayer?.currentItem?.asset.duration
        let durationSeconds = CMTimeGetSeconds(duration ?? .zero)
        let newValue = avPlayer?.currentItem?.loadedTimeRanges
        guard let timeRange = newValue?.first?.timeRangeValue else {
            return
        }
        let loadedValue = CMTimeGetSeconds(timeRange.duration)
        progressView.setProgress(Float(CGFloat(loadedValue) / CGFloat(durationSeconds)), animated: true)
    }

    private func configSeeker() {
        // time slider
        timeTrackingSlider.setThumbImage(#imageLiteral(resourceName: "seekIcon"), for: .normal)
        timeTrackingSlider.setValue(0, animated: false)
        timeTrackingSlider.addTarget(self, action: #selector(handleSliderChangeValue(sender:event:)), for: .allEvents)
        // progress View
        progressView.tintColor = .white
        progressView.trackTintColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.3)
        bottomView.insertSubview(progressView, belowSubview: timeTrackingSlider)
        progressView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
                progressView.leftAnchor.constraint(equalTo: timeTrackingSlider.leftAnchor),
                progressView.rightAnchor.constraint(equalTo: timeTrackingSlider.rightAnchor),
                progressView.centerYAnchor.constraint(equalTo: timeTrackingSlider.centerYAnchor, constant: 1),
                progressView.heightAnchor.constraint(equalToConstant: 1)
            ])
        onLoadedTimeRangedChanged()
        // time label
        setTimeLabel(withDuration: CMTimeGetSeconds(avPlayer?.currentItem?.asset.duration ?? .zero), currentTime: 0)
    }

    private func configControlView() {
        let downArrowImage = #imageLiteral(resourceName: "minimizeButton").withRenderingMode(.alwaysTemplate)
        let previousImage = #imageLiteral(resourceName: "previousButton").withRenderingMode(.alwaysTemplate)
        let nextImage = #imageLiteral(resourceName: "nextButton").withRenderingMode(.alwaysTemplate)
        nextButton.setImage(nextImage, for: .normal)
        previousButton.setImage(previousImage, for: .normal)
        minimizeButton.setImage(downArrowImage, for: .normal)
        if let avPlayer = PlayerManager.shared.avPlayer {
            avPlayer.isPlaying ? playButton.setImage(#imageLiteral(resourceName: "pauseButton"), for: .normal) :
                playButton.setImage(#imageLiteral(resourceName: "playButton"), for: .normal)
        }
        nextButton.tintColor = .white
        previousButton.tintColor = .white
        minimizeButton.tintColor = .white
    }

    private func configSpeedSegment() {
        speedSegment.selectedSegmentIndex = 1
    }

    private func resetSeeker() {
        setTimeLabel(withDuration: CMTimeGetSeconds(avPlayer?.currentItem?.asset.duration ?? .zero), currentTime: 0)
        timeTrackingSlider.setValue(0, animated: false)
        progressView.setProgress(0, animated: false)
    }

    private func setHiddenToolbar(isHidden: Bool) {
        isShowingToolBar = !isHidden
        let toolbarHeight: CGFloat = 30
        let controlViewHeight: CGFloat = 60

        UIView.animate(withDuration: 0.5) { [weak self] in
            self?.topToolbarConstraint.constant = isHidden ? -toolbarHeight * 2 : 0
            self?.bottomControlViewConstraint.constant = isHidden ? -controlViewHeight : 0
            self?.view.layoutIfNeeded()
        }
    }

    private func setHiddenControlButton() {
        guard let count = urls?.count else { return }
        if currentTrack?.index == 0 {
            nextButton.isEnabled = count == 0 ? false : true 
            previousButton.isEnabled = false
        } else if currentTrack?.index == count - 1 {
            nextButton.isEnabled = false
            previousButton.isEnabled = true
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

    @objc private func handleSliderChangeValue(sender: AnyObject, event: UIEvent) {
        guard let handleEvent = event.allTouches?.first else { return }
        switch handleEvent.phase {
        case .began:
            currentTrack?.state = .seeking
        case .ended:
            currentTrack?.state = .readyToPlay
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
        if avPlayer.isPlaying {
            PlayerManager.shared.pause()
            playButton.setImage(#imageLiteral(resourceName: "playButton"), for: .normal)
        } else {
            PlayerManager.shared.play()
            playButton.setImage(#imageLiteral(resourceName: "pauseButton"), for: .normal)
        }
    }

    @IBAction func onNextButtonClicked(_ sender: UIButton) {
        configSpeedSegment()
        resetSeeker()
        PlayerManager.shared.playNext(forController: self)
    }

    @IBAction func onPreviousButtonClicked(_ sender: UIButton) {
        configSpeedSegment()
        resetSeeker()
        PlayerManager.shared.playPrevious(forController: self)
    }

    @IBAction func onMinimizeButtonClicked(_ sender: UIButton) {
        delegate?.onMinimizePlayer()
        dismiss(animated: true, completion: nil)
    }

    @IBAction func onSpeedSegmentClicked(_ sender: Any) {
        PlayerManager.shared.playbackRate = speedSegment.selectedSegmentIndex == 0 ? Float(0.5) :
            Float(speedSegment.selectedSegmentIndex)
    }
}

extension VideoPlayerController: PlayerManagerDelegate {

    func onConfigAVPlayerTrigger(layer: AVPlayerLayer?) {
        guard let layer = layer else { return }
        self.avPlayerLayer = layer
        urls = PlayerManager.shared.playlistUrls
        playerView.layer.addSublayer(layer)
        layer.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width,
                                      height: UIScreen.main.bounds.height)
        avPlayer = PlayerManager.shared.avPlayer
        currentTrack = PlayerManager.shared.currentTrack
        setHiddenControlButton()
    }

    func onTimeObserverTrigger(currentTime: Double, duration: Double) {
        guard let currentTrack = self.currentTrack else { return }
        if currentTrack.state != .seeking {
            self.timeTrackingSlider.setValue(Float(currentTime / Double(duration)), animated: true)
        }
        if Float(currentTime / Double(duration)) >= 1 {
            self.currentTrack?.state = .playedToTheEnd
            self.playButton.setImage(#imageLiteral(resourceName: "playButton"), for: .normal)
        }
        self.setTimeLabel(withDuration: duration, currentTime: currentTime)
    }

}
