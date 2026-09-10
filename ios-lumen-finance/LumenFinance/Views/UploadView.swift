//
//  UploadView.swift
//  LumenFinance
//
//  The primary action hub. Three submission paths: Manual Entry (fully
//  working), Upload Screenshot/Receipt (picks a photo + stubbed parser),
//  and CSV/JSON import (structured stub).
//

import SwiftUI
import SwiftData
import PhotosUI

struct UploadView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(FeatureFlags.self) private var flags

    @State private var goManual = false
    @State private var photoItem: PhotosPickerItem?
    @State private var parsedDraft: TransactionDraft?
    @State private var isParsing = false
    @State private var goReviewUpload = false
    @State private var showCSV = false
    @State private var uploadError: Bool = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.s4) {
                    intro

                    if flags.enableManualEntry {
                        optionCard(
                            icon: "square.and.pencil",
                            title: "Manual Entry",
                            subtitle: "Type the details yourself. Fast and precise.",
                            tint: Theme.accent,
                            badge: nil
                        ) { goManual = true }
                    }

                    if flags.enableOCRStub {
                        PhotosPicker(selection: $photoItem, matching: .images) {
                            optionContent(
                                icon: "camera.viewfinder",
                                title: "Upload Screenshot / Receipt",
                                subtitle: isParsing ? "Loading photo…" : "Preview stub: sample fields, not extracted data.",
                                tint: Theme.info,
                                badge: "OCR stub",
                                loading: isParsing
                            )
                        }
                        .buttonStyle(PressableStyle())
                        .disabled(isParsing)
                    }

                    if flags.enableCSVJSONImportStub {
                        optionCard(
                            icon: "tablecells",
                            title: "Import CSV / JSON",
                            subtitle: "Bring data from another tool.",
                            tint: Color(hex: "#5C6E8A"),
                            badge: "Preview"
                        ) { showCSV = true }
                    }

                    privacyNote

                    Color.clear.frame(height: 20)
                }
                .padding(.horizontal, Theme.s5)
                .padding(.top, Theme.s3)
            }
            .background(Theme.canvas)
            .scrollIndicators(.hidden)
            .navigationTitle("Add activity")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark").fontWeight(.semibold).foregroundStyle(Theme.inkSecondary)
                    }
                    .accessibilityLabel("Close add activity")
                }
            }
            .navigationDestination(isPresented: $goManual) {
                ManualEntryView { dismiss() }
            }
            .navigationDestination(isPresented: $goReviewUpload) {
                if let parsedDraft {
                    ReviewTransactionView(draft: parsedDraft) { dismiss() }
                }
            }
            .sheet(isPresented: $showCSV) { CSVImportStubView() }
            .task(id: photoItem) {
                guard let item = photoItem else { return }
                await handlePickedPhoto(item)
            }
            .alert("Photo could not be loaded", isPresented: $uploadError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Nothing was saved. Try another photo or use Manual Entry.")
            }
        }
    }

    private var intro: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("How would you like to add it?")
                .font(.system(size: 22, weight: .semibold, design: .serif))
                .foregroundStyle(Theme.ink)
            Text("Everything you add is reviewed before it's saved. Nothing syncs to a bank.")
                .font(.system(size: 14))
                .foregroundStyle(Theme.inkSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func optionCard(icon: String, title: String, subtitle: String, tint: Color, badge: String?, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            optionContent(icon: icon, title: title, subtitle: subtitle, tint: tint, badge: badge, loading: false)
        }
        .buttonStyle(PressableStyle())
    }

    private func optionContent(icon: String, title: String, subtitle: String, tint: Color, badge: String?, loading: Bool) -> some View {
        HStack(spacing: Theme.s4) {
            ZStack {
                RoundedRectangle(cornerRadius: 16).fill(tint.opacity(0.14)).frame(width: 52, height: 52)
                if loading {
                    ProgressView().tint(tint)
                } else {
                    Image(systemName: icon).font(.system(size: 22, weight: .medium)).foregroundStyle(tint)
                }
            }
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(title).font(.system(size: 16, weight: .semibold)).foregroundStyle(Theme.ink)
                    if let badge { SoftTag(text: badge, tint: tint) }
                }
                Text(subtitle).font(.system(size: 13)).foregroundStyle(Theme.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right").font(.system(size: 13, weight: .semibold)).foregroundStyle(Theme.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface()
    }

    private var privacyNote: some View {
        HStack(spacing: Theme.s2) {
            Image(systemName: "lock.shield").foregroundStyle(Theme.accent)
            Text("No OCR runs in this preview. Photos stay local in temporary storage and may be removed by the system. Check every sample field before saving.")
                .font(.system(size: 12))
                .foregroundStyle(Theme.inkSecondary)
        }
        .padding(.top, Theme.s2)
    }

    // MARK: - Stubbed parse

    private func handlePickedPhoto(_ item: PhotosPickerItem) async {
        isParsing = true
        defer { isParsing = false }
        do {
            guard let data = try await item.loadTransferable(type: Data.self), !data.isEmpty else {
                uploadError = true
                return
            }
            try Task.checkCancellation()
            let type = item.supportedContentTypes.first
            let filename = "upload_\(UUID().uuidString).\(type?.preferredFilenameExtension ?? "data")"
            let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
            try data.write(to: url, options: .atomic)
            let draft = Self.makeStubbedDraft(fileURI: url.absoluteString, sizeBytes: data.count)
            draft.source?.original_filename = nil
            draft.source?.mime_type = type?.preferredMIMEType
            parsedDraft = draft
            goReviewUpload = true
            photoItem = nil
        } catch is CancellationError {
            return
        } catch {
            uploadError = true
            photoItem = nil
        }
    }

    /// Explicit demonstration only; these values are never represented as extracted truth.
    static func makeStubbedDraft(fileURI: String?, sizeBytes: Int?) -> TransactionDraft {
        let pick = ("Preview receipt", 19.99)
        let source = TransactionSource(
            source_type: .receipt_photo,
            original_filename: nil,
            stored_file_uri: fileURI,
            file_size_bytes: sizeBytes,
            mime_type: nil,
            uploaded_at: .now,
            captured_at: nil,
            source_timezone: TimeZone.current.identifier,
            raw_extracted_text: "PREVIEW STUB — no text was extracted from the photo.",
            parse_status: .manual_review,
            source_hash: nil
        )
        let draft = TransactionDraft()
        draft.transaction_type = .expense
        draft.amountText = String(format: "%.2f", pick.1)
        draft.merchant_name = pick.0
        draft.status = .pending
        draft.source = source
        draft.confidence_score = nil
        return draft
    }
}

