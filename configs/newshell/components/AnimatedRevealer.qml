import qs.services

Expander {
    id: root

    property bool revealed: false

    expanded: revealed
    duration: Config.motion.medium
}
