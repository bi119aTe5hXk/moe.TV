//
//  PlaybackHistoryHandler.swift
//  moe.TV
//
//  Created by bi119aTe5hXk on 2024/11/13.
//

import Foundation

func readPlaybackHistory() -> Array<BangumiItemModel> {
	let save = SettingsHandler()
	return save.getPlaybackHistory()
}

func savePlaybackHistory(_ item: BangumiItemModel) {
	let save = SettingsHandler()
	var history = save.getPlaybackHistory()
	history.removeAll(where: { $0.id == item.id })
	var item1 = item
	item1.unwatched_count = 0
	history.insert(item1, at: 0)
	print("Saved playback history: \(history.count)")
	save.setPlaybackHistory(history: history)
}
