//
//  LoginViewController.swift
//  Smart Home
//
//  Created by Joshua Wong on 22/6/2018.
//  Copyright © 2018 Joshua Wong. All rights reserved.
//

import UIKit
import SwiftyJSON

class LoginViewController: UIViewController, UITextFieldDelegate {
	
	// api that is sent from PreviousVC
	var smart_api: SMART? = nil
	
	// api type that is sent from PreviousVC
	var smart_apitype: (type_name: String, obj_type: SMART.Type, obj_login: GET_API)? = nil
	
	// Previous View Controller Object
	var previousVC: UIViewController? = nil
	
	// No Fields Required = 0
	// First Field Required = 1
	// Both Fields Required = 2
	private var fieldsRL: UInt = 2
	var fieldsRequiredLevel: UInt {
		get {
			return fieldsRL
		}
		set(_fieldsRL) {
			if (_fieldsRL <= 2) {
				fieldsRL = _fieldsRL
			} else {
				print(String(_fieldsRL) + " is not a Valid Int")
			}
		}
	}
	
    @IBOutlet weak var cancel_btn: UIButton!
	@IBOutlet weak var login_btn: UIButton!
	@IBOutlet weak var login_lbl: UILabel!
	@IBOutlet weak var username_field: UITextField!
	@IBOutlet weak var pass_field: UITextField!
	@IBOutlet weak var error_lbl: UILabel!
	
	func dismiss(fromSide: String = convertFromCATransitionSubtype(CATransitionSubtype.fromBottom)) {
		
		let transition: CATransition = CATransition()
		let timeFunc = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
		transition.duration = 0.3
		transition.timingFunction = timeFunc
		transition.type = CATransitionType.reveal
		transition.subtype = convertToOptionalCATransitionSubtype(fromSide)
		self.view.window?.layer.add(transition, forKey: nil)
		self.dismiss(animated: false, completion: nil)
		
	}
	
	// Dismiss View Controller
	func dismissVC(token: String? = nil) {
		
		// If PreviousVC is SmartVC
		if var smartvc = previousVC as? SmartVC {
			
			// Allow this View Controller to be performed again
			smartvc.token_updating = false
			
			// Send new token back to previous VC
			if (token != nil) {
				smartvc.new_token = token!
			}
			self.dismiss(fromSide: convertFromCATransitionSubtype(CATransitionSubtype.fromRight))
			return
		}
		
		if (previousVC is DevicesVC) {
			navigationController?.popViewController(animated: true)
			return
		}
		
		self.dismiss()
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		// Delegates and Tags for text field return
		username_field.delegate = self
		username_field.tag = 0
		pass_field.delegate = self
		pass_field.tag = 1
		
		if (previousVC is DevicesVC) {
			UIoverrides()
		}
			
		login_btn.isEnabled = false

		// If PreviousVC is SmartVC
		if (previousVC is SmartVC) {
			if (smart_api != nil) {
				// api is provided
				login_lbl.text = smart_api!.vendor_name
			}
		}
		
		if (previousVC is DevicesVC) {
			if (smart_apitype != nil) {
				login_lbl.text = smart_apitype!.type_name
			}
			
			//navigationItem.hidesBackButton = true
			//let newBackButton = UIBarButtonItem(title: "Back", style: UIBarButtonItemStyle.plain, target: self, action: #selector(back(sender:)))
			//navigationItem.leftBarButtonItem = newBackButton
		}
		
	}
	
	// API selection Action -> UI Changes
	private func UIoverrides() {
		
		if let override = smart_apitype?.obj_login as? LOGIN_UIOVERRIDES {
			override.field_overrides(firstField: &username_field, secondField: &pass_field, fieldsRequirementLevel: &fieldsRequiredLevel)
		}
		
	}
	
	@IBAction func cancel_pressed(_ sender: Any) {
		dismissVC()
	}
	

	@IBAction func username_editchanged(_ sender: Any) {
		checkEmpty()
	}
	

	@IBAction func pass_editchanged(_ sender: Any) {
		checkEmpty()
	}
	
