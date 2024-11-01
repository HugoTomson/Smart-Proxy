import SwiftUI
import UIKit
import ImageIO

struct GIFView: UIViewRepresentable {
    private let gifName: String
    @Binding var isPlaying: Bool

    init(gifName: String, isPlaying: Binding<Bool>) {
        self.gifName = gifName
        self._isPlaying = isPlaying
    }

    func makeUIView(context: Context) -> UIView {
        let containerView = UIView()
        let imageView = UIImageView()

        containerView.addSubview(imageView)

        imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            imageView.topAnchor.constraint(equalTo: containerView.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])

        imageView.contentMode = .scaleAspectFit

        if let path = Bundle.main.path(forResource: gifName, ofType: "gif"),
           let data = NSData(contentsOfFile: path),
           let gifImages = UIImage.extractFramesFromGif(data: data as Data) {
            // Указываем изображения GIF для анимации
            context.coordinator.frames = gifImages.frames
            context.coordinator.duration = gifImages.duration
            context.coordinator.imageView = imageView
            
            // Устанавливаем последний кадр, если `isPlaying = true`
            if isPlaying {
                imageView.image = gifImages.frames.last
                context.coordinator.isAlreadyPlaed = true
            }
        }

        return containerView
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        if let imageView = context.coordinator.imageView {
            context.coordinator.playGif(imageView: imageView, isPlaying: isPlaying)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator {
        var frames: [UIImage] = []
        var duration: Double = 0
        var imageView: UIImageView?
        var isAlreadyPlaed = false

        func playGif(imageView: UIImageView, isPlaying: Bool) {
            // Логика проигрывания или остановки анимации
            if !isPlaying && isAlreadyPlaed {
                self.isAlreadyPlaed = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    imageView.stopAnimating()
                }
            } else if isPlaying && !imageView.isAnimating && !isAlreadyPlaed {
                // Устанавливаем анимацию и запускаем проигрывание
                isAlreadyPlaed = true
                imageView.animationImages = frames
                imageView.animationDuration = duration
                imageView.animationRepeatCount = 1
                imageView.startAnimating()
                
                // Останавливаем на последнем кадре после завершения анимации
                DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                    imageView.image = self.frames.last
                }
            }
        }
    }
}

extension UIImage {
    class func extractFramesFromGif(data: Data) -> (frames: [UIImage], duration: Double)? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }

        var images = [UIImage]()
        var duration: Double = 0

        let count = CGImageSourceGetCount(source)
        for i in 0..<count {
            if let cgImage = CGImageSourceCreateImageAtIndex(source, i, nil) {
                images.append(UIImage(cgImage: cgImage))
                let frameDuration = UIImage.frameDuration(at: i, source: source)
                duration += frameDuration
            }
        }

        return (frames: images, duration: duration)
    }

    class func frameDuration(at index: Int, source: CGImageSource) -> Double {
        var frameDuration = 0.1
        let cfProperties = CGImageSourceCopyPropertiesAtIndex(source, index, nil)
        let gifProperties: CFDictionary = unsafeBitCast(
            CFDictionaryGetValue(cfProperties, Unmanaged.passUnretained(kCGImagePropertyGIFDictionary).toOpaque()),
            to: CFDictionary.self
        )
        var delayTime = unsafeBitCast(
            CFDictionaryGetValue(gifProperties, Unmanaged.passUnretained(kCGImagePropertyGIFUnclampedDelayTime).toOpaque()),
            to: AnyObject.self
        ) as! Double
        if delayTime == 0 {
            delayTime = unsafeBitCast(
                CFDictionaryGetValue(gifProperties, Unmanaged.passUnretained(kCGImagePropertyGIFDelayTime).toOpaque()),
                to: AnyObject.self
            ) as! Double
        }
        frameDuration = delayTime
        return frameDuration
    }
}
