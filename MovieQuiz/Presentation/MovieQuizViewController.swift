import UIKit

final class MovieQuizViewController: UIViewController, QuestionFactoryDelegate {
    
    private var correctAnswers: Int = 0

    private var questionFactory: QuestionFactoryProtocol?
    private var currentQuestion: QuizQuestion?
    private var alertPresenter: AlertPresenter?
    private var statisticService: StatisticServiceProtocol?
    private let moviesLoader: MoviesLoading = MoviesLoader()
    
    private let presenter = MovieQuizPresenter()

    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imageView.layer.cornerRadius = 20
        
         questionFactory = QuestionFactory(moviesLoader: MoviesLoader(), delegate: self)
         statisticService = StatisticServiceImplementation()
        
        alertPresenter = AlertPresenter(delegate: self)
        questionFactory?.loadData()
         showLoadingIndicator()
        
        presenter.viewController = self
    }
    
    // MARK: - QuestionFactoryDelegate
    

    
    @IBOutlet private var imageView: UIImageView!
    @IBOutlet private var textLabel: UILabel!
    @IBOutlet private var counterLabel: UILabel!
    
    @IBAction private func yesButtonClicked(_ sender: UIButton) {
        presenter.currentQuestion = currentQuestion
        presenter.yesButtonClicked()
    }
    @IBAction private func noButtonClicked(_ sender: UIButton) {
        presenter.currentQuestion = currentQuestion
        presenter.noButtonClicked()
    }
//    @IBAction private func noButtonClicked(_ sender: UIButton) {
//        guard let currentQuestion = currentQuestion else {
//            return
//        }
//        let givenAnswer = false
//        showAnswerResult(isCorrect: givenAnswer == currentQuestion.correctAnswer)
//    }
    
//    @IBAction private func yesButtonClicked(_ sender: UIButton) {
//        guard let currentQuestion = currentQuestion else {
//            return
//        }
//        let givenAnswer = true
//        showAnswerResult(isCorrect: givenAnswer == currentQuestion.correctAnswer)
//    }

    @IBOutlet private var activityIndicator: UIActivityIndicatorView!
    
    func didReceiveNextQuestion(question: QuizQuestion?) {
        guard let question = question else {
                return
            }
            
            currentQuestion = question
            let viewModel = presenter.convert(model: question)
            DispatchQueue.main.async { [weak self] in
                self?.show(quiz: viewModel)
            }
    }
    
    func didLoadDataFromServer() {
        activityIndicator.isHidden = true // скрываем индикатор загрузки
        questionFactory?.requestNextQuestion()
    }
    
    func didFailToLoadData(with error: Error) {
        showNetworkError(message: error.localizedDescription) // возьмём в качестве сообщения описание ошибки
    }
    
    private func showLoadingIndicator() {
        activityIndicator.startAnimating()
    }
    
    private func hideLoadingIndicator() {
        activityIndicator.stopAnimating()
    }
    
    private func showNetworkError(message: String) {
        hideLoadingIndicator()
        
        let alertModel = AlertModel(title: "Что-то пошло не так(",
                                    message: message,
                                    buttonText: "Попробовать еще раз") { [weak self] _ in
            guard let self = self else { return }
            self.questionFactory?.loadData()
            self.showLoadingIndicator()
        }
        
        alertPresenter?.showAlert(alertModel: alertModel)
    }
    
    private func show(quiz step: QuizStepViewModel) {
        self.imageView.image = step.image
        self.textLabel.text = step.question
        self.counterLabel.text = step.questionNumber
    }
    
    private func show(quiz result: QuizResultsViewModel) {
        let alertModel = AlertModel(
            title: result.title,
            message: result.text + "\n" + "Количество сыгранных квизов: \(statisticService?.gamesCount ?? 0) \n" + "Рекорд: \(statisticService?.bestGame.date.dateTimeString ?? "")) \n" + "Средняя точность: \(String(format: "%.2f", statisticService?.totalAccuracy ?? 0.0))% \n",
            buttonText: result.buttonText) {
                [weak self] _ in guard let self = self else { return }
            
                self.presenter.resetQuestionIndex()
                self.correctAnswers = 0

                self.questionFactory?.requestNextQuestion()
            }

        alertPresenter?.showAlert(alertModel: alertModel)

    }
    
    func showAnswerResult(isCorrect: Bool) {
        if isCorrect {
            correctAnswers += 1
        }
        
        imageView.layer.masksToBounds = true
        imageView.layer.borderWidth = 8
        imageView.layer.borderColor = isCorrect ? UIColor.ypGreen.cgColor : UIColor.ypRed.cgColor
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.showNextQuestionOrResults()
                self.imageView.layer.borderWidth = 0
            }
    }
    
    private func showNextQuestionOrResults() {
        if presenter.isLastQuestion() {
            let text = correctAnswers == presenter.questionsAmount ?
            "Поздравляем, Вы ответили на 10 из 10!":
            "Ваш результат: \(correctAnswers)/10"
            let viewModel = QuizResultsViewModel(title: "Этот раунд окончен!",
                                            text: text,
                                            buttonText: "Сыграть еще раз")
            statisticService?.store(correct: correctAnswers, total: presenter.questionsAmount)
            show(quiz: viewModel)
            
        } else {
            presenter.switchToNextQuestion()
            questionFactory?.requestNextQuestion()
        }
    }

}
