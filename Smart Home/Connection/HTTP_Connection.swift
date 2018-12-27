//
//  JSON_Connection.swift
//  Smart Home
//
//  Created by Joshua Wong on 22/5/2018.
//  Copyright © 2018 Joshua Wong. All rights reserved.
//

import UIKit
import SwiftyJSON

class JSON_CONN: Connection {
	
	static var _timeout: Double = 3
	var timeout: Double {
		return JSON_CONN._timeout
	}
	
	private var conn_url: URL?
	private var valid: Bool = false
	private var queue = [URLSessionDataTask]()
	
	/*-----------------------------------------------
	/
	/	INITIALIZE WITH URL AND/OR PORT
	/
	/ ---------------------------------------------*/
	
	init(url: URL) {
		conn_url = url
		valid = true
	}
	
	init?(url: String) {
		if (isValidURL(url: url)) {
			conn_url = URL(string: url)
			valid = true
		} else {
			return nil
		}
	}
	
	private func isValidURL(url: String?) -> Bool {
		
		//Check for nil
		if let url = url {
			// create NSURL instance
			if URL(string: url) != nil {
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
	
	func getURL() -> URL {
		return conn_url!
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
	
	/*-----------------------------------------------
	/
	/	HTTP(S) JSON POST REQUESTS
	/
	/ ---------------------------------------------*/
	
	// Public Send Function
	func send_string(json: String) -> (cancelled: Bool, response: String?) {
		return POST(json: json)
	}
	
	static func do_GET(url: URL) -> String? {
		return do_HTTP(url: url, type: "GET", post_contents: "")
	}
	
	static func do_POST(url: URL, post_contents: String) -> String? {
		return do_HTTP(url: url, type: "POST", post_contents: post_contents)
	}
	
	// Static Send Function
	static func do_HTTP(url: URL, type: String, post_contents: String) -> String? {
		
		let session = URLSession.shared
		var request = URLRequest(url: url)
		
		request.httpMethod = type
		request.cachePolicy = NSURLRequest.CachePolicy.reloadIgnoringCacheData
		URLCache.shared.removeCachedResponse(for: request as URLRequest)
		
		if (type == "POST") {
			request.httpBody = post_contents.data(using: String.Encoding.utf8)
			request.addValue("application/json", forHTTPHeaderField: "Content-Type")
		}
		
		var dataString: String? = nil
		var success = false
		
		let task = session.dataTask(with: request as URLRequest) {
			(data, response, error) in
			
			guard let data = data, let _:URLResponse = response, error == nil else {
				print("error")
				return
			}
			
			dataString =  String(data: data, encoding: String.Encoding.utf8)
			success = true
		}
		
		let current_time = DispatchTime.now().uptimeNanoseconds
		task.resume()
		
		// Wait til task comes back or timeout in 5 seconds
		while (!success && DispatchTime.now().uptimeNanoseconds - current_time < UInt64(_timeout*1e9)) {}
		
		if (debug_contains(type: .JSON)) {
			print("URL: " + url.absoluteString)
			print("/*******************************")
			print(dataString ?? "RESPONSE NIL")
			print("*******************************/")
			print("\n\n")
		}
		
		return (dataString)
	}
	
	// Private Send Function with URL override
	private func POST(url_override: URL? = nil, json: String) -> (cancelled: Bool, response: String?) {
		
		// Check Valid
		if (!valid) { return (false, nil) }
		
		// Check URL
		var url_type: URL
		if (url_override != nil) {
			url_type = url_override!
		} else {
			if (conn_url == nil) {
				return (false, nil)
			} else {
				url_type = conn_url!
			}
		}
		
		// Check existing queues with the same data
		for operation_q in queue {
			if (operation_q.taskDescription == json) {
				operation_q.cancel()
			}
		}
		
		// Send Data
		return POST_SubFunc(url_type: url_type, json: json)
		
	}
	
	private func POST_SubFunc(url_type: URL, json: String) -> (cancelled: Bool, response: String?) {
		
		let session = URLSession.shared
		var request = URLRequest(url: url_type)

		request.addValue("application/json", forHTTPHeaderField: "Content-Type")
		request.httpMethod = "POST"
		request.cachePolicy = NSURLRequest.CachePolicy.reloadIgnoringCacheData
		
		request.httpBody = json.data(using: String.Encoding.utf8)
		var dataString: String? = nil
		var success = false
		
		let task = session.dataTask(with: request as URLRequest) {
			(data, response, error) in
			
			guard let data = data, let _:URLResponse = response, error == nil else {
				print("error")
				return
			}
			
			dataString =  String(data: data, encoding: String.Encoding.utf8)
			success = true
		}
		
		// Define task by json
		task.taskDescription = json
		queue.append(task)
		
		let current_time = DispatchTime.now().uptimeNanoseconds
		task.resume()
		
		// Wait til task comes back or timeout in 5 seconds
		while (!success && DispatchTime.now().uptimeNanoseconds - current_time < UInt64(timeout*1e9)) {
			
			// Check for terminate
			if #available(iOS 11.0, *) {
				if (task.progress.isCancelled) {
					print("Task Terminated by Newer Task!")
					return (true, nil)
				}
			} else {
				// Fallback on earlier versions
				// Just wait the full 5 seconds
			}
			
		}
		if (debug_contains(type: .JSON)) {
			print("JSON RESPONSE")
			print("/*******************************")
			print(dataString ?? "RESPONSE NIL")
			print("*******************************/")
			print("\n\n")
		}
		
		return (false, dataString)
	}
	
}

