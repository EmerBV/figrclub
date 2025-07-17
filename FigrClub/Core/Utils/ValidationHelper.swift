//
//  ValidationHelper.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 15/7/25.
//

import Foundation
import Combine

// MARK: - ValidationHelper para eliminar duplicación
final class ValidationHelper {
    
    /// Crear un publisher de validación para un campo de texto
    static func createValidationPublisher<T: Publisher>(
        for publisher: T,
        using validator: @escaping (T.Output) -> ValidationResult
    ) -> AnyPublisher<ValidationResult, Never> where T.Failure == Never, T.Output: Equatable {
        return publisher
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .map { value in
                guard let stringValue = value as? String, !stringValue.isEmpty else {
                    return ValidationResult.valid
                }
                return validator(value)
            }
            .eraseToAnyPublisher()
    }
    
    /// Crear un publisher para validación de confirmación de contraseña
    static func createPasswordConfirmationPublisher(
        password: AnyPublisher<String, Never>,
        confirmPassword: AnyPublisher<String, Never>,
        localizationManager: LocalizationManagerProtocol? = nil
    ) -> AnyPublisher<ValidationResult, Never> {
        return Publishers.CombineLatest(password, confirmPassword)
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .map { password, confirmPassword in
                guard !confirmPassword.isEmpty else { return ValidationResult.valid }
                let errorMessage = localizationManager?.localizedString(for: .passwordsDontMatch) ?? "Las contraseñas no coinciden"
                return password == confirmPassword ? .valid : .invalid(errorMessage)
            }
            .eraseToAnyPublisher()
    }
}

// MARK: - Form Validation State Manager
@MainActor
final class FormValidationManager: ObservableObject {
    @Published private var validationStates: [String: ValidationResult] = [:]
    private var cancellables = Set<AnyCancellable>()
    
    func addValidation(for key: String, publisher: AnyPublisher<ValidationResult, Never>) {
        publisher
            .sink { [weak self] result in
                self?.validationStates[key] = result
            }
            .store(in: &cancellables)
    }
    
    func getValidation(for key: String) -> ValidationResult {
        return validationStates[key] ?? .valid
    }
    
    var isFormValid: Bool {
        return validationStates.values.allSatisfy { $0.isValid }
    }
    
    func clearValidations() {
        validationStates.removeAll()
    }
    
    func getErrors() -> [String] {
        return validationStates.values.compactMap { validation in
            if case .invalid(let error) = validation {
                return error
            }
            return nil
        }
    }
}

// MARK: - Validation Extensions
extension ValidationResult {
    var fieldState: FieldState {
        switch self {
        case .valid:
            return .valid
        case .invalid(let message):
            return .invalid(message)
        }
    }
} 