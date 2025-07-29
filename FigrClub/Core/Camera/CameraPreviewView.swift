//
//  CameraPreviewView.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 29/7/25.
//

import SwiftUI
import AVFoundation

/// Vista de SwiftUI que envuelve AVCaptureVideoPreviewLayer
struct CameraPreviewView: UIViewRepresentable {
    let previewLayer: AVCaptureVideoPreviewLayer
    var onTap: ((CGPoint) -> Void)?
    var onPinch: ((CGFloat) -> Void)?
    
    func makeUIView(context: Context) -> UIView {
        let view = CameraPreviewUIView()
        view.previewLayer = previewLayer
        view.onTap = onTap
        view.onPinch = onPinch
        
        previewLayer.frame = view.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        if let cameraPreviewView = uiView as? CameraPreviewUIView {
            cameraPreviewView.onTap = onTap
            cameraPreviewView.onPinch = onPinch
        }
        
        DispatchQueue.main.async {
            previewLayer.frame = uiView.bounds
        }
    }
}

/// UIView personalizada que maneja gestos de tap y pinch
private class CameraPreviewUIView: UIView {
    var previewLayer: AVCaptureVideoPreviewLayer?
    var onTap: ((CGPoint) -> Void)?
    var onPinch: ((CGFloat) -> Void)?
    
    private var initialZoom: CGFloat = 1.0
    
    override func layoutSubviews() {
        super.layoutSubviews()
        previewLayer?.frame = bounds
    }
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        setupGestures()
    }
    
    private func setupGestures() {
        // Gesture de tap para enfocar
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        addGestureRecognizer(tapGesture)
        
        // Gesture de pinch para zoom
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        addGestureRecognizer(pinchGesture)
    }
    
    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        let point = gesture.location(in: self)
        let focusPoint = CGPoint(
            x: point.x / bounds.width,
            y: point.y / bounds.height
        )
        onTap?(focusPoint)
        
        // Mostrar indicador de enfoque
        showFocusIndicator(at: point)
    }
    
    @objc private func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        switch gesture.state {
        case .began:
            initialZoom = gesture.scale
        case .changed:
            let zoomFactor = gesture.scale / initialZoom
            onPinch?(zoomFactor)
        default:
            break
        }
    }
    
    private func showFocusIndicator(at point: CGPoint) {
        // Remover indicadores anteriores
        subviews.compactMap { $0 as? FocusIndicatorView }.forEach { $0.removeFromSuperview() }
        
        // Agregar nuevo indicador
        let focusIndicator = FocusIndicatorView()
        focusIndicator.center = point
        addSubview(focusIndicator)
        
        focusIndicator.animate()
        
        // Remover después de la animación
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            focusIndicator.removeFromSuperview()
        }
    }
}

/// Vista del indicador de enfoque
private class FocusIndicatorView: UIView {
    
    override init(frame: CGRect) {
        super.init(frame: CGRect(x: 0, y: 0, width: 80, height: 80))
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = UIColor.clear
        layer.borderWidth = 2
        layer.borderColor = UIColor.yellow.cgColor
        layer.cornerRadius = 4
        
        // Líneas internas
        let horizontalLine = UIView()
        horizontalLine.backgroundColor = UIColor.yellow
        horizontalLine.translatesAutoresizingMaskIntoConstraints = false
        addSubview(horizontalLine)
        
        let verticalLine = UIView()
        verticalLine.backgroundColor = UIColor.yellow
        verticalLine.translatesAutoresizingMaskIntoConstraints = false
        addSubview(verticalLine)
        
        NSLayoutConstraint.activate([
            // Línea horizontal
            horizontalLine.centerXAnchor.constraint(equalTo: centerXAnchor),
            horizontalLine.centerYAnchor.constraint(equalTo: centerYAnchor),
            horizontalLine.widthAnchor.constraint(equalToConstant: 20),
            horizontalLine.heightAnchor.constraint(equalToConstant: 1),
            
            // Línea vertical
            verticalLine.centerXAnchor.constraint(equalTo: centerXAnchor),
            verticalLine.centerYAnchor.constraint(equalTo: centerYAnchor),
            verticalLine.widthAnchor.constraint(equalToConstant: 1),
            verticalLine.heightAnchor.constraint(equalToConstant: 20)
        ])
    }
    
    func animate() {
        // Animación de aparición
        transform = CGAffineTransform(scaleX: 1.5, y: 1.5)
        alpha = 0
        
        UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseInOut], animations: {
            self.transform = CGAffineTransform.identity
            self.alpha = 1.0
        }) { _ in
            // Animación de desaparición
            UIView.animate(withDuration: 0.5, delay: 0.8, options: [.curveEaseInOut]) {
                self.alpha = 0
            }
        }
    }
}
