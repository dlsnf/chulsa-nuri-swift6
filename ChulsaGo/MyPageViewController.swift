//
//  MyPageViewController.swift
//  LovePet
//
//  Created by Nu-Ri Lee on 2017. 5. 29..
//  Updated by ChatGPT (GPT-5) on 2025. 10. 10.
//  Swift 6 Concurrency / Sendable Safe Refactor.
//

import UIKit

// MARK: - URLSession Delegate 전용 클래스
final class MyPageSessionDelegate: NSObject, URLSessionTaskDelegate, URLSessionDataDelegate {

    weak var parent: MyPageViewController?

    init(parent: MyPageViewController) {
        self.parent = parent
    }

    nonisolated func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let parent = parent else { return }
        Task { @MainActor in
            if let error = error {
                let alertController = UIAlertController(title: "Alert", message: error.localizedDescription, preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: "OK", style: .default))
                parent.present(alertController, animated: true)
            } else {
                print("✅ Upload task completed successfully.")
            }
        }
    }

    nonisolated func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse,
                                completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        print("didReceive response: \(response)")
        completionHandler(.allow)
    }

    nonisolated func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        print("didReceive data: \(data.count) bytes")
    }

    nonisolated func urlSession(_ session: URLSession, task: URLSessionTask,
                                didSendBodyData bytesSent: Int64,
                                totalBytesSent: Int64,
                                totalBytesExpectedToSend: Int64) {
        let uploadProgress: Float = Float(totalBytesSent) / Float(totalBytesExpectedToSend)
        print("Upload progress: \(uploadProgress * 100)%")
    }
}

