#' Plot releases
#'
#' Plots the counts from [dig_tally()] with a title, a subtitle that says
#' what is shown, and alt text for screen readers. Genres, styles,
#' formats, labels, artists, roles and countries are drawn as ranked
#' lollipops with the count and share at each tip. Decades are columns
#' with their counts, years are columns with the busiest year marked, and
#' `by = "added"` is a line of the running total. Plotting needs the
#' ggplot2 package.
#'
#' The colours have a contrast of at least 3:1 with the background, and
#' every value that is not on an axis is written next to its mark, so no
#' value depends on colour alone. The title, subtitle and alt text can be
#' changed with [ggplot2::labs()].
#'
#' Every plot has the caption "Data provided by Discogs.", which the API
#' Terms of Use require next to any data from 'Discogs'. Where you publish
#' a plot, link the caption to the 'Discogs' page with the data. Plots of
#' a collection or wantlist show Restricted Data, see [dig_collection()].
#'
#' @inheritParams dig_tally
#'
#' @return A ggplot object, which can be changed with `+`, or `NULL`
#'   invisibly if `x` is `NULL`.
#'
#' @examplesIf interactive() && rlang::is_installed("ggplot2")
#' collection <- dig_collection("username", all = TRUE)
#' dig_plot(collection, "decade")
#' dig_plot(collection, "added")
#' dig_plot(dig_artist_releases(1, all = TRUE), "role")
#'
#' @export
dig_plot <- function(x,
                     by = c("genre", "style", "format", "label", "artist", "role", "country",
                            "decade", "year", "added"),
                     n = 10, unique = FALSE) {
  by <- rlang::arg_match(by)
  rlang::check_installed("ggplot2", reason = "to plot releases.")
  data <- tally_collection(x, by, n, unique)
  if (is.null(data)) {
    return(invisible(NULL))
  }
  total <- if (unique) nrow(dplyr::distinct(x, dplyr::across(dplyr::all_of(release_key(x))))) else nrow(x)
  unit <- if (unique || !"instance_id" %in% names(x)) "releases" else "copies"
  about <- list(by = by, total = total, unit = unit)
  if (nrow(data) == 0) {
    return(plot_empty(about))
  }
  plot <- switch(by,
    decade = plot_decades(data, about),
    year = plot_years(data, about),
    added = plot_growth(data, about),
    plot_ranking(data, n, nrow(tally_collection(x, by, Inf, unique)), about)
  )
  plot
}

credit <- "Data provided by Discogs."

dig_colours <- c(
  surface = "#fcfcfb", ink = "#0b0b0b", ink_soft = "#52514e", muted = "#898781",
  grid = "#e1e0d9", accent = "#2a78d6"
)

plot_ranking <- function(data, n, values, about) {
  names(data)[1] <- "value"
  lumped <- seq_len(nrow(data)) > n
  colour <- dplyr::if_else(lumped, dig_colours[["muted"]], dig_colours[["accent"]])
  if (about$by == "role") {
    data$value <- keep_distinct(
      data$value,
      stringr::str_to_sentence(stringr::str_replace_all(data$value, "([a-z])([A-Z])", "\\1 \\2"))
    )
  }
  data$value <- keep_distinct(data$value, stringr::str_wrap(data$value, 28))
  data$value <- factor(data$value, levels = rev(data$value))
  data$tip <- paste0(big_number(data$n), " (", percent(data$share), ")")
  plural <- c(
    genre = "genres", style = "styles", format = "formats", label = "labels",
    artist = "artists", role = "roles", country = "countries"
  )[[about$by]]
  shown <- if (any(lumped)) paste0(", the ", n, " most common of ", big_number(values), " ", plural, " shown") else ""
  several <- if (about$by %in% c("genre", "style", "format", "label")) {
    paste0(". A ", singular(about$unit), " can have more than one ", about$by)
  } else {
    ""
  }
  top <- data[1, ]
  ggplot2::ggplot(data, ggplot2::aes(y = .data$value)) +
    ggplot2::geom_segment(
      ggplot2::aes(x = 0, xend = .data$n, yend = .data$value),
      colour = colour, linewidth = 0.8, lineend = "round"
    ) +
    ggplot2::geom_point(
      ggplot2::aes(x = .data$n),
      shape = 21, size = 3.4, stroke = 1.1, fill = colour, colour = dig_colours[["surface"]]
    ) +
    ggplot2::geom_text(
      ggplot2::aes(x = .data$n, label = .data$tip),
      hjust = 0, nudge_x = max(data$n) * 0.035, size = 3.4, colour = dig_colours[["ink_soft"]]
    ) +
    ggplot2::scale_x_continuous(limits = c(0, NA), expand = ggplot2::expansion(mult = c(0.01, 0.22))) +
    ggplot2::labs(
      x = NULL, y = NULL, caption = credit,
      title = paste(stringr::str_to_sentence(about$unit), "by", about$by),
      subtitle = paste0(count_of(about$total, about$unit), shown, several, "."),
      alt = paste0(
        "Lollipop chart of ", about$unit, " by ", about$by, ". ", top$value, " is the most common, with ",
        count_of(top$n, about$unit), " (", percent(top$share), ")."
      )
    ) +
    theme_dig() +
    ggplot2::theme(
      axis.text.x = ggplot2::element_blank(),
      panel.grid.major = ggplot2::element_blank(),
      axis.text.y = ggplot2::element_text(colour = dig_colours[["ink"]], hjust = 1)
    )
}

