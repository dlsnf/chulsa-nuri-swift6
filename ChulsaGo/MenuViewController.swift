//
//  MenuViewController.swift
//  menuNuri
//
//  Created by Nu-Ri Lee on 2017. 5. 25..
//  Copyright © 2017년 nuri lee. All rights reserved.
//

import UIKit

class MenuViewController: UIViewController {
    
    
    var pin_type : String = String();
    
    @IBOutlet weak var loginOff: UIView!
    
    @IBOutlet weak var loginOn: UIView!
    @IBOutlet weak var lgoinOnProfileImageView: UIImageView!
    
    @IBOutlet weak var profileLabel: UILabel!
    @IBAction func showLogin(_ sender: Any) {
        //print("showLogin");
    }
    
    @IBOutlet weak var newDate: UILabel!
    @IBOutlet weak var hotLike: UILabel!
    @IBOutlet var menuIcon: [UIImageView]!
    @IBOutlet var menuLabel: [UILabel]!
    
    @IBAction func showSetting(_ sender: Any) {
//         UserDefaults.standard.set(-1, forKey: "loginSesstion");
//         loginInit()
//         //infoLikeReload
//         let noti = Notification.init(name : Notification.Name(rawValue: "infoLikeReload"));
//         NotificationCenter.default.post(noti);
        self.performSegue(withIdentifier: "showMyPage", sender: self);
    }
    @IBAction func menuButtonPress(_ sender: UIButton) {
        //print(sender.tag);
        
        let tag = sender.tag;
        if ( tag == 0 )
        {
            //초기화 체크
            UserDefaults.standard.set(true, forKey: "initCheck");
            
            let newRootViewController = self.storyboard!.instantiateViewController(withIdentifier: "NaviController") as! UINavigationController
            let vc = newRootViewController.viewControllers[0] as! HomeViewController;
            vc.pin_type = enum_pin_type.chulsa.rawValue;
            UIApplication.shared.keyWindow!.replaceRootViewControllerWith(newRootViewController, animated: false, completion: nil)
            UIApplication.shared.keyWindow!.makeKeyAndVisible();
            
            
        }else if ( tag == 1 )
        {
            //초기화 체크
            UserDefaults.standard.set(true, forKey: "initCheck");
            
            let newRootViewController = self.storyboard!.instantiateViewController(withIdentifier: "NaviController") as! UINavigationController
            let vc = newRootViewController.viewControllers[0] as! HomeViewController;
            vc.pin_type = enum_pin_type.food.rawValue;
            UIApplication.shared.keyWindow!.replaceRootViewControllerWith(newRootViewController, animated: false, completion: nil)
            UIApplication.shared.keyWindow!.makeKeyAndVisible();
            
            
        }
        
    }
    
