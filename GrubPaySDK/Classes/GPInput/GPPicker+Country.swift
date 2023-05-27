//
//  GPCountryPicker.swift
//  GrubPaySDK
//
//  Created by Edward Yuan on 2023-05-11.
//

import Foundation

import UIKit

enum GPCountry: CaseIterable {
    case us,
         ca,
         uk,
         others

    var name: String {
        switch self {
        case .us:
            return "US"
        case .ca:
            return "Canada"
        case .uk:
            return "UK"
        case .others:
            return "Others"
        }
    }

    var zipName: String {
        switch self {
        case .us:
            return "Zip"
        default:
            return "Postal"
        }
    }

    var zipPh: String {
        switch self {
        case .us:
            return "#####"
        case .ca:
            return "A1A 1A1"
        case .uk:
            return "WS11 1DB"
        default:
            return "#####"
        }
    }

    var inputMask: String? {
        switch self {
        case .us:
            return "#####-####"
        case .ca:
            return "A#A #A#"
        case .uk:
            return "AA## #AA"
        default:
            return nil
        }
    }

    var keyboardType: UIKeyboardType {
        switch self {
        case .us:
            return .numberPad
        default:
            return .default
        }
    }

    func validateText(_ text: String) -> Bool {
        switch self {
        case .us:
            return text.count > 4
        case .ca:
            return text.count == 7
        case .uk:
            return text.count > 3
        default:
            return true
        }
    }
}

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
        return countries[row].name
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
