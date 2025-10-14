//
//  addPinMapViewController.swift
//  ChulsaGo
//
//  Created by Nu-Ri Lee on 2017. 6. 18..
//  Updated for Swift 6 Concurrency & API changes by ChatGPT on 2025.10.10
//

import UIKit
import MapKit

// MARK: - Protocol
protocol HandleMapSearchAddPin: AnyObject {
    func dropPinZoomIn(_ placemark: MKPlacemark)
}

// MARK: - URLSession Delegate (업로드 전용, 별도 클래스)
final class AddPinUploadSessionDelegate: NSObject, URLSessionTaskDelegate, URLSessionDataDelegate {
    weak var controller: addPinMapViewController?

    init(controller: addPinMapViewController) {
        self.controller = controller
    }

    nonisolated func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let controller = controller else { return }
        Task { @MainActor in
            if let error = error {
                let alert = UIAlertController(title: "Alert", message: error.localizedDescription, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                controller.present(alert, animated: true)
            } else {
                // 성공 처리(필요 시 UI 갱신)
                // 예: controller.uploadEffectView.isHidden = true
            }
        }
    }

    nonisolated func urlSession(_ session: URLSession, task: URLSessionTask,
                                didSendBodyData bytesSent: Int64,
                                totalBytesSent: Int64,
                                totalBytesExpectedToSend: Int64) {
        guard let controller = controller else { return }
        guard totalBytesExpectedToSend > 0 else { return }
        let progress = Float(totalBytesSent) / Float(totalBytesExpectedToSend)
        Task { @MainActor in
            controller.uploadPregressView.progress = progress
            controller.uploadPregressLabel.text = "\(Int(progress * 100)) %"
        }
    }

    nonisolated func urlSession(_ session: URLSession,
                                dataTask: URLSessionDataTask,
                                didReceive response: URLResponse,
                                completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        print("didReceive response: \(response)")
        completionHandler(.allow)
    }

    nonisolated func urlSession(_ session: URLSession,
                                dataTask: URLSessionDataTask,
                                didReceive data: Data) {
        print("didReceive data: \(data.count) bytes")
    }
}

