//
//  IFTTT.swift
//  Smart Home
//
//  Created by Joshua Wong on 6/8/2018.
//  Copyright © 2018 Joshua Wong. All rights reserved.
//

import UIKit
import SwiftyJSON

class IFTTT_PROTO: SMARTDB {

	required init() {}

	var type_name: String {
		return "IFTTT WebHooks"
	}
	
	var obj_type: SMART.Type {
		return IFTTT.self as SMART.Type
	}
	
	var obj_login: GET_API {
		return IFTTT_GETTOKEN()
	}
	
	func save_to_file(api: SMART, name: String) -> [String : Any] {
		
		if let ifttt_api = api as? IFTTT {
			
			let info = ifttt_api.get_info()
			let json: [String: Any] = [
				"type_id": type(of: self).type_id,
				"name": name,
				"info": [
					"token": info.token,
					"event": info.event
				]
			]
			return json
		}
		return [:]
	}
	
	func load_from_file(file: [String : Any]) -> (api: SMART?, name: String?) {
		
		let info = file["info"] as? [String : String]
		if (info != nil) {
			let token = info!["token"]
			let event = info!["event"]
			if (token == nil || event == nil) {
				return (nil, nil)
			}
			let api = IFTTT(_token: token!, _url: event!)
			let name = file["name"] as? String
			if (name == nil) {
				return (nil, nil)
			}
			return (api, name)
		}
		return (nil, nil)
	}
	
}

class IFTTT_GETTOKEN: CUSTOM_GETAPI, LOGIN_UIOVERRIDES {
	
	init() {}
	
	var connection: JSON_CONN?
	var token: String = ""
	var event: String = ""
	let url_1: String = "https://maker.ifttt.com/trigger/"
	let url_2: String = "/with/key/"
	var url: String {
		return url_1 + event + url_2 + token
	}
	
	func field_overrides(firstField: inout UITextField, secondField: inout UITextField, fieldsRequirementLevel: inout UInt) {
		firstField.placeholder = "Event Name"
		secondField.placeholder = "API Key"
		secondField.isSecureTextEntry = false
	}
	
	func getAPI(firstText: String?, secondText: String?) -> (error: Bool, new_api: SMART?, name: String?) {
		
		self.token = secondText!
		self.event = firstText!
		
		guard let _connection = JSON_CONN(url: url) else {
			return (true, nil, "Error: Incorrect Information")
		}
		connection = _connection
		
		let result = check_run()
		
		if (result.success == true) {
			// URL is the event
			let api = IFTTT(_token: token, _url: event)
			return (false, api, event)
			
		} else if (result.msg != nil) {
			return (true, nil, result.msg!)
			
		} else {
			return (true, nil, "Error: Cannot Connect")
		}
	}
	
	func check_run() -> (cancelled: Bool, success: Bool?, msg: String?) {
		let result = connection!.send_string(json: "")
		
		if (result.cancelled) {
			return (true, nil, nil)
		}
		
		if (result.response == nil) {
			return (false, false, nil)
		}
		
		// Handle Error
		let json = JSON(parseJSON: result.response!)
		let error = JSON(parseJSON: json["errors"].stringValue)
		if let msg = error["message"].string {
			return (false, false, ("IFTTT Error: " + msg))
		}
		
		if (result.response!.range(of: ("Congratulations! You've fired the " + event + " event")) != nil) {
			return (false, true, nil)
		}
		
		return (false, false, nil)
	}
}

class IFTTT: IFTTT_GETTOKEN, Trigger, Remote_SingleDevice {
	
	var vendor_name: String {
		return "IFTTT"
	}
	
	var type_id: UInt {
		return IFTTT_PROTO.type_id
	}
	
	// URL is the event name
	required init?(_token: String, _url: String) {
		super.init()
		token = _token
		event = _url
		guard let _connection = JSON_CONN(url: url_1 + event + url_2 + token) else {
			return nil
		}
		connection = _connection
	}
	
	func get_info() -> (token: String, event: String) {
		return (token, event)
	}
	
	func run() -> (cancelled: Bool, success: Bool?) {
		
		let run = check_run()
		
		if (run.cancelled) {
			return (true, nil)
		}
		
		if (run.success != true) {
			if (run.msg != nil) {
				print(run.msg!)
			}
			return (false, false)
		}

		return (false, true)
	}
}
