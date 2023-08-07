# frozen_string_literal: true

class MockPrompt
  attr_reader :question_answers

  def initialize
    @question_answers = []
  end

  def select(question, choices)
    answer = get_answer(question)

    case answer
    when Numeric
      choices[answer][:value]
    when Symbol
      choices.send(answer)[:value]
    else
      raise StandardError, "Undefined answer class #{answer.class}"
    end
  end

  def ask(question, params = {})
    answer = get_answer(question)
    answer.nil? ? params[:default] : answer
  end

  def yes?(question)
    answer = get_answer(question)
    answer == 'y'
  end

  def promise_question_answer(question, answer)
    @question_answers << { question: question, answer: answer }
  end

  private

  def get_answer(question)
    answer_index = @question_answers.index { |question_answer| question_answer[:question] == question }
    answer = @question_answers[answer_index].fetch(:answer)
    @question_answers.delete_at(answer_index)

    answer
  end
end
