#if canImport(UIKit)
import UIKit
import XCTest
@testable import VDTransition

final class VDTests: XCTestCase {
    
    func testMatch() {
        let transition1 = UIViewTransition.scale(1)
        let transition2 = UIViewTransition.scale(2)
        let transition3 = UIViewTransition.backgroundColor(.blue)
        
        XCTAssertTrue(transition1.matches(transition2))
        XCTAssertTrue(transition2.matches(transition1))
        XCTAssertFalse(transition3.matches(transition1))
        XCTAssertFalse(transition2.matches(transition3))
    }
}
#endif
