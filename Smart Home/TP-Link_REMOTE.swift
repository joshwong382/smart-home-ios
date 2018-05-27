//
//  TP-Link_REMOTE.swift
//  Smart Home
//
//  Created by Joshua Wong on 14/5/2018.
//  Copyright © 2018 Joshua Wong. All rights reserved.
//

import UIKit
import SwiftyJSON

class TPLINK_REMOTE: Plug, Remote {
	
	var connection: JSON_CONN
	private var token: String
	private var domain: String
	private var devid: String
	
	init(_token: String, _domain: String, _devid: String) {
		print("Using TP-LINK Remote Plug")
		connection = JSON_CONN()
		token = _token
		domain = _domain
		devid = _devid
	}
	
	var has_led: Bool {
		get {
			// TPLINK API does have LEDs
			return true
		}
	}
	
	private func getURL() -> String {
		return domain + "/?token=" + token
	}
	
	private func getAPICalls(api: String) -> String? {
		let apiDict: [String : String] = [
			"ON": "{\\\"system\\\":{\\\"set_relay_state\\\":{\\\"state\\\":1}}}",
			"OFF": "{\\\"system\\\":{\\\"set_relay_state\\\":{\\\"state\\\":0}}}",
			"LED_ON": "{\\\"system\\\":{\\\"set_led_off\\\":{\\\"off\\\":0}}}",
			"LED_OFF": "{\\\"system\\\":{\\\"set_led_off\\\":{\\\"off\\\":1}}}",
			"INFO": "{\\\"system\\\":{\\\"get_sysinfo\\\":null}}"
		]
		
		var string: String? = nil
		if (apiDict[api] != nil) {
			string = """
			{"method":"passthrough", "params": {"deviceId": "
			""" + devid + """
			", "requestData": \"
			""" + apiDict[api]! + """
			\"}}
			"""
		}
		return string
	}
	
	// Update States
	
	// get state of power and status LED
	func getCommonStates() -> (pwr: Bool?, led: Bool?) {
		
		// Get Plug Info
		let response = connection.POST(url: getURL(), json: getAPICalls(api: "INFO")!)
		
		// Check Relay State
		var json_obj: JSON = JSON(parseJSON: response!)
		json_obj = JSON(parseJSON: json_obj["result"]["responseData"].stringValue)
		let pwr = json_obj["system"]["get_sysinfo"]["relay_state"].boolValue
		let led = json_obj["system"]["get_sysinfo"]["led_off"].boolValue
		
		return (pwr, led)
	}
	
	// JSON interface functions
	
	func getUpTime() -> (Bool, Int?, Int?, Int?) {
		let result = getSpecificState(match: "on_time")
		if (result == nil || result == "") { return (false, nil, nil, nil) }
		let on_time: Int = Int(result!)!
		var h, m, s: Int
		(h,m,s) = secToTime(seconds: on_time)
		//print(h,"h",m,"m",s,"s")
		return (true, h,m,s)
	}
	
	func getSpecificState(match: String) -> String? {
		// Get Plug Info
		let response = connection.POST(url: getURL(), json: getAPICalls(api: "INFO")!)
		
		// Check Relay State
		var json_obj: JSON = JSON(parseJSON: response!)
		let response_data = json_obj["result"]["responseData"].stringValue
		json_obj = JSON(parseJSON: response_data)
		let relay = json_obj["system"]["get_sysinfo"][match].stringValue
		
		return relay
	}
	
	func changeRelayState(state: Bool) -> Bool? {
		
		var req: String
		if (state) {
			req = "ON"
		}
		else {
			req = "OFF"
		}
		
		// Get Plug Info
		let response = connection.POST(url: getURL(), json: getAPICalls(api: req)!)
		
		// Check Relay State Set
		var json_obj: JSON = JSON(parseJSON: response!)
		json_obj = JSON(parseJSON: json_obj["result"]["responseData"].stringValue)
		let relay = json_obj["system"]["set_relay_state"]["err_code"].boolValue
		return relay
	}
	
	// change state of status LED
	func changeLEDState(state: Bool) -> Bool? {
		var req: String
		if (state) {
			req = "LED_ON"
		}
		else {
			req = "LED_OFF"
		}
		
		let response = connection.POST(url: getURL(), json: getAPICalls(api: req)!)
		
		// Check Relay State Set
		var json_obj: JSON = JSON(parseJSON: response!)
		json_obj = JSON(parseJSON: json_obj["result"]["responseData"].stringValue)
		let relay: Bool = json_obj["system"]["set_relay_state"]["err_code"].boolValue
		return relay
	}
	
}
