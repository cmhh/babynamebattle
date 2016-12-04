library(RSQLite)

con <- dbConnect(RSQLite::SQLite(), "data/battle.db")

addResourcePath("assets", paste0(getwd(), "/www/assets"))
