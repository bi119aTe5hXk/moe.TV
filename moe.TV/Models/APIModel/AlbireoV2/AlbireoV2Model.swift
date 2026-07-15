//
//  AlbireoV2Model.swift
//  moe.TV
//

import Foundation

private let albireoV2ModelJSONDecoder = JSONDecoder()

enum AlbireoV2FavoriteStatus: String, CaseIterable {
	case watching = "WATCHING"
	case wish = "WISH"
	case watched = "WATCHED"
	case pause = "PAUSE"
	case abandoned = "ABANDONED"

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

struct AlbireoV2BangumiListResponse: Decodable {
	let data: [AlbireoV2BangumiItem]
}

struct AlbireoV2FavoriteListResponse: Decodable {
	let data: [AlbireoV2FavoriteItem]
}

struct AlbireoV2FavoriteItem: Decodable {
	let bangumi: AlbireoV2BangumiItem?
	let unwatchedCount: Int?
	let status: String?

	func toBangumiItemModel() -> BangumiItemModel? {
		guard var model = bangumi?.toBangumiItemModel() else {
			return nil
		}
		model.unwatched_count = unwatchedCount ?? model.unwatched_count
		if let status, let favoriteStatus = AlbireoV2FavoriteStatus(rawValue: status) {
			model.favorite_status = favoriteStatus.legacyValue
		}
		return model
	}
}

struct AlbireoV2FavoriteInfo: Decodable {
	let status: String?
}

struct AlbireoV2BangumiItem: Decodable {
	let id: String
	let bgmId: Int?
	let name: String?
	let nameCn: String?
	let summary: String?
	let airDate: String?
	let airWeekday: Int?
	let type: Int?
	let status: Int?
	let subType: String?
	let eps: Int?
	let favoriteStatus: String?
	let unwatchedCount: Int?
	let coverImage: AlbireoV2CoverImage?
	let episodes: [AlbireoV2EpisodeItem]?
	let favorite: AlbireoV2FavoriteInfo?
	let itemId: String?

	enum CodingKeys: String, CodingKey {
		case id
		case bgmId
		case name
		case nameCn
		case summary
		case airDate
		case airWeekday
		case type
		case status
		case subType
		case eps
		case favoriteStatus
		case unwatchedCount
		case coverImage
		case episodes
		case bangumiEpisodes
		case itemEpisodes
		case items
		case favorite
		case itemId
	}

	init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		id = try container.decode(String.self, forKey: .id)
		bgmId = decodeAlbireoV2OptionalInt(container, forKey: .bgmId)
		name = try container.decodeIfPresent(String.self, forKey: .name)
		nameCn = try container.decodeIfPresent(String.self, forKey: .nameCn)
		summary = try container.decodeIfPresent(String.self, forKey: .summary)
		airDate = try container.decodeIfPresent(String.self, forKey: .airDate)
		airWeekday = decodeAlbireoV2OptionalInt(container, forKey: .airWeekday)
		type = decodeAlbireoV2BangumiType(container, forKey: .type)
		status = decodeAlbireoV2OptionalInt(container, forKey: .status)
		subType = try container.decodeIfPresent(String.self, forKey: .subType)
		eps = decodeAlbireoV2OptionalInt(container, forKey: .eps)
		unwatchedCount = decodeAlbireoV2OptionalInt(container, forKey: .unwatchedCount)
		coverImage = try container.decodeIfPresent(AlbireoV2CoverImage.self, forKey: .coverImage)
		episodes = decodeAlbireoV2EpisodeItems(container)
		favorite = try container.decodeIfPresent(AlbireoV2FavoriteInfo.self, forKey: .favorite)
		itemId = try container.decodeIfPresent(String.self, forKey: .itemId)
		let explicitFavoriteStatus = try container.decodeIfPresent(String.self, forKey: .favoriteStatus)
		let statusString = try? container.decodeIfPresent(String.self, forKey: .status)
		favoriteStatus = favorite?.status ?? explicitFavoriteStatus ?? statusString
	}

