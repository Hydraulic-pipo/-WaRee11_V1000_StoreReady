//
//  SolverResultChartView.swift
//  WaRee11_V0501
//
//  Created by Chalermchon Lertlum on 9/12/2568 BE.
//

import UIKit

/// วาดกราฟผลลัพธ์ Simulation:
/// - แกน X = เวลา (time)
/// - เส้นสีน้ำเงิน = Water level h(t)
/// - เส้นสีส้ม = Discharge Q_out(t)
/// - เส้นส้มบาง = Q_in (ค่าคงที่) แนวนอน
class SolverResultChartView: UIView {
    
    /// ผลลัพธ์ที่จะใช้วาด
    var result: SolverResult? {
        didSet { setNeedsDisplay() }
    }
    
    /// Q_in จาก SimulationSettings (ค่าคงที่)
    var qIn: Double? {
        didSet { setNeedsDisplay() }
    }
    
    private let axisColor = UIColor.gray.withAlphaComponent(0.6)
    private let gridColor = UIColor.gray.withAlphaComponent(0.25)
    private let hColor = UIColor.systemBlue
    private let qColor = UIColor.systemOrange
    private let qInColor = UIColor.systemOrange.withAlphaComponent(0.5)
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        guard let result = result,
              result.points.count > 1,
              let context = UIGraphicsGetCurrentContext() else {
            drawNoData(in: rect)
            return
        }
        
        let points = result.points
        
        let times = points.map { $0.time }
        let hs = points.map { $0.waterLevel }
        let qs = points.map { $0.discharge }
        
        guard let tMin = times.min(),
              let tMax = times.max(),
              tMax > tMin else {
            drawNoData(in: rect)
            return
        }
        
        guard let hMin = hs.min(), let hMax = hs.max() else {
            drawNoData(in: rect)
            return
        }
        guard var qMin = qs.min(), var qMax = qs.max() else {
            drawNoData(in: rect)
            return
        }
        
        // รวม Q_in เข้าไปในช่วง qMin/qMax ด้วย เพื่อให้เส้น Q_in อยู่ในกราฟ
        if let qIn = qIn {
            qMin = min(qMin, qIn)
            qMax = max(qMax, qIn)
        }
        
        let paddingLeft: CGFloat = 40
        let paddingRight: CGFloat = 40
        let paddingTop: CGFloat = 20
        let paddingBottom: CGFloat = 30
        
        let graphRect = CGRect(
            x: paddingLeft,
            y: paddingTop,
            width: rect.width - paddingLeft - paddingRight,
            height: rect.height - paddingTop - paddingBottom
        )
        
        context.setFillColor(UIColor.systemBackground.cgColor)
        context.fill(rect)
        
        drawGrid(in: context,
                 rect: rect,
                 graphRect: graphRect,
                 tMin: tMin,
                 tMax: tMax,
                 hMin: hMin,
                 hMax: hMax)
        
        let tRange = tMax - tMin
        let hRange = (hMax - hMin == 0) ? 1.0 : (hMax - hMin)
        let qRange = (qMax - qMin == 0) ? 1.0 : (qMax - qMin)
        
        func pointH(_ time: Double, _ h: Double) -> CGPoint {
            let x = graphRect.minX + CGFloat((time - tMin) / tRange) * graphRect.width
            let y = graphRect.maxY - CGFloat((h - hMin) / hRange) * graphRect.height
            return CGPoint(x: x, y: y)
        }
        
        func pointQ(_ time: Double, _ q: Double) -> CGPoint {
            let x = graphRect.minX + CGFloat((time - tMin) / tRange) * graphRect.width
            let y = graphRect.maxY - CGFloat((q - qMin) / qRange) * graphRect.height
            return CGPoint(x: x, y: y)
        }
        
        // h(t)
        let hPath = UIBezierPath()
        if let first = points.first {
            hPath.move(to: pointH(first.time, first.waterLevel))
            for p in points.dropFirst() {
                hPath.addLine(to: pointH(p.time, p.waterLevel))
            }
        }
        hColor.setStroke()
        hPath.lineWidth = 2.0
        hPath.stroke()
        
        // Q_out(t)
        let qPath = UIBezierPath()
        if let first = points.first {
            qPath.move(to: pointQ(first.time, first.discharge))
            for p in points.dropFirst() {
                qPath.addLine(to: pointQ(p.time, p.discharge))
            }
        }
        qColor.setStroke()
        qPath.lineWidth = 1.5
        let dash: [CGFloat] = [4, 3]
        qPath.setLineDash(dash, count: dash.count, phase: 0)
        qPath.stroke()
        
        // เส้น Q_in แนวนอน
        if let qIn = qIn {
            let y = graphRect.maxY - CGFloat((qIn - qMin) / qRange) * graphRect.height
            let path = UIBezierPath()
            path.move(to: CGPoint(x: graphRect.minX, y: y))
            path.addLine(to: CGPoint(x: graphRect.maxX, y: y))
            qInColor.setStroke()
            path.lineWidth = 1.0
            let dashIn: [CGFloat] = [2, 2]
            path.setLineDash(dashIn, count: dashIn.count, phase: 0)
            path.stroke()
        }
        
