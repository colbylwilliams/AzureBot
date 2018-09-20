//
//  BotClientError.swift
//  AzureBot
//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License.
//

import Foundation

public enum BotClientError : Error {
    case unknown
    case invalidIds
    case noConversation
    case urlError(String)
    case decodeError(DecodingError)
    case encodingError(EncodingError)
    case apiError(ApiError?)
}
