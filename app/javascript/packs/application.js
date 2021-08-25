// This file is automatically compiled by Webpack, along with any other files
// present in this directory. You're encouraged to place your actual application logic in
// a relevant structure within app/javascript and only use these pack files to reference
// that code so it'll be compiled.

require("@rails/ujs").start()
require("@rails/activestorage").start()
require("channels")
require("local-time").start()

window.Rails = Rails

import "@hotwired/turbo-rails"
import 'bootstrap'
import 'data-confirm-modal'
import "controllers"

$(document).on("turbo:load", () => {
    $('[data-toggle="tooltip"]').tooltip()
    $('[data-toggle="popover"]').popover()
})
