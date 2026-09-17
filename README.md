# Introduction to R for Biologists

Course assignments, study guides, and R tutorials published at:

<https://romerocruzsa.github.io/Intro_R_Biologist/>

## Adding new course work

Put every new assignment or project inside the `assignments` folder.

For example, create this file for Homework 2:

```text
assignments/homework-2/homework-2.Rmd
```

You can also add data, images, and other files to the same folder.

## Publishing the website

1. If you added an `.Rmd` file, knit it in RStudio. Keep the generated HTML file
   beside the R Markdown file and use the same filename:

   ```text
   assignments/homework-2/homework-2.Rmd
   assignments/homework-2/homework-2.html
   ```

2. From the main project folder, run:

   ```sh
   Rscript build_site.R
   ```

3. Open `docs/index.html` and check the new page.
4. Commit the new course files and the updated `docs` folder together.

Do not add course work directly to `docs`. The publishing script rebuilds that
folder.

## How publishing works

- The script publishes `.R` and `.Rmd` files found inside `assignments`.
- A knitted HTML file keeps its R Markdown design. The script only adds the
  course header.
- If an `.Rmd` file has no matching HTML file, the website displays its source
  code without running it.
- Plain `.R` files are also displayed as source code and are not executed.
- The course homepage includes a download link for each source file.

Inherited materials listed in `site/hidden_sources.txt` are excluded from the
website. Remove a file path from that list when you are ready to publish it.

The website address comes from the filename. For example:

- `assignment_4.Rmd` becomes `/Intro_R_Biologist/assignment-4/`
- `Study Guide dplyr.Rmd` becomes `/Intro_R_Biologist/study-guide-dplyr/`

## GitHub Pages setting

Configure the repository’s Pages source as **Deploy from a branch**, using the
`main` branch and the `/docs` folder.