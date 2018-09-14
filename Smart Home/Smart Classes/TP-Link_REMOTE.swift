//
//  TP-Link_REMOTE.swift
//  Smart Home
//
//  Created by Joshua Wong on 14/5/2018.
//  Copyright © 2018 Joshua Wong. All rights reserved.
//

import UIKit
import SwiftyJSON

class TPLINK_REMOTE_LOGIN {
	
	private var token: String = ""
	private var token_url: String = "https://wap.tplinkcloud.com"
	private var uuid: String = "760fec46-3711-49a7-9c26-c46fb436da76"
	
	init() {}
	
	func get_devices(username: String?, password: String) -> (error: Bool, devices: [(api_url: String, device_id: String)]?) {
		
		if (token == "") {
			return (true, nil)
		}
		
		let devices_conn = JSON_CONN(url: token_url + "?token=" + token)
		let request: JSON = [
			"method": "getDeviceList"
		]
		
		let response = devices_conn.send_string(json: request.rawString()!).response
		if (response == nil) { return (true, nil) }
		
		var json_obj: JSON = JSON(parseJSON: response!)
		
		// Check Error Code
		if (json_obj["error_code"].intValue != 0) {
			return (true, nil)
		}
		
		var devices = [(api_url: String, device_id: String)]()
		
		let devicelist = json_obj["result"]["deviceList"].arrayValue
		for device in devicelist {
			devices.append((api_url: device["appServerUrl"].stringValue, device_id: device["deviceid"].stringValue))
		}
		
		return (false, devices)
	}
	
	func token_from_login(username: String?, password: String) -> (error: Bool, token: String?) {
		
		let token_conn = JSON_CONN(url: token_url)
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
		
		return (false, potential_token)
	}
	
}

class TPLINK_REMOTE: TPLINK_REMOTE_LOGIN, Plug, Remote {
	
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
	
	init(_token: String, _domain: String, _devid: String) {
		print("Using TP-LINK Remote Plug")
		token = _token
		domain = _domain
		devid = _devid
		connection = JSON_CONN(url: _domain + "/?token=" + _token)
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
		
		// Check Token Expiry
		if (json_obj["msg"].stringValue == "Token expired") {
			token_expire = true
			print("Token Expired")
			return (false, nil, nil)
		}
		
		json_obj = JSON(parseJSON: json_obj["result"]["responseData"].stringValue)
		let pwr = json_obj["system"]["get_sysinfo"]["relay_state"].boolValue
		let led = json_obj["system"]["get_sysinfo"]["led_off"].boolValue
		
		return (false, pwr, led)
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
