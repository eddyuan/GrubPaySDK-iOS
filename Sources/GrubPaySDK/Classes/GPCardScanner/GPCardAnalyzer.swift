//
//  GPCardAnalyzer.swift
//  GrubPaySDK
//
//  Created by Edward Yuan on 2023-06-16.
//

import Foundation
import UIKit
import Vision

@available(iOS 13.0, *)
class GPCardAnalyzer {
    private lazy var textRequest: VNRecognizeTextRequest = {
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.minimumTextHeight = 0.010
        request.usesLanguageCorrection = false
        return request
    }()

    func analyz(
        ciImage: CIImage,
        onCardNumber: (_: String) -> Void,
        onDate: (_: String) -> Void
    ) {
        let imgRequestHandler = VNImageRequestHandler(ciImage: ciImage, options: [:])
        try? imgRequestHandler.perform([textRequest])

        guard let results = textRequest.results, results.count > 0 else {
            return
        }

        let maxCandidates = 6
        for result in results {
            guard
                let candidate = result.topCandidates(maxCandidates).first,
                candidate.confidence > 0.1 && candidate.string.count > 2
            else { continue }
            let line = candidate.string
            if let foundNum = findCardNumber(line) {
                onCardNumber(foundNum)
                continue
            }

            if let foundDate = findExpiryDate(line) {
                onDate(foundDate)
                continue
            }
        }
    }
}

@available(iOS 13.0, *)
extension GPCardAnalyzer {
    // MARK: This is used to check sum of last digit of a credit card

    func findCardNumber(_ source: String) -> String? {
        let trimmed = source.replacingOccurrences(of: " ", with: "")
        if trimmed.matchesRegex(regex: kCardRegex) && trimmed.luhnCheck() {
            return trimmed
        }
        return nil
    }

    func findExpiryDate(_ source: String) -> String? {
        if !source.contains("/") {
            return nil
        }

        do {
            let regex = try NSRegularExpression(pattern: "\\d{2}/\\d{2}")
            let matches = regex.matches(in: source, range: NSRange(source.startIndex..., in: source))
            if let match = matches.first {
                let extractedString = String(source[Range(match.range, in: source)!])
                let strComponents = extractedString.components(separatedBy: "/")
                if strComponents.count == 2 {
                    if let sMonth = Int(strComponents[0]), var sYear = Int(strComponents[1]), sMonth > 0 && sMonth < 13 {
                        if sYear < 100 {
                            sYear += 2000
                        }
                        let currentDate = Date()
                        let calendar = Calendar.current
                        let year = calendar.component(.year, from: currentDate)
                        var isDateValid = false
                        if sYear > year && sYear < (year + 20) {
                            isDateValid = true
                        } else if sYear == year {
                            let month = calendar.component(.month, from: currentDate)
                            isDateValid = sMonth >= month
                        }
                        if isDateValid {
                            return String(format: "%02d/%02d", sMonth, sYear % 100)
                        }
                    }
                }
            }
            return nil
        } catch {
            return nil
        }
    }
}
