@_exported import Foundation
public struct CGVector: Equatable { public var dx: CGFloat; public var dy: CGFloat
  public init(dx: CGFloat, dy: CGFloat) { self.dx = dx; self.dy = dy }
  public init(dx: Double, dy: Double) { self.dx = CGFloat(dx); self.dy = CGFloat(dy) }
  public static var zero: CGVector { CGVector(dx: CGFloat(0), dy: CGFloat(0)) } }
