require(dplyr)
require(ggplot2)
require(quantileCI)

stats <- function(df, tag) {
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

print_latency_summary_table <- function(first, second, first_tag, second_tag) {
  first <- filter(first, status == 200)
  second <- filter(second, status == 200)
  firstreqs <- first$latency
  secondreqs <- second$latency
  stats(firstreqs, paste(first_tag, sep=""))
  stats(secondreqs, paste(second_tag, sep=""))
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

#commands to run on R terminal
#source("analysis.R")
#gci = filter(rbind(read.al(paste("./", "gci", 1, ".csv", sep=""))), status == 200)
#nogci = filter(rbind(read.al(paste("./", "nogci", 1, ".csv", sep=""))), status == 200)
#plot_ecdf(gci,nogci, 130)
#plot(gci$latency)
#plot(nogci$latency)
#hist(gci$latency)
#hist(nogci$latency)
