#if LUMEN_PHOTOS_DIAGNOSTIC

import SwiftUI
import PhotosUI
import UniformTypeIdentifiers
import ImageIO
import UIKit

/// Diagnostic-only physical-device harness for Phase 1B PhotosPicker characterization.
///
/// This intentionally uses the production upload path's exact transfer request:
/// `item.loadTransferable(type: Data.self)`.
///
/// It does not persist the selected image, write to SwiftData, inspect actual GPS values,
/// or modify production ingestion behavior.
struct PhotosPickerCharacterizationView: View {
    private enum Scenario: String, CaseIterable, Identifiable {
        case cameraLocationOnAutomatic
        case cameraLocationOffAutomatic
        case cameraLocationOnCurrent
        case screenshotAutomatic
        case cameraLocationOnMostCompatible
        case custom

        var id: String { rawValue }

        var title: String {
            switch self {
            case .cameraLocationOnAutomatic:
                return "Camera · Location ON · Automatic"
            case .cameraLocationOffAutomatic:
                return "Same camera photo · Location OFF · Automatic"
            case .cameraLocationOnCurrent:
                return "Same camera photo · Location ON · Current"
            case .screenshotAutomatic:
                return "Screenshot · Automatic"
            case .cameraLocationOnMostCompatible:
                return "Camera · Location ON · Most Compatible"
            case .custom:
                return "Custom / edited library image"
            }
        }

        var instruction: String {
            switch self {
            case .cameraLocationOnAutomatic:
                return "Use a camera photo that Photos shows has Location. In the system picker Options, leave Location ON and Format Automatic."
            case .cameraLocationOffAutomatic:
                return "Use the SAME camera photo. In Options, turn Location OFF and leave Format Automatic."
            case .cameraLocationOnCurrent:
                return "Use the SAME camera photo. In Options, leave Location ON and choose Format Current."
            case .screenshotAutomatic:
                return "Choose a screenshot PNG. Leave Format Automatic."
            case .cameraLocationOnMostCompatible:
                return "Optional: use the SAME camera photo with Location ON and Format Most Compatible."
            case .custom:
                return "Choose an edited/library image or another case you want to characterize."
            }
        }
    }

    @State private var selectedScenario: Scenario = .cameraLocationOnAutomatic
    @State private var selectedItem: PhotosPickerItem?
    @State private var reports: [String] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var copyMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    introCard
                    scenarioCard
                    privacyCard

                    if isLoading {
                        HStack(spacing: 10) {
                            ProgressView()
                            Text("Loading the picker-supplied representation…")
                                .foregroundStyle(.secondary)
                        }
                    }

                    if let errorMessage {
                        diagnosticCard(title: "Diagnostic error") {
                            Text(errorMessage)
                                .foregroundStyle(.red)
                                .textSelection(.enabled)
                        }
                    }

