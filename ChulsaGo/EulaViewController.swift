//
//  EulaViewController.swift
//  ChulsaGo
//
//  Created by nuri Lee on 2017. 12. 18..
//  Copyright © 2017년 nuri lee. All rights reserved.
//

import UIKit
import SystemConfiguration
import KakaoSDKUser  // 2.x SDK
import KakaoSDKCommon  // KakaoSDK.shared를 사용하기 위해 추가

class EulaViewController: UIViewController {
    
    @IBAction func btnEulaPress(_ sender: UIBarButtonItem) {
        
        print("카톡 실행!!")
        
        // KakaoTalk 설치 확인 (없으면 웹 로그인 fallback)
        if (UserApi.isKakaoTalkLoginAvailable()) {
            // 2.x 방식으로 KakaoTalk 로그인
            UserApi.shared.loginWithKakaoTalk { (oauthToken, error) in
                if let error = error {
                    print("KakaoTalk login error: \(error.localizedDescription)")
                    // 에러 알림
                    let alert = UIAlertController(title: "로그인 실패", message: error.localizedDescription, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "확인", style: .default))
                    self.present(alert, animated: true)
                    return
                }
                
                print("KakaoTalk login success! Token: \(oauthToken?.accessToken ?? "nil")")
                self.getKaKaoValue()  // 성공 시 사용자 정보 가져오기
            }
        } else {
            print("KakaoTalk not available – fallback to web")
            // KakaoTalk 없으면 웹 로그인
            UserApi.shared.loginWithKakaoAccount { (oauthToken, error) in
                if let error = error {
                    print("Web login error: \(error.localizedDescription)")
                    return
                }
                print("Web login success!")
                self.getKaKaoValue()
            }
        }
    }
    
    func getKaKaoValue() {
        // 사용자 정보 가져오기 (2.x 방식)
        UserApi.shared.me { (user, error) in
            if let error = error {
                print("Me API error: \(error.localizedDescription)")
                return
            }
            
            guard let user = user else {
                print("User nil")
                return
            }
            
            let email = user.kakaoAccount?.email ?? ""
            let type = "kakao"
            let id = String(user.id ?? 0)  // UInt64 -> String 변환
            let name = user.kakaoAccount?.profile?.nickname ?? ""
            let profile_image = user.kakaoAccount?.profile?.profileImageUrl?.absoluteString ?? ""
            let thumbnail_image = user.kakaoAccount?.profile?.thumbnailImageUrl?.absoluteString ?? ""
            
            // 서버로 정보 전송 (기존 Ajax 로직)
            let param = "key=nuri&email=\(email)&name=\(name)&type=\(type)&id=\(id)&profile_image=\(profile_image)&thumbnail_image=\(thumbnail_image)"
            
            Ajax.forecast(withUrl: AppDelegate.serverUrl + "/chulsago/login.php", withParam: param) { (results: [[String: Any]]) in
                for result in results {
                    if let error = result["error"] {
                        print(error)
                        // 에러 알림
                    } else {
                        if let seq = result["seq"] as? String, let userSeq = Int(seq) {
                            UserDefaults.standard.set(userSeq, forKey: "loginSesstion")
                            // noti post 등 기존 로직 (e.g., dismiss or noti post)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3)
                            {
                                
                                                                
                                //로그인 초기화
                                let noti = Notification.init(name : Notification.Name(rawValue: "loginInit"));
                                NotificationCenter.default.post(noti);
                                
                                //infoLikeReload
                                let noti2 = Notification.init(name : Notification.Name(rawValue: "infoLikeReload"));
                                NotificationCenter.default.post(noti2);
                                
                                
                                //addPin에서 로그인페이지로 이동 되었을때 바로 addPin 페이지로 이동
                                let loginToAddPin = UserDefaults.standard.object(forKey: "loginToAddPin") as? Bool ?? false;
                                
                                if loginToAddPin {
                                    let noti2 = Notification.init(name : Notification.Name(rawValue: "loginToAddPin"));
                                    NotificationCenter.default.post(noti2);
                                }
                                
                            }
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                self.presentingViewController?.dismiss(animated: true)
                            }
                        }
                    }
                }
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // SDK 초기화 확인 (디버깅용)
        do {
            _ = try KakaoSDK.shared.appKey()
            print("Kakao SDK initialized successfully")
        } catch {
            print("Kakao SDK not initialized: \(error)")
        }
    }
}
