# (*Opravdu free*) QR_app

## Smysl a cíl

Tento repozitář slouží k vytvoření jednoduché appky, kam si student VŠ pošle odkaz a ona mu ke stažení vrátí QR kód. Inspirovala mě situace, kdy řada studujících jako závěrečnou práci analyzuje data z vlastního dotazníku. Sběr přes Google Forms, to je OK. Horší je, že po nástěnkách dávají QR kódy s žádostí o vyplnění a free-služby, co generování QR kódu nabízí, si QR kódem pošlou respondenty nejprve na svou reklamu a vlastní odkaz na dotazník je utopený někde ve změti reklam a napsaný pettitem.

Chci dát všem studentům šanci, aby si mohli generovat QR kódy zadarmo. Opravdu zadarmo. A chci chránit respondenty před reklamou. To je tedy smysl tohoto repozitáře.

## Nabídka

Stahujte a používejte, pokud máte možnost appku opravdu zdarma provozovat. Budu rád za Vaše komentáře a doplnění.

## Kdo

František Kalvas,\
Hlavní analytik ZČU v Plzni\
[kalvas\[at\]rek.zcu.cz](mailto:kalvas@rek.zcu.cz "kalvas[at]rek.zcu.cz")\
+420 775 640 158

## Jak aplikaci spustit (Doporučeno: Docker)

Nejčistší a nejjednodušší cesta, jak aplikaci nasadit na server nebo u sebe na počítači, je pomocí Dockeru. Aplikace spojuje R (Shiny) a Python, a kontejner zajistí, že vše poběží bez nutnosti složité instalace závislostí.

### 1. Příprava před spuštěním

1)  Naklonujte si tento repozitář: `git clone https://github.com/frantisek901/QR_app.git`
2)  V hlavní složce projektu **vytvořte prázdnou složku `data`**. Do této složky se bude ukládat soubor `database.sqlite`, aby logy přežily i restart kontejneru.

### 2. Sestavení Docker obrazu (Build)

V terminálu (ve složce projektu) spusťte:

``` bash
docker build -t qr_app_image .
```

### 3. Spuštění kontejneru (Run)

Pro spuštění kontejneru a propojení databáze s vaší lokální složkou data použijte následující příkaz. **(Poznámka: Nezapomeňte absolutní cestu /absolutni/cesta/k/vasi/slozce/data nahradit skutečnou cestou k vaší vytvořené složce na serveru.)**

``` bash
docker run -d \
  -p 3838:3838 \
  -v "/absolutni/cesta/k/vasi/slozce/data:/srv/shiny-server/qr_app/data" \
  --name qr_app_kontejner \
  qr_app_image
```

Aplikace poběží na adrese `http://localhost:3838`

### 4. Pro vývojáře (Lokální spuštění bez Dockeru)

Pokud chcete aplikaci upravovat a vyvíjet lokálně bez Dockeru:

1)  Nainstalujte **R** a **Python** (verze 3.10+).
2)  V R nainstalujte potřebné balíčky: `install.packages(c("shiny", "reticulate", "DBI", "RSQLite"))`.
3)  Otevřete a spusťte skript `code/databaze.R` (vytvoří lokální prázdnou databázi `database.sqlite` ve složce `data`).
4)  Otevřete `app.R` v **RStudiu/Positronu** a klikněte na `Run Shiny App` nebo stiskněte `Ctrl + Shift + Enter`.
