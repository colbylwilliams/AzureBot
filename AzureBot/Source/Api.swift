//
//  Api.swift
//  AzureBot
//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License.
//

import Foundation

enum Api {
    case startConversation
    case reconnectToConversation(conversationId: String)
    case getActivities(conversationId: String)
    case postActivity(conversationId: String)
    case upload(conversationId: String)
    case refreshToken
    case generateTokenForNewConversation
    
    var base: String {
        switch self {
        case .refreshToken, .generateTokenForNewConversation:
            return "https://directline.botframework.com/v3/directline/tokens/"
        default: return "https://directline.botframework.com/v3/directline/conversations/"
        }
    }
    
    var full: String {
        switch self {
        case .startConversation:                           return base
        case let .reconnectToConversation(conversationId): return base + conversationId
        case let .getActivities(conversationId),
             let .postActivity(conversationId):            return base + conversationId + "/activities"
        case let .upload(conversationId):                  return base + conversationId + "/upload"
        case .refreshToken:                                return base + "/refresh"
        case .generateTokenForNewConversation:             return base + "/generate"
        }
    }
    
    var method: HttpMethod {
        switch self {
        case .reconnectToConversation, .getActivities: return .get
        default: return .post
        }
    }
    
    var hasValidIds: Bool {
        switch self {
        case let .reconnectToConversation(conversationId),
             let .getActivities(conversationId),
             let .postActivity(conversationId),
             let .upload(conversationId): return !conversationId.isEmpty
        default: return true
        }
    }
    
    func url(withQuery query: String? = nil) -> URL? {
        return URL(string: urlString(withQuery: query))
    }
    
    func urlString(withQuery query: String? = nil) -> String {
        return full + query.valueOrEmpty
    }
    
    func contentType(_ boundary: String? = nil) -> String {
        switch self {
        case .upload: return "multipart/form-data; boundary=\(boundary!)"
        default: return "application/json"
        }
    }
}
