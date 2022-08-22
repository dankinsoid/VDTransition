import CoreGraphics

public enum TransitionDirection: String, Hashable, CaseIterable {
    
    case insertion, removal

    public func at(_ value: CGFloat) -> Progress {
        switch self {
        case .insertion:	return .insertion(value)
        case .removal: 		return .removal(value)
        }
    }

    public func at(_ value: Progress.Edge) -> Progress {
        switch self {
        case .insertion:	return .insertion(value)
        case .removal: 		return .removal(value)
        }
    }
}
