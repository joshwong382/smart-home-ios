//
//  SidePopViewController.swift
//  Smart Home
//
//  Created by Joshua Wong on 2/6/2018.
//  Copyright © 2018 Joshua Wong. All rights reserved.
//

import UIKit

class SidePopViewController: UIViewContLR {
	
	var previousView: String? = nil

	@IBOutlet weak var done_btn: UIButton!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		print(previousView!)
	}
	
	@IBAction func done_pressed(_ sender: Any) {
	
	// Dismiss View Controller
	self.dismiss()
	
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
