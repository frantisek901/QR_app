#### Shiny App pro QR_app ####

## Encoding: UTF-8
## Upravil:  2026-03-16 FrK

# Pokud ti nějaký balíček chybí, nainstaluj ho přes install.packages()
library(shiny)
library(reticulate)
library(DBI)
library(RSQLite)
library(digest)
# install.packages("emayili")
library(emayili)

# --- 1. PROPOJENÍ S PYTHONEM ---
# # Seznam balíčků, které náš Python skript potřebuje
# python_packages <- c("qrcode", "pillow")
# 
# # Zkontrolujeme, zda jsou moduly dostupné.
# # (Pozor: v Pythonu se balíček jmenuje 'pillow', ale importuje se jako 'PIL')
# if (!py_module_available("qrcode") || !py_module_available("PIL")) {
#   message(
#     "🔧 Detekováno první spuštění: Instaluji potřebné Python balíčky (qrcode, pillow)..."
#   )
# 
#   # py_install automaticky nainstaluje balíčky do toho správného .virtualenv pro reticulate
#   py_install(python_packages)
# 
#   message("✅ Python balíčky jsou připraveny!")
# }
# 
# Nyní už můžeme bezpečně načíst náš Python skript
source_python("code/QR_gen.py")

# --- 2. UŽIVATELSKÉ ROZHRANÍ (UI) ---
ui <- fluidPage(
  # Hlavička aplikace
  titlePanel("Opravdu free QR generátor"),

  # --- ZAČÁTEK: Instrukce pro uživatele ---
  div(
    class = "well",

    h4("Proč tento nástroj vznikl?"),
    p(
      "Setkali jsme se s tím, že studující v dobré víře často používají různé 'free' generátory QR kódů pro své dotazníky. Tyto pochybné služby ale respondenty občas přesměrují nejdříve na agresivní reklamu, nebo po čase přestanou fungovat úplně. Každopádně to nevrhá dobré světlo na dotazníkové průzkumy na univerzitě obecně. Proto jsme vytvořili (za pomoci Gemini 3.0 Pro) tento univerzitní generátor -- je čistý, bezpečný, spolehlivý a bez jakýchkoliv háčků."
    ),

    h4("Jak generátor používat:"),
    tags$ul(
      tags$li(
        strong("Cílový odkaz:"),
        " Zkopírujte a vložte plnou URL adresu Vašeho dotazníku (např. z Google Forms, Click4Survey, MS Forms, Survio, Qualtrics)."
      ),
      tags$li(
        strong("E-mail (volitelně):"),
        " Vygenerovaný QR kód si můžete rovnou stáhnout zde na stránce. Pokud ale právě pracujete na mobilu, můžete si ho nechat poslat do e-mailové schránky a pohodlně ho vložit do textu až později na počítači."
      )
    ),

    p(
      strong("🔒 Ochrana soukromí:"),
      " Vaše e-mailové adresy nijak neskladujeme ani nesdílíme. V naší databázi se ukládá pouze jejich nevratně zašifrovaný otisk (hash), ze kterého nelze původní e-mail zpětně přečíst. Slouží nám jen pro základní statistiku využití aplikace."
    )
  ),
  # --- KONEC: Instrukce pro uživatele ---

  sidebarLayout(
    sidebarPanel(
      # Vstupní pole
      textInput(
        "url",
        "Váš odkaz (na dotazník) (URL):",
        placeholder = "https://www.zcu.cz/..."
      ),
      textInput(
        "email",
        "Váš e-mail (volitelné):",
        placeholder = "jmeno@zcu.cz"
      ),

      # Tlačítka
      actionButton(
        "generate",
        "Vytvořit QR kód",
        class = "btn-primary",
        style = "width: 100%; margin-bottom: 15px;"
      ),
      downloadButton("download_qr", "Stáhnout QR kód", style = "width: 100%;")
    ),

    mainPanel(
      h4("Váš vygenerovaný QR kód:"),
      # Zde se zobrazí obrázek
      imageOutput("qr_plot")
    )
  )
)

