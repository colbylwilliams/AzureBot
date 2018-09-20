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
    
    let demo = false
    
    public static let shared: BotClient = BotClient()
    init() { }
    
    fileprivate var directLineSecretKey: String = ""

    fileprivate var context: [Context] = []
    
    fileprivate var socket: WebSocket!
    fileprivate let session: URLSession = URLSession(configuration: URLSessionConfiguration.default)
    
    //fileprivate var activities: [Activity] = []
    fileprivate var watermark: String?
    fileprivate var conversation: Conversation?


    var currentUser = ChannelAccount(id: "default-user", name: "User")
    

    // MARK: - Public API
    
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
    
    
    public func configure(withPlistNamed customPlistName: String? = nil, user: ChannelAccount? = nil, context: [Context] = []) {
        
        if let keys = BotKeys.tryCreateFromPlists(custom: customPlistName) {
            
            if keys.hasValidDirectLineSecret {
                self.directLineSecretKey = keys.directLineSecret!
            }
        }
        
        if let user = user, !user.id.isNilOrEmpty, !user.name.isNilOrEmpty {
            self.currentUser = user
        }
        self.context = context
    }

    
    
    public func start(completion: @escaping (Response<Conversation>) -> Void) {
        
        if (conversation?.token ?? directLineSecretKey).isEmpty, let keys = BotKeys.tryCreateFromPlists(), keys.hasValidDirectLineSecret {
            self.directLineSecretKey = keys.directLineSecret!
        }
        
        guard !(conversation?.token ?? directLineSecretKey).isEmpty else {
            print("[BotClient] Error: Can not start client without a conversation token or Direct Line Secret")
            completion(Response(BotClientError.invalidIds))
            return
        }
        
        let starting = conversation == nil
        
        restoreConversation()
        
        if conversation == nil {
            startConversation { r in
                if let c = r.resource {
                    self.conversation = c
                    if let wws = c.streamUrl, let url = URL(string: wws) {
                        self.cacheConversation()
                        self.startSocket(url)
                    }
                } else if let e = r.error {
                    print("[BotClient] Error: " + e.localizedDescription)
                }
                completion(r)
            }
        } else {
            
            getActivities(fromWatermark: watermark) { ar in
                
                if let set = ar.resource {
                    self.process(activitySet: set)
                }
                
                self.reconnectToConversation(withWatermark: self.watermark) { r in
                    if let c = r.resource {
                        self.conversation = c
                        if let wws = c.streamUrl, let url = URL(string: wws) {
                            self.cacheConversation()
                            self.startSocket(url)
                            
                            if starting {
                                self.postActivity(Activity(type: .conversationUpdate, from: self.currentUser, in: c)) { _ in }
                            }
                        }
                    } else if let e = r.error {
                        print("[BotClient] Error: " + e.localizedDescription)
                    }
                    completion(r)
                }
            }
        }
    }

    
    public func send(message: String, completion: @escaping (Response<ResourceResponse>) -> Void) {
        
        if demo, message.lowercased() == "reset" {
            messages = SortedArray(areInIncreasingOrder: > )
            watermark = "0"
            conversation = nil
            UserDefaults.standard.set(nil, forKey: "com.azure.bot.conversation.id")
            start { _ in }
            return
        }
        
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
        
        postActivity(activity, completion: completion)
    }
    
    
    
    // MARK: - Process Activities
    
    func process(activitySet: ActivitySet) {
        
        if let wm = activitySet.watermark, !wm.isEmpty, (watermark.isNilOrEmpty || wm > watermark!) {
            watermark = wm
        }
        
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

    
    
    // MARK: - WebSocketDelegate
    
    func startSocket(_ url: URL) {
        print("[BotClient] starting socket...")
        socket = WebSocket.init(url: url)
        socket.delegate = self
        socket.connect()
    }
    
    // MARK: WebSocketDelegate
    
    public func websocketDidConnect(socket: WebSocketClient) {
        print("[BotClient] websocketDidConnect")
    }
    
    public func websocketDidDisconnect(socket: WebSocketClient, error: Error?) {
        print("[BotClient] websocketDidDisconnect: \(error?.localizedDescription ?? "")")
    }
    
    public func websocketDidReceiveMessage(socket: WebSocketClient, text: String) {
        
        // ignore empty messages
        guard !text.isEmpty, let data = text.data(using: .utf8) else { return }
        
        print("[BotClient] websocketDidReceiveMessage:\n\(text)")
        
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
    
    
    
    // MARK: - Direct Line API
    
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

    // MARK: - Create & Send Request
    
    fileprivate func sendRequest<T:Codable> (_ request: URLRequest, completion: @escaping (Response<T>) -> ()) {
        
        session.dataTask(with: request) { (data, response, error) in
            
            let httpResponse = response as? HTTPURLResponse
            
            if let error = error {
                
                completion(Response(request: request, data: data, response: httpResponse, result: .failure(error)))
                
            } else if let data = data {
                
                if let statusCode = httpResponse?.statusCode, statusCode >= 400 {
                    
                    if statusCode == HttpStatusCode.forbidden.rawValue, !self.directLineSecretKey.isEmpty, request.url != Api.refreshToken.url() {

                        print("repeatRequest")
                        
                        self.conversation?.token = nil
                        
                        var repeatRequest = request
                        
                        repeatRequest.setValue("Bearer \(self.conversation?.token ?? self.directLineSecretKey)", forHTTPHeaderField: "Authorization")

                        self.sendRequest(repeatRequest, completion: completion)
                        
                    } else {
                        completion(Response(request: request, data: data, response: httpResponse, result: .failure(BotClientError.apiError(try? self.decoder.decode(ApiError.self, from: data)))))
                    }
                    
                    return
                }
                
                
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

// MARK: - Conversation Cache

extension BotClient {
    
    fileprivate func restoreConversation() {
        if conversation == nil,
            let data = UserDefaults.standard.data(forKey: "com.azure.bot.conversation.id"),
            let conversation = try? decoder.decode(Conversation.self, from: data) {
            self.conversation = conversation
        }
    }
    
    fileprivate func cacheConversation() {
        if let c = conversation, !c.conversationId.isNilOrEmpty, let data = try? self.encoder.encode(c) {
            UserDefaults.standard.set(data, forKey: "com.azure.bot.conversation.id")
        }
    }
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

public struct ApiError: Decodable {

    public let error: ApiErrorDetails

    public struct ApiErrorDetails: Decodable {
        public let code: String
        public let message: String
    }
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

