//
//  PlayerEvent.swift
//  TuneFlow
//
//  Created by Ivo on 13/04/26.
//

import Foundation
import TuneDomain

struct PlayerEvent: TuneEvent {
    let name: String
    let parameters: [String: String]
    
    private init(name: String, parameters: [String : String]) {
        self.name = name
        self.parameters = parameters
    }

    static func screenViewed(songName: String, artist: String) -> Self {
        .init(
            name: "player_screen_viewed",
            parameters: [
                "song_name": songName,
                "artist": artist
            ]
        )
    }
}
