//
//  EAAccessoryExtensions.swift
//  HTT Demo
//
//  Created by Daniel Gump on 12/2/20.
//  Copyright © 2020 HomeTown Ticketing. All rights reserved.
//

import ExternalAccessory
import Foundation

extension EAAccessory: HTTAccessory {}

protocol HTTAccessory {
	var isConnected: Bool { get }
	var serialNumber: String { get }

	var manufacturer: String { get }
	var connectionID: Int { get }
	var firmwareRevision: String { get }
	var hardwareRevision: String { get }
	var modelNumber: String { get }
	var name: String { get }

}
