require(dplyr)
require(ggplot2)
require(quantileCI)
require(base64enc)

read.al <- function(path) {
  df <- read.csv(path, sep=",",header=T, dec=".")
  df$latency <- df$latency * 1000
  return(tail(df, -100))
}

summary_table <- function(df, tag) {
    p50 = quantileCI::quantile_confint_nyblom(df, 0.5)
    p95 = quantileCI::quantile_confint_nyblom(df, 0.95)
    p99 = quantileCI::quantile_confint_nyblom(df, 0.99)
    p999 = quantileCI::quantile_confint_nyblom(df, 0.999)
    p9999 = quantileCI::quantile_confint_nyblom(df, 0.9999)
    p99999 = quantileCI::quantile_confint_nyblom(df, 0.99999)
    cat("Latency(ms) ", tag, " ")
    cat("avg:", signif(t.test(df)$conf.int, digits = 2), " | ")
    cat("50:", signif(p50, digits = 4), " | ")
    cat("95:", signif(p95, digits = 4), " | " )
    cat("99:", signif(p99, digits = 4), " |\n")
    cat("99.9:", signif(p999, digits = 4), " | ")
    cat("99.99:", signif(p9999, digits = 4), " | ")
    cat("99.999:", signif(p99999, digits = 4), " | ")
    cat("Dist.Tail.:", signif(p99999-p50, digits = 4))
    cat("\n\n")
}

plot_ecdf = function(GCI, NOGCI, limit) {
  ecdf_GCI = ecdf(GCI$latency)
  ecdf_NOGCI = ecdf(NOGCI$latency)

  x_limit = c(0, limit)

  plot(ecdf_GCI, verticals=TRUE, do.points=FALSE
       , main="ECDF", xlab="tempo de execução (ms)"
       , ylab="frequencia", col='blue',
       xlim=x_limit)
  plot(ecdf_NOGCI, verticals=TRUE
       , do.points=FALSE, add=TRUE, col='red',
       xlim=x_limit)

  legend("bottomright",
         legend=c("GCI", "NOGCI"),
         col=c("blue", "red"), pch = c(16,16), bty = "n",
         pt.cex = 1, cex = 1.2, text.col = "black",
         horiz = F , inset = c(0.1, 0.1))
}

get_service_time_column <- function(df) {
  service_time = c()
  for (val in df$response_body) {
    service_time <- c(service_time, as.numeric(rawToChar(base64decode(toString(val)))))
  }
  return(service_time)
}