// MARK: - Main ViewController
@MainActor
class MyPageViewController: UIViewController,
                            UIImagePickerControllerDelegate,
                            UINavigationControllerDelegate,
                            URLSessionDelegate,
                            UISearchBarDelegate {

    // MARK: - Properties
    var get_seq: String = "0"
    var myPage: Bool = true
    var othersPage: Bool = false

    @IBOutlet weak var tempImageView: UIImageView!
    @IBOutlet weak var stackProfileView: UIStackView!
    @IBOutlet weak var profileView: ProfileView!
    @IBOutlet weak var profileImge: UIImageView!
    @IBOutlet weak var nickNameLabel: UILabel!
    @IBOutlet weak var ratingLabel: UILabel!
    @IBOutlet weak var nickNameLabelInfo: UILabel!
    @IBOutlet weak var ratingLabelInfo: UILabel!
    @IBOutlet weak var stackNickNameView: UIView!
    @IBOutlet weak var logoutView: UIView!
    @IBOutlet weak var btnLogout: RoundButton!
    @IBOutlet weak var blockSettingView: UIView!

    private var sessionDelegate: MyPageSessionDelegate?

    // MARK: - View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()

        // Gesture to dismiss
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(draggedView(_:)))
        self.view.addGestureRecognizer(panGesture)

        let loginSession = UserDefaults.standard.object(forKey: "loginSesstion") as? Int ?? -1
        if String(loginSession) != self.get_seq {
            self.myPage = false
            if loginSession != -1 {
                self.othersPage = true
            } else {
                self.othersPage = false
            }
        }

        if myPage {
            let profileViewTap = MyTapGestureRecognizer(target: self, action: #selector(profileViewTap(recognizer:)))
            self.profileView.addGestureRecognizer(profileViewTap)

            let stackNickNameViewTap = MyTapGestureRecognizer(target: self, action: #selector(nickNameViewTap(recognizer:)))
            self.stackNickNameView.addGestureRecognizer(stackNickNameViewTap)

            self.blockSettingView.isHidden = false
        } else if othersPage {
            self.btnLogout.setTitle(NSLocalizedString("user block", comment: "user block"), for: .normal)
        } else {
            self.logoutView.isHidden = true
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // 상태바 표시 업데이트 (Private API 대신 공식 API 사용)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.setNeedsStatusBarAppearanceUpdate()
        }
        loadProfile(user_seq: self.get_seq)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
            
        if segue.identifier == "changeNickName" {
            let vc = segue.destination as! ChangeNickNameViewController;
            vc.get_seq = self.get_seq;
            vc.get_nickName = self.nickNameLabel.text!;
        }
        
        if segue.identifier == "showMyPin" {
            let vc = segue.destination as! MyPinViewController;
            vc.user_seq = self.get_seq;
        }
        
        
        
    }

    // MARK: - Status Bar Management
    override var prefersStatusBarHidden: Bool {
        return false  // Always show status bar
    }

    // MARK: - Rotation
    override var shouldAutorotate: Bool { true }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        UIDevice.current.userInterfaceIdiom == .phone ? [.portrait] : [.all]
    }

    // MARK: - Logout / Block Button
    @IBAction func btnLogoutPress(_ sender: Any) {
        if self.othersPage {
            self.userBlock()
        } else {
            self.logOut()
        }
    }

    // MARK: - View Dismiss
    @IBAction func leftBarButtonPress(_ sender: Any) {
        self.dismissView()
    }

    func dismissView() {
        NotificationCenter.default.post(name: Notification.Name("loginInit"), object: nil)
        NotificationCenter.default.post(name: Notification.Name("statusBarHide"), object: nil)
        self.dismiss(animated: true)
    }

    // MARK: - Drag to Dismiss Gesture
    @objc func draggedView(_ recognizer: UIPanGestureRecognizer) {
        let translation = recognizer.translation(in: view)
        if translation.y > 0 {
            self.navigationController?.view.frame.origin.y = translation.y
            let percent: CGFloat = max(0, 1 - (translation.y / 1.7) / 100)
            self.navigationController?.view.superview?.backgroundColor = UIColor(white: 1, alpha: percent)
        }

        if recognizer.state == .ended {
            if translation.y >= 170 {
                self.dismissView()
            } else {
                UIView.animate(withDuration: 0.3) {
                    self.navigationController?.view.frame.origin = .zero
                }
            }
        }
    }

    // MARK: - Image Picker
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        if let image = info[.originalImage] as? UIImage {
            self.tempImageView.image = image
            self.myImageUploadRequest(image: image)
            self.dismiss(animated: true)
        }
    }

    // MARK: - Upload Function
    func myImageUploadRequest(image: UIImage) {
        let myUrl = URL(string: AppDelegate.serverUrl + "/chulsago/upload_img_profile.php")!
        var request = URLRequest(url: myUrl)
        request.httpMethod = "POST"

        let loginSession = UserDefaults.standard.object(forKey: "loginSesstion") as? Int ?? -1
        let params = ["key": "nuri", "user_seq": String(loginSession)]
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        guard let imageData = image.jpegData(compressionQuality: 1) else { return }
        request.httpBody = createBody(parameters: params, filePathKey: "file", imageDataKey: imageData, boundary: boundary)

        sessionDelegate = MyPageSessionDelegate(parent: self)
        let session = URLSession(configuration: .default, delegate: sessionDelegate, delegateQueue: .main)
        let task = session.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Upload error: \(error.localizedDescription)")
                return
            }
            guard let data = data else { return }
            do {
                if let array = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                    for result in array {
                        print("Upload result: \(result)")
                    }
                    Task { @MainActor in
                        self.loadProfile(user_seq: self.get_seq)
                    }
                }
            } catch {
                print("Upload parse error: \(error)")
            }
        }
        task.resume()
    }

    func createBody(parameters: [String: String], filePathKey: String, imageDataKey: Data, boundary: String) -> Data {
        var body = Data()
        for (key, value) in parameters {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(value)\r\n".data(using: .utf8)!)
        }
        let filename = "user-profile.jpg"
        let mimetype = "image/jpg"
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"\(filePathKey)\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mimetype)\r\n\r\n".data(using: .utf8)!)
        body.append(imageDataKey)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        return body
    }

    // MARK: - Load Profile
    func loadProfile(user_seq: String) {
        let param = "key=nuri&seq=\(user_seq)"
        Ajax.forecast(withUrl: AppDelegate.serverUrl + "/chulsago/user_select.php", withParam: param) { results in
            for result in results {
                if let error = result["error"] as? String {
                    let alert = UIAlertController(title: NSLocalizedString("waiting", comment: ""), message: error, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: NSLocalizedString("done", comment: ""), style: .cancel))
                    self.present(alert, animated: true)
                } else {
                    //let seq : String = (result["seq"] as? String)!;
                    let name : String = (result["name"] as? String)!;
                    let point : String = (result["point"] as? String)!;
                    let thumbnail_image : String = (result["thumbnail_image"] as? String)!;
                    
                    let point2 : Int = Int(point)!;
                    
                    //레이아웃 바꿀때 충돌 방지
                    DispatchQueue.main.async() {
                        
                        //프로필 사진 추가
                        if thumbnail_image != ""{
                            self.profileImge.contentMode = UIView.ContentMode.scaleAspectFill
                            self.profileImge.downloadAndResizeImageFrom(thumbnail_image, contentMode: .scaleAspectFill, newWidth: 400)
                        }else{
                            self.profileImge.contentMode = UIView.ContentMode.center
                            self.profileImge.image = UIImage(named: "nonProfile");
                        }
                        
                        //프로필 텍스트 추가
                        if name != ""{
                            let profileText = name;
                            self.nickNameLabel.text = profileText;
                            self.navigationItem.title = profileText;
                        }else{
                            let profileText = "NULL";
                            self.nickNameLabel.text = profileText;
                            self.navigationItem.title = profileText;
                        }
                        
                        
                        
                        //등급 가져오기
                        let rating: String = RatingClass.rating(point: point2) + " (P. " + String(point2) + ")";
                        self.ratingLabel.text = rating;
                        
                        
                    }
                }
            }
        }
    }

    // MARK: - User Block
    func userBlock() {
        let alert = UIAlertController(title: NSLocalizedString("user block", comment: ""), message: NSLocalizedString("are you sure you want to block this user?", comment: ""), preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("cancel", comment: ""), style: .cancel))
        alert.addAction(UIAlertAction(title: NSLocalizedString("ok", comment: ""), style: .default) { _ in
            
            let loginSession = UserDefaults.standard.object(forKey: "loginSesstion") as? Int ?? -1
            if loginSession == -1 {
                
                let confirm = UIAlertController(title: NSLocalizedString("done", comment: ""), message: NSLocalizedString("fail blocked.", comment: ""), preferredStyle: .alert)
                confirm.addAction(UIAlertAction(title: "OK", style: .default))
                
                return
            }
            let param = "key=nuri&user_seq=\(loginSession)&block_user_seq=\(self.get_seq)"
            Ajax.forecast(withUrl: AppDelegate.serverUrl + "/chulsago/user_block.php", withParam: param) { result in
                print("Block result: \(result)")
                DispatchQueue.main.async {
                    let confirm = UIAlertController(title: NSLocalizedString("done", comment: ""), message: NSLocalizedString("user has been blocked.", comment: ""), preferredStyle: .alert)
                    confirm.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(confirm, animated: true)
                }
            }
        })
        self.present(alert, animated: true)
    }

    // MARK: - Logout
    func logOut() {
        let alert = UIAlertController(title: NSLocalizedString("logout", comment: ""), message: NSLocalizedString("do you really want to logout?", comment: ""), preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("cancel", comment: ""), style: .cancel))
        alert.addAction(UIAlertAction(title: NSLocalizedString("ok", comment: ""), style: .default) { _ in
            UserDefaults.standard.removeObject(forKey: "loginSesstion")
            NotificationCenter.default.post(name: Notification.Name("loginInit"), object: nil)
            self.dismissView()
        })
        self.present(alert, animated: true)
    }

    // MARK: - Nickname Tap
    @objc func nickNameViewTap(recognizer: UITapGestureRecognizer) {
        let alert = UIAlertController(title: NSLocalizedString("change nickname", comment: ""), message: nil, preferredStyle: .alert)
        alert.addTextField { textField in
            textField.placeholder = self.nickNameLabel.text
        }
        alert.addAction(UIAlertAction(title: NSLocalizedString("cancel", comment: ""), style: .cancel))
        alert.addAction(UIAlertAction(title: NSLocalizedString("ok", comment: ""), style: .default) { _ in
            guard let newName = alert.textFields?.first?.text, !newName.isEmpty else { return }
            let param = "key=nuri&name=\(newName)"
            Ajax.forecast(withUrl: AppDelegate.serverUrl + "/chulsago/user_name_update.php", withParam: param) { result in
                print("Nickname update result: \(result)")
                DispatchQueue.main.async {
                    self.nickNameLabel.text = newName
                    self.navigationItem.title = newName
                }
            }
        })
        self.present(alert, animated: true)
    }

    // MARK: - Profile Image Tap
    @objc func profileViewTap(recognizer: UITapGestureRecognizer) {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.allowsEditing = false
        picker.sourceType = .photoLibrary
        self.present(picker, animated: true)
    }
}
