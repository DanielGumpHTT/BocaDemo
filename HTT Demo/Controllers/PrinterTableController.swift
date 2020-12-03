//
//  PrinterTableController.swift
//  HTT Demo
//
//  Created by Daniel Gump on 11/18/20.
//  Copyright © 2020 HomeTown Ticketing. All rights reserved.
//

import ExternalAccessory
import UIKit

class PrinterTableController: UITableViewController {

	private var printers: [HTTPrinter] = []

	//MARK: Public functions
	public func storeLogo(){

		if let path = Bundle.main.resourcePath {

			//let url = URL(fileURLWithPath: path+"/raiders.bmp")
			let url = URL(fileURLWithPath: path+"/HTTlogo.png")

			print("BMP image found at path")

			//_ = HTTPrinter.active?.store(logo: url)
			_ = HTTPrinter.active?.printImage(url, withCut: true)

		} else {
			print("No valid file path found")
		}

	}

	public func printTicket(){

		//let text = "<RC100,100><F11>\"Hello world\" --HomeTown Ticketing<p>"
		//_ = HTTPrinter.active?.printText(text, withCut: true)

		//_ = HTTPrinter.active?.store(logo: UIImage(named: "Logo")!)
		//_ = HTTPrinter.active?.printLogo(withCut: true)

		let params: [String: String] = [
			"ticket": "\(UInt64.random(in: 100000000000...999999999999))",
			"host": "HomeTown Ticketing",
			"venue": "HomeTown Ticketing Parking Lot",
			"address1": "1328 Dublin Rd., 3rd Floor",
			"address2": "Columbus, OH 43215",
			"title": "Monster Truck Rally",
			"date": "Sunday Sunday Sunday",
			"time": "1:00pm",
			"name": "Truck Zilla",
			"type": "Adult",
			"section": "Reserved",
			"row": "A",
			"seat": "\(UInt8.random(in: 1...255))",
			"price": "$12.00",
			"order": "ABCDEFG",
			"terms": "This ticket will allow one person to enter event. Ticket must not be duplicated. No refunds. No exchanges.",
			"logo": "HTTlogo_wide.png"
		]

		_ = HTTPrinter.active?.printTicket(with: params)

	}

	public func connect() -> Bool {
		return HTTPrinter.active?.connect() ?? false
	}

	public func disconnect() {
		_ = HTTPrinter.active?.disconnect()
	}

	//MARK: Private functions
	private func refresh() {

		printers = HTTPrinter.initAll()

		tableView.reloadData()

	}

	//MARK: Override functions
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)

		refresh()

	}

    // MARK: - Table view data source

	override func numberOfSections(in tableView: UITableView) -> Int {
		return 1
	}

	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return printers.count
	}

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cellPrinter", for: indexPath)

		let ea = printers[indexPath.row].printer!

		var make = "Unknown"
		switch ea.manufacturer {
			case "Roving Networks":
				make = "Boca Manufacturing"

			case "Star micronics":
				make = "Star Micronics"

			default:
				break

		}

		cell.textLabel?.text = "Manufacturer: \(make), Model: \(ea.modelNumber)"
		cell.detailTextLabel?.text = "SN:\(ea.serialNumber) Name:\(ea.name)"
		cell.accessoryType = (((HTTPrinter.active?.printer!.serialNumber ?? "") == ea.serialNumber) ? .checkmark : .none)

        return cell
    }

	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

		HTTPrinter.active = printers[indexPath.row]

		if let cont = parent as? PrinterController {

			cont.btnConnect.isEnabled = (HTTPrinter.active != nil)
			cont.btnPrint.isEnabled = false
			cont.btnConnect.title = "Connect"
			
		}

		tableView.reloadData()
	}

}
