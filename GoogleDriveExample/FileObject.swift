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
    
    var id: String
    var index: Int
    var name: String
    var size: Int64
    var mimeType: MimeType
    
    static func makeFiles(_ fileList: [GTLRDrive_File]) -> [Self] {
        return fileList.enumerated().map {
            return FileObject(
                id: $1.identifier ?? "",
                index: $0,
                name: $1.name ?? "",
                size: $1.size?.int64Value ?? 0,
                mimeType: ($0.mimeType == "application/vnd.google-apps.folder") ? .folder : .file
            )
        }
    }
}
