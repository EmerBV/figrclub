//
//  KeyboardObserver.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 27/6/25.
//

import Foundation
import SwiftUI
import Combine

final class KeyboardObserver: ObservableObject {
    @Published var keyboardHeight: CGFloat = 0
    @Published var isKeyboardVisible = false
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        let keyboardWillShow = NotificationCenter.default
            .publisher(for: UIResponder.keyboardWillShowNotification)
            .compactMap { notification in
                (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect)?.height
            }
        
        let keyboardWillHide = NotificationCenter.default
            .publisher(for: UIResponder.keyboardWillHideNotification)
            .map { _ in CGFloat(0) }
        
        Publishers.Merge(keyboardWillShow, keyboardWillHide)
            .sink { [weak self] height in
                DispatchQueue.main.async {
                    self?.keyboardHeight = height
                    self?.isKeyboardVisible = height > 0
                }
            }
            .store(in: &cancellables)
    }
}
