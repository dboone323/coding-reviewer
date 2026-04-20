import CoreData
import Foundation

public extension ReviewIssue {
    @nonobjc
    class func fetchRequest() -> NSFetchRequest<ReviewIssue> {
        NSFetchRequest<ReviewIssue>(entityName: "ReviewIssue")
    }

    @NSManaged var id: UUID?
    @NSManaged var title: String?
    @NSManaged var detail: String?
    @NSManaged var severity: String?
    @NSManaged var session: ReviewSession?
}
