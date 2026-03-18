#### Skript pro generování QR kódů pro QR_app ####

## Encoding: UTF-8
## Upravil:  2026-03-16 FrK

## Část kódu pro případnou instalaci balíčků qrcode a PIL
import sys
import subprocess

# Funkce pro tichou instalaci balíčků
def install_package(package_name):
    print(f"🔧 Instaluji chybějící Python balíček: {package_name}...")
    subprocess.check_call([sys.executable, "-m", "pip", "install", package_name])

# Zkusíme načíst qrcode, pokud není, nainstalujeme
try:
    import qrcode
except ImportError:
    install_package("qrcode")
    import qrcode

# Zkusíme načíst pillow (modul se jmenuje PIL), pokud není, nainstalujeme
try:
    import PIL
except ImportError:
    install_package("pillow")
    import PIL


# Nyní už jede samotný skript na QR kód:
import os

def generate_qr(url: str, output_path: str = "figs/temp_qr.png") -> str:
    """
    Vygeneruje QR kód z poskytnuté URL a uloží ho jako obrázek.
    
    Parametry:
    url (str): Odkaz, na který má QR kód směřovat.
    output_path (str): Cesta, kam se má obrázek uložit.
    
    Vrací:
    str: Absolutní cestu k uloženému souboru (užitečné později pro R a e-maily).
    """
    # Nastavení parametrů QR kódu (aby vypadal hezky a byl dobře čitelný)
    qr = qrcode.QRCode(
        version=1, # Velikost matice (1 je nejmenší)
        error_correction=qrcode.constants.ERROR_CORRECT_H, # Vysoká oprava chyb (QR půjde přečíst i lehce poškozený)
        box_size=10, # Velikost jednoho "pixelu" v QR kódu
        border=4, # Velikost bílého okraje (4 je standard)
    )
    
    # Přidání dat a vygenerování
    qr.add_data(url)
    qr.make(fit=True)

    # Vytvoření obrázku (můžeme měnit barvy, pro začátek černobílý)
    img = qr.make_image(fill_color="black", back_color="white")
    
    # Uložení obrázku
    img.save(output_path)
    
    # Vrátíme absolutní cestu, aby s tím Rko (Shiny) a posílání e-mailů neměly problém
    return os.path.abspath(output_path)

# Malý testík, když tento skript spustíš přímo
if __name__ == "__main__":
    test_url = "Tohle je jen testovací QR kód!"
    test_file = "figs/test_qr.png"
    vysledek = generate_qr(test_url, test_file)
    print(f"Hotovo! QR kód pro {test_url} byl uložen do: {vysledek}")
