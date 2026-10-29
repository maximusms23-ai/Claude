// battery_info.swift — shortcuts-forge Helper (Swift)
//
// Zweck:
//     Liefert Batterie-Status als einzeiliges JSON auf stdout.
//     Referenz fuer Swift-Helper mit echtem macOS-Framework (IOKit).
//
// Build (via bin/build-shortcut-helpers):
//     swiftc -O battery_info.swift -o build/battery_info
//     codesign --force --sign - build/battery_info
//
// Usage (aus Kurzbefehl via "Run Shell Script"):
//     "$HOME/Documents/Tom-Shortcuts/helpers/swift/build/battery_info"
//
// Output:
//     {"percent":87,"charging":false,"source":"Battery Power"}
//     Bei Desktop ohne Batterie: {"percent":-1,"charging":false,"source":"AC Power"}

import Foundation
import IOKit.ps

func fail(_ message: String) -> Never {
    FileHandle.standardError.write(Data("battery_info: \(message)\n".utf8))
    exit(1)
}

guard let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue() else {
    fail("IOPSCopyPowerSourcesInfo fehlgeschlagen")
}
guard let sources = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as? [CFTypeRef] else {
    fail("IOPSCopyPowerSourcesList fehlgeschlagen")
}

let providing = IOPSGetProvidingPowerSourceType(snapshot)?.takeRetainedValue() as String? ?? "Unknown"

var percent = -1
var charging = false

for source in sources {
    guard let info = IOPSGetPowerSourceDescription(snapshot, source)?.takeUnretainedValue() as? [String: Any] else {
        continue
    }
    if let capacity = info[kIOPSCurrentCapacityKey as String] as? Int,
       let max = info[kIOPSMaxCapacityKey as String] as? Int, max > 0 {
        percent = Int((Double(capacity) / Double(max)) * 100.0)
    }
    if let isCharging = info[kIOPSIsChargingKey as String] as? Bool {
        charging = isCharging
    }
}

let payload: [String: Any] = ["percent": percent, "charging": charging, "source": providing]
guard let data = try? JSONSerialization.data(withJSONObject: payload, options: [.sortedKeys]),
      let json = String(data: data, encoding: .utf8) else {
    fail("JSON-Serialisierung fehlgeschlagen")
}
print(json)
