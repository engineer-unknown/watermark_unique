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
            if let colorBackgroundHex = arguments["backgroundTextColor"] as? CGFloat {
                backgroundTextColor = UIColor(rgb: Int(colorBackgroundHex))
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
            UIGraphicsBeginImageContextWithOptions(image.size, false, 0.0)

            image.draw(at: .zero)

            // Calculate the size of the text
            let textFont = UIFont.systemFont(ofSize: textWatermarkSize)
            let textAttributes: [NSAttributedString.Key: Any] = [
                .font: textFont,
                .foregroundColor: colorWatermark
            ]
            let textSize = text.size(withAttributes: textAttributes)

            // Calculate the rect for text
            let textRect = CGRect(x: x, y: y, width: textSize.width, height: textSize.height)

            // Calculate the rect for background text
            var backgroundRect = textRect.inset(by: UIEdgeInsets(top: -(backgroundTextPaddingTop ?? 0),
                                                                 left: -(backgroundTextPaddingLeft ?? 0),
                                                                 bottom: -(backgroundTextPaddingBottom ?? 0),
                                                                 right: -(backgroundTextPaddingRight ?? 0)))

            // Ensure backgroundRect does not exceed image bounds
            backgroundRect = backgroundRect.intersection(CGRect(x: x, y: y, width: image.size.width, height: image.size.height))

            if let backgroundColor = backgroundTextColor {
                backgroundColor.setFill()
                UIRectFill(backgroundRect)
            }

            text.draw(in: textRect, withAttributes: textAttributes)

            guard let newImage = UIGraphicsGetImageFromCurrentImageContext() else {
                UIGraphicsEndImageContext()
                completion(nil, NSError(domain: "ImageProcessorErrorDomain", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create new image"]))
                return
            }

            UIGraphicsEndImageContext()

            guard let data = newImage.jpegData(compressionQuality: (quality / 100)) ?? newImage.pngData() else {
                completion(nil, NSError(domain: "ImageProcessorErrorDomain", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image data"]))
                return
            }

            let fileManager = FileManager.default
            let newFilePath = (filePath as NSString).deletingLastPathComponent + "/\(UUID().uuidString).\(imageFormat)"
            if fileManager.createFile(atPath: newFilePath, contents: data, attributes: nil) {
                completion(newFilePath, nil)
            } else {
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
              completion(nil, NSError(domain: "READ_ERROR", code: -1, userInfo: [NSLocalizedDescriptionKey: "Ошибка чтения файла изображения"]))
            return
        }

        UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)

        image.draw(in: CGRect(origin: .zero, size: image.size))

        watermarkImage.draw(in: CGRect(x: x, y: y, width: watermarkWidth, height: watermarkHeight))

        guard let newImage = UIGraphicsGetImageFromCurrentImageContext(),
              let compressedData = newImage.jpegData(compressionQuality: (quality / 100)) else {
            completion(nil, NSError(domain: "CONVERSION_ERROR", code: -1, userInfo: [NSLocalizedDescriptionKey: "Ошибка преобразования данных изображения"]))
            return
        }

        UIGraphicsEndImageContext()

        let newFilePath = (filePath as NSString).deletingLastPathComponent + "/\(UUID().uuidString).\(imageFormat)"

        do {
            try compressedData.write(to: URL(fileURLWithPath: newFilePath), options: .atomic)
            completion(newFilePath, nil)
        } catch {
            completion(nil, NSError(domain: "ImageProcessorErrorDomain", code: -1, userInfo: [NSLocalizedDescriptionKey: "Ошибка сохранения изображения"]))
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
