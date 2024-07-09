library(RMySQL)

# Replace with your actual database credentials
con <- dbConnect(RMySQL::MySQL(),
                 dbname = "SawtoothDB1",
                 host = "localhost",
                 username = "SawtoothUser",
                 password = "Jt535RMJx5")

dbIsValid(con)

# List tables in the database
dbListTables(con)
dbWriteTable(con, "mtcars", mtcars)
dbListTables(con)

# Read table on the database
dbReadTable(con, "mtcars")

# Remove table on the database
dbRemoveTable(con, "mtcars")
dbListTables(con)

# # Example query
# result <- dbGetQuery(con, "SELECT * FROM users")
# head(result)  # Display the first few rows of the result

# Disconnect from the database
dbDisconnect(con)
