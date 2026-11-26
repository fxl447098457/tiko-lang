# makeseed.py -- writes orderdb/seed.tiko: the sample data the program puts into a new database.
#   python tools/makeseed.py
# Deterministic (a fixed random seed), so running it again gives the same file. Every name is
# made up: no real company or person.
import random, os

rnd = random.Random(20261124)

customers = [
    # company, contact, city, country
    ("Alder & Finch Outfitters", "Mara Quill", "Portland", "USA"),
    ("Bluewater Provisions", "Theo Marsh", "Halifax", "Canada"),
    ("Copperleaf Trading Co.", "Ines Varga", "Melbourne", "Australia"),
    ("Driftwood Mercantile", "Jonah Pike", "Galway", "Ireland"),
    ("Ember Lane Foods", "Priya Nandakumar", "Leicester", "UK"),
    ("Fernhill Grocers", "Callum Reid", "Dunedin", "New Zealand"),
    ("Granite Peak Supply", "Rosa Delgado", "Denver", "USA"),
    ("Harbourlight Deli", "Sven Aalto", "Turku", "Finland"),
    ("Ironbark Kitchens", "Leah Moreau", "Brisbane", "Australia"),
    ("Juniper Street Market", "Omar Haddad", "Montreal", "Canada"),
    ("Kestrel Fine Foods", "Anika Brandt", "Hamburg", "Germany"),
    ("Lanternfish Bistro", "Paolo Ricci", "Genoa", "Italy"),
    ("Millbrook Pantry", "Hannah Ostrowski", "Kraków", "Poland"),
    ("Northfield Hollow Co-op", "Elias Berg", "Bergen", "Norway"),
    ("Oakridge Larder", "Grace Mbeki", "Cape Town", "South Africa"),
    ("Pebble Creek Café", "Lucas Ferreira", "Porto", "Portugal"),
    ("Quayside Cheese Shop", "Nora Lindqvist", "Gothenburg", "Sweden"),
    ("Riverbend Roasters", "Diego Santos", "Valencia", "Spain"),
    ("Saltmarsh Seafood", "Freya Jensen", "Aarhus", "Denmark"),
    ("Thistledown Teas", "Ewan MacLeod", "Inverness", "UK"),
    ("Upland Orchard Store", "Mei Tanaka", "Nagano", "Japan"),
    ("Valemont Patisserie", "Claire Dubois", "Lyon", "France"),
    ("Willowmere Wholefoods", "Ben Okafor", "Wellington", "New Zealand"),
    ("Yarrow & Sage Apothecary", "Lena Novak", "Ljubljana", "Slovenia"),
    ("Zephyr Hill Vineyards", "Marco Bianchi", "Mendoza", "Argentina"),
]
tiers = ["Standard", "Standard", "Silver", "Silver", "Gold", "Platinum"]

products = [
    # name, category, price
    ("Arabica Coffee Beans 1 kg", "Beverages", 24.50),
    ("Earl Grey Tea 250 g", "Beverages", 9.75),
    ("Sparkling Apple Juice 6-pack", "Beverages", 14.20),
    ("Aged Cheddar 500 g", "Dairy", 12.40),
    ("Cultured Butter 250 g", "Dairy", 6.90),
    ("Smoked Salmon 200 g", "Seafood", 18.60),
    ("Anchovies in Olive Oil", "Seafood", 7.30),
    ("Sourdough Starter Kit", "Bakery", 15.00),
    ("Rye Crispbread", "Bakery", 4.85),
    ("Wildflower Honey 500 g", "Pantry", 11.25),
    ("Extra Virgin Olive Oil 1 L", "Pantry", 19.90),
    ("Sea Salt Flakes", "Pantry", 5.60),
    ("Dark Chocolate 70%", "Confections", 3.95),
    ("Salted Caramels", "Confections", 8.40),
    ("Dried Apricots 1 kg", "Produce", 13.10),
    ("Heirloom Tomato Passata", "Produce", 4.20),
]

statuses = ["Open", "Shipped", "Delivered", "Delivered", "Delivered", "Cancelled"]

def q(s):
    return "'" + s.replace("'", "''") + "'"

