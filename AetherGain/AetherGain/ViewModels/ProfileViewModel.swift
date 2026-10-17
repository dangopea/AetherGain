











import Foundation
import FirebaseAuth
import FirebaseFirestore
import Combine



class ProfileViewModel: ObservableObject {

    @Published var profile: UserProfile = UserProfile()


    @Published var isLoading = false
    @Published var errorMessage: String?

    private var db = Firestore.firestore()
    private var listener: ListenerRegistration?
    private var authStateHandle: AuthStateDidChangeListenerHandle?


    private var userID: String? {
        Auth.auth().currentUser?.uid
    }

    init() {
        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in

            if let uid = user?.uid {
                self?.loadProfile(for: uid)
            } else {

                self?.profile = UserProfile()
                self?.removeListener()
            }
        }
    }


    func loadProfile(for uid: String) {
        isLoading = true

        let docRef = db.collection("users").document(uid)

        listener = docRef.addSnapshotListener { [weak self] snapshot, error in
            guard let self = self else { return }

            if error != nil {
                self.errorMessage = "Couldn't load your profile. Check your connection and reopen this screen."
                self.isLoading = false
                return
            }



            guard let snapshot else { self.isLoading = false; return }

            if snapshot.exists {
                do {
                    self.profile = try snapshot.data(as: UserProfile.self)
                } catch {
                    self.errorMessage = "Your profile could not be read. Nothing was changed."
                    print("[Profile] decode failed, document left untouched: \(error)")
                }
            } else {
                self.profile = UserProfile()
                self.saveProfile()
            }

            self.isLoading = false
        }
    }


    func saveProfile() {
        guard let uid = userID else {
            errorMessage = "You're signed out. Sign in again to continue."
            return
        }

        isLoading = true
        stopSavingIndicatorIfServerIsSlow()

        let docRef = db.collection("users").document(uid)

        do {


            try docRef.setData(from: profile, merge: true) { [weak self] error in
                DispatchQueue.main.async {
                    if error != nil {
                        self?.errorMessage = "Couldn't save your profile. Check your connection and tap Save again."
                    } else {
                        self?.errorMessage = nil
                    }
                    self?.isLoading = false
                }
            }
        } catch {
            errorMessage = "Your profile couldn't be prepared for saving. Check the text fields for unusual characters."
            isLoading = false
        }
    }


    private func removeListener() {
        listener?.remove()
        listener = nil
        if let handle = authStateHandle {
            Auth.auth().removeStateDidChangeListener(handle)
            authStateHandle = nil
        }
    }

    private func stopSavingIndicatorIfServerIsSlow() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            guard let self, self.isLoading else { return }
            self.isLoading = false
        }
    }

    deinit {
        removeListener()
    }
}
