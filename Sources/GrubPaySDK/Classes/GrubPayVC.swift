//
//  GrubPayVC.swift
//  GrubPaySDK
//
//  Created by Edward Yuan on 2023-06-22.
//
import Foundation
import UIKit

internal extension UIResponder {
    private weak static var _currentFirstResponder: UIResponder?

    static var currentFirstResponder: UIResponder? {
        _currentFirstResponder = nil
        UIApplication.shared.sendAction(#selector(findFirstResponder(_:)), to: nil, from: nil, for: nil)
        return _currentFirstResponder
    }

    @objc private func findFirstResponder(_ sender: Any) {
        UIResponder._currentFirstResponder = self
    }
}

class GrubPayVC: UIViewController {
    private let contentInsets = UIEdgeInsets(
        top: 16,
        left: 16,
        bottom: 16,
        right: 16
    )
    
    private let secureId: String
    private let inputStyle: GPInputStyle
    private let onCompletion: (Result<GrubPayResponse, GrubPayError>) -> Void
    private let saveCard: Bool
    
    private var keyboardHeight: CGFloat = 0.0 {
        didSet {
            adjustKeyboardLayout()
        }
    }
    
    private func adjustKeyboardLayout() {
        DispatchQueue.main.async {
            [weak self] in
            let contentInset = UIEdgeInsets(top: 0, left: 0, bottom: self?.keyboardHeight ?? 0, right: 0)
            self?.scrollView.contentInset = contentInset
            self?.scrollView.scrollIndicatorInsets = contentInset
        }
    }
    
    private var adaptiveConstraints: [NSLayoutConstraint] = []
    
    private func onValidChange(_ isValid: Bool) {
        if submitButton.isEnabled != isValid {
            DispatchQueue.main.async {
                [weak self] in
                self?.submitButton.isEnabled = isValid
            }
        }
    }
    
    // MARK: Elements
    
    private lazy var grubpayElement: GrubPayElement = {
        let el = GrubPayElement(
            viewController: self,
            onValidChange: self.onValidChange
        )
        el.inputStyle = inputStyle
        return el
    }()

    private lazy var submitButton: GrubPayButton = {
        let b = GrubPayButton()
        b.setTitleColor(UIColor.white, for: .normal)
        b.setBackground(inputStyle.accentColor, for: .normal)
        b.setBackground(UIColor.systemGray.withAlphaComponent(0.4), for: .disabled)
        b.layer.cornerRadius = 12.0
        b.layer.masksToBounds = true
        b.isHidden = true
        b.isEnabled = false
        b.addTarget(self, action: #selector(onSubmitButton), for: .touchUpInside)
        return b
    }()
    
    private lazy var stackView: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical
        sv.spacing = 24
        sv.alignment = .fill
        sv.addArrangedSubview(grubpayElement)
        sv.addArrangedSubview(submitButton)
        return sv
    }()
    
    private lazy var scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.backgroundColor = GPInputStyle.getAdaptiveColor(light: UIColor.white, dark: GPInputStyle.defaultDarkBg)
        sv.addSubview(stackView)
        sv.isScrollEnabled = true
        sv.isUserInteractionEnabled = true
        return sv
    }()
    
    @objc private func onCancel() {
        onCompletion(.failure(.cancel))
        dismissView()
    }
    
    private func dismissView() {
        DispatchQueue.main.async {
            [weak self] in
            self?.dismiss(animated: true, completion: nil)
        }
    }
    
    private lazy var leftBarButton: UIBarButtonItem = {
        let buttomItem = UIBarButtonItem(
            barButtonSystemItem: .stop,
            target: self,
            action: #selector(onCancel)
        )
        return buttomItem
    }()
    
    @objc func keyboardWillShow(_ notification: Notification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else {
            return
        }
        keyboardHeight = keyboardFrame.cgRectValue.height
    }

    @objc func keyboardWillHide(_ notification: Notification) {
        keyboardHeight = 0
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        let tapGesture = UITapGestureRecognizer(
            target: self,
            action: #selector(dismissKeyboard)
        )
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
        addViews()
        updateColors()
        setupLayout()
    }
    
