require(dplyr)
require(ggplot2)
require(quantileCI)
require(base64enc)

analyse_i <- function(i) {
    gci = filter(read.al(paste("../experiment/results/", "gci", as.character(i), ".csv", sep="")), status == 200)
    gci$response_time = gci$response_time / 1000000
    gci$service_time = gci$body / 1000000

    nogci = filter(read.al(paste("../experiment/results/", "nogci", as.character(i), ".csv", sep="")), status == 200)
    nogci$response_time = nogci$response_time / 1000000
    nogci$service_time = nogci$body / 1000000

    graph_tail(gci$response_time, nogci$response_time, 
        title=paste("THUMBNAILATOR ECDF RESPONSE TIME", as.character(i)), 
        x_limit_inf=0, x_limit_sup=max(max(gci$response_time, na.rm = TRUE), max(nogci$response_time, na.rm = TRUE)), 
        annotate_y=0.90
    )

    Sys.sleep(2)
    plot(gci$response_time, ylab="response time", main=paste("GCI", as.character(i)))
    Sys.sleep(3)
    plot(nogci$response_time, ylab="response time", main=paste("NOGCI", as.character(i)))
    Sys.sleep(3)
    summary_table(gci$response_time, paste("gci", as.character(i)), nogci$response_time, paste("nogci", as.character(i)))
}

read.al <- function(path) {
  df <- read.csv(path, sep=",",header=T, dec=".")
  return (tail(df, -500))
}

read.al.sim <- function(path) {
  return (read.csv(path, sep=",",header=T, dec="."))
}

summary_table <- function(df1, tag1, df2, tag2) {
  qCI <- function(df, p) {
    return(quantileCI::quantile_confint_nyblom(df, p))
  }
  stats <- function(df) {
    avg = signif(t.test(df)$conf.int, digits = 2)
    p50 = signif(qCI(df, 0.5), digits = 4)
    p95 = signif(qCI(df, 0.95), digits = 4)
    p99 = signif(qCI(df, 0.99), digits = 4)
    p999 = signif(qCI(df, 0.999), digits = 4)
    p9999 = signif(qCI(df, 0.9999), digits = 4)
    p99999 = signif(qCI(df, 0.99999), digits = 4)
    dist = signif(qCI(df, 0.99999)- qCI(df, 0.5), digits = 4)
    data <- c(avg, p50, p95, p99, p999, p9999, p99999, dist)
    return(data)
  }

  stats1 = stats(df1)
  stats2 = stats(df2)
  avgdf    <- data.frame("avg",    stats1[1],  stats1[2],  stats2[1],  stats2[2])
  p50df    <- data.frame("p50",    stats1[3],  stats1[4],  stats2[3],  stats2[4])
  p95df    <- data.frame("p95",    stats1[5],  stats1[6],  stats2[5],  stats2[6])
  p99df    <- data.frame("p99",    stats1[7],  stats1[8],  stats2[7],  stats2[8])
  p999df   <- data.frame("p999",   stats1[9],  stats1[10], stats2[9],  stats2[10])
  p9999df  <- data.frame("p9999",  stats1[11], stats1[12], stats2[11], stats2[12])
  p99999df <- data.frame("p99999", stats1[13], stats1[14], stats2[13], stats2[14])
  distdf   <- data.frame("dist",   stats1[15], stats1[16], stats2[15], stats2[16])

  tag1_inf = paste(tag1, "cii", sep = ".")
  tag1_sup = paste(tag1, "cis", sep = ".")
  tag2_inf = paste(tag2, "cii", sep = ".")
  tag2_sup = paste(tag2, "cis", sep = ".")
  names(avgdf)    <- c("stats", tag1_inf, tag1_sup, tag2_inf, tag2_sup)
  names(p50df)    <- c("stats", tag1_inf, tag1_sup, tag2_inf, tag2_sup)
  names(p95df)    <- c("stats", tag1_inf, tag1_sup, tag2_inf, tag2_sup)
  names(p99df)    <- c("stats", tag1_inf, tag1_sup, tag2_inf, tag2_sup)
  names(p999df)   <- c("stats", tag1_inf, tag1_sup, tag2_inf, tag2_sup)
  names(p9999df)  <- c("stats", tag1_inf, tag1_sup, tag2_inf, tag2_sup)
  names(p99999df) <- c("stats", tag1_inf, tag1_sup, tag2_inf, tag2_sup)
  names(distdf)   <- c("stats", tag1_inf, tag1_sup, tag2_inf, tag2_sup)
  df <- rbind(avgdf, p50df, p95df, p99df, p999df, p9999df, p99999df, distdf)
  df
}

