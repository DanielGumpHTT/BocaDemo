//
//  HTTBocaPrinter.swift
//  HTT Demo
//
//  Created by Daniel Gump on 11/19/20.
//  Copyright © 2020 HomeTown Ticketing. All rights reserved.
//

// Ticket stock sizes
//  0       Concert (2 x 5.5)
//  1       Cinema (3.25 x 2)
//  2       Credit Card (2.13 x 3.37)
//  3       Receipt (3.25 x 8)
//  4       Ski (3.25 x 6)
//  5       "4 x 6"
//  6       Wristband 1 (11 x 1)
//  7       Wristband 2 (11 x 1.328)

// Font sizes
// <F1>		Font1 characters (5x7)
// <F2>		Font2 characters (8x16)
// <F3>		OCRB (17x31)
// <F4>		OCRA (5x9)
// <F6>		large OCRB (30x52)
// <F7>		OCRA (15x29)
// <F8>		Courier (20x40)(20x33)
// <F9>		small OCRB (13x20)
// <F10>	Prestige (25x41)
// <F11>	Script (25x49)
// <F12>	Orator (46x91)
// <F13>	Courier (20x40)(20x42)

import Foundation
import UIKit

class HTTBocaPrinter: HTTPrinter {

	private var port = false

	init(with: HTTAccessory) {
		super.init()

		self.printer = with

	}

	deinit {
		_ = disconnect()
	}

	//MARK: Override functions

	override func connect() -> Bool {

		port = OpenSessionBTPicker(printer!.name)

		if !port {
			lastError = "Could not connect to \(printer!.name)"
			return false
		}

		return true
	}

	override func disconnect() -> Bool {

		if !port {
			return false
		}

		CloseSessionBT()
		port = false

		return true
	}

	override func printText(_ text: String, withCut: Bool) -> Bool {

		if !port {
			lastError = "Port to \(printer!.name) not open"
			return false
		}

		SendString(text)

		if withCut {
			PrintCut()
		}

		return true
	}

	override func printImage(_ path: URL, withCut: Bool) -> Bool {

		if !port {
			lastError = "Port to \(printer!.name) not open"
			return false
		}

		var text = "<NR>\r"

		if let bmpData = FileManager.default.contents(atPath: path.relativePath) {

			let bmpString = bmpData.hexEncodedString(options: .upperCase)

			text += "<SP0,0><bmp><g\(bmpString.count)>\(bmpString)\r" //surrounded by ESC

		} else {
			lastError = "Unable to load BMP image"
			return false
		}

		//return false
		return printText(text, withCut: false)

	}

	override func printLogo(withCut: Bool) -> Bool {

		if !port {
			lastError = "Port to \(printer!.name) not open"
			return false
		}

		if !PrintLogo(1, 0, 0) {
			lastError = "Unable to print logo to \(printer!.name)"
			return false
		}

		if withCut {
			PrintCut()
		}

		return true
	}

	override func store(logo: URL) -> Bool {

		if !port {
			lastError = "Port to \(printer!.name) not open"
			return false
		}

		//Store HomeTown Ticketing logo on printer as image #1
		var text = storeHTTLogo()

		if let bmpData = FileManager.default.contents(atPath: logo.relativePath) {

			let bmpString = bmpData.hexEncodedString(options: .upperCase)

			text += "<ID2>\u{1B}<bmp><g\(bmpString.count)>\(bmpString)\u{1B}\r" //surrounded by ESC

		} else {
			lastError = "Unable to load BMP image"
			return false
		}

		//return false
		return printText(text, withCut: false)

	}


