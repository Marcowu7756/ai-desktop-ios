// Apple-side probe — measurement, not verification.
//
// Purpose: convert an UNKNOWN into a recorded observation. It answers two
// questions that cannot be answered on Windows:
//
//   1. does `import FoundationModels` compile against the iOS SDK in use, and
//   2. what does `SystemLanguageModel` report in *this* environment.
//
// It deliberately does not assert that the model is available. A CI machine is
// not an iPhone: "unavailable here" is an expected and informative result.
// A green run here is NOT device verification.

import Foundation
import XCTest

#if canImport(FoundationModels)
import FoundationModels
#endif

final class AppleProbeTests: XCTestCase {
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
}
