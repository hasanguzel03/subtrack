import Foundation

struct ServiceCatalogItem: Identifiable {
    let id = UUID()
    let name: String
    let iconName: String
    let colorHex: String
    let defaultPriceTRY: Double
    let defaultPriceUSD: Double
    let defaultPriceEUR: Double
    let defaultPriceGBP: Double
    let defaultCycle: String   // "monthly" or "yearly"

    func defaultPrice(for currencySymbol: String) -> Double {
        switch currencySymbol {
        case "₺": return defaultPriceTRY
        case "$": return defaultPriceUSD
        case "€": return defaultPriceEUR
        case "£": return defaultPriceGBP
        default: return defaultPriceUSD
        }
    }
}

let serviceCatalog: [ServiceCatalogItem] = [
    ServiceCatalogItem(name: "Netflix",          iconName: "film",                colorHex: "#E50914", defaultPriceTRY: 259.99, defaultPriceUSD: 17.99, defaultPriceEUR: 15.99, defaultPriceGBP: 12.99, defaultCycle: "monthly"),
    ServiceCatalogItem(name: "Spotify",          iconName: "music.note",          colorHex: "#1DB954", defaultPriceTRY: 115.0,  defaultPriceUSD: 12.99, defaultPriceEUR: 12.99, defaultPriceGBP: 11.99, defaultCycle: "monthly"),
    ServiceCatalogItem(name: "YouTube Premium",  iconName: "play.rectangle",      colorHex: "#FF0000", defaultPriceTRY: 119.99, defaultPriceUSD: 15.99, defaultPriceEUR: 12.99, defaultPriceGBP: 12.99, defaultCycle: "monthly"),
    ServiceCatalogItem(name: "iCloud+",          iconName: "icloud",              colorHex: "#007AFF", defaultPriceTRY: 49.99,  defaultPriceUSD: 0.99,  defaultPriceEUR: 0.99,  defaultPriceGBP: 0.99,  defaultCycle: "monthly"),
    ServiceCatalogItem(name: "Apple Music",      iconName: "headphones",          colorHex: "#FA243C", defaultPriceTRY: 89.99,  defaultPriceUSD: 10.99, defaultPriceEUR: 11.99, defaultPriceGBP: 10.99, defaultCycle: "monthly"),
    ServiceCatalogItem(name: "Amazon Prime",     iconName: "shippingbox",         colorHex: "#00A8E1", defaultPriceTRY: 69.90,  defaultPriceUSD: 14.99, defaultPriceEUR: 8.99,  defaultPriceGBP: 8.99,  defaultCycle: "monthly"),
    ServiceCatalogItem(name: "ChatGPT Plus",     iconName: "sparkles",            colorHex: "#10A37F", defaultPriceTRY: 999.99, defaultPriceUSD: 20.0,  defaultPriceEUR: 22.99, defaultPriceGBP: 19.99, defaultCycle: "monthly"),
    ServiceCatalogItem(name: "Gemini",           iconName: "sparkle",             colorHex: "#4285F4", defaultPriceTRY: 719.99, defaultPriceUSD: 19.99, defaultPriceEUR: 21.99, defaultPriceGBP: 18.99, defaultCycle: "monthly"),
    ServiceCatalogItem(name: "Claude",           iconName: "sun.max",             colorHex: "#D97757", defaultPriceTRY: 899.99, defaultPriceUSD: 20.0,  defaultPriceEUR: 21.99, defaultPriceGBP: 18.0,  defaultCycle: "monthly"),
    ServiceCatalogItem(name: "Disney+",          iconName: "star",                colorHex: "#113CCF", defaultPriceTRY: 249.90, defaultPriceUSD: 12.49, defaultPriceEUR: 9.99,  defaultPriceGBP: 8.99,  defaultCycle: "monthly"),
    ServiceCatalogItem(name: "Xbox Game Pass",   iconName: "gamecontroller",      colorHex: "#107C10", defaultPriceTRY: 409.0,  defaultPriceUSD: 14.99, defaultPriceEUR: 12.99, defaultPriceGBP: 10.99, defaultCycle: "monthly"),
    ServiceCatalogItem(name: "PlayStation Plus", iconName: "gamecontroller.fill", colorHex: "#0050C8", defaultPriceTRY: 400.0,  defaultPriceUSD: 10.99, defaultPriceEUR: 9.99,  defaultPriceGBP: 6.99,  defaultCycle: "monthly"),
]
