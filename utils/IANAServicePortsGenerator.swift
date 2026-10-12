#!/usr/bin/env swift
import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

#if canImport(FoundationXML)
import FoundationXML
#endif

let registryURL =
    "https://www.iana.org/assignments/service-names-port-numbers/service-names-port-numbers.csv"
let rfcIndexURL = "https://www.rfc-editor.org/rfc-index.xml"
let outputPath = "Sources/IPAddress/Port/IANAServicePorts.swift"

/// The column width available to a doc comment line, after the 4 spaces of indentation and the
/// 4 characters of the `/// ` prefix. Keeps the emitted file within swift-format's `lineLength`.
let docCommentWidth = 92

/// Stands in for the spaces inside a rendered link, so word wrapping cannot break the link
/// across two lines. `docComment` turns it back into a space once the lines are laid out.
let nonBreakingSpace = "\u{1}"

func fetchWithRetries(url: URL) throws -> Data {
    for _ in 1..<5 {
        do {
            return try Data(contentsOf: url)
        } catch {
            print("✗ Failed to fetch \(url): \(String(reflecting: error))")
            print("Retrying in 3 seconds...")
            sleep(3)
        }
    }
    return try Data(contentsOf: url)
}

/// A minimal [RFC 4180] CSV parser. The registry quotes fields that contain commas, quotes or
/// newlines, all three of which occur in the `Description` and `Assignment Notes` columns.
///
/// [RFC 4180]: https://datatracker.ietf.org/doc/html/rfc4180
func parseCSV(_ text: String) -> [[String]] {
    // Scalars rather than characters, because Swift treats a `\r\n` pair as a single grapheme
    // cluster, which would hide every row separator in the registry.
    let scalars = Array(text.unicodeScalars)
    var rows: [[String]] = []
    var row: [String] = []
    var field = ""
    var inQuotes = false
    var idx = 0

    while idx < scalars.count {
        let scalar = scalars[idx]

        if inQuotes {
            if scalar == "\"" {
                if idx + 1 < scalars.count, scalars[idx + 1] == "\"" {
                    field.unicodeScalars.append("\"")
                    idx += 2
                    continue
                }
                inQuotes = false
            } else {
                field.unicodeScalars.append(scalar)
            }
            idx += 1
            continue
        }

        switch scalar {
        case "\"":
            inQuotes = true
        case ",":
            row.append(field)
            field = ""
        case "\n":
            row.append(field)
            rows.append(row)
            row = []
            field = ""
        case "\r":
            break
        default:
            field.unicodeScalars.append(scalar)
        }

        idx += 1
    }

    if !field.isEmpty || !row.isEmpty {
        row.append(field)
        rows.append(row)
    }

    return rows
}

/// One IANA service name on one port number. The registry spreads that pair over as many rows as
/// it has transport protocols.
struct ServicePort: Hashable {
    var name: String
    var port: UInt16
}

struct Registration {
    var transports: Set<String> = []
    var description: String = ""
    var references: Set<String> = []
}

func isPlainIdentifier(_ name: String) -> Bool {
    guard let first = name.first, first.isASCII, first.isLetter || first == "_" else {
        return false
    }
    return name.allSatisfy {
        $0.isASCII && ($0.isLetter || $0.isNumber || $0 == "_")
    }
}

/// [SE-0451] raw identifiers may not contain a backtick, a backslash, or any whitespace other
/// than a space, and may not consist solely of spaces.
///
/// [SE-0451]: https://github.com/swiftlang/swift-evolution/blob/main/proposals/0451-escaped-identifiers.md
func isValidRawIdentifier(_ name: String) -> Bool {
    guard !name.isEmpty, name.contains(where: { $0 != " " }) else {
        return false
    }
    return !name.contains(where: { $0 == "`" || $0 == "\\" || ($0.isWhitespace && $0 != " ") })
}

