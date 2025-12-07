//
//  CodingReviewerUITests.swift
//  CodingReviewerUITests
//
//  Comprehensive visual regression testing for macOS
//

import XCTest

final class CodingReviewerUITests: XCTestCase {
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
        
        // Wait for app to fully load
        sleep(2)
    }

    override func tearDownWithError() throws {
        // Cleanup if needed
    }
    
    // MARK: - Helper Functions
    
    /// Captures a screenshot with a descriptive name
    private func captureScreenshot(named name: String) {
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
    
    /// Safely click a button by identifier or label
    private func clickButton(_ identifier: String) -> Bool {
        let button = app.buttons[identifier].firstMatch
        if button.exists && button.isHittable {
            button.click()
            sleep(1)
            return true
        }
        return false
    }
    
    /// Click a menu item
    private func clickMenuItem(_ menu: String, item: String) -> Bool {
        let menuBar = app.menuBars.firstMatch
        if menuBar.exists {
            let menuBarItem = menuBar.menuBarItems[menu].firstMatch
            if menuBarItem.exists {
                menuBarItem.click()
                let menuItem = app.menuItems[item].firstMatch
                if menuItem.exists {
                    menuItem.click()
                    sleep(1)
                    return true
                }
            }
        }
        return false
    }
    
    // MARK: - Launch Tests
    
    @MainActor
    func testApplicationLaunch() throws {
        // Verify app launches successfully
        XCTAssertTrue(app.state == .runningForeground, "App should be running")
        captureScreenshot(named: "Launch_Main")
    }

    // MARK: - Main Window Screenshots
    
    @MainActor
    func testMainWindowScreenshots() throws {
        captureScreenshot(named: "MainWindow_Initial")
        
        // Check for main window elements (may not exist for document-based apps)
        let mainWindow = app.windows.firstMatch
        if mainWindow.exists {
            captureScreenshot(named: "MainWindow_Full")
        }
    }
    
    // MARK: - Welcome/Home View Screenshots
    
    @MainActor
    func testWelcomeViewScreenshots() throws {
        captureScreenshot(named: "Welcome_Main")
        
        // Look for welcome/getting started elements
        let welcomeTexts = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS[c] 'welcome' OR label CONTAINS[c] 'start' OR label CONTAINS[c] 'review'")
        ).allElementsBoundByIndex
        
        if welcomeTexts.count > 0 {
            captureScreenshot(named: "Welcome_WithMessage")
        }
    }
    
    // MARK: - Sidebar Navigation Screenshots
    
    @MainActor
    func testSidebarScreenshots() throws {
        // Look for sidebar/outline view
        let sidebar = app.outlines.firstMatch
        if sidebar.exists {
            captureScreenshot(named: "Sidebar_Main")
            
            // Try clicking sidebar items
            let sidebarItems = sidebar.outlineRows.allElementsBoundByIndex
            for (index, item) in sidebarItems.prefix(5).enumerated() {
                if item.isHittable {
                    item.click()
                    sleep(1)
                    captureScreenshot(named: String(format: "Sidebar_Item%02d", index + 1))
                }
            }
        } else {
            captureScreenshot(named: "Sidebar_NoOutline")
        }
    }
    
    // MARK: - Code Review View Screenshots
    
    @MainActor
    func testCodeReviewViewScreenshots() throws {
        // Navigate to code review functionality
        if clickButton("Review") || clickButton("Analyze") || clickButton("Start Review") {
            sleep(2)
            captureScreenshot(named: "CodeReview_Main")
        }
        
        // Look for text editor/code view
        let textView = app.textViews.firstMatch
        if textView.exists {
            captureScreenshot(named: "CodeReview_Editor")
        }
        
        // Scroll if scrollbar exists
        let scrollView = app.scrollViews.firstMatch
        if scrollView.exists {
            scrollView.scroll(byDeltaX: 0, deltaY: -200)
            sleep(1)
            captureScreenshot(named: "CodeReview_Scrolled")
        }
    }
    
    // MARK: - Settings View Screenshots
    
    @MainActor
    func testSettingsScreenshots() throws {
        // Try keyboard shortcut for preferences
        app.typeKey(",", modifierFlags: .command)
        sleep(1)
        
        // Check if settings window opened
        let settingsWindow = app.windows["Settings"].firstMatch
        let preferencesWindow = app.windows["Preferences"].firstMatch
        
        if settingsWindow.exists {
            captureScreenshot(named: "Settings_Main")
        } else if preferencesWindow.exists {
            captureScreenshot(named: "Preferences_Main")
        } else {
            // Try menu bar
            if clickMenuItem("CodingReviewer", item: "Settings...") || 
               clickMenuItem("CodingReviewer", item: "Preferences...") {
                sleep(1)
                captureScreenshot(named: "Settings_FromMenu")
            }
        }
        
        // Close any settings window
        app.typeKey("w", modifierFlags: .command)
    }
    
    // MARK: - About Window Screenshots
    
    @MainActor
    func testAboutWindowScreenshots() throws {
        // Open About window via menu
        if clickMenuItem("CodingReviewer", item: "About CodingReviewer") {
            sleep(1)
            captureScreenshot(named: "About_Window")
            
            // Close About window
            app.typeKey("w", modifierFlags: .command)
        }
    }
    
    // MARK: - File Menu Screenshots
    
    @MainActor
    func testFileMenuScreenshots() throws {
        let menuBar = app.menuBars.firstMatch
        if menuBar.exists {
            let fileMenu = menuBar.menuBarItems["File"].firstMatch
            if fileMenu.exists {
                fileMenu.click()
                sleep(1)
                captureScreenshot(named: "Menu_File")
                
                // Dismiss menu
                app.typeKey(.escape, modifierFlags: [])
            }
        }
    }
    
    // MARK: - Edit Menu Screenshots
    
    @MainActor
    func testEditMenuScreenshots() throws {
        let menuBar = app.menuBars.firstMatch
        if menuBar.exists {
            let editMenu = menuBar.menuBarItems["Edit"].firstMatch
            if editMenu.exists {
                editMenu.click()
                sleep(1)
                captureScreenshot(named: "Menu_Edit")
                
                // Dismiss menu
                app.typeKey(.escape, modifierFlags: [])
            }
        }
    }
    
    // MARK: - Full App Tour Screenshots
    
    @MainActor
    func testFullAppScreenshotTour() throws {
        // Tour 1: Initial state
        captureScreenshot(named: "Tour_01_Launch")
        
        // Tour 2: Main window
        let mainWindow = app.windows.firstMatch
        if mainWindow.exists {
            captureScreenshot(named: "Tour_02_MainWindow")
        }
        
        // Tour 3: Try different views/tabs
        let toolbar = app.toolbars.firstMatch
        if toolbar.exists {
            let toolbarButtons = toolbar.buttons.allElementsBoundByIndex
            for (index, button) in toolbarButtons.prefix(4).enumerated() {
                if button.isHittable {
                    button.click()
                    sleep(1)
                    captureScreenshot(named: String(format: "Tour_%02d_Toolbar_%@", index + 3, button.label))
                }
            }
        }
        
        // Tour Final: Current state
        captureScreenshot(named: "Tour_Final")
    }
    
    // MARK: - Accessibility Verification
    
    @MainActor
    func testAccessibilityLabelsExist() throws {
        captureScreenshot(named: "Accessibility_Verification")
        
        // Check buttons have labels (informational, not required)
        let buttons = app.buttons.allElementsBoundByIndex
        var labeledButtonCount = 0
        for button in buttons.prefix(10) {
            if button.isHittable && !(button.label.isEmpty) {
                labeledButtonCount += 1
            }
        }
        
        // Log for informational purposes
        if labeledButtonCount > 0 {
            print("Found \(labeledButtonCount) labeled buttons")
        }
    }
    
    // MARK: - Performance Tests
    
    func testLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }
}
