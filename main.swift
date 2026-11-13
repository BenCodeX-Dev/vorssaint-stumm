// Mutes the default output device whenever its volume reaches 0, like macOS does.
// Vorssaint's "Use finer volume steps" sets the volume to 0 without muting, and the
// MacBook speakers still play at -63.5 dB there. Unmutes again only if this tool muted.
import AudioToolbox
import CoreAudio
import Foundation

let zero: Float32 = 0.001
let queue = DispatchQueue(label: "vorssaint-stumm")
var device = AudioDeviceID(0)
var watched = Set<AudioDeviceID>()
var autoMuted = false

func address(_ selector: AudioObjectPropertySelector,
             _ element: AudioObjectPropertyElement = kAudioObjectPropertyElementMain,
             scope: AudioObjectPropertyScope = kAudioDevicePropertyScopeOutput) -> AudioObjectPropertyAddress {
    AudioObjectPropertyAddress(mSelector: selector, mScope: scope, mElement: element)
}

func log(_ text: String) {
    print("\(Date()) \(text)")
    fflush(stdout)
}

func defaultOutput() -> AudioDeviceID {
    var id = AudioDeviceID(0)
    var size = UInt32(MemoryLayout<AudioDeviceID>.size)
    var a = address(kAudioHardwarePropertyDefaultOutputDevice, scope: kAudioObjectPropertyScopeGlobal)
    AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &a, 0, nil, &size, &id)
    return id
}

func volume(_ dev: AudioDeviceID) -> Float32? {
    var a = address(kAudioHardwareServiceDeviceProperty_VirtualMainVolume)
    var value = Float32(0)
    var size = UInt32(MemoryLayout<Float32>.size)
    guard AudioObjectHasProperty(dev, &a),
          AudioObjectGetPropertyData(dev, &a, 0, nil, &size, &value) == noErr else { return nil }
    return value
}

// Some devices only have per-channel mute (elements 1 and 2), not a main one.
func muteElements(_ dev: AudioDeviceID) -> [AudioObjectPropertyElement] {
    for group in [[kAudioObjectPropertyElementMain], [1, 2]] as [[AudioObjectPropertyElement]] {
        let found = group.filter { element in
            var a = address(kAudioDevicePropertyMute, element)
            var settable = DarwinBoolean(false)
            return AudioObjectHasProperty(dev, &a)
                && AudioObjectIsPropertySettable(dev, &a, &settable) == noErr && settable.boolValue
        }
        if !found.isEmpty { return found }
    }
    return []
}

func isMuted(_ dev: AudioDeviceID) -> Bool? {
    guard let element = muteElements(dev).first else { return nil }
    var a = address(kAudioDevicePropertyMute, element)
    var value = UInt32(0)
    var size = UInt32(MemoryLayout<UInt32>.size)
    guard AudioObjectGetPropertyData(dev, &a, 0, nil, &size, &value) == noErr else { return nil }
    return value != 0
}

func setMuted(_ dev: AudioDeviceID, _ on: Bool) {
    var value = UInt32(on ? 1 : 0)
    for element in muteElements(dev) {
        var a = address(kAudioDevicePropertyMute, element)
        AudioObjectSetPropertyData(dev, &a, 0, nil, UInt32(MemoryLayout<UInt32>.size), &value)
    }
}

func check() {
    guard let level = volume(device), let muted = isMuted(device) else { return }
    if level <= zero {
        if !muted {
            setMuted(device, true)
            autoMuted = true
            log("volume 0, muted device \(device)")
        }
    } else if autoMuted {
        if muted {
            setMuted(device, false)
            log("volume \(level), unmuted device \(device)")
        }
        autoMuted = false
    }
}

// Listeners stay on every device seen; callbacks for a device that is no longer the default do nothing.
func watch(_ dev: AudioDeviceID) {
    guard !watched.contains(dev) else { return }
    watched.insert(dev)
    let listener: AudioObjectPropertyListenerBlock = { _, _ in
        if dev == device { check() }
    }
    var targets = [address(kAudioHardwareServiceDeviceProperty_VirtualMainVolume)]
    for element: AudioObjectPropertyElement in [kAudioObjectPropertyElementMain, 1, 2] {
        targets.append(address(kAudioDevicePropertyVolumeScalar, element))
        targets.append(address(kAudioDevicePropertyMute, element))
    }
    for var a in targets {
        if AudioObjectHasProperty(dev, &a) {
            AudioObjectAddPropertyListenerBlock(dev, &a, queue, listener)
        }
    }
}

func follow() {
    let current = defaultOutput()
    if current != device {
        device = current
        autoMuted = false
        watch(device)
    }
    check()
}

var defaultAddress = address(kAudioHardwarePropertyDefaultOutputDevice, scope: kAudioObjectPropertyScopeGlobal)
AudioObjectAddPropertyListenerBlock(AudioObjectID(kAudioObjectSystemObject), &defaultAddress, queue) { _, _ in follow() }
queue.async { follow() }
log("started")
dispatchMain()
