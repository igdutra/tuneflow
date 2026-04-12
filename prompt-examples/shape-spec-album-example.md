## Prompt

Implement Track 7 — Screen: Album.

Inject all standards.

TuneFlow needs an Album screen that opens from a selected song context and shows:
- album artwork
- album title
- album artist
- full ordered track list for that album

The target UI is the existing `mockups/album.png`:
- large hero artwork
- album title
- artist name
- vertical list of tracks
- back navigation

The shaping spec must define:
- what model boundary supports this screen
- what API call loads the album
- what route opens the screen
- what view model owns the screen
- what tests are required

## API Contract

Search remains based on the iTunes Search API:
- `https://itunes.apple.com/search`

Album loading should use the iTunes Lookup API:
- `https://itunes.apple.com/lookup?id=<collectionId>&entity=song`

Important API fact:
- album navigation depends on `collectionId`
- without `collectionId`, a selected song cannot reliably load its album

Expected lookup response shape:
- top-level envelope with `resultCount` and `results`
- one collection-style album result
- song results representing the album tracks

The shaping spec must define:
- which fields are required from the search response
- which fields are required from the lookup response
- whether search DTOs and lookup DTOs should be separate
- how the lookup payload maps into the domain

## Domain Recommendation

Make a firm recommendation on this:
- do not model the Album screen as only `[Song]`
- add the minimum navigation field needed to `Song`:
  - `collectionId: Int`
- add a second entity:
  - `Album`

Recommended repository contract:
- `func fetchAlbum(collectionId: Int) async throws -> Album`

Reasoning:
- the Album screen needs album-level metadata plus ordered tracks
- returning only `[Song]` forces callers to infer album metadata from a track array
- `Album` is the cleaner screen boundary

Preferred `Album` shape:
- `id: Int` or `collectionId: Int`
- `title: String`
- `artistName: String`
- `artworkURL: URL`
- `tracks: [Song]`

Only introduce `AlbumTrack` if the shaping work finds a concrete reason that `Song` cannot represent album track rows cleanly.

## What The Shape Spec Must Decide

Answer these concretely:

1. What exact field must be added to `Song`?
2. Should a new `Album` entity be added to TuneDomain?
3. Should `fetchAlbum(collectionId:)` return `Album` or `[Song]`?
4. What exact route should be added for album navigation?
5. What should trigger album navigation?
6. What should `viewAlbum()` do?
7. What fields are mandatory now, and what is deferred?
8. What tests are mandatory?

## Mandatory Guidance

Default to these choices unless there is a strong reason not to:

- `Song` gains `collectionId`
- `Album` is added as a new domain entity
- album loading returns `Album`
- the album endpoint is `lookup?id=<collectionId>&entity=song`
- the screen has a dedicated view model
- track ordering must be preserved

Be explicit about tradeoffs:
- if you return `[Song]`, justify why that weaker boundary is acceptable
- if you introduce `AlbumTrack`, justify why `Song` is insufficient

## Tests To Require

At minimum, require:
- mapper tests for lookup payloads containing one album result plus track rows
- repository tests validating the lookup request URL
- router tests for album route navigation
- view model tests for album loading success and failure
- tests proving track order is preserved
- tests proving album navigation does not crash when `collectionId` is unavailable or invalid

## Non-Goals

Keep the track bounded. Do not expand into:
- caching
- commerce metadata
- deep links
- genre features
- unrelated player work
- polish fields that the Album screen does not need
