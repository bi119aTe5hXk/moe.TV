//
//  EpisodeFeedbackView.swift
//  moe.TV
//

import SwiftUI

private enum EpisodeFeedbackIssue: String, CaseIterable, Identifiable {
	case cannotPlay = "Video cannot be played"
	case incorrectContent = "Incorrect video content"
	case playbackProblem = "Audio or video problem"
	case other = "Other"

	var id: String { rawValue }
	var title: LocalizedStringKey { LocalizedStringKey(rawValue) }
}

struct EpisodeFeedbackView: View {
	let episode: EpisodeDetailModel
	let preferredVideoURL: URL?

	@Environment(\.dismiss) private var dismiss
	@State private var selectedIssue = EpisodeFeedbackIssue.cannotPlay
	@State private var selectedVideoID: String
	@State private var details = ""
	@State private var isSubmitting = false
	@State private var showsResult = false
	@State private var submissionSucceeded = false
	@State private var resultMessage = ""

	init(episode: EpisodeDetailModel, preferredVideoURL: URL? = nil) {
		self.episode = episode
		self.preferredVideoURL = preferredVideoURL

		let videos = episode.video_files ?? []
		let preferredID = videos.first(where: {
			Self.matches(videoURL: $0.url, preferredURL: preferredVideoURL)
		})?.id
		_selectedVideoID = State(initialValue: preferredID ?? videos.first?.id ?? "")
	}

	var body: some View {
		NavigationStack {
			Form {
				Section("Issue type") {
					Picker("Issue type", selection: $selectedIssue) {
						ForEach(EpisodeFeedbackIssue.allCases) { issue in
							Text(issue.title).tag(issue)
						}
					}
					.labelsHidden()
				}

				if videoFiles.count > 1 {
					Section("Video source") {
						Picker("Video source", selection: $selectedVideoID) {
							ForEach(Array(videoFiles.enumerated()), id: \.element.id) { index, video in
								Text(videoLabel(video, index: index)).tag(video.id)
							}
						}
						.labelsHidden()
					}
				}

				Section("Details (optional)") {
					#if os(tvOS)
					TextField("Describe what happened", text: $details)
					#else
					TextEditor(text: $details)
						.frame(minHeight: 120)
						.accessibilityLabel("Describe what happened")
					#endif
				}
			}
			.navigationTitle("Video feedback")
			.toolbar {
				ToolbarItem(placement: .cancellationAction) {
					Button("Cancel") { dismiss() }
						.disabled(isSubmitting)
				}
				ToolbarItem(placement: .confirmationAction) {
					Button("Submit") { submit() }
						.disabled(selectedVideoID.isEmpty || isSubmitting)
				}
			}
			.overlay {
				if isSubmitting {
					ProgressView()
						.padding(20)
						.background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
				}
			}
			.alert(
				submissionSucceeded ? "Feedback sent" : "Unable to send feedback",
				isPresented: $showsResult
			) {
				Button("OK") {
					if submissionSucceeded { dismiss() }
				}
			} message: {
				Text(resultMessage)
			}
		}
	}

	private var videoFiles: [videoFilesListModel] {
		episode.video_files ?? []
	}

	private func submit() {
		guard !selectedVideoID.isEmpty else {
			showResult(success: false, message: String(localized: "No video source is available for feedback."))
			return
		}

		isSubmitting = true
		let trimmedDetails = details.trimmingCharacters(in: .whitespacesAndNewlines)
		let issue = trimmedDetails.isEmpty
			? String(localized: String.LocalizationValue(selectedIssue.rawValue))
			: "\(String(localized: String.LocalizationValue(selectedIssue.rawValue))): \(trimmedDetails)"

		submitAlbireoV2EpisodeFeedback(
			episodeID: episode.id,
			videoID: selectedVideoID,
			issue: issue
		) { success, result in
			DispatchQueue.main.async {
				isSubmitting = false
				let message = success
					? String(localized: "Thank you for your feedback.")
					: (result as? String ?? String(localized: "Unable to send feedback"))
				showResult(success: success, message: message)
			}
		}
	}

	private func showResult(success: Bool, message: String) {
		submissionSucceeded = success
		resultMessage = message
		showsResult = true
	}

	private func videoLabel(_ video: videoFilesListModel, index: Int) -> String {
		if let name = video.file_name?.trimmingCharacters(in: .whitespacesAndNewlines), !name.isEmpty {
			return name
		}
		if let path = video.url.flatMap(URL.init(string:))?.lastPathComponent, !path.isEmpty {
			return path
		}
		return "\(String(localized: "Video source")) \(index + 1)"
	}

	private static func matches(videoURL: String?, preferredURL: URL?) -> Bool {
		guard let videoURL, let preferredURL else { return false }
		if videoURL == preferredURL.absoluteString { return true }
		guard let candidateURL = URL(string: videoURL) else { return false }
		return !candidateURL.lastPathComponent.isEmpty
			&& candidateURL.lastPathComponent == preferredURL.lastPathComponent
	}
}
