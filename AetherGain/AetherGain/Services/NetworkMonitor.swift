//
//  NetworkMonitor.swift
//  AetherGain
//
//  Criterion 9: monitor connectivity, notify UI, retry Firestore network on reconnect.
//

import Foundation
import Combine
import Network
import FirebaseFirestore
import SwiftUI

@MainActor
final class NetworkMonitor: ObservableObject {
    static let shared = NetworkMonitor()

    @Published private(set) var isOnline: Bool = true
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "aethergain.network.monitor")
    private var started = false

    func start() {
        guard !started else { return }
        started = true
        monitor.pathUpdateHandler = { [weak self] path in
            let online = path.status == .satisfied
            Task { @MainActor in
                self?.apply(online: online)
            }
        }
        monitor.start(queue: queue)
    }

    private func apply(online: Bool) {
        let wasOnline = isOnline
        isOnline = online

        if !wasOnline && online {
            // Force Firestore to flush queued writes and resume listeners.
            Firestore.firestore().enableNetwork { _ in }
            AGToastCenter.shared.show("Back online — syncing your data.", kind: .success)
        } else if wasOnline && !online {
            AGToastCenter.shared.show("You're offline. Changes will sync when reconnected.", kind: .info)
        }
    }
}
