// The MIT License (MIT)
//
// Copyright (c) 2015 Joakim Gyllström
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import UIKit
import Photos

/**
BSImagePickerViewController.
Use settings or buttons to customize it to your needs.
*/
public class BSImagePickerViewController : UIViewController, BSImagePickerSettings {
    private let settings = Settings()
    
    private var doneBarButton: UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Done, target: nil, action: nil)
    private var cancelBarButton: UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Cancel, target: nil, action: nil)
    private let albumTitleView: AlbumTitleView = bundle.loadNibNamed("AlbumTitleView", owner: nil, options: nil).first as! AlbumTitleView
    private var dataSource: SelectableDataSource?
    private let selections: [PHAsset]
    
    static let bundle: NSBundle = NSBundle(forClass: PhotosViewController.self)
    
    lazy var photosViewController: PhotosViewController = {
        let dataSource: SelectableDataSource
        if self.dataSource != nil {
            dataSource = self.dataSource!
        } else {
            dataSource = BSImagePickerViewController.defaultDataSource()
        }
        
        let vc = PhotosViewController(dataSource: dataSource, settings: self.settings, selections: self.selections)
        
        vc.doneBarButton = self.doneBarButton
        vc.cancelBarButton = self.cancelBarButton
        vc.albumTitleView = self.albumTitleView
        
        vc.cancelClosure = { _ in
            self.imagePickerDidCancel()
        }
        
        vc.finishClosure = { assets in
            self.imagePickerDidComplete(assets)
        }

        return vc
    }()
    
    public class func authorize(status: PHAuthorizationStatus = PHPhotoLibrary.authorizationStatus(), fromViewController: UIViewController, completion: Bool -> Void) {
        switch status {
        case .Authorized:
            // We are authorized. Run block
            completion(true)
        case .NotDetermined:
            // Ask user for permission
            PHPhotoLibrary.requestAuthorization({ (status) -> Void in
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.authorize(status, fromViewController: fromViewController, completion: completion)
                })
            })
        default: ()
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                // Set up alert controller with some default strings. These should probably be overriden in application localizeable strings.
                // If you don't enjoy my Swenglish that is ^^
                let alertController = UIAlertController(title: NSLocalizedString("imagePickerNoCameraAccessTitle", value: "Can't access Photos", comment: "Alert view title"),
                    message: NSLocalizedString("imagePickerNoCameraAccessMessage", value: "You need to enable Photos access in application settings.", comment: "Alert view message"),
                    preferredStyle: .Alert)
                
                let cancelAction = UIAlertAction(title: NSLocalizedString("imagePickerNoCameraAccessCancelButton", value: "Cancel", comment: "Cancel button title"), style: .Cancel) { _ in completion(false) }

                let settingsAction = UIAlertAction(title: NSLocalizedString("imagePickerNoCameraAccessSettingsButton", value: "Settings", comment: "Settings button title"), style: .Default, handler: { (action) -> Void in
                    completion(false)
                    let url = NSURL(string: UIApplicationOpenSettingsURLString)
                    if let url = url where UIApplication.sharedApplication().canOpenURL(url) {
                        UIApplication.sharedApplication().openURL(url)
                    }
                })
                
                alertController.addAction(cancelAction)
                alertController.addAction(settingsAction)
                
                fromViewController.presentViewController(alertController, animated: true, completion: nil)
            })
        }
    }
    
    /**
    Want it to show your own custom fetch results? Make sure the fetch results are of PHAssetCollections
    - parameter fetchResults: PHFetchResult of PHAssetCollections
    */
    public convenience init(fetchResults: [PHFetchResult]) {
        self.init(dataSource: FetchResultsDataSource(fetchResults: fetchResults))
    }
    
    /**
    Do you have an asset collection you want to select from? Use this initializer!
    - parameter assetCollection: The PHAssetCollection you want to select from
    - parameter selections: Selected assets
    */
    public convenience init(assetCollection: PHAssetCollection, selections: [PHAsset] = []) {
        self.init(dataSource: AssetCollectionDataSource(assetCollection: assetCollection), selections: selections)
    }
    
    /**
    Sets up an classic image picker with results from camera roll and albums
    */
    public convenience init() {
        self.init(dataSource: nil)
    }
    
    /**
    You should probably use one of the convenience inits
    - parameter dataSource: The data source for the albums
    - parameter selections: Any PHAsset you want to seed the picker with as selected
    */
    public required init(dataSource: SelectableDataSource?, selections: [PHAsset] = []) {
        if let dataSource = dataSource {
            self.dataSource = dataSource
        }
        
        self.selections = selections
        
        super.init(nibName: nil, bundle: nil)
    }

    /**
    https://www.youtube.com/watch?v=dQw4w9WgXcQ
    */
    required public init?(coder aDecoder: NSCoder) {
        dataSource = BSImagePickerViewController.defaultDataSource()
        selections = []
        super.init(coder: aDecoder)
    }
    
    /**
    Load view. See apple documentation
    */
    public override func loadView() {
        super.loadView()
        
        // TODO: Settings
        view.backgroundColor = UIColor.whiteColor()
        
        if PHPhotoLibrary.authorizationStatus() == .Authorized {
            navigationController?.pushViewController(photosViewController, animated: false)
        }
    }
    
    private static func defaultDataSource() -> SelectableDataSource {
        let fetchOptions = PHFetchOptions()
        
        // Camera roll fetch result
        let cameraRollResult = PHAssetCollection.fetchAssetCollectionsWithType(.SmartAlbum, subtype: .SmartAlbumUserLibrary, options: fetchOptions)
        
        // Albums fetch result
        let albumResult = PHAssetCollection.fetchAssetCollectionsWithType(.Album, subtype: .Any, options: fetchOptions)
        
        return FetchResultsDataSource(fetchResults: [cameraRollResult, albumResult])
    }
    
    // MARK: ImagePickerSettings proxy
    /**
    See BSImagePicketSettings for documentation
    */
    public var maxNumberOfSelections: Int {
        get {
            return settings.maxNumberOfSelections
        }
        set {
            settings.maxNumberOfSelections = newValue
        }
    }
    
    /**
    See BSImagePicketSettings for documentation
    */
    public var selectionCharacter: Character? {
        get {
            return settings.selectionCharacter
        }
        set {
            settings.selectionCharacter = newValue
        }
    }
    
    /**
    See BSImagePicketSettings for documentation
    */
    public var selectionFillColor: UIColor {
        get {
            return settings.selectionFillColor
        }
        set {
            settings.selectionFillColor = newValue
        }
    }
    
    /**
    See BSImagePicketSettings for documentation
    */
    public var selectionStrokeColor: UIColor {
        get {
            return settings.selectionStrokeColor
        }
        set {
            settings.selectionStrokeColor = newValue
        }
    }
    
    /**
    See BSImagePicketSettings for documentation
    */
    public var selectionShadowColor: UIColor {
        get {
            return settings.selectionShadowColor
        }
        set {
            settings.selectionShadowColor = newValue
        }
    }
    
    /**
    See BSImagePicketSettings for documentation
    */
    public var selectionTextAttributes: [String: AnyObject] {
        get {
            return settings.selectionTextAttributes
        }
        set {
            settings.selectionTextAttributes = newValue
        }
    }
    
    /**
    See BSImagePicketSettings for documentation
    */
    public var cellsPerRow: (verticalSize: UIUserInterfaceSizeClass, horizontalSize: UIUserInterfaceSizeClass) -> Int {
        get {
            return settings.cellsPerRow
        }
        set {
            settings.cellsPerRow = newValue
        }
    }
    
    // MARK: Buttons
    /**
    Cancel button
    */
    public var cancelButton: UIBarButtonItem {
        get {
            return self.cancelBarButton
        }
    }
    
    /**
    Done button
    */
    public var doneButton: UIBarButtonItem {
        get {
            return self.doneBarButton
        }
    }
    
    /**
    Album button
    */
    public var albumButton: UIButton {
        get {
            return self.albumTitleView.albumButton
        }
    }
    
    // MARK: event methods for override
    
    public func imagePickerDidCancel() {
        
    }
    
    public func imagePickerDidComplete(assets: [PHAsset]) {
        
    }
}