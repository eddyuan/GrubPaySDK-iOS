//
//  ViewController.swift
//  GrubPaySDK
//
//  Created by 43017558 on 04/21/2023.
//  Copyright (c) 2023 43017558. All rights reserved.
//

import GrubPaySDK
import UIKit

import CommonCrypto

class ViewController: UIViewController {
    // MARK: - Config For Testing

    let mchId = "10001321"
    let loginName = "eway"
    let mchKey = "LkFe0lpxjFUU27xh9hXhPxU2yztzIcgv"
    let requestUrl = "https://test.grubpay.io/laravel/api/auth"

    // MARK: - Properties

    let contentInsets = UIEdgeInsets(
        top: 48,
        left: 0,
        bottom: 48,
        right: 0
    )

    // MARK: EMethod 1: Embed GrubPayElement in your UI

    // GrubPayElement is a UIView that will render a form when mount() is successully called
    // When mount() not called, it shows a placeholder with a spinner loading indicator
    // When submitted, the form will be disabled.
    private lazy var grubpayElement: GrubPayElement = {
        let el = GrubPay.element(
            viewController: self,
            onValidChange: {
                isValid in
                // This is a Bool value indicate if the form input is valid
                // You can update your submit button's status for a reactive button style
                print("isValid", isValid)
            },
            onEnableChange: {
                isEnabled in
                // This is when enabled status changed on the form
                // It is different from the loading status, because the form will remain disabled
                // upon response from our server, regarless succeeded or failed
                print("isEnabled", isEnabled)
            },
            onLoadingChange: {
                isLoading in
                // This is when the loading status changed on the form
                print("isLoading", isLoading)
            }
        )
        el.inputStyle = GPInputStyle()
        return el
    }()

    // When you received secureId from your server, you can call mount() on the grubpayElement
    // This will render grubpayElement as an input form
    func mountGrubPay(_ secureId: String) {
        grubpayElement.mount(secureId) {
            result in
            switch result {
            case .success(let channel):
                print(channel)
            case .failure(let error):
                // This is usually caused by incorrect secureId or some network error
                // Retry .mount() with another secureId
                print("mount error", error.message)
            }
        }
    }

    @objc func onMountButton() {
        getSecureIdFromYourServer {
            result in
            switch result {
            case .success(let secureId):
                self.mountGrubPay(secureId)
            case .failure(let error):
                // Error from your server
                print("Get secureId error", error)
            }
        }
    }

    @objc func onSubmitButton() {
        grubpayElement.submit(
            saveCard: true,
            completion: {
                result in
                switch result {
                case .success:
                    print("success")
                case .failure(let error):
                    print(error.type)
                    print(error.message)
                }
            }
        )
    }

