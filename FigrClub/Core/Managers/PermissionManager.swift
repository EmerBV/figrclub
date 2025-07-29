//
//  PermissionManager.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 29/7/25.
//

import Foundation
import AVFoundation
import Photos
import UIKit
import Combine

/// Tipos de permisos disponibles
enum PermissionType: String, CaseIterable {
    case camera = "camera"
    case microphone = "microphone"
    case photoLibrary = "photoLibrary"
    case notifications = "notifications"
    
    var displayName: String {
        switch self {
        case .camera:
            return "Cámara"
        case .microphone:
            return "Micrófono"
        case .photoLibrary:
            return "Librería de Fotos"
        case .notifications:
            return "Notificaciones"
        }
    }
    
    var description: String {
        switch self {
        case .camera:
            return "Para tomar fotos y grabar videos de tus figuras"
        case .microphone:
            return "Para grabar audio en tus videos"
        case .photoLibrary:
            return "Para seleccionar fotos de tu galería"
        case .notifications:
            return "Para recibir actualizaciones y notificaciones"
        }
    }
    
    var iconName: String {
        switch self {
        case .camera:
            return "camera.fill"
        case .microphone:
            return "mic.fill"
        case .photoLibrary:
            return "photo.fill"
        case .notifications:
            return "bell.fill"
        }
    }
}

/// Estados de autorización de permisos
enum PermissionStatus {
    case notDetermined
    case denied
    case authorized
    case restricted
    case limited // Solo para Photo Library en iOS 14+
    
    var isAuthorized: Bool {
        switch self {
        case .authorized, .limited:
            return true
        default:
            return false
        }
    }
    
    var canRequest: Bool {
        return self == .notDetermined
    }
}

/// Protocolo para delegar eventos de permisos
protocol PermissionManagerDelegate: AnyObject {
    func permissionManager(_ manager: PermissionManager, didUpdateStatus status: PermissionStatus, for permission: PermissionType)
    func permissionManager(_ manager: PermissionManager, didFailWithError error: PermissionError)
}

/// Errores relacionados con permisos
enum PermissionError: LocalizedError {
    case permissionDenied(PermissionType)
    case permissionRestricted(PermissionType)
    case unknownError(PermissionType)
    
    var errorDescription: String? {
        switch self {
        case .permissionDenied(let type):
            return "Permiso denegado para \(type.displayName)"
        case .permissionRestricted(let type):
            return "Permiso restringido para \(type.displayName)"
        case .unknownError(let type):
            return "Error desconocido al solicitar permiso para \(type.displayName)"
        }
    }
}

/// Gestor centralizado de permisos del sistema
@MainActor
final class PermissionManager: ObservableObject {
    
    // MARK: - Singleton
    static let shared = PermissionManager()
    
    // MARK: - Published Properties
    @Published private(set) var cameraStatus: PermissionStatus = .notDetermined
    @Published private(set) var microphoneStatus: PermissionStatus = .notDetermined
    @Published private(set) var photoLibraryStatus: PermissionStatus = .notDetermined
    @Published private(set) var notificationsStatus: PermissionStatus = .notDetermined
    
    // MARK: - Private Properties
    weak var delegate: PermissionManagerDelegate?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    private init() {
        updateAllStatuses()
        setupStatusObserving()
    }
    
    // MARK: - Public Methods
    
    /// Solicita permiso para un tipo específico
    /// - Parameter type: Tipo de permiso a solicitar
    /// - Returns: Estado del permiso después de la solicitud
    func requestPermission(for type: PermissionType) async -> PermissionStatus {
        Logger.info("Requesting permission for \(type.rawValue)")
        
        switch type {
        case .camera:
            return await requestCameraPermission()
        case .microphone:
            return await requestMicrophonePermission()
        case .photoLibrary:
            return await requestPhotoLibraryPermission()
        case .notifications:
            return await requestNotificationPermission()
        }
    }
    
    /// Obtiene el estado actual de un permiso
    /// - Parameter type: Tipo de permiso
    /// - Returns: Estado actual del permiso
    func getPermissionStatus(for type: PermissionType) -> PermissionStatus {
        switch type {
        case .camera:
            return cameraStatus
        case .microphone:
            return microphoneStatus
        case .photoLibrary:
            return photoLibraryStatus
        case .notifications:
            return notificationsStatus
        }
    }
    
