//
//  SolverManage.swift
//  WaRee11_V0501
//
//  Created by Chalermchon Lertlum on 9/12/2568 BE.
//
//
//  SolverManager.swift
//  WaRee11_V0501
//
//  ตัวจัดการ "ตัวแก้สมการ" สำหรับ simulation
//  STEP 1: เพิ่ม solver แบบ storage 1 reach ใช้ Manning จริงจาก cross section
//

import Foundation

final class SolverManager {
    
    static let shared = SolverManager()
    
    private init() {}
    
    /// จุดเดียวที่ใช้รัน simulation ทั้งแอป
    /// - settings: การตั้งค่าการคำนวณเวลา
    /// - crossSection: geometry ของ node ปัจจุบัน; ถ้าไม่มีจะ fallback เป็น dummy
    func run(settings: SimulationSettings,
             crossSection: CrossSectionData?) -> SolverResult {
        
        // ถ้ามี cross section + Manning n → ใช้ solver จริง
        if let cs = crossSection,
           let n = cs.manningN,
           n > 0,
           cs.points.count >= 2 {
            
            return runSingleReachStorageModel(settings: settings,
                                              crossSection: cs,
                                              manningN: n)
        }
        
        // ถ้าไม่มี geometry หรือยังไม่ตั้ง n → ใช้ dummy แบบเดิม
        switch settings.schemeType.lowercased() {
        case "upwind":
            return runUpwindDummy(settings: settings)
        case "lax":
            return runLaxDummy(settings: settings)
        case "maccormack":
            return runMacCormackDummy(settings: settings)
        default:
            return runUpwindDummy(settings: settings)
        }
    }
    
    // MARK: - REAL SOLVER (storage model + Manning)
    
    /// แบบจำลอง storage 1 reach:
    /// dV/dt = Qin - Qout(h),  V = A(h)*L
    /// dh/dt = (Qin - Qout) / (L * T(h))
    private func runSingleReachStorageModel(settings: SimulationSettings,
                                            crossSection: CrossSectionData,
                                            manningN: Double) -> SolverResult {
        
        var points: [SolverResultPoint] = []
        
        let dt = settings.timeStep
        let nSteps = max(settings.totalSteps, 1)
        
        // ความยาว reach (สมมุติไว้ก่อน 1000 m; ภายหลังดึงจาก RiverNetwork ได้)
        let reachLength: Double = 1000.0
        
        // หา bed min elevation
        let bedElevations = crossSection.points.map { $0.elevation }
        let minBed = bedElevations.min() ?? 0.0
        
        // เลือก h เริ่มต้น:
        // 1) ถ้ามี waterLevel ใน cross section ใช้ค่านั้น
        // 2) ถ้ามี designWaterLevel ใช้ค่านั้น
        // 3) ไม่งั้นใช้ stageDown จาก settings
        var h: Double = settings.stageDown
        if let wl = crossSection.waterLevel {
            h = wl
        } else if let dwl = crossSection.designWaterLevel {
            h = dwl
        }
        // ไม่ให้ต่ำกว่าท้องลำน้ำ
        h = max(h, minBed + 0.01)
        
        // tailwater คงที่ = stageDown
        let hDown = settings.stageDown
        
        let g = settings.gravity
        let c0 = settings.c0
        let qIn = settings.flowIn
        
        for i in 0..<nSteps {
            let t = Double(i) * dt
            
            // geometry ณ h ปัจจุบัน
            let geom = computeGeometry(crossSection: crossSection, waterLevel: h)
            let A = geom.area
            let T = max(geom.topWidth, 0.01)          // กันไม่ให้หารศูนย์
            let P = max(geom.wettedPerimeter, 0.01)
            
            // ถ้า A แทบเป็นศูนย์ แสดงว่าน้ำยังไม่ถึงท้องลำน้ำ → ให้ Q_out = 0
            let qOut: Double
            if A < 1e-6 {
                qOut = 0.0
            } else {
                // gradient S จากความต่างระดับ upstream/downstream
                let dz = max(h - hDown, 0.0)
                let S = max(dz / reachLength, 1e-5)
                
                // R = A / P
                let R = A / P
                
                // Manning: Q = c0/n * A * R^(2/3) * S^(1/2)
                let q = (c0 / manningN) * A * pow(R, 2.0/3.0) * sqrt(S)
                qOut = max(q, 0.0)
            }
            
            // dh/dt = (Qin - Qout) / (L * T)
            let dHdt = (qIn - qOut) / (reachLength * T)
            let hNew = max(h + dt * dHdt, minBed + 0.0)  // ไม่ให้ต่ำกว่าท้อง
            
            // เก็บค่า ณ เวลานี้ (ใช้ h, qOut ปัจจุบัน)
            let point = SolverResultPoint(time: t,
                                          waterLevel: h,
                                          discharge: qOut)
            points.append(point)
            
            // update state สำหรับ step ถัดไป
            h = hNew
        }
        
        return SolverResult(points: points)
    }
    
    // MARK: - Geometry helper
    