	func toBangumiItemModel() -> BangumiItemModel {
		var model = BangumiItemModel(
			id: id,
			bgm_id: bgmId,
			name: name,
			name_cn: nameCn ?? "",
			summary: summary ?? "",
			image: coverImage?.url ?? "",
			type: type ?? 2,
			status: status ?? 0,
			air_weekday: airWeekday,
			eps: eps ?? 0,
			favorite_status: nil,
			unwatched_count: unwatchedCount ?? 0
		)
		if let favoriteStatus, let status = AlbireoV2FavoriteStatus(rawValue: favoriteStatus) {
			model.favorite_status = status.legacyValue
		}
		return model
	}

	func toEPBangumiModel() -> EPbangumiModel {
		EPbangumiModel(
			id: id,
			bgm_id: bgmId,
			name: name,
			name_cn: nameCn ?? "",
			summary: summary ?? "",
			image: coverImage?.url ?? "",
			type: type ?? 2,
			status: status ?? 0,
			air_weekday: airWeekday,
			eps: eps ?? 0
		)
	}
}

struct AlbireoV2CoverImage: Decodable {
	let id: String?
	let width: Int?
	let height: Int?
	let dominantColor: String?
	let url: String?
}

struct AlbireoV2BangumiDetailResponse: Decodable {
	let data: AlbireoV2BangumiItem?

	init(from decoder: Decoder) throws {
		let container = try? decoder.container(keyedBy: CodingKeys.self)
		if let wrappedData = try container?.decodeIfPresent(AlbireoV2BangumiItem.self, forKey: .data) {
			data = wrappedData
		} else {
			data = try AlbireoV2BangumiItem(from: decoder)
		}
	}

	enum CodingKeys: String, CodingKey {
		case data
	}
}


struct AlbireoV2EpisodeListResponse: Decodable {
	let data: [AlbireoV2EpisodeItem]
}

struct AlbireoV2EpisodeItem: Decodable {
	let id: String
	let bangumiId: String?
	let bgmEpsId: Int?
	let name: String?
	let nameCn: String?
	let thumbnail: String?
	let status: Int?
	let episodeNo: Int?
	let duration: String?
	let videoFiles: [videoFilesListModel]?
	let bangumi: AlbireoV2BangumiItem?
	let thumbnailImage: AlbireoV2CoverImage?
	let progress: watchProgress?

	enum CodingKeys: String, CodingKey {
		case id
		case bangumiId
		case bangumiID
		case bgmEpsId
		case name
		case nameCn
		case thumbnail
		case status
		case episodeNo
		case duration
		case videoFiles
		case video_files
		case bangumi
		case thumbnailImage
		case watchProgress
		case watch_progress
	}

	init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		id = try container.decode(String.self, forKey: .id)
		bangumiId = try container.decodeIfPresent(String.self, forKey: .bangumiId) ?? container.decodeIfPresent(String.self, forKey: .bangumiID)
		bgmEpsId = decodeAlbireoV2OptionalInt(container, forKey: .bgmEpsId)
		name = try container.decodeIfPresent(String.self, forKey: .name)
		nameCn = try container.decodeIfPresent(String.self, forKey: .nameCn)
		thumbnail = try container.decodeIfPresent(String.self, forKey: .thumbnail)
		status = decodeAlbireoV2OptionalInt(container, forKey: .status)
		episodeNo = decodeAlbireoV2OptionalInt(container, forKey: .episodeNo)
		if let stringDuration = try? container.decodeIfPresent(String.self, forKey: .duration) {
			duration = stringDuration
		} else if let intDuration = try? container.decodeIfPresent(Int.self, forKey: .duration) {
			duration = String(intDuration)
		} else {
			duration = nil
		}
		videoFiles = try container.decodeIfPresent([videoFilesListModel].self, forKey: .videoFiles) ?? container.decodeIfPresent([videoFilesListModel].self, forKey: .video_files)
		bangumi = try container.decodeIfPresent(AlbireoV2BangumiItem.self, forKey: .bangumi)
		thumbnailImage = try container.decodeIfPresent(AlbireoV2CoverImage.self, forKey: .thumbnailImage)
		if let v2Progress = try container.decodeIfPresent(AlbireoV2WatchProgress.self, forKey: .watchProgress) {
			progress = v2Progress.toWatchProgress(defaultBangumiId: bangumiId, defaultEpisodeId: id)
		} else {
			progress = try container.decodeIfPresent(watchProgress.self, forKey: .watch_progress)
		}
	}

	func toBGMEpisode(defaultBangumiId: String) -> BGMEpisode {
		BGMEpisode(
			id: id,
			bangumi_id: bangumiId ?? bangumi?.id ?? defaultBangumiId,
			bgm_eps_id: bgmEpsId,
			name: name,
			name_cn: nameCn ?? "",
			thumbnail: thumbnail ?? thumbnailImage?.url,
			status: status ?? 0,
			episode_no: episodeNo,
			duration: duration,
			watch_progress: progress
		)
	}

	func toEpisodeDetailModel(defaultBangumiId: String) -> EpisodeDetailModel {
		let bgmEpisode = toBGMEpisode(defaultBangumiId: defaultBangumiId)
		return EpisodeDetailModel(
			id: bgmEpisode.id,
			bangumi_id: bgmEpisode.bangumi_id,
			bgm_eps_id: bgmEpisode.bgm_eps_id,
			name: bgmEpisode.name,
			name_cn: bgmEpisode.name_cn,
			summary: "",
			thumbnail: bgmEpisode.thumbnail,
			status: bgmEpisode.status,
			episode_no: bgmEpisode.episode_no,
			duration: bgmEpisode.duration,
			bangumi: bangumi?.toEPBangumiModel(),
			video_files: videoFiles,
			watch_progress: progress
		)
	}
}

