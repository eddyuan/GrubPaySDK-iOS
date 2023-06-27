//
//  GPFromController.swift
//  GrubPaySDK
//
//  Created by Edward Yuan on 2023-05-12.
//

import Foundation

internal class GPFormConfig {
    let channel: GrubPayChannel
    let requireName: Bool
    let requireZip: Bool
    let secureId: String
    let merchantName: String
    let amount: Int
   
    private init(channel: GrubPayChannel, requireName: Bool, requireZip: Bool, secureId: String, merchantName: String?, amount: Int) {
        self.channel = channel
        self.requireName = requireName
        self.requireZip = requireZip
        self.secureId = secureId
        self.merchantName = merchantName ?? "Merchant"
        self.amount = amount
    }
    
    private static func ach(_ secureId: String, requireName: Bool, merchantName: String?, amount: Int) -> GPFormConfig {
        return GPFormConfig(
            channel: .ach,
            requireName: requireName,
            requireZip: false,
            secureId: secureId,
            merchantName: merchantName,
            amount: amount
        )
    }
    
    private static func card(_ secureId: String, requireName: Bool, requireZip: Bool, merchantName: String?, amount: Int) -> GPFormConfig {
        return GPFormConfig(
            channel: .card,
            requireName: requireName,
            requireZip: requireZip,
            secureId: secureId,
            merchantName: merchantName,
            amount: amount
        )
    }
    
    internal static func fromJson(_ json: [String: Any], secureId: String) -> GPFormConfig? {
        guard let channel = json["channel"] as? String else {
            return nil
        }
        guard let mode = GrubPayChannel(rawValue: channel) else {
            return nil
        }
        
        switch mode {
        case .ach:
            return GPFormConfig.ach(
                secureId,
                requireName: tBool(json["requireName"]),
                merchantName: tStringOrNil(json["merchantName"]),
                amount: tInt(json["amount"])
            )
        case .card:
            return GPFormConfig.card(
                secureId,
                requireName: tBool(json["requireName"]),
                requireZip: tBool(json["requireZip"]),
                merchantName: tStringOrNil(json["merchantName"]),
                amount: tInt(json["amount"])
            )
        }
    }
}

internal class GPFormController {
    // MARK: Data
    
    private let serverUrl = "https://api.grubpay.io/v4/"
  
    private var mounted: Bool {
        return config != nil
    }
    
    internal var isFormValid: Bool = false {
        didSet {
            observers.forEach {
                $0.observer?.validDidChange?(isFormValid)
            }
        }
    }
    
    private var _rootVC: UIViewController?
    internal var rootViewController: UIViewController? {
        get {
            return _rootVC ?? UIApplication.shared.windows.first(
                where: { $0.isKeyWindow }
            )?.rootViewController
        } set {
            _rootVC = newValue
        }
    }

    internal var country: GPCountry = .us {
        didSet {
            fields.forEach { $0.observer?.countryDidChange?() }
            observers.forEach { $0.observer?.countryDidChange?() }
        }
    }
    
    internal var style: GPInputStyle = .init() {
        didSet {
            fields.forEach { $0.observer?.styleDidChange?() }
            observers.forEach { $0.observer?.styleDidChange?() }
        }
    }
    
    internal var config: GPFormConfig? {
        didSet {
            fields.forEach { $0.observer?.configDidChange?() }
            observers.forEach { $0.observer?.configDidChange?() }
        }
    }
    
    private func setIsEnabled() {
        let isEnabled = !isLoading && !isPaid && !isFailed
        if self.isEnabled != isEnabled {
            self.isEnabled = isEnabled
        }
    }
    
    internal var isEnabled: Bool = false {
        didSet {
            fields.forEach { $0.observer?.isEnabledDidChange?(isEnabled) }
            observers.forEach { $0.observer?.isEnabledDidChange?(isEnabled) }
        }
    }
    
    internal var isLoading: Bool = false {
        didSet {
            observers.forEach { $0.observer?.isLoadingDidChange?(isLoading) }
            setIsEnabled()
        }
    }
    
    internal var isPaid: Bool = false {
        didSet {
            setIsEnabled()
        }
    }

    internal var isFailed: Bool = false {
        didSet {
            setIsEnabled()
        }
    }
    
    internal var cardBrand: GrubPayCardBrand = .unknown
    
    // MARK: ACH Agreement related
    
    internal var agreeToAch: Bool = false {
        didSet {
            fields.forEach { $0.observer?.didChangeAchAgree?(agreeToAch) }
            observers.forEach { $0.observer?.didChangeAchAgree?(agreeToAch) }
        }
    }
    
