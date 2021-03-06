library(stringr)
library(tidyr)
library(dplyr)
library(ggplot2)
library(jsonlite)

#location of this folder on your computer
setwd("/Users/rebeccajarvis/Documents/prog-impf-shift/s2-level/")
#setwd("~/git/prog-impf-shift/s2-level/")

datalist <- data.frame()

for (filename in c("datafiles/prog-11-s2.json", "datafiles/impf-11-s2.json", "datafiles/null-11-s2.json", "datafiles/null-11add-s2.json", "datafiles/prog-11add-s2.json", "datafiles/impf-11add-s2.json"))
{
  templist <- cbind(filename, fromJSON(filename, flatten=TRUE))
  datalist <- rbind(datalist, templist)
}
rm(templist)
rm(filename)

#ugly but oh well
#removing states I don't really want to plot--[0.7, 0.9] and one-event states, b/c they have to be described by null
datalist <- filter(datalist, y != 0)

#I think some of this is unneccessary, but I'll just leave it
datalist$x <- substring(datalist$x, 3)
datalist$x <- gsub('.{1}$', '', datalist$x)
datalist <- rename(datalist, worldstate = x)
datalist <- rename(datalist, freq = y)
datalist$stageno <- factor(datalist$sub,levels = c("emer1", "emer9", "emer8", "emer7", "emer6", "emer2", "emer3", "emer4", "emer5", "cat", "exp1", "exp2", "exp3", "exp4", "exp6", "exp7", "exp8", "exp9", "exp5"))

datalist$utterance <- ifelse(grepl(pattern = "prog", x = datalist$filename), "PROG",
                             ifelse(grepl(pattern = "impf", x = datalist$filename), "IMPF", "NULL"))
datalist <- subset(datalist, select = -c(model, sub, filename))


#I'll filter out nulls for now, since they're pretty uninteresting
datalist <- filter(datalist, utterance != "NULL")



#graphs



####################


#graph colored by "category"
multistate <- c("0.1, 0.3, 0.5, 0.7, 0.9", "0.1, 0.3, 0.5, 0.7", "0.1, 0.3, 0.5, 0.9", "0.1, 0.3, 0.7, 0.9", "0.1, 0.5, 0.7, 0.9", "0.3, 0.5, 0.7, 0.9", "0.1, 0.3, 0.5", "0.1, 0.3, 0.7", "0.1, 0.5, 0.7", "0.1, 0.3, 0.9", "0.1, 0.5, 0.9", "0.1, 0.7, 0.9", "0.3, 0.5, 0.7", "0.3, 0.5, 0.9", "0.3, 0.7, 0.9", "0.5, 0.7, 0.9")
twospread <- c("0.1, 0.7", "0.1, 0.9", "0.3, 0.7", "0.3, 0.9", "0.5, 0.7", "0.5, 0.9")
twonarrow <- c("0.1, 0.3", "0.3, 0.5", "0.1, 0.5")

datalist$statetype <- ifelse(datalist$worldstate %in% multistate, "multistate",
                             ifelse(datalist$worldstate %in% twospread, "twospread", "twonarrow"))
catgraph <- ggplot(data=datalist, aes(x = stageno, y = freq, colour = statetype)) + geom_line(aes(linetype = utterance, group = interaction(worldstate, utterance))) + theme_bw() #+ geom_point()

#ggsave("s2-allstates-bycat.jpg", plot = catgraph, device = NULL, path = NULL,
#       scale = 1, width = 8, height = 6,
#       dpi = 300, limitsize = TRUE)




####################




datalist$statesort <- ifelse(grepl("0.1, 0.3", datalist$worldstate), "both1and3", 
                             ifelse(!grepl("0.1", datalist$worldstate), "not1", NA))
datalist2 <- filter(datalist, !is.na(statesort))
datalist2 <- group_by(datalist2, statesort, stageno, utterance)
sum2 <- summarise(datalist2, meanfreq = mean(freq))

graph2 <- ggplot(data=sum2, aes(x = stageno, y = meanfreq, colour = statesort, group = interaction(statesort, utterance))) + geom_line(aes(linetype = utterance)) + theme_bw() + scale_color_manual(values=c("red", "blue"))
#ggsave("statesort.png",height=7,width=11)




####################




datalist$ev1 <- ifelse(grepl("0.1", datalist$worldstate), 1, NA)
datalist$ev3 <- ifelse(grepl("0.3", datalist$worldstate), 3, NA)
datalist$ev5 <- ifelse(grepl("0.5", datalist$worldstate), 5, NA)
datalist$ev7 <- ifelse(grepl("0.7", datalist$worldstate), 7, NA)
datalist$ev9 <- ifelse(grepl("0.9", datalist$worldstate), 9, NA)

#not elegant but works
ev1data <- filter(datalist, !is.na(ev1)) %>%
  group_by(stageno, utterance) %>%
  summarise(meanfreq = mean(freq)) %>%
  mutate(event = "1")

ev3data <- filter(datalist, !is.na(ev3)) %>%
  group_by(stageno, utterance) %>%
  summarise(meanfreq = mean(freq)) %>%
  mutate(event = "3")

ev5data <- filter(datalist, !is.na(ev5)) %>%
  group_by(stageno, utterance) %>%
  summarise(meanfreq = mean(freq)) %>%
  mutate(event = "5")

ev7data <- filter(datalist, !is.na(ev7)) %>%
  group_by(stageno, utterance) %>%
  summarise(meanfreq = mean(freq)) %>%
  mutate(event = "7")

ev9data <- filter(datalist, !is.na(ev9)) %>%
  group_by(stageno, utterance) %>%
  summarise(meanfreq = mean(freq)) %>%
  mutate(event = "9")

eventdata <- rbind(ev1data, ev3data, ev5data, ev7data, ev9data)
rm(ev1data)
rm(ev3data)
rm(ev5data)
rm(ev7data)
rm(ev9data)

evgraph <- ggplot(data=eventdata, aes(x = stageno, y = meanfreq, colour = event, group = interaction(event, utterance))) +
  geom_line(aes(linetype = utterance)) +
  theme_bw()

#ggsave("evgraph-large.png",height=7,width=11)




####################
#working on plots that look similar to the earlier ones

#let's try "everything containing state x over time"
#x-axis: Tx (average over all states containing x)--this comes from eventdata
#y-axis: probability
#two bars: PROG & IMPF
#facet by state (lots of them...)


eventdata$stageno <- factor(eventdata$stageno, labels = c("10p:1i", "9p:1i", "8p:1i", "7p:1i", "6p:1i", "5p:1i", "4p:1i", "3p:1i", "2p:1i", "1p:1i", "1p:2i", "1p:3i", "1p:4i", "1p:5i", "1p:6i", "1p:7i", "1p:8i", "1p:9i", "1p:10i"))

#narrowing our collection of stages to odd ones only
eventdata <- filter(eventdata, stageno %in% c("9p:1i", "7p:1i", "5p:1i", "3p:1i", "1p:1i", "1p:3i", "1p:5i", "1p:7i", "1p:9i"))



#putting the following instead of the second line here gives you a non-stacked plot: geom_bar(stat="identity", width=.5, position = "dodge")
evbar <- ggplot(data=eventdata, aes(x=event,y=meanfreq,fill=utterance)) +
  geom_bar(stat="identity") +
  scale_fill_manual(values = c("red", "blue")) +
  facet_wrap(~stageno, nrow = 1) +
  theme_bw()

ggsave("fig-stacked_bar-9_state.png",height=6,width=11)


