//
//  Models.swift
//  AzureBot
//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License.
//

import Foundation

public class Conversation: Codable {
    public var conversationId: String?
    public var token: String?
    public var expires_in: Int?
    public var streamUrl: String?
    public var referenceGrammarId: String?
    public var eTag: String?
}

public class ActivitySet: Codable {
    public var activities: [Activity] = []
    public var watermark: String?
}

public struct Activity: Codable, Comparable {
    public var type: ActivityType?
    public var id: String?
    public var timestamp: Date?
    public var localTimestamp: Date?
    public var serviceUrl: String?
    public var channelId: String?
    public var from: ChannelAccount?
    public var conversation: ConversationAccount?
    public var recipient: ChannelAccount?
    public var textFormat: TextFormat?
    public var attachmentLayout: AttachmentLayout?
    public var membersAdded: [ChannelAccount]?
    public var membersRemoved: [ChannelAccount]?
    public var topicName: String?
    public var historyDisclosed: Bool?
    public var locale: String?
    public var text: String?
    public var speak: String?
    public var inputHint: String?
    public var summary: String?
    public var suggestedActions: SuggestedActions?
    public var attachments: [Attachment]?
    public var entities: [Entity]?
    public var channelData: Data?
    public var action: String?
    public var replyToId: String?
    public var value: Data?
    public var name: String?
    public var relatesTo: ConversationReference?
    public var code: String?

    public enum ActivityType: String, Codable {
        case message               = "message"
        case contactRelationUpdate = "contactRelationUpdate"
        case conversationUpdate    = "conversationUpdate"
        case typing                = "typing"
        case endOfConversation     = "endOfConversation"
        case event                 = "event"
        case invoke                = "invoke"
    }

    public enum TextFormat: String, Codable {
        case plain    = "plain"
        case markdown = "markdown"
    }

    public enum AttachmentLayout: String, Codable {
        case list     = "list"
        case carousel = "carousel"
    }
    
    public init(message: String, from: ChannelAccount, `in` conv: Conversation?) {
        self.type = .message
        self.timestamp = Date()
        self.text = message
        self.from = from
        
        if let c = conv {
            self.conversation = ConversationAccount(withId: c.conversationId)
        }
    }
    
    // backwards as the newest messages should be on top
    public static func < (lhs: Activity, rhs: Activity) -> Bool {
        if let lhsId = lhs.id, let rhsId = rhs.id {
            return lhsId > rhsId
        }
        return false
    }
    
    public static func == (lhs: Activity, rhs: Activity) -> Bool {
        if let lhsId = lhs.id, let rhsId = rhs.id {
            return lhsId == rhsId
        }
        return false
    }
}

public struct ChannelAccount: Codable {
    public var id: String?
    public var name: String?
}

public struct ConversationAccount: Codable {
    public var isGroup: Bool?
    public var id: String?
    public var name: String?
    
    init(withId id: String?) {
        self.id = id
    }
}

public class SuggestedActions: Codable {
    public var to: [String]?
    public var actions: [CardAction]?
}

public class Attachment: Codable {
    public var contentType: String?
    public var contentUrl: String?
    public var content: Data?
    public var name: String?          // optional
    public var thumbnailUrl: String?  // optional
}

public class Entity: Codable {
    public var type: String?
}

public class ConversationReference: Codable {
    public var activityId: String?    // optional
    public var user: ChannelAccount?  // optional
    public var bot: ChannelAccount?
    public var conversation: ConversationAccount?
    public var channelId: String?
    public var serviceUrl: String?
}

public class CardAction: Codable {
    public var type: String?
    public var title: String?
    public var image: String?
    public var value: Data?
}

public class ResourceResponse: Codable {
    public var id: String?
}

public class HeroCard: Codable {
    public var title: String?
    public var subtitle: String?
    public var text: String?
    public var images: [CardImage]?
    public var buttons: [CardAction]?
    public var tap: CardAction?
}

public class CardImage: Codable {
    public var url: String?
    public var alt: String?
    public var tap: CardAction?
}

public class ErrorResponse: Codable {
    public var error: ApiError?
}

public class ApiError: Codable {
    public var code: String?
    public var message: String?
}

public class AnimationCard: Codable {
    public var title: String?
    public var subtitle: String?
    public var text: String?
    public var image: ThumbnailUrl?
    public var media: [MediaUrl]?
    public var buttons: [CardAction]?
    public var shareable: Bool?// = true
    public var autoloop: Bool?// = true
    public var autostart: Bool?// = true
}

public class ThumbnailUrl: Codable {
    public var url: String?
    public var alt: String?
}

public class MediaUrl: Codable {
    public var url: String?
    public var profile: String? // optional
}

public class AudioCard: Codable {
    public var aspect: Aspect?
    public var title: String?
    public var subtitle: String?
    public var text: String?
    public var image: ThumbnailUrl?
    public var media: [MediaUrl]?
    public var buttons: [CardAction]?
    public var shareable: Bool = true
    public var autoloop: Bool = true
    public var autostart: Bool = true

    public enum Aspect: String, Codable {
        case sixteenByNine = "16x9"
        case nineBySixteen = "9x16"
    }
}

public class ReceiptCard: Codable {
    public var title: String?
    public var items: [ReceiptItem]?
    public var facts: [Fact]?
    public var tap: CardAction?
    public var total: String?
    public var tax: String?
    public var vat: String?
    public var buttons: [CardAction]?
}

public class ReceiptItem: Codable {
    public var title: String?
    public var subtitle: String?
    public var text: String?
    public var image: CardImage?
    public var price: String?
    public var quantity: String?
    public var tap: CardAction?
}

public class Fact: Codable {
    public var key: String?
    public var value: String?
}

public class SigninCard: Codable {
    public var text: String?
    public var buttons: [CardAction]?
}

public class ThumbnailCard: Codable {
    public var title: String?
    public var subtitle: String?
    public var text: String?
    public var images: [CardImage]?
    public var buttons: [CardAction]?
    public var tap: CardAction?
}

public class VideoCard: Codable {
    public var aspect: String?
    public var title: String?
    public var subtitle: String?
    public var text: String?
    public var image: ThumbnailUrl?
    public var media: [MediaUrl]?
    public var buttons: [CardAction]?
    public var shareable: Bool?
    public var autoloop: Bool?
    public var autostart: Bool?

    public enum Aspect: String, Codable {
        case sixteenByNine = "16:9"
        case fourByThree = "4:3"
    }
}

public class GeoCoordinates: Codable {
    // [WGS 84](https://en.wikipedia.org/wiki/World_Geodetic_System)
    public var elevation: Double?
    public var latitude: Double?
    public var longitude: Double?
    public var type: String?
    public var name: String?
}

public class Mention: Codable {
    public var mentioned: ChannelAccount?
    public var text: String?
    public var type: String?
}

public class Place: Codable {
    // may be `string` or complex object of type `PostalAddress`
    public var address: Data?
    // may be complex object of type `GeoCoordinates` or `GeoShape`
    public var geo: Data?
    // may be `string` (URL) or complex object of type `Map`
    public var hasMap: Data?
    public var type: String?
    public var name: String?
}

public class Thing: Codable {
    public var type: String?
    public var name: String?
}

public class TokenParameters: Codable {
    public var user: ChannelAccount?
    public var eTag: String?
}
