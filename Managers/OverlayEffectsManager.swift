import SwiftUI
import Combine

/// Controls full-screen visual effects overlaid on the app
@MainActor
class OverlayEffectsManager: ObservableObject {
    static let shared = OverlayEffectsManager()
    
    @Published var currentEffect: OverlayEffect = .none
    
    /// Unique ID for the current effect instance. Used to prevent stale dismiss callbacks.
    @Published private(set) var effectID: UUID = UUID()
    
    // Timer for periodic effects
    private var periodicTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    /// Task for auto-dismiss - cancelled when new effect starts
    private var dismissTask: Task<Void, Never>?
    
    private init() {
        setupThemeObservation()
    }
    
    // MARK: - API
    
    func showEffect(_ effect: OverlayEffect) {
        // Cancel any pending dismiss from previous effect
        dismissTask?.cancel()
        dismissTask = nil
        
        // Generate new ID for this effect instance
        effectID = UUID()
        withAnimation {
            currentEffect = effect
        }
        
        // Schedule auto-dismiss (centralized - views don't manage this anymore)
        if effect != .none {
            scheduleDismiss(for: effect, id: effectID)
        }
    }
    
    func forceTriggerEffect() {
        if case .periodic(let effect, _, _) = ThemeManager.shared.currentTheme.ambientEffect {
            // Cancel any running dismiss first
            dismissTask?.cancel()
            dismissTask = nil
            
            // Clear then re-show
            withAnimation { currentEffect = .none }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                self?.showEffect(effect)
            }
        }
    }
    
    /// Dismiss the current effect. Only dismisses if the caller's ID matches the current effectID.
    func dismiss(id: UUID? = nil) {
        // If an ID is provided, only dismiss if it matches (prevents stale callbacks)
        if let id = id, id != effectID {
            return // Silently ignore stale dismiss
        }
        
        // Cancel pending auto-dismiss
        dismissTask?.cancel()
        dismissTask = nil
        
        withAnimation {
            // Only dismiss if not forced constant by theme
            if case .constant(let effect) = ThemeManager.shared.currentTheme.ambientEffect {
                if currentEffect == effect { return } // Cannot dismiss constant effect
                // If dismissing a temporary effect, restore constant
                currentEffect = effect
            } else {
                currentEffect = .none
            }
        }
    }
    
    // MARK: - Private: Auto-Dismiss Scheduling
    
    private func scheduleDismiss(for effect: OverlayEffect, id: UUID) {
        let duration = effect.duration
        guard duration > 0 else { return }
        
        dismissTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(duration))
            
            // Only dismiss if task wasn't cancelled and ID still matches
            guard !Task.isCancelled else { return }
            self?.dismiss(id: id)
        }
    }
    
    // MARK: - Theme Observation
    
    private func setupThemeObservation() {
        ThemeManager.shared.$currentTheme
            .sink { [weak self] newTheme in
                self?.handleThemeChange(newTheme)
            }
            .store(in: &cancellables)
    }
    
    private func handleThemeChange(_ theme: any Theme) {
        // Cancel any pending operations
        dismissTask?.cancel()
        dismissTask = nil
        periodicTimer?.invalidate()
        periodicTimer = nil
        
        switch theme.ambientEffect {
        case .none:
            currentEffect = .none
            
        case .constant(let effect):
            showEffect(effect)
            
        case .periodic(let effect, let minInterval, let maxInterval):
            currentEffect = .none
            scheduleNextPeriodicEffect(effect: effect, min: minInterval, max: maxInterval)
        }
    }
    
    private func scheduleNextPeriodicEffect(effect: OverlayEffect, min: TimeInterval, max: TimeInterval) {
        let interval = Double.random(in: min...max)
        
        periodicTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.triggerPeriodicEffect(effect, min: min, max: max)
            }
        }
    }
    
    private func triggerPeriodicEffect(_ effect: OverlayEffect, min: TimeInterval, max: TimeInterval) {
        // Ensure we start clean - force clear if stuck
        if currentEffect != .none {
            withAnimation { currentEffect = .none }
            // Wait for clear, then show
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
                self?.showEffect(effect)
                self?.scheduleNextAfterDismiss(effect: effect, min: min, max: max)
            }
        } else {
            showEffect(effect)
            scheduleNextAfterDismiss(effect: effect, min: min, max: max)
        }
    }
    
    private func scheduleNextAfterDismiss(effect: OverlayEffect, min: TimeInterval, max: TimeInterval) {
        // Schedule next occurrence AFTER this effect's duration + buffer
        let rescheduleDelay = effect.duration + 0.3
        DispatchQueue.main.asyncAfter(deadline: .now() + rescheduleDelay) { [weak self] in
            guard let self = self else { return }
            // Only reschedule if theme still uses this effect
            if case .periodic(let e, _, _) = ThemeManager.shared.currentTheme.ambientEffect,
               e == effect {
                self.scheduleNextPeriodicEffect(effect: effect, min: min, max: max)
            }
        }
    }
}