	//MARK: - Controlling the Keyboard
	func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		if (textField == username_field) {
			textField.resignFirstResponder()
			pass_field.becomeFirstResponder()
		} else if (textField == pass_field) {
			textField.resignFirstResponder()
			login_pressed(textField)
		}
		return true
	}
	
	func checkEmpty() {
		
		if (fieldsRequiredLevel == 0) {
			login_btn.isEnabled = true
		}
		
		if (fieldsRequiredLevel == 1) {
			if (username_field.text == "") {
				login_btn.isEnabled = false
			} else {
				login_btn.isEnabled = true
			}
		}
		
		if (fieldsRequiredLevel == 2) {
			if (username_field.text == "" || pass_field.text == "") {
				login_btn.isEnabled = false
			} else {
				login_btn.isEnabled = true
			}
		}
	}
	

	@IBAction func login_pressed(_ sender: Any) {
		
		view.endEditing(true)
		
		// Check Network
		if (reachability.connection == .none) {
			error_lbl.text = "Error: Cannot Connect"
			return
		}
		
		// For any SmartVC including PlugVC
		if let remote_api = smart_api as? TOKEN_LOGIN {
			
			// Attempt to Login
			let response: String?
			let error: Bool
			(error, response) = remote_api.token_from_login(username: username_field.text!, password: pass_field.text!)
			
			if (response == nil) {
				error_lbl.text = "Error: Cannot Connect"
				return
			}
			
			if (error) {
				error_lbl.text = response
				return
			}
			
			dismissVC(token: response!)
			return
		}
		
		// For DevicesVC
		else if (smart_apitype != nil) {
			
			if let remote_apitype = smart_apitype!.obj_login as? TOKEN {
				
				let response: String?
				
				// Attempt to Login
				if let login_api = remote_apitype as? TOKEN_LOGIN {
					
					let error: Bool
					(error, response) = login_api.token_from_login(username: username_field.text!, password: pass_field.text!)
					
					if (response == nil) {
						error_lbl.text = "Error: Cannot Connect"
						return
					}
					
					if (error) {
						error_lbl.text = response
						return
					}
					
				} else {
					
					let result = remote_apitype.check_token(token: pass_field.text!)
					response = result.token
					
					if (response == nil) {
						error_lbl.text = "Unknown Error: 1725"
						return
					}
					
					if (result.error) {
						error_lbl.text = "Incorrect Token/API Key"
						return
					}
				}
				
				// Use Token to Get Devices
				
				// TOKEN_LOGIN_MULTIDEVICE
				if let multidevice_api = remote_apitype as? TOKEN_MULTIDEVICE {
					let result = multidevice_api.get_devices()
					if (result.error == false && result.devices != nil) {
						
						// Get devices
						let device_list = result.devices!
						
						// If only one device, use that device
						switch device_list.count {
							
						case 0:
							error_lbl.text = "No devices are connected to your account"
							return
						
						default:
							// Create api object and dismiss
							
							// Instantiate apis array
							var apis = [(api: SMART, name: String)]()
							
							// For each device in account
							for device in device_list {
								
								// Final check for api type
								if let api_type = (smart_apitype!.obj_type.self as? (Remote_MultiDevice.Type)) {
									// Create Object
									let api = api_type.init(_token: response!, _url: device.api_url, _devid: device.device_id)
									
									if (debug_contains(type: .TokenUpdate)) {
										print("Token: " + response!)
										print("Domain: " + device.api_url)
										print("Device ID: " + device.device_id)
									}
									
									// Add to array
									apis.append((api: (api as! SMART), name: device.alias))
								}
							}
							
							// Send data back to previousVC
							if let devicevc = previousVC as? DevicesVC {
								for api in apis {
									devicevc.addAPI(newly_added_api: (obj: api.api, customized_name: api.name))
								}
								dismissVC()
							} else {
								error_lbl.text = "Error: Unable to add device to list"
							}
							return
						
						}
					} else {
						error_lbl.text = "Error: Unable to find devices"
						return
					}
					
				// TOKEN_LOGIN SINGLEDEVICE
				} else if let singledevice_api = remote_apitype as? TOKEN_SINGLEDEVICE {
					
					// Final check type
					if let api_type = (smart_apitype!.obj_type.self as? (Remote_SingleDevice.Type)) {
						
						// Get info from device
						let device = singledevice_api.getDevice()
						let api = api_type.init(_token: response!, _url: device.url)
						if let devicevc = previousVC as? DevicesVC {
							devicevc.addAPI(newly_added_api: (obj: api as! SMART, customized_name: device.name))
							dismissVC()
						} else {
							error_lbl.text = "Error: Unable to add device to list"
						}
						return
					}
					
				}
				return
			}
			
			// Use a custom method for getting API
			else if let apitype = smart_apitype!.obj_login as? CUSTOM_GETAPI {
				let result = apitype.getAPI(firstText: username_field.text, secondText: pass_field.text)
				
				if (result.new_api == nil || result.name == nil || result.error) {
					if (result.name == nil || result.name == "") {
						error_lbl.text = "Error: Unable to Connect"
					} else {
						error_lbl.text = result.name
					}
					return
				}

				if let devicevc = previousVC as? DevicesVC {
					devicevc.addAPI(newly_added_api: (obj: result.new_api!, customized_name: result.name!))
					dismissVC()
				} else {
					error_lbl.text = "Error: Unable to add device to list"
				}
				return
			}
		}
		
		// When all fails
		error_lbl.text = "Error: Feature Unavailable"
	}
	
	
	/*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromCATransitionSubtype(_ input: CATransitionSubtype) -> String {
	return input.rawValue
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToOptionalCATransitionSubtype(_ input: String?) -> CATransitionSubtype? {
	guard let input = input else { return nil }
	return CATransitionSubtype(rawValue: input)
}
