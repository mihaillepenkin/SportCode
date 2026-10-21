//
//  Repository.swift
//  SportCode
//
//  Created by Михаил Лепенкин on 19.10.2026.
//

import Foundation
import SwiftData

// MARK: - Protocols
protocol ExerciseRepositoryProtocol {
    func fetchExercises() async throws -> [ExerciseDTO]
}

protocol WorkoutRepositoryProtocol {
    func saveWorkout(_ workout: WorkoutSession) throws
    func fetchWorkouts() throws -> [WorkoutSession]
    func fetchTotalCaloriesToday() throws -> Double
}

// MARK: - Network Repository
class NetworkExerciseRepository: ExerciseRepositoryProtocol {
    func fetchExercises() async throws -> [ExerciseDTO] {
        let urlString = "https://raw.githubusercontent.com/mihaillepenkin/swifIOS/refs/heads/main/data.json"
        
        guard let url = URL(string: urlString) else {
            print("Неверный URL, используем fallback")
            return getFallbackExercises()
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            // Проверяем, что ответ успешный
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                print("Ошибка сервера: \(httpResponse.statusCode), используем fallback")
                return getFallbackExercises()
            }
            
            let exercises = try JSONDecoder().decode([ExerciseDTO].self, from: data)
            print("Загружено \(exercises.count) упражнений из сети")
            return exercises
        } catch {
            print("Ошибка сети: \(error.localizedDescription), используем fallback")
            return getFallbackExercises()
        }
    }
    
    // Fallback список упражнений (всегда работает)
    private func getFallbackExercises() -> [ExerciseDTO] {
        let json = """
        [
          { "id": 1, "name": "Бег", "met": 9.8, "icon": "figure.run" },
          { "id": 2, "name": "Велосипед", "met": 7.5, "icon": "figure.outdoor.cycle" },
          { "id": 3, "name": "Силовая тренировка", "met": 6.0, "icon": "dumbbell.fill" },
          { "id": 4, "name": "Йога", "met": 2.5, "icon": "figure.mind.and.body" },
          { "id": 5, "name": "Плавание", "met": 8.0, "icon": "figure.pool.swim" },
          { "id": 6, "name": "Ходьба", "met": 3.5, "icon": "figure.walk" },
          { "id": 7, "name": "Прыжки на скакалке", "met": 12.0, "icon": "figure.jump.rope" },
          { "id": 8, "name": "Танцы", "met": 5.0, "icon": "figure.dance" }
        ]
        """
        
        if let data = json.data(using: .utf8) {
            if let exercises = try? JSONDecoder().decode([ExerciseDTO].self, from: data) {
                return exercises
            }
        }
        
        return [
            ExerciseDTO(id: 1, name: "Бег", met: 9.8, icon: "figure.run"),
            ExerciseDTO(id: 2, name: "Велосипед", met: 7.5, icon: "figure.outdoor.cycle")
        ]
    }
}

// MARK: - SwiftData Repository
class SwiftDataWorkoutRepository: WorkoutRepositoryProtocol {
    private let context: ModelContext
    
    init(context: ModelContext) {
        self.context = context
    }
    
    func saveWorkout(_ workout: WorkoutSession) throws {
        context.insert(workout)
        try context.save()
    }
    
    func fetchWorkouts() throws -> [WorkoutSession] {
        let descriptor = FetchDescriptor<WorkoutSession>(sortBy: [SortDescriptor(\.date, order: .reverse)])
        return try context.fetch(descriptor)
    }
    
    func fetchTotalCaloriesToday() throws -> Double {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        
        var descriptor = FetchDescriptor<WorkoutSession>(
            predicate: #Predicate { $0.date >= startOfDay }
        )
        let sessions = try context.fetch(descriptor)
        return sessions.reduce(0) { $0 + $1.caloriesBurned }
    }
}