    internal func validateAchAgreement(_ completion: @escaping (_ success: Bool) -> Void) {
        guard let mode = config?.channel else {
            completion(false)
            return
        }
        if !agreeToAch && mode == .ach {
            showAchAgreement(completion)
        } else {
            completion(true)
        }
    }
    
    internal func showAchAgreement(
        _ completion: @escaping (_ success: Bool) -> Void = { _ in }
    ) {
        guard let rootViewController = rootViewController else {
            completion(agreeToAch)
            return
        }
        let storeName = config?.merchantName ?? "Merchant"
        let storeNames = storeName + "'" + (storeName.hasSuffix("s") ? "" : "s")
        let message = "By accepting this agreement, you authorize \(storeName) to debit the bank account specified above for any amount owed for charges arising from your use of \(storeNames) services and/or purchase of products from \(storeName), pursuant to \(storeNames) website and terms, until this authorization is revoked. You may amend or cancel this authorization at any time by providing notice to \(storeName) with 30 (thirty) days notice."

        let alertController = UIAlertController(
            title: "ACH Agreement",
            message: message,
            preferredStyle: .alert
        )
        
        if agreeToAch {
            alertController.addAction(
                UIAlertAction(title: "OK", style: .default) {
                    _ in
                    completion(true)
                }
            )
        } else {
            alertController.addAction(
                UIAlertAction(title: "Disagree", style: .default) {
                    [weak self] _ in
                    completion(self?.agreeToAch ?? false)
                }
            )
            alertController.addAction(
                UIAlertAction(title: "Agree", style: .default) {
                    [weak self] _ in
                    self?.agreeToAch = true
                    completion(self?.agreeToAch ?? false)
                }
            )
        }

        rootViewController.present(
            alertController,
            animated: true,
            completion: nil
        )
    }
    
    private func sendPOSTRequest(
        url: String,
        params: [String: Any],
        completion: @escaping (Result<[String: Any], GrubPayError>) -> Void
    ) {
        guard let url = URL(string: serverUrl + url) else {
            completion(.failure(GrubPayError.invalidUrl))
            return
        }
        let uuid = UUID()
        var params = params
        params["uuid"] = uuid.uuidString
        params["device"] = "iOS"
        params["os_version"] = UIDevice.current.systemVersion
        let podBundle = Bundle(for: GPFormController.self)
        if let version = podBundle.infoDictionary?["CFBundleShortVersionString"] as? String {
            params["sdk_version"] = version
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        // Set the Content-Type header
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Convert the parameters to JSON data
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: params, options: [])
            request.httpBody = jsonData
        } catch {
            completion(.failure(GrubPayError.other(error.localizedDescription)))
            return
        }

        let task = URLSession.shared.dataTask(with: request) {
            data, _, error in
            if let error = error {
                completion(.failure(GrubPayError.requireNewSecureId(error.localizedDescription)))
                return
            }

            guard let responseData = data else {
                completion(.failure(GrubPayError.noResponseData))
                return
            }
            
            do {
                guard let json = try JSONSerialization.jsonObject(
                    with: responseData,
                    options: []
                ) as? [String: Any] else {
                    completion(.failure(GrubPayError.noResponseData))
                    return
                }
                
                guard let retCode = json["retCode"] as? String else {
                    completion(.failure(GrubPayError.requireNewSecureId("No retCode found")))
                    return
                }
                guard retCode == "SUCCESS" else {
                    let retMsg = json["retMsg"] as? String ?? "No retMsg found"
                    completion(.failure(GrubPayError.requireNewSecureId(retMsg)))
                    return
                }
                guard let retData = json["retData"] as? [String: Any] else {
                    completion(.failure(GrubPayError.requireNewSecureId("No retData found")))
                    return
                }
                completion(.success(retData))
                return
            } catch {
                completion(.failure(GrubPayError.requireNewSecureId(error.localizedDescription)))
                return
            }
        }

        task.resume()
    }
    
    // MARK: Operations
    
    private var fields: [GPFormObsWeak] = []
    private var observers: [GPFormObsWeak] = []
    
    internal func addField(_ field: GPFormObs) {
        fields.append(GPFormObsWeak(field))
    }
    
    internal func addObs(_ obs: GPFormObs) {
        observers.append(GPFormObsWeak(obs))
    }
    
    internal func removeObs(_ field: GPFormObs) {
        fields.removeAll(where: { $0.observer === field || $0.observer == nil })
        observers.removeAll(where: { $0.observer === field || $0.observer == nil })
    }
    
    internal func onEditChange() {
        var isFormValid = true
        fields.forEach {
            let fieldIsValid = $0.observer?.valid ?? true
            if !fieldIsValid {
                isFormValid = false
                return
            }
        }
        if self.isFormValid != isFormValid {
            self.isFormValid = isFormValid
        }
    }
    
    internal func onFinishField(_ val: GPInputType) {
        fields.forEach { $0.observer?.didFinishField?(val.rawValue) }
    }
    
    internal func scanCard() {
        if #available(iOS 13.0, *) {
            guard let rootViewController = rootViewController else {
                return
            }
            GPCardScanner.showScanner(
                buttonColor: style.accentColor,
                rootViewController: rootViewController
            ) {
                [weak self] card, date in
                self?.fields.forEach { $0.observer?.didScan?(card, date) }
            }
        }
    }
}

