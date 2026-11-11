import StoreKit

/// StoreKit 2 wrapper for the single non-consumable "Full Game" unlock (PRD §5.6, spec §7).
/// Entitlement is never persisted by us: `Transaction.currentEntitlements` is the source of truth.
@MainActor
final class StoreService: ObservableObject {
    static let fullGameID = "com.yourstudio.grainfall.fullgame"

    enum PurchaseState: Equatable { case idle, purchasing, pending, failed(String) }

    @Published private(set) var product: Product?
    @Published private(set) var hasFullGame = false
    @Published private(set) var state: PurchaseState = .idle

    /// Listens for purchases made elsewhere (other devices, Ask to Buy, refunds). Lives as long as the app.
    private var updates: Task<Void, Never>?

    init() {
        updates = Task { [weak self] in
            for await result in Transaction.updates {
                await self?.handle(result)
            }
        }
    }

    func load() async {
        do {
            product = try await Product.products(for: [Self.fullGameID]).first
        } catch {
            product = nil
        }
        await refreshEntitlements()
    }

    func refreshEntitlements() async {
        var owned = false
        for await result in Transaction.currentEntitlements {
            if case let .verified(t) = result, t.productID == Self.fullGameID, t.revocationDate == nil {
                owned = true
            }
        }
        hasFullGame = owned
    }

    func purchase() async {
        guard let product else {
            state = .failed("The store isn't available right now. Please try again later.")
            return
        }
        state = .purchasing
        do {
            switch try await product.purchase() {
            case let .success(result):
                await handle(result)
                state = .idle
            case .pending:
                state = .pending
            case .userCancelled:
                state = .idle
            @unknown default:
                state = .idle
            }
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    /// "Restore Purchases" (required by App Review).
    func restore() async {
        do {
            try await AppStore.sync()
        } catch {
            state = .failed(error.localizedDescription)
        }
        await refreshEntitlements()
    }

    private func handle(_ result: VerificationResult<Transaction>) async {
        guard case let .verified(transaction) = result else { return }
        if transaction.productID == Self.fullGameID {
            hasFullGame = transaction.revocationDate == nil
        }
        await transaction.finish()
    }
}
