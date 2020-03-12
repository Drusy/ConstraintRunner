//
//  ConstraintRunner.swift
//
//  Created by Drusy on 20/03/2018.
//  Copyright © 2018 Openium. All rights reserved.
//

import Foundation
import Reachability

protocol DateProvider {
    func now() -> Date
}

protocol ReachabilityProvider {
    var connection: Reachability.Connection { get }
}

extension Reachability: ReachabilityProvider {}

class ConstraintRunner {
    
    private class ContraintRunnerDateProvider: DateProvider {
        func now() -> Date {
            return Date()
        }
    }
    
    typealias CompletionHandler = (Bool) -> Void

    enum ConnectivityType {
        /// Job will run regardless the connectivity of the platform
        case any
        /// Requires a connectivity, wifi or cellular
        case reachable
        /// Require no connectivity at all (flight mode for example)
        case notReachable
        /// Requires at least cellular such as 2G, 3G, 4G, LTE or Wifi
        case cellular
        /// Device has to be connected to Wifi or Lan
        case wifi
    }
    
    enum Period {
        case any
        // Once every 12h
        case twiceADay
        // Once every 24h
        case onceADay
        // Once every 7days
        case onceAWeek
        // Once every x days
        case onceEveryDayCount(Int)
        // Once every x hours
        case onceEveryHourCount(Int)
        // Once every x minutes
        case onceEveryMinuteCount(Int)
        // Once every x seconds
        case onceEverySecondCount(Int)
    }
    
    static let second: TimeInterval = 1
    static let minute: TimeInterval = second * 60
    static let hour: TimeInterval = minute * 60
    static let day: TimeInterval = hour * 24
    static let week: TimeInterval = day * 7
    
    static private let userDefaultsPrefix = String(describing: ConstraintRunner.self)
    
    lazy var dateProvider: DateProvider = { return ContraintRunnerDateProvider() }()
    lazy var reachabilityProvider: ReachabilityProvider? = { return Reachability() }()
    
    private let identifier: String
    private let retryIdentifier: String

    private var period: Period = .any
    private var connectivity: ConnectivityType = .any
    private var maxRetryInterval: TimeInterval = 0

    init(identifier: String) {
        let constraintRunnerIdentifier = "\(ConstraintRunner.userDefaultsPrefix).\(identifier)"
        
        self.identifier = constraintRunnerIdentifier
        self.retryIdentifier = "\(constraintRunnerIdentifier).retry"
    }
    
    // MARK: -

    /// Execute the given handler if needed.
    /// The handler will be executed if the specifies constraints are satisfied
    /// The handler can perform asynchronous task and call the given `CompletionHandler` when done
    /// passing `true` if succeeded or `false` if it failed
    ///
    /// - Parameter handler: The handler to execute if needed
    /// - Returns: `true` if the handler have been called, `false` otherwise
    @discardableResult
    func runIfNeeded(force: Bool = false, asyncHandler: (@escaping CompletionHandler) -> Void) -> Bool {
        guard force == true || shouldRun() else { return false }
        
        asyncHandler { [weak self] succeeded in
            guard let strongSelf = self else { return }
            
            if succeeded {
                strongSelf.onRunSucceeded()
            } else {
                strongSelf.onRunFailed()
            }
        }
        
        return true
    }
    
    /// Execute the given handler if needed.
    /// The handler will be executed if the specifies constraints are satisfied
    /// The handler should perform synchronous task and return `true` if the task succeeded or `false`
    /// if it failed
    ///
    /// - Parameter handler: The handler to execute if needed
    /// - Returns: `true` if the handler have been called, `false` otherwise
    @discardableResult
    func runIfNeeded(syncHandler: () -> Bool) -> Bool {
        guard shouldRun() else { return false }

        if syncHandler() {
            onRunSucceeded()
        } else {
            onRunFailed()
        }
        
        return true
    }
    
    /// Constraint the task for a maximum period of time
    ///
    /// - Parameter period: The period if time, defined by `Period`
    func period(_ period: Period) -> ConstraintRunner {
        self.period = period
        return self
    }
    
    /// Constraint the task for a minimum internet connection
    ///
    /// - Parameter network: The minimum required internet connectivity
    func connectivity(atLeast connectivity: ConnectivityType) -> ConstraintRunner {
        self.connectivity = connectivity
        return self
    }

    /// Constraint the task for a minimum retry interval
    ///
    /// - Parameter interval: The minimum interval in second for it to accept a retry
    func maxRetryInterval(_ interval: TimeInterval) -> ConstraintRunner {
        self.maxRetryInterval = interval
        return self
    }
    
