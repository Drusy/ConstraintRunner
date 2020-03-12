import XCTest
import Reachability
@testable import ConstraintRunner

final class ConstraintRunnerTests: XCTestCase {
    let acceptableTolerance = 0.1

    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    // MARK: - Mock
    
    class ReachabilityProviderMock: ReachabilityProvider {
        let connection: Reachability.Connection
        
        init(connection: Reachability.Connection) {
            self.connection = connection
        }
    }
    
    class DateProviderMock: DateProvider {
        let date: Date
        
        init(date: Date) {
            self.date = date
        }

        func now() -> Date {
            return date
        }
    }
    
    // MARK: - Connectivity
    
    func testRunner_connectivity_default_alwaystrue() {
        let possibleConnections: [Reachability.Connection] = [.none, .cellular, .wifi]
        
        possibleConnections.forEach {
            let runner = ConstraintRunner(identifier: UUID().uuidString)
            runner.reachabilityProvider = ReachabilityProviderMock(connection: $0)
            
            let executed = runner.runIfNeeded { handler in
                handler(true)
            }
            
            XCTAssertTrue(executed)
        }
    }
    
    func testRunner_connectivity_any_alwaystrue() {
        let possibleConnections: [Reachability.Connection] = [.none, .cellular, .wifi]
        
        possibleConnections.forEach {
            let runner = ConstraintRunner(identifier: UUID().uuidString).connectivity(atLeast: .any)
            runner.reachabilityProvider = ReachabilityProviderMock(connection: $0)
            
            let executed = runner.runIfNeeded { handler in
                handler(true)
            }
            
            XCTAssertTrue(executed)
        }
    }
    
    func testRunner_connectivity_reachable_ok() {
        let possibleConnections: [Reachability.Connection] = [.cellular, .wifi]
        
        possibleConnections.forEach {
            let runner = ConstraintRunner(identifier: UUID().uuidString).connectivity(atLeast: .reachable)
            runner.reachabilityProvider = ReachabilityProviderMock(connection: $0)
            
            let executed = runner.runIfNeeded { handler in
                handler(true)
            }
            
            XCTAssertTrue(executed)
        }
    }
    
    func testRunner_connectivity_reachable_ko() {
        let possibleConnections: [Reachability.Connection] = [.none]
        
        possibleConnections.forEach {
            let runner = ConstraintRunner(identifier: UUID().uuidString).connectivity(atLeast: .reachable)
            runner.reachabilityProvider = ReachabilityProviderMock(connection: $0)
            
            let executed = runner.runIfNeeded { handler in
                handler(true)
            }
            
            XCTAssertFalse(executed)
        }
    }
    
    func testRunner_connectivity_notreachable_ok() {
        let possibleConnections: [Reachability.Connection] = [.none]
        
        possibleConnections.forEach {
            let runner = ConstraintRunner(identifier: UUID().uuidString).connectivity(atLeast: .notReachable)
            runner.reachabilityProvider = ReachabilityProviderMock(connection: $0)
            
            let executed = runner.runIfNeeded { handler in
                handler(true)
            }
            
            XCTAssertTrue(executed)
        }
    }
    
    func testRunner_connectivity_notreachable_ko() {
        let possibleConnections: [Reachability.Connection] = [.cellular, .wifi]
        
        possibleConnections.forEach {
            let runner = ConstraintRunner(identifier: UUID().uuidString).connectivity(atLeast: .notReachable)
            runner.reachabilityProvider = ReachabilityProviderMock(connection: $0)
            
            let executed = runner.runIfNeeded { handler in
                handler(true)
            }
            
            XCTAssertFalse(executed)
        }
    }
    
    func testRunner_connectivity_cellular_ok() {
        let possibleConnections: [Reachability.Connection] = [.cellular]
        
        possibleConnections.forEach {
            let runner = ConstraintRunner(identifier: UUID().uuidString).connectivity(atLeast: .cellular)
            runner.reachabilityProvider = ReachabilityProviderMock(connection: $0)
            
            let executed = runner.runIfNeeded { handler in
                handler(true)
            }
            
            XCTAssertTrue(executed)
        }
    }
    
