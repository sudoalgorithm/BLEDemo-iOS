//
//  ViewController.swift
//  BLEDemo
//
//  Created by Kunal Malhotra on 12/9/18.
//  Copyright © 2018 Kunal Malhotra. All rights reserved.
//

import UIKit
import CoreBluetooth
import MQTTFramework

class ViewController: UIViewController, CBCentralManagerDelegate, CBPeripheralDelegate, MQTTSessionManagerDelegate {
    var manager:CBCentralManager? = nil
    var mainPeripheral:CBPeripheral? = nil
    var mainCharacteristic:CBCharacteristic? = nil
    var recievedData = "" // recieved data chunk
    var stringValue = ""  // final string of data
    var time: Date!
    var date: Date!
    var dateFormatter: DateFormatter!
    var timeFormatter: DateFormatter!
    
    @IBOutlet weak var recievedMessageText: UITextView!
    let BLEService = "6E400001-B5A3-F393-E0A9-E50E24DCCA9E" //UART service
    let BLECharacteristic = "6E400003-B5A3-F393-E0A9-E50E24DCCA9E" //RX characteristic
    
    let mqtt = MQTTSessionManager()
    
    //CHANGE THESE TO INFORMATION FROM WATSON IOT
    let ORG_ID = "flstl1"//organization ID
    let ioTHostBase = "messaging.internetofthings.ibmcloud.com"//IoT host address
    let DEV_TYPE = "type01" //device type
    let DEV_ID = "dev01"    //device ID
    let IOT_API_KEY = "abcdefg"// API key that is found in the IoT service credentials
    let IOT_AUTH_TOKEN = "abcdefg"// API token that is found in the IoT service credentials
    let TOPIC = "iot-2/type/type01/id/dev01/evt/status/fmt/json"
    
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        connectToIoT()
        
        
        manager = CBCentralManager(delegate: self, queue: nil);
        
