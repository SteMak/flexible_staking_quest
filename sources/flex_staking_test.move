#[test_only]
module quest::flex_staking_tests {
    use aptos_std::account;
    use aptos_std::coin;
    use aptos_std::signer;

    use aptos_std::aptos_coin as staked_coin;
    use aptos_std::aptos_coin::AptosCoin as StakeCoin;

    use quest::flex_staking::{ Self, ShareCoin, resource_seed };

    const INITIAL_BALANCE: u64 = 1_200_000_000 * 100_000_000;

    #[test(aptos_std = @aptos_std, source = @quest)]
    fun test_init(aptos_std: &signer, source: &signer) {
        let (burn_cap, mint_cap) = staked_coin::initialize_for_test(aptos_std);

        let source_address = signer::address_of(source);
        account::create_account_for_test(source_address);
        coin::register<StakeCoin>(source);
        staked_coin::mint(aptos_std, source_address, INITIAL_BALANCE);

        flex_staking::init_module_for_test(source);

        coin::destroy_burn_cap(burn_cap);
        coin::destroy_mint_cap(mint_cap);

        assert!(flex_staking::get_converted(10, false) == 10, 0);
        assert!(flex_staking::get_converted(100, true) == 100, 0);
    }

    #[test(aptos_std = @aptos_std, user = @0x885)]
    #[expected_failure(abort_code = 0x50001, location = flex_staking)]
    fun test_init_failure(aptos_std: &signer, user: &signer) {
        let (burn_cap, mint_cap) = staked_coin::initialize_for_test(aptos_std);

        let user_address = signer::address_of(user);
        account::create_account_for_test(user_address);
        coin::register<StakeCoin>(user);
        staked_coin::mint(aptos_std, user_address, INITIAL_BALANCE);

        flex_staking::init_module_for_test(user);

        coin::destroy_burn_cap(burn_cap);
        coin::destroy_mint_cap(mint_cap);
    }

    #[test(aptos_std = @aptos_std, source = @quest, user_a = @0x885)]
    fun single_user_no_rewards(aptos_std: &signer, source: &signer, user_a: &signer) {
        let (burn_cap, mint_cap) = staked_coin::initialize_for_test(aptos_std);
        flex_staking::init_for_test(source);

        let user_a_address = signer::address_of(user_a);
        account::create_account_for_test(user_a_address);
        coin::register<StakeCoin>(user_a);
        staked_coin::mint(aptos_std, user_a_address, INITIAL_BALANCE);

        coin::destroy_burn_cap(burn_cap);
        coin::destroy_mint_cap(mint_cap);

        flex_staking::deposit(user_a, 1000);

        assert!(coin::balance<ShareCoin>(user_a_address) == 1000, 0);
        assert!(coin::balance<StakeCoin>(user_a_address) == INITIAL_BALANCE - 1000, 0);

        flex_staking::deposit(user_a, 10000);

        assert!(flex_staking::get_converted(10, false) == 10, 0);
        assert!(flex_staking::get_converted(100, true) == 100, 0);

        assert!(coin::balance<ShareCoin>(user_a_address) == 10000 + 1000, 0);
        assert!(coin::balance<StakeCoin>(user_a_address) == INITIAL_BALANCE - (10000 + 1000), 0);

        flex_staking::withdraw(user_a, 10999);

        assert!(coin::balance<ShareCoin>(user_a_address) == 10000 + 1000 - 10999, 0);
        assert!(coin::balance<StakeCoin>(user_a_address) == INITIAL_BALANCE - (10000 + 1000 - 10999), 0);

        assert!(flex_staking::get_converted(10, false) == 10, 0);
        assert!(flex_staking::get_converted(100, true) == 100, 0);

        flex_staking::withdraw(user_a, 1);

        assert!(coin::balance<ShareCoin>(user_a_address) == 0, 0);
        assert!(coin::balance<StakeCoin>(user_a_address) == INITIAL_BALANCE, 0);

        assert!(flex_staking::get_converted(10, false) == 10, 0);
        assert!(flex_staking::get_converted(100, true) == 100, 0);
    }

