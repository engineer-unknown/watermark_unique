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
            guard let filePath = arguments["filePath"] as? String,
                  let text = arguments["text"] as? String,
                  let x = arguments["x"] as? CGFloat,
                  let y = arguments["y"] as? CGFloat,
                  let textSize = arguments["textSize"] as? CGFloat,
                  let colorHex = arguments["color"] as? CGFloat,
                  let color = UIColor(rgb: Int(colorHex)),
                  let quality = arguments["quality"] as? CGFloat,
                  let imageFormat = arguments["imageFormat"] as? String else {
                result(FlutterError(code: "ARGUMENT_ERROR", message: "Missing arguments", details: nil))
                return
            }

         var backgroundTextColor: UIColor?

         if let colorBackgroundHex = arguments["backgroundTextColor"] as? Int {
             let alpha = CGFloat((colorBackgroundHex >> 24) & 0xFF) / 255.0
             let red = CGFloat((colorBackgroundHex >> 16) & 0xFF) / 255.0
             let green = CGFloat((colorBackgroundHex >> 8) & 0xFF) / 255.0
             let blue = CGFloat(colorBackgroundHex & 0xFF) / 255.0

             print("Alpha: \(alpha), Red: \(red), Green: \(green), Blue: \(blue)")

             backgroundTextColor = UIColor(red: red, green: green, blue: blue, alpha: alpha)
         }


            let backgroundTextPaddingTop = arguments["backgroundTextPaddingTop"] as? CGFloat
            let backgroundTextPaddingBottom = arguments["backgroundTextPaddingBottom"] as? CGFloat
            let backgroundTextPaddingLeft = arguments["backgroundTextPaddingLeft"] as? CGFloat
            let backgroundTextPaddingRight = arguments["backgroundTextPaddingRight"] as? CGFloat

            addTextWatermark(text: text,
                             filePath: filePath,
                             x: CGFloat(x),
                             y: y,
                             textWatermarkSize: textSize,
                             colorWatermark: color,
                             backgroundTextColor: backgroundTextColor,
                             quality: quality,
                             backgroundTextPaddingTop: backgroundTextPaddingTop,
                             backgroundTextPaddingBottom: backgroundTextPaddingBottom,
                             backgroundTextPaddingLeft: backgroundTextPaddingLeft,
                             backgroundTextPaddingRight: backgroundTextPaddingRight,
                             imageFormat: imageFormat) { (newFilePath, error) in
                if let error = error {
                    result(FlutterError(code: "PROCESSING_ERROR", message: "Failed to process image: \(error.localizedDescription)", details: nil))
                } else if let newFilePath = newFilePath {
                    result(newFilePath)
                } else {
                    result(FlutterError(code: "UNKNOWN_ERROR", message: "Unknown error occurred", details: nil))
                }
            }
        case "addImageWatermark":
            guard let filePath = arguments["filePath"] as? String,
                  let watermarkImagePath = arguments["watermarkImagePath"] as? String,
                  let x = arguments["x"] as? CGFloat,
                  let y = arguments["y"] as? CGFloat,
                  let watermarkWidth = arguments["watermarkWidth"] as? CGFloat,
                  let watermarkHeight = arguments["watermarkHeight"] as? CGFloat,
                  let quality = arguments["quality"] as? CGFloat,
                  let imageFormat = arguments["imageFormat"] as? String else {
                result(FlutterError(code: "ARGUMENT_ERROR", message: "Missing arguments", details: nil))
                return
            }

            addImageWatermark(filePath: filePath,
                              watermarkImagePath: watermarkImagePath,
                              x: x,
                              y: y,
                              watermarkWidth: watermarkWidth,
                              watermarkHeight: watermarkHeight,
                              quality: quality,
                              imageFormat: imageFormat) { (newFilePath, error) in
                if let error = error {
                    result(FlutterError(code: "PROCESSING_ERROR", message: "Failed to process image: \(error.localizedDescription)", details: nil))
                } else if let newFilePath = newFilePath {
                    result(newFilePath)
                } else {
                    result(FlutterError(code: "UNKNOWN_ERROR", message: "Unknown error occurred", details: nil))
                }
            }
        case "getPlatformVersion":
            result("iOS " + UIDevice.current.systemVersion)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    func addTextWatermark(text: String,
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
                          completion: @escaping (String?, Error?) -> Void) {

        guard let image = UIImage(contentsOfFile: filePath) else {
            completion(nil, NSError(domain: "ImageProcessorErrorDomain", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to load image"]))
            return
        }

        DispatchQueue.global().async {
            UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)

            image.draw(in: CGRect(origin: .zero, size: image.size))

            let textFont = UIFont.systemFont(ofSize: textWatermarkSize)
            let textAttributes: [NSAttributedString.Key: Any] = [
                .font: textFont,
                .foregroundColor: colorWatermark
            ]

            let maxTextWidth = image.size.width - x - (backgroundTextPaddingLeft ?? 0) - (backgroundTextPaddingRight ?? 0)

            func wrappedText(_ text: String, width: CGFloat, font: UIFont) -> [String] {
                let words = text.split(separator: " ")
                var lines: [String] = []
                var currentLine = ""

                for word in words {
                    let newLine = currentLine.isEmpty ? String(word) : "\(currentLine) \(word)"
                    let size = newLine.size(withAttributes: [.font: font])

                    if size.width <= width {
                        currentLine = newLine
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

            let lines = wrappedText(text, width: maxTextWidth, font: textFont)
            var currentY = y

            for line in lines {
                let textSize = line.size(withAttributes: textAttributes)
                let textRect = CGRect(x: x, y: currentY, width: textSize.width, height: textSize.height)

                var backgroundRect = textRect.inset(by: UIEdgeInsets(top: -(backgroundTextPaddingTop ?? 0),
                                                                     left: -(backgroundTextPaddingLeft ?? 0),
                                                                     bottom: -(backgroundTextPaddingBottom ?? 0),
                                                                     right: -(backgroundTextPaddingRight ?? 0)))

                backgroundRect = backgroundRect.intersection(CGRect(x: x-(backgroundTextPaddingTop ?? 0), y: y-(backgroundTextPaddingTop ?? 0), width: image.size.width, height: image.size.height))

                if let backgroundColor = backgroundTextColor {
                    backgroundColor.setFill()
                    UIRectFill(backgroundRect)
                }

                line.draw(in: textRect, withAttributes: textAttributes)

                currentY += textSize.height
            }

            guard let newImage = UIGraphicsGetImageFromCurrentImageContext(),
                let compressedData = newImage.jpegData(compressionQuality: (quality / 100)) else {
                UIGraphicsEndImageContext()
                completion(nil, NSError(domain: "ImageProcessorErrorDomain", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create new image"]))
                return
            }

            UIGraphicsEndImageContext()

            let newFilePath = (filePath as NSString).deletingLastPathComponent + "/\(UUID().uuidString).\(imageFormat)"

            do {
                try compressedData.write(to: URL(fileURLWithPath: newFilePath), options: .atomic)
                completion(newFilePath, nil)
            } catch {
                completion(nil, NSError(domain: "ImageProcessorErrorDomain", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to save image"]))
            }
        }
    }

    func addImageWatermark(filePath: String,
                           watermarkImagePath: String,
                           x: CGFloat,
                           y: CGFloat,
                           watermarkWidth: CGFloat,
                           watermarkHeight: CGFloat,
                           quality: CGFloat,
                           imageFormat: String,
                           completion: @escaping (String?, Error?) -> Void) {

        guard let image = UIImage(contentsOfFile: filePath),
              let watermarkImage = UIImage(contentsOfFile: watermarkImagePath) else {
              completion(nil, NSError(domain: "READ_ERROR", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create new image"]))
            return
        }

        UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)

        image.draw(in: CGRect(origin: .zero, size: image.size))

        watermarkImage.draw(in: CGRect(x: x, y: y, width: watermarkWidth, height: watermarkHeight))

        guard let newImage = UIGraphicsGetImageFromCurrentImageContext(),
              let compressedData = newImage.jpegData(compressionQuality: (quality / 100)) else {
            UIGraphicsEndImageContext()
            completion(nil, NSError(domain: "CONVERSION_ERROR", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create new image"]))
            return
        }

        UIGraphicsEndImageContext()

        let newFilePath = (filePath as NSString).deletingLastPathComponent + "/\(UUID().uuidString).\(imageFormat)"

        do {
            try compressedData.write(to: URL(fileURLWithPath: newFilePath), options: .atomic)
            completion(newFilePath, nil)
        } catch {
            completion(nil, NSError(domain: "ImageProcessorErrorDomain", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to save image"]))
        }
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
