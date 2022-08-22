import SwiftUI

public enum RelationValue<Value> {

    case absolute(Value)
    case relative(Double)
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
