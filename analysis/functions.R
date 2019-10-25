require(dplyr)
require(ggplot2)
require(quantileCI)
require(base64enc)

read.al <- function(path) {
  df <- read.csv(path, sep=",",header=T, dec=".")
  return (tail(df, -100))
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

get_service_time_column <- function(df) {
  service_time = c()
  for (val in df$response_body) {
    service_time <- c(service_time, as.numeric(rawToChar(base64decode(toString(val)))))
  }
  return(service_time)
}

graph_tail <- function(gci, nogci, title, x_limit_inf, x_limit_sup, annotate_y) {
  cmp <- rbind(
    data.frame("response_time"=gci, Type="GCI"),
    data.frame("response_time"=nogci, Type="NOGCI")
  )
  gci.color <- "blue"
  gci.p999 <- quantile(gci, 0.9999)
  gci.p50 <- quantile(gci, 0.5)
  
  nogci.color <- "red"
  nogci.p999 <- quantile(nogci, 0.9999)
  nogci.p50 <- quantile(nogci, 0.5)
  
  size = 0.5
  alpha = 0.5
  angle = 90
  p <- ggplot(cmp, aes(response_time, color=Type)) +
    stat_ecdf(size=size) +
    # P50
    annotate(geom="text", x=gci.p50, y=annotate_y, label="Median", angle=angle, color=gci.color) +
    geom_vline(xintercept=gci.p50, linetype="dotted", size=size, alpha=alpha, color=gci.color) +
    annotate(geom="text", x=nogci.p50, y=annotate_y, label="Median", angle=angle, color=nogci.color) + 
    geom_vline(xintercept=nogci.p50, linetype="dotted", size=size, alpha=alpha, color=nogci.color) +
    
    # P999
    annotate(geom="text", x=gci.p999, y=annotate_y, label="99.99th", angle=angle, color=gci.color) +
    geom_vline(xintercept=gci.p999, linetype="dotted", size=size, alpha=alpha, color=gci.color) +
    annotate(geom="text", x=nogci.p999, y=annotate_y, label="99.99th", angle=angle, color=nogci.color) + 
    geom_vline(xintercept=nogci.p999, linetype="dotted", size=size, alpha=alpha, color=nogci.color) +
    
    #scale_x_continuous(breaks=seq(0, max(cmp$latency), 10)) +
    #coord_cartesian(ylim = c(0.99, 1)) +
    xlim(x_limit_inf, x_limit_sup) +
    theme(legend.position="top") +
    scale_color_manual(breaks = c("GCI", "NOGCI"), values=c("blue", "red")) +
    theme_bw() +
    ggtitle(title) +
    xlab("response time (ms)") +
    ylab("rate") 
  
  print(p)
}