import XCTest
import CoreGraphics
import SwiftUI
@testable import VDTransition

typealias Progress = VDTransition.Progress

// MARK: - Mock view for testing without UIKit/AppKit dependency

final class MockView: Transformable {

    var frame: CGRect = CGRect(x: 0, y: 0, width: 100, height: 100)
    var bounds: CGRect = CGRect(x: 0, y: 0, width: 100, height: 100)
    var anchorPoint: CGPoint = CGPoint(x: 0.5, y: 0.5)
    var affineTransform: CGAffineTransform = .identity
    var isLtrDirection: Bool = true
    var alpha: CGFloat = 1.0
    var cornerRadius: CGFloat = 0.0
    var extra: CGFloat = 0.0

    func convert(_ frame: CGRect, to: MockView?) -> CGRect { frame }
}

// MARK: - Helper

/// Validates a transition by applying it at specified progress values and checking keyPath results.
///
/// - Parameters:
///   - transition: The transition to validate.
///   - view: The view to apply the transition to.
///   - expectations: Array of (progress, expected keyPath values) pairs.
///     Each entry is a `Progress` and a list of `(keyPath, expected value, accuracy)`.
///   - file: Source file for assertion failures.
///   - line: Source line for assertion failures.
func assertTransition<Base>(
    _ transition: UITransition<Base>,
    on view: Base,
    expectations: [(progress: Progress, values: [(keyPath: PartialKeyPath<Base>, expected: CGFloat, accuracy: CGFloat)])],
    file: StaticString = #file,
    line: UInt = #line
) {
    var transition = transition
    transition.beforeTransition(view: view)

    for expectation in expectations {
        transition.update(progress: expectation.progress, view: view)
        for check in expectation.values {
            let actual = view[keyPath: check.keyPath] as! CGFloat
            XCTAssertEqual(
                actual, check.expected,
                accuracy: check.accuracy,
                "At progress \(expectation.progress): keyPath \(check.keyPath) — expected \(check.expected), got \(actual)",
                file: file, line: line
            )
        }
    }

    // Restore initial state
    transition.setInitialState(view: view)
}

// MARK: - Tests

final class UITransitionTests: XCTestCase {

    // MARK: - Identity

    func testIdentityDoesNothing() {
        let view = MockView()
        let transition = UITransition<MockView>.identity

        XCTAssertTrue(transition.isIdentity)

        var t = transition
        t.beforeTransition(view: view)
        t.update(progress: .insertion(0.5), view: view)

        XCTAssertEqual(view.alpha, 1.0)
        XCTAssertEqual(view.affineTransform, .identity)
    }

    // MARK: - Single keyPath

    func testSingleKeyPathTransition() {
        let view = MockView()
        let transition = UITransition<MockView>(\.alpha) { progress, _, value in
            progress.value(identity: value, transformed: 0)
        }

        assertTransition(transition, on: view, expectations: [
            (.insertion(0), [(\.alpha, 0.0, 0.001)]),
            (.insertion(0.5), [(\.alpha, 0.5, 0.001)]),
            (.insertion(1.0), [(\.alpha, 1.0, 0.001)]),
        ])

        // Initial state restored
        XCTAssertEqual(view.alpha, 1.0, accuracy: 0.001)
    }

    // MARK: - Two keyPath

    func testTwoKeyPathTransition() {
        let view = MockView()
        let transition = UITransition<MockView>(\.alpha, \.cornerRadius) { progress, _, values in
            (
                progress.value(identity: values.0, transformed: 0),
                progress.value(identity: values.1, transformed: 10)
            )
        }

        assertTransition(transition, on: view, expectations: [
            (.insertion(0), [(\.alpha, 0.0, 0.001), (\.cornerRadius, 10.0, 0.001)]),
            (.insertion(0.5), [(\.alpha, 0.5, 0.001), (\.cornerRadius, 5.0, 0.001)]),
            (.insertion(1.0), [(\.alpha, 1.0, 0.001), (\.cornerRadius, 0.0, 0.001)]),
        ])
    }

    // MARK: - Static .value transition

