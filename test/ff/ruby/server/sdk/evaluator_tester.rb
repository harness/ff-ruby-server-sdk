class EvaluatorTester

  def initialize
    super

    @no_target = "_no_target"

    cache = DefaultCache.new

    @repository = StorageRepository.new(cache, nil, nil)

    @results = []
    @evaluator = Evaluator.new(@repository)
  end

  def process(data)

    raise "Not implemented"
  end


end