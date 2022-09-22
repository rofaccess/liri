RSpec.describe Liri::Common::TextTimeParser do
  describe '#to_seconds' do
    context 'el texto esta en una sola unidad de tiempo' do
      it 'el texto en segundo se convierte a un decimal en segundo' do
        text = '1 second'
        result = Liri::Common::TextTimeParser.to_seconds(text)
        expect(result).to eq 1.0
      end

      it 'el texto en segundos se convierte a un decimal en segundos' do
        text = '10 seconds'
        result = Liri::Common::TextTimeParser.to_seconds(text)
        expect(result).to eq 10.0
      end

      it 'el texto en segundos y con decimales se convierte a un decimal en segundos' do
        text = '0.00342 seconds'
        result = Liri::Common::TextTimeParser.to_seconds(text)
        expect(result).to eq 0.00342
      end

      it 'el texto en minuto se convierte a un decimal en segundos' do
        text = '1 minute'
        result = Liri::Common::TextTimeParser.to_seconds(text)
        expect(result).to eq 60.0
      end

      it 'el texto en minutos se convierte a un decimal en segundos' do
        text = '15 minutes'
        result = Liri::Common::TextTimeParser.to_seconds(text)
        expect(result).to eq 900.0
      end

      it 'el texto en minutos y con decimales se convierte a un decimal en segundos' do
        text = '15.5 minutes'
        result = Liri::Common::TextTimeParser.to_seconds(text)
        expect(result).to eq 930.0
      end

      it 'el texto en hora se convierte a un decimal en segundos' do
        text = '1 hour'
        result = Liri::Common::TextTimeParser.to_seconds(text)
        expect(result).to eq 3600.0
      end

      it 'el texto en horas se convierte a un decimal en segundos' do
        text = '2 hours'
        result = Liri::Common::TextTimeParser.to_seconds(text)
        expect(result).to eq 7200.0
      end

      # Este caso tambien prueba que se devuelva el valor correcto para algunos decimales
      # Una multipliación normal devuelve
      # (203.033*3600).to_f = 730918.7999999999
      # Una multiplicación con BigDecimal devuelve
      # (BigDecimal('203.033') * 3600).to_f = 730918.8
      it 'el texto en horas se convierte a un decimal en segundos' do
        text = '203.033 hours'
        result = Liri::Common::TextTimeParser.to_seconds(text)
        expect(result).to eq 730_918.8
      end

      it 'el texto en dia se convierte a un decimal en segundos' do
        text = '1 day'
        result = Liri::Common::TextTimeParser.to_seconds(text)
        expect(result).to eq 86_400.0
      end

      it 'el texto en dias se convierte a un decimal en segundos' do
        text = '2 days'
        result = Liri::Common::TextTimeParser.to_seconds(text)
        expect(result).to eq 172_800.0
      end

      it 'el texto en días y con decimales se convierte a un decimal en segundos' do
        text = '2.1 days'
        result = Liri::Common::TextTimeParser.to_seconds(text)
        expect(result).to eq 181_440.0
      end
    end

    context 'el texto esta en 2 unidades de tiempo' do
      it 'el texto en minutos y segundos se convierte a un decimal en segundos' do
        text = '1 minute 5 seconds'
        result = Liri::Common::TextTimeParser.to_seconds(text)
        expect(result).to eq 65
      end

      it 'el texto en horas, minutos y segundos se convierte a un decimal en segundos' do
        text = '1 hour 30 minutes 25 seconds'
        result = Liri::Common::TextTimeParser.to_seconds(text)
        expect(result).to eq 5425
      end
    end
  end
end

