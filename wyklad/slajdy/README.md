# Slajdy (Slidev)

Prezentacja w [Slidev](https://sli.dev), wizualnie odtwarzająca szablon prezentacji
projektu Politechniczna Sieć Via Carpatia.
Skrypt `slidev.sh` używa lokalnego Node.js (>= 22.12, na Fedorze: `sudo dnf install nodejs24-bin nodejs24-npm-bin`),
a gdy go brak - kontenera Dockera (lub Podmana: `CONTAINER_ENGINE=podman`). Slidev jest zależnością projektu (`package-lock.json`), nie trzeba go instalować globalnie.

```bash
./slidev.sh dev       # podgląd: http://localhost:3030, tryb prelegenta: /presenter
./slidev.sh remote haslo  # jw. + dostęp z sieci: sterowanie slajdami z telefonu
./slidev.sh build     # statyczna strona w dist/ - na wykład, działa bez internetu
./slidev.sh export    # PDF - kopia zapasowa
```

## Układy (frontmatter `layout:`)

| Układ | Odpowiednik w szablonie | Użycie |
|---|---|---|
| `cover` | Slajd tytułowy | `# Tytuł` + opcjonalny akapit; `subtitle:` w dolnym polu |
| `agenda` | Plan prezentacji | `# Plan prezentacji` + lista |
| `section` | Nagłówek sekcji | `# Nazwa sekcji` + opcjonalny akapit |
| `default` | Dwa elementy zawartości (pas tytułu) | pierwszy `# Tytuł` trafia do pasa, reszta pod nim |
| `two-cols` | jw., dwie kolumny | lewa kolumna, potem `::right::` i prawa |
| `end` | Slajd końcowy | treść w dużym polu, `subtitle:` (np. autor), `thanks:` (domyślnie „Dziękuję za uwagę”) |

Notatki prelegenta: komentarz HTML `<!-- ... -->` na końcu slajdu.

## Pliki

```
slides.md                 treść prezentacji
layouts/                  układy slajdów (Vue)
components/TemplateFrame.vue  rama szablonu: tło, logo, stopka z informacją o finansowaniu
styles/index.css          kolory, czcionki, położenie elementów (px na płótnie 1280×720)
setup/mermaid.ts          kolory diagramów Mermaid
public/szablon/           grafiki szablonu (tło, logo)
public/fonts/             Carlito - zamiennik Calibri (OFL), działa offline
slidev.sh                 uruchamianie: lokalny Node.js albo kontener (obraz Playwright)
```
