//
//  PlayerViewController.swift
//  moe.TV
//
//  Created by bi119aTe5hXk on 2023/07/04.
//
import AVFoundation
import AVKit
import Combine
import Foundation
import MediaPlayer

class PlayerViewController: ObservableObject {
	@Published var avPlayer: AVPlayer?
	@Published var streamingCacheManager: StreamingCacheManager?

	@Published var currentTime: Double = 0
	@Published var duration: Double = 0
	@Published var isPlaying = false
	@Published var isSeeking = false
	@Published var playbackRate: Double = 1.0
	@Published var loadedTimeRanges: [ClosedRange<Double>] = []

	private let streamingFactory = StreamingPlayerItemFactory()
	private var timeObserverToken: Any?
	private var stallRecoveryTask: Task<Void, Never>?
	private var shouldResumeAfterStall = false
	private var cancellables = Set<AnyCancellable>()

	let offlinePBM = OfflinePlaybackManager()
	var settingsHandler = SettingsHandler()

	deinit {
		Task { @MainActor [weak self] in
			self?.removeTimeObserver()
		}
	}

	@MainActor
	func loadFromUrl(url: URL, useStreamingCache: Bool = false) {
		print("\(url)")

		resetPlayerState()

		if useStreamingCache {
			do {
				let item = try streamingFactory.makePlayerItem(for: url)
				streamingCacheManager = streamingFactory.cacheManager
				avPlayer = AVPlayer(playerItem: item)
			} catch {
				print("Streaming cache player failed, fallback to AVPlayer(url:): \(error)")
				streamingCacheManager = nil
				avPlayer = AVPlayer(url: url)
			}
		} else {
			streamingCacheManager = nil
			avPlayer = AVPlayer(url: url)
		}

		configureCurrentPlayer()
	}

	@MainActor
	func stop(deleteStreamingCache: Bool = false) {
		avPlayer?.pause()
		removeTimeObserver()
		streamingFactory.stop(deleteCache: deleteStreamingCache)
		streamingCacheManager = nil
		avPlayer = nil
		currentTime = 0
		duration = 0
		isPlaying = false
		isSeeking = false
		playbackRate = settingsHandler.getPlaybackRate()
		loadedTimeRanges = []
		stallRecoveryTask?.cancel()
		stallRecoveryTask = nil
		shouldResumeAfterStall = false
		cancellables.removeAll()
	}

	@MainActor
	func play() {
		applyPlaybackRate()
		isPlaying = true
	}

	@MainActor
	func pause() {
		avPlayer?.pause()
		isPlaying = false
		streamingCacheManager?.prefetchFromLastRequestedOffset()
	}

	@MainActor
	func togglePlayPause() {
		if avPlayer?.timeControlStatus == .playing {
			pause()
		} else {
			play()
		}
	}

	@MainActor
	func setPlaybackRate(_ rate: Double, persist: Bool = true) {
		let safeRate = max(0.25, min(rate, 3.0))
		playbackRate = safeRate
		avPlayer?.defaultRate = Float(safeRate)

		if avPlayer?.timeControlStatus == .playing {
			applyPlaybackRate()
		}

		if persist {
			settingsHandler.setPlaybackRate(rate: safeRate)
		}
	}

	@MainActor
	func seek(to seconds: Double, autoPlay: Bool = false) {
		guard let player = avPlayer else { return }

		let safeDuration = duration > 0 ? duration : CMTimeGetSeconds(player.currentItem?.duration ?? .zero)
		let targetSeconds = max(0, min(seconds, safeDuration.isFinite ? safeDuration : seconds))
		let target = CMTime(seconds: targetSeconds, preferredTimescale: Int32(NSEC_PER_SEC))

		isSeeking = true
		player.seek(to: target, toleranceBefore: .zero, toleranceAfter: .zero) { [weak self] finished in
			Task { @MainActor in
				guard let self else { return }
				self.currentTime = targetSeconds
				self.isSeeking = false

		if autoPlay, finished {
					self.play()
				}

				self.streamingCacheManager?.prefetchFromLastRequestedOffset()
			}
		}
	}

	@MainActor
	func seek(by delta: Double, autoPlay: Bool = false) {
		seek(to: currentTime + delta, autoPlay: autoPlay)
	}

