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
	
	private var TCP_state_queue = [(cell: UITableViewCell, api: SMART, indexPath: IndexPath)]()
	private let TCP_state_dispatch = DispatchQueue(label: "tcp_state_async_queue")
	private let reload_semaphore = DispatchSemaphore(value: 1)
	private var add_btn: UIBarButtonItem? = nil
	private var settings_btn : UIBarButtonItem? = nil
	
	override func viewDidLoad() {
		super.viewDidLoad()
		print("Lines of Code: " + String(number_of_lines))
		// Edit Button
		let edit_btn = UIBarButtonItem(title: "Edit", style: .plain, target: self, action: #selector(edit(_:)))
		navigationItem.leftBarButtonItem = edit_btn
		
		// Add Button
		add_btn = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.add, target: self, action: #selector(create_smartobj(_:)))
		settings_btn = UIBarButtonItem(title: "Settings", style: .plain, target: self, action: #selector(switch_to_settings(_:)))
		navigationItem.rightBarButtonItem = settings_btn

		// Table Subview is refresh
		threaded_check_relay_state()
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
	
	@objc func switch_to_settings(_ sender: UIBarButtonItem) {
		self.performSegue(withIdentifier: "Table2SettingsSegue", sender: self)
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
		if (debug.contains(.UIViewWelcome)) {
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
		cell!.textLabel?.text = info.api.name
		cell!.textLabel?.numberOfLines = 0
		cell!.textLabel?.lineBreakMode = .byTruncatingTail
		
		// Check Current State for Plug
		if (info.api is Plug || info.api is Switch) {
			TCP_state_queue.append((cell: cell!, api: info.api, indexPath: indexPath))
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
			reload_semaphore.wait()
			reloadData()
			reload_semaphore.signal()
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
		api_data.move(prevIndex: sourceIndexPath.row, toIndex: destinationIndexPath.row)
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
			self.tableView.setEditing(false, animated: true)
			self.navigationItem.leftBarButtonItem?.title = "Edit"
			self.navigationItem.rightBarButtonItem = settings_btn
		} else {
			self.tableView.setEditing(true, animated: true)
			self.navigationItem.leftBarButtonItem?.title = "Done"
			self.navigationItem.rightBarButtonItem = add_btn
		}
		
	}
	
	
	// Creates a new object on the page
	@objc func create_smartobj(_ sender: UIBarButtonItem) {
		self.performSegue(withIdentifier: "Table2DeviceSegue", sender: self)
	}
	
	func add_smartobj(obj: SMART) {
		
		// append table list
		_ = api_data.add(api: obj)
		
		// reload data
		reloadData()
		
	}
	
	func reloadData() {
		if (debug.contains(.UIViewWelcome)) {
			print("reloading...")
		}
		
		if (Thread.isMainThread) {
			tableView.reloadData()
		} else {
			DispatchQueue.main.async {
				self.tableView.reloadData()
			}
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
	
	/*

		PRIVATE THREAD TCP STATE QUEUE FUNCTIONS

	*/
	
	// should only be called in viewDidLoad
	private func threaded_check_relay_state() {
		
		TCP_state_dispatch.async {
			while (true) {
				
				// Manual Refresh
				while (!self.TCP_state_queue.isEmpty) {
					let info = self.TCP_state_queue.removeFirst()
					self.accessoryViewCreation(cell: info.cell, api: info.api, index: info.indexPath.row, background: false)
				}
				
				// Automatic Refresh every 5 seconds
				var cells: [UITableViewCell]?
				DispatchQueue.main.sync {
					cells = self.tableView.visibleCells
				}
				
				if (cells == nil) { continue }
				if (cells!.count == 0) { continue }
				var cell_index = 0
				
				// Only background reload if ViewController is visible
				var vc_visible: Bool? = true
				DispatchQueue.main.async {
					vc_visible = self.isViewLoaded && (self.view!.window != nil)
				}
				
				let prev_time = DispatchTime.now().uptimeNanoseconds
				while (vc_visible! && self.TCP_state_queue.isEmpty && cell_index < cells!.count) {
					
					if (DispatchTime.now().uptimeNanoseconds - prev_time >= UInt64(5*1e9)) {
						self.reload_semaphore.wait()
						
						// get every cell
						let cell = cells![cell_index]
						
						// check cell is not offline (if we refresh this it might take a long time)
						if (cell.api_offline) {
							continue
						}
						
						// get api and update view
						let api = api_data.get(index: cell_index).api
						self.accessoryViewCreation(cell: cell, api: api, index: cell_index, background: true)
						self.reload_semaphore.signal()
						cell_index += 1
						
						DispatchQueue.main.async {
							vc_visible = self.isViewLoaded && (self.view!.window != nil)
						}
						if (!vc_visible!) {
							print("Background Reload Suspended")
						}
					}
				}
			}
		}
	}
	
	private func checkRelayState(api: SMART) -> Bool? {
		if let PlugAPI = api as? Plug {
			let result = PlugAPI.getCommonStates(timeout: 0)
			return result.pwr
		}
		
		if let SwitchAPI = api as? Switch {
			let result = SwitchAPI.getPowerState(timeout: 3)
			return result.pwr
		}
		return nil
	}
	
	// Run the check relay state with all the necessary UI changes
	private func accessoryViewCreation(cell: UITableViewCell, api: SMART, index: Int, background: Bool) {
		
		// this should not be run on the main thread
		if (Thread.isMainThread) {
			print("Error: Cannot be Run in Main Thread")
			return
		}
		
		// Create on-off switch
		var on_off_sw: UISwitch? = nil
		
		var relayState: Bool?
		
		let state = reachability.connection
		
		if (state != .none) {
			relayState = self.checkRelayState(api: api)
		} else {
			relayState = nil
		}
		
		// Update UI
		DispatchQueue.main.async {

			// Offline
			if (relayState == nil) {
				
				self.displayOffline(cell: cell)
				
			} else {
				
				if let cell_sw = cell.accessoryView as? UISwitch {
					// Don't recreate element
					cell_sw.setOn(relayState!, animated: true)
				} else {
					// Cell accessoryView to be a On Off Switch
					on_off_sw = UISwitch(frame: CGRect(x: 1, y: 1, width: 20, height: 20))
					on_off_sw!.setOn(relayState!, animated: false)
					// Set switch tag to index
					on_off_sw!.tag = index
					// Set switch action to toggle()
					on_off_sw!.addTarget(self, action: #selector(self.toggle(_:)), for: .valueChanged)
					cell.accessoryView = on_off_sw
				}
			}
		}
	}
	
	// Reachability
	override func reachabilityChanged(state: Reachability.Connection) {
		super.reachabilityChanged(state: state)
		reloadData()
	}
}
