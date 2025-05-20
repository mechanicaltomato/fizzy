import { Controller } from "@hotwired/stimulus"
import { signedDifferenceInDays } from "helpers/date_helpers"

const REFRESH_INTERVAL = 3_600_000 // 1 hour (in milliseconds)

export default class extends Controller {
  static targets = [ "top", "days", "bottom" ]
  static values = { "closesAt": String, "reminderBefore": Number, "entropyAction": String }

  #timer

  connect() {
    this.#timer = setInterval(this.update.bind(this), REFRESH_INTERVAL)
    this.update()
  }

  disconnect() {
    clearInterval(this.#timer)
  }

  update() {
    const closesInDays = signedDifferenceInDays(new Date(), new Date(this.closesAtValue))

    if (closesInDays > this.reminderBeforeValue) {
      this.#hide()
      return
    }

    this.topTarget.innerHTML = closesInDays < 1 ? this.entropyActionValue : `${this.entropyActionValue} in`
    this.daysTarget.innerHTML = closesInDays < 1 ? "!" : closesInDays
    this.bottomTarget.innerHTML = closesInDays < 1 ? "Today" : (closesInDays === 1 ? "day" : "days")

    this.#show()
  }

  #hide() {
    this.element.setAttribute("hidden", "")
  }

  #show() {
    this.element.removeAttribute("hidden")
  }
}
