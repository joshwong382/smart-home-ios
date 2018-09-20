//
//  net_status.swift
//  Smart Home
//
//  Created by Joshua Wong on 7/8/2018.
//  Copyright © 2018 Joshua Wong. All rights reserved.
//

import UIKit
import Reachability

let reachability = _reachability()

protocol _reachabilityDelegate: class {
	func reachabilityChanged(state: Reachability.Connection)
}

class ReachabilityVCDelegate: UIViewController, _reachabilityDelegate {
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		reachability.delegate = self as _reachabilityDelegate
	}
	
	func reachabilityChanged(state: Reachability.Connection) {
		switch state {
		case .none:
			print("Network became unreachable")
			
		case .wifi:
			print("On WiFi")
			
		case .cellular:
			print("On Cellular")
		}
	}
}

class ReachabilityTableVCDelegate: UITableViewController, _reachabilityDelegate {
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		reachability.delegate = self as _reachabilityDelegate
	}
	
	func reachabilityChanged(state: Reachability.Connection) {
		switch state {
		case .none:
			print("Network became unreachable")
			
		case .wifi:
			print("On WiFi")
			
		case .cellular:
			print("On Cellular")
		}
	}
}

class _reachability {
	
	init() {
		reachability_init = false
		reachability = Reachability()!
		self.delegate = nil
		connection = reachability.connection
		startMonitoring()
	}
	
	weak var delegate: _reachabilityDelegate? = nil
	let reachability: Reachability
	var reachability_init: Bool
	var connection: Reachability.Connection
	
	// Network Reachability Functions

	@objc func reachabilityChanged(notification: Notification) {
		if (!reachability_init) { reachability_init = true }
		else {
			let reachability = notification.object as! Reachability
			// Perform all functions that are delegated
			delegate?.reachabilityChanged(state: reachability.connection)
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
