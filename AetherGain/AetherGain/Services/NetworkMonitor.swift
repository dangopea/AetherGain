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
import UIKit

@MainActor
final class NetworkMonitor: ObservableObject {
    static let shared = NetworkMonitor()

    @Published private(set) var isOnline: Bool = true
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "aethergain.network.monitor")
    private var started = false
    private var pollTimer: Timer?

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

        // Two safety nets behind the push handler.
        //
        // `pathUpdateHandler` is meant to fire on every transition, but it is
        // not guaranteed to: a handler registered while the interface is
        // already changing can miss the edge, and in the Simulator the handler
        // watches the host Mac's interfaces rather than the device's, so a
        // reconnection sometimes produces no callback at all. The offline
        // banner would then stay on screen for the rest of the run even though
        // the connection was back.
        //
        // 1. Every three seconds, compare the published state against
        //    `monitor.currentPath`, which is a synchronous read of the current
        //    status rather than a notification, and correct it if they differ.
        // 2. Re-read it whenever the app returns to the foreground, because a
        //    transition that happened while the app was suspended delivers no
        //    callback on resume.
        pollTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.reconcile() }
        }
        NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil, queue: .main) { [weak self] _ in
                Task { @MainActor in self?.reconcile() }
            }
    }

    /// Pulls the authoritative status and applies it only when it disagrees
    /// with what the UI is showing, so the toast still fires exactly once per
    /// real transition instead of every three seconds.
    private func reconcile() {
        let online = monitor.currentPath.status == .satisfied
        guard online != isOnline else { return }
        print("[NetworkMonitor] reconcile corrected a missed transition")
        apply(online: online)
    }

    private func apply(online: Bool) {
        let wasOnline = isOnline
        isOnline = online
        print("[NetworkMonitor] path update: \(wasOnline ? "online" : "offline") -> \(online ? "online" : "offline")")

        if !wasOnline && online {
            // Force Firestore to flush queued writes and resume listeners.
            Firestore.firestore().enableNetwork { _ in }
            AGToastCenter.shared.show("Back online — syncing your data.", kind: .success)
        } else if wasOnline && !online {
            AGToastCenter.shared.show("You're offline. Changes will sync when reconnected.", kind: .info)
        }
    }
}