    func testRunner_connectivity_cellular_ko() {
        let possibleConnections: [Reachability.Connection] = [.wifi, .none]
        
        possibleConnections.forEach {
            let runner = ConstraintRunner(identifier: UUID().uuidString).connectivity(atLeast: .cellular)
            runner.reachabilityProvider = ReachabilityProviderMock(connection: $0)
            
            let executed = runner.runIfNeeded { handler in
                handler(true)
            }
            
            XCTAssertFalse(executed)
        }
    }
    
    func testRunner_connectivity_wifi_ok() {
        let possibleConnections: [Reachability.Connection] = [.wifi]
        
        possibleConnections.forEach {
            let runner = ConstraintRunner(identifier: UUID().uuidString).connectivity(atLeast: .wifi)
            runner.reachabilityProvider = ReachabilityProviderMock(connection: $0)
            
            let executed = runner
                .runIfNeeded { handler in
                    handler(true)
            }
            
            XCTAssertTrue(executed)
        }
    }
    
    func testRunner_connectivity_wifi_ko() {
        let possibleConnections: [Reachability.Connection] = [.cellular, .none]
        
        possibleConnections.forEach {
            let runner = ConstraintRunner(identifier: UUID().uuidString).connectivity(atLeast: .wifi)
            runner.reachabilityProvider = ReachabilityProviderMock(connection: $0)
            
            let executed = runner.runIfNeeded { handler in
                handler(true)
            }
            
            XCTAssertFalse(executed)
        }
    }
    
    // MARK: - Period
    
    func testRunner_period_default_alwaystrue() {
        let runner = ConstraintRunner(identifier: UUID().uuidString).period(.any)
        
        let executed = runner.runIfNeeded { handler in
            handler(true)
        }
        
        XCTAssertTrue(executed)
    }
    
    func testRunner_period_any_alwaystrue() {
        let runner = ConstraintRunner(identifier: UUID().uuidString).period(.any)
        
        let executed = runner.runIfNeeded { handler in
            handler(true)
        }
        
        XCTAssertTrue(executed)
    }
    
    func testRunner_period_onceaday_ko() {
        let runner = ConstraintRunner(identifier: UUID().uuidString).period(.onceADay)
        XCTAssertTrue(runner.runIfNeeded { return true })
        
        let executed = runner.runIfNeeded { handler in
            handler(true)
        }
        
        XCTAssertFalse(executed)
    }
    
    func testRunner_period_onceaday_ok() {
        let runner = ConstraintRunner(identifier: UUID().uuidString).period(.onceADay)
        XCTAssertTrue(runner.runIfNeeded { return true })
        runner.dateProvider = DateProviderMock(date: Date().addingTimeInterval(24 * 60 * 60))
        
        let executed = runner.runIfNeeded { handler in
            handler(true)
        }
        
        XCTAssertTrue(executed)
    }
    
    func testRunner_period_onceaweek_ko() {
        let runner = ConstraintRunner(identifier: UUID().uuidString).period(.onceAWeek)
        XCTAssertTrue(runner.runIfNeeded { return true })
        
        let executed = runner.runIfNeeded { handler in
            handler(true)
        }
        
        XCTAssertFalse(executed)
    }
    
    func testRunner_period_onceaweek_ok() {
        let runner = ConstraintRunner(identifier: UUID().uuidString).period(.onceAWeek)
        XCTAssertTrue(runner.runIfNeeded { return true })
        runner.dateProvider = DateProviderMock(date: Date().addingTimeInterval(7 * 24 * 60 * 60))
        
        let executed = runner.runIfNeeded { handler in
            handler(true)
        }
        
        XCTAssertTrue(executed)
    }
    
    func testRunner_period_twiceaday_ko() {
        let runner = ConstraintRunner(identifier: UUID().uuidString).period(.twiceADay)
        XCTAssertTrue(runner.runIfNeeded { return true })
        
        let executed = runner.runIfNeeded { handler in
            handler(true)
        }
        
        XCTAssertFalse(executed)
    }
    
