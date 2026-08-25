# Introduction to R for Biologists

Course assignments, study guides, and R tutorials published at:

<https://romerocruzsa.github.io/Intro_R_Biologist/>

## Publishing course materials

The website is a static GitHub Pages site built into `docs/`. It deliberately
uses base R and pre-rendered HTML instead of Quarto or a server-side framework.

1. Add an `.Rmd` or `.R` file anywhere under `assignments/`.
2. For an `.Rmd`, knit it in RStudio if the page should include executed output
   and plots. Leave the generated `.html` beside its source file.
3. Run:

   ```sh
   Rscript build_site.R
   ```

4. Review `docs/index.html`, then commit the source and regenerated `docs/`
   files together.

The public URL is derived from the filename using lowercase kebab case. For
example:

- `assignment_4.Rmd` becomes `/Intro_R_Biologist/assignment-4/`
- `Study Guide dplyr.Rmd` becomes `/Intro_R_Biologist/study-guide-dplyr/`

Each page also provides the original source as a download. Plain `.R` files are
shown as code and are never executed during publication. If an `.Rmd` has no
matching self-contained HTML file, its source is shown instead, so a missing R
package cannot break the website build.

## GitHub Pages setting

Configure the repository’s Pages source as **Deploy from a branch**, using the
`main` branch and the `/docs` folder.