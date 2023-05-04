module animeswap::animeswap {
    use sui::object::UID;
    use sui::balance::{Balance, Supply};
    use sui::clock::{Self, Clock};

    struct LPCoin<phantom X, phantom Y> has drop {}

    struct LiquidityPool<phantom X, phantom Y> has key, store {
        id: UID,
        coin_x_reserve: Balance<X>,
        coin_y_reserve: Balance<Y>,
        lp_coin_reserve: Balance<LPCoin<X, Y>>,
        lp_supply: Supply<LPCoin<X, Y>>,
        last_block_timestamp: u64,
        last_price_x_cumulative: u128,
        last_price_y_cumulative: u128,
        k_last: u128,
        locked: bool,
    }

    /// entry, swap from exact X to Y
    /// no require for X Y order
    public entry fun swap_exact_coins_for_coins_entry<X, Y>(
        _lps: &mut LiquidityPools,
        _clock: &Clock,
        _coins_in_origin: Coin<X>,
        _amount_in: u64,
        _amount_out_min: u64,
        _ctx: &mut TxContext,
    ) {
        abort 0
    }

    /// entry, swap from exact X to Y to Z
    public entry fun swap_exact_coins_for_coins_2_pair_entry<X, Y, Z>(
        _lps: &mut LiquidityPools,
        _clock: &Clock,
        _coins_in_origin: Coin<X>,
        _amount_in: u64,
        _amount_out_min: u64,
        _ctx: &mut TxContext,
    ) {
        abort 0
    }

    /// entry, swap from X to exact Y
    /// no require for X Y order
    public entry fun swap_coins_for_exact_coins_entry<X, Y>(
        _lps: &mut LiquidityPools,
        _clock: &Clock,
        _coins_in_origin: Coin<X>,
        _amount_out: u64,
        _amount_in_max: u64,
        _ctx: &mut TxContext,
    ) {
        abort 0
    }

    public entry fun swap_coins_for_exact_coins_2_pair_entry<X, Y, Z>(
        _lps: &mut LiquidityPools,
        _clock: &Clock,
        _coins_in_origin: Coin<X>,
        _amount_out: u64,
        _amount_in_max: u64,
        _ctx: &mut TxContext,
    ) {
        abort 0
    }

    /// swap from Coin to Coin, both sides
    /// require X < Y
    public fun swap_coins_for_coins<X, Y>(
        _lps: &mut LiquidityPools,
        _clock: &Clock,
        _coins_x_in: Coin<X>,
        _coins_y_in: Coin<Y>,
        _ctx: &mut TxContext,
    ): (Coin<X>, Coin<Y>) {
        abort 0
    }

    /// swap from Balance to Balance, both sides
    /// require X < Y
    public fun swap_balance_for_balance<X, Y>(
        _lps: &mut LiquidityPools,
        _clock: &Clock,
        _coins_x_in: Balance<X>,
        _coins_y_in: Balance<Y>,
    ): (Balance<X>, Balance<Y>) {
        abort 0
    }

    /// Swap coins, both sides
    /// require X < Y
    public fun swap<X, Y>(
        _lps: &mut LiquidityPools,
        _clock: &Clock,
        _coins_x_in: Balance<X>,
        _amount_x_out: u64,
        _coins_y_in: Balance<Y>,
        _amount_y_out: u64,
    ): (Balance<X>, Balance<Y>) {
        abort 0
    }
}