// MARK: - Main ViewController
@MainActor
class addPinMapViewController: UIViewController,
                               CLLocationManagerDelegate,
                               MKMapViewDelegate,
                               UITextViewDelegate,
                               UIImagePickerControllerDelegate,
                               UINavigationControllerDelegate,
                               UISearchBarDelegate {

    // MARK: - Map search
    var selectedPin: MKPlacemark?
    var resultSearchController: UISearchController!

    // MARK: - IBOutlets
    @IBOutlet weak var mapView: MKMapView!

    @IBOutlet weak var myLocationView: UIView!
    @IBOutlet weak var myLocationImage: UIImageView!
    @IBOutlet weak var locationLabelView: UIView!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var pinHere: UIImageView!
    @IBOutlet weak var mapViewConstraintBottom: NSLayoutConstraint!

    @IBOutlet weak var step2View: UIView!
    @IBOutlet weak var step2AddressView: UIView!
    @IBOutlet weak var step2Address: UILabel!
    @IBOutlet weak var step2InfoAddress: UILabel!

    @IBOutlet weak var step2SelectImageView: UIView!
    @IBOutlet weak var step2InfoSelectImage: UILabel!
    @IBOutlet weak var step2SelectImage: UIImageView!
    @IBOutlet weak var step2ImageCancel: RoundButton!
    @IBOutlet weak var step2TextView: UITextView!
    @IBOutlet weak var step2BlackBlur: UIVisualEffectView!
    @IBOutlet weak var step2SelectImageBtn: UIButton!

    @IBOutlet weak var step2BorderBottom1: UIView!
    @IBOutlet weak var step2BorderBottom2: UIView!

    @IBOutlet weak var uploadEffectView: UIVisualEffectView!
    @IBOutlet weak var uploadPregressView: UIProgressView!
    @IBOutlet weak var uploadPregressLabel: UILabel!

    @IBOutlet weak var btnSearch: UIView!

    // MARK: - State vars
    var coreLocationManger = CLLocationManager()
    var locationManager2: LocationManager!
    var myLocationBool: Bool = false

    var GlobalMyLatitude: Double!
    var GlobalMyLongitude: Double!

    var GlobalStep: Int!
    var editingText: Bool = false
    var step2ImageBool: Bool = false
    var textViewEmpty: Bool = true
    var pin_type = String()

    // upload session delegate holder
    private var uploadDelegate: AddPinUploadSessionDelegate?

    // MARK: - Actions
    @IBAction func step2SelectImagBtnClick(_ sender: Any) {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .photoLibrary
        present(picker, animated: true)
    }

    @IBAction func step2ImageCancelBtn(_ sender: Any) {
        step2SelectImage.image = nil
        btnImageCancel()
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        setupSearchController()
        GlobalStep = 1
        uploadEffectView.isHidden = true

        // setup UI state
        step()
        step2BlackBlur.isHidden = true
        step2BlackBlur.alpha = 0

        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)),
                                               name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)),
                                               name: UIResponder.keyboardWillHideNotification, object: nil)

        step2TextView.delegate = self
        step2TextView.text = NSLocalizedString("input body", comment: "input body")
        step2TextView.textColor = .lightGray

        // shadow for locationLabelView
        locationLabelView.layer.cornerRadius = 4
        locationLabelView.clipsToBounds = false
        locationLabelView.layer.shadowColor = UIColor.black.cgColor
        locationLabelView.layer.shadowOpacity = 0.15
        locationLabelView.layer.shadowOffset = CGSize.zero
        locationLabelView.layer.shadowRadius = 2.5

        // gestures
        let myLocationTap = UITapGestureRecognizer(target: self, action: #selector(myLocationToggle))
        myLocationView.addGestureRecognizer(myLocationTap)

        let blackBlurTap = UITapGestureRecognizer(target: self, action: #selector(blackBlurTap))
        step2BlackBlur.addGestureRecognizer(blackBlurTap)

        let btnSearchViewTap = UITapGestureRecognizer(target: self, action: #selector(btnSearchPress))
        btnSearch.addGestureRecognizer(btnSearchViewTap)

        myLocation()
    }

    // MARK: - Search controller setup
    private func setupSearchController() {
        guard let locationSearchTable = storyboard?.instantiateViewController(withIdentifier: "LocationSearchTable_2") as? LocationSearchTable_2 else { return }
        let controller = UISearchController(searchResultsController: locationSearchTable)
        controller.searchResultsUpdater = locationSearchTable
        controller.hidesNavigationBarDuringPresentation = true
        controller.dimsBackgroundDuringPresentation = true
        definesPresentationContext = true
        controller.searchBar.tag = 0
        controller.searchBar.delegate = self

        locationSearchTable.mapView = self.mapView
        locationSearchTable.handleMapSearchDelegate = self

        // search bar appearance tweaks (KVC - keep guarded)
        if let textField = controller.searchBar.value(forKey: "searchField") as? UITextField {
            (textField.value(forKey: "placeholderLabel") as? UILabel)?.textColor = .lightGray
            textField.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.3)
            textField.borderStyle = .roundedRect
            if let glassIcon = textField.leftView as? UIImageView {
                glassIcon.image = glassIcon.image?.withRenderingMode(.alwaysTemplate)
                glassIcon.tintColor = .lightGray
            }
        }

        resultSearchController = controller
    }

    // MARK: - Gesture handlers
    @objc func btnSearchPress() {
        present(resultSearchController, animated: true)
    }

    @objc func blackBlurTap() {
        if editingText {
            step2TextView.resignFirstResponder()
        }
    }

    @objc func textViewDone() {
        step2TextView.resignFirstResponder()
    }

    // MARK: - UIImagePickerControllerDelegate
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        step2SelectImage.image = info[.originalImage] as? UIImage
        dismiss(animated: true)
        btnImageCancel()
    }

    // MARK: - Upload
    func myImageUploadRequest() {
        guard let url = URL(string: AppDelegate.serverUrl + "/chulsago/upload_img.php") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let loginSession = UserDefaults.standard.object(forKey: "loginSesstion") as? Int ?? -1
        let key = "nuri"
        let seq = String(loginSession)
        let bodyText = textViewEmpty ? "" : (step2TextView.text ?? "")
        let latitude = String(GlobalMyLatitude ?? 0.0)
        let longitude = String(GlobalMyLongitude ?? 0.0)
        let address = step2Address.text ?? ""
        let param = [
            "key": key,
            "pin_type": pin_type,
            "seq": seq,
            "latitude": latitude,
            "longitude": longitude,
            "address": address,
            "body": bodyText
        ]

        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        guard let image = step2SelectImage.image, let imageData = image.jpegData(compressionQuality: 1.0) else { return }

        request.httpBody = createBodyWithParameters(parameters: param, filePathKey: "file", imageDataKey: imageData, boundary: boundary)

        // 분리된 delegate 사용
        uploadDelegate = AddPinUploadSessionDelegate(controller: self)
        let configuration = URLSessionConfiguration.default
        let session = URLSession(configuration: configuration, delegate: uploadDelegate, delegateQueue: .main)

        let task = session.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            if let error = error {
                print("Upload error:", error.localizedDescription)
                Task { @MainActor in
                    let alert = UIAlertController(title: NSLocalizedString("waiting", comment: ""), message: error.localizedDescription, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: NSLocalizedString("done", comment: ""), style: .cancel))
                    self.present(alert, animated: true)
                }
                return
            }

            guard let data = data else { return }
            do {
                if let array = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                    for result in array {
                        print("Upload response:", result)
                    }

                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                        UserDefaults.standard.set(self.GlobalMyLatitude, forKey: "latitude")
                        UserDefaults.standard.set(self.GlobalMyLongitude, forKey: "longitude")
                        NotificationCenter.default.post(name: Notification.Name("mapViewMove"), object: nil)
                    }

                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        NotificationCenter.default.post(name: Notification.Name("pinInit"), object: nil)
                    }

                    Task { @MainActor in
                        self.presentingViewController?.dismiss(animated: true)
                    }
                } else {
                    // 서버가 예상한 형태가 아닌 경우
                    let respStr = String(data: data, encoding: .utf8) ?? "no response"
                    Task { @MainActor in
                        let alert = UIAlertController(title: NSLocalizedString("waiting", comment: ""), message: respStr, preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: NSLocalizedString("done", comment: ""), style: .cancel))
                        self.present(alert, animated: true)
                    }
                }
            } catch {
                Task { @MainActor in
                    let alert = UIAlertController(title: NSLocalizedString("waiting", comment: ""), message: error.localizedDescription, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: NSLocalizedString("done", comment: ""), style: .cancel))
                    self.present(alert, animated: true)
                }
            }
        }
        task.resume()
    }

    private func createBodyWithParameters(parameters: [String: String]?,
                                          filePathKey: String,
                                          imageDataKey: Data,
                                          boundary: String) -> Data {
        var body = Data()

        if let parameters = parameters {
            for (key, value) in parameters {
                body.append("--\(boundary)\r\n".data(using: .utf8)!)
                body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: .utf8)!)
                body.append("\(value)\r\n".data(using: .utf8)!)
            }
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

    // MARK: - Text view delegate
    func textViewDidBeginEditing(_ textView: UITextView) {
        editingText = true
        navigationItem.title = NSLocalizedString("explanation", comment: "explanation")
        step2BlackBlur.isHidden = false
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 2, initialSpringVelocity: 0, options: .curveEaseInOut) {
            self.step2BlackBlur.alpha = 0.7
        }

        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: NSLocalizedString("done", comment: "done"),
                                                            style: .plain, target: self, action: #selector(textViewDone))

        if step2TextView.textColor == .lightGray {
            step2TextView.text = ""
            step2TextView.textColor = .black
        }
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        navigationItem.title = NSLocalizedString("select image", comment: "select image")
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 2, initialSpringVelocity: 0, options: .curveEaseInOut) {
            self.step2BlackBlur.alpha = 0
        } completion: { _ in
            self.step2BlackBlur.isHidden = true
            self.editingText = false
        }

        let backImage = UIImage(named: "btn_back")
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: backImage, style: .plain, target: self, action: #selector(btnBack))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: NSLocalizedString("comfirm", comment: "comfirm"),
                                                            style: .plain, target: self, action: #selector(btnNext))

        if step2TextView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            textViewEmpty = true
            step2TextView.text = NSLocalizedString("input body", comment: "input body")
            step2TextView.textColor = .lightGray
        } else {
            textViewEmpty = false
        }
    }

    // MARK: - Keyboard
    @objc func keyboardWillShow(notification: Notification) {
        if let frame = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            if view.frame.origin.y == 0 {
                if UIDevice.current.userInterfaceIdiom == .phone {
                    view.frame.origin.y -= frame.height / 2
                }
            }
        }
    }

    @objc func keyboardWillHide(notification: Notification) {
        if view.frame.origin.y != 0 {
            view.frame.origin.y = 0
        }
    }

    // MARK: - Map compact/expand helpers
    func shortMap() {
        let center = mapView.centerCoordinate
        GlobalMyLatitude = center.latitude
        GlobalMyLongitude = center.longitude

        // remove previous "location" annotations
        for annotation in mapView.annotations {
            if let a = annotation as? CustomPointAnnotation, a.type == "location" {
                mapView.removeAnnotation(a)
            }
        }

        mapView.isUserInteractionEnabled = false

        mapViewConstraintBottom.isActive = false
        // add a fixed height constraint
        let heightConstraint = mapView.heightAnchor.constraint(equalToConstant: 140)
        heightConstraint.isActive = true

        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 2, initialSpringVelocity: 0, options: .curveEaseInOut) {
            self.view.layoutIfNeeded()
            self.locationLabelView.alpha = 0
            self.myLocationView.alpha = 0
            self.btnSearch.alpha = 0
        } completion: { _ in
            self.locationLabelView.isHidden = true
            self.myLocationView.isHidden = true
            self.btnSearch.isHidden = true
        }
    }

    func longMap() {
        mapView.isUserInteractionEnabled = true
        locationLabelView.isHidden = false
        myLocationView.isHidden = false
        btnSearch.isHidden = false

        // remove the height constraint if any (we don't track the specific constraint object here)
        mapView.heightAnchor.constraint(equalToConstant: 140).isActive = false
        mapViewConstraintBottom.isActive = true

        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 2, initialSpringVelocity: 0, options: .curveEaseInOut) {
            self.view.layoutIfNeeded()
            self.locationLabelView.alpha = 1
            self.myLocationView.alpha = 1
            self.btnSearch.alpha = 1
        }
    }

    // MARK: - Navigation step control
    func step() {
        let transition = CATransition()
        transition.duration = 0.2
        transition.type = CATransitionType.fade
        navigationController?.navigationBar.layer.add(transition, forKey: "fadeText")

        switch GlobalStep {
        case 1:
            navigationItem.title = "\(NSLocalizedString(pin_type, comment: "pin_type")) \(NSLocalizedString("checkin", comment: "checkin"))"
            navigationItem.leftBarButtonItem = UIBarButtonItem(title: NSLocalizedString("cancel", comment: "cancel"),
                                                               style: .plain, target: self, action: #selector(btnBack))
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: NSLocalizedString("next", comment: "next"),
                                                                style: .plain, target: self, action: #selector(btnNext))
            step2View.isHidden = true

        case 2:
            navigationItem.title = NSLocalizedString("select image", comment: "select image")
            let backImage = UIImage(named: "btn_back")
            navigationItem.leftBarButtonItem = UIBarButtonItem(image: backImage, style: .plain, target: self, action: #selector(btnBack))
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: NSLocalizedString("comfirm", comment: "comfirm"),
                                                                style: .plain, target: self, action: #selector(btnNext))

            // reverse geocode current coordinates
            let myLocation = CLLocation(latitude: GlobalMyLatitude ?? 0.0, longitude: GlobalMyLongitude ?? 0.0)
            locationManager2.reverseGeocodeLocationWithCoordinates(myLocation) { reverseGecodeInfo, placemark, error in
                if error == nil {
                    let address = reverseGecodeInfo?.object(forKey: "formattedAddress") as? String ?? "null"
                    Task { @MainActor in
                        self.step2Address.text = address
                    }
                }
            }

            step2View.isHidden = false
            step2View.alpha = 0
            UIView.animate(withDuration: 0.2) {
                self.step2View.alpha = 1
            }

            var delayCounter = 1

            step2BorderBottom1.alpha = 0
            step2BorderBottom2.alpha = 0
            step2AddressView.backgroundColor = .clear
            step2SelectImageView.backgroundColor = .clear

            UIView.animate(withDuration: 0.5, delay: 0.2) {
                self.step2AddressView.backgroundColor = .white
                self.step2SelectImageView.backgroundColor = .white
                self.step2BorderBottom1.alpha = 1
                self.step2BorderBottom2.alpha = 1
            }

            let uiLabelArray: [UILabel] = [step2InfoAddress, step2Address, step2InfoSelectImage]
            uiLabelArray.forEach {
                $0.alpha = 0
                $0.transform = CGAffineTransform(translationX: 0, y: 20)
            }
            for uiLabel in uiLabelArray {
                UIView.animate(withDuration: 0.2, delay: Double(delayCounter) * 0.05) {
                    uiLabel.alpha = 1
                    uiLabel.transform = .identity
                }
                delayCounter += 1
            }

            let uiImageViewArray: [UIImageView] = [step2SelectImage]
            uiImageViewArray.forEach {
                $0.alpha = 0
                $0.transform = CGAffineTransform(translationX: 0, y: 20)
            }

            step2SelectImageBtn.alpha = 0
            step2SelectImageBtn.transform = CGAffineTransform(translationX: 0, y: 20)
            step2ImageCancel.alpha = 0
            step2ImageCancel.transform = CGAffineTransform(translationX: 0, y: 20)

            for uiImageView in uiImageViewArray {
                UIView.animate(withDuration: 0.2, delay: Double(delayCounter) * 0.05) {
                    uiImageView.alpha = 1
                    uiImageView.transform = .identity
                    self.step2SelectImageBtn.alpha = 1
                    self.step2SelectImageBtn.transform = .identity
                    self.step2ImageCancel.alpha = 1
                    self.step2ImageCancel.transform = .identity
                }
                delayCounter += 1
            }

            let uiTextViewArray: [UITextView] = [step2TextView]
            uiTextViewArray.forEach { $0.alpha = 0 }
            for uiTextView in uiTextViewArray {
                UIView.animate(withDuration: 0.5, delay: Double(delayCounter) * 0.05) {
                    uiTextView.alpha = 1
                }
                delayCounter += 1
            }

            btnImageCancel()

        default:
            break
        }
    }

    func btnImageCancel() {
        if step2SelectImage.image != nil {
            step2ImageCancel.isHidden = false
            step2SelectImageBtn.isHidden = true
        } else {
            step2ImageCancel.isHidden = true
            step2SelectImageBtn.isHidden = false
        }
    }

    // MARK: - Navigation actions
    @objc func btnBack() {
        switch GlobalStep {
        case 1:
            outAddPin()
        case 2:
            GlobalStep = 1
            longMap()
            step()
        default:
            break
        }
    }

    @objc func btnNext() {
        switch GlobalStep {
        case 1:
            GlobalStep = 2
            shortMap()
            step()
        case 2:
            // submit
            if step2SelectImage.image != nil {
                let transition = CATransition()
                transition.duration = 0.2
                transition.type = CATransitionType.fade
                navigationController?.navigationBar.layer.add(transition, forKey: "fadeText")

                navigationItem.title = NSLocalizedString("upload...", comment: "upload...")

                navigationItem.leftBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
                navigationItem.rightBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)

                myImageUploadRequest()
                uploadEffectView.isHidden = false
                UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .curveEaseInOut) {
                    self.uploadEffectView.alpha = 1
                }
            } else {
                let alert = UIAlertController(title: NSLocalizedString("alert", comment: "alert"),
                                              message: NSLocalizedString("select image.", comment: "select image."),
                                              preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: NSLocalizedString("done", comment: "done"), style: .default))
                present(alert, animated: true)
            }
        default:
            break
        }
    }

    func outAddPin() {
        let alert = UIAlertController(title: NSLocalizedString("alert", comment: "alert"),
                                      message: NSLocalizedString("cancel checkin", comment: "cancel checkin"),
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("cancel", comment: "cancel"), style: .cancel))
        alert.addAction(UIAlertAction(title: NSLocalizedString("exit", comment: "exit"), style: .destructive) { _ in
            self.presentingViewController?.dismiss(animated: true)
        })
        present(alert, animated: true)
    }

    // MARK: - Location helpers
    func myLocation() {
        if CLLocationManager.authorizationStatus() == .authorizedWhenInUse ||
            CLLocationManager.authorizationStatus() == .authorizedAlways {

            if let loc = coreLocationManger.location {
                GlobalMyLatitude = loc.coordinate.latitude
                GlobalMyLongitude = loc.coordinate.longitude

                let region = MKCoordinateRegion(center: loc.coordinate, span: MKCoordinateSpan(latitudeDelta: 0.3, longitudeDelta: 0.3))
                mapView.setRegion(region, animated: true)
                mapView.showsUserLocation = true
                mapView.userLocation.title = ""
            } else {
                let alert = UIAlertController(title: NSLocalizedString("not user location", comment: "not user location"),
                                              message: NSLocalizedString("not find user location", comment: "not find user location"),
                                              preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: NSLocalizedString("done", comment: "done"), style: .cancel))
                present(alert, animated: true)
            }
        } else {
            print("User location access not allowed")
        }
    }

    @objc func myLocationToggle() {
        if CLLocationManager.authorizationStatus() == .authorizedWhenInUse ||
            CLLocationManager.authorizationStatus() == .authorizedAlways {

            if myLocationBool {
                myLocationImage.image = UIImage(named: "myLocation_off")
                myLocationBool = false
                mapView.setUserTrackingMode(.none, animated: true)
            } else {
                mapView.setUserTrackingMode(.follow, animated: true)
                myLocationImage.image = UIImage(named: "myLocation_on")
                myLocationBool = true
            }
        } else {
            let alert = UIAlertController(title: NSLocalizedString("need user location", comment: "need user location"),
                                          message: NSLocalizedString("setting info location", comment: "setting info location"),
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("done", comment: "done"), style: .cancel))
            alert.addAction(UIAlertAction(title: NSLocalizedString("setting", comment: "setting"), style: .default) { _ in
                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsUrl)
                }
            })
            present(alert, animated: true)
        }
    }

    // MARK: - MKMapViewDelegate
    func mapView(_ mapView: MKMapView, didChange mode: MKUserTrackingMode, animated: Bool) {
        if myLocationBool {
            myLocationToggle()
        }
    }

    func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
        if GlobalStep == 1 {
            navigationItem.rightBarButtonItem?.isEnabled = false
        }
    }

    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        if GlobalStep == 1 {
            let center = mapView.centerCoordinate
            let numberOfPlaces = 5.0
            let multiplier = pow(10.0, numberOfPlaces)
            let latShort = round(center.latitude * multiplier) / multiplier
            let lonShort = round(center.longitude * multiplier) / multiplier
            locationLabel.text = "\(NSLocalizedString("latitude", comment: "latitude")): \(latShort)     \(NSLocalizedString("longitude", comment: "longitude")): \(lonShort)"
            navigationItem.rightBarButtonItem?.isEnabled = true
        }
    }
}

// MARK: - Map Search Handler
extension addPinMapViewController: @MainActor HandleMapSearchAddPin {
    func dropPinZoomIn(_ placemark: MKPlacemark) {
        selectedPin = placemark

        // remove previous "location" annotations
        for annotation in mapView.annotations {
            if let a = annotation as? CustomPointAnnotation, a.type == "location" {
                mapView.removeAnnotation(a)
            }
        }

        let annotation = CustomPointAnnotation()
        annotation.coordinate = placemark.coordinate
        annotation.title = placemark.name
        annotation.type = "location"
        if let city = placemark.locality, let state = placemark.administrativeArea {
            annotation.subtitle = "\(city) \(state)"
        }
        mapView.addAnnotation(annotation)

        let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        let region = MKCoordinateRegion(center: placemark.coordinate, span: span)
        mapView.setRegion(region, animated: true)
    }
}
