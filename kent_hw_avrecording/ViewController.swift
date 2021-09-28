//
//  ViewController.swift
//  kent_hw_avrecording
//
//  Created by MIKETSAI on 2021/5/27.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {
    
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var recordBtn: UIButton!
    @IBOutlet weak var stopBtn: UIButton!
    
    var voiceRecorder : AVAudioRecorder?
    var voicePlayer : AVAudioPlayer?
    var stats : Bool = false
    
    let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!

    var recording = [RecordingModel]()
    
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        fetchRecordings()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let audioSession = AVAudioSession.sharedInstance()
        audioSession.requestRecordPermission { result in
            if result == true{
                print("Permission get!!")
            }else{
                print("Permission denied!!")
            }
        }
        
        try? AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playAndRecord)
        
        self.tableView.dataSource = self
        self.tableView.delegate = self
        

        recordBtn.isEnabled = true
        stopBtn.isEnabled = false
        
        print(documentsURL)
        
    }
    
    func fetchRecordings() {
        recording.removeAll()
        let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let directoryContents = try! FileManager.default.contentsOfDirectory(at: documentDirectory, includingPropertiesForKeys: nil)
        for audio in directoryContents {
            let name = audio.lastPathComponent
            let file = RecordingModel()
            file.fileName = name
            file.fileURL = audio
            recording.append(file)
            recording.sort(by: { $0.fileName!.compare($1.fileName!) == .orderedDescending})

        }
    }
        
    func getDate() -> String {
        let newDate = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd' 'HH:mm:ss"
        dateFormatter.timeZone = TimeZone(identifier: "Asia/Taipei")
        let dataString = dateFormatter.string(from: newDate)
        return dataString
    }

    @IBAction func recordBtn(_ sender: UIButton) {
        let settings : [String : Any] =
            [AVFormatIDKey : kAudioFormatAppleIMA4,
             AVSampleRateKey : 22050.0,
             AVNumberOfChannelsKey : 1,
             AVLinearPCMBitDepthKey : 16,
             AVLinearPCMIsFloatKey : false,
             AVLinearPCMIsBigEndianKey : false]
        
        let dataString = getDate()
        let path = documentsURL.appendingPathComponent("\(dataString).caf")
        voiceRecorder = try? AVAudioRecorder(url: path, settings: settings)
        voiceRecorder?.prepareToRecord()

        if voiceRecorder?.isRecording == false{
            recordBtn.isEnabled = false
            stopBtn.isEnabled = true
            self.voiceRecorder?.record()
        }
    }
    
    @IBAction func stopBtn(_ sender: UIButton) {
        if voiceRecorder?.isRecording == true{
            recordBtn.isEnabled = true
            stopBtn.isEnabled = false
            self.voiceRecorder?.stop()
            fetchRecordings()
            self.tableView.reloadData()
        }
    }
}

//MARK: - UITableViewDataSource
extension ViewController : UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.recording.count
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! RecordingCell
        let recordingCell = self.recording[ indexPath.row]
        cell.delegate = self
        cell.cellLabel.text = recordingCell.fileName
        cell.cellButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
        return cell
    }
}

//MARK: - UITableViewDelegate
extension ViewController : UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        print("選\(indexPath.row)")
        self.tableView.deselectRow(at: indexPath, animated: true)
    }
    
    // set editing
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        
        self.tableView.setEditing(editing, animated: true)
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        
        if editingStyle == .delete {//紅色刪除，另一種是綠色加號
            //1.刪除data中的資料
            let file = self.recording.remove(at: indexPath.row)
            
            //archiving delete
            let home = URL(fileURLWithPath: NSHomeDirectory())//利用URL物件組路徑
            let doc = home.appendingPathComponent("Documents")//Documents不要拚錯
            
            if let filename = file.fileName {
                let filepath = doc.appendingPathComponent(filename)
                try? FileManager.default.removeItem(at: filepath)
            }
         
            fetchRecordings()
            //2.通知畫面更新
            self.tableView.deleteRows(at: [indexPath], with: .automatic)
        }
        
    }

    
}



//MARK: - AVAudioRecorderDelegate
extension ViewController : AVAudioRecorderDelegate {
    // in case a phone call come in
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag{
            self.voiceRecorder?.stop()
            self.voiceRecorder = nil
            recordBtn.isEnabled = true
            stopBtn.isEnabled = false
            fetchRecordings()
            self.tableView.reloadData()
        }
    }
    
    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        print(error)
    }

}

//MARK: - AVAudioPlayerDelegate
extension ViewController : AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        print("finish play")
        finishPlaying()
        tableView.reloadData()
    }
}

//MARK: - RecordingCellDelegate
extension ViewController : RecordingCellDelegate {
    
    func playBtnToggle(sender: RecordingCell) {
        if let selectedIndexPath = tableView.indexPath(for: sender) {
            let playfile = recording[selectedIndexPath.row]
            
            
            if voicePlayer?.isPlaying != self.stats {
                startPlaying(url: playfile.fileURL!)
                sender.cellButton.setImage(UIImage(systemName: "pause.fill"), for: .normal)
                self.stats = true
            } else {
                pausePlaying()
                sender.cellButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
                self.stats = false
            }

//            if voicePlayer == nil{
//                startPlaying(url: playfile.fileURL!)
//                sender.cellButton.setImage(UIImage(systemName: "pause.fill"), for: .normal)
//            } else {
//                finishPlaying()
//                sender.cellButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
//            }

        }
    }
    
    func startPlaying(url : URL){
        voicePlayer = try? AVAudioPlayer(contentsOf: url)
        voicePlayer?.numberOfLoops = 0
        voicePlayer?.volume = 70
        voicePlayer?.prepareToPlay()
        voicePlayer?.delegate = self
        voicePlayer?.play()

    }
    
    func pausePlaying(){
//        voicePlayer?.stop()
        voicePlayer?.pause()
//        voicePlayer = nil
    }
    func finishPlaying(){
        voicePlayer?.stop()
//        voicePlayer?.pause()
        voicePlayer = nil
    }

    
}


