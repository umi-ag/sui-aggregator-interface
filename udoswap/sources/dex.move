module udoswap::dex {
    use sui::object::{Self, UID};
    use sui::coin::{Self, Coin};
    use sui::balance::{Self, Supply, Balance};
    use sui::transfer;
    use sui::math;
    use sui::tx_context::{Self, TxContext};

    /// For when supplied Coin is zero.
    const E_ZERO_AMOUNT: u64 = 0;

    /// For when pool fee is set incorrectly.
    /// Allowed values are: [0-10000).
    const E_WRONG_FEE: u64 = 1;

    /// For when someone tries to swap in an empty pool.
    const E_RESERVES_EMPTY: u64 = 2;

    /// For when initial LSP amount is zero.
    const E_SHARE_FULL: u64 = 3;

    /// For when someone attempts to add more liquidity than u128 Math allows.
    const E_POOL_FULL: u64 = 4;

    /// The integer scaling setting for fees calculation.
    const FEE_SCALING: u128 = 10000;

    /// The max value that can be held in one of the Balances of
    /// a Pool. U64 MAX / FEE_SCALING
    const MAX_POOL_VALUE: u64 = {
        18446744073709551615 / 10000
    };

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
        id: UID,
        reserve_x: Balance<X>,
        reserve_y: Balance<Y>,
        lsp_supply: Supply<LSP<X, Y>>,
        /// Fee Percent is denominated in basis points.
        fee_percent: u64
    }

    /// Module initializer is empty - to publish a new Pool one has
    /// to create a type which will mark LSPs.
    fun init(_: &mut TxContext) {}

    /// Create new `Pool` for token `T`. Each Pool holds a `Coin<T>`
    /// and a `Coin<SUI>`. Swaps are available in both directions.
    ///
    /// Share is calculated based on Uniswap's constant product formula:
    ///  liquidity = sqrt( X * Y )
    public entry fun create_pool<X, Y>(
        fee_percent: u64,
        ctx: &mut TxContext
    ) {
        assert!(fee_percent >= 0 && fee_percent < 10000, E_WRONG_FEE);

        let lsp_supply = balance::create_supply(LSP<X, Y> {});
        transfer::share_object(Pool {
            id: object::new(ctx),
            reserve_x: balance::zero<X>(),
            reserve_y: balance::zero<Y>(),
            lsp_supply,
            fee_percent
        });
    }

    public fun create_pool_direct<X, Y>(
        coin_x: Coin<X>,
        coin_y: Coin<Y>,
        fee_percent: u64,
        ctx: &mut TxContext
    ): Coin<LSP<X, Y>> {
        let coin_amount_x = coin::value(&coin_x);
        let coin_amount_y = coin::value(&coin_y);

        assert!(coin_amount_x > 0 && coin_amount_y > 0, E_ZERO_AMOUNT);
        assert!(coin_amount_x < MAX_POOL_VALUE && coin_amount_y < MAX_POOL_VALUE, E_POOL_FULL);
        assert!(fee_percent >= 0 && fee_percent < 10000, E_WRONG_FEE);

        // Initial share of LSP is the sqrt(a) * sqrt(b)
        let share = math::sqrt(coin_amount_x) * math::sqrt(coin_amount_y);
        let lsp_supply = balance::create_supply(LSP<X, Y> {});
        let lsp = balance::increase_supply(&mut lsp_supply, share);

        transfer::share_object(Pool {
            id: object::new(ctx),
            reserve_x: coin::into_balance(coin_x),
            reserve_y: coin::into_balance(coin_y),
            lsp_supply,
            fee_percent
        });

        coin::from_balance(lsp, ctx)
    }

    entry fun swap_x_to_y<X, Y>(pool: &mut Pool<X, Y>, coin_x: Coin<X>, ctx: &mut TxContext) {
        transfer::public_transfer(
            swap_x_to_y_direct(pool, coin_x, ctx),
            tx_context::sender(ctx)
        )
    }

    public fun swap_x_to_y_direct<X, Y>(
        pool: &mut Pool<X, Y>, coin_x: Coin<X>, ctx: &mut TxContext
    ): Coin<Y> {
        assert!(coin::value(&coin_x) > 0, E_ZERO_AMOUNT);

        let balance_x = coin::into_balance(coin_x);

        // Calculate the output amount - fee
        let (reserve_x, reserve_y, _) = get_amounts(pool);

        assert!(reserve_x > 0 && reserve_y > 0, E_RESERVES_EMPTY);

        let output_amount = get_input_price(
            balance::value(&balance_x),
            reserve_x,
            reserve_y,
            pool.fee_percent
        );

        balance::join(&mut pool.reserve_x, balance_x);
        coin::take(&mut pool.reserve_y, output_amount, ctx)
    }

    /// Entry point for the `swap_token` method. Sends swapped SUI
    /// to the sender.
    entry fun swap_y_to_x<X, Y>(
        pool: &mut Pool<X, Y>, coin_y: Coin<Y>, ctx: &mut TxContext
    ) {
        transfer::public_transfer(
            swap_y_to_x_direct(pool, coin_y, ctx),
            tx_context::sender(ctx)
        )
    }

    /// Swap `Coin<T>` for the `Coin<SUI>`.
    /// Returns the swapped `Coin<SUI>`.
    public fun swap_y_to_x_direct<X, Y>(
        pool: &mut Pool<X, Y>, coin_y: Coin<Y>, ctx: &mut TxContext
    ): Coin<X> {
        assert!(coin::value(&coin_y) > 0, E_ZERO_AMOUNT);

        let balance_y = coin::into_balance(coin_y);
        let (reserve_x, reserve_y, _) = get_amounts(pool);

        assert!(reserve_x > 0 && reserve_y > 0, E_RESERVES_EMPTY);

        let output_amount = get_input_price(
            balance::value(&balance_y),
            reserve_y,
            reserve_x,
            pool.fee_percent
        );

        balance::join(&mut pool.reserve_y, balance_y);
        coin::take(&mut pool.reserve_x, output_amount, ctx)
    }

    entry fun add_liquidity<X, Y>(
        pool: &mut Pool<X, Y>, coin_x: Coin<X>, coin_y: Coin<Y>, ctx: &mut TxContext
    )
    {
        transfer::public_transfer(
            add_liquidity_direct(pool, coin_x, coin_y, ctx),
            tx_context::sender(ctx)
        );
    }

    public fun add_liquidity_direct<X, Y>(
        pool: &mut Pool<X, Y>, coin_x: Coin<X>, coin_y: Coin<Y>, ctx: &mut TxContext
    ): Coin<LSP<X, Y>>
    {
        assert!(coin::value(&coin_x) > 0, E_ZERO_AMOUNT);
        assert!(coin::value(&coin_y) > 0, E_ZERO_AMOUNT);

        let balance_x = coin::into_balance(coin_x);
        let balance_y = coin::into_balance(coin_y);

        let (reserve_x, reserve_y, lsp_supply) = get_amounts(pool);

        let x_added = balance::value(&balance_x);
        let y_added = balance::value(&balance_y);
        let share_minted = if (reserve_x * reserve_y > 0) {
            math::min(
                (x_added * lsp_supply) / reserve_x,
                (y_added * lsp_supply) / reserve_y
            )
        } else {
            math::sqrt(x_added) * math::sqrt(y_added)
        };

        let coin_amount_x = balance::join(&mut pool.reserve_x, balance_x);
        let coin_amount_y = balance::join(&mut pool.reserve_y, balance_y);

        assert!(coin_amount_x < MAX_POOL_VALUE, E_POOL_FULL);
        assert!(coin_amount_y < MAX_POOL_VALUE, E_POOL_FULL);

        let balance = balance::increase_supply(&mut pool.lsp_supply, share_minted);
        coin::from_balance(balance, ctx)
    }

    /// Entrypoint for the `remove_liquidity` method. Transfers
    /// withdrawn assets to the sender.
    entry fun remove_liquidity_<X, Y>(
        pool: &mut Pool<X, Y>,
        lsp: Coin<LSP<X, Y>>,
        ctx: &mut TxContext
    )
    {
        let (coin_x, coin_y) = remove_liquidity(pool, lsp, ctx);
        let sender = tx_context::sender(ctx);

        transfer::public_transfer(coin_x, sender);
        transfer::public_transfer(coin_y, sender);
    }

    /// Remove liquidity from the `Pool` by burning `Coin<LSP>`.
    /// Returns `Coin<T>` and `Coin<SUI>`.
    public fun remove_liquidity<X, Y>(
        pool: &mut Pool<X, Y>,
        lsp: Coin<LSP<X, Y>>,
        ctx: &mut TxContext
    ): (Coin<X>, Coin<Y>)
    {
        let lsp_amount = coin::value(&lsp);

        // If there's a non-empty LSP, we can
        assert!(lsp_amount > 0, E_ZERO_AMOUNT);

        let (reserve_x, reserve_y, lsp_supply) = get_amounts(pool);
        let x_removed = (reserve_x * lsp_amount) / lsp_supply;
        let y_removed = (reserve_y * lsp_amount) / lsp_supply;

        balance::decrease_supply(&mut pool.lsp_supply, coin::into_balance(lsp));

        (
            coin::take(&mut pool.reserve_x, x_removed, ctx),
            coin::take(&mut pool.reserve_y, y_removed, ctx)
        )
    }

    /// Public getter for the price of SUI in token T.
    /// - How much SUI one will get if they send `to_sell` amount of T;
    public fun price_x_to_y<X, Y>(pool: &Pool<X, Y>, delta_y: u64): u64
    {
        let (reserve_x, reserve_y, _) = get_amounts(pool);
        get_input_price(delta_y, reserve_y, reserve_x, pool.fee_percent)
    }

    /// Public getter for the price of token T in SUI.
    /// - How much T one will get if they send `to_sell` amount of SUI;
    public fun price_y_to_x<X, Y>(pool: &Pool<X, Y>, delta_x: u64): u64 {
        let (reserve_x, reserve_y, _) = get_amounts(pool);
        get_input_price(delta_x, reserve_x, reserve_y, pool.fee_percent)
    }


    /// Get most used values in a handy way:
    /// - amount of CoinX
    /// - amount of CoinY
    /// - total supply of LSP
    public fun get_amounts<X, Y>(pool: &Pool<X, Y>): (u64, u64, u64) {
        (
            balance::value(&pool.reserve_x),
            balance::value(&pool.reserve_y),
            balance::supply_value(&pool.lsp_supply)
        )
    }

    /// Calculate the output amount minus the fee - 0.3%
    public fun get_input_price(
        input_amount: u64, input_reserve: u64, output_reserve: u64, fee_percent: u64
    ): u64 {
        // up casts
        let (
            input_amount,
            input_reserve,
            output_reserve,
            fee_percent
        ) = (
            (input_amount as u128),
            (input_reserve as u128),
            (output_reserve as u128),
            (fee_percent as u128)
        );

        let input_amount_with_fee = input_amount * (FEE_SCALING - fee_percent);
        let numerator = input_amount_with_fee * output_reserve;
        let denominator = (input_reserve * FEE_SCALING) + input_amount_with_fee;

        (numerator / denominator as u64)
    }

    #[test_only]
    public fun init_for_testing(ctx: &mut TxContext) {
        init(ctx)
    }
}
