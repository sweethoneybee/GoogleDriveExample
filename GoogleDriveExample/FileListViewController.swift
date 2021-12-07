//
//  FileListViewController.swift
//  GoogleDriveExample
//
//  Created by 정성훈 on 2021/12/05.
//

import UIKit

class FileListViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
    var currentDepth: String?

    private var files: [FileObject] = []
    private var nextPageToken: String?
    
    private var isFetching = false
    override func viewDidLoad() {
        super.viewDidLoad()
        
        GDHelper.shared.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        
        fetchFileList()
    }

    func updateUI() {
        tableView.reloadData()
    }
    
    func reload(_ index: Int) {
        tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
    }
    
    private func fetchFileList() {
        isFetching = true
        GDHelper.shared.fetchFileList(in: currentDepth) { [weak self] pageToken, fileList, error in
            guard let self = self else { return }
            
            if let error = error {
                print("파일리스트 받아오는 중 에러 발생=\(error)")
                return
            }
            
            guard let fileList = fileList else {
                print("파일리스트 받은 게 없음")
                return
            }
            
            self.nextPageToken = pageToken
            self.files = FileObject.makeFiles(fileList)
            self.updateUI()
            self.isFetching = false
        }
    }
    
    private func fetchFileList(using nextPageToken: String?) {
        guard isFetching == false else {
            return
        }
        guard nextPageToken != nil else {
            return
        }
        
        isFetching = true
        GDHelper.shared.fetchFileList(in: currentDepth, usingToken: nextPageToken) { [weak self] pageToken, fileList, error in
            guard let self = self else { return }
            
            if let error = error {
                print("파일리스트 받아오는 중 에러 발생=\(error)")
                return
            }
            
            guard let fileList = fileList else {
                print("파일리스트 받은 게 없음")
                return
            }
            
            self.nextPageToken = pageToken
            self.files.append(contentsOf: FileObject.makeFiles(fileList))
            self.updateUI()
            self.isFetching = false
        }
    }
}

// MARK: - UI Delegate
extension FileListViewController { // TODO: Adopt cell delegate
    func downloadButtonTapped(_ cell: UITableViewCell) {
        if let indexPath = tableView.indexPath(for: cell) {
            let file = files[indexPath.item]
            GDHelper.shared.downloadFile(from: file)
            reload(indexPath.item)
        }
    }
    
    func makeBreadButtonTapped(_ cell: UITableViewCell) {
        if let indexPath = tableView.indexPath(for: cell) {
            let file = files[indexPath.item]
            // xlsx 파일 읽는 객체가 로직을 수행함.
        }
    }
    
    func cancelButtonTapped(_ cell: UITableViewCell) {
        if let indexPath = tableView.indexPath(for: cell) {
            let file = files[indexPath.item]
            GDHelper.shared.cancelDownload(for: file.id)
            reload(indexPath.item)
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
                
        var content = UIListContentConfiguration.subtitleCell()
        content.text = file.name
        content.textProperties.numberOfLines = 1
        content.textProperties.lineBreakMode = .byTruncatingTail
        
        if file.mimeType == .folder {
            content.image = UIImage(systemName: "folder")
        } else {
            content.image = UIImage(systemName: "f.square")
            let formatter = ByteCountFormatter()
            formatter.countStyle = .binary
            content.secondaryText = formatter.string(fromByteCount: file.size)
        }
        
        cell.contentConfiguration = content
        return cell
    }
}

extension FileListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let file = files[indexPath.item]
        if file.mimeType == .folder {
            if let vc = self.storyboard?.instantiateViewController(withIdentifier: "FileListViewController") as? FileListViewController {
                vc.currentDepth = file.id
                navigationController?.pushViewController(vc, animated: true)
            }
        } else {
            print("파일 다운로드 로직 수행해야함. 사이즈=\(file.size)")
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

extension FileListViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if (scrollView.contentOffset.y + scrollView.frame.height) > scrollView.contentSize.height {
            fetchFileList(using: nextPageToken)
        }
    }
}

extension FileListViewController: GDHelperDownloadDelegate {
    func didFinishDownload(_ fileObject: FileObject, error: Error?) {
        guard fileObject.index < files.count else { return }
        
        let file = files[fileObject.index]
        if file.id == fileObject.id {
            if let error = error{
                print("다운로드 실패 에러처리=\(error)")
            }
            reload(fileObject.index)
        }
    }
}
