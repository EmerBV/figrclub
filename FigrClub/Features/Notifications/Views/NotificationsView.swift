//
//  NotificationsView.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 30/6/25.
//

import SwiftUI

// MARK: - Notifications View
struct NotificationsView: View {
    var body: some View {}
    
    
    /*
    @StateObject private var viewModel = DependencyContainer.shared.resolve(NotificationsViewModel.self)
    
    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.notifications) { notification in
                    NotificationRowView(notification: notification)
                        .onTapGesture {
                            viewModel.markAsRead(notification)
                        }
                }
                .onDelete(perform: viewModel.deleteNotifications)
            }
            .refreshable {
                await viewModel.refreshNotifications()
            }
            .navigationTitle("Notificaciones")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Marcar como leídas") {
                        viewModel.markAllAsRead()
                    }
                    .disabled(viewModel.notifications.isEmpty)
                }
            }
        }
        .task {
            await viewModel.loadNotifications()
        }
        .onAppear {
            Analytics.shared.logScreenView(screenName: "NotificationsView")
        }
    }
     */
}
