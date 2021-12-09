//
//  GDHelper.swift
//  GoogleDriveExample
//
//  Created by 정성훈 on 2021/12/05.
//

import Foundation
import CoreXLSX

protocol GDHelperDownloadDelegate: AnyObject {
    func didFinishDownload(_ fileObject:FileObject, error: Error?)
}

final class GDHelper {
    init() {
        service = GTLRDriveService()
        service.isRetryEnabled = true
    }

    static let shared = GDHelper()
    weak var delegate: GDHelperDownloadDelegate?
    
    var activeDownloads: [String: GTLRServiceTicket] = [:] // [GTLRDrive_File.id : GTLRServiceTicket
    var service: GTLRDriveService
    var fileListTicket: GTLRServiceTicket?
    
    var authorizer: GTMFetcherAuthorizationProtocol? {
        get {
            return service.authorizer
        }
        set {
            service.authorizer = newValue
        }
    }
    
    let drivePath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("googleDrive", isDirectory: true)

    func localPath(for id: String) -> URL {
        return drivePath.appendingPathComponent(id)
    }
    
    /// refer to https://developers.google.com/drive/api/v3/reference/files
    func fetchFileList(in root: String?,
                       usingToken nextPageToken: String? = nil,
                       onCompleted: ((String?, [GTLRDrive_File]?, Error?)->Void)? = nil) {
        let query = GTLRDriveQuery_FilesList.query()
        query.fields = "nextPageToken,files(mimeType,id,name,size)"
        query.q = "(mimeType = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' or mimeType = 'application/vnd.google-apps.folder' or mimeType = 'application/pdf') and '\(root ?? "root")' in parents and trashed = false"
        query.pageSize = 10
        query.pageToken = nextPageToken
        query.orderBy = "folder, name"
        
        fileListTicket = service.executeQuery(query) { ticket, result, error in
            if let error = error {
                print("파일리스트에러=\(error)")
                onCompleted?(nil, nil, error)
                return
            }
            
            let fileList = result as? GTLRDrive_FileList
            onCompleted?(fileList?.nextPageToken, fileList?.files, nil)
        }
    }
    
    func downloadFile(from fileObject: FileObject) {
        guard activeDownloads[fileObject.id] == nil else { return }
        let id = fileObject.id
        let query = GTLRDriveQuery_FilesGet.queryForMedia(withFileId: id)
        
        activeDownloads[id] = service.executeQuery(query) { ticket, object, error in
            defer {
                self.activeDownloads.removeValue(forKey: id)
            }
            
            if let error = error {
                print("다운로드에러=\(error)")
                self.delegate?.didFinishDownload(fileObject, error: error)
                return
            }
            
            guard let data = (object as? GTLRDataObject)?.data else {
                return
            }
            
            do {
                let destinationURL = self.localPath(for: id)
                try data.write(to: destinationURL)
                print("다운로드 성공 후 데이터 쓰기 성공")
                self.delegate?.didFinishDownload(fileObject, error: nil)
            } catch {
                print("다운로드 후 데이터 쓰기 실패")
                self.delegate?.didFinishDownload(fileObject, error: error)
            }
        }
    }
    
    func cancelDownload(for id: String) {
        if let ticket = activeDownloads[id] {
            ticket.cancel()
            activeDownloads.removeValue(forKey: id)
        }
    }
    
    func readWorkSheet(from data: Data) {
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
    
    func fileExist(_ file: FileObject) -> Bool {
        let destinationURL = self.localPath(for: file.id)
        return FileManager.default.fileExists(atPath: destinationURL.path)
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
