package hello_world

import k2 ".."

main :: proc() {
    k2.init(1280, 720, "Greetings from Karl2D!")

    for k2.update() {
        k2.clear(k2.LIGHT_BLUE)
        k2.draw_text("Hellope!", {50, 50}, 100, k2.DARK_BLUE)
        k2.present()
    }

    k2.shutdown()
}
