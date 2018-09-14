//
//  WelcomeVC.swift
//  Smart Home
//
//  Created by Joshua Wong on 20/7/2018.
//  Copyright © 2018 Joshua Wong. All rights reserved.
//

import UIKit

class UINavHomeController: UINavigationController {
	
}

// Table is handled by the View Controller
class UIViewWelcome: UITableViewController {
	
	var tableList = [(name: String, api: SMART)]()
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		// Refresh Button
		let ref_btn = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.refresh, target: self, action: #selector(refresh(_:)))
		navigationItem.leftBarButtonItem = ref_btn
		
		// Add Button
		let add_btn = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.add, target: self, action: #selector(create_smartobj(_:)))
		navigationItem.rightBarButtonItem = add_btn
		
		let api = TPLINK_LOCAL(ip: "12.34.56.205")
		
		// Load up the tablelist
		tableList.append((name: "Room Light", api: api))
	}
	
	// Send data to LoginVC
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		
		if (segue.destination is LoginViewController) {
			let destVC = segue.destination as! LoginViewController
			destVC.previousVC = segue.source
		}
	}
	
	
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		if (debug_contains(type: .UIViewWelcome)) {
			print("Table Item Count: " + String(tableList.count))
		}
		return tableList.count
	}
	
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		
		// Let cell = for each cell
		let cell = UITableViewCell(style: UITableViewCellStyle.default, reuseIdentifier: "cell")
		
		// Get Current Array Values
		let info = tableList[indexPath.row]
		
		// Each cell's text to be value
		cell.textLabel?.text = info.name
		
		// Create on-off switch
		let on_off_sw: UISwitch
		let offline_lbl: UILabel
		
		let relayState = checkRelayState(api: info.api)
		
		// Offline
		if (relayState == nil) {
			// Cell accessoryView to be a text
			offline_lbl = UILabel(frame: CGRect(x: 1, y: 1, width: 60, height: 20))
			offline_lbl.textColor = .red
			offline_lbl.text = "Offline"
			cell.accessoryView = offline_lbl
			
		} else {
			// Cell accessoryView to be a On Off Switch
			on_off_sw = UISwitch(frame: CGRect(x: 1, y: 1, width: 20, height: 20))
			on_off_sw.isOn = relayState!
			// Set switch tag to index
			on_off_sw.tag = indexPath.row
			// Set switch action to toggle()
			on_off_sw.addTarget(self, action: #selector(toggle(_:)), for: .valueChanged)
			cell.accessoryView = on_off_sw
		}
		
		return cell
	}
	
	@objc func toggle(_ sender: UISwitch) {
		let success = changeRelayState(state: sender.isOn, api: tableList[sender.tag].api)
		
		// Unknown Error
		if (!success) {
			sender.isEnabled = false
		}
	}
	
	// Refreshes the page for reconenctions
	@objc func refresh(_ sender: UIBarButtonItem) {
		if (debug_contains(type: .UIViewWelcome)) {
			print("reloading...")
		}
		self.tableView.reloadData()
	}
	
	// Creates a new object on the page
	@objc func create_smartobj(_ sender: UIBarButtonItem) {
		self.performSegue(withIdentifier: "Table2DeviceSegue", sender: self)
	}
	
	func checkRelayState(api: SMART) -> Bool? {
		if let PlugAPI = api as? Plug {
			let result = PlugAPI.getCommonStates()
			return result.pwr
		}
		return nil
	}
	
	func changeRelayState(state: Bool, api: SMART) -> Bool {
		
		if let PlugAPI = api as? Plug {
			let result = PlugAPI.changeRelayState(state: state)
			if (result.success == false) { return false }
			return true
		}
		
		return false
	}
}
