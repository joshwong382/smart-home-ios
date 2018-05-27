//
//  JSON_Connection.swift
//  Smart Home
//
//  Created by Joshua Wong on 22/5/2018.
//  Copyright © 2018 Joshua Wong. All rights reserved.
//

import UIKit
import SwiftyJSON

class JSON_CONN {
	
	var connected: Bool = false
	
	init() {
		if (testPOST() == "SUCCESS") {
			connected = true
			print("Connected to Josh's Server")
		}
	}
	
	private func isValidURL(url: String?) -> Bool {
		
		//Check for nil
		if let url = url {
			// create NSURL instance
			if let urlobj = URL(string: url) {
				return true
			}
		}
		return false
	}
	
	private func isValidJSON(json: String?) -> Bool {
		if (json == nil) { return false }
		let jsonData = json?.data(using: String.Encoding.utf8)
		return JSONSerialization.isValidJSONObject(jsonData!)
	}
	
	func JSONtoString(json: Any, prettyPrinted: Bool = false) -> String {
		var options: JSONSerialization.WritingOptions = []
		if prettyPrinted {
			options = JSONSerialization.WritingOptions.prettyPrinted
		}
		
		do {
			let data = try JSONSerialization.data(withJSONObject: json, options: options)
			if let string = String(data: data, encoding: String.Encoding.utf8) {
				return string
			}
		} catch {
			print(error)
		}
		
		return ""
	}
	
	func StringtoJSON(string: String) -> JSON {
		return JSON(parseJSON: string)
	}
	
	func testPOST() -> String? {
		let jsonObject: [String: Any]  = [
			"test": "SUCCESS"
		]
		
		return POST(url: "https://ca.josh-wong.net/public/testpost.php", json: JSONtoString(json: jsonObject))
	}
	
	func POST(url: String, json: String) -> String? {
		
		if (!isValidURL(url: url)) { return nil }
		
		let url_type: URL = URL(string: url)!
		let session = URLSession.shared
		
		var request = URLRequest(url: url_type)
		request.addValue("application/json", forHTTPHeaderField: "Content-Type")
		request.httpMethod = "POST"
		request.cachePolicy = NSURLRequest.CachePolicy.reloadIgnoringCacheData
		
		request.httpBody = json.data(using: String.Encoding.utf8)
		var dataString: String? = nil
		var success = false
		
		let task = session.dataTask(with: request as URLRequest) {
			(
			data, response, error) in
			
			guard let data = data, let _:URLResponse = response, error == nil else {
				print("error")
				return
			}
			
			dataString =  String(data: data, encoding: String.Encoding.utf8)
			success = true
		}
		
		task.resume()
		
		// Wait til task comes back
		while (!success) {}
		
		return dataString
	}
}
