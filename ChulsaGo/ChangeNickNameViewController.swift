import UIKit

class ChangeNickNameViewController: UIViewController {

    var get_seq: String = "0"
    var get_nickName: String = ""

    @IBOutlet weak var nickNameTextField: UITextField!

    // ✅ Swift 최신 문법으로 수정
    func ltrim(_ str: String, _ chars: Set<Character>) -> String {
        if let index = str.firstIndex(where: { !chars.contains($0) }) {
            return String(str[index...])
        } else {
            return ""
        }
    }

    @IBAction func nickNameTextFeildChange(_ sender: Any) {

        let text = self.nickNameTextField.text?.stringTrim() ?? ""

        let text_length = text.count
        let text_max_length = 10
        let text_min_length = 3

        if text.isEmpty {
            self.navigationItem.rightBarButtonItem?.isEnabled = false
        } else if text == self.get_nickName {
            self.navigationItem.rightBarButtonItem?.isEnabled = false
        } else if text_length < text_min_length {
            self.navigationItem.rightBarButtonItem?.isEnabled = false
        } else {
            self.navigationItem.rightBarButtonItem?.isEnabled = true
        }
    }

    @IBAction func btnChangePress(_ sender: UIBarButtonItem) {
        self.changeNickName()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationItem.rightBarButtonItem?.isEnabled = false
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        print(get_seq)

        self.nickNameTextField.text = self.get_nickName
        self.nickNameTextField.becomeFirstResponder()
    }

    func changeNickName() {
        // ✅ 특수문자 제거
        let text = self.nickNameTextField.text?.replacingOccurrences(
            of: "[^\\wㄱ-ㅎ가-힣ㅏ-ㅣ]|[_]",
            with: "",
            options: .regularExpression
        )

        let text_length = text?.count ?? 0

        if text != self.nickNameTextField.text {
            let alertController = UIAlertController(
                title: NSLocalizedString("error", comment: "error"),
                message: NSLocalizedString("not character", comment: "not character"),
                preferredStyle: .alert
            )
            let okButton = UIAlertAction(
                title: NSLocalizedString("done", comment: "done"),
                style: .cancel
            )
            alertController.addAction(okButton)
            self.present(alertController, animated: true, completion: nil)

        } else if text_length > 10 {
            let alertController = UIAlertController(
                title: NSLocalizedString("error", comment: "error"),
                message: NSLocalizedString("nickname ten length", comment: "nickname ten length"),
                preferredStyle: .alert
            )
            let okButton = UIAlertAction(
                title: NSLocalizedString("done", comment: "done"),
                style: .cancel
            )
            alertController.addAction(okButton)
            self.present(alertController, animated: true, completion: nil)

        } else {
            print("실행")

            let key = "nuri"
            let user_seq = self.get_seq
            let nick_name = text ?? ""
            let param = "key=\(key)&user_seq=\(user_seq)&nick_name=\(nick_name)"

            Ajax.forecast(withUrl: AppDelegate.serverUrl + "/chulsago/change_nick_name.php", withParam: param) { (results: [[String: Any]]) in

                for result in results {
                    if let error = result["error"] {
                        print(error)

                        DispatchQueue.main.async {
                            let alertController = UIAlertController(
                                title: NSLocalizedString("waiting", comment: "waiting"),
                                message: "\(error)",
                                preferredStyle: .alert
                            )
                            let okButton = UIAlertAction(
                                title: NSLocalizedString("done", comment: "done"),
                                style: .cancel
                            )
                            alertController.addAction(okButton)
                            self.present(alertController, animated: true, completion: nil)
                        }

                    } else {
                        let status = String(describing: result["status"] ?? "")

                        print(status)

                        DispatchQueue.main.async {
                            self.nickNameTextField.resignFirstResponder()
                            self.navigationController?.popViewController(animated: true)
                        }
                    }
                }
            } // Ajax
        }
    }
}
