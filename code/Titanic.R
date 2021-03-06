setwd("C:/kaggle/Titanic Machine Learning from Disaster")
getwd()
list.files()

# Multiple plot function
#
# ggplot objects can be passed in ..., or to plotlist (as a list of ggplot objects)
# - cols:   Number of columns in layout
# - layout: A matrix specifying the layout. If present, 'cols' is ignored.
#
# If the layout is something like matrix(c(1,2,3,3), nrow=2, byrow=TRUE),
# then plot 1 will go in the upper left, 2 will go in the upper right, and
# 3 will go all the way across the bottom.
#
multiplot <- function(..., plotlist=NULL, file, cols=1, layout=NULL) {
  library(grid)
  
  # Make a list from the ... arguments and plotlist
  plots <- c(list(...), plotlist)
  
  numPlots = length(plots)
  
  # If layout is NULL, then use 'cols' to determine layout
  if (is.null(layout)) {
    # Make the panel
    # ncol: Number of columns of plots
    # nrow: Number of rows needed, calculated from # of cols
    layout <- matrix(seq(1, cols * ceiling(numPlots/cols)),
                     ncol = cols, nrow = ceiling(numPlots/cols))
  }
  
  if (numPlots==1) {
    print(plots[[1]])
    
  } else {
    # Set up the page
    grid.newpage()
    pushViewport(viewport(layout = grid.layout(nrow(layout), ncol(layout))))
    
    # Make each plot, in the correct location
    for (i in 1:numPlots) {
      # Get the i,j matrix positions of the regions that contain this subplot
      matchidx <- as.data.frame(which(layout == i, arr.ind = TRUE))
      
      print(plots[[i]], vp = viewport(layout.pos.row = matchidx$row,
                                      layout.pos.col = matchidx$col))
    }
  }
}
# http://www.cookbook-r.com/Graphs/Multiple_graphs_on_one_page_(ggplot2)/

# Data input, assesment : 데이터 불러들이기, 확인하는 과정 
library(readr) # Data input with readr::read_csv()
library(descr) # descr::CrossTable() - 범주별 빈도수, 비율 수치로 확인

# Visualization
library(VIM)             # Missing values assesment used by VIM::aggr()
library(ggplot2)         # Used in almost visualization 
library(RColorBrewer)    # plot의 color 설정 
library(scales)          # plot setting - x, y 축 설정

# Feature engineering, Data Pre-processing
library(tidyverse)     # dplyr, ggplot2, purrr, etc... 
library(dplyr)           # Feature Engineering & Data Pre-processing 
library(purrr)           # Check missing values 
library(tidyr)           # tidyr::gather() 

train <- readr::read_csv('train.csv')
test  <- readr::read_csv('test.csv')

# rbind(train,test) # There is no Survived variable in test set
full <- dplyr::bind_rows(train, test)

str(full) # 1309 obs, 12 variables
full <- full %>%
  dplyr::mutate(Survived = factor(Survived),
                Pclass   = factor(Pclass, ordered=F),
                Name     = factor(Name),
                Sex      = factor(Sex),
                Ticket   = factor(Ticket),
                Cabin    = factor(Cabin),
                Embarked = factor(Embarked))
str(full)
summary(full)

# Unique value of variables 
lapply(full, function(x) length(unique(x)))

# Missing values
require(moonBook)
na.count=apply(full, 2, function(x) sum(is.na(x)))
na.count[na.count>0]
sort(na.count[na.count>0], decreasing = T) %>% barplot

require(VIM)
# prop: 결측치를 비율로 표시
# combined: 그래프를 합쳐서 하나로 표시
# numbers: 결합 누적 개수를 표시
# sortVars: 변수들을 sort
# sortCombs: 결합 변수들 sort
aggr(full, prop = FALSE, combined = TRUE, numbers = TRUE,
          sortVars = TRUE, sortCombs = TRUE)
# cabin 결측치 529 -> cabin & Survived 결측치 244
marginplot(full[c("Pclass","Age")], pch=10, col=c("red", "blue"))

# ex) gather function
#iris.df = as.data.frame(iris)
#iris.df$row <- 1:nrow(iris.df)
#IRIS <- arrange(sample_n(iris.df[, -c(3:4)], 10), Species)
#IRIS
#iris_gather1 <- gather(IRIS, type, value, 1:2)
#iris_gather1
#iris_gather2 <- gather(IRIS, type, value, -Species, -row)
#iris_gather2
#gather(IRIS, key="Species", value="row")

