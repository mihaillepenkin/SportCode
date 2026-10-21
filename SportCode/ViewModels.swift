//
//  ViewModels.swift
//  SportCode
//
//  Created by Михаил Лепенкин on 20.10.2026.
//

import Foundation
import Observation
import SwiftData

@Observable
class DashboardViewModel {
    var totalCaloriesToday: Double = 0
    private let repository: WorkoutRepositoryProtocol
    
    init(repository: WorkoutRepositoryProtocol) {
        self.repository = repository
    }
    
    func loadData() {
        totalCaloriesToday = (try? repository.fetchTotalCaloriesToday()) ?? 0
    }
}

@Observable
class HistoryViewModel {
    var sessions: [WorkoutSession] = []
    private let repository: WorkoutRepositoryProtocol
    
    init(repository: WorkoutRepositoryProtocol) {
        self.repository = repository
    }
    
    func loadData() {
        sessions = (try? repository.fetchWorkouts()) ?? []
    }
}

@Observable
class CatalogViewModel {
    var exercises: [ExerciseDTO] = []
    var selectedExercise: ExerciseDTO?
    private let repository: ExerciseRepositoryProtocol
    
    init(repository: ExerciseRepositoryProtocol) {
        self.repository = repository
    }
    
    func loadExercises() async {
        do {
            exercises = try await repository.fetchExercises()
        } catch {
            print("Failed to load exercises: \(error)")
        }
    }
}

@Observable
class AddWorkoutViewModel {
    var weight: Double = 70.0
    var durationMinutes: Int = 30
    var selectedExercise: ExerciseDTO?
    var exercises: [ExerciseDTO] = []
    var isLoading: Bool = false
    var isSaved: Bool = false
    
    private let workoutRepository: WorkoutRepositoryProtocol
    private let exerciseRepository: ExerciseRepositoryProtocol
    
    init(workoutRepository: WorkoutRepositoryProtocol, exerciseRepository: ExerciseRepositoryProtocol) {
        self.workoutRepository = workoutRepository
        self.exerciseRepository = exerciseRepository
    }
    
    func loadExercises() async {
        print("Начинаем загрузку упражнений...")
        isLoading = true
        do {
            exercises = try await exerciseRepository.fetchExercises()
            print("Упражнения загружены: \(exercises.count) шт.")
        } catch {
            print("Ошибка загрузки: \(error)")
        }
        isLoading = false
    }
    
    var calculatedCalories: Double {
        guard let met = selectedExercise?.met else { return 0 }
        let hours = Double(durationMinutes) / 60.0
        return met * weight * hours
    }
    
    func saveWorkout() {
        guard let exercise = selectedExercise else { return }
        let session = WorkoutSession(
            exerciseName: exercise.name,
            durationMinutes: durationMinutes,
            caloriesBurned: calculatedCalories
        )
        try? workoutRepository.saveWorkout(session)
        isSaved = true
    }
}