        customiseNavigationBar()
    }
    
    func customiseNavigationBar () {
        
        self.navigationItem.rightBarButtonItem = nil
        
        let rightButton = UIButton()
        
        if (mainPeripheral == nil) {
            rightButton.setTitle("Scan", for: [])
            rightButton.setTitleColor(UIColor.blue, for: [])
            rightButton.frame = CGRect(origin: CGPoint(x: 0,y :0), size: CGSize(width: 60, height: 30))
            rightButton.addTarget(self, action: #selector(self.scanButtonPressed), for: .touchUpInside)
        } else {
            rightButton.setTitle("Disconnect", for: [])
            rightButton.setTitleColor(UIColor.blue, for: [])
            rightButton.frame = CGRect(origin: CGPoint(x: 0,y :0), size: CGSize(width: 100, height: 30))
            rightButton.addTarget(self, action: #selector(self.disconnectButtonPressed), for: .touchUpInside)
        }
        
        let rightBarButton = UIBarButtonItem()
        rightBarButton.customView = rightButton
        self.navigationItem.rightBarButtonItem = rightBarButton
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if (segue.identifier == "scan-segue") {
            let scanController : ScanTableViewController = segue.destination as! ScanTableViewController
            
            //set the manager's delegate to the scan view so it can call relevant connection methods
            manager?.delegate = scanController
            scanController.manager = manager
            scanController.parentView = self
        }
        
    }
    
    // MARK: Button Methods
    func scanButtonPressed() {
        performSegue(withIdentifier: "scan-segue", sender: nil)
    }
    
    func disconnectButtonPressed() {
        //this will call didDisconnectPeripheral, but if any other apps are using the device it will not immediately disconnect
        manager?.cancelPeripheralConnection(mainPeripheral!)
    }
    
    
    
    // MARK: - CBCentralManagerDelegate Methods
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        mainPeripheral = nil
        customiseNavigationBar()
        print("Disconnected" + peripheral.name!)
    }
    
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        print(central.state)
    }
    
    // MARK: CBPeripheralDelegate Methods
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        
        for service in peripheral.services! {
            
            print("Service found with UUID: " + service.uuid.uuidString)
            
            //device information service
            if (service.uuid.uuidString == "180A") {
                peripheral.discoverCharacteristics(nil, for: service)
            }
            
            //GAP (Generic Access Profile) for Device Name
            // This replaces the deprecated CBUUIDGenericAccessProfileString
            if (service.uuid.uuidString == "1800") {
                peripheral.discoverCharacteristics(nil, for: service)
            }
            
            //Bluefruit Service
            if (service.uuid.uuidString == BLEService) {
                peripheral.discoverCharacteristics(nil, for: service)
            }
            
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        
        //get device name
        if (service.uuid.uuidString == "1800") {
            
            for characteristic in service.characteristics! {
                
                if (characteristic.uuid.uuidString == "2A00") {
                    peripheral.readValue(for: characteristic)
                    print("Found Device Name Characteristic")
                }
                
            }
            
        }
        
        if (service.uuid.uuidString == "180A") {
            
            for characteristic in service.characteristics! {
                
                if (characteristic.uuid.uuidString == "2A29") {
                    peripheral.readValue(for: characteristic)
                    print("Found a Device Manufacturer Name Characteristic")
                } else if (characteristic.uuid.uuidString == "2A23") {
                    peripheral.readValue(for: characteristic)
                    print("Found System ID")
                }
                
            }
            
        }
        
        if (service.uuid.uuidString == BLEService) {
            
            for characteristic in service.characteristics! {
                
                if (characteristic.uuid.uuidString == BLECharacteristic) {
                    //we'll save the reference, we need it to write data
                    mainCharacteristic = characteristic
                    
                    //Set Notify is useful to read incoming data async
                    peripheral.setNotifyValue(true, for: characteristic)
                    print("Found bluefruit Data Characteristic")
                    
                }
                
            }
            
        }
        
    }
    //this method gets called whenever the value of the RX changes
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if (characteristic.uuid.uuidString == "2A00") {
            //value for device name recieved
            let deviceName = characteristic.value
            print(deviceName ?? "No Device Name")
        } else if (characteristic.uuid.uuidString == "2A29") {
            //value for manufacturer name recieved
            let manufacturerName = characteristic.value
            print(manufacturerName ?? "No Manufacturer Name")
        } else if (characteristic.uuid.uuidString == "2A23") {
            //value for system ID recieved
            let systemID = characteristic.value
            print(systemID ?? "No System ID")
        } else if (characteristic.uuid.uuidString == BLECharacteristic) {
            
            //data recieved
            if(characteristic.value != nil) {
                recievedData = String(data: characteristic.value!, encoding: String.Encoding.utf8) as String!
                
                // the methods below are simply meant to print out the date and time the data was recieved
                date = Date()
                time = Date()
                dateFormatter = DateFormatter()
                timeFormatter = DateFormatter()
                dateFormatter.dateFormat = "dd/MM/yy"
                timeFormatter.dateFormat = "hh:mm"
                let dateString = dateFormatter.string(from: date)
                let timeString = timeFormatter.string(from: time)
                
                
                //check if the data chunk contains char "a" signaling the last data chunk
                if (recievedData.contains("a")){
                    
                    // remove char "a" and add data chunk to the string value
                    recievedData = recievedData.replacingOccurrences(of: "a", with: "")
                    stringValue += recievedData
                    
                    
                    //write the final string on the label
                    recievedMessageText.text =
                        recievedMessageText.text+dateString+"  "+timeString+"\n"+stringValue+"\n"
                    
                    
                    //send final string to IoT platform
                    mqtt.send(stringValue.data(using: String.Encoding.utf8), topic: TOPIC, qos: MQTTQosLevel.exactlyOnce, retain: false)
                    
                    print(stringValue)
                    //clear string value for next reading
                    stringValue=""
                    recievedData=""
                    
                }
                    
                else{
                    //if the data chunk isn't the last, append data chunk to string value
                    stringValue.append(recievedData)
                }
                
            }
        }
        
        
    }
    
    func connectToIoT(){
        if (mqtt.state != MQTTSessionManagerState.connected) {
            let host = ORG_ID + "." + ioTHostBase
            let clientId = "a:" + ORG_ID + ":" + IOT_API_KEY
            
            NSLog("current mqtt topic: " + TOPIC)
            mqtt.connect(
                to: host,
                port: 1883,
                tls: false,
                keepalive: 60,
                clean: true,
                auth: true,
                user: IOT_API_KEY,
                pass: IOT_AUTH_TOKEN,
                will: false,
                willTopic: nil,
                willMsg: nil,
                willQos: MQTTQosLevel.atMostOnce,
                willRetainFlag: false,
                withClientId: clientId)
            
            // Wait for the session to connect
            while mqtt.state != MQTTSessionManagerState.connected {
                NSLog("waiting for connect " + (mqtt.state).hashValue.description)
                RunLoop.current.run(until: NSDate(timeIntervalSinceNow: 1) as Date)
            }
            
            NSLog("connected")
            
            
        }
        
    }
}
