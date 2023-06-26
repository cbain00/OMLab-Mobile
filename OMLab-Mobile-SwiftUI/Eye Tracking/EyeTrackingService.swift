//
//  UDPListener.swift
//
//  Created by Michael Robert Ellis on 12/16/21.
// https://medium.com/@michaelrobertellis/how-to-make-a-swift-ios-udp-listener-using-apples-network-framework-f7cef6f4e45f

import Foundation
import Network
import Combine

class EyeTrackingNetworkService: ObservableObject {
    var viewController : EyeTrackingViewController!
    var listener: NWListener?
    var connection: NWConnection?
    var queue = DispatchQueue.global(qos: .userInitiated)
    /// New data will be place in this variable to be received by observers
    @Published private(set) public var messageReceived: String?
    /// When there is an active listening NWConnection this will be `true`
    @Published private(set) public var isReady: Bool = false
    /// Default value `true`, this will become false if the UDPListener ceases listening for any reason
    @Published public var listening: Bool = true
    
    /// A convenience init using Int instead of NWEndpoint.Port
    convenience init(on port: Int, _ viewController : EyeTrackingViewController) {
        self.init(on: NWEndpoint.Port(integerLiteral: NWEndpoint.Port.IntegerLiteralType(port)),viewController)
    }
    /// Use this init or the one that takes an Int to start the listener
    init(on port: NWEndpoint.Port, _ viewController: EyeTrackingViewController) {
        self.viewController = viewController
        let params = NWParameters.udp
        params.allowFastOpen = true
        // create listener with passed port number
        self.initListener(port, params)
    }

    /// Create initListener function to handle statusUpdate, make recursive, clean old listener
    func initListener(_ port: NWEndpoint.Port, _ params: NWParameters) {
        // Initialize a new listener
        self.listener = try? NWListener(using: params, on: port)
        self.listener?.stateUpdateHandler = { update in
            switch update {
            case .ready:
                self.isReady = true
                print("Listener connected to port \(port)")
            case .failed:
                // Announce that we are no longer able to listen
                self.listening = false
                self.isReady = false
                print("Listener disconnected from port \(port)")
            case .cancelled:
                // Clean up the old listener if it exists
                self.listener?.cancel()
                print("Listener disconnected from port \(port)")
                print("\nAttemping reconnect...")
                //print("Update value: \(update)")
                self.initListener(port, params)
                
            default:
                print("Listener connecting to port \(port)...")
            }
        }
        self.listener?.newConnectionHandler = { connection in
            print("Listener receiving new message")
            self.createConnection(connection: connection)
        }
        self.listener?.start(queue: self.queue)
    }

    func createConnection(connection: NWConnection) {
        self.connection = connection
        self.connection?.stateUpdateHandler = { (newState) in
            switch (newState) {
            case .ready:
                print("Listener ready to receive message - \(connection)")
                self.receive()
            case .cancelled, .failed:
                print("Listener failed to receive message - \(connection)")
                // Cancel the listener, something went wrong
                self.listener?.cancel()
                // Announce we are no longer able to listen
                self.listening = false
            default:
                print("Listener waiting to receive message - \(connection)")
            }
        }
        self.connection?.start(queue: .global())
    }
    
    func receive() {
        self.connection?.receiveMessage { data, context, isComplete, error in
            if let unwrappedError = error {
                print("Error: NWError received in \(#function) - \(unwrappedError)")
                return
            }
            
            guard isComplete, let data = data else {
                print("Error: Received nil Data with context - \(String(describing: context))")
                return
            }
            
            let stringFromByteArray = String(data: Data(_: data), encoding: .utf8)
            print(stringFromByteArray ?? "")
            self.messageReceived = stringFromByteArray
            switch (stringFromByteArray ?? "") {
                case "StartRecording" :
                DispatchQueue.main.async {
                    self.viewController.recordingSwitch.isOn = true
                }
                case "StopRecording" :
                DispatchQueue.main.async {
                    self.viewController.recordingSwitch.isOn = false
                }
                default:
                    self.viewController.recordEvent(stringFromByteArray ?? "")
            }
            
            if self.listening {
                self.receive()
            }
            
            let sendString = "send" + stringFromByteArray!
            self.connection?.send(content: sendString.data(using: .utf8), completion: NWConnection.SendCompletion.contentProcessed({ sendError in
                if sendError != nil {
                    print(sendError!)
                }
            }))
        }
    }
    
