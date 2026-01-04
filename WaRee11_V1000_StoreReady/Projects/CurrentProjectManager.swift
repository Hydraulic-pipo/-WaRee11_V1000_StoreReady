//
//  CurrentProjectManager.swift
//  WaRee11_V0501
//
//  Created by Chalermchon Lertlum on 21/11/2568 BE.
//

import Foundation

/// จัดการโปรเจกต์ที่ผู้ใช้กำลังทำงานอยู่ (current project)
final class CurrentProjectManager {
    
    static let shared = CurrentProjectManager()
    private init() {}
    
    /// โปรเจกต์ที่กำลังถูกเลือก/ใช้งานอยู่
    private(set) var currentProject: Project?
    
    /// ตั้งค่าโปรเจกต์ปัจจุบัน
    func setCurrentProject(_ project: Project) {
        currentProject = project
    }
    
    /// ล้างค่าโปรเจกต์ปัจจุบัน (เช่น ตอน logout หรือเปลี่ยนผู้ใช้)
    func clearCurrentProject() {
        currentProject = nil
    }
}
