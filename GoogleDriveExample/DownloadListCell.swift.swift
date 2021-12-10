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
    @IBOutlet var cancelButton: UIButton!
    
    weak var delegate: DownloadListCellDelegate?

    func configure(_ file: FileObject, downloaded: Bool, fetcher: GTMSessionFetcher?) {
        title.text = file.name

        if file.mimeType == .folder {
            iconView.image = UIImage(systemName: "folder")
            subTitle.text = " "
            downloadButton.isHidden = true
            openButton.isHidden = true
            cancelButton.isHidden = true
        } else {
            iconView.image = UIImage(systemName: "f.square")
            
            var showDownloadControls = false
            if let fetcher = fetcher {
                showDownloadControls = fetcher.isFetching
            }
            
            let formatter = ByteCountFormatter()
            formatter.countStyle = .binary
            subTitle.text = formatter.string(fromByteCount: file.size)
            
            cancelButton.isHidden = !showDownloadControls
            openButton.isHidden = !downloaded
            downloadButton.isHidden = downloaded || showDownloadControls
        }
    }
    
    @IBAction func didDownloadButtonTapped() {
        delegate?.downloadButtonTapped(self)
    }
    
    @IBAction func didOpenButtonTapped() {
        delegate?.openButtonTapped(self)
    }
    
    @IBAction func didCancelButtonTapped() {
        delegate?.cancelButtonTapped(self)
    }
}

