//
//  HTTScannerView.swift
//  Barcode Scanner
//
//  Created by Daniel Gump on 11/11/20.
//  Copyright 2020 HomeTown Ticketing. All Rights Reserved.
//

import AVFoundation
import UIKit
import Vision

class HTTScannerView: UIView, AVCaptureMetadataOutputObjectsDelegate, AVCaptureVideoDataOutputSampleBufferDelegate {

	//MARK: Public variables
	public weak var delegate: HTTScannerViewDelegate?
	public var stopAfterScan = true
	public var crosshairSize: CGFloat = 0.60 // range [0.0, 1.0]

	//MARK: Public getters
	public var isScannable: Bool {
		get {
			return captureSession.isRunning
		}
		set {

		}
	}

	public var hasTorch: Bool {
		get {
			return _hasTorch
		}
		set {

		}
	}

	public var torchActive: Bool {
		get {
			return _torchActive
		}
		set {
			_torchActive = !newValue
			toggleTorch()
		}
	}

	//MARK: Private variables
	private var captureSession = AVCaptureSession()
	private var previewLayer: AVCaptureVideoPreviewLayer?
	private var videoCaptureDevice: AVCaptureDevice?

	private var crosshairFrame = CGRect(origin: CGPoint.zero, size: CGSize.zero)

	private var processing = false //Throttle on slower devices
	private var _hasTorch = false
	private var _torchActive = false
	private var _metadataTypes: HTTScannerViewMetadataTypes = .any

	private var barcodeRequest: Any? //Vision framework

	//MARK: Deinitializer
	deinit {
		stop()
	}

	//MARK: Public functions
	public func show(){
		buildInterface()
	}

	public func hide(){
		stop()
	}

	public func start(forTypes: HTTScannerViewMetadataTypes) {

		_metadataTypes = forTypes

		restart()

	}

	public func restart() {

		captureSession.startRunning()

		buildInterface()
		delegate?.message(fromScanner: "Scanner started")

	}

	public func stop() {

		captureSession.stopRunning()

		if _torchActive {
			toggleTorch()
		}

		buildInterface()
		delegate?.message(fromScanner: "Scanner stopped")

	}

	public func toggleTorch(){
		if !_hasTorch {
			return
		}

		do {
			try videoCaptureDevice?.lockForConfiguration()
		} catch _ {
			delegate?.message(fromScanner: "Unable to toggle torch")
			return
		}

		_torchActive = !_torchActive
		videoCaptureDevice?.torchMode = _torchActive ? .on : .off
		delegate?.message(fromScanner: "Torch \(_torchActive ? "active" : "inactive")")

		videoCaptureDevice?.unlockForConfiguration()
	}

