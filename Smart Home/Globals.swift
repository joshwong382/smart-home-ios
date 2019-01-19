//
//  Globals.swift
//  Smart Home
//
//  Created by Joshua Wong on 29/12/2018.
//  Copyright © 2018 Joshua Wong. All rights reserved.
//

// Useful Functions
import UIKit
import SwiftyJSON

// GLOBALS
let protocols = proto_db()
let debug: [DEBUG_STR] = []

// Global Extensions
enum DEBUG_STR {
	case JSON
	case TCP
	case UIViewWelcome
	case TokenUpdate
	case DATA
}

// No Fields Required = 0
// First Field Required = 1
// Both Fields Required = 2
enum FIELD_REQUIREMENTS {
	case NO_REQUIREMENTS
	case FIRST_FIELD
	case BOTH_FIELDS
}

func twoDigitInt(int: Int) -> String {
	if (int < 10) { return ("0" + String(int)) }
	else { return String(int) }
}

func secToTime (seconds : Int) -> (Int, Int, Int) {
	return (seconds / 3600, (seconds % 3600) / 60, (seconds % 3600) % 60)
}

// Extensions

extension StringProtocol {
	var ascii: [UInt32] {
		return unicodeScalars.filter{$0.isASCII}.map{$0.value}
	}
}
extension Character {
	var ascii: UInt32? {
		return String(self).unicodeScalars.filter{$0.isASCII}.first?.value
	}
}

extension String {
	func toJSON() -> Any? {
		guard let data = self.data(using: .utf8, allowLossyConversion: false) else { return nil }
		return try? JSONSerialization.jsonObject(with: data, options: .mutableContainers)
	}
}

extension UILabel {
	func loadingIndicator(_ show: Bool) {
		let tag = 808404
		if show {
			self.isEnabled = false
			self.alpha = 0.5
			let indicator = UIActivityIndicatorView(style: .gray)
			let buttonHeight = self.bounds.size.height
			let buttonWidth = self.bounds.size.width
			indicator.center = CGPoint(x: buttonWidth/2, y: buttonHeight/2)
			indicator.tag = tag
			self.addSubview(indicator)
			indicator.startAnimating()
		} else {
			self.isEnabled = true
			self.alpha = 1.0
			if let indicator = self.viewWithTag(tag) as? UIActivityIndicatorView {
				indicator.stopAnimating()
				indicator.removeFromSuperview()
			}
		}
	}
}

extension UITableViewCell {
	var api_offline: Bool {
		var uilabel_text: String? = nil
		DispatchQueue.main.async {
			if let accessoryView = self.accessoryView as? UILabel {
				uilabel_text = accessoryView.text
			}
		}
		
		if (uilabel_text == "Offline") {
			return true
		}
		return false
	}
}
