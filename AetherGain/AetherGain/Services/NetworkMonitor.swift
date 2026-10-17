






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



        pollTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.reconcile() }
        }
        NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil, queue: .main) { [weak self] _ in
                Task { @MainActor in self?.reconcile() }
            }
    }




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

            Firestore.firestore().enableNetwork { _ in }
            AGToastCenter.shared.show("Back online — syncing your data.", kind: .success)
        } else if wasOnline && !online {
            AGToastCenter.shared.show("You're offline. Changes will sync when reconnected.", kind: .info)
        }
    }
}
