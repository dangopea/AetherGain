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

    /// Server-side filter on `sharesToLeaderboard == true`. This both
    ///  1. keeps the read count low, and
    ///  2. lets you write a matching Firestore Security Rule such as:
    ///       allow list: if request.query.limit <= 25 &&
    ///                   resource.data.sharesToLeaderboard == true;
    ///     so anyone can see opted-in profiles but nothing else.
    func loadLeaderboard() {
        listener?.remove()
        listener = db.collection("users")
            .whereField("sharesToLeaderboard", isEqualTo: true)
            .order(by: "xp", descending: true)
            .limit(to: 25)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self else { return }
                if let error {
                    DispatchQueue.main.async {
                        self.users = []
                        self.errorMessage = error.localizedDescription
                        self.rulesHint = nil
                    }
                    return
                }
                guard let documents = snapshot?.documents else { return }
                let decoded: [LeaderboardUser] = documents.compactMap {
                    try? $0.data(as: LeaderboardUser.self)
                }
                let myUID = Auth.auth().currentUser?.uid
                let currentUserIsOptedIn = decoded.contains(where: { $0.id == myUID })

                DispatchQueue.main.async {
                    self.users = decoded
                    self.errorMessage = nil

                    // Only surface the "rules probably block reads" hint if:
                    //   - the current user has actually opted in (so they're expected
                    //     to see themselves + others), AND
                    //   - the returned list contains only them (or nothing).
                    // If the user hasn't opted in, seeing 0 or 1 person is expected
                    // behaviour, so we say nothing.
                    if currentUserIsOptedIn && decoded.count <= 1 {
                        self.rulesHint = "Only see yourself? Either nobody else has opted in, or your Firestore rules block reading other users' documents. See LeaderboardViewModel for the rule to add."
                    } else {
                        self.rulesHint = nil
                    }
                }
            }
    }

    deinit { listener?.remove() }
}
