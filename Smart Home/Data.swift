//
//  Data.swift
//  Smart Home
//
//  Created by Joshua Wong on 13/8/2018.
//  Copyright © 2018 Joshua Wong. All rights reserved.
//

import UIKit

let api_data = DataManager()

class DataManager {
	
	init() {
		tableList = [(name: String, api: SMART, current_sess_uid: UInt)]()
		cellUID = 0
		fromFile()
	}
	
	//private var fileManager: FileManager = FileManager.default
	private var tableList: [(name: String, api: SMART, current_sess_uid: UInt)]
	private var cellUID: UInt
	
	var count: Int {
		get {
			return tableList.count
		}
	}
	
	var domain: String {
		return Bundle.main.bundleIdentifier!
	}
	
	private func fromFile() {
		let fileCount = UserDefaults.standard.integer(forKey: (domain + ".API_count"))
		for i in 0 ... fileCount {
			let data = UserDefaults.standard.dictionary(forKey: (domain + ".API" + String(i)))
			if (data != nil) {
				let typeid = data!["type_id"] as? Int
				if (typeid == nil) {
					return
				}
				
				let result = protocols.getProtoByTypeID(id: typeid!)?.load_from_file(file: data!)
				if (result?.api == nil) {
					return
				}
				tableList.append((name: result!.name!, api: result!.api!, current_sess_uid: cellUID))
				cellUID += 1
			}
		}
	}
	
	// Add to tableList
	func add(name: String, api: SMART) -> Bool {
		let count = self.count
		tableList.append((name: name, api: api, current_sess_uid: cellUID))
		let data = protocols.getProtoByTypeID(id: Int(api.type_id))?.save_to_file(api: api, name: name)
		
		if (data!.isEmpty) {
			print("Permanent Storage Failed")
		}
		
		cellUID += 1
		if (data == nil) { return true }
		UserDefaults.standard.set(data, forKey: (domain + ".API" + String(count)))
		UserDefaults.standard.set(count, forKey: (domain + ".API_count"))
		UserDefaults.standard.synchronize()
		return false
	}
	
	// Access tableList
	func get(index: Int) -> (name: String, api: SMART, current_sess_uid: UInt) {
		return tableList[index]
	}
	
	func delete(index: Int) {
		// Remove from table
		tableList.remove(at: index)
		
		// Do a clean delete
		if (count == 0) {
			clearAll()
			return
		}
		
		// Recreate Persistent Info
		sync(fromIndex: index)
		
		// Remove last object as it's duplicated
		UserDefaults.standard.removeObject(forKey: domain + ".API" + String(count))
	}
	
	// Sync from list to storage
	private func sync(fromIndex: Int = 0) {
		if (fromIndex < count) {
			for i in fromIndex...count {
				let list = get(index: i-1)
				let data = protocols.getProtoByTypeID(id: Int(list.api.type_id))?.save_to_file(api: list.api, name: list.name)
				UserDefaults.standard.set(data, forKey: (domain + ".API" + String(i)))
			}
		}
		UserDefaults.standard.set(count, forKey: (domain + ".API_count"))
		UserDefaults.standard.synchronize()
	}
	
	func clearAll() {
		tableList.removeAll()
		let domain = Bundle.main.bundleIdentifier!
		UserDefaults.standard.removePersistentDomain(forName: domain)
		UserDefaults.standard.synchronize()
	}
}
