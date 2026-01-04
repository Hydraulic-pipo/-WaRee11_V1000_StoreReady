//
//  RiverNode.swift
//  WaRee11_V0501
//
//  Created by Chalermchon Lertlum on 21/11/2568 BE.
//

import Foundation

/// ข้อมูลโหนดแม่น้ำ 1 จุด
struct RiverNode: Codable, Equatable, Identifiable {
    let id: UUID
    var name: String
    var chainage: Double
    var latitude: Double?
    var longitude: Double?
    
    init(id: UUID = UUID(),
         name: String,
         chainage: Double,
         latitude: Double? = nil,
         longitude: Double? = nil) {
        self.id = id
        self.name = name
        self.chainage = chainage
        self.latitude = latitude
        self.longitude = longitude
    }
}
