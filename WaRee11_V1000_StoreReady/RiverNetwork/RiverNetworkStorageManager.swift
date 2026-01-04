//
//  RiverNetworkStorageManager.swift
//  WaRee11_V0501
//
//  Created by Chalermchon Lertlum on 21/11/2568 BE.
//

import Foundation

/// จัดการเก็บ/โหลด river nodes สำหรับแต่ละโปรเจกต์
final class RiverNetworkStorageManager {
    
    static let shared = RiverNetworkStorageManager()
    private init() {}
    
    /// สร้าง key สำหรับเก็บ node ของโปรเจกต์แต่ละอัน
    private func key(for project: Project) -> String {
        return "river_nodes_\(project.id.uuidString)"
    }
    
    /// โหลด nodes ของโปรเจกต์หนึ่งอัน
    func loadNodes(for project: Project) -> [RiverNode] {
        let defaults = UserDefaults.standard
        let storageKey = key(for: project)
        
        guard let data = defaults.data(forKey: storageKey) else {
            return []
        }
        
        do {
            let nodes = try JSONDecoder().decode([RiverNode].self, from: data)
            return nodes
        } catch {
            print("Failed to decode river nodes: \(error)")
            return []
        }
    }
    
    /// เซฟ nodes ทั้งหมดของโปรเจกต์หนึ่งอัน
    func saveNodes(_ nodes: [RiverNode], for project: Project) {
        let defaults = UserDefaults.standard
        let storageKey = key(for: project)
        
        do {
            let data = try JSONEncoder().encode(nodes)
            defaults.set(data, forKey: storageKey)
        } catch {
            print("Failed to encode river nodes: \(error)")
        }
    }
    
    /// เพิ่ม node ใหม่เข้าไปในโปรเจกต์
    func addNode(_ node: RiverNode, to project: Project) {
        var nodes = loadNodes(for: project)
        nodes.append(node)
        saveNodes(nodes, for: project)
    }
    
    /// ลบ node ตาม index
    func deleteNode(at index: Int, for project: Project) {
        var nodes = loadNodes(for: project)
        guard index < nodes.count else { return }
        nodes.remove(at: index)
        saveNodes(nodes, for: project)
    }
}
