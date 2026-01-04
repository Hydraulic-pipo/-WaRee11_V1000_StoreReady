//
//  CrossSectionEditorViewController.swift
//  WaRee11_V0501
//
//  Created by Chalermchon Lertlum on 21/11/2568 BE.
//

import UIKit

/// หน้าสำหรับจัดการหน้าตัด (cross section) ของ node หนึ่งใน project หนึ่ง
/// - แสดง:
///   - ชื่อ Project + Node + Manning n + Design h,Q (ใน header)
///   - กราฟหน้าตัด (CrossSectionChartView)
///   - ช่องกรอก Manning n
///   - ช่องกรอก Water level (ระดับน้ำทั่วไป)
///   - ปุ่ม Normal depth / Bankfull
///   - ปุ่ม Template (สร้างหน้าตัดอัตโนมัติ)
///   - ปุ่ม + เพิ่มจุดเอง
///   - ปุ่ม Show Rating Curve
///   - ปุ่ม Sim (เปิดหน้า Simulation Settings)
///   - ตารางจุด (width, elevation)
class CrossSectionEditorViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    // MARK: - Outlets
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var chartView: CrossSectionChartView!
    @IBOutlet weak var manningTextField: UITextField!
    @IBOutlet weak var waterLevelTextField: UITextField!
    @IBOutlet weak var normalDepthButton: UIButton!
    @IBOutlet weak var bankfullButton: UIButton!
    
    // MARK: - Context
    
    var project: Project!
    var node: RiverNode!
    
    // MARK: - Data
    
    private var crossSectionData = CrossSectionData(points: [], manningN: nil, waterLevel: nil)
    private let headerLabel = UILabel()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemBackground
        title = "Cross Section"
        
        setupHeader()
        setupTableView()
        setupButtons()
        setupManningField()
        setupWaterLevelField()
        setupWaterButtons()
        
        loadData()
    }
    
    // MARK: - Setup UI
    
    private func setupHeader() {
        headerLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        headerLabel.textAlignment = .center
        headerLabel.numberOfLines = 0
        headerLabel.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: 90)
        updateHeaderText()
        tableView.tableHeaderView = headerLabel
    }
    
    private func updateHeaderText() {
        let projectName = project?.name ?? "Unknown Project"
        let nodeName = node?.name ?? "Unknown Node"
        
        let nText: String
        if let n = crossSectionData.manningN {
            nText = String(format: "%.4f", n)
        } else {
            nText = "(not set)"
        }
        
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
        Manning n = \(nText)
        \(designText)
        """
    }
    
    private func setupTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "PointCell")
    }
    
    /// ตั้งค่าปุ่มบน Navigation Bar
    private func setupButtons() {

        // ปุ่มด้านขวา: + และ Template
        let addPointItem = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(addPointTapped)
        )

        let templateItem = UIBarButtonItem(
            title: "Template",
            style: .plain,
            target: self,
            action: #selector(templateTapped)
        )

        navigationItem.rightBarButtonItems = [addPointItem, templateItem]

        // ปุ่มด้านซ้าย: Back + Sim
        let simItem = UIBarButtonItem(
            title: "Sim",
            style: .plain,
            target: self,
            action: #selector(simButtonTapped)
        )

        // 🔥 สำคัญมาก
        navigationItem.leftItemsSupplementBackButton = true
        navigationItem.leftBarButtonItems = [simItem]
    }
    
    private func setupManningField() {
        manningTextField.keyboardType = .decimalPad
        manningTextField.placeholder = "e.g. 0.030"
        
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let done = UIBarButtonItem(barButtonSystemItem: .done,
                                   target: self,
                                   action: #selector(manningEditingDidEnd))
        toolbar.setItems([done], animated: false)
        manningTextField.inputAccessoryView = toolbar
    }
    
    private func setupWaterLevelField() {
        waterLevelTextField.keyboardType = .decimalPad
        waterLevelTextField.placeholder = "e.g. 0.50"
        
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let done = UIBarButtonItem(barButtonSystemItem: .done,
                                   target: self,
                                   action: #selector(waterLevelEditingDidEnd))
        toolbar.setItems([done], animated: false)
        waterLevelTextField.inputAccessoryView = toolbar
    }
    
    private func setupWaterButtons() {
        normalDepthButton.setTitle("Normal depth", for: .normal)
        bankfullButton.setTitle("Bankfull", for: .normal)
    }
    
    // MARK: - Data load / save
    
    private func loadData() {
        guard let project = project, let node = node else { return }
        
        crossSectionData = CrossSectionStorageManager.shared
            .loadCrossSection(for: project, node: node)
        
        tableView.reloadData()
        updateManningFieldFromData()
        updateWaterLevelFieldFromData()
        updateHeaderText()
        
        chartView.refresh(points: crossSectionData.points,
                          manningN: crossSectionData.manningN,
                          waterLevel: crossSectionData.waterLevel,
                          designWaterLevel: crossSectionData.designWaterLevel,
                          designDischarge: crossSectionData.designDischarge)
    }
    
    private func saveData() {
        guard let project = project, let node = node else { return }
        CrossSectionStorageManager.shared.saveCrossSection(crossSectionData,
                                                           for: project,
                                                           node: node)
    }
    
    private func updateManningFieldFromData() {
        if let n = crossSectionData.manningN {
            manningTextField.text = String(format: "%.4f", n)
        } else {
            manningTextField.text = nil
        }
    }
    
    private func updateWaterLevelFieldFromData() {
        if let wl = crossSectionData.waterLevel {
            waterLevelTextField.text = String(format: "%.2f", wl)
        } else {
            waterLevelTextField.text = nil
        }
    }
    
    // MARK: - เปิดหน้า Simulation Settings
    
    /// กดปุ่ม Sim ที่ navigation bar
    @objc private func simButtonTapped() {
        // ดึง view controller จาก Storyboard ID = "SimulationSettingsViewController"
        guard let settingsVC = storyboard?.instantiateViewController(
            withIdentifier: "SimulationSettingsViewController"
        ) as? SimulationSettingsViewController else {
            return
        }
        
        // ส่ง Design Q (ถ้ามี) ไปเป็น suggestedFlowIn
        settingsVC.suggestedFlowIn = crossSectionData.designDischarge
        
        // ส่ง context ของ project และ node ไปด้วย
        settingsVC.project = project
        settingsVC.node = node
        
        navigationController?.pushViewController(settingsVC, animated: true)
    }
    
    // MARK: - Manning n
    
    @objc private func manningEditingDidEnd() {
        manningTextField.resignFirstResponder()
        
        let text = manningTextField.text ?? ""
        if let value = Double(text), value > 0 {
            crossSectionData.manningN = value
        } else {
            crossSectionData.manningN = nil
            manningTextField.text = nil
        }
        saveData()
        updateHeaderText()
        chartView.refresh(points: crossSectionData.points,
                          manningN: crossSectionData.manningN,
                          waterLevel: crossSectionData.waterLevel,
                          designWaterLevel: crossSectionData.designWaterLevel,
                          designDischarge: crossSectionData.designDischarge)
    }
    
    // MARK: - Water level
    
    @objc private func waterLevelEditingDidEnd() {
        waterLevelTextField.resignFirstResponder()
        
        let text = waterLevelTextField.text ?? ""
        if let value = Double(text) {
            crossSectionData.waterLevel = value
        } else {
            crossSectionData.waterLevel = nil
            waterLevelTextField.text = nil
        }
        saveData()
        chartView.refresh(points: crossSectionData.points,
                          manningN: crossSectionData.manningN,
                          waterLevel: crossSectionData.waterLevel,
                          designWaterLevel: crossSectionData.designWaterLevel,
                          designDischarge: crossSectionData.designDischarge)
    }
    
    @IBAction func normalDepthButtonTapped(_ sender: UIButton) {
        guard let wl = computeNormalDepthLevel() else { return }
        crossSectionData.waterLevel = wl
        updateWaterLevelFieldFromData()
        saveData()
        chartView.refresh(points: crossSectionData.points,
                          manningN: crossSectionData.manningN,
                          waterLevel: crossSectionData.waterLevel,
                          designWaterLevel: crossSectionData.designWaterLevel,
                          designDischarge: crossSectionData.designDischarge)
    }
    
    @IBAction func bankfullButtonTapped(_ sender: UIButton) {
        guard let wl = computeBankfullLevel() else { return }
        crossSectionData.waterLevel = wl
        updateWaterLevelFieldFromData()
        saveData()
        chartView.refresh(points: crossSectionData.points,
                          manningN: crossSectionData.manningN,
                          waterLevel: crossSectionData.waterLevel,
                          designWaterLevel: crossSectionData.designWaterLevel,
                          designDischarge: crossSectionData.designDischarge)
    }
    
    private func computeNormalDepthLevel() -> Double? {
        let zs = crossSectionData.points.map { $0.elevation }
        guard let minZ = zs.min(), let maxZ = zs.max(), maxZ > minZ else {
            return nil
        }
        let depth = maxZ - minZ
        return minZ + 0.6 * depth
    }
    
    private func computeBankfullLevel() -> Double? {
        let zs = crossSectionData.points.map { $0.elevation }
        return zs.max()
    }
    
    // MARK: - Add point
    
    @objc private func addPointTapped() {
        let alert = UIAlertController(title: "Add Cross Section Point",
                                      message: "Enter width and elevation",
                                      preferredStyle: .alert)
        
        alert.addTextField { tf in
            tf.placeholder = "Width (m)"
            tf.keyboardType = .decimalPad
        }
        
        alert.addTextField { tf in
            tf.placeholder = "Elevation (m)"
            tf.keyboardType = .decimalPad
        }
        
        let addAction = UIAlertAction(title: "Add", style: .default) { [weak self] _ in
            guard let self = self else { return }
            
            let widthText = alert.textFields?[0].text ?? ""
            let elevText = alert.textFields?[1].text ?? ""
            
            guard let width = Double(widthText),
                  let elevation = Double(elevText) else {
                return
            }
            
            let point = CrossSectionPoint(width: width, elevation: elevation)
            self.crossSectionData.points.append(point)
            self.saveData()
            self.tableView.reloadData()
            self.chartView.refresh(points: self.crossSectionData.points,
                                   manningN: self.crossSectionData.manningN,
                                   waterLevel: self.crossSectionData.waterLevel,
                                   designWaterLevel: self.crossSectionData.designWaterLevel,
                                   designDischarge: self.crossSectionData.designDischarge)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        alert.addAction(addAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true)
    }
    
    // MARK: - Template
    
    @objc private func templateTapped() {
        showTemplateMenu()
    }
    
    private func showTemplateMenu() {
        let alert = UIAlertController(title: "Cross Section Template",
                                      message: "Choose a template type",
                                      preferredStyle: .actionSheet)
        
        let rectangularAction = UIAlertAction(title: "Rectangular", style: .default) { [weak self] _ in
            self?.showRectangularTemplateInput()
        }
        
        let trapezoidalAction = UIAlertAction(title: "Trapezoidal", style: .default) { [weak self] _ in
            self?.showTrapezoidalTemplateInput()
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        alert.addAction(rectangularAction)
        alert.addAction(trapezoidalAction)
        alert.addAction(cancelAction)
        
        if let popover = alert.popoverPresentationController {
            if let rightItems = navigationItem.rightBarButtonItems,
               let templateItem = rightItems.last {
                popover.barButtonItem = templateItem
            } else {
                popover.sourceView = self.view
                popover.sourceRect = CGRect(x: view.bounds.midX,
                                            y: view.bounds.midY,
                                            width: 0,
                                            height: 0)
            }
        }
        
        present(alert, animated: true)
    }
    
    private func showRectangularTemplateInput() {
        let alert = UIAlertController(title: "Rectangular Section",
                                      message: "Enter bottom width, depth, and Manning n (optional)",
                                      preferredStyle: .alert)
        
        alert.addTextField { tf in
            tf.placeholder = "Bottom width (m)"
            tf.keyboardType = .decimalPad
        }
        
        alert.addTextField { tf in
            tf.placeholder = "Depth (m)"
            tf.keyboardType = .decimalPad
        }
        
        alert.addTextField { tf in
            tf.placeholder = "Manning n (optional)"
            tf.keyboardType = .decimalPad
        }
        
        let generateAction = UIAlertAction(title: "Generate", style: .default) { [weak self] _ in
            guard let self = self else { return }
            
            let widthText = alert.textFields?[0].text ?? ""
            let depthText = alert.textFields?[1].text ?? ""
            let nText = alert.textFields?[2].text ?? ""
            
            guard let bottomWidth = Double(widthText),
                  let depth = Double(depthText),
                  bottomWidth > 0,
                  depth > 0 else {
                return
            }
            
            let nValue = Double(nText)
            
            self.crossSectionData = CrossSectionData.rectangular(
                bottomWidth: bottomWidth,
                depth: depth,
                manningN: nValue,
                waterLevel: self.crossSectionData.waterLevel,
                designWaterLevel: self.crossSectionData.designWaterLevel,
                designDischarge: self.crossSectionData.designDischarge
            )
            self.updateManningFieldFromData()
            self.updateHeaderText()
            self.saveData()
            self.tableView.reloadData()
            self.chartView.refresh(points: self.crossSectionData.points,
                                   manningN: self.crossSectionData.manningN,
                                   waterLevel: self.crossSectionData.waterLevel,
                                   designWaterLevel: self.crossSectionData.designWaterLevel,
                                   designDischarge: self.crossSectionData.designDischarge)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        alert.addAction(generateAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true)
    }
    
    private func showTrapezoidalTemplateInput() {
        let alert = UIAlertController(title: "Trapezoidal Section",
                                      message: "Enter bottom width, depth, side slope (H:1), and Manning n (optional)",
                                      preferredStyle: .alert)
        
        alert.addTextField { tf in
            tf.placeholder = "Bottom width (m)"
            tf.keyboardType = .decimalPad
        }
        
        alert.addTextField { tf in
            tf.placeholder = "Depth (m)"
            tf.keyboardType = .decimalPad
        }
        
        alert.addTextField { tf in
            tf.placeholder = "Side slope H:1 (e.g. 2 = 2H:1V)"
            tf.keyboardType = .decimalPad
        }
        
        alert.addTextField { tf in
            tf.placeholder = "Manning n (optional)"
            tf.keyboardType = .decimalPad
        }
        
        let generateAction = UIAlertAction(title: "Generate", style: .default) { [weak self] _ in
            guard let self = self else { return }
            
            let widthText = alert.textFields?[0].text ?? ""
            let depthText = alert.textFields?[1].text ?? ""
            let slopeText = alert.textFields?[2].text ?? ""
            let nText = alert.textFields?[3].text ?? ""
            
            guard let bottomWidth = Double(widthText),
                  let depth = Double(depthText),
                  let sideSlope = Double(slopeText),
                  bottomWidth > 0,
                  depth > 0 else {
                return
            }
            
            let nValue = Double(nText)
            
            self.crossSectionData = CrossSectionData.trapezoidal(
                bottomWidth: bottomWidth,
                depth: depth,
                sideSlope: sideSlope,
                includeBankTop: true,
                manningN: nValue,
                waterLevel: self.crossSectionData.waterLevel,
                designWaterLevel: self.crossSectionData.designWaterLevel,
                designDischarge: self.crossSectionData.designDischarge
            )
            self.updateManningFieldFromData()
            self.updateHeaderText()
            self.saveData()
            self.tableView.reloadData()
            self.chartView.refresh(points: self.crossSectionData.points,
                                   manningN: self.crossSectionData.manningN,
                                   waterLevel: self.crossSectionData.waterLevel,
                                   designWaterLevel: self.crossSectionData.designWaterLevel,
                                   designDischarge: self.crossSectionData.designDischarge)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        alert.addAction(generateAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true)
    }
    
    // MARK: - Rating Curve segue
    
    @IBAction func showRatingCurveTapped(_ sender: UIButton) {
        performSegue(withIdentifier: "showRatingCurve", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        if segue.identifier == "showRatingCurve" {
            if let dest = segue.destination as? RatingCurveViewController {
                dest.project = project
                dest.node = node
            }
        }
    }
    
    // MARK: - TableView
    
    func tableView(_ tableView: UITableView,
                   numberOfRowsInSection section: Int) -> Int {
        return crossSectionData.points.count
    }
    
    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PointCell",
                                                 for: indexPath)
        
        let point = crossSectionData.points[indexPath.row]
        let widthText = String(format: "%.2f", point.width)
        let elevText = String(format: "%.2f", point.elevation)
        
        cell.textLabel?.text = "x = \(widthText) m,  z = \(elevText) m"
        return cell
    }
    
    func tableView(_ tableView: UITableView,
                   commit editingStyle: UITableViewCell.EditingStyle,
                   forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            crossSectionData.points.remove(at: indexPath.row)
            saveData()
            tableView.deleteRows(at: [indexPath], with: .automatic)
            chartView.refresh(points: crossSectionData.points,
                              manningN: crossSectionData.manningN,
                              waterLevel: crossSectionData.waterLevel,
                              designWaterLevel: crossSectionData.designWaterLevel,
                              designDischarge: crossSectionData.designDischarge)
        }
    }
}
