module MyModule::ReferralNetwork {
    use aptos_framework::signer;
    use aptos_framework::coin;
    use aptos_framework::aptos_coin::AptosCoin;
    use std::vector;
    use std::option::{Self, Option};

    /// Struct representing a user's referral network data
    struct ReferralData has store, key {
        referrer: Option<address>,     // Address of the user who referred this user
        referrals: vector<address>,    // List of users this person has referred
        total_rewards: u64,            // Total rewards earned from referrals
        referral_count: u64,           // Number of successful referrals made
    }

    /// Function to register a new user in the referral network
    public fun register_user(
        user: &signer, 
        referrer_address: Option<address>
    )acquires ReferralData {
        let user_addr = signer::address_of(user);
        
        // Create new referral data for the user
        let referral_data = ReferralData {
            referrer: referrer_address,
            referrals: vector::empty<address>(),
            total_rewards: 0,
            referral_count: 0,
        };
        
        move_to(user, referral_data);
        
        // If user has a referrer, add this user to referrer's list
        if (option::is_some(&referrer_address)) {
            let referrer_addr = *option::borrow(&referrer_address);
            if (exists<ReferralData>(referrer_addr)) {
                let referrer_data = borrow_global_mut<ReferralData>(referrer_addr);
                vector::push_back(&mut referrer_data.referrals, user_addr);
                referrer_data.referral_count = referrer_data.referral_count + 1;
            };
        };
    }

    /// Function to process referral rewards when a user makes a purchase/action
    public fun process_referral_reward(
        payer: &signer,
        user_address: address,
        reward_amount: u64
    ) acquires ReferralData {
        let user_data = borrow_global<ReferralData>(user_address);
        
        // Check if user has a referrer
        if (option::is_some(&user_data.referrer)) {
            let referrer_address = *option::borrow(&user_data.referrer);
            
            // Transfer reward to referrer
            let reward = coin::withdraw<AptosCoin>(payer, reward_amount);
            coin::deposit<AptosCoin>(referrer_address, reward);
            
            // Update referrer's total rewards
            let referrer_data = borrow_global_mut<ReferralData>(referrer_address);
            referrer_data.total_rewards = referrer_data.total_rewards + reward_amount;
        };
    }
}