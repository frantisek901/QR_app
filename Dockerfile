#### Dockerfile ####

#### Dockerfile ####

# 1. Základ pro R Shiny aplikaci
FROM rocker/shiny:4.3.2

# 2. Instalace systémových nástrojů pro Python a R balíčky
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    python3-venv \
    libsqlite3-dev \
    libssl-dev \
    libcurl4-openssl-dev \
    libxml2-dev \
    zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

# 3. Příprava bezpečného virtuálního prostředí pro Python
ENV VIRTUAL_ENV=/opt/venv
RUN python3 -m venv $VIRTUAL_ENV
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

# 4. Instalace Python balíčků
RUN pip install --no-cache-dir qrcode pillow

# 5. Instalace R balíčků (NEPRŮSTŘELNÁ VERZE)
# Pokud se nějaký balíček nenainstaluje, Rko okamžitě ukončí Docker build s chybou!
RUN R -e "pkgs <- c('shiny', 'reticulate', 'DBI', 'RSQLite'); install.packages(pkgs, repos='https://cloud.r-project.org/'); if (!all(pkgs %in% installed.packages()[,'Package'])) { quit(status=1, save='no') }"

# 6. Pracovní složka v kontejneru
WORKDIR /srv/shiny-server/qr_app

# 7. Zkopírování všeho z rootu (včetně /code a /figs) do kontejneru
COPY . /srv/shiny-server/qr_app/

# 8. Vytvoření složky figs pro jistotu
RUN mkdir -p /srv/shiny-server/qr_app/figs

# 9. Nasměrování reticulate na izolovaný Python v kontejneru
ENV RETICULATE_PYTHON="$VIRTUAL_ENV/bin/python"

# 10. Nastavení práv, aby Shiny mohlo zapisovat do DB a složky figs
RUN chown -R shiny:shiny /srv/shiny-server/qr_app

# 11. Otevření portu pro prohlížeč
EXPOSE 3838

# 12. Spuštění aplikace z rootu
USER shiny
CMD ["R", "-e", "shiny::runApp('/srv/shiny-server/qr_app', host = '0.0.0.0', port = 3838)"]
