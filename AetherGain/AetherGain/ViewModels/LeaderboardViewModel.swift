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

    /// Firestore refuses a query that filters on one field and orders by
    /// another unless a composite index for exactly that pair exists. The
    /// ordered form is the one worth having — the database sorts, and only the
    /// top 25 documents cross the network — but it is useless if the index is
    /// absent, because the query does not run slowly, it fails outright.
    ///
    /// So both forms are implemented. The ordered query is attempted first; a
    /// FAILED_PRECONDITION reply (code 9, which is Firestore's way of saying
    /// "no such index") swaps in an unordered query that is sorted in the app
    /// instead. The fallback costs more: it downloads up to 50 documents to
    /// show 25, and the sorting work moves onto the phone. That is an
    /// acceptable price for a leaderboard of this size and a bad one for a
    /// large user base, which is precisely why it is the fallback and not the
    /// default.
    ///
    /// Both forms also have to satisfy the same Firestore Security Rule, and
    /// the rule bounds the page size, so its bound must be the larger of the
    /// two the app can ask for:
    ///
    ///     match /users/{userId} {
    ///       allow get, create, update, delete: if request.auth != null
    ///                                          && request.auth.uid == userId;
    ///       allow list: if request.auth != null
    ///                   && request.query.limit <= 50
    ///                   && resource.data.sharesToLeaderboard == true;
    ///     }
    ///
    /// A rule written for 25 would permit the ordered query and silently refuse
    /// the fallback, which is the worst possible outcome: the feature would
    /// work until the day the index was missing.
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
                // The full error, not just its sentence. A Firestore failure
                // carries a numeric code that says which of three very
                // different things went wrong: 7 is a security rule refusing
                // the read, 9 is a missing composite index, 16 is an expired
                // sign-in. They look alike on screen and need opposite fixes.
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

            // Which copy of the data this is matters: Firestore answers every
            // listener from the on-disk cache first and from the server a
            // moment later. A list that appears and then empties means the
            // two disagree, and only the second one is authoritative.
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