# --- 3. SERVEROVÁ LOGIKA ---
server <- function(input, output, session) {
  # Reaktivní proměnná pro ukládání cesty k vygenerovanému obrázku
  qr_path <- reactiveVal(NULL)

  # Co se stane po kliknutí na tlačítko "Vytvořit QR kód"
  observeEvent(input$generate, {
    # Zkontrolujeme, že uživatel zadal nějaké URL (aby nám to nespadlo)
    req(input$url)

    # --- KROK 1. Vygenerování QR kódu přes PYTHON ---
    # Vytvoříme si dočasný soubor (temporary file), kam Python uloží obrázek
    temp_file <- tempfile(fileext = ".png")

    # TADY JE TA MAGIE: Voláme Python funkci z R! Obrázek se fyzicky uloží.
    generate_qr(input$url, temp_file)

    # Uložíme cestu do reaktivní proměnné, aby se aktualizovalo UI
    qr_path(temp_file)

    # --- KROK 2. Zápis do SQL DATABÁZE ---
    con <- dbConnect(RSQLite::SQLite(), "database.sqlite")

    # Automatické vytvoření tabulky, pokud databáze začíná s čistým štítem
    dbExecute(
      con,
      "CREATE TABLE IF NOT EXISTS qr_logs (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      target_url TEXT NOT NULL,
      email_hash TEXT
      )
      "
    )

    # Hashování e-mailu (pokud ho student zadal)
    email_hash <- NA
    if (trimws(input$email) != "") {
      # Zkusíme načíst sůl z .Renviron (pokud tam není, vezme to prázdný řetězec)
      salt <- Sys.getenv("APP_SALT", unset = "")
      email_hash <- digest::digest(
        paste0(tolower(trimws(input$email)), salt),
        algo = "sha256"
      )
    }

    # Bezpečný zápis do databáze
    dbExecute(
      con,
      "
      INSERT INTO qr_logs (target_url, email_hash) 
      VALUES (?, ?)
    ",
      params = list(input$url, email_hash)
    )

    dbDisconnect(con) # Slušné vychování - odpojíme se

    # --- KROK 3. Odeslání E-MAILU ---
    # Pokud uživatel vyplnil políčko s e-mailem
    if (trimws(input$email) != "") {
      # Vytvoření zprávy
      email_msg <- envelope() |>
        from(Sys.getenv("MY_EMAIL")) |> # Tvůj otestovaný odesílatel
        to(trimws(input$email)) |> # Dynamický e-mail od uživatele
        subject("Tvůj QR kód (pro dotazník) je připraven!") |>
        text(paste0(
          "Vážená uživatelko, vážený uživateli,\n\n\n",
          "v příloze Vám posíláme vygenerovaný QR kód pro odkaz (na Váš dotazník): ",
          input$url,
          "\n\n\n",
          "Ať se Vám daří!\n",
          "František Kalvas & univerzitní QR generátor"
        )) |>
        attachment(qr_path()) # TADY připojujeme ten obrázek z disku!

      # Nastavení SMTP serveru (tvá funkční konfigurace)
      smtp_server <- emayili::server(
        host = Sys.getenv("SMTP_HOST"),
        port = as.integer(Sys.getenv("SMTP_PORT")),
        username = Sys.getenv("SMTP_USER"), # Tvůj otestovaný login
        password = Sys.getenv("SMTP_PASS")
      )

      # Samotné odeslání (zabalené do tryCatch, aby appka nespadla, když někdo zadá nesmyslný e-mail)
      tryCatch(
        {
          smtp_server(email_msg)
          showNotification(
            "E-mail s QR kódem byl úspěšně odeslán!",
            type = "message"
          )
        },
        error = function(e) {
          showNotification(
            paste("Chyba při odesílání e-mailu:", e$message),
            type = "error"
          )
        }
      )
    }
  })

  # --- ZOBRAZOVACÍ ČÁST (UI logika, proběhne až po dokončení observeEvent) ---

  # Vykreslení obrázku v prohlížeči
  output$qr_plot <- renderImage(
    {
      # Čekáme, dokud v qr_path něco není
      req(qr_path())

      # Vrátíme seznam pro renderImage
      list(
        src = qr_path(),
        alt = "Vygenerovaný QR kód",
        width = 300,
        height = 300
      )
    },
    deleteFile = FALSE
  )

  # Funkce pro stažení obrázku
  output$download_qr <- downloadHandler(
    filename = function() {
      paste0("QR_dotaznik_", Sys.Date(), ".png")
    },
    content = function(file) {
      # Zkopírujeme náš dočasný soubor tam, kam si to uživatel stahuje
      file.copy(qr_path(), file)
    }
  )
}

# Spuštění aplikace
shinyApp(ui = ui, server = server)
