//
//  LoginViewController.swift
//  LovePet
//
//  Created by Nu-Ri Lee on 2017. 6. 4..
//  Copyright © 2017년 nuri lee. All rights reserved.
//

import UIKit
import Foundation
import SystemConfiguration
import KakaoSDKUser  // Kakao SDK import 추가

//handle login
protocol HandleTextField: class {
    func focusTextField();
}


class LoginViewController : UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet var scrollViewBottom: NSLayoutConstraint!
    
    @IBOutlet weak var textFieldEmail: UITextField!
    @IBOutlet weak var textFieldPassword: UITextField!
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true);
    }
    
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        //print(textField.tag);
        
        let email = textFieldEmail.text!;
        
        if (textField.tag == 0){
            let check = isValid(email);
            if (email == "")
            {
                let alertController = UIAlertController(title: NSLocalizedString("fail login", comment: "fail login"), message: NSLocalizedString("input email", comment: "input email"), preferredStyle: .alert)
                let okButton = UIAlertAction(title: NSLocalizedString("done", comment: "done"), style: .default, handler: { (action) -> Void in
                    self.textFieldEmail.becomeFirstResponder();
                })
                alertController.addAction(okButton)
                self.present(alertController, animated: true, completion: nil)
                
            }else if check {
                self.textFieldPassword.becomeFirstResponder()
            }else{
                let alertController = UIAlertController(title: NSLocalizedString("fail login", comment: "fail login"), message: NSLocalizedString("not email type", comment: "not email type"), preferredStyle: .alert)
                let okButton = UIAlertAction(title: NSLocalizedString("done", comment: "done"), style: .cancel , handler: { (action) -> Void in
                    self.textFieldEmail.becomeFirstResponder();
                })
                alertController.addAction(okButton)
                self.present(alertController, animated: true, completion: nil)
            }
        }else if (textField.tag == 1){
            loginCheck();
        }
        
