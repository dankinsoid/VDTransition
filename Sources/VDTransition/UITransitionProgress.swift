import Foundation

public enum Progress: Hashable, Codable {
    
    case insertion(CGFloat), removal(CGFloat)
    
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
    
    public var inverted: Progress {
        switch self {
        case .insertion(let float): return .removal(1 - float)
        case .removal(let float): return .insertion(1 - float)
        }
    }
    
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
