//
//  CancelJob.swift
//  WeChatSwift
//
//  Created by sujian on 2017/1/11.
//  Copyright © 2017年 sujian. All rights reserved.
//

import Foundation

typealias CancelableTask = (_ cancel: Bool) -> Void
@discardableResult
func delay(time: TimeInterval, work: @escaping () -> Void) -> CancelableTask?{
    
    var finalTask: CancelableTask?
    
    let cancelableTask: CancelableTask = { cancel in
        if cancel {
            finalTask = nil
        } else {
            DispatchQueue.main.async(execute: work)
        }
    }
    
    finalTask = cancelableTask
    
    let delay = DispatchTime.now() + time
    DispatchQueue.main.asyncAfter(deadline: delay, execute: {
    
        if let task = finalTask {
            task(false)
        }
    })
    
    return finalTask
}

func cancel(cancelableTask: CancelableTask?) {
    cancelableTask?(true)
}
