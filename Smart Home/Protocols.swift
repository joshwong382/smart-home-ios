//
//  Protocols.swift
//  Smart Home
//
//  Created by Joshua Wong on 15/5/2018.
//  Copyright © 2018 Joshua Wong. All rights reserved.
//

import UIKit
import SwiftyJSON

// Connection Protocols follow Connection
protocol Connection {
	var timeout: Double {
		get
	}
}

/****************************
*
* SMART HOME PROTOCOL DATABASE
*
****************************/

// For Device List
protocol SMARTDB: class {
	
	init()
	
	// Type ID (also found in DataManager class)
	static var type_id: UInt {
		get
	}
	
	// Device Type Name
	var type_name: String {
		get
	}
	// API object that will be created
	var obj_type: SMART.Type {
		get
	}
	// The Login Object before API object
	var obj_login: GET_API {
		get
	}
	// Save this object to file
	func save_to_file(api: SMART) -> [String: Any]
	// Load this object from file
	func load_from_file(file: [String: Any]) -> SMART?
}

extension SMARTDB {
	
	static var type_id: UInt {
		
		let proto = self.init()
		
		// No Error Handler but is intended.
		return protocols.findTypeID(db: proto)!
	}
	
}

// Database class for protocols
class proto_db {
	
	private var protos = [(db: SMARTDB, typeid: UInt)]()
	
	init() {
		// Display Order
		protos.append((db: TPLINK_PROTO_LOCAL() as SMARTDB, typeid: 0))
		protos.append((db: TPLINK_PROTO_REMOTE() as SMARTDB, typeid: 1))
		protos.append((db: IFTTT_PROTO() as SMARTDB, typeid: 2))
		protos.append((db: WEB_GPIO_PROTO() as SMARTDB, typeid: 3))
		protos.append((db: WEB_GET_PROTO() as SMARTDB, typeid: 4))
	}
	
	func findTypeID(db: SMARTDB) -> UInt? {
		let index = protos.first(where: { db.type_name == $0.db.type_name })?.typeid
		if (index == nil) {
			return nil
		} else {
			return index!
		}
	}
	
	func getProtoByOrder(index: Int) -> SMARTDB? {
		if (index >= 0 && index < protos.count) {
			return protos[index].db
		}
		else {
			return nil
		}
	}
	
	func getProtoByTypeID(id: Int) -> SMARTDB? {
		if (id >= 0 && id < protos.count) {
			return protos.first(where: { id == $0.typeid })?.db
		}
		else {
			return nil
		}
	}
	
	func getCount() -> Int {
		return protos.count
	}
	
	func get_apitype_by_order(index: Int) -> (type_name: String, obj_type: SMART.Type, obj_login: GET_API)? {
		let proto = getProtoByOrder(index: index)
		if (proto == nil) { return nil }
		else { return (type_name: proto!.type_name, obj_type: proto!.obj_type, obj_login: proto!.obj_login) }
	}
}

/****************************
 *
 * CONNECTION PROTOCOLS
 *
 ****************************/

// Local/Remote APIs follow these protocols
protocol Local: GET_API {
	var connection: IP_CONN {
		get set
	}
}

protocol Remote: GET_API {
	var connection: JSON_CONN? {
		get set
	}
}

protocol Remote_MultiDevice: Remote {
	init?(_token: String, _url: String, _devid: String)
}

protocol Remote_SingleDevice: Remote {
	init?(_token: String, _url: String)
}

protocol Remote_TokenHasExpiry: Remote {
	func checkExpiry() -> Bool
	func token_update(token: String)
}

/****************************
*
* GET API PROTOCOLS (AUTHENTICATION)
*
****************************/

protocol LOGIN_UIOVERRIDES: GET_API {
	func field_overrides(firstField: inout UITextField, secondField: inout UITextField, fieldsRequirementLevel: inout FIELD_REQUIREMENTS)
}

// GET_API to identify all login methods for LoginVC
protocol GET_API {}

// The login method is custom, just send raw strings and return full api object
protocol CUSTOM_GETAPI: GET_API {
	// Name can also be error message
	func getAPI(firstText: String?, secondText: String?) -> (error: Bool, errstr: String, new_api: SMART?)
}

// This login uses Tokens/API Keys to login
protocol TOKEN: GET_API {
	func check_token(token: String) -> (error: Bool, token: String)
}

// This login uses Tokens and requires a Username/Password Login Combo to obtain that token
protocol TOKEN_LOGIN: TOKEN {
	// TOKEN can also be error message
	func token_from_login(username: String?, password: String) -> (error: Bool, token: String?)
}

// This method gets an available device from a Token/API Key
protocol TOKEN_SINGLEDEVICE: TOKEN {
	func getDevice() -> (error: Bool, url: String, name: String)
}

// This method gets all available devices from a Token/API Key
protocol TOKEN_MULTIDEVICE: TOKEN {
	func get_devices() -> (error: Bool, devices: [(api_url: String, device_id: String, alias: String)]?)
}

/****************************
*
* SMART HOME (API) PROTOCOLS
*
****************************/

// Base Smart Home Protocol
protocol SMART {
	var vendor_name: String {
		get
	}
	
	var type_id: UInt {
		get
	}
	
	var name: String {
		get set
	}
}

protocol PWM_DEV: SMART {
	func getState() -> (cancelled: Bool, state: Int?)
	func changeState(state: Int) -> (cancelled: Bool, success: Bool?)
}

protocol Switch: SMART { 
	
	// Get State
	func getPowerState() -> (cancelled: Bool, pwr: Bool?)
	
	// Change State
	func changeRelayState(state: Bool) -> (cancelled: Bool, success: Bool?)
}

protocol Plug: Switch {
	
	var has_led: Bool {
		get
	}
	
	// get unit turned on time
	func getUpTime() -> (cancelled: Bool, hour: Int?, min: Int?, sec: Int?)
	
	// get another states (see SMART protocol)
	func getSpecificState(match: String) -> (cancelled: Bool, state: String?)
	
	// Change State (see Switch protocol)
	//func changeRelayState(state: Bool) -> (cancelled: Bool, success: Bool?)
	
	// get state of power and status LED
	func getCommonStates() -> (cancelled: Bool, pwr: Bool?, led: Bool?)
	
	// change state of status LED
	func changeLEDState(state: Bool) -> (cancelled: Bool, success: Bool?)
	
}

protocol Trigger: SMART {
	func run() -> (cancelled: Bool, success: Bool?)
}

/****************************
*
* VIEW CONTROLLER PROTOCOLS
*
****************************/

protocol SmartVC {
	var token_updating: Bool {
		get set
	}
	
	var new_token: String {
		get set
	}
}
