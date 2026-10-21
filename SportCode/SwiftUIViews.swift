import SwiftUI
import SwiftData

// MARK: - Root View (TabView + NavigationStack)
struct RootView: View {
    @Environment(\.modelContext) private var context
    
    var body: some View {
        TabView {
            // Вкладка 1: Дашборд
            NavigationStack {
                DashboardView(viewModel: DashboardViewModel(repository: SwiftDataWorkoutRepository(context: context)))
            }
            .tabItem { Label("Главная", systemImage: "house.fill") }
            
            // Вкладка 2: История
            NavigationStack {
                HistoryView(viewModel: HistoryViewModel(repository: SwiftDataWorkoutRepository(context: context)))
            }
            .tabItem { Label("История", systemImage: "clock.fill") }
            
            // Вкладка 3: Каталог (UIKit)
            NavigationStack {
                ExerciseCatalogUIKitView(
                    viewModel: CatalogViewModel(repository: NetworkExerciseRepository())
                )
            }
            .tabItem { Label("Упражнения", systemImage: "list.bullet") }
        }
    }
}

// MARK: - Screen 1: Dashboard
struct DashboardView: View {
    var viewModel: DashboardViewModel
    
    @Environment(\.modelContext) private var context
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Сегодня сожжено")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("\(Int(viewModel.totalCaloriesToday)) ккал")
                .font(.system(size: 48, weight: .bold))
                .foregroundColor(.orange)
            
            NavigationLink(destination: AddWorkoutView(
                viewModel: AddWorkoutViewModel(
                    workoutRepository: SwiftDataWorkoutRepository(context: context),
                    exerciseRepository: NetworkExerciseRepository()
                )
            )) {
                Text("Начать тренировку")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .padding(.top, 40)
        .navigationTitle("Тренировки")
        .onAppear { viewModel.loadData() }
    }
}

// MARK: - Screen 2: History
struct HistoryView: View {
    var viewModel: HistoryViewModel
    
    var body: some View {
        List(viewModel.sessions) { session in
            VStack(alignment: .leading, spacing: 5) {
                Text(session.exerciseName).font(.headline)
                Text("\(session.durationMinutes) мин • \(Int(session.caloriesBurned)) ккал")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text(session.date, style: .date)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding(.vertical, 5)
        }
        .navigationTitle("История")
        .onAppear { viewModel.loadData() }
    }
}

// MARK: - Screen 4: Add Workout
struct AddWorkoutView: View {
    @Bindable var viewModel: AddWorkoutViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedExerciseName: String = ""
    
    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.exercises.isEmpty {
                ProgressView("Загрузка упражнений...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Form {
                    exerciseSection
                    parametersSection
                    resultSection
                    saveButton
                }
            }
        }
        .navigationTitle("Новая тренировка")
        .task {
            // Загружаем данные из сети при открытии экрана
            await viewModel.loadExercises()
        }
    }
    
    private var exerciseSection: some View {
        Section("Упражнение") {
            Picker("Выберите тип", selection: $selectedExerciseName) {
                Text("Не выбрано").tag("")
                //Берем упражнения из ViewModel (они пришли из сети)
                ForEach(viewModel.exercises) { ex in
                    Text(ex.name).tag(ex.name)
                }
            }
            .onChange(of: selectedExerciseName) { _, newValue in
                viewModel.selectedExercise = viewModel.exercises.first { $0.name == newValue }
            }
        }
    }
    
    private var parametersSection: some View {
        Section("Параметры") {
            HStack {
                Text("Вес (кг)")
                Spacer()
                TextField("70", value: $viewModel.weight, format: .number)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
            }
            Stepper("Время: \(viewModel.durationMinutes) мин", value: $viewModel.durationMinutes, in: 5...180, step: 5)
        }
    }
    
    private var resultSection: some View {
        Section("Результат") {
            HStack {
                Text("Сожжено калорий:")
                Spacer()
                Text("\(Int(viewModel.calculatedCalories)) ккал")
                    .fontWeight(.bold)
                    .foregroundColor(.orange)
            }
        }
    }
    
    private var saveButton: some View {
        Section {
            Button("Сохранить тренировку") {
                viewModel.saveWorkout()
                if viewModel.isSaved { dismiss() }
            }
            .disabled(viewModel.selectedExercise == nil)
        }
    }
}
