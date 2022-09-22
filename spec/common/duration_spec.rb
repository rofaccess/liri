RSpec.describe Liri::Common::Duration, "#humanize" do
  context "Con redondeo de piso" do
    it "un redondeo de 0 decimal el resultado es de un numero sin decimales" do
      expect(Liri::Common::Duration.humanize(3.5516, times_round: 0, times_round_type: :floor)).to eq "3s"
    end

    it "y un redondeo de 1 decimal el resultado es de un numero con 1 digito decimal" do
      expect(Liri::Common::Duration.humanize(3.5516, times_round: 1, times_round_type: :floor)).to eq "3.5s"
    end

    it "y un redondeo en dos decimales el resultado es de un numero con 2 digitos decimales" do
      expect(Liri::Common::Duration.humanize(3.5516, times_round: 2, times_round_type: :roof)).to eq "3.55s"
    end
  end

  context "Con redondeo de techo" do
    it "y un redondeo en un decimal el resultado es de un numero sin decimales" do
      expect(Liri::Common::Duration.humanize(3.5516, times_round: 0, times_round_type: :roof)).to eq "4s"
    end

    it "y un redondeo en un decimal el resultado es de un numero con 1 digito decimal" do
      expect(Liri::Common::Duration.humanize(3.5516, times_round: 1, times_round_type: :roof)).to eq "3.6s"
    end

    it "y un redondeo en dos decimales el resultado es de un numero con 2 digitos decimales" do
      expect(Liri::Common::Duration.humanize(3.5516, times_round: 2, times_round_type: :roof)).to eq "3.55s"
    end
  end
end

