library(xtable)
library(plm)
library(dplyr)
library(lmtest)
library(tidyr)
library(lfe)
library(stargazer)
library(broom)
library(standardize)
library(rstudioapi)

setwd(dirname(getActiveDocumentContext()$path))

# load data into memory
# ---------------------
retailpanel <- read.table("../Data/processed_data_main.csv", header=TRUE, sep=",")
retailpanel$gender<-ifelse(retailpanel$player.gender=='Female',1,0)
retailpanel$high_crashrisk<-ifelse(retailpanel$owner__crash_probability==0.06,1,0)
retailpanel$high_score<-ifelse(retailpanel$FinScore>=median(retailpanel$FinScore),1,0)
retailpanel$owner__gamified<-ifelse(retailpanel$owner__gamified=='True',1,0)

m1<-felm(secs_since_round_starts ~ owner__gamified | 0 | 0 | owner__participant__code + owner__round_number,
           data=subset(retailpanel,exit_sell==1))
m2<-felm(secs_since_round_starts ~ owner__gamified + FinScore + player.age + gender + high_crashrisk | 0 | 0 | owner__participant__code + owner__round_number,
           data=subset(retailpanel,exit_sell==1))


# generate regression table for H1
stargazer(m1,m2,
          title = "Gamification and time-to-sell",
          dep.var.labels = c("Time-to-sell (seconds)"),
          covariate.labels = c("Gamified","Financial score","Age","Gender: Female","Crash probability"),
          omit.stat = c("LL", "ser", "F"), ci = FALSE, single.row = FALSE, no.space = TRUE,
          out='../reports/H1_table.tex')


m1<-felm(exit_crash ~ owner__gamified | 0 | 0 | owner__participant__code + owner__round_number,
           data=subset(retailpanel))
m2<-felm(exit_crash ~ owner__gamified + FinScore + player.age + gender + high_crashrisk | 0 | 0 | owner__participant__code + owner__round_number,
           data=subset(retailpanel))


# generate regression table for H1
stargazer(m1,m2,
          title = "Gamification and risk of ruin",
          covariate.labels = c("Gamified","Financial score","Age","Gender: Female","Crash probability"),
          omit.stat = c("LL", "ser", "F"), ci = FALSE, single.row = FALSE, no.space = TRUE,
          out='../reports/H2_table.tex')

m1<-felm(mindchanges ~ owner__gamified | 0 | 0 | owner__participant__code + owner__round_number,
           data=subset(retailpanel))
m2<-felm(mindchanges ~ owner__gamified + FinScore + player.age + gender + high_crashrisk | 0 | 0 | owner__participant__code + owner__round_number,
           data=subset(retailpanel))


# generate regression table for H1
stargazer(m1,m2,
          title = "Gamification and changing mind",
          covariate.labels = c("Gamified","Financial score","Age","Gender: Female","Crash probability"),
          omit.stat = c("LL", "ser", "F"), ci = FALSE, single.row = FALSE, no.space = TRUE,
          out='../reports/H3_table.tex')


# Tobit model
mt<-vglm(secs_since_round_starts ~ owner__gamified + FinScore + player.age + gender + high_crashrisk,
         tobit(Upper=retailpanel$censoring),data=retailpanel)
mt_DC<-coeftest(mt,type='HC3',cluster=owner__participant__code+owner__round_number)
stargazer(mt_DC,
          title = "Tobit")