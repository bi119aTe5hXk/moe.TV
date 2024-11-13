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
	history.insert(item, at: 0)
	//print("Saved playback history: \(history)")
	save.setPlaybackHistory(history: history)
}
