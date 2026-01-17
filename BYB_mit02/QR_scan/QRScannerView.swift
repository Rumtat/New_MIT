//
//  QRScannerView.swift
//  BYB_mit02
//
//  Created by Vituruch Sinthusate on 17/1/2569 BE.
//


//
//  QRScannerView.swift
//  BYB_mit02
//

import SwiftUI
import AVFoundation

struct QRScannerView: UIViewControllerRepresentable {
    typealias UIViewControllerType = ScannerViewController

    var onResult: (String) -> Void
    var onCancel: () -> Void

    func makeUIViewController(context: Context) -> ScannerViewController {
        let vc = ScannerViewController()
        vc.onResult = onResult
        vc.onCancel = onCancel
        return vc
    }

    func updateUIViewController(_ uiViewController: ScannerViewController, context: Context) {}
}

// MARK: - UIKit VC

final class ScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {

    var onResult: ((String) -> Void)?
    var onCancel: (() -> Void)?

    private let session = AVCaptureSession()
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var didSendResult = false

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupCamera()
        setupOverlay()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        didSendResult = false
        if !session.isRunning { session.startRunning() }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if session.isRunning { session.stopRunning() }
    }

    private func setupCamera() {
        session.beginConfiguration()
        session.sessionPreset = .high

        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input)
        else {
            session.commitConfiguration()
            return
        }
        session.addInput(input)

        let output = AVCaptureMetadataOutput()
        guard session.canAddOutput(output) else {
            session.commitConfiguration()
            return
        }
        session.addOutput(output)

        output.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        output.metadataObjectTypes = [.qr, .ean13, .ean8, .code128, .pdf417]

        session.commitConfiguration()

        let preview = AVCaptureVideoPreviewLayer(session: session)
        preview.videoGravity = .resizeAspectFill
        preview.frame = view.bounds
        view.layer.addSublayer(preview)
        previewLayer = preview
    }

    private func setupOverlay() {
        // Top bar with close button
        let close = UIButton(type: .system)
        close.setTitle("ปิด", for: .normal)
        close.setTitleColor(.white, for: .normal)
        close.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        close.addTarget(self, action: #selector(tapClose), for: .touchUpInside)

        close.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(close)

        NSLayoutConstraint.activate([
            close.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            close.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16)
        ])

        // Center guide box
        let guide = UIView()
        guide.layer.borderColor = UIColor.white.withAlphaComponent(0.85).cgColor
        guide.layer.borderWidth = 2
        guide.layer.cornerRadius = 16
        guide.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(guide)

        NSLayoutConstraint.activate([
            guide.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            guide.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            guide.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.72),
            guide.heightAnchor.constraint(equalTo: guide.widthAnchor)
        ])

        // Hint text
        let hint = UILabel()
        hint.text = "วาง QR ให้อยู่ในกรอบ"
        hint.textColor = UIColor.white.withAlphaComponent(0.9)
        hint.font = .systemFont(ofSize: 15, weight: .medium)
        hint.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hint)

        NSLayoutConstraint.activate([
            hint.topAnchor.constraint(equalTo: guide.bottomAnchor, constant: 14),
            hint.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }

    @objc private func tapClose() {
        onCancel?()
    }

    func metadataOutput(_ output: AVCaptureMetadataOutput,
                        didOutput metadataObjects: [AVMetadataObject],
                        from connection: AVCaptureConnection) {
        guard !didSendResult else { return }
        guard let obj = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              let value = obj.stringValue, !value.isEmpty
        else { return }

        didSendResult = true
        onResult?(value)
    }
}
