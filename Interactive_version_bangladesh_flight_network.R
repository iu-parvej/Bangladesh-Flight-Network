# ---- Load Packages ----
if (!require("pacman")) install.packages("pacman")
pacman::p_load(tidyverse, sf, leaflet, htmltools, htmlwidgets, viridis, geosphere)

# ---- Set File Paths ----
base_dir <- "E:/All Project/R Project"
bangladesh_shp_path <- file.path(base_dir, "Shapefile/Bangladesh/bgd_admbnda_adm1_bbs_20201113.shp")
airport_file <- file.path(base_dir, "Data/airports.dat")
routes_file <- file.path(base_dir, "Data/routes.dat")
output_html <- file.path(base_dir, "Shapefile/Output/bangladesh_flight_network_hover_final.html")

# ---- Load and Prepare Data ----
bangladesh <- st_read(bangladesh_shp_path) %>% st_transform(4326)
airport <- read.csv(airport_file, header = FALSE)
colnames(airport)[1:14] <- c("ID", "Name", "City", "Country", "IATA", "ICAO",
                             "Latitude", "Longitude", "Altitude", "Timezone",
                             "DST", "Tz", "Type", "Source")

bd_airports <- airport %>% filter(Country == "Bangladesh", IATA != "\\N") %>% distinct(IATA, .keep_all = TRUE)
routes <- read.csv(routes_file, header = FALSE)
colnames(routes) <- c("Airline", "Airline_ID", "Source_Airport", "Source_ID",
                      "Destination_Airport", "Destination_ID", "Codeshare", "Stops", "Equipment")

intl_routes <- routes %>%
  filter(Source_Airport %in% bd_airports$IATA,
         !Destination_Airport %in% bd_airports$IATA,
         Stops == "0") %>%
  distinct(Source_Airport, Destination_Airport, .keep_all = TRUE)

dest_airports <- airport %>% filter(IATA %in% intl_routes$Destination_Airport)
bd_airports_with_flights <- bd_airports %>% filter(IATA %in% intl_routes$Source_Airport)

# ---- Create Curved Lines ----
create_curve_safe <- function(origin_lon, origin_lat, dest_lon, dest_lat) {
  tryCatch({
    coords <- gcIntermediate(
      c(origin_lon, origin_lat),
      c(dest_lon, dest_lat),
      n = 50, addStartEnd = TRUE, breakAtDateLine = TRUE
    )
    if (!is.null(coords)) st_linestring(coords) else NULL
  }, error = function(e) NULL)
}

flight_lines <- intl_routes %>%
  left_join(bd_airports, by = c("Source_Airport" = "IATA")) %>%
  left_join(dest_airports, by = c("Destination_Airport" = "IATA")) %>%
  mutate(
    flight_geom = pmap(list(Longitude.x, Latitude.x, Longitude.y, Latitude.y), create_curve_safe),
    geom_valid = map_lgl(flight_geom, Negate(is.null))
  ) %>%
  filter(geom_valid)

flight_lines_sf <- st_sf(flight_lines, geometry = flight_lines$flight_geom, crs = 4326)
flight_lines_sf$id <- paste0("line", seq_len(nrow(flight_lines_sf)))

# ---- Color Palette ----
bd_pal <- colorFactor(viridis(6), domain = bd_airports_with_flights$IATA)

# ---- Build Leaflet Map ----
m <- leaflet(options = leafletOptions(minZoom = 3, maxZoom = 8)) %>%
  addProviderTiles(providers$CartoDB.DarkMatter, group = "Dark") %>%
  addProviderTiles(providers$Esri.WorldImagery, group = "Satellite") %>%
  
  addPolygons(
    data = bangladesh,
    color = "#4ecdc4", weight = 1,
    fillColor = "#1a1a1a", fillOpacity = 0.3,
    group = "Bangladesh", popup = "Bangladesh"
  ) %>%
  
  # Invisible wider lines under flight lines to increase hover area
  addPolylines(
    data = flight_lines_sf,
    color = "transparent",
    weight = 15,
    opacity = 0,
    group = "Flights Hover",
    layerId = ~paste0("hover_", id)
  ) %>%
  
  # Flight lines visible, dashed style and layerId
  addPolylines(
    data = flight_lines_sf,
    color = ~bd_pal(Source_Airport),
    weight = 2,
    opacity = 0.8,
    dashArray = "5, 3",
    group = "Flights",
    layerId = ~id,
    popup = ~paste0(
      "<b>Route:</b> ", Source_Airport, " → ", Destination_Airport, "<br>",
      "<b>From:</b> ", Name.x, " (", City.x, ")<br>",
      "<b>To:</b> ", Name.y, " (", City.y, ", ", Country.y, ")"
    )
  ) %>%
  
  # Bangladesh airports with radius increased, but use bindTooltip for hover labels (sticky + no flicker)
  addCircleMarkers(
    data = bd_airports_with_flights,
    lng = ~Longitude, lat = ~Latitude,
    radius = 8,
    color = ~bd_pal(IATA), fillColor = ~bd_pal(IATA), fillOpacity = 1,
    popup = ~paste0("<b>", Name, "</b><br>", City),
    group = "Bangladesh Airports",
    layerId = ~IATA
  ) %>%
  addCircleMarkers(
    data = bd_airports_with_flights,
    lng = ~Longitude, lat = ~Latitude,
    radius = 8,
    color = "transparent", fillOpacity = 0, # invisible layer for hover tooltip
    label = ~paste0(Name, " (", City, ")"),
    labelOptions = labelOptions(
      direction = "top",
      style = list("color" = "white", "background" = "black", "padding" = "3px"),
      textsize = "12px",
      sticky = TRUE,
      opacity = 0.9
    ),
    group = "Bangladesh Airports Hover"
  ) %>%
  
  # Destination airports same approach
  addCircleMarkers(
    data = dest_airports,
    lng = ~Longitude, lat = ~Latitude,
    radius = 7,
    color = "#ff7f00", fillColor = "#ff7f00", fillOpacity = 0.8,
    popup = ~paste0("<b>", Name, "</b><br>", City, ", ", Country),
    group = "Destinations",
    layerId = ~IATA
  ) %>%
  addCircleMarkers(
    data = dest_airports,
    lng = ~Longitude, lat = ~Latitude,
    radius = 7,
    color = "transparent", fillOpacity = 0,
    label = ~paste0(Name, " (", City, ")"),
    labelOptions = labelOptions(
      direction = "top",
      style = list("color" = "white", "background" = "black", "padding" = "3px"),
      textsize = "12px",
      sticky = TRUE,
      opacity = 0.9
    ),
    group = "Destinations Hover"
  ) %>%
  
  # Layers and controls (include hover label groups)
  addLayersControl(
    baseGroups = c("Dark", "Satellite"),
    overlayGroups = c("Bangladesh", "Flights", "Flights Hover", "Bangladesh Airports", "Bangladesh Airports Hover", "Destinations", "Destinations Hover"),
    options = layersControlOptions(collapsed = FALSE)
  ) %>%
  
  addScaleBar(position = "bottomleft") %>%
  
  # Title at top center - bold single line
  addControl(
    html = HTML("
      <div style='text-align:center; font-weight: bold;
                  font-size: 18px; color: white; padding: 6px;
                  background: rgba(0,0,0,0.7); border-radius: 5px;'>
        Bangladesh International Flight Network
      </div>
    "),
    position = 'topleft'
  ) %>%
  
  # Legend for BD airports with full names
  addLegend(
    position = "bottomright",
    colors = bd_pal(bd_airports_with_flights$IATA),
    labels = bd_airports_with_flights$Name,
    title = "Bangladeshi Airports (Source)",
    opacity = 1
  ) %>%
  
  # Add your embedded Flight Radar iframe at bottom left as a control
  addControl(
    html = HTML('
      <div style="width: 300px; height: 250px; border: 0px solid #444; border-radius: 0px; overflow: hidden;">
        <iframe
          src="https://www.airnavradar.com/?widget=1&z=7&hideAirportCard=true&hideAirportWeather=true&hideFlightCard=true&airport=DAC"
          width="300" height="250" frameborder="0" scrolling="no"
          style="display: block;">
        </iframe>
      </div>
    '),
    position = "bottomleft"
  ) %>%
  
  setView(lng = 90, lat = 23.5, zoom = 4)

# ---- Inject JavaScript for hover effects on flight lines ----
m <- htmlwidgets::onRender(m, "
function(el, x) {
  var map = this;

  // Store original styles for visible lines
  map.eachLayer(function(layer) {
    if(layer.options && layer.options.layerId && layer.options.layerId.startsWith('line')) {
      layer._originalStyle = {
        color: layer.options.color,
        weight: layer.options.weight,
        dashArray: layer.options.dashArray,
        opacity: layer.options.opacity
      };
    }
  });

  // Hover handlers for invisible wide lines
  map.eachLayer(function(layer) {
    if(layer.options && layer.options.layerId && layer.options.layerId.startsWith('hover_line')) {
      var lineId = layer.options.layerId.replace('hover_', '');

      var visibleLine = null;
      map.eachLayer(function(l) {
        if(l.options && l.options.layerId === lineId) {
          visibleLine = l;
        }
      });

      if(visibleLine) {
        layer.on('mouseover', function(e) {
          visibleLine.setStyle({
            color: 'deepskyblue',
            weight: 4,
            dashArray: '5,3',
            opacity: 1
          });
          visibleLine.openPopup();
        });
        layer.on('mouseout', function(e) {
          var orig = visibleLine._originalStyle;
          visibleLine.setStyle({
            color: orig.color,
            weight: orig.weight,
            dashArray: orig.dashArray,
            opacity: orig.opacity
          });
          visibleLine.closePopup();
        });
      }
    }
  });
}
")

# ---- Save & View Map ----
htmlwidgets::saveWidget(
  widget = m,
  file = output_html,
  selfcontained = TRUE,
  title = "Bangladesh International Flights",
  background = "black"
)

browseURL(output_html)
