import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button"]

  connect() {
    this.applyTheme(this.currentTheme)
    this.updateActiveButton()
  }

  get currentTheme() {
    return localStorage.getItem("theme") || "system"
  }

  setTheme(event) {
    const theme = event.currentTarget.dataset.theme
    localStorage.setItem("theme", theme)
    this.applyTheme(theme)
    this.updateActiveButton()
  }

  applyTheme(theme) {
    const root = document.documentElement

    if (theme === "system") {
      root.removeAttribute("data-theme")
    } else {
      root.setAttribute("data-theme", theme)
    }
  }

  updateActiveButton() {
    const currentTheme = this.currentTheme

    this.buttonTargets.forEach(button => {
      const buttonTheme = button.dataset.theme
      if (buttonTheme === currentTheme) {
        button.classList.add("btn--reversed")
        button.setAttribute("aria-pressed", "true")
      } else {
        button.classList.remove("btn--reversed")
        button.setAttribute("aria-pressed", "false")
      }
    })
  }
}