	@MainActor
	func playerObserverHandler(
		status: AVPlayer.TimeControlStatus?,
		bgmItem: BangumiItemModel?,
		filename: String?,
		ep: EpisodeDetailModel?,
		isOffline: Bool,
		isBGMTVWatched: Bool
	) {
		switch status {
		case nil:
			print("nothing is here")
		case .waitingToPlayAtSpecifiedRate:
			print("waiting")
			let shouldRecover = isPlaying || (avPlayer?.rate ?? 0) > 0
			isPlaying = false
			streamingCacheManager?.prefetchFromLastRequestedOffset()
			if shouldRecover {
				scheduleStallRecovery()
			}
		case .paused:
			print("paused")
			shouldResumeAfterStall = false
			isPlaying = false
			if let player = avPlayer {
				logPlaybackPosition(
					player: player,
					bgmItem: bgmItem,
					ep: ep,
					isOffline: isOffline,
					filename: filename,
					isBGMTVWatched: isBGMTVWatched
				)
			}
			streamingCacheManager?.prefetchFromLastRequestedOffset()
		case .playing:
			print("playing")
			shouldResumeAfterStall = true
			stallRecoveryTask?.cancel()
			stallRecoveryTask = nil
			isPlaying = true
		case .some:
			print("unknown player status:\(String(describing: status))")
		@unknown default:
			print("unknown player status:\(String(describing: status))")
		}
	}

	func logPlaybackPosition(
		player: AVPlayer,
		bgmItem: BangumiItemModel?,
		ep: EpisodeDetailModel?,
		isOffline: Bool,
		filename: String?,
		isBGMTVWatched: Bool
	) {
		guard let currentItem = player.currentItem else { return }

		let currentTime = CMTimeGetSeconds(currentItem.currentTime())
		var percent = currentTime / CMTimeGetSeconds(currentItem.duration)
		if percent.isNaN {
			percent = 0
		}
		print("logprogress:\(currentTime),\(percent)")

		let isFinished = percent > 0.95

		if !isOffline {
			if let theEP = ep {
				if isFinished && !isBGMTVWatched {
					if let subject_id = theEP.bangumi?.bgm_id {
						if let episode_id = theEP.bgm_eps_id {
							print("save to BGM.TV as watched")
							setBGMSBEPStatues(
								subject_id: subject_id,
								episode_id: episode_id,
								status: 2
							) { result, data in
								print(data)
							}
						} else {
							print("ep.bgm_eps_id is missing")
						}
					} else {
						print("ep.bangumi.bgm_id is missing")
					}
				}

				if let bangumi_id = theEP.bangumi_id {
					print("save progress to albireo")
					sentAlbireoEPWatchProgress(
						ep_id: theEP.id,
						bangumi_id: bangumi_id,
						last_watch_position: currentTime,
						percentage: percent,
						is_finished: isFinished
					) { result, data in
						print(data as Any)
					}
				} else {
					print("ep.bangumi_id is missing")
				}

				if let item = bgmItem {
					savePlaybackHistory(item)

					if settingsHandler.getSetWatchedWhenFinishedFinalEP() && isFinished {
						if let episode_no = theEP.episode_no {
							if let eps = theEP.bangumi?.eps {
								if episode_no == eps {
									print("should set the subject/collection as watched: episode_no:\(episode_no),eps:\(eps)")
									if item.favorite_status == 3 {
										changeFavStatus(
											idstr: item.id,
											bgmid: item.bgm_id,
											status: 2
										)
									} else {
										print("fav status is not watching. skip set as watched")
									}
								}
							}
						}
					}
				}
			}
		} else {
			if let theFileName = filename {
				print("loging offline, filename is \(theFileName)")
				offlinePBM.setPlayBackStatus(
					item: OfflineVideoItem(
						epID: ep?.id ?? nil,
						bgm_eps_id: ep?.bgm_eps_id ?? nil,
						filename: theFileName,
						position: currentTime,
						isFinished: isFinished
					)
				)
			}
		}
	}

	func setMatadata(ep: EpisodeDetailModel?) -> [AVMetadataItem] {
		var metadata: [AVMetadataItem] = []
		guard let ep else { return metadata }

		if let name = ep.name {
			metadata.append(createMetadataItem(for: .commonIdentifierTitle, value: name))
		}
		if let summary = ep.summary {
			metadata.append(createMetadataItem(for: .commonIdentifierDescription, value: summary))
		}
		if let imageURL = ep.thumbnail {
			let url = URL(string: imageURL)!
			let rdata = try? Data(contentsOf: url)
			metadata.append(
				createMetadataItem(
					for: .commonIdentifierArtwork,
					value: rdata ?? NSNull()
				)
			)
		}
		if let subtitle = ep.name_cn {
			metadata.append(createMetadataItem(for: .iTunesMetadataTrackSubTitle, value: subtitle))
		}

		return metadata
	}

	func createMetadataItem(for identifier: AVMetadataIdentifier, value: Any) -> AVMetadataItem {
		let item = AVMutableMetadataItem()
		item.identifier = identifier
		item.value = value as? NSCopying & NSObjectProtocol
		item.extendedLanguageTag = "und"
		return item.copy() as! AVMetadataItem
	}

	func changeFavStatus(idstr: String?, bgmid: Int?, status: Int) {
		if let idstr1 = idstr {
			print("changing fav status to \(status)")
			changeAlbireoFavStatus(bangumi_id: idstr1, status: status, completion: { isSuccess, result in
				print(result as Any)
				if isSuccess {
					print("albireo fav status change success")
				}
			})
		}

		if let bgm_id = bgmid {
			setBGMCollectionStatus(subject_id: bgm_id, status: status) { isSuccess, result in
				print(result as Any)
				if isSuccess {
					print("setBGMCollectionStatus success")
				} else {
					print("setBGMCollectionStatus retrun false")
				}
			}
		} else {
			print("bgmid not found")
		}
	}

