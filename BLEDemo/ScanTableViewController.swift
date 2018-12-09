//
//  ScanTableViewController.swift
//  BLEDemo
//
//  Created by Kunal Malhotra on 12/9/18.
//  Copyright © 2018 Kunal Malhotra. All rights reserved.
//

import UIKit
import CoreBluetooth
import CocoaMQTT

class ScanTableViewController: UITableViewController, CBCentralManagerDelegate {
    
    var peripherals:[CBPeripheral] = []
    var manager:CBCentralManager? = nil
    var parentView:ViewController? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        scanBLEDevices()
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return peripherals.count
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "scanTableCell", for: indexPath)
        let peripheral = peripherals[indexPath.row]
        cell.textLabel?.text = peripheral.name
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let peripheral = peripherals[indexPath.row]
        
        manager?.connect(peripheral, options: nil)
    }
    
    // MARK: BLE Scanning
    func scanBLEDevices() {
        manager?.scanForPeripherals(withServices: [CBUUID.init(string: parentView!.BLEService)], options: nil)
        
        //stop scanning after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.stopScanForBLEDevices()
        }
    }
    
    func stopScanForBLEDevices() {
        manager?.stopScan()
    }
    
    // MARK: - CBCentralManagerDelegate Methods
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if(!peripherals.contains(peripheral)) {
            peripherals.append(peripheral)
        }
        
        self.tableView.reloadData()
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        print(central.state)
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        
        
        //pass reference to connected peripheral to parent view
        parentView?.mainPeripheral = peripheral
        peripheral.delegate = parentView
        peripheral.discoverServices(nil)
        
        //set the manager's delegate view to parent so it can call relevant disconnect methods
        manager?.delegate = parentView
        parentView?.customiseNavigationBar()
        
        if let navController = self.navigationController {
            navController.popViewController(animated: true)
        }
        
        print("Connected to " +  peripheral.name!)
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print(error!)
    }
    
}
