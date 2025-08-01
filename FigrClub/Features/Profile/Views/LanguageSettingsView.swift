//
//  LanguageSettingsView.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 16/7/25.
//

import SwiftUI

struct LanguageSettingsView: View {
    @Environment(\.localizationManager) private var localizationManager
    @Environment(\.dismiss) private var dismiss
    @State private var selectedLanguage: SupportedLanguage
    @State private var showLanguageChanged = false
    
    init() {
        // Initialize with current language from environment
        // This will be updated in onAppear
        self._selectedLanguage = State(initialValue: .spanish)
    }
    
    var body: some View {
        FigrNavigationStack {
            VStack(spacing: 24) {
                // Header
                headerSection
                
                // Language Options
                languageOptionsSection
                
                Spacer()
                
                // Save Button
                saveButtonSection
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .navigationTitle(localizationManager.localizedString(for: .changeLanguage))
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(localizationManager.localizedString(for: .close)) {
                        dismiss()
                    }
                    .themedTextColor(.primary)
                }
            }
            .onAppear {
                selectedLanguage = localizationManager.currentLanguage
            }
            .alert(
                localizationManager.localizedString(for: .languageChanged, arguments: selectedLanguage.displayName),
                isPresented: $showLanguageChanged
            ) {
                Button(localizationManager.localizedString(for: .ok)) {
                    dismiss()
                }
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "globe")
                .font(.system(size: 50))
                .foregroundColor(.blue)
            
            Text(localizationManager.localizedString(for: .language))
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text("Selecciona tu idioma preferido")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    private var languageOptionsSection: some View {
        VStack(spacing: 16) {
            ForEach(SupportedLanguage.allCases, id: \.self) { language in
                languageOptionView(for: language)
            }
        }
    }
    
    private func languageOptionView(for language: SupportedLanguage) -> some View {
        Button {
            selectedLanguage = language
        } label: {
            HStack(spacing: 16) {
                // Flag
                Text(language.flag)
                    .font(.system(size: 32))
                
                // Language info
                VStack(alignment: .leading, spacing: 4) {
                    Text(language.displayName)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(language.nativeName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Selection indicator
                if selectedLanguage == language {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.blue)
                } else {
                    Image(systemName: "circle")
                        .font(.system(size: 24))
                        .foregroundColor(.gray)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(selectedLanguage == language ? Color.blue.opacity(0.1) : Color(.systemGray6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(selectedLanguage == language ? Color.blue : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(.plain)
    }
    
    private var saveButtonSection: some View {
        VStack(spacing: 16) {
            Button {
                applyLanguageChange()
            } label: {
                Text(localizationManager.localizedString(for: .save))
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(hasLanguageChanged ? .blue : .gray)
                    )
            }
            .disabled(!hasLanguageChanged)
            
            if localizationManager.isSystemLanguageDetected {
                Text("Idioma detectado automáticamente: \(localizationManager.currentLanguage.displayName)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    private var hasLanguageChanged: Bool {
        selectedLanguage != localizationManager.currentLanguage
    }
    
    private func applyLanguageChange() {
        Logger.info("🌍 LanguageSettingsView: Changing language to \(selectedLanguage.displayName)")
        
        localizationManager.setLanguage(selectedLanguage)
        showLanguageChanged = true
        
        Logger.info("✅ LanguageSettingsView: Language changed successfully")
    }
}

// MARK: - Preview
/*
 #if DEBUG
 struct LanguageSettingsView_Previews: PreviewProvider {
 static var previews: some View {
 LanguageSettingsView()
 .localizationManager(LocalizationManager.preview())
 }
 }
 #endif
 */
