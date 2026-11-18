set.seed(17)

genres <- c(
  "Electronic", "Rock", "Jazz", "Funk / Soul", "Hip Hop", "Pop", "Classical", "Reggae", "Latin", "Blues",
  "Folk, World, & Country", "Stage & Screen"
)

copies <- 240

collection <- tibble::tibble(
  release_id = sample(100000, copies),
  instance_id = seq_len(copies),
  genres = purrr::map(seq_len(copies), \(i) sample(genres, sample(1:2, 1), prob = 12:1))
)

plot <- tidycrates::dig_plot(collection, "genre") +
  ggplot2::labs(caption = "Made-up example data.")

ggplot2::ggsave(file.path("man", "figures", "README-genres.png"), plot, width = 7, height = 4.6, dpi = 144)
