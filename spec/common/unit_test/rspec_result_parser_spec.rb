RSpec.describe Liri::Common::UnitTest::RspecResultParser do
  describe '#finish_in_values' do
    it 'la línea tiene valores en segundos y decimales' do
      line = 'Finished in 0.00342 seconds (files took 0.22366 seconds to load)'
      values = Liri::Common::UnitTest::RspecResultParser.finish_in_values(line)
      expect(values[:finish_in]).to eq 0.00342
      expect(values[:files_load]).to eq 0.22366
    end

    it 'la línea tiene valores en minutos, segundos y decimales' do
      line = 'Finished in 12 minutes 51 seconds (files took 8.24 seconds to load)'
      values = Liri::Common::UnitTest::RspecResultParser.finish_in_values(line)
      expect(values[:finish_in]).to eq 771
      expect(values[:files_load]).to eq 8.24
    end

    it 'la línea tiene valores en horas, minutos, segundos y decimales' do
      line = 'Finished in 1 hour 50 seconds (files took 1.24 minutes to load)'
      values = Liri::Common::UnitTest::RspecResultParser.finish_in_values(line)
      expect(values[:finish_in]).to eq 3650
      expect(values[:files_load].to_f).to eq 74.4
    end
  end

  describe '#finished_summary_values' do
    it 'la línea tiene examples y failures' do
      line = '8 examples, 0 failures'
      values = Liri::Common::UnitTest::RspecResultParser.finished_summary_values(line)
      expect(values[:examples]).to eq 8
      expect(values[:failures]).to eq 0
      expect(values[:failures]).to eq 0
    end

    it 'la línea tiene examples, failures y pending' do
      line = '16346 examples, 11 failures, 9 pending'
      values = Liri::Common::UnitTest::RspecResultParser.finished_summary_values(line)
      expect(values[:examples]).to eq 16_346
      expect(values[:failures]).to eq 11
      expect(values[:pending]).to eq 9
    end

    it 'la línea tiene examples y 1 failure' do
      line = '16346 examples, 1 failure'
      values = Liri::Common::UnitTest::RspecResultParser.finished_summary_values(line)
      expect(values[:examples]).to eq 16_346
      expect(values[:failures]).to eq 1
      expect(values[:pending]).to eq 0
    end

    it 'la línea tiene examples, 1 failure y pending' do
      line = '16346 examples, 1 failure, 9 pending'
      values = Liri::Common::UnitTest::RspecResultParser.finished_summary_values(line)
      expect(values[:examples]).to eq 16_346
      expect(values[:failures]).to eq 1
      expect(values[:pending]).to eq 9
    end
  end

  describe "#failed_example" do
    it "la linea contiene .rb:algun_numero" do
      line = "rspec ./spec/system/budgets/budgets_spec.rb:326 # Budgets Index map Skip invalid map markers"
      result = Liri::Common::UnitTest::RspecResultParser.failed_example(line)
      expect(result).to eq "/spec/system/budgets/budgets_spec.rb:326"
    end

    it "la linea contiene .rb:[algun_numero, algun_numero]" do
      line = "rspec ./spec/system/management/budget_investments_spec.rb[1:3:1:3] # Budget Investments behaves like mappable At new_management_budget_investment_path Should create budget_investment with map"
      result = Liri::Common::UnitTest::RspecResultParser.failed_example(line)
      expect(result).to eq "/spec/system/management/budget_investments_spec.rb[1:3:1:3]"
    end
  end
end