	//MARK: Private functions
	private func setup(){

		//Get camera details
		videoCaptureDevice = AVCaptureDevice.default(for: .video)

		if videoCaptureDevice == nil {
			delegate?.message(fromScanner: "Unable to initialize camera")
			return
		}

		_hasTorch = videoCaptureDevice!.hasTorch

		//Set up input stream
		guard let videoInput: AVCaptureDeviceInput = try? AVCaptureDeviceInput(device: videoCaptureDevice!) else {
			delegate?.message(fromScanner: "Unable to initialize video stream")
			return
		}

		//Set up AV capture session with inputs and outputs
		captureSession.beginConfiguration()
		captureSession.sessionPreset = .photo

		if captureSession.canAddInput(videoInput) {
			captureSession.addInput(videoInput)
		} else {
			delegate?.message(fromScanner: "Unable to attach input video stream")
			return
		}


		if #available(iOS 11.0, *) {

			//Set up video output stream
			let videoOutput = AVCaptureVideoDataOutput()

			if captureSession.canAddOutput(videoOutput) {
				captureSession.addOutput(videoOutput)

				videoOutput.alwaysDiscardsLateVideoFrames = true
				videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey: kCVPixelFormatType_32BGRA] as [String: Any]
				videoOutput.setSampleBufferDelegate(self, queue: .global(qos: .userInteractive))

				barcodeRequest = VNDetectBarcodesRequest(completionHandler: mlHandler)

			} else {
				delegate?.message(fromScanner: "Unable to attach barcode handling to output")
				return
			}

		} else {

			//Metadata output stream
			let metadataOutput = AVCaptureMetadataOutput()

			if captureSession.canAddOutput(metadataOutput) {
				captureSession.addOutput(metadataOutput)

				metadataOutput.setMetadataObjectsDelegate(self, queue: .global(qos: .userInteractive))
				metadataOutput.metadataObjectTypes = metadataOutput.availableMetadataObjectTypes
				//metadataOutput.metadataObjectTypes = [.aztec, .code128, .code39, .code39Mod43, .code93, .dataMatrix, .ean13, .ean8, .interleaved2of5, .itf14, .pdf417, .pdf417, .upce]

			} else {
				delegate?.message(fromScanner: "Unable to attach barcode handling to output")
				return
			}

		}

		captureSession.commitConfiguration()

		//Everything was set up successfully

		previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
		previewLayer!.videoGravity = .resizeAspectFill
		layer.addSublayer(previewLayer!)

		buildInterface()
	}

	private func buildInterface() {

		let width = min(bounds.width, bounds.height)

		//clamp crosshair size to reasonable values
		crosshairSize = max(0.0, min(1.0, crosshairSize))

		let crosshairWidth = width * crosshairSize

		//Crosshairs bounds
		crosshairFrame.size = CGSize(width: crosshairWidth, height: crosshairWidth)
		crosshairFrame.origin = CGPoint(x: 0.5 * (bounds.width - crosshairWidth), y: 0.5 * (bounds.height - crosshairWidth))

		let minX = crosshairFrame.minX
		let minY = crosshairFrame.minY
		let maxX = crosshairFrame.maxX
		let maxY = crosshairFrame.maxY


		layer.frame = bounds
		previewLayer?.frame = bounds

		//Make sure the video stream has the correct orientation
		if let connection = previewLayer?.connection {

			if connection.isVideoOrientationSupported {

				connection.videoOrientation = AVCaptureVideoOrientation(rawValue: UIApplication.shared.statusBarOrientation.rawValue) ?? .portrait

			}

		}

		while layer.sublayers!.count > 1 {
			_ = layer.sublayers?.popLast()
		}

		//Create translucent frame
		UIGraphicsBeginImageContext(layer.bounds.size)

		let framePath = UIBezierPath()

		//top
		framePath.move(to: CGPoint.zero)
		framePath.addLine(to: CGPoint(x: frame.width, y: 0.0))
		framePath.addLine(to: CGPoint(x: frame.width, y: minY))
		framePath.addLine(to: CGPoint(x: 0.0, y: minY))
		framePath.close()
		framePath.fill()

		//bottom and sides
		framePath.move(to: CGPoint(x: 0.0, y: minY))
		framePath.addLine(to: CGPoint(x: minX, y: minY))
		framePath.addLine(to: CGPoint(x: minX, y: maxY))
		framePath.addLine(to: CGPoint(x: maxX, y: maxY))
		framePath.addLine(to: CGPoint(x: maxX, y: minY))
		framePath.addLine(to: CGPoint(x: frame.width, y: minY))
		framePath.addLine(to: CGPoint(x: frame.width, y: frame.height))
		framePath.addLine(to: CGPoint(x: 0.0, y: frame.height))
		framePath.close()
		framePath.fill()

		UIGraphicsEndImageContext()

		let frameLayer = CAShapeLayer()
		frameLayer.fillColor = UIColor.white.withAlphaComponent(0.3).cgColor
		frameLayer.frame = layer.bounds
		frameLayer.path = framePath.cgPath

		layer.addSublayer(frameLayer)

		//Create crosshair
		UIGraphicsBeginImageContext(layer.bounds.size)

		let crosshairPath = UIBezierPath()

		//Top left
		crosshairPath.move(to: CGPoint(x: minX, y: 0.2 * (4.0 * minY + maxY) ) )
		crosshairPath.addLine(to: CGPoint(x: minX, y: minY) )
		crosshairPath.addLine(to: CGPoint(x: 0.2 * (4.0 * minX + maxX), y: minY) )

		//Top right
		crosshairPath.move(to: CGPoint(x: 0.2 * (minX + 4.0 * maxX), y: minY) )
		crosshairPath.addLine(to: CGPoint(x: maxX, y: minY) )
		crosshairPath.addLine(to: CGPoint(x: maxX, y: 0.2 * (4.0 * minY + maxY) ) )

		//Bottom right
		crosshairPath.move(to: CGPoint(x: maxX, y: 0.2 * (minY + 4.0 * maxY) ) )
		crosshairPath.addLine(to: CGPoint(x: maxX, y: maxY) )
		crosshairPath.addLine(to: CGPoint(x: 0.2 * (minX + 4.0 * maxX), y: maxY) )

		//Bottom left
		crosshairPath.move(to: CGPoint(x: 0.2 * (4.0 * minX + maxX), y: maxY) )
		crosshairPath.addLine(to: CGPoint(x: minX, y: maxY) )
		crosshairPath.addLine(to: CGPoint(x: minX, y: 0.2 * (minY + 4.0 * maxY) ) )

		let crosshairLayer = CAShapeLayer()
		if captureSession.isRunning {
			crosshairLayer.strokeColor = UIColor(red: 0.0, green: 0.8, blue: 0.0, alpha: 0.5).cgColor
		} else {
			crosshairLayer.strokeColor = UIColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 0.5).cgColor
		}
		crosshairLayer.fillColor = UIColor.clear.cgColor
		crosshairLayer.lineCap = .round
		crosshairLayer.lineJoin = .round
		crosshairLayer.lineWidth = 3.0
		crosshairLayer.frame = layer.bounds
		crosshairLayer.path = crosshairPath.cgPath

		UIGraphicsEndImageContext()

		layer.addSublayer(crosshairLayer)

	}



	//MARK: Initializers
	required init?(coder: NSCoder) {
		super.init(coder: coder)

		setup()
	}

	override init(frame: CGRect) {
		super.init(frame: frame)

		setup()
	}

	//MARK: Overrides
	override func layoutSubviews() {
		super.layoutSubviews()

		buildInterface()
	}

	override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {

		if captureSession.isRunning {
			stop()
		} else {
			restart()
		}

	}

	//MARK: Private functions
	private func handleResults(forBarcode: String?, ofType: String, at: CGRect){

		if ofType == "Unknown" || forBarcode == nil {
			return
		}

		if ofType == "QR Code" && _metadataTypes == .barcode {
			return
		}

		if ofType != "QR Code" && _metadataTypes == .qrcode {
			return
		}

		AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))

		DispatchQueue.main.async {

			self.delegate?.message(fromScanner: "Scanned \(ofType) \(forBarcode ?? "")")

			if ofType == "QR Code" {
				self.delegate?.found(qrCode: forBarcode!, at: at)
			} else {
				self.delegate?.found(barcode: forBarcode!, ofType: ofType, at: at)
			}

		}

	}

	//MARK: AVCaptureMetadataOutputObjectsDelegate
	func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {

		//print("AVFoundation")

		for barcode in metadataObjects {

			if let code = barcode as? AVMetadataMachineReadableCodeObject {

				var symbology = "Unknown"

				switch barcode.type {

					case .aztec:
						symbology = "Aztec"

					case .code128:
						symbology = "Code-128"

					case .code39, .code39Mod43:
						symbology = "Code-39"

					case .code93:
						symbology = "Code-93"

					case .dataMatrix:
						symbology = "Data Matrix"

					case .ean13:
						symbology = "EAN-13"

					case .ean8:
						symbology = "EAN-8"

					case .interleaved2of5:
						symbology = "Interleaved 2 of 5"

					case .itf14:
						symbology = "ITF-14"

					case .pdf417:
						symbology = "PDF-417"

					case .qr:
						symbology = "QR Code"

					case .upce:
						symbology = "UPCe"

					default:
						break

				}

				handleResults(forBarcode: code.stringValue, ofType: symbology, at: barcode.bounds)

				if stopAfterScan {
					captureSession.stopRunning()
					return
				}

			}

		}

	}

	//MARK: AVCaptureVideoDataOutputSampleBufferDelegate
	func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {

		//Throttle processing to keep UI fast
		if processing {
			return
		}

		guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
			return
		}

		processing = true

		if #available(iOS 11.0, *) {
			let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])

			do {
				if let request = barcodeRequest as? VNDetectBarcodesRequest {
						try handler.perform([request])
				}

			 } catch _ {
				 delegate?.message(fromScanner: "Error processing scan")

			 }
		}


	}


	//MARK: Process barcodes
	@available(iOS 11.0, *)
	private func mlHandler(request: VNRequest, error: Error?) {

		//print("Vision")

		processing = false

		if delegate == nil {
			return
		}

		if error != nil {
			delegate?.message(fromScanner: error!.localizedDescription)
			return
		}


		guard let results = request.results else { return }

		for result in results {

			if let barcode = result as? VNBarcodeObservation {

				if let code = barcode.payloadStringValue {

					var symbology = "Unknown"

					switch barcode.symbology {

						case .Aztec:
							symbology = "Aztec"

						case .Code128:
							symbology = "Code-128"

						case .Code39, .Code39Checksum, .Code39FullASCII, .Code39FullASCIIChecksum:
							symbology = "Code-39"

						case .Code93, .Code93i:
							symbology = "Code-93"

						case .DataMatrix:
							symbology = "Data Matrix"

						case .EAN13:
							symbology = "EAN-13"

						case .EAN8:
							symbology = "EAN-8"

						case .I2of5, .I2of5Checksum:
							symbology = "Interleaved 2 of 5"

						case .ITF14:
							symbology = "ITF-14"

						case .PDF417:
							symbology = "PDF-417"

						case .QR:
							symbology = "QR Code"

						case .UPCE:
							symbology = "UPCe"

						default:
							break

					}

					handleResults(forBarcode: code, ofType: symbology, at: barcode.boundingBox)

					if stopAfterScan {
						captureSession.stopRunning()
						return
					}

				}

			}

		}

	}

}


protocol HTTScannerViewDelegate: AnyObject {

	func found(qrCode: String, at: CGRect) -> Void
	func found(barcode: String, ofType: String, at: CGRect) -> Void
	func message(fromScanner: String) -> Void

}

extension HTTScannerViewDelegate {

	func found(barcode: String, ofType: String, at: CGRect) -> Void {

	}
	func message(fromScanner: String) -> Void {
		
	}

}

enum HTTScannerViewMetadataTypes: Int {
	case any = 0
	case barcode
	case qrcode
}
