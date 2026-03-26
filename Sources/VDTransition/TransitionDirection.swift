import CoreGraphics

/// The direction of a transition: appearing (insertion) or disappearing (removal).
public enum TransitionDirection: String, Hashable, CaseIterable {

    case insertion, removal

    /// Creates a ``Progress`` at the given raw value in this direction.
    ///
    /// - Parameter value: Progress value (0…1).
    /// - Returns: A `Progress` case matching this direction.
    public func at(_ value: CGFloat) -> Progress {
        switch self {
        case .insertion:	return .insertion(value)
        case .removal: 		return .removal(value)
        }
    }

    /// Creates a ``Progress`` at the given edge (start or end) in this direction.
    ///
    /// - Parameter value: `.start` (0) or `.end` (1).
    /// - Returns: A `Progress` case matching this direction and edge.
    public func at(_ value: Progress.Edge) -> Progress {
        switch self {
        case .insertion:	return .insertion(value)
        case .removal: 		return .removal(value)
        }
    }
}
