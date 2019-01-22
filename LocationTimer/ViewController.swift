//
//  ViewController.swift
//  LocationTimer
//
//  Created by 罗泰 on 2019/1/21.
//  Copyright © 2019 chenwang. All rights reserved.
//

import UIKit
import CoreLocation

var i: Int = 0
let timeInterval: Int = 5 * 60

class ViewController: UIViewController {
    @IBOutlet weak var textView: UITextView!
    lazy var manager: LocationCenter = {
        let temp = LocationCenter.init()
        temp.textView = self.textView
        return temp
    }()
    //MARK: - 生命周期
    override func viewDidLoad() {
        super.viewDidLoad()
        self.textView.isEditable = false
        self.manager.startUpdaingLocation()
    }
    
    @IBAction func stopClick() {
        self.manager.stopUpdaingLocation()
    }
    
    @IBAction func beginClick() {
        self.manager.startUpdaingLocation()
    }
    
    @IBAction func clearClick() {
        self.manager.clearAllText()
    }
}



/// LocationCenter
class LocationCenter: NSObject {
    lazy var locationManager: CLLocationManager = {
        let pro = CLLocationManager.init()
        pro.allowsBackgroundLocationUpdates = true
        pro.desiredAccuracy = kCLLocationAccuracyBest
        pro.pausesLocationUpdatesAutomatically = false
        pro.distanceFilter = 0.01
        pro.delegate = self
        return pro
    }()
    
    var textView: UITextView!
    var timer: Timer? = nil
    var backgroundTaskId: UIBackgroundTaskIdentifier = UIBackgroundTaskIdentifier.invalid
    override init() {
        super.init()
        self.addNotification()
    }
    
    deinit {
        self.removeNotification()
    }
}



// MARK: - CLLocationManagerDelegate
extension LocationCenter: CLLocationManagerDelegate {
    /// 获取定位代理回调
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        manager.stopUpdatingLocation()
        if let location = locations.first
        {
            self.locaitonHandle(location)
        }
    }
    
    
    /// 用户权限变更回调代理
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        print("位置访问权限改变:\(status.rawValue)");
        switch status
        {
        case .notDetermined:()
        case .denied:()
        case .restricted:()
        case .authorizedAlways:
            self.startUpdaingLocation()
        case .authorizedWhenInUse:()
        }
    }
}

// MARK: - 业务逻辑
extension LocationCenter {
    
    /// 进入后台
    @objc private func enterBackground() {
        self.backgroundTaskId = UIApplication.shared.beginBackgroundTask(expirationHandler: {
            if self.backgroundTaskId != UIBackgroundTaskIdentifier.invalid
            {
                self.backgroundTaskId = UIBackgroundTaskIdentifier.invalid
            }
        })
    }
    
    
    /// 进入前台
    @objc private func becomeActive() {
        guard self.backgroundTaskId != UIBackgroundTaskIdentifier.invalid else { return }
        UIApplication.shared.endBackgroundTask(self.backgroundTaskId)
    }
    
    
    /// 添加通知
    private func addNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(becomeActive), name: UIApplication.didBecomeActiveNotification , object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(enterBackground), name: UIApplication.willResignActiveNotification, object: nil)
    }
    
    
    /// 移除通知
    private func removeNotification() {
        NotificationCenter.default.removeObserver(self)
    }
    
    
    /// 刷新textView
    private func showText() {
        if let arr = UserDefaults.standard.object(forKey: "arr") as? Array<String>
        {
            var str = ""
            for (index, s) in arr.enumerated()
            {
                str.append(String.init(format: "%@  [%ld]\n\n", s, index))
            }
            self.textView.text = str
            self.textView.layoutManager.allowsNonContiguousLayout = false;
            self.textView.scrollRangeToVisible(NSRange.init(location: str.count , length: 1))
        }
    }
    
    
    /// 开始定位
    func startUpdaingLocation() {
        self.locationManager.startUpdatingLocation()
        self.locationManager.startMonitoringSignificantLocationChanges()
        if self.timer == nil
        {
            self.timer = Timer.scheduledTimer(withTimeInterval: TimeInterval(timeInterval), repeats: true, block: {[weak self] (t) in
                self?.startUpdaingLocation()
            })
        }
    }
    
    
    /// 停止定位
    func stopUpdaingLocation() {
        self.locationManager.stopUpdatingLocation()
        guard self.timer != nil else { return }
        self.timer?.fireDate = .distantFuture
        self.timer?.invalidate()
        self.timer = nil
    }
    
  
    /// 定位点处理
    private func locaitonHandle(_ location: CLLocation) {
        let coorStr = String(describing: location.coordinate)
        let date = Date.init()
        let format = DateFormatter.init()
        format.dateFormat = "YYYY\\MM\\dd HH:mm:ss"
        let dateStr = format.string(from: date)
        if var arr = UserDefaults.standard.object(forKey: "arr") as? Array<String>
        {
            arr.append(String.init(format: "%@ %@", coorStr, dateStr))
            UserDefaults.standard.set(arr, forKey: "arr")
            UserDefaults.standard.synchronize()
        }
        else
        {
            self.clearAllText()
        }
        i += 1
        print("[\(dateStr)] + [\(i)]")
        self.showText()
    }
    
    
    /// 清空屏幕
    func clearAllText() {
        UserDefaults.standard.set([String](), forKey: "arr")
        UserDefaults.standard.synchronize()
        self.showText()
    }
}
