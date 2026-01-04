//
//  SimulationSettings.swift
//  WaRee11_V0501
//
//  Created by Chalermchon Lertlum on 28/11/2568 BE.
//

//
//  SimulationSettings.swift
//  WaRee11_v05
//
//  Created by Chalermchon Lertlum on.
//

import Foundation

/// เก็บค่าการตั้งค่าการรัน Simulation ทั้งหมดใน 1 struct
/// ทำให้:
///  - เซฟ / โหลด ผ่าน UserDefaults ง่าย (Codable)
///  - ส่งต่อไปให้ Solver ทีเดียวได้เลย
struct SimulationSettings: Codable {
    
    /// ขนาด time step (วินาที) เช่น 60 = 1 นาที
    var timeStep: Double
    
    /// จำนวน step ที่จะรัน (Nstep)
    var totalSteps: Int
    
    /// Courant number (สำหรับเช็ค stability)
    var courantNumber: Double
    
    /// ความเร่งโน้มถ่วง g (m/s²) เช่น 9.81
    var gravity: Double
    
    /// ค่าคงที่ใน Manning (c0 = 1.0 สำหรับ SI, 1.49 สำหรับ US)
    var c0: Double
    
    /// ชนิดของ Scheme เช่น "upwind", "lax", "maccormack"
    var schemeType: String
    
    /// ขอให้ถือว่าเป็น upstream inflow Q (m³/s)
    var flowIn: Double
    
    /// downstream water level (stage) (m)
    var stageDown: Double
    
    /// เวลาเริ่ม Simulation (ใช้สำหรับ timestamp แสดงผล)
    var startDate: Date
    
    /// เวลาเสร็จ Simulation
    var endDate: Date
}