struct AlbireoV2Reference: Decodable {
	let id: String?
}

struct AlbireoV2WatchProgress: Decodable {
	let id: String
	let userId: String?
	let watchStatus: Int?
	let lastWatchPosition: Double?
	let percentage: Float?
	let bangumi: AlbireoV2Reference?
	let episode: AlbireoV2Reference?

	enum CodingKeys: String, CodingKey {
		case id
		case userId
		case watchStatus
		case lastWatchPosition
		case percentage
		case bangumi
		case episode
	}

	init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		id = try container.decode(String.self, forKey: .id)
		userId = try container.decodeIfPresent(String.self, forKey: .userId)
		watchStatus = decodeAlbireoV2OptionalInt(container, forKey: .watchStatus)
		lastWatchPosition = decodeAlbireoV2OptionalDouble(container, forKey: .lastWatchPosition)
		percentage = decodeAlbireoV2OptionalFloat(container, forKey: .percentage)
		bangumi = try container.decodeIfPresent(AlbireoV2Reference.self, forKey: .bangumi)
		episode = try container.decodeIfPresent(AlbireoV2Reference.self, forKey: .episode)
	}

	func toWatchProgress(defaultBangumiId: String?, defaultEpisodeId: String?) -> watchProgress {
		watchProgress(
			id: id,
			user_id: userId,
			last_watch_position: lastWatchPosition,
			bangumi_id: bangumi?.id ?? defaultBangumiId,
			watch_status: watchStatus,
			episode_id: episode?.id ?? defaultEpisodeId,
			percentage: percentage
		)
	}
}

private func decodeAlbireoV2EpisodeItems(_ container: KeyedDecodingContainer<AlbireoV2BangumiItem.CodingKeys>) -> [AlbireoV2EpisodeItem]? {
	for key in [AlbireoV2BangumiItem.CodingKeys.episodes, .bangumiEpisodes, .itemEpisodes, .items] {
		if let episodes = try? container.decodeIfPresent([AlbireoV2EpisodeItem].self, forKey: key) {
			return episodes
		}
	}
	return nil
}

private func decodeAlbireoV2OptionalDouble<Key: CodingKey>(_ container: KeyedDecodingContainer<Key>, forKey key: Key) -> Double? {
	if let value = try? container.decodeIfPresent(Double.self, forKey: key) {
		return value
	}
	if let value = try? container.decodeIfPresent(Int.self, forKey: key) {
		return Double(value)
	}
	if let value = try? container.decodeIfPresent(String.self, forKey: key) {
		return Double(value)
	}
	return nil
}

private func decodeAlbireoV2OptionalFloat<Key: CodingKey>(_ container: KeyedDecodingContainer<Key>, forKey key: Key) -> Float? {
	if let value = try? container.decodeIfPresent(Float.self, forKey: key) {
		return value
	}
	if let value = try? container.decodeIfPresent(Double.self, forKey: key) {
		return Float(value)
	}
	if let value = try? container.decodeIfPresent(Int.self, forKey: key) {
		return Float(value)
	}
	if let value = try? container.decodeIfPresent(String.self, forKey: key) {
		return Float(value)
	}
	return nil
}

