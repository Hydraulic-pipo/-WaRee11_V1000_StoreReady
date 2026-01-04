//
//  ResultsViewController.swift
//  WaRee11_V0501
//
//  Created by Chalermchon Lertlum on 9/12/2568 BE.
//

import UIKit

/// แสดงผลการจำลอง:
/// - กราฟ (SolverResultChartView)
/// - ตาราง t, h, Q_out
/// ข้อมูลอ่านจาก ResultsManager.shared
class ResultsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    // MARK: - Outlets
    
    @IBOutlet weak var chartView: SolverResultChartView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var summaryLabel: UILabel!
    
    // MARK: - Context
    
    var project: Project?
    var node: RiverNode?
    
    // MARK: - Data
    
    private var result: SolverResult?
    private var settings: SimulationSettings?
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Results"
        view.backgroundColor = .systemBackground
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "ResultCell")
        
        loadDataFromManager()
        updateUI()
    }
    
    private func loadDataFromManager() {
        result = ResultsManager.shared.lastResult
        settings = ResultsManager.shared.lastSettings
    }
    
    private func updateUI() {
        guard let result = result, !result.points.isEmpty else {
            summaryLabel.text = "No results. Please run simulation first."
            chartView.result = nil
            chartView.qIn = nil
            return
        }
        
        summaryLabel.numberOfLines = 0
        
        let n = result.points.count
        let tMin = result.points.first?.time ?? 0.0
        let tMax = result.points.last?.time ?? 0.0
        
        let projectName = project?.name ?? "Unknown Project"
        let nodeName = node?.name ?? "Unknown Node"
        
        let qInText: String
        if let s = settings {
            qInText = String(format: "%.2f", s.flowIn)
        } else {
            qInText = "-"
        }
        
        summaryLabel.text = """
        Project: \(projectName)
        Node: \(nodeName)
        
        Result points: \(n)
        Time range: \(Int(tMin)) – \(Int(tMax)) s
        Q_in: \(qInText) m³/s
        """
        
        chartView.result = result
        chartView.qIn = settings?.flowIn
        
        tableView.reloadData()
    }
    
    // MARK: - TableView
    
    func tableView(_ tableView: UITableView,
                   numberOfRowsInSection section: Int) -> Int {
        return result?.points.count ?? 0
    }
    
    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ResultCell",
                                                 for: indexPath)
        
        guard let point = result?.points[indexPath.row] else {
            cell.textLabel?.text = "-"
            return cell
        }
        
        let tText = String(format: "%.0f", point.time)
        let hText = String(format: "%.3f", point.waterLevel)
        let qText = String(format: "%.3f", point.discharge)
        
        cell.textLabel?.font = UIFont.monospacedDigitSystemFont(ofSize: 13, weight: .regular)
        cell.textLabel?.text = "t=\(tText) s   h=\(hText) m   Q_out=\(qText) m³/s"
        
        return cell
    }
}
