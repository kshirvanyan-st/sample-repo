import GrainfallCore
import MetalKit
import QuartzCore

/// Draws the simulation's RGBA8 frame with Metal: one texture upload + one 4-vertex strip per frame.
/// Triple-buffered so the CPU never writes a texture the GPU is still reading.
@MainActor
final class PixelRenderer: NSObject, MTKViewDelegate, PixelSurface {
    static let maxFramesInFlight = 3

    var frameSource: (@MainActor (_ now: Double) -> [UInt32])?
    var insets: (top: Double, bottom: Double) = (0, 0)

    private let device: MTLDevice
    private let queue: MTLCommandQueue
    private let pipeline: MTLRenderPipelineState
    private let textures: [MTLTexture]
    private var frameIndex = 0
    private let inFlight = DispatchSemaphore(value: PixelRenderer.maxFramesInFlight)

    init?(view: MTKView) {
        guard let device = view.device ?? MTLCreateSystemDefaultDevice(),
              let queue = device.makeCommandQueue(),
              let library = device.makeDefaultLibrary() else { return nil }
        self.device = device
        self.queue = queue

        let desc = MTLRenderPipelineDescriptor()
        desc.label = "Grid"
        desc.vertexFunction = library.makeFunction(name: "grid_vertex")
        desc.fragmentFunction = library.makeFunction(name: "grid_fragment")
        desc.colorAttachments[0].pixelFormat = view.colorPixelFormat
        guard let pipeline = try? device.makeRenderPipelineState(descriptor: desc) else { return nil }
        self.pipeline = pipeline

        let tdesc = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba8Unorm, width: Grid.width,
                                                             height: Grid.height, mipmapped: false)
        tdesc.usage = .shaderRead
        tdesc.storageMode = .shared
        var textures: [MTLTexture] = []
        for _ in 0..<PixelRenderer.maxFramesInFlight {
            guard let t = device.makeTexture(descriptor: tdesc) else { return nil }
            textures.append(t)
        }
        self.textures = textures
        super.init()

        view.device = device
        let bg = Palette.background
        view.clearColor = MTLClearColor(red: Double(bg.r) / 255, green: Double(bg.g) / 255, blue: Double(bg.b) / 255, alpha: 1)
        view.preferredFramesPerSecond = 120 // ProMotion; the simulation itself is fixed at 60 Hz.
        view.delegate = self
    }

    // MTKView calls its delegate on the main thread; hop explicitly so this compiles whether or
    // not the SDK annotates MTKViewDelegate as main-actor isolated.
    nonisolated func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}

    nonisolated func draw(in view: MTKView) {
        MainActor.assumeIsolated { render(in: view) }
    }

    private func render(in view: MTKView) {
        guard let frameSource else { return }
        let pixels = frameSource(CACurrentMediaTime())
        guard pixels.count == Grid.width * Grid.height,
              let pass = view.currentRenderPassDescriptor,
              let drawable = view.currentDrawable else { return }

        inFlight.wait()
        frameIndex = (frameIndex + 1) % textures.count
        let texture = textures[frameIndex]
        pixels.withUnsafeBytes { raw in
            texture.replace(region: MTLRegionMake2D(0, 0, Grid.width, Grid.height), mipmapLevel: 0,
                            withBytes: raw.baseAddress!, bytesPerRow: Grid.width * 4)
        }

        guard let cmd = queue.makeCommandBuffer(),
              let enc = cmd.makeRenderCommandEncoder(descriptor: pass) else { inFlight.signal(); return }
        let box = Letterbox(viewWidth: view.bounds.width, viewHeight: view.bounds.height,
                            topInset: insets.top, bottomInset: insets.bottom)
            .scaled(by: view.drawableSize.width / max(1, view.bounds.width))
        enc.setViewport(MTLViewport(originX: box.x, originY: box.y, width: box.width, height: box.height, znear: 0, zfar: 1))
        enc.setRenderPipelineState(pipeline)
        enc.setFragmentTexture(texture, index: 0)
        enc.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
        enc.endEncoding()

        let semaphore = inFlight
        cmd.addCompletedHandler { _ in semaphore.signal() }
        cmd.present(drawable)
        cmd.commit()
    }
}
