# frozen_string_literal: true

describe Facter::InternalFactManager do
  let(:internal_fact_manager) { Facter::InternalFactManager.new }
  let(:os_name_class_spy) { class_spy(Facts::Linux::Os::Name) }
  let(:os_name_instance_spy) { instance_spy(Facts::Linux::Os::Name) }

  describe '#resolve_facts' do
    it 'resolved one core fact' do
      resolved_fact = mock_resolved_fact('os', 'Ubuntu', nil, [])

      allow(os_name_class_spy).to receive(:new).and_return(os_name_instance_spy)
      allow(os_name_instance_spy).to receive(:call_the_resolver).and_return(resolved_fact)

      searched_fact = instance_spy(Facter::SearchedFact, name: 'os', fact_class: os_name_class_spy, filter_tokens: [],
                                                         user_query: '', type: :core)

      resolved_facts = internal_fact_manager.resolve_facts([searched_fact])

      expect(resolved_facts).to eq([resolved_fact])
    end

    it 'resolved one legacy fact' do
      networking_interface_class_spy = class_spy(Facts::Windows::NetworkInterfaces)
      windows_networking_interface = instance_spy(Facts::Windows::NetworkInterfaces)

      resolved_fact = mock_resolved_fact('network_Ethernet0', '192.168.5.121', nil, [], :legacy)

      allow(networking_interface_class_spy).to receive(:new).and_return(windows_networking_interface)
      allow(windows_networking_interface).to receive(:call_the_resolver).and_return(resolved_fact)

      searched_fact = instance_spy(Facter::SearchedFact, name: 'network_.*', fact_class: networking_interface_class_spy,
                                                         filter_tokens: [], user_query: '', type: :core)

      resolved_facts = internal_fact_manager.resolve_facts([searched_fact])

      expect(resolved_facts).to eq([resolved_fact])
    end

    context 'when there are multiple search facts pointing to the same fact' do
      before do
        resolved_fact = mock_resolved_fact('os', 'Ubuntu', nil, [])

        allow(os_name_class_spy).to receive(:new).and_return(os_name_instance_spy)
        allow(os_name_instance_spy).to receive(:call_the_resolver).and_return(resolved_fact)

        searched_fact = instance_spy(Facter::SearchedFact, name: 'os.name', fact_class: os_name_class_spy,
                                                           filter_tokens: [], user_query: '', type: :core)

        searched_fact_with_alias = instance_spy(Facter::SearchedFact, name: 'operatingsystem',
                                                                      fact_class: os_name_class_spy, filter_tokens: [],
                                                                      user_query: '', type: :core)

        internal_fact_manager.resolve_facts([searched_fact, searched_fact_with_alias])
      end

      it 'resolves the fact only once' do
        expect(os_name_instance_spy).to have_received(:call_the_resolver).once
      end
    end
  end
end
