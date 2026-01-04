//
//  CrossSectionStorageManager.swift
//  WaRee11_V0501
//
//  Created by Chalermchon Lertlum on 21/11/2568 BE.
//

import Foundation

/// จัดการเก็บ/โหลดข้อมูล cross section สำหรับแต่ละ project + node
final class CrossSectionStorageManager {
    
    static let shared = CrossSectionStorageManager()
    private init() {}
    
    /// สร้าง key สำหรับเก็บหน้าตัดของ node หนึ่งใน project หนึ่ง
    private func key(for project: Project, node: RiverNode) -> String {
        return "cross_section_\(project.id.uuidString)_\(node.id.uuidString)"
    }
    
    /// โหลดข้อมูลหน้าตัด (points) ของ node ใน project
    func loadCrossSection(for project: Project, node: RiverNode) -> CrossSectionData {
        let defaults = UserDefaults.standard
        let storageKey = key(for: project, node: node)
        
        guard let data = defaults.data(forKey: storageKey) else {
            return CrossSectionData(points: [])
        }
        
        do {
            let cs = try JSONDecoder().decode(CrossSectionData.self, from: data)
            return cs
        } catch {
            print("Failed to decode cross section: \(error)")
            return CrossSectionData(points: [])
        }
    }
    
    /// เซฟข้อมูลหน้าตัด
    func saveCrossSection(_ cs: CrossSectionData, for project: Project, node: RiverNode) {
        let defaults = UserDefaults.standard
        let storageKey = key(for: project, node: node)
        
        do {
            let data = try JSONEncoder().encode(cs)
            defaults.set(data, forKey: storageKey)
        } catch {
            print("Failed to encode cross section: \(error)")
        }
    }
}
