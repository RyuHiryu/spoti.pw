// Pages that list Spotify's flags by topic; every row forces one flag.
#import "Settings/SGModPage.h"
#import "Flags.h"

UIViewController *SGLockScreenSettingsPage(void) {
    return [[SGModPage alloc] initWithTitle:@"Lock screen widget" intro:SGRestartNote sections:@[
        SGSection(@"Spotify's flags", @[
            SGFlagRow(@"Like and dislike buttons", @"ios-feature-lockscreen.like_dislike_enabled"),
            SGFlagRow(@"Animated artwork", @"ios-feature-lockscreen.animated_artwork_enabled"),
            SGFlagRow(@"Video artwork", @"ios-feature-lockscreen.vit_artwork_enabled"),
            SGFlagRow(@"Companion content", @"ios-feature-lockscreen.companion_content_enabled"),
            SGFlagRow(@"Burst skip", @"ios-feature-lockscreen.burst_skip_enabled"),
            SGFlagRow(@"Chapter skip controls", @"ios-feature-lockscreen.enable_chapter_skip_controls"),
            SGFlagRow(@"Skip button on podcasts", @"ios-feature-lockscreen.skip_button_on_podcasts"),
        ]),
    ] footer:nil];
}

UIViewController *SGPlaybackSettingsPage(void) {
    return [[SGModPage alloc] initWithTitle:@"Playback" intro:SGRestartNote sections:@[
        SGSection(@"Queue", @[
            SGFlagRow(@"Play next in the context menu", @"ios-feature-queue.is_play_next_context_menu_enabled"),
        ]),
        SGSection(@"Player", @[
            SGFlagRow(@"New progress slider", @"ios-feature-encoreexperiments.new_npv_slider_enabled"),
            SGFlagRow(@"Connect as a bottom sheet", @"ios-feature-nowplaying-elements.enable_connect_bottom_sheet"),
            SGFlagRow(@"Connect sheet from the video switcher", @"ios-playbackcontrol-audiovideoswitcher-impl.enable_connect_bottom_sheet"),
        ]),
        SGSection(@"Now playing bar", @[
            SGFlagRow(@"Hold and drag to resize", @"ios-feature-nowplayingbar.hold_and_drag_to_resize"),
            SGFlagRow(@"Save button", @"ios-feature-nowplayingbar.add_button"),
            SGFlagRow(@"Queue badge", @"ios-feature-nowplayingbar.queue_badge"),
            SGFlagRow(@"Two lines of track info", @"ios-feature-nowplayingbar.two_lines_information_unit"),
        ]),
    ] footer:nil];
}

// Every switch here forces a flag Spotify ships on to off, so the switch off is Spotify's own value.
UIViewController *SGAdsSettingsPage(void) {
    return [[SGModPage alloc] initWithTitle:@"Ads & nags" intro:SGRestartNote sections:@[
        SGSection(@"Ads", @[
            SGKillRow(@"Ad when the app opens", @"ios-feature-adonappopen.enabled"),
            SGKillRow(@"Its CTA card", @"ios-feature-adonappopen.cta_card_enabled"),
        ]),
        SGSection(@"Upsells", @[
            SGKillRow(@"Shuffle toggle upsell", @"ios-feature-shuffletoggleupsell.is_enabled_pt2"),
            SGKillRow(@"Shuffle upsell in the video player", @"ios-feature-nowplaying-modes.video_first_shuffle_upsell_enabled"),
        ]),
        SGSection(@"Badges", @[
            SGKillRow(@"DJ beta badge", @"ios-home-evopage-impl.dj_mdc_beta_badge_enabled"),
            SGKillRow(@"DJ button on Home", @"ios-home-evopage-impl.idj_show_dj_button"),
        ]),
        SGSection(@"Tooltips", @[
            SGKillRow(@"Data saver", @"ios-feature-nowplayingbar.data_saver_tooltip"),
            SGKillRow(@"Smart shuffle helper", @"ios-messaging-reduceinterventions-impl.enable_message_smart_shuffle_helper_tooltip"),
            SGKillRow(@"Watch feed explorer", @"ios-messaging-reduceinterventions-impl.enable_message_watch_feed_entity_explorer_tooltip"),
            SGKillRow(@"AI playlist creation", @"ios-messaging-reduceinterventions-impl.enable_message_your_library_ai_playlist_creation_tooltip"),
            SGKillRow(@"Account switching", @"ios-messaging-reduceinterventions-impl.enable_message_account_switching_tooltip"),
            SGKillRow(@"Concert notifications", @"ios-messaging-reduceinterventions-impl.enable_message_live_events_concert_notifications_tooltip"),
            SGKillRow(@"Live event", @"ios-messaging-reduceinterventions-impl.enable_message_live_events_event_entity_safe_tooltip"),
            SGKillRow(@"Live event venue", @"ios-messaging-reduceinterventions-impl.enable_message_live_events_event_entity_venuename_header_tooltip"),
            SGKillRow(@"Player suggestions upsell", @"ios-messaging-reduceinterventions-impl.enable_message_reinvent_free_n_p_v_suggestions_upsell"),
            SGKillRow(@"Puffin nudge", @"ios-messaging-reduceinterventions-impl.enable_message_puffin_nudge_end_optimization"),
        ]),
        SGSection(nil, @[
            SGFlagRow(@"Reduce interventions", @"ios-messaging-reduceinterventions-impl.enabled"),
        ]),
    ] footer:@"The tooltip switches belong to Spotify's own intervention-reduction system, which the last switch turns on."];
}

