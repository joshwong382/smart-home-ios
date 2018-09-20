//
//  DevicesVC.swift
//  Smart Home
//
//  Created by Joshua Wong on 21/7/2018.
//  Copyright © 2018 Joshua Wong. All rights reserved.
//

import UIKit

// Programming Notes
/*
	1. For Individual actions of the table, use prepare() -> LoginVC -> UIoverrides()
	2. backBarButtonItem is changed everytime a segue is performed out of this VC
*/

class DevicesVC: UIViewController, UITableViewDelegate, UITableViewDataSource {

	// Previous View Controller Object
	var previousVC: UIViewController? = nil
	
	// Store backBarButtonItem when changed
	var navItem: UIBarButtonItem? = nil
	
	@IBOutlet weak var table: UITableView!
	
	private var markForDismiss: Bool = false
	
	override func viewDidLoad() {
        super.viewDidLoad()
		
		navItem = navigationItem.backBarButtonItem
		
        // Cancel Button
		let cancel_btn = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.done, target: self, action: #selector(cancel_dismissVC(_:)))
		navigationItem.leftBarButtonItem = cancel_btn
    }
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		navigationItem.backBarButtonItem = navItem
		
		// If marked for dismiss then dismiss immediately
		if (markForDismiss) {
			dismissVC()
			return
		}
		
		// Deselect selected row after view controller comes back
		if let selectionIndexPath = table.indexPathForSelectedRow {
			table.deselectRow(at: selectionIndexPath, animated: animated)
		}
	}
	
	// Send data to LoginVC
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		
		// Perform Segue
		if let destVC = (segue.destination as? LoginViewController) {
			if let indexPath = sender as? IndexPath {
				destVC.smart_apitype = protocols.get_apitype_by_order(index: indexPath.row)
			}
			destVC.previousVC = self
			navigationItem.backBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: nil, action: nil)
		}
	}
	
	// Number of cells
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return protocols.getCount()
	}
	
	// Displying the table cells
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		// Create cell
		let cell = UITableViewCell(style: UITableViewCell.CellStyle.default, reuseIdentifier: "cell")
		
		// Add Elements
		cell.textLabel?.text = protocols.getProtoByOrder(index: indexPath.row)!.type_name
		cell.accessoryType = .detailDisclosureButton
		
		return cell
	}
	
	// When user clicked on a table cell
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		
		// Sender is indexPath so prepare() knows which is pressed
		performSegue(withIdentifier: "Device2LoginSegue", sender: indexPath)
	}
	
	@objc func cancel_dismissVC(_ sender: UIBarButtonItem) {
		dismissVC()
	}
	
	func addAPI(newly_added_api: (obj: SMART, customized_name: String)) {
		if let sourceVC = previousVC as? UIViewWelcome {
			sourceVC.add_smartobj(obj: newly_added_api.obj, objname: newly_added_api.customized_name)
			markForDismiss = true
		}
	}
	
	func dismissVC() {
		self.dismiss(animated: true, completion: nil)
	}
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