    func testValueTransition() {
        let view = MockView()
        let transition = UITransition<MockView>.value(\.alpha, 0)

        assertTransition(transition, on: view, expectations: [
            (.insertion(0), [(\.alpha, 0.0, 0.001)]),
            (.insertion(1.0), [(\.alpha, 1.0, 0.001)]),
        ])
    }

    func testConstantTransition() {
        let view = MockView()
        let transition = UITransition<MockView>.constant(\.alpha, 0.3)

        var t = transition
        t.beforeTransition(view: view)
        t.update(progress: .insertion(0), view: view)
        XCTAssertEqual(view.alpha, 0.3, accuracy: 0.001)
        t.update(progress: .insertion(0.5), view: view)
        XCTAssertEqual(view.alpha, 0.3, accuracy: 0.001)
        t.update(progress: .insertion(1.0), view: view)
        XCTAssertEqual(view.alpha, 0.3, accuracy: 0.001)
        t.setInitialState(view: view)
    }

    // MARK: - Scale (Transformable)

    func testScaleTransition() {
        let view = MockView()
        let transition = UITransition<MockView>.scale(0.5)

        var t = transition
        t.beforeTransition(view: view)

        // At insertion(0) — fully transformed: scaled to 0.5
        t.update(progress: .insertion(0), view: view)
        XCTAssertEqual(view.affineTransform.a, 0.5, accuracy: 0.001)
        XCTAssertEqual(view.affineTransform.d, 0.5, accuracy: 0.001)

        // At insertion(1) — identity: scale 1
        t.update(progress: .insertion(1.0), view: view)
        XCTAssertEqual(view.affineTransform.a, 1.0, accuracy: 0.001)
        XCTAssertEqual(view.affineTransform.d, 1.0, accuracy: 0.001)

        t.setInitialState(view: view)
        XCTAssertEqual(view.affineTransform, .identity)
    }

    // MARK: - Offset (Transformable)

    func testOffsetTransition() {
        let view = MockView()
        let transition = UITransition<MockView>.offset(x: 100, y: 50)

        var t = transition
        t.beforeTransition(view: view)

        // At insertion(0) — fully transformed
        t.update(progress: .insertion(0), view: view)
        XCTAssertEqual(view.affineTransform.tx, 100, accuracy: 0.001)
        XCTAssertEqual(view.affineTransform.ty, 50, accuracy: 0.001)

        // At insertion(1) — identity
        t.update(progress: .insertion(1.0), view: view)
        XCTAssertEqual(view.affineTransform.tx, 0, accuracy: 0.001)
        XCTAssertEqual(view.affineTransform.ty, 0, accuracy: 0.001)

        t.setInitialState(view: view)
    }

    // MARK: - Rotate (Transformable)

    func testRotateTransition() {
        let view = MockView()
        let angle: CGFloat = .pi / 4 // 45 degrees
        let transition = UITransition<MockView>.rotate(angle)

        var t = transition
        t.beforeTransition(view: view)

        // At insertion(0) — fully rotated
        t.update(progress: .insertion(0), view: view)
        XCTAssertEqual(view.affineTransform.a, cos(angle), accuracy: 0.001)
        XCTAssertEqual(view.affineTransform.b, sin(angle), accuracy: 0.001)

        // At insertion(1) — identity
        t.update(progress: .insertion(1.0), view: view)
        XCTAssertEqual(view.affineTransform.a, 1.0, accuracy: 0.001)
        XCTAssertEqual(view.affineTransform.b, 0.0, accuracy: 0.001)

        t.setInitialState(view: view)
    }

    // MARK: - Combined (non-conflicting)

    func testCombinedNonConflicting() {
        let view = MockView()
        let transition: UITransition<MockView> = .combined(
            .value(\.alpha, 0),
            .value(\.cornerRadius, 20)
        )

        assertTransition(transition, on: view, expectations: [
            (.insertion(0), [(\.alpha, 0.0, 0.001), (\.cornerRadius, 20.0, 0.001)]),
            (.insertion(1.0), [(\.alpha, 1.0, 0.001), (\.cornerRadius, 0.0, 0.001)]),
        ])
    }

    // MARK: - Combined (conflicting keyPaths — sequential application)

