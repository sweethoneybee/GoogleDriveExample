//
//  ViewController.swift
//  GoogleDriveExample
//
//  Created by 정성훈 on 2021/12/02.
//

import UIKit
import GoogleSignIn
import CoreXLSX

class ViewController: UIViewController {

    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var signInButton: UIButton!
    
    var signedInUsername: String? {
        if let auth = GDHelper.shared.authorizer {
            if case true? = auth.canAuthorize {
                return auth.userEmail
            } else {
                return nil
            }
        }
        return nil
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        GIDSignIn.sharedInstance.restorePreviousSignIn { user, error in
            if let authorizer = GIDSignIn.sharedInstance.currentUser?.authentication.fetcherAuthorizer() {
                GDHelper.shared.authorizer = authorizer
                self.updateUI()
            }
        }
    }

    func updateUI() {
        usernameLabel.text = self.signedInUsername ?? "로그인필요함"
    }
    
    @IBAction func signInGoogle(_ sender: Any) {
        let signConfiguration = GIDConfiguration(clientID: APIKeys.clientID)
        GIDSignIn.sharedInstance.signIn(with: signConfiguration, additionalScopes: [kGTLRAuthScopeDriveReadonly], presenting: self) { user, error in
            if let error = error {
                print("로그인에러 발생=\(error)")
                return
            }

            guard let user = user else {
                print("로그인유저 없음")
                return
            }

            print("성공!")
            GDHelper.shared.authorizer = user.authentication.fetcherAuthorizer()
            self.updateUI()
        }
    }
    
    @IBAction func printFileLists(_ sender: Any) {
        if let vc = self.storyboard?.instantiateViewController(withIdentifier: "FileListViewController") as? FileListViewController {
            vc.currentDepth = "root"
            navigationController?.pushViewController(vc, animated: true)
        }
    }
}
