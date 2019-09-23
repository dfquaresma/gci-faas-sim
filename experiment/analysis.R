require(dplyr)
require(ggplot2)
require(quantileCI)

print_summary_table <- function(nogci, gci) {
  nogci <- filter(nogci, status == 200)
  gci <- filter(gci, status == 200)
  nogcireq <- nogci$latency
  gcireq <- gci$latency
  stats <- function(df, tag) {
    p50 = quantileCI::quantile_confint_nyblom(df, 0.5)
    p95 = quantileCI::quantile_confint_nyblom(df, 0.95)
    p99 = quantileCI::quantile_confint_nyblom(df, 0.99)
    p999 = quantileCI::quantile_confint_nyblom(df, 0.999)
    p9999 = quantileCI::quantile_confint_nyblom(df, 0.9999) 
    cat("Latency(ms) ", tag, " ")
    cat("avg:", signif(t.test(df)$conf.int, digits = 2), " | ")
    cat("50:", signif(p50, digits = 4), " | ")
    cat("95:", signif(p95, digits = 4), " | ")
    cat("99:", signif(p99, digits = 4), " |\n")
    cat("99.9:", signif(p999, digits = 4), " | ")
    cat("99.99:", signif(p9999, digits = 4), " | ")
    cat("Dist.Tail.:", signif(p9999-p50, digits = 4))
    cat("\n")
  }
  stats(nogcireq, paste("NOGCI", sep=""))
  stats(gcireq, paste("GCI", sep=""))
}

read.al <- function(path) {
  df <- read.csv(path, sep=",",header=T, dec=".")
  df$latency <- df$latency * 1000
  return(tail(df, -100))
}

print_entries_table <- function(i) {
  path <- "./input-entries/"
  nogci <- rbind(read.al(paste(path, "nogci", i, ".csv", sep="")))
  gci <- rbind(read.al(paste(path, "gci", i, ".csv", sep="")))
  print_summary_table(nogci,  gci)
}

print_all_entries_table <- function() {
  for (i in 1:8){
    print_entries_table(i)
  }
}