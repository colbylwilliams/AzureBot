//
//  BotKeys.swift
//  AzureBot
//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License.
//

import Foundation

struct BotKeys : Codable {
    
    fileprivate static let directLineSecretDefault = "BOT_FRAMEWORK_DIRECT_LINE_SECRET"
    
    let directLineSecret: String?
    
    
    var hasValidDirectLineSecret: Bool {
        return directLineSecret != nil && !directLineSecret!.isEmpty && directLineSecret! != BotKeys.directLineSecretDefault
    }
    
    init?(from infoDictionary: [String:Any]?) {
        guard let info = infoDictionary else { return nil }
        directLineSecret = info[CodingKeys.directLineSecret.rawValue] as? String
    }
    
    private enum CodingKeys: String, CodingKey {
        case directLineSecret = "BotFrameworkDirectLineSecret"
    }
    
    static func tryCreateFromPlists(custom: String? = nil) -> BotKeys? {
        
        let plistDecoder = PropertyListDecoder()
        
        if let customName = custom,
            let customData = Bundle.main.plist(named: customName),
            let customKeys = try? plistDecoder.decode(BotKeys.self, from: customData), customKeys.hasValidDirectLineSecret {
            
            return customKeys
        }
        
        if let botData = Bundle.main.plist(named: "AzureBot"),
            let botKeys = try? plistDecoder.decode(BotKeys.self, from: botData), botKeys.hasValidDirectLineSecret {
            
            return botKeys
        }
        
        if let infoKeys = BotKeys(from: Bundle.main.infoDictionary), infoKeys.hasValidDirectLineSecret {
            
            return infoKeys
        }
        
        return nil
    }
}
