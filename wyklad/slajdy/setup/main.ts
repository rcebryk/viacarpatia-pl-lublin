// Widok prezentera: akapit notatek dla bieżącego kliknięcia ([click]) przewijany do GÓRY panelu.
// Slidev sam przewija go na środek (scrollIntoView block: 'center'), przez co dłuższy akapit
// bywa ucięty u dołu. Obserwator łapie moment, w którym znacznik dostaje klasę "-active",
// i nadpisuje to przewinięcie (działa po kodzie Slidev, bo MutationObserver to mikrozadanie).
import { defineAppSetup } from '@slidev/types'

const ACTIVE = 'slidev-note-click-mark-active'

export default defineAppSetup(() => {
  if (typeof window === 'undefined' || typeof MutationObserver === 'undefined')
    return

  const observer = new MutationObserver((mutations) => {
    for (const m of mutations) {
      const el = m.target as HTMLElement
      const wasActive = (m.oldValue ?? '').split(/\s+/).includes(ACTIVE)
      if (!wasActive && el.classList?.contains(ACTIVE))
        el.scrollIntoView({ block: 'start', behavior: 'smooth' })
    }
  })

  observer.observe(document.documentElement, {
    subtree: true,
    attributes: true,
    attributeFilter: ['class'],
    attributeOldValue: true,
  })
})
