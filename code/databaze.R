#### Skript na vytvoření SQLite databáze ####

## Encoding: UTF-8
## Upravil:  2026-03-16 FrK

# Nainstaluj balíček RSQLite, pokud ho ještě nemáš: 
# install.packages("RSQLite")
library(DBI)
library(RSQLite)
library(digest)

# 1. Připojení k databázi
con <- dbConnect(RSQLite::SQLite(), "database.sqlite")

# (Volitelné) Smazání staré tabulky z předchozího pokusu
dbExecute(con, "DROP TABLE IF EXISTS qr_logs")

# 2. Vytvoření upravené tabulky
# Místo 'email_sent' máme 'email_hash'.
# Je to TEXT a může být NULL (pokud student e-mail nezadá).
dbExecute(
  con,
  "
  CREATE TABLE IF NOT EXISTS qr_logs (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      target_url TEXT NOT NULL,
      email_hash TEXT
  )
"
)

# 3. Simulace vstupu od uživatele a zahašování
student_email <- "jan.novak@univerzita.cz"
# Použijeme algoritmus sha256.
# Tip: V praxi je dobré email před hashem převést na malá písmena (tolower),
# aby 'Jan@...' a 'jan@...' měly stejný hash.
hashed_email <- digest(tolower(student_email), algo = "sha256")

# 4. Vložení testovacího záznamu do databáze
# Použijeme parametrizovaný dotaz (tzv. bind variables) pomocí dbExecute.
# Je to bezpečnější proti SQL injection, i když tady nám to asi nehrozí.
dbExecute(
  con,
  "
  INSERT INTO qr_logs (target_url, email_hash) 
  VALUES (?, ?)
",
  params = list('https://moje-univerzita.cz/dotaznik-test', hashed_email)
)

# A co když email nezadá? Uložíme tam NA (v SQL se to přeloží jako NULL)
dbExecute(
  con,
  "
  INSERT INTO qr_logs (target_url, email_hash) 
  VALUES (?, ?)
",
  params = list('https://moje-univerzita.cz/dotaznik-jiny', NA)
)

# 5. Kontrola dat
test_data <- dbGetQuery(con, "SELECT * FROM qr_logs")
print(test_data)

# 6. Odpojení
dbDisconnect(con)
