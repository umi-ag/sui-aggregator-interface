module nojoswap::amm {
    use sui::object::UID;
    use sui::balance::{Balance, Supply};

    struct LP<phantom A, phantom B> has drop { }

    struct Pool<phantom A, phantom B> has key {
        id: UID,
        balance_a: Balance<A>,
        balance_b: Balance<B>,
        lp_supply: Supply<LP<A, B>>,
        lp_fee_bps: u64,
        admin_fee_pct: u64,
        admin_fee_balance: Balance<LP<A, B>>
    }

    public fun swap_a<A, B>(
        _pool: &mut Pool<A, B>,
        _input: Balance<A>,
        _min_out: u64,
    ): Balance<B> {
        abort 0
    }

    public fun swap_b<A, B>(
        _pool: &mut Pool<A, B>,
        _input: Balance<B>,
        _min_out: u64
    ): Balance<A> {
        abort 0
    }
}