private func decodeAlbireoV2OptionalInt<Key: CodingKey>(_ container: KeyedDecodingContainer<Key>, forKey key: Key) -> Int? {
	if let value = try? container.decodeIfPresent(Int.self, forKey: key) {
		return value
	}
	if let value = try? container.decodeIfPresent(String.self, forKey: key) {
		return Int(value)
	}
	return nil
}

private func decodeAlbireoV2BangumiType<Key: CodingKey>(_ container: KeyedDecodingContainer<Key>, forKey key: Key) -> Int? {
	if let value = try? container.decodeIfPresent(Int.self, forKey: key) {
		return value
	}
	guard let value = try? container.decodeIfPresent(String.self, forKey: key) else {
		return nil
	}
	switch value.lowercased() {
	case "anime":
		return 2
	default:
		return 0
	}
}

func decodeAlbireoV2BangumiItems(from data: Data) throws -> [BangumiItemModel] {
	if let response = try? albireoV2ModelJSONDecoder.decode(AlbireoV2FavoriteListResponse.self, from: data) {
		let list = response.data.compactMap { $0.toBangumiItemModel() }
		if list.isEmpty == false {
			return list
		}
	}

	if let response = try? albireoV2ModelJSONDecoder.decode(AlbireoV2BangumiListResponse.self, from: data) {
		return response.data.map { $0.toBangumiItemModel() }
	}

	throw DecodingError.dataCorrupted(
		DecodingError.Context(
			codingPath: [],
			debugDescription: "Unsupported Albireo V2 bangumi list response."
		)
	)
}

func decodeAlbireoV2BangumiDetail(from data: Data) throws -> BangumiDetailModel {
	let response = try albireoV2ModelJSONDecoder.decode(AlbireoV2BangumiDetailResponse.self, from: data)
	guard let item = response.data else {
		throw DecodingError.dataCorrupted(
			DecodingError.Context(codingPath: [], debugDescription: "Albireo V2 bangumi detail response data is empty.")
		)
	}
	let listItem = item.toBangumiItemModel()
	let episodes = item.episodes?.map { episode in
		episode.toBGMEpisode(defaultBangumiId: item.id)
	} ?? []
	return BangumiDetailModel(
		id: listItem.id,
		bgm_id: listItem.bgm_id,
		name: listItem.name,
		name_cn: listItem.name_cn,
		summary: listItem.summary,
		image: listItem.image,
		type: listItem.type,
		status: listItem.status,
		air_weekday: listItem.air_weekday,
		eps: listItem.eps,
		favorite_status: listItem.favorite_status,
		episodes: episodes
	)
}

func decodeAlbireoV2Episodes(from data: Data, defaultBangumiId: String) throws -> [BGMEpisode] {
	if let response = try? albireoV2ModelJSONDecoder.decode(AlbireoV2EpisodeListResponse.self, from: data) {
		return response.data.map { $0.toBGMEpisode(defaultBangumiId: defaultBangumiId) }
	}

	if let response = try? albireoV2ModelJSONDecoder.decode([AlbireoV2EpisodeItem].self, from: data) {
		return response.map { $0.toBGMEpisode(defaultBangumiId: defaultBangumiId) }
	}

	throw DecodingError.dataCorrupted(
		DecodingError.Context(
			codingPath: [],
			debugDescription: "Unsupported Albireo V2 episode list response."
		)
	)
}

func decodeAlbireoV2EpisodeDetail(from data: Data, defaultBangumiId: String) throws -> EpisodeDetailModel {
	if let response = try? albireoV2ModelJSONDecoder.decode(AlbireoV2EpisodeItem.self, from: data) {
		return response.toEpisodeDetailModel(defaultBangumiId: defaultBangumiId)
	}

	throw DecodingError.dataCorrupted(
		DecodingError.Context(
			codingPath: [],
			debugDescription: "Unsupported Albireo V2 episode detail response."
		)
	)
}

func albireoV2TopLevelKeys(from data: Data) -> [String] {
	guard let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
		return []
	}
	return object.keys.sorted()
}