    private lazy var mountButton: UIButton = {
        let b = UIButton(type: .system)
        b.backgroundColor = UIColor.systemBlue
        b.setTitleColor(UIColor.white, for: .normal)
        b.setTitle("Mount", for: .normal)
        b.addTarget(self, action: #selector(onMountButton), for: .touchUpInside)
        return b
    }()

    private lazy var submitButton: UIButton = {
        let b = UIButton(type: .system)
        b.backgroundColor = UIColor.systemGreen
        b.setTitleColor(UIColor.white, for: .normal)
        b.setTitle("Submit", for: .normal)
        b.addTarget(self, action: #selector(onSubmitButton), for: .touchUpInside)
        return b
    }()

    // MARK: Method 2: Call launch to show in a new modal

    @objc func onLaunchButton() {
        getSecureIdFromYourServer {
            result in
            switch result {
            case .success(let secureId):
                self.launchGrubPay(secureId)
            case .failure(let error):
                print(error)
            }
        }
    }

    func launchGrubPay(_ secureId: String) {
        GrubPay.launch(secureId, viewController: self) {
            [weak self] result in
            switch result {
            case .success(let response):
                self?.handleResponse(response)
            case .failure(let error):
                self?.handleError(error)
            }
        }
    }

    private lazy var launchButton: UIButton = {
        let b = UIButton(type: .system)
        b.backgroundColor = UIColor.systemBlue
        b.setTitleColor(UIColor.white, for: .normal)
        b.setTitle("Launch", for: .normal)
        b.addTarget(self, action: #selector(onLaunchButton), for: .touchUpInside)
        return b
    }()

    // MARK: Handle results and errors

    func handleResponse(_ response: GrubPayResponse) {
        // This means the payment or tokenize succeeded.

        // It is recommanded that you query the order with our server to validate if this is a payment

        // Order detail can be founded at response.order

        print(response)
        // This is the original JSON from our server
        print(response.json)

        // Below are formatted properties
        print(response.capture)
        print(response.returnUrl)
        if let order = response.order {
            print(order)
            print(order.payOrderId)
            print(order.mchId)
            print(order.mchOrderNo)
            print(order.amount)
            print(order.status)
            // .... etc
        }
        if let creditCard = response.creditCard {
            print(creditCard.cardNum)
            print(creditCard.cardType)
            print(creditCard.token)
            print(creditCard.zip)
            print(creditCard.pan)
        }
        if let achAccount = response.achAccount {
            print(achAccount.acctNum)
            print(achAccount.token)
        }
    }

    func handleError(_ error: GrubPayError) {
        print(error.message)
        if error.requireNewSecureId {
            print("This means the current secureId will be invalid on next call, in order to retry, you will need to call mount() or launch() again with a new secureId. Remember, once a secureId is sent to our server, it will be marked as invalid upon callback regardless payment succeeded or failed. So unless it's validator error which is not sent to our server, almost all other errors will result in requireNewSecureId")
        } else {
            print("This means you don't have to do anything, user can simply retry")
        }
        switch error.type {
        case .cancel:
            print("User cancelled the request")
        case .failed:
            print("Payment failed")
        case .loading:
            print("Previous request not completed yet, please wait")
        case .mount:
            print("Submit is called before mount, you need to call mount first")
        case .network:
            print("This is network error")
        case .paid:
            print("This secureId is already paid")
        case .secureId:
            print("Invalid secureId")
        case .server:
            print("Server responded with some error")
        case .timeout:
            print("Request timeout, this error is not implemented yet")
        case .validator:
            print("Form validation failed, no action required, but you can show some UI to notify user that there are some errors on the input")
            print("Names of the error fields", error.validatorErrors!)
        case .viewController:
            print("A root viewController is not found, try to provide your own ViewController")
        case .other:
            print("Some other errors")
        }
    }

    // MARK: View hierarchy

    private lazy var stackView: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical
        sv.spacing = 8
        sv.alignment = .fill
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.addArrangedSubview(grubpayElement)
        sv.addArrangedSubview(mountButton)
        sv.addArrangedSubview(submitButton)
        sv.addArrangedSubview(launchButton)
        return sv
    }()

    private lazy var scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.backgroundColor = GPInputStyle.getAdaptiveColor(light: UIColor.white, dark: UIColor.black)
        if let window = UIApplication.shared.windows.first {
            let topPadding = window.safeAreaInsets.top
            sv.contentInset.top = topPadding
            sv.scrollIndicatorInsets.top = topPadding
        }
        sv.addSubview(stackView)
        return sv
    }()

    // MARK: Overrides

    override func viewDidLoad() {
        super.viewDidLoad()

        // Add the scrollView
        view.addSubview(scrollView)

        // Setup the layout
        setupLayout()
    }

    deinit {
        // Remove keyboard listener
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }

    // MARK: Addition optimizations

    func addKeyboardListenerAndTouchToDismissKeyboard() {
        // Adjust layout when keyboard show/hide
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)

        // Tap outside to dismiss input
        let tapGesture = UITapGestureRecognizer(
            target: self,
            action: #selector(dismissKeyboard)
        )
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }

