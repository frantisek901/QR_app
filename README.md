# (*Opravdu free*) QR_app

## Smysl a cíl

Tento repozitář slouží k vytvoření jednoduché appky, kam si student VŠ pošle odkaz a ona mu buď na e-mail, nebo ke stažení vrátí QR kód. Inspirovala mi situace, kdy řada studujících jako závěrečnou práci analyzuje data z vlastního dotazníku. Že si je seberou přes Google Forms, to je OK. Horší je, že po nástěnkách dávají QR kódy s žádostí o vyplnění a free-služby, co generování QR kódu nabízí si QR kódem pošlou respondenty nejprve na svou reklamu a vlastní odkaz na dotazník je utopený někde ve změti reklam a napsaný pettitem.

Chci dát všem studentům šanci, aby si mohli generovat QR kódy zadarmo. Opravdu zadarmo. A chci chránit respondenty před reklamou. To je tedy smysl tohoto repozitáře.

## Nabídka

Stahujte a používejte, pokud máte možnost appku opravdu zdarma provozovat.

Budu rád za Vaše komentáře a doplnění.

## Kdo

František Kalvas, \
Hlavní analytik ZČU v Plzni \
[kalvas\[at\]rek.zcu.cz](mailto:kalvas@rek.zcu.cz  "kalvas[at]rek.zcu.cz") \
+420 775 640 158

## Jak aplikaci spustit (Lokálně)

Pokud si chcete aplikaci rozběhnout u sebe na počítači, postupujte podle těchto kroků. Aplikace využívá R pro webové rozhraní (Shiny) a e-maily, a Python pro samotné generování QR kódů.

### 1. Příprava prostředí
* Ujistěte se, že máte nainstalované **R** (a ideálně i vývojové prostředí jako RStudio nebo Positron).
* Nainstalujte si **Python** (doporučena je verze 3.10 nebo novější).
* V R si nainstalujte potřebné balíčky spuštěním tohoto příkazu v konzoli:
  `install.packages(c("shiny", "reticulate", "DBI", "RSQLite", "digest", "emayili"))`

### 2. Nastavení e-mailu a hesel (Bezpečnost především!)
Aby aplikace mohla odesílat e-maily, potřebuje znát přihlašovací údaje k vašemu SMTP serveru. Tyto údaje **nikdy neukládáme přímo do kódu**, abychom je omylem nenahráli na internet!
1. V hlavní složce projektu najděte soubor `.Renviron.example`.
2. Vytvořte jeho kopii a tu pojmenujte přesně `.Renviron` (nezapomeňte na tečku na začátku). *Poznámka: Tento soubor je ignorován Gitem, takže zůstane jen u vás na disku.*
3. Otevřete `.Renviron` v textovém editoru a vyplňte své údaje:
   * `MY_EMAIL`: E-mail, ze kterého se zprávy odesílají.
   * `SMTP_USER` a `SMTP_PASS`: Vaše přihlašovací jméno a heslo (např. do univerzitní sítě).
   * `SMTP_HOST` a `SMTP_PORT`: Adresa serveru a port (často např. 465 pro šifrované spojení).
   * `APP_SALT`: Libovolný tajný text pro bezpečné hashování e-mailů v databázi.
4. **Důležité:** Po vytvoření nebo úpravě souboru `.Renviron` musíte R restartovat (Session -> Restart R), aby se proměnné načetly.

### 3. Vytvoření databáze
Než aplikaci poprvé spustíte, musíte vytvořit prázdnou databázi pro ukládání logů.
* Otevřete a spusťte skript `code/databaze.R` (případně jen `databaze.R`, podle toho, kde soubor máte). 
* Tento skript vytvoří soubor `database.sqlite` a připraví v něm potřebné tabulky.

### 4. Spuštění aplikace
Nyní máte vše připraveno! Otevřete soubor `app.R` a klikněte na tlačítko **Run App** (v RStudiu/Positronu). Aplikace se otevře ve vašem prohlížeči a je připravena generovat QR kódy.
