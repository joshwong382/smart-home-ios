//
//  RPI.swift
//  Smart Home
//
//  Created by Joshua Wong on 3/9/2018.
//  Copyright © 2018 Joshua Wong. All rights reserved.
//

import UIKit
import SwiftyJSON

class RPI_PROTO: SMARTDB {
	
	required init() {}
	
	var type_name: String {
		return "GPIO (Web POST)"
	}
	
	var obj_type: SMART.Type {
		return RPI.self as SMART.Type
	}
	
	var obj_login: GET_API {
		return RPI_GETINFO()
	}
	
	func save_to_file(api: SMART, name: String) -> [String : Any] {
		
		if let rpi_api = api as? RPI {
			
			let info = rpi_api.get_info()
			let json: [String: Any] = [
				"type_id": type(of: self).type_id,
				"name": name,
				"info": [
					
				]
			]
			return json
		}
		return [:]
	}
	
	func load_from_file(file: [String : Any]) -> (api: SMART?, name: String?) {
		
		let info = file["info"] as? [String : String]
		if (info != nil) {
			
		}
		return (nil, nil)
	}
	
}

class RPI_GETINFO: CUSTOM_GETAPI, LOGIN_UIOVERRIDES {
	
	init() {}
	
	func getAPI(firstText: String?, secondText: String?) -> (error: Bool, new_api: SMART?, name: String?) {
		let url = URL(string: firstText!)
		if (url == nil) {
			return (true, nil, "Invalid URL")
		}
		return (false, nil, nil)
	}
	
	func field_overrides(firstField: inout UITextField, secondField: inout UITextField, fieldsRequirementLevel: inout UInt) {
		firstField.placeholder = "URL"
		fieldsRequirementLevel = 1
		secondField.placeholder = "JSON Auth (obj.auth)"
	}
}

class RPI: RPI_GETINFO, Switch, Remote_SingleDevice {
	
	var connection: JSON_CONN?
	
	var vendor_name: String {
		return "Raspberry Pi"
	}
	
	var type_id: UInt {
		return RPI_PROTO.type_id
	}
	
	var has_led: Bool {
		return false
	}
	
	required init?(_token: String, _url: String) {
		
	}
	
	func get_info() {
	
	}
	
	func getPowerState() -> (cancelled: Bool, pwr: Bool?) {
		let power = connection!.send_string(json: "")
		return (false, nil)
	}
	
	func changeRelayState(state: Bool) -> (cancelled: Bool, success: Bool?) {
		return (false, nil)
	}
}

