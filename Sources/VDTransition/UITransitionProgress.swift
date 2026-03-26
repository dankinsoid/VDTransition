import Foundation

/// Animation progress, distinguishing between insertion and removal directions.
///
/// Progress values range from 0 (start of the transition) to 1 (end of the transition).
/// - `.insertion(0)` = fully transformed (e.g. invisible), `.insertion(1)` = identity (e.g. fully visible).
/// - `.removal(0)` = identity, `.removal(1)` = fully transformed.
///
/// ```swift
/// // Interpolate between identity and transformed:
/// let alpha = progress.value(identity: 1.0, transformed: 0.0)
/// ```
public enum Progress: Hashable, Codable {

    /// Insertion in progress. Value goes from 0 (fully transformed) to 1 (identity).
    case insertion(CGFloat)
    /// Removal in progress. Value goes from 0 (identity) to 1 (fully transformed).
    case removal(CGFloat)
    
    /// The raw progress value (0…1), regardless of direction.
    public var value: CGFloat {
        get {
            switch self {
            case .insertion(let float): return float
            case .removal(let float): return float
            }
        }
        set {
            switch self {
            case .insertion: self = .insertion(newValue)
            case .removal: self = .removal(newValue)
            }
        }
    }
    
    /// Normalized progress: 0 = identity, 1 = fully transformed, for both directions.
    ///
    /// For insertion this equals `value`; for removal it equals `1 - value`.
    public var progress: CGFloat {
        get {
            switch self {
            case .insertion(let float): return float
            case .removal(let float): return 1 - float
            }
        }
        set {
            switch self {
            case .insertion: self = .insertion(newValue)
            case .removal: self = .removal(1 - newValue)
            }
        }
    }
    
    /// Swaps direction and flips value: `insertion(v)` → `removal(1-v)` and vice versa.
    public var inverted: Progress {
        switch self {
        case .insertion(let float): return .removal(1 - float)
        case .removal(let float): return .insertion(1 - float)
        }
    }
    
    /// Flips value within the same direction: `insertion(v)` → `insertion(1-v)`.
    public var reversed: Progress {
        switch self {
        case .insertion(let float): return .insertion(1 - float)
        case .removal(let float): return .removal(1 - float)
        }
    }
    
    public var direction: TransitionDirection {
        get {
            switch self {
            case .insertion: return .insertion
            case .removal: return .removal
            }
        }
        set {
            self = newValue.at(value)
        }
    }
    
    public var isRemoval: Bool {
        get {
            if case .removal = self {
                return true
            }
            return false
        }
        set {
            direction = newValue ? .removal : .insertion
        }
    }
    
    public var isInsertion: Bool {
        get {
            if case .insertion = self {
                return true
            }
            return false
        }
        set {
            direction = newValue ? .insertion : .removal
        }
    }
    
    public static func insertion(_ edge: Edge) -> Progress {
        .insertion(edge.progress)
    }
    
    public static func removal(_ edge: Edge) -> Progress {
        .removal(edge.progress)
    }
}

#if canImport(SwiftUI)
import SwiftUI

extension Progress {
    
    /// Interpolates between `identity` and `transformed` based on normalized progress.
    ///
    /// At progress 0 (identity state) returns `identity`; at progress 1 (fully transformed) returns `transformed`.
    ///
    /// - Parameters:
    ///   - identity: The value at rest (not transformed).
    ///   - transformed: The fully transformed value.
    /// - Returns: The interpolated value.
    public func value<T: VectorArithmetic>(identity: T, transformed: T) -> T {
        var result = (identity - transformed)
        result.scale(by: progress)
        return transformed + result
    }
}
#endif

extension Progress {
    
    public enum Edge {
        
        case start, end
        
        public var progress: CGFloat {
            switch self {
            case .start: return 0
            case .end: return 1
            }
        }
    }
}
