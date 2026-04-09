import CoreData
import Foundation

public extension ReviewSession {
    @nonobjc
    class func fetchRequest() -> NSFetchRequest<ReviewSession> {
        NSFetchRequest<ReviewSession>(entityName: "ReviewSession")
    }

    @NSManaged var id: UUID?
    @NSManaged var date: Date?
    @NSManaged var summary: String?
    @NSManaged var issues: NSSet?
}

// MARK: Generated accessors for issues

public extension ReviewSession {
    @objc(addIssuesObject:)
    @NSManaged
    func addToIssues(_ value: ReviewIssue)

    @objc(removeIssuesObject:)
    @NSManaged
    func removeFromIssues(_ value: ReviewIssue)

    @objc(addIssues:)
    @NSManaged
    func addToIssues(_ values: NSSet)

    @objc(removeIssues:)
    @NSManaged
    func removeFromIssues(_ values: NSSet)
}
