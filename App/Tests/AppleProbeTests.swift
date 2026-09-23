// Apple-side probes — measurement, not verification.
//
// Two independent experiments live here, and their results are recorded
// separately:
//
//   PROBE ...       what environment is this, and is the model importable
//   GENERATION ...  one real request: did it complete, what came back, how long
//
// Neither asserts anything about success. A measurement that fails is still a
// measurement, and a green run here is NOT device verification. To see what
// actually happened, read the GENERATION lines — the job can be green while
// generation failed.

import Foundation
import XCTest

#if canImport(FoundationModels)
import FoundationModels
#endif

final class AppleProbeTests: XCTestCase {
    private static func timestamp() -> String {
        ISO8601DateFormatter().string(from: Date())
    }

    func testReportAppleEnvironment() {
        print("PROBE os=\(ProcessInfo.processInfo.operatingSystemVersionString)")

#if canImport(FoundationModels)
        print("PROBE FoundationModels=importable")
        if #available(iOS 26.0, macOS 26.0, *) {
            let model = SystemLanguageModel.default
            print("PROBE SystemLanguageModel.availability=\(String(describing: model.availability))")
        } else {
            print("PROBE FoundationModels=importable but API needs iOS 26+ at runtime")
        }
#else
        print("PROBE FoundationModels=NOT importable in this SDK")
#endif
    }

    /// One minimal request. Deliberately not asserting success.
    func testAttemptOneGenerationRequest() async {
        print("GENERATION started=\(Self.timestamp())")

#if canImport(FoundationModels)
        guard #available(iOS 26.0, macOS 26.0, *) else {
            print("GENERATION result=skipped reason=os_below_26")
            return
        }

        let model = SystemLanguageModel.default
        print("GENERATION availability=\(String(describing: model.availability))")

        let prompt = "Reply with exactly one word: pong"
        print("GENERATION prompt=\"\(prompt)\"")

        let session = LanguageModelSession()
        let started = Date()

        do {
            let response = try await session.respond(to: prompt)
            let elapsed = Date().timeIntervalSince(started)
            let text = response.content.trimmingCharacters(in: .whitespacesAndNewlines)
            print("GENERATION result=succeeded")
            print("GENERATION latency=\(String(format: "%.3f", elapsed))s")
            print("GENERATION output=\"\(text)\"")
        } catch {
            let elapsed = Date().timeIntervalSince(started)
            print("GENERATION result=failed")
            print("GENERATION latency=\(String(format: "%.3f", elapsed))s")
            print("GENERATION error=\(String(describing: error))")
        }

        print("GENERATION finished=\(Self.timestamp())")
#else
        print("GENERATION result=skipped reason=framework_not_importable")
#endif
    }
}
