//
//  CrossSectionChartView.swift
//  WaRee11_V0501
//
//  Created by Chalermchon Lertlum on 24/11/2568 BE.
//

import UIKit

/// วาดหน้าตัดจากชุดจุด (width, elevation) ให้ดูคล้ายภูมิประเทศจริงมากขึ้น
/// - แสดง:
///   - พื้นหลังไล่เฉดฟ้า–ดิน
///   - เส้นกริด + scale (x, z)
///   - พื้นดิน (fill ใต้เส้นหน้าตัด)
///   - เส้นหน้าตัด (polyline)
///   - เส้นระดับ 0 (ถ้ามี)
///   - ระดับน้ำ (waterLevel) + เติมสีน้ำตามรูปหน้าตัด
///   - เส้น Design water level (designWaterLevel) + label design Q/h
///   - ค่า Manning n overlay มุมขวาบน
class CrossSectionChartView: UIView {
    
    /// จุดที่ใช้วาดกราฟ
    var points: [CrossSectionPoint] = [] {
        didSet { setNeedsDisplay() }
    }
    
    /// ค่า Manning n ของหน้าตัดนี้ (เอาไว้โชว์บนกราฟ)
    var manningN: Double? {
        didSet { setNeedsDisplay() }
    }
    
    /// ระดับน้ำทั่วไป (เช่น จากช่อง Water level)
    var waterLevel: Double? {
        didSet { setNeedsDisplay() }
    }
    
    /// ระดับน้ำจุดออกแบบ (จาก Rating Curve)
    var designWaterLevel: Double? {
        didSet { setNeedsDisplay() }
    }
    
    /// Q จุดออกแบบ (จาก Rating Curve)
    var designDischarge: Double? {
        didSet { setNeedsDisplay() }
    }
    
    // สีต่าง ๆ ที่ใช้วาด
    private let groundFillColor = UIColor(red: 0.65, green: 0.50, blue: 0.35, alpha: 1.0)  // น้ำตาลดิน
    private let groundStrokeColor = UIColor(red: 0.35, green: 0.20, blue: 0.10, alpha: 1.0) // ขอบดินเข้ม
    private let axisColor = UIColor.gray.withAlphaComponent(0.4)
    private let gridColor = UIColor.gray.withAlphaComponent(0.25)
    
    private let waterFillColor = UIColor.systemBlue.withAlphaComponent(0.30)
    private let waterLineColor = UIColor.systemBlue
    
    private let designLineColor = UIColor.systemRed.withAlphaComponent(0.7)
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        guard points.count > 1 else { return }
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        // ----------------------------------------------------
        // 1) เตรียมข้อมูล + sort ตาม width ให้เรียงจากซ้ายไปขวา
        // ----------------------------------------------------
        let sortedPoints = points.sorted { $0.width < $1.width }
        let widths = sortedPoints.map { $0.width }
        let elevs = sortedPoints.map { $0.elevation }
        
        guard let minX = widths.min(),
              let maxX = widths.max(),
              let minY = elevs.min(),
              let maxY = elevs.max(),
              maxX > minX else {
            return
        }
        
        // ----------------------------------------------------
        // 2) กำหนด padding รอบกราฟ + คำนวณสเกล
        // ----------------------------------------------------
        let paddingLeft: CGFloat = 40   // สำหรับตัวเลข z
        let paddingRight: CGFloat = 20
        let paddingTop: CGFloat = 24
        let paddingBottom: CGFloat = 30 // สำหรับตัวเลข x
        
        let graphWidth = rect.width - paddingLeft - paddingRight
        let graphHeight = rect.height - paddingTop - paddingBottom
        
        // เผื่อ margin บน–ล่าง
        let yMarginFactor = 0.1
        let yRange = maxY - minY
        let expandedMinY = minY - yRange * yMarginFactor
        let expandedMaxY = maxY + yRange * yMarginFactor
        
