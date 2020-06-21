import Foundation
import Publish
import Plot

// This type acts as the configuration for your website.
struct HawkenDotIs: Website {
    enum SectionID: String, WebsiteSectionID {
        // Add the sections that you want your website to contain here:
        case cooking
        case learning
        case listening
        case making
        case reading
        case researching
        case writing
    }

    struct ItemMetadata: WebsiteItemMetadata {
        // Add any site-specific metadata that you want to use here.
    }

    // Update these properties to configure your website:
    var url = URL(string: "https://www.hawken.is")!
    var name = "hawken.is"
    var description = "My website!"
    var language: Language { .english }
    var imagePath: Path? { nil }
}

// This will generate your website using the built-in Foundation theme:
let path: Path? = nil
let rssFeedSections: Set<HawkenDotIs.SectionID> = Set(HawkenDotIs.SectionID.allCases)
let rssFeedConfig: RSSFeedConfiguration? = .default
let deploymentMethod: DeploymentMethod<HawkenDotIs>? = nil
let plugins: [Plugin<HawkenDotIs>] = []
let indentation: Indentation.Kind? = Indentation.Kind.tabs(1)

try HawkenDotIs().publish(using: [
    .group(plugins.map(PublishingStep.installPlugin)),
    .optional(.copyResources()),
    .addMarkdownFiles(),
    .sortItems(by: \.date, order: .descending),
    .generateHTML(withTheme: .foundation, indentation: indentation),
    .unwrap(rssFeedConfig) { config in
        .generateRSSFeed(including: rssFeedSections, config: config)
    },
    .generateSiteMap(indentedBy: indentation),
    .unwrap(deploymentMethod, PublishingStep.deploy),
    .deploy(using: .git("git@github.com:hawkrives/hawken.is.git")),
])
