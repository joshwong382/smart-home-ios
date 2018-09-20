//
//  Segue.swift
//  Smart Home
//
//  Created by Joshua Wong on 20/6/2018.
//  Copyright © 2018 Joshua Wong. All rights reserved.
//

import Foundation

import UIKit

class UIStorySegueR: UIStoryboardSegue {
	
	override func perform() {
		
		let src = self.source
		let dst = self.destination
		let transition: CATransition = CATransition()
		let timeFunc = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
		transition.duration = 0.3
		transition.timingFunction = timeFunc
		transition.type = CATransitionType.push
		transition.subtype = CATransitionSubtype.fromRight
		
		src.view.window?.layer.add(transition, forKey: nil)
		src.present(dst, animated: false, completion: nil)
	}
	
}

class UIViewContR: UIViewController {
	
	func dismiss() {
		
		let transition: CATransition = CATransition()
		let timeFunc = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
		transition.duration = 0.3
		transition.timingFunction = timeFunc
		transition.type = CATransitionType.reveal
		transition.subtype = CATransitionSubtype.fromLeft
		self.view.window?.layer.add(transition, forKey: nil)
		self.dismiss(animated: false, completion: nil)
		
	}
}

class UIStorySegueL: UIStoryboardSegue {
	
	override func perform() {
		
		let src = self.source
		let dst = self.destination
		let transition: CATransition = CATransition()
		let timeFunc = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
		transition.duration = 0.3
		transition.timingFunction = timeFunc
		transition.type = CATransitionType.push
		transition.subtype = CATransitionSubtype.fromLeft
		
		src.view.window?.layer.add(transition, forKey: nil)
		src.present(dst, animated: false, completion: nil)
	}
	
}

class UIViewContL: UIViewController {
	
	func dismiss() {
		
		let transition: CATransition = CATransition()
		let timeFunc = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
		transition.duration = 0.3
		transition.timingFunction = timeFunc
		transition.type = CATransitionType.reveal
		transition.subtype = CATransitionSubtype.fromRight
		self.view.window?.layer.add(transition, forKey: nil)
		self.dismiss(animated: false, completion: nil)
		
	}
}
