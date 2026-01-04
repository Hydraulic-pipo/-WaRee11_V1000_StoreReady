//
//  RatingCurveChartView.swift
//  WaRee11_V0501
//
//  Created by Chalermchon Lertlum on 28/11/2568 BE.
//

import UIKit

/// วาดกราฟ Rating Curve: Q–h
/// - แกนแนวนอน: h (ระดับน้ำ, m)
/// - แกนแนวตั้ง: Q (m3/s)
class RatingCurveChartView: UIView {
    
    /// ข้อมูล h–Q
    private var points: [RatingCurvePoint] = [] {
        didSet { setNeedsDisplay() }
    }
    
    /// index ของจุดที่ถูกเลือก (จากตาราง)
    private var selectedIndex: Int? {
        didSet { setNeedsDisplay() }
    }
    
    // สี
    private let axisColor = UIColor.gray.withAlphaComponent(0.6)
    private let gridColor = UIColor.gray.withAlphaComponent(0.25)
    private let curveColor = UIColor.systemBlue
    private let selectedPointColor = UIColor.systemRed
    private let backgroundTop = UIColor.systemTeal.withAlphaComponent(0.15)
    private let backgroundBottom = UIColor.white
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        guard points.count > 1 else { return }
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        // เตรียม min / max
        let hs = points.map { $0.waterLevel }
        let qs = points.map { $0.discharge }
        
        guard let minH = hs.min(), let maxH = hs.max(),
              let minQ = qs.min(), let maxQ = qs.max(),
              maxH > minH else { return }
        
        let paddingLeft: CGFloat = 48
        let paddingRight: CGFloat = 16
        let paddingTop: CGFloat = 16
        let paddingBottom: CGFloat = 32
        
        let graphRect = CGRect(
            x: paddingLeft,
            y: paddingTop,
            width: rect.width - paddingLeft - paddingRight,
            height: rect.height - paddingTop - paddingBottom
        )
        
        // background gradient
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let colors: [CGColor] = [backgroundTop.cgColor, backgroundBottom.cgColor]
        let locations: [CGFloat] = [0.0, 1.0]
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
        
        // ขยายช่วง Q เล็กน้อยให้กราฟไม่ชนขอบ
        let qRange = maxQ - minQ
        let minQExp = minQ - 0.05 * qRange
        let maxQExp = maxQ + 0.10 * qRange
        
        let hRange = maxH - minH
        
        let xScale = graphRect.width / CGFloat(hRange)
        let yScale = graphRect.height / CGFloat(maxQExp - minQExp)
        
        func toScreen(_ h: Double, _ q: Double) -> CGPoint {
            let x = graphRect.minX + CGFloat(h - minH) * xScale
            let y = graphRect.maxY - CGFloat(q - minQExp) * yScale
            return CGPoint(x: x, y: y)
        }
        
        // Draw grid + axes + labels
        drawGridAndAxes(in: context,
                        rect: rect,
                        graphRect: graphRect,
                        minH: minH, maxH: maxH,
                        minQ: minQExp, maxQ: maxQExp,
                        toScreen: toScreen)
        
        // วาดเส้นโค้ง Q–h
        let path = UIBezierPath()
        if let first = points.first {
            path.move(to: toScreen(first.waterLevel, first.discharge))
            for p in points.dropFirst() {
                path.addLine(to: toScreen(p.waterLevel, p.discharge))
            }
        }
        curveColor.setStroke()
        path.lineWidth = 2.0
        path.stroke()
        
        // วาดจุดที่ถูกเลือก (selected point) ถ้ามี
        if let idx = selectedIndex, idx >= 0, idx < points.count {
            let p = points[idx]
            let screenPt = toScreen(p.waterLevel, p.discharge)
            
            // วาดวงกลม
            let radius: CGFloat = 5
            let circle = UIBezierPath(ovalIn: CGRect(
                x: screenPt.x - radius,
                y: screenPt.y - radius,
                width: radius * 2,
                height: radius * 2
            ))
            UIColor.white.setFill()
            circle.fill()
            selectedPointColor.setStroke()
            circle.lineWidth = 2
            circle.stroke()
            
            // วาด label เล็ก ๆ ข้างจุด
            let text = String(format: "h=%.2f, Q=%.2f", p.waterLevel, p.discharge)
            let font = UIFont.systemFont(ofSize: 10, weight: .medium)
            let attrs: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: selectedPointColor
            ]
            let size = text.size(withAttributes: attrs)
            let offset: CGFloat = 6
            var textOrigin = CGPoint(x: screenPt.x + offset,
                                     y: screenPt.y - size.height - offset)
            