summary_table_sim <- function(df1, df2, df3, df4, df5, df6, tags) {
  qCI <- function(df, p) {
    return(quantileCI::quantile_confint_nyblom(df, p))
  }
  stats <- function(df) {
    avg = signif(t.test(df)$conf.int, digits = 2)
    p50 = signif(qCI(df, 0.5), digits = 4)
    p95 = signif(qCI(df, 0.95), digits = 4)
    p99 = signif(qCI(df, 0.99), digits = 4)
    p999 = signif(qCI(df, 0.999), digits = 4)
    p9999 = signif(qCI(df, 0.9999), digits = 4)
    p99999 = signif(qCI(df, 0.99999), digits = 4)
    dist = signif(qCI(df, 0.99999)- qCI(df, 0.5), digits = 4)
    data <- c(avg, p50, p95, p99, p999, p9999, p99999, dist)
    return(data)
  }

  stats1 = stats(df1)
  stats2 = stats(df2)
  stats3 = stats(df3)
  stats4 = stats(df4)
  stats5 = stats(df5)
  stats6 = stats(df6)
  
  avgdf    <- data.frame("avg",     stats1[2],  stats2[1],  stats3[2],  stats4[1],  stats5[2],  stats6[1])
  p50df    <- data.frame("p50",     stats1[4],  stats2[3],  stats3[4],  stats4[3],  stats5[4],  stats6[3])
  p95df    <- data.frame("p95",     stats1[6],  stats2[5],  stats3[6],  stats4[5],  stats5[6],  stats6[5])
  p99df    <- data.frame("p99",     stats1[8],  stats2[7],  stats3[8],  stats4[7],  stats5[8],  stats6[7])
  p999df   <- data.frame("p999",   stats1[10],  stats2[9], stats3[10],  stats4[9], stats5[10],  stats6[9])
  p9999df  <- data.frame("p9999",  stats1[12], stats2[11], stats3[12], stats4[11], stats5[12], stats6[11])
  p99999df <- data.frame("p99999", stats1[14], stats2[13], stats3[14], stats4[13], stats5[14], stats6[13])
  distdf   <- data.frame("dist",   stats1[16], stats2[15], stats3[16], stats4[15], stats5[16], stats6[15])
  
  tag1_inf = paste(tags[1], "cii", sep = ".")
  tag1_sup = paste(tags[1], "cis", sep = ".")
  tag2_inf = paste(tags[2], "cii", sep = ".")
  tag2_sup = paste(tags[2], "cis", sep = ".")
  tag3_inf = paste(tags[3], "cii", sep = ".")
  tag3_sup = paste(tags[3], "cis", sep = ".")
  tag4_inf = paste(tags[4], "cii", sep = ".")
  tag4_sup = paste(tags[4], "cis", sep = ".")
  tag5_inf = paste(tags[5], "cii", sep = ".")
  tag5_sup = paste(tags[5], "cis", sep = ".")
  tag6_inf = paste(tags[6], "cii", sep = ".")
  tag6_sup = paste(tags[6], "cis", sep = ".")
  names(avgdf)    <- c("stats", tag1_sup, tag2_inf, tag3_sup, tag4_inf, tag5_sup, tag6_inf)
  names(p50df)    <- c("stats", tag1_sup, tag2_inf, tag3_sup, tag4_inf, tag5_sup, tag6_inf)
  names(p95df)    <- c("stats", tag1_sup, tag2_inf, tag3_sup, tag4_inf, tag5_sup, tag6_inf)
  names(p99df)    <- c("stats", tag1_sup, tag2_inf, tag3_sup, tag4_inf, tag5_sup, tag6_inf)
  names(p999df)   <- c("stats", tag1_sup, tag2_inf, tag3_sup, tag4_inf, tag5_sup, tag6_inf)
  names(p9999df)  <- c("stats", tag1_sup, tag2_inf, tag3_sup, tag4_inf, tag5_sup, tag6_inf)
  names(p99999df) <- c("stats", tag1_sup, tag2_inf, tag3_sup, tag4_inf, tag5_sup, tag6_inf)
  names(distdf)   <- c("stats", tag1_sup, tag2_inf, tag3_sup, tag4_inf, tag5_sup, tag6_inf)
  df <- rbind(avgdf, p50df, p95df, p99df, p999df, p9999df, p99999df, distdf)
  df
}

graph_tail <- function(gci, nogci, tags, title, x_limit_inf, x_limit_sup, annotate_y) {
  cmp <- rbind(
    data.frame("response_time"=gci, Type=tags[1]),
    data.frame("response_time"=nogci, Type=tags[2])
  )
  gci.color <- "blue"
  gci.p999 <- quantile(gci, 0.9999)
  gci.p50 <- quantile(gci, 0.5)
  
  nogci.color <- "red"
  nogci.p999 <- quantile(nogci, 0.9999)
  nogci.p50 <- quantile(nogci, 0.5)
  
  annotate_y = 0.9
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
    
    xlim(x_limit_inf, x_limit_sup) +
    theme(legend.position="top") +
    scale_color_manual(breaks = tags, values=c("blue", "red")) +
    theme_bw() +
    ggtitle(title) +
    xlab("response time (ms)") +
    ylab("rate") 
  
  print(p)
}

