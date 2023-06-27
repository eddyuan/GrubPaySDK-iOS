//
//  GPCountryPicker.swift
//  GrubPaySDK
//
//  Created by Edward Yuan on 2023-05-11.
//

import Foundation

import UIKit

class GPPickerCountry: UIPickerView {
    private let countries = GPCountry.allCases

    var country: GPCountry {
        get {
            let selectedRow = self.selectedRow(inComponent: 0)
            return countries[selectedRow]
        }
        set {
            if let row = countries.firstIndex(of: newValue) {
                self.selectRow(row, inComponent: 0, animated: false)
            }
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupPickerView()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupPickerView()
    }

    private func setupPickerView() {
        delegate = self
        dataSource = self
    }
}

extension GPPickerCountry: UIPickerViewDelegate {
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return countries[row].rawValue
    }
}

extension GPPickerCountry: UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return countries.count
    }
}
