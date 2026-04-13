import TuneDomain

final class EventTrackerSpy: EventTracker {
    private(set) var trackedEvents: [any TuneEvent] = []

    func track(_ event: any TuneEvent) {
        trackedEvents.append(event)
    }
}