        let xScale = graphWidth / CGFloat(maxX - minX)
        let yScale = graphHeight / CGFloat(expandedMaxY - expandedMinY)
        
        func pointToScreen(_ w: Double, _ z: Double) -> CGPoint {
            let x = paddingLeft + CGFloat(w - minX) * xScale
            let y = rect.height - paddingBottom - CGFloat(z - expandedMinY) * yScale
            return CGPoint(x: x, y: y)
        }
        
        let graphRect = CGRect(
            x: paddingLeft,
            y: paddingTop,
            width: graphWidth,
            height: graphHeight
        )
        
        // ----------------------------------------------------
        // 3) วาดพื้นหลัง gradient
        // ----------------------------------------------------
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let colors: [CGColor] = [
            UIColor.systemTeal.withAlphaComponent(0.4).cgColor,
            UIColor.white.cgColor,
            UIColor(red: 0.95, green: 0.92, blue: 0.88, alpha: 1.0).cgColor
        ]
        let locations: [CGFloat] = [0.0, 0.5, 1.0]
        if let gradient = CGGradient(colorsSpace: colorSpace,
                                     colors: colors as CFArray,
                                     locations: locations) {
            context.saveGState()
            context.addRect(graphRect)
            context.clip()
            context.drawLinearGradient(
                gradient,
                start: CGPoint(x: rect.midX, y: graphRect.minY),
                end: CGPoint(x: rect.midX, y: graphRect.maxY),
                options: []
            )
            context.restoreGState()
        }
        
        // ----------------------------------------------------
        // 4) วาดเส้นกริด + scale text
        // ----------------------------------------------------
        drawGridAndAxes(in: context,
                        rect: rect,
                        graphRect: graphRect,
                        minX: minX, maxX: maxX,
                        minY: expandedMinY, maxY: expandedMaxY,
                        pointToScreen: pointToScreen)
        
        // ----------------------------------------------------
        // 5) วาดพื้นดิน (polygon ใต้หน้าตัด)
        // ----------------------------------------------------
        let groundPath = UIBezierPath()
        
        let firstScreen = pointToScreen(sortedPoints[0].width, sortedPoints[0].elevation)
        groundPath.move(to: firstScreen)
        
        for p in sortedPoints.dropFirst() {
            groundPath.addLine(to: pointToScreen(p.width, p.elevation))
        }
        
        let lastPoint = sortedPoints.last!
        let lastScreenX = pointToScreen(lastPoint.width, lastPoint.elevation).x
        let firstScreenX = firstScreen.x
        let bottomY = rect.height - paddingBottom
        
        groundPath.addLine(to: CGPoint(x: lastScreenX, y: bottomY))
        groundPath.addLine(to: CGPoint(x: firstScreenX, y: bottomY))
        groundPath.close()
        
        groundFillColor.setFill()
        groundPath.fill()
        
        groundStrokeColor.setStroke()
        groundPath.lineWidth = 1.0
        groundPath.stroke()
        
        // ----------------------------------------------------
        // 6) ระบายสีน้ำตามระดับ waterLevel (ถ้ามี)
        // ----------------------------------------------------
        if let wl = waterLevel {
            drawWaterFill(waterLevel: wl,
                          sortedPoints: sortedPoints,
                          minX: minX,
                          maxX: maxX,
                          pointToScreen: pointToScreen)
            
            // เส้น water level หลัก
            let wlY = pointToScreen(minX, wl).y
            let waterLinePath = UIBezierPath()
            waterLinePath.move(to: CGPoint(x: paddingLeft, y: wlY))
            waterLinePath.addLine(to: CGPoint(x: rect.width - paddingRight, y: wlY))
            waterLineColor.setStroke()
            waterLinePath.lineWidth = 1.5
            waterLinePath.stroke()
            
            // label WL เล็ก ๆ
            let text = String(format: "WL = %.2f m", wl)
            let font = UIFont.systemFont(ofSize: 11, weight: .medium)
            let textColor = UIColor.systemBlue
            
            let attributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: textColor
            ]
            let textSize = text.size(withAttributes: attributes)
            let textOrigin = CGPoint(
                x: paddingLeft + 4,
                y: paddingTop + 4
            )
            
