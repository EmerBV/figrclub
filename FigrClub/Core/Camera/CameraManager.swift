//
//  CameraManager.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 29/7/25.
//

import AVFoundation
import UIKit
import Combine

/// Protocolo para manejar eventos de la cámara
protocol CameraManagerDelegate {
    func cameraManager(_ manager: CameraManager, didCapturePhoto image: UIImage)
    func cameraManager(_ manager: CameraManager, didStartRecording url: URL)
    func cameraManager(_ manager: CameraManager, didFinishRecording url: URL)
    func cameraManager(_ manager: CameraManager, didFailWithError error: CameraError)
    func cameraManager(_ manager: CameraManager, didUpdateRecordingDuration duration: TimeInterval)
}

/// Errores específicos de la cámara
enum CameraError: LocalizedError {
    case notAuthorized
    case configurationFailed
    case captureSessionAlreadyRunning
    case captureSessionNotRunning
    case noCameraAvailable
    case photoCaptureFailed
    case videoRecordingFailed
    case deviceNotFound
    
    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return "Camera access is not authorized"
        case .configurationFailed:
            return "Failed to configure camera session"
        case .captureSessionAlreadyRunning:
            return "Capture session is already running"
        case .captureSessionNotRunning:
            return "Capture session is not running"
        case .noCameraAvailable:
            return "No camera is available"
        case .photoCaptureFailed:
            return "Failed to capture photo"
        case .videoRecordingFailed:
            return "Failed to record video"
        case .deviceNotFound:
            return "Camera device not found"
        }
    }
}

/// Posición de la cámara
enum CameraPosition {
    case front
    case back
    
    var avCaptureDevicePosition: AVCaptureDevice.Position {
        switch self {
        case .front: return .front
        case .back: return .back
        }
    }
}

/// Modo de flash
enum CameraFlashMode {
    case off
    case on
    case auto
    
    var avFlashMode: AVCaptureDevice.FlashMode {
        switch self {
        case .off: return .off
        case .on: return .on
        case .auto: return .auto
        }
    }
}

/// Gestor principal de la cámara usando AVCaptureSession
@MainActor
final class CameraManager: NSObject, ObservableObject {
    
    // MARK: - Published Properties
    @Published var isSessionRunning = false
    @Published var isRecording = false
    @Published var recordingDuration: TimeInterval = 0
    @Published var cameraPosition: CameraPosition = .back
    @Published var flashMode: CameraFlashMode = .off
    @Published var zoom: CGFloat = 1.0
    @Published var isConfigured = false
    @Published var permissionGranted = false
    
    // MARK: - Private Properties
    private let captureSession = AVCaptureSession()
    private var videoDeviceInput: AVCaptureDeviceInput?
    private var photoOutput = AVCapturePhotoOutput()
    private var videoOutput = AVCaptureMovieFileOutput()
    private var previewLayer: AVCaptureVideoPreviewLayer?
    
    private let sessionQueue = DispatchQueue(label: "camera.session.queue")
    private var setupResult: SessionSetupResult = .success
    private var recordingTimer: Timer?
    private var currentVideoURL: URL?
    
    var delegate: CameraManagerDelegate?
    
    // MARK: - Session Setup Result
    private enum SessionSetupResult {
        case success
        case notAuthorized
        case configurationFailed
    }
    
    // MARK: - Initialization
    override init() {
        super.init()
        
        // Check camera permissions without requesting
        updatePermissionStatus()
        
        sessionQueue.async { [weak self] in
            self?.configureSession()
        }
    }
    
    deinit {
        Task { @MainActor in
            await cleanup()
        }
    }
    
    // MARK: - Public Methods
    
