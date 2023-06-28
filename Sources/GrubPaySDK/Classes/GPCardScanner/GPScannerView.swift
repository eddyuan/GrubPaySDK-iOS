//
//  GPCardScannerView.swift
//  GrubPaySDK
//
//  Created by Edward Yuan on 2023-06-16.
//

import AVFoundation
import CoreImage
import Foundation
import UIKit
import Vision

private extension UIImage {
    func scaledToFitSize(_ size: CGSize) -> UIImage? {
        return UIGraphicsImageRenderer(size: size).image { _ in
            self.draw(in: CGRect(origin: .zero, size: size))
        }.withRenderingMode(.alwaysTemplate)
    }
}

@available(iOS 13.0, *)
class GPScannerView: UIView {
    // MARK: - Private Properties

    private let session: AVCaptureSession = .init()
    private lazy var videoLayer: AVCaptureVideoPreviewLayer = {
        let el = AVCaptureVideoPreviewLayer(session: self.session)
        el.videoGravity = .resizeAspectFill
        el.connection?.videoOrientation = .portrait
        return el
    }()

    private let outputQueue = DispatchQueue(label: "io.grubpay.gpScannerOutput", qos: .default)
    private var isProcessing: Bool = false
    private var isCaptureStopped = true
    private var isSessionInitialized = false

    private lazy var textRequest: VNRecognizeTextRequest = {
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.minimumTextHeight = 0.010
        request.usesLanguageCorrection = false
        return request
    }()

//    private let device = AVCaptureDevice.default(for: .video)

    private var videoOutput: AVCaptureVideoDataOutput?

    // MARK: Config for card box style

    private let analyzer = GPCardAnalyzer()

    // MARK: UI related configs

    private let buttonColor: UIColor!
    private var targetPreviewSize: CGSize?
    private var cardWidth: CGFloat = 0
    private var cardHeight: CGFloat = 0
    private var cardX: CGFloat = 0
    private var cardY: CGFloat = 0
    private var cardYB: CGFloat = 0
    private var isVertical: Bool?

    // MARK: Output data

    private var cardNumberCandidates = [String: Int]()
    private var cardDateCandidates = [String: Int]()
    private var cardNumberAffirm = 0
    private var cardDateAffirm = 0

    private var creditCardNumber: String? {
        didSet {
            DispatchQueue.main.async { [weak self] in
                if let creditCardNumber = self?.creditCardNumber {
                    self?.labelCardNumber.text = creditCardNumber.mask(mask: "####  ####  ####  ####")
                    self?.labelCardNumber.layer.opacity = 1
                    self?.labelCardNumber.layer.shadowOpacity = 0.6
                } else {
                    self?.labelCardNumber.text = GPScannerConfig.cardNumberPlaceholder
                    self?.labelCardNumber.layer.opacity = GPScannerConfig.placeholderOpacity
                    self?.labelCardNumber.layer.shadowOpacity = 0
                }
                self?.tapticFeedback()
            }
        }
    }

    private var creditCardDate: String? {
        didSet {
            DispatchQueue.main.async { [weak self] in
                if let creditCardDate = self?.creditCardDate {
                    self?.labelCardDate.text = creditCardDate
                    self?.labelCardDate.layer.opacity = 1
                    self?.labelCardDate.layer.shadowOpacity = 0.6
                } else {
                    self?.labelCardDate.text = GPScannerConfig.cardDatePlaceholder
                    self?.labelCardDate.layer.opacity = GPScannerConfig.placeholderOpacity
                    self?.labelCardDate.layer.shadowOpacity = 0
                }
                self?.tapticFeedback()
            }
        }
    }

    private var invertedColor: UIColor {
        guard let components = buttonColor.cgColor.components else {
            return UIColor.white
        }
        let red = components[0]
        let green = components[1]
        let blue = components[2]
        let brightness = ((red * 299) + (green * 587) + (blue * 114)) / 1000
        return (brightness > 0.5) ? UIColor.black : UIColor.white
    }

