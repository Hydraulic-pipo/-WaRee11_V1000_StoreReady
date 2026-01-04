//
//  EditRiverNetworkViewController.swift
//  WaRee11_V0501
//
//  Created by Chalermchon Lertlum on 21/11/2568 BE.
//

import UIKit

/// หน้าสำหรับจัดการ River Network ของโปรเจกต์ที่เลือก
/// เวอร์ชันนี้: แสดงชื่อโปรเจกต์ + รายการ river nodes ใน TableView + ปุ่มเพิ่ม node
class EditRiverNetworkViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    // เชื่อมจาก storyboard
    @IBOutlet weak var tableView: UITableView!
    
    private let projectNameLabel = UILabel()
    
    /// โปรเจกต์ปัจจุบัน
    private var currentProject: Project? {
        return CurrentProjectManager.shared.currentProject
    }
    
    /// รายการโหนดแม่น้ำ
    private var nodes: [RiverNode] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemBackground
        title = "River Network"
        
        setupHeader()
        setupTableView()
        loadNodes()
        setupAddButton()
    }
    
    // MARK: - Setup UI
    
    /// header แสดงชื่อโปรเจกต์
    private func setupHeader() {
        projectNameLabel.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        projectNameLabel.textAlignment = .center
        projectNameLabel.numberOfLines = 0
        projectNameLabel.textColor = .label
        
        if let project = currentProject {
            projectNameLabel.text = "Project: \(project.name)"
        } else {
            projectNameLabel.text = "No project selected"
        }
        
        projectNameLabel.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: 60)
        tableView.tableHeaderView = projectNameLabel
    }
    
    private func setupTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "NodeCell")
    }
    
    private func setupAddButton() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(addNodeTapped)
        )
    }
    
    // MARK: - Data
    
    private func loadNodes() {
        guard let project = currentProject else {
            nodes = []
            tableView.reloadData()
            return
        }
        
        nodes = RiverNetworkStorageManager.shared.loadNodes(for: project)
        tableView.reloadData()
    }
    
    private func saveNodes() {
        guard let project = currentProject else { return }
        RiverNetworkStorageManager.shared.saveNodes(nodes, for: project)
    }
    
    // MARK: - Actions
    
    @objc private func addNodeTapped() {
        let alert = UIAlertController(title: "Add River Node",
                                      message: "Enter node name and chainage",
                                      preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.placeholder = "Node name (e.g. N1)"
        }
        
        alert.addTextField { textField in
            textField.placeholder = "Chainage (m)"
            textField.keyboardType = .decimalPad
        }
        
        let addAction = UIAlertAction(title: "Add", style: .default) { [weak self] _ in
            guard let self = self else { return }
            
            let name = alert.textFields?[0].text ?? ""
            let chainageText = alert.textFields?[1].text ?? ""
            
            guard !name.isEmpty,
                  let chainage = Double(chainageText) else {
                return
            }
            
            let newNode = RiverNode(name: name, chainage: chainage)
            self.nodes.append(newNode)
            self.saveNodes()
            self.tableView.reloadData()
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alert.addAction(addAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true, completion: nil)
    }
    
    // MARK: - UITableViewDataSource
    
    func tableView(_ tableView: UITableView,
                   numberOfRowsInSection section: Int) -> Int {
        return nodes.count
    }
    
    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "NodeCell", for: indexPath)
        
        let node = nodes[indexPath.row]
        let chainageText = String(format: "%.2f m", node.chainage)
        cell.textLabel?.text = "\(node.name)  –  \(chainageText)"
        cell.accessoryType = .disclosureIndicator
        
        return cell
    }
    
    // MARK: - UITableViewDelegate
    
    // ลบ node
    func tableView(_ tableView: UITableView,
                   commit editingStyle: UITableViewCell.EditingStyle,
                   forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            nodes.remove(at: indexPath.row)
            saveNodes()
            tableView.deleteRows(at: [indexPath], with: .automatic)
        }
    }
    
    // แตะ node → ไปหน้า Cross Section
    func tableView(_ tableView: UITableView,
                   didSelectRowAt indexPath: IndexPath) {
        guard let project = currentProject else {
            tableView.deselectRow(at: indexPath, animated: true)
            return
        }
        
        let node = nodes[indexPath.row]
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let csVC = storyboard.instantiateViewController(withIdentifier: "CrossSectionEditorViewController") as? CrossSectionEditorViewController else {
            tableView.deselectRow(at: indexPath, animated: true)
            return
        }
        
        // ส่ง project และ node ไปให้หน้าถัดไป
        csVC.project = project
        csVC.node = node
        
        navigationController?.pushViewController(csVC, animated: true)
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
