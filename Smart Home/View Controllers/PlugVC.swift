//
//  PlugVC.swift
//  Smart Home
//
//  Created by Joshua Wong on 11/5/2018.
//  Copyright © 2018 Joshua Wong. All rights reserved.
//

import UIKit
import Reachability
import SwiftyJSON

class PlugViewController: UIViewController, UITextFieldDelegate, UIPopoverPresentationControllerDelegate, SmartVC {
	
	// Name this ViewController
	let VCName = "PlugVC"
	
	// Variables
	var def_ip: String = "192.168.1.201"
	var token: String = "75e5102d-A7mBwUeGJeO1Kqgopo6mrZ6"
	var tplink_region: String = "https://aps1-wap.tplinkcloud.com"
	var tplink_devid: String = "800657D0D18FB9E97BF5DFAAE62F903818A76421"
	var api: Plug? = nil
	
	// Connect UI element with code
	@IBOutlet weak var darkBlueBG: UIImageView!
	@IBOutlet weak var powerButton: UIButton!
	@IBOutlet weak var green_light: UIImageView!
	@IBOutlet weak var red_light: UIImageView!
	@IBOutlet weak var led_lbl: UILabel!
	@IBOutlet weak var led_sw: UISwitch!
	@IBOutlet weak var uptime_lbl: UILabel!
	@IBOutlet weak var url_txt: UITextField!
	@IBOutlet weak var local_remote_SW: UISegmentedControl!
	@IBOutlet weak var sidebar: UIButton!
	
	// Reachability
	let reachability = Reachability()!
	
	var prev_connected = false
	var connected = false
	
	var relay_state: Bool? = nil
	var led_state: Bool? = nil
	var start_time: UInt64 = 0
	var on_time: Int = 0
	var reachability_init = false
	var updating_common_states = false
	
	var token_updating_bool = false
	var token_updating: Bool {
		get {
			return token_updating_bool
		}
		set(newVal) {
			token_updating_bool = newVal
		}
	}
	var new_token: String {
		get {
			return ""
		}
		set(newVal) {
			uptime_lbl.textColor = UIColor.black
			uptime_lbl.text = "Token Updated!"
			token = newVal
			updateCommonStates()
		}
	}
	
	// Bring up the navigation controller
	@IBAction func sidebar_activated(_ sender: Any) {
		self.performSegue(withIdentifier: "PopUpSegue", sender: self)
	}

	// Send data to SidePopVC
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if (segue.destination is SidePopViewController) {
			let destVC = segue.destination as! SidePopViewController
			destVC.previousView = VCName
		}
		
