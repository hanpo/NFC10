//
//  CameraViewController.swift
//  NFC10
//
//  Created by HAN PO CHENG on 2021/11/6.
//

import UIKit
import AVFoundation
import Photos

class CameraViewController: UIViewController, AVCaptureFileOutputRecordingDelegate, UITabBarDelegate {
    
    private var session: AVCaptureSession!
    private var videoDevice: AVCaptureDevice!
    private var audioDevice: AVCaptureDevice!
    private var fileOutput: AVCaptureMovieFileOutput!
    private var previewView: PreviewView!
    
    private var timer:Timer?
    private var countDownNumber = 4
    private var recordCountNumber = 10
    var soundPlayer: AVAudioPlayer?
    
    private let countdownLabel:UILabel = {
        let eLabel = UILabel(frame: CGRect.zero)
        eLabel.font = UIFont.boldSystemFont(ofSize: 120)
        eLabel.textColor = .white
        eLabel.textAlignment = .center
        return eLabel
    }()
    
    // MARK: - Setup
    override func loadView() {
        super.loadView()
        
        previewView = PreviewView()
        self.view.addSubview(previewView)
        self.view.addSubview(countdownLabel)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(CameraViewController.onDidBecomeActive(_:)), name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(CameraViewController.onWillResignActive(_:)), name: UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(CameraViewController.onWillTerminate(_:)), name: UIApplication.willTerminateNotification, object: nil)
        
