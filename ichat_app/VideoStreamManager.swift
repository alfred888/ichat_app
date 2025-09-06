import Foundation
import AVFoundation
import VideoToolbox

protocol VideoStreamManagerDelegate: AnyObject {
    func didReceiveVideoFrame(_ frame: Data)
    func didReceiveAudioFrame(_ frame: Data)
    func didReceiveError(_ error: Error)
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
        let videoDecoderSpecification: [CFString: Any] = [
            kVTVideoDecoderSpecification_RequireHardwareAcceleratedVideoDecoder: true
        ]
        
        let destinationPixelBufferAttributes: [CFString: Any] = [
            kCVPixelBufferPixelFormatTypeKey: kCVPixelFormatType_32BGRA
        ]
        
        let status = VTDecompressionSessionCreate(
            allocator: kCFAllocatorDefault,
            formatDescription: nil,
            decoderSpecification: videoDecoderSpecification as CFDictionary,
            imageBufferAttributes: destinationPixelBufferAttributes as CFDictionary,
            outputCallback: decompressionOutputCallback,
            refcon: Unmanaged.passUnretained(self).toOpaque(),
            decompressionSessionOut: &decompressionSession
        )
        
        guard status == noErr else {
            print("创建解压缩会话失败: \(status)")
            return
        }
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
            infoFlagsOut: nil
        )
        
        if status != noErr {
            print("编码视频帧失败: \(status)")
        }
    }
    
    func decodeVideoFrame(_ data: Data) {
        guard let session = decompressionSession else { return }
        
        // 这里需要解析H.264数据并创建CMFormatDescription
        // 简化实现，实际需要更复杂的H.264解析
        let sampleBuffer = createSampleBuffer(from: data)
        guard let sampleBuffer = sampleBuffer else { return }
        
        let status = VTDecompressionSessionDecodeFrame(
            session,
            sampleBuffer: sampleBuffer,
            flags: [],
            frameRefcon: nil,
            infoFlagsOut: nil
        )
        
        if status != noErr {
            print("解码视频帧失败: \(status)")
        }
    }
    
    private func createSampleBuffer(from data: Data) -> CMSampleBuffer? {
        // 这里需要根据实际的H.264数据格式创建CMSampleBuffer
        // 简化实现，实际需要解析SPS/PPS等参数
        return nil
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

// MARK: - Decompression Callback
private func decompressionOutputCallback(
    decompressionOutputRefCon: UnsafeMutableRawPointer?,
    sourceFrameRefCon: UnsafeMutableRawPointer?,
    status: OSStatus,
    infoFlags: VTDecodeInfoFlags,
    imageBuffer: CVImageBuffer?,
    presentationTimeStamp: CMTime,
    presentationDuration: CMTime
) {
    guard status == noErr, let imageBuffer = imageBuffer else { return }
    
    let manager = Unmanaged<VideoStreamManager>.fromOpaque(decompressionOutputRefCon!).takeUnretainedValue()
    
    // 将解码后的图像缓冲区转换为数据
    CVPixelBufferLockBaseAddress(imageBuffer, .readOnly)
    defer { CVPixelBufferUnlockBaseAddress(imageBuffer, .readOnly) }
    
    if let baseAddress = CVPixelBufferGetBaseAddress(imageBuffer) {
        let width = CVPixelBufferGetWidth(imageBuffer)
        let height = CVPixelBufferGetHeight(imageBuffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer)
        let dataSize = height * bytesPerRow
        
        let data = Data(bytes: baseAddress, count: dataSize)
        manager.delegate?.didReceiveVideoFrame(data)
    }
}