plot_decades <- function(data, about) {
  data <- tibble::tibble(decade = seq(min(data$decade), max(data$decade), by = 10L)) |>
    dplyr::left_join(data, by = "decade") |>
    dplyr::mutate(n = dplyr::coalesce(.data$n, 0L))
  data$name <- factor(paste0(data$decade, "s"), levels = paste0(data$decade, "s"))
  peak <- data[which.max(data$n), ]
  ggplot2::ggplot(data, ggplot2::aes(.data$name, .data$n)) +
    ggplot2::geom_col(width = 0.42, fill = dig_colours[["accent"]]) +
    ggplot2::geom_text(
      ggplot2::aes(label = big_number(.data$n)),
      vjust = -0.6, size = 3.4, colour = dig_colours[["ink_soft"]]
    ) +
    ggplot2::scale_y_continuous(expand = ggplot2::expansion(mult = c(0, 0.12))) +
    ggplot2::labs(
      x = NULL, y = NULL, caption = credit,
      title = paste(stringr::str_to_sentence(about$unit), "by decade"),
      subtitle = time_subtitle(sum(data$n), about),
      alt = paste0(
        "Column chart of ", about$unit, " by decade, from the ", data$name[1], " to the ",
        data$name[nrow(data)], ". The most are from the ", peak$name, ", with ", big_number(peak$n), "."
      )
    ) +
    theme_dig() +
    ggplot2::theme(
      axis.text.y = ggplot2::element_blank(),
      panel.grid.major = ggplot2::element_blank(),
      axis.text.x = ggplot2::element_text(colour = dig_colours[["ink"]])
    )
}

plot_years <- function(data, about) {
  peak <- data[which.max(data$n), ]
  ggplot2::ggplot(data, ggplot2::aes(.data$year, .data$n)) +
    ggplot2::geom_col(width = 0.72, fill = dig_colours[["accent"]]) +
    ggplot2::annotate(
      "text",
      x = peak$year, y = peak$n, label = paste0(peak$year, ": ", big_number(peak$n)),
      vjust = -0.7, size = 3.4, colour = dig_colours[["ink_soft"]]
    ) +
    ggplot2::scale_y_continuous(expand = ggplot2::expansion(mult = c(0, 0.14))) +
    ggplot2::labs(
      x = NULL, y = NULL, caption = credit,
      title = paste(stringr::str_to_sentence(about$unit), "by year"),
      subtitle = time_subtitle(sum(data$n), about),
      alt = paste0(
        "Column chart of ", about$unit, " by year, from ", min(data$year), " to ", max(data$year),
        ". The most are from ", peak$year, ", with ", big_number(peak$n), "."
      )
    ) +
    theme_dig() +
    ggplot2::theme(panel.grid.major.x = ggplot2::element_blank())
}