    func cancel() {
        self.listening = false
        self.connection?.cancel()
    }
}


/*
//
//  https://jayeshkawli.ghost.io/creating-websocket-server-on-ios-using/
//

import Foundation
import Network



class SwiftWebSocketServer {
    var listener: NWListener
    var connectedClients: [NWConnection] = []
    
    init(port: UInt16) {
        
        let parameters = NWParameters(tls: nil)
        parameters.allowLocalEndpointReuse = true
        parameters.includePeerToPeer = true
        
        let wsOptions = NWProtocolWebSocket.Options()
        wsOptions.autoReplyPing = true
        
        parameters.defaultProtocolStack.applicationProtocols.insert(wsOptions, at: 0)
        
        do {
            if let port = NWEndpoint.Port(rawValue: port) {
                listener = try NWListener(using: parameters, on: port)
                print(listener.debugDescription)
            } else {
                fatalError("Unable to start WebSocket server on port \(port)")
            }
        } catch {
            fatalError(error.localizedDescription)
        }
        
        
    }


var timer: Timer?


func startServer() {
                        
        let serverQueue = DispatchQueue(label: "ServerQueue")
        
        listener.newConnectionHandler = { newConnection in
            
        }
        
        listener.stateUpdateHandler = { state in
            print(state)
            switch state {
            case .ready:
                print("Server Ready")
            case .failed(let error):
                print("Server failed with \(error.localizedDescription)")
            default:
                break
            }
        }

        listener.start(queue: serverQueue)
        startTimer()
    
    
    listener.newConnectionHandler = { newConnection in
                    print("New connection connecting")
                    
                    func receive() {
                        newConnection.receiveMessage { (data, context, isComplete, error) in
                            if let data = data, let context = context {
                                print("Received a new message from client")
                                receive()
                            }
                        }
                    }
                    receive()
                    
                    newConnection.stateUpdateHandler = { state in
                        switch state {
                        case .ready:
                            print("Client ready")
                            try! self.sendMessageToClient(data: JSONEncoder().encode(["t": "connect.connected"]), client: newConnection)
                        case .failed(let error):
                            print("Client connection failed \(error.localizedDescription)")
                        case .waiting(let error):
                            print("Waiting for long time \(error.localizedDescription)")
                        default:
                            break
                        }
                    }

                    newConnection.start(queue: serverQueue)
                }
    }
      
    func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true, block: { timer in
            
            guard !self.connectedClients.isEmpty else {
                return
            }
            
            self.sendMessageToAllClients()
            
        })
        timer?.fire()
    }
    
    func sendMessageToAllClients() {
        let data = getTradingQuoteData()
        for (index, client) in self.connectedClients.enumerated() {
            print("Sending message to client number \(index)")
            try! self.sendMessageToClient(data: data, client: client)
        }
    }
    
    func sendMessageToClient(data: Data, client: NWConnection) throws {
        let metadata = NWProtocolWebSocket.Metadata(opcode: .binary)
        let context = NWConnection.ContentContext(identifier: "context", metadata: [metadata])
        
        client.send(content: data, contentContext: context, isComplete: true, completion: .contentProcessed({ error in
            if let error = error {
                print(error.localizedDescription)
            } else {
                // no-op
            }
        }))
    }
    
    func getTradingQuoteData() -> Data {
        let data = SocketQuoteResponse(t: "trading.quote", body: QuoteResponseBody(securityId: "100", currentPrice: String(Int.random(in: 1...1000))))
        return try! JSONEncoder().encode(data)
    }
    
 
    struct SocketQuoteResponse: Encodable {
        let t: String
        let body: QuoteResponseBody
    }

    struct QuoteResponseBody: Encodable {
        let securityId: String
        let currentPrice: String
    }

    struct ConnectionAck: Encodable {
        let t: String
        let connectionId: Int
    }
    
    
}
*/
