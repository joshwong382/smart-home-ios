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
	
	enum API: String {
		case ON = "{\\\"system\\\":{\\\"set_relay_state\\\":{\\\"state\\\":1}}}"
		case OFF = "{\\\"system\\\":{\\\"set_relay_state\\\":{\\\"state\\\":0}}}"
		case LED_ON = "{\\\"system\\\":{\\\"set_led_off\\\":{\\\"off\\\":0}}}"
		case LED_OFF = "{\\\"system\\\":{\\\"set_led_off\\\":{\\\"off\\\":1}}}"
		case INFO = "{\\\"system\\\":{\\\"get_sysinfo\\\":null}}"
	}
	
	var connection: JSON_CONN
	private var token: String
	private var domain: String
	private var devid: String
	
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
	
	// Update States
	
	// get state of power and status LED
	func getCommonStates() -> (cancelled: Bool, pwr: Bool?, led: Bool?) {
		
		// Get Plug Info
		let response = connection.send_string(json: getAPICalls(api: API.INFO))
		
		// Check Cancelled
		if (response.cancelled) { return (true, nil, nil) }
		
		// Check Relay State
		if (response.response == nil) { return (false, nil, nil) }
		
		var json_obj: JSON = JSON(parseJSON: response.response!)
		json_obj = JSON(parseJSON: json_obj["result"]["responseData"].stringValue)
		let pwr = json_obj["system"]["get_sysinfo"]["relay_state"].boolValue
		let led = json_obj["system"]["get_sysinfo"]["led_off"].boolValue
		
		return (false, pwr, led)
	}
	
	// JSON interface functions
	
	func getUpTime() -> (cancelled: Bool, hour: Int?, min: Int?, sec: Int?) {
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
		// Get Plug Info
		let response = connection.send_string(json: getAPICalls(api: API.INFO))
		
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
		
		var req: API
		if (state) {
			req = API.ON
		}
		else {
			req = API.OFF
		}
		
		// Get Plug Info
		let response = connection.send_string(json: getAPICalls(api: req))
		
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
		var req: API
		if (state) {
			req = API.LED_ON
		}
		else {
			req = API.LED_OFF
		}
		
		let response = connection.send_string(json: getAPICalls(api: req))
		
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
