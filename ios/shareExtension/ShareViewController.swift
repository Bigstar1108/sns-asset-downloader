//
//  ShareViewController.swift
//  shareExtension
//
//  Created by 황대성 on 2022/12/21.
//

import UIKit
import Social
import MobileCoreServices
import Photos
import UniformTypeIdentifiers
import AVFoundation
import ImageIO

@objc(ShareViewController)
class ShareViewController: UIViewController {
    var hostAppBundleIdentifier = "com.daeseong.snsAssetDownloader"
    let sharedKey = "SharingKey"
    var appGroupId = ""
    var sharedText: [String] = []
    
    let urlContentType = UTType.url.identifier;
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadIds();
    }
    
    private func loadIds() {
        // load Share extension App Id
        let shareExtensionAppBundleIdentifier = Bundle.main.bundleIdentifier!;

        // convert ShareExtension id to host app id
        // By default it is remove last part of id after last point
        let lastIndexOfPoint = shareExtensionAppBundleIdentifier.lastIndex(of: ".");
        hostAppBundleIdentifier = String(shareExtensionAppBundleIdentifier[..<lastIndexOfPoint!]);
        
        appGroupId = (Bundle.main.object(forInfoDictionaryKey: "AppGroupId") as? String) ?? "group.\(hostAppBundleIdentifier)";
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if let content = self.extensionContext?.inputItems.first as? NSExtensionItem {
            if let contents = content.attachments {
                for (index, attachment) in (contents).enumerated() {
                    if attachment.isURL {
                        handleUrl(content: content, attachment: attachment, index: index)
                    }
                    else {
                        print(" \(attachment) File type is not supported by flutter shaing plugin.")
                    }
                }
            }
        }
    }

    private func handleUrl (content: NSExtensionItem, attachment: NSItemProvider, index: Int) {
        attachment.loadItem(forTypeIdentifier: urlContentType, options: nil) { [weak self] data, error in
            if error == nil, let item = data as? URL, let this = self {
                this.sharedText.append(item.absoluteString)
                  
                if index == (content.attachments?.count)! - 1 {
                    let userDefaults = UserDefaults(suiteName: this.appGroupId)
                    userDefaults?.set(this.sharedText, forKey: this.sharedKey)
                    userDefaults?.synchronize()
                    this.redirectToHostApp(type: .url)
                }
            } else {
                self?.dismissWithError()
            }
        }
    }
    
    private func dismissWithError() {
        print("[ERROR] Error loading data!")
        let alert = UIAlertController(title: "Error", message: "Error loading data", preferredStyle: .alert)

        let action = UIAlertAction(title: "Error", style: .cancel) { _ in
            self.dismiss(animated: true, completion: nil)
        }

        alert.addAction(action)
        present(alert, animated: true, completion: nil)
        extensionContext!.completeRequest(returningItems: [], completionHandler: nil)
    }
    
    private func redirectToHostApp(type: RedirectType) {
        // load group and app id from build info
        loadIds();

        let url = URL(string: "SharingMedia-\(hostAppBundleIdentifier)://dataUrl=\(sharedKey)#\(type)")
        var responder = self as UIResponder?
        let selectorOpenURL = sel_registerName("openURL:")

        while (responder != nil) {
            if (responder?.responds(to: selectorOpenURL))! {
                let _ = responder?.perform(selectorOpenURL, with: url)
            }

            responder = responder!.next
        }

        extensionContext!.completeRequest(returningItems: [], completionHandler: nil)
    }
    
    enum RedirectType { case url }
}

extension Array {
    subscript (safe index: UInt) -> Element? {
        return Int(index) < count ? self[Int(index)] : nil
    }
}

// MARK: - Attachment Types
extension NSItemProvider {
    var isURL: Bool {
        return hasItemConformingToTypeIdentifier(UTType.url.identifier)
    }
}
