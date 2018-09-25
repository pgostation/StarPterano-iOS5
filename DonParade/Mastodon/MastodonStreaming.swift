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

final class MastodonStreaming: NSObject, WebSocketDelegate {
    private var socket: WebSocket
    private var callback: (String?)->Void
    
    init(url: URL, callback: @escaping (String?)->Void) {
        self.socket = WebSocket(url: url)
        
        self.callback = callback
        
        super.init()
        
        self.socket.delegate = self
        self.socket.connect()
    }
    
    func websocketDidConnect(socket: WebSocketClient) {
        print("websocket is connected")
    }
    
    func websocketDidDisconnect(socket: WebSocketClient, error: Error?) {
        print("websocket is disconnected. error=\(error?.localizedDescription)")
    }
    
    func websocketDidReceiveMessage(socket: WebSocketClient, text: String) {
        self.callback(text)
    }
    
    func websocketDidReceiveData(socket: WebSocketClient, data: Data) {
        //
    }
}
