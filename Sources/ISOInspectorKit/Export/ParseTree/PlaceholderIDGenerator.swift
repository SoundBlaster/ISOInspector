import Foundation

extension ParseTree {
    public struct PlaceholderIDGenerator: Sendable {
        private var nextIdentifier: Int64
        
        public init(startingAt initial: Int64 = -1) {
            self.nextIdentifier = initial
        }
        
        public mutating func next() -> Int64 {
            let identifier = nextIdentifier
            nextIdentifier -= 1
            return identifier
        }
    }
}