            let bgRect = CGRect(
                x: textOrigin.x - 4,
                y: textOrigin.y - 2,
                width: textSize.width + 8,
                height: textSize.height + 4
            )
            let bgPath = UIBezierPath(roundedRect: bgRect, cornerRadius: 4)
            UIColor.white.withAlphaComponent(0.8).setFill()
            bgPath.fill()
            
            text.draw(at: textOrigin, withAttributes: attributes)
        }
        
        // ----------------------------------------------------
        // 7) เส้นระดับ 0 (ถ้ามีในช่วง)
        // ----------------------------------------------------
        if expandedMinY <= 0 && expandedMaxY >= 0 {
            let zeroY = pointToScreen(minX, 0).y
            let axisPath = UIBezierPath()
            axisPath.move(to: CGPoint(x: paddingLeft, y: zeroY))
            axisPath.addLine(to: CGPoint(x: rect.width - paddingRight, y: zeroY))
            axisColor.setStroke()
            axisPath.lineWidth = 1
            let dash: [CGFloat] = [4, 4]
            axisPath.setLineDash(dash, count: dash.count, phase: 0)
            axisPath.stroke()
        }
        
        // ----------------------------------------------------
        // 8) วาดเส้นหน้าตัด
        // ----------------------------------------------------
        let sectionPath = UIBezierPath()
        sectionPath.lineWidth = 2.0
        UIColor.black.setStroke()
        
        if let first = sortedPoints.first {
            sectionPath.move(to: pointToScreen(first.width, first.elevation))
            for p in sortedPoints.dropFirst() {
                sectionPath.addLine(to: pointToScreen(p.width, p.elevation))
            }
        }
        sectionPath.stroke()
        
        // ----------------------------------------------------
        // 9) เส้น Design water level + label design Q/h (ถ้ามี)
        // ----------------------------------------------------
        if let dh = designWaterLevel {
            let y = pointToScreen(minX, dh).y
            let designPath = UIBezierPath()
            designPath.move(to: CGPoint(x: paddingLeft, y: y))
            designPath.addLine(to: CGPoint(x: rect.width - paddingRight, y: y))
            designLineColor.setStroke()
            designPath.lineWidth = 1.5
            let dash: [CGFloat] = [6, 3]
            designPath.setLineDash(dash, count: dash.count, phase: 0)
            designPath.stroke()
            
            // label มุมขวาบน
            var text: String
            if let dq = designDischarge {
                text = String(format: "Design: h=%.2f m, Q=%.2f m³/s", dh, dq)
            } else {
                text = String(format: "Design: h=%.2f m", dh)
            }
            let font = UIFont.systemFont(ofSize: 11, weight: .medium)
            let attributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: designLineColor
            ]
            let textSize = text.size(withAttributes: attributes)
            let margin: CGFloat = 8
            var textOrigin = CGPoint(
                x: rect.width - textSize.width - margin,
                y: paddingTop + 4 + 18 // ต่ำกว่า label WL นิดหน่อย
            )
            if waterLevel == nil {
                // ถ้าไม่มี WL ปกติ → ขยับขึ้นไปด้านบนหน่อย
                textOrigin.y = paddingTop + 4
            }
            let bgRect = CGRect(
                x: textOrigin.x - 4,
                y: textOrigin.y - 2,
                width: textSize.width + 8,
                height: textSize.height + 4
            )
            let bgPath = UIBezierPath(roundedRect: bgRect, cornerRadius: 4)
            UIColor.white.withAlphaComponent(0.9).setFill()
            bgPath.fill()
            text.draw(at: textOrigin, withAttributes: attributes)
        }
        
        // ----------------------------------------------------
        // 10) ค่า Manning n overlay มุมขวาบน
        // ----------------------------------------------------
        if let n = manningN {
            let text = String(format: "n = %.4f", n)
            let font = UIFont.systemFont(ofSize: 12, weight: .medium)
            let textColor = UIColor.black.withAlphaComponent(0.8)
            
            let attributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: textColor
            ]
            
            let textSize = text.size(withAttributes: attributes)
            let margin: CGFloat = 8
            let textOrigin = CGPoint(
                x: rect.width - textSize.width - margin - 6,
                y: rect.minY + 4
            )
            
            let bgRect = CGRect(
                x: textOrigin.x - 6,
                y: textOrigin.y - 3,
                width: textSize.width + 12,
                height: textSize.height + 6
            )
            let bgPath = UIBezierPath(roundedRect: bgRect, cornerRadius: 6)
            UIColor.white.withAlphaComponent(0.8).setFill()
            bgPath.fill()
            
            text.draw(at: textOrigin, withAttributes: attributes)
        }
    }
    
    // MARK: - วาดกริด + สเกล
    
    private func drawGridAndAxes(
        in context: CGContext,
        rect: CGRect,
        graphRect: CGRect,
        minX: Double, maxX: Double,
        minY: Double, maxY: Double,
        pointToScreen: (Double, Double) -> CGPoint
    ) {
        let font = UIFont.systemFont(ofSize: 10)
        
        // Horizontal grid (z)
        let horizontalLines = 4
        let yStep = (maxY - minY) / Double(horizontalLines)
        
        for i in 0...horizontalLines {
            let z = minY + Double(i) * yStep
            let p = pointToScreen(minX, z)
            let y = p.y
            
            let path = UIBezierPath()
            path.move(to: CGPoint(x: graphRect.minX, y: y))
            path.addLine(to: CGPoint(x: graphRect.maxX, y: y))
            gridColor.setStroke()
            path.lineWidth = 0.5
            let dash: [CGFloat] = [2, 3]
            path.setLineDash(dash, count: dash.count, phase: 0)
            path.stroke()
            
            let text = String(format: "%.1f", z)
            let attrs: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: UIColor.darkGray
            ]
            let textSize = text.size(withAttributes: attrs)
            let textPoint = CGPoint(
                x: graphRect.minX - textSize.width - 4,
                y: y - textSize.height / 2
            )
            text.draw(at: textPoint, withAttributes: attrs)
        }
        
        // Vertical grid (x)
        let verticalLines = 4
        let xStep = (maxX - minX) / Double(verticalLines)
        
        for i in 0...verticalLines {
            let xVal = minX + Double(i) * xStep
            let p = pointToScreen(xVal, minY)
            let x = p.x
            
            let path = UIBezierPath()
            path.move(to: CGPoint(x: x, y: graphRect.minY))
            path.addLine(to: CGPoint(x: x, y: graphRect.maxY))
            gridColor.setStroke()
            path.lineWidth = 0.5
            let dash: [CGFloat] = [2, 3]
            path.setLineDash(dash, count: dash.count, phase: 0)
            path.stroke()
            
            let text = String(format: "%.0f", xVal)
            let attrs: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: UIColor.darkGray
            ]
            let textSize = text.size(withAttributes: attrs)
            let textPoint = CGPoint(
                x: x - textSize.width / 2,
                y: graphRect.maxY + 4
            )
            text.draw(at: textPoint, withAttributes: attrs)
        }
        
        // กรอบ
        let borderPath = UIBezierPath(rect: graphRect)
        axisColor.setStroke()
        borderPath.lineWidth = 1
        borderPath.stroke()
    }
    
    // MARK: - วาดสีน้ำตามรูปหน้าตัด
    
    private func drawWaterFill(
        waterLevel wl: Double,
        sortedPoints: [CrossSectionPoint],
        minX: Double,
        maxX: Double,
        pointToScreen: (Double, Double) -> CGPoint
    ) {
        // หา "ขอบล่าง" ของน้ำ (bottom boundary) ตามรูปหน้าตัด
        var wettedPoints: [CGPoint] = []
        var hasWater = false
        
        for i in 0..<(sortedPoints.count - 1) {
            let p1 = sortedPoints[i]
            let p2 = sortedPoints[i + 1]
            
            let z1 = p1.elevation
            let z2 = p2.elevation
            
            // ความลึกที่แต่ละจุด (ถ้าเหนือน้ำ = 0)
            let d1 = wl - z1
            let d2 = wl - z2
            
            let below1 = d1 > 0 // จุดต่ำกว่าหรือเท่าระดับน้ำ
            let below2 = d2 > 0
            
            if below1 {
                // จุดแรกอยู่ในน้ำ → ใช้ elevation จริง
                wettedPoints.append(pointToScreen(p1.width, p1.elevation))
                hasWater = true
            }
            
            // ตรวจว่ามีน้ำตัดผ่าน segment นี้ไหม (จุดหนึ่งอยู่ใต้, อีกจุดอยู่เหนือ)
            if below1 != below2 {
                // หาจุดตัดระหว่างเส้น segment กับระดับน้ำ
                let x1 = p1.width
                let x2 = p2.width
                let z1 = p1.elevation
                let z2 = p2.elevation
                
                let dz = z2 - z1
                if dz != 0 {
                    let t = (wl - z1) / dz
                    let tClamped = max(0.0, min(1.0, t))
                    let xInt = x1 + (x2 - x1) * tClamped
                    let zInt = wl
                    wettedPoints.append(pointToScreen(xInt, zInt))
                    hasWater = true
                }
            }
            
            // ถ้าจุดสุดท้ายของ segment อยู่ในน้ำ แต่เรายังไม่ append (กรณีทั้งคู่ต่ำกว่าระดับน้ำ จะถูก append ตอน loop รอบถัดไปอยู่แล้ว)
            if i == sortedPoints.count - 2 && below2 {
                wettedPoints.append(pointToScreen(p2.width, p2.elevation))
                hasWater = true
            }
        }
        
        guard hasWater, wettedPoints.count >= 2 else { return }
        
        // หา x ซ้ายสุด / ขวาสุดของบริเวณที่มีน้ำ
        let xs = wettedPoints.map { Double($0.x) }
        guard let minScreenX = xs.min(), let maxScreenX = xs.max() else { return }
        
        // สร้าง polygon: เริ่มจากเส้นระดับน้ำด้านซ้าย → ไล่ตาม wettedPoints → กลับขึ้นเส้นน้ำด้านขวา
        let waterPath = UIBezierPath()
        
        waterPath.move(to: CGPoint(x: CGFloat(minScreenX), y: pointToScreen(minX, wl).y))
        for pt in wettedPoints {
            waterPath.addLine(to: pt)
        }
        waterPath.addLine(to: CGPoint(x: CGFloat(maxScreenX), y: pointToScreen(maxX, wl).y))
        waterPath.close()
        
        waterFillColor.setFill()
        waterPath.fill()
    }
    
    // MARK: - Public API
    
    /// อัปเดตจุด + manning n + water level + design h,Q
    func refresh(points newPoints: [CrossSectionPoint],
                 manningN: Double?,
                 waterLevel: Double? = nil,
                 designWaterLevel: Double? = nil,
                 designDischarge: Double? = nil) {
        self.points = newPoints
        self.manningN = manningN
        self.waterLevel = waterLevel
        self.designWaterLevel = designWaterLevel
        self.designDischarge = designDischarge
    }
    
    /// เวอร์ชันสั้น (คงค่า water/design เดิม)
    func refresh(points newPoints: [CrossSectionPoint]) {
        self.points = newPoints
    }
}
