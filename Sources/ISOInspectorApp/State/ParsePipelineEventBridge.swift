#if canImport(Combine)
import Combine
import Foundation
import ISOInspectorKit

public struct ParsePipelineEventBridge {
    public init() {}

    public func makeConnection(
        pipeline: ParsePipeline,
        reader: RandomAccessReader,
        context: ParsePipeline.Context = .init()
    ) -> Connection {
        let stream = pipeline.events(for: reader, context: context)
        return makeConnection(stream: stream)
    }

    public func makeConnection(stream: ParsePipeline.EventStream) -> Connection {
        Connection(stream: stream)
    }

    public final class Connection {
        private let subject: PassthroughSubject<ParseEvent, Error>
        private let relay: SubjectRelay
        private var stream: ParsePipeline.EventStream?
        private var streamingTask: Task<Void, Never>?
        private var hasStarted = false
        private let lock = NSLock()

        init(stream: ParsePipeline.EventStream) {
            self.stream = stream
            let subject = PassthroughSubject<ParseEvent, Error>()
            let box = SendableSubject(subject: subject)
            self.subject = subject
            self.relay = SubjectRelay(subject: box)
        }

        deinit {
            cancel()
        }

        public var events: AnyPublisher<ParseEvent, Error> {
            subject
                .handleEvents(receiveSubscription: { [weak self] _ in
                    self?.startStreamingIfNeeded()
                }, receiveCancel: { [weak self] in
                    self?.cancel()
                })
                .eraseToAnyPublisher()
        }

        public func cancel() {
            let relay = self.relay
            lock.lock()
            hasStarted = true
            stream = nil
            let task = streamingTask
            streamingTask = nil
            lock.unlock()

            let shouldFinishImmediately = task == nil
            task?.cancel()
            if shouldFinishImmediately {
                Task { await relay.finish() }
            }
        }

        private func startStreamingIfNeeded() {
            let relay = self.relay
            let stream: ParsePipeline.EventStream?
            let task: Task<Void, Never>?

            lock.lock()
            if hasStarted {
                lock.unlock()
                return
            }
            hasStarted = true
            stream = self.stream
            self.stream = nil
            if let stream {
                task = Task {
                    do {
                        for try await event in stream {
                            await relay.send(event)
                        }
                        await relay.finish()
                    } catch {
                        if error is CancellationError {
                            await relay.finish()
                        } else {
                            await relay.fail(error)
                        }
                    }
                }
            } else {
                task = nil
            }
            streamingTask = task
            lock.unlock()

            if stream == nil {
                Task { await relay.finish() }
            }
        }
    }
}

private struct SendableSubject: @unchecked Sendable {
    let subject: PassthroughSubject<ParseEvent, Error>
}

private actor SubjectRelay {
    private let subject: SendableSubject

    init(subject: SendableSubject) {
        self.subject = subject
    }

    func send(_ event: ParseEvent) {
        subject.subject.send(event)
    }

    func finish() {
        subject.subject.send(completion: .finished)
    }

    func fail(_ error: Error) {
        subject.subject.send(completion: .failure(error))
    }
}
#endif
