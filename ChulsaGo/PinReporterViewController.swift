//
//  PinReporterViewController.swift
//  ChulsaGo
//
//  Created by nuri Lee on 2017. 11. 30..
//  Copyright © 2017년 nuri lee. All rights reserved.
//

import UIKit

class PinReporterViewController : UIViewController, UITextViewDelegate {
    
    var pin_seq : String = String();
    var pin_type : String = String();
    var pin_user_seq : String = String();
    var reporter_seq : String = String();
    
    @IBOutlet weak var textView: UITextView!
    
    @IBAction func btnCancelPress(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil);
    }
    
    @IBAction func btnSendPress(_ sender: UIBarButtonItem) {
        
        if ( self.textView.text == "" ){
            
            let alertController = UIAlertController(title: NSLocalizedString("waiting", comment: "waiting"), message: NSLocalizedString("input body", comment: "input body"), preferredStyle: .alert)
            let okButton = UIAlertAction(title: NSLocalizedString("done", comment: "done"), style: .cancel , handler: { (action) -> Void in
            })
            alertController.addAction(okButton)
            self.present(alertController, animated: true, completion: nil)
            
        }else{
            
            DispatchQueue.main.async() {
                self.textView.resignFirstResponder();
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                
                //버튼 비활성화
                self.navigationItem.leftBarButtonItem?.isEnabled = false;
                self.navigationItem.rightBarButtonItem?.isEnabled = false;
                
                Common.pinReport(pin_seq: String(self.pin_seq), pin_type: self.pin_type, pin_user_seq: self.pin_user_seq, reporter_seq: self.reporter_seq, body: self.textView.text){ (result:String) in
                    
                    if( result == "ok")
                    {
                        let alertController = UIAlertController(title: NSLocalizedString("completed", comment: "completed"), message: NSLocalizedString("report success", comment: "report success"), preferredStyle: .alert)
                        
                        let okButton = UIAlertAction(title: NSLocalizedString("done", comment: "done"), style: .cancel , handler: { (action) -> Void in
                            
                            self.dismiss(animated: true, completion: nil);
                        })
                        
                        alertController.addAction(okButton)
                        
                        self.present(alertController, animated: true, completion: nil)
                    }else{
                        //버튼 활성화
                        self.navigationItem.leftBarButtonItem?.isEnabled = true;
                        self.navigationItem.rightBarButtonItem?.isEnabled = true;
                        
                        let alertController = UIAlertController(title: NSLocalizedString("waiting", comment: "waiting"), message: "\(result)", preferredStyle: .alert)
                        
                        let okButton = UIAlertAction(title: NSLocalizedString("done", comment: "done"), style: .cancel , handler: { (action) -> Void in
                        })
                        
                        alertController.addAction(okButton)
                        
                        self.present(alertController, animated: true, completion: nil)
                        
                    }
                }//report
                
            }//sync
            
        }//if
    }
    
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated);
        
        // 상태바 표시 업데이트 (Private API 대신 공식 API 사용)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.setNeedsStatusBarAppearanceUpdate()
        }
    }
    
    // MARK: - Status Bar Management
    override var prefersStatusBarHidden: Bool {
        return false  // Always show status bar
    }
    
    override func viewDidLoad() {
        super.viewDidLoad();
        
//         print(pin_seq);
//         print(pin_type);
//         print(pin_user_seq);
//         print(reporter_seq);
        
        self.navigationItem.rightBarButtonItem?.isEnabled = false;
        
        // 수정: NSNotification.Name. prefix 제거, UIResponder.keyboardWillShowNotification 직접 사용
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        self.textView.delegate = self;
        
        DispatchQueue.main.async() {
            self.textView.becomeFirstResponder();
        }
        
    }
    
    func textViewDidChange(_ textView: UITextView) {
        if ( textView.text == "" )
        {
            self.navigationItem.rightBarButtonItem?.isEnabled = false;
        }else{
            self.navigationItem.rightBarButtonItem?.isEnabled = true;
        }
    }
    
    var key_check:Bool = false;
    // 수정: NSNotification -> Notification
    @objc func keyboardWillShow(notification: Notification) {
        if key_check == false{
            adjustingHeight(true, notification: notification)
        }
    }
    
    // 수정: NSNotification -> Notification
    @objc func keyboardWillHide(notification: Notification) {
        if key_check == true{
            adjustingHeight(false, notification: notification)
        }
    }
    
    // 수정: NSNotification -> Notification
    func adjustingHeight(_ show:Bool, notification: Notification) {
        
        var keyboardHeight:CGFloat = 0;
        
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
        {
            keyboardHeight = keyboardSize.height;
            //print(keyboardHeight);
        }
        
        let changeInHeight = (keyboardHeight);
        
        if show{
            textView.contentInset.bottom += changeInHeight
            
            textView.scrollIndicatorInsets.bottom += changeInHeight
            key_check = true;
        }else{
            textView.contentInset.bottom = 0
            
            textView.scrollIndicatorInsets.bottom = 0
            key_check = false;
        }
        
    }
    
}
