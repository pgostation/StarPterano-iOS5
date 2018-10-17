//
//  MastodonStreaming.swift
//  DonParade
//
//  Created by takayoshi on 2018/09/25.
//  Copyright © 2018年 pgostation. All rights reserved.
//

// ストリーミングAPIを叩きたい

import Foundation
import Starscream

final class MastodonStreaming: NSObject, WebSocketDelegate, WebSocketPongDelegate {
    private var socket: WebSocket
    private var callback: (String?)->Void
    private var timer: Timer? = nil
    var isConnect = false
    
    init(url: URL, callback: @escaping (String?)->Void) {
        self.isConnect = true
        
        self.socket = WebSocket(url: url)
        
        self.callback = callback
        
        super.init()
        
        self.socket.delegate = self
        self.socket.pongDelegate = self
        self.socket.connect()
    }
    
    deinit {
        print("websocket is disposed")
    }
    
    func websocketDidConnect(socket: WebSocketClient) {
        print("websocket is connected")
        self.isConnect = true
        
        self.timer = Timer.scheduledTimer(timeInterval: 179, target: self, selector: #selector(ping), userInfo: nil, repeats: true)
    }
    
    func websocketDidDisconnect(socket: WebSocketClient, error: Error?) {
        print("websocket is disconnected. error=\(error?.localizedDescription ?? "")")
        if self.isConnect {
            self.isConnect = false
            self.timer?.invalidate()
            self.timer = nil
            
            MainViewController.instance?.showNotify(text: I18n.get("NOTIFY_DISCONNECTED_STREAMING"))
        }
    }
    
    func websocketDidReceiveMessage(socket: WebSocketClient, text: String) {
        self.callback(text)
    }
    
    func websocketDidReceiveData(socket: WebSocketClient, data: Data) {
        //
    }
    
    func disconnect() {
        if self.isConnect {
            self.isConnect = false
            self.socket.disconnect()
            self.timer?.invalidate()
            self.timer = nil
        }
    }
    
    @objc func ping() {
        print("websocket ping")
        self.socket.write(ping: Data())
    }
    
    func websocketDidReceivePong(socket: WebSocketClient, data: Data?) {
        print("Got pong! Maybe some data: \(data?.count ?? -1)")
    }
}
