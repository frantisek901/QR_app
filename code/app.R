#### Shiny App pro QR_app ####

## Encoding: UTF-8
## Upravil:  2026-03-16 FrK

# Pokud ti nějaký balíček chybí, nainstaluj ho přes install.packages()
library(shiny)
library(reticulate)
library(DBI)
library(RSQLite)
library(digest)

# --- 1. PROPOJENÍ S PYTHONEM ---
# Seznam balíčků, které náš Python skript potřebuje
python_packages <- c("qrcode", "pillow")

# Zkontrolujeme, zda jsou moduly dostupné.
# (Pozor: v Pythonu se balíček jmenuje 'pillow', ale importuje se jako 'PIL')
if (!py_module_available("qrcode") || !py_module_available("PIL")) {
  message(
    "🔧 Detekováno první spuštění: Instaluji potřebné Python balíčky (qrcode, pillow)..."
  )

  # py_install automaticky nainstaluje balíčky do toho správného .virtualenv pro reticulate
  py_install(python_packages)

  message("✅ Python balíčky jsou připraveny!")
}

# Nyní už můžeme bezpečně načíst náš Python skript
source_python("code/QR_gen.py")

# --- 2. UŽIVATELSKÉ ROZHRANÍ (UI) ---
ui <- fluidPage(
  titlePanel("Univerzitní QR Generátor pro Dotazníky"),

  sidebarLayout(
    sidebarPanel(
      # Vstupní pole
      textInput(
        "url",
        "Odkaz na dotazník (URL):",
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

    # 1. Vygenerování QR kódu přes PYTHON
    # Vytvoříme si dočasný soubor (temporary file), kam Python uloží obrázek
    temp_file <- tempfile(fileext = ".png")

    # TADY JE TA MAGIE: Voláme Python funkci z R!
    generate_qr(input$url, temp_file)

    # Uložíme cestu do reaktivní proměnné, aby se aktualizovalo UI
    qr_path(temp_file)

    # 2. Zápis do SQL DATABÁZE
    con <- dbConnect(RSQLite::SQLite(), "database.sqlite")

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
  })

  # 3. Vykreslení obrázku
  output$qr_plot <- renderImage(
    {
      # Čekáme, dokud v qr_path něco není (tj. dokud uživatel neklikne)
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

  # 4. Funkce pro stažení obrázku
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
