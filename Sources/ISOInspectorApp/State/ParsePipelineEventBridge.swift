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
        private let subject = PassthroughSubject<ParseEvent, Error>()
        private var stream: ParsePipeline.EventStream?
        private var streamingTask: Task<Void, Never>?
        private var hasStarted = false
        private let lock = NSLock()

        init(stream: ParsePipeline.EventStream) {
            self.stream = stream
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
            lock.lock()
            hasStarted = true
            stream = nil
            let task = streamingTask
            streamingTask = nil
            lock.unlock()

            let shouldFinishImmediately = task == nil
            task?.cancel()
            if shouldFinishImmediately {
                subject.send(completion: .finished)
            }
        }

        private func startStreamingIfNeeded() {
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
                            subject.send(event)
                        }
                        subject.send(completion: .finished)
                    } catch {
                        if error is CancellationError {
                            subject.send(completion: .finished)
                        } else {
                            subject.send(completion: .failure(error))
                        }
                    }
                }
            } else {
                task = nil
            }
            streamingTask = task
            lock.unlock()

            if stream == nil {
                subject.send(completion: .finished)
            }
        }
    }
}
#endif
