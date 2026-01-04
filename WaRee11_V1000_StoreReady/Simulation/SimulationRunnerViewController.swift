//
//  SimulationRunnerViewController.swift
//  WaRee11_V0501
//
//  Created by Chalermchon Lertlum on 8/12/2568 BE.
//
//

import UIKit

/// หน้าสำหรับ "รัน Simulation"
/// ใช้ SolverManager (สมการจริงถ้ามี cross section + n)
class SimulationRunnerViewController: UIViewController {
    
    // MARK: - Outlets
    
    @IBOutlet weak var simulationSummaryLabel: UILabel!
    @IBOutlet weak var runButton: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var showResultsButton: UIButton!
    
    // MARK: - Context
    
    var project: Project?
    var node: RiverNode?
    
    // MARK: - Data
    
    private var settings: SimulationSettings?
    private var crossSectionData: CrossSectionData?
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Simulation Runner"
        view.backgroundColor = .systemBackground
        
        activityIndicator.hidesWhenStopped = true
        statusLabel.text = "Ready"
        
        showResultsButton.isEnabled = false
        
        loadSettings()
        loadCrossSection()
        updateSummaryText()
    }
    
    // MARK: - Load settings / cross section
    
    private func loadSettings() {
        settings = SimulationSettingsManager.load()
    }
    
    private func loadCrossSection() {
        guard let project = project, let node = node else {
            crossSectionData = nil
            return
        }
        crossSectionData = CrossSectionStorageManager.shared
            .loadCrossSection(for: project, node: node)
    }
    
    private func updateSummaryText() {
        guard let s = settings else {
            simulationSummaryLabel.text = """
            No simulation settings found.
            Please set up Simulation Settings first.
            """
            simulationSummaryLabel.textColor = .systemRed
            runButton.isEnabled = false
            showResultsButton.isEnabled = false
            return
        }
        
        let dtText = String(format: "%.0f", s.timeStep)
        let courantText = String(format: "%.2f", s.courantNumber)
        let gText = String(format: "%.2f", s.gravity)
        let c0Text = String(format: "%.2f", s.c0)
        let qText = String(format: "%.2f", s.flowIn)
        let hText = String(format: "%.2f", s.stageDown)
        
        let projectName = project?.name ?? "Unknown Project"
        let nodeName = node?.name ?? "Unknown Node"
        
        let hasXS = (crossSectionData?.points.count ?? 0) >= 2
        let xsInfo = hasXS ? "Cross-section: OK" : "Cross-section: missing or n not set"
        
        simulationSummaryLabel.textColor = .label
        simulationSummaryLabel.numberOfLines = 0
        simulationSummaryLabel.text = """
        Project: \(projectName)
        Node: \(nodeName)
        \(xsInfo)
        
        Time step: \(dtText) s
        Total steps: \(s.totalSteps)
        Courant: \(courantText)
        g: \(gText), c0: \(c0Text)
        Scheme: \(s.schemeType)
        Q_in: \(qText) m³/s
        Stage_down: \(hText) m
        """
        
        runButton.isEnabled = true
    }
    
    // MARK: - Actions
    
    @IBAction func runButtonTapped(_ sender: UIButton) {
        view.endEditing(true)
        
        guard let s = settings else {
            statusLabel.text = "No settings."
            return
        }
        
        runButton.isEnabled = false
        showResultsButton.isEnabled = false
        activityIndicator.startAnimating()
        statusLabel.text = "Running..."
        
        // เรียก SolverManager พร้อม geometry (ถ้ามี)
        let result = SolverManager.shared.run(settings: s,
                                              crossSection: crossSectionData)
        
        // ⭐️ เซฟทั้ง result + settings
        ResultsManager.shared.save(result: result, settings: s)
        
        activityIndicator.stopAnimating()
        runButton.isEnabled = true
        showResultsButton.isEnabled = true
        statusLabel.text = "Done. Generated \(result.points.count) points."
    }
    
    @IBAction func showResultsButtonTapped(_ sender: UIButton) {
        guard let _ = ResultsManager.shared.lastResult else {
            statusLabel.text = "No result to show."
            return
        }
        
        guard let vc = storyboard?.instantiateViewController(
            withIdentifier: "ResultsViewController"
        ) as? ResultsViewController else {
            return
        }
        
        vc.project = project
        vc.node = node
        
        navigationController?.pushViewController(vc, animated: true)
    }
}
