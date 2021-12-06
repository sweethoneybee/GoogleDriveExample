//
//  FileObject.swift
//  GoogleDriveExample
//
//  Created by 정성훈 on 2021/12/05.
//

import Foundation

struct FileObject {
    enum MimeType {
        case folder
        case file
    }
    
    var id: String = ""
    var name: String = ""
    var size: Int64 = .zero
    var mimeType: MimeType = .file
    
    static func makeFiles(_ fileList: [GTLRDrive_File]) -> [Self] {
        return fileList.map {
            var fileObject = FileObject()
            fileObject.id = $0.identifier ?? ""
            fileObject.name = $0.name ?? ""
            fileObject.size = $0.size?.int64Value ?? 20
            if $0.mimeType == "application/vnd.google-apps.folder" {
                fileObject.mimeType = .folder
            } else {
                fileObject.mimeType = .file
            }
            return fileObject
        }
    }
}