    func testCombinedConflictingAppliesSequentially() {
        let view = MockView()

        // Two transitions on the same keyPath (affineTransform):
        // scale(0.5) then offset(x: 100). They conflict on \.affineTransform.
        // When combined, the second should receive the result of the first.
        let transition: UITransition<MockView> = .combined(
            .scale(0.5),
            .offset(x: 100, y: 0)
        )

        var t = transition
        t.beforeTransition(view: view)

        // At insertion(0) — both fully transformed:
        // First scale 0.5, then translate 100 on the scaled transform.
        t.update(progress: .insertion(0), view: view)
        // scale(0.5) produces a=0.5, d=0.5
        // then translatedBy(x:100) on that produces tx = 0.5*100 = 50
        XCTAssertEqual(view.affineTransform.a, 0.5, accuracy: 0.001)
        XCTAssertEqual(view.affineTransform.d, 0.5, accuracy: 0.001)
        XCTAssertEqual(view.affineTransform.tx, 50, accuracy: 0.001)

        // At insertion(1) — identity
        t.update(progress: .insertion(1.0), view: view)
        XCTAssertEqual(view.affineTransform, .identity)

        t.setInitialState(view: view)
    }

    func testCombinedConflictingScaleAndRotate() {
        let view = MockView()
        let angle: CGFloat = .pi / 2

        let transition: UITransition<MockView> = .combined(
            .scale(0.5),
            .rotate(angle)
        )

        var t = transition
        t.beforeTransition(view: view)

        // At insertion(0): scale(0.5) then rotate(π/2)
        // scale: [0.5, 0, 0, 0.5]
        // rotated by π/2: a=0, b=0.5, c=-0.5, d=0
        t.update(progress: .insertion(0), view: view)
        XCTAssertEqual(view.affineTransform.a, 0.0, accuracy: 0.001)
        XCTAssertEqual(view.affineTransform.b, 0.5, accuracy: 0.001)
        XCTAssertEqual(view.affineTransform.c, -0.5, accuracy: 0.001)
        XCTAssertEqual(view.affineTransform.d, 0.0, accuracy: 0.001)

        // At insertion(1): identity
        t.update(progress: .insertion(1.0), view: view)
        XCTAssertEqual(view.affineTransform.a, 1.0, accuracy: 0.001)
        XCTAssertEqual(view.affineTransform.b, 0.0, accuracy: 0.001)

        t.setInitialState(view: view)
    }

    // MARK: - Matches

    func testMatchesSameKeyPaths() {
        let t1 = UITransition<MockView>.value(\.alpha, 0)
        let t2 = UITransition<MockView>.value(\.alpha, 0.5)
        XCTAssertTrue(t1.matches(t2))
    }

    func testMatchesDifferentKeyPaths() {
        let t1 = UITransition<MockView>.value(\.alpha, 0)
        let t2 = UITransition<MockView>.value(\.cornerRadius, 10)
        XCTAssertFalse(t1.matches(t2))
    }

    func testPatternMatch() {
        let t1 = UITransition<MockView>.value(\.alpha, 0)
        let t2 = UITransition<MockView>.value(\.alpha, 0.5)
        XCTAssertTrue(t1 ~= t2)
    }

    // MARK: - Inverted / reversed

    func testInverted() {
        let view = MockView()
        let transition = UITransition<MockView>.value(\.alpha, 0).inverted

        var t = transition
        t.beforeTransition(view: view)

        // .inverted: insertion(v) → removal(1-v)
        // insertion(0) → removal(1): progress = 1-1 = 0, alpha = transformed = 0
        t.update(progress: .insertion(0), view: view)
        XCTAssertEqual(view.alpha, 0.0, accuracy: 0.001)

        // insertion(1) → removal(0): progress = 1-0 = 1, alpha = identity = 1
        t.update(progress: .insertion(1.0), view: view)
        XCTAssertEqual(view.alpha, 1.0, accuracy: 0.001)

        t.setInitialState(view: view)
    }

