//
//  GDHelper.swift
//  GoogleDriveExample
//
//  Created by 정성훈 on 2021/12/05.
//

import Foundation
import CoreXLSX

final class GDHelper {
    init(authorizer: GTMFetcherAuthorizationProtocol) {
        service = GTLRDriveService()
        service.authorizer = authorizer
        service.isRetryEnabled = true
    }
    
    var service: GTLRDriveService
    var fileListTicket: GTLRServiceTicket?
    
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
