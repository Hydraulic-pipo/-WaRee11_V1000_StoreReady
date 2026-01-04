//
//  ProjectListViewController.swift
//  WaRee11_V0501
//
//  Created by Chalermchon Lertlum on 21/11/2568 BE.
//

import UIKit

class ProjectListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    
    private var projects: [Project] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Projects"
        view.backgroundColor = .systemBackground
        
        tableView.dataSource = self
        tableView.delegate = self
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "ProjectCell")
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(addProjectTapped)
        )
        
        reloadProjects()
    }
    
    private func reloadProjects() {
        projects = ProjectStorageManager.shared.loadProjects()
        tableView.reloadData()
    }
    
    // MARK: - Actions
    
    @objc private func addProjectTapped() {
        let alert = UIAlertController(title: "New Project",
                                      message: "Enter project name",
                                      preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.placeholder = "Project name"
        }
        
        let createAction = UIAlertAction(title: "Create", style: .default) { [weak self] _ in
            guard let self = self else { return }
            let name = alert.textFields?.first?.text ?? ""
            if name.isEmpty {
                return
            }
            ProjectStorageManager.shared.addProject(name: name)
            self.reloadProjects()
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alert.addAction(createAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true, completion: nil)
    }
    
    // MARK: - UITableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return projects.count
    }
    
    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ProjectCell", for: indexPath)
        let project = projects[indexPath.row]
        cell.textLabel?.text = project.name
        cell.accessoryType = .disclosureIndicator
        return cell
    }
    
    // MARK: - UITableViewDelegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let project = projects[indexPath.row]
        
        // 1) ตั้ง current project
        CurrentProjectManager.shared.setCurrentProject(project)
        
        // 2) ไปหน้า EditRiverNetworkViewController
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let vc = storyboard.instantiateViewController(withIdentifier: "EditRiverNetworkViewController") as? EditRiverNetworkViewController else {
            tableView.deselectRow(at: indexPath, animated: true)
            return
        }
        
        navigationController?.pushViewController(vc, animated: true)
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    // ลบโปรเจกต์ด้วยการเลื่อน
    func tableView(_ tableView: UITableView,
                   commit editingStyle: UITableViewCell.EditingStyle,
                   forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            ProjectStorageManager.shared.deleteProject(at: indexPath.row)
            reloadProjects()
        }
    }
}
