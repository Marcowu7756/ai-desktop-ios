// BrainKit — BrainRegistry
//
// The switch that makes "adapter disabled" a configuration change rather than a
// refactor. If no adapter in the policy is both enabled and registered, the
// product gets `nil` and must surface that — never fake a reply.

import ProductCore

public enum BrainAdapterID: String, Sendable, Equatable, CaseIterable {
    case mock
    case foundationModels
    case remoteLLM
    /// Never instantiated by this package. Present so the policy can name it.
    case manifoldKit
}

public struct BrainPolicy: Sendable, Equatable {
    public var enabled: Set<BrainAdapterID>
    public var preferred: BrainAdapterID

    public init(enabled: Set<BrainAdapterID>, preferred: BrainAdapterID) {
        self.enabled = enabled
        self.preferred = preferred
    }

    /// V0 default: mock brain only. Everything else stays off.
    public static let v0Default = BrainPolicy(enabled: [.mock], preferred: .mock)
}

public struct BrainRegistry: Sendable {
    public typealias Factory = @Sendable () -> any BrainProtocol

    private let factories: [BrainAdapterID: Factory]

    public init(factories: [BrainAdapterID: Factory] = [:]) {
        self.factories = factories
    }

    public func register(_ id: BrainAdapterID, factory: @escaping Factory) -> BrainRegistry {
        var next = factories
        next[id] = factory
        return BrainRegistry(factories: next)
    }

    /// Returns the preferred adapter if the policy allows it and it is actually
    /// registered; otherwise the first enabled registered adapter; otherwise nil.
    public func brain(for policy: BrainPolicy) -> (any BrainProtocol)? {
        if policy.enabled.contains(policy.preferred), let factory = factories[policy.preferred] {
            return factory()
        }
        for id in BrainAdapterID.allCases where policy.enabled.contains(id) {
            if let factory = factories[id] {
                return factory()
            }
        }
        return nil
    }
}
