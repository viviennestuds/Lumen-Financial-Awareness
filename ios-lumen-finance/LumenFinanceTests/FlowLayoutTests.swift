import XCTest
import SwiftUI
@testable import LumenFinance

@MainActor
final class FlowLayoutTests: XCTestCase {
    func testFlowLayoutReturnsFiniteMeasuredSize() {
        let measurements = Measurements()
        let host = UIHostingController(rootView: MeasurementLayout(measurements: measurements) {
            Text("#essential").padding(8)
            Text("#recurring").padding(8)
        })
        _ = host.sizeThatFits(in: CGSize(width: 320, height: 800))
        XCTAssertFalse(measurements.results.isEmpty, "The layout probe must actually execute")
        for result in measurements.results {
            XCTAssertTrue(result.size.width.isFinite && result.size.height.isFinite,
                          "FlowLayout.sizeThatFits proposal=\(result.name) returned \(result.size)")
            XCTAssertGreaterThanOrEqual(result.size.width, 0)
            XCTAssertGreaterThan(result.size.height, 0)
            if result.name == "finite" { XCTAssertEqual(result.size.width, 320) }
            if result.name == "unspecified" || result.name == "infinity" {
                XCTAssertEqual(result.size.width, result.contentWidth, accuracy: 0.001,
                               "An unconstrained layout must report measured content, excluding trailing spacing")
            }
        }
    }

    private final class Measurements {
        var results: [(name: String, size: CGSize, contentWidth: CGFloat)] = []
    }

    private struct MeasurementLayout: Layout {
        let measurements: Measurements

        func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
            let contentWidth = subviews.reduce(CGFloat.zero) { $0 + $1.sizeThatFits(.unspecified).width }
                + CGFloat(max(0, subviews.count - 1)) * 8
            let proposals: [(String, ProposedViewSize)] = [
                ("unspecified", .unspecified), ("infinity", .infinity),
                ("zero", .zero), ("finite", ProposedViewSize(width: 320, height: nil))
            ]
            for (name, candidate) in proposals {
                let size = FlowLayout(spacing: 8).sizeThatFits(proposal: candidate, subviews: subviews, cache: &cache)
                measurements.results.append((name, size, contentWidth))
            }
            // The harness has a finite frame so the assertions report the production layout's raw return value.
            return CGSize(width: 320, height: 100)
        }

        func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
            FlowLayout(spacing: 8).placeSubviews(in: bounds, proposal: proposal, subviews: subviews, cache: &cache)
        }
    }
}
