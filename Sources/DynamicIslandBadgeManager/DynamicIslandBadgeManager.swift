import UIKit

final class DynamicIslandBadgeManager {
    public static let shared = DynamicIslandBadgeManager()
    
    private var badgeImageView: UIImageView?
    private var addedToWindow = false
    
    private init() {
        registerForNotifications()
    }
    
    // MARK: - Public Methods
    func setupWithImage(_ image: UIImage) {
        if !addedToWindow {
            addToWindow()
        }
        badgeImageView?.image = image
    }
    
    func bringToFront() {
        guard let badgeImageView = badgeImageView, let window = badgeImageView.superview else { return }
        window.bringSubviewToFront(badgeImageView)
    }
    
    // MARK: - Private Methods
    private func registerForNotifications() {
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(appDidEnterBackground),
                                       name: UIApplication.didEnterBackgroundNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(appWillEnterForeground),
                                       name: UIApplication.willEnterForegroundNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(appDidBecomeActive),
                                       name: UIApplication.didBecomeActiveNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(appWillResignActive),
                                       name: UIApplication.willResignActiveNotification, object: nil)
    }
    
    private func addToWindow() {
        guard let window = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .last(where: { $0.isKeyWindow }), isAvailable, !addedToWindow else { return }
        
        addBadge(to: window)
        addedToWindow = true
    }
    
    private func addBadge(to window: UIWindow) {
        guard isAvailable else { return }
        
        let size = CGSize(width: 120, height: 30)
        let origin = CGPoint(x: UIScreen.main.bounds.midX - size.width / 2,
                             y: is16ProSeries ? 14 : 11)
        let rect = CGRect(origin: origin, size: size)
        
        let imageView = UIImageView(frame: rect)
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        
        window.addSubview(imageView)
        window.bringSubviewToFront(imageView)
        
        badgeImageView = imageView
    }
    
    @objc private func appDidEnterBackground() {
        badgeImageView?.isHidden = true
    }
    
    @objc private func appWillEnterForeground() {
        badgeImageView?.isHidden = false
    }
    
    @objc private func appDidBecomeActive() {
        badgeImageView?.isHidden = false
    }
    
    @objc private func appWillResignActive() {
        badgeImageView?.isHidden = true
    }
}

// MARK: - Device Compatibility Extension
private extension DynamicIslandBadgeManager {
    var identifier: String {
        #if targetEnvironment(simulator)
            return ProcessInfo().environment["SIMULATOR_MODEL_IDENTIFIER"] ?? ""
        #else
            var systemInfo = utsname()
            uname(&systemInfo)
            return Mirror(reflecting: systemInfo.machine).children.reduce("") { identifier, element in
                guard let value = element.value as? Int8, value != 0 else { return identifier }
                return identifier + String(UnicodeScalar(UInt8(value)))
            }
        #endif
    }
    
    var is14Series: Bool {
        ["iPhone15,2", "iPhone15,3"].contains(identifier)
    }
    
    var is15Series: Bool {
        ["iPhone15,4", "iPhone15,5", "iPhone16,1", "iPhone16,2"].contains(identifier)
    }
    
    var is16Series: Bool {
        ["iPhone17,1", "iPhone17,2", "iPhone17,3", "iPhone17,4"].contains(identifier)
    }
    
    var is16ProSeries: Bool {
        ["iPhone17,1", "iPhone17,2"].contains(identifier)
    }
    
    var hasIsland: Bool {
        is14Series || is15Series || is16Series
    }
    
    var isAvailable: Bool {
        if #unavailable(iOS 16) {
            return false
        }
        return hasIsland
    }
}