func identifier(_ name: String) -> String? {
    if isPlainIdentifier(name) {
        return name
    }
    guard isValidRawIdentifier(name) else {
        return nil
    }
    return "`\(name)`"
}

/// Collapses every run of whitespace into a single space, so the text is safe to place on a
/// single `///` line.
func singleLine(_ text: String) -> String {
    text.split(whereSeparator: \.isWhitespace).joined(separator: " ")
}

func wrapped(_ text: String, width: Int) -> [String] {
    var lines: [String] = []
    var line = ""

    for word in text.split(separator: " ") {
        if line.isEmpty {
            line = String(word)
        } else if line.count + 1 + word.count <= width {
            line += " " + word
        } else {
            lines.append(line)
            line = String(word)
        }
    }

    if !line.isEmpty {
        lines.append(line)
    }

    return lines
}

func docComment(_ paragraphs: [String]) -> String {
    let rendered = paragraphs.filter { !$0.isEmpty }.map { paragraph in
        wrapped(paragraph, width: docCommentWidth)
            .map { "    /// \($0.replacingOccurrences(of: nonBreakingSpace, with: " "))\n" }
            .joined()
    }
    return rendered.joined(separator: "    ///\n")
}

/// The registry packs several references into one field, each in its own pair of brackets.
/// For example `[RFC 7858][RFC 8094][RFC 9250]`.
func parseReferences(_ raw: String) -> [String] {
    var references: [String] = []
    var current = ""
    var depth = 0

    for character in raw {
        switch character {
        case "[":
            depth += 1
            if depth == 1 {
                continue
            }
        case "]":
            depth -= 1
            if depth == 0 {
                let reference = singleLine(current)
                if !reference.isEmpty {
                    references.append(reference)
                }
                current = ""
                continue
            }
        default:
            break
        }

        if depth > 0 {
            current.append(character)
        }
    }

    return references
}

/// The number of a published RFC, for a reference such as `RFC 9110` or `RFC9110`.
///
/// Deliberately rejects the registry's in-progress draft references, such as
/// `RFC-ietf-anima-brski-prm-23`, which do not name a published RFC yet.
func publishedRFCNumber(_ reference: String) -> String? {
    guard
        reference.count > 3,
        reference.hasPrefix("RFC"),
        case let number = reference.dropFirst(3).trimmingPrefix(" "),
        !number.isEmpty,
        number.allSatisfy(\.isNumber)
    else {
        return nil
    }
    return String(number)
}

func canonicalReference(_ reference: String) -> String {
    guard let number = publishedRFCNumber(reference) else {
        return reference
    }
    return "RFC \(number)"
}

/// Every RFC status that [rfc-index.xsd] allows. The schema refers to [RFC 2026] for their
/// meaning.
///
/// [rfc-index.xsd]: https://www.rfc-editor.org/rfc-index.xsd
/// [RFC 2026]: https://datatracker.ietf.org/doc/html/rfc2026
enum RFCStatus: String {
    case internetStandard = "INTERNET STANDARD"
    case draftStandard = "DRAFT STANDARD"
    case proposedStandard = "PROPOSED STANDARD"
    case unknown = "UNKNOWN"
    case bestCurrentPractice = "BEST CURRENT PRACTICE"
    case forYourInformation = "FOR YOUR INFORMATION"
    case experimental = "EXPERIMENTAL"
    case historic = "HISTORIC"
    case informational = "INFORMATIONAL"

    /// [RFC 2026] says Experimental, Informational and Historic RFCs "are not Internet Standards
    /// in any sense". [RFC 6410] keeps the existing Draft Standards on the Standards Track.
    ///
    /// [RFC 2026]: https://datatracker.ietf.org/doc/html/rfc2026#section-4.2
    /// [RFC 6410]: https://datatracker.ietf.org/doc/html/rfc6410#section-2.3
    var isStandardsTrackOrBCP: Bool {
        switch self {
        case .internetStandard, .draftStandard, .proposedStandard, .bestCurrentPractice:
            return true
        case .unknown, .forYourInformation, .experimental, .historic, .informational:
            return false
        }
    }
}

