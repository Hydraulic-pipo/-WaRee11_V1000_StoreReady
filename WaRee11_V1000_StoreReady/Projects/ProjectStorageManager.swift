//
//  ProjectStorageManager.swift
//  WaRee11_V0501
//
//  Created by Chalermchon Lertlum on 21/11/2568 BE.
//

import Foundation

/// จัดการเก็บ/โหลดรายชื่อโปรเจกต์จาก UserDefaults
final class ProjectStorageManager {
    
    static let shared = ProjectStorageManager()
    
    private init() {}
    
    private let storageKey = "projects_list_v1"
    
    // โหลดโปรเจกต์ทั้งหมด
    func loadProjects() -> [Project] {
        let defaults = UserDefaults.standard
        guard let data = defaults.data(forKey: storageKey) else {
            return []
        }
        
        do {
            let projects = try JSONDecoder().decode([Project].self, from: data)
            return projects
        } catch {
            print("Failed to decode projects: \(error)")
            return []
        }
    }
    
    // บันทึกโปรเจกต์ทั้งหมด
    private func saveProjects(_ projects: [Project]) {
        let defaults = UserDefaults.standard
        do {
            let data = try JSONEncoder().encode(projects)
            defaults.set(data, forKey: storageKey)
        } catch {
            print("Failed to encode projects: \(error)")
        }
    }
    
    // เพิ่มโปรเจกต์ใหม่
    func addProject(name: String) {
        var projects = loadProjects()
        let newProject = Project(name: name)
        projects.append(newProject)
        saveProjects(projects)
    }
    
    // ลบโปรเจกต์ตาม index ใน array
    func deleteProject(at index: Int) {
        var projects = loadProjects()
        guard index < projects.count else { return }
        projects.remove(at: index)
        saveProjects(projects)
    }
}
