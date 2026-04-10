# Standards for Network Layer

The following standards apply to this work. Referenced by path — see the source files for full content.

---

## swift/module-composition

@agent-os/standards/swift/module-composition.md

**Why it applies:** Defines TuneFlow's layer names (TuneUI/Domain/TuneCache/TuneAPI), dependency rules, protocol boundaries, DTO strategy, and mapper patterns. This spec creates the TuneDomain shared boundary and TuneAPI's internal structure following these rules.

---

## swift/testing

@agent-os/standards/swift/testing.md

**Why it applies:** All tests in this spec use Swift Testing conventions: struct suites, `makeSUT()` with SUTBundle, spy vs stub distinction, `#expect`/`#require`, parameterized tests for status codes, and parallel safety considerations for URLProtocolStub.
