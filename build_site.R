#!/usr/bin/env Rscript

# Build the dependency-free GitHub Pages site in docs/.
#
# Existing knitted HTML is reused when it is self-contained. Plain .R files,
# and .Rmd files that have not been knitted yet, are published as readable
# source pages instead. This keeps the Pages build deterministic and prevents
# assignment code from running during publication.

script_arg <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
script_path <- if (length(script_arg)) {
  sub("^--file=", "", script_arg[[1]])
} else {
  "build_site.R"
}

project_dir <- dirname(normalizePath(script_path, mustWork = TRUE))
assignments_dir <- file.path(project_dir, "assignments")
site_source_dir <- file.path(project_dir, "site")
output_dir <- file.path(project_dir, "docs")

if (!dir.exists(assignments_dir)) {
  stop("Could not find the assignments directory.")
}

html_escape <- function(value) {
  value <- gsub("&", "&amp;", value, fixed = TRUE)
  value <- gsub("<", "&lt;", value, fixed = TRUE)
  value <- gsub(">", "&gt;", value, fixed = TRUE)
  value <- gsub('"', "&quot;", value, fixed = TRUE)
  gsub("'", "&#39;", value, fixed = TRUE)
}

slugify <- function(value) {
  value <- iconv(value, from = "", to = "ASCII//TRANSLIT")
  value[is.na(value)] <- ""
  value <- tolower(value)
  value <- gsub("[^a-z0-9]+", "-", value)
  gsub("(^-+|-+$)", "", value)
}

titleize <- function(value) {
  words <- strsplit(gsub("[-_]+", " ", value), "\\s+")[[1]]
  paste(tools::toTitleCase(tolower(words)), collapse = " ")
}

extract_title <- function(path) {
  lines <- readLines(path, n = 80, warn = FALSE, encoding = "UTF-8")
  title_line <- grep("^title\\s*:", lines, value = TRUE, ignore.case = TRUE)

  if (!length(title_line)) {
    return(titleize(tools::file_path_sans_ext(basename(path))))
  }

  title <- sub("^[^:]+:\\s*", "", title_line[[1]])
  title <- gsub("^['\"]|['\"]$", "", title)
  title <- sub("^Assigment\\b", "Assignment", title)
  gsub("RMardown", "R Markdown", title, fixed = TRUE)
}

relative_to <- function(path, base) {
  normalized_path <- normalizePath(path, winslash = "/", mustWork = TRUE)
  normalized_base <- normalizePath(base, winslash = "/", mustWork = TRUE)
  substring(normalized_path, nchar(normalized_base) + 2L)
}

group_for <- function(relative_path) {
  top_directory <- strsplit(dirname(relative_path), "/", fixed = TRUE)[[1]][[1]]

  if (grepl("^assignment[_ -]?[0-9]+$", top_directory, ignore.case = TRUE)) {
    return("Assignments")
  }
  if (identical(top_directory, "exam practice")) {
    return("Practice & Study Guides")
  }
  if (top_directory %in% c("midterm", "final_exam")) {
    return("Exams")
  }
  if (identical(top_directory, "tips to work")) {
    return("Tips & Resources")
  }

  "Other Resources"
}

find_rendered_html <- function(source_path, slug) {
  candidates <- list.files(
    dirname(source_path),
    pattern = "\\.html?$",
    full.names = TRUE,
    ignore.case = TRUE
  )

  if (!length(candidates)) {
    return(NULL)
  }

  candidate_slugs <- vapply(
    tools::file_path_sans_ext(basename(candidates)),
    slugify,
    character(1)
  )
  matches <- candidates[candidate_slugs == slug]

  if (!length(matches)) {
    return(NULL)
  }

  matches[[1]]
}

