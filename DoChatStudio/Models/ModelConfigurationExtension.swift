//
//  ModelConfiguration.swift
//  DoChatStudio
//
//  Created by Cosas on 9/28/25.
//

import Foundation
import MLX
import MLXLLM
import MLXLMCommon
import MLXVLM

extension ModelConfiguration: Codable {
    private enum CodingKeys: String, CodingKey {
        case id
        case tokenizerId
        case overrideTokenizer
        case defaultPrompt
        case extraEOSTokens
    }

    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let identifier = try container.decode(Identifier.self, forKey: .id)
        let tokenizerId = try container.decodeIfPresent(String.self, forKey: .tokenizerId)
        let overrideTokenizer = try container.decodeIfPresent(String.self, forKey: .overrideTokenizer)
        let defaultPrompt = try container.decodeIfPresent(String.self, forKey: .defaultPrompt) ?? "hello"
        let extraEOSTokens = try container.decodeIfPresent(Set<String>.self, forKey: .extraEOSTokens) ?? []

        switch identifier {
        case .id(let id, let revision):
            self.init(
                id: id,
                revision: revision,
                tokenizerId: tokenizerId,
                overrideTokenizer: overrideTokenizer,
                defaultPrompt: defaultPrompt,
                extraEOSTokens: extraEOSTokens
            )
        case .directory(let url):
            self.init(
                directory: url,
                tokenizerId: tokenizerId,
                overrideTokenizer: overrideTokenizer,
                defaultPrompt: defaultPrompt,
                extraEOSTokens: extraEOSTokens
            )
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(tokenizerId, forKey: .tokenizerId)
        try container.encodeIfPresent(overrideTokenizer, forKey: .overrideTokenizer)
        try container.encode(defaultPrompt, forKey: .defaultPrompt)
        try container.encode(extraEOSTokens, forKey: .extraEOSTokens)
    }
}

extension ModelConfiguration.Identifier: Codable {
    private enum CodingKeys: String, CodingKey {
        case type
        case id
        case revision
        case directory
    }

    private enum IdentifierType: String, Codable {
        case id
        case directory
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(IdentifierType.self, forKey: .type)

        switch type {
        case .id:
            let id = try container.decode(String.self, forKey: .id)
            let revision = try container.decodeIfPresent(String.self, forKey: .revision) ?? "main"
            self = .id(id, revision: revision)
        case .directory:
            let url = try container.decode(URL.self, forKey: .directory)
            self = .directory(url)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .id(let id, let revision):
            try container.encode(IdentifierType.id, forKey: .type)
            try container.encode(id, forKey: .id)
            try container.encode(revision, forKey: .revision)
        case .directory(let url):
            try container.encode(IdentifierType.directory, forKey: .type)
            try container.encode(url, forKey: .directory)
        }
    }
}


extension ModelConfiguration: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(tokenizerId)
        hasher.combine(overrideTokenizer)
        hasher.combine(defaultPrompt)
        hasher.combine(extraEOSTokens)
    }
}

extension ModelConfiguration.Identifier: Hashable {
    public func hash(into hasher: inout Hasher) {
        switch self {
        case .id(let id, let revision):
            hasher.combine(0)          // tag for the case
            hasher.combine(id)
            hasher.combine(revision)
        case .directory(let url):
            hasher.combine(1)          // tag for the case
            hasher.combine(url)
        }
    }
}
