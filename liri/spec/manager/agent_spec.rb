RSpec.describe Liri::Agent::Runner, '#run_tests' do
  before(:all) do
    @manager_unit_test = Liri::Manager::UnitTest::Rspec.new(source_code_folder_path)
    @runner = Liri::Agent::Runner.new(agent_unit_test_class)
  end
=begin
  it 'ejecuta 4 pruebas unitarias en 2 hilos' do
    runners = [
        {
            runner:  Liri::Agent::Runner.new(agent_unit_test_class),
            status: 'running',
            tests: []
        },
        {
            runner:  Liri::Agent::Runner.new(agent_unit_test_class),
            status: 'running',
            tests: []
        }

    ]

    all_tests = @manager_unit_test.all_tests
    threads = []

    while all_tests.any? do

    end

    runners.each_with_index do |runner, index|
      threads[index] = Thread.new {
        tests_samples = all_tests.sample(tests_quantity_by_runners)
        all_tests.remove!(tests_samples.keys)

        tests_result = runner.run_tests(tests_samples)
        puts(tests_result[:result])

        expect(tests_result).to be_a(Hash)
        expect(tests_result[:result]).to eq('..')
        expect(tests_result[:failures]).to eq('')
        expect(tests_result[:example_quantity]).to eq(2)
        expect(tests_result[:failure_quantity]).to eq(0)
        expect(tests_result[:passed_quantity]).to eq(2)
        expect(tests_result[:failed_examples]).to eq('')
        expect(tests_result[:test_keys]).to eq(tests_samples.keys)

        Thread.current["tests_result"] = tests_result
      }
    end

    threads.each {|t| t.join; print t["tests_result"], ", " }
  end
=end
end
