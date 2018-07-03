//
//  BotClient.swift
//  AzureBot
//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License.
//

import Foundation
import Starscream

extension Notification.Name {
    static let BotClientDidAddMessageNotification = Notification.Name("BotClientDidAddMessageNotification")
}

public class BotClient: WebSocketDelegate {
    
    public static let shared: BotClient = BotClient()
    init() { }
    
    fileprivate static let _directLineSecretKey = "" // paste key here or pass in configure()
    fileprivate var directLineSecretKey: String = _directLineSecretKey

    fileprivate var context: [Context] = []
    
    fileprivate var socket: WebSocket!
    fileprivate let session: URLSession = URLSession(configuration: URLSessionConfiguration.default)
    
    fileprivate var activities: [Activity] = []
    fileprivate var conversation: Conversation?

    
    var currentUser = ChannelAccount(id: "default-user", name: "User")
    
    
    var messages:SortedArray<Activity> = SortedArray(areInIncreasingOrder: > ) {
        didSet {
            //print("didSet: \(messages.count)")
            if oldValue.count != messages.count {
                NotificationCenter.default.post(name: Notification.Name.BotClientDidAddMessageNotification, object: self, userInfo: nil)
            }
        }
    }
    
    
    public func configure(secret: String? = nil, user: ChannelAccount? = nil, context: [Context] = []) {
        if !secret.isNilOrEmpty {
            self.directLineSecretKey = secret!
        }
        if let user = user, !user.id.isNilOrEmpty, !user.name.isNilOrEmpty {
            self.currentUser = user
        }
        self.context = context
    }
    
    
    public func start(completion: @escaping (Response<Conversation>) -> Void) {
        startConversation { r in
            if let c = r.resource {
                self.conversation = c
                if let wws = c.streamUrl, let url = URL(string: wws) {
                    self.startSocket(url)
                }
            } else if let e = r.error {
                print("[BotClient] Error: " + e.localizedDescription)
            }
            completion(r)
        }
    }
    
    
    public func send(message: String, completion: @escaping (Response<ResourceResponse>) -> Void) {
        
        var activity = Activity(message: message, from: currentUser, in: conversation)
        
        for c in context {
            switch c {
            case .location:
                LocationManager.shared.getLocation { (location, error) in
                    if let location = location {
                        activity.entities = [GeoCoordinates.from(location: location)]
                    }
                }
            }
        }
        
        print("insert: \(messages.insert(activity))")
        
        postActivity(activity, completion: completion)
    }
    
        
    func startSocket(_ url: URL) {
        print("[BotClient] starting socket...")
        socket = WebSocket.init(url: url)
        socket.delegate = self
        socket.connect()
    }
    
    
    // MARK: - WebSocketDelegate
    
    public func websocketDidConnect(socket: WebSocketClient) {
        print("[BotClient] websocketDidConnect")
    }
    
    public func websocketDidDisconnect(socket: WebSocketClient, error: Error?) {
        print("[BotClient] websocketDidDisconnect: \(error?.localizedDescription ?? "")")
    }
    
    public func websocketDidReceiveMessage(socket: WebSocketClient, text: String) {
        //print("[BotClient] websocketDidReceiveMessage: \(text)")
        
        // ignore empty messages
        guard !text.isEmpty, let data = text.data(using: .utf8) else { return }
        
        do {
            let activitySet = try decoder.decode(ActivitySet.self, from: data)
            process(activitySet: activitySet)
        } catch {
            print("[BotClient] Error: " + error.localizedDescription)
        }
    }
    
    public func websocketDidReceiveData(socket: WebSocketClient, data: Data) {
        print("[BotClient] websocketDidReceiveData: \(data)")
    }

    
    func process(activitySet: ActivitySet) {
        
        for activity in activitySet.activities {
            
            guard let type = activity.type else { break; }
            // https://docs.microsoft.com/en-us/azure/bot-service/rest-api/bot-framework-rest-direct-line-3-0-receive-activities?view=azure-bot-service-4.0#websocket-vs-http-get
            switch type {
            case .message:

                messages.insertOrReplace(element: activity)
                
            case .contactRelationUpdate:
                print("contactRelationUpdate")
            case .conversationUpdate:
                print("conversationUpdate")
            case .typing:
                print("typing")
            case .endOfConversation:
                print("endOfConversation")
            case .event:
                print("event")
            case .invoke:
                print("invoke")
            }
        }
    }
    
    
    public func startConversation(completion: @escaping (Response<Conversation>) -> Void) {
        do {
            let request = try dataRequest(for: Api.startConversation)
            
            return sendRequest(request, completion: completion)
        
        } catch {
            completion(Response(error))
        }
    }

    public func reconnectToConversation(withWatermark watermark: String? = nil, completion: @escaping (Response<Conversation>) -> Void) {
        do {
            guard let conversationId = conversation?.conversationId else { throw BotClientError.noConversation }
        
            let request = try dataRequest(for: Api.reconnectToConversation(conversationId: conversationId), withQuery: getQuery(("watermark", watermark)))
            
            return sendRequest(request, completion: completion)
            
        } catch {
            completion(Response(error))
        }
    }

    public func getActivities(fromWatermark watermark: String? = nil, completion: @escaping (Response<ActivitySet>) -> Void) {
        do {
            guard let conversationId = conversation?.conversationId else { throw BotClientError.noConversation }
            
            let request = try dataRequest(for: Api.getActivities(conversationId: conversationId), withQuery: getQuery(("watermark", watermark)))
            
            return sendRequest(request, completion: completion)
            
        } catch {
            completion(Response(error))
        }
    }

    public func postActivity(_ activity: Activity, completion: @escaping (Response<ResourceResponse>) -> Void) {
        do {
            guard let conversationId = conversation?.conversationId else { throw BotClientError.noConversation }
            
            let request = try dataRequest(for: Api.postActivity(conversationId: conversationId), withBody: activity)
            
            return sendRequest(request, completion: completion)
            
        } catch {
            completion(Response(error))
        }
    }

    public func upload(image: Data, withUserId userId: String? = nil, completion: @escaping (Response<ResourceResponse>) -> Void) {
        do {
            guard let conversationId = conversation?.conversationId else { throw BotClientError.noConversation }
            
            let request = try dataRequest(for: Api.upload(conversationId: conversationId), withBody: image, withQuery: getQuery(("userId", userId)))
            
            return sendRequest(request, completion: completion)
            
        } catch {
            completion(Response(error))
        }

    }

    public func refreshToken(completion: @escaping (Response<Conversation>) -> Void) {
        do {
            let request = try dataRequest(for: Api.refreshToken)
            
            return sendRequest(request, completion: completion)
            
        } catch {
            completion(Response(error))
        }
    }

    public func generateTokenForNewConversation(withParameters parameters: TokenParameters? = nil, completion: @escaping (Response<Conversation>) -> Void) {
        do {
            let request = try dataRequest(for: Api.generateTokenForNewConversation, withBody: parameters)
            
            return sendRequest(request, completion: completion)
            
        } catch {
            completion(Response(error))
        }
    }

    fileprivate func sendRequest<T:Codable> (_ request: URLRequest, completion: @escaping (Response<T>) -> ()) {
        
        session.dataTask(with: request) { (data, response, error) in
            
            let httpResponse = response as? HTTPURLResponse
            
            if let error = error {
                
                completion(Response(request: request, data: data, response: httpResponse, result: .failure(error)))
                
            } else if let data = data {
                
                do {
                    
                    let resource = try self.decoder.decode(T.self, from: data)
                    
                    completion(Response(request: request, data: data, response: httpResponse, result: .success(resource)))
                    
                } catch {
                    
                    completion(Response(request: request, data: data, response: httpResponse, result: .failure(error)))
                }
            } else {
                completion(Response(request: request, data: data, response: httpResponse, result: .failure(BotClientError.unknown)))
            }
            }.resume()
    }
    
    fileprivate func dataRequest(for api: Api, withQuery query: String? = nil, andHeaders headers: [String:String]? = nil) throws -> URLRequest {
        return try self._dataRequest(for: api, withQuery: query, andHeaders: headers)
    }
    
    fileprivate func dataRequest<T:Codable>(for api: Api, withBody body: T? = nil, withQuery query: String? = nil, andHeaders headers: [String:String]? = nil) throws -> URLRequest {
        
        if let body = body {
            
            let bodyData = try encoder.encode(body)
            
            return try self._dataRequest(for: api, withBody: bodyData, withQuery: query, andHeaders: headers)
        }
        
        return try self._dataRequest(for: api, withQuery: query, andHeaders: headers)
    }
    
     fileprivate func dataRequest(for api: Api, withBody body: Data? = nil, withQuery query: String? = nil, andHeaders headers: [String:String]? = nil) throws -> URLRequest {
        
         if let body = body {
            
             return try self._dataRequest(for: api, withBody: getMultipartFormBody(body), withQuery: query, andHeaders: headers)
         }
        
         return try self._dataRequest(for: api, withQuery: query, andHeaders: headers)
     }
    
    
    
    fileprivate let boundary = "Boundary-\(UUID().uuidString)"
    
    fileprivate func _dataRequest(for api: Api, withBody body: Data? = nil, withQuery query: String? = nil, andHeaders headers: [String:String]? = nil) throws -> URLRequest {
        
        guard api.hasValidIds else { throw BotClientError.invalidIds }
        
        guard let url = api.url(withQuery: query) else { throw BotClientError.urlError(api.urlString(withQuery: query)) }
        
        var request = URLRequest(url: url)
        
        request.httpMethod = api.method.rawValue
        
        request.addValue(api.contentType(boundary), forHTTPHeaderField: "Content-Type")
        
        request.addValue("Bearer \(conversation?.token ?? directLineSecretKey)", forHTTPHeaderField: "Authorization")
        
        if let headers = headers {
            for header in headers {
                request.addValue(header.value, forHTTPHeaderField: header.key)
            }
        }
        
        request.httpBody = body
        
        return request
    }
    
