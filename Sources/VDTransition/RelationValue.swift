import SwiftUI

public enum RelationValue<Value> {

    case absolute(Value)
    case relative(Double)
    
    public var absolute: Value? {
        if case .absolute(let value) = self { return value }
        return nil
    }
    
    public var relative: Double? {
        if case .relative(let value) = self { return value }
        return nil
    }
    
    public var type: RelationType {
        switch self {
        case .absolute: return .absolute
        case .relative: return .relative
        }
    }
}

extension RelationValue where Value: VectorArithmetic {

    public func value(for full: Value) -> Value {
        switch self {
        case .absolute(let value):
            return value
        case .relative(let koeficient):
            var result = full
            result.scale(by: koeficient)
            return result
        }
    }
}

public enum RelationType: String, Hashable {
    
    case absolute, relative
}

extension RelationValue: Equatable where Value: Equatable {}
extension RelationValue: Hashable where Value: Hashable {}

public func / <F: BinaryFloatingPoint>(_ lhs: RelationValue<F>, _ rhs: F) -> RelationValue<F> {
    switch lhs {
    case .absolute(let value): return .absolute(value / rhs)
    case .relative(let value): return .relative(value / Double(rhs))
    }
}

public func * <F: BinaryFloatingPoint>(_ lhs: RelationValue<F>, _ rhs: F) -> RelationValue<F> {
    switch lhs {
    case .absolute(let value): return .absolute(value * rhs)
    case .relative(let value): return .relative(value * Double(rhs))
    }
}

public func * <F: BinaryFloatingPoint>(_ lhs: F, _ rhs: RelationValue<F>) -> RelationValue<F> {
    rhs * lhs
}
