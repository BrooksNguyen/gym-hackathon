import AppIntents

struct AskAICoachIntent: AppIntent {
    static var title: LocalizedStringResource = "Ask Gymini AI Coach"

    @Parameter(title: "Question")
    var question: String

    func perform() async throws -> some ProvidesDialog {
        // Mock processing logic for Apple Intelligence
        return .result(dialog: "Here is your plan for today...")
    }
}