    fileprivate func getMultipartFormBody(_ data: Data) -> Data {
        
        var body = Data()
        
        let boundaryPrefix = "--\(boundary)\r\n"
        
        body.appendString(boundaryPrefix)
        body.appendString("Content-Disposition: form-data; name=\"file\"; filename=\"\(UUID().uuidString).jpeg\"\r\n")
        body.appendString("Content-Type: image/jpg\r\n\r\n")
        body.append(data)
        body.appendString("\r\n")
        body.appendString("--".appending(boundary.appending("--")))
        
        return body
    }
    
    fileprivate func getQuery(_ args: (String, Any?)...) -> String? {
        
        var query: String? = nil
        
        let filtered = args.compactMap { $0.1 != nil ? ($0.0, $0.1!) : nil }
        
        for item in filtered {
            query.add(item.0, item.1)
        }
        
        return query
    }
    
    let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .custom(roundTripIso8601Encoder) //.formatted(iso8601Formatter)
        encoder.outputFormatting = .prettyPrinted
        return encoder
    }()
    
    let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom(roundTripIso8601Decoder) //.formatted(iso8601Formatter)
        return decoder
    }()
}

// MARK: - Date Encoder & Decoder

extension BotClient {
    
    static let iso8601Formatter: DateFormatter = {
        
        let formatter = DateFormatter()
        
        formatter.calendar      = Calendar(identifier: .iso8601)
        formatter.locale        = Locale(identifier: "en_US_POSIX")
        formatter.timeZone      = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat    = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSZ"
        
        return formatter
    }()
    
    static let roundTripIso8601: DateFormatter = {
        
        let formatter = DateFormatter()
        
        formatter.calendar      = Calendar(identifier: .iso8601)
        formatter.locale        = Locale(identifier: "en_US_POSIX")
        formatter.timeZone      = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat    = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSZ"
        
        return formatter
    }()
    
    static func roundTripIso8601Encoder(date: Date, encoder: Encoder) throws -> Void {
        
        var container = encoder.singleValueContainer()
        
        let data = roundTripIso8601.roundTripIso8601StringWithMicroseconds(from: date)
        
        try container.encode(data)
    }
    
    
    static func roundTripIso8601Decoder(decoder: Decoder) throws -> Date {
        
        let container = try decoder.singleValueContainer()
        
        let dateString = try container.decode(String.self)
        
        guard let microsecondDate = roundTripIso8601.roundTripIso8601DateWithMicroseconds(from: dateString) else {
            throw DecodingError.dataCorrupted(.init(codingPath: container.codingPath, debugDescription: "unable to parse string (\(dateString)) into date"))
        }
        
        return microsecondDate
    }
}

public enum BotClientError : Error {
    case unknown
    case invalidIds
    case noConversation
    case urlError(String)
    case decodeError(DecodingError)
    case encodingError(EncodingError)
}


fileprivate extension Optional where Wrapped == String {
    mutating func add (_ queryKey: String, _ queryValue: Any?) {
        if self == nil, let queryValue = queryValue {
            
            if let queryValueString = queryValue as? String, queryValueString.isEmpty {
                return
            }
            
            var queryValueString = "\(queryValue)".replacingOccurrences(of: " ", with: "%20")
            
            if let queryValueArray = queryValue as? [String], !queryValueArray.isEmpty {
                queryValueString = queryValueArray.joined(separator: ",").replacingOccurrences(of: "\\\"", with: "")
            }
            
            if !queryValueString.isEmpty {
                self = "?\(queryKey)=\(queryValueString)"
            }
        } else {
            self!.add(queryKey, queryValue)
        }
    }
}

fileprivate extension String {
    mutating func add (_ queryKey: String, _ queryValue: Any?) {
        if let queryValue = queryValue {
            
            if let queryValueString = queryValue as? String, queryValueString.isEmpty {
                return
            }
            
            var queryValueString = "\(queryValue)".replacingOccurrences(of: " ", with: "%20")
            
            if let queryValueArray = queryValue as? [String], !queryValueArray.isEmpty {
                queryValueString = queryValueArray.joined(separator: ",").replacingOccurrences(of: "\\\"", with: "")
            }
            
            if !queryValueString.isEmpty {
                if self.contains("?") {
                    self += "&\(queryKey)=\(queryValueString)"
                } else {
                    self = "?\(queryKey)=\(queryValueString)"
                }
            }
        }
    }
}


