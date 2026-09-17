# Package install
# install.packages("palmerpenguins")
# install.packages("ggplot2")
# install.packages("dplyr")

# Load libraries
library(palmerpenguins)
library(ggplot2)
library(dplyr)
library(readr)

citation("ggplot2")

# Inspect penguins dataset
data("penguins")
head(penguins)
tail(penguins,2)
summary(penguins)

sec.column <- penguins[,2]
sec.column

penguins[3:5, 3]
mean(penguins$body_mass,na.rm=TRUE)
mean(penguins$body_mass)

table(penguins$island)
prop.table(table(penguins$island))

fahrenheit_to_celsius <- function(temp_F) {
  temp_C <- ((temp_F - 32)*5)/9
  return(temp_C)
}

fahrenheit_to_celsius(100)

storms <- read.csv("assignments/datasets/storms.csv")
View(storms)
summary(storms)

# partition a hurricane subset
hurricane <- storms[storms$status == "hurricane", c('name', 'year', 'category', 'pressure', 'wind')]
head(hurricane)

# select specific columns in our hurricance subset
hurricane <- hurricane[, c('name', 'year', 'category', 'pressure', 'wind')]

# categorize? hurricanes by their wind speed
wind_speed <- function(wind) {
  if(wind<80){"Low wind speed"}
  else if(wind<110){"Moderate wind speed"}
  else{"Huff and puff and puff (High wind speed)"}
}
# wind_speed(hurricane[1000,"wind"])

hurricane$windclass <- sapply(
  hurricane$wind, wind_speed)

head(hurricane)
