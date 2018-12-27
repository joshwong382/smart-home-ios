//
//  WEB_GPIO.swift
//  Smart Home
//
//  Created by Joshua Wong on 3/9/2018.
//  Copyright © 2018 Joshua Wong. All rights reserved.
//

/*

WEB_GPIO
Test Request: { "command": "test" }
Test Response: { "test": "success"/"fail" }
On Request: { "state": "on" }
On Response: { "success": true/false }
Off Request: { "state": "off" }
Off Response: { "success": true/false }
Status Request: { "command": "status" }
Status Response: { "status": "on"/"off"/"fail" }

*/

import UIKit
import SwiftyJSON

class WEB_GPIO_PROTO: SMARTDB {
	
	required init() {}
	
	var type_name: String {
		return "Web API (POST)"
	}
	
	var obj_type: SMART.Type {
		return WEB_GPIO.self as SMART.Type
	}
	
	var obj_login: GET_API {
		return WEB_GPIO_GETINFO()
	}
	
	func save_to_file(api: SMART, name: String) -> [String : Any] {
		
		if let web_gpio_api = api as? WEB_GPIO {
			
			let url = web_gpio_api.get_info()
			let json: [String: Any] = [
				"type_id": type(of: self).type_id,
				"name": name,
				"url": url.absoluteString
			]
			return json
		}
		return [:]
	}
	
	func load_from_file(file: [String : Any]) -> (api: SMART?, name: String?) {
		
		let json = file as? [String: String]
		
		if (json == nil) {
			print("Load From File Failed")
			return (nil, nil)
		}
		
		if let url = URL(string: json!["url"]!) {
			if (json!["name"]!.count > 0) {
				let api = WEB_GPIO(_url: url)
				api.name = json!["name"]!
				return (api, api.name)
			}
		}

		print("Load From File Failed")
		return (nil, nil)
	}
	
}

class WEB_GPIO_GETINFO: CUSTOM_GETAPI, LOGIN_UIOVERRIDES {
	
	init() {}
	
	func getAPI(firstText: String?, secondText: String?) -> (error: Bool, new_api: SMART?, name: String?) {
		let url = URL(string: secondText!)
		if (url == nil) {
			return (true, nil, "Invalid URL")
		}
		
		// Check URL Response
		let test_conn = JSON_CONN(url: url!)

		var a = test_conn.send_string(json: "{\"command\":\"test\"}")
		if (a.cancelled) {
			a = test_conn.send_string(json: "{\"command\":\"test\"}")
		}
		
		if (a.response == nil) {
			return (true, nil, "Error: Unable to Connect")
		}
		let json = JSON(parseJSON: a.response!)
		if (json["test"] == "success") {
			return (false, WEB_GPIO(_token: "", _url: url!.absoluteString), firstText!)
		}
		return (true, nil, "Error: Invalid Response")

	}
	
	func field_overrides(firstField: inout UITextField, secondField: inout UITextField, fieldsRequirementLevel: inout UInt) {
		firstField.placeholder = "Name your Device"
		secondField.placeholder = "URL"
		secondField.isSecureTextEntry = false
		fieldsRequirementLevel = 2
	}
}

class WEB_GPIO: WEB_GPIO_GETINFO, Switch, Remote_SingleDevice {
	
	var connection: JSON_CONN?
	
	private var privname: String? = nil;
	var name: String? {
		get {
			return privname;
		}
		
		set(_name) {
			privname = _name;
		}
	}
	
	var vendor_name: String {
		return "Web POST"
	}
	
	var type_id: UInt {
		return WEB_GPIO_PROTO.type_id
	}
	
	required init?(_token: String, _url: String) {
		connection = JSON_CONN(url: _url)
		if (connection == nil) {
			return nil
		}
	}
	
	required init(_url: URL) {
		connection = JSON_CONN(url: _url)
	}
	
	func get_info() -> URL {
		return connection!.getURL()
	}
	
	func getPowerState() -> (cancelled: Bool, pwr: Bool?) {
		let power = connection!.send_string(json: "{\"command\":\"status\"}")
		
		if (power.cancelled) {
			return (true, nil)
		}
		
		if (power.response == nil) {
			return (false, nil)
		}
		
		let json = JSON(parseJSON: power.response!)
		
		let status = json["status"].stringValue
		
		if (status == "on") {
			return (false, true)
		}
		
		if (status == "off") {
			return (false, false)
		}
		
		return (false, nil)
	}
	
	func changeRelayState(state: Bool) -> (cancelled: Bool, success: Bool?) {
		let response: (cancelled: Bool, response: String?)
		
		if (state) {
			response = connection!.send_string(json: "{\"command\": \"on\" }")
		} else {
			response = connection!.send_string(json: "{ \"command\": \"off\" }")
		}
		
		if (response.cancelled) {
			return (true, nil)
		}
		
		if (response.response == nil) {
			return (false, nil)
		}
		
		let json = JSON(parseJSON: response.response!)
		
		let status = json["state"].stringValue
		
		if (status == "on" && state) {
			return (false, true)
		}
		
		if (status == "off" && !state) {
			return (false, true)
		}
		
		return (false, false)
	}
}