// MARK: - CSV / JSON import stub

struct CSVImportStubView: View {
    @Environment(\.dismiss) private var dismiss

    private let preview: [(String, String, String)] = [
        ("2026-05-28", "Trader Joe's", "-52.30"),
        ("2026-05-27", "Spotify", "-10.99"),
        ("2026-05-26", "Refund - Amazon", "+14.20"),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.s4) {
                    StubBanner(
                        title: "Import preview",
                        message: "This is a structured stub. Real CSV/JSON parsing & column mapping arrive in a later phase.",
                        icon: "tablecells"
                    )

                    FormCard(title: "Detected rows (sample)") {
                        VStack(spacing: 0) {
                            ForEach(Array(preview.enumerated()), id: \.offset) { _, row in
                                HStack {
                                    Text(row.0).font(.system(size: 13, design: .monospaced)).foregroundStyle(Theme.muted)
                                    Spacer()
                                    Text(row.1).font(.system(size: 14, weight: .medium)).foregroundStyle(Theme.ink)
                                    Spacer()
                                    Text(row.2)
                                        .font(.system(size: 14, weight: .semibold, design: .monospaced))
                                        .foregroundStyle(row.2.hasPrefix("+") ? Theme.income : Theme.ink)
                                }
                                .padding(.vertical, Theme.s2)
                                Divider().background(Theme.hairline)
                            }
                        }
                    }

                    FormCard(title: "Column mapping") {
                        DetailRow(label: "Date column", value: "column 1")
                        DetailRow(label: "Merchant column", value: "column 2")
                        DetailRow(label: "Amount column", value: "column 3")
                    }

                    Text("Import will be enabled once mapping & validation are complete.")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.muted)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                .padding(.horizontal, Theme.s5)
                .padding(.top, Theme.s3)
            }
            .background(Theme.canvas)
            .navigationTitle("CSV / JSON")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }.fontWeight(.semibold)
                }
            }
        }
    }
}
