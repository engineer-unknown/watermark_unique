import Flutter
import UIKit

public class WatermarkUniquePlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "WatermarkImage", binaryMessenger: registrar.messenger())
        let instance = WatermarkUniquePlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let arguments = call.arguments as? [String: Any] else {
            result(FlutterError(code: "ARGUMENT_ERROR", message: "Missing arguments", details: nil))
            return
        }

        switch call.method {
        case "addTextWatermark":
            handleAddTextWatermark(arguments: arguments, result: result)
        case "addImageWatermark":
            handleAddImageWatermark(arguments: arguments, result: result)
        case "getPlatformVersion":
            result("iOS " + UIDevice.current.systemVersion)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func handleAddTextWatermark(arguments: [String: Any], result: @escaping FlutterResult) {
        guard let filePath = arguments["filePath"] as? String,
              let text = arguments["text"] as? String,
              let x = arguments["x"] as? CGFloat,
              let y = arguments["y"] as? CGFloat,
              let textSize = arguments["textSize"] as? CGFloat,
              let colorHex = arguments["color"] as? CGFloat,
              let color = UIColor(rgb: Int(colorHex)),
              let quality = arguments["quality"] as? CGFloat,
              let imageFormat = arguments["imageFormat"] as? String else {
            result(FlutterError(code: "ARGUMENT_ERROR", message: "Missing or invalid arguments", details: nil))
            return
        }

        let backgroundTextColor: UIColor? = {
            if let colorBackgroundHex = arguments["backgroundTextColor"] as? Int {
                let alpha = CGFloat((colorBackgroundHex >> 24) & 0xFF) / 255.0
                let red = CGFloat((colorBackgroundHex >> 16) & 0xFF) / 255.0
                let green = CGFloat((colorBackgroundHex >> 8) & 0xFF) / 255.0
                let blue = CGFloat(colorBackgroundHex & 0xFF) / 255.0
                return UIColor(red: red, green: green, blue: blue, alpha: alpha)
            }
            return nil
        }()

        addTextWatermark(
            text: text,
            filePath: filePath,
            x: x,
            y: y,
            textWatermarkSize: textSize,
            colorWatermark: color,
            backgroundTextColor: backgroundTextColor,
            quality: quality,
            backgroundTextPaddingTop: arguments["backgroundTextPaddingTop"] as? CGFloat,
            backgroundTextPaddingBottom: arguments["backgroundTextPaddingBottom"] as? CGFloat,
            backgroundTextPaddingLeft: arguments["backgroundTextPaddingLeft"] as? CGFloat,
            backgroundTextPaddingRight: arguments["backgroundTextPaddingRight"] as? CGFloat,
            imageFormat: imageFormat
        ) { newFilePath, error in
            if let error = error {
                result(FlutterError(code: "PROCESSING_ERROR", message: error.localizedDescription, details: nil))
            } else if let newFilePath = newFilePath {
                result(newFilePath)
            } else {
                result(FlutterError(code: "UNKNOWN_ERROR", message: "Unknown error occurred", details: nil))
            }
        }
    }

    private func handleAddImageWatermark(arguments: [String: Any], result: @escaping FlutterResult) {
        guard let filePath = arguments["filePath"] as? String,
              let watermarkImagePath = arguments["watermarkImagePath"] as? String,
              let x = arguments["x"] as? CGFloat,
              let y = arguments["y"] as? CGFloat,
              let watermarkWidth = arguments["watermarkWidth"] as? CGFloat,
              let watermarkHeight = arguments["watermarkHeight"] as? CGFloat,
              let quality = arguments["quality"] as? CGFloat,
              let imageFormat = arguments["imageFormat"] as? String else {
            result(FlutterError(code: "ARGUMENT_ERROR", message: "Missing or invalid arguments", details: nil))
            return
        }

        addImageWatermark(
            filePath: filePath,
            watermarkImagePath: watermarkImagePath,
            x: x,
            y: y,
            watermarkWidth: watermarkWidth,
            watermarkHeight: watermarkHeight,
            quality: quality,
            imageFormat: imageFormat
        ) { newFilePath, error in
            if let error = error {
                result(FlutterError(code: "PROCESSING_ERROR", message: error.localizedDescription, details: nil))
            } else if let newFilePath = newFilePath {
                result(newFilePath)
            } else {
                result(FlutterError(code: "UNKNOWN_ERROR", message: "Unknown error occurred", details: nil))
            }
        }
    }

    func addTextWatermark(
        text: String,
        filePath: String,
        x: CGFloat,
        y: CGFloat,
        textWatermarkSize: CGFloat,
        colorWatermark: UIColor,
        backgroundTextColor: UIColor?,
        quality: CGFloat,
        backgroundTextPaddingTop: CGFloat?,
        backgroundTextPaddingBottom: CGFloat?,
        backgroundTextPaddingLeft: CGFloat?,
        backgroundTextPaddingRight: CGFloat?,
        imageFormat: String,
        completion: @escaping (String?, Error?) -> Void
    ) {
        guard let image = UIImage(contentsOfFile: filePath) else {
            completion(nil, NSError(domain: "ImageProcessorErrorDomain", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to load image"]))
            return
        }

        DispatchQueue.global().async {
            UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
            image.draw(in: CGRect(origin: .zero, size: image.size))

            let font = UIFont.systemFont(ofSize: textWatermarkSize)
            let attributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: colorWatermark
            ]

            let maxWidth = image.size.width - x - (backgroundTextPaddingLeft ?? 0) - (backgroundTextPaddingRight ?? 0)
            let lines = self.wrappedText(text, width: maxWidth, font: font)
            var currentY = y

            for line in lines {
                let size = line.size(withAttributes: attributes)
                let textRect = CGRect(x: x, y: currentY, width: size.width, height: size.height)

                let backgroundRect = textRect.inset(by: UIEdgeInsets(
                    top: -(backgroundTextPaddingTop ?? 0),
                    left: -(backgroundTextPaddingLeft ?? 0),
                    bottom: -(backgroundTextPaddingBottom ?? 0),
                    right: -(backgroundTextPaddingRight ?? 0))
                )

                if let bgColor = backgroundTextColor {
                    bgColor.setFill()
                    UIRectFillUsingBlendMode(backgroundRect, .normal)
                }

                line.draw(in: textRect, withAttributes: attributes)
                currentY += size.height
            }

            guard let newImage = UIGraphicsGetImageFromCurrentImageContext(),
                  let data = newImage.jpegData(compressionQuality: (quality / 100)) else {
                UIGraphicsEndImageContext()
                completion(nil, NSError(domain: "ImageProcessorErrorDomain", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create new image"]))
                return
            }

            UIGraphicsEndImageContext()

            let newPath = (filePath as NSString).deletingLastPathComponent + "/\(UUID().uuidString).\(imageFormat)"

            do {
                try data.write(to: URL(fileURLWithPath: newPath), options: .atomic)
                completion(newPath, nil)
            } catch {
                completion(nil, error)
            }
        }
    }

    func addImageWatermark(
        filePath: String,
        watermarkImagePath: String,
        x: CGFloat,
        y: CGFloat,
        watermarkWidth: CGFloat,
        watermarkHeight: CGFloat,
        quality: CGFloat,
        imageFormat: String,
        completion: @escaping (String?, Error?) -> Void
    ) {
        guard let image = UIImage(contentsOfFile: filePath),
              let watermark = UIImage(contentsOfFile: watermarkImagePath) else {
            completion(nil, NSError(domain: "READ_ERROR", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to load images"]))
            return
        }

        UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
        image.draw(in: CGRect(origin: .zero, size: image.size))
        watermark.draw(in: CGRect(x: x, y: y, width: watermarkWidth, height: watermarkHeight))

        guard let newImage = UIGraphicsGetImageFromCurrentImageContext(),
              let data = newImage.jpegData(compressionQuality: (quality / 100)) else {
            UIGraphicsEndImageContext()
            completion(nil, NSError(domain: "CONVERSION_ERROR", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to process image"]))
            return
        }

        UIGraphicsEndImageContext()

        let newPath = (filePath as NSString).deletingLastPathComponent + "/\(UUID().uuidString).\(imageFormat)"

        do {
            try data.write(to: URL(fileURLWithPath: newPath), options: .atomic)
            completion(newPath, nil)
        } catch {
            completion(nil, error)
        }
    }

    private func wrappedText(_ text: String, width: CGFloat, font: UIFont) -> [String] {
        let words = text.split(separator: " ")
        var lines: [String] = []
        var currentLine = ""

        for word in words {
            let testLine = currentLine.isEmpty ? String(word) : "\(currentLine) \(word)"
            let testSize = testLine.size(withAttributes: [.font: font])

            if testSize.width <= width {
                currentLine = testLine
            } else {
                if !currentLine.isEmpty {
                    lines.append(currentLine)
                }
                currentLine = String(word)
            }
        }

        if !currentLine.isEmpty {
            lines.append(currentLine)
        }

        return lines
    }
}

extension UIColor {
    convenience init?(rgb: Int?) {
        guard let rgb = rgb else { return nil }
        let red = CGFloat((rgb >> 16) & 0xFF) / 255.0
        let green = CGFloat((rgb >> 8) & 0xFF) / 255.0
        let blue = CGFloat(rgb & 0xFF) / 255.0
        self.init(red: red, green: green, blue: blue, alpha: 1.0)
    }
}