	override func printTicket(with: [String: String]) -> Bool {

		var text = "<NR>\r" //Landscape rotation
		text += "<RC511,1000><F2>Powered by\r"
		text += "<SP502,1115><LD1>\r"

		for line in with {

			switch line.key {

				case "host":
					//Inverted
					let len = line.value.count
					//Pad whitespace to 48 characters
					if len < 48 {
						let count = (48 - len) >> 1
						let pad = String(repeating: " ", count: count)
						text += "<RC5,10><F10>\(pad+line.value+pad+((len % 2) == 1 ? " " : ""))\r" //Prestige (25x41)
					//Trim more than 48 characters
					} else {
						text += "<RC5,10><F10>\(line.value.dropLast(len - 48))\r"//Prestige (25x41)
					}

				case "title":
					//Inverted
					let len = line.value.count
					//Pad whitespace to 40 characters
					if len < 40 {
						let count = (40 - len) >> 1
						let pad = String(repeating: " ", count: count)
						text += "<EI><RC50,10><F6>\(pad+line.value+pad+((len % 2) == 1 ? " " : ""))<DI>\r"//large OCRB (30x52)
					//Trim more than 40 characters
					} else {
						text += "<EI><RC50,10><F6>\(line.value.dropLast(len - 40))<DI>\r"//large OCRB (30x52)
					}

				case "order":
					text += "<RC115,30><F8>Order #\(line.value)\r"

				case "name":
					text += "<RC149,30><F8>Name:\r"
					text += "<RC160,180><F9>\(line.value)\r"

				case "price":
					text += "<RC182,30><F8>Price:\r"
					text += "<RC193,180><F9>\(line.value)\r"

				case "type":
					text += "<RC193,280><F9>(\(line.value))\r"

				case "ticket":
					text += "<RC235,42><F9>ADMIT ONE PERSON\r" //small OCRB 13x20

					//QR code 5pt, no tilde, numeric encoding, 15% error correction
					text += "<RC275,30><QR5,0,2,0>{\(line.value)}\r"

					text += "<RC500,22><F7>\(line.value)\r" //Courier 20x40

				case "venue":
					let x = 1350 - 20 * line.value.count
					text += "<RC120,\(x)><F3>\(line.value)\r" //OCRB 17x31 chars

				case "address1":
					let x = 1350 - 13 * line.value.count
					text += "<RC165,\(x)><F9>\(line.value)\r" //small OCRB 13x20 chars

				case "address2":
					let x = 1350 - 13 * line.value.count
					text += "<RC195,\(x)><F9>\(line.value)\r" //small OCRB 13x20 chars

				case "date":
					let x = 1350 - 20 * line.value.count
					text += "<RC230,\(x)><F3>\(line.value)\r"

				case "time":
					let x = 1350 - 13 * line.value.count
					text += "<RC280,\(x)><F9>\(line.value)\r"

				case "section":
					let val = line.value.prefix(14)
					let x = 1190 - val.count * 9
					text += "<EI><RC320,1045><F9>        Section        <DI>\r"
					text += "<RC343,1046><BX50,300>\r"
					text += "<RC356,\(x)><F7>\(val)\r"//2x OCRA (30x52)

				case "row":
					let x = 1133 - line.value.count * 30
					text += "<EI><RC400,1045><F9>    Row    <DI>\r"
					text += "<RC423,1046><BX70,143>\r"
					text += "<HW2,2><RC433,\(x)><F7>\(line.value)<HW1,1>\r"//2x OCRA (30x52)

				case "seat":
					let x = 1307 - line.value.count * 30
					text += "<EI><RC400,1201><F9>   Seat    <DI>\r"
					text += "<RC423,1202><BX70,143>\r"
					text += "<HW2,2><RC433,\(x)><F7>\(line.value)<HW1,1>\r"//2x OCRA (30x52)

				case "logo":
					//text += "<RC220,300><BX316,600>\r"
					//text += "<RC360,440><F6>LOGO HERE\r"
					text += "<SP220,300><LD2>\r"
					break

				case "terms":
					text += "<RC545,10><F2>\(line.value)\r" //Font1 5x7 chars

				default:
					break
			}

		}

		//return false
		return printText(text, withCut: true)
	}

	//MARK: Private functions

