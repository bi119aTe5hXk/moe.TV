//
//  AlbireoV2Model.swift
//  moe.TV
//

import Foundation
import MiraStreamingSDK

extension FavoriteStatus {
	var legacyValue: Int {
		switch self {
		case .wish:
			return 1
		case .watched:
			return 2
		case .watching:
			return 3
		case .pause:
			return 4
		case .abandoned:
			return 5
		case .unknownDefaultOpenApi:
			return 0
		}
	}

	init?(legacyValue: Int) {
		switch legacyValue {
		case 1:
			self = .wish
		case 2:
			self = .watched
		case 3:
			self = .watching
		case 4:
			self = .pause
		case 5:
			self = .abandoned
		default:
			return nil
		}
	}
}

struct AlbireoV2OAuthTokenResponse: Decodable {
	let accessToken: String
	let refreshToken: String?
	let idToken: String?
	let expiresIn: Int?
	let tokenType: String?
	let scope: String?

	enum CodingKeys: String, CodingKey {
		case accessToken = "access_token"
		case refreshToken = "refresh_token"
		case idToken = "id_token"
		case expiresIn = "expires_in"
		case tokenType = "token_type"
		case scope
	}
}

extension PaginatedFavorite {
	func toBangumiItemModels() -> [BangumiItemModel] {
		data.map { favorite in
			var model = favorite.bangumi.toBangumiItemModel()
			model.favorite_status = favorite.status.legacyValue
			model.unwatched_count = favorite.unwatchedCount ?? 0
			return model
		}
	}
}

extension PaginatedBangumi {
	func toBangumiItemModels() -> [BangumiItemModel] {
		data.map { $0.toBangumiItemModel() }
	}
}

extension OnAirBangumiResponse {
	func toBangumiItemModels() -> [BangumiItemModel] {
		data.map { $0.toBangumiItemModel() }
	}
}

extension BangumiSummary {
	func toBangumiItemModel() -> BangumiItemModel {
		BangumiItemModel(
			id: id.uuidString,
			bgm_id: bgmId,
			name: name,
			name_cn: nameCn,
			summary: summary,
			image: coverImage.url,
			type: type?.legacyValue ?? 0,
			status: 0,
			air_weekday: airWeekday,
			eps: 0,
			favorite_status: nil,
			unwatched_count: 0
		)
	}
}

extension OnAirBangumi {
	func toBangumiItemModel() -> BangumiItemModel {
		BangumiItemModel(
			id: id.uuidString,
			bgm_id: bgmId,
			name: name,
			name_cn: nameCn,
			summary: "",
			image: coverImage?.url ?? "",
			type: type.rawValue == 2 ? 2 : 6,
			status: 1,
			air_weekday: nil,
			eps: 0,
			favorite_status: nil,
			unwatched_count: 0
		)
	}
}

extension BangumiDetail {
	func toBangumiDetailModel() -> BangumiDetailModel {
		let episodeModels = episodes?.map {
			$0.toBGMEpisode(defaultBangumiID: id)
		} ?? []

		return BangumiDetailModel(
			id: id.uuidString,
			bgm_id: bgmId,
			name: name,
			name_cn: nameCn,
			summary: summary,
			image: coverImage.url,
			type: type?.legacyValue ?? 0,
			status: 0,
			air_weekday: airWeekday,
			eps: episodeModels.count,
			favorite_status: favorite?.status.legacyValue,
			episodes: episodeModels
		)
	}

	func toEPBangumiModel() -> EPbangumiModel {
		EPbangumiModel(
			id: id.uuidString,
			bgm_id: bgmId,
			name: name,
			name_cn: nameCn,
			summary: summary,
			image: coverImage.url,
			type: type?.legacyValue ?? 0,
			status: 0,
			air_weekday: airWeekday,
			eps: episodes?.count ?? 0
		)
	}
}

extension EpisodeSummary {
	func toBGMEpisode(defaultBangumiID: UUID) -> BGMEpisode {
		BGMEpisode(
			id: id.uuidString,
			bangumi_id: defaultBangumiID.uuidString,
			bgm_eps_id: bgmEpsId,
			name: name,
			name_cn: nameCn ?? "",
			thumbnail: thumbnailImage?.url,
			status: status.legacyValue,
			episode_no: episodeNo,
			duration: duration,
			watch_progress: watchProgress?.toWatchProgress(
				bangumiID: defaultBangumiID,
				episodeID: id
			)
		)
	}
}

extension EpisodeDetail {
	func toEpisodeDetailModel() -> EpisodeDetailModel {
		let bangumiID = bangumi.id
		let progress = watchProgress?.toWatchProgress(
			bangumiID: bangumiID,
			episodeID: id
		)

		return EpisodeDetailModel(
			id: id.uuidString,
			bangumi_id: bangumiID.uuidString,
			bgm_eps_id: bgmEpsId,
			name: name,
			name_cn: nameCn ?? "",
			summary: "",
			thumbnail: thumbnailImage?.url,
			status: status.legacyValue,
			episode_no: episodeNo,
			duration: duration,
			bangumi: bangumi.toEPBangumiModel(),
			video_files: videoFiles?.map { $0.toVideoFilesListModel() },
			watch_progress: progress
		)
	}
}

extension VideoFile {
	func toVideoFilesListModel() -> videoFilesListModel {
		videoFilesListModel(
			id: id.uuidString,
			status: 3,
			url: url,
			file_path: nil,
			file_name: fileName,
			episode_id: episode.id.uuidString,
			bangumi_id: bangumi.id.uuidString,
			duration: duration.map { Int($0.rounded()) }
		)
	}
}

extension WatchProgressFields {
	func toWatchProgress(bangumiID: UUID, episodeID: UUID) -> watchProgress {
		watchProgress(
			id: id.uuidString,
			user_id: userId.uuidString,
			last_watch_position: lastWatchPosition,
			bangumi_id: bangumiID.uuidString,
			watch_status: watchStatus.legacyValue,
			episode_id: episodeID.uuidString,
			percentage: percentage.map(Float.init)
		)
	}
}

private extension BangumiSummary.ModelType {
	var legacyValue: Int {
		switch self {
		case .anime:
			return 2
		case .real:
			return 6
		case .game, .music, .book, .unknownDefaultOpenApi:
			return 0
		}
	}
}

private extension BangumiDetail.ModelType {
	var legacyValue: Int {
		switch self {
		case .anime:
			return 2
		case .real:
			return 6
		case .game, .music, .book, .unknownDefaultOpenApi:
			return 0
		}
	}
}

private extension EpisodeStatus {
	var legacyValue: Int {
		switch self {
		case ._0:
			return 0
		case ._1:
			return 1
		case ._2:
			return 2
		case .unknownDefaultOpenApi:
			return 0
		}
	}
}

private extension WatchProgressStatus {
	var legacyValue: Int {
		switch self {
		case ._1:
			return 1
		case ._2:
			return 2
		case ._3:
			return 3
		case ._4:
			return 4
		case ._5:
			return 5
		case .unknownDefaultOpenApi:
			return 0
		}
	}
}
