// swift-linter-tools-version: 0.1
// ===----------------------------------------------------------------------===//
//
// This source file is part of the swift-carrier-primitives open source project
//
// Copyright (c) 2026 Coen ten Thije Boonkkamp and the swift-carrier-primitives project authors
// Licensed under Apache License v2.0
//
// See LICENSE for license information
//
// ===----------------------------------------------------------------------===//

// Shape-γ unified consumer manifest. Replaces the prior nested-package
// Lint/{Package.swift, Sources/Lint/main.swift} pair with a single
// Lint.swift declaring both SwiftPM dependencies and rule activations.
//
// Canary for the unified-single-file pattern per
// swift-institute/Research/2026-05-12-swift-linter-unified-consumer-manifest.md.
//
// Also exercises the inline-custom-rule path: the rule below is defined
// at file scope (backtick natural-English form per the institute rule-
// naming convention) and activated alongside the primitives-tier bundle.
// Demonstrates that consumers can author domain-aware rules directly in
// `Lint.swift` without requiring a separate rule package — the
// swift-syntax dep is declared inline.

import Linter
import Linter_Primitives_Rules
import SwiftSyntax

extension Lint.Rule {
    static let `carrier import noted` = Lint.Rule(
        id: "carrier import noted",
        default: .warning,
        findings: { source, severity in
            var findings: [Diagnostic.Record] = []
            for statement in source.tree.statements {
                guard let importDecl = statement.item.as(ImportDeclSyntax.self) else { continue }
                let pathText = importDecl.path.trimmedDescription
                guard pathText.hasPrefix("Carrier") else { continue }
                let location = source.converter.location(
                    for: importDecl.positionAfterSkippingLeadingTrivia
                )
                findings.append(
                    Diagnostic.Record(
                        location: Source.Location(
                            fileID: source.file.fileID,
                            filePath: source.file.filePath,
                            line: location.line,
                            column: location.column
                        ),
                        severity: severity,
                        identifier: "carrier import noted",
                        message: "[carrier import noted] Inline custom rule fired on `import \(pathText)` — Shape γ canary demonstrating that consumers can author rules directly in Lint.swift."
                    )
                )
            }
            return findings
        }
    )
}

Lint.run(dependencies: [
    .package(
        path: "../swift-primitives-linter-rules",
        products: ["Linter Primitives Rules"]
    ),
    .package(
        url: "https://github.com/swiftlang/swift-syntax.git",
        "602.0.0"..<"603.0.0",
        products: ["SwiftSyntax"]
    ),
]) {
    Lint.Rule.Bundle.primitives
    Lint.Rule.Configuration.enable(.`carrier import noted`)
}