    #[test(aptos_std = @aptos_std, source = @quest, user_a = @0x885)]
    fun single_user_rewards(aptos_std: &signer, source: &signer, user_a: &signer) {
        let (burn_cap, mint_cap) = staked_coin::initialize_for_test(aptos_std);
        flex_staking::init_for_test(source);

        let user_a_address = signer::address_of(user_a);
        account::create_account_for_test(user_a_address);
        coin::register<StakeCoin>(user_a);
        staked_coin::mint(aptos_std, user_a_address, INITIAL_BALANCE);

        let source_address = signer::address_of(source);
        account::create_account_for_test(source_address);
        coin::register<StakeCoin>(source);
        staked_coin::mint(aptos_std, source_address, INITIAL_BALANCE);

        let resource_account_address = account::create_resource_address(&source_address, resource_seed());

        coin::destroy_burn_cap(burn_cap);
        coin::destroy_mint_cap(mint_cap);

        coin::transfer<StakeCoin>(source, resource_account_address, 2000);

        flex_staking::deposit(user_a, 1000);

        assert!(coin::balance<ShareCoin>(user_a_address) == 1000, 0);
        assert!(coin::balance<StakeCoin>(user_a_address) == INITIAL_BALANCE - 1000, 0);

        assert!(flex_staking::get_converted(10, false) == 30, 0);
        assert!(flex_staking::get_converted(100, true) == 33, 0);

        flex_staking::withdraw(user_a, 999);

        assert!(coin::balance<ShareCoin>(user_a_address) == 1000 - 999, 0);
        assert!(coin::balance<StakeCoin>(user_a_address) == INITIAL_BALANCE - 1000 + 999 * 3000/1000, 0);

        assert!(flex_staking::get_converted(10, false) == 30, 0);
        assert!(flex_staking::get_converted(100, true) == 33, 0);

        flex_staking::deposit(user_a, 299 * 3);

        assert!(coin::balance<ShareCoin>(user_a_address) == 300, 0);
        assert!(coin::balance<StakeCoin>(user_a_address) == INITIAL_BALANCE + 1100, 0);

        assert!(flex_staking::get_converted(10, false) == 30, 0);
        assert!(flex_staking::get_converted(100, true) == 33, 0);

        coin::transfer<StakeCoin>(source, resource_account_address, 900);

        assert!(flex_staking::get_converted(10, false) == 60, 0);
        assert!(flex_staking::get_converted(100, true) == 16, 0);

        flex_staking::withdraw(user_a, 102);

        assert!(coin::balance<ShareCoin>(user_a_address) == 198, 0);
        assert!(coin::balance<StakeCoin>(user_a_address) == INITIAL_BALANCE + 1712, 0);

        flex_staking::deposit(user_a, 198);

        assert!(coin::balance<ShareCoin>(user_a_address) == 198 + 198 / 6, 0);
        assert!(coin::balance<StakeCoin>(user_a_address) == INITIAL_BALANCE + 1514, 0);

        assert!(flex_staking::get_converted(10, false) == 60, 0);
        assert!(flex_staking::get_converted(100, true) == 16, 0);

        flex_staking::burn(user_a, 198);

        assert!(coin::balance<ShareCoin>(user_a_address) == 198 / 6, 0);
        assert!(coin::balance<StakeCoin>(user_a_address) == INITIAL_BALANCE + 1514, 0);

        assert!(flex_staking::get_converted(10, false) == 60 * 7, 0);
        assert!(flex_staking::get_converted(100, true) == 2, 0);

        flex_staking::withdraw(user_a, 198 / 6);

        assert!(coin::balance<ShareCoin>(user_a_address) == 0, 0);
        assert!(coin::balance<StakeCoin>(user_a_address) == INITIAL_BALANCE + 1514 + 198 * 7, 0);
    }

    #[test(aptos_std = @aptos_std, source = @quest, user_a = @0x885, user_b = @0x886)]
    fun multiple_user_rewards(aptos_std: &signer, source: &signer, user_a: &signer, user_b: &signer) {
        let (burn_cap, mint_cap) = staked_coin::initialize_for_test(aptos_std);
        flex_staking::init_for_test(source);

        let user_a_address = signer::address_of(user_a);
        account::create_account_for_test(user_a_address);
        coin::register<StakeCoin>(user_a);
        staked_coin::mint(aptos_std, user_a_address, INITIAL_BALANCE);

        let user_b_address = signer::address_of(user_b);
        account::create_account_for_test(user_b_address);
        coin::register<StakeCoin>(user_b);
        staked_coin::mint(aptos_std, user_b_address, INITIAL_BALANCE);

        let source_address = signer::address_of(source);
        account::create_account_for_test(source_address);
        coin::register<StakeCoin>(source);
        staked_coin::mint(aptos_std, source_address, INITIAL_BALANCE);

        let resource_account_address = account::create_resource_address(&source_address, resource_seed());

        coin::destroy_burn_cap(burn_cap);
        coin::destroy_mint_cap(mint_cap);

        coin::transfer<StakeCoin>(source, resource_account_address, 2000);

        flex_staking::deposit(user_a, 1000);
        flex_staking::deposit(user_b, 3000);

        assert!(coin::balance<ShareCoin>(user_a_address) == 1000, 0);
        assert!(coin::balance<StakeCoin>(user_a_address) == INITIAL_BALANCE - 1000, 0);
        assert!(coin::balance<ShareCoin>(user_b_address) == 1000, 0);
        assert!(coin::balance<StakeCoin>(user_b_address) == INITIAL_BALANCE - 3000, 0);

        assert!(flex_staking::get_converted(10, false) == 30, 0);
        assert!(flex_staking::get_converted(100, true) == 33, 0);

        flex_staking::burn(user_a, 500);

        assert!(flex_staking::get_converted(10, false) == 40, 0);
        assert!(flex_staking::get_converted(100, true) == 25, 0);

        flex_staking::withdraw(user_b, 800);
        flex_staking::burn(user_b, 200);
        flex_staking::withdraw(user_a, 400);

        assert!(coin::balance<ShareCoin>(user_a_address) == 100, 0);
        assert!(coin::balance<StakeCoin>(user_a_address) == INITIAL_BALANCE + 1240, 0);
        assert!(coin::balance<ShareCoin>(user_b_address) == 0, 0);
        assert!(coin::balance<StakeCoin>(user_b_address) == INITIAL_BALANCE + 200, 0);

        assert!(flex_staking::get_converted(10, false) == 56, 0);
        assert!(flex_staking::get_converted(100, true) == 17, 0);
    }

