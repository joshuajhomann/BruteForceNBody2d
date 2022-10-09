//
//  ContentView.swift
//  Shared
//
//  Created by Joshua Homann on 2/4/22.
//

import SwiftUI


struct Body {
    var position: CGPoint
    var velocity: CGVector
    var acceleration: CGVector
    var mass: Double
}

@MainActor
final class Simulation: ObservableObject {
    private(set) var body: UnsafeBufferPointer<Body>
    private var current: UnsafeMutableBufferPointer<Body>
    private var previous: UnsafeMutableBufferPointer<Body>
    private let currentStorage: UnsafeMutablePointer<Body>
    private let previousStorage: UnsafeMutablePointer<Body>
    private var lastUpdateTime: Date?
    private var simulationSize: CGSize = .zero
    enum Constant {
        static let bodyCount = 400
    }
    init() {
        currentStorage = .allocate(capacity: Constant.bodyCount)
        previousStorage = .allocate(capacity: Constant.bodyCount)

        body = .init(start: currentStorage, count: Constant.bodyCount)
        current = .init(start: currentStorage, count: Constant.bodyCount)
        previous = .init(start: previousStorage, count: Constant.bodyCount)
    }

    deinit {
        currentStorage.deallocate()
        previousStorage.deallocate()
    }

    func update(time: Date, size: CGSize) {
        let dt = lastUpdateTime.map(time.timeIntervalSince) ?? 0
        lastUpdateTime = time
        if size != simulationSize {
            setup()
            simulationSize = size
        }
        swapBuffers()
        for (index, p) in previous.enumerated() {
            let s = p.position
            let v = p.velocity
            let a = p.acceleration
            var a1 = CGVector.zero
            for i in previous.indices where i != index {
                let dx = s.x - previous[i].position.x
                let dy = s.y - previous[i].position.y
                let m = previous[i].mass
                let dSquared = dx*dx + dy*dy
                let d1_5 = pow(dSquared, -1.5)
                let g = 1e1
                a1.dx += -(dx * g * m) * d1_5
                a1.dy += -(dy * g * m) * d1_5
            }
            let s1 = CGPoint(
                x: s.x + v.dx * dt + a.dx * dt * dt,
                y: s.y + v.dy * dt + a.dy * dt * dt
            )
            let v1 = CGVector(
                dx: v.dx + dt * 0.5 * (a.dx + a1.dx),
                dy: v.dy + dt * 0.5 * (a.dy + a1.dy)
            )
            current[index].position = s1
            current[index].velocity = v1
            current[index].acceleration = a1
        }
    }

    private func setup() {
        let minDimension = min(simulationSize.width, simulationSize.height)
        let midX = simulationSize.width*0.5
        let midY = simulationSize.height*0.5

        for index in body.indices {
            let theta = Double.random(in: 0...Double.pi * 2.0)
            let r = Double.random(in: 0.0 * minDimension...minDimension * 0.55)
            let v = Double.random(in: minDimension * -0.01...minDimension * 0.01)
            current[index].position = .init(
                x: midX + r * cos(theta),
                y: midY + r * sin(theta)
            )
            current[index].velocity =  .zero
            current[index].acceleration = .zero
            current[index].mass = 1.0
            previous[index] = current[index]
        }
    }

    private func swapBuffers() {
        if current.baseAddress == currentStorage {
            body = .init(start: previousStorage, count: Constant.bodyCount)
            current = .init(start: previousStorage, count: Constant.bodyCount)
            previous = .init(start: currentStorage, count: Constant.bodyCount)
        } else {
            body = .init(start: currentStorage, count: Constant.bodyCount)
            current = .init(start: currentStorage, count: Constant.bodyCount)
            previous = .init(start: previousStorage, count: Constant.bodyCount)
        }
    }
}


struct ContentView: View {
    @StateObject private var viewModel: Simulation
    private enum Graphic: Hashable {
        case star
    }

    init(viewModel: Simulation) {
        _viewModel = .init(wrappedValue: viewModel)
    }

    var body: some View {
        TimelineView(.animation) { timeContext in
            Canvas(
                opaque: true,
                colorMode: .linear,
                rendersAsynchronously: true,
                renderer: { context, size in
                    guard let star = context.resolveSymbol(id: Graphic.star) else { return }
                    viewModel.update(time: timeContext.date, size: size)
                    viewModel.body.forEach {
                        context.draw(star, at: $0.position)
                    }
                },
                symbols: {
                    Text("🌞").font(.system(size: 12)).tag(Graphic.star)
                }
            )
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(viewModel: .init())
    }
}