    func didSetBoth() {
        DispatchQueue.main.async {
            [weak self] in
            guard let self = self else {
                return
            }
            if self.creditCardNumber != nil || self.creditCardDate != nil {
                self.buttonComplete.setImage(self.confirmImage, for: .normal)
                self.buttonComplete.tintColor = self.invertedColor
            } else {
                self.buttonComplete.setImage(self.closeImage, for: .normal)
                self.buttonComplete.tintColor = self.invertedColor
            }
        }

        if cardNumberAffirm > GPScannerConfig.triesForConfirm && cardDateAffirm > GPScannerConfig.triesForConfirm {
            onConfirm()
        }
    }

    // MARK: Strings

    private var hintTopText = NSLocalizedString(
        "Center your card until the fields are recognized",
        bundle: GrubPay.bundle,
        comment: ""
    )

    private var hintBottomText = NSLocalizedString(
        "Touch a recognized value to delete the value and try again",
        bundle: GrubPay.bundle,
        comment: ""
    )

    private var buttonCancelTitle = NSLocalizedString(
        "Cancel",
        bundle: GrubPay.bundle,
        comment: ""
    )

    // MARK: - UI Elements

    let imageSize = CGSize(width: GPScannerConfig.buttonSize * 0.3, height: GPScannerConfig.buttonSize * 0.3)
    lazy var closeImage = UIImage(systemName: "xmark")?.scaledToFitSize(imageSize)
    lazy var confirmImage = UIImage(systemName: "checkmark")?.scaledToFitSize(imageSize)

