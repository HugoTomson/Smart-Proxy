import SwiftUI
import AVFoundation

struct QRCodeScannerView: UIViewControllerRepresentable {
    var didFindCode: (String) -> Void
    @State var captureSession: AVCaptureSession?
    @Environment(\.presentationMode) var presentationMode
    
    
    
    func setupCamera() {
        captureSession = AVCaptureSession()
        guard let captureSession = captureSession else { return }
        
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let videoInput = try? AVCaptureDeviceInput(device: videoDevice),
              captureSession.canAddInput(videoInput) else {
            print("Не удалось получить доступ к задней камере")
            return
        }
        
        captureSession.addInput(videoInput)
        captureSession.startRunning()
    }
    
    
    
    func checkCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if granted {
                    DispatchQueue.main.async {
                        self.setupCamera()
                    }
                } else {
                    print("Доступ к камере не предоставлен")
                    DispatchQueue.main.async {  presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        case .restricted, .denied:
            print("Доступ к камере ограничен или запрещен")
            didFindCode("denied")
            DispatchQueue.main.async { presentationMode.wrappedValue.dismiss()
            }
        case .authorized:
            setupCamera()
        @unknown default:
            print("Неизвестный статус авторизации")
        }
    }
    
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    func makeUIViewController(context: Context) -> UIViewController {
        checkCameraPermission()
        let viewController = UIViewController()
        let captureSession = AVCaptureSession()
      
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return viewController }
        let videoInput: AVCaptureDeviceInput
        
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            return viewController
        }
        
        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
        } else {
            return viewController
        }
        
        let metadataOutput = AVCaptureMetadataOutput()
        if captureSession.canAddOutput(metadataOutput) {
            captureSession.addOutput(metadataOutput)
            
            metadataOutput.setMetadataObjectsDelegate(context.coordinator, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr]
        } else {
            return viewController
        }
        
        // Настройка слоя предварительного просмотра
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = viewController.view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        viewController.view.layer.addSublayer(previewLayer)
        
        // Добавление маски
        let overlayLayer = createOverlay(frame: viewController.view.bounds)
        viewController.view.layer.addSublayer(overlayLayer)
        
        captureSession.startRunning()
        
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
    
    class Coordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate {
        var parent: QRCodeScannerView
        var opend = false;
        
        init(parent: QRCodeScannerView) {
            self.parent = parent
        }
        
        func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
            if let metadataObject = metadataObjects.first {
                guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
                guard let stringValue = readableObject.stringValue else { return }
                AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
                
                if !opend{
                    opend = true
                    parent.didFindCode(stringValue)
                    parent.presentationMode.wrappedValue.dismiss()
                
                }
            }
        }
    }
}

// Функция для создания наложения маски с вырезанным прямоугольником
func createOverlay(frame: CGRect) -> CALayer {
    let overlayLayer = CALayer()
    overlayLayer.frame = frame
    
    let maskLayer = CAShapeLayer()
    maskLayer.frame = frame
    
    // Размеры и положение вырезанного прямоугольника
    let rectWidth: CGFloat = 250
    let rectHeight: CGFloat = 250
    let rectX: CGFloat = (frame.width - rectWidth) / 2
    let rectY: CGFloat = (frame.height - rectHeight) / 2
    let transparentRect = CGRect(x: rectX, y: rectY, width: rectWidth, height: rectHeight)
    
    let path = UIBezierPath(rect: frame)
    let cornerRadius: CGFloat = 20
    let transparentPath = UIBezierPath(roundedRect: transparentRect, cornerRadius: cornerRadius)
    
    path.append(transparentPath)
    maskLayer.path = path.cgPath
    maskLayer.fillRule = .evenOdd
    
    overlayLayer.backgroundColor = UIColor.black.withAlphaComponent(0.6).cgColor
    overlayLayer.mask = maskLayer
    
    return overlayLayer
}