    /// คำนวณ A(h), topWidth(h), wettedPerimeter(h) จาก cross-section points
    private func computeGeometry(crossSection: CrossSectionData,
                                 waterLevel h: Double)
    -> (area: Double, topWidth: Double, wettedPerimeter: Double) {
        
        let pts = crossSection.points.sorted { $0.width < $1.width }
        if pts.count < 2 {
            return (0.0, 0.0, 0.0)
        }
        
        var area: Double = 0.0
        var wettedPerimeter: Double = 0.0
        
        var wetMinX = Double.greatestFiniteMagnitude
        var wetMaxX = -Double.greatestFiniteMagnitude
        
        for i in 0..<(pts.count - 1) {
            let p1 = pts[i]
            let p2 = pts[i + 1]
            
            let x1 = p1.width
            let z1 = p1.elevation
            let x2 = p2.width
            let z2 = p2.elevation
            
            let dx = x2 - x1
            let dz = z2 - z1
            let segLen = hypot(dx, dz)
            
            let y1 = h - z1
            let y2 = h - z2
            
            let below1 = y1 > 0
            let below2 = y2 > 0
            
            // กรณีไม่มีจุดใดอยู่ใต้น้ำ
            if !below1 && !below2 {
                continue
            }
            
            // update ขอบเขตผิวน้ำ (ใช้แค่ x)
            wetMinX = min(wetMinX, x1, x2)
            wetMaxX = max(wetMaxX, x1, x2)
            
            // ทั้งสองจุดอยู่ใต้น้ำ → fully submerged segment
            if below1 && below2 {
                // area = trapezoid บน dx
                area += (y1 + y2) * 0.5 * abs(dx)
                wettedPerimeter += segLen
            } else {
                // partial submerged: หนึ่งจุดเหนือ, หนึ่งจุดใต้
                // หาจุดตัดกับผิวน้ำ z = h
                // สมมติ pLow เป็นจุดใต้, pHigh เป็นจุดเหนือ
                let (xLow, zLow, yLow, xHigh, zHigh) : (Double, Double, Double, Double, Double)
                if below1 && !below2 {
                    xLow = x1; zLow = z1; yLow = y1
                    xHigh = x2; zHigh = z2
                } else {
                    xLow = x2; zLow = z2; yLow = y2
                    xHigh = x1; zHigh = z1
                }
                
                // fraction จาก low → high ที่ z = h
                let dzSeg = zHigh - zLow
                if abs(dzSeg) < 1e-9 {
                    continue
                }
                let f = (h - zLow) / dzSeg  // 0..1
                let xInt = xLow + f * (xHigh - xLow)
                
                // ความยาวส่วนใต้น้ำ
                let dxSub = xInt - xLow
                let dzSub = h - zLow
                let subLen = hypot(dxSub, dzSub)
                wettedPerimeter += abs(subLen)
                
                // area เป็น trapezoid จาก yLow → 0 บน dxSub
                area += (yLow + 0.0) * 0.5 * abs(dxSub)
                
                // update ผิวน้ำด้วยจุดตัดเพิ่ม
                wetMinX = min(wetMinX, xInt)
                wetMaxX = max(wetMaxX, xInt)
            }
        }
        
        let topWidth: Double
        if wetMinX <= wetMaxX {
            topWidth = wetMaxX - wetMinX
        } else {
            topWidth = 0.0
        }
        
        return (area, topWidth, wettedPerimeter)
    }
    
    // MARK: - DUMMY SOLVERS เดิม (เผื่อกรณีไม่มี geometry)
    
    /// Upwind: ให้กราฟค่อย ๆ ขึ้นแล้วทรงตัว (smooth)
    private func runUpwindDummy(settings: SimulationSettings) -> SolverResult {
        var points: [SolverResultPoint] = []
        
        let dt = settings.timeStep
        let nSteps = max(settings.totalSteps, 1)
        let baseQ = settings.flowIn
        let baseH = settings.stageDown
        
        for i in 0..<nSteps {
            let t = Double(i) * dt
            
            let frac = min(Double(i) / Double(nSteps), 1.0)
            let q = baseQ * (0.7 + 0.3 * frac)
            let h = baseH + 0.3 * frac
            
            let p = SolverResultPoint(time: t,
                                      waterLevel: h,
                                      discharge: q)
            points.append(p)
        }
        
        return SolverResult(points: points)
    }
    
    /// Lax: กราฟมีการแกว่ง (oscillation) เล็กน้อยรอบค่าเฉลี่ย
    private func runLaxDummy(settings: SimulationSettings) -> SolverResult {
        var points: [SolverResultPoint] = []
        
        let dt = settings.timeStep
        let nSteps = max(settings.totalSteps, 1)
        let baseQ = settings.flowIn
        let baseH = settings.stageDown
        
        for i in 0..<nSteps {
            let t = Double(i) * dt
            
            let phase = 2.0 * Double.pi * Double(i) / 80.0
            let q = baseQ * (1.0 + 0.15 * sin(phase))
            let h = baseH + 0.25 * sin(phase + Double.pi / 4.0)
            
            let p = SolverResultPoint(time: t,
                                      waterLevel: h,
                                      discharge: q)
            points.append(p)
        }
        
        return SolverResult(points: points)
    }
    
    /// MacCormack: ทำรูปแบบเป็น pulse (พุ่งขึ้น-ลงชัด ๆ)
    private func runMacCormackDummy(settings: SimulationSettings) -> SolverResult {
        var points: [SolverResultPoint] = []
        
        let dt = settings.timeStep
        let nSteps = max(settings.totalSteps, 1)
        let baseQ = settings.flowIn
        let baseH = settings.stageDown
        
        let peakIndex = nSteps / 3
        
        for i in 0..<nSteps {
            let t = Double(i) * dt
            
            let x = Double(i - peakIndex)
            let sigma = Double(nSteps) / 10.0
            let pulse = exp(-0.5 * (x * x) / (sigma * sigma))
            
            let q = baseQ * (0.8 + 0.6 * pulse)
            let h = baseH + 0.4 * pulse
            
            let p = SolverResultPoint(time: t,
                                      waterLevel: h,
                                      discharge: q)
            points.append(p)
        }
        
        return SolverResult(points: points)
    }
}
