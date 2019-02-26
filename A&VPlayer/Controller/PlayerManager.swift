//
//  PlayerManager.swift
//  A&VPlayer
//
//  Created by can.khac.nguyen on 2/26/19.
//  Copyright © 2019 can.khac.nguyen. All rights reserved.
//

import Foundation
import AVKit

protocol PlayerManagerDelegate: class {
    func onConfigAVPlayerTrigger(layer: AVPlayerLayer?)
    func onTimeObserverTrigger(currentTime: Double, duration: Double)
}

class PlayerManager {

    static let shared = PlayerManager()

    var avPlayer: AVPlayer?
    var avPlayerLayer: AVPlayerLayer?
    var currentTrack: Track?
    var playlistUrls: [URL]?
    var timeObserver: Any?

    weak var delegate: PlayerManagerDelegate?

    func configAVPlayer(forController controller: UIViewController) {
        guard let urls = playlistUrls else { return }
        currentTrack = Track(url: urls[0], index: 0)
        avPlayer = AVPlayer()
        avPlayerLayer = AVPlayerLayer(player: avPlayer)
        avPlayerLayer?.videoGravity = .resizeAspect
        prepareToPlay(forController: controller)
    }

    func continueAVPlayer(forController controller: UIViewController) {
        prepareToPlay(forController: controller)
    }

    func play() {
        guard let avPlayer = avPlayer, currentTrack?.state != .playedToTheEnd else { return }
        avPlayer.play()
    }

    func pause() {
        guard let avPlayer = avPlayer, currentTrack?.state != .playedToTheEnd else { return }
        avPlayer.pause()
    }

    func playNext(forController controller: UIViewController) {
        pause()
        currentTrack = getNextItem()
        prepareToPlay(forController: controller)
    }

    func playPrevious(forController controller: UIViewController) {
        pause()
        currentTrack = getPreviousItem()
        prepareToPlay(forController: controller)
    }

    func stopObserver(forController controller: UIViewController) {
        if let timeObserver = timeObserver {
            avPlayer?.removeTimeObserver(timeObserver)
            avPlayer?.currentItem?.removeObserver(controller, forKeyPath: #keyPath(AVPlayerItem.status))
            avPlayer?.currentItem?.removeObserver(controller, forKeyPath: Constant.loadTimeRangedKey)
            self.timeObserver = nil
        }
    }

    // MARK: Private function
    private func prepareToPlay(forController controller: UIViewController) {
        stopObserver(forController: controller)
        currentTrack?.playerItem.canUseNetworkResourcesForLiveStreamingWhilePaused = true
        avPlayer?.replaceCurrentItem(with: currentTrack?.playerItem)
        startObserver(forController: controller)
        delegate?.onConfigAVPlayerTrigger(layer: avPlayerLayer)
    }

    private func startObserver(forController controller: UIViewController) {
        let interval = CMTime(seconds: 1.0, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        guard let avPlayer = avPlayer, let durationCMTimeFormat = avPlayer.currentItem?.asset.duration else {
            return
        }
        let duration = CMTimeGetSeconds(durationCMTimeFormat)
        // time observer
        timeObserver = avPlayer.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            self?.delegate?.onTimeObserverTrigger(currentTime: time.seconds, duration: Double(duration))
        }
        // add KVO
        avPlayer.currentItem?.addObserver(controller, forKeyPath: #keyPath(AVPlayerItem.status),
                                          options: .new, context: nil)
        avPlayer.currentItem?.addObserver(controller, forKeyPath: Constant.loadTimeRangedKey,
                                          options: .new, context: nil)
    }

    private func getNextItem() -> Track? {
        guard let urls = playlistUrls, let trackIndex = currentTrack?.index, trackIndex >= 0 else { return nil}
        let nextIndex = trackIndex + 1 >= urls.count ? 0 : trackIndex + 1
        return Track(url: urls[nextIndex], index: nextIndex)
    }

    private func getPreviousItem() -> Track? {
        guard let urls = playlistUrls, let trackIndex = currentTrack?.index, trackIndex >= 0 else { return nil }
        let previousIndex = trackIndex - 1 < 0 ? 0 : trackIndex - 1
        return Track(url: urls[previousIndex], index: previousIndex)
    }


}
