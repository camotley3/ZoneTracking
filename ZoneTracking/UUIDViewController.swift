//
//  UUIDViewController.swift
//  ZoneTracking
//
//  Created by Yasir Iqbal on 14/08/2020.
//  Copyright © 2020 Yasir Iqbal. All rights reserved.
//

import UIKit
import KeychainSwift

class UUIDViewController: UIViewController {
    
    @IBOutlet weak var lbl_uuid: UILabel!
    
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
        
    }
    
    
    @IBAction func btn_proceed(_ sender: UIButton) {
        self.performSegue(withIdentifier: "sw_track", sender: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "sw_track" {
            let destVC = segue.destination as! ViewController
            destVC.deviceID = self.deviceID
        }
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
