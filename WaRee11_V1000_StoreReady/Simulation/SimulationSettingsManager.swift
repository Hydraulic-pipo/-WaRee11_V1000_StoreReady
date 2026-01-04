//
//  SimulationSettingsManager.swift
//  WaRee11_V0501
//
//  Created by Chalermchon Lertlum on 28/11/2568 BE.
//

//
//  SimulationSettingsManager.swift
//  WaRee11_v05
//
//

import Foundation

/// จัดการเซฟ / โหลด SimulationSettings ผ่าน UserDefaults
struct SimulationSettingsManager {
    
    private static let key = "SimulationSettings"
    
    static func save(_ settings: SimulationSettings) {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(settings) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
    
    static func load() -> SimulationSettings? {
        guard let data = UserDefaults.standard.data(forKey: key) else {
            return nil
        }
        let decoder = JSONDecoder()
        return try? decoder.decode(SimulationSettings.self, from: data)
    }
}
