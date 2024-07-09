# Load the RCurl package
library(RCurl)

# FTP server details
ftp_server <- "192.168.66.92"
ftp_port <- 21
ftp_user <- "ftpuser"
ftp_password <- "ftppassword"

# Function to list files on the FTP server
list_files_ftp <- function(ftp_server, ftp_port, ftp_user, ftp_password) {
  # Construct the FTP URL with user credentials
  ftp_url <- paste0("ftp://", ftp_user, ":", ftp_password, "@", ftp_server, ":", ftp_port)

  # Attempt to get the list of files
  tryCatch({
    file_list <- getURL(ftp_url, ftp.use.epsv = FALSE, dirlistonly = TRUE)
    cat("Files on the FTP server:\n", file_list, "\n")
  }, error = function(e) {
    cat("Error: ", e$message, "\n")
  })
}

# Test the FTP access
list_files_ftp(ftp_server, ftp_port, ftp_user, ftp_password)


# # Load the RCurl package
# library(RCurl)
#
# FTP server details
ftp_url <- "ftp://127.0.0.1"
username <- "ftpuser"
password <- "ftppassword"

# List files in the FTP directory
ftp_files <- getURL(ftp_url, userpwd = paste(username, password, sep = ":"))
cat(ftp_files)

# Download a specific file from the FTP server
file_url <- "ftp://example.com/path/to/yourfile.txt"
downloaded_file <- getBinaryURL(file_url, userpwd = paste(username, password, sep = ":"))

# Save the downloaded file locally
writeBin(downloaded_file, "localfile.txt")
