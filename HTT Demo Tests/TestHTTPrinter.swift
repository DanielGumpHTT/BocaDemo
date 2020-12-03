//
//  TestHTTPrinter.swift
//  HTT Demo Tests
//
//  Created by Daniel Gump on 12/1/20.
//  Copyright © 2020 HomeTown Ticketing. All rights reserved.
//

import ExternalAccessory
import XCTest

struct MockAccessory: HTTAccessory {

	let manufacturer: String
	let connectionID: Int
	let firmwareRevision: String
	let hardwareRevision: String
	let modelNumber: String
	let name: String
	let serialNumber: String

	let isConnected = false

}

class TestHTTPrinter: XCTestCase {

	func testPrinterArray(){

		let boca = MockAccessory(manufacturer: "Roving Networks", connectionID: 0, firmwareRevision: "1.0.0", hardwareRevision: "1.0.0", modelNumber: "Test", name: "Test Boca", serialNumber: "12345")

		let unknown = MockAccessory(manufacturer: "Unknown", connectionID: 2, firmwareRevision: "1.0.0", hardwareRevision: "1.0.0", modelNumber: "Test", name: "Test", serialNumber: "ABCDEF")

		HTTPrinter.testPrinters = [boca, unknown]

		let printers = HTTPrinter.initAll()

		//Order: test, expected, comments
		XCTAssertEqual(printers.count, 1, "Expect the \"Unknown\" manufacturer to be rejected")

		XCTAssertNotNil(printers[0] as? HTTBocaPrinter, "Make sure the 1st printer is the Boca")

		XCTAssertTrue(printers[0].connect(), "Expect successful connection to mock Boca printer") //Boca's SDK allows mock connections
		XCTAssertEqual(printers[0].lastError, "", "Expect No errors")

	}

}
