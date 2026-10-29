import SwiftUI

// One motion vocabulary for the whole app, after Apple's "Designing Fluid Interfaces" (WWDC 2018):
// springs described by response (how fast) and damping (1 = no bounce), started from wherever the view is now,
// so every animation can be interrupted and reversed. Bounce is saved for moments that earned it.
// Reduce Motion swaps movement for short cross-fades.
enum Motion {
    /// Most UI: critically damped, no overshoot.
    static let standard = Animation.spring(response: 0.35, dampingFraction: 1)
    /// Small, quick changes (selection, toggles, highlights).
    static let snappy = Animation.spring(response: 0.25, dampingFraction: 1)
    /// Panels and cards arriving (a touch of life, still settles fast).
    static let present = Animation.spring(response: 0.38, dampingFraction: 0.86)
    /// Celebrations only: stars, rewards, a right answer.
    static let celebrate = Animation.spring(response: 0.42, dampingFraction: 0.68)
    /// Pressing down: immediate, so the finger feels it on touch-down.
    static let press = Animation.easeOut(duration: 0.1)
    /// Letting go: settles without wobbling.
    static let release = Animation.spring(response: 0.3, dampingFraction: 1)

    /// The animation to use, or a short fade when Reduce Motion is on.
    static func adaptive(_ animation: Animation, reduceMotion: Bool) -> Animation {
        reduceMotion ? .easeInOut(duration: 0.18) : animation
    }
}

extension AnyTransition {
    /// A panel appearing: grows slightly from 96% and fades in, and leaves the same way it came.
    static var panel: AnyTransition { .scale(scale: 0.96).combined(with: .opacity) }

    /// Moving deeper into a place (list → game): slides in from the trailing edge, back out the same way.
    static var pushIn: AnyTransition {
        .asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .trailing).combined(with: .opacity))
    }

    /// The screen you came from: drifts a little to the leading side instead of flying off.
    static var pushedBack: AnyTransition {
        .asymmetric(insertion: .offset(x: -40).combined(with: .opacity),
                    removal: .offset(x: -40).combined(with: .opacity))
    }
}

extension View {
    /// Big titles: tighter tracking, as large type reads better slightly condensed.
    func displayTracking(_ size: CGFloat) -> some View {
        tracking(size >= 28 ? -0.6 : size >= 20 ? -0.3 : 0)
    }
}
