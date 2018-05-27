//
//  IP_Connection.swift
//  Smart Home
//
//  Created by Joshua Wong on 14/5/2018.
//  Copyright © 2018 Joshua Wong. All rights reserved.
//

import UIKit

class IP_CONN {
	
	let default_port = 9999
	
	private var conn_ip: String?
	private var conn_port: Int?
	private var able_to_connect: Bool = false
	private var valid: Bool = false
	
	init(ip: String, port: Int) {
		var valid: Bool
		(valid, self.conn_ip, self.conn_port) = isValidIPPort(str: (ip + ":" + String(port)), def_port: self.default_port)
		self.valid = valid
	}
	
	init(string: String) {
		var valid: Bool
		(valid, self.conn_ip, self.conn_port) = isValidIPPort(str: string, def_port: self.default_port)
		self.valid = valid
	}
	
	func ableConnect() -> Bool {
		return self.able_to_connect
	}
	
	func isValid() -> Bool {
		return self.valid
	}
	
	func returnIP() -> String? {
		return conn_ip
	}
	
	func returnPort() -> Int? {
		return conn_port
	}
	
	private func isValidIPPort(str: String, def_port: Int) -> (valid: Bool, ip: String?, port: Int?) {
		let split = str.components(separatedBy: ":")
		let num_colons = split.count - 1
		if (num_colons > 1) { return (false, nil, nil) }
		
		var ip_str: String
		var _port: Int
		// Default Port
		if (num_colons == 0) {
			ip_str = str
			_port = def_port
		}
		else {
			ip_str = split[0]
			if (split[1] == "") { _port = def_port }
			else if (Int(split[1]) == nil) { return (false, nil, nil) }
			else { _port = Int(split[1])! }
		}
		
		// Check Port
		if (_port < 1 && _port > 65535) { return (false, nil, nil) }
		
		// Check IP
		let parts = ip_str.components(separatedBy: ".")
		let nums = parts.compactMap { Int($0) }
		if !(parts.count == 4 && nums.count == 4 && nums.filter { $0 >= 0 && $0 < 255}.count == 4) {
			return (false, nil, nil)
		}
		
		return (true, ip_str, _port)
	}
	
	// TCP Socket Functions

	private func sendReq(data: [UInt8]) -> (success: Bool, receive : [UInt8]?) {
		if (!self.valid) { return (false, [0]) }
		var inp: InputStream?
		var out: OutputStream?
		Stream.getStreamsToHost(withName: self.conn_ip!, port: self.conn_port!, inputStream: &inp, outputStream: &out)
		if (inp == nil || out == nil) { return (false, [0]) }
		let inputStream = inp!
		let outputStream = out!
		
		inputStream.open()
		outputStream.open()
		var buffer: [UInt8] = data
		
		// Retry until timeout of 2s
		var loop = true
		let timeout = DispatchTime.now().uptimeNanoseconds
		
		while (loop) {
			switch outputStream.streamStatus {
			case .error, .notOpen, .atEnd, .closed:
				return (false, nil)
			case .opening:
				break
			case .open, .reading, .writing:
				loop = false
				break
			}
			if (DispatchTime.now().uptimeNanoseconds - timeout > UInt64(2e9)) { return (false, [0]) }
		}
		outputStream.write(&buffer, maxLength: buffer.count)
		let bufferSize = 1024
		var inputBuffer = Array<UInt8>(repeating: 0, count: bufferSize)
		inputStream.read(&inputBuffer, maxLength: bufferSize)
		return (true, inputBuffer)
	}
	
	public func send_data(data: [UInt8]) -> [UInt8]? {
		if (!self.valid) {
			self.able_to_connect = false
			return nil
		}
		var receive: [UInt8]?
		(self.able_to_connect, receive) = sendReq(data: data)
		if (receive == nil) { return nil }
		
		var response: [UInt8] = Array()
		for i in receive! {
			if (i != 0) { response.append(i) }
		}
		return response
	}
}
