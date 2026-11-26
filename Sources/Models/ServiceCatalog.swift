import Foundation

struct ServiceCatalogItem: Identifiable {
    let id = UUID()
    let name: String
    let iconName: String
    let defaultPriceTRY: Double
    let defaultPriceUSD: Double
    let defaultCycle: String   // "monthly" or "yearly"
}

let serviceCatalog: [ServiceCatalogItem] = [
    ServiceCatalogItem(name: "Netflix",              iconName: "film",                defaultPriceTRY: 229,  defaultPriceUSD: 15.49, defaultCycle: "monthly"),
    ServiceCatalogItem(name: "Spotify",              iconName: "music.note",          defaultPriceTRY: 59,   defaultPriceUSD: 10.99, defaultCycle: "monthly"),
    ServiceCatalogItem(name: "YouTube Premium",      iconName: "play.rectangle",      defaultPriceTRY: 79.99,defaultPriceUSD: 13.99, defaultCycle: "monthly"),
    ServiceCatalogItem(name: "iCloud+",              iconName: "icloud",              defaultPriceTRY: 39.99,defaultPriceUSD: 2.99,  defaultCycle: "monthly"),
    ServiceCatalogItem(name: "Apple Music",          iconName: "headphones",          defaultPriceTRY: 39.99,defaultPriceUSD: 10.99, defaultCycle: "monthly"),
    ServiceCatalogItem(name: "Amazon Prime",         iconName: "shippingbox",         defaultPriceTRY: 39,   defaultPriceUSD: 14.99, defaultCycle: "monthly"),
    ServiceCatalogItem(name: "ChatGPT Plus",         iconName: "sparkles",            defaultPriceTRY: 679,  defaultPriceUSD: 20,    defaultCycle: "monthly"),
    ServiceCatalogItem(name: "Disney+",              iconName: "star",                defaultPriceTRY: 149,  defaultPriceUSD: 13.99, defaultCycle: "monthly"),
    ServiceCatalogItem(name: "BluTV",                iconName: "tv",                  defaultPriceTRY: 84.99,defaultPriceUSD: 7.99,  defaultCycle: "monthly"),
    ServiceCatalogItem(name: "Max",                  iconName: "tv",                  defaultPriceTRY: 149,  defaultPriceUSD: 15.99, defaultCycle: "monthly"),
    ServiceCatalogItem(name: "Exxen",                iconName: "play.circle",         defaultPriceTRY: 149.90,defaultPriceUSD: 9.99, defaultCycle: "monthly"),
    ServiceCatalogItem(name: "Xbox Game Pass",       iconName: "gamecontroller",      defaultPriceTRY: 339,  defaultPriceUSD: 17.99, defaultCycle: "monthly"),
    ServiceCatalogItem(name: "PlayStation Plus",     iconName: "gamecontroller.fill",  defaultPriceTRY: 440,  defaultPriceUSD: 17.99, defaultCycle: "monthly"),
    ServiceCatalogItem(name: "Adobe Creative Cloud", iconName: "paintbrush",          defaultPriceTRY: 1200, defaultPriceUSD: 59.99, defaultCycle: "monthly"),
    ServiceCatalogItem(name: "Canva Pro",            iconName: "wand.and.stars",      defaultPriceTRY: 529,  defaultPriceUSD: 12.99, defaultCycle: "monthly"),
    ServiceCatalogItem(name: "Duolingo Super",       iconName: "book",                defaultPriceTRY: 519,  defaultPriceUSD: 12.99, defaultCycle: "yearly"),
]