/// Collects the `current-status` of every `rfc-entry` in the [RFC index], by RFC number. Only
/// the direct children of an `rfc-entry` count, since `doc-id` also nests deeper, for example
/// in `obsoleted-by`.
///
/// [RFC index]: https://www.rfc-editor.org/rfc-index.xml
final class RFCIndexParserDelegate: NSObject, XMLParserDelegate {
    var statuses: [Int: RFCStatus] = [:]
    var elementNames: [String] = []
    var text = ""
    var docID: String?
    var currentStatus: String?

    func parser(
        _ parser: XMLParser,
        didStartElement elementName: String,
        namespaceURI: String?,
        qualifiedName: String?,
        attributes: [String: String]
    ) {
        elementNames.append(elementName)
        text = ""
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        text += string
    }

    func parser(
        _ parser: XMLParser,
        didEndElement elementName: String,
        namespaceURI: String?,
        qualifiedName: String?
    ) {
        elementNames.removeLast()

        if elementName == "rfc-entry" {
            addEntry()
        } else if elementNames.last == "rfc-entry", elementName == "doc-id" {
            guard docID == nil else {
                fatalError("An RFC index entry has a second doc-id, \(text).")
            }
            docID = text
        } else if elementNames.last == "rfc-entry", elementName == "current-status" {
            guard currentStatus == nil else {
                fatalError("An RFC index entry has a second current-status, \(text).")
            }
            currentStatus = text
        }
    }

    func addEntry() {
        guard
            let docID,
            docID.hasPrefix("RFC"),
            case let digits = docID.dropFirst(3),
            digits.allSatisfy({ $0.isASCII && $0.isNumber }),
            let number = Int(digits)
        else {
            fatalError("An RFC index entry has an unexpected doc-id, \(String(reflecting: docID)).")
        }
        guard let currentStatus, let status = RFCStatus(rawValue: currentStatus) else {
            fatalError(
                "The RFC index has an unexpected current-status for \(docID), "
                    + "\(String(reflecting: currentStatus))."
            )
        }
        guard statuses.updateValue(status, forKey: number) == nil else {
            fatalError("The RFC index lists \(docID) more than once.")
        }
        self.docID = nil
        self.currentStatus = nil
    }
}

func parseRFCIndex(_ data: Data) -> [Int: RFCStatus] {
    let delegate = RFCIndexParserDelegate()
    // swift-corelibs-foundation hands `XMLParser(data:)` to libxml2 in one piece, which libxml2
    // 2.9 rejects past 10 MB as a "Huge input lookup". A stream reaches libxml2 in chunks.
    let parser = XMLParser(stream: InputStream(data: data))
    parser.delegate = delegate
    // swift-corelibs-foundation runs libxml2 in recovery mode, so `parse()` can succeed on a
    // malformed document and only report the error in `parserError`.
    guard parser.parse(), parser.parserError == nil else {
        fatalError("Failed to parse the RFC index: \(String(reflecting: parser.parserError)).")
    }
    guard !delegate.statuses.isEmpty else {
        fatalError("The RFC index is empty.")
    }
    return delegate.statuses
}

/// The references to Standards Track and Best Current Practice RFCs. A reference to an RFC that
/// the RFC index does not list is left out, and collected into `unlistedRFCs`.
func standardsTrackOrBCPReferences(
    _ references: [String],
    statuses: [Int: RFCStatus],
    unlistedRFCs: inout Set<String>
) -> [String] {
    var standards: [String] = []
    for reference in references {
        guard let number = publishedRFCNumber(reference) else {
            continue
        }
        guard let rfc = Int(number), let status = statuses[rfc] else {
            unlistedRFCs.insert(reference)
            continue
        }
        if status.isStandardsTrackOrBCP {
            standards.append(reference)
        }
    }
    return standards
}