    private let viewGuide: GPCardOverlay = .init()
    private lazy var labelCardNumber: UILabel = {
        let el = UILabel()
        el.text = GPScannerConfig.cardNumberPlaceholder
        el.numberOfLines = 1
        el.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(clearCardNumber)))
        el.isUserInteractionEnabled = true
        el.textColor = .white
        el.layer.opacity = GPScannerConfig.placeholderOpacity
        el.layer.shadowOffset = CGSize(width: 1, height: 1)
        el.layer.shadowColor = UIColor.black.cgColor
        el.layer.shadowOpacity = 0
        el.layer.shadowRadius = 1
        return el
    }()

    private lazy var labelCardDate: UILabel = {
        let el = UILabel()
        el.text = GPScannerConfig.cardDatePlaceholder
        el.numberOfLines = 1
        el.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(clearCardDate)))
        el.isUserInteractionEnabled = true
        el.textColor = .white
        el.layer.opacity = GPScannerConfig.placeholderOpacity
        el.layer.shadowOffset = CGSize(width: 1, height: 1)
        el.layer.shadowColor = UIColor.black.cgColor
        el.layer.shadowOpacity = 0
        el.layer.shadowRadius = 1
        return el
    }()

    private lazy var labelHintTop: UILabel = {
        let el = UILabel()
        el.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        el.text = hintBottomText
        el.numberOfLines = 0
        el.textAlignment = .center
        el.textColor = .white
        return el
    }()

    private lazy var labelHintBottom: UILabel = {
        let el = UILabel()
        el.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        el.text = hintBottomText
        el.numberOfLines = 0
        el.textAlignment = .center
        el.textColor = .white
        return el
    }()

    private lazy var buttonComplete: UIButton = {
        let el = UIButton()
        el.setImage(closeImage, for: .normal)
        el.backgroundColor = buttonColor
        el.tintColor = invertedColor
        el.layer.cornerRadius = GPScannerConfig.buttonSize / 2
        el.layer.masksToBounds = true
        el.addTarget(self, action: #selector(onConfirmButton), for: .touchUpInside)
        return el
    }()

//    private lazy var testImage: UIImageView = {
//        let el = UIImageView()
//        el.contentMode = .scaleAspectFit
//        el.clipsToBounds = true
//        el.backgroundColor = UIColor.red
//        return el
//    }()

    // MARK: - Instance dependencies

    private var onSuccess: (_ number: String?, _ date: String?) -> Void?
    private var onError: ((Error) -> Void)?

    // MARK: - Initializers

    init(
        onSuccess: @escaping (_ number: String?, _ date: String?) -> Void,
        onError: @escaping (Error) -> Void,
        buttonColor: UIColor
    ) {
        self.buttonColor = buttonColor
        self.onSuccess = onSuccess
        self.onError = onError
        super.init(frame: .zero)
        setupGuideViews()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        stopCapture()
    }

    private func startSession() {
        guard isCaptureStopped else {
            return
        }

        if !isSessionInitialized {
            guard let device = AVCaptureDevice.default(for: .video),
                  let input = try? AVCaptureDeviceInput(device: device)
            else {
                onError?(CameraInitializationError())
                return
            }

            videoOutput = AVCaptureVideoDataOutput()
            guard let videoOutput = videoOutput else {
                onError?(CameraInitializationError())
                return
            }
            videoOutput.alwaysDiscardsLateVideoFrames = true
            videoOutput.setSampleBufferDelegate(self, queue: outputQueue)
            session.addInput(input)
            session.addOutput(videoOutput)
            session.sessionPreset = .photo
            for connection in session.connections {
                connection.videoOrientation = .portrait
            }

            isSessionInitialized = true
        }

        DispatchQueue.global().async { [weak self] in
            self?.session.startRunning()
        }

        isCaptureStopped = false
    }

    func stopCapture() {
        DispatchQueue.global().async { [weak self] in
            self?.session.stopRunning()
            self?.isCaptureStopped = true
        }
    }

    // MARK: Open methods

    func startCapture() {
        let cameraAuthStatus = AVCaptureDevice.authorizationStatus(for: .video)
        switch cameraAuthStatus {
        case .authorized:
            startSession()
        case .notDetermined: // Not asked for camera permission yet
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async { [weak self] in
                    if granted {
                        self?.startSession()
                    } else {
                        self?.onError?(CameraPermissionError(authorizationStatus: .denied))
                    }
                }
            }
        case .denied, .restricted:
            onError?(CameraPermissionError(authorizationStatus: cameraAuthStatus))
        @unknown default:
            onError?(CameraPermissionError(authorizationStatus: cameraAuthStatus))
        }
    }

    override func layoutSubviews() {
        setupHierarchy()
        setVideoOrientation()
        super.layoutSubviews()
    }

    // MARK: - Add Views

    private func setVideoOrientation() {
        guard let connection = videoOutput?.connection(with: AVMediaType.video), connection.isVideoOrientationSupported,
              let connection3 = videoLayer.connection,
              connection3.isVideoOrientationSupported,
              let connection2 = session.connections.first,
              connection2.isVideoOrientationSupported
        else {
            return
        }
        let currentOrientation = UIDevice.current.orientation
        switch currentOrientation {
        case .portrait:
            connection.videoOrientation = .portrait
            connection2.videoOrientation = .portrait
            connection3.videoOrientation = .portrait
        case .landscapeLeft:
            connection.videoOrientation = .landscapeRight
            connection2.videoOrientation = .landscapeRight
            connection3.videoOrientation = .landscapeRight
        case .landscapeRight:
            connection.videoOrientation = .landscapeLeft
            connection2.videoOrientation = .landscapeLeft
            connection3.videoOrientation = .landscapeLeft
        case .portraitUpsideDown:
            connection.videoOrientation = .portraitUpsideDown
            connection2.videoOrientation = .portraitUpsideDown
            connection3.videoOrientation = .portraitUpsideDown
        default:
            return
        }
    }

    private func setupGuideViews() {
        layer.addSublayer(videoLayer)
        addSubview(viewGuide)
        bringSubviewToFront(viewGuide)
//        addSubview(testImage)
        addSubview(labelCardNumber)
        addSubview(labelCardDate)
        addSubview(labelHintTop)
        addSubview(labelHintBottom)
        addSubview(buttonComplete)
    }

    private func setupHierarchy() {
        videoLayer.frame = frame
//        testImage.frame = CGRect(x: 20, y: 20, width: 200, height: 200)
        let safeAreaInsets = safeAreaInsets
        let viewWidth = frame.width
        let viewHeight = frame.height

        targetPreviewSize = CGSize(width: viewWidth, height: viewHeight)

        // Access individual insets
        let topInset = safeAreaInsets.top
        let bottomInset = safeAreaInsets.bottom
        let leftInset = safeAreaInsets.left
        let rightInset = safeAreaInsets.right
        let isVertical = frame.height >= frame.width
        if self.isVertical != isVertical {
            self.isVertical = isVertical
        }

        let cardAreaW: CGFloat!
        let cardAreaH: CGFloat!
        let cardContainerX: CGFloat!
        let cardContainerY: CGFloat!
        let cardContainerW: CGFloat!
        let cardContainerH: CGFloat!
        let buttonX: CGFloat!
        let buttonY: CGFloat!

        if isVertical {
            cardAreaW = viewWidth
            cardAreaH = viewHeight - bottomInset - GPScannerConfig.buttonSize - GPScannerConfig.buttonPaddingEdge
            cardContainerX = leftInset + GPScannerConfig.cardPaddingEdge
            cardContainerY = topInset + GPScannerConfig.cardPaddingEdge
            cardContainerW = cardAreaW - (GPScannerConfig.cardPaddingEdge * 2) - leftInset - rightInset
            cardContainerH = cardAreaH - topInset - (GPScannerConfig.cardPaddingEdge * 2)
            buttonX = (viewWidth - GPScannerConfig.buttonSize) / 2
            buttonY = viewHeight - GPScannerConfig.buttonPaddingEdge - bottomInset - GPScannerConfig.buttonSize
        } else {
            cardAreaW = viewWidth - rightInset - GPScannerConfig.buttonSize - GPScannerConfig.buttonPaddingEdge
            cardAreaH = viewHeight
            cardContainerX = leftInset + GPScannerConfig.cardPaddingEdge
            cardContainerY = GPScannerConfig.cardPaddingEdge
            cardContainerW = cardAreaW - leftInset - (GPScannerConfig.cardPaddingEdge * 2)
            cardContainerH = cardAreaH - (GPScannerConfig.cardPaddingEdge * 2)
            buttonX = viewWidth - GPScannerConfig.buttonPaddingEdge - GPScannerConfig.buttonSize - rightInset
            buttonY = (viewHeight - GPScannerConfig.buttonSize) / 2
        }

        let hintW = cardContainerW - (GPScannerConfig.hintPadding * 2)
        let hintTopH = labelHintTop.sizeThatFits(CGSize(width: hintW, height: CGFloat.greatestFiniteMagnitude)).height
        let hintBottomH = labelHintBottom.sizeThatFits(CGSize(width: hintW, height: CGFloat.greatestFiniteMagnitude)).height

        let hintSpacer = max(hintTopH, hintBottomH) + GPScannerConfig.hintPadding
        let maxCardH = cardContainerH - (hintSpacer * 2)
        let maxCardWFromH = min(GPScannerConfig.maxCardWidth, maxCardH / GPScannerConfig.cardRatio)
        cardWidth = min(maxCardWFromH, cardContainerW)
        cardHeight = cardWidth * GPScannerConfig.cardRatio
        cardX = (cardContainerW - cardWidth) / 2 + cardContainerX
        cardY = (cardContainerH - cardHeight) / 2 + cardContainerY
        cardYB = cardY + cardHeight

        let hintX = cardContainerX + GPScannerConfig.hintPadding
        let hintTopY = cardY - GPScannerConfig.hintPadding - hintTopH
        let hintBottomY = cardYB + GPScannerConfig.hintPadding

        let innerLabelPadding = cardWidth * 0.1

        let labelCardX = cardX + innerLabelPadding

        viewGuide.frame = frame
        viewGuide.cutout = CGRect(x: cardX, y: cardY, width: cardWidth, height: cardHeight)

        let labelCardNumberFontSize = cardWidth * 0.06
        let labelCardNumberHeight = labelCardNumberFontSize * 1.4
        let labelCardNumberY = cardY + ((cardHeight - labelCardNumberHeight) / 2)
        labelCardNumber.font = UIFont.systemFont(
            ofSize: labelCardNumberFontSize,
            weight: .bold
        )
        labelCardNumber.frame = CGRect(
            x: labelCardX,
            y: labelCardNumberY,
            width: cardWidth - (innerLabelPadding * 2),
            height: labelCardNumberHeight
        )

        let labelCardDateFontSize = cardWidth * 0.045
        let labelCardDateHeight = labelCardDateFontSize * 1.4
        let labelCardDateY = cardYB - innerLabelPadding - labelCardDateHeight
        labelCardDate.font = UIFont.systemFont(ofSize: labelCardDateFontSize, weight: .bold)
        labelCardDate.frame = CGRect(
            x: labelCardX,
            y: labelCardDateY,
            width: cardWidth - (innerLabelPadding * 2),
            height: labelCardDateHeight
        )

        labelHintTop.frame = CGRect(
            x: hintX,
            y: hintTopY,
            width: hintW,
            height: hintTopH
        )

        labelHintBottom.frame = CGRect(
            x: hintX,
            y: hintBottomY,
            width: hintW,
            height: hintBottomH
        )

        buttonComplete.frame = CGRect(
            x: buttonX,
            y: buttonY,
            width: GPScannerConfig.buttonSize,
            height: GPScannerConfig.buttonSize
        )
    }

    // MARK: - Clear on touch

    @objc func clearCardNumber() {
        setCardNumber(nil)
    }

    @objc func clearCardDate() {
        setCardDate(nil)
    }

    // MARK: - Completed process

    @objc func onConfirmButton() {
        onConfirm()
    }

    private func onConfirm() {
        stopCapture()
        onSuccess(creditCardNumber, creditCardDate)
    }

    // MARK: - Payment detection

    private func setCardNumber(_ val: String?) {
        guard val != nil else {
            cardNumberCandidates.removeAll()
            cardNumberAffirm = 0
            if creditCardNumber != nil {
                creditCardNumber = nil
            }
            return
        }

        if cardNumberCandidates[val!] != nil {
            cardNumberCandidates[val!]! += 1
        } else {
            cardNumberCandidates[val!] = 1
        }

        if let maxEntry = cardNumberCandidates.max(by: { $0.value < $1.value }) {
            let maxEntryVal = maxEntry.value
            cardNumberAffirm = maxEntryVal
            if cardNumberAffirm > GPScannerConfig.minTries {
                let mostPossible = maxEntry.key
                if creditCardNumber != mostPossible {
                    creditCardNumber = mostPossible
                }
                didSetBoth()
            }
        }
    }

    private func setCardDate(_ val: String?) {
        guard val != nil else {
            cardDateCandidates.removeAll()
            cardDateAffirm = 0
            if creditCardDate != nil {
                creditCardDate = nil
            }
            return
        }

        if cardDateCandidates[val!] != nil {
            cardDateCandidates[val!]! += 1
        } else {
            cardDateCandidates[val!] = 1
        }

        if let maxEntry = cardDateCandidates.max(by: { $0.value < $1.value }) {
            let maxEntryVal = maxEntry.value
            cardDateAffirm = maxEntryVal
            if cardDateAffirm > GPScannerConfig.minTries {
                let mostPossible = maxEntry.key
                if creditCardDate != mostPossible {
                    creditCardDate = mostPossible
                }
                didSetBoth()
            }
        }
    }

    private func tapticFeedback() {
        let feedbackGenerator = UINotificationFeedbackGenerator()
        feedbackGenerator.prepare()
        feedbackGenerator.notificationOccurred(.success)
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

@available(iOS 13.0, *)
extension GPScannerView: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        guard !isProcessing else { return }
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            debugPrint("unable to get image from sample buffer")
            return
        }

        isProcessing = true
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.findCardData(pixelBuffer: pixelBuffer)
            self?.isProcessing = false
        }
    }

    private func findCardData(pixelBuffer: CVImageBuffer) {
        guard cardWidth > 0 && cardHeight > 0,
              let targetSize = targetPreviewSize
        else {
            return
        }

        let ciImage = CIImage(cvImageBuffer: pixelBuffer)
        let resizeFilter = CIFilter(name: "CILanczosScaleTransform")!

        // Compute scale and corrective aspect ratio
        let scale = max(targetSize.width / ciImage.extent.width, targetSize.height / ciImage.extent.height)

        // Apply resizing
        resizeFilter.setValue(ciImage, forKey: kCIInputImageKey)
        resizeFilter.setValue(scale, forKey: kCIInputScaleKey)

        guard let outputImage = resizeFilter.outputImage else {
            return
        }

        let extraBottom = (outputImage.extent.height - targetSize.height) / 2
        let extraLeft = (outputImage.extent.width - targetSize.width) / 2

        let croppedImage = outputImage.cropped(
            to: CGRect(
                x: cardX + extraLeft,
                y: targetSize.height - cardYB + extraBottom,
                width: cardWidth,
                height: cardHeight
            )
        )

        analyzer.analyz(
            ciImage: croppedImage,
            onCardNumber: {
                cardNum in
                setCardNumber(cardNum)
            },
            onDate: {
                dateString in
                setCardDate(dateString)
            }
        )
    }
}
