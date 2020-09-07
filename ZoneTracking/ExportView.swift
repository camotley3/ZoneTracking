//
//  ExportView.swift
//  ZoneTracking
//
//  Created by Yasir Iqbal on 07/09/2020.
//  Copyright © 2020 Yasir Iqbal. All rights reserved.
//

import UIKit

class ExportView: UIView {
    
    private let labelTitle : UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.boldSystemFont(ofSize: 16)
        label.text = "Export Info"
        label.textColor = UIColor.white
        return label
    }()
    
    let txtInfo : UITextView = {
        let textView = UITextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.font = UIFont.systemFont(ofSize: 12)
        textView.isEditable = false
        textView.isSelectable = true
        return textView
    }()
    
    lazy var btnExport : UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Export", for: .normal)
        button.addTarget(self, action: #selector(funcExport), for: .touchUpInside)
        return button
    }()
    
    lazy var btnCancel : UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Cancel", for: .normal)
        button.addTarget(self, action: #selector(funcCancel), for: .touchUpInside)
        return button
    }()
    
    
    weak var vc : ViewController!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.backgroundColor = UIColor.blue
        
        self.addSubview(self.labelTitle)
        self.labelTitle.topAnchor.constraint(equalTo: self.topAnchor, constant: 8).isActive = true
        self.labelTitle.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
        
        
        self.addSubview(self.txtInfo)
        self.txtInfo.topAnchor.constraint(equalTo: self.labelTitle.bottomAnchor, constant: 8).isActive = true
        self.txtInfo.leadingAnchor.constraint(equalTo: self.leadingAnchor).isActive = true
        self.txtInfo.trailingAnchor.constraint(equalTo: self.trailingAnchor).isActive = true
        
        self.addSubview(self.btnExport)
        self.btnExport.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 16).isActive = true
        self.btnExport.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        
        self.addSubview(self.btnCancel)
        self.btnCancel.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -16).isActive = true
        self.btnCancel.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        
        self.txtInfo.bottomAnchor.constraint(equalTo: self.btnCancel.topAnchor, constant: -4).isActive = true
        
    }
    
    @objc func funcExport() {
        self.vc.export()
        self.isHidden = true
    }
    
    @objc func funcCancel() {
        self.isHidden = true
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
}