def date(y, m, d):
    return "%04d-%02d-%02d" % (y, m, d)

sql = []
for i, (co, contact, city, country) in enumerate(customers, 1):
    first = contact.split()[0].lower()
    dom = "".join(ch for ch in co.lower() if ch.isalnum())[:14]
    email = "%s@%s.example" % (first, dom)
    phone = "+%d %03d %04d" % (rnd.randint(1, 99), rnd.randint(100, 999), rnd.randint(0, 9999))
    tier = rnd.choice(tiers)
    active = 0 if i in (6, 17) else 1
    credit = {"Standard": 2500, "Silver": 5000, "Gold": 10000, "Platinum": 25000}[tier]
    since = date(rnd.randint(2015, 2024), rnd.randint(1, 12), rnd.randint(1, 28))
    rating = rnd.choice([2, 3, 3, 4, 4, 4, 5, 5])
    notes = rnd.choice(["", "", "Prefers delivery before 10 am.", "Invoices by email only.",
                        "Seasonal buyer: busiest in December.", "Ask for the loading dock at the back."])
    sql.append("insert into customer( id, company, contact, email, phone, city, country, tier, active, "
               "credit_limit, since, rating, notes ) values( %d, %s, %s, %s, %s, %s, %s, %s, %d, %d, %s, %d, %s );"
               % (i, q(co), q(contact), q(email), q(phone), q(city), q(country), q(tier), active, credit,
                  q(since), rating, q(notes)))

for i, (name, cat, price) in enumerate(products, 1):
    sql.append("insert into product( id, name, category, price ) values( %d, %s, %s, %.2f );" % (i, q(name), q(cat), price))

line_id = 0
for oid in range(1, 101):
    cust = rnd.randint(1, len(customers))
    # the orders in date order, 2025-01 to 2026-11
    day = int((oid - 1) * 690 / 100) + rnd.randint(0, 5)
    y, rem = 2025, day
    mdays = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
    m = 1
    while rem >= mdays[m - 1]:
        rem -= mdays[m - 1]
        m += 1
        if m > 12:
            m, y = 1, y + 1
    d = rem + 1
    status = "Open" if oid > 92 else rnd.choice(statuses)
    shipped = 1 if status in ("Shipped", "Delivered") else 0
    picks = rnd.sample(range(1, len(products) + 1), rnd.randint(1, 4))
    total = 0.0
    lines = []
    for p in picks:
        qty = rnd.choice([1, 2, 2, 3, 4, 5, 6, 10, 12])
        price = products[p - 1][2]
        total += qty * price
        line_id += 1
        lines.append("insert into order_line( id, order_id, product_id, qty, unit_price ) values( %d, %d, %d, %d, %.2f );"
                     % (line_id, oid, p, qty, price))
    note = rnd.choice(["", "", "", "Gift wrap", "Leave with reception", "Urgent"])
    sql.append("insert into orders( id, customer_id, order_date, status, shipped, total, notes ) values( %d, %d, %s, %s, %d, %.2f, %s );"
               % (oid, cust, q(date(y, m, d)), q(status), shipped, round(total, 2), q(note)))
    sql.extend(lines)

out = []
out.append("' GENERATED by tools/makeseed.py: the sample data a new database starts with. Do not edit;")
out.append("' change makeseed.py and run it again (python tools/makeseed.py).")
out.append("'")
out.append("' %d customers, %d products, 100 orders, %d order lines. Every name is made up." % (len(customers), len(products), line_id))
out.append('#module "orderdb"')
out.append("")
out.append("' The INSERTs, one statement per line, run in one transaction by OpenData.")
out.append("function SeedSql( ) as ustring")
out.append("    dim as ustring s")
for st in sql:
    out.append('    s &= "' + st.replace('"', '""') + '" & wchr( 10 )')
out.append("    return s")
out.append("end function")
out.append("")
here = os.path.dirname(os.path.abspath(__file__))
path = os.path.join(here, "..", "orderdb", "seed.tiko")
with open(path, "w", encoding="utf-8", newline="\n") as f:
    f.write("\n".join(out))
print("wrote", os.path.normpath(path), len(sql), "statements")
