// Kolory diagramów Mermaid dopasowane do szablonu (granat + jasne linie)
import { defineMermaidSetup } from '@slidev/types'

export default defineMermaidSetup(() => ({
  theme: 'base',
  themeVariables: {
    fontFamily: 'Calibri, Carlito, sans-serif',
    fontSize: '20px',
    primaryColor: '#223962',
    primaryTextColor: '#ffffff',
    primaryBorderColor: '#9cc3ff',
    lineColor: '#cfe0ff',
    textColor: '#ffffff',
    edgeLabelBackground: '#0a1a33',
  },
}))
