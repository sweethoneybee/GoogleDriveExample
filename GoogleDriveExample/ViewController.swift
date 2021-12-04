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

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var signInButton: UIButton!
    var helper: GDHelper?
    
    var signedInUsername: String? {
        if let auth = self.helper?.service.authorizer {
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
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        
        GIDSignIn.sharedInstance.restorePreviousSignIn { user, error in
            if let authorizer = GIDSignIn.sharedInstance.currentUser?.authentication.fetcherAuthorizer() {
                self.helper = GDHelper(authorizer: authorizer)
         
                self.updateUI()
            }
        }
    }

    func updateUI() {
        usernameLabel.text = self.signedInUsername ?? "로그인필요함"
        
        if helper?.fileList != nil {
            tableView.reloadData()
        }
    }
    
    @IBAction func signInGoogle(_ sender: Any) {
        if GIDSignIn.sharedInstance.hasPreviousSignIn() == false {
            let signConfiguration = GIDConfiguration(clientID: APIKeys.clientID)
            GIDSignIn.sharedInstance.signIn(with: signConfiguration, presenting: self) { user, error in
                if let error = error {
                    print("로그인에러 발생=\(error)")
                    return
                }
                
                guard let user = user else {
                    print("로그인유저 없음")
                    return
                }
                
                print("성공!")
            }
        }
    }
    
    @IBAction func addDriveScope(_ sender: Any) {
        GIDSignIn.sharedInstance.addScopes([kGTLRAuthScopeDriveReadonly], presenting: self) { user, error in
            if let error = error {
                print("드라이브권한에러 발생=\(error)")
                return
            }
            
            guard let user = user else {
                print("드라이브권한유저 없음")
                return
            }
            
            print("성공!")
            self.helper = GDHelper(authorizer: user.authentication.fetcherAuthorizer())
        }
    }
    
    @IBAction func printFileLists(_ sender: Any) {
        helper?.fetchFileList {
            self.updateUI()
        }
    }
}

class GDHelper {
    init(authorizer: GTMFetcherAuthorizationProtocol) {
        service = GTLRDriveService()
        service.authorizer = authorizer
        service.shouldFetchNextPages = true
        service.isRetryEnabled = true
    }
    
    var service: GTLRDriveService
    
    var fileList: GTLRDrive_FileList?
    var fileListTicket: GTLRServiceTicket?
    
    func fetchFileList(onCompleted: (()->Void)? = nil) {
        let query = GTLRDriveQuery_FilesList.query()
        query.fields = "kind,nextPageToken,files(mimeType,id,kind,name,webViewLink,thumbnailLink,trashed)"
        
        fileListTicket = service.executeQuery(query) { ticket, result, error in
            if let error = error {
                print("파일리스트에러=\(error)")
                return
            }
            
            self.fileList = result as? GTLRDrive_FileList
            if let files = self.fileList?.files {
                print(files)
            }
            onCompleted?()
        }
    }
    
    func downloadFile(_ file: GTLRDrive_File, toDestinationURL destinationURL: URL) {
        guard let id = file.identifier else {
            print("다운로드 전에 바인딩실패")
            return
        }
        let query = GTLRDriveQuery_FilesGet.queryForMedia(withFileId: id)
        
        service.executeQuery(query) { ticket, object, error in
            if let error = error {
                print("다운로드에러=\(error)")
                return
            }
            
            guard let data = (object as? GTLRDataObject)?.data else {
                return
            }
            
            var rows: [[String]] = []
            do {
                let xlsxFile = try XLSXFile(data: data)
                
                for wbk in try xlsxFile.parseWorkbooks() {
                    for (name, path) in try xlsxFile.parseWorksheetPathsAndNames(workbook: wbk) {
                        if let worksheetName = name {
                            print("워크시트이름=\(worksheetName)")
                        }
                        
                        let worksheet = try xlsxFile.parseWorksheet(at: path)
                        if let sharedStrings = try xlsxFile.parseSharedStrings() {
                            for row in worksheet.data?.rows ?? [] {
                                let rowCStrings = row.cells.compactMap { $0.stringValue(sharedStrings) }
                                rows.append(rowCStrings)
                            }
                        }
                        
                    }
                }
            } catch {
                print("셀 탐색 실패")
            }
            
            rows.forEach {
                $0.forEach {
                    print($0, terminator: "")
                }
                print("")
            }
        }
        
      
        // 파일이 큰 경우, 아래와 같은 방식으로 다운로드 프로그레스를 관찰할 수 있음
//        let downloadRequest = service.request(for: query)
//        let fetcher = service.fetcherService.fetcher(with: downloadRequest as URLRequest)
//        fetcher.destinationFileURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("testest")
//        fetcher.beginFetch { data, error in
//            if let error = error {
//                print("다운로드에러=\(error)")
//                return
//            }
//
//            guard let data = data else {
//                return
//            }
//            print("다운로드 성공")
//            print(data)
//        }
    }
}


extension ViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        helper?.fileList?.files?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        
        var configuration = UIListContentConfiguration.cell()
        
        if let file = helper?.fileList?.files?[indexPath.item] {
            configuration.text = file.name ?? "이름 옵셔널임"
            configuration.secondaryText = file.mimeType ?? "미디어타입 옵셔널임"
        } else {
            configuration.text = "찾을 수 없는 파일"
        }
        
        cell.contentConfiguration = configuration
        return cell
    }
    
    
}

extension ViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let file = helper?.fileList?.files?[indexPath.item] {
            self.helper?.downloadFile(file, toDestinationURL: URL(fileURLWithPath: "test"))
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