            // กันไม่ให้ข้อความหลุดจอ
            if textOrigin.x + size.width > rect.maxX {
                textOrigin.x = screenPt.x - size.width - offset
            }
            if textOrigin.y < rect.minY {
                textOrigin.y = screenPt.y + offset
            }
            
            let bgRect = CGRect(
                x: textOrigin.x - 3,
                y: textOrigin.y - 2,
                width: size.width + 6,
                height: size.height + 4
            )
            let bgPath = UIBezierPath(roundedRect: bgRect, cornerRadius: 4)
            UIColor.white.withAlphaComponent(0.9).setFill()
            bgPath.fill()
            
            text.draw(at: textOrigin, withAttributes: attrs)
        }
    }
    
    private func drawGridAndAxes(
        in context: CGContext,
        rect: CGRect,
        graphRect: CGRect,
        minH: Double, maxH: Double,
        minQ: Double, maxQ: Double,
        toScreen: (Double, Double) -> CGPoint
    ) {
        let font = UIFont.systemFont(ofSize: 10)
        
        // Horizontal grid for Q
        let horizontalLines = 4
        let qStep = (maxQ - minQ) / Double(horizontalLines)
        
        for i in 0...horizontalLines {
            let q = minQ + Double(i) * qStep
            let p = toScreen(minH, q)
            let y = p.y
            
            let line = UIBezierPath()
            line.move(to: CGPoint(x: graphRect.minX, y: y))
            line.addLine(to: CGPoint(x: graphRect.maxX, y: y))
            gridColor.setStroke()
            line.lineWidth = 0.5
            let dash: [CGFloat] = [2, 3]
            line.setLineDash(dash, count: dash.count, phase: 0)
            line.stroke()
            
            let text = String(format: "%.2f", q)
            let attrs: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: UIColor.darkGray
            ]
            let size = text.size(withAttributes: attrs)
            let pt = CGPoint(x: graphRect.minX - size.width - 4,
                             y: y - size.height / 2)
            text.draw(at: pt, withAttributes: attrs)
        }
        
        // Vertical grid for h
        let verticalLines = 4
        let hStep = (maxH - minH) / Double(verticalLines)
        
        for i in 0...verticalLines {
            let h = minH + Double(i) * hStep
            let p = toScreen(h, minQ)
            let x = p.x
            
            let line = UIBezierPath()
            line.move(to: CGPoint(x: x, y: graphRect.minY))
            line.addLine(to: CGPoint(x: x, y: graphRect.maxY))
            gridColor.setStroke()
            line.lineWidth = 0.5
            let dash: [CGFloat] = [2, 3]
            line.setLineDash(dash, count: dash.count, phase: 0)
            line.stroke()
            
            let text = String(format: "%.2f", h)
            let attrs: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: UIColor.darkGray
            ]
            let size = text.size(withAttributes: attrs)
            let pt = CGPoint(x: x - size.width / 2,
                             y: graphRect.maxY + 4)
            text.draw(at: pt, withAttributes: attrs)
        }
        
        // Axis box
        let border = UIBezierPath(rect: graphRect)
        axisColor.setStroke()
        border.lineWidth = 1
        border.stroke()
        
        // Axis labels
        let axisFont = UIFont.systemFont(ofSize: 11, weight: .medium)
        
        let qLabel = "Q (m³/s)"
        let qAttrs: [NSAttributedString.Key: Any] = [
            .font: axisFont,
            .foregroundColor: UIColor.black
        ]
        let qSize = qLabel.size(withAttributes: qAttrs)
        let qPoint = CGPoint(
            x: graphRect.minX - qSize.width / 2 - 8,
            y: graphRect.minY - qSize.height - 2
        )
        qLabel.draw(at: qPoint, withAttributes: qAttrs)
        
        let hLabel = "h (m)"
        let hSize = hLabel.size(withAttributes: qAttrs)
        let hPoint = CGPoint(
            x: graphRect.midX - hSize.width / 2,
            y: graphRect.maxY + 18
        )
        hLabel.draw(at: hPoint, withAttributes: qAttrs)
    }
    
    // MARK: - Public API
    
    /// อัปเดตข้อมูลกราฟ + จุดที่เลือก
    func update(points newPoints: [RatingCurvePoint], selectedIndex: Int? = nil) {
        self.points = newPoints
        self.selectedIndex = selectedIndex
    }
    
    /// เวอร์ชันเดิม (เผื่อมีโค้ดที่เรียกอยู่แล้ว)
    func update(points newPoints: [RatingCurvePoint]) {
        self.points = newPoints
    }
}