    func testReversed() {
        let view = MockView()
        let transition = UITransition<MockView>.value(\.alpha, 0).reversed

        var t = transition
        t.beforeTransition(view: view)

        // .reversed flips value within same direction: insertion(v) → insertion(1-v)
        // insertion(0) → insertion(1) → identity
        t.update(progress: .insertion(0), view: view)
        XCTAssertEqual(view.alpha, 1.0, accuracy: 0.001)

        // insertion(1) → insertion(0) → fully transformed
        t.update(progress: .insertion(1.0), view: view)
        XCTAssertEqual(view.alpha, 0.0, accuracy: 0.001)

        t.setInitialState(view: view)
    }

    // MARK: - Asymmetric

    func testAsymmetric() {
        let view = MockView()
        let transition = UITransition<MockView>.asymmetric(
            insertion: .value(\.alpha, 0),
            removal: .value(\.alpha, 0.5)
        )

        var t = transition
        t.beforeTransition(view: view)

        // Insertion: alpha goes from 0 → 1
        t.update(progress: .insertion(0), view: view)
        XCTAssertEqual(view.alpha, 0.0, accuracy: 0.001)
        t.update(progress: .insertion(1.0), view: view)
        XCTAssertEqual(view.alpha, 1.0, accuracy: 0.001)

        // Removal: alpha goes from 1 → 0.5
        t.update(progress: .removal(0), view: view)
        XCTAssertEqual(view.alpha, 1.0, accuracy: 0.001)
        t.update(progress: .removal(1.0), view: view)
        XCTAssertEqual(view.alpha, 0.5, accuracy: 0.001)

        t.setInitialState(view: view)
    }

    // MARK: - Filter

    func testFilterInsertionOnly() {
        let view = MockView()
        let transition = UITransition<MockView>.value(\.alpha, 0)
            .filter(\.isInsertion)

        var t = transition
        t.beforeTransition(view: view)

        // Insertion works
        t.update(progress: .insertion(0), view: view)
        XCTAssertEqual(view.alpha, 0.0, accuracy: 0.001)
        t.update(progress: .insertion(1.0), view: view)
        XCTAssertEqual(view.alpha, 1.0, accuracy: 0.001)

        // Removal is filtered out — state unchanged (stays at identity)
        t.update(progress: .removal(0), view: view)
        XCTAssertEqual(view.alpha, 1.0, accuracy: 0.001)
        t.update(progress: .removal(1.0), view: view)
        XCTAssertEqual(view.alpha, 1.0, accuracy: 0.001)

        t.setInitialState(view: view)
    }

    // MARK: - ArrayLiteral

    func testArrayLiteralCombines() {
        let view = MockView()
        let transition: UITransition<MockView> = [
            .value(\.alpha, 0),
            .value(\.cornerRadius, 20),
        ]

        var t = transition
        t.beforeTransition(view: view)

        t.update(progress: .insertion(0), view: view)
        XCTAssertEqual(view.alpha, 0.0, accuracy: 0.001)
        XCTAssertEqual(view.cornerRadius, 20.0, accuracy: 0.001)

        t.update(progress: .insertion(1.0), view: view)
        XCTAssertEqual(view.alpha, 1.0, accuracy: 0.001)
        XCTAssertEqual(view.cornerRadius, 0.0, accuracy: 0.001)

        t.setInitialState(view: view)
    }

    // MARK: - beforeTransitionIfNeeded reuses state from matching transition

    func testBeforeTransitionIfNeededReusesState() {
        let view = MockView()
        view.alpha = 0.8

        var old = UITransition<MockView>.value(\.alpha, 0)
        old.beforeTransition(view: view)

        // Now change view state
        view.alpha = 0.3

        var new = UITransition<MockView>.value(\.alpha, 0)
        new.beforeTransitionIfNeeded(view: view, current: old)

        // Should reuse old's captured state (0.8), not capture current (0.3)
        new.update(progress: .insertion(1.0), view: view)
        XCTAssertEqual(view.alpha, 0.8, accuracy: 0.001)
    }

    // MARK: - Reset clears initial state

