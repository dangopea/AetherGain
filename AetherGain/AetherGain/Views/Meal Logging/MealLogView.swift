//
//  MealLogView.swift
//  AetherGain
//
//  Created by Dhriti on 3/8/2569 BE.
//

import Foundation
import SwiftUI

import PhotosUI

struct MealLogView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @StateObject private var mealVM = MealViewModel()
    
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var selectedImage: Image?
    
    var body: some View {
        
        NavigationStack {
            
            Form {
                
                Section("Photo (optional)") {
                    PhotosPicker("Choose or Take Photo", selection: $selectedPhoto, matching: .images)
                    
                    if let selectedImage {
                        selectedImage
                            .resizable()
                            .scaledToFit()
                            .frame(height: 200)
                            .cornerRadius(10)
                    }
                }
                
                
                Section("Meal Details") {
                    TextField("Food Name", text: $mealVM.currentMeal.foodName)
                    
                    HStack {
                        
                        Text("Calories")
                        Spacer()
                        TextField("kcal", value: $mealVM.currentMeal.calories, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                        
                    }
                    
                    HStack {
                        
                        Text("Protein")
                        Spacer()
                        TextField("g", value: $mealVM.currentMeal.protein, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                        
                    }
                                        
                    TextField("Notes", text: $mealVM.currentMeal.notes)
                }
                
                if mealVM.isLoading {
                    ProgressView("Saving meal...")
                }
                
                if let error = mealVM.errorMessage {
                    Text(error).foregroundColor(.red)
                }
                
                Button("Save Meal") {
                    mealVM.saveMeal()
                    authVM.userDidInteract()
                }
                
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.indigo)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            
            .navigationTitle("Log Meal")
            .onChange(of: selectedPhoto) { newItem in
                
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        selectedImage = Image(uiImage: uiImage)
                        mealVM.analyzeMealPhoto(uiImage) { success in
                            if !success {
                                mealVM.errorMessage = "No food detected in photo"
                            }
                        }
                    }
                }
            }
            .onAppear { authVM.userDidInteract() }
            .onTapGesture { authVM.userDidInteract() }
        }
    }
}
