//
//  languageManager.swift
//  Runner
//
//  Created by 王文智 on 2026/9/2.
//
import FlutterMacOS

class LanguageManager{
    
    static let shared = LanguageManager()
    var channel: FlutterMethodChannel?
    
    var currentLangMap = [String:String]()
    
    var updateLangCallBack = {()
    }
    
    func setupMethodCall(c:FlutterMethodChannel?){
        channel = c
        
        channel?.setMethodCallHandler {[weak self] call, result in
            
            guard let `self` = self else { return }
            if call.method == "updateLang" {
                
                if let lang =  call.arguments as? [String:String]{
                    
                    currentLangMap = lang
                    
                    
                    updateLangCallBack()
                }
            }
        }
        
    }
}

extension String{
    
    func lang() -> String{
        
        let dict = LanguageManager.shared.currentLangMap
        
        let s = dict[self] ?? self
        
        return s
    }
}
