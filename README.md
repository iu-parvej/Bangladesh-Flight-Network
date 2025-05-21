
# Bangladesh International Flight Network

This R project visualizes the international flight routes from Bangladesh using OpenFlights data and shapefiles for geographic context.

## 🔗 Useful Links

- [Go to Live Interaction Map](https://parvej.me/bdflight/)
- [Full R Code](https://github.com/iu-parvej/Bangladesh-Flight-Network/blob/main/Interactive_version_bangladesh_flight_network.R)

## 📌Features

- Visualizes international routes departing from Bangladeshi airports
- Spatial network representation using `ggraph` and `sf`
- Interactive labeling and customized layout
- Aesthetic dark-themed output image


# How to Build an Interactive Bangladesh Flight Network Map with Embedded Flight Radar


### 1️⃣ Set Up Your Environment
Install R and RStudio (if not already installed).  
Install required packages using the following command:

```r
install.packages(c("tidyverse", "sf", "leaflet", "htmltools", 
                   "htmlwidgets", "viridis", "geosphere"))
```

### 2️⃣ Prepare Your Data
- **Download** the shapefile for Bangladesh's administrative boundaries.
- **Obtain** airport and route data (e.g., from OpenFlights: `airports.dat`, `routes.dat`).
- **Read** the shapefile using:

```r
sf::st_read("path/to/shapefile")
```

- **Load** airports and routes as CSVs:

```r
read.csv("airports.csv")
read.csv("routes.csv")
```

### 3️⃣ Filter and Clean Data
- **Filter airports** to only include Bangladesh (`Country == "Bangladesh"`).
- **Select** international routes departing from BD airports to destinations outside BD (no stops).
- **Join** airport data with routes for coordinates.

### 4️⃣ Create Curved Flight Lines
- Use `geosphere::gcIntermediate()` to create smooth curved paths:

```r
geosphere::gcIntermediate(c(lon1, lat1), c(lon2, lat2), n=50, addStartEnd=TRUE)
```

- Convert paths to spatial lines:

```r
sf::st_linestring(matrix(c(lon1, lat1, lon2, lat2), ncol=2))
```

### 5️⃣ Build Your Leaflet Map
- Initialize **Leaflet** with a preferred base map (e.g., *CartoDB.DarkMatter* or *Esri.WorldImagery*).
- Add **Bangladesh polygon** shapefile with a semi-transparent fill.
- Overlay **curved flight paths** with color-coded origins, dashed styles, and interactive popups.
- Add **airport markers** with hover tooltips.

### 6️⃣ Add Interactivity
Enhance user interaction with **JavaScript event handlers**:

```js
htmlwidgets::onRender("
  function(el,x) { 
    el.on('mouseover', function() {
      this.style.stroke = 'blue';
      this.style.strokeWidth = '2';
    });
  }
")
```

- Utilize `labelOptions(sticky = TRUE)` to prevent flickering hover labels.

### 7️⃣ Add Title & Legend
- Add a **bold title** at the top center:

```r
leaflet::addControl("<h2>Bangladesh International Flight Network</h2>", position = "topcenter")
```

- Include a **color-coded legend** for BD airports:

```r
leaflet::addLegend(position="bottomright", colors=colorVector, labels=airportNames)
```

### 8️⃣ Embed Live Flight Radar Map
Embed an iframe from a flight radar website:

```html
<iframe src="https://www.flightradar24.com/" width="350" height="270" style="border:2px solid black; border-radius:10px;"></iframe>
```

### 9️⃣ Save and Share
Save your project as a standalone HTML file:

```r
htmlwidgets::saveWidget(myLeafletMap, "BangladeshFlightNetwork.html")
```

### 🔟 Tips for Improvement
- Optimize **hover sensitivity** by adding invisible thicker lines under routes.
- Utilize **sticky labels** for airport names to enhance usability.
- Experiment with **colorFactor()** and `dashArray` for customized styles.
- Try **different Leaflet base maps** for unique presentations.
- Expand the dataset to explore **other airports or flight sources**.

---


## 📁 Project Structure

```text
.
├── data/               # Airport and route data
├── Shapefile/          # Bangladesh and world shapefiles
├── bangladesh_flight_network.R  # Main R script
├── README.md           # Project overview
├── .gitignore          # Files to ignore in Git
└── LICENSE             # License info


