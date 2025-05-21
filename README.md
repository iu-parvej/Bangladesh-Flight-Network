# Bangladesh International Flight Network

This R project visualizes the international flight routes from Bangladesh using OpenFlights data and shapefiles for geographic context.

## 📌 Features

- Visualizes international routes departing from Bangladeshi airports
- Spatial network representation using `ggraph` and `sf`
- Interactive labeling and customized layout
- Aesthetic dark-themed output image

## 📁 Project Structure

```text
.
├── data/               # Airport and route data
├── Shapefile/          # Bangladesh and world shapefiles
├── bangladesh_flight_network.R  # Main R script
├── README.md           # Project overview
├── .gitignore          # Files to ignore in Git
└── LICENSE             # License info

How to Build an Interactive Bangladesh Flight Network Map with Embedded Flight Radar

1. Set Up Your Environment
Install R and RStudio (if not installed).
Install needed packages by running:

install.packages(c("tidyverse", "sf", "leaflet", "htmltools", "htmlwidgets", "viridis", "geosphere"))

2. Prepare Your Data
Download the shapefile for Bangladesh administrative boundaries.
Download airport and route data (e.g., from OpenFlights: airports.dat, routes.dat).
Read shapefile with sf::st_read().
Load airports and routes as CSV using read.csv().

3. Filter and Clean Data
Filter airports for Bangladesh only (Country == "Bangladesh").
Select international routes starting from BD airports and going to airports outside BD with no stops.
Join the airport info to the routes for coordinates.

4. Create Curved Flight Lines
Use geosphere::gcIntermediate() to create smooth curved paths between the origin and destination airports.
Convert these to SF spatial lines (st_linestring).

5. Build Your Leaflet Map
Initialize leaflet with desired base maps (e.g., CartoDB.DarkMatter, Esri.WorldImagery).
Add the Bangladesh polygon shapefile with a semi-transparent fill.
Add curved flight lines with color coding by source airport, dashed lines, and pop-up info.
Add airport points (circles) with hover tooltips using sticky labels.
Use invisible, thicker lines under flight routes to improve hover sensitivity.

6. Add Interactivity
Add JavaScript event handlers via htmlwidgets::onRender() to:
Highlight flight lines on hover with a thicker blue dashed style.
Show/hide popups smoothly.
Use sticky labelOptions(sticky = TRUE) on airports to avoid flickering hover popups.

7. Add Title and Legend
Use leaflet::addControl() to add a bold title at the top center.
Use leaflet::addLegend() to show color-coded BD airports with full names.

8. Embed Live Flight Radar Map
Embed an iframe from a flight radar website (like AirNavRadar) in a Leaflet control at the bottom left.
Resize iframe (e.g., 350x270 px) to fit nicely inside the map.
Style iframe container with border and rounded corners.

9. Save and Share
Save your map as a self-contained HTML file using htmlwidgets::saveWidget().
Open in any browser to explore and share.

10. Tips for Improvement
Adjust hover sensitivity by adding invisible, thicker lines under routes.
You can use sticky labels to smooth the airport name hover.
Customize colors and line styles with colorFactor() and dashArray.

Explore more Leaflet providers for different map styles.
You can just experiment with other airports or flight data sources.
