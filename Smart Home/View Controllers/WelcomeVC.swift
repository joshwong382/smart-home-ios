//
//  WelcomeVC.swift
//  Smart Home
//
//  Created by Joshua Wong on 20/7/2018.
//  Copyright © 2018 Joshua Wong. All rights reserved.
//

import UIKit
import Reachability

// Table is handled by the View Controller
class UIViewWelcome: ReachabilityTableVCDelegate {
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		// Edit Button
		let edit_btn = UIBarButtonItem(title: "Edit", style: UIBarButtonItem.Style.plain, target: self, action: #selector(edit(_:)))
		navigationItem.leftBarButtonItem = edit_btn
		
		// Add Button
		let add_btn = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.add, target: self, action: #selector(create_smartobj(_:)))
		navigationItem.rightBarButtonItem = add_btn

		// Table Subview is refresh
		tableView.addSubview(refresh)
	}
	
	// Send data to DevicesVC
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		
		// When adding devices
		if let destVC = (segue.destination as? UINavigationController) {
			if let tableVC = destVC.viewControllers.first as? DevicesVC {
				tableVC.previousVC = segue.source
			}
		}
		
		// When user clicked a table cell
		if let destVC = (segue.destination as? PlugViewController) {
			// Make sure indexPath is sent so that we know which cell is pressed
			if let indexPath = sender as? IndexPath {
				// Plug is forced in perform Segue
				if let api = api_data.get(index: indexPath.row).api as? Plug {
					destVC.api = api
				}
			}
		}
	}
	
	// Handles refresh
	lazy var refresh: UIRefreshControl = {
		let refresh = UIRefreshControl()
		refresh.addTarget(self, action: #selector(tableRefresh(_:)), for: UIControl.Event.valueChanged)
		refresh.tintColor = .black
		return refresh
	}()
	
	@objc func tableRefresh(_ refreshControl: UIRefreshControl) {
		reloadData()
		refresh.endRefreshing()
	}
	
	// Number of cells
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		if (debug_contains(type: .UIViewWelcome)) {
			print("Table Item Count: " + String(api_data.count))
		}
		return api_data.count
	}
	
	// Displaying the table cells
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		
		// DISPLAY ORDER IN Protocols.swift -> proto_db()
		
		// Get Current Array Values
		let info = api_data.get(index: indexPath.row)
		
		// Let cell = for each cell
		// AT THE MOMENT THIS ALWAYS RETURNS NIL
		var cell: UITableViewCell? = tableView.cellForRow(at: indexPath)
		
		// Check Previous Cell
		if cell?.tag != Int(info.current_sess_uid) {
			
			// If cell is different when reloaded or not created
			cell = UITableViewCell(style: UITableViewCell.CellStyle.default, reuseIdentifier: "cell")
			
			cell!.tag = Int(info.current_sess_uid)
			
			// Default accessoryView
			let loading_bar = UIActivityIndicatorView(style: .gray)
			cell!.accessoryView = loading_bar
			loading_bar.startAnimating()
		}
		
		// Each cell's text to be value
		cell!.textLabel?.text = info.name
		cell!.textLabel?.numberOfLines = 0
		cell!.textLabel?.lineBreakMode = .byTruncatingTail
		
		// Check Current State for Plug
		if (info.api is Plug || info.api is Switch) {
			
			// Create on-off switch
			var on_off_sw: UISwitch? = nil
			
			var relayState: Bool?
			DispatchQueue.global().async {
				
				let state = reachability.connection
				
				if (state != .none) {
					relayState = self.checkRelayState(api: info.api)
				} else {
					relayState = nil
				}
				
				DispatchQueue.main.async {
					
					// Offline
					if (relayState == nil) {
						
						self.displayOffline(cell: cell!)
						
					} else {
						
						if let cell_sw = cell!.accessoryView as? UISwitch {
							// Don't recreate element
							cell_sw.isOn = relayState!
						} else {
							// Cell accessoryView to be a On Off Switch
							on_off_sw = UISwitch(frame: CGRect(x: 1, y: 1, width: 20, height: 20))
							on_off_sw!.isOn = relayState!
							// Set switch tag to index
							on_off_sw!.tag = indexPath.row
							// Set switch action to toggle()
							on_off_sw!.addTarget(self, action: #selector(self.toggle(_:)), for: .valueChanged)
							cell!.accessoryView = on_off_sw
						}
					}
				}
			}
		}
		
		// No need to check state for trigger
		else if (info.api is Trigger) {
			
			let btn = UIButton(type: .system)
			btn.frame = CGRect(x: 1, y: 1, width: 60, height: 20)
			btn.setTitle("Trigger", for: .normal)
			btn.tag = indexPath.row
			btn.addTarget(self, action: #selector(self.trigger(_:)), for: .touchUpInside)
			
			cell!.accessoryView = btn
		}
		
		return cell!
	}
	
	// Can Edit
	override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
		return true
	}
	
	// Delete
	override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
		if (editingStyle == .delete) {
			// Actually delete the cell
			api_data.delete(index: indexPath.row)
			reloadData()
		}
	}
	
	func displayOffline(cell: UITableViewCell) {
		var offline_lbl: UILabel? = nil
		if let cell_offline = cell.accessoryView as? UILabel {
			cell_offline.textColor = .red
			cell_offline.text = "Offline"
		} else {
			// Cell accessoryView to be a text
			offline_lbl = UILabel(frame: CGRect(x: 1, y: 1, width: 60, height: 20))
			offline_lbl!.textColor = .red
			offline_lbl!.text = "Offline"
			cell.accessoryView = offline_lbl
		}
	}
	
	// When user clicked on a table cell
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		
		let api = api_data.get(index: indexPath.row).api
		
		// If api is Plug then proceed
		if (api is Plug) {
			performSegue(withIdentifier: "Table2PlugSegue", sender: indexPath)
		}
	}
	
	// When user moves elements around
	override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
	}
	
	@objc func toggle(_ sender: UISwitch) {
		let api = api_data.get(index: sender.tag).api
		
		if let PlugAPI = api as? Plug {
			_ = PlugAPI.changeRelayState(state: sender.isOn)
		}
		
		if let SwitchAPI = api as? Switch {
			_ = SwitchAPI.changeRelayState(state: sender.isOn)
		}
	}
	
	@objc func trigger(_ sender: UIButton) {
		let api = api_data.get(index: sender.tag).api
		
		if let TriggerAPI = api as? Trigger {
			_ = TriggerAPI.run()
		}
	}
	
	// Refreshes the page for reconenctions
	@objc func edit(_ sender: UIBarButtonItem) {
		
		if(self.tableView.isEditing) {
			self.tableView.isEditing = false
			self.navigationItem.leftBarButtonItem?.title = "Edit"
		} else {
			self.tableView.isEditing = true
			self.navigationItem.leftBarButtonItem?.title = "Done"
		}
		
	}
	
	
	// Creates a new object on the page
	@objc func create_smartobj(_ sender: UIBarButtonItem) {
		self.performSegue(withIdentifier: "Table2DeviceSegue", sender: self)
	}
	
	func add_smartobj(obj: SMART, objname: String) {
		
		// append table list
		_ = api_data.add(name: objname, api: obj)
		
		// reload data
		reloadData()
		
	}
	
	func reloadData() {
		if (debug_contains(type: .UIViewWelcome)) {
			print("reloading...")
		}
		tableView.reloadData()
	}
	
	func checkRelayState(api: SMART) -> Bool? {
		if let PlugAPI = api as? Plug {
			let result = PlugAPI.getCommonStates()
			return result.pwr
		}
		
		if let SwitchAPI = api as? Switch {
			let result = SwitchAPI.getPowerState()
			return result.pwr
		}
		return nil
	}
	
	// Reachability
	override func reachabilityChanged(state: Reachability.Connection) {
		super.reachabilityChanged(state: state)
		reloadData()
	}
}
