//
//  SolverResult.swift
//  WaRee11_V0501
//
//  Created by Chalermchon Lertlum on 8/12/2568 BE.
//

import Foundation

/// 1 จุดผลลัพธ์ในเวลา t
/// - time: เวลา (วินาที นับจากเริ่ม simulation)
/// - waterLevel: ระดับน้ำ (m)
/// - discharge: Q (m3/s)
struct SolverResultPoint: Codable {
    var time: Double
    var waterLevel: Double
    var discharge: Double
}

/// ใช้เก็บผลลัพธ์ทั้งชุดของการรัน simulation หนึ่งครั้ง
struct SolverResult: Codable {
    var points: [SolverResultPoint]
    
    init(points: [SolverResultPoint] = []) {
        self.points = points
    }
}
