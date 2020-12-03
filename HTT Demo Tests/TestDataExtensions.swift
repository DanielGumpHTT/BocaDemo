//
//  TestDataExtensions.swift
//  HTT Demo Tests
//
//  Created by Daniel Gump on 12/1/20.
//  Copyright © 2020 HomeTown Ticketing. All rights reserved.
//

import XCTest

class TestDataExtensions: XCTestCase {

	func testDataToHexString(){

		let string = "Test\n\r\t\0"
		let data: Data = string.data(using: .utf8)!

		XCTAssertEqual(data.hexEncodedString(options: .upperCase), "546573740A0D0900")
		XCTAssertEqual(data.hexEncodedString(options: .lowerCase), "546573740a0d0900")

	}

}