    /// Defines if the task should run or not
    /// If all the constraints are satisfied, the task should run
    ///
    /// - Returns: `true` if the task should run, `false` otherwise
    func shouldRun() -> Bool {
        guard isPeriodSatisfied() else { return false }
        guard isMaxRetryIntervalSatisfied() else { return false }
        guard isConnectivitySatisfied() else { return false }

        return true
    }
    
    /// Calculate the duration before the next possible execution
    ///
    /// - Returns: The duration before the next possible execution of the constrained task
    func timeIntervalBeforeNextExecution() -> TimeInterval {
        return timeIntervalBeforePeriodSatisfied() ?? timeIntervalBeforeMaxRetryIntervalSatisfied() ?? 0
    }
    
    /// Defined if the last execution of the process failed
    ///
    /// - Returns: `true` if the last execution failed, `false` otherwise
    func didLastExecutionFail() -> Bool {
        return UserDefaults.standard.object(forKey: retryIdentifier) != nil
    }
    
    /// Remove all the persisted properties
    static func removeAllPersistedProperties() {
        UserDefaults.standard
            .dictionaryRepresentation()
            .filter { $0.key.starts(with: ConstraintRunner.userDefaultsPrefix) }
            .forEach {
                UserDefaults.standard.removeObject(forKey: $0.key)
        }
    }
    
    // MARK: - Core
    
    func onRunSucceeded() {
        UserDefaults.standard.set(Date(), forKey: identifier)
        UserDefaults.standard.removeObject(forKey: retryIdentifier)
        UserDefaults.standard.synchronize()
    }
    
    func onRunFailed() {
        UserDefaults.standard.set(Date(), forKey: retryIdentifier)
        UserDefaults.standard.synchronize()
    }
    
    private func timeIntervalBeforeMaxRetryIntervalSatisfied() -> TimeInterval? {
        guard let lastRetry = UserDefaults.standard.object(forKey: retryIdentifier) as? Date else { return nil }
        
        let now = dateProvider.now()
        let elapsed = now.timeIntervalSince1970 - lastRetry.timeIntervalSince1970
        
        let offset = maxRetryInterval - elapsed
        return offset > 0 ? offset : nil
    }
    
    private func isMaxRetryIntervalSatisfied() -> Bool {
        return timeIntervalBeforeMaxRetryIntervalSatisfied() == nil
    }
    
    private func timeIntervalBeforePeriodSatisfied() -> TimeInterval? {
        guard let lastRun = UserDefaults.standard.object(forKey: identifier) as? Date else { return nil }
        
        let now = dateProvider.now()
        let elapsed = now.timeIntervalSince1970 - lastRun.timeIntervalSince1970
        let periodTimeInterval: TimeInterval
        
        switch period {
        case .any:
            periodTimeInterval = 0
            
        case .twiceADay:
            periodTimeInterval = ConstraintRunner.day / 2
            
        case .onceADay:
            periodTimeInterval = ConstraintRunner.day
            
        case .onceAWeek:
            periodTimeInterval = ConstraintRunner.week
            
        case .onceEveryDayCount(let count):
            periodTimeInterval = ConstraintRunner.day * TimeInterval(count)
            
        case .onceEveryHourCount(let count):
            periodTimeInterval = ConstraintRunner.hour * TimeInterval(count)
            
        case .onceEveryMinuteCount(let count):
            periodTimeInterval = ConstraintRunner.minute * TimeInterval(count)
            
        case .onceEverySecondCount(let count):
            periodTimeInterval = ConstraintRunner.second * TimeInterval(count)
        }
        
        let offset = periodTimeInterval - elapsed
        return offset > 0 ? offset : nil
    }
    
    private func isPeriodSatisfied() -> Bool {
        return timeIntervalBeforePeriodSatisfied() == nil
    }
    
    private func isConnectivitySatisfied() -> Bool {
        guard let reachability = reachabilityProvider else { return true }
        var connectivitySatisfied: Bool
        
        switch connectivity {
        case .any:
            connectivitySatisfied = true
            
        case .notReachable:
            connectivitySatisfied = reachability.connection == .none
            
        case .reachable:
            connectivitySatisfied = reachability.connection != .none
            
        case .wifi:
            connectivitySatisfied = reachability.connection == .wifi
            
        case .cellular:
            connectivitySatisfied = reachability.connection == .cellular
        }
        
        return connectivitySatisfied
    }
}
