import UIKit
import AVFoundation

class VideoCallViewController: UIViewController {
    
    // MARK: - UI Components
    private let remoteVideoView = UIView()
    private let localVideoView = UIView()
    private let connectionStatusLabel = UILabel()
    private let ipAddressTextField = UITextField()
    private let connectButton = UIButton(type: .system)
    private let disconnectButton = UIButton(type: .system)
    
    // MARK: - Pan Tilt Controls
    private let panTiltContainer = UIView()
    private let upButton = UIButton(type: .system)
    private let downButton = UIButton(type: .system)
    private let leftButton = UIButton(type: .system)
    private let rightButton = UIButton(type: .system)
    private let stopButton = UIButton(type: .system)
    
    // MARK: - Video Components
    private var captureSession: AVCaptureSession?
    private var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    private var videoOutput: AVCaptureVideoDataOutput?
    private var audioOutput: AVCaptureAudioDataOutput?
    
    // MARK: - Managers
    private let networkManager = NetworkManager()
    private let videoStreamManager = VideoStreamManager()
    private var isConnected = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        setupCamera()
        setupManagers()
    }
    
    private func setupManagers() {
        networkManager.delegate = self
        videoStreamManager.delegate = self
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = .black
        
        // 远程视频视图
        remoteVideoView.backgroundColor = .darkGray
        remoteVideoView.layer.cornerRadius = 8
        view.addSubview(remoteVideoView)
        
        // 本地视频视图
        localVideoView.backgroundColor = .lightGray
        localVideoView.layer.cornerRadius = 8
        localVideoView.layer.borderWidth = 2
        localVideoView.layer.borderColor = UIColor.white.cgColor
        view.addSubview(localVideoView)
        
        // 连接状态标签
        connectionStatusLabel.text = "未连接"
        connectionStatusLabel.textColor = .white
        connectionStatusLabel.textAlignment = .center
        connectionStatusLabel.font = UIFont.systemFont(ofSize: 16)
        view.addSubview(connectionStatusLabel)
        
        // IP地址输入框
        ipAddressTextField.placeholder = "输入设备IP地址"
        ipAddressTextField.text = "192.168.1.100"
        ipAddressTextField.backgroundColor = .white
        ipAddressTextField.textColor = .black
        ipAddressTextField.textAlignment = .center
        ipAddressTextField.layer.cornerRadius = 8
        ipAddressTextField.layer.borderWidth = 1
        ipAddressTextField.layer.borderColor = UIColor.gray.cgColor
        view.addSubview(ipAddressTextField)
        
        // 连接按钮
        connectButton.setTitle("连接", for: .normal)
        connectButton.backgroundColor = .systemGreen
        connectButton.setTitleColor(.white, for: .normal)
        connectButton.layer.cornerRadius = 8
        connectButton.addTarget(self, action: #selector(connectButtonTapped), for: .touchUpInside)
        view.addSubview(connectButton)
        
        // 断开连接按钮
        disconnectButton.setTitle("断开", for: .normal)
        disconnectButton.backgroundColor = .systemRed
        disconnectButton.setTitleColor(.white, for: .normal)
        disconnectButton.layer.cornerRadius = 8
        disconnectButton.addTarget(self, action: #selector(disconnectButtonTapped), for: .touchUpInside)
        disconnectButton.isEnabled = false
        view.addSubview(disconnectButton)
        
        // 云台控制容器
        panTiltContainer.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        panTiltContainer.layer.cornerRadius = 12
        view.addSubview(panTiltContainer)
        
        // 云台控制按钮
        setupPanTiltControls()
    }
    
    private func setupPanTiltControls() {
        // 上按钮
        upButton.setTitle("↑", for: .normal)
        upButton.titleLabel?.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        upButton.backgroundColor = .systemBlue
        upButton.setTitleColor(.white, for: .normal)
        upButton.layer.cornerRadius = 25
        upButton.addTarget(self, action: #selector(panTiltButtonPressed(_:)), for: .touchDown)
        upButton.addTarget(self, action: #selector(panTiltButtonReleased(_:)), for: .touchUpInside)
        upButton.addTarget(self, action: #selector(panTiltButtonReleased(_:)), for: .touchUpOutside)
        upButton.tag = 1
        panTiltContainer.addSubview(upButton)
        
        // 下按钮
        downButton.setTitle("↓", for: .normal)
        downButton.titleLabel?.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        downButton.backgroundColor = .systemBlue
        downButton.setTitleColor(.white, for: .normal)
        downButton.layer.cornerRadius = 25
        downButton.addTarget(self, action: #selector(panTiltButtonPressed(_:)), for: .touchDown)
        downButton.addTarget(self, action: #selector(panTiltButtonReleased(_:)), for: .touchUpInside)
        downButton.addTarget(self, action: #selector(panTiltButtonReleased(_:)), for: .touchUpOutside)
        downButton.tag = 2
        panTiltContainer.addSubview(downButton)
        
        // 左按钮
        leftButton.setTitle("←", for: .normal)
        leftButton.titleLabel?.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        leftButton.backgroundColor = .systemBlue
        leftButton.setTitleColor(.white, for: .normal)
        leftButton.layer.cornerRadius = 25
        leftButton.addTarget(self, action: #selector(panTiltButtonPressed(_:)), for: .touchDown)
        leftButton.addTarget(self, action: #selector(panTiltButtonReleased(_:)), for: .touchUpInside)
        leftButton.addTarget(self, action: #selector(panTiltButtonReleased(_:)), for: .touchUpOutside)
        leftButton.tag = 3
        panTiltContainer.addSubview(leftButton)
        
        // 右按钮
        rightButton.setTitle("→", for: .normal)
        rightButton.titleLabel?.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        rightButton.backgroundColor = .systemBlue
        rightButton.setTitleColor(.white, for: .normal)
        rightButton.layer.cornerRadius = 25
        rightButton.addTarget(self, action: #selector(panTiltButtonPressed(_:)), for: .touchDown)
        rightButton.addTarget(self, action: #selector(panTiltButtonReleased(_:)), for: .touchUpInside)
        rightButton.addTarget(self, action: #selector(panTiltButtonReleased(_:)), for: .touchUpOutside)
        rightButton.tag = 4
        panTiltContainer.addSubview(rightButton)
        
        // 停止按钮
        stopButton.setTitle("停止", for: .normal)
        stopButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        stopButton.backgroundColor = .systemRed
        stopButton.setTitleColor(.white, for: .normal)
        stopButton.layer.cornerRadius = 20
        stopButton.addTarget(self, action: #selector(stopButtonTapped), for: .touchUpInside)
        panTiltContainer.addSubview(stopButton)
    }
    
    private func setupConstraints() {
        remoteVideoView.translatesAutoresizingMaskIntoConstraints = false
        localVideoView.translatesAutoresizingMaskIntoConstraints = false
        connectionStatusLabel.translatesAutoresizingMaskIntoConstraints = false
        ipAddressTextField.translatesAutoresizingMaskIntoConstraints = false
        connectButton.translatesAutoresizingMaskIntoConstraints = false
        disconnectButton.translatesAutoresizingMaskIntoConstraints = false
        panTiltContainer.translatesAutoresizingMaskIntoConstraints = false
        upButton.translatesAutoresizingMaskIntoConstraints = false
        downButton.translatesAutoresizingMaskIntoConstraints = false
        leftButton.translatesAutoresizingMaskIntoConstraints = false
        rightButton.translatesAutoresizingMaskIntoConstraints = false
        stopButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // 远程视频视图
            remoteVideoView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            remoteVideoView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            remoteVideoView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            remoteVideoView.bottomAnchor.constraint(equalTo: panTiltContainer.topAnchor, constant: -20),
            
            // 本地视频视图
            localVideoView.topAnchor.constraint(equalTo: remoteVideoView.topAnchor, constant: 20),
            localVideoView.trailingAnchor.constraint(equalTo: remoteVideoView.trailingAnchor, constant: -20),
            localVideoView.widthAnchor.constraint(equalToConstant: 120),
            localVideoView.heightAnchor.constraint(equalToConstant: 160),
            
            // 连接状态标签
            connectionStatusLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            connectionStatusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            connectionStatusLabel.trailingAnchor.constraint(equalTo: localVideoView.leadingAnchor, constant: -20),
            
            // IP地址输入框
            ipAddressTextField.bottomAnchor.constraint(equalTo: panTiltContainer.topAnchor, constant: -10),
            ipAddressTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            ipAddressTextField.trailingAnchor.constraint(equalTo: connectButton.leadingAnchor, constant: -10),
            ipAddressTextField.heightAnchor.constraint(equalToConstant: 40),
            
            // 连接按钮
            connectButton.bottomAnchor.constraint(equalTo: panTiltContainer.topAnchor, constant: -10),
            connectButton.trailingAnchor.constraint(equalTo: disconnectButton.leadingAnchor, constant: -10),
            connectButton.widthAnchor.constraint(equalToConstant: 80),
            connectButton.heightAnchor.constraint(equalToConstant: 40),
            
            // 断开连接按钮
            disconnectButton.bottomAnchor.constraint(equalTo: panTiltContainer.topAnchor, constant: -10),
            disconnectButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            disconnectButton.widthAnchor.constraint(equalToConstant: 80),
            disconnectButton.heightAnchor.constraint(equalToConstant: 40),
            
            // 云台控制容器
            panTiltContainer.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            panTiltContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            panTiltContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            panTiltContainer.heightAnchor.constraint(equalToConstant: 200),
            
            // 云台控制按钮布局
            upButton.centerXAnchor.constraint(equalTo: panTiltContainer.centerXAnchor),
            upButton.topAnchor.constraint(equalTo: panTiltContainer.topAnchor, constant: 20),
            upButton.widthAnchor.constraint(equalToConstant: 50),
            upButton.heightAnchor.constraint(equalToConstant: 50),
            
            downButton.centerXAnchor.constraint(equalTo: panTiltContainer.centerXAnchor),
            downButton.topAnchor.constraint(equalTo: upButton.bottomAnchor, constant: 10),
            downButton.widthAnchor.constraint(equalToConstant: 50),
            downButton.heightAnchor.constraint(equalToConstant: 50),
            
            leftButton.centerYAnchor.constraint(equalTo: upButton.centerYAnchor),
            leftButton.leadingAnchor.constraint(equalTo: panTiltContainer.leadingAnchor, constant: 40),
            leftButton.widthAnchor.constraint(equalToConstant: 50),
            leftButton.heightAnchor.constraint(equalToConstant: 50),
            
            rightButton.centerYAnchor.constraint(equalTo: upButton.centerYAnchor),
            rightButton.trailingAnchor.constraint(equalTo: panTiltContainer.trailingAnchor, constant: -40),
            rightButton.widthAnchor.constraint(equalToConstant: 50),
            rightButton.heightAnchor.constraint(equalToConstant: 50),
            
            stopButton.centerXAnchor.constraint(equalTo: panTiltContainer.centerXAnchor),
            stopButton.bottomAnchor.constraint(equalTo: panTiltContainer.bottomAnchor, constant: -20),
            stopButton.widthAnchor.constraint(equalToConstant: 80),
            stopButton.heightAnchor.constraint(equalToConstant: 40)
        ])
    }
    
    // MARK: - Camera Setup
    private func setupCamera() {
        captureSession = AVCaptureSession()
        guard let captureSession = captureSession else { return }
        
        captureSession.sessionPreset = .medium
        
        // 添加视频输入
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
              let videoInput = try? AVCaptureDeviceInput(device: videoDevice) else {
            print("无法访问摄像头")
            return
        }
        
        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
        }
        
        // 添加音频输入
        guard let audioDevice = AVCaptureDevice.default(for: .audio),
              let audioInput = try? AVCaptureDeviceInput(device: audioDevice) else {
            print("无法访问麦克风")
            return
        }
        
        if captureSession.canAddInput(audioInput) {
            captureSession.addInput(audioInput)
        }
        
        // 设置视频预览层
        videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        videoPreviewLayer?.videoGravity = .resizeAspectFill
        videoPreviewLayer?.frame = localVideoView.bounds
        localVideoView.layer.addSublayer(videoPreviewLayer!)
        
        // 添加视频输出
        videoOutput = AVCaptureVideoDataOutput()
        videoOutput?.setSampleBufferDelegate(self, queue: DispatchQueue.global(qos: .userInitiated))
        if captureSession.canAddOutput(videoOutput!) {
            captureSession.addOutput(videoOutput!)
        }
        
        // 添加音频输出
        audioOutput = AVCaptureAudioDataOutput()
        audioOutput?.setSampleBufferDelegate(self, queue: DispatchQueue.global(qos: .userInitiated))
        if captureSession.canAddOutput(audioOutput!) {
            captureSession.addOutput(audioOutput!)
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            captureSession.startRunning()
        }
    }
    
    // MARK: - Button Actions
    @objc private func connectButtonTapped() {
        guard let ipAddress = ipAddressTextField.text, !ipAddress.isEmpty else {
            showAlert(title: "错误", message: "请输入设备IP地址")
            return
        }
        
        connectToDevice(ipAddress: ipAddress)
    }
    
    @objc private func disconnectButtonTapped() {
        disconnectFromDevice()
    }
    
    @objc private func panTiltButtonPressed(_ sender: UIButton) {
        guard isConnected else { return }
        
        var command: String
        switch sender.tag {
        case 1: command = "UP"
        case 2: command = "DOWN"
        case 3: command = "LEFT"
        case 4: command = "RIGHT"
        default: return
        }
        
        sendPanTiltCommand(command)
    }
    
    @objc private func panTiltButtonReleased(_ sender: UIButton) {
        sendPanTiltCommand("STOP")
    }
    
    @objc private func stopButtonTapped() {
        sendPanTiltCommand("STOP")
    }
    
    // MARK: - Network Communication
    private func connectToDevice(ipAddress: String) {
        connectionStatusLabel.text = "连接中..."
        connectButton.isEnabled = false
        
        networkManager.connect(to: ipAddress)
    }
    
    private func disconnectFromDevice() {
        networkManager.disconnect()
        connectionStatusLabel.text = "未连接"
        connectButton.isEnabled = true
        disconnectButton.isEnabled = false
        isConnected = false
    }
    
    private func sendPanTiltCommand(_ command: String) {
        guard isConnected else { return }
        
        networkManager.sendPanTiltCommand(command)
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        present(alert, animated: true)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        videoPreviewLayer?.frame = localVideoView.bounds
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
extension VideoCallViewController: AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // 处理视频和音频数据
        if output == videoOutput {
            // 编码视频帧
            let timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
            if let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
                videoStreamManager.encodeVideoFrame(pixelBuffer, timestamp: timestamp)
            }
        } else if output == audioOutput {
            // 编码音频帧
            videoStreamManager.encodeAudioFrame(sampleBuffer)
        }
    }
}

// MARK: - NetworkManagerDelegate
extension VideoCallViewController: NetworkManagerDelegate {
    func didConnect() {
        DispatchQueue.main.async {
            self.connectionStatusLabel.text = "已连接"
            self.connectButton.isEnabled = false
            self.disconnectButton.isEnabled = true
            self.isConnected = true
        }
    }
    
    func didDisconnect() {
        DispatchQueue.main.async {
            self.connectionStatusLabel.text = "未连接"
            self.connectButton.isEnabled = true
            self.disconnectButton.isEnabled = false
            self.isConnected = false
        }
    }
    
    func didReceiveMessage(_ message: String) {
        print("收到消息: \(message)")
        // 处理接收到的消息
    }
    
    func didReceiveError(_ error: Error) {
        DispatchQueue.main.async {
            self.showAlert(title: "网络错误", message: error.localizedDescription)
        }
    }
}

// MARK: - VideoStreamManagerDelegate
extension VideoCallViewController: VideoStreamManagerDelegate {
    func didReceiveVideoFrame(_ frame: Data) {
        // 处理接收到的视频帧
        // 这里应该解码并显示在remoteVideoView上
    }
    
    func didReceiveAudioFrame(_ frame: Data) {
        // 处理接收到的音频帧
        // 这里应该解码并播放音频
    }
    
    func didReceiveVideoError(_ error: Error) {
        DispatchQueue.main.async {
            self.showAlert(title: "视频流错误", message: error.localizedDescription)
        }
    }
}
