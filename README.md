# Fundamentals of Database Systems — GitHub Pages Materials

This folder contains the course landing page, 36 HTML lessons, supporting reference images, and SQL activity files.

## Categories

- `P-*` — PRELIM
- `M-*` — MIDTERM
- `SF-*` — SEMI FINAL
- `F-*` — FINAL

## Automatic lesson locks

The landing page keeps every planned lesson card visible. When a lesson HTML file is absent from the GitHub repository, its card automatically becomes **Locked — Not Yet Available**. Upload that exact HTML file later and the card automatically becomes available after the page is refreshed. You do not need to edit `index.html`.

Example: Keep the `M-6` card locked by not uploading `M-6.html`. Upload `M-6.html` later to release it.

## Publish with GitHub Pages

1. Create a GitHub repository.
2. Upload the contents of this folder, keeping `index.html` at the repository root.
3. Open **Settings → Pages**.
4. Under **Build and deployment**, choose **Deploy from a branch**.
5. Select the `main` branch and `/ (root)`, then save.

## Local testing

Automatic lock detection requires a web server. From this folder, run:

```bash
python -m http.server 8000
```

Then open `http://localhost:8000`. Opening `index.html` directly uses browser `file:` mode and assumes local lesson files are available.

## Important files

- `index.html` — landing page
- `P-*.html`, `M-*.html`, `SF-*.html`, `F-*.html` — lesson materials
- `assets/student-visuals/` — lesson reference images
- `DB/` — SQL setup files used by activities
