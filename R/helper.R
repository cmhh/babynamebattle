library(sampling)
library(dplyr)
library(data.table)
library(dtplyr)

con <- dbConnect(SQLite(), dbname="data/battle.db")

getbattlesummary <- function(con, player, sex = 'M'){
  query <- paste0("
  SELECT
    name1 as name,
    sum(winner == 1) as wins,
    sum(winner == 2) as losses
  FROM
    battles
  WHERE
    player = \'", player, "\' 
    and sex = \'", sex, "\'
    and NOT EXISTS(
      SELECT
        *
      FROM
        scratched
      WHERE
        battles.name1 = scratched.name
    )
  GROUP BY
    name1
  UNION
  SELECT
    name2 as name,
    sum(winner == 2) as wins,
    sum(winner == 1) as losses
  FROM
    battles
  WHERE
    player = \'", player, "\' 
    and sex = \'", sex, "\'
    and NOT EXISTS(
      SELECT
        *
      FROM
        scratched
      WHERE
        battles.name2 = scratched.name
    )
  GROUP BY
    name2
  ")
  
  res <- data.table(dbGetQuery(con, query))
  res <- data.table(group_by(res, name) %>% summarise(wins = sum(wins), losses = sum(losses)))
  res[, c("battles", "win percent") := .(wins + losses, round(wins / (wins + losses) * 100, 2))]
  setorderv(res, "win percent", -1L)
  res
}

getwinners <- function(con, player, sex = 'M'){
  query <- paste0("
  SELECT
    roster.*
  FROM
    roster
  INNER JOIN
    (
      SELECT
        DISTINCT
        sex,
        name
      FROM
        (
          SELECT
            DISTINCT
            sex,
            name1 as name
          FROM
            battles
          WHERE
            winner = 1
            and player = \'", player, "\'
            and sex = \'", sex, "\'
            and NOT EXISTS(
              SELECT
                *
              FROM
                scratched
              WHERE
                battles.name1 = scratched.name
            )
          UNION
          SELECT
            DISTINCT
            sex,
            name2 as name
          FROM
            battles
          WHERE
            winner = 2
            and player = \'", player, "\'
            and sex = \'", sex, "\'
          and NOT EXISTS(
            SELECT
              *
            FROM
              scratched
            WHERE
              battles.name2 = scratched.name
          )
        )
    ) winners
  ON
  roster.sex = winners.sex
  AND roster.name = winners.name
  ")
  res <- data.table(dbGetQuery(con, query))
  res
}

getscratched <- function(con, player, sex = 'M'){
  x <- getbattlesummary(con, player, sex)
  query <- paste0("
    SELECT
      name, sex
    FROM
      scratched
    WHERE
      player = \'", player, "\'
      and sex = \'", sex, "\'
  ")
  y <- data.table(dbGetQuery(con, query))
  merge(y, x, by="name", all.x = TRUE, all.y = FALSE)
}

getname <- function(con, player, sex = 'M'){
  query <- paste0("
    SELECT 
       roster.* 
    FROM 
      roster
    WHERE NOT EXISTS 
      (
        SELECT 
          * 
        FROM 
          scratched 
        WHERE 
          player =  \'", player, "\'
          and roster.sex = scratched.sex
          and roster.name = scratched.name
      )
    and
      sex = \'", sex, "\'")
  res <- dbGetQuery(con, query)
  res$pik <- res$p/sum(res$p)
  unlist(res[sampling::UPsystematic(res$pik)==1, "name"])
}

getname1 <- function(con, player, sex = 'M'){
   res <- getwinners(con, player, sex)
   n <- nrow(res)
   if (n>=5){
      res <- unlist(res[sample(n,1), name])
   }
   else res <- getname(con, player, sex)
   return(res)
}

logbattle <- function(con, player, sex = 'M', name1, name2, winner){
   query <- "INSERT INTO battles values(?, ?, ?, ?, ?)"
   res <- dbSendPreparedQuery(con, query, 
                       data.frame(player = player, sex = sex,
                                  name1 = name1, name2 = name2, winner = winner))
   dbClearResult(res)
}

cut0 <- function(con, player, sex, name){
   query <- "INSERT INTO SCRATCHED values(?, ?, ?)"
   res <- dbSendPreparedQuery(con, query, data.frame(player = player, sex = sex, name = name))
   dbClearResult(res)
}

restore <- function(con, player, sex, name){
  query <- "DELETE FROM scratched WHERE player = ? AND sex = ? AND name = ?"
  res <- dbSendPreparedQuery(con, query, data.frame(player = player, sex = sex, name = name))
  dbClearResult(res)
}

delete <- function(con, player, sex, name){
  query <- "INSERT INTO SCRATCHED values(?, ?, ?)"
  res <- dbSendPreparedQuery(con, query, data.frame(player = player, sex = sex, name = name))
  dbClearResult(res)
}