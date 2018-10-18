//
//  LBXSwiftManager.swift
//  NVRCloudIOS
//
//  Created by Nvr on 2018/10/18.
//  Copyright © 2018年 zhangyu. All rights reserved.
//

import UIKit
import LBXScan

typealias scanResultBack = (_ scanInfo:String?)->(Void)

class LBXSwiftManager: LBXScanViewController,LBXScanViewControllerDelegate{
    
    var callBack:scanResultBack? = nil
    
    /**
     @brief  扫码区域上方提示文字
     */
    var topTitle:UILabel?
    
    /**
     @brief  提示文字
     */
    var topTitleStr:String?
    
    /**
     @brief  闪关灯开启状态
     */
    var isOpenedFlash:Bool = false
    
    // MARK: - 底部几个功能：开启闪光灯、相册、我的二维码
    
    //底部显示的功能项
    var bottomItemsView:UIView?
    
    //相册
    var btnPhoto:UIButton = UIButton()
    
    //闪光灯
    var btnFlash:UIButton = UIButton()
    
    var  isPushedWebviewController = false
    
    //MARK: -系统回调方法
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.delegate = self
        self.libraryType = .SLT_ZXing
        isNeedScanImage = true
        setting()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        drawBottomItems()
    }
    
    func scanResult(with array: [LBXScanResult]!) {
        if array.count >= 0 {
            if let back = callBack{
                back(array[0].strScanned)
                self.navigationController?.popViewController(animated: true)
            }
        }
    }
}

//MARK: -UI

extension NvrScanViewController {
    
    func setting(){
        self.title = NSLocalizedString("qr_scan", comment: "")
        style = getStyle()
        style?.centerUpOffset += 10
    }
    
    //扫码框样式
    
    func getStyle() -> LBXScanViewStyle {
        
        let lbxStyle = LBXScanViewStyle()
        lbxStyle.centerUpOffset = 44
        lbxStyle.photoframeAngleStyle = LBXScanViewPhotoframeAngleStyle.inner
        lbxStyle.photoframeLineW = 3
        lbxStyle.photoframeAngleW = 30
        lbxStyle.photoframeAngleH = 30
        lbxStyle.isNeedShowRetangle = false
        lbxStyle.colorAngle = UIColor.base_color
        lbxStyle.anmiationStyle = LBXScanViewAnimationStyle.netGrid
        
        let image = UIImage.init(named: "qrcode_scan_full_net")
        lbxStyle.animationImage = image
        lbxStyle.notRecoginitonArea = UIColor.init(red: 0, green: 0, blue: 0, alpha: 0.6)
        
        return lbxStyle
    }
    
    func drawBottomItems()
    {
        topTitle = UILabel(frame: CGRect(x:60, y: 30, width: SCREEN_WIDTH - 120, height: 50))
        topTitle?.text = topTitleStr
        topTitle?.backgroundColor = UIColor.clear
        topTitle?.textColor = UIColor.white
        topTitle?.textAlignment = .center
        topTitle?.font = UIFont.systemFont(ofSize: 18.0)
        topTitle?.numberOfLines = 0
        self.view.addSubview(topTitle!)
        
        if (bottomItemsView != nil) {
            return;
        }
        
        let yMax = self.view.frame.maxY - self.view.frame.minY
        
        bottomItemsView = UIView(frame:CGRect(x: 0.0, y: yMax-100,width: self.view.frame.size.width, height: 100 ) )
        
        
        bottomItemsView!.backgroundColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.6)
        
        self.view .addSubview(bottomItemsView!)
        
        
        let size = CGSize(width: 65, height: 87);
        
        self.btnFlash = UIButton()
        btnFlash.bounds = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        btnFlash.center = CGPoint(x: bottomItemsView!.frame.width/3, y: bottomItemsView!.frame.height/2)
        btnFlash.setImage(UIImage(named: "qrcode_scan_btn_flash_nor"), for:UIControlState.normal)
        btnFlash.addTarget(self, action: #selector(NvrScanViewController.openOrCloseFlash), for: UIControlEvents.touchUpInside)
        
        
        self.btnPhoto = UIButton()
        btnPhoto.bounds = btnFlash.bounds
        btnPhoto.center = CGPoint(x: bottomItemsView!.frame.width/3*2, y: bottomItemsView!.frame.height/2)
        btnPhoto.setImage(UIImage(named: "qrcode_scan_btn_photo_nor"), for: UIControlState.normal)
        btnPhoto.setImage(UIImage(named: "qrcode_scan_btn_photo_down"), for: UIControlState.highlighted)
        btnPhoto.addTarget(self, action: #selector(NvrScanViewController.openLocalPhotoAlbum), for: UIControlEvents.touchUpInside)
        
        
        bottomItemsView?.addSubview(btnFlash)
        bottomItemsView?.addSubview(btnPhoto)
        
        self.view .addSubview(bottomItemsView!)
        
    }
}

//MARK: -点击事件

extension NvrScanViewController {
    
    //打开相册
    @objc func openLocalPhotoAlbum()
    {
        
        LBXPermissions.authorizePhotoWith { [weak self] (granted) in
            
            if granted
            {
                if let strongSelf = self
                {
                    let picker = UIImagePickerController()
                    picker.sourceType = UIImagePickerControllerSourceType.photoLibrary
                    picker.delegate = self;
                    picker.allowsEditing = true
                    strongSelf.present(picker, animated: true, completion: nil)
                }
            }
            else
            {
                LBXPermissions.jumpToSystemPrivacySetting()
            }
        }
    }
    
    
    //MARK: -----相册选择图片识别二维码 （条形码没有找到系统方法）
    public override func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any])
    {
        picker.dismiss(animated: true, completion: nil)
        
        var image:UIImage? = info[UIImagePickerControllerEditedImage] as? UIImage
        
        if (image == nil )
        {
            image = info[UIImagePickerControllerOriginalImage] as? UIImage
        }
        
        if(image == nil)
        {
            return
        }
        
        if(image != nil)
        {
            ZXingWrapper.recognizeImage(image!) { (formart, str) in
                if let back = self.callBack{
                    back(str)
                    self.navigationController?.popViewController(animated: true)
                }
                self.navigationController?.popViewController(animated: true)
            }
        }
        _ = SweetAlert().showAlert(NSLocalizedString("remind", comment: ""), subTitle: "scan fail", style: .error)
    }
    
    
    //开关闪光灯
    @objc override func openOrCloseFlash()
    {
        zxingObj?.openTorch(isOpenedFlash)
        
        isOpenedFlash = !isOpenedFlash
        
        if isOpenedFlash
        {
            btnFlash.setImage(UIImage(named: "qrcode_scan_btn_flash_down"), for:UIControlState.normal)
        }
        else
        {
            btnFlash.setImage(UIImage(named: "qrcode_scan_btn_flash_nor"), for:UIControlState.normal)
        }
    }
    
}


