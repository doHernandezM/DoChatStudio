//  Chat.swift
//  DoChatStudio
//
//  Created by Cosas on 2/2/25.
//

//public typealias Chat = (role: Role, content: String)

import SwiftUI
import LLM

public struct Message: Identifiable, Codable {
    public let id: UUID
    
    public let role: Role?
    public let content: String
    public let timestamp: Date
    public var tokens: Int = 0
    public var ignored: Bool = false
    public var llmState: LLMState? = nil
    
    enum CodingKeys: String, CodingKey {
        case id
        case role
        case content
        case timestamp
        case tokens
        case ignored
    }
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.role = try container.decode(String.self, forKey: .role) == "user" ? .user : .bot
        self.content = try container.decode(String.self, forKey: .content)
        self.timestamp = try container.decode(Date.self, forKey: .timestamp)
        self.tokens = try container.decode(Int.self, forKey: .tokens)
        self.ignored = try container.decode(Bool.self, forKey: .ignored)
    }
    
    public init (chat: Chat, ignored: Bool = false, llmState: LLMState? = nil) {
        self.init(role: chat.role, content: chat.content, ignored: ignored, llmState: llmState)
    }
    
    public init (role: Role?, content: String, ignored: Bool = false, llmState: LLMState? = nil) {
        self.id = UUID()
        self.role = role
        self.content = content
        self.timestamp = Date()
        self.ignored = ignored
        self.llmState = llmState
    }
    
    public func encode(to encoder: any Encoder) throws {
        let roleString = role == nil ? "" : role == .user ? "user" : "bot"
        
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(roleString, forKey: .role)
        try container.encode(content, forKey: .content)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(tokens, forKey: .tokens)
        try container.encode(ignored, forKey: .ignored)
    }
}
