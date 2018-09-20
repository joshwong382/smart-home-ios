//
//  TP-Link_LOCAL.swift
//  Smart Home
//
//  Created by Joshua Wong on 14/5/2018.
//  Copyright © 2018 Joshua Wong. All rights reserved.
//

import UIKit
import SwiftyJSON

class TPLINK_PROTO_LOCAL: SMARTDB {
	
	required init() {}
	
	var type_name: String {
		get {
			return "TP-LINK Smart Plug (Local)"
		}
	}
	
	var obj_type: SMART.Type {
		get {
			return TPLINK_LOCAL.self as SMART.Type
		}
	}
	
	var obj_login: GET_API {
		get {
			return TPLINK_LOCAL_LOGIN()
		}
	}
	
	func save_to_file(api: SMART, name: String) -> [String: Any] {
		// Local
		if let aapi = api as? TPLINK_LOCAL {
			let ip = aapi.connection.returnIP()!
			let port = aapi.connection.returnPort()!
			let json: [String: Any] = [
				"type_id": type(of: self).type_id,
				"name": name,
				"type": "LOCAL",
				"info": [
					"ip": ip,
					"port": String(port)
				]
			]
			return json
		}
		return [:]
	}
	
	func load_from_file(file: [String : Any]) -> (api: SMART?, name: String?) {
		
		if (file["type"] as? String == "LOCAL") {
			if let info = file["info"] as? [String: String] {
				let ip = info["ip"]
				let port = info["port"]
				if (ip == nil || port == nil) {
					return (nil, nil)
				}
				let api = TPLINK_LOCAL(ip: ip! + ":" + port!)
				let name = file["name"] as? String
				if (name == nil) {
					return (nil, nil)
				}
				return (api, name)
			}
		}
		return (nil, nil)
	}
}

class TPLINK_LOCAL_LOGIN: CUSTOM_GETAPI, LOGIN_UIOVERRIDES {
	
	func field_overrides(firstField: inout UITextField, secondField: inout UITextField, fieldsRequirementLevel: inout UInt) {
		fieldsRequirementLevel = 1
		firstField.placeholder = "IP(:PORT) or URL"
		secondField.isHidden = true
	}
	
	func getAPI(firstText: String?, secondText: String?) -> (error: Bool, new_api: SMART?, name: String?) {
		if (firstText == nil) {
			return (true, nil, nil)
		}
		let api = TPLINK_LOCAL(ip: firstText!)
		if (api == nil) {
			return (true, nil, nil)
		}
		
		var i = 0
		var name: String? = nil
		while (true) {
			let result = api!.getSpecificState(match: "alias")
			if (result.cancelled == false) {
				name = result.state
				break
			}
			if (i >= 5) {
				name = nil
				break
			}
			i += 1
		}
		return (false, api, name)
	}
	
}

class TPLINK_LOCAL: Plug, Local {
	
	var connection: IP_CONN
	
	init?(ip: String) {
		connection = IP_CONN(string: ip)
		if (connection.isValid()) {
			print("Using TP-LINK Local Plug")
		} else {
			print("Connection Error")
			return nil
		}
	}
	
	init?(conn: IP_CONN) {
		connection = conn
		if (connection.isValid()) {
			print("Using TP-LINK Local Plug")
		} else {
			print("Connection Error")
			return nil
		}
	}

	var has_led: Bool {
		get {
			// TPLINK API does have LEDs
			return true
		}
	}
	
	var vendor_name: String {
		get {
			return "TP-LINK"
		}
	}
	
	var type_id: UInt {
		get {
			return TPLINK_PROTO_LOCAL.type_id
		}
	}
	
	/*-----------------------------------------------
	/
	/	STATES UPDATE
	/
	/ ---------------------------------------------*/
	
	private func getAllStates() -> (cancelled: Bool, json_str: String?) {
		
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
		
		if (response.count == 0) { return (false, nil) }
		
		var json = response.trimmingCharacters(in: .whitespacesAndNewlines)
		json = String(response.dropFirst(3))
		
		json = "{" + json
		
		if (debug_contains(type: .TCP)) {
			print("/*************")
			print(response)
			print("*************/")
		}
		
		return (false, json)
	}
	
	// get state of power and status LED
	func getCommonStates() -> (cancelled: Bool, pwr: Bool?, led: Bool?) {
		
		let result = getAllStates()
		
		// Check Cancelled
		if (result.cancelled) { return (true, nil, nil) }
		
		// Check Request
		if (result.json_str == nil) { return (false, nil, nil) }
		
		// Check Relay State
		let json_obj: JSON = JSON(parseJSON: result.json_str!)
		
		if (json_obj["system"]["get_sysinfo"]["relay_state"].stringValue == "") { return (false, nil, nil) }
		
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
	
	// A Stub to Get Common States to satisfy protocol
	func getPowerState() -> (cancelled: Bool, pwr: Bool?) {
		let result = getCommonStates()
		return (result.cancelled, result.pwr)
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
		
		let result = getAllStates()
		
		// Check Cancelled
		if (result.cancelled) { return (true, nil) }
		
		// Check Request
		if (result.json_str == nil) { return (false, nil) }
		
		// Check Relay State
		let json_obj: JSON = JSON(parseJSON: result.json_str!)
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
		var result = [UInt8](pack(">I", [data.count]))
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