    func testResetClearsState() {
        let view = MockView()
        view.alpha = 0.7

        var t = UITransition<MockView>.value(\.alpha, 0)
        t.beforeTransition(view: view)
        t.reset()

        // After reset, beforeTransitionIfNeeded should capture fresh state
        view.alpha = 0.9
        t.beforeTransition(view: view)
        t.update(progress: .insertion(1.0), view: view)
        XCTAssertEqual(view.alpha, 0.9, accuracy: 0.001)
    }

    // MARK: - Constant at progress

    func testConstantAtProgress() {
        let view = MockView()
        let transition = UITransition<MockView>.value(\.alpha, 0)
            .constant(at: .insertion(0.5))

        var t = transition
        t.beforeTransition(view: view)

        // Regardless of progress passed, transition uses insertion(0.5)
        t.update(progress: .insertion(0), view: view)
        XCTAssertEqual(view.alpha, 0.5, accuracy: 0.001)
        t.update(progress: .insertion(1.0), view: view)
        XCTAssertEqual(view.alpha, 0.5, accuracy: 0.001)
        t.update(progress: .removal(0.5), view: view)
        XCTAssertEqual(view.alpha, 0.5, accuracy: 0.001)

        t.setInitialState(view: view)
    }

    // MARK: - initialState parameter

    func testInitialStateOverridesCapture() {
        let view = MockView()
        view.alpha = 0.8

        // initialState forces identity value to 1.0, ignoring captured 0.8
        let transition = UITransition<MockView>(\.alpha, initialState: 1.0) { progress, _, value in
            progress.value(identity: value, transformed: 0)
        }

        var t = transition
        t.beforeTransition(view: view)

        t.update(progress: .insertion(1.0), view: view)
        XCTAssertEqual(view.alpha, 1.0, accuracy: 0.001)

        t.update(progress: .insertion(0), view: view)
        XCTAssertEqual(view.alpha, 0.0, accuracy: 0.001)
    }

    // MARK: - Three keyPath init

    func testThreeKeyPathTransition() {
        let view = MockView()
        view.extra = 5.0
        let transition = UITransition<MockView>(\.alpha, \.cornerRadius, \.extra) { progress, _, values in
            (
                progress.value(identity: values.0, transformed: 0),
                progress.value(identity: values.1, transformed: 10),
                progress.value(identity: values.2, transformed: 0)
            )
        }

        var t = transition
        t.beforeTransition(view: view)

        t.update(progress: .insertion(0), view: view)
        XCTAssertEqual(view.alpha, 0.0, accuracy: 0.001)
        XCTAssertEqual(view.cornerRadius, 10.0, accuracy: 0.001)
        XCTAssertEqual(view.extra, 0.0, accuracy: 0.001)

        t.update(progress: .insertion(1.0), view: view)
        XCTAssertEqual(view.alpha, 1.0, accuracy: 0.001)
        XCTAssertEqual(view.cornerRadius, 0.0, accuracy: 0.001)
        XCTAssertEqual(view.extra, 5.0, accuracy: 0.001)

        t.setInitialState(view: view)
    }

    // MARK: - Insertion / removal convenience

    func testInsertionProperty() {
        let view = MockView()
        // .insertion converts removal progress to insertion (mirrored)
        let transition = UITransition<MockView>.value(\.alpha, 0).insertion

        var t = transition
        t.beforeTransition(view: view)

        // For removal(0), .insertion converts to insertion(1) → identity
        t.update(progress: .removal(0), view: view)
        XCTAssertEqual(view.alpha, 1.0, accuracy: 0.001)

        // For removal(1), .insertion converts to insertion(0) → fully transformed
        t.update(progress: .removal(1.0), view: view)
        XCTAssertEqual(view.alpha, 0.0, accuracy: 0.001)
    }

    func testRemovalProperty() {
        let view = MockView()
        let transition = UITransition<MockView>.value(\.alpha, 0).removal

        var t = transition
        t.beforeTransition(view: view)

        // For insertion(0), .removal converts to removal(1) → fully transformed
        t.update(progress: .insertion(0), view: view)
        XCTAssertEqual(view.alpha, 0.0, accuracy: 0.001)

        // For insertion(1), .removal converts to removal(0) → identity
        t.update(progress: .insertion(1.0), view: view)
        XCTAssertEqual(view.alpha, 1.0, accuracy: 0.001)
    }
}