UIViewController *SGUnreleasedSettingsPage(void) {
    return [[SGModPage alloc] initWithTitle:@"Unreleased" intro:SGRestartNote sections:@[
        SGSection(@"Player", @[
            SGFlagRow(@"Snake on the cover art", @"ios-feature-cover-art-snake.enabled"),
        ]),
        SGSection(@"Podcast comments", @[
            SGFlagRow(@"Comments card", @"ios-feature-comments.enable_comments_card"),
            SGFlagRow(@"Pinned comments", @"ios-feature-comments.enable_pinned_comments"),
            SGFlagRow(@"Several reactions", @"ios-feature-comments.enable_multi_reactions"),
        ]),
        SGSection(@"Sleep timer", @[
            SGFlagRow(@"Fade out", @"ios-feature-sleeptimer.enable_fade_out"),
            SGFlagRow(@"One minute option", @"ios-feature-sleeptimer.enable_one_minute_option"),
            SGFlagRow(@"Options sheet", @"ios-feature-sleeptimer.use_options_sheet"),
        ]),
        SGSection(@"Elsewhere", @[
            SGFlagRow(@"Local files from the Files app", @"ios-feature-localfiles.documents_enabled"),
            SGFlagRow(@"Progress bar in the home screen widget", @"ios-widgets-widgetremoteconfig-impl.progress_bar_enabled"),
        ]),
    ] footer:nil];
}

static UIViewController *martiniPage(void) {
    return [[SGModPage alloc] initWithTitle:@"AI Chat (Martini)" intro:SGRestartNote sections:@[
        SGSection(@"On Home", @[
            SGFlagRow(@"Chat entry point", @"ios-home-evopage-impl.interactive_entrypoint_enabled"),
            SGFlagRow(@"Martini behind it", @"ios-home-evopage-impl.interactive_entrypoint_martini_enabled"),
            SGFlagRow(@"Floating chat", @"ios-home-evopage-impl.interactive_entrypoint_floating_chat_enabled"),
            SGFlagRow(@"Microphone", @"ios-home-evopage-impl.interactive_entrypoint_mic_enabled"),
            SGFlagRow(@"Glowing pill", @"ios-home-evopage-impl.interactive_entrypoint_pill_glow_enabled"),
        ]),
        SGSection(@"The chat", @[
            SGFlagRow(@"Intent pills", @"ios-martini-floatingchat-impl.intent_pills_enabled"),
            SGFlagRow(@"Thinking states", @"ios-martini-floatingchat-impl.thinking_states_enabled"),
            SGFlagRow(@"Voice recording", @"ios-martini-floatingchat-impl.voice_recording_enabled"),
        ]),
        SGSection(@"In the player", @[
            SGFlagRow(@"Chat entry point", @"ios-martini-npvcardprovider-impl.floating_chat_entry_point_enabled"),
        ]),
    ] footer:nil];
}

UIViewController *SGExperimentalSettingsPage(void) {
    return [[SGModPage alloc] initWithTitle:@"Experimental" intro:nil sections:@[
        SGSection(nil, @[
            SGPageRow(@"AI Chat (Martini)", ^UIViewController *{ return martiniPage(); }),
        ]),
    ] footer:nil];
}
