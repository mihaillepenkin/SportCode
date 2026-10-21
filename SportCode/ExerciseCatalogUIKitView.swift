//
//  ExerciseCatalogUIKitView.swift
//  SportCode
//
//  Created by Михаил Лепенкин on 20.10.2026.
//

import SwiftUI
import UIKit

// MARK: - 1. UIKit ViewController
class ExerciseCatalogViewController: UIViewController {
    var exercises: [ExerciseDTO] = []
    var onSelectExercise: ((ExerciseDTO) -> Void)?
    
    lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 12
        layout.minimumLineSpacing = 12
        layout.sectionInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.backgroundColor = .systemBackground
        cv.register(ExerciseCell.self, forCellWithReuseIdentifier: "ExerciseCell")
        cv.dataSource = self
        cv.delegate = self
        return cv
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Каталог (UIKit)"
        
        view.addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
}

extension ExerciseCatalogViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return exercises.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ExerciseCell", for: indexPath) as! ExerciseCell
        cell.configure(with: exercises[indexPath.item])
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (collectionView.frame.width - 44) / 2 // 2 колонки
        return CGSize(width: width, height: 120)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        onSelectExercise?(exercises[indexPath.item])
    }
}

// MARK: - Custom UICollectionViewCell
class ExerciseCell: UICollectionViewCell {
    private let iconImageView: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.tintColor = .systemBlue
        iv.contentMode = .scaleAspectFit
        return iv
    }()
    
    private let titleLabel: UILabel = {
        let lbl = UILabel()
        lbl.translatesAutoresizingMaskIntoConstraints = false
        lbl.font = .systemFont(ofSize: 16, weight: .semibold)
        lbl.textAlignment = .center
        return lbl
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .secondarySystemBackground
        contentView.layer.cornerRadius = 12
        
        contentView.addSubview(iconImageView)
        contentView.addSubview(titleLabel)
        
        NSLayoutConstraint.activate([
            iconImageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            iconImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            iconImageView.widthAnchor.constraint(equalToConstant: 40),
            iconImageView.heightAnchor.constraint(equalToConstant: 40),
            
            titleLabel.topAnchor.constraint(equalTo: iconImageView.bottomAnchor, constant: 10),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8)
        ])
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    func configure(with exercise: ExerciseDTO) {
        iconImageView.image = UIImage(systemName: exercise.icon)
        titleLabel.text = exercise.name
    }
}

// MARK: - 2. SwiftUI Wrapper (UIViewControllerRepresentable)
struct ExerciseCatalogUIKitView: UIViewControllerRepresentable {
    @State var viewModel: CatalogViewModel
    @Environment(\.modelContext) private var context
    
    func makeUIViewController(context: Context) -> ExerciseCatalogViewController {
        let vc = ExerciseCatalogViewController()
        vc.onSelectExercise = { exercise in
            viewModel.selectedExercise = exercise
            // Переход на экран добавления тренировки при выборе упражнения
            // В реальном приложении тут лучше использовать NavigationLink, но для демо пробрасываем через Coordinator или просто показываем алерт/переход
            // Для простоты в этом коде: переход сделаем через NavigationStack, но так как мы внутри UIKit,
            // лучше передать данные в AddWorkoutView.
            // Чтобы не усложнять, просто обновим стейт.
        }
        
        // Загружаем данные при создании
        Task {
            await viewModel.loadExercises()
            await MainActor.run {
                vc.exercises = viewModel.exercises
                vc.collectionView.reloadData()
            }
        }
        
        return vc
    }
    
    func updateUIViewController(_ uiViewController: ExerciseCatalogViewController, context: Context) {
        uiViewController.exercises = viewModel.exercises
        uiViewController.collectionView.reloadData()
    }
}
