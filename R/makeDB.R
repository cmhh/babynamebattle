library(babynames)
library(data.table)
library(dtplyr)
library(RSQLite)

namesdt <- data.table(babynames)
setkey(namesdt, year, sex, name)
namesdt[, w := sapply(year, function(x) (x - 1880) / 134)]

n <- group_by(namesdt, sex, name) %>% summarise(n = sum(n * w))
N <- group_by(namesdt, sex) %>% summarise(N = sum(n * w))
setkey(n, sex, name)
setkey(N, sex)

roster <- merge(n, N, by="sex")
roster[, p := n / N]
roster <- roster[, .(sex, name, p)]
setkey(roster, sex, name)

players <- data.table(player=c("Jenna", "Chris"))

db = dbConnect(SQLite(), dbname="data/battle.db")

dbWriteTable(db, "roster", roster)

query <- "
CREATE TABLE battles (player TEXT, sex TEXT, name1 TEXT, name2 TEXT, winner INTEGER)
"
dbSendQuery(conn = db, query)

query <- "
CREATE TABLE scratched (player TEXT, sex TEXT, name TEXT)
"
dbSendQuery(conn = db, query)

dbDisconnect(db)