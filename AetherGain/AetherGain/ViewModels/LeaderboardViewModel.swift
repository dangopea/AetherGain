import Foundation
import FirebaseFirestore
import FirebaseAuth
import Combine

struct LeaderboardUser: Identifiable, Codable {
    @DocumentID var id: String?
    var name: String = ""
    var xp: Int = 0
    var streakDays: Int? = nil
    var sharesToLeaderboard: Bool? = false
    var profileImageURL: String? = nil

    var level: Int { GameEngine.level(for: xp) }
    var badges: [Badge] {
        GameEngine.badges(for: xp, streakDays: streakDays ?? 0)
    }
}

class LeaderboardViewModel: ObservableObject {

    @Published var users: [LeaderboardUser] = []
    @Published var errorMessage: String?
    @Published var rulesHint: String?

    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?










    private static let missingIndexCode = 9

    func loadLeaderboard() {
        attach(orderedByServer: true)
    }

    private func attach(orderedByServer: Bool) {
        listener?.remove()

        var query: Query = db.collection("users")
            .whereField("sharesToLeaderboard", isEqualTo: true)
        if orderedByServer {
            query = query.order(by: "xp", descending: true).limit(to: 25)
        } else {



            query = query.limit(to: 50)
        }

        listener = query.addSnapshotListener { [weak self] snapshot, error in
            guard let self else { return }

            if let error {


                let ns = error as NSError
                print("[Leaderboard] ERROR domain=\(ns.domain) code=\(ns.code): \(ns.localizedDescription)")

                if orderedByServer && ns.code == Self.missingIndexCode {
                    print("[Leaderboard] no composite index — re-attaching without server-side ordering")
                    DispatchQueue.main.async { self.attach(orderedByServer: false) }
                    return
                }

                DispatchQueue.main.async {
                    self.users = []
                    self.errorMessage = "The leaderboard couldn't load. Check your connection and open it again."
                    self.rulesHint = nil
                }
                return
            }

            guard let snapshot else { return }
            let documents = snapshot.documents



            print("[Leaderboard] snapshot fromCache=\(snapshot.metadata.isFromCache) "
                  + "ordered=\(orderedByServer) docs=\(documents.count)")

            var decoded: [LeaderboardUser] = documents.compactMap {
                do {
                    return try $0.data(as: LeaderboardUser.self)
                } catch {



                    print("[Leaderboard]   decode failed for \($0.documentID): \(error)")
                    return nil
                }
            }

            if !orderedByServer {
                decoded.sort { $0.xp > $1.xp }
                decoded = Array(decoded.prefix(25))
            }

            let myUID = Auth.auth().currentUser?.uid
            let currentUserIsOptedIn = decoded.contains(where: { $0.id == myUID })

            DispatchQueue.main.async {
                self.users = decoded
                self.errorMessage = nil




                if currentUserIsOptedIn && decoded.count <= 1 {
                    self.rulesHint = "Only see yourself? Either nobody else has opted in, or your Firestore rules block reading other users' documents."
                } else {
                    self.rulesHint = nil
                }
            }
        }
    }

    deinit { listener?.remove() }
}
