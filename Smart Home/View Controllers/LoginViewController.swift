//
//  LoginViewController.swift
//  Smart Home
//
//  Created by Joshua Wong on 22/6/2018.
//  Copyright © 2018 Joshua Wong. All rights reserved.
//

import UIKit
import SwiftyJSON

class LoginViewController: UIViewController {

	// Previous View Controller Name
	var previousView: String? = nil
	
	// api that is sent from PreviousVC
	var smart_api: SMART? = nil
	
	// Previous View Controller Object
	var previousVC: UIViewController? = nil

    @IBOutlet weak var cancel_btn: UIButton!
	@IBOutlet weak var login_btn: UIButton!
	@IBOutlet weak var login_lbl: UILabel!
	@IBOutlet weak var username_field: UITextField!
	@IBOutlet weak var pass_field: UITextField!
	@IBOutlet weak var error_lbl: UILabel!
	
	func dismissVC(token: String? = nil) {
		
		// Dismiss View Controller
		
		// If PreviousVC is SmartVC
		if var smartvc = previousVC! as? SmartVC {
			
			// Allow this View Controller to be performed again
			smartvc.token_updating = false
			
			// Send new token back to previous VC
			if (token == nil) {
				smartvc.new_token = token!
			}
		}
		
		self.dismiss(animated: true, completion: nil)
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		login_btn.isEnabled = false
		
		// If PreviousVC is SmartVC
		if (previousVC is SmartVC) {
			if (smart_api == nil) {
				// api is provided
				login_lbl.text = smart_api!.vendor_name
			}
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
	
	
	func checkEmpty() {
		if (username_field.text == "" || pass_field.text == "") {
			login_btn.isEnabled = false
		} else {
			login_btn.isEnabled = true
		}
	}
	

	@IBAction func login_pressed(_ sender: Any) {
		
		// Check if is Remote
		if let remote_api = smart_api as? Remote {
			
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
			
			
		} else {
			error_lbl.text = "Error: Login feature unavailable"
		}
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
