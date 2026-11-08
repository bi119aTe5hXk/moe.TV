//
//  EpisodeUpdateNotificationManager.swift
//  moe.TV
//

#if !os(tvOS)
import Foundation
import UserNotifications

#if os(iOS)
import BackgroundTasks
#elseif os(macOS)
import AppKit
#endif

private struct EpisodeUpdateSnapshot: Codable {
	let id: String
	let name: String
	let unwatchedCount: Int
	let episodesUpdatedAt: Date?
}

private struct EpisodeUpdate {
	let snapshot: EpisodeUpdateSnapshot
	let addedEpisodeCount: Int
}

private final class EpisodeUpdateNotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
	static let shared = EpisodeUpdateNotificationDelegate()

	func userNotificationCenter(
		_ center: UNUserNotificationCenter,
		willPresent notification: UNNotification,
		withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
	) {
		completionHandler([.banner, .sound])
	}
}

final class EpisodeUpdateNotificationManager {
	static let shared = EpisodeUpdateNotificationManager()
	static let backgroundTaskIdentifier = "net.bi119aTe5hXk.moetv.episode-refresh"

	private let enabledKey = "episodeUpdateNotificationsEnabled"
	private let intervalHoursKey = "episodeUpdateNotificationIntervalHours"
	private let snapshotKey = "episodeUpdateNotificationSnapshot"
	private let defaults = UserDefaults.standard
	private let lock = NSLock()
	private var isChecking = false
	private var isSchedulingBackgroundRefresh = false
	private var backgroundTaskRegistered = false
#if os(macOS)
	private var macBackgroundScheduler: NSBackgroundActivityScheduler?
#endif

	private init() {}

	var isEnabled: Bool {
		defaults.bool(forKey: enabledKey)
	}

	var checkIntervalHours: Int {
		let savedValue = defaults.integer(forKey: intervalHoursKey)
		return savedValue == 0 ? 4 : min(24, max(1, savedValue))
	}

	func prepareNotifications() {
		UNUserNotificationCenter.current().delegate = EpisodeUpdateNotificationDelegate.shared
	}

	func setEnabled(_ enabled: Bool, completion: @escaping (Bool) -> Void) {
		guard enabled else {
			defaults.set(false, forKey: enabledKey)
#if os(iOS)
			BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: Self.backgroundTaskIdentifier)
#elseif os(macOS)
			macBackgroundScheduler?.invalidate()
			macBackgroundScheduler = nil
#endif
			DispatchQueue.main.async { completion(true) }
			return
		}

		UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
			guard granted, error == nil else {
				self.defaults.set(false, forKey: self.enabledKey)
				DispatchQueue.main.async { completion(false) }
				return
			}

			self.defaults.set(true, forKey: self.enabledKey)
			self.defaults.removeObject(forKey: self.snapshotKey)
			self.scheduleBackgroundRefresh(replacingExisting: true)
			DispatchQueue.main.async { completion(true) }
		}
	}

	func setCheckIntervalHours(_ hours: Int) {
		defaults.set(min(24, max(1, hours)), forKey: intervalHoursKey)
		if isEnabled {
			scheduleBackgroundRefresh(replacingExisting: true)
		}
	}

	func appDidBecomeActive() {
		guard isEnabled else { return }
		prepareNotifications()
		scheduleBackgroundRefresh()
	}

#if os(iOS)
	func registerBackgroundTask() {
		lock.lock()
		guard !backgroundTaskRegistered else {
			lock.unlock()
			return
		}
		backgroundTaskRegistered = true
		lock.unlock()

		BGTaskScheduler.shared.register(
			forTaskWithIdentifier: Self.backgroundTaskIdentifier,
			using: nil
		) { task in
			guard let refreshTask = task as? BGAppRefreshTask else {
				task.setTaskCompleted(success: false)
				return
			}
			self.handleBackgroundRefresh(refreshTask)
		}
	}

	private func handleBackgroundRefresh(_ task: BGAppRefreshTask) {
		scheduleBackgroundRefresh()
		var expired = false
		task.expirationHandler = {
			expired = true
		}

		checkForUpdates(shouldNotify: true) { success in
			task.setTaskCompleted(success: success && !expired)
		}
	}
#endif

	private func scheduleBackgroundRefresh(replacingExisting: Bool = false) {
#if os(iOS)
		guard isEnabled else { return }
		lock.lock()
		guard !isSchedulingBackgroundRefresh else {
			lock.unlock()
			return
		}
		isSchedulingBackgroundRefresh = true
		lock.unlock()

		if replacingExisting {
			BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: Self.backgroundTaskIdentifier)
		}
		BGTaskScheduler.shared.getPendingTaskRequests { requests in
			defer {
				self.lock.lock()
				self.isSchedulingBackgroundRefresh = false
				self.lock.unlock()
			}
			guard self.isEnabled else { return }
			if !replacingExisting,
			   requests.contains(where: { $0.identifier == Self.backgroundTaskIdentifier }) {
				return
			}

			let request = BGAppRefreshTaskRequest(identifier: Self.backgroundTaskIdentifier)
			request.earliestBeginDate = Date(
				timeIntervalSinceNow: TimeInterval(self.checkIntervalHours * 60 * 60)
			)
			do {
				try BGTaskScheduler.shared.submit(request)
			} catch {
				print("Episode update background refresh scheduling failed: \(error)")
			}
		}
