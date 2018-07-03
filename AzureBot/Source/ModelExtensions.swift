//
//  ModelExtensions.swift
//  AzureBot
//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License.
//

import Foundation
import CoreLocation

extension Activity: Comparable {
    
    var hasId: Bool { return !id.isNilOrEmpty }
    var hasTimestamp: Bool { return timestamp != nil }
    var hasLocalTimestamp: Bool { return localTimestamp != nil }
    var hasAnyTimestamp: Bool { return hasTimestamp || hasLocalTimestamp }
    var anyTimestamp: Date? { return timestamp ?? localTimestamp }
    
    // backwards as the newest messages should be on top
    public static func < (lhs: Activity, rhs: Activity) -> Bool {
        
        if lhs.hasId, rhs.hasId {
            return lhs.id! < rhs.id!
        }
        
        if lhs.hasAnyTimestamp, rhs.hasAnyTimestamp {
            return lhs.anyTimestamp!.timeIntervalSince1970.rounded() < rhs.anyTimestamp!.timeIntervalSince1970.rounded()
        }
        
        // if lhs.hasTimestamp, rhs.hasTimestamp {
            // return lhs.timestamp!.timeIntervalSince1970.rounded() < rhs.timestamp!.timeIntervalSince1970.rounded()
        // }

        // if lhs.hasLocalTimestamp, rhs.hasLocalTimestamp {
            // return lhs.localTimestamp!.timeIntervalSince1970.rounded() < rhs.localTimestamp!.timeIntervalSince1970.rounded()
        // }

        return false
    }
    

    public static func == (lhs: Activity, rhs: Activity) -> Bool {
        
        if lhs.hasId, rhs.hasId {
            return lhs.id! == rhs.id!
        }
        
        if lhs.hasTimestamp, rhs.hasTimestamp {
            return lhs.timestamp!.timeIntervalSince1970.rounded() == rhs.timestamp!.timeIntervalSince1970.rounded()
        }
        
        if lhs.hasLocalTimestamp, rhs.hasLocalTimestamp {
            return lhs.localTimestamp!.timeIntervalSince1970.rounded() == rhs.localTimestamp!.timeIntervalSince1970.rounded()
        }
        
        return false
    }
}


extension GeoCoordinates {
    static func from(location: CLLocation) -> GeoCoordinates {
        return GeoCoordinates(type: "GeoCoordinates", name: "location", elevation: location.altitude, latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
    }
}
