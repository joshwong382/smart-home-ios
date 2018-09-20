//
//  TP-Link_REMOTE.swift
//  Smart Home
//
//  Created by Joshua Wong on 14/5/2018.
//  Copyright © 2018 Joshua Wong. All rights reserved.
//

import UIKit
import SwiftyJSON

class TPLINK_PROTO_REMOTE: SMARTDB {
	
	required init() {}
	
	var type_name: String {
		get {
			return "TP-LINK Smart Plug (Remote)"
		}
	}
	
	var obj_type: SMART.Type {
		get {
			return TPLINK_REMOTE.self as SMART.Type
		}
	}
	
	
	var obj_login: GET_API {
		get {
			return TPLINK_REMOTE_LOGIN()
		}
	}
	
	func save_to_file(api: SMART, name: String) -> [String: Any] {
		
		// If TPLINK is Remote
		if let aapi = api as? TPLINK_REMOTE {
			let info = aapi.get_info()
			let json: [String: Any] = [
				"type_id": type(of: self).type_id,
				"name": name,
				"type": "REMOTE",
				"info": [
					"token": info.token,
					"domain": info.domain,
					"devid": info.devid
				]
			]
			return json
		}
		
		return [:]
	}
	
	func load_from_file(file: [String: Any]) -> (api: SMART?, name: String?) {
		
		if (file["type"] as? String == "REMOTE") {
			let info = file["info"] as? [String : Any]
			if (info != nil) {
				let token = info!["token"] as? String
				let domain = info!["domain"] as? String
				let devid = info!["devid"] as? String
				if (token == nil || domain == nil || devid == nil) {
					return (nil, nil)
				}
				let api = TPLINK_REMOTE(_token: token!, _url: domain!, _devid: devid!)
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

class TPLINK_REMOTE_LOGIN: TOKEN_MULTIDEVICE, TOKEN_LOGIN {
	
	private var token: String = ""
	private var token_url: String = "https://wap.tplinkcloud.com"
	private var uuid: String = "760fec46-3711-49a7-9c26-c46fb436da76"
	
	init() {}
	
	func check_token(token: String) -> (error: Bool, token: String) {
		self.token = token
		let result = get_devices()
		if (result.error) {
			self.token = ""
			return (true, "")
		}
		return (false, token)
	}
	
	func get_devices() -> (error: Bool, devices: [(api_url: String, device_id: String, alias: String)]?) {
		
		if (token == "") {
			return (true, nil)
		}
		
		guard let devices_conn = JSON_CONN(url: token_url + "?token=" + token) else {
			return (true, nil)
		}
		
		let request: JSON = [
			"method": "getDeviceList"
		]
		
		let response = devices_conn.send_string(json: request.rawString()!).response
		if (response == nil || response == "") { return (true, nil) }
		
		var json_obj: JSON = JSON(parseJSON: response!)
		
		// Check Error Code
		if let error_code = json_obj["error_code"].int {
			if (error_code != 0) {
				return (true, nil)
			}
		}
		
		var devices = [(api_url: String, device_id: String, alias: String)]()
		
		let devicelist = json_obj["result"]["deviceList"].arrayValue
		
		for device in devicelist {
			var alias: String
			
			// Check if device has alias. If not, use the factory assigned name
			if (device["alias"].stringValue != "") {
				alias = device["alias"].stringValue
			} else {
				alias = device["deviceName"].stringValue
			}
			devices.append((api_url: device["appServerUrl"].stringValue, device_id: device["deviceId"].stringValue, alias: alias))
		}
		
		return (false, devices)
	}
	
	func token_from_login(username: String?, password: String) -> (error: Bool, token: String?) {
		
		guard let token_conn = JSON_CONN(url: token_url) else {
			return (true, nil)
		}
		
		let request: JSON = [
			"method": "login",
			"params": [
				"appType": "Kasa_Android",
				"cloudUserName": username,
				"cloudPassword": password,
				"terminalUUID": uuid
			]
		]
		
		let response = token_conn.send_string(json: request.rawString()!).response
		if (response == nil) { return (true, nil) }
		
		var json_obj: JSON = JSON(parseJSON: response!)
		
		// Print Error Message if there is one
		if (json_obj["error_code"].intValue != 0) {
			return (true, json_obj["msg"].stringValue)
		}
		
		let potential_token: String = json_obj["result"]["token"].stringValue
		
		// Make sure token is more than 2 characters
		if (potential_token.count < 2) {
			return (true, nil)
		}
		
		token = potential_token
		
		return (false, potential_token)
	}
	
}

class TPLINK_REMOTE: TPLINK_REMOTE_LOGIN, Remote_TokenHasExpiry, Remote_MultiDevice, Plug {
	
	enum API: String {
		case ON = "{\\\"system\\\":{\\\"set_relay_state\\\":{\\\"state\\\":1}}}"
		case OFF = "{\\\"system\\\":{\\\"set_relay_state\\\":{\\\"state\\\":0}}}"
		case LED_ON = "{\\\"system\\\":{\\\"set_led_off\\\":{\\\"off\\\":0}}}"
		case LED_OFF = "{\\\"system\\\":{\\\"set_led_off\\\":{\\\"off\\\":1}}}"
		case INFO = "{\\\"system\\\":{\\\"get_sysinfo\\\":null}}"
	}
	
	var connection: JSON_CONN?
	private var token = ""
	private var domain: String = ""
	private var devid: String = ""
	private var token_expire: Bool = false
	
	required init?(_token: String, _url: String, _devid: String) {
		print("Using TP-LINK Remote Plug")
		token = _token
		domain = _url
		devid = _devid
		guard let connection = JSON_CONN(url: _url + "/?token=" + _token) else {
			return nil
		}
		self.connection = connection
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
			return TPLINK_PROTO_REMOTE.type_id
		}
	}
	
	func get_info() -> (token: String, domain: String, devid: String) {
		return (token, domain, devid)
	}
	
	private func getURL() -> String {
		return domain + "/?token=" + token
	}
	
	private func getAPICalls(api: API) -> String {
		return """
		{"method":"passthrough", "params": {"deviceId": "
		""" + devid + """
		", "requestData": \"
		""" + api.rawValue + """
		\"}}
		"""
	}
	
	func token_update(token: String) {
		self.token = token
	}
	
	func checkExpiry() -> Bool {
		return token_expire
	}
	// Update States
	
	// get state of power and status LED
	func getCommonStates() -> (cancelled: Bool, pwr: Bool?, led: Bool?) {
		
		if (token_expire) { return (false, nil, nil) }
		
		// Get Plug Info
		let response = connection!.send_string(json: getAPICalls(api: API.INFO))
		
		// Check Cancelled
		if (response.cancelled) { return (true, nil, nil) }
		
		// Check Relay State
		if (response.response == nil) { return (false, nil, nil) }
		
		
		var json_obj: JSON = JSON(parseJSON: response.response!)
		
		if let err_code = json_obj["error_code"].int {
		
			// Check Token Expiry
			if (json_obj["msg"].stringValue == "Token expired") {
				token_expire = true
				print("Token Expired")
				return (false, nil, nil)
			}
			
			// Check Device Offline
			if (json_obj["msg"].stringValue == "Device is offline") {
				print("Device Offline")
				return (false, nil, nil)
			}
			
			// Check Error Code
			if (json_obj["error_code"].intValue != 0) {
				print("Unknown Error: " + String(err_code))
				return (false, nil, nil)
			}
			
		} else {
			
			// TP-LINK API Error
			print("TP-LINK API ERROR")
			return (false, nil, nil)
			
		}
		
		json_obj = JSON(parseJSON: json_obj["result"]["responseData"].stringValue)
		let pwr = json_obj["system"]["get_sysinfo"]["relay_state"].boolValue
		let led = json_obj["system"]["get_sysinfo"]["led_off"].boolValue
		
		return (false, pwr, led)
	}
	
	// Stub to getCommonStates()
	func getPowerState() -> (cancelled: Bool, pwr: Bool?) {
		let result = getCommonStates()
		return (result.cancelled, result.pwr)
	}
	
	// JSON interface functions
	
	func getUpTime() -> (cancelled: Bool, hour: Int?, min: Int?, sec: Int?) {
		if (token_expire) { return (false, nil, nil, nil) }
		
		let result = getSpecificState(match: "on_time")

		// Check Cancelled and State
		if (result.cancelled) { return (true, nil, nil, nil) }
		if (result.state == nil || result.state == "") { return (false, nil, nil, nil) }
		
		let on_time: Int = Int(result.state!)!
		var h, m, s: Int
		(h,m,s) = secToTime(seconds: on_time)
		//print(h,"h",m,"m",s,"s")
		return (true, h,m,s)
	}
	
	func getSpecificState(match: String) -> (cancelled: Bool, state: String?) {
		if (token_expire) { return (false, nil) }
		
		// Get Plug Info
		let response = connection!.send_string(json: getAPICalls(api: API.INFO))
		
		// Check cancelled
		if (response.cancelled) { return (true, nil) }
		
		// Check response
		if (response.response == nil) { return (false, nil) }
		
		// Check Relay State
		var json_obj: JSON? = JSON(parseJSON: response.response!)
		if (json_obj == nil) { return (false, nil) }
		
		let response_data = json_obj!["result"]["responseData"].stringValue
		
		json_obj = JSON(parseJSON: response_data)
		if (json_obj == nil) { return (false, nil) }
		
		let relay = json_obj!["system"]["get_sysinfo"][match].stringValue
		
		return (false, relay)
	}
	
	func changeRelayState(state: Bool) -> (cancelled: Bool, success: Bool?) {
		if (token_expire) { return (false, nil) }
		
		var req: API
		if (state) {
			req = API.ON
		}
		else {
			req = API.OFF
		}
		
		// Get Plug Info
		let response = connection!.send_string(json: getAPICalls(api: req))
		
		// Check cancelled
		if (response.cancelled) { return (true, nil) }
		
		// Check response
		if (response.response == nil) { return (false, nil) }
		
		// Check Relay State Set
		var json_obj: JSON? = JSON(parseJSON: response.response!)
		if (json_obj == nil) { return (false, nil) }
		
		json_obj = JSON(parseJSON: json_obj!["result"]["responseData"].stringValue)
		if (json_obj == nil) { return (false, nil) }
		
		let relay = json_obj!["system"]["set_relay_state"]["err_code"].boolValue
		
		return (false, relay)
	}
	
	// change state of status LED
	func changeLEDState(state: Bool) -> (cancelled: Bool, success: Bool?) {
		if (token_expire) { return (false, nil) }
		
		var req: API
		if (state) {
			req = API.LED_ON
		}
		else {
			req = API.LED_OFF
		}
		
		let response = connection!.send_string(json: getAPICalls(api: req))
		
		// Check cancelled
		if (response.cancelled) { return (true, nil) }
		
		// Check response
		if (response.response == nil) { return (false, nil) }
		
		// Check Relay State Set
		var json_obj: JSON? = JSON(parseJSON: response.response!)
		if (json_obj == nil) { return (false, nil) }
		
		json_obj = JSON(parseJSON: json_obj!["result"]["responseData"].stringValue)
		if (json_obj == nil) { return (false, nil) }
		
		let relay: Bool = json_obj!["system"]["set_relay_state"]["err_code"].boolValue
		
		return (false, relay)
	}
	
}
