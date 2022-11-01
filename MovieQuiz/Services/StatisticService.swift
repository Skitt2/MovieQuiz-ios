//import Foundation
//
//protocol StatisticService {
//    func store(correct count: Int, total amount: Int)
//    var totalAccuracy: Double { get }
//    var gameaCount: Int { get }
//    var bestGame: GameRecord { get private(set) }
//}
//
//final class StatisticServiceImplementation: StatisticService {
//    var totalAccuracy: Double
//
//    var gameaCount: Int
//
//    var bestGame: GameRecord {
//        get {
//            guard let data = userDefaults.data(forKey: Keys.bestGame.rawValue),
//            let record = try? JSONDecoder().decode(GameRecord.self, from: data) else {
//                return .init(correct: 0, total: 0, date: Date())
//            }
//
//            return record
//        }
//
//        set {
//            guard let data = try? JSONEncoder().encode(newValue) else {
//                print("Невозможно сохранить результат")
//                return
//            }
//
//            userDefaults.set(data, forKey: Keys.bestGame.rawValue)
//        }
//    }
//
//}