                    if !reports.isEmpty {
                        reportsCard
                    }
                }
                .padding(18)
            }
            .navigationTitle("Lumen Picker Lab")
            .navigationBarTitleDisplayMode(.inline)
            .task(id: selectedItem) {
                guard let item = selectedItem else { return }
                await characterize(item)
            }
        }
    }

    private var introCard: some View {
        diagnosticCard(title: "Phase 1B diagnostic only") {
            Text("This build characterizes the image representation delivered by the system Photos picker. It does not open Lumen’s ledger, create Transactions, save TransactionSource rows, or retain the selected image.")
                .foregroundStyle(.secondary)

            Text("The transfer request is the same one used by the current upload flow:")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text("item.loadTransferable(type: Data.self)")
                .font(.system(.footnote, design: .monospaced))
                .textSelection(.enabled)
        }
    }

    private var scenarioCard: some View {
        diagnosticCard(title: "1 · Choose the test case") {
            Picker("Scenario", selection: $selectedScenario) {
                ForEach(Scenario.allCases) { scenario in
                    Text(scenario.title).tag(scenario)
                }
            }
            .pickerStyle(.menu)

            Text(selectedScenario.instruction)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            PhotosPicker(selection: $selectedItem, matching: .images) {
                Label("2 · Open Photos picker", systemImage: "photo.on.rectangle.angled")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .disabled(isLoading)

            Text("Use the picker’s Options screen to set Location and Format as described above before selecting the asset. Lumen cannot programmatically read those per-selection option choices, so the scenario name is your test label rather than an OS-attested setting.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private var privacyCard: some View {
        diagnosticCard(title: "Privacy of this report") {
            Text("The report records metadata PRESENCE, not sensitive metadata values. It never prints GPS coordinates, captions, image bytes, filenames, merchant data, or photo contents.")
                .foregroundStyle(.secondary)

            Text("The selected image Data is inspected in memory only and is released after the report is produced.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private var reportsCard: some View {
        diagnosticCard(title: "Characterization reports") {
            HStack {
                Button {
                    UIPasteboard.general.string = reports.joined(separator: "\n\n")
                    copyMessage = "Copied all reports"
                } label: {
                    Label("Copy all", systemImage: "doc.on.doc")
                }
                .buttonStyle(.borderedProminent)

                Button(role: .destructive) {
                    reports.removeAll()
                    copyMessage = nil
                } label: {
                    Label("Clear", systemImage: "trash")
                }
                .buttonStyle(.bordered)
            }

            if let copyMessage {
                Text(copyMessage)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            ForEach(Array(reports.enumerated()), id: \.offset) { index, report in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Report \(index + 1)")
                            .font(.headline)
                        Spacer()
                        Button("Copy") {
                            UIPasteboard.general.string = report
                            copyMessage = "Copied report \(index + 1)"
                        }
                        .buttonStyle(.bordered)
                    }

                    ScrollView(.horizontal, showsIndicators: true) {
                        Text(report)
                            .font(.system(size: 11, design: .monospaced))
                            .textSelection(.enabled)
                            .fixedSize(horizontal: true, vertical: false)
                    }
                    .padding(10)
                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
    }

    private func diagnosticCard<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
            content()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(uiColor: .secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    @MainActor
    private func characterize(_ item: PhotosPickerItem) async {
        isLoading = true
        errorMessage = nil
        copyMessage = nil
        defer {
            isLoading = false
            selectedItem = nil
        }

        do {
            // Keep this transfer request identical to the current production upload flow.
            guard let data = try await item.loadTransferable(type: Data.self), !data.isEmpty else {
                errorMessage = "PhotosPicker returned no Data."
                return
            }
            try Task.checkCancellation()

            let report = Self.makeReport(
                scenario: selectedScenario.title,
                data: data,
                supportedContentTypes: item.supportedContentTypes
            )
            reports.append(report)
        } catch is CancellationError {
            errorMessage = "Selection was cancelled before characterization completed."
        } catch {
            errorMessage = "Characterization failed: \(error.localizedDescription)"
        }
    }

    private static func makeReport(
        scenario: String,
        data: Data,
        supportedContentTypes: [UTType]
    ) -> String {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let supported = supportedContentTypes.map(\.identifier).joined(separator: ",")
        let preferred = supportedContentTypes.first

        var lines: [String] = [
            "LUMEN_PHOTOS_PICKER_CHARACTERIZATION_V1",
            "scenario=\(scenario)",
            "scenario_is_user_selected_label=true",
            "picker_option_values_read_programmatically=false",
            "captured_at_utc=\(timestamp)",
            "ios_version=\(UIDevice.current.systemVersion)",
            "transfer_request=item.loadTransferable(type: Data.self)",
            "supported_content_types=\(supported.isEmpty ? "none-reported" : supported)",
            "first_supported_type=\(preferred?.identifier ?? "none")",
            "first_supported_extension=\(preferred?.preferredFilenameExtension ?? "none")",
            "first_supported_mime=\(preferred?.preferredMIMEType ?? "none")",
            "data_byte_count=\(data.count)",
            "gps_values_emitted=false",
            "caption_values_emitted=false",
            "image_contents_emitted=false"
        ]

        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
            lines.append("imageio_decode=failed")
            return lines.joined(separator: "\n")
        }

        lines.append("imageio_decode=success")
        lines.append("imageio_frame_count=\(CGImageSourceGetCount(source))")

        let decodedIdentifier: String
        if let sourceType = CGImageSourceGetType(source) {
            decodedIdentifier = sourceType as String
        } else {
            decodedIdentifier = "unknown"
        }
        let decodedType = UTType(decodedIdentifier)
        lines.append("decoded_type_identifier=\(decodedIdentifier)")
        lines.append("decoded_extension=\(decodedType?.preferredFilenameExtension ?? "unknown")")
        lines.append("decoded_mime=\(decodedType?.preferredMIMEType ?? "unknown")")

        guard let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any] else {
            lines.append("image_properties=unavailable")
            return lines.joined(separator: "\n")
        }

        func nested(_ key: CFString) -> [CFString: Any]? {
            properties[key] as? [CFString: Any]
        }

        let exif = nested(kCGImagePropertyExifDictionary)
        let gps = nested(kCGImagePropertyGPSDictionary)
        let tiff = nested(kCGImagePropertyTIFFDictionary)
        let iptc = nested(kCGImagePropertyIPTCDictionary)
        let png = nested(kCGImagePropertyPNGDictionary)
        let jfif = nested(kCGImagePropertyJFIFDictionary)

        let width = (properties[kCGImagePropertyPixelWidth] as? NSNumber)?.intValue
        let height = (properties[kCGImagePropertyPixelHeight] as? NSNumber)?.intValue
        let orientation = (properties[kCGImagePropertyOrientation] as? NSNumber)?.intValue

        lines.append("pixel_width=\(width.map(String.init) ?? "unknown")")
        lines.append("pixel_height=\(height.map(String.init) ?? "unknown")")
        lines.append("orientation=\(orientation.map(String.init) ?? "unknown")")
        lines.append("metadata_exif_present=\(yesNo(exif?.isEmpty == false))")
        lines.append("metadata_gps_present=\(yesNo(gps?.isEmpty == false))")
        lines.append("metadata_tiff_present=\(yesNo(tiff?.isEmpty == false))")
        lines.append("metadata_iptc_present=\(yesNo(iptc?.isEmpty == false))")
        lines.append("metadata_png_present=\(yesNo(png?.isEmpty == false))")
        lines.append("metadata_jfif_present=\(yesNo(jfif?.isEmpty == false))")

        let exifOriginalDate = exif?[kCGImagePropertyExifDateTimeOriginal] != nil
        let exifDigitizedDate = exif?[kCGImagePropertyExifDateTimeDigitized] != nil
        let tiffDate = tiff?[kCGImagePropertyTIFFDateTime] != nil
        let cameraMake = tiff?[kCGImagePropertyTIFFMake] != nil
        let cameraModel = tiff?[kCGImagePropertyTIFFModel] != nil
        let software = tiff?[kCGImagePropertyTIFFSoftware] != nil

        let metadataKeyNames: [String] = [exif, gps, tiff, iptc, png, jfif]
            .compactMap { $0 }
            .flatMap { dictionary in dictionary.keys.map { String(describing: $0) } }
        let captionLikeKeyPresent = metadataKeyNames.contains { key in
            let lowered = key.lowercased()
            return lowered.contains("caption") || lowered.contains("description") || lowered.contains("comment")
        }

        lines.append("exif_datetime_original_present=\(yesNo(exifOriginalDate))")
        lines.append("exif_datetime_digitized_present=\(yesNo(exifDigitizedDate))")
        lines.append("tiff_datetime_present=\(yesNo(tiffDate))")
        lines.append("camera_make_field_present=\(yesNo(cameraMake))")
        lines.append("camera_model_field_present=\(yesNo(cameraModel))")
        lines.append("software_field_present=\(yesNo(software))")
        lines.append("caption_or_description_like_metadata_key_present=\(yesNo(captionLikeKeyPresent))")

        // Deliberately report metadata existence/count only. Never serialize dictionary values.
        lines.append("exif_key_count=\(exif?.count ?? 0)")
        lines.append("gps_key_count=\(gps?.count ?? 0)")
        lines.append("tiff_key_count=\(tiff?.count ?? 0)")
        lines.append("iptc_key_count=\(iptc?.count ?? 0)")
        lines.append("png_key_count=\(png?.count ?? 0)")

        return lines.joined(separator: "\n")
    }

    private static func yesNo(_ value: Bool) -> String {
        value ? "yes" : "no"
    }
}

#endif
