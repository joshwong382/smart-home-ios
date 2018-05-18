//
//  PlugView.swift
//  Smart Home
//
//  Created by Joshua Wong on 11/5/2018.
//  Copyright © 2018 Joshua Wong. All rights reserved.
//

import UIKit
import Reachability
import SwiftyJSON

var def_ip: String = "192.168.1.201"
var connection: Connection = Connection(string: def_ip)
var api: Plug?

class ViewController: UIViewController, UITextFieldDelegate {
	
	// Connect UI element with code
	@IBOutlet weak var darkBlueBG: UIImageView!
	@IBOutlet weak var powerButton: UIButton!
	@IBOutlet weak var green_light: UIImageView!
	@IBOutlet weak var red_light: UIImageView!
	@IBOutlet weak var led_lbl: UILabel!
	@IBOutlet weak var led_sw: UISwitch!
	@IBOutlet weak var uptime_lbl: UILabel!
	@IBOutlet weak var url_txt: UITextField!
	
	var prev_connected = false
	var connected = false
	
	var relay_state: Bool? = nil
	var led_state: Bool? = nil
	var start_time: UInt64 = 0
	var on_time: Int = 0
	
	override func viewDidLoad() {
		
		super.viewDidLoad()
		
		// Define Plug Type
		api = TPLINK()
		
		// Check if LED is available
		if !(api?.has_led)! {
			led_lbl.isHidden = true
			led_sw.isHidden = true
			led_sw.isEnabled = false
		}
		
		// keyboard
		url_txt.delegate = self
		
		green_light.isHidden = true
		red_light.isHidden = true
		darkBlueBG.isHidden = false
		//url_txt.text = conn_ip + ":" + conn_port
		
		startMonitoring()
		updateCommonStates()
		prev_connected = connected
		
	}
	
	// Override screen touch
	override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?){
		updateCommonStates()
		super.touchesBegan(touches, with: event)
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
			let success = api!.changeRelayState(state: !ui_relay_state!)
			
			DispatchQueue.main.async {
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
			let success: Bool? = api!.changeLEDState(state: is_on)
			
			DispatchQueue.main.async {
				
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
	
	@IBAction func urltxt_editing_start(_ sender: Any) {
		url_txt.textColor = UIColor.black
		if (url_txt.text == "Invalid IP or port") {
			url_txt.text = ""
		}
	}
	
	func check_urltext_valid() -> Bool {
		
		// Check valid URL
		if (url_txt.text == nil) {
			// Establish New Connection
			connection = Connection(string: def_ip)
			return connection.isValid()
		}
		
		// Establish New Connection
		connection = Connection(string: url_txt.text!)
		return connection.isValid()
	}
	
	func textFieldShouldReturn(_ scoreText: UITextField) -> Bool {
		self.view.endEditing(true)
		if (check_urltext_valid()) {
			updateCommonStates()
			url_txt.text = connection.returnIP()! + ":" + String(connection.returnPort()!)
		} else {
			url_txt.textColor = UIColor.red
			url_txt.text = "Invalid IP or port"
		}
		return true
	}
	
	// UI display modules
	
	func displayError() {
		green_light.isHidden = true
		red_light.isHidden = true
		
		if (api?.has_led)! {
			led_sw.isHidden = true
			led_lbl.isHidden = true
		}
		
		powerButton.isEnabled = false
		uptime_lbl.text = "Error: Cannot Connect!"
		uptime_lbl.textColor = UIColor.red
		prev_connected = connected
		connected = false
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
	}
	
	// Include displaying Uptime
	func updateCommonStates() {
		
		DispatchQueue.global().async {

			(self.relay_state, self.led_state) = api!.getCommonStates()
			
			DispatchQueue.main.async {

				// Check connection
				if (!connection.ableConnect() || self.relay_state == nil || self.led_state == nil) {
					self.displayError()
					return
				}
				
				var valid = true
				self.displayNormal()
				
				// Time
				var h,m: Int?
				(valid, h,m,_) = api!.getUpTime()
				if (!valid) {
					self.displayError()
					return
				}
				let hS = twoDigitInt(int: h!)
				let mS = twoDigitInt(int: m!)
				self.uptime_lbl.text = "Uptime: \(hS)h \(mS)m"
				return
				
			}
		}
	}

	// Network Reachability Functions
	let reachability = Reachability()!
	
	@objc func reachabilityChanged(notification: Notification) {
		updateCommonStates()
		/*let reachability = notification.object as! Reachability
		switch reachability.currentReachabilityStatus {
		case .notReachable:
			debugPrint(“Network became unreachable”)
		case .reachableViaWiFi:
			debugPrint(“Network reachable through WiFi”)
		case .reachableViaWWAN:
			debugPrint(“Network reachable through Cellular Data”)
		}*/
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
