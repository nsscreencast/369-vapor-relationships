import Routing
import Vapor
import FluentPostgreSQL

public func routes(_ router: Router) throws {
    router.get("_setup") { req -> Future<String> in
        let project = Project(title: "test project", description: "test description")
        return project.create(on: req).flatMap { project in
            let titles = ["Issue #1", "Issue #2", "Issue #3"]
            let issues = try titles.map { try Issue(subject: $0, body: "Test body for issue \($0)", projectId: project.requireID())}
            let futures = issues.map { $0.create(on: req) }
            return futures.flatten(on: req).map { issues in
                return "Created project: \(project.id!) with issues: \(issues.map { $0.id! })"
            }
        }
    }
    
    router.get("projects") { req -> Future<String> in
        return Project.find(UUID("8AB043A6-7B69-4443-B6E7-D626866A7996")!, on: req).flatMap { project in
            guard let project = project else {
                throw Abort(.notFound)
            }
            return try project.issues.query(on: req).all().map { issues in
                return issues.map { $0.subject }.joined(separator: "\n")
            }
        }
    }
    
    router.get("issue") { req -> Future<String> in
        return Issue.find(UUID("45b69719-84f1-465b-9eaa-d5713f3916c1")!, on: req).flatMap { issue in
            guard let issue = issue else {
                throw Abort(.notFound)
            }
            return issue.project.get(on: req).map { project in
                return "Issue's project is: \(project.title)"
            }
        }
    }
}
