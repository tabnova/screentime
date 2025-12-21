//
//  EnrollmentView.swift
//  TabnovaEMM
//
//  Created on 2024
//

import SwiftUI
import AVFoundation

struct EnrollmentView: View {
    var onEnrollmentComplete: () -> Void
    @State private var showScanner = false
    @State private var scannedCode: String?
    @State private var showAlert = false
    
    var body: some View {
        ZStack {
            if showScanner {
                QRCodeScannerView(scannedCode: $scannedCode, isPresented: $showScanner)
                    .ignoresSafeArea()
            } else {
                Color.white
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    ZStack {
                        Color(hex: "1A9B8E")
                            .ignoresSafeArea(edges: .top)
                        
                        Text("Enrollment")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .frame(height: 100)
                    
                    Spacer()
                    
                    // Logo
                    ZStack {
                        HexagonShape()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color(hex: "1A9B8E"), Color(hex: "0D7A70")]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 120, height: 120)
                        
                        HexagonShape()
                            .fill(Color(hex: "5DDECD"))
                            .frame(width: 80, height: 80)
                        
                        VStack(spacing: 1) {
                            Text("TABNOVA")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(Color(hex: "1A9B8E"))
                            Text("Enterprise")
                                .font(.system(size: 8, weight: .semibold))
                                .foregroundColor(Color(hex: "1A9B8E"))
                        }
                    }
                    .padding(.top, 40)
                    
                    Spacer()
                    
                    // QR Code Button
                    Button(action: {
                        showScanner = true
                    }) {
                        Text("QR CODE")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color(hex: "1A9B8E"))
                            .cornerRadius(25)
                    }
                    .padding(.horizontal, 50)
                    .padding(.bottom, 100)
                }
            }
        }
        .onChange(of: scannedCode) { newValue in
            if let code = newValue {
                handleScannedCode(code)
            }
        }
        .alert("Enrollment", isPresented: $showAlert) {
            Button("OK") {
                onEnrollmentComplete()
            }
        } message: {
            Text("Profile configuration has been downloaded. Please install the profile from Settings > General > VPN & Device Management.")
        }
    }
    
    private func handleScannedCode(_ code: String) {
        // Simulate profile download
        // In a real app, this would download and install the MDM profile
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            showAlert = true
        }
    }
}

// QR Code Scanner View
struct QRCodeScannerView: UIViewControllerRepresentable {
    @Binding var scannedCode: String?
    @Binding var isPresented: Bool
    
    func makeUIViewController(context: Context) -> QRScannerViewController {
        let controller = QRScannerViewController()
        controller.delegate = context.coordinator
        return controller
    }
    
    func updateUIViewController(_ uiViewController: QRScannerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, QRScannerDelegate {
        var parent: QRCodeScannerView
        
        init(_ parent: QRCodeScannerView) {
            self.parent = parent
        }
        
        func didScanCode(_ code: String) {
            parent.scannedCode = code
            parent.isPresented = false
        }
        
        func didFailWithError(_ error: Error) {
            print("Scanning failed: \(error.localizedDescription)")
            parent.isPresented = false
        }
    }
}

// QR Scanner Delegate Protocol
protocol QRScannerDelegate: AnyObject {
    func didScanCode(_ code: String)
    func didFailWithError(_ error: Error)
}

// QR Scanner View Controller
class QRScannerViewController: UIViewController {
    weak var delegate: QRScannerDelegate?
    
    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupCamera()
        addCloseButton()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let session = captureSession, !session.isRunning {
            DispatchQueue.global(qos: .userInitiated).async {
                session.startRunning()
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if let session = captureSession, session.isRunning {
            DispatchQueue.global(qos: .userInitiated).async {
                session.stopRunning()
            }
        }
    }
    
    private func setupCamera() {
        captureSession = AVCaptureSession()
        
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
            delegate?.didFailWithError(NSError(domain: "Camera", code: -1, userInfo: [NSLocalizedDescriptionKey: "No camera available"]))
            return
        }
        
        let videoInput: AVCaptureDeviceInput
        
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            delegate?.didFailWithError(error)
            return
        }
        
        if let session = captureSession, session.canAddInput(videoInput) {
            session.addInput(videoInput)
        } else {
            delegate?.didFailWithError(NSError(domain: "Camera", code: -2, userInfo: [NSLocalizedDescriptionKey: "Could not add video input"]))
            return
        }
        
        let metadataOutput = AVCaptureMetadataOutput()
        
        if let session = captureSession, session.canAddOutput(metadataOutput) {
            session.addOutput(metadataOutput)
            
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr]
        } else {
            delegate?.didFailWithError(NSError(domain: "Camera", code: -3, userInfo: [NSLocalizedDescriptionKey: "Could not add metadata output"]))
            return
        }
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)
        previewLayer?.frame = view.layer.bounds
        previewLayer?.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer!)
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession?.startRunning()
        }
    }
    
    private func addCloseButton() {
        let closeButton = UIButton(type: .system)
        closeButton.setTitle("Cancel", for: .normal)
        closeButton.setTitleColor(.white, for: .normal)
        closeButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        closeButton.backgroundColor = UIColor(red: 0.1, green: 0.6, blue: 0.56, alpha: 1.0)
        closeButton.layer.cornerRadius = 10
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        
        view.addSubview(closeButton)
        
        NSLayoutConstraint.activate([
            closeButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -30),
            closeButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            closeButton.widthAnchor.constraint(equalToConstant: 200),
            closeButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    @objc private func closeTapped() {
        dismiss(animated: true)
    }
}

extension QRScannerViewController: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        captureSession?.stopRunning()
        
        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
            guard let stringValue = readableObject.stringValue else { return }
            
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            delegate?.didScanCode(stringValue)
        }
    }
}

struct EnrollmentView_Previews: PreviewProvider {
    static var previews: some View {
        EnrollmentView(onEnrollmentComplete: {})
    }
}
