import { Controller } from "@hotwired/stimulus"

// FIXME: Can we do this without a controller? https://github.com/basecamp/fizzy/pull/130#discussion_r1833094616
export default class extends Controller {
  merge({ params: { key, value } }) {
    const url = new URL(window.location.href)
    url.searchParams.set(key, value)
    Turbo.visit(url)
  }
}
