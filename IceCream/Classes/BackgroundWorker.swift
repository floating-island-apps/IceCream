//
//  BackgroundWorker.swift
//  IceCream
//
//  Created by Kit Forge on 5/9/19.
//

import Foundation
import RealmSwift

// Based on https://academy.realm.io/posts/realm-notifications-on-background-threads-with-swift/
// Tweaked a little by Yue Cai

class BackgroundWorker: NSObject {
    static let shared = BackgroundWorker()
    
    private var thread: Thread?
    private let queue = DispatchQueue(label: "com.backgroundworker.IceCream")
    private var block: (() -> Void)?
    
    func start(_ block: @escaping () -> Void) {
        queue.sync { [weak self] in
            self?.block = block
        }
        
        if thread == nil {
            thread = Thread { [weak self] in
                guard let self = self, let thread = self.thread else {
                    Thread.exit()
                    return
                }
                while !thread.isCancelled {
                    RunLoop.current.run(
                        mode: .default,
                        before: Date.distantFuture)
                }
                Thread.exit()
            }
            thread?.name = "\(String(describing: self))-\(UUID().uuidString)"
            thread?.start()
        }
        
        if let thread = thread {
            perform(#selector(runBlock),
                    on: thread,
                    with: nil,
                    waitUntilDone: true,
                    modes: [RunLoop.Mode.default.rawValue])
        }
    }
    
    func stop() {
        queue.sync { [weak self] in
            self?.block = nil
            self?.thread?.cancel()
        }
    }
    
    @objc private func runBlock() {
        queue.sync { [weak self] in
            self?.block?()
        }
    }
}
