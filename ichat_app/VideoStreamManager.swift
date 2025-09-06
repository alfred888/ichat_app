import Foundation
import AVFoundation
import VideoToolbox

protocol VideoStreamManagerDelegate: AnyObject {
    func didReceiveVideoFrame(_ frame: Data)
    func didReceiveAudioFrame(_ frame: Data)
    func didReceiveVideoError(_ error: Error)
}

class VideoStreamManager: NSObject {
    weak var delegate: VideoStreamManagerDelegate?
    
    private var compressionSession: VTCompressionSession?
    private var decompressionSession: VTDecompressionSession?
    private var isCompressionSessionReady = false
    
    override init() {
        super.init()
        setupCompressionSession()
        setupDecompressionSession()
    }
    
    deinit {
        if let session = compressionSession {
            VTCompressionSessionInvalidate(session)
        }
        if let session = decompressionSession {
            VTDecompressionSessionInvalidate(session)
        }
    }
    
    // MARK: - Compression Setup
    private func setupCompressionSession() {
        let status = VTCompressionSessionCreate(
            allocator: kCFAllocatorDefault,
            width: 640,
            height: 480,
            codecType: kCMVideoCodecType_H264,
            encoderSpecification: nil,
            imageBufferAttributes: nil,
            compressedDataAllocator: nil,
            outputCallback: compressionOutputCallback,
            refcon: Unmanaged.passUnretained(self).toOpaque(),
            compressionSessionOut: &compressionSession
        )
        
        guard status == noErr, let session = compressionSession else {
            print("创建压缩会话失败: \(status)")
            return
        }
        
        // 设置压缩参数
        VTSessionSetProperty(session, key: kVTCompressionPropertyKey_RealTime, value: kCFBooleanTrue)
        VTSessionSetProperty(session, key: kVTCompressionPropertyKey_ProfileLevel, value: kVTProfileLevel_H264_Baseline_AutoLevel)
        VTSessionSetProperty(session, key: kVTCompressionPropertyKey_AverageBitRate, value: NSNumber(value: 1000000)) // 1Mbps
        VTSessionSetProperty(session, key: kVTCompressionPropertyKey_MaxKeyFrameInterval, value: NSNumber(value: 30))
        
        VTCompressionSessionPrepareToEncodeFrames(session)
        isCompressionSessionReady = true
    }
    
    private func setupDecompressionSession() {
        // 解压缩会话将在收到第一个视频帧时创建
        // 因为需要先有CMFormatDescription
    }
    
    // MARK: - Video Processing
    func encodeVideoFrame(_ pixelBuffer: CVPixelBuffer, timestamp: CMTime) {
        guard isCompressionSessionReady, let session = compressionSession else { return }
        
        let status = VTCompressionSessionEncodeFrame(
            session,
            imageBuffer: pixelBuffer,
            presentationTimeStamp: timestamp,
            duration: CMTime.invalid,
            frameProperties: nil,
            sourceFrameRefcon: nil,
            infoFlagsOut: nil
        )
        
        if status != noErr {
            print("编码视频帧失败: \(status)")
        }
    }
    
    func decodeVideoFrame(_ data: Data) {
        // 简化实现：直接传递数据给代理
        // 实际项目中需要完整的H.264解码实现
        delegate?.didReceiveVideoFrame(data)
    }
    
    // MARK: - Audio Processing
    func encodeAudioFrame(_ sampleBuffer: CMSampleBuffer) {
        // 音频编码实现
        // 可以使用AAC编码
    }
    
    func decodeAudioFrame(_ data: Data) {
        // 音频解码实现
    }
}

// MARK: - Compression Callback
private func compressionOutputCallback(
    outputCallbackRefCon: UnsafeMutableRawPointer?,
    sourceFrameRefCon: UnsafeMutableRawPointer?,
    status: OSStatus,
    infoFlags: VTEncodeInfoFlags,
    sampleBuffer: CMSampleBuffer?
) {
    guard status == noErr, let sampleBuffer = sampleBuffer else { return }
    
    let manager = Unmanaged<VideoStreamManager>.fromOpaque(outputCallbackRefCon!).takeUnretainedValue()
    
    // 提取H.264数据
    if let dataBuffer = CMSampleBufferGetDataBuffer(sampleBuffer) {
        let length = CMBlockBufferGetDataLength(dataBuffer)
        var dataPointer: UnsafeMutablePointer<Int8>?
        CMBlockBufferGetDataPointer(dataBuffer, atOffset: 0, lengthAtOffsetOut: nil, totalLengthOut: nil, dataPointerOut: &dataPointer)
        
        if let pointer = dataPointer {
            let data = Data(bytes: pointer, count: length)
            manager.delegate?.didReceiveVideoFrame(data)
        }
    }
}