    @objc func keyboardWillShow(_ notification: Notification) {
        guard let keyboardFrame = notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue else {
            return
        }
        let keyboardHeight = keyboardFrame.cgRectValue.height
        let targetInset = UIEdgeInsets(
            top: contentInsets.top,
            left: contentInsets.left,
            bottom: contentInsets.bottom + keyboardHeight,
            right: contentInsets.right
        )
        scrollView.contentInset = targetInset
        scrollView.scrollIndicatorInsets = targetInset
    }

    @objc func keyboardWillHide(_ notification: Notification) {
        scrollView.contentInset = contentInsets
        scrollView.scrollIndicatorInsets = contentInsets
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    // MARK: - Helper Methods

    private func setupLayout() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -32),
        ])
    }
}

extension ViewController {
    // Request related

    func sendPOSTRequest(
        url: String,
        params: [String: Any],
        completion: @escaping (Result<Data, Error>) -> Void
    ) {
        guard let url = URL(string: url) else {
            let error = NSError(domain: "Invalid URL", code: 0, userInfo: nil)
            completion(.failure(error))
            return
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
            completion(.failure(error))
            return
        }

        let task = URLSession.shared.dataTask(with: request) { data, _, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let responseData = data else {
                let error = NSError(domain: "No data in response", code: 0, userInfo: nil)
                completion(.failure(error))
                return
            }

            completion(.success(responseData))
        }

        task.resume()
    }

    func signMap(
        _ hashmap: [String: Any],
        mchKey: String
    ) -> [String: Any] {
        let sortedQuery = hashmap
            .compactMap { key, value -> String? in
                switch value {
                case let stringValue as String:
                    return "\(key)=\(stringValue)"
                case let intValue as Int:
                    return "\(key)=\(intValue)"
                case let floatValue as CGFloat:
                    return "\(key)=\(floatValue)"
                case let boolValue as Bool:
                    return "\(key)=\(boolValue)"
                default:
                    return nil
                }
            }
            .sorted()
            .joined(separator: "&")
            +
            "&key=\(mchKey)"
        let sign = calculateMD5Hash(sortedQuery).uppercased()
        let result = hashmap.merging(["sign": sign], uniquingKeysWith: { _, new in new })
        print("signed JSON =>", result)
        return result
    }

    func calculateMD5Hash(_ input: String) -> String {
        if let data = input.data(using: .utf8) {
            var digest = [UInt8](repeating: 0, count: Int(CC_MD5_DIGEST_LENGTH))
            _ = data.withUnsafeBytes { (bytes: UnsafePointer<UInt8>) in
                CC_MD5(bytes, CC_LONG(data.count), &digest)
            }

            var md5String = ""
            for byte in digest {
                md5String += String(format: "%02x", byte)
            }
            return md5String
        }
        return ""
    }

    func getSecureIdFromYourServer(completion: @escaping (Result<String, Error>) -> Void) {
        let originalParams: [String: Any] = [
            "mchId": mchId,
            "mchOrderNo": "test\(Date().timeIntervalSince1970)",
            "amount": 1,
            "currency": "USD",
            "loginName": loginName,
            "channel": arc4random_uniform(2) == 0 ? "CC_CARD" : "CC_ACH",
            "capture": "N",
        ]

        let signedParams = signMap(
            originalParams,
            mchKey: mchKey
        )

        sendPOSTRequest(
            url: requestUrl,
            params: signedParams
        ) {
            result in
            switch result {
            case .success(let data):
                do {
                    // Parse the response data as JSON
                    if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                        // Handle the JSON dictionary
                        print("VC Res: \(json)")
                        if json["retCode"] as? String == "SUCCESS" {
                            if let retData = json["retData"] as? [String: Any], let secureId = retData["secureId"] as? String {
                                completion(.success(secureId))
                            } else {
                                completion(.failure(CustomError("secureId not found in response")))
                            }
                        } else {
                            completion(.failure(CustomError((json["retMsg"] as? String) ?? "Error and no retMsg found")))
                        }
                    } else {
                        completion(.failure(CustomError("Invalid JSON format")))
                    }
                } catch {
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}

class CustomError: Error {
    let message: String!

    init(_ message: String) {
        self.message = message
    }
}