internal extension GPFormController {
    func mount(
        _ secureId: String,
        completion: @escaping (Result<GrubPayChannel, GrubPayError>) -> Void
    ) {
        if isLoading {
            completion(.failure(GrubPayError.loading))
            return
        }
        resetConfigs()
        isLoading = true
        
        sendPOSTRequest(
            url: "getChannel",
            params: ["secureId": secureId]
        ) {
            [weak self] result in
            self?.isLoading = false
            switch result {
            case .success(let data):
                guard let config = GPFormConfig.fromJson(data, secureId: secureId) else {
                    completion(.failure(GrubPayError.cannotRetrieveMethod))
                    return
                }
                self?.config = config
                completion(.success(config.channel))
            case .failure(let error):
                completion(.failure(error))
            }
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
            [weak self] in
            if errors.isEmpty {
                self?.validateAchAgreement {
                    result in
                    if result {
                        onSuccess(params)
                    } else {
                        onError(["ACH Agreement"])
                    }
                }
            } else {
                onError(errors)
            }
        }
    }
    
    func submitForm(
        saveCard: Bool = false,
        completion: @escaping (Result<GrubPayResponse, GrubPayError>) -> Void
    ) {
        if isLoading {
            completion(.failure(GrubPayError.loading))
            return
        }
        
        if isPaid {
            completion(.failure(GrubPayError.paid))
            return
        }
        
        if isFailed {
            completion(.failure(GrubPayError.failed))
            return
        }
        
        if !mounted {
            completion(.failure(GrubPayError.mount))
            return
        }
        validate(
            onSuccess: {
                [weak self] params in
                guard let config = self?.config else {
                    completion(.failure(GrubPayError.mount))
                    return
                }
                var _params = params
                if saveCard, config.channel == .card {
                    _params["addUser"] = saveCard
                }
                self?.doSubmit(
                    params: _params,
                    completion: completion
                )
            },
            onError: {
                [weak self] errors in
                self?.isLoading = false
                completion(.failure(GrubPayError.validator(errors)))
            }
        )
    }
    
    func doSubmit(
        params: [String: Any],
        completion: @escaping (Result<GrubPayResponse, GrubPayError>) -> Void
    ) {
        if isLoading {
            completion(.failure(GrubPayError.loading))
            return
        }
        
        if isPaid {
            completion(.failure(GrubPayError.paid))
            return
        }
        
        if isFailed {
            completion(.failure(GrubPayError.failed))
            return
        }
        
        guard let config = config else {
            completion(.failure(GrubPayError.mount))
            return
        }
        isLoading = true
        var params = params
        params["secureId"] = config.secureId
        let cardBrand = cardBrand
        sendPOSTRequest(url: "auth", params: params, completion: {
            [weak self] result in
            switch result {
            case .success(let data):
                self?.isPaid = true
                completion(.success(GrubPayResponse.fromJson(data, brand: cardBrand)))
            case .failure(let error):
                self?.isFailed = true
                completion(.failure(error))
            }
            self?.isLoading = false
        })
    }
    
    private func resetConfigs() {
        if config != nil {
            config = nil
        }
        fields.removeAll()
        if cardBrand != .unknown {
            cardBrand = .unknown
        }
        if isPaid {
            isPaid = false
        }
        if isFailed {
            isFailed = false
        }
        if isLoading {
            isLoading = false
        }
    }
}

internal class GPFormObsWeak {
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
    @objc optional func validDidChange(_ isValid: Bool)
    @objc optional func isEnabledDidChange(_ isEnabled: Bool)
    @objc optional func isLoadingDidChange(_ isLoading: Bool)
    @objc optional func doValidate(
        onSuccess: @escaping (_ param: [String: Any]) -> Void,
        onError: @escaping (_ name: String) -> Void
    )
    @objc optional var valid: Bool { get }
    @objc optional func didScan(_ cardNumber: String?, _ expiryDate: String?)
    @objc optional func didChangeAchAgree(_ val: Bool)
    @objc optional func didFinishField(_ val: Int)
}
