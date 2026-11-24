import QtQuick

/**
 * WelcomeReveal — 3.5-second choreographed welcome entrance sequence:
 *   0–400 ms:    Background fades in
 *   400–1000 ms: Main black window scales from 96% to 100%
 *   800–1500 ms: Titan logo reveals with soft cyan glow
 *   1300–1900 ms: Product title fades and rises
 *   1700–2300 ms: Subtitle appears
 *   2300–2800 ms: Progress indicators reveal
 *   2800–3500 ms: Explore ArchTitan button appears
 */
Item {
    id: root

    property bool reducedMotion: typeof tourCtrl !== "undefined" ? tourCtrl.reducedMotion : false
    property real bgOpacity: reducedMotion ? 1.0 : 0.0
    property real windowScale: reducedMotion ? 1.0 : 0.96
    property real windowOpacity: reducedMotion ? 1.0 : 0.0
    property real logoOpacity: reducedMotion ? 1.0 : 0.0
    property real logoScale: reducedMotion ? 1.0 : 0.88
    property real titleOpacity: reducedMotion ? 1.0 : 0.0
    property real titleOffsetY: reducedMotion ? 0.0 : 18.0
    property real subtitleOpacity: reducedMotion ? 1.0 : 0.0
    property real subtitleOffsetY: reducedMotion ? 0.0 : 12.0
    property real progressOpacity: reducedMotion ? 1.0 : 0.0
    property real buttonOpacity: reducedMotion ? 1.0 : 0.0
    property real buttonOffsetY: reducedMotion ? 0.0 : 10.0

    function play() {
        if (reducedMotion) {
            completeImmediately();
            return;
        }
        bgOpacity = 0.0;
        windowScale = 0.96;
        windowOpacity = 0.0;
        logoOpacity = 0.0;
        logoScale = 0.88;
        titleOpacity = 0.0;
        titleOffsetY = 18.0;
        subtitleOpacity = 0.0;
        subtitleOffsetY = 12.0;
        progressOpacity = 0.0;
        buttonOpacity = 0.0;
        buttonOffsetY = 10.0;
        choreography.restart();
    }

    function completeImmediately() {
        choreography.stop();
        bgOpacity = 1.0;
        windowScale = 1.0;
        windowOpacity = 1.0;
        logoOpacity = 1.0;
        logoScale = 1.0;
        titleOpacity = 1.0;
        titleOffsetY = 0.0;
        subtitleOpacity = 1.0;
        subtitleOffsetY = 0.0;
        progressOpacity = 1.0;
        buttonOpacity = 1.0;
        buttonOffsetY = 0.0;
    }

    ParallelAnimation {
        id: choreography

        // 0–400 ms: Background fades in
        NumberAnimation {
            target: root; property: "bgOpacity"
            from: 0.0; to: 1.0; duration: 400; easing.type: Easing.OutCubic
        }

        // 400–1000 ms: Main black window scales from 96% to 100%
        SequentialAnimation {
            PauseAnimation { duration: 350 }
            ParallelAnimation {
                NumberAnimation {
                    target: root; property: "windowOpacity"
                    from: 0.0; to: 1.0; duration: 500; easing.type: Easing.OutCubic
                }
                NumberAnimation {
                    target: root; property: "windowScale"
                    from: 0.96; to: 1.0; duration: 650; easing.type: Easing.OutCubic
                }
            }
        }

        // 800–1500 ms: Titan logo reveals with soft cyan glow
        SequentialAnimation {
            PauseAnimation { duration: 700 }
            ParallelAnimation {
                NumberAnimation {
                    target: root; property: "logoOpacity"
                    from: 0.0; to: 1.0; duration: 750; easing.type: Easing.OutCubic
                }
                NumberAnimation {
                    target: root; property: "logoScale"
                    from: 0.88; to: 1.0; duration: 800; easing.type: Easing.OutCubic
                }
            }
        }

        // 1300–1900 ms: Product title fades and rises
        SequentialAnimation {
            PauseAnimation { duration: 1150 }
            ParallelAnimation {
                NumberAnimation {
                    target: root; property: "titleOpacity"
                    from: 0.0; to: 1.0; duration: 580; easing.type: Easing.OutCubic
                }
                NumberAnimation {
                    target: root; property: "titleOffsetY"
                    from: 18.0; to: 0.0; duration: 580; easing.type: Easing.OutCubic
                }
            }
        }

        // 1700–2300 ms: Subtitle appears
        SequentialAnimation {
            PauseAnimation { duration: 1550 }
            ParallelAnimation {
                NumberAnimation {
                    target: root; property: "subtitleOpacity"
                    from: 0.0; to: 1.0; duration: 560; easing.type: Easing.OutCubic
                }
                NumberAnimation {
                    target: root; property: "subtitleOffsetY"
                    from: 12.0; to: 0.0; duration: 560; easing.type: Easing.OutCubic
                }
            }
        }

        // 2300–2800 ms: Progress indicators reveal
        SequentialAnimation {
            PauseAnimation { duration: 2050 }
            NumberAnimation {
                target: root; property: "progressOpacity"
                from: 0.0; to: 1.0; duration: 480; easing.type: Easing.OutCubic
            }
        }

        // 2800–3500 ms: Explore ArchTitan button appears
        SequentialAnimation {
            PauseAnimation { duration: 2450 }
            ParallelAnimation {
                NumberAnimation {
                    target: root; property: "buttonOpacity"
                    from: 0.0; to: 1.0; duration: 580; easing.type: Easing.OutCubic
                }
                NumberAnimation {
                    target: root; property: "buttonOffsetY"
                    from: 10.0; to: 0.0; duration: 580; easing.type: Easing.OutCubic
                }
            }
        }
    }
}
