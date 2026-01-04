//
//  ResultsManager.swift
//  WaRee11_V0501
//
//  Created by Chalermchon Lertlum on 8/12/2568 BE.
//

import Foundation

/// เก็บผลลัพธ์ล่าสุดของ simulation (แบบง่าย ๆ ในหน่วยความจำ)
final class ResultsManager {
    
    static let shared = ResultsManager()
    
    /// ผลลัพธ์ล่าสุด
    private(set) var lastResult: SolverResult?
    
    /// การตั้งค่าที่ใช้รัน simulation ล่าสุด (ไว้ให้ Results/Chart ใช้)
    private(set) var lastSettings: SimulationSettings?
    
    private init() {}
    
    func save(result: SolverResult, settings: SimulationSettings) {
        self.lastResult = result
        self.lastSettings = settings
    }
    
    func clear() {
        self.lastResult = nil
        self.lastSettings = nil
    }
}
