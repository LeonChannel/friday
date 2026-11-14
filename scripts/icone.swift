// Resumo: Gera o ícone do app (todos os tamanhos do macOS) a partir da geometria do logo, a mesma que o app desenha.
// Tags: visual
//
// Uso: swiftc -parse-as-library -o build/icone scripts/icone.swift Packages/FridayKit/Sources/FridayFeatures/Design/FridayMarkShapes.swift && build/icone

import AppKit
import SwiftUI

private let lime = Color(red: 0xC8 / 255, green: 0xF1 / 255, blue: 0x69 / 255)
private let coral = Color(red: 0xFF / 255, green: 0x8A / 255, blue: 0x65 / 255)
private let tileTop = Color(red: 0x1C / 255, green: 0x1F / 255, blue: 0x23 / 255)
private let tileBottom = Color(red: 0x0E / 255, green: 0x0F / 255, blue: 0x11 / 255)

/// Ícone no grid do macOS: placa de 824 em 1024, cantos contínuos.
private struct AppIcon: View {
    var body: some View {
        let plate: CGFloat = 824
        ZStack {
            RoundedRectangle(cornerRadius: 185, style: .continuous)
                .fill(LinearGradient(colors: [tileTop, tileBottom], startPoint: .top, endPoint: .bottom))
                .overlay(RoundedRectangle(cornerRadius: 185, style: .continuous).strokeBorder(Color.white.opacity(0.07), lineWidth: 4))
                .frame(width: plate, height: plate)
                .shadow(color: .black.opacity(0.35), radius: 24, y: 12)
            let mark: CGFloat = plate * 0.78
            let width = mark * FridayMarkMetrics.strokeRatio
            ZStack {
                FridayYouStroke().stroke(lime, style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round))
                FridayClaudeStroke().stroke(coral, style: StrokeStyle(lineWidth: width, lineCap: .round))
            }
            .frame(width: mark, height: mark)
        }
        .frame(width: 1024, height: 1024)
    }
}

@main
struct IconMaker {
    @MainActor static func main() throws {
        let folder = URL(fileURLWithPath: "Friday/Assets.xcassets/AppIcon.appiconset", isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        var images: [[String: String]] = []
        for points in [16, 32, 128, 256, 512] {
            for scale in [1, 2] {
                let pixels = points * scale
                let renderer = ImageRenderer(content: AppIcon())
                renderer.scale = CGFloat(pixels) / 1024
                guard let tiff = renderer.nsImage?.tiffRepresentation, let rep = NSBitmapImageRep(data: tiff),
                      let png = rep.representation(using: .png, properties: [:]) else { throw CocoaError(.fileWriteUnknown) }
                let name = "icon_\(points)x\(points)\(scale == 2 ? "@2x" : "").png"
                try png.write(to: folder.appendingPathComponent(name))
                images.append(["idiom": "mac", "size": "\(points)x\(points)", "scale": "\(scale)x", "filename": name])
            }
        }
        let contents: [String: Any] = ["images": images, "info": ["author": "xcode", "version": 1]]
        try JSONSerialization.data(withJSONObject: contents, options: [.prettyPrinted, .sortedKeys]).write(to: folder.appendingPathComponent("Contents.json"))
        let catalog: [String: Any] = ["info": ["author": "xcode", "version": 1]]
        try JSONSerialization.data(withJSONObject: catalog, options: [.prettyPrinted]).write(to: folder.deletingLastPathComponent().appendingPathComponent("Contents.json"))
        print("ícone gerado em \(folder.path)")
    }
}
