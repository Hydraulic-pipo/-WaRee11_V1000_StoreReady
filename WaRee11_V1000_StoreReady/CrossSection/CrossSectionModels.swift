//
//  CrossSectionModels.swift
//  WaRee11_V0501
//
//  Created by Chalermchon Lertlum on 21/11/2568 BE.
//

import Foundation

/// จุดหน้าตัด 1 จุด (ระยะทางแนวนอนจากแกนอ้างอิง, ระดับความสูง)
struct CrossSectionPoint: Codable, Equatable {
    var width: Double      // ระยะทางแนวนอน (m)
    var elevation: Double  // ระดับความสูง (m) เช่น ใช้ค่าลบสำหรับก้นร่องน้ำ
}

/// ข้อมูลหน้าตัดของโหนดหนึ่ง ๆ
/// เก็บ:
/// - points: จุดหน้าตัด
/// - manningN: ค่าสัมประสิทธิ์ Manning
/// - waterLevel: ระดับน้ำ (elevation) เพื่อใช้อ้างอิง/แสดงผล
/// - designWaterLevel: ระดับน้ำที่เลือกเป็นจุดออกแบบจาก Rating Curve
/// - designDischarge: Q ที่เลือกเป็นจุดออกแบบจาก Rating Curve
struct CrossSectionData: Codable, Equatable {
    var points: [CrossSectionPoint]
    var manningN: Double?
    var waterLevel: Double?
    
    /// ระดับน้ำจุดออกแบบ (design h, m)
    var designWaterLevel: Double?
    
    /// Q จุดออกแบบ (design Q, m3/s)
    var designDischarge: Double?
    
    init(points: [CrossSectionPoint] = [],
         manningN: Double? = nil,
         waterLevel: Double? = nil,
         designWaterLevel: Double? = nil,
         designDischarge: Double? = nil) {
        self.points = points
        self.manningN = manningN
        self.waterLevel = waterLevel
        self.designWaterLevel = designWaterLevel
        self.designDischarge = designDischarge
    }
}

// MARK: - Template Generators

extension CrossSectionData {
    
    /// สร้างหน้าตัดแบบสี่เหลี่ยมผืนผ้า (rectangular channel)
    static func rectangular(bottomWidth: Double,
                            depth: Double,
                            manningN: Double? = nil,
                            waterLevel: Double? = nil,
                            designWaterLevel: Double? = nil,
                            designDischarge: Double? = nil) -> CrossSectionData {
        // ผิวดิน = 0, ก้นร่องน้ำ = -depth
        let zTop = 0.0
        let zBottom = -abs(depth)
        
        let xLeft = 0.0
        let xRight = bottomWidth
        
        let points = [
            CrossSectionPoint(width: xLeft, elevation: zTop),
            CrossSectionPoint(width: xLeft, elevation: zBottom),
            CrossSectionPoint(width: xRight, elevation: zBottom),
            CrossSectionPoint(width: xRight, elevation: zTop)
        ]
        
        return CrossSectionData(points: points,
                                manningN: manningN,
                                waterLevel: waterLevel,
                                designWaterLevel: designWaterLevel,
                                designDischarge: designDischarge)
    }
    
    /// สร้างหน้าตัดแบบคางหมู (trapezoidal channel)
    static func trapezoidal(bottomWidth: Double,
                            depth: Double,
                            sideSlope: Double,
                            includeBankTop: Bool = true,
                            manningN: Double? = nil,
                            waterLevel: Double? = nil,
                            designWaterLevel: Double? = nil,
                            designDischarge: Double? = nil) -> CrossSectionData {
        
        let d = abs(depth)
        let m = max(sideSlope, 0.0)
        
        let sideWidth = m * d
        let zTop = 0.0
        let zBottom = -d
        
        let leftBottomX = sideWidth
        let rightBottomX = sideWidth + bottomWidth
        
        var points: [CrossSectionPoint] = []
        
        if includeBankTop {
            points.append(CrossSectionPoint(width: 0.0, elevation: zTop))
        }
        
        points.append(CrossSectionPoint(width: leftBottomX, elevation: zBottom))
        points.append(CrossSectionPoint(width: rightBottomX, elevation: zBottom))
        
        if includeBankTop {
            let rightTopX = rightBottomX + sideWidth
            points.append(CrossSectionPoint(width: rightTopX, elevation: zTop))
        }
        
        return CrossSectionData(points: points,
                                manningN: manningN,
                                waterLevel: waterLevel,
                                designWaterLevel: designWaterLevel,
                                designDischarge: designDischarge)
    }
}
