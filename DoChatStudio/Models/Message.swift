//
//  Message.swift
//  MLXChatExample
//
//  Created by İbrahim Çetin on 20.04.2025.
//

import Foundation
import MLX
import MLXLMCommon

/// Represents a chat message in the conversation.
/// Messages can contain text content and optional media attachments (images and videos).
@Observable
class Message: Identifiable, Codable {
    /// Unique identifier for the message
    let id: UUID

    /// The role of the message sender (user, assistant, or system)
    let role: Role

    /// The text content of the message
    var content: String

    /// Array of image URLs attached to the message
    var images: [URL]

    /// Array of video URLs attached to the message
    var videos: [URL]

    /// Timestamp when the message was created
    let timestamp: Date
    
    var timeStampString: String
    
    var generationInfo: GenerateCompletionInfo? = nil {
        didSet {
            self.timeStampString = {
                let dateFormatterStart = DateFormatter()
                dateFormatterStart.dateStyle = .short
                dateFormatterStart.timeStyle = .medium
                let dateFormatterEnd = DateFormatter()
                dateFormatterEnd.dateStyle = .none
                dateFormatterEnd.timeStyle = .medium
                
                if generationInfo == nil {
                    return dateFormatterStart.string(from: timestamp)
                }
                let generationTime = generationInfo!.generateTime + generationInfo!.promptTime
                return "\(dateFormatterStart.string(from: timestamp)) - \(dateFormatterEnd.string(from: timestamp.addingTimeInterval(generationTime)))"
            
            }()
        }
    }

    var modelState: ModelState? = nil
    
    /// Creates a new message with the specified role, content, and optional media attachments
    /// - Parameters:
    ///   - role: The role of the message sender
    ///   - content: The text content of the message
    ///   - images: Optional array of image URLs
    ///   - videos: Optional array of video URLs
    init(role: Role, content: String, images: [URL] = [], videos: [URL] = []) {
        self.id = UUID()
        self.role = role
        self.content = content
        self.images = images
        self.videos = videos
        self.timestamp = .now
        self.timeStampString = {
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .short
            dateFormatter.timeStyle = .medium
            return dateFormatter.string(from: .now)
        
        }()
    }

    /// Defines the role of the message sender in the conversation
    enum Role: Codable {
        /// Message from the user
        case prompt
        
        case user
        /// Message from the AI assistant
        case assistant
        /// System message providing context or instructions
        case system
    }
}

/// Convenience methods for creating different types of messages
extension Message {
    /// Creates a user message with optional media attachments
    /// - Parameters:
    ///   - content: The text content of the message
    ///   - images: Optional array of image URLs
    ///   - videos: Optional array of video URLs
    /// - Returns: A new Message instance with user role
    static func user(_ content: String, images: [URL] = [], videos: [URL] = []) -> Message {
        Message(role: .user, content: content, images: images, videos: videos)
    }
    static func prompt(_ content: String, images: [URL] = [], videos: [URL] = []) -> Message {
        Message(role: .prompt, content: content, images: images, videos: videos)
    }

    /// Creates an assistant message
    /// - Parameter content: The text content of the message
    /// - Returns: A new Message instance with assistant role
    static func assistant(_ content: String) -> Message {
        Message(role: .assistant, content: content)
    }

    /// Creates a system message
    /// - Parameter content: The text content of the message
    /// - Returns: A new Message instance with system role
    static func system(_ content: String) -> Message {
        Message(role: .system, content: content)
    }
}


extension GenerateCompletionInfo: Codable {
    
    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.init(promptTokenCount: try c.decodeIfPresent(Int.self, forKey: .promptTokenCount) ?? 0
                    , generationTokenCount: try c.decodeIfPresent(Int.self, forKey: .generationTokenCount) ?? 0
                    , promptTime: try c.decodeIfPresent(TimeInterval.self, forKey: .promptTime) ?? TimeInterval()
                    , generationTime: try c.decode(TimeInterval.self, forKey: .generateTime)
        )
    }
    
    private enum CodingKeys: String, CodingKey {
        case promptTokenCount, generationTokenCount, promptTime, generateTime
    }
    
    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encodeIfPresent(promptTokenCount, forKey: .promptTokenCount)
        try c.encodeIfPresent(generationTokenCount, forKey: .generationTokenCount)
        try c.encodeIfPresent(promptTime, forKey: .promptTime)
        try c.encodeIfPresent(generateTime, forKey: .generateTime)
    
    }
    
    var generationTime: String {
        let formatter = DateComponentsFormatter()
        formatter.maximumUnitCount = 2
        formatter.unitsStyle = .abbreviated
        formatter.zeroFormattingBehavior = .dropAll
//        formatter.allowsFractionalUnits = false
        formatter.allowedUnits = [.day, .hour, .minute, .second]
        
        let string = formatter.string(from: self.generateTime)
        return string ?? ""
    }

    var promptGenerationTime: String {
        let formatter = DateComponentsFormatter()
        formatter.maximumUnitCount = 2
        formatter.unitsStyle = .abbreviated
        formatter.zeroFormattingBehavior = .dropAll
//        formatter.allowsFractionalUnits = false
        formatter.allowedUnits = [.day, .hour, .minute, .second]
        
        let string = formatter.string(from: self.promptTime)
        return string ?? ""
    }
    
    var summarize: String {
        get {
        """
        Tokens: In:\(promptTokenCount), Out: \(generationTokenCount)
        Tokens per Second: In \(promptTokensPerSecond.formatted()) Out: \(generationTokenCount)
        Total \(tokensPerSecond.formatted()) tokens per second, Time:\(generateTime.formatted())s
        """
        }
    }
    
    
//    public let promptTokenCount: Int
//    public let generationTokenCount: Int
//    public let promptTime: TimeInterval
//    public let generateTime: TimeInterval
//        
}

