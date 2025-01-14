 #[starknet::interface]
trait ITry<TContractState> {
    fn get_value(self: @TContractState) -> u128;
    fn increase_value(ref self: TContractState) -> u128;
    fn decrease_value(ref self: TContractState) -> u128;
}

#[starknet::contract]
mod gammer {
    use openzeppelin::access::ownable::OwnableComponent;
    use openzeppelin::upgrades::interface::IUpgradeable;
    use openzeppelin::upgrades::UpgradeableComponent;
    use starknet::{ClassHash, ContractAddress};

    component!(path: UpgradeableComponent, storage: upgradeable, event: UpgradeableEvent);
    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);


    #[abi(embed_v0)]
    impl OwnableMixinImpl = OwnableComponent::OwnableMixinImpl<ContractState>;
    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;
    // Upgradeable
    impl UpgradeableInternalImpl = UpgradeableComponent::InternalImpl<ContractState>;

    #[storage]
    struct Storage {
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
        #[substorage(v0)]
        upgradeable: UpgradeableComponent::Storage,
        value: u128,
        name: felt252
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        OwnableEvent: OwnableComponent::Event,
        #[flat]
        UpgradeableEvent: UpgradeableComponent::Event,
    }

    #[constructor]
    fn constructor(ref self: ContractState,owner: ContractAddress, intial_value: u128) {
        self.ownable.initializer(owner);
        self.value.write(intial_value );
    }

    #[abi(embed_v0)]
    impl TryImpl of super:: ITry<ContractState> {
        fn get_value(self: @ContractState)-> u128 {
            self.value.read()
        }

        fn increase_value(ref self: ContractState) -> u128{
            self.value.write(self.value.read() + 1);
            self.value.read()
        }

        fn decrease_value(ref self: ContractState) -> u128{
            assert(self.value.read() > 0, 'number < 0');
            self.value.write(self.value.read() - 1);
            self.value.read()
        }
    }

   //
    // Upgradeable
    //
    
    #[abi(embed_v0)]
    impl UpgradeableImpl of IUpgradeable<ContractState> {
        fn upgrade(ref self: ContractState, new_class_hash: ClassHash) {
            self.ownable.assert_only_owner();
            self.upgradeable.upgrade(new_class_hash);
        }
    }
}