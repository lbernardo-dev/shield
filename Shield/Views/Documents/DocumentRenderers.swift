import SwiftUI

// MARK: - DocumentView dispatcher

@ViewBuilder
func DocumentView(
    kind: DocumentKind,
    size: CGSize,
    fields: DocumentFields? = nil,
    redactions: [Redaction] = [],
    watermark: Watermark? = nil,
    showFieldOverlays: Bool = false,
    imageFileName: String? = nil,
    isVaulted: Bool = false
) -> some View {
    switch kind {
    case .photo:
        PhotoDocumentView(
            imageFileName: imageFileName,
            size: size,
            redactions: redactions,
            watermark: watermark,
            isVaulted: isVaulted
        )
    case .dniESP:
        DNISpainView(
            size: size,
            fields: fields,
            redactions: redactions,
            watermark: watermark,
            showFieldOverlays: showFieldOverlays
        )
    case .passportUSA:
        PassportUSAView(
            size: size,
            fields: fields,
            redactions: redactions,
            watermark: watermark,
            showFieldOverlays: showFieldOverlays
        )
    case .drivingUK:
        DrivingUKView(
            size: size,
            fields: fields,
            redactions: redactions,
            watermark: watermark,
            showFieldOverlays: showFieldOverlays
        )
    case .passportMEX:
        PassportMEXView(
            size: size,
            fields: fields,
            redactions: redactions,
            watermark: watermark
        )
    case .dniITA:
        DNIItalyView(
            size: size,
            fields: fields,
            redactions: redactions,
            watermark: watermark
        )
    case .genericID:
        GenericIDView(
            size: size,
            fields: fields,
            redactions: redactions,
            watermark: watermark
        )
    }
}

// MARK: - Blur redaction overlay (real UIKit blur per-rect)

struct BlurRedactionOverlay: View {
    let redactions: [Redaction]
    let size: CGSize

    var body: some View {
        ZStack {
            ForEach(redactions.filter { $0.style == .blurStrong || $0.style == .blurSoft }) { r in
                let radius: CGFloat = r.style == .blurStrong ? 18 : 8
                let scaledRect = CGRect(
                    x: r.rect.origin.x * size.width,
                    y: r.rect.origin.y * size.height,
                    width: r.rect.width * size.width,
                    height: r.rect.height * size.height
                )
                BlurRectView(radius: radius)
                    .frame(width: scaledRect.width, height: scaledRect.height)
                    .position(x: scaledRect.midX, y: scaledRect.midY)
            }
        }
        .frame(width: size.width, height: size.height)
        .allowsHitTesting(false)
    }
}

struct BlurRectView: UIViewRepresentable {
    let radius: CGFloat

    func makeUIView(context: Context) -> UIVisualEffectView {
        let effect = UIBlurEffect(style: .systemUltraThinMaterial)
        let view = UIVisualEffectView(effect: effect)
        view.clipsToBounds = true
        return view
    }

    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        let intensity: CGFloat = radius >= 16 ? 1.0 : 0.5
        uiView.alpha = intensity
    }
}

// MARK: - PhotoDocumentView

struct PhotoDocumentView: View {
    let imageFileName: String?
    let size: CGSize
    var redactions: [Redaction] = []
    var watermark: Watermark? = nil
    var isVaulted: Bool = false

    var body: some View {
        ZStack {
            if let fileName = imageFileName,
               let uiImage = AppState.loadImage(fileName: fileName, isVaulted: isVaulted) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size.width, height: size.height)
                    .clipped()
            } else {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(hex: "2a2a2a"))
                    .overlay(
                        Image(systemName: "doc.on.doc.fill")
                            .font(.system(size: size.height * 0.25))
                            .foregroundColor(Color(hex: "555555"))
                    )
                    .frame(width: size.width, height: size.height)
            }

            // Non-blur redactions + watermark via Canvas
            Canvas { context, sz in
                for r in redactions where r.style != .blurStrong && r.style != .blurSoft {
                    let rect = CGRect(
                        x: r.rect.origin.x * sz.width,
                        y: r.rect.origin.y * sz.height,
                        width: r.rect.width * sz.width,
                        height: r.rect.height * sz.height
                    )
                    drawMask(context: &context, rect: rect, style: r.style)
                }
                if let wm = watermark {
                    drawWatermark(context: &context, size: sz, watermark: wm)
                }
            }
            .frame(width: size.width, height: size.height)

            // Real blur via UIVisualEffectView
            BlurRedactionOverlay(redactions: redactions, size: size)
        }
        .frame(width: size.width, height: size.height)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Helpers

func scaled(_ v: CGFloat, _ base: CGFloat) -> CGFloat { v * base }

// MARK: - Vector doc wrapper (adds real blur layer on top of Canvas)

struct VectorDocBlurWrapper<Content: View>: View {
    let redactions: [Redaction]
    let size: CGSize
    @ViewBuilder let content: () -> Content

    var body: some View {
        ZStack {
            content()
            BlurRedactionOverlay(redactions: redactions, size: size)
        }
        .frame(width: size.width, height: size.height)
    }
}

// MARK: - MaskOverlay (Canvas draw func)