    func swapRootViewController(newController: UIViewController) {
        let rootView = UIApplication.shared.keyWindow!
        
        rootView.rootViewController?.dismiss(animated: false, completion: nil)
        
        UIView.transition(with: rootView, duration: 0.3, options: .transitionCrossDissolve, animations: {
            rootView.rootViewController = newController
        }, completion: nil)
        
    }
    
    
    @objc func loginInit(){
        
        let loginSesseion = UserDefaults.standard.object(forKey: "loginSesstion") as? Int ?? -1;
        
        if loginSesseion != -1 { //로그인 되었을때
            loginOff.isHidden = true;
            loginOn.isHidden = false;
            
            
            let param : String = "key=nuri&seq=" + String(loginSesseion);
            
            Ajax.forecast(withUrl: AppDelegate.serverUrl + "/chulsago/user_select.php", withParam: param) { (results:[[String:Any]]) in
                
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
                        let seq : String = (result["seq"] as? String)!;
                        let name : String = (result["name"] as? String)!;
                        let thumbnail_image : String = (result["thumbnail_image"] as? String)!;
                        
                        
                        //레이아웃 바꿀때 충돌 방지
                        DispatchQueue.main.async() {
                            
                            
                            print("seq : \(seq)");
                            print("name : \(name)");
                            
                            //프로필 사진 추가
                            if thumbnail_image != ""{
                                self.lgoinOnProfileImageView.contentMode = UIView.ContentMode.scaleAspectFill
                                self.lgoinOnProfileImageView.downloadAndResizeImageFrom(thumbnail_image, contentMode: .scaleAspectFill, newWidth: 200)
                            }else{
                                self.lgoinOnProfileImageView.contentMode = UIView.ContentMode.center
                                self.lgoinOnProfileImageView.image = UIImage(named: "nonProfile");
                            }
                            
                            //프로필 텍스트 추가
                            if name != ""{
                                let profileText = name + " " + NSLocalizedString("welcome", comment: "welcome");
                                DispatchQueue.main.async() {
                                    self.profileLabel.text = profileText;
                                    print(profileText);
                                }
                            }else{
                                DispatchQueue.main.async() {
                                    let profileText = NSLocalizedString("welcome user", comment: "welcome user");
                                    self.profileLabel.text = profileText;
                                }
                            }
                        }
                        
                        
                    }
                }
            }
            
            
        }else{ //로그인 안되었을때
            loginOn.isHidden = true;
            loginOff.isHidden = false;
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let name = Notification.Name("loginInit");
        NotificationCenter.default.addObserver(self, selector: #selector(loginInit), name: name, object: nil)
        
        
        self.pin_type = AppDelegate.homePinType;
        
        if ( self.pin_type == enum_pin_type.chulsa.rawValue ){
            //print("chulsa");
            self.menuIcon[0].image = UIImage(named: "map_on");
            self.menuLabel[0].textColor = UIColor(red: 83/255.0, green: 149/255.0, blue: 233/255.0, alpha: 1.0);
        }else{
            //print("food");
            self.menuIcon[1].image = UIImage(named: "map_on");
            self.menuLabel[1].textColor = UIColor(red: 83/255.0, green: 149/255.0, blue: 233/255.0, alpha: 1.0);
        }
        
        
        
        
        //핀 카운트 체크
        Common.pinCount(pin_type: enum_pin_type.chulsa.rawValue ){ (result:String) in
            let count = result;
            DispatchQueue.main.async() {
                self.menuLabel[0].text = self.menuLabel[0].text! + " (" + count + ")";
            }
        }//Common
        
        //핀 카운트 체크
        Common.pinCount(pin_type: enum_pin_type.food.rawValue ){ (result:String) in
            let count = result;
            DispatchQueue.main.async() {
                self.menuLabel[1].text = self.menuLabel[1].text! + " (" + count + ")";
            }
        }//Common
        
        
        
        loginInit();
        
        
        DispatchQueue.main.async() {
            self.getPolicy();
        }
        
    }
    
    func getPolicy(){
        
        

        
        //정책 조회
        let key : String = "nuri";
        let param : String = "key="+key;
        
        
        Ajax.forecast(withUrl: AppDelegate.serverUrl + "/chulsago/get_policy.php", withParam: param) { (results:[[String:Any]]) in
            
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
//                    print("@@@ : \(result)");
                    //print(result["seq"]!)
                    let hot_like : String = String(describing: result["hot_like"]!)
                    let hot_date_day : String = String(describing: result["hot_date_day"]!)
                    
                    
                    self.hotLike.text = hot_like;
                    
                    if let hot_date_day_comma = self.formatNumberString(hot_date_day) {
//                        print(hot_date_day_comma)  // 출력: "1,234,567"
                        
                        let currentLanguage = Locale.current.languageCode ?? "en"  // 기본값 en (영어)
                                
                        if currentLanguage == "ko" {
                            print("앱 언어가 한국어입니다.")
                            self.newDate.text = "최근 \(hot_date_day_comma)일";
                        } else {
                            print("앱 언어가 한국어가 아닙니다. 현재: \(currentLanguage)")
                            self.newDate.text = "Last \(hot_date_day_comma) days";
                            
                        }
                        
                    }
                }
            }
            
        }//Ajax
        
    }
    
    //콤마적용
    func formatNumberString(_ input: String) -> String? {
        // 1. 문자열을 숫자형으로 변환 (Int로 가정, 소수점 있으면 Double 사용)
        guard let number = Int(input) else {
            print("유효하지 않은 숫자 문자열입니다.")
            return nil
        }
        
        // 2. NumberFormatter로 세 자리마다 콤마 적용
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal  // 세 자리 콤마 스타일
        formatter.locale = Locale(identifier: "ko_KR")  // 한국어 로케일 (필요 시 변경)
        
        // 숫자를 포맷팅된 문자열로 변환
        guard let formattedString = formatter.string(from: NSNumber(value: number)) else {
            print("포맷팅 실패")
            return nil
        }
        
        return formattedString
    }
    
    // MARK: - Status Bar Management
    override var prefersStatusBarHidden: Bool {
        return true  // Hide status bar for menu
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated);
        
        
        // 상태바 숨김 업데이트 (Private API 대신 공식 API 사용)
        self.setNeedsStatusBarAppearanceUpdate()
        
        loginInit();
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        
        if segue.identifier == "showMyPage" {
            let loginSesseion = UserDefaults.standard.object(forKey: "loginSesstion") as? Int ?? -1;
            let send_seq : String = String(loginSesseion);
            let nav = segue.destination as! UINavigationController;
            let vc = nav.viewControllers[0] as! MyPageViewController;
            vc.get_seq = send_seq;
        }
        
        
    }
    
    
    
}

extension UIView {
    func snapshot() -> UIImage {
        UIGraphicsBeginImageContextWithOptions(bounds.size, false, UIScreen.main.scale)
        drawHierarchy(in: bounds, afterScreenUpdates: true)
        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return result!
    }
}

extension UIWindow {
    func replaceRootViewControllerWith(_ replacementController: UIViewController, animated: Bool, completion: (() -> Void)?) {
        let snapshotImageView = UIImageView(image: self.snapshot())
        self.addSubview(snapshotImageView)
        
        let dismissCompletion = { () -> Void in // dismiss all modal view controllers
            self.rootViewController = replacementController
            self.bringSubviewToFront(snapshotImageView)
            if animated {
                UIView.animate(withDuration: 0.3, animations: { () -> Void in
                    snapshotImageView.alpha = 0
                }, completion: { (success) -> Void in
                    snapshotImageView.removeFromSuperview()
                    completion?()
                })
            }
            else {
                snapshotImageView.removeFromSuperview()
                completion?()
            }
        }
        if self.rootViewController!.presentedViewController != nil {
            self.rootViewController!.dismiss(animated: false, completion: dismissCompletion)
        }
        else {
            dismissCompletion()
        }
    }
}
