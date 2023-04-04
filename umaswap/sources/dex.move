module umaswap::dex {
    use sui::object::{UID};
    use sui::coin::{Coin};
    use sui::balance::{Supply, Balance};
    use sui::tx_context::{TxContext};

    /// The Pool token that will be used to mark the pool share
    /// of a liquidity provider. The first type parameter stands
    /// for the witness type of a pool. The seconds is for the
    /// coin held in the pool.
    struct LSP<phantom X, phantom Y> has drop {}

    /// The pool with exchange.
    ///
    /// - `fee_percent` should be in the range: [0-10000), meaning
    /// that 1000 is 100% and 1 is 0.1%
    struct Pool<phantom X, phantom Y> has key {
        _id: UID,
        _reserve_x: Balance<X>,
        _reserve_y: Balance<Y>,
        _lsp_supply: Supply<LSP<X, Y>>,
        _fee_percent: u64
    }

    /// Module initializer is empty - to publish a new Pool one has
    /// to create a type which will mark LSPs.
    fun init(_: &mut TxContext) {}

    public fun swap_x_to_y_direct<X, Y>(
        _pool: &mut Pool<X, Y>,
        _coin_x: Coin<X>,
        _ctx: &mut TxContext
    ): Coin<Y> {
        abort 0
    }

    /// Swap `Coin<T>` for the `Coin<SUI>`.
    /// Returns the swapped `Coin<SUI>`.
    public fun swap_y_to_x_direct<X, Y>(
        _pool: &mut Pool<X, Y>,
        _coin_y: Coin<Y>,
        _ctx: &mut TxContext
    ): Coin<X> {
        abort 0
    }
}
