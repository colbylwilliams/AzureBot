//
//  Utilities.swift
//  AzureBot
//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License.
//

import UIKit

extension String {
    
    func ensuringSuffix(_ suffix: String) -> String {
        if self.hasSuffix(suffix) {
            return self
        }
        return self + suffix
    }
    
    func removingSuffix(_ suffix: String) -> String {
        guard hasSuffix(suffix) else { return self }
        return String(dropLast(suffix.count))
    }
}

extension Optional where Wrapped == String {
    
    var isNilOrEmpty: Bool {
        return self == nil || self!.isEmpty
    }
    
    var valueOrEmpty: String {
        return self != nil ? self! : ""
    }
}

extension Optional where Wrapped: CustomStringConvertible {
    
    var valueOrNilString: String {
        return self?.description ?? "nil"
    }
}


extension Optional where Wrapped == Date {
    
    var valueOrEmpty: String {
        return self != nil ? "\(self!.timeIntervalSince1970)" : ""
    }
    
    var valueOrNilString: String {
        return self != nil ? "\(self!.timeIntervalSince1970)" : "nil"
    }
}


extension Bundle {
    func plist(named name: String) -> Data? {
        if let url = self.url(forResource: name.removingSuffix(".plist"), withExtension: "plist") {
            return try? Data(contentsOf: url)
        }
        return nil
    }
}


extension Data {
    mutating func appendString(_ string: String) {
        let data = string.data(using: String.Encoding.utf8, allowLossyConversion: false)
        append(data!)
    }
}


extension UIView {
    
    func roundCorners(radius: CGFloat, skipping: CACornerMask = []) {
        self.layer.roundCorners(radius: radius, skipping: skipping)
    }
    func addShadow(opacity: Float, radius: CGFloat = 3.0, offset: CGSize = CGSize(width: 0.0, height: -3.0)) {
        self.layer.addShadow(opacity: opacity, radius: radius, offset: offset)
    }
}

extension CALayer {
    
    fileprivate var allCorners: CACornerMask { return [ .layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMaxXMaxYCorner, .layerMinXMaxYCorner ] }
    
    func roundCorners(radius: CGFloat, skipping skip: CACornerMask = []) {
        self.cornerRadius = radius
        self.maskedCorners = allCorners.subtracting(skip)
    }
    // system default for shadowRadius is 3.0
    // system default for shadowOffset is (0.0, -3.0)
    func addShadow(opacity: Float, radius: CGFloat = 3.0, offset: CGSize = CGSize(width: 0.0, height: -3.0)) {
        self.shadowOffset = .zero
        self.shadowOpacity = opacity
        self.shadowRadius = radius
        self.shadowColor = UIColor.black.cgColor
        self.masksToBounds = false
        self.shadowOffset = offset
    }
}

extension DateFormatter {
    
    func roundTripIso8601StringWithMicroseconds(from date: Date) -> String {
        
        var data = self.string(from: date)
        
        if let fractionStart = data.range(of: "."),
            let fractionEnd = data.index(fractionStart.lowerBound, offsetBy: 7, limitedBy: data.endIndex) {
            
            let fractionRange = fractionStart.lowerBound..<fractionEnd
            let intVal = Int64(1000000 * date.timeIntervalSince1970)
            let newFraction = String(format: ".%06d", intVal % 1000000)
            data.replaceSubrange(fractionRange, with: newFraction)
        }
        
        return data
    }
    
    func roundTripIso8601DateWithMicroseconds(from dateString: String) -> Date? {
        
        guard let parsedDate = self.date(from: dateString) else {
            return nil
        }
        
        var preliminaryDate = Date(timeIntervalSinceReferenceDate: floor(parsedDate.timeIntervalSinceReferenceDate))
        
        if let fractionStart = dateString.range(of: "."),
            let fractionEnd = dateString.index(fractionStart.lowerBound, offsetBy: 7, limitedBy: dateString.endIndex) {
            let fractionRange = fractionStart.lowerBound..<fractionEnd
            let fractionStr = String(dateString[fractionRange])
            
            if var fraction = Double(fractionStr) {
                fraction = Double(floor(1000000*fraction)/1000000)
                preliminaryDate.addTimeInterval(fraction)
            }
        }
        
        return preliminaryDate
    }
}
