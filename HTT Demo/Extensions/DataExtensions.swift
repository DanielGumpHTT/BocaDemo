//
//  Data.swift
//  HTT Demo
//
//  Created by Daniel Gump on 11/30/20.
//  Copyright © 2020 HomeTown Ticketing. All rights reserved.
//

import Foundation

public extension Data {

	enum HexEncodingOptions: Int {
		case lowerCase = 0, upperCase
	}

	func hexEncodedString(options: HexEncodingOptions) -> String {
		let hexDigits = Array((options == .upperCase ? "0123456789ABCDEF" : "0123456789abcdef").utf16)
		var chars: [unichar] = []
		chars.reserveCapacity(2 * count)
		for byte in self {
			chars.append(hexDigits[Int(byte / 16)])
			chars.append(hexDigits[Int(byte % 16)])
		}
		return String(utf16CodeUnits: chars, count: chars.count)
	}

}
