# frozen_string_literal: true

describe Facter::Options do
  describe '#defaults' do
    it 'sets debug to false' do
      expect(Facter::Options[:debug]).to be_falsey
    end

    it 'sets trace to false' do
      expect(Facter::Options[:trace]).to be_falsey
    end

    it 'sets verbose to false' do
      expect(Facter::Options[:verbose]).to be_falsey
    end

    it 'sets log_level to warn' do
      expect(Facter::Options[:log_level]).to eq(:warn)
    end

    it 'sets show_legacy to false' do
      expect(Facter::Options[:show_legacy]).to be_truthy
    end

    it 'set custom-dir with empty array' do
      expect(Facter::Options[:custom_dir].size).to eq(0)
    end

    it 'sets external-dir with empty array' do
      expect(Facter::Options[:external_dir].size).to eq(0)
    end

    it 'sets ruby to true' do
      expect(Facter::Options[:ruby]).to be_truthy
    end
  end

  describe '#init_from_cli' do
    context 'with defaults' do
      let(:option_store) { class_spy(Facter::OptionStore).as_stubbed_const }

      # before do
      #   allow(option_store).to receive(:cli=)
      # end

      it 'calls OptionStore with cli' do
        Facter::Options.init_from_cli

        expect(option_store).to have_received(:cli=).with(true)
      end

      it 'calls OptionStore with show_legacy' do
        Facter::Options.init_from_cli

        expect(option_store).to have_received(:show_legacy=).with(false)
      end
    end
  end

  describe '#init' do
    let(:config_reader_double) { double(Facter::ConfigReader) }
    let(:block_list_double) { double(Facter::BlockList) }

    before do
      allow(Facter::ConfigReader).to receive(:new).and_return(config_reader_double)
      allow(config_reader_double).to receive(:cli).and_return(nil)

      allow(config_reader_double).to receive(:global).and_return(nil)
      allow(config_reader_double).to receive(:ttls).and_return([])

      allow(Facter::BlockList).to receive(:instance).and_return(block_list_double)
      allow(block_list_double).to receive(:blocked_facts).and_return([])
    end

    context 'when defaults are overridden only by config file global options' do
      it 'sets debug to true' do
        allow(config_reader_double).to receive(:cli).and_return(
          'debug' => true
        )

        Facter::Options.init

        expect(Facter::Options[:debug]).to be_falsey
      end

      it 'sets trace to true' do
        allow(config_reader_double).to receive(:cli).and_return(
          'trace' => true
        )

        Facter::Options.init

        expect(Facter::Options[:trace]).to be_falsey
      end

      it 'sets verbose to true' do
        allow(config_reader_double).to receive(:cli).and_return(
          'verbose' => true
        )

        Facter::Options.init

        expect(Facter::Options[:verbose]).to be_falsey
      end

      it 'sets logs level to debug' do
        allow(config_reader_double).to receive(:cli).and_return(
          'log-level' => :warn
        )

        Facter::Options.init

        expect(Facter::Options[:log_level]).to eq(:warn)
      end

      it 'sets show_legacy to true' do
        allow(config_reader_double).to receive(:global).and_return(
          'show-legacy' => true
        )
        Facter::Options.init

        expect(Facter::Options[:show_legacy]).to be_truthy
      end

      it 'sets blocked_facts' do
        allow(block_list_double).to receive(:blocked_facts).and_return(%w[block_fact1 blocked_fact2])

        Facter::Options.init

        expect(Facter::Options[:blocked_facts]).to eq(%w[block_fact1 blocked_fact2])
      end

      it 'sets ttls' do
        allow(config_reader_double).to receive(:ttls).and_return([{ 'timezone' => '30 days' }])

        Facter::Options.init

        expect(Facter::Options[:ttls]).to eq([{ 'timezone' => '30 days' }])
      end

      context 'when custom facts' do
        before do
          allow(config_reader_double).to receive(:global).and_return(
            'custom-dir' => %w[custom_dir1 custom_dir2]
          )
          Facter::Options.init
        end

        it 'sets custom-facts to true' do
          expect(Facter::Options[:custom_facts]).to be_truthy
        end

        it 'sets custom-dir' do
          expect(Facter::Options[:custom_dir]).to eq(%w[custom_dir1 custom_dir2])
        end

        it 'sets ruby to true' do
          expect(Facter::Options[:ruby]).to be_truthy
        end
      end

      context 'when external facts' do
        before do
          allow(config_reader_double).to receive(:global).and_return(
            'no-external-facts' => false, 'external-dir' => %w[external_dir1 external_dir2]
          )
          Facter::Options.init
        end

        it 'sets external-dir' do
          expect(Facter::Options[:external_dir]).to eq(%w[external_dir1 external_dir2])
        end

        it 'sets external-facts to true' do
          expect(Facter::Options[:external_facts]).to be_truthy
        end
      end
    end
  end
end