    func testRunner_period_twiceaday_ok() {
        let runner = ConstraintRunner(identifier: UUID().uuidString).period(.twiceADay)
        XCTAssertTrue(runner.runIfNeeded { return true })
        runner.dateProvider = DateProviderMock(date: Date().addingTimeInterval(12 * 60 * 60))
        
        let executed = runner.runIfNeeded { handler in
            handler(true)
        }
        
        XCTAssertTrue(executed)
    }
    
    func testRunner_period_onceeverydaycount_ko() {
        let runner = ConstraintRunner(identifier: UUID().uuidString).period(.onceEveryDayCount(20))
        XCTAssertTrue(runner.runIfNeeded { return true })
        
        let executed = runner.runIfNeeded { handler in
            handler(true)
        }
        
        XCTAssertFalse(executed)
    }
    
    func testRunner_period_onceeverydaycount_ok() {
        let runner = ConstraintRunner(identifier: UUID().uuidString).period(.onceEveryDayCount(20))
        XCTAssertTrue(runner.runIfNeeded { return true })
        runner.dateProvider = DateProviderMock(date: Date().addingTimeInterval(20 * 24 * 60 * 60))
        
        let executed = runner.runIfNeeded { handler in
            handler(true)
        }
        
        XCTAssertTrue(executed)
    }
    
    func testRunner_period_onceeveryhourcount_ko() {
        let runner = ConstraintRunner(identifier: UUID().uuidString).period(.onceEveryHourCount(20))
        XCTAssertTrue(runner.runIfNeeded { return true })
        
        let executed = runner.runIfNeeded { handler in
            handler(true)
        }
        
        XCTAssertFalse(executed)
    }
    
    func testRunner_period_onceeveryhourcount_ok() {
        let runner = ConstraintRunner(identifier: UUID().uuidString).period(.onceEveryHourCount(20))
        XCTAssertTrue(runner.runIfNeeded { return true })
        runner.dateProvider = DateProviderMock(date: Date().addingTimeInterval(20 * 60 * 60))
        
        let executed = runner.runIfNeeded { handler in
            handler(true)
        }
        
        XCTAssertTrue(executed)
    }
    
    func testRunner_period_onceeveryminutecount_ko() {
        let runner = ConstraintRunner(identifier: UUID().uuidString).period(.onceEveryMinuteCount(20))
        XCTAssertTrue(runner.runIfNeeded { return true })
        
        let executed = runner.runIfNeeded { handler in
            handler(true)
        }
        
        XCTAssertFalse(executed)
    }
    
    func testRunner_period_onceeveryminutecount_ok() {
        let runner = ConstraintRunner(identifier: UUID().uuidString).period(.onceEveryMinuteCount(20))
        XCTAssertTrue(runner.runIfNeeded { return true })
        runner.dateProvider = DateProviderMock(date: Date().addingTimeInterval(20 * 60))
        
        let executed = runner.runIfNeeded { handler in
            handler(true)
        }
        
        XCTAssertTrue(executed)
    }
    
    func testRunner_period_onceeverysecondcount_ko() {
        let runner = ConstraintRunner(identifier: UUID().uuidString).period(.onceEverySecondCount(20))
        XCTAssertTrue(runner.runIfNeeded { return true })
        
        let executed = runner.runIfNeeded { handler in
            handler(true)
        }
        
        XCTAssertFalse(executed)
    }
    
    func testRunner_period_onceeverysecondcount_ok() {
        let runner = ConstraintRunner(identifier: UUID().uuidString).period(.onceEverySecondCount(20))
        XCTAssertTrue(runner.runIfNeeded { return true })
        runner.dateProvider = DateProviderMock(date: Date().addingTimeInterval(20))
        
        let executed = runner.runIfNeeded { handler in
            handler(true)
        }
        
        XCTAssertTrue(executed)
    }
    
    // MARK: - Period / Time before next execution
    