		if (segue.destination is LoginViewController) {
			let destVC = segue.destination as! LoginViewController
			destVC.smart_api = api
			destVC.previousVC = segue.source
		}
	}
	
	override func viewDidLoad() {
		
		super.viewDidLoad()
		displayWait(begin: true)
		
		// test networking
		setenv("CFNETWORK_DIAGNOSTICS", "0", 1)
		var override_remote = false
		
		 /*-----------------------------------------------
		 /
		 /	REACHABILITY for DEFAULT LOCAL/REMOTE SWITCH
		 /
		 / ---------------------------------------------*/
		
		// Check reachability and determine local or remote
		if (reachability.connection == .wifi) { local_remote_SW.selectedSegmentIndex = 0 }	// WiFi
		else if (reachability.connection == .cellular) {
			// Cellular
			local_remote_SW.selectedSegmentIndex = 1
			override_remote = true
		}
		
		// Default Plug Type and create API class object
		local_remote_switched_main(override: override_remote, init_startup: true)
		
		// keyboard
		url_txt.delegate = self
		
		green_light.isHidden = true
		red_light.isHidden = true
		darkBlueBG.isHidden = false
		//url_txt.text = conn_ip + ":" + conn_port
		
		startMonitoring()
	}
	
	// Override screen touch
	override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?){
		updateCommonStates()
		super.touchesBegan(touches, with: event)
	}
	
	/*-----------------------------------------------
	/
	/	LOCAL/REMOTE SWITCH + UPDATE CONNECTION DETAILS
	/
	/ ---------------------------------------------*/
	
	// Creates a new connection (override: overrides to remote connection)
	func local_remote_switched_main(override: Bool = false, init_startup: Bool = false) {

		var local_ip: String? = nil
		let selected_index = local_remote_SW.selectedSegmentIndex
		if (selected_index == 0 && !override) {
			url_txt.isHidden = false
			url_txt.isEnabled = true
			
			// IP is get from update_connection_text
			local_ip = update_connection_text()
			
			// Check IP Validity
			if (local_ip == nil) {
				api = nil
				displayError()
				return
			}
			
			// Check if previous API is NULL and display WAIT
			if (api == nil && init_startup == false) {
				displayWait()
			}
			
			api = TPLINK_LOCAL(ip: local_ip!)
			
			updateCommonStates()
			prev_connected = connected
		}
		else {
			url_txt.isHidden = true
			url_txt.isEnabled = false
			DispatchQueue.global().async {
				self.api = TPLINK_REMOTE(_token: self.token, _domain: self.tplink_region, _devid: self.tplink_devid)
				
				DispatchQueue.main.async {
					self.updateCommonStates()
					self.prev_connected = self.connected
				}
			}
		}

	}
	
	@IBAction func local_Remote_Switched(_ sender: Any) {
		displayWait()
		local_remote_switched_main()
	}
	
	@IBAction func powerPressed(_ sender: Any) {
		
		// Disable switch while operating
		powerButton.isEnabled = false
		
		// We don't want any accidental state change
		let ui_relay_state = relay_state
		updateCommonStates()
		
		if (ui_relay_state == nil) {
			if (relay_state == nil) { displayError() }
			else { return }
		}
		
		// If update state just changed back online don't do anything
		DispatchQueue.global().async {
			var cancelled: Bool
			var success: Bool?
			(cancelled, success) = self.api!.changeRelayState(state: !ui_relay_state!)
			
			DispatchQueue.main.async {
				
				// Check if cancelled
				if (cancelled) { return }
				
				// Check if disconnected
				if (self.connected && self.prev_connected) {
					if (success == nil) {
						self.displayError()
					}
				}
				self.updateCommonStates()
			}
		}
	}
	
	@IBAction func led_switched(_ sender: Any) {
		
		// Disable switch while operating
		led_sw.isEnabled = false
		
		let is_on = led_sw.isOn
		DispatchQueue.global().async {
			
			// Change LED state
			var cancelled: Bool
			var success: Bool?
			(cancelled, success) = self.api!.changeLEDState(state: is_on)
			
			DispatchQueue.main.async {
				
				// Check if cancelled
				if (cancelled) { return }
				
				// Update UI
				if (success == nil) {
					self.displayError()
				} else {
					
					// Confirm LED state
					self.updateCommonStates()
				}
			}
		}
		
		// Re-enable switch
		led_sw.isEnabled = true
	}
	
	/*-----------------------------------------------
	/
	/	UI CHANGES
	/
	/ ---------------------------------------------*/
	
	@IBAction func urltxt_editing_start(_ sender: Any) {
		url_txt.textColor = UIColor.black
		if (url_txt.text == "Invalid IP or port") {
			url_txt.text = ""
		}
	}
	
	// URL TEXT EDIT ENDED
	func textFieldShouldReturn(_ scoreText: UITextField) -> Bool {
		self.view.endEditing(true)
		
		// Switch the Conection
		local_remote_switched_main()
		return true
	}
	
	func check_urltext_valid() -> IP_CONN {
		
		var connection: IP_CONN
		// Check valid URL
		if (url_txt.text == nil) {
			connection = IP_CONN(string: def_ip)
		} else {
			connection = IP_CONN(string: url_txt.text!)
		}
		return connection
	}
	
	func update_connection_text() -> String? {
		let connection = check_urltext_valid()
		
		if (connection.isValid()) {
			url_txt.text = connection.returnIP()! + ":" + String(connection.returnPort()!)
		} else {
			url_txt.textColor = UIColor.red
			url_txt.text = "Invalid IP or port"
		}
		
		return connection.returnIP()
	}
	
	// UI display modules
	
	func displayWait(begin: Bool = false) {
		green_light.isHidden = true
		red_light.isHidden = true
		
		led_sw.isHidden = true
		led_lbl.isHidden = true
		
		powerButton.isEnabled = false
		uptime_lbl.textColor = UIColor.white
		if (!begin) {
			uptime_lbl.text = "Please Wait..."
		} else {
			uptime_lbl.text = "Smart Home\nBy Joshua Wong"
		}
		
		local_remote_SW.isEnabled = false
	}
	
	func displayError(custom_error: ERRMSG? = nil) {
		green_light.isHidden = true
		red_light.isHidden = true
		
		if (custom_error != nil) {
			led_sw.isHidden = true
			led_lbl.isHidden = true
			uptime_lbl.text = custom_error!.rawValue
			
			// Update token!
			if (custom_error == .token_expired) {
				token_updating = true
				DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1), execute: {
					self.performSegue(withIdentifier: "LoginSegue", sender: self)
				})
			}
			
		}
		else if (api == nil) {
			led_sw.isHidden = true
			led_lbl.isHidden = true
			uptime_lbl.text = "Error: Invalid Connection!"
		}
		else if (api?.has_led)! {
			led_sw.isHidden = true
			led_lbl.isHidden = true
			uptime_lbl.text = "Error: Cannot Connect!"
		}
		
		uptime_lbl.textColor = UIColor.red
		powerButton.isEnabled = false
		prev_connected = connected
		connected = false
		
		local_remote_SW.isEnabled = true
	}
	
	func displayNormal() {
		if (relay_state!) { green_light.isHidden = false; red_light.isHidden = true }
		else { red_light.isHidden = false; green_light.isHidden = true }
		
		if (api?.has_led)! {
			led_lbl.isHidden = false
			led_sw.isHidden = false
			led_sw.setOn(!led_state!, animated: false)
		}
		
		powerButton.isEnabled = true
		uptime_lbl.textColor = UIColor.white
		prev_connected = connected
		connected = true
		
		local_remote_SW.isEnabled = true
	}

	/*-----------------------------------------------
	/
	/	STATUS UPDATES + API FUNCTIONS
	/
	/ ---------------------------------------------*/
	
	// Include displaying Uptime
	func updateCommonStates() {
		
		// Check connection first
		if (reachability.connection == .none) {
			displayError()
			return
		}
		
		// Check if it was previously updating
		if (updating_common_states) {
			return
		}
		
		// Check if token has expired
		if let remote_api = api as? Remote {
			if (remote_api.checkExpiry()) {
				if (token_updating) {
					return
				}
			}
		}
		
		// Real Update
		updating_common_states = true
		let serialQueue = DispatchQueue(label: "UPDATE_STATUS")
		serialQueue.async {

			var cancelled: Bool
			(cancelled, self.relay_state, self.led_state) = self.api!.getCommonStates()
			
			DispatchQueue.main.async {

				// Check if cancelled
				if (cancelled) { return }
				
				// If REMOTE, check token expiry
				if let api_remote = self.api as? Remote {
					if (api_remote.checkExpiry()) {
						self.displayError(custom_error: .token_expired)
						self.updating_common_states = false
						return
					}
				}
				
				// Check connection
				if (self.relay_state == nil || self.led_state == nil) {
					self.displayError()
					self.updating_common_states = false
					return
				}
				
				var valid = true
				self.displayNormal()
				
				// Time
				var h,m: Int?
				(valid, h,m,_) = self.api!.getUpTime()
				if (!valid) {
					self.displayError()
					self.updating_common_states = false
					return
				}
				let hS = twoDigitInt(int: h!)
				let mS = twoDigitInt(int: m!)
				self.uptime_lbl.text = "Uptime: \(hS)h \(mS)m"
				self.updating_common_states = false
				return
				
			}
		}
	}

	// Network Reachability Functions
	
	@objc func reachabilityChanged(notification: Notification) {
		if (!reachability_init) { reachability_init = true }
		else {
			let reachability = notification.object as! Reachability
			switch reachability.connection {
			case .none:
				//debugPrint("Network became unreachable")
				displayError()
			case .wifi:
				print("On WiFi")
				updateCommonStates()
			case .cellular:
				print("On Cellular")
				updateCommonStates()
			}
		}
	}
	
	func startMonitoring() {
		NotificationCenter.default.addObserver(self,
											   selector: #selector(self.reachabilityChanged),
											   name: Notification.Name.reachabilityChanged,
											   object: reachability)
		do{
			try reachability.startNotifier()
		} catch {
			debugPrint("Could not start reachability notifier")
		}
	}
}

// Useful Functions

func twoDigitInt(int: Int) -> String {
	if (int < 10) { return ("0" + String(int)) }
	else { return String(int) }
}

func secToTime (seconds : Int) -> (Int, Int, Int) {
	return (seconds / 3600, (seconds % 3600) / 60, (seconds % 3600) % 60)
}

// Extensions

extension StringProtocol {
	var ascii: [UInt32] {
		return unicodeScalars.filter{$0.isASCII}.map{$0.value}
	}
}
extension Character {
	var ascii: UInt32? {
		return String(self).unicodeScalars.filter{$0.isASCII}.first?.value
	}
}

extension String {
	func toJSON() -> Any? {
		guard let data = self.data(using: .utf8, allowLossyConversion: false) else { return nil }
		return try? JSONSerialization.jsonObject(with: data, options: .mutableContainers)
	}
}