/// Renders an RFC reference as a link to its datatracker page.
func renderReference(_ reference: String) -> String? {
    guard let number = publishedRFCNumber(reference) else {
        return nil
    }
    let label = ["IETF", "RFC", number].joined(separator: nonBreakingSpace)
    return "[\(label)](https://datatracker.ietf.org/doc/html/rfc\(number))"
}

func referencesPhrase(_ references: Set<String>) -> String {
    let rendered = references.sorted().compactMap(renderReference)
    switch rendered.count {
    case 0:
        return ""
    case 1:
        return "Defined in \(rendered[0])."
    default:
        let allButLast = rendered.dropLast().joined(separator: ", ")
        return "Defined in \(allButLast) and \(rendered[rendered.count - 1])."
    }
}

func transportsPhrase(_ transports: Set<String>) -> String {
    let sorted = transports.sorted()
    switch sorted.count {
    case 0:
        return ""
    case 1:
        return "Registered for \(sorted[0]) transport protocol."
    default:
        let allButLast = sorted.dropLast().joined(separator: ", ")
        return
            "Registered for \(allButLast) and \(sorted[sorted.count - 1]) transport protocols."
    }
}

func column(_ name: String, in header: [String]) -> Int {
    guard let index = header.firstIndex(of: name) else {
        fatalError("The registry has no '\(name)' column. Columns: \(header).")
    }
    return index
}

func build(_ rows: [[String]], rfcStatuses: [Int: RFCStatus]) -> [ServicePort: Registration] {
    guard let header = rows.first else {
        fatalError("The registry is empty.")
    }

    let serviceNameColumn = column("Service Name", in: header)
    let portNumberColumn = column("Port Number", in: header)
    let transportColumn = column("Transport Protocol", in: header)
    let descriptionColumn = column("Description", in: header)
    let referenceColumn = column("Reference", in: header)
    let widestColumn = max(descriptionColumn, referenceColumn)

    var table: [ServicePort: Registration] = [:]
    var skippedPortNumbers: Set<String> = []
    var unlistedRFCs: Set<String> = []

    for row in rows.dropFirst() where row.count > widestColumn {
        let name = row[serviceNameColumn].trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else {
            continue
        }

        let references = standardsTrackOrBCPReferences(
            parseReferences(row[referenceColumn]).map(canonicalReference),
            statuses: rfcStatuses,
            unlistedRFCs: &unlistedRFCs
        )

        // The registry lists a handful of ports as an inclusive range rather than a single
        // number, and leaves the column empty for unassigned entries. Neither is emitted.
        let rawPort = row[portNumberColumn].trimmingCharacters(in: .whitespaces)
        guard let port = UInt16(rawPort) else {
            if !rawPort.isEmpty, !references.isEmpty {
                skippedPortNumbers.insert(rawPort)
            }
            continue
        }

        let servicePort = ServicePort(name: name, port: port)
        var registration = table[servicePort] ?? Registration()

        let transport = row[transportColumn].trimmingCharacters(in: .whitespaces)
        if !transport.isEmpty {
            registration.transports.insert(transport)
        }
        if registration.description.isEmpty {
            registration.description = singleLine(row[descriptionColumn])
        }
        registration.references.formUnion(references)

        table[servicePort] = registration
    }

    if !skippedPortNumbers.isEmpty {
        print(
            "Skipped port numbers backed by a Standards Track or BCP RFC: "
                + skippedPortNumbers.sorted().joined(separator: ", ")
        )
    }

    if !unlistedRFCs.isEmpty {
        print(
            "Skipped references to RFCs missing from the RFC index: "
                + unlistedRFCs.sorted().joined(separator: ", ")
        )
    }

    // A registration the registry does not back with a Standards Track or BCP RFC is dropped
    // entirely.
    let backed = table.filter { !$0.value.references.isEmpty }
    print("Dropped \(table.count - backed.count) registrations with no Standards Track or BCP RFC")

    return backed
}

struct Entry {
    let servicePort: ServicePort
    let identifier: String
    let registration: Registration
}

