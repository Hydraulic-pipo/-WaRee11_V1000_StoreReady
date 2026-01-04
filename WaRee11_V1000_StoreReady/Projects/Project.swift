//
//  Project.swift
//  WaRee11_V0501
//
//  Created by Chalermchon Lertlum on 21/11/2568 BE.
//

import Foundation

/// ข้อมูลของโปรเจกต์หนึ่งอัน
struct Project: Codable, Equatable, Identifiable {
    let id: UUID
    var name: String
    let createdAt: Date
    
    init(id: UUID = UUID(), name: String, createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
    }
}