	@MainActor
	private func resetPlayerState() {
		avPlayer?.pause()
		removeTimeObserver()
		streamingFactory.stop(deleteCache: false)
		streamingCacheManager = nil
		currentTime = 0
		duration = 0
		isPlaying = false
		isSeeking = false
		playbackRate = settingsHandler.getPlaybackRate()
		loadedTimeRanges = []
		stallRecoveryTask?.cancel()
		stallRecoveryTask = nil
		shouldResumeAfterStall = false
		cancellables.removeAll()
	}

	@MainActor
	private func configureCurrentPlayer() {
		guard let player = avPlayer else { return }

		player.currentItem?.preferredForwardBufferDuration = TimeInterval(120)
		player.currentItem?.canUseNetworkResourcesForLiveStreamingWhilePaused = true
		player.automaticallyWaitsToMinimizeStalling = true
		playbackRate = settingsHandler.getPlaybackRate()
		player.defaultRate = Float(playbackRate)

		observePlayerItem(player.currentItem)
		addTimeObserver(to: player)

		player.publisher(for: \.timeControlStatus)
			.receive(on: RunLoop.main)
			.sink { [weak self] status in
				self?.isPlaying = status == .playing
			}
			.store(in: &cancellables)
	}

	@MainActor
	private func applyPlaybackRate() {
		guard let player = avPlayer else { return }
		player.defaultRate = Float(playbackRate)
		player.playImmediately(atRate: Float(playbackRate))
	}

	@MainActor
	private func observePlayerItem(_ item: AVPlayerItem?) {
		guard let item else { return }

		item.publisher(for: \.duration)
			.receive(on: RunLoop.main)
			.sink { [weak self] duration in
				let seconds = CMTimeGetSeconds(duration)
				if seconds.isFinite, seconds > 0 {
					self?.duration = seconds
				}
			}
			.store(in: &cancellables)

		item.publisher(for: \.loadedTimeRanges)
			.receive(on: RunLoop.main)
			.sink { [weak self] _ in
				self?.updateLoadedTimeRanges()
			}
			.store(in: &cancellables)

		NotificationCenter.default.publisher(for: .AVPlayerItemPlaybackStalled, object: item)
			.receive(on: RunLoop.main)
			.sink { [weak self] _ in
				self?.handlePlaybackStalled()
			}
			.store(in: &cancellables)
	}

	@MainActor
	private func addTimeObserver(to player: AVPlayer) {
		removeTimeObserver()

		let interval = CMTime(seconds: 0.25, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
		timeObserverToken = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
			guard let self else { return }
			let seconds = CMTimeGetSeconds(time)
			if seconds.isFinite, !self.isSeeking {
				self.currentTime = seconds
			}

			if let itemDuration = player.currentItem?.duration {
				let duration = CMTimeGetSeconds(itemDuration)
				if duration.isFinite, duration > 0 {
					self.duration = duration
				}
			}

			self.updateLoadedTimeRanges()
		}
	}

	@MainActor
	private func updateLoadedTimeRanges() {
		guard let item = avPlayer?.currentItem else {
			loadedTimeRanges = []
			return
		}

		loadedTimeRanges = item.loadedTimeRanges.compactMap { value in
			let range = value.timeRangeValue
			let start = CMTimeGetSeconds(range.start)
			let end = CMTimeGetSeconds(range.start + range.duration)

			guard start.isFinite, end.isFinite, end > start else {
				return nil
			}

			return start...end
		}
	}

	@MainActor
	private func handlePlaybackStalled() {
		print("playback stalled")
		streamingCacheManager?.prefetchFromLastRequestedOffset(length: 16 * 1024 * 1024)
		if shouldResumeAfterStall {
			scheduleStallRecovery()
		}
	}

	@MainActor
	private func scheduleStallRecovery() {
		stallRecoveryTask?.cancel()
		stallRecoveryTask = Task { @MainActor [weak self] in
			try? await Task.sleep(nanoseconds: 900_000_000)
			guard let self, self.shouldResumeAfterStall, let player = self.avPlayer else { return }
			guard player.timeControlStatus != .playing else { return }

			let current = player.currentTime()
			player.seek(to: current, toleranceBefore: .zero, toleranceAfter: .zero) { [weak self] _ in
				Task { @MainActor in
					guard let self, self.shouldResumeAfterStall else { return }
					self.applyPlaybackRate()
				}
			}
		}
	}

	@MainActor
	private func removeTimeObserver() {
		guard let token = timeObserverToken, let player = avPlayer else {
			timeObserverToken = nil
			return
		}

		player.removeTimeObserver(token)
		timeObserverToken = nil
	}
}