        previewView.translatesAutoresizingMaskIntoConstraints = false
        previewView.leftAnchor.constraint(equalTo: self.view.leftAnchor, constant: 0).isActive = true
        previewView.rightAnchor.constraint(equalTo: self.view.rightAnchor, constant: 0).isActive = true
        previewView.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 0).isActive = true
        previewView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: 0).isActive = true
        
        
        countdownLabel.translatesAutoresizingMaskIntoConstraints = false
        countdownLabel.centerXAnchor.constraint(equalTo: self.view.centerXAnchor, constant: 0).isActive = true
        countdownLabel.centerYAnchor.constraint(equalTo: self.view.centerYAnchor, constant: 0).isActive = true
        countdownLabel.widthAnchor.constraint(equalToConstant: 220).isActive = true
        countdownLabel.heightAnchor.constraint(equalToConstant: 220).isActive = true
        
        session = AVCaptureSession()
        previewView.session = session
        
        videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
        let videoInput = try! AVCaptureDeviceInput.init(device: videoDevice)
        session.addInput(videoInput)
        
        // switchFormat(desiredFps: 30.0)
        switchFormat(desiredFps: 60.0)
        // switchFormat(desiredFps: 120.0)
        // switchFormat(desiredFps: 240.0)
        
        audioDevice = AVCaptureDevice.default(for: .audio)
        let audioInput = try! AVCaptureDeviceInput.init(device: audioDevice)
        session.addInput(audioInput)
        
        fileOutput = AVCaptureMovieFileOutput()
        session.addOutput(fileOutput)
        
        session.startRunning()
    }
    
    
    @objc func onDidBecomeActive(_ notification: Notification?) {
        print(#function)
        
        cleanAllMp4File()
        
        if session.isRunning == false {
            session.startRunning()
        }
        
        playSound()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + DispatchTimeInterval.milliseconds(Int(countDownNumber * 1000))) {
            self.startRecording()
        }
        
        timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(countDownAction), userInfo: nil, repeats: true)
    }
    
    @objc func onWillResignActive(_ notification: Notification?) {
        print(#function)
        
        countdownLabel.text = ""
        
        stopRecording()
        
        if session.isRunning {
            session.stopRunning()
        }
        
        timer?.invalidate()
    }
    
    @objc func onWillTerminate(_ notification: Notification?) {
        if session.isRunning {
            session.stopRunning()
        }
    }
    
    //MARK: - Switch to the specified FPS format (choose the highest resolution format for that FPS)
    private func switchFormat(desiredFps: Double) {
        print("switchFormat: \(desiredFps) fps")
        
        //limit 1920x1080
        let limitWidth: Int32 = 1921  // width 1920px
        let limitHeight: Int32 = 1081 // height 1080px
        
        let isRunning = session.isRunning
        if isRunning {
            session.stopRunning()
        }
        
        var selectedFormat: AVCaptureDevice.Format! = nil
        var maxWidth: Int32 = 0
        var maxHeight: Int32 = 0
        
        for format in videoDevice.formats {
            for range: AVFrameRateRange in format.videoSupportedFrameRateRanges {
                let description = format.formatDescription as CMFormatDescription  //format
                let dimensions = CMVideoFormatDescriptionGetDimensions(description)  //width,height
                let width = dimensions.width
                let height = dimensions.height
                //Get the highest resolution at the specified frame rate (don't choose a resolution that exceeds the upper limit)
                if desiredFps == range.maxFrameRate && (maxWidth <= width && width < limitWidth) && (maxHeight <= height && height < limitHeight) {
                    selectedFormat = format
                    maxWidth = width
                    maxHeight = height
                }
            }
        }
        
        if selectedFormat != nil {
            do {
                try videoDevice.lockForConfiguration()
                videoDevice.activeFormat = selectedFormat
                videoDevice.activeVideoMinFrameDuration = CMTime(value: 1, timescale:Int32(desiredFps))
                videoDevice.activeVideoMaxFrameDuration = CMTime(value: 1, timescale:Int32(desiredFps))
                videoDevice.unlockForConfiguration()
                print("Set format frame rate: \(desiredFps) fps ・ \(maxWidth) × \(maxHeight) px")
                
                if isRunning {
                    print("session resume")
                    session.startRunning()
                }
            }
            catch {
                print("The format frame rate could not be specified: \(desiredFps) fps")
            }
        }else {
            print("can't be selected: \(desiredFps) fps")  //try others
            switch desiredFps {
            case 240.0:
                print("240fps can't be selected, so try again to see if 120fps can be selected.")
                switchFormat(desiredFps: 120.0)
            case 120.0:
                print("120fps can't be selected, so try again to see if 60fps can be selected.")
                switchFormat(desiredFps: 60.0)
            case 60.0:
                print("60fps can't be selected, so try again to see if 30fps can be selected.")
                switchFormat(desiredFps: 30.0)
            case 30.0:
                print("30fps can't be selected")
            default:
                print("unknow FPS : \(desiredFps)")
            }
        }
    }
    
    private func startRecording() {
        print(#function)
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentsDirectory = paths[0] as String
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMddHHmmssSSS"
        let filePath: String? = "\(documentsDirectory)/yaParkVideo-\(formatter.string(from: Date())).mp4"
        print("start Recording at : \(filePath!)")
        let fileURL = NSURL(fileURLWithPath: filePath!)
        fileOutput?.startRecording(to: fileURL as URL, recordingDelegate: self)
    }
    
    private func stopRecording() {
        print(#function)
        fileOutput?.stopRecording()
    }
    
    private func cleanAllMp4File(){
        let documentsUrl =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        
        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(at: documentsUrl,includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
            for fileURL in fileURLs {
                if fileURL.pathExtension == "mp4" {
                    try FileManager.default.removeItem(at: fileURL)
                }
            }
        } catch  {
            print(error)
        }
        
    }
    
    private func resetCount() {
        self.countDownNumber = 4
        self.recordCountNumber = 10
    }
    
    private func downloadFiles() {
        print(#function)
        let documentDirectoryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        do {
            let contentUrls = try FileManager.default.contentsOfDirectory(at: documentDirectoryURL, includingPropertiesForKeys: nil)
            for contentUrl in contentUrls {
                if contentUrl.pathExtension == "mp4" {
                    print("mp4 save to photo library: \(contentUrl.lastPathComponent)")
                    PHPhotoLibrary.shared().performChanges({
                        PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: contentUrl)
                    }) { (isCompleted, error) in
                        if isCompleted {
                            print("successful saved : \(contentUrl.lastPathComponent)")
                            do {
                                try FileManager.default.removeItem(atPath: contentUrl.path)
                                print("File deletion successful after exporting the photo library: \(contentUrl.lastPathComponent)")
                                
                                self.resetCount()
                                
                                //Jump to photo
                                DispatchQueue.main.async {
                                    UIApplication.shared.open(URL(string:"photos-redirect://")!)
                                    // TODO: Video Replay App
                                }
                                
                            }
                            catch {
                                print("File deletion failure after exporting photo library : \(contentUrl.lastPathComponent)")
                            }
                        }else {
                            print("mp4 export failure : \(contentUrl.lastPathComponent)")
                        }
                    }
                }
                else {
                    print("not mp4 file : \(contentUrl.lastPathComponent)")
                }
            }
        }
        catch {
            print("error : \(error)")
        }
    }
    
    
    // MARK: - fileOutput
    
    func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {
        print(#function)
    }
    
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        print(#function)
        downloadFiles()
    }
    
    // MARK: - Timer method
    
    @objc func countDownAction() {
        countDownNumber -= 1
        countdownLabel.text = String(countDownNumber)
        print(countDownNumber)
        if countDownNumber == 0 {
            countdownLabel.text = "Go!"
            timer?.invalidate()
            timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(startRecordingAction), userInfo: nil, repeats: true)
        }
    }
    
    @objc func startRecordingAction() {
        countdownLabel.text = "🔴"
        recordCountNumber -= 1
        print(recordCountNumber)
        if recordCountNumber == 0 {
            timer?.invalidate()
            stopRecording()
        }
        
    }
    
    func playSound() {
        guard let url = Bundle.main.url(forResource: "countdown", withExtension: "mp3") else { return }

        do {
            try AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .videoRecording)
            try AVAudioSession.sharedInstance().setActive(true)

            soundPlayer = try AVAudioPlayer(contentsOf: url, fileTypeHint: AVFileType.mp3.rawValue)
            guard let player = soundPlayer else { return }
            player.prepareToPlay()
            player.play()

        } catch let error {
            print(error.localizedDescription)
        }
    }
}