	//Store HomeTown Ticketing logo on printer as image #1
	private func storeHTTLogo() -> String {

		var text = "<ID1>\u{1B}<RC0,0>" //ESC
		text += "<g480>7FFFFFF1E0E0E0E0E0E0E0E0E0E0E0E0E0E0F0FFFF7F00007FFFFFF0E0E0E0E0" //Rows 1-8 of columns 1-32
		text +=       "E0E0E0E0E0E0E0E0E0E0F1FFFF7F000000000000000000000000000000000000" //Rows 1-8 of columns 33-64
		text +=       "0000000000000000000000000000000000000000000000000000000000000000" //Rows 1-8 of columns 65-96
		text +=       "0000000000000000000000000000000000000000000000000000000000000000" //Rows 1-8 of columns 97-128
		text +=       "0000000000000000000000000000000000000000000000000000000000000000" //Rows 1-8 of columns 129-160
		text +=       "0000000000000000000000000000000000000000000000000000000000000000" //Rows 1-8 of columns 161-192
		text +=       "0000000000000000000000000000000000000000000000000000000000000000" //Rows 1-8 of columns 193-224
		text +=       "00000000000000000000000000000000\r" //Rows 1-8 of columns 225-240
		text += "<g480>C0E0E0E0E0FFFF7F0000000000007FFFFFE0E0E0E0C00000C0E0E0E0E0FFFF7F" //Rows 9-16 of columns 1-32
		text +=       "0000000000007FFFFFE0E0E0E0C0000000000000001C1C1F1F1F1F1E1C1C0000" //Rows 9-16 of columns 33-64
		text +=       "00001C1C1E1F1F1F1F1C1C000000000307070F0F1F1E1E1E1E1E1F0F0F070703" //Rows 9-16 of columns 65-96
		text +=       "000000001C1C1C1F1F1F1F0F0300000000000000030F1F1F1F1F1C1C1C000000" //Rows 9-16 of columns 97-128
		text +=       "1C1C1F1F1F1F1C1C1C1C1C1E1F1F0F000E1F1F1F1C1C1C1E1F1F1F1F1E1C1C1C" //Rows 9-16 of columns 129-160
		text +=       "1F1F1F0E0000000307070F0F1F1E1E1E1E1E1F0F0F0707030000001C1C1F1F1F" //Rows 9-16 of columns 161-192
		text +=       "1F1C1C00000000071F1F1F07000000001C1C1F1F1F1F1C1C00001C1C1F1F1F1F" //Rows 9-16 of columns 193-224
		text +=       "0F03010000001C1C1E1F1F1F1F1E1C1C\r" //Rows 9-16 of columns 225-240
		text += "<g480>0000000000FFFFFF000000000000C0E1E1E1E1E1E1E1E1E1E1E1E1E1E1E1E1C0" //Rows 17-24 of columns 1-32
		text +=       "000000000000FFFFFF0000000000000000000000000000FFFFFFFF1F0E0E0E0E" //Rows 17-24 of columns 33-64
		text +=       "0E0E0E0E1FFFFFFFFF000000003FFFFFFFE08000000000000000000080E0FFFF" //Rows 17-24 of columns 65-96
		text +=       "FF3F000000001FFFFFFFE0F0FCFF1F0701071FFFFCF0E0FFFFFF1F0000000000" //Rows 17-24 of columns 97-128
		text +=       "0000FFFFFFFF0E0E0E0E0E0E848080000080800000000000FFFFFFFF00000000" //Rows 17-24 of columns 129-160
		text +=       "00808000003FFFFFFFE08000000000000000000080E0FFFFFF3F00000080F8FF" //Rows 17-24 of columns 161-192
		text +=       "FF7F0700010F7FFFFCE0FCFF7F0F0100077FFFFFF880000000000000FFFFFFFF" //Rows 17-24 of columns 193-224
		text +=       "E0F8FC7F3F0F070100FFFFFFFF000000\r" //Rows 17-24 of columns 225-240
		text += "<g480>0001010101FFFFFF000000000000FFFFFFC1C1C1C1C0C0C0C0C1C1C1C1FFFFFF" //Rows 25-32 of columns 1-32
		text +=       "000000000000FFFFFF0101010100000000000000000707FFFFFFFF0F07070000" //Rows 25-32 of columns 33-64
		text +=       "000007070FFFFFFFFF0707000080E0F8FCFC3E1E1F0F0F0F0F0F1F1E3EFCFCF8" //Rows 25-32 of columns 65-96
		text +=       "E0800007070FFFFFFFFF07070080E0F0F0F0E080000707FFFFFFFF0F07070000" //Rows 25-32 of columns 97-128
		text +=       "0707FFFFFFFF07070707070F3F3F3E00000000000007070FFFFFFFFF0F070700" //Rows 25-32 of columns 129-160
		text +=       "000000000080E0F8FCFC3E1E1F0F0F0F0F0F1F1E3EFCFCF8E080000000000080" //Rows 25-32 of columns 161-192
		text +=       "F8FEFF3FFFFEF8C0000000C0F8FEFF3FFFFEF8800000000000000707FFFFFFFF" //Rows 25-32 of columns 193-224
		text +=       "0F07070080E0F0FCFEFFFFFFFF000000\r" //Rows 25-32 of columns 225-240
		text += "<g480>FFFFFFE3C1C1C18101010101010181C1C1C1C3FFFFFF0000FFFFFFC3C1C1C1C1" //Rows 33-40 of columns 1-32
		text +=       "01010101010181C1C1C1E3FFFFFF000000000000000000000000000000000000" //Rows 33-40 of columns 33-64
		text +=       "0000000000000000000000000000000000000000000000000000000000000000" //Rows 33-40 of columns 65-96
		text +=       "0000000000000000000000000000000000000000000000000000000000000000" //Rows 33-40 of columns 97-128
		text +=       "0000000000000000000000000000000000000000000000000000000000000000" //Rows 33-40 of columns 129-160
		text +=       "0000000000000000000000000000000000000000000000000000000000000000" //Rows 33-40 of columns 161-192
		text +=       "0000000000000000000000000000000000000000000000000000000000000000" //Rows 33-40 of columns 193-224
		text +=       "00000000000000000000000000000000\r" //Rows 33-40 of columns 225-240
		text += "<g480>80C0C0C0C0C0C0C0C0C0C0C0C0C0C0C0C0C0C0C0C080000080C0C0C0C0C0C0C0" //Rows 41-42 of columns 1-32
		text +=       "C0C0C0C0C0C0C0C0C0C0C0C0C080000000000000000000000000000000000000" //Rows 41-42 of columns 33-64
		text +=       "0000000000000000000000000000000000000000000000000000000000000000" //Rows 41-42 of columns 65-96
		text +=       "0000000000000000000000000000000000000000000000000000000000000000" //Rows 41-42 of columns 97-128
		text +=       "0000000000000000000000000000000000000000000000000000000000000000" //Rows 41-42 of columns 129-160
		text +=       "0000000000000000000000000000000000000000000000000000000000000000" //Rows 41-42 of columns 161-192
		text +=       "0000000000000000000000000000000000000000000000000000000000000000" //Rows 41-42 of columns 193-224
		text +=       "00000000000000000000000000000000\r" //Rows 41-42 of columns 225-240
		text += "\u{1B}\r" //ESC

		return text
	}

}
