import Foundation

extension Array where Element == URLQueryItem {
    func uniquedByName() -> [URLQueryItem] {
        var uniqueItems: [URLQueryItem] = []
        var namesEncountered: Set<String> = []
        // last takes precedence
        for item in self.reversed() where !namesEncountered.contains(item.name) {
            uniqueItems.insert(item, at: 0)
            namesEncountered.insert(item.name)
        }
        return uniqueItems
    }
}
