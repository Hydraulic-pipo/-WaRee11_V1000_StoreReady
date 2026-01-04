//
//  RatingCurveViewController.swift
//  WaRee11_V0501
//
//  Created by Chalermchon Lertlum on 28/11/2568 BE.
//

import UIKit

/// 1 จุดของ Rating Curve: (ระดับน้ำ, Q)
struct RatingCurvePoint {
    let waterLevel: Double  // ระดับน้ำ (m, elevation)
    let discharge: Double   // Q (m3/s)
}

/// หน้าสำหรับแสดง Rating Curve ของ Cross Section หนึ่ง ๆ
/// - แสดง:
///   - Header: Project / Node / Manning n / Bed slope / Design point (ถ้ามี)
///   - ช่องกรอก Bed slope S0
///   - กราฟ Q–h (RatingCurveChartView) + จุดที่เลือก
///   - ตาราง h–Q
///   - Label แสดงจุดที่เลือก
///   - ปุ่ม Save design point (บันทึก design h,Q ลง CrossSectionData)
class RatingCurveViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    // MARK: - Outlets (เชื่อมจาก Storyboard)
    
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var slopeTextField: UITextField!
    @IBOutlet weak var chartView: RatingCurveChartView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var selectedInfoLabel: UILabel!
    
    // MARK: - Context (รับมาจาก CrossSectionEditor)
    
    var project: Project!
    var node: RiverNode!
    
    // MARK: - Data
    
    private var crossSectionData = CrossSectionData()
    private var ratingPoints: [RatingCurvePoint] = []
    
    /// จำนวนจุดใน Rating Curve
    private let numberOfPoints = 15
    
    /// Slope ของท้องน้ำ (S0) เริ่มต้น (แก้ได้จาก UI)
    private var bedSlope: Double = 0.001  // 1:1000
    
    /// index ของจุดที่เลือก (ใน ratingPoints)
    private var selectedIndex: Int? = nil
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Rating Curve"
        view.backgroundColor = .systemBackground
        
        setupTableView()
        setupSlopeField()
        setupSelectedInfoLabel()
        loadCrossSection()
        updateHeader()
        generateRatingCurve()
    }
    
    // MARK: - Setup
    
    private func setupTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "RatingCell")
    }
    
    private func setupSlopeField() {
        slopeTextField.keyboardType = .decimalPad
        slopeTextField.placeholder = "Bed slope S0 (e.g. 0.001)"
        slopeTextField.text = String(format: "%.4f", bedSlope)
        
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let done = UIBarButtonItem(barButtonSystemItem: .done,
                                   target: self,
                                   action: #selector(slopeEditingDidEnd))
        toolbar.setItems([done], animated: false)
        slopeTextField.inputAccessoryView = toolbar
    }
    
    private func setupSelectedInfoLabel() {
        selectedInfoLabel.textAlignment = .center
        selectedInfoLabel.numberOfLines = 0
        selectedInfoLabel.text = "Selected: (none)"
        selectedInfoLabel.textColor = .darkGray
        selectedInfoLabel.font = UIFont.systemFont(ofSize: 13)
    }
    
    private func loadCrossSection() {
        guard let project = project, let node = node else { return }
        crossSectionData = CrossSectionStorageManager.shared
            .loadCrossSection(for: project, node: node)
    }
    
    private func saveCrossSection() {
        guard let project = project, let node = node else { return }
        CrossSectionStorageManager.shared.saveCrossSection(crossSectionData,
                                                           for: project,
                                                           node: node)
    }
    
    private func updateHeader() {
        let projectName = project?.name ?? "Unknown Project"
        let nodeName = node?.name ?? "Unknown Node"
        
        let nText: String
        if let n = crossSectionData.manningN {
            nText = String(format: "%.4f", n)
        } else {
            nText = "(not set)"
        }
        
        let sText = String(format: "%.4f", bedSlope)
        
        var designText = "Design: (none)"
        if let dh = crossSectionData.designWaterLevel,
           let dQ = crossSectionData.designDischarge {
            let hStr = String(format: "%.3f", dh)
            let qStr = String(format: "%.3f", dQ)
            designText = "Design: h = \(hStr) m, Q = \(qStr) m³/s"
        }
        
        headerLabel.text = """
        Project: \(projectName)
        Node: \(nodeName)
        Manning n = \(nText),  S0 = \(sText)
        \(designText)
        """
        headerLabel.numberOfLines = 0
        headerLabel.textAlignment = .center
    }
    
    // MARK: - Actions: Slope edit
    
    @objc private func slopeEditingDidEnd() {
        slopeTextField.resignFirstResponder()
        
        let text = slopeTextField.text ?? ""
        if let value = Double(text), value > 0 {
            bedSlope = value
        } else {
            // ถ้ากรอกผิด → กลับไปใช้ค่าเดิม
            slopeTextField.text = String(format: "%.4f", bedSlope)
        }
        updateHeader()
        generateRatingCurve()
    }
    
    // MARK: - สร้าง Rating Curve ด้วยสมการ Manning
    
    /// สร้างชุด (h, Q) ใช้ Manning:
    ///   Q = (1/n) * A * R^(2/3) * S0^(1/2)
    private func generateRatingCurve() {
        ratingPoints.removeAll()
        
        let zs = crossSectionData.points.map { $0.elevation }
        guard let minZ = zs.min(), let maxZ = zs.max(), maxZ > minZ else {
            chartView.update(points: [])
            selectedIndex = nil
            updateSelectedInfoLabel()
            tableView.reloadData()
            return
        }
        
        // Manning n
        guard let n = crossSectionData.manningN, n > 0 else {
            chartView.update(points: [])
            selectedIndex = nil
            updateSelectedInfoLabel()
            tableView.reloadData()
            return
        }
        
        // ช่วงระดับน้ำ: จากใกล้ก้นลำน้ำ → ถึง bankfull
        let hMin = minZ + 0.05 * (maxZ - minZ)
        let hMax = maxZ
        
        for i in 0..<numberOfPoints {
            let t = Double(i) / Double(max(numberOfPoints - 1, 1))
            let wl = hMin + t * (hMax - hMin)
            
            let (A, P) = computeAreaAndWettedPerimeter(for: wl)
            if A <= 0 || P <= 0 {
                let point = RatingCurvePoint(waterLevel: wl, discharge: 0.0)
                ratingPoints.append(point)
                continue
            }
            
            let R = A / P
            let Q = (1.0 / n) * A * pow(R, 2.0 / 3.0) * sqrt(bedSlope)
            
            let point = RatingCurvePoint(waterLevel: wl, discharge: Q)
            ratingPoints.append(point)
        }
        
        // default: เลือกจุดบนสุด (ประมาณ bankfull) ถ้ามีข้อมูล
        if ratingPoints.isEmpty {
            selectedIndex = nil
        } else {
            selectedIndex = ratingPoints.count - 1
        }
        
        chartView.update(points: ratingPoints, selectedIndex: selectedIndex)
        updateSelectedInfoLabel()
        tableView.reloadData()
        
        // เลือก row ใน table ให้ตรงกับ selectedIndex
        if let idx = selectedIndex, idx >= 0, idx < ratingPoints.count {
            let indexPath = IndexPath(row: idx, section: 0)
            tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
        }
    }
    
    /// คำนวณ A (พื้นที่เปียก) และ P (wetted perimeter) ที่ระดับน้ำ waterLevel
    private func computeAreaAndWettedPerimeter(for waterLevel: Double) -> (Double, Double) {
        let sorted = crossSectionData.points.sorted { $0.width < $1.width }
        guard sorted.count > 1 else { return (0.0, 0.0) }
        
        var area = 0.0
        var wettedPerimeter = 0.0
        
        for i in 0..<(sorted.count - 1) {
            let p1 = sorted[i]
            let p2 = sorted[i + 1]
            
            let x1 = p1.width
            let x2 = p2.width
            let z1 = p1.elevation
            let z2 = p2.elevation
            
            let dx = x2 - x1
            if dx <= 0 { continue }
            
            // ความลึกน้ำที่แต่ละจุด (ถ้าเหนือน้ำ = 0)
            let d1 = max(0.0, waterLevel - z1)
            let d2 = max(0.0, waterLevel - z2)
            
            // ----- พื้นที่เปียก (A) -----
            if d1 > 0 || d2 > 0 {
                let avgDepth = (d1 + d2) * 0.5
                let segArea = avgDepth * dx
                area += segArea
            }
            
            // ----- Wetted Perimeter (P) -----
            let zMin = min(z1, z2)
            let zMax = max(z1, z2)
            
            if waterLevel <= zMin {
                // น้ำต่ำกว่าทั้งสองจุด → ไม่เปียก
                continue
            } else if waterLevel >= zMax {
                // น้ำสูงกว่าทั้ง segment → เปียกเต็ม segment
                let dz = z2 - z1
                let segLength = hypot(dx, dz)
                wettedPerimeter += segLength
            } else {
                // น้ำตัดผ่าน segment → เปียกบางส่วน
                let dz = z2 - z1
                if dz == 0 {
                    // segment แนวนอน และอยู่ใต้น้ำบางส่วน → เปียกเต็ม
                    let segLength = hypot(dx, dz)
                    wettedPerimeter += segLength
                } else {
                    let t = (waterLevel - z1) / dz
                    let tClamped = max(0.0, min(1.0, t))
                    
                    let xInt = x1 + (x2 - x1) * tClamped
                    let zInt = waterLevel
                    
                    if z1 < waterLevel {
                        // เปียกจาก p1 → intersection
                        let dxW = xInt - x1
                        let dzW = zInt - z1
                        let segLength = hypot(dxW, dzW)
                        wettedPerimeter += segLength
                    } else {
                        // เปียกจาก intersection → p2
                        let dxW = x2 - xInt
                        let dzW = z2 - zInt
                        let segLength = hypot(dxW, dzW)
                        wettedPerimeter += segLength
                    }
                }
            }
        }
        
        return (area, wettedPerimeter)
    }
    
    // MARK: - Selected Info
    
    private func updateSelectedInfoLabel() {
        guard let idx = selectedIndex,
              idx >= 0,
              idx < ratingPoints.count else {
            selectedInfoLabel.text = "Selected: (none)"
            return
        }
        
        let p = ratingPoints[idx]
        let hText = String(format: "%.3f", p.waterLevel)
        let qText = String(format: "%.3f", p.discharge)
        
        selectedInfoLabel.text = "Selected: h = \(hText) m,   Q = \(qText) m³/s"
    }
    
    // MARK: - Save design point
    
    /// ปุ่ม "Save design point" → บันทึก h,Q ที่เลือกลง CrossSectionData
    @IBAction func saveDesignTapped(_ sender: UIButton) {
        guard let idx = selectedIndex,
              idx >= 0,
              idx < ratingPoints.count else {
            // ยังไม่ได้เลือกจุด
            return
        }
        
        let p = ratingPoints[idx]
        
        crossSectionData.designWaterLevel = p.waterLevel
        crossSectionData.designDischarge = p.discharge
        saveCrossSection()
        updateHeader()
        
        // อัปเดต label แจ้งว่าเซฟแล้ว
        let hText = String(format: "%.3f", p.waterLevel)
        let qText = String(format: "%.3f", p.discharge)
        selectedInfoLabel.text = "Selected: h = \(hText) m, Q = \(qText) m³/s (saved)"
    }
    
    // MARK: - UITableViewDataSource / Delegate
    
    func tableView(_ tableView: UITableView,
                   numberOfRowsInSection section: Int) -> Int {
        return ratingPoints.count
    }
    
    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "RatingCell",
                                                 for: indexPath)
        
        let p = ratingPoints[indexPath.row]
        let hText = String(format: "%.3f", p.waterLevel)
        let qText = String(format: "%.3f", p.discharge)
        
        cell.textLabel?.text = "h = \(hText) m   →   Q = \(qText) m³/s"
        cell.textLabel?.numberOfLines = 1
        
        return cell
    }
    
    /// แตะเลือก row → เปลี่ยนจุดที่เลือก + อัปเดตกราฟ
    func tableView(_ tableView: UITableView,
                   didSelectRowAt indexPath: IndexPath) {
        selectedIndex = indexPath.row
        updateSelectedInfoLabel()
        chartView.update(points: ratingPoints, selectedIndex: selectedIndex)
    }
}
