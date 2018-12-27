//
//  WEB_GET.swift
//  Smart Home
//
//  Created by Joshua Wong on 26/12/2018.
//  Copyright © 2018 Joshua Wong. All rights reserved.
//

/*
ON:		URL:/on
OFF:	URL:/off
STATUS:	URL:/status
*/

import UIKit
import SwiftyJSON

class WEB_GET_PROTO: SMARTDB {
	
	required init() {}
	
	var type_name: String {
		return "Web API (GET)"
	}
	
	var obj_type: SMART.Type {
		return WEB_GET.self as SMART.Type
	}
	
	var obj_login: GET_API {
		return WEB_GET_GETINFO()
	}
	
	func save_to_file(api: SMART, name: String) -> [String : Any] {
		
		if let web_get_api = api as? WEB_GET {
			
			let url = web_get_api.get_info()
			let json: [String: Any] = [
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
			return (nil, nil)
		}
		
		if let url = URL(string: json!["url"]!) {
			if (json!["name"]!.count > 0) {
				let api = WEB_GET(url: url)
				api.name = json!["name"]!
				return (api, api.name)
			}
		}
		
		return (nil, nil)
	}
	
}

class WEB_GET_GETINFO: CUSTOM_GETAPI, LOGIN_UIOVERRIDES {
	
	init() {}
	
	func getAPI(firstText: String?, secondText: String?) -> (error: Bool, new_api: SMART?, name: String?) {
		if (firstText == nil || secondText == nil) { return (true, nil, nil) }
		
		let url = URL(string: secondText!)
		if (url == nil) { return (true, nil, "Invalid URL") }
		
		let api = WEB_GET(url: url!)
		let pwr = api.getPowerState()
		if (pwr.pwr == nil) { return (true, nil, "Protocol Incorrect\n(Maybe you entered a wrong URL?)") }
		
		return (false, api, firstText!)
	}
	
	func field_overrides(firstField: inout UITextField, secondField: inout UITextField, fieldsRequirementLevel: inout UInt) {
		firstField.placeholder = "Name your Device"
		secondField.placeholder = "URL (eg. http://example.com/led1)"
		secondField.isSecureTextEntry = false
		// No Fields Required = 0
		// First Field Required = 1
		// Both Fields Required = 2
		fieldsRequirementLevel = 2
	}
}

class WEB_GET: WEB_GET_GETINFO, Switch {
	
	private var base_url: URL
	
	private var on_get: URL {
		get {
			return base_url.appendingPathComponent("/on")
		}
	}
	
	private var off_get: URL {
		get {
			return base_url.appendingPathComponent("/off")
		}
	}
	private var status_get: URL {
		get {
			return base_url.appendingPathComponent("/status")
		}
	}
	
	private var privname: String? = nil
	var name: String? {
		get {
			return privname;
		}
		
		set(_name) {
			privname = _name;
		}
	}
	
	var vendor_name: String {
		return "Web GET"
	}
	
	var type_id: UInt {
		return WEB_GPIO_PROTO.type_id
	}
	
	// Functions
	required init(url: URL) {
		var temp = url.absoluteString
		
		// remove last "/"
		if (temp.suffix(1) == "/") {
			temp.removeLast()
			base_url = URL(string: temp)!
		} else {
			base_url = url
		}
	}
	
	func get_info() -> URL {
		return base_url
	}
	
	func getPowerState() -> (cancelled: Bool, pwr: Bool?) {
		var result = JSON_CONN.do_GET(url: status_get)
		
		if (result == nil) { return (false, nil) }
		result = result!.trimmingCharacters(in: .newlines)
		result = result!.trimmingCharacters(in: .whitespaces)
		
		if (result == "0") {
			return (false, false)
		}
		
		if (result == "1") {
			return (false, true)
		}
		
		return (false, nil)
	}
	
	func changeRelayState(state: Bool) -> (cancelled: Bool, success: Bool?) {
		
		// Get URL
		var url: URL
		if (state) {
			url = on_get
		} else {
			url = off_get
		}
		
		// send request
		let result = JSON_CONN.do_GET(url: url)
		
		// check result
		if (result == nil) { return (false, nil) }
		if (result == "") { return (false, nil) }
		return (false, true)
	}
}
