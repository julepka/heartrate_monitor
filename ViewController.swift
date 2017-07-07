

import UIKit
import CoreBluetooth

class ViewController: UIViewController, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    // comment this line if you do not have a label in your controller to display a heartrate
    @IBOutlet weak var label: UILabel!
    
    var centralManager:CBCentralManager!
    var connectingPeripheral:CBPeripheral!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        centralManager = CBCentralManager(delegate: self, queue: DispatchQueue.main)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    // MARK: - CentralManager (iPhone)
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state{
        case .poweredOn:
            print("poweredOn")
            
            let serviceUUIDs:[CBUUID] = [CBUUID(string: "180D")]
            let lastPeripherals = centralManager.retrieveConnectedPeripherals(withServices: serviceUUIDs)
            
            if lastPeripherals.count > 0 {
                let device = lastPeripherals.last
                connectingPeripheral = device;
                centralManager.connect(connectingPeripheral, options: nil)
            }
            else {
                centralManager.scanForPeripherals(withServices: serviceUUIDs, options: nil)
            }
            
        default:
            print(central.state)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        connectingPeripheral = peripheral
        connectingPeripheral.delegate = self
        centralManager.connect(connectingPeripheral, options: nil)
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.discoverServices(nil)
    }
    
    // MARK: - Peripheral (HeartRateMonitor)
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if error != nil {
            print(error?.localizedDescription ?? "Error on didDiscoverServices method")
            return
        }
        for service in peripheral.services as [CBService]!{
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if error != nil {
            print(error?.localizedDescription ?? "Error on didDiscoverCharacteristics method")
            return
        }
        if service.uuid == CBUUID(string: "180D"){
            if let characteristics = service.characteristics {
                for characteristic in characteristics {
                    switch characteristic.uuid.uuidString{
                        
                    case "2A37":
                        // Set notification on heart rate measurement
                        print("Found a Heart Rate Measurement Characteristic")
                        peripheral.setNotifyValue(true, for: characteristic)
                        
                    case "2A38":
                        // Read body sensor location
                        print("Found a Body Sensor Location Characteristic")
                        peripheral.readValue(for: characteristic)
                        
                    default: break

                    }
                    
                }
            }
        }
    }
    
    func update(heartRateData: Data){
        
        var buffer = [UInt8](heartRateData)
        
        var bpm: UInt16?
        if (buffer.count >= 2) {
            if (buffer[0] & 0x01 == 0) {
                bpm = UInt16(buffer[1])
            } else {
                bpm = UInt16(buffer[1]) << 8
                bpm =  bpm! | UInt16(buffer[2])
            }
        }
        
        if let actualBpm = bpm {
            print(actualBpm)
            label.text = "\(actualBpm)"
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if error != nil {
            print(error?.localizedDescription ?? "Error on didUpdateValue method")
            return
        }
        switch characteristic.uuid.uuidString{
        case "2A37":
            if let value = characteristic.value {
                update(heartRateData: value)
            }
            
        default: break
            
        }
    }

}

