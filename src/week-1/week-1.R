# # greetings = function(name) {
# #   message = paste("Hello,",name)
# #   return(message)
# # }
# # 
# # greetings(name="Sebastian")
# # 
# # a <- c(1,2,3,4,5,6)
# # b <- c(7,8,9,10,11,12)
# # ab <- a+b
# # ab
# install.packages("palmerpenguins")
# install.packages("ggplot2")
# install.packages("tidyverse")
# # install.packages("")
# 
library(palmerpenguins)
library(ggplot2)
# library(tidyverse)

data(penguins)

plot <- ggplot(data=penguins,
               aes(x=flipper_length_mm,
                   y=body_mass_g)) +
  geom_point(aes(color=species,
                 shape=species))
plot
