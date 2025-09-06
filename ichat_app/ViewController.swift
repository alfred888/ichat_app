import UIKit

class ViewController: UIViewController {
    
    private let videoCallButton = UIButton(type: .system)
    private let settingsButton = UIButton(type: .system)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        // 标题
        let titleLabel = UILabel()
        titleLabel.text = "视频对讲系统"
        titleLabel.font = UIFont.systemFont(ofSize: 28, weight: .bold)
        titleLabel.textAlignment = .center
        titleLabel.textColor = .label
        view.addSubview(titleLabel)
        
        // 副标题
        let subtitleLabel = UILabel()
        subtitleLabel.text = "连接云台设备进行视频通话"
        subtitleLabel.font = UIFont.systemFont(ofSize: 16)
        subtitleLabel.textAlignment = .center
        subtitleLabel.textColor = .secondaryLabel
        view.addSubview(subtitleLabel)
        
        // 视频通话按钮
        videoCallButton.setTitle("开始视频通话", for: .normal)
        videoCallButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        videoCallButton.backgroundColor = .systemBlue
        videoCallButton.setTitleColor(.white, for: .normal)
        videoCallButton.layer.cornerRadius = 12
        videoCallButton.addTarget(self, action: #selector(videoCallButtonTapped), for: .touchUpInside)
        view.addSubview(videoCallButton)
        
        // 设置按钮
        settingsButton.setTitle("设置", for: .normal)
        settingsButton.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        settingsButton.backgroundColor = .systemGray5
        settingsButton.setTitleColor(.label, for: .normal)
        settingsButton.layer.cornerRadius = 8
        settingsButton.addTarget(self, action: #selector(settingsButtonTapped), for: .touchUpInside)
        view.addSubview(settingsButton)
        
        // 设置约束
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        videoCallButton.translatesAutoresizingMaskIntoConstraints = false
        settingsButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 100),
            
            subtitleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10),
            subtitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            subtitleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            videoCallButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            videoCallButton.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            videoCallButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            videoCallButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            videoCallButton.heightAnchor.constraint(equalToConstant: 50),
            
            settingsButton.topAnchor.constraint(equalTo: videoCallButton.bottomAnchor, constant: 20),
            settingsButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            settingsButton.widthAnchor.constraint(equalToConstant: 100),
            settingsButton.heightAnchor.constraint(equalToConstant: 40)
        ])
    }
    
    private func setupConstraints() {
        // 约束已在setupUI中设置
    }
    
    @objc private func videoCallButtonTapped() {
        let videoCallVC = VideoCallViewController()
        videoCallVC.modalPresentationStyle = .fullScreen
        present(videoCallVC, animated: true)
    }
    
    @objc private func settingsButtonTapped() {
        let alert = UIAlertController(title: "设置", message: "设置功能开发中...", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        present(alert, animated: true)
    }
}