//         self.view.endEditing(true);
//
//         self.scrollView.contentInset.bottom = 0
//         self.scrollView.scrollIndicatorInsets.bottom = 0
//         self.key_check = false;
        return(true);
    }
    
    @IBAction func btnLoginAction(_ sender: Any) {
        loginCheck();
    }
    
    
    func loginCheck(){
        var email : String = textFieldEmail.text!;
        email = email.stringTrim();
        textFieldEmail.text = email;
        var password : String = textFieldPassword.text!;
        password = password.stringTrim();
        textFieldPassword.text = password;
        
        
        var emailCheck : Bool = false;
        if (email != "")
        {
            emailCheck = isValid(email);
        }
        
        
        if (email == "")
        {
            let alertController = UIAlertController(title: NSLocalizedString("fail login", comment: "fail login"), message: NSLocalizedString("input email", comment: "input email"), preferredStyle: .alert)
            let okButton = UIAlertAction(title: NSLocalizedString("done", comment: "done"), style: .default, handler: { (action) -> Void in
                self.textFieldEmail.becomeFirstResponder();
            })
            alertController.addAction(okButton)
            self.present(alertController, animated: true, completion: nil)
            
            
        }else if ( emailCheck == false ){
            //이메일 체크
            let alertController = UIAlertController(title: NSLocalizedString("fail login", comment: "fail login"), message: NSLocalizedString("not email type", comment: "not email type"), preferredStyle: .alert)
            let okButton = UIAlertAction(title: NSLocalizedString("done", comment: "done"), style: .cancel , handler: { (action) -> Void in
                self.textFieldEmail.becomeFirstResponder();
            })
            alertController.addAction(okButton)
            self.present(alertController, animated: true, completion: nil)
            
        }else if (password == "")
        {
            let alertController = UIAlertController(title: NSLocalizedString("fail login", comment: "fail login"), message: NSLocalizedString("input password", comment: "input password"), preferredStyle: .alert)
            let okButton = UIAlertAction(title: NSLocalizedString("done", comment: "done"), style: .default, handler: { (action) -> Void in
                self.textFieldPassword.becomeFirstResponder();
            })
            alertController.addAction(okButton)
            self.present(alertController, animated: true, completion: nil)
        }else{
            
            let key : String = "nuri";
            let type : String = "app";
            let param : String = "key="+key+"&email="+email+"&password="+password+"&type="+type;
            self.view.endEditing(true);
            self.scrollView.contentInset.bottom = 0
            self.scrollView.scrollIndicatorInsets.bottom = 0
            self.key_check = false;
            
            //로그인 시도
            DispatchQueue.main.async() {
                
                self.performLoginAjax(email: email, password: password)
            }//async
        }
        
    }
    
    func performLoginAjax(email: String, password: String) {
        let url = AppDelegate.serverUrl + "/chulsago/login.php"
        let param = "key=nuri&email=\(email)&password=\(password)&type=app"
        Ajax.forecast(withUrl: url, withParam: param) { (results:[[String:Any]]) in
    
            for result in results{
                if (result["error"] != nil){
                    //에러발생시
                    print(result["error"] ?? "error")
                    let alertController = UIAlertController(title: NSLocalizedString("waiting", comment: "waiting"), message: "\(String(describing: result["error"]!))", preferredStyle: .alert)
                    let okButton = UIAlertAction(title: NSLocalizedString("done", comment: "done"), style: .cancel , handler: { (action) -> Void in
                    })
                    alertController.addAction(okButton)
                    
                    self.present(alertController, animated: true, completion: nil)
                }else{
                    //print(result["seq"]!)
                    let userSeq = Int(String(describing: result["seq"]!))
                    UserDefaults.standard.set(userSeq!, forKey: "loginSesstion");
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        
                        //로그인 초기화
                        let noti = Notification(name: Notification.Name("loginInit"))
                        NotificationCenter.default.post(noti)
                        
                        //infoLikeReload
                        let noti2 = Notification(name: Notification.Name("infoLikeReload"))
                        NotificationCenter.default.post(noti2)
                        
                        
                        //addPin에서 로그인페이지로 이동 되었을때 바로 addPin 페이지로 이동
                        let loginToAddPin = UserDefaults.standard.object(forKey: "loginToAddPin") as? Bool ?? false;
                        
                        if loginToAddPin {
                            let noti2 = Notification(name: Notification.Name("loginToAddPin"))
                            NotificationCenter.default.post(noti2)
                        }
                        
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        self.presentingViewController?.dismiss(animated: true)
                    }
                }
            }
    
        }//Ajax
    }
    
    //이메일 체크
    func isValid(_ email: String) -> Bool {
        let emailRegEx = "(?:[a-z0-9!#$%\\&'*+/=?\\^_`{|}~-]+(?:\\.[a-z0-9!#$%\\&'*+/=?\\^_`{|}"+"~-]+)*|\"(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21\\x23-\\x5b\\x5d-\\"+"x7f]|\\\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])*\")@(?:(?:[a-z0-9](?:[a-"+"z0-9-]*[a-z0-9])?\\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?|\\[(?:(?:25[0-5"+"]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-"+"9][0-9]?|[a-z0-9-]*[a-z0-9]:(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21"+"-\\x5a\\x53-\\x7f]|\\\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])+)\\])"
        
        let emailTest = NSPredicate(format:"SELF MATCHES[c] %@", emailRegEx)
        return emailTest.evaluate(with: email)
    }
    
    
    func getKaKaoValue(){
        // Kakao 로그인 (KakaoTalk 앱으로)
        UserApi.shared.loginWithKakaoTalk { (oauthToken, error) in
            if let error = error {
                print(error.localizedDescription)
                // 실패 알림
                let alert = UIAlertController(title: "로그인 실패", message: error.localizedDescription, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "확인", style: .default))
                self.present(alert, animated: true)
                return
            }
            
            // 사용자 정보 가져오기
            UserApi.shared.me { (user, error) in
                if let error = error {
                    print(error.localizedDescription)
                    return
                }
                
                guard let user = user else { return }
                
                let email = user.kakaoAccount?.email ?? ""
                let type = "kakao"
                let id = String(user.id ?? 0)  // UInt64 -> String 변환
                let name = user.kakaoAccount?.profile?.nickname ?? ""
                let profile_image = user.kakaoAccount?.profile?.profileImageUrl?.absoluteString ?? ""
                let thumbnail_image = user.kakaoAccount?.profile?.thumbnailImageUrl?.absoluteString ?? ""
                
                // 서버로 정보 전송 (너의 Ajax 로직)
                let param = "key=nuri&email=\(email)&name=\(name)&type=\(type)&id=\(id)&profile_image=\(profile_image)&thumbnail_image=\(thumbnail_image)"
                
                Ajax.forecast(withUrl: AppDelegate.serverUrl + "/chulsago/login.php", withParam: param) { (results: [[String: Any]]) in
                    // 기존 로직 (로그인 성공 처리)
                    for result in results {
                        if let error = result["error"] {
                            print(error)
                            // 에러 알림
                        } else {
                            if let seq = result["seq"] as? String, let userSeq = Int(seq) {
                                UserDefaults.standard.set(userSeq, forKey: "loginSesstion")
                                // noti post 등 기존 로직
                            }
                        }
                    }
                }
            }
        }
    }
    
    
    func kakaoLoginStart(){
        
        //print("왜 안돼");
        
    }
    
    @IBAction func kakaoLogin(_ sender: UIButton) {
        
        //go EULA
        
    }
    
    @IBAction func dismissView(_ sender: Any) {
        self.presentingViewController?.dismiss(animated: true)
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        // 상태바 표시 (Private API 대신 공식 API 사용)
        self.setNeedsStatusBarAppearanceUpdate()
        
        self.textFieldEmail.delegate = self;
        self.textFieldPassword.delegate = self;
        
        
        let viewTap = UITapGestureRecognizer(target: self, action:#selector(self.viewTap))
        scrollView.addGestureRecognizer(viewTap)
        
        
        
        
    }
    
    override var prefersStatusBarHidden: Bool {
        return false  // Always show status bar
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated);
        addObservers();
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        removeObservers();
        
    }
    
    
    
    
    @objc func viewTap(){
        //self.view.endEditing(true);
        self.view.endEditing(true);
        
        self.scrollView.contentInset.bottom = 0
        self.scrollView.scrollIndicatorInsets.bottom = 0
        self.key_check = false;
        
    }
    
    func addObservers(){
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        
    }
    
    func removeObservers()
    {
        NotificationCenter.default.removeObserver(self)
    }
    
    //키보드 스크롤뷰 새로운 방법
    var key_check:Bool = false;
    
    @objc func keyboardWillShow(_ notification: Notification){
        if key_check == false{
            adjustingHeight(true, notification: notification as Notification)
        }
    }
    
    
    @objc func keyboardWillHide(notification: NSNotification) {
    
        if key_check == true{
            adjustingHeight(false, notification: notification as Notification)
            //self.view.endEditing(true);
        }
    }
    
    func adjustingHeight(_ show:Bool, notification:Notification) {
        
//         if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
//
//
//             let contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardSize.height, right: 0)
//
//             if show{
//                 scrollView.contentInset = contentInset;
//                 print("킴");
//                 key_check = true;
//             }else{
//                 scrollView.contentInset = UIEdgeInsets.zero;
//                 print("끔");
//                 key_check = false;
//             }
//         }
//
        var keyboardHeight:CGFloat = 0;
    
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
        {
            keyboardHeight = keyboardSize.height;
            //print(keyboardHeight);
        }
        
        
        if show{
            //self.editTextView.frame.origin.y -= changeInHeight;
            //self.editTextBottomSpace.constant = changeInHeight;
            
            UIView.animate(withDuration: 0.3,
                           delay: 0,
                           options: .curveEaseInOut,
                           animations: {
                self.view.layoutIfNeeded()
            })
            
            
            
            
            self.scrollView.contentInset.bottom += keyboardHeight
            self.scrollView.scrollIndicatorInsets.bottom += keyboardHeight
            self.key_check = true;
            
        }else{
            
            //self.editTextView.frame.origin.y += changeInHeight;
            //self.editTextBottomSpace.constant = 0;
            
            UIView.animate(withDuration: 0.3,
                           delay: 0,
                           options: .curveEaseInOut,
                           animations: {
                self.view.layoutIfNeeded()
            })
            
            self.scrollView.contentInset.bottom = 0
            self.scrollView.scrollIndicatorInsets.bottom = 0
            self.key_check = false;
            
        }
        
        
        
    }
    
    
    
    
}

//search map
extension LoginViewController: @MainActor HandleTextField {
    
    func focusTextField() {
        print("뀨");
    }
    
}
