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

    /// Filtering on one field while ordering by another needs a composite index;
    /// without it the query fails outright instead of running slowly. The ordered
    /// form is attempted first, and a code 9 reply swaps in an unordered query
    /// sorted in the app, which downloads 50 documents to show 25.
    ///
    /// Matching rule — its bound must cover the larger of the two queries:
    ///     allow list: if request.auth != null
    ///                 && request.query.limit <= 50
    ///                 && resource.data.sharesToLeaderboard == true;
    private static let missingIndexCode = 9   // FirestoreErrorCode.failedPrecondition

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
            // No order(by:) here, so only the automatic single-field index is
            // needed. The wider limit leaves room to sort locally without the
            // top of the table being cut off by an arbitrary selection.
            query = query.limit(to: 50)
        }

        listener = query.addSnapshotListener { [weak self] snapshot, error in
            guard let self else { return }

            if let error {
                // The numeric code separates three look-alike failures: 7 a security rule,
                // 9 a missing composite index, 16 an expired sign-in.
                let ns = error as NSError
                print("[Leaderboard] ERROR domain=\(ns.domain) code=\(ns.code): \(ns.localizedDescription)")

                if orderedByServer && ns.code == Self.missingIndexCode {
                    print("[Leaderboard] no composite index — re-attaching without server-side ordering")
                    DispatchQueue.main.async { self.attach(orderedByServer: false) }
                    return
                }

                DispatchQueue.main.async {
                    self.users = []
                    self.errorMessage = error.localizedDescription
                    self.rulesHint = nil
                }
                return
            }

            guard let snapshot else { return }
            let documents = snapshot.documents

            // Firestore answers from the cache first and from the server a moment
            // later; only the second is authoritative.
            print("[Leaderboard] snapshot fromCache=\(snapshot.metadata.isFromCache) "
                  + "ordered=\(orderedByServer) docs=\(documents.count)")

            var decoded: [LeaderboardUser] = documents.compactMap {
                do {
                    return try $0.data(as: LeaderboardUser.self)
                } catch {
                    // A silent compactMap would hide a type mismatch — an xp
                    // written as text rather than a number, say — as an empty
                    // leaderboard with no error anywhere.
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

                // Only surface the "rules probably block reads" hint if the
                // current user has opted in and is nonetheless alone in the
                // list. Someone who has not opted in seeing nobody is expected.
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
