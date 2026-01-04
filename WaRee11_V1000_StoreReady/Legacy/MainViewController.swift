//
//  MainViewController.swift
//  WaRee11_V0501
//
//  Created by Chalermchon Lertlum on 21/11/2568 BE.
//

import UIKit

class MainViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemBackground
        title = "WaRee11 Main"
        
        // MARK: - Label แสดงข้อความ
        let label = UILabel()
        label.text = "Main Screen\n(Projects, River Network, etc. will be here)"
        label.numberOfLines = 0
        label.textAlignment = .center
        
        // MARK: - ปุ่มเปิด Project List
        let projectsButton = UIButton(type: .system)
        projectsButton.setTitle("Open Projects", for: .normal)
        projectsButton.addTarget(self, action: #selector(openProjectsTapped), for: .touchUpInside)
        
        // ใช้ StackView จัดสองอย่างนี้ให้อยู่กลาง
        let stack = UIStackView(arrangedSubviews: [label, projectsButton])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 20
        
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor)
        ])
        
        // MARK: - ปุ่ม Logout บน Navigation Bar
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Logout",
            style: .plain,
            target: self,
            action: #selector(logoutTapped)
        )
    }
    
    // เปิดหน้า Project List
    @objc private func openProjectsTapped() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        // ใช้ Storyboard ID ที่เราตั้งไว้
        guard let vc = storyboard.instantiateViewController(withIdentifier: "ProjectListViewController") as? ProjectListViewController else {
            return
        }
        navigationController?.pushViewController(vc, animated: true)
    }
    
    // Logout → กลับไปหน้า Login
    @objc private func logoutTapped() {
        AuthManager.shared.logout()
        dismiss(animated: true, completion: nil)
    }
}
