//
//  smart_base.swift
//  Smart Home
//
//  Created by Joshua Wong on 15/5/2018.
//  Copyright © 2018 Joshua Wong. All rights reserved.
//

import UIKit

protocol Plug {
	
	var has_led: Bool {
		get
	}
	
	// get unit turned on time
	func getUpTime() -> (Bool, Int?, Int?, Int?)
	
	// get another states
	func getSpecificState(match: String) -> String?
	
	// change state of power
	func changeRelayState(state: Bool) -> Bool?
	
	// get state of power and status LED
	func getCommonStates() -> (pwr: Bool?, led: Bool?)
	
	// change state of status LED
	func changeLEDState(state: Bool) -> Bool?
	
}

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