func entryCode(_ entry: Entry) -> String {
    let summary =
        "The IANA `\(entry.servicePort.name)` service port, \(entry.servicePort.port)."
    let comment = docComment([
        summary,
        entry.registration.description,
        transportsPhrase(entry.registration.transports),
        referencesPhrase(entry.registration.references),
    ])
    return comment
        + """
            @inlinable
            public static var \(entry.identifier): Self {
                Port(rawValue: \(entry.servicePort.port))
            }

        """
}

func emit(_ table: [ServicePort: Registration]) -> String {
    let header = """
        // This file is generated by the utils/IANAServicePortsGenerator.swift script.
        //
        // The source of truth is the IANA Service Name and Transport Protocol Port Number
        // Registry, whose management procedures are defined in IETF RFC 6335 (BCP 165).
        //
        // https://www.iana.org/assignments/service-names-port-numbers/service-names-port-numbers.xhtml
        // https://datatracker.ietf.org/doc/html/rfc6335
        //
        // Only registrations that the registry backs with a Standards Track or Best Current
        // Practice RFC are emitted, going by each RFC's current status in the RFC Editor's index.
        //
        // https://www.rfc-editor.org/rfc-index.xml
        // https://datatracker.ietf.org/doc/html/rfc2026

        extension Port {

        """

    var entries: [Entry] = []
    var skipped: [String] = []

    for (servicePort, registration) in table {
        // The IANA service name is used verbatim, wrapped in backticks when it is not a plain
        // Swift identifier. A name that shares its identifier with another name is a duplicate
        // declaration, which the compiler rejects when the generated file is next built.
        guard let identifier = identifier(servicePort.name) else {
            skipped.append(servicePort.name)
            continue
        }

        entries.append(
            Entry(
                servicePort: servicePort,
                identifier: identifier,
                registration: registration
            )
        )
    }

    // Ascending by port number, then by name so equal ports keep a stable, reproducible order.
    entries.sort {
        ($0.servicePort.port, $0.servicePort.name) < ($1.servicePort.port, $1.servicePort.name)
    }

    print("Emitted \(entries.count) static properties")
    if !skipped.isEmpty {
        print("Skipped \(skipped.count) names that cannot be spelled as a Swift identifier:")
        for name in skipped.sorted() {
            print("  - \(name.debugDescription)")
        }
    }

    return header + entries.map(entryCode).joined(separator: "\n") + "}\n"
}

func run() {
    let currentDirectory = FileManager.default.currentDirectoryPath
    guard currentDirectory.hasSuffix("swift-endpoint") else {
        fatalError(
            "This script must be run from the swift-endpoint root directory. "
                + "Current directory: \(currentDirectory)."
        )
    }

    print("Downloading \(registryURL) ...")
    let file = try! fetchWithRetries(url: URL(string: registryURL)!)
    print("Downloaded \(file.count) bytes")

    let text = String(decoding: file, as: UTF8.self)
    let rows = parseCSV(text)
    print("Parsed \(rows.count) rows")

    print("Downloading \(rfcIndexURL) ...")
    let rfcIndex = try! fetchWithRetries(url: URL(string: rfcIndexURL)!)
    print("Downloaded \(rfcIndex.count) bytes")

    let rfcStatuses = parseRFCIndex(rfcIndex)
    print("Parsed \(rfcStatuses.count) RFCs")

    let table = build(rows, rfcStatuses: rfcStatuses)
    print("Built \(table.count) registrations")

    let generated = emit(table)
    print("Generated \(generated.count(where: \.isNewline)) lines")

    if FileManager.default.fileExists(atPath: outputPath),
        try! String(contentsOfFile: outputPath, encoding: .utf8) == generated
    {
        print("Generated code matches current contents, no changes needed.")
    } else {
        print("Writing to \(outputPath) ...")
        try! generated.write(toFile: outputPath, atomically: true, encoding: .utf8)
    }

    print("Done!")
}

run()
