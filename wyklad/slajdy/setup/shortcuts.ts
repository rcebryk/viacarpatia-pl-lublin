// Skróty prowadzącego: szybki powrót do mapy wykładu (slajd "Droga commita").
//   m - skok na slajd z aliasem "droga" (zapamiętuje, skąd przyszliśmy)
//   b - powrót na zapamiętany slajd i to samo kliknięcie
// Działa w widoku prezentera i w zwykłym widoku; nawigacja synchronizuje się między laptopami.
import { defineShortcutsSetup } from '@slidev/types'
import { useNav } from '@slidev/client'

const MAP_ALIAS = 'droga'

export default defineShortcutsSetup((nav, base) => {
  const { slides, currentSlideNo, clicks, go } = useNav()
  let back: { no: number, clicks: number } | null = null

  const mapNo = () => slides.value.find(s => s.meta.slide?.frontmatter.routeAlias === MAP_ALIAS)?.no

  return [
    ...base,
    {
      name: 'goto_map',
      key: 'm',
      fn: () => {
        const target = mapNo()
        if (!target || currentSlideNo.value === target)
          return
        back = { no: currentSlideNo.value, clicks: clicks.value }
        go(target)
      },
    },
    {
      name: 'back_from_map',
      key: 'b',
      fn: () => {
        if (!back)
          return
        const { no, clicks: c } = back
        back = null
        go(no, c)
      },
    },
  ]
})
