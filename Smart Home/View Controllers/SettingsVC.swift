//
//  SettingsVC.swift
//  Smart Home
//
//  Created by Joshua Wong on 2/1/2019.
//  Copyright © 2019 Joshua Wong. All rights reserved.
//

import UIKit
import QuickTableViewController

class SettingsVC: QuickTableViewController {
	
	override func viewDidLoad() {
		super.viewDidLoad()
		print("hello")
		tableContents = [
			Section(title: "Switch", rows: [
				SwitchRow(title: "Phoebe Fung", switchValue: true, action: { _ in }),
				]),
			
			Section(title: "Tap Action", rows: [
				//TapActionRow(title: "Delete Phoebe", action: { [weak self] in self?.showAlert($0) })
				TapActionRow(title: "K Bye", action: { [weak self] in self?.showAlert($0) }),
				TapActionRow(title: "Delete Phoebe!", customization: { cell, _ in
					cell.textLabel?.textColor = .red
				}, action: { [weak self] in self?.showAlert($0) })
				]),
			
			Section(title: "Navigation", rows: [
				NavigationRow(title: "CellStyle.default", subtitle: .none, icon: .named("gear")),
				NavigationRow(title: "CellStyle", subtitle: .rightAligned(".value1"), icon: .named("time"), action: { _ in }),
				]),
			
			RadioSection(title: "Phoebe is: ", options: [
				OptionRow(title: "So ma fan", isSelected: true, action: didToggleOption()),
				OptionRow(title: "Chopstick", isSelected: false, action: didToggleOption()),
				OptionRow(title: "Spoon", isSelected: false, action: didToggleOption())
				], footer: "See Phoebe for more details.")
		]
	}

	private func showAlert(_ sender: Row) {
		// ...
	}
	
	private func didToggleOption() -> (Row) -> Void {
		return { [weak self] row in
			// ...
		}
	}
}
