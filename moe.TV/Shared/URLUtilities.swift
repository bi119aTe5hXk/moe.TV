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

func normalizedHTTPServerURL(_ rawValue: String, fallback: String = "") -> String {
	normalizedServerURL(rawValue, fallback: fallback)
}

func validatedHTTPServerURL(_ rawValue: String, fallback: String = "") -> String? {
	let normalizedURL = normalizedHTTPServerURL(rawValue, fallback: fallback)
	guard !normalizedURL.isEmpty,
		  let components = URLComponents(string: normalizedURL),
		  let scheme = components.scheme?.lowercased(),
		  scheme == "http" || scheme == "https",
		  let host = components.host,
		  isValidServerHost(host),
		  components.user == nil,
		  components.password == nil,
		  components.query == nil,
		  components.fragment == nil else {
		return nil
	}
	return normalizedURL
}

func isValidHTTPServerURL(_ rawValue: String, fallback: String = "") -> Bool {
	validatedHTTPServerURL(rawValue, fallback: fallback) != nil
}

private func isValidServerHost(_ host: String) -> Bool {
	let value = host.trimmingCharacters(in: .whitespacesAndNewlines)
	guard value == host,
		  !value.isEmpty,
		  value.rangeOfCharacter(from: .whitespacesAndNewlines) == nil else {
		return false
	}

	if value == "localhost" {
		return true
	}
	if isValidIPv4Host(value) || isLikelyIPv6Host(value) {
		return true
	}

	let labels = value.split(separator: ".", omittingEmptySubsequences: false)
	guard labels.count >= 2 else {
		return false
	}
	return labels.allSatisfy(isValidDomainLabel)
}

private func isValidDomainLabel(_ label: Substring) -> Bool {
	guard !label.isEmpty,
		  label.count <= 63,
		  isLetterOrNumber(label.first),
		  isLetterOrNumber(label.last) else {
		return false
	}
	return label.allSatisfy { $0.isLetter || $0.isNumber || $0 == "-" }
}

private func isLetterOrNumber(_ character: Character?) -> Bool {
	guard let character else {
		return false
	}
	return character.isLetter || character.isNumber
}

private func isValidIPv4Host(_ host: String) -> Bool {
	let parts = host.split(separator: ".", omittingEmptySubsequences: false)
	guard parts.count == 4 else {
		return false
	}
	return parts.allSatisfy { part in
		guard let value = Int(part), value >= 0, value <= 255 else {
			return false
		}
		return String(value) == part || part == "0"
	}
}

private func isLikelyIPv6Host(_ host: String) -> Bool {
	host.contains(":") && host.allSatisfy { $0.isHexDigit || $0 == ":" }
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
