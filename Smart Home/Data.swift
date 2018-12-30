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
		tableList = [(api: SMART, current_sess_uid: UInt)]()
		cellUID = 0
		fromFile()
	}
	
	//private var fileManager: FileManager = FileManager.default
	private var tableList: [(api: SMART, current_sess_uid: UInt)]
	private var cellUID: UInt
	
	var count: Int {
		get {
			return tableList.count
		}
	}
	
	private var domain: String {
		return Bundle.main.bundleIdentifier!
	}
	
	private func fromFile() {
		//print("Load Count: " + String(fileCount))
		cellUID = 0
		tableList.removeAll()
		
		let fileCount = UserDefaults.standard.integer(forKey: (domain + ".API_count"))
		if (debug.contains(.DATA)) {
			print("Count: " + String(fileCount))
		}
		if (fileCount == 0) { return }
		for i in 0 ... fileCount-1 {
			
			let result = load_entry(index: UInt(i))
			if (result != nil) {
				tableList.append((api: result!, current_sess_uid: cellUID))
				cellUID += 1
			}
		}
	}
	
	// Add to tableList
	func add(api: SMART) -> Bool {
		tableList.append((api: api, current_sess_uid: cellUID))
		return update_entry(api: api, index: UInt(count-1))
	}
	
	// Access tableList
	func get(index: Int) -> (api: SMART, current_sess_uid: UInt) {
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
		if (debug.contains(.DATA)) {
			print("After Delete Count: " + String(count))
		}
		sync_from_tableList_to_storage(fromIndex: index, toIndex: count)
		
		// Remove last object as it's duplicated
		UserDefaults.standard.removeObject(forKey: domain + ".API" + String(count))
	}
	
	func move(prevIndex: Int, toIndex: Int) {
		if (debug.contains(.DATA)) {
			print("Moving a row")
		}
		let element = tableList.remove(at: prevIndex)
		tableList.insert(element, at: toIndex)
		sync_from_tableList_to_storage(fromIndex: prevIndex, toIndex: toIndex)
	}
	
	private func load_entry(index: UInt) -> SMART? {
		let data = UserDefaults.standard.dictionary(forKey: (domain + ".API" + String(index)))
		
		if (debug.contains(.DATA)) {
			print("Load: " + (domain + ".API" + String(index)))
			//print(data!)
		}
		
		if (data != nil) {
			let typeid = data!["type_id"] as? Int
			if (typeid == nil) {
				return nil
			}
			
			let result = protocols.getProtoByTypeID(id: typeid!)?.load_from_file(file: data!)
			if (result == nil) {
				return nil
			}
			
			return result!
		}
		
		return nil
	}
	
	private func update_entry(api: SMART, index: UInt) -> Bool {
		let data = protocols.getProtoByTypeID(id: Int(api.type_id))?.save_to_file(api: api)
		
		if (data!.isEmpty) {
			print("Permanent Storage Failed")
		}
		
		cellUID += 1
		if (data == nil) { return true }
		UserDefaults.standard.set(data, forKey: (domain + ".API" + String(index)))

		// set count
		UserDefaults.standard.set(count, forKey: (domain + ".API_count"))
		UserDefaults.standard.synchronize()
		
		if (debug.contains(.DATA)) {
			print("Count: " + String(count) + ", Index: " + String(index))
			print("Save: " + (domain + ".API" + String(index)) + " For: ")
			print(data!)
		}
		return false
	}
	
	// Sync from list to storage
	func sync_from_tableList_to_storage(fromIndex: Int = 0, toIndex: Int = -1) {
		
		var to_index: Int = toIndex
		if (toIndex == -1) { to_index = count }
		if (to_index < 0) { return }
		if (to_index < fromIndex) { return }
		
		if (debug.contains(.DATA)) {
			print("Sync index " + String(fromIndex) + " to " + String(to_index))
		}
		
		DispatchQueue.global().async {
			if (toIndex < self.count) {
				for i in (fromIndex...to_index).reversed() {
					let list = self.get(index: i)
					let data = protocols.getProtoByTypeID(id: Int(list.api.type_id))?.save_to_file(api: list.api)
					UserDefaults.standard.set(data, forKey: (self.domain + ".API" + String(i)))
				}
			}
		
			UserDefaults.standard.set(self.count, forKey: (self.domain + ".API_count"))
			UserDefaults.standard.synchronize()
		}
		
		if (debug.contains(.DATA)) {
			print("Update Count: " + String(count))
		}
	}
	
	func clearAll() {
		if (debug.contains(.DATA)) {
			print("Remove All")
		}
		
		tableList.removeAll()
		
		DispatchQueue.global().async {
			UserDefaults.standard.removePersistentDomain(forName: self.domain)
			UserDefaults.standard.synchronize()
		}
	}
}
