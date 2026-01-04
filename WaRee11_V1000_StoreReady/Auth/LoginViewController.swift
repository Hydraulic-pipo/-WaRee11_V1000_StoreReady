//
//  LoginViewController.swift
//  WaRee11_V0501
//
//  Created by Chalermchon Lertlum on 21/11/2568 BE.
//

import UIKit

class LoginViewController: UIViewController {
    
    // เชื่อมกับ TextField ใน Storyboard
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // ตั้งค่าเริ่มต้นเล็กน้อย
        view.backgroundColor = .systemBackground
        
        // ถ้ามี email ที่เคยสมัครไว้แล้ว แสดงไว้ในช่อง
        if let savedEmail = AuthManager.shared.savedEmail {
            emailTextField.text = savedEmail
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // ถ้าเคยล็อกอินไว้แล้ว → ข้ามหน้า Login ไปหน้า Main ทันที
        if AuthManager.shared.isLoggedIn {
            goToMainScreen()
        }
    }
    
    // MARK: - Actions
    
    @IBAction func loginButtonTapped(_ sender: UIButton) {
        let email = emailTextField.text ?? ""
        let password = passwordTextField.text ?? ""
        
        // ตรวจให้ไม่เป็นค่าว่าง
        guard !email.isEmpty, !password.isEmpty else {
            showAlert(title: "Error", message: "Please enter email and password.")
            return
        }
        
        let success = AuthManager.shared.login(email: email, password: password)
        
        if success {
            goToMainScreen()
        } else {
            showAlert(title: "Login Failed", message: "Email or password is incorrect.\nIf you are new, please register first.")
        }
    }
    
    @IBAction func registerButtonTapped(_ sender: UIButton) {
        let email = emailTextField.text ?? ""
        let password = passwordTextField.text ?? ""
        
        guard !email.isEmpty, !password.isEmpty else {
            showAlert(title: "Error", message: "Please enter email and password to register.")
            return
        }
        
        // สมัคร + ล็อกอินอัตโนมัติ
        AuthManager.shared.register(email: email, password: password)
        showAlert(title: "Registered", message: "Account created and logged in.") { [weak self] in
            self?.goToMainScreen()
        }
    }
    
    // MARK: - Navigation
    
    private func goToMainScreen() {
        // ใช้ segue ตัวใหม่ที่ไป Navigation Controller
        performSegue(withIdentifier: "showMainNav", sender: self)
    }
    
    // MARK: - Helper
    
    private func showAlert(title: String, message: String, completion: (() -> Void)? = nil) {
        let alert = UIAlertController(title: title,
                                      message: message,
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
            completion?()
        }))
        present(alert, animated: true, completion: nil)
    }
}
