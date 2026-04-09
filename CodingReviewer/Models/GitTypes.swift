//
//  GitTypes.swift
//  CodingReviewer
//
//  Shared git-related model types
//

import Foundation

/// Represents a git commit
public struct GitCommit: Identifiable, Sendable, Codable {
    public let id: String // hash
    public let author: String
    public let date: Date
    public let message: String

    public init(id: String, author: String, date: Date, message: String) {
        self.id = id
        self.author = author
        self.date = date
        self.message = message
    }
}

/// Represents a git stash
public struct GitStash: Identifiable, Sendable, Codable {
    public let id: String
    public let name: String
    public let date: Date

    public init(id: String, name: String, date: Date) {
        self.id = id
        self.name = name
        self.date = date
    }
}