    #[test(aptos_std = @aptos_std, source = @quest, user_a = @0x885)]
    #[expected_failure(abort_code = 0x10002, location = flex_staking)]
    fun test_too_big_deposit_failure(aptos_std: &signer, source: &signer, user_a: &signer) {
        let (burn_cap, mint_cap) = staked_coin::initialize_for_test(aptos_std);
        flex_staking::init_for_test(source);

        let user_a_address = signer::address_of(user_a);
        account::create_account_for_test(user_a_address);
        coin::register<StakeCoin>(user_a);
        staked_coin::mint(aptos_std, user_a_address, INITIAL_BALANCE);

        coin::destroy_burn_cap(burn_cap);
        coin::destroy_mint_cap(mint_cap);

        flex_staking::deposit(user_a, INITIAL_BALANCE + 1);
    }

    #[test(aptos_std = @aptos_std, source = @quest, user_a = @0x885)]
    #[expected_failure(abort_code = 0x10002, location = flex_staking)]
    fun test_too_big_withdraw_failure(aptos_std: &signer, source: &signer, user_a: &signer) {
        let (burn_cap, mint_cap) = staked_coin::initialize_for_test(aptos_std);
        flex_staking::init_for_test(source);

        let user_a_address = signer::address_of(user_a);
        account::create_account_for_test(user_a_address);
        coin::register<StakeCoin>(user_a);
        staked_coin::mint(aptos_std, user_a_address, INITIAL_BALANCE);

        let source_address = signer::address_of(source);
        account::create_account_for_test(source_address);
        coin::register<StakeCoin>(source);
        staked_coin::mint(aptos_std, source_address, INITIAL_BALANCE);

        let resource_account_address = account::create_resource_address(&source_address, resource_seed());

        coin::destroy_burn_cap(burn_cap);
        coin::destroy_mint_cap(mint_cap);

        coin::transfer<StakeCoin>(source, resource_account_address, 1001);

        flex_staking::deposit(user_a, 1000);
        flex_staking::withdraw(user_a, 1000 + 1);
    }

    #[test(aptos_std = @aptos_std, source = @quest, user_a = @0x885)]
    fun test_big_invest_success(aptos_std: &signer, source: &signer, user_a: &signer) {
        let (burn_cap, mint_cap) = staked_coin::initialize_for_test(aptos_std);
        flex_staking::init_for_test(source);

        let user_a_address = signer::address_of(user_a);
        account::create_account_for_test(user_a_address);
        coin::register<StakeCoin>(user_a);
        staked_coin::mint(aptos_std, user_a_address, INITIAL_BALANCE);

        coin::destroy_burn_cap(burn_cap);
        coin::destroy_mint_cap(mint_cap);

        flex_staking::deposit(user_a, INITIAL_BALANCE);

        assert!(coin::balance<ShareCoin>(user_a_address) == INITIAL_BALANCE, 0);
        assert!(coin::balance<StakeCoin>(user_a_address) == 0, 0);

        assert!(flex_staking::get_converted(10, false) == 10, 0);
        assert!(flex_staking::get_converted(100, true) == 100, 0);

        flex_staking::withdraw(user_a, INITIAL_BALANCE);

        assert!(coin::balance<ShareCoin>(user_a_address) == 0, 0);
        assert!(coin::balance<StakeCoin>(user_a_address) == INITIAL_BALANCE, 0);
    }
}