    private func afterMounted() {
        guard let config = grubpayElement.controller.config else {
            return
        }
        DispatchQueue.main.async {
            [weak self] in
            self?.submitButton.isHidden = false
            if config.amount > 0 {
                let numberFormatter = NumberFormatter()
                numberFormatter.numberStyle = .currency
                numberFormatter.currencySymbol = "$"
                numberFormatter.minimumFractionDigits = 2
                numberFormatter.maximumFractionDigits = 2
                if let formattedValue = numberFormatter.string(from: NSNumber(value: Float(config.amount) / 100)) {
                    self?.title = formattedValue
                }
                self?.submitButton.setTitle(
                    NSLocalizedString(
                        "Pay",
                        bundle: Bundle(for: GrubPayVC.self),
                        comment: ""
                    ),
                    for: .normal
                )
            } else {
                if config.channel == .card {
                    self?.title = NSLocalizedString(
                        "Authorize Card",
                        bundle: Bundle(for: GrubPayVC.self),
                        comment: ""
                    )
                } else {
                    self?.title = NSLocalizedString(
                        "Authorize ACH",
                        bundle: Bundle(for: GrubPayVC.self),
                        comment: ""
                    )
                }
                self?.submitButton.setTitle(
                    NSLocalizedString(
                        "Submit",
                        bundle: Bundle(for: GrubPayVC.self),
                        comment: ""
                    ),
                    for: .normal
                )
            }
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    private func addViews() {
        view.addSubview(scrollView)
        navigationItem.leftBarButtonItem = leftBarButton
    }
    
    private func updateColors() {
        let bColor: UIColor!
        let fColor: UIColor = GPInputStyle.getAdaptiveColor(light: UIColor.black, dark: UIColor.white)
        if #available(iOS 13.0, *) {
            bColor = UIColor.systemBackground
        } else {
            bColor = GPInputStyle.getAdaptiveColor(light: UIColor.white, dark: GPInputStyle.defaultDarkBg)
        }
        DispatchQueue.main.async {
            [weak self] in
            self?.leftBarButton.tintColor = fColor
            self?.view.backgroundColor = bColor
        }
    }
    
    private func setupLayout() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            submitButton.heightAnchor.constraint(equalToConstant: 46.0),
        ])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        updateLayout()
    }
    
    private func updateLayout() {
        NSLayoutConstraint.deactivate(adaptiveConstraints)
        let safeInsets = view.safeAreaInsets
        let l = safeInsets.left + contentInsets.left
        let r = safeInsets.right + contentInsets.right
        let t = contentInsets.top
        let b = contentInsets.bottom
        adaptiveConstraints = [
            stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: l),
            stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -r),
            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: t),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: b),
            stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -(l + r)),
        ]
        NSLayoutConstraint.activate(adaptiveConstraints)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        coordinator.animate(alongsideTransition: { _ in
            self.updateLayout()
            // Trigger layout update
            self.view.setNeedsLayout()
            self.view.layoutIfNeeded()
        }, completion: nil)
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    internal init(
        _ secureId: String,
        saveCard: Bool = false,
        inputStyle: GPInputStyle = .init(),
        launchAfterLoaded: Bool = false,
        rootViewController: UIViewController? = nil,
        completion: @escaping (Result<GrubPayResponse, GrubPayError>) -> Void
    ) {
        self.secureId = secureId
        self.inputStyle = inputStyle
        self.onCompletion = completion
        self.saveCard = saveCard
        super.init(nibName: nil, bundle: nil)
        grubpayElement.mount(secureId) {
            [weak self] result in
            switch result {
            case .success:
                self?.afterMounted()
                if launchAfterLoaded {
                    self?.launch(rootViewController)
                }
            case .failure(let error):
                self?.onCompletion(.failure(error))
                self?.dismissView()
            }
        }
    }
    
    private func launch(_ rootViewController: UIViewController? = nil) {
        DispatchQueue.main.async {
            [weak self] in
            guard let rootViewController = rootViewController ?? UIApplication.shared.windows.first(
                where: { $0.isKeyWindow }
            )?.rootViewController, let self = self else {
                self?.onCompletion(.failure(.viewController))
                return
            }
            self.modalPresentationStyle = .pageSheet
            let navigationController = UINavigationController(rootViewController: self)
            navigationController.presentationController?.delegate = self
            rootViewController.present(
                navigationController,
                animated: true,
                completion: nil
            )
        }
    }
    
    @objc func onSubmitButton() {
        submitButton.isLoading = true
        leftBarButton.isEnabled = false
        grubpayElement.submit(
            saveCard: saveCard,
            completion: {
                [weak self] result in
                switch result {
                case .success(let data):
                    self?.onCompletion(.success(data))
                    self?.dismissView()
                case .failure(let error):
                    if error.requireNewSecureId {
                        self?.onCompletion(.failure(error))
                        self?.dismissView()
                    } else {
                        DispatchQueue.main.async {
                            [weak self] in
                            self?.submitButton.isLoading = false
                            self?.leftBarButton.isEnabled = true
                        }
                    }
                }
            }
        )
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension GrubPayVC: UIAdaptivePresentationControllerDelegate {
    func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
        return !grubpayElement.isLoading
    }
    
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        onCompletion(.failure(.cancel))
    }
}
