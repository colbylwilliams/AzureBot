//
//  LocationManager.swift
//  AzureBot
//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License.
//

import Foundation
import CoreLocation


class LocationManager: NSObject, CLLocationManagerDelegate {
    
    enum LocationError: Error {
        case unknown
        case notConfigured
        case authorizationDenied
        case locationServicesDisabled
    }
    
    static let shared: LocationManager = LocationManager()
    
    fileprivate var authorized: Bool?
    
    fileprivate var _locationManager: CLLocationManager!
    fileprivate var locationManager: CLLocationManager {
        if let manager = _locationManager { return manager }
        _locationManager = CLLocationManager()
        _locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        _locationManager.distanceFilter = 100.0  // In meters.
        _locationManager.delegate = self
        return _locationManager
    }

    
    fileprivate var locationUpdated: [((CLLocation?, Error?) -> Void)] = []
    
    func getLocation(completion: @escaping (CLLocation?, Error?) -> Void) {
        
        checkAuthorization { (authed, error) in
    
            guard authed, error == nil else { completion(nil, error ?? LocationError.authorizationDenied); return }
            
            guard CLLocationManager.locationServicesEnabled() else { completion(nil, LocationError.locationServicesDisabled); return }
        
            
            if let location = self.locationManager.location, location.isLessThanOneMinuteOld {
                completion(location, nil); return
            }
            
            let pendingRequests = !self.locationUpdated.isEmpty
            
            self.locationUpdated.append(completion)
            
            guard !pendingRequests else { return }
            
            self.locationManager.requestLocation()
        }
    }
    
    
    fileprivate var authorizationUpdated: [((Bool, Error?) -> Void)] = []
    
    fileprivate func checkAuthorization(completion: @escaping (Bool, Error?) -> Void) {
        
        if let authed = authorized { completion(authed, nil); return }
        
        let authStatus = CLLocationManager.authorizationStatus()
        
        switch authStatus {
        case .notDetermined:
            authorizationUpdated.append(completion)
            locationManager.requestWhenInUseAuthorization()
        case .restricted, .denied:
            authorized = false
            completion(false, nil)
        case .authorizedWhenInUse, .authorizedAlways:
            authorized = true
            completion(true, nil)
        }
    }
    
    
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        guard let location = locations.last, location.isLessThanOneMinuteOld else {
            print("[LocationManager] Info: Location either nil or more than one minute old.  Requesting new location...")
            manager.requestLocation()
            return
        }
        
        locationUpdated.forEach { $0(location, nil) }
        locationUpdated = []
    }
    
    
    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        authorizationUpdated.forEach { $0(false, error) }
        authorizationUpdated = []
        
        locationUpdated.forEach { $0(nil, error) }
        locationUpdated = []
    }
    

    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .notDetermined:
            authorized = nil
        case .restricted, .denied:
            authorized = false
        case .authorizedWhenInUse, .authorizedAlways:
            authorized = true
        }
        
        authorizationUpdated.forEach { $0(authorized ?? false, nil) }
        authorizationUpdated = []
    }
    
    public func locationManagerShouldDisplayHeadingCalibration(_ manager: CLLocationManager) -> Bool { return false }
}

fileprivate extension CLLocation {
    fileprivate var isLessThanOneMinuteOld: Bool { return timestamp.timeIntervalSinceNow > -60 }
}
