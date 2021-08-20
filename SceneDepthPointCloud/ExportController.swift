//
//  ExportController.swift
//  SceneDepthPointCloud

import SwiftUI
import Foundation


class ExportController : UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {
    private var exportData = [URL]()
    private var selectedExport: URL?
    private var selectedExportIdx : Int?
    private let deleteButton = UIButton(type: .system)
    private let exportButton = UIButton(type: .system)
    private let exportPicker = UIPickerView()
    private let goToSaveCurrentViewButton = UIButton(type: .system)
    private let mainImage = UIImageView()
    private let exportLabel = UILabel()
    var mainController: MainController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        mainController.renderer.loadSavedClouds()
        exportData = mainController.renderer.savedCloudURLs
        
        goToSaveCurrentViewButton.setTitle("Go To Current Scan", for: .normal)
        goToSaveCurrentViewButton.tintColor = .cyan
        goToSaveCurrentViewButton.setImage(.init(systemName: "arrow.down.doc"), for: .normal)
        goToSaveCurrentViewButton.translatesAutoresizingMaskIntoConstraints = false
        goToSaveCurrentViewButton.addTarget(self, action: #selector(goToCurrentScan), for: .touchUpInside)
        view.addSubview(goToSaveCurrentViewButton)
        
        mainImage.image = .init(systemName: "square.and.arrow.up.on.square")
        mainImage.tintColor = .darkGray
        mainImage.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(mainImage)
        
        exportLabel.text = "Saved Scans: \(exportData.count) found"
        exportLabel.translatesAutoresizingMaskIntoConstraints = false
        exportLabel.textColor = .white
        view.addSubview(exportLabel)
        
        exportPicker.delegate = self
        exportPicker.dataSource = self
        exportPicker.translatesAutoresizingMaskIntoConstraints = false
        if !exportData.isEmpty {
            exportPicker.delegate?.pickerView?(exportPicker, didSelectRow: 0, inComponent: 0)
        }
        view.addSubview(exportPicker)
        
        exportButton.tintColor = .green
        exportButton.setTitle("Export Selectted Scan", for: .normal)
        exportButton.setImage(.init(systemName: "square.and.arrow.up"), for: .normal)
        exportButton.translatesAutoresizingMaskIntoConstraints = false
        exportButton.addTarget(self, action: #selector(executeExport), for: .touchUpInside)
        view.addSubview(exportButton)
        
        deleteButton.tintColor = .red
        deleteButton.setTitle("Delete Selected Scan", for: .normal)
        deleteButton.setImage(.init(systemName: "trash.slash"), for: .normal)
        deleteButton.translatesAutoresizingMaskIntoConstraints = false
        deleteButton.addTarget(self, action: #selector(executeDelete), for: .touchUpInside)
        view.addSubview(deleteButton)
        
        NSLayoutConstraint.activate([
            exportLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 50),
            exportLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            mainImage.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -150),
            mainImage.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            mainImage.widthAnchor.constraint(equalToConstant: 300),
            mainImage.heightAnchor.constraint(equalToConstant: 300),
            
            exportButton.widthAnchor.constraint(equalToConstant: 250),
            exportButton.heightAnchor.constraint(equalToConstant: 50),
            exportButton.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: 50),
            exportButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            deleteButton.widthAnchor.constraint(equalToConstant: 250),
            deleteButton.heightAnchor.constraint(equalToConstant: 50),
            deleteButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -100),
            deleteButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            exportPicker.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            exportPicker.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: 150),
            
            goToSaveCurrentViewButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -50),
            goToSaveCurrentViewButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int { return 1 }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return exportData.count
    }
    func pickerView(_ pickerView: UIPickerView,titleForRow row: Int, forComponent component: Int) -> String? {
        return exportData[row].lastPathComponent
        
    }
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        selectedExportIdx = row
        selectedExport = !exportData.isEmpty ? exportData[row] : nil
    }
   
    func onSaveError(error: XError) {
        dismissModal()
        mainController.onSaveError(error: error)
    }
        
    func dismissModal() { self.dismiss(animated: true, completion: nil) }
    
    @objc func executeExport() {
        guard selectedExport != nil else { return }
        dismissModal()
        mainController.export(url: selectedExport!)
    }
    
    @objc func goToCurrentScan() {
        dismissModal()
        mainController.goToSaveCurrentScanView()
    }
    
    @objc func executeDelete() -> Void {
        guard selectedExport != nil else { return }

        try! FileManager.default.removeItem(at: selectedExport!)
        mainController.renderer.savedCloudURLs.remove(at: selectedExportIdx!)
        exportData.remove(at: selectedExportIdx!)
        exportPicker.reloadAllComponents()
        
        if selectedExportIdx == 0  {
            exportPicker.delegate?.pickerView?(exportPicker, didSelectRow: 0, inComponent: 0)
        } else if selectedExportIdx == exportData.count {
            exportPicker.delegate?.pickerView?(exportPicker, didSelectRow: selectedExportIdx!-1, inComponent: 0)
        } else {
            exportPicker.delegate?.pickerView?(exportPicker, didSelectRow: selectedExportIdx!, inComponent: 0)
        }
        
        exportLabel.text = "Saved Scans: \(exportData.count) found"
    }
}
