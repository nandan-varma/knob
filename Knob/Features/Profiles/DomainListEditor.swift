import SwiftUI

struct DomainListEditor: View {
    @Binding var domains: [String]
    @State private var newDomain = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                TextField("e.g. twitter.com", text: $newDomain)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit(addDomain)
                Button("Add", action: addDomain)
                    .disabled(normalized(newDomain).isEmpty)
            }

            ForEach(domains, id: \.self) { domain in
                HStack {
                    Text(domain)
                    Spacer()
                    Button {
                        domains.removeAll { $0 == domain }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func addDomain() {
        let cleaned = normalized(newDomain)
        guard !cleaned.isEmpty, !domains.contains(cleaned) else { return }
        domains.append(cleaned)
        newDomain = ""
    }

    private func normalized(_ raw: String) -> String {
        raw.trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: "https://", with: "")
            .replacingOccurrences(of: "http://", with: "")
            .replacingOccurrences(of: "www.", with: "")
    }
}
