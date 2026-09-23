// ProductCore — CompanionSession
//
// The turn loop, owned by the verified layer.
//
// This logic used to live in the SwiftUI view model, which put the project's
// most important logic inside its only unverifiable file. Moving it here means
// the loop is covered by the same hard gate as the rest of ProductCore, and the
// shell is left with presentation only.
//
// No UI strings live here: an outcome is a typed value, and the shell decides
// how to say it.

import Foundation

public enum CompanionSessionOutcome: Sendable, Equatable {
    case replied
    /// No adapter is enabled or registered. Surfaced, never faked.
    case noBrainConfigured
    case brainFailed(BrainError)
}

/// What a view model needs in order to render one submitted turn.
public struct CompanionSessionResult: Sendable, Equatable {
    public var state: PersonaState
    /// The committed turn, or nil when nothing was committed.
    public var turn: CompanionTurn?
    public var outcome: CompanionSessionOutcome
    /// Present only when the turn carried an action intent.
    public var actionDecision: ActionDecision?

    public init(
        state: PersonaState,
        turn: CompanionTurn?,
        outcome: CompanionSessionOutcome,
        actionDecision: ActionDecision? = nil
    ) {
        self.state = state
        self.turn = turn
        self.outcome = outcome
        self.actionDecision = actionDecision
    }
}

/// Owns one companion's live state, transcript, and turn loop.
public actor CompanionSession {
    /// How many past turns are handed to the brain as context.
    public static let contextWindow = 8

    private let brain: (any BrainProtocol)?
    private let memory: any SessionMemoryStore
    private let mapper: PresentationMapper
    private let actionBoundary: ActionBoundary

    private var state: PersonaState
    private var transcript: [CompanionTurn] = []

    public init(
        persona: Persona,
        brain: (any BrainProtocol)?,
        memory: any SessionMemoryStore = InMemorySessionMemoryStore(),
        mapper: PresentationMapper = PresentationMapper(),
        actionBoundary: ActionBoundary = ActionBoundary()
    ) {
        self.state = PersonaState(persona: persona)
        self.brain = brain
        self.memory = memory
        self.mapper = mapper
        self.actionBoundary = actionBoundary
    }

    public func currentState() -> PersonaState {
        state
    }

    public func turns() -> [CompanionTurn] {
        transcript
    }

    /// Runs one turn. Nothing is committed unless the brain produced a usable
    /// response that ProductCore's mapper accepted.
    public func submit(_ utterance: String) async -> CompanionSessionResult {
        guard let brain else {
            return CompanionSessionResult(
                state: state,
                turn: nil,
                outcome: .noBrainConfigured
            )
        }

        let thinking = state.characterState.withPresence(.thinking)
        state.characterState = thinking

        let input = BrainInput(
            utterance: utterance,
            context: ConversationContext(
                recentTurns: await memory.recent(limit: Self.contextWindow),
                rememberedFacts: await memory.facts()
            ),
            persona: state.persona,
            currentState: thinking
        )

        let response: BrainResponse
        do {
            response = try await brain.respond(to: input)
        } catch let error as BrainError {
            state.characterState = thinking.withPresence(.failed)
            return CompanionSessionResult(state: state, turn: nil, outcome: .brainFailed(error))
        } catch {
            state.characterState = thinking.withPresence(.failed)
            return CompanionSessionResult(
                state: state,
                turn: nil,
                outcome: .brainFailed(.unavailable(reason: String(describing: error)))
            )
        }

        // The deterministic step. Everything downstream of this line is
        // reproducible from the brain's response plus the previous state.
        let turn = mapper.map(response, previous: thinking)
        state.characterState = turn.characterState
        transcript.append(turn)

        await memory.append(turn)
        for event in turn.memoryEvents {
            await memory.remember(event)
        }

        // Authorization is decided before the result is handed back, so the
        // decision is part of the turn rather than a detached side effect.
        var decision: ActionDecision?
        if let intent = turn.actionIntent {
            decision = await actionBoundary.submit(
                intent,
                context: JudgmentContext(personaID: state.persona.id)
            )
        }

        return CompanionSessionResult(
            state: state,
            turn: turn,
            outcome: .replied,
            actionDecision: decision
        )
    }
}
