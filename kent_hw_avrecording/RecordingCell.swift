//
//  RecordingCell.swift
//  kent_hw_avrecording
//
//  Created by MIKETSAI on 2021/6/14.
//



import UIKit

protocol RecordingCellDelegate: class {
    func playBtnToggle(sender: RecordingCell)
}

class RecordingCell: UITableViewCell {

    weak var delegate: RecordingCellDelegate?
    
    @IBOutlet weak var cellLabel: UILabel!
    @IBOutlet weak var cellButton: UIButton!
    
    @IBAction func playToggle(_ sender: UIButton) {
        delegate?.playBtnToggle(sender: self)
    }
    
}