# Check for missing values
missing_values <- full %>% summarize_all(funs(sum(is.na(.))/n()))
# wide to long
missing_values <- gather(missing_values, key="feature", value="missing_pct")
missing_values %>% 
  # Aesthetic setting : reorder(-missing_pct) : 내림차순으로 정렬
  # reorder(정렬하고 싶은 변수, 연속형 데이터, 함수)
  ggplot(aes(x=reorder(feature,missing_pct),y=missing_pct)) +
  geom_bar(stat="identity",fill="red")+ # y축의 높이를 데이터의 값으로
  #theme_bw() +
  coord_flip() + # 축 변환
  labs(x = "Feature names", y = "Rate") + 
  ggtitle("Rate of missing values")
# https://rpubs.com/paul_0907/438825
# https://m.blog.naver.com/PostView.nhn?blogId=hwan0447&logNo=221325812408&proxyReferer=https:%2F%2Fwww.google.com%2F

missing_values2 <- missing_values %>% filter(missing_pct>0)
missing_values2 %>% 
  ggplot(aes(x=reorder(feature,missing_pct),y=missing_pct)) +
  geom_bar(stat="identity",fill="red")+ # y축의 높이를 데이터의 값으로
  #theme_bw() +
  coord_flip() + # 축 변환
  labs(x = "Feature names", y = "Rate") + 
  ggtitle("Rate of missing values")

# Age
age.p1 <- full %>% 
  ggplot(aes(Age)) + 
  geom_histogram(breaks = seq(0, 80, by = 1), # 간격 설정 
                 col    = "black",            # 막대 경계선 색깔 
                 fill   = "green",            # 막대 내부 색깔 
                 alpha  = .5) +               # 막대 투명도 = 50% 
  ggtitle("Titanic passengers age plot") +
  theme(plot.title = element_text(face = "bold",    # 글씨체 
                                  hjust = 0.5,      # Horizon(가로비율) = 0.5
                                  size = 15,
                                  color = "darkblue"))

age.p2 <- full %>% 
  filter(!is.na(Survived)) %>% 
  ggplot(aes(Age, fill = Survived)) + 
  geom_density(alpha = .5) +
  ggtitle("Titanic passengers age density plot") + 
  theme(plot.title = element_text(face = "bold",
                                  hjust = 0.5,
                                  size = 15,
                                  color = "darkblue"))
multi.layout = matrix(c(1,1,2,2), nrow=2, byrow=T) # 세로로 2개
multiplot(age.p1, age.p2, layout = multi.layout)
multi.layout = matrix(c(1,1,2,2), nrow=2, byrow=F) # 가로로 2개
multiplot(age.p1, age.p2, layout = multi.layout)

# SibSp & Parch -> FamilySized
full <- full %>% 
  # SibSp + Parch + 1(myself) => FamilySize
  mutate(FamilySize = .$SibSp + .$Parch + 1,
         FamilySized = case_when(FamilySize == 1 ~ "Single",
                                 FamilySize >= 2 & FamilySize < 5 ~ "Small",
                                 FamilySize >= 5 ~ "Big"),
         FamilySized = factor(FamilySized, levels = c("Single", "Small", "Big")))

# Pclass
full %>% 
  group_by(Pclass) %>% 
  summarize(N = n()) %>% 
  ggplot(aes(Pclass, N)) +
  geom_col() +
  geom_text(aes(label = N),        # Plot의 y에 해당하는 N(빈도수)를 매핑
            size = 5,              # 글씨 크기 
            vjust = 1.2,           # vertical(가로) 위치 설정 
            colour = "white") +    # 글씨 색깔 : 흰색
          # color = "#FFFFFF")     # 글씨 색깔 : 흰색
  ggtitle("Number of each Pclass's passengers") + 
  theme(plot.title = element_text(face = "bold",
                                  hjust = 0.5,
                                  size = 15)) +
  labs(x = "Pclass", y = "Count")

# Fare
Fare.p1 <- full %>%
  ggplot(aes(Fare)) + 
  geom_histogram(col    = "black",
                 fill   = "green", 
                 alpha  = .5) +
  ggtitle("Histogram of passengers Fare") +
  theme(plot.title = element_text(face = "bold",
                                  hjust = 0.5,
                                  size = 15))

Fare.p2 <- full %>%
  filter(!is.na(Survived)) %>% 
  ggplot(aes(Survived, Fare)) + 
  # 관측치를 회색점으로 찍되, 중복되는 부분은 퍼지게 그려줍니다.
  #geom_jitter(col = "gray") + 
  geom_boxplot(alpha = .5) + 
  ggtitle("passengers Fare") +
  theme(plot.title = element_text(face = "bold",
                                  hjust = 0.5,
                                  size = 15))
multi.layout = matrix(c(1,1,2,2), 2, 2, byrow=F) # 가로로 2개
multiplot(Fare.p1, Fare.p2, layout = multi.layout)