plot_growth <- function(data, about) {
  last <- data[nrow(data), ]
  start <- format(data$added[1], "%B %Y")
  before <- seq(data$added[1], by = "-1 month", length.out = 2)[2]
  line <- dplyr::bind_rows(tibble::tibble(added = before, total = 0L), data[c("added", "total")])
  ggplot2::ggplot(line, ggplot2::aes(.data$added, .data$total)) +
    ggplot2::geom_area(fill = dig_colours[["accent"]], alpha = 0.1) +
    ggplot2::geom_line(colour = dig_colours[["accent"]], linewidth = 0.8, linejoin = "round", lineend = "round") +
    ggplot2::geom_point(
      data = last, shape = 21, size = 3.4, stroke = 1.1,
      fill = dig_colours[["accent"]], colour = dig_colours[["surface"]]
    ) +
    ggplot2::geom_text(
      data = last, ggplot2::aes(label = big_number(.data$total)),
      hjust = 0, nudge_x = as.numeric(diff(range(data$added))) * 0.02 + 5,
      size = 3.4, colour = dig_colours[["ink_soft"]]
    ) +
    ggplot2::scale_x_date(expand = ggplot2::expansion(mult = c(0.01, 0.08))) +
    ggplot2::scale_y_continuous(limits = c(0, NA), expand = ggplot2::expansion(mult = c(0, 0.08))) +
    ggplot2::labs(
      x = NULL, y = NULL, caption = credit,
      title = paste(stringr::str_to_sentence(about$unit), "over time"),
      subtitle = paste0(count_of(last$total, about$unit), " added since ", start, "."),
      alt = paste0(
        "Line chart of the running number of ", about$unit, " from ", start, " to ",
        format(last$added, "%B %Y"), ", reaching ", big_number(last$total), "."
      )
    ) +
    theme_dig() +
    ggplot2::theme(panel.grid.minor = ggplot2::element_blank(), panel.grid.major.x = ggplot2::element_blank())
}

plot_empty <- function(about) {
  ggplot2::ggplot() +
    ggplot2::labs(
      title = paste(stringr::str_to_sentence(about$unit), "by", about$by),
      subtitle = "Nothing to plot.",
      alt = "Empty chart: there is nothing to plot."
    ) +
    theme_dig()
}

time_subtitle <- function(counted, about) {
  left_out <- about$total - counted
  unknown <- if (left_out > 0) paste0(", ", big_number(left_out), " with an unknown year left out") else ""
  paste0(count_of(about$total, about$unit), unknown, ".")
}

theme_dig <- function() {
  ggplot2::theme_minimal(base_size = 12) +
    ggplot2::theme(
      plot.title = ggplot2::element_text(face = "bold", size = 15, colour = dig_colours[["ink"]]),
      plot.subtitle = ggplot2::element_text(
        size = 11, colour = dig_colours[["ink_soft"]], margin = ggplot2::margin(b = 12)
      ),
      plot.title.position = "plot",
      plot.caption = ggplot2::element_text(
        size = 9, colour = dig_colours[["ink_soft"]], hjust = 0, margin = ggplot2::margin(t = 10)
      ),
      plot.caption.position = "plot",
      plot.background = ggplot2::element_rect(fill = dig_colours[["surface"]], colour = NA),
      plot.margin = ggplot2::margin(16, 20, 12, 16),
      axis.text = ggplot2::element_text(colour = dig_colours[["ink_soft"]], size = 10),
      panel.grid.major = ggplot2::element_line(colour = dig_colours[["grid"]], linewidth = 0.3),
      panel.grid.minor = ggplot2::element_blank()
    )
}

count_of <- function(n, unit) {
  paste(big_number(n), if (n == 1) singular(unit) else unit)
}

singular <- function(unit) {
  c(copies = "copy", releases = "release")[[unit]]
}

keep_distinct <- function(old, new) {
  if (anyDuplicated(new)) old else new
}

big_number <- function(x) {
  formatC(x, format = "d", big.mark = ",")
}

percent <- function(x) {
  dplyr::if_else(x > 0 & x < 0.005, "<1%", paste0(round(100 * x), "%"))
}
