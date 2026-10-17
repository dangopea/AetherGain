






import Foundation
import FirebaseAuth
import FirebaseFirestore
import Combine

class WorkoutViewModel: ObservableObject {

    @Published var currentSession: WorkoutSession = WorkoutSession()
    @Published var history: [WorkoutSession] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private var db = Firestore.firestore()
    private var listener: ListenerRegistration?

    private var userID: String? {
        Auth.auth().currentUser?.uid
    }

    init() {
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            if let uid = user?.uid {
                self?.loadHistory(for: uid)
            } else {
                self?.history = []
                self?.removeListener()
            }
        }
    }


    func addExercise() {
        currentSession.exercises.append(ExerciseTemplate.configuredExercise(named: "Bench Press"))
    }

    func addCustomExercise(named name: String) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            errorMessage = "Enter an exercise name"
            return
        }

        currentSession.exercises.append(ExerciseTemplate.configuredExercise(named: trimmedName))
        errorMessage = nil
    }

    func applyTemplate(_ template: ExerciseTemplate, at index: Int) {
        guard currentSession.exercises.indices.contains(index) else { return }
        currentSession.exercises[index] = ExerciseTemplate.configuredExercise(named: template.name)
    }


    func removeExercise(at index: Int) {
        currentSession.exercises.remove(at: index)
    }


    func completeSession() {
        guard let uid = userID else {
            errorMessage = "You're signed out. Sign in again to continue."
            return
        }

        guard currentSession.isValidForXP else {
            errorMessage = "Add at least one valid exercise (sets & reps > 0)"
            return
        }

        isLoading = true
        stopSavingIndicatorIfServerIsSlow()

        let earnedXP = GameEngine.workoutXP(for: currentSession)
        currentSession.totalXP = earnedXP


        if currentSession.date > Date() {

            currentSession.date = Date()
        }



        let batch = db.batch()


        let sessionRef = db.collection("users").document(uid).collection("workouts").document()
        do {
            try batch.setData(from: currentSession, forDocument: sessionRef)
        } catch {
            errorMessage = "This workout couldn't be prepared for saving. Check the exercise names and try again."
            isLoading = false
            return
        }


        let profileRef = db.collection("users").document(uid)
        batch.updateData([
            "xp": FieldValue.increment(Int64(earnedXP))
        ], forDocument: profileRef)


        batch.commit { [weak self] error in
            DispatchQueue.main.async {
                if error != nil {
                    self?.errorMessage = "Couldn't save your workout. Check your connection and tap Complete again."
                } else {
                    self?.errorMessage = nil

                    self?.currentSession = WorkoutSession()
                }
                self?.isLoading = false
            }
        }
    }




    func updateSession(_ edited: WorkoutSession, completion: @escaping (Error?) -> Void) {
        guard let uid = userID, let sessionID = edited.id else {
            completion(NSError(domain: "AGWorkout", code: 400,
                               userInfo: [NSLocalizedDescriptionKey: "Missing session id."]))
            return
        }
        guard edited.isValidForXP else {
            completion(NSError(domain: "AGWorkout", code: 422,
                               userInfo: [NSLocalizedDescriptionKey: "Need at least one valid exercise."]))
            return
        }

        var updated = edited
        let previousXP = edited.totalXP
        let newXP = GameEngine.workoutXP(for: updated)
        updated.totalXP = newXP
        let xpDelta = newXP - previousXP

        isLoading = true
        let batch = db.batch()
        let sessionRef = db.collection("users").document(uid).collection("workouts").document(sessionID)
        do {
            try batch.setData(from: updated, forDocument: sessionRef, merge: false)
        } catch {
            isLoading = false
            completion(error); return
        }
        if xpDelta != 0 {
            let profileRef = db.collection("users").document(uid)
            batch.updateData(["xp": FieldValue.increment(Int64(xpDelta))], forDocument: profileRef)
        }
        batch.commit { [weak self] error in
            DispatchQueue.main.async {
                self?.isLoading = false
                completion(error)
            }
        }
    }


    func deleteSession(_ session: WorkoutSession) {
        guard let uid = userID, let sessionID = session.id else { return }
        let batch = db.batch()
        let sessionRef = db.collection("users").document(uid).collection("workouts").document(sessionID)
        batch.deleteDocument(sessionRef)


        let profileRef = db.collection("users").document(uid)
        batch.updateData([
            "xp": FieldValue.increment(Int64(-session.totalXP))
        ], forDocument: profileRef)

        batch.commit { [weak self] error in
            DispatchQueue.main.async {
                if error != nil {
                    self?.errorMessage = "Couldn't delete that session. Check your connection and try again."
                }
            }
        }
    }


    private func loadHistory(for uid: String) {
        let collectionRef = db.collection("users").document(uid).collection("workouts")

        listener = collectionRef
            .order(by: "date", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                if error != nil {
                    self?.errorMessage = "Couldn't load your history. Pull down to refresh once you're back online."
                    return
                }

                guard let documents = snapshot?.documents else {
                    self?.history = []
                    return
                }

                self?.history = documents.compactMap { try? $0.data(as: WorkoutSession.self) }
            }
    }


    private func removeListener() {
        listener?.remove()
        listener = nil
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