        drawAxes(in: context, graphRect: graphRect)
        drawLegend(in: context, rect: rect)
    }
    
    private func drawNoData(in rect: CGRect) {
        let message = "No result data"
        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 14, weight: .medium),
            .foregroundColor: UIColor.gray
        ]
        let size = message.size(withAttributes: attrs)
        let point = CGPoint(
            x: rect.midX - size.width/2,
            y: rect.midY - size.height/2
        )
        message.draw(at: point, withAttributes: attrs)
    }
    
    private func drawGrid(
        in context: CGContext,
        rect: CGRect,
        graphRect: CGRect,
        tMin: Double,
        tMax: Double,
        hMin: Double,
        hMax: Double
    ) {
        let font = UIFont.systemFont(ofSize: 10)
        
        let borderPath = UIBezierPath(rect: graphRect)
        axisColor.setStroke()
        borderPath.lineWidth = 1.0
        borderPath.stroke()
        
        let verticalLines = 4
        let tStep = (tMax - tMin) / Double(verticalLines)
        for i in 0...verticalLines {
            let tVal = tMin + Double(i) * tStep
            let x = graphRect.minX + CGFloat(Double(i) / Double(verticalLines)) * graphRect.width
            
            let path = UIBezierPath()
            path.move(to: CGPoint(x: x, y: graphRect.minY))
            path.addLine(to: CGPoint(x: x, y: graphRect.maxY))
            gridColor.setStroke()
            path.lineWidth = 0.5
            let dash: [CGFloat] = [2, 3]
            path.setLineDash(dash, count: dash.count, phase: 0)
            path.stroke()
            
            let text = String(format: "%.0f", tVal)
            let attrs: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: UIColor.darkGray
            ]
            let size = text.size(withAttributes: attrs)
            let p = CGPoint(x: x - size.width/2,
                            y: graphRect.maxY + 4)
            text.draw(at: p, withAttributes: attrs)
        }
        
        let horizontalLines = 4
        let hStep = (hMax - hMin) / Double(horizontalLines)
        for i in 0...horizontalLines {
            let hVal = hMin + Double(i) * hStep
            let y = graphRect.maxY - CGFloat(Double(i) / Double(horizontalLines)) * graphRect.height
            
            let path = UIBezierPath()
            path.move(to: CGPoint(x: graphRect.minX, y: y))
            path.addLine(to: CGPoint(x: graphRect.maxX, y: y))
            gridColor.setStroke()
            path.lineWidth = 0.5
            let dash: [CGFloat] = [2, 3]
            path.setLineDash(dash, count: dash.count, phase: 0)
            path.stroke()
            
            let text = String(format: "%.2f", hVal)
            let attrs: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: UIColor.darkGray
            ]
            let size = text.size(withAttributes: attrs)
            let p = CGPoint(x: graphRect.minX - size.width - 4,
                            y: y - size.height/2)
            text.draw(at: p, withAttributes: attrs)
        }
    }
    
    private func drawAxes(in context: CGContext, graphRect: CGRect) {
        let font = UIFont.systemFont(ofSize: 11)
        
        let xLabel = "Time (s)"
        let xAttrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.darkGray
        ]
        let xSize = xLabel.size(withAttributes: xAttrs)
        let xPoint = CGPoint(
            x: graphRect.midX - xSize.width/2,
            y: graphRect.maxY + 16
        )
        xLabel.draw(at: xPoint, withAttributes: xAttrs)
        
        let yLabel = "h (m), Q_out/Q_in (scaled)"
        let yAttrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.darkGray
        ]
        let ySize = yLabel.size(withAttributes: yAttrs)
        let yPoint = CGPoint(
            x: graphRect.minX - ySize.width/2 - 10,
            y: graphRect.minY - 4
        )
        yLabel.draw(at: yPoint, withAttributes: yAttrs)
    }
    
    private func drawLegend(in context: CGContext, rect: CGRect) {
        let font = UIFont.systemFont(ofSize: 11)
        
        let hText = "Water level h(t)"
        let qText = "Discharge Q_out(t)"
        let qInText = "Q_in (constant)"
        
        let margin: CGFloat = 8
        var y = rect.minY + margin
        
        func drawItem(color: UIColor, text: String) {
            let boxSize: CGFloat = 10
            let boxRect = CGRect(x: rect.minX + margin,
                                 y: y,
                                 width: boxSize,
                                 height: boxSize)
            color.setFill()
            context.fill(boxRect)
            
            let attrs: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: UIColor.label
            ]
            let size = text.size(withAttributes: attrs)
            let textPoint = CGPoint(
                x: boxRect.maxX + 6,
                y: y + boxSize/2 - size.height/2
            )
            text.draw(at: textPoint, withAttributes: attrs)
            
            y += max(boxSize, size.height) + 4
        }
        
        drawItem(color: hColor, text: hText)
        drawItem(color: qColor, text: qText)
        drawItem(color: qInColor, text: qInText)
    }
}
