//
//  SimulationSettingsViewController.swift
//  WaRee11_V0501
//
//  Created by Chalermchon Lertlum on 28/11/2568 BE.

//
//  SimulationSettingsViewController.swift
//  WaRee11_v05
//

import UIKit

class SimulationSettingsViewController: UIViewController {
    
    // MARK: - Outlets
    
    @IBOutlet weak var startDatePicker: UIDatePicker!
    @IBOutlet weak var endDatePicker: UIDatePicker!
    
    @IBOutlet weak var timeStepField: UITextField!
    @IBOutlet weak var stepsField: UITextField!
    @IBOutlet weak var courantField: UITextField!
    @IBOutlet weak var gravityField: UITextField!
    @IBOutlet weak var c0Field: UITextField!
    @IBOutlet weak var flowInField: UITextField!
    @IBOutlet weak var stageDownField: UITextField!
    
    @IBOutlet weak var schemeSegmentedControl: UISegmentedControl!
    
    // MARK: - Data passed in
    
    /// Design Q จาก CrossSection / Rating Curve
    var suggestedFlowIn: Double?
    
    /// Context ของ project / node ที่กำลังเซ็ต Simulation
    var project: Project?
    var node: RiverNode?
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Simulation Settings"
        view.backgroundColor = .systemBackground
        
        setupTextFields()
        setupSchemeControl()
        loadExistingSettingsIfAny()
    }
    
    // MARK: - Setup
    
    private func setupTextFields() {
        let fields: [UITextField] = [
            timeStepField,
            stepsField,
            courantField,
            gravityField,
            c0Field,
            flowInField,
            stageDownField
        ]
        
        for tf in fields {
            tf.keyboardType = .decimalPad
        }
        
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let done = UIBarButtonItem(barButtonSystemItem: .done,
                                   target: self,
                                   action: #selector(doneEditing))
        toolbar.setItems([done], animated: false)
        
        for tf in fields {
            tf.inputAccessoryView = toolbar
        }
    }
    
    private func setupSchemeControl() {
        schemeSegmentedControl.removeAllSegments()
        let schemes = ["Upwind", "Lax", "MacCormack"]
        for (index, title) in schemes.enumerated() {
            schemeSegmentedControl.insertSegment(withTitle: title, at: index, animated: false)
        }
        schemeSegmentedControl.selectedSegmentIndex = 0
    }
    
    // MARK: - Load existing
    
    private func loadExistingSettingsIfAny() {
        if let settings = SimulationSettingsManager.load() {
            // มีค่าเก่า → เติมค่าเก่าลง UI
            timeStepField.text = String(format: "%.0f", settings.timeStep)
            stepsField.text = "\(settings.totalSteps)"
            courantField.text = String(format: "%.2f", settings.courantNumber)
            gravityField.text = String(format: "%.2f", settings.gravity)
            c0Field.text = String(format: "%.2f", settings.c0)
            flowInField.text = String(format: "%.2f", settings.flowIn)
            stageDownField.text = String(format: "%.2f", settings.stageDown)
            
            startDatePicker.date = settings.startDate
            endDatePicker.date = settings.endDate
            
            let scheme = settings.schemeType.lowercased()
            switch scheme {
            case "upwind":
                schemeSegmentedControl.selectedSegmentIndex = 0
            case "lax":
                schemeSegmentedControl.selectedSegmentIndex = 1
            case "maccormack":
                schemeSegmentedControl.selectedSegmentIndex = 2
            default:
                schemeSegmentedControl.selectedSegmentIndex = 0
            }
            
        } else {
            // ไม่มีค่าเก่า → set default
            timeStepField.text = "60"
            stepsField.text = "100"
            courantField.text = "0.8"
            gravityField.text = "9.81"
            c0Field.text = "1.0"
            
            if let q = suggestedFlowIn {
                flowInField.text = String(format: "%.2f", q)
            } else {
                flowInField.text = "10.0"
            }
            
            stageDownField.text = "1.0"
            
            let now = Date()
            startDatePicker.date = now
            endDatePicker.date = now.addingTimeInterval(3600)
        }
    }
    
    // MARK: - สร้าง settings จาก UI
    
    private func buildSettingsFromUI() -> SimulationSettings? {
        guard
            let dtText = timeStepField.text, let dt = Double(dtText),
            let stepsText = stepsField.text, let totalSteps = Int(stepsText),
            let crText = courantField.text, let courant = Double(crText),
            let gText = gravityField.text, let g = Double(gText),
            let c0Text = c0Field.text, let c0 = Double(c0Text),
            let qText = flowInField.text, let qIn = Double(qText),
            let hText = stageDownField.text, let hDown = Double(hText)
        else {
            showAlert(title: "Invalid Input",
                      message: "Please check all numeric fields.")
            return nil
        }
        
        let scheme: String
        switch schemeSegmentedControl.selectedSegmentIndex {
        case 0: scheme = "upwind"
        case 1: scheme = "lax"
        case 2: scheme = "maccormack"
        default: scheme = "upwind"
        }
        
        let settings = SimulationSettings(
            timeStep: dt,
            totalSteps: totalSteps,
            courantNumber: courant,
            gravity: g,
            c0: c0,
            schemeType: scheme,
            flowIn: qIn,
            stageDown: hDown,
            startDate: startDatePicker.date,
            endDate: endDatePicker.date
        )
        
        return settings
    }
    
    // MARK: - Actions
    
    @objc private func doneEditing() {
        view.endEditing(true)
    }
    
    @IBAction func saveButtonTapped(_ sender: UIButton) {
        view.endEditing(true)
        
        guard let settings = buildSettingsFromUI() else {
            return
        }
        
        SimulationSettingsManager.save(settings)
        
        showAlert(title: "Saved",
                  message: "Simulation settings have been saved.")
    }
    
    @IBAction func runButtonTapped(_ sender: UIButton) {
        view.endEditing(true)
        
        guard let settings = buildSettingsFromUI() else {
            return
        }
        
        SimulationSettingsManager.save(settings)
        
        guard let runnerVC = storyboard?.instantiateViewController(
            withIdentifier: "SimulationRunnerViewController"
        ) as? SimulationRunnerViewController else {
            return
        }
        
        // ส่ง context project/node ให้ Runner ด้วย
        runnerVC.project = project
        runnerVC.node = node
        
        navigationController?.pushViewController(runnerVC, animated: true)
    }
    
    // MARK: - Helper
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title,
                                      message: message,
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK",
                                      style: .default,
                                      handler: nil))
        present(alert, animated: true)
    }
}