    /// Actualiza el estado de permisos sin solicitarlos
    private func updatePermissionStatus() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .authorized:
            permissionGranted = true
            setupResult = .success
        case .denied, .restricted:
            permissionGranted = false
            setupResult = .notAuthorized
        case .notDetermined:
            permissionGranted = false
            setupResult = .success // Permitimos configurar, pero solicitaremos permisos al iniciar
        @unknown default:
            permissionGranted = false
            setupResult = .notAuthorized
        }
    }
    
    /// Solicita permisos de cámara si es necesario
    func requestCameraPermissionIfNeeded() async -> Bool {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch status {
        case .authorized:
            await MainActor.run {
                permissionGranted = true
            }
            return true
            
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            await MainActor.run {
                permissionGranted = granted
                if !granted {
                    setupResult = .notAuthorized
                }
            }
            return granted
            
        default:
            await MainActor.run {
                permissionGranted = false
                setupResult = .notAuthorized
            }
            return false
        }
    }
    
    /// Configura la sesión de captura
    private func configureSession() {
        guard setupResult == .success else { return }
        
        captureSession.beginConfiguration()
        captureSession.sessionPreset = .photo
        
        // Configurar entrada de video
        do {
            var defaultVideoDevice: AVCaptureDevice?
            
            if let backCameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) {
                defaultVideoDevice = backCameraDevice
            } else if let frontCameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) {
                defaultVideoDevice = frontCameraDevice
            }
            
            guard let videoDevice = defaultVideoDevice else {
                Logger.error("Default video device is unavailable")
                setupResult = .configurationFailed
                captureSession.commitConfiguration()
                return
            }
            
            let videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)
            
            if captureSession.canAddInput(videoDeviceInput) {
                captureSession.addInput(videoDeviceInput)
                self.videoDeviceInput = videoDeviceInput
            } else {
                Logger.error("Couldn't add video device input to the session")
                setupResult = .configurationFailed
                captureSession.commitConfiguration()
                return
            }
        } catch {
            Logger.error("Couldn't create video device input: \(error)")
            setupResult = .configurationFailed
            captureSession.commitConfiguration()
            return
        }
        
        // Configurar salida de foto
        if captureSession.canAddOutput(photoOutput) {
            captureSession.addOutput(photoOutput)
            
            photoOutput.isHighResolutionCaptureEnabled = true
            photoOutput.maxPhotoQualityPrioritization = .quality
        } else {
            Logger.error("Could not add photo output to the session")
            setupResult = .configurationFailed
            captureSession.commitConfiguration()
            return
        }
        
        // Configurar salida de video
        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
            
            // Configurar conexión de video
            if let connection = videoOutput.connection(with: .video) {
                if connection.isVideoStabilizationSupported {
                    connection.preferredVideoStabilizationMode = .auto
                }
            }
        } else {
            Logger.error("Could not add video output to the session")
            setupResult = .configurationFailed
            captureSession.commitConfiguration()
            return
        }
        
        captureSession.commitConfiguration()
        
        Task { @MainActor in
            self.isConfigured = true
        }
    }
    
    /// Inicia la sesión de captura
    func startSession() async {
        // Solicitar permisos si es necesario
        let hasPermission = await requestCameraPermissionIfNeeded()
        
        guard hasPermission else {
            await MainActor.run {
                delegate?.cameraManager(self, didFailWithError: .notAuthorized)
            }
            return
        }
        
        await withCheckedContinuation { continuation in
            sessionQueue.async { [weak self] in
                guard let self = self else { 
                    continuation.resume()
                    return 
                }
                
                switch self.setupResult {
                case .success:
                    self.captureSession.startRunning()
                    Task { @MainActor in
                        self.isSessionRunning = self.captureSession.isRunning
                        continuation.resume()
                    }
                    
                case .notAuthorized:
                    Task { @MainActor in
                        self.delegate?.cameraManager(self, didFailWithError: .notAuthorized)
                        continuation.resume()
                    }
                    
                case .configurationFailed:
                    Task { @MainActor in
                        self.delegate?.cameraManager(self, didFailWithError: .configurationFailed)
                        continuation.resume()
                    }
                }
            }
        }
    }
    
    /// Detiene la sesión de captura
    func stopSession() async {
        await withCheckedContinuation { continuation in
            sessionQueue.async { [weak self] in
                guard let self = self else { 
                    continuation.resume()
                    return 
                }
                
                if self.captureSession.isRunning {
                    self.captureSession.stopRunning()
                    Task { @MainActor in
                        self.isSessionRunning = false
                        continuation.resume()
                    }
                } else {
                    continuation.resume()
                }
            }
        }
    }
    
    /// Captura una foto
    func capturePhoto() async throws {
        guard isSessionRunning else {
            throw CameraError.captureSessionNotRunning
        }
        
        // Configurar formato de salida con HEVC si está disponible
        let photoSettings: AVCapturePhotoSettings
        if photoOutput.availablePhotoCodecTypes.contains(AVVideoCodecType.hevc) {
            photoSettings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.hevc])
        } else {
            photoSettings = AVCapturePhotoSettings()
        }
        
        // Configurar flash
        if let videoDeviceInput = videoDeviceInput,
           videoDeviceInput.device.isFlashAvailable {
            photoSettings.flashMode = flashMode.avFlashMode
        }
        
        // Habilitar corrección de lente
        if let photoOutputConnection = photoOutput.connection(with: .video) {
            if photoOutputConnection.isVideoOrientationSupported {
                photoOutputConnection.videoOrientation = .portrait
            }
        }
        
        photoOutput.capturePhoto(with: photoSettings, delegate: self)
    }
    
    /// Inicia la grabación de video
    func startVideoRecording() async throws {
        guard isSessionRunning else {
            throw CameraError.captureSessionNotRunning
        }
        
        guard !isRecording else {
            throw CameraError.captureSessionAlreadyRunning
        }
        
        // Crear URL para el archivo de video
        let outputURL = createVideoFileURL()
        currentVideoURL = outputURL
        
        // Configurar orientación
        if let connection = videoOutput.connection(with: .video) {
            if connection.isVideoOrientationSupported {
                connection.videoOrientation = .portrait
            }
        }
        
        // Iniciar grabación
        videoOutput.startRecording(to: outputURL, recordingDelegate: self)
        
        await MainActor.run {
            isRecording = true
            recordingDuration = 0
            startRecordingTimer()
            delegate?.cameraManager(self, didStartRecording: outputURL)
        }
    }
    
    /// Detiene la grabación de video
    func stopVideoRecording() {
        guard isRecording else { return }
        
        videoOutput.stopRecording()
        stopRecordingTimer()
        
        Task { @MainActor in
            isRecording = false
        }
    }
    
    /// Cambia la posición de la cámara
    func flipCamera() async throws {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            let currentVideoDevice = self.videoDeviceInput?.device
            let currentPosition = currentVideoDevice?.position
            
            let preferredPosition: AVCaptureDevice.Position
            let preferredDeviceType: AVCaptureDevice.DeviceType
            
            switch currentPosition {
            case .unspecified, .front:
                preferredPosition = .back
                preferredDeviceType = .builtInWideAngleCamera
                
            case .back:
                preferredPosition = .front
                preferredDeviceType = .builtInWideAngleCamera
                
            case .none:
                Logger.error("Unknown capture position. Defaulting to back, wide-angle camera.")
                preferredPosition = .back
                preferredDeviceType = .builtInWideAngleCamera
                
            @unknown default:
                Logger.error("Unknown capture position. Defaulting to back, wide-angle camera.")
                preferredPosition = .back
                preferredDeviceType = .builtInWideAngleCamera
            }
            
            let devices = self.videoDeviceDiscoverySession.devices
            var newVideoDevice: AVCaptureDevice?
            
            // Buscar dispositivo con posición preferida
            newVideoDevice = devices.first { device in
                return device.position == preferredPosition && device.deviceType == preferredDeviceType
            }
            
            if let videoDevice = newVideoDevice {
                do {
                    let videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)
                    
                    self.captureSession.beginConfiguration()
                    
                    // Remover entrada actual
                    if let currentVideoDeviceInput = self.videoDeviceInput {
                        self.captureSession.removeInput(currentVideoDeviceInput)
                    }
                    
                    // Agregar nueva entrada
                    if self.captureSession.canAddInput(videoDeviceInput) {
                        self.captureSession.addInput(videoDeviceInput)
                        self.videoDeviceInput = videoDeviceInput
                    } else {
                        if let currentVideoDeviceInput = self.videoDeviceInput {
                            self.captureSession.addInput(currentVideoDeviceInput)
                        }
                    }
                    
                    // Actualizar conexión de salida de foto
                    if let photoOutputConnection = self.photoOutput.connection(with: .video) {
                        if photoOutputConnection.isVideoOrientationSupported {
                            photoOutputConnection.videoOrientation = .portrait
                        }
                    }
                    
                    self.captureSession.commitConfiguration()
                    
                    Task { @MainActor in
                        self.cameraPosition = preferredPosition == .back ? .back : .front
                    }
                    
                } catch {
                    Logger.error("Error switching cameras: \(error)")
                    Task { @MainActor in
                        self.delegate?.cameraManager(self, didFailWithError: .configurationFailed)
                    }
                }
            }
        }
    }
    
    /// Configura el nivel de zoom
    func setZoom(_ factor: CGFloat) async {
        guard let device = videoDeviceInput?.device else { return }
        
        let clampedZoomFactor = max(1.0, min(factor, device.activeFormat.videoMaxZoomFactor))
        
        do {
            try device.lockForConfiguration()
            device.videoZoomFactor = clampedZoomFactor
            device.unlockForConfiguration()
            
            await MainActor.run {
                zoom = clampedZoomFactor
            }
        } catch {
            Logger.error("Error setting zoom: \(error)")
        }
    }
    
    /// Configura el modo de flash
    func setFlashMode(_ mode: CameraFlashMode) {
        flashMode = mode
    }
    
    /// Configura el enfoque en un punto específico
    func focusAt(_ point: CGPoint) async {
        guard let device = videoDeviceInput?.device else { return }
        
        if device.isFocusPointOfInterestSupported && device.isFocusModeSupported(.autoFocus) {
            do {
                try device.lockForConfiguration()
                device.focusPointOfInterest = point
                device.focusMode = .autoFocus
                device.unlockForConfiguration()
            } catch {
                Logger.error("Error setting focus: \(error)")
            }
        }
    }
    
    /// Obtiene la capa de preview
    func getPreviewLayer() -> AVCaptureVideoPreviewLayer {
        if previewLayer == nil {
            previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            previewLayer?.videoGravity = .resizeAspectFill
        }
        return previewLayer!
    }
    
    // MARK: - Private Methods
    
    private lazy var videoDeviceDiscoverySession = AVCaptureDevice.DiscoverySession(
        deviceTypes: [.builtInWideAngleCamera, .builtInDualCamera, .builtInTrueDepthCamera],
        mediaType: .video,
        position: .unspecified
    )
    
    private func createVideoFileURL() -> URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileName = "video_\(Date().timeIntervalSince1970).mov"
        return documentsPath.appendingPathComponent(fileName)
    }
    
    private func startRecordingTimer() {
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            Task { @MainActor in
                self.recordingDuration += 0.1
                self.delegate?.cameraManager(self, didUpdateRecordingDuration: self.recordingDuration)
            }
        }
    }
    
    private func stopRecordingTimer() {
        recordingTimer?.invalidate()
        recordingTimer = nil
    }
    
    private func cleanup() async {
        await stopSession()
        stopRecordingTimer()
        previewLayer?.removeFromSuperlayer()
    }
}

