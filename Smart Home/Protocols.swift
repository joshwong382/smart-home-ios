//
//  Protocols.swift
//  Smart Home
//
//  Created by Joshua Wong on 15/5/2018.
//  Copyright © 2018 Joshua Wong. All rights reserved.
//

import UIKit

// Connection Protocols follow Connection
protocol Connection {
	var timeout: Double {
		get
	}
}

// Local/Remote APIs follow these protocols
protocol Local {
	var connection: IP_CONN {
		get set
	}
}

protocol Remote {
	var connection: JSON_CONN {
		get set
	}
}

// Smart Home Type protocols
protocol Plug {
	
	var has_led: Bool {
		get
	}
	
	// get unit turned on time
	func getUpTime() -> (cancelled: Bool, hour: Int?, min: Int?, sec: Int?)
	
	// get another states
	func getSpecificState(match: String) -> (cancelled: Bool, state: String?)
	
	// change state of power
	func changeRelayState(state: Bool) -> (cancelled: Bool, success: Bool?)
	
	// get state of power and status LED
	func getCommonStates() -> (cancelled: Bool, pwr: Bool?, led: Bool?)
	
	// change state of status LED
	func changeLEDState(state: Bool) -> (cancelled: Bool, success: Bool?)
	
}
