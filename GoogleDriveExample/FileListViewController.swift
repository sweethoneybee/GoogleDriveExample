//
//  FileListViewController.swift
//  GoogleDriveExample
//
//  Created by 정성훈 on 2021/12/05.
//

import UIKit

class FileListViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
    weak var helper: GDHelper?
    var currentDepth: String?
    private var files: [FileObject] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        
        fetchFileList()
    }

    func updateUI() {
        tableView.reloadData()
    }
    
    private func fetchFileList() {
        helper?.fetchFileList(in: currentDepth ?? "root") { [weak self] fileList, error in
            guard let self = self else { return }
            
            if let error = error {
                print("파일리스트 받아오는 중 에러 발생=\(error)")
                return
            }
            
            guard let fileList = fileList else {
                print("파일리스트 받은 게 없음")
                return
            }
            
            self.files = fileList.map {
                var fileObject = FileObject()
                fileObject.id = $0.identifier ?? ""
                fileObject.name = $0.name ?? ""
                if $0.mimeType == "application/vnd.google-apps.folder" {
                    fileObject.mimeType = .folder
                } else {
                    fileObject.mimeType = .file
                }
                return fileObject
            }.sorted {
                if $0.mimeType != $1.mimeType {
                    return $0.mimeType == .folder
                }
                return $0.name < $1.name
            }
            self.updateUI()
        }
    }
}


extension FileListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        files.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let file = files[indexPath.item]
        
        var configuration = UIListContentConfiguration.cell()
        configuration.text = file.name
        configuration.image = file.mimeType == .folder ? UIImage(systemName: "folder") : UIImage(systemName: "f.square")
        
        cell.contentConfiguration = configuration
        return cell
    }
}

extension FileListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let file = files[indexPath.item]
        if file.mimeType == .folder {
            if let vc = self.storyboard?.instantiateViewController(withIdentifier: "FileListViewController") as? FileListViewController {
                vc.helper = self.helper
                vc.currentDepth = file.id
                navigationController?.pushViewController(vc, animated: true)
            }
        } else {
            print("파일 다운로드 로직 수행해야함")
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

