//
//  DownloadListCell.swift.swift
//  GoogleDriveExample
//
//  Created by 정성훈 on 2021/12/09.
//

import UIKit

protocol DownloadListCellDelegate: AnyObject {
    func downloadButtonTapped(_ cell: UITableViewCell)
    func openButtonTapped(_ cell: UITableViewCell)
    func cancelButtonTapped(_ cell: UITableViewCell)
}

final class DownloadListCell: UITableViewCell {
    
    static let identifier = "DownloadListCell"
    
    @IBOutlet var iconView: UIImageView!
    @IBOutlet var title: UILabel!
    @IBOutlet var subTitle: UILabel!
    @IBOutlet var downloadButton: UIButton!
    @IBOutlet var openButton: UIButton!
    
    weak var delegate: DownloadListCellDelegate?
    
    func configure(_ file: FileObject, downloaded: Bool) {
        title.text = file.name

        if file.mimeType == .folder {
            iconView.image = UIImage(systemName: "folder")
            downloadButton.isHidden = true
            openButton.isHidden = true
        } else {
            iconView.image = UIImage(systemName: "f.square")
            let formatter = ByteCountFormatter()
            formatter.countStyle = .binary
            subTitle.text = formatter.string(fromByteCount: file.size)
            
            downloadButton.addTarget(self, action: #selector(didDownloadButtonTapped), for: .touchUpInside)
            openButton.addTarget(self, action: #selector(didOpenButtonTapped), for: .touchUpInside)
            
            downloadButton.isHidden = downloaded
            openButton.isHidden = !downloaded
        }
    }
    
    @objc
    private func didDownloadButtonTapped() {
        delegate?.downloadButtonTapped(self)
    }
    
    @objc
    private func didOpenButtonTapped() {
        delegate?.openButtonTapped(self)
    }
}

