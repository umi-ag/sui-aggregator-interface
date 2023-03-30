module nojoswap::amm {
    use std::type_name::{Self, TypeName};
    use std::vector;
    use sui::object::{Self, UID, ID};
    use sui::balance::{Self, Balance, Supply};
    use sui::coin::{Self, Coin};
    use sui::balance::{create_supply};
    use sui::tx_context::{Self, TxContext};
    use sui::transfer;
    use sui::event;
    use sui::math;
    use sui::table::{Self, Table};

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
        pool: &mut Pool<A, B>, input: Balance<A>, min_out: u64,
    ): Balance<B> {
        abort 0
    }

    public fun swap_b<A, B>(
        pool: &mut Pool<A, B>, input: Balance<B>, min_out: u64
    ): Balance<A> {
        abort 0
    }
}