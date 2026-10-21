//
//  AppEntry.swift
//  SportCode
//
//  Created by Михаил Лепенкин on 19.10.2026.
//

import SwiftUI
import SwiftData

// MARK: - App Entry
@main
struct WorkoutTrackerApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(for: WorkoutSession.self)
    }
}

// MARK: - SwiftData Model (База данных)
@Model
final class WorkoutSession {
    var id: UUID
    var date: Date
    var exerciseName: String
    var durationMinutes: Int
    var caloriesBurned: Double

    init(id: UUID = UUID(), date: Date = Date(), exerciseName: String, durationMinutes: Int, caloriesBurned: Double) {
        self.id = id
        self.date = date
        self.exerciseName = exerciseName
        self.durationMinutes = durationMinutes
        self.caloriesBurned = caloriesBurned
    }
}

// MARK: - Network DTO (Сеть)
struct ExerciseDTO: Codable, Identifiable, Hashable {
    let id: Int
    let name: String
    let met: Double // Метаболический эквивалент для формулы калорий
    let icon: String // Название SF Symbol
}
