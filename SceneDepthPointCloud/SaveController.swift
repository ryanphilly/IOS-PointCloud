//
//  SaveController.swift
//  SceneDepthPointCloud

import SwiftUI
import Foundation

class SaveController : UIViewController, UIPickerViewDelegate, UIPickerViewDataSource, UITextFieldDelegate {
    private var formatData: [String] = ["Ascii", "Binary Little Endian", "Binary Big Endian"]
    private var exportData = [URL]()
    private var selectedFormat: String?
    private let mainImage = UIImageView(image: .init(named: "save"))
    private let formatPicker = UIPickerView()
    private let spinner = UIActivityIndicatorView(style: .large)
    private let saveCurrentButton = UIButton(type: .system)
    private let goToExportViewButton = UIButton(type: .system)
    private let saveCurrentScanLabel = UILabel()
    private let fileTypeWarning = UILabel()
    private let fileNameInput = UITextField()
    var mainController: MainController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        fileTypeWarning.text = "Only supports .ply file format."
        fileTypeWarning.translatesAutoresizingMaskIntoConstraints = false
        fileTypeWarning.textColor = .white
        view.addSubview(fileTypeWarning)
        
        mainImage.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(mainImage)
        
        formatPicker.delegate = self
        formatPicker.dataSource = self
        formatPicker.translatesAutoresizingMaskIntoConstraints =  false
        formatPicker.delegate?.pickerView?(formatPicker, didSelectRow: 0, inComponent: 0)
        view.addSubview(formatPicker)
        
        fileNameInput.delegate = self
        fileNameInput.isUserInteractionEnabled = true
        fileNameInput.translatesAutoresizingMaskIntoConstraints = false
        fileNameInput.placeholder = "File Name"
        fileNameInput.borderStyle = .roundedRect
        fileNameInput.autocorrectionType = .no
        fileNameInput.returnKeyType = .done
        fileNameInput.backgroundColor = .systemBackground
        view.addSubview(fileNameInput)
        
        saveCurrentScanLabel.text = "Current Scan: \(mainController.renderer.highConfCount) points"
        saveCurrentScanLabel.translatesAutoresizingMaskIntoConstraints = false
        saveCurrentScanLabel.textColor = .white
        view.addSubview(saveCurrentScanLabel)

        spinner.color = .white
        spinner.backgroundColor = .clear
        spinner.hidesWhenStopped = true
        spinner.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(spinner)
        
        saveCurrentButton.tintColor = .green
        saveCurrentButton.setTitle("Save Current Scan", for: .normal)
        saveCurrentButton.setImage(.init(systemName: "arrow.down.doc"), for: .normal)
        saveCurrentButton.translatesAutoresizingMaskIntoConstraints = false
        saveCurrentButton.addTarget(self, action: #selector(executeSave), for: .touchUpInside)
        view.addSubview(saveCurrentButton)
        
        goToExportViewButton.tintColor = .cyan
        goToExportViewButton.setTitle("Previously Saved Scans", for: .normal)
        goToExportViewButton.setImage(.init(systemName: "tray.full"), for: .normal)
        goToExportViewButton.translatesAutoresizingMaskIntoConstraints = false
        goToExportViewButton.addTarget(self, action: #selector(goToExportView), for: .touchUpInside)
        view.addSubview(goToExportViewButton)
        
        NSLayoutConstraint.activate([
            formatPicker.heightAnchor.constraint(equalToConstant: 225),
            formatPicker.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -200),
            formatPicker.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            fileNameInput.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            fileNameInput.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            fileNameInput.widthAnchor.constraint(equalToConstant: 250),
            fileNameInput.heightAnchor.constraint(equalToConstant: 45),
            
            mainImage.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -185),
            mainImage.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: 20),
            mainImage.widthAnchor.constraint(equalToConstant: 300),
            mainImage.heightAnchor.constraint(equalToConstant: 300),
            
            saveCurrentScanLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            saveCurrentScanLabel.bottomAnchor.constraint(equalTo: view.topAnchor, constant: 50),
            
            spinner.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -50),
            
            fileTypeWarning.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            fileTypeWarning.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -120),
            
            saveCurrentButton.widthAnchor.constraint(equalToConstant: 150),
            saveCurrentButton.heightAnchor.constraint(equalToConstant: 50),
            saveCurrentButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            saveCurrentButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -165),
            
            goToExportViewButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -50),
            goToExportViewButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }
    
    /// Text field delegate methods
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool { return true }
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return false
    }
    
    /// Picker delegate methods
    func numberOfComponents(in pickerView: UIPickerView) -> Int { return 1 }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int { return formatData.count }
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? { return formatData[row] }
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) { selectedFormat = formatData[row] }
   
    func onSaveError(error: XError) {
        dismissModal()
        mainController.onSaveError(error: error)
    }
        
    func dismissModal() { self.dismiss(animated: true, completion: nil) }
    
    private func beforeSave() {
        goToExportViewButton.isEnabled = false
        saveCurrentButton.isEnabled = false
        isModalInPresentation = true
    }
    
    @objc func goToExportView() -> Void {
        dismissModal()
        mainController.goToExportView()
    }
        
    @objc func executeSave() -> Void {
        let fileName = !fileNameInput.text!.isEmpty ? fileNameInput.text : "untitled"
        let format = selectedFormat!
            .lowercased(with: .none)
            .split(separator: " ")
            .joined(separator: "_")
        
        mainController.renderer.saveAsPlyFile(
            fileName: fileName!,
            beforeGlobalThread: [beforeSave, spinner.startAnimating],
            afterGlobalThread: [dismissModal, spinner.stopAnimating, mainController.afterSave],
            errorCallback: onSaveError,
            format: format)
    }
    
}

