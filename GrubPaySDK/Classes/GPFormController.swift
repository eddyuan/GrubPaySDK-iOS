//
//  GPFromController.swift
//  GrubPaySDK
//
//  Created by Edward Yuan on 2023-05-12.
//

import Foundation

enum GPFormMode: Int {
    case ach,
         card
}

// struct GPField {
//    let valid: Bool
//    let name: String
//    let value: Any
// }

class GPFormConfig {
    let mode: GPFormMode
    let requireName: Bool
    let requireZip: Bool
    let secureId: String
    let merchantName: String
    private init(mode: GPFormMode, requireName: Bool, requireZip: Bool, secureId: String, merchantName: String) {
        self.mode = mode
        self.requireName = requireName
        self.requireZip = requireZip
        self.secureId = secureId
        self.merchantName = merchantName
    }
    
    static func ach(_ secureId: String, merchantName: String) -> GPFormConfig {
        return GPFormConfig(
            mode: .ach,
            requireName: true,
            requireZip: false,
            secureId: secureId,
            merchantName: merchantName
        )
    }
    
    static func card(_ secureId: String, requireName: Bool, requireZip: Bool, merchantName: String) -> GPFormConfig {
        return GPFormConfig(
            mode: .card,
            requireName: requireName,
            requireZip: requireZip,
            secureId: secureId,
            merchantName: merchantName
        )
    }
}

class GPFormController {
    func initialize(
        _ secureId: String,
        onSuccess: @escaping ((GPFormConfig) -> Void),
        onError: @escaping ((String) -> Void)
    ) {
        if isLoading {
            onError("Loading")
            return
        }
        isLoading = true
        fields.removeAll()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            let config: GPFormConfig!
            if secureId == "demoCard" {
                config = GPFormConfig.card(
                    "demoCard",
                    requireName: true,
                    requireZip: true,
                    merchantName: "Some test merchant"
                )
            } else {
                config = GPFormConfig.ach(
                    "demoAch",
                    merchantName: "Some test merchant"
                )
            }
            self.config = config
            onSuccess(config)
            self.isLoading = false
        }
    }
    
    private var fields: [GPFormObsWeak] = []
    private var observers: [GPFormObsWeak] = []
    
    // MARK: Operations
    
    func addField(_ field: GPFormObs) {
        fields.append(GPFormObsWeak(field))
    }
    
    func addObs(_ obs: GPFormObs) {
        fields.append(GPFormObsWeak(obs))
    }
    
    func removeObs(_ field: GPFormObs) {
        fields.removeAll(where: { $0.observer === field || $0.observer == nil })
        observers.removeAll(where: { $0.observer === field || $0.observer == nil })
    }
    
    func notifyFieldChange() {
        fields.forEach { $0.observer?.fieldDidChange?() }
    }
    
    // MARK: Data

    var country: GPCountry = .us {
        didSet {
            fields.forEach { $0.observer?.countryDidChange?() }
            observers.forEach { $0.observer?.countryDidChange?() }
        }
    }
    
    var style: GPInputStyle = .init() {
        didSet {
            fields.forEach { $0.observer?.styleDidChange?() }
            observers.forEach { $0.observer?.styleDidChange?() }
        }
    }
    
    var config: GPFormConfig? {
        didSet {
            fields.forEach { $0.observer?.configDidChange?() }
            observers.forEach { $0.observer?.configDidChange?() }
        }
    }
    
    var isLoading: Bool = false {
        didSet {
            fields.forEach { $0.observer?.loadingDidChange?() }
        }
    }
    
    func validate(
        onSuccess: @escaping ([String: Any]) -> Void,
        onError: @escaping ([String]) -> Void
    ) {
        let group = DispatchGroup()
        var params: [String: Any] = [:]
        var errors: [String] = []
        fields.forEach { field in
            group.enter()
            if field.observer?.doValidate == nil {
                group.leave()
            } else {
                field.observer!.doValidate!(
                    onSuccess: {
                        param in
                        params.merge(param) { _, new in new }
                        group.leave()
                    },
                    onError: {
                        errorName in
                        errors.append(errorName)
                        group.leave()
                    }
                )
            }
        }
        group.notify(queue: DispatchQueue.main) {
            print("Params:", params)
            print("Errors:", errors)
            if errors.isEmpty {
                onSuccess(params)
            } else {
                onError(errors)
            }
        }
    }
    
    func submitForm() {
        validate(
            onSuccess: {
                params in
                self.doSubmit(params)
            },
            onError: {
                errors in
                print(errors)
            }
        )
    }
    
    func doSubmit(_: [String: Any]) {
        isLoading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.isLoading = false
        }
    }
}

class GPFormObsWeak {
    weak var observer: GPFormObs?

    init(_ observer: GPFormObs) {
        self.observer = observer
    }
}

// DataObserver
@objc protocol GPFormObs: AnyObject {
    @objc optional func styleDidChange()
    @objc optional func countryDidChange()
    @objc optional func configDidChange()
    @objc optional func fieldDidChange()
    @objc optional func loadingDidChange()
    @objc optional func doValidate(
        onSuccess: @escaping (_ param: [String: Any]) -> Void,
        onError: @escaping (_ name: String) -> Void
    )
    @objc optional var valid: Bool { get }
}