#elseif os(macOS)
		guard isEnabled else { return }
		if !replacingExisting, macBackgroundScheduler != nil { return }
		macBackgroundScheduler?.invalidate()

		let scheduler = NSBackgroundActivityScheduler(identifier: Self.backgroundTaskIdentifier)
		scheduler.interval = TimeInterval(checkIntervalHours * 60 * 60)
		scheduler.tolerance = min(15 * 60, scheduler.interval * 0.1)
		scheduler.repeats = true
		scheduler.qualityOfService = .utility
		scheduler.schedule { completion in
			guard self.isEnabled else {
				completion(.finished)
				return
			}
			guard !NSApp.isActive else {
				completion(.deferred)
				return
			}
			self.checkForUpdates(shouldNotify: true) { success in
				completion(success ? .finished : .deferred)
			}
		}
		macBackgroundScheduler = scheduler
#endif
	}

	private func checkForUpdates(
		shouldNotify: Bool,
		completion: ((Bool) -> Void)? = nil
	) {
		lock.lock()
		guard !isChecking else {
			lock.unlock()
			completion?(false)
			return
		}
		isChecking = true
		lock.unlock()

		fetchWatchingList { result in
			defer {
				self.lock.lock()
				self.isChecking = false
				self.lock.unlock()
			}

			switch result {
			case .success(let items):
				let snapshots = items.map(Self.makeSnapshot)
				let updates = self.detectUpdates(in: snapshots)
				self.saveSnapshots(snapshots)
				if shouldNotify, !updates.isEmpty {
					self.sendNotification(for: updates)
				}
				print("Episode update check finished: watching=\(snapshots.count), updates=\(updates.count)")
				completion?(true)
			case .failure(let error):
				print("Episode update check failed: \(error.localizedDescription)")
				completion?(false)
			}
		}
	}

	private func fetchWatchingList(
		completion: @escaping (Result<[BangumiItemModel], Error>) -> Void
	) {
		let settings = SettingsHandler()
		settings.registerSettings()

		switch settings.getAlbireoAuthMode() {
		case .albireoV2OAuth:
			getAlbireoV2FavoriteList(status: .watching) { success, value in
				Self.finishListRequest(success: success, value: value, completion: completion)
			}
		case .legacyCookie:
			getAlbireoMyBangumiList { success, value in
				Self.finishListRequest(success: success, value: value, completion: completion)
			}
		}
	}

	private static func finishListRequest(
		success: Bool,
		value: Any?,
		completion: @escaping (Result<[BangumiItemModel], Error>) -> Void
	) {
		if success, let items = value as? [BangumiItemModel] {
			completion(.success(items))
			return
		}

		let message = (value as? String) ?? "Invalid favorite list response."
		completion(.failure(NSError(
			domain: "EpisodeUpdateNotificationManager",
			code: 1,
			userInfo: [NSLocalizedDescriptionKey: message]
		)))
	}

	private static func makeSnapshot(from item: BangumiItemModel) -> EpisodeUpdateSnapshot {
		let translatedName = item.name_cn?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
		let originalName = item.name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
		return EpisodeUpdateSnapshot(
			id: item.id,
			name: translatedName.isEmpty ? originalName : translatedName,
			unwatchedCount: max(0, item.unwatched_count ?? 0),
			episodesUpdatedAt: item.eps_update_time
		)
	}

	private func detectUpdates(in currentSnapshots: [EpisodeUpdateSnapshot]) -> [EpisodeUpdate] {
		let previousSnapshots = loadSnapshots()
		guard !previousSnapshots.isEmpty else { return [] }

		let currentIDs = Set(currentSnapshots.map(\.id))
		guard !currentIDs.isDisjoint(with: previousSnapshots.keys) else {
			return []
		}

		return currentSnapshots.compactMap { current in
			guard let previous = previousSnapshots[current.id] else { return nil }
			let addedCount = current.unwatchedCount - previous.unwatchedCount
			let updateTimeAdvanced: Bool
			if let currentDate = current.episodesUpdatedAt,
			   let previousDate = previous.episodesUpdatedAt {
				updateTimeAdvanced = currentDate > previousDate
			} else {
				updateTimeAdvanced = false
			}

			guard addedCount > 0 || (updateTimeAdvanced && current.unwatchedCount > 0) else {
				return nil
			}
			return EpisodeUpdate(snapshot: current, addedEpisodeCount: max(addedCount, 1))
		}
	}

	private func loadSnapshots() -> [String: EpisodeUpdateSnapshot] {
		guard let data = defaults.data(forKey: snapshotKey),
			  let snapshots = try? JSONDecoder().decode([EpisodeUpdateSnapshot].self, from: data) else {
			return [:]
		}
		return Dictionary(uniqueKeysWithValues: snapshots.map { ($0.id, $0) })
	}

	private func saveSnapshots(_ snapshots: [EpisodeUpdateSnapshot]) {
		guard let data = try? JSONEncoder().encode(snapshots) else { return }
		defaults.set(data, forKey: snapshotKey)
	}

	private func sendNotification(for updates: [EpisodeUpdate]) {
		let content = UNMutableNotificationContent()
		content.sound = .default

		if let update = updates.first, updates.count == 1 {
			content.title = NSLocalizedString("New episode available", comment: "Episode update notification title")
			content.body = String(
				format: NSLocalizedString("%@ has %d new episode(s).", comment: "Episode update notification body"),
				locale: Locale.current,
				update.snapshot.name,
				update.addedEpisodeCount
			)
			content.userInfo = ["bangumiID": update.snapshot.id]
		} else {
			content.title = NSLocalizedString("New episodes available", comment: "Episode update notification title")
			content.body = String(
				format: NSLocalizedString("%d followed shows have new episodes.", comment: "Episode update notification body"),
				locale: Locale.current,
				updates.count
			)
		}

		let request = UNNotificationRequest(
			identifier: "episode-update-\(UUID().uuidString)",
			content: content,
			trigger: nil
		)
		UNUserNotificationCenter.current().add(request) { error in
			if let error {
				print("Episode update notification delivery failed: \(error)")
			}
		}
	}
}
#endif
