import Foundation
import Network

protocol NetworkManagerDelegate: AnyObject {
    func didConnect()
    func didDisconnect()
    func didReceiveMessage(_ message: String)
    func didReceiveError(_ error: Error)
}

class NetworkManager: NSObject {
    weak var delegate: NetworkManagerDelegate?
    
    private var webSocket: URLSessionWebSocketTask?
    private var urlSession: URLSession?
    private var isConnected = false
    
    override init() {
        super.init()
        setupURLSession()
    }
    
    private func setupURLSession() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 10
        config.timeoutIntervalForResource = 30
        urlSession = URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }
    
    func connect(to ipAddress: String, port: Int = 8080) {
        guard let url = URL(string: "ws://\(ipAddress):\(port)") else {
            delegate?.didReceiveError(NetworkError.invalidURL)
            return
        }
        
        webSocket = urlSession?.webSocketTask(with: url)
        webSocket?.resume()
        
        // 开始接收消息
        receiveMessage()
    }
    
    func disconnect() {
        webSocket?.cancel(with: .goingAway, reason: nil)
        webSocket = nil
        isConnected = false
        delegate?.didDisconnect()
    }
    
    func sendMessage(_ message: String) {
        guard isConnected else {
            delegate?.didReceiveError(NetworkError.notConnected)
            return
        }
        
        let data = message.data(using: .utf8)!
        let message = URLSessionWebSocketTask.Message.data(data)
        
        webSocket?.send(message) { [weak self] error in
            if let error = error {
                self?.delegate?.didReceiveError(error)
            }
        }
    }
    
    func sendPanTiltCommand(_ command: String) {
        let jsonMessage = """
        {
            "type": "panTilt",
            "command": "\(command)",
            "timestamp": \(Date().timeIntervalSince1970)
        }
        """
        sendMessage(jsonMessage)
    }
    
    private func receiveMessage() {
        webSocket?.receive { [weak self] result in
            switch result {
            case .success(let message):
                switch message {
                case .data(let data):
                    if let string = String(data: data, encoding: .utf8) {
                        self?.delegate?.didReceiveMessage(string)
                    }
                case .string(let string):
                    self?.delegate?.didReceiveMessage(string)
                @unknown default:
                    break
                }
                // 继续接收下一条消息
                self?.receiveMessage()
            case .failure(let error):
                self?.delegate?.didReceiveError(error)
            }
        }
    }
}

// MARK: - URLSessionWebSocketDelegate
extension NetworkManager: URLSessionWebSocketDelegate {
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        isConnected = true
        delegate?.didConnect()
    }
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        isConnected = false
        delegate?.didDisconnect()
    }
}

// MARK: - Network Errors
enum NetworkError: Error, LocalizedError {
    case invalidURL
    case notConnected
    case connectionFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "无效的URL地址"
        case .notConnected:
            return "未连接到设备"
        case .connectionFailed:
            return "连接失败"
        }
    }
}
