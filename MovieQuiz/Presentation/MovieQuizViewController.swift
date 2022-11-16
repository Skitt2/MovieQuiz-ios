import UIKit

final class MovieQuizViewController: UIViewController {
    
    private var alertPresenter: AlertPresenter?
    private var statisticService: StatisticServiceProtocol?
    private let moviesLoader: MoviesLoading = MoviesLoader()
    
    private var presenter: MovieQuizPresenter!

    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imageView.layer.cornerRadius = 20
        presenter = MovieQuizPresenter(viewController: self)
         statisticService = StatisticServiceImplementation()
        
        alertPresenter = AlertPresenter(delegate: self)

         showLoadingIndicator()
        
//        presenter.viewController = self
    }

    @IBOutlet private var imageView: UIImageView!
    @IBOutlet private var textLabel: UILabel!
    @IBOutlet private var counterLabel: UILabel!
    
    @IBAction private func yesButtonClicked(_ sender: UIButton) {
        presenter.yesButtonClicked()
    }
    @IBAction private func noButtonClicked(_ sender: UIButton) {
        presenter.noButtonClicked()
    }

    @IBOutlet private var activityIndicator: UIActivityIndicatorView!
    
    func showLoadingIndicator() {
        activityIndicator.startAnimating()
    }
    
    func hideLoadingIndicator() {
        activityIndicator.stopAnimating()
        activityIndicator.isHidden = true
    }
    
    func showNetworkError(message: String) {
        hideLoadingIndicator()
        
        let alertModel = AlertModel(title: "Что-то пошло не так(",
                                    message: message,
                                    buttonText: "Попробовать еще раз") { [weak self] _ in
            guard let self = self else { return }
            self.presenter.restartGame()
            self.showLoadingIndicator()
        }
        
        alertPresenter?.showAlert(alertModel: alertModel)
    }
    
    func show(quiz step: QuizStepViewModel) {
        self.imageView.image = step.image
        self.textLabel.text = step.question
        self.counterLabel.text = step.questionNumber
    }
    
    func show(quiz result: QuizResultsViewModel) {
        let alertModel = AlertModel(
            title: result.title,
            message: result.text + "\n" + "Количество сыгранных квизов: \(statisticService?.gamesCount ?? 0) \n" + "Рекорд: \(statisticService?.bestGame.date.dateTimeString ?? "")) \n" + "Средняя точность: \(String(format: "%.2f", statisticService?.totalAccuracy ?? 0.0))% \n",
            buttonText: result.buttonText) {
                [weak self] _ in guard let self = self else { return }
            
                self.presenter.restartGame()

//                self.questionFactory?.requestNextQuestion()
            }

        alertPresenter?.showAlert(alertModel: alertModel)

    }
    
    func showAnswerResult(isCorrect: Bool) {
        
        presenter.didAnswer(isCorrectAnswer: isCorrect)
        
        imageView.layer.masksToBounds = true
        imageView.layer.borderWidth = 8
        imageView.layer.borderColor = isCorrect ? UIColor.ypGreen.cgColor : UIColor.ypRed.cgColor
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self = self else { return }
//            self.presenter.questionFactory = self.questionFactory
            self.showNextQuestionOrResults()
        }
    }
    
    private func showNextQuestionOrResults() {
        if presenter.isLastQuestion() {
            let text = presenter.correctAnswers == presenter.questionsAmount ?
            "Поздравляем, Вы ответили на 10 из 10!":
            "Ваш результат: \(presenter.correctAnswers)/10"
            let viewModel = QuizResultsViewModel(title: "Этот раунд окончен!",
                                            text: text,
                                            buttonText: "Сыграть еще раз")
            statisticService?.store(correct: presenter.correctAnswers, total: presenter.questionsAmount)
            show(quiz: viewModel)
            
        } else {
            presenter.switchToNextQuestion()
        }
    }

}
