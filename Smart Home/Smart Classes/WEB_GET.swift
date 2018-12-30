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
	
	func save_to_file(api: SMART) -> [String : Any] {
		
		if let web_get_api = api as? WEB_GET {
			
			let url = web_get_api.get_info()
			let json: [String: Any] = [
				"type_id": type(of: self).type_id,
				"name": api.name,
				"url": url.absoluteString
			]
			return json
		}
		return [:]
	}
	
	func load_from_file(file: [String : Any]) -> SMART? {
		
		let url_string = file["url"] as? String
		if (url_string == nil) { print("Load From File Failed"); return nil }
		
		let url = URL(string: url_string!)
		if (url == nil) { print("Load From File Failed"); return nil }
		
		let name = file["name"] as? String
		
		let api = WEB_GET(url: url!)
		api.name = name ?? ""
		return api
	}
	
}

class WEB_GET_GETINFO: CUSTOM_GETAPI, LOGIN_UIOVERRIDES {
	
	init() {}
	
	func getAPI(firstText: String?, secondText: String?) -> (error: Bool, errstr: String, new_api: SMART?) {
		if (firstText == nil || secondText == nil) { return (true, "Please do not hack your way through.", nil) }
		
		if (!(secondText!.hasPrefix("http://") || secondText!.hasPrefix("https://"))) {
			return (true, "Please start your URL with http(s)://", nil)
		}
		
		let url = URL(string: secondText!)
		if (url == nil) { return (true, "Invalid URL", nil) }
		
		let api = WEB_GET(url: url!)
		let pwr = api.getPowerState()
		if (pwr.pwr == nil) { return (true, "Protocol Incorrect\n(Maybe you entered a wrong URL?)", nil) }
		
		api.name = firstText!
		return (false, "", api)
	}
	
	func field_overrides(firstField: inout UITextField, secondField: inout UITextField, fieldsRequirementLevel: inout FIELD_REQUIREMENTS) {
		firstField.placeholder = "Name your Device"
		secondField.placeholder = "URL (eg. http://example.com/led1)"
		secondField.isSecureTextEntry = false
		fieldsRequirementLevel = .BOTH_FIELDS
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
	var name: String {
		get {
			return privname ?? "";
		}
		
		set(_name) {
			privname = _name;
		}
	}
	
	var vendor_name: String {
		return "Web GET"
	}
	
	var type_id: UInt {
		return WEB_GET_PROTO.type_id
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
		print("Using HTTP GET Switch")
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
