//
//  HTTPrinter.swift
//  Barcode Scanner
//
//  Created by Daniel Gump on 11/12/20.
//  Copyright © 2020 HomeTown Ticketing. All rights reserved.
//

import CoreServices
import ExternalAccessory
import Foundation
import UIKit

class HTTPrinter: NSObject, EAAccessoryDelegate {

	//Used for unit tests
	public static var testPrinters: [HTTAccessory] = []

	//MARK: Public static variables
	public static var delegate: HTTPrinterDelegate?

	//MARK: Public static getters/setters
	public static var active: HTTPrinter? {
		get {
			return HTTPrinter.activePrinter
		}
		set {
			HTTPrinter.activePrinter = newValue
		}
	}

	//MARK: Private static variables
	private static var activePrinter: HTTPrinter?

	//MARK: Static initializers
	public static func initAll() -> [HTTPrinter] {

		var printers: [HTTPrinter] = []

		let tempPrinters: [HTTAccessory] = (testPrinters.count > 0 ? testPrinters : EAAccessoryManager.shared().connectedAccessories)

		for tempPrinter in tempPrinters {

			switch tempPrinter.manufacturer {

				case "Roving Networks":
					let newPrinter = HTTBocaPrinter(with: tempPrinter)
					printers.append(newPrinter)

				default:
					break

			}

		}

		return printers
	}

	//MARK: Public variables
	final public var printer: HTTAccessory?

	public var lastError = ""

	//MARK: Private variables

	//MARK: Base functions to override
	public func connect() -> Bool {
		return false
	}
	public func disconnect() -> Bool {
		return false
	}

	public func printText(_ text: String, withCut: Bool) -> Bool {
		return false
	}

	public func printImage(_ image: URL, withCut: Bool) -> Bool {
		return false
	}

	public func printLogo(withCut: Bool) -> Bool {
		return false
	}

	public func printTicket(with: [String: String]) -> Bool {
		return false
	}

	public func store(logo: URL) -> Bool {
		return false
	}

	//MARK: Private functions


	//MARK: Inits
	override init() {


	}

	//MARK: EAAccessoryDelegate
	func accessoryDidDisconnect(_ accessory: EAAccessory) {
		print("Disconnecting")
		print(accessory.debugDescription)
	}

}

protocol HTTPrinterDelegate: AnyObject {

	func printed() -> Void

	func printer(info: [String: Any]) -> Void

	func printer(error: String) -> Void

}

enum HTTPrinterTypes: String {
	case All
	case Boca
	case Unknown
}
