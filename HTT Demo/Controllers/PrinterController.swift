//
//  ViewController.swift
//  Barcode Scanner
//
//  Created by Daniel Gump on 11/11/20.
//  Copyright 2020 HomeTown Ticketing. All Rights Reserved.
//

import UIKit

class PrinterController: UIViewController, HTTPrinterDelegate {

	@IBOutlet weak var btnPrint: UIBarButtonItem!
	@IBOutlet weak var btnLogo: UIBarButtonItem!
	@IBOutlet weak var btnConnect: UIBarButtonItem!

	@IBAction func tappedBtnRefresh(_ sender: UIBarButtonItem) {

		guard let cont = children.first as? PrinterTableController else { return }

		cont.tableView.reloadData()

	}


	@IBAction func tappedBtnPrint(_ sender: UIBarButtonItem) {

		guard let cont = children.first as? PrinterTableController else { return }

		cont.printTicket()

	}

	@IBAction func tappedBtnLogo(_ sender: UIBarButtonItem) {

		guard let cont = children.first as? PrinterTableController else { return }

		cont.storeLogo()

	}


	@IBAction func tappedBtnConnect(_ sender: UIBarButtonItem) {

		guard let cont = children.first as? PrinterTableController else { return }

		if sender.title == "Connect" {
			if cont.connect() {
				btnPrint.isEnabled = true
				btnLogo.isEnabled = true
				sender.title = "Disconnect"
				return
			}
		} else {
			cont.disconnect()
		}

		btnPrint.isEnabled = false
		btnLogo.isEnabled = false
		sender.title = "Connect"
	}

	private var printers = HTTPrinter()

	override func viewDidLoad() {
		super.viewDidLoad()

	}

	override func viewDidAppear(_ animated: Bool) {


	}

	override func viewWillDisappear(_ animated: Bool) {

	}

	func printed() {
		//
	}

	func printer(info: [String : Any])  {
		//
	}

	func printer(error: String) {
		//
	}
}