read_text <- function(path) {
  paste(readLines(path, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
}

is_self_contained_html <- function(html) {
  relative_asset_pattern <- paste0(
    "(?:src|href)\\s*=\\s*[\"']",
    "(?!https?:|//|data:|#|mailto:|javascript:)",
    "[^\"']+"
  )
  !grepl(relative_asset_pattern, html, perl = TRUE, ignore.case = TRUE)
}

page_document <- function(title, body, css_path = "assets/css/course.css") {
  paste0(
    "<!doctype html>\n",
    '<html lang="en">\n',
    "<head>\n",
    '  <meta charset="utf-8">\n',
    '  <meta name="viewport" content="width=device-width, initial-scale=1">\n',
    "  <title>", html_escape(title), "</title>\n",
    '  <link rel="preconnect" href="https://fonts.googleapis.com">\n',
    '  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>\n',
    '  <link href="https://fonts.googleapis.com/css2?family=Roboto:wght@400;700&display=swap" rel="stylesheet">\n',
    '  <link rel="stylesheet" href="', css_path, '">\n',
    "</head>\n",
    '<body class="course-shell">\n',
    body,
    "\n</body>\n",
    "</html>\n"
  )
}

course_navigation <- function(download_path = NULL) {
  download_link <- if (is.null(download_path)) {
    ""
  } else {
    paste0(
      '<a href="', download_path,
      '" class="course-nav__source" download>Download source</a>'
    )
  }

  paste0(
    '<a class="skip-link" href="#main-content">Skip to content</a>',
    '<nav class="course-nav" aria-label="Course navigation">',
    '<div class="course-nav__inner">',
    '<a class="course-nav__brand" href="../">Introduction to R for Biologists</a>',
    '<div class="course-nav__links">',
    '<a href="../">Course home</a>',
    download_link,
    "</div>",
    "</div>",
    "</nav>"
  )
}

inject_course_chrome <- function(html, download_path) {
  stylesheet <- paste0(
    "\n",
    '  <link rel="preconnect" href="https://fonts.googleapis.com">', "\n",
    '  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>', "\n",
    '  <link href="https://fonts.googleapis.com/css2?family=Roboto:wght@400;700&display=swap" rel="stylesheet">', "\n",
    '  <link rel="stylesheet" href="../assets/css/course.css">', "\n"
  )

  html <- sub(
    "</head>",
    paste0(stylesheet, "</head>"),
    html,
    ignore.case = TRUE
  )

  navigation <- course_navigation(download_path)
  html <- sub(
    "(<body[^>]*>)",
    paste0("\\1\n", navigation, '\n<div id="main-content" class="course-rendered-content">'),
    html,
    perl = TRUE,
    ignore.case = TRUE
  )
  sub("</body>", "</div>\n</body>", html, ignore.case = TRUE)
}

render_source_page <- function(item) {
  source <- read_text(item$source_path)
  source_type <- toupper(sub("^\\.", "", item$extension))
  body <- paste0(
    course_navigation(paste0("../downloads/", item$download_name)),
    '<main id="main-content" class="course-page">',
    '<header class="page-heading">',
    '<p class="eyebrow">', html_escape(source_type), " source</p>",
    "<h1>", html_escape(item$title), "</h1>",
    '<p class="page-summary">This file is displayed without executing its R code.</p>',
    "</header>",
    '<pre class="source-code" tabindex="0"><code>',
    html_escape(source),
    "</code></pre>",
    "</main>",
    '<footer class="course-footer"><p>Introduction to R for Biologists</p></footer>'
  )

  page_document(item$title, body, css_path = "../assets/css/course.css")
}

render_homepage <- function(items) {
  group_order <- c(
    "Assignments",
    "Practice & Study Guides",
    "Exams",
    "Tips & Resources",
    "Other Resources"
  )
  active_groups <- group_order[group_order %in% vapply(items, `[[`, character(1), "group")]

  sections <- vapply(active_groups, function(group) {
    group_items <- items[vapply(items, `[[`, character(1), "group") == group]
    rows <- vapply(group_items, function(item) {
      paste0(
        "<tr>",
        '<td class="resource-title">',
        '<a class="resource-link" href="', item$slug, '/">',
        html_escape(item$title),
        "</a>",
        "</td>",
        '<td class="resource-file">', html_escape(basename(item$source_path)), "</td>",
        "</tr>"
      )
    }, character(1))
    item_count <- length(group_items)
    count_label <- paste(item_count, if (item_count == 1L) "entry" else "entries")

    paste0(
      '<details class="resource-section" id="', slugify(group), '">',
      "<summary>",
      '<span class="resource-section__title">', html_escape(group), "</span>",
      '<span class="resource-section__count">', count_label, "</span>",
      "</summary>",
      '<div class="resource-table-wrap">',
      '<table class="resource-table">',
      "<thead><tr><th scope=\"col\">Resource</th><th scope=\"col\">Source file</th></tr></thead>",
      "<tbody>", paste(rows, collapse = "\n"), "</tbody>",
      "</table>",
      "</div>",
      "</details>"
    )
  }, character(1))

  body <- paste0(
    '<header class="course-hero">',
    '<div class="course-hero__inner">',
    '<p class="eyebrow">',
    '<a class="course-home-link" href="https://romerocruzsa.github.io/" ',
    'aria-label="Back to the personal homepage">',
    '<span class="course-home-link__arrow" aria-hidden="true">←</span>',
    "<span>BIOL 4994 / 4991 · BIOL 6994 / 6997</span>",
    "</a>",
    "</p>",
    "<h1>Introduction to R for Biologists</h1>",
    '<p class="course-hero__lead">Course prompts, assignments, study guides, and practical R resources.</p>',
    '<p class="course-hero__languages">',
    "<strong>Espa&ntilde;ol:</strong> Aqu&iacute; encontrar&aacute;s los materiales y tutoriales de R que desarrollaremos durante la clase.<br>",
    "<strong>English:</strong> Here you will find the R materials and tutorials we will work on during class.",
    "</p>",
    "</div>",
    "</header>",
    '<main id="main-content" class="course-page course-page--home">',
    paste(sections, collapse = "\n"),
    "</main>",
    '<footer class="course-footer">',
    "<p>Maintained throughout the semester · ",
    '<a href="https://github.com/romerocruzsa/Intro_R_Biologist">View the source repository</a>',
    "</p>",
    "</footer>"
  )

  page_document("Introduction to R for Biologists", body)
}

render_not_found <- function() {
  body <- paste0(
    '<main id="main-content" class="course-page not-found">',
    '<p class="eyebrow">404</p>',
    "<h1>Course page not found</h1>",
    "<p>The requested material may have moved or may not have been published yet.</p>",
    '<p><a class="text-link" href="./">Return to the course homepage</a></p>',
    "</main>"
  )
  page_document("Page not found · Introduction to R for Biologists", body)
}

source_paths <- list.files(
  assignments_dir,
  pattern = "\\.(R|Rmd)$",
  recursive = TRUE,
  full.names = TRUE,
  ignore.case = TRUE
)

if (!length(source_paths)) {
  stop("No .R or .Rmd assignment files were found.")
}

items <- lapply(source_paths, function(source_path) {
  relative_path <- relative_to(source_path, assignments_dir)
  stem <- tools::file_path_sans_ext(basename(source_path))
  slug <- slugify(stem)
  extension <- paste0(".", tools::file_ext(source_path))

  list(
    source_path = source_path,
    relative_path = relative_path,
    slug = slug,
    title = extract_title(source_path),
    extension = extension,
    group = group_for(relative_path),
    download_name = paste0(slug, extension)
  )
})

slugs <- vapply(items, `[[`, character(1), "slug")
duplicate_slugs <- unique(slugs[duplicated(slugs)])
if (length(duplicate_slugs)) {
  stop(
    "Public route collision for: ",
    paste(duplicate_slugs, collapse = ", "),
    ". Rename one of the source files before rebuilding."
  )
}

group_rank <- c(
  "Assignments" = 1L,
  "Practice & Study Guides" = 2L,
  "Exams" = 3L,
  "Tips & Resources" = 4L,
  "Other Resources" = 5L
)
item_order <- order(
  group_rank[vapply(items, `[[`, character(1), "group")],
  vapply(items, `[[`, character(1), "relative_path")
)
items <- items[item_order]

if (dir.exists(output_dir)) {
  unlink(output_dir, recursive = TRUE)
}
dir.create(output_dir, recursive = TRUE)
dir.create(file.path(output_dir, "assets", "css"), recursive = TRUE)
dir.create(file.path(output_dir, "downloads"), recursive = TRUE)

stylesheet_source <- file.path(site_source_dir, "course.css")
if (!file.exists(stylesheet_source)) {
  stop("Could not find site/course.css.")
}
invisible(file.copy(
  stylesheet_source,
  file.path(output_dir, "assets", "css", "course.css"),
  overwrite = TRUE
))

for (item in items) {
  route_dir <- file.path(output_dir, item$slug)
  dir.create(route_dir, recursive = TRUE)

  download_path <- file.path(output_dir, "downloads", item$download_name)
  invisible(file.copy(item$source_path, download_path, overwrite = TRUE))

  rendered_path <- find_rendered_html(item$source_path, item$slug)
  output_html <- NULL

  if (!is.null(rendered_path)) {
    rendered_html <- read_text(rendered_path)
    if (is_self_contained_html(rendered_html)) {
      output_html <- inject_course_chrome(
        rendered_html,
        paste0("../downloads/", item$download_name)
      )
    }
  }

  if (is.null(output_html)) {
    output_html <- render_source_page(item)
  }

  writeLines(
    enc2utf8(output_html),
    file.path(route_dir, "index.html"),
    useBytes = TRUE
  )
}

writeLines(
  enc2utf8(render_homepage(items)),
  file.path(output_dir, "index.html"),
  useBytes = TRUE
)
writeLines(
  enc2utf8(render_not_found()),
  file.path(output_dir, "404.html"),
  useBytes = TRUE
)
invisible(file.create(file.path(output_dir, ".nojekyll")))

message(
  "Built ", length(items), " assignment routes in ",
  normalizePath(output_dir, winslash = "/")
)
