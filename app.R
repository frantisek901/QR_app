#### Shiny App pro QR_app ####

## Encoding: UTF-8
## Upravil:  2026-03-16 FrK

# Pokud ti nějaký balíček chybí, nainstaluj ho přes install.packages()
library(shiny)
library(reticulate)
library(DBI)
library(RSQLite)
library(digest)
library(stringr)

# --- 1. PROPOJENÍ S PYTHONEM ---
# Jdeme načíst náš Python skript
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
      "Setkali jsme se s tím, že studující v dobré víře často používají pro odkazy (URL) na své dotazníky různé 'free' generátory QR kódů. Tyto pochybné služby ale respondenty často přesměrují nejdříve na agresivní reklamu, nebo po čase přestanou fungovat úplně. Každopádně to nevrhá dobré světlo na dotazníkové průzkumy na univerzitě obecně. Proto jsme vytvořili (za pomoci Gemini 3.0 Pro) tento univerzitní generátor -- je čistý, bezpečný, spolehlivý a bez jakýchkoliv háčků."
    ),

    h4("Jak generátor používat:"),
    tags$ul(
      tags$li(
        strong("Cílový odkaz:"),
        " Zkopírujte a vložte plnou URL adresu Vašeho dotazníku (např. z Google Forms, Click4Survey, MS Forms, Survio, Qualtrics). ",
        br(),
        strong("Poznámka:"),
        " Nemusí jít nutně o odkaz na dotazník, naše služba Vám do QR kódu zakóduje jakýkoli odkaz. Dokonce jakýkoli text včetně emoji až do maximální délky 480 znaků."
      )
    ),
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

    # --- NOVÉ: Bezpečnostní validace délky ---
    if (nchar(input$url) > 480) {
      showNotification(
        "Jejda! Odkaz/text je příliš dlouhý (více než 480 znaků). Zkuste ho zkrátit, ať aplikace zvládne QR kód vygenerovat.",
        type = "error",
        duration = 6
      )
      # return() funguje jako stopka - zastaví kód, takže se Python vůbec nezavolá
      return()
    }

    # --- KROK 1. Vygenerování QR kódu přes PYTHON ---
    # Vytvoříme si dočasný soubor (temporary file), kam Python uloží obrázek
    temp_file <- tempfile(fileext = ".png")

    # TADY JE TA MAGIE: Voláme Python funkci z R! Obrázek se fyzicky uloží.
    generate_qr(input$url, temp_file)

    # Uložíme cestu do reaktivní proměnné, aby se aktualizovalo UI
    qr_path(temp_file)

    # --- KROK 2. Zápis do SQL DATABÁZE ---
    con <- dbConnect(RSQLite::SQLite(), "data/database.sqlite")

    # Automatické vytvoření tabulky, pokud databáze začíná s čistým štítem
    dbExecute(
      con,
      "CREATE TABLE IF NOT EXISTS qr_logs (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      target_url TEXT NOT NULL
      )
      "
    )

    # Bezpečný zápis do databáze
    dbExecute(
      con,
      "
      INSERT INTO qr_logs (target_url) 
      VALUES (?)
    ",
      params = list(input$url)
    )

    dbDisconnect(con) # Slušné vychování - odpojíme se
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
