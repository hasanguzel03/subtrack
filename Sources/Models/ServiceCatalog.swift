import Foundation

struct ServiceCatalogItem: Identifiable {
    let id = UUID()
    let name: String
    let iconName: String
    let colorHex: String
    let defaultPriceTRY: Double
    let defaultPriceUSD: Double
    let defaultCycle: String   // "monthly" or "yearly"
}

let serviceCatalog: [ServiceCatalogItem] = [
    ServiceCatalogItem(name: "Netflix",              iconName: "film",                colorHex: "#E50914", defaultPriceTRY: 229,    defaultPriceUSD: 15.49, defaultCycle: "monthly"),
    ServiceCatalogItem(name: "Spotify",              iconName: "music.note",          colorHex: "#1DB954", defaultPriceTRY: 59,     defaultPriceUSD: 10.99, defaultCycle: "monthly"),
    ServiceCatalogItem(name: "YouTube Premium",      iconName: "play.rectangle",      colorHex: "#FF0000", defaultPriceTRY: 79.99,  defaultPriceUSD: 13.99, defaultCycle: "monthly"),
    ServiceCatalogItem(name: "iCloud+",              iconName: "icloud",              colorHex: "#007AFF", defaultPriceTRY: 39.99,  defaultPriceUSD: 2.99,  defaultCycle: "monthly"),
    ServiceCatalogItem(name: "Apple Music",          iconName: "headphones",          colorHex: "#FA243C", defaultPriceTRY: 39.99,  defaultPriceUSD: 10.99, defaultCycle: "monthly"),
    ServiceCatalogItem(name: "Amazon Prime",         iconName: "shippingbox",         colorHex: "#00A8E1", defaultPriceTRY: 39,     defaultPriceUSD: 14.99, defaultCycle: "monthly"),
    ServiceCatalogItem(name: "ChatGPT Plus",         iconName: "sparkles",            colorHex: "#10A37F", defaultPriceTRY: 679,    defaultPriceUSD: 20,    defaultCycle: "monthly"),
    ServiceCatalogItem(name: "Disney+",              iconName: "star",                colorHex: "#113CCF", defaultPriceTRY: 149,    defaultPriceUSD: 13.99, defaultCycle: "monthly"),
    ServiceCatalogItem(name: "BluTV",                iconName: "tv",                  colorHex: "#002BE7", defaultPriceTRY: 84.99,  defaultPriceUSD: 7.99,  defaultCycle: "monthly"),
    ServiceCatalogItem(name: "Max",                  iconName: "tv",                  colorHex: "#002BE7", defaultPriceTRY: 149,    defaultPriceUSD: 15.99, defaultCycle: "monthly"),
    ServiceCatalogItem(name: "Exxen",                iconName: "play.circle",         colorHex: "#F5C518", defaultPriceTRY: 149.90, defaultPriceUSD: 9.99,  defaultCycle: "monthly"),
    ServiceCatalogItem(name: "Xbox Game Pass",       iconName: "gamecontroller",      colorHex: "#107C10", defaultPriceTRY: 339,    defaultPriceUSD: 17.99, defaultCycle: "monthly"),
    ServiceCatalogItem(name: "PlayStation Plus",     iconName: "gamecontroller.fill", colorHex: "#0050C8", defaultPriceTRY: 440,    defaultPriceUSD: 17.99, defaultCycle: "monthly"),
    ServiceCatalogItem(name: "Adobe Creative Cloud", iconName: "paintbrush",          colorHex: "#FF0000", defaultPriceTRY: 1200,   defaultPriceUSD: 59.99, defaultCycle: "monthly"),
    ServiceCatalogItem(name: "Canva Pro",            iconName: "wand.and.stars",      colorHex: "#00C4CC", defaultPriceTRY: 529,    defaultPriceUSD: 12.99, defaultCycle: "monthly"),
    ServiceCatalogItem(name: "Duolingo Super",       iconName: "book",                colorHex: "#58CC02", defaultPriceTRY: 519,    defaultPriceUSD: 12.99, defaultCycle: "yearly"),
]