graph_tail_sim <- function(gci, nogci, tags, x_limit_inf, x_limit_sup, y_limit_inf, y_limit_sup, 
                           annotate_y, p999_instead_p9999=FALSE, img_name=FALSE) {
  cmp <- rbind(
    data.frame("response_time"=gci, tipo=tags[1]),
    data.frame("response_time"=nogci, tipo=tags[2])
  )
  gci.color <- "blue"
  gci.q3 <- quantile(gci, 0.75)
  gci.p50 <- quantile(gci, 0.5)
  gci.q1 <- quantile(gci, 0.25)
  
  nogci.color <- "red"
  nogci.q3 <- quantile(nogci, 0.75)
  nogci.p50 <- quantile(nogci, 0.5)
  nogci.q1 <- quantile(nogci, 0.25)
  
  tail_tag = "99.99th"
  tail = 0.9999
  if (p999_instead_p9999) {
    tail_tag = "99.9th"
    tail = 0.999
  }
  gci.tail <- quantile(gci, tail)
  nogci.tail <- quantile(nogci, tail)
  
  annotate_y = 0.9
  size = 0.5
  alpha = 0.5
  angle = 90
  p <- ggplot(cmp, aes(response_time, color=tipo)) +
    stat_ecdf(size=size) +
    
    # Q1
    annotate(geom="text", x=gci.q1, y=annotate_y, label="1-quantile", angle=angle, color=gci.color) +
    geom_vline(xintercept=gci.q1, linetype="dotted", size=size, alpha=alpha, color=gci.color) +
    annotate(geom="text", x=nogci.q1, y=annotate_y, label="1-quantile", angle=angle, color=nogci.color) + 
    geom_vline(xintercept=nogci.q1, linetype="dotted", size=size, alpha=alpha, color=nogci.color) +
    
    # P50
    annotate(geom="text", x=gci.p50, y=annotate_y, label="Median", angle=angle, color=gci.color) +
    geom_vline(xintercept=gci.p50, linetype="dotted", size=size, alpha=alpha, color=gci.color) +
    annotate(geom="text", x=nogci.p50, y=annotate_y, label="Median", angle=angle, color=nogci.color) + 
    geom_vline(xintercept=nogci.p50, linetype="dotted", size=size, alpha=alpha, color=nogci.color) +
    
    # Q3
    annotate(geom="text", x=gci.q3, y=annotate_y, label="3-quantile", angle=angle, color=gci.color) +
    geom_vline(xintercept=gci.q3, linetype="dotted", size=size, alpha=alpha, color=gci.color) +
    annotate(geom="text", x=nogci.q3, y=annotate_y, label="3-quantile", angle=angle, color=nogci.color) + 
    geom_vline(xintercept=nogci.q3, linetype="dotted", size=size, alpha=alpha, color=nogci.color) +
    
    # P9999
    annotate(geom="text", x=gci.tail, y=annotate_y, label=tail_tag, angle=angle, color=gci.color) +
    geom_vline(xintercept=gci.tail, linetype="dotted", size=size, alpha=alpha, color=gci.color) +
    annotate(geom="text", x=nogci.tail, y=annotate_y, label=tail_tag, angle=angle, color=nogci.color) + 
    geom_vline(xintercept=nogci.tail, linetype="dotted", size=size, alpha=alpha, color=nogci.color) +
    
    xlim(x_limit_inf, x_limit_sup) +
    ylim(y_limit_inf, y_limit_sup) +
    theme(legend.position="top") +
    scale_color_manual(breaks = tags, values=c("blue", "red")) +
    theme_bw() +
    xlab("Tempo de Resposta (ms)") +
    ylab("ECDF")
  
  if (img_name != FALSE) {
      ggsave(img_name, width=10, height=5)
    }
  print(p)
  
}

get_service_time_column <- function(df) {
  service_time = c()
  for (val in df$response_body) {
    service_time <- c(service_time, as.numeric(rawToChar(base64decode(toString(val)))))
  }
  return(service_time)
}

quantile_wrapped = function(data) {
  quantile(data, c(.0, .25, .50, .75, .90, .95, .99, .999, .9999, .99999, 1))
}

quantiles_dataframe_comparison = function(nogci, gci) {
  comparison = (quantile_wrapped(nogci) / quantile_wrapped(gci))
  data.frame(
    nogci      = quantile_wrapped(nogci),
    gci        = quantile_wrapped(gci),
    comparison = comparison
  )
}

quantiles_dataframe_comparison_sim = function(df1, df2, df3, df4, df5, df6) {
  normsched = (quantile_wrapped(df1) / quantile_wrapped(df2))
  opsched = (quantile_wrapped(df3) / quantile_wrapped(df4))
  opgcisched = (quantile_wrapped(df5) / quantile_wrapped(df6))
  comparissons = data.frame(
    normsched  = normsched,
    opsched    = opsched,
    opgcisched = opgcisched
  )
  return(comparissons)
}

quantiles_dataframe_comparison_sim2 = function(df1, df2, df3, df4) {
  normsched = (quantile_wrapped(df1) / quantile_wrapped(df2))
  opsched = (quantile_wrapped(df3) / quantile_wrapped(df4))
  comparissons = data.frame(
    normsched  = normsched,
    opsched    = opsched
  )
  return(comparissons)
}
