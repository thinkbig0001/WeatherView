//
//  MyURLProtocol.swift
//  WeatherDemo
//
//  Created by TAPAN BISWAS on 2/4/18.
//  Copyright © 2018 TAPAN BISWAS. All rights reserved.
//

import UIKit

var requestCount = 0

class MyURLProtocol: URLProtocol {
    static var lastTriedRequest: [URLRequest] = []
    
    override class func canInit(with request: URLRequest) -> Bool {
        lastTriedRequest.append(request)
        print(request.description)
        return false
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    override func startLoading() {
        //do nothing
    }
    
    override func stopLoading() {
        //do nothing
    }
    
}
