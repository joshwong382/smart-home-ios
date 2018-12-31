//
//  PlugVC.swift
//  Smart Home
//
//  Created by Joshua Wong on 11/5/2018.
//  Copyright © 2018 Joshua Wong. All rights reserved.
//

import UIKit
import SwiftyJSON
import Reachability

class PlugViewController: ReachabilityVCDelegate, UITextFieldDelegate, UIPopoverPresentationControllerDelegate, SmartVC {
	
	// Variables
	//var def_ip: String = "192.168.1.201"
	//var token: String = "75e5102d-A7mBwUeGJeO1Kqgopo6mrZ6"
	//var tplink_region: String = "https://aps1-wap.tplinkcloud.com"
	//var tplink_devid: String = "800657D0D18FB9E97BF5DFAAE62F903818A76421"
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
	
	var prev_connected = false
	var connected = false
	
	var relay_state: Bool? = nil
	var led_state: Bool? = nil
	var start_time: UInt64 = 0
	var on_time: Int = 0
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
			if let api_remote = api as? Remote_TokenHasExpiry {
				uptime_lbl.textColor = .black
				uptime_lbl.text = "Token Updated!"
				api_remote.token_update(token: newVal)
				updateCommonStates()
			}
		}
	}
	
	// Bring up the navigation controller
	@IBAction func sidebar_activated(_ sender: Any) {
		self.dismiss(animated: true, completion: nil)
	}

	// Send data to Segue Destinations
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		
		if (segue.destination is LoginViewController) {
			let destVC = segue.destination as! LoginViewController
			destVC.smart_api = api
			destVC.previousVC = segue.source
		}
	}
	
	override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
		super.dismiss(animated: flag, completion: completion)
	}
	
	override func viewDidLoad() {
		
		super.viewDidLoad()
		
		// Display Startup Logo
		//displayWait(begin: true)
		
		displayWait()
		
		// test networking
		setenv("CFNETWORK_DIAGNOSTICS", "0", 1)
		var override_remote = false
		
		// Create Reachability Delegate!
		
		
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
		
		if (api is Remote) {
			
			local_remote_SW.selectedSegmentIndex = 1
			url_txt.isHidden = true
			url_txt.isEnabled = false
			
		} else if let local_api = api as? Local {
			
			local_remote_SW.selectedSegmentIndex = 0
			url_txt.isHidden = false
			url_txt.isEnabled = false
			url_txt.text = local_api.connection.returnIP()! + ":" + String(local_api.connection.returnPort()!)
			
		} else {
			local_remote_SW.isHidden = true
		}
		
		local_remote_SW.isEnabled = false
		self.updateCommonStates()

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
		
		if (ui_relay_state == nil) {
			if (relay_state == nil) { displayError() }
			else {
				powerButton.isEnabled = true
				return
			}
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
						return
					}
				}
				
				if (success == true) {
					self.relay_state = !ui_relay_state!
					self.displayNormal()
					
				}
				self.powerButton.isEnabled = true
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
		url_txt.textColor = .black
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
	
	// UI display modules
	
	func displayWait(begin: Bool = false) {
		green_light.isHidden = true
		red_light.isHidden = true
		
		led_sw.isHidden = true
		led_lbl.isHidden = true
		
		powerButton.isEnabled = false
		uptime_lbl.textColor = .white
		if (!begin) {
			uptime_lbl.text = "Please Wait..."
		} else {
			uptime_lbl.text = "Smart Home\nBy Joshua Wong"
		}
		
		//local_remote_SW.isEnabled = false
	}
	
	func displayError(custom_error: String? = nil) {
		green_light.isHidden = true
		red_light.isHidden = true
		
		if (custom_error != nil) {
			led_sw.isHidden = true
			led_lbl.isHidden = true
			uptime_lbl.text = custom_error!
			
			// Update token!
			if (custom_error == "Error: Token Expired!") {
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
		
		//local_remote_SW.isEnabled = true
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
		
		//local_remote_SW.isEnabled = true
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
		if let remote_api = api as? Remote_TokenHasExpiry {
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
			(cancelled, self.relay_state, self.led_state) = self.api!.getCommonStates(timeout: 0)
			
			DispatchQueue.main.async {

				// Check if cancelled
				if (cancelled) { return }
				
				// If REMOTE, check token expiry
				if let api_remote = self.api as? Remote_TokenHasExpiry {
					if (api_remote.checkExpiry()) {
						// careful: custom error "Error: Token Expired!" is linked to the displayError function in some way
						self.displayError(custom_error: "Error: Token Expired!")
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
				
				var cancelled: Bool
				self.displayNormal()
				
				// Time
				var h,m: Int?
				(cancelled, h,m,_) = self.api!.getUpTime()
				
				if (cancelled) {
					self.displayError()
					self.updating_common_states = false
					return
				}
				
				if (h == nil || m == nil) {
					self.updating_common_states = false
					self.uptime_lbl.text = self.api!.name;
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
	
	override func reachabilityChanged(state: Reachability.Connection) {
		super.reachabilityChanged(state: state)
		if (state == .none) {
			displayError()
		}
	}
}