    /// Verifica si un permiso está autorizado
    /// - Parameter type: Tipo de permiso
    /// - Returns: true si está autorizado
    func isPermissionAuthorized(for type: PermissionType) -> Bool {
        return getPermissionStatus(for: type).isAuthorized
    }
    
    /// Solicita múltiples permisos de forma secuencial
    /// - Parameter types: Array de tipos de permisos
    /// - Returns: Diccionario con los estados finales
    func requestMultiplePermissions(for types: [PermissionType]) async -> [PermissionType: PermissionStatus] {
        var results: [PermissionType: PermissionStatus] = [:]
        
        for type in types {
            let status = await requestPermission(for: type)
            results[type] = status
        }
        
        return results
    }
    
    /// Abre la configuración de la aplicación
    func openAppSettings() {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString),
              UIApplication.shared.canOpenURL(settingsUrl) else {
            Logger.error("Cannot open app settings")
            return
        }
        
        UIApplication.shared.open(settingsUrl) { success in
            Logger.info("Opened app settings: \(success)")
        }
    }
    
    /// Actualiza todos los estados de permisos
    func updateAllStatuses() {
        updateCameraStatus()
        updateMicrophoneStatus()
        updatePhotoLibraryStatus()
        updateNotificationStatus()
    }
    
    // MARK: - Private Methods - Camera
    
    private func requestCameraPermission() async -> PermissionStatus {
        let currentStatus = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch currentStatus {
        case .authorized:
            await updateCameraStatus()
            return cameraStatus
            
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            await updateCameraStatus()
            
            if granted {
                Logger.info("Camera permission granted")
            } else {
                Logger.warning("Camera permission denied by user")
                delegate?.permissionManager(self, didFailWithError: .permissionDenied(.camera))
            }
            return cameraStatus
            
        case .denied:
            Logger.warning("Camera permission previously denied")
            delegate?.permissionManager(self, didFailWithError: .permissionDenied(.camera))
            return .denied
            
        case .restricted:
            Logger.warning("Camera permission restricted")
            delegate?.permissionManager(self, didFailWithError: .permissionRestricted(.camera))
            return .restricted
            
        @unknown default:
            Logger.error("Unknown camera permission status")
            return .denied
        }
    }
    
    private func updateCameraStatus() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        let newStatus = mapAVAuthorizationStatus(status)
        
        if cameraStatus != newStatus {
            cameraStatus = newStatus
            delegate?.permissionManager(self, didUpdateStatus: newStatus, for: .camera)
        }
    }
    
    // MARK: - Private Methods - Microphone
    
    private func requestMicrophonePermission() async -> PermissionStatus {
        let currentStatus = AVCaptureDevice.authorizationStatus(for: .audio)
        
        switch currentStatus {
        case .authorized:
            await updateMicrophoneStatus()
            return microphoneStatus
            
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .audio)
            await updateMicrophoneStatus()
            
            if granted {
                Logger.info("Microphone permission granted")
            } else {
                Logger.warning("Microphone permission denied by user")
                delegate?.permissionManager(self, didFailWithError: .permissionDenied(.microphone))
            }
            return microphoneStatus
            
        case .denied:
            Logger.warning("Microphone permission previously denied")
            delegate?.permissionManager(self, didFailWithError: .permissionDenied(.microphone))
            return .denied
            
        case .restricted:
            Logger.warning("Microphone permission restricted")
            delegate?.permissionManager(self, didFailWithError: .permissionRestricted(.microphone))
            return .restricted
            
        @unknown default:
            Logger.error("Unknown microphone permission status")
            return .denied
        }
    }
    
    private func updateMicrophoneStatus() {
        let status = AVCaptureDevice.authorizationStatus(for: .audio)
        let newStatus = mapAVAuthorizationStatus(status)
        
        if microphoneStatus != newStatus {
            microphoneStatus = newStatus
            delegate?.permissionManager(self, didUpdateStatus: newStatus, for: .microphone)
        }
    }
    
    // MARK: - Private Methods - Photo Library
    
    private func requestPhotoLibraryPermission() async -> PermissionStatus {
        let currentStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        
        switch currentStatus {
        case .authorized, .limited:
            await updatePhotoLibraryStatus()
            return photoLibraryStatus
            
        case .notDetermined:
            let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
            await updatePhotoLibraryStatus()
            
            switch status {
            case .authorized, .limited:
                Logger.info("Photo library permission granted")
            case .denied:
                Logger.warning("Photo library permission denied by user")
                delegate?.permissionManager(self, didFailWithError: .permissionDenied(.photoLibrary))
            case .restricted:
                Logger.warning("Photo library permission restricted")
                delegate?.permissionManager(self, didFailWithError: .permissionRestricted(.photoLibrary))
            default:
                break
            }
            return photoLibraryStatus
            
        case .denied:
            Logger.warning("Photo library permission previously denied")
            delegate?.permissionManager(self, didFailWithError: .permissionDenied(.photoLibrary))
            return .denied
            
        case .restricted:
            Logger.warning("Photo library permission restricted")
            delegate?.permissionManager(self, didFailWithError: .permissionRestricted(.photoLibrary))
            return .restricted
            
        @unknown default:
            Logger.error("Unknown photo library permission status")
            return .denied
        }
    }
    
    private func updatePhotoLibraryStatus() {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        let newStatus = mapPHAuthorizationStatus(status)
        
        if photoLibraryStatus != newStatus {
            photoLibraryStatus = newStatus
            delegate?.permissionManager(self, didUpdateStatus: newStatus, for: .photoLibrary)
        }
    }
    
    // MARK: - Private Methods - Notifications
    
    private func requestNotificationPermission() async -> PermissionStatus {
        let center = UNUserNotificationCenter.current()
        
        do {
            let settings = await center.notificationSettings()
            
            switch settings.authorizationStatus {
            case .authorized, .provisional, .ephemeral:
                await updateNotificationStatus()
                return notificationsStatus
                
            case .notDetermined:
                let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound, .provisional])
                await updateNotificationStatus()
                
                if granted {
                    Logger.info("Notification permission granted")
                } else {
                    Logger.warning("Notification permission denied by user")
                    delegate?.permissionManager(self, didFailWithError: .permissionDenied(.notifications))
                }
                return notificationsStatus
                
            case .denied:
                Logger.warning("Notification permission previously denied")
                delegate?.permissionManager(self, didFailWithError: .permissionDenied(.notifications))
                return .denied
                
            @unknown default:
                Logger.error("Unknown notification permission status")
                return .denied
            }
        } catch {
            Logger.error("Error requesting notification permission: \(error)")
            delegate?.permissionManager(self, didFailWithError: .unknownError(.notifications))
            return .denied
        }
    }
    
    private func updateNotificationStatus() async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        let newStatus = mapUNAuthorizationStatus(settings.authorizationStatus)
        
        if notificationsStatus != newStatus {
            notificationsStatus = newStatus
            delegate?.permissionManager(self, didUpdateStatus: newStatus, for: .notifications)
        }
    }
    
    private func updateNotificationStatus() {
        Task {
            await updateNotificationStatus()
        }
    }
    
    // MARK: - Mapping Helpers
    
    private func mapAVAuthorizationStatus(_ status: AVAuthorizationStatus) -> PermissionStatus {
        switch status {
        case .notDetermined:
            return .notDetermined
        case .denied:
            return .denied
        case .authorized:
            return .authorized
        case .restricted:
            return .restricted
        @unknown default:
            return .denied
        }
    }
    
    private func mapPHAuthorizationStatus(_ status: PHAuthorizationStatus) -> PermissionStatus {
        switch status {
        case .notDetermined:
            return .notDetermined
        case .denied:
            return .denied
        case .authorized:
            return .authorized
        case .restricted:
            return .restricted
        case .limited:
            return .limited
        @unknown default:
            return .denied
        }
    }
    
    private func mapUNAuthorizationStatus(_ status: UNAuthorizationStatus) -> PermissionStatus {
        switch status {
        case .notDetermined:
            return .notDetermined
        case .denied:
            return .denied
        case .authorized, .provisional, .ephemeral:
            return .authorized
        @unknown default:
            return .denied
        }
    }
    
    // MARK: - Status Observing
    
    private func setupStatusObserving() {
        // Observar cambios cuando la app vuelve del foreground
        NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
            .sink { [weak self] _ in
                self?.updateAllStatuses()
            }
            .store(in: &cancellables)
    }
}
