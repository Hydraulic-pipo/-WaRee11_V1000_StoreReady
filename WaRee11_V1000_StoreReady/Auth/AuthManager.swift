//
//  AuthManager.swift
//  WaRee11_V0501
//
//  Created by Chalermchon Lertlum on 21/11/2568 BE.
//

import Foundation

/// จัดการเรื่องการล็อกอินแบบง่าย ๆ
/// เก็บข้อมูลใน UserDefaults (ไว้เริ่มต้นก่อน อนาคตค่อยย้ายไป Keychain)
final class AuthManager {
    
    // ใช้เป็น singleton ให้เรียกใช้ได้จากทุกที่: AuthManager.shared
    static let shared = AuthManager()
    
    private init() {}
    
    // กุญแจที่ใช้เก็บข้อมูลใน UserDefaults
    private let emailKey = "auth_email"
    private let passwordKey = "auth_password"
    private let loggedInKey = "auth_isLoggedIn"
    
    // MARK: - Public Properties
    
    /// user ล็อกอินอยู่หรือไม่
    var isLoggedIn: Bool {
        return UserDefaults.standard.bool(forKey: loggedInKey)
    }
    
    /// email ที่เคยสมัครไว้ (ถ้ามี)
    var savedEmail: String? {
        return UserDefaults.standard.string(forKey: emailKey)
    }
    
    // MARK: - Public Methods
    
    /// สมัครสมาชิก (ง่าย ๆ แค่เก็บ email/password)
    /// - ข้อควรจำ: ระบบนี้ไม่ปลอดภัยสำหรับ production จริง ใช้เพื่อเรียนรู้ก่อน
    func register(email: String, password: String) {
        UserDefaults.standard.set(email, forKey: emailKey)
        UserDefaults.standard.set(password, forKey: passwordKey)
        UserDefaults.standard.set(true, forKey: loggedInKey)
    }
    
    /// ล็อกอิน: ตรวจ email/password ตรงกับที่เคยสมัครไหม
    /// คืนค่า true = สำเร็จ, false = ไม่สำเร็จ
    func login(email: String, password: String) -> Bool {
        let savedEmail = UserDefaults.standard.string(forKey: emailKey)
        let savedPassword = UserDefaults.standard.string(forKey: passwordKey)
        
        if email == savedEmail && password == savedPassword {
            UserDefaults.standard.set(true, forKey: loggedInKey)
            return true
        } else {
            return false
        }
    }
    
    /// ล็อกเอาต์
    func logout() {
        UserDefaults.standard.set(false, forKey: loggedInKey)
    }
    
    /// ลบข้อมูลบัญชี (ใช้ตอนอยาก reset ระบบ)
    func clearAccount() {
        UserDefaults.standard.removeObject(forKey: emailKey)
        UserDefaults.standard.removeObject(forKey: passwordKey)
        UserDefaults.standard.set(false, forKey: loggedInKey)
    }
}