func drawMask(
    context: inout GraphicsContext,
    rect: CGRect,
    style: MaskStyle,
    id: String = ""
) {
    switch style {
    case .block:
        context.fill(Path(rect), with: .color(.black))

    case .blockWhite:
        context.fill(Path(rect), with: .color(.white))

    case .pixelate:
        let cols = max(3, Int(rect.width / 6))
        let rows = max(2, Int(rect.height / 6))
        let cw = rect.width / CGFloat(cols)
        let ch = rect.height / CGFloat(rows)
        for i in 0..<cols {
            for j in 0..<rows {
                let v = CGFloat(40 + (i * 37 + j * 53) % 200) / 255
                let cellRect = CGRect(
                    x: rect.minX + CGFloat(i) * cw,
                    y: rect.minY + CGFloat(j) * ch,
                    width: cw + 0.5,
                    height: ch + 0.5
                )
                context.fill(Path(cellRect), with: .color(Color(white: v)))
            }
        }

    case .blurStrong:
        // Heavy frosted glass: dense white layers simulate strong blur
        context.fill(Path(rect), with: .color(Color.white.opacity(0.80)))
        context.fill(Path(rect), with: .color(Color.gray.opacity(0.30)))

    case .blurSoft:
        // Light frosted glass: subtle white veil
        context.fill(Path(rect), with: .color(Color.white.opacity(0.55)))
        context.fill(Path(rect), with: .color(Color.white.opacity(0.15)))

    case .diagonal:
        // Black + yellow stripes
        context.fill(Path(rect), with: .color(.black))
        context.drawLayer { ctx in
            ctx.clip(to: Path(rect))
            var stripeX = rect.minX
            while stripeX < rect.maxX + rect.height {
                let stripePath = Path { p in
                    p.move(to: CGPoint(x: stripeX, y: rect.minY))
                    p.addLine(to: CGPoint(x: stripeX + 3, y: rect.minY))
                    p.addLine(to: CGPoint(x: stripeX + 3 - rect.height, y: rect.maxY))
                    p.addLine(to: CGPoint(x: stripeX - rect.height, y: rect.maxY))
                    p.closeSubpath()
                }
                ctx.fill(stripePath, with: .color(Color(hex: "FFD60A")))
                stripeX += 6
            }
        }

    case .secure:
        context.fill(Path(rect), with: .color(.black))
        let dotSize: CGFloat = 1.6
        let spacing: CGFloat = 8
        var dotX = rect.minX + 2
        while dotX < rect.maxX {
            var dotY = rect.minY + 2
            while dotY < rect.maxY {
                let dotRect = CGRect(x: dotX - dotSize/2, y: dotY - dotSize/2, width: dotSize, height: dotSize)
                context.fill(Path(ellipseIn: dotRect), with: .color(Color(hex: "FFD60A")))
                dotY += spacing
            }
            dotX += spacing
        }

    case .redactedTag:
        context.fill(Path(rect), with: .color(.black))
        let text = Text(LanguageManager.shared.model("model_mask_redacted_label"))
            .font(.system(size: min(rect.height * 0.5, 12), weight: .bold, design: .monospaced))
            .foregroundColor(Color(hex: "FFD60A"))
        context.draw(text, at: CGPoint(x: rect.midX, y: rect.midY))

    case .semi:
        context.fill(Path(rect), with: .color(Color.black.opacity(0.55)))
    }
}

// MARK: - Watermark draw func

func drawWatermark(context: inout GraphicsContext, size: CGSize, watermark: Watermark) {
    let text = Text(watermark.text)
        .font(.system(size: size.width * 0.05, weight: .heavy))
        .foregroundColor(watermark.color.opacity(watermark.opacity))

    if watermark.isRepeating {
        let stepX = size.width / 3
        let stepY = size.height / 4
        for i in -2..<6 {
            for j in -2..<8 {
                let cx = CGFloat(i) * stepX + size.width / 6
                let cy = CGFloat(j) * stepY + size.height / 8
                var ctx2 = context
                ctx2.translateBy(x: cx, y: cy)
                ctx2.rotate(by: .degrees(-22))
                ctx2.draw(text, at: .zero)
            }
        }
    } else {
        var ctx2 = context
        ctx2.translateBy(x: size.width / 2, y: size.height / 2)
        ctx2.rotate(by: .degrees(-22))
        ctx2.draw(text, at: .zero)
    }
}

// MARK: - DNI Spain

struct DNISpainView: View {
    let size: CGSize
    var fields: DocumentFields? = nil
    var redactions: [Redaction] = []
    var watermark: Watermark? = nil
    var showFieldOverlays: Bool = false

