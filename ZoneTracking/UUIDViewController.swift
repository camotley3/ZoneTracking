//
//  UUIDViewController.swift
//  ZoneTracking
//
//  Created by Yasir Iqbal on 14/08/2020.
//  Copyright © 2020 Yasir Iqbal. All rights reserved.
//

import UIKit
import KeychainSwift
import RealmSwift

class UUIDViewController: UIViewController {
    
    @IBOutlet weak var btn_proceedOld: UIButton!
    @IBOutlet weak var lbl_uuid: UILabel!
    
    let realm = try! Realm()
    
    let keychain = KeychainSwift()
    var deviceID : String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.deviceID = self.keychain.get("uuid")
        
        if self.deviceID != nil {
            self.lbl_uuid.text = self.deviceID!
        }
        else {
            self.deviceID = UUID().uuidString
            self.keychain.set(self.deviceID, forKey: "uuid")
            self.lbl_uuid.text = self.deviceID!
        }
        
        self.btn_proceedOld.setTitle("Proceed - Append - \(self.realm.objects(LogRow.self).count)", for: .normal)
        
    }
    
    
    @IBAction func btn_new(_ sender: UIButton) {
        
        let objects = self.realm.objects(LogRow.self)
        try! self.realm.write {
            self.realm.delete(objects)
        }
        
        self.performSegue(withIdentifier: "sw_track", sender: nil)
    }
    
    @IBAction func btn_old(_ sender: UIButton) {
        self.performSegue(withIdentifier: "sw_track", sender: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "sw_track" {
            let destVC = segue.destination as! ViewController
            destVC.deviceID = self.deviceID
        }
    }

}
