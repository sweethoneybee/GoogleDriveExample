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
    var mimeType: MimeType = .file
}
