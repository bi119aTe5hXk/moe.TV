//
//  URLUtilities.swift
//  moe.TV
//

import Foundation

func normalizedServerURL(_ rawValue: String, fallback: String = "") -> String {
	var value = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
	if value.isEmpty {
		value = fallback
	}
	while value.hasSuffix("/") {
		value.removeLast()
	}
	if !value.isEmpty && !value.contains("://") {
		value = "https://\(value)"
	}
	return value
}

func completeServerPath(baseURL: String, path: String) -> String {
	if let url = URL(string: path), url.scheme != nil {
		return path
	}

	let normalizedBase = normalizedServerURL(baseURL)
	if path.hasPrefix("/") {
		return "\(normalizedBase)\(path)"
	}
	return "\(normalizedBase)/\(path)"
}

func formURLEncodedData(_ parameters: [String: String]) -> Data {
	let body = parameters
		.map { key, value in
			"\(formURLEscape(key))=\(formURLEscape(value))"
		}
		.joined(separator: "&")
	return Data(body.utf8)
}

func formURLEscape(_ string: String) -> String {
	var allowed = CharacterSet.urlQueryAllowed
	allowed.remove(charactersIn: ":#[]@!$&'()*+,;=")
	return string.addingPercentEncoding(withAllowedCharacters: allowed) ?? string
}

extension Data {
	init?(base64URLString: String) {
		var value = base64URLString
			.replacingOccurrences(of: "-", with: "+")
			.replacingOccurrences(of: "_", with: "/")
		let padding = value.count % 4
		if padding > 0 {
			value.append(String(repeating: "=", count: 4 - padding))
		}
		self.init(base64Encoded: value)
	}

	func base64URLEncodedString() -> String {
		base64EncodedString()
			.replacingOccurrences(of: "+", with: "-")
			.replacingOccurrences(of: "/", with: "_")
			.replacingOccurrences(of: "=", with: "")
	}
}