    var body: some View {
        VectorDocBlurWrapper(redactions: redactions, size: size) {
            Canvas { context, sz in
                drawDNI(context: &context, size: sz)
                if let wm = watermark { drawWatermark(context: &context, size: sz, watermark: wm) }
                for r in redactions where !r.style.isBlur {
                    let rect = CGRect(
                        x: r.rect.origin.x * sz.width,
                        y: r.rect.origin.y * sz.height,
                        width: r.rect.width * sz.width,
                        height: r.rect.height * sz.height
                    )
                    drawMask(context: &context, rect: rect, style: r.style)
                }
                if showFieldOverlays {
                    for box in DocumentFieldBoxes.dniESP {
                        let rect = CGRect(
                            x: box.rect.origin.x * sz.width,
                            y: box.rect.origin.y * sz.height,
                            width: box.rect.width * sz.width,
                            height: box.rect.height * sz.height
                        )
                        context.fill(Path(rect), with: .color(Color(hex: "FFD60A").opacity(0.12)))
                        context.stroke(Path(rect), with: .color(Color(hex: "FFD60A")), lineWidth: 1)
                    }
                }
            }
            .frame(width: size.width, height: size.height)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    private func drawDNI(context: inout GraphicsContext, size sz: CGSize) {
        let w = sz.width, h = sz.height

        // Background gradient
        context.fill(Path(CGRect(x: 0, y: 0, width: w, height: h)),
                     with: .linearGradient(
                        Gradient(colors: [Color(hex: "E8E4D8"), Color(hex: "C8C2B0")]),
                        startPoint: .zero, endPoint: CGPoint(x: w, y: h)
                     ))

        // Guilloche dots
        for ix in stride(from: 0, to: w, by: 3) {
            for iy in stride(from: 0, to: h, by: 3) {
                let dot = CGRect(x: ix + 0.8, y: iy + 0.8, width: 0.8, height: 0.8)
                context.fill(Path(ellipseIn: dot), with: .color(Color(hex: "9a9080").opacity(0.4)))
            }
        }

        // Header band
        let headerH = h * 0.13
        context.fill(Path(CGRect(x: 0, y: 0, width: w, height: headerH)),
                     with: .color(Color(hex: "1B3A6B")))

        // Header text
        let headerText1 = Text(LanguageManager.shared.model("model_doc_spain_title"))
            .font(.system(size: h * 0.065, weight: .black))
            .foregroundColor(Color(hex: "FFD24A"))
        context.draw(headerText1, at: CGPoint(x: w * 0.05, y: headerH * 0.6), anchor: .leading)

        let headerText2 = Text(LanguageManager.shared.model("model_doc_spain_dni"))
            .font(.system(size: h * 0.045, weight: .bold))
            .foregroundColor(.white)
        context.draw(headerText2, at: CGPoint(x: w * 0.97, y: headerH * 0.6), anchor: .trailing)

        // Photo area
        let photoRect = CGRect(x: w * 0.04, y: h * 0.18, width: w * 0.22, height: h * 0.55)
        context.fill(Path(photoRect), with: .color(Color(hex: "5a4a3c")))
        // Face
        let headRect = CGRect(x: w * 0.15 - h * 0.09, y: h * 0.27, width: h * 0.18, height: h * 0.18)
        context.fill(Path(ellipseIn: headRect), with: .color(Color(hex: "c8a888")))
        let bodyRect = CGRect(x: w * 0.15 - h * 0.16, y: h * 0.50, width: h * 0.32, height: h * 0.28)
        context.fill(Path(ellipseIn: bodyRect), with: .color(Color(hex: "3a2a1c")))

        // Fields
        let f = fields
        let dniFullName = f?.fullName ?? "GARCÍA LÓPEZ, MARÍA"
        let dniParts = dniFullName.components(separatedBy: ", ")
        let dniSurnames = dniParts.count > 0 ? dniParts[0] : ""
        let dniGiven = dniParts.count > 1 ? dniParts[1] : ""
        let dniSurnameWords = dniSurnames.components(separatedBy: " ")
        let dniSurname1 = dniSurnameWords.count > 0 && !dniSurnameWords[0].isEmpty ? dniSurnameWords[0] : "—"
        let dniSurname2 = dniSurnameWords.count > 1 ? dniSurnameWords.dropFirst().joined(separator: " ") : "—"

        let fieldData: [(String, String, CGFloat, CGFloat)] = [
            (LanguageManager.shared.model("model_label_surname1"), dniSurname1, 0.30, 0.22),
            (LanguageManager.shared.model("model_label_surname2"), dniSurname2, 0.30, 0.36),
            (LanguageManager.shared.model("model_label_given_name"), dniGiven.isEmpty ? "—" : dniGiven, 0.30, 0.50),
            (LanguageManager.shared.model("model_label_sex"), f?.sex ?? "F", 0.30, 0.64),
            (LanguageManager.shared.model("model_label_nationality"), f?.nationality ?? "ESP", 0.40, 0.64),
            (LanguageManager.shared.model("model_label_dob"), f?.dateOfBirth ?? "14 03 1990", 0.62, 0.64),
            (LanguageManager.shared.model("model_label_doc_number"), f?.documentNumber ?? "12345678Z", 0.30, 0.78),
            (LanguageManager.shared.model("model_label_expires"), f?.expires ?? "12 11 2031", 0.62, 0.78),
        ]
        for (label, value, fx, fy) in fieldData {
            let labelT = Text(label)
                .font(.system(size: h * 0.03, weight: .semibold))
                .foregroundColor(Color(hex: "5a5040"))
            context.draw(labelT, at: CGPoint(x: w * fx, y: h * fy), anchor: .topLeading)

            let valueT = Text(value)
                .font(.system(size: h * 0.052, weight: .bold, design: .monospaced))
                .foregroundColor(Color(hex: "0a0a0a"))
            context.draw(valueT, at: CGPoint(x: w * fx, y: h * fy + h * 0.04), anchor: .topLeading)
        }

        // MRZ band
        context.fill(Path(CGRect(x: 0, y: h * 0.86, width: w, height: h * 0.14)),
                     with: .color(Color(hex: "f0ebde")))
        let mrzRaw = f?.mrz ?? "IDESP12345678Z<<<<<<<<<<<<<<\n9003147F3111122ESP<<<<<<<<<<<8"
        let mrzLines = mrzRaw.components(separatedBy: "\n")
        let mrz1 = Text(mrzLines.count > 0 ? mrzLines[0] : "")
            .font(.system(size: h * 0.038, weight: .bold, design: .monospaced))
            .foregroundColor(Color(hex: "0a0a0a"))
        context.draw(mrz1, at: CGPoint(x: w * 0.04, y: h * 0.875), anchor: .topLeading)
        let mrz2 = Text(mrzLines.count > 1 ? mrzLines[1] : "")
            .font(.system(size: h * 0.038, weight: .bold, design: .monospaced))
            .foregroundColor(Color(hex: "0a0a0a"))
        context.draw(mrz2, at: CGPoint(x: w * 0.04, y: h * 0.92), anchor: .topLeading)
    }
}

// MARK: - Passport USA

struct PassportUSAView: View {
    let size: CGSize
    var fields: DocumentFields? = nil
    var redactions: [Redaction] = []
    var watermark: Watermark? = nil
    var showFieldOverlays: Bool = false

    var body: some View {
        VectorDocBlurWrapper(redactions: redactions, size: size) {
            Canvas { context, sz in
                drawPassport(context: &context, size: sz)
                if let wm = watermark { drawWatermark(context: &context, size: sz, watermark: wm) }
                for r in redactions where !r.style.isBlur {
                    let rect = CGRect(
                        x: r.rect.origin.x * sz.width,
                        y: r.rect.origin.y * sz.height,
                        width: r.rect.width * sz.width,
                        height: r.rect.height * sz.height
                    )
                    drawMask(context: &context, rect: rect, style: r.style)
                }
                if showFieldOverlays {
                    for box in DocumentFieldBoxes.passportUSA {
                        let rect = CGRect(
                            x: box.rect.origin.x * sz.width,
                            y: box.rect.origin.y * sz.height,
                            width: box.rect.width * sz.width,
                            height: box.rect.height * sz.height
                        )
                        context.fill(Path(rect), with: .color(Color(hex: "FFD60A").opacity(0.12)))
                        context.stroke(Path(rect), with: .color(Color(hex: "FFD60A")), lineWidth: 1)
                    }
                }
            }
            .frame(width: size.width, height: size.height)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    private func drawPassport(context: inout GraphicsContext, size sz: CGSize) {
        let w = sz.width, h = sz.height

        context.fill(Path(CGRect(x: 0, y: 0, width: w, height: h)),
                     with: .linearGradient(
                        Gradient(colors: [Color(hex: "F5F0DC"), Color(hex: "E5DCB8")]),
                        startPoint: .zero, endPoint: CGPoint(x: 0, y: h)
                     ))

        // Dot pattern
        for ix in stride(from: 0, to: w, by: 4) {
            for iy in stride(from: 0, to: h, by: 4) {
                let dot = CGRect(x: ix + 1.4, y: iy + 1.4, width: 1.2, height: 1.2)
                context.fill(Path(ellipseIn: dot), with: .color(Color(hex: "b8a878").opacity(0.35)))
            }
        }

        // Title
        let title = Text(LanguageManager.shared.model("model_doc_passport_title"))
            .font(.system(size: h * 0.045, weight: .bold))
            .foregroundColor(Color(hex: "3a2a1c"))
        context.draw(title, at: CGPoint(x: w * 0.04, y: h * 0.06), anchor: .topLeading)

        let country = Text(LanguageManager.shared.model("model_doc_usa_title"))
            .font(.system(size: h * 0.036, weight: .semibold))
            .foregroundColor(Color(hex: "3a2a1c"))
        context.draw(country, at: CGPoint(x: w * 0.04, y: h * 0.13), anchor: .topLeading)

        // Photo
        let photoRect = CGRect(x: w * 0.04, y: h * 0.20, width: w * 0.20, height: h * 0.55)
        context.fill(Path(photoRect), with: .color(Color(hex: "3a2a1c")))
        let headRect = CGRect(x: w * 0.14 - h * 0.085, y: h * 0.28, width: h * 0.17, height: h * 0.17)
        context.fill(Path(ellipseIn: headRect), with: .color(Color(hex: "d4b896")))
        let bodyRect = CGRect(x: w * 0.14 - h * 0.14, y: h * 0.50, width: h * 0.28, height: h * 0.26)
        context.fill(Path(ellipseIn: bodyRect), with: .color(Color(hex: "1a1a2a")))

        // Fields
        let fp = fields
        let ppFullName = fp?.fullName ?? "MILLER, JAMES R."
        let ppParts = ppFullName.components(separatedBy: ", ")
        let ppSurname = ppParts.count > 0 ? ppParts[0] : "—"
        let ppGiven = ppParts.count > 1 ? ppParts[1] : "—"

        let fieldData: [(String, String, CGFloat, CGFloat)] = [
            (LanguageManager.shared.model("model_label_type"), "P", 0.28, 0.22),
            (LanguageManager.shared.model("model_label_code"), fp?.nationality ?? "USA", 0.42, 0.22),
            (LanguageManager.shared.model("model_label_passport_no"), fp?.documentNumber ?? "518749632", 0.62, 0.22),
            (LanguageManager.shared.model("model_label_surname_nom"), ppSurname, 0.28, 0.36),
            (LanguageManager.shared.model("model_label_given_names"), ppGiven, 0.28, 0.50),
            (LanguageManager.shared.model("model_label_nationality"), fp?.nationality ?? "USA", 0.28, 0.62),
            (LanguageManager.shared.model("model_label_dob"), fp?.dateOfBirth ?? "21 JUL 1985", 0.28, 0.74),
            (LanguageManager.shared.model("model_label_sex"), fp?.sex ?? "M", 0.55, 0.74),
            (LanguageManager.shared.model("model_label_expires"), fp?.expires ?? "03 MAR 2032", 0.70, 0.74),
        ]
        for (label, value, fx, fy) in fieldData {
            let labelT = Text(label)
                .font(.system(size: h * 0.026, weight: .semibold))
                .foregroundColor(Color(hex: "6a5030"))
            context.draw(labelT, at: CGPoint(x: w * fx, y: h * fy), anchor: .topLeading)
            let valueT = Text(value)
                .font(.system(size: h * 0.042, weight: .bold, design: .monospaced))
                .foregroundColor(Color(hex: "1a1a1a"))
            context.draw(valueT, at: CGPoint(x: w * fx, y: h * fy + h * 0.036), anchor: .topLeading)
        }

        // MRZ
        context.fill(Path(CGRect(x: 0, y: h * 0.85, width: w, height: h * 0.15)),
                     with: .color(Color(hex: "f0e8c8")))
        let ppMrzRaw = fp?.mrz ?? "P<USAMILLER<<JAMES<R<<<<<<<<<<<<<<<<<<<<<<<<\n5187496325USA8507218M3203034<<<<<<<<<<<<<<00"
        let ppMrzLines = ppMrzRaw.components(separatedBy: "\n")
        let mrz1 = Text(ppMrzLines.count > 0 ? ppMrzLines[0] : "")
            .font(.system(size: h * 0.034, weight: .bold, design: .monospaced))
            .foregroundColor(Color(hex: "1a1a1a"))
        context.draw(mrz1, at: CGPoint(x: w * 0.04, y: h * 0.86), anchor: .topLeading)
        let mrz2 = Text(ppMrzLines.count > 1 ? ppMrzLines[1] : "")
            .font(.system(size: h * 0.034, weight: .bold, design: .monospaced))
            .foregroundColor(Color(hex: "1a1a1a"))
        context.draw(mrz2, at: CGPoint(x: w * 0.04, y: h * 0.91), anchor: .topLeading)
    }
}

// MARK: - Driving Licence UK

struct DrivingUKView: View {
    let size: CGSize
    var fields: DocumentFields? = nil
    var redactions: [Redaction] = []
    var watermark: Watermark? = nil
    var showFieldOverlays: Bool = false

    var body: some View {
        VectorDocBlurWrapper(redactions: redactions, size: size) {
            Canvas { context, sz in
                drawLicence(context: &context, size: sz)
                if let wm = watermark { drawWatermark(context: &context, size: sz, watermark: wm) }
                for r in redactions where !r.style.isBlur {
                    let rect = CGRect(
                        x: r.rect.origin.x * sz.width,
                        y: r.rect.origin.y * sz.height,
                        width: r.rect.width * sz.width,
                        height: r.rect.height * sz.height
                    )
                    drawMask(context: &context, rect: rect, style: r.style)
                }
                if showFieldOverlays {
                    for box in DocumentFieldBoxes.drivingUK {
                        let rect = CGRect(
                            x: box.rect.origin.x * sz.width,
                            y: box.rect.origin.y * sz.height,
                            width: box.rect.width * sz.width,
                            height: box.rect.height * sz.height
                        )
                        context.fill(Path(rect), with: .color(Color(hex: "FFD60A").opacity(0.12)))
                        context.stroke(Path(rect), with: .color(Color(hex: "FFD60A")), lineWidth: 1)
                    }
                }
            }
            .frame(width: size.width, height: size.height)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    private func drawLicence(context: inout GraphicsContext, size sz: CGSize) {
        let w = sz.width, h = sz.height

        context.fill(Path(CGRect(x: 0, y: 0, width: w, height: h)),
                     with: .linearGradient(
                        Gradient(colors: [Color(hex: "FFE9B8"), Color(hex: "F5C77C")]),
                        startPoint: .zero, endPoint: CGPoint(x: w, y: h)
                     ))

        // Blue side band
        context.fill(Path(CGRect(x: 0, y: 0, width: w * 0.10, height: h)),
                     with: .color(Color(hex: "1B3A6B")))

        let ukText = Text(LanguageManager.shared.model("model_doc_uk_short"))
            .font(.system(size: h * 0.09, weight: .black))
            .foregroundColor(Color(hex: "FFD24A"))
        context.draw(ukText, at: CGPoint(x: w * 0.05, y: h * 0.20), anchor: .top)

        // Title
        let title = Text(LanguageManager.shared.model("model_doc_uk_dl_title"))
            .font(.system(size: h * 0.048, weight: .heavy))
            .foregroundColor(Color(hex: "1B3A6B"))
        context.draw(title, at: CGPoint(x: w * 0.13, y: h * 0.06), anchor: .topLeading)
        let subtitle = Text(LanguageManager.shared.model("model_doc_uk_title"))
            .font(.system(size: h * 0.032, weight: .semibold))
            .foregroundColor(Color(hex: "1B3A6B"))
        context.draw(subtitle, at: CGPoint(x: w * 0.13, y: h * 0.13), anchor: .topLeading)

        // Photo
        let photoRect = CGRect(x: w * 0.13, y: h * 0.22, width: w * 0.20, height: h * 0.55)
        context.fill(Path(photoRect), with: .color(Color(hex: "3a2a1c")))
        let headRect = CGRect(x: w * 0.23 - h * 0.085, y: h * 0.30, width: h * 0.17, height: h * 0.17)
        context.fill(Path(ellipseIn: headRect), with: .color(Color(hex: "a8784a")))
        let bodyRect = CGRect(x: w * 0.23 - h * 0.14, y: h * 0.50, width: h * 0.28, height: h * 0.26)
        context.fill(Path(ellipseIn: bodyRect), with: .color(Color(hex: "1a1a1a")))

        // Fields
        let fd = fields
        let dlFullName = fd?.fullName ?? "PATEL, AISHA"
        let dlParts = dlFullName.components(separatedBy: ", ")
        let dlSurname = dlParts.count > 0 ? dlParts[0] : "—"
        let dlGiven = dlParts.count > 1 ? dlParts[1] : "—"

        let fieldData: [(String, String, CGFloat, CGFloat)] = [
            (LanguageManager.shared.model("model_label_uk_surname"), dlSurname, 0.36, 0.24),
            (LanguageManager.shared.model("model_label_uk_given_names"), dlGiven, 0.36, 0.36),
            (LanguageManager.shared.model("model_label_uk_dob"), fd?.dateOfBirth ?? "02-09-1992", 0.36, 0.48),
            (LanguageManager.shared.model("model_label_uk_issued"), fd?.issued ?? "02-09-2022", 0.36, 0.60),
            (LanguageManager.shared.model("model_label_uk_expires"), fd?.expires ?? "02-09-2032", 0.62, 0.60),
            (LanguageManager.shared.model("model_label_uk_driver_no"), fd?.documentNumber ?? "PATEL902145JZ9MN", 0.36, 0.72),
            (LanguageManager.shared.model("model_label_uk_address"), fd?.address ?? "14 KINGS RD, LONDON SW3 5UL", 0.36, 0.84),
        ]
        for (label, value, fx, fy) in fieldData {
            let labelT = Text(label)
                .font(.system(size: h * 0.026, weight: .semibold))
                .foregroundColor(Color(hex: "5a4020"))
            context.draw(labelT, at: CGPoint(x: w * fx, y: h * fy), anchor: .topLeading)
            let valueT = Text(value)
                .font(.system(size: h * 0.036, weight: .bold, design: .monospaced))
                .foregroundColor(Color(hex: "1a1a1a"))
            context.draw(valueT, at: CGPoint(x: w * fx, y: h * fy + h * 0.038), anchor: .topLeading)
        }
    }
}

// MARK: - Passport Mexico

struct PassportMEXView: View {
    let size: CGSize
    var fields: DocumentFields? = nil
    var redactions: [Redaction] = []
    var watermark: Watermark? = nil

    var body: some View {
        VectorDocBlurWrapper(redactions: redactions, size: size) {
            Canvas { context, sz in
                draw(context: &context, size: sz)
                if let wm = watermark { drawWatermark(context: &context, size: sz, watermark: wm) }
                for r in redactions where !r.style.isBlur {
                    let rect = CGRect(
                        x: r.rect.origin.x * sz.width, y: r.rect.origin.y * sz.height,
                        width: r.rect.width * sz.width, height: r.rect.height * sz.height
                    )
                    drawMask(context: &context, rect: rect, style: r.style)
                }
            }
            .frame(width: size.width, height: size.height)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    private func draw(context: inout GraphicsContext, size sz: CGSize) {
        let w = sz.width, h = sz.height

        // Background — off-white
        context.fill(Path(CGRect(x: 0, y: 0, width: w, height: h)),
                     with: .linearGradient(
                        Gradient(colors: [Color(hex: "F2F0E8"), Color(hex: "DCD9CC")]),
                        startPoint: .zero, endPoint: CGPoint(x: w, y: h)
                     ))

        // Green header band
        let headerH = h * 0.14
        context.fill(Path(CGRect(x: 0, y: 0, width: w, height: headerH)),
                     with: .color(Color(hex: "006847")))

        let title1 = Text(LanguageManager.shared.model("model_doc_mexico_title"))
            .font(.system(size: h * 0.046, weight: .black))
            .foregroundColor(.white)
        context.draw(title1, at: CGPoint(x: w * 0.50, y: headerH * 0.30), anchor: .top)

        let title2 = Text(LanguageManager.shared.model("model_doc_mexico_passport"))
            .font(.system(size: h * 0.034, weight: .semibold))
            .foregroundColor(Color(hex: "CE1126"))
        context.draw(title2, at: CGPoint(x: w * 0.50, y: headerH * 0.62), anchor: .top)

        // Photo
        let photoRect = CGRect(x: w * 0.04, y: h * 0.20, width: w * 0.20, height: h * 0.52)
        context.fill(Path(photoRect), with: .color(Color(hex: "3a2a1c")))
        let headRect = CGRect(x: w * 0.14 - h * 0.080, y: h * 0.28, width: h * 0.16, height: h * 0.16)
        context.fill(Path(ellipseIn: headRect), with: .color(Color(hex: "c8a070")))
        let bodyRect = CGRect(x: w * 0.14 - h * 0.13, y: h * 0.48, width: h * 0.26, height: h * 0.24)
        context.fill(Path(ellipseIn: bodyRect), with: .color(Color(hex: "1a1a2a")))

        // Fields
        let f = fields
        let name = f?.fullName ?? "HERNÁNDEZ, CARLOS A."
        let parts = name.components(separatedBy: ", ")
        let surname = parts.count > 0 ? parts[0] : "—"
        let given = parts.count > 1 ? parts[1] : "—"

        let fieldData: [(String, String, CGFloat, CGFloat)] = [
            (LanguageManager.shared.model("model_label_mex_surname"), surname, 0.28, 0.23),
            (LanguageManager.shared.model("model_label_mex_given"), given, 0.28, 0.36),
            (LanguageManager.shared.model("model_label_nationality"), f?.nationality ?? "MEXICANA", 0.28, 0.49),
            (LanguageManager.shared.model("model_label_dob"), f?.dateOfBirth ?? "15 05 1988", 0.28, 0.60),
            (LanguageManager.shared.model("model_label_passport_no"), f?.documentNumber ?? "G12345678", 0.28, 0.72),
            (LanguageManager.shared.model("model_label_expires"), f?.expires ?? "10 08 2033", 0.62, 0.72),
        ]
        for (label, value, fx, fy) in fieldData {
            let labelT = Text(label)
                .font(.system(size: h * 0.026, weight: .semibold))
                .foregroundColor(Color(hex: "006847"))
            context.draw(labelT, at: CGPoint(x: w * fx, y: h * fy), anchor: .topLeading)
            let valueT = Text(value)
                .font(.system(size: h * 0.040, weight: .bold, design: .monospaced))
                .foregroundColor(Color(hex: "1a1a1a"))
            context.draw(valueT, at: CGPoint(x: w * fx, y: h * fy + h * 0.036), anchor: .topLeading)
        }

        // MRZ
        context.fill(Path(CGRect(x: 0, y: h * 0.86, width: w, height: h * 0.14)),
                     with: .color(Color(hex: "e8e4d4")))
        let mrzRaw = f?.mrz ?? "P<MEXHERNANDEZ<<CARLOS<A<<<<<<<<<<<<<<<<<<<<<\nG123456788MEX8805158M3308107<<<<<<<<<<<<<<02"
        let mrzLines = mrzRaw.components(separatedBy: "\n")
        let mrz1 = Text(mrzLines.count > 0 ? mrzLines[0] : "")
            .font(.system(size: h * 0.032, weight: .bold, design: .monospaced))
            .foregroundColor(Color(hex: "1a1a1a"))
        context.draw(mrz1, at: CGPoint(x: w * 0.04, y: h * 0.872), anchor: .topLeading)
        let mrz2 = Text(mrzLines.count > 1 ? mrzLines[1] : "")
            .font(.system(size: h * 0.032, weight: .bold, design: .monospaced))
            .foregroundColor(Color(hex: "1a1a1a"))
        context.draw(mrz2, at: CGPoint(x: w * 0.04, y: h * 0.920), anchor: .topLeading)
    }
}

// MARK: - DNI Italy

struct DNIItalyView: View {
    let size: CGSize
    var fields: DocumentFields? = nil
    var redactions: [Redaction] = []
    var watermark: Watermark? = nil

    var body: some View {
        VectorDocBlurWrapper(redactions: redactions, size: size) {
            Canvas { context, sz in
                draw(context: &context, size: sz)
                if let wm = watermark { drawWatermark(context: &context, size: sz, watermark: wm) }
                for r in redactions where !r.style.isBlur {
                    let rect = CGRect(
                        x: r.rect.origin.x * sz.width, y: r.rect.origin.y * sz.height,
                        width: r.rect.width * sz.width, height: r.rect.height * sz.height
                    )
                    drawMask(context: &context, rect: rect, style: r.style)
                }
            }
            .frame(width: size.width, height: size.height)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    private func draw(context: inout GraphicsContext, size sz: CGSize) {
        let w = sz.width, h = sz.height

        // Background — light grey/blue
        context.fill(Path(CGRect(x: 0, y: 0, width: w, height: h)),
                     with: .linearGradient(
                        Gradient(colors: [Color(hex: "EAF0F8"), Color(hex: "D0DCF0")]),
                        startPoint: .zero, endPoint: CGPoint(x: w, y: h)
                     ))

        // Subtle grid pattern
        for ix in stride(from: 0, to: w, by: 6) {
            for iy in stride(from: 0, to: h, by: 6) {
                let dot = CGRect(x: ix + 2, y: iy + 2, width: 0.7, height: 0.7)
                context.fill(Path(ellipseIn: dot), with: .color(Color(hex: "7090c0").opacity(0.25)))
            }
        }

        // Italian flag stripe left
        let stripeW = w * 0.04
        context.fill(Path(CGRect(x: 0, y: 0, width: stripeW, height: h)), with: .color(Color(hex: "009246")))
        context.fill(Path(CGRect(x: stripeW, y: 0, width: stripeW, height: h)), with: .color(.white))
        context.fill(Path(CGRect(x: stripeW * 2, y: 0, width: stripeW, height: h)), with: .color(Color(hex: "CE2B37")))

        // Header
        let headerH = h * 0.14
        context.fill(Path(CGRect(x: stripeW * 3, y: 0, width: w - stripeW * 3, height: headerH)),
                     with: .color(Color(hex: "003D8F")))
        let title = Text(LanguageManager.shared.model("model_doc_italy_title"))
            .font(.system(size: h * 0.040, weight: .bold))
            .foregroundColor(.white)
        context.draw(title, at: CGPoint(x: stripeW * 3 + 6, y: headerH * 0.28), anchor: .topLeading)

        // Photo
        let photoRect = CGRect(x: w * 0.14, y: h * 0.20, width: w * 0.20, height: h * 0.52)
        context.fill(Path(photoRect), with: .color(Color(hex: "4a3828")))
        let headRect = CGRect(x: w * 0.24 - h * 0.080, y: h * 0.28, width: h * 0.16, height: h * 0.16)
        context.fill(Path(ellipseIn: headRect), with: .color(Color(hex: "d4a878")))
        let bodyRect = CGRect(x: w * 0.24 - h * 0.13, y: h * 0.48, width: h * 0.26, height: h * 0.24)
        context.fill(Path(ellipseIn: bodyRect), with: .color(Color(hex: "1a1a2a")))

        // Fields
        let f = fields
        let name = f?.fullName ?? "FERRARI, MARCO"
        let parts = name.components(separatedBy: ", ")
        let surname = parts.count > 0 ? parts[0] : "—"
        let given = parts.count > 1 ? parts[1] : "—"

        let fieldData: [(String, String, CGFloat, CGFloat)] = [
            (LanguageManager.shared.model("model_label_ita_surname"), surname, 0.38, 0.22),
            (LanguageManager.shared.model("model_label_ita_name"), given, 0.38, 0.35),
            (LanguageManager.shared.model("model_label_nationality"), f?.nationality ?? "ITALIANA", 0.38, 0.48),
            (LanguageManager.shared.model("model_label_dob"), f?.dateOfBirth ?? "23 04 1991", 0.38, 0.59),
            (LanguageManager.shared.model("model_label_ita_tax_code"), f?.documentNumber ?? "FRRMRC91D23H501Z", 0.38, 0.71),
            (LanguageManager.shared.model("model_label_expires"), f?.expires ?? "23 04 2031", 0.70, 0.71),
        ]
        for (label, value, fx, fy) in fieldData {
            let labelT = Text(label)
                .font(.system(size: h * 0.026, weight: .semibold))
                .foregroundColor(Color(hex: "003D8F"))
            context.draw(labelT, at: CGPoint(x: w * fx, y: h * fy), anchor: .topLeading)
            let valueT = Text(value)
                .font(.system(size: h * 0.038, weight: .bold, design: .monospaced))
                .foregroundColor(Color(hex: "0a0a0a"))
            context.draw(valueT, at: CGPoint(x: w * fx, y: h * fy + h * 0.036), anchor: .topLeading)
        }

        // MRZ — use actual OCR-extracted MRZ if available; omit placeholder if not.
        context.fill(Path(CGRect(x: 0, y: h * 0.87, width: w, height: h * 0.13)),
                     with: .color(Color(hex: "d8e4f4")))
        if let mrzRaw = f?.mrz, !mrzRaw.isEmpty {
            let mrzLines = mrzRaw.components(separatedBy: "\n")
            let offsets: [CGFloat] = [0.878, 0.906, 0.934]
            for (i, line) in mrzLines.prefix(3).enumerated() {
                let mrzT = Text(line)
                    .font(.system(size: h * 0.028, weight: .bold, design: .monospaced))
                    .foregroundColor(Color(hex: "0a0a0a"))
                context.draw(mrzT, at: CGPoint(x: w * 0.04, y: h * offsets[i]), anchor: .topLeading)
            }
        }
    }
}

// MARK: - Generic ID

struct GenericIDView: View {
    let size: CGSize
    var fields: DocumentFields? = nil
    var redactions: [Redaction] = []
    var watermark: Watermark? = nil

    var body: some View {
        VectorDocBlurWrapper(redactions: redactions, size: size) {
            Canvas { context, sz in
                draw(context: &context, size: sz)
                if let wm = watermark { drawWatermark(context: &context, size: sz, watermark: wm) }
                for r in redactions where !r.style.isBlur {
                    let rect = CGRect(
                        x: r.rect.origin.x * sz.width, y: r.rect.origin.y * sz.height,
                        width: r.rect.width * sz.width, height: r.rect.height * sz.height
                    )
                    drawMask(context: &context, rect: rect, style: r.style)
                }
            }
            .frame(width: size.width, height: size.height)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    private func draw(context: inout GraphicsContext, size sz: CGSize) {
        let w = sz.width, h = sz.height

        // Neutral background
        context.fill(Path(CGRect(x: 0, y: 0, width: w, height: h)),
                     with: .linearGradient(
                        Gradient(colors: [Color(hex: "F8F8F6"), Color(hex: "E4E4DE")]),
                        startPoint: .zero, endPoint: CGPoint(x: w, y: h)
                     ))

        // Subtle line pattern
        var lineY: CGFloat = 0
        while lineY < h {
            context.stroke(Path { p in p.move(to: CGPoint(x: 0, y: lineY)); p.addLine(to: CGPoint(x: w, y: lineY)) },
                           with: .color(Color(hex: "c0c0b8").opacity(0.3)), lineWidth: 0.5)
            lineY += 8
        }

        // Header
        let headerH = h * 0.14
        context.fill(Path(CGRect(x: 0, y: 0, width: w, height: headerH)),
                     with: .color(Color(hex: "2C2C2C")))
        let title = Text(LanguageManager.shared.model("model_doc_generic_id"))
            .font(.system(size: h * 0.046, weight: .black))
            .foregroundColor(.white)
        context.draw(title, at: CGPoint(x: w * 0.05, y: headerH * 0.55), anchor: .leading)

        // Photo placeholder
        let photoRect = CGRect(x: w * 0.04, y: h * 0.20, width: w * 0.20, height: h * 0.52)
        context.fill(Path(photoRect), with: .color(Color(hex: "555550")))
        context.stroke(Path(photoRect), with: .color(Color(hex: "888880")), lineWidth: 1)
        let headRect = CGRect(x: w * 0.14 - h * 0.078, y: h * 0.27, width: h * 0.156, height: h * 0.156)
        context.fill(Path(ellipseIn: headRect), with: .color(Color(hex: "b8a090")))
        let bodyRect = CGRect(x: w * 0.14 - h * 0.13, y: h * 0.47, width: h * 0.26, height: h * 0.25)
        context.fill(Path(ellipseIn: bodyRect), with: .color(Color(hex: "222222")))

        // Fields
        let f = fields
        let name = f?.fullName ?? "SAMPLE, FIRST M."
        let parts = name.components(separatedBy: ", ")
        let surname = parts.count > 0 ? parts[0] : "—"
        let given = parts.count > 1 ? parts[1] : "—"

        let fieldData: [(String, String, CGFloat, CGFloat)] = [
            (LanguageManager.shared.model("model_label_surname"), surname, 0.30, 0.22),
            (LanguageManager.shared.model("model_label_given_name"), given, 0.30, 0.35),
            (LanguageManager.shared.model("model_label_nationality"), f?.nationality ?? "—", 0.30, 0.48),
            (LanguageManager.shared.model("model_label_dob"), f?.dateOfBirth ?? "01 JAN 1990", 0.30, 0.59),
            (LanguageManager.shared.model("model_label_doc_number"), f?.documentNumber ?? "ID000000000", 0.30, 0.71),
            (LanguageManager.shared.model("model_label_expires"), f?.expires ?? "01 JAN 2030", 0.62, 0.71),
        ]
        for (label, value, fx, fy) in fieldData {
            let labelT = Text(label)
                .font(.system(size: h * 0.026, weight: .semibold))
                .foregroundColor(Color(hex: "888880"))
            context.draw(labelT, at: CGPoint(x: w * fx, y: h * fy), anchor: .topLeading)
            let valueT = Text(value)
                .font(.system(size: h * 0.040, weight: .bold, design: .monospaced))
                .foregroundColor(Color(hex: "1a1a1a"))
            context.draw(valueT, at: CGPoint(x: w * fx, y: h * fy + h * 0.036), anchor: .topLeading)
        }

        // Bottom strip — show actual OCR MRZ if available; leave blank otherwise.
        context.fill(Path(CGRect(x: 0, y: h * 0.87, width: w, height: h * 0.13)),
                     with: .color(Color(hex: "e0e0d8")))
        if let mrzRaw = f?.mrz, !mrzRaw.isEmpty {
            let mrzLines = mrzRaw.components(separatedBy: "\n")
            let offsets: [CGFloat] = [0.882, 0.910, 0.938]
            for (i, line) in mrzLines.prefix(3).enumerated() {
                let mrzT = Text(line)
                    .font(.system(size: h * 0.028, weight: .bold, design: .monospaced))
                    .foregroundColor(Color(hex: "3a3a3a"))
                context.draw(mrzT, at: CGPoint(x: w * 0.04, y: h * offsets[i]), anchor: .topLeading)
            }
        }
    }
}