# Sex
sex.p1 <- full %>% 
  group_by(Sex) %>% 
  summarize(N = n()) %>% 
  ggplot(aes(Sex, N)) +
  geom_col() +
  geom_text(aes(label = N),
            size = 5,
            vjust = 1.2,
            color = "#FFFFFF") + 
  ggtitle("Bar plot of Sex") +
  labs(x = "Sex", y = "Count")

sex.p2 <- full[1:891, ] %>% 
  ggplot(aes(Sex, fill = Survived)) +
  geom_bar(position = "fill") + 
  scale_fill_brewer(palette = "Set1") +
  scale_y_continuous(labels = percent) +
  ggtitle("Survival Rate by Sex") + 
  labs(x = "Sex", y = "Rate")

# position="fill" : 데이터의 종류를 비율로 표시 해주는 barplot 
full[1:891,] %>% 
  ggplot(aes(Sex, fill=Survived)) +
  geom_bar(position="fill") +
  scale_y_continuous(labels = percent) # y축을 %로 나타냄
# position="dodge" : 데이터의 종류를 따로 표시 해주는 barplot
full[1:891,] %>% 
  ggplot(aes(Sex, fill=Survived)) +
  geom_bar(position="dodge") +
  scale_y_continuous() # y축을 %로 나타냄
multi.layout = matrix(c(1,1,2,2), 2, 2, byrow=T)
multiplot(sex.p1, sex.p2, layout = multi.layout)
# mosaicplot
mosaicplot(Survived ~ Sex, data=full[1:891,], col=T,
           main="Survival tate by passengers sex")

# Embarked
full$Embarked <- replace(full$Embarked, which(is.na(full$Embarked)), 'S')

# Title
full$Name %>% head
Title <- gsub('(.*, )|(\\..*)', '', full$Name)
# 쉼표 전까지의 모든 문자,숫자,공백을 날리고 쉼표 후 한칸도 날린다
# 마침표를 찾아서(\\.) 그 뒤의 모든 문자,숫자,공백을 날린다.

# ^ : ^기호 뒤에 있는 글자로 시작하는 문장을 찾음
# . : 문자, 숫자, 공백을 가리지 않고 어떤 것이라도 매칭
# * : 무한번
# \\: 특수문자(^, $, ., ...)을 매칭
# $ : 문자열의 끝
# https://blog.naver.com/sw4r/221119461120
# https://statart.tistory.com/64
# https://statkclee.github.io/nlp2/regex-index.html
# Another way
Title <- gsub("^.*, (.*?)\\..*$", "\\1", full$Name)
# ( needs to be escaped
# \\(, . means everything,
# * means repeated 0 to n,
# ? means non greedy to remove not everything from the first to the last match.
full$Title <- Title
unique(Title)
table(Title)
# 18 -> 5 범주화
full <- full %>% 
  mutate(Title = ifelse(Title %in% c("Mlle", "Ms", "Lady", "Dona"), "Miss", Title),
         Title = ifelse(Title == "Mme", "Mrs", Title),
         Title = ifelse(Title %in% c("Capt", "Col", "Major", "Dr", "Rev", "Don",
                                     "Sir", "the Countess", "Jonkheer"), "Officer", Title),
         Title = factor(Title))
table(full$Title)

# Generate new variables: Age.Group
fit_Age <- rpart(Age ~ Title + Pclass + SibSp + Parch, data=full)
full$Age[is.na(full$Age)] <- predict(fit_Age, newdata=full[is.na(full$Age),])
fit_Fare <- rpart(Fare ~ Title + Pclass + Embarked + Sex + Age, data=full)
full$Fare[is.na(full$Fare)] <- predict(fit_Fare, newdata=full[is.na(full$Fare),])

full <- full %>%
  mutate(Age.Group = case_when(Age < 13 ~ "Age.0012",
                               Age >= 13 & Age < 18 ~ "Age.1317",
                               Age >= 18 & Age < 60 ~ "Age.1859",
                               Age >= 60 ~ "Age.60inf"),
         Age.Group = factor(Age.Group))

colnames(full)
train <- full[1:891,]
test <- full[892:1309,]
train <- train %>% 
  select("Pclass", "Sex", "Embarked", "FamilySized", "Fare",
         "Age.Group", "Title", "Survived")

Id <- test$PassengerId
test <- test %>% 
  select("Pclass", "Sex", "Embarked", "FamilySized", "Fare",
         "Age.Group", "Title", "Survived")

set.seed(123)
library(randomForest)
titanic.rf <- randomForest(Survived ~ ., data = train, importance = T, ntree = 2000)
importance(titanic.rf)
varImpPlot(titanic.rf)

pred.rf <- predict(object = titanic.rf, newdata = test, type = "class")

submit <- data.frame(PassengerId = Id, Survived = pred.rf)
write.csv(submit, file = './titanic_submit.csv', row.names = F)