    func testRunner_period_success_timeIntervalBeforeNextExecution() {
        let secondPeriod: Int = 10
        let runner = ConstraintRunner(identifier: UUID().uuidString).period(.onceEverySecondCount(secondPeriod))
        XCTAssertTrue(runner.runIfNeeded { return true })
        
        let timeIntervalBeforeNextExecution = runner.timeIntervalBeforeNextExecution()
        XCTAssert(fabs(timeIntervalBeforeNextExecution - TimeInterval(secondPeriod)) < acceptableTolerance)
    }
    
    func testRunner_period_failed_timeIntervalBeforeNextExecution() {
        let secondPeriod: Int = 10
        let runner = ConstraintRunner(identifier: UUID().uuidString).period(.onceEverySecondCount(secondPeriod))
        XCTAssertTrue(runner.runIfNeeded { return false })
        
        let timeIntervalBeforeNextExecution = runner.timeIntervalBeforeNextExecution()
        XCTAssertEqual(0, timeIntervalBeforeNextExecution)
    }
    
    // MARK: - Max retry interval
    
    func testRunner_maxRetryInterval_default_succeded_true() {
        let runner = ConstraintRunner(identifier: UUID().uuidString)
        
        let executed = runner.runIfNeeded { handler in
            handler(true)
        }
        
        XCTAssertTrue(executed)
    }
    
    func testRunner_maxRetryInterval_default_failed_true() {
        let runner = ConstraintRunner(identifier: UUID().uuidString)
        
        let executed = runner.runIfNeeded { handler in
            handler(false)
        }
        
        XCTAssertTrue(executed)
    }
    
    func testRunner_maxRetryInterval_invalid() {
        let runner = ConstraintRunner(identifier: UUID().uuidString).maxRetryInterval(10)
        XCTAssertTrue(runner.runIfNeeded { return false })

        let executed = runner.runIfNeeded { handler in
            handler(false)
        }
        
        XCTAssertFalse(executed)
    }
    
    func testRunner_maxRetryInterval_valid() {
        let runner = ConstraintRunner(identifier: UUID().uuidString).maxRetryInterval(10)
        XCTAssertTrue(runner.runIfNeeded { return false })
        runner.dateProvider = DateProviderMock(date: Date().addingTimeInterval(10))

        let executed = runner.runIfNeeded { handler in
            handler(false)
        }
        
        XCTAssertTrue(executed)
    }
    
    // MARK: - Max retry interval / Time before next execution
    
    func testRunner_maxRetryInterval_success_timeIntervalBeforeNextExecution() {
        let maxRetryInterval: TimeInterval = 10
        let runner = ConstraintRunner(identifier: UUID().uuidString).maxRetryInterval(maxRetryInterval)
        XCTAssertTrue(runner.runIfNeeded { return true })
        
        let timeIntervalBeforeNextExecution = runner.timeIntervalBeforeNextExecution()
        XCTAssertEqual(0, timeIntervalBeforeNextExecution)
    }
    
    func testRunner_maxRetryInterval_failed_timeIntervalBeforeNextExecution() {
        let maxRetryInterval: TimeInterval = 10
        let runner = ConstraintRunner(identifier: UUID().uuidString).maxRetryInterval(maxRetryInterval)
        XCTAssertTrue(runner.runIfNeeded { return false })
        
        let timeIntervalBeforeNextExecution = runner.timeIntervalBeforeNextExecution()
        XCTAssert(fabs(timeIntervalBeforeNextExecution - maxRetryInterval) < acceptableTolerance)
    }
    
    // MARK: - Did last execution failed
    
    func testRunner_didLastExecutionFail_fail() {
        let runner = ConstraintRunner(identifier: UUID().uuidString)
        XCTAssertTrue(runner.runIfNeeded { return false })
        
        XCTAssertTrue(runner.didLastExecutionFail())
    }
    
    func testRunner_didLastExecutionFail_success() {
        let runner = ConstraintRunner(identifier: UUID().uuidString)
        XCTAssertTrue(runner.runIfNeeded { return true })
        
        XCTAssertFalse(runner.didLastExecutionFail())
    }
}
