#install.packages("haven")
#install.packages("reshape2")
#install.packages("ggplot2")

#加载包
library(haven)
library(reshape2)
library(ggplot2)

#读入数据
data <- read_dta("Drawing.dta")

#数据分为两类
COLE <- data[data$sociobosque_type=="COLECTIVO",]
INDI <- data[data$sociobosque_type=="INDIVIDUAL",]

#数据table表格
COLE_sum <- as.data.frame(matrix(rep(NA,length(seq(2008,2020))*4),
                                 nrow = length(seq(2008,2020))))
row.names(COLE_sum) <- seq(2008,2020)
colnames(COLE_sum) <- c("SBP only","SBP+ITs","SBP+PAs","SBP+ITs+PAs")

INDI_sum <- as.data.frame(matrix(rep(NA,length(seq(2008,2020))*4),
                                 nrow = length(seq(2008,2020))))
row.names(INDI_sum) <- seq(2008,2020)
colnames(INDI_sum) <- c("SBP only","SBP+ITs","SBP+PAs","SBP+ITs+PAs")

#统计汇总条目数
#PART COLE
for (i in seq(2008,2020)) {
  filter <- COLE[COLE$sociobosque_year==i,]
  if (nrow(filter)==0) {
    next
  } else {
    filter$type <- ifelse(filter$indigenous == "NA" & filter$pa == "NA","SBP only",
                          ifelse(filter$indigenous != "NA" & filter$pa == "NA", "SBP+ITs",
                                ifelse(filter$indigenous == "NA" & filter$pa != "NA","SBP+PAs",
                                       ifelse(filter$indigenous != "NA" & filter$pa != "NA","SBP+ITs+PAs","NA"))))
    sum <- as.data.frame(table(filter$type))
    sum$Var1 <- as.character(sum$Var1)
    for (j in 1:nrow(sum)) {
      COLE_sum[as.character(i),sum[j,1]] <- sum[j,2]
    }
  }
}

#PART_INDI
for (i in seq(2008,2020)) {
  filter <- INDI[INDI$sociobosque_year==i,]
  if (nrow(filter)==0) {
    next
  } else {
    filter$type <- ifelse(filter$indigenous == "NA" & filter$pa == "NA","SBP only",
                          ifelse(filter$indigenous != "NA" & filter$pa == "NA", "SBP+ITs",
                                 ifelse(filter$indigenous == "NA" & filter$pa != "NA","SBP+PAs",
                                        ifelse(filter$indigenous != "NA" & filter$pa != "NA","SBP+ITs+PAs","NA"))))
    sum <- as.data.frame(table(filter$type))
    sum$Var1 <- as.character(sum$Var1)
    for (j in 1:nrow(sum)) {
      INDI_sum[as.character(i),sum[j,1]] <- sum[j,2]
    }
  }
}

#整理绘图数据
COLE_sum$year <- row.names(COLE_sum)
COLE_sum <- melt(COLE_sum,id.vars = "year")
COLE_sum$variable <- paste0("COLECTIVO_",COLE_sum$variable)
COLE_sum$value <- -COLE_sum$value

INDI_sum$year <- row.names(INDI_sum)
INDI_sum <- melt(INDI_sum,id.vars = "year")
INDI_sum$variable <- paste0("INDIVIDUAL_",INDI_sum$variable)
INDI_sum$value <- INDI_sum$value*20   #为保证绘图效果，INDI数据扩大20倍

plot <- rbind(COLE_sum,INDI_sum)
plot$year <- factor(plot$year,levels = rev(seq(2008,2020)))
plot$variable <- factor(plot$variable,levels = unique(plot$variable))

plot$color <- factor(plot$variable,
                     levels = c("COLECTIVO_SBP only","COLECTIVO_SBP+ITs","COLECTIVO_SBP+PAs", 
                                "COLECTIVO_SBP+ITs+PAs","INDIVIDUAL_SBP only","INDIVIDUAL_SBP+ITs"
                                ,"INDIVIDUAL_SBP+PAs","INDIVIDUAL_SBP+ITs+PAs"),
                     labels = c("SBP only","SBP+ITs","SBP+PAs", 
                                "SBP+ITs+PAs","SBP only","SBP+ITs"
                                ,"SBP+PAs","SBP+ITs+PAs"))


# 加载字体支持
library(showtext)

# 自动使用 showtext 渲染所有文字
showtext_auto()

#绘图
ggplot(plot,aes(x=value,y=year))+
  geom_bar(stat = "identity",aes(fill=color),width = 0.7)+
  scale_x_continuous(breaks = seq(-30000,30000,5000),
                     labels = c(c(30000,25000,20000,15000,10000,5000,0),seq(250,1500,250)))+   #指定特定位置的x轴说明
  labs(x="",y="",fill="")+
  scale_fill_manual(values = c("#3D9F3C","#9ED17B","#367DB0","#9DC7DD"))+   #指定颜色
  theme_minimal()+
  theme(panel.grid.major.x = element_line(colour = "grey"),
        panel.grid = element_blank(),
        axis.text = element_text(color = "black",size=12), 
        legend.position = c(0.9,0.2),
        legend.box.background = element_rect(fill = "white", color = "black"),      # 整个图例区域背景（如使用 legend.box）
        legend.title = element_blank(), # 去掉图例的标题
        plot.title = element_text(hjust = 0.6, family = "CMU Serif Roman", size = 16, face = "bold")) +  # 字号，粗体，居中
  labs(title = c("Collective contracts                                Individual contracts"))

ggsave("bar_new.pdf",width = 300, height = 180, units = "mm", dpi = 300)