// MARK: - AVCapturePhotoCaptureDelegate
extension CameraManager: AVCapturePhotoCaptureDelegate {
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            Logger.error("Photo capture error: \(error)")
            delegate?.cameraManager(self, didFailWithError: .photoCaptureFailed)
            return
        }
        
        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            Logger.error("Could not create image from photo data")
            delegate?.cameraManager(self, didFailWithError: .photoCaptureFailed)
            return
        }
        
        // Aplicar orientación correcta
        let orientedImage = image.fixedOrientation()
        delegate?.cameraManager(self, didCapturePhoto: orientedImage)
    }
}

// MARK: - AVCaptureFileOutputRecordingDelegate
extension CameraManager: AVCaptureFileOutputRecordingDelegate {
    
    func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {
        Logger.info("Started recording to \(fileURL)")
    }
    
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        
        stopRecordingTimer()
        
        if let error = error {
            Logger.error("Video recording error: \(error)")
            delegate?.cameraManager(self, didFailWithError: .videoRecordingFailed)
            return
        }
        
        delegate?.cameraManager(self, didFinishRecording: outputFileURL)
        Logger.info("Finished recording to \(outputFileURL)")
    }
}

// MARK: - UIImage Extension
private extension UIImage {
    func fixedOrientation() -> UIImage {
        if imageOrientation == .up {
            return self
        }
        
        var transform = CGAffineTransform.identity
        
        switch imageOrientation {
        case .down, .downMirrored:
            transform = transform.translatedBy(x: size.width, y: size.height)
            transform = transform.rotated(by: .pi)
        case .left, .leftMirrored:
            transform = transform.translatedBy(x: size.width, y: 0)
            transform = transform.rotated(by: .pi / 2)
        case .right, .rightMirrored:
            transform = transform.translatedBy(x: 0, y: size.height)
            transform = transform.rotated(by: -.pi / 2)
        default:
            break
        }
        
        switch imageOrientation {
        case .upMirrored, .downMirrored:
            transform = transform.translatedBy(x: size.width, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
        case .leftMirrored, .rightMirrored:
            transform = transform.translatedBy(x: size.height, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
        default:
            break
        }
        
        let ctx = CGContext(data: nil, width: Int(size.width), height: Int(size.height),
                            bitsPerComponent: cgImage!.bitsPerComponent, bytesPerRow: 0,
                            space: cgImage!.colorSpace!, bitmapInfo: cgImage!.bitmapInfo.rawValue)
        ctx?.concatenate(transform)
        
        switch imageOrientation {
        case .left, .leftMirrored, .right, .rightMirrored:
            ctx?.draw(cgImage!, in: CGRect(x: 0, y: 0, width: size.height, height: size.width))
        default:
            ctx?.draw(cgImage!, in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        }
        
        let cgImage = ctx?.makeImage()
        return UIImage(cgImage: cgImage!)
    }
}
