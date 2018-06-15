//
//  TP-Link_LOCAL.swift
//  Smart Home
//
//  Created by Joshua Wong on 14/5/2018.
//  Copyright © 2018 Joshua Wong. All rights reserved.
//

import UIKit
import SwiftyJSON

class TPLINK_LOCAL: Plug, Local {
	
	var connection: IP_CONN
	
	init(ip: String) {
		connection = IP_CONN(string: ip)
		if (connection.isValid()) {
			print("Using TP-LINK Local Plug")
		} else {
			print("Connection Error")
		}
	}
	
	init(conn: IP_CONN) {
		connection = conn
		if (connection.isValid()) {
			print("Using TP-LINK Local Plug")
		} else {
			print("Connection Error")
		}
	}

	var has_led: Bool {
		get {
			// TPLINK API does have LEDs
			return true
		}
	}
	
	/*-----------------------------------------------
	/
	/	STATES UPDATE
	/
	/ ---------------------------------------------*/
	
	// get state of power and status LED
	func getCommonStates() -> (cancelled: Bool, pwr: Bool?, led: Bool?) {
		
		// Get Plug Info
		let info_req = "{\"system\":{\"get_sysinfo\":null}}"
		var cancelled: Bool
		var request: [UInt8]?
		(cancelled, request) = connection.send_data(data: encrypt_req(data: info_req))
		
		// Check Cancelled
		if (cancelled) { return (true, nil, nil) }
		
		// Check Request
		if (request == nil) { return (false, nil, nil) }
		
		// Check connection
		if (!connection.ableConnect()) { return (false, nil, nil) }
		
		let response = decrypt_req(data: request!)
		
		var json = response.trimmingCharacters(in: .whitespacesAndNewlines)
		json = String(response.dropFirst(3))
		json = "{" + json
		//print(json)
		
		// Check Relay State
		let json_obj: JSON = JSON(parseJSON: json)
		let pwr = json_obj["system"]["get_sysinfo"]["relay_state"].boolValue
		let led = json_obj["system"]["get_sysinfo"]["led_off"].boolValue
		
		/*
		if let range = json.range(of: "\"relay_state\":") {
		let relay = json[range.upperBound...]
		let power: Int = Int(String(relay[relay.startIndex]))!
		pwr = Bool(truncating: power as NSNumber)
		}
		
		if let range2 = json.range(of: "\"led_off\":") {
		let relay2 = json[range2.upperBound...]
		let led_pwr: Int = Int(String(relay2[relay2.startIndex]))!
		led = Bool(truncating: led_pwr as NSNumber)
		}*/
		
		return (false, pwr, led)
	}
	
	// JSON interface functions

	func getUpTime() -> (cancelled: Bool, hour: Int?, min: Int?, sec: Int?) {
		
		var cancelled: Bool
		var result: String?
		(cancelled, result) = getSpecificState(match: "on_time")
		
		if (cancelled) { return (true, nil, nil, nil) }
		if (result == nil) { return (false, nil, nil, nil) }
		
		let on_time: Int = Int(result!)!
		var h, m, s: Int
		(h,m,s) = secToTime(seconds: on_time)
		//print(h,"h",m,"m",s,"s")
		return (false, h,m,s)
	}

	func getSpecificState(match: String) -> (cancelled: Bool, state: String?) {
		// Get Plug Info
		let info_req = "{\"system\":{\"get_sysinfo\":null}}"
		var cancelled: Bool
		var request: [UInt8]?
		(cancelled, request) = connection.send_data(data: encrypt_req(data: info_req))
		
		// Check Cancelled
		if (cancelled) { return (true, nil) }
		
		// Check Request
		if (request == nil) { return (false, nil) }
		
		// Check connection
		if (!connection.ableConnect()) { return (false, nil) }
		
		let response = decrypt_req(data: request!)
		
		var json = response.trimmingCharacters(in: .whitespacesAndNewlines)
		json = String(response.dropFirst(3))
		json = "{" + json
		
		// Check Relay State
		let json_obj: JSON = JSON(parseJSON: json)
		let relay = json_obj["system"]["get_sysinfo"][match].stringValue
		
		return (false, relay)
	}

	func changeRelayState(state: Bool) -> (cancelled: Bool, success: Bool?) {
		let on_req = "{\"system\":{\"set_relay_state\":{\"state\":1}}}"
		let off_req = "{\"system\":{\"set_relay_state\":{\"state\":0}}}"
		var req: String
		if (state) {
			req = on_req
		}
		else {
			req = off_req
		}
		
		var cancelled: Bool
		var request: [UInt8]?
		(cancelled, request) = connection.send_data(data: encrypt_req(data: req))
		
		// Check Cancelled
		if (cancelled) { return (true, nil) }
		
		// Check Request
		if (request == nil) { return (false, nil) }
		
		// Check connection
		if (!connection.ableConnect()) { return (false, nil) }
		
		let response = decrypt_req(data: request!)
		let json = response.trimmingCharacters(in: .whitespacesAndNewlines)
		
		// Check Relay State Set
		if let range = json.range(of: "\"err_code\":") {
			let relay = json[range.upperBound...]
			let pwr: Int = Int(String(relay[relay.startIndex]))!
			return (false, Bool(truncating: pwr as NSNumber))
		}
		return (false, nil)
	}
	
	// change state of status LED
	func changeLEDState(state: Bool) -> (cancelled: Bool, success: Bool?) {
		let led_on = "{\"system\":{\"set_led_off\":{\"off\":0}}}"
		let led_off = "{\"system\":{\"set_led_off\":{\"off\":1}}}"
		var req: String
		if (state) {
			req = led_on
		}
		else {
			req = led_off
		}
		
		var cancelled: Bool
		var request: [UInt8]?
		(cancelled, request) = connection.send_data(data: encrypt_req(data: req))
		
		// Check Cancelled
		if (cancelled) { return (true, nil) }
		
		// Check Request
		if (request == nil) { return (false, nil) }
		
		// Check connection
		if (!connection.ableConnect()) { return (false, nil) }
		
		let response = decrypt_req(data: request!)
		let json = response.trimmingCharacters(in: .whitespacesAndNewlines)
		
		// Check Relay State Set
		if let range = json.range(of: "\"err_code\":") {
			let relay = json[range.upperBound...]
			let pwr: Int = Int(String(relay[relay.startIndex]))!
			return (false, Bool(truncating: pwr as NSNumber))
		}
		return (false, nil)
	}

	/*-----------------------------------------------
	/
	/	TP-LINK PROTOCOL FUNCTIONS
	/
	/ ---------------------------------------------*/

	func encrypt_req(data: String) -> [UInt8] {
		let data_char = Array(data)
		var key: UInt32 = 171
		var result = [UInt8]()
		result += [0,0,0,0]
		for i: Character in data_char {
			let a = key ^ (i.ascii)!
			key = a
			result += [UInt8(a)]
		}
		return result
	}

	func decrypt_req(data: [UInt8]) -> String {
		var key: UInt32 = 171
		var result: String = ""
		for i in data {
			let a = key ^ UInt32(i)
			key = UInt32(i)
			if (a < 255) && (a > 0) {
				result += String(UnicodeScalar(a)!)
			}
		}
		return result
	}
}
