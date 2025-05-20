# Load packages
if (!require("pacman")) install.packages("pacman")
pacman::p_load(tidyverse, sf, igraph, tidygraph, ggraph, ggplot2,
               ggspatial, rnaturalearth, rnaturalearthdata, maps, ggrepel, RColorBrewer)

# ---- Set File Paths ----
base_dir <- "E:/All Project/R Project"
bangladesh_shp_path <- file.path(base_dir, "Shapefile/Bangladesh/bgd_admbnda_adm1_bbs_20201113.shp")
world_shp_path <- file.path(base_dir, "Shapefile/World/world-administrative-boundaries.shp")
airport_file <- file.path(base_dir, "Data/airports.dat")
routes_file <- file.path(base_dir, "Data/routes.dat")
output_path <- file.path(base_dir, "Shapefile/Output/bangladesh_international_flight_network.png")

# ---- Load Shapefiles ----
bangladesh <- st_read(bangladesh_shp_path) %>% st_transform(4326)
world <- st_read(world_shp_path) %>% st_transform(4326)

# ---- Load Airport Data ----
airport_url <- "https://raw.githubusercontent.com/jpatokal/openflights/master/data/airports.dat"
if (!file.exists(airport_file)) download.file(airport_url, airport_file, mode = "wb")
airport <- read.csv(airport_file, header = FALSE)
colnames(airport)[1:14] <- c("ID", "Name", "City", "Country", "IATA", "ICAO",
                             "Latitude", "Longitude", "Altitude", "Timezone",
                             "DST", "Tz", "Type", "Source")

# Filter Bangladesh airports
ind_airport <- airport %>% filter(Country == "Bangladesh", IATA != "\\N")
ind_iata <- ind_airport$IATA

# ---- Load Route Data ----
routes_url <- "https://raw.githubusercontent.com/jpatokal/openflights/master/data/routes.dat"
if (!file.exists(routes_file)) download.file(routes_url, routes_file, mode = "wb")
routes <- read.csv(routes_file, header = FALSE)
colnames(routes) <- c("Airline", "Airline_ID", "Source_Airport", "Source_ID",
                      "Destination_Airport", "Destination_ID", "Codeshare", "Stops", "Equipment")

# Filter international routes from Bangladesh
ind_flights <- routes %>%
  filter((Source_Airport %in% ind_iata & !Destination_Airport %in% ind_iata)) %>%
  distinct(Source_Airport, Destination_Airport)

# ---- Prepare Nodes and Edges ----
all_iatas <- unique(c(ind_flights$Source_Airport, ind_flights$Destination_Airport))
vertices <- airport %>%
  filter(IATA %in% all_iatas) %>%
  mutate(lon = Longitude, lat = Latitude)

# Add color by Bangladeshi origin airport
airport_colors <- RColorBrewer::brewer.pal(n = min(8, nrow(ind_airport)), name = "Set2")
ind_airport <- ind_airport %>%
  mutate(color = airport_colors[as.numeric(factor(IATA))])

edges <- ind_flights %>%
  left_join(ind_airport[, c("IATA", "color")], by = c("Source_Airport" = "IATA")) %>%
  rename(origin = Source_Airport, dest = Destination_Airport)

# ---- Build Graph ----
graph <- tbl_graph(nodes = vertices, edges = edges, node_key = "IATA")

# ---- Filter World Data to Connected Countries Only ----
connected_countries <- unique(left_join(edges, vertices, by = c("dest" = "IATA"))$Country)
filtered_world <- world %>% filter(name %in% connected_countries | name == "Bangladesh")

# ---- Dynamic Zoom with Extra 2° Margin ----
airport_points <- st_as_sf(vertices, coords = c("lon", "lat"), crs = 4326)
combined_geometry <- st_union(c(st_geometry(bangladesh), st_geometry(airport_points)))
zoom_bbox <- st_buffer(combined_geometry, dist = 42)  # Original 30 + 2°
bbox <- st_bbox(zoom_bbox)

x_buffer_left   <- 5  # Increase this to show more to the west (e.g., beyond UK)
x_buffer_right  <- 5  # Increase to show more of East Asia
y_buffer_bottom <- 5  # More south (e.g., Indian Ocean)
y_buffer_top    <- 5  # More north (e.g., Russia/Central Asia)

xlim <- c(bbox["xmin"] - x_buffer_left, bbox["xmax"] + x_buffer_right)
ylim <- c(bbox["ymin"] - y_buffer_bottom, bbox["ymax"] + y_buffer_top)


# ---- Plotting ----
flight_map <- ggraph(graph, layout = "manual", x = vertices$lon, y = vertices$lat) +
  
  # Filtered world map
  geom_sf(data = filtered_world, fill = "#232120", color = "NA", linewidth = 0.3, inherit.aes = FALSE) +
  
  # Bangladesh boundary
  geom_sf(data = bangladesh, fill = NA, color = "#575250", linewidth = 0.5, inherit.aes = FALSE) +
  
  # Flight paths: colored per origin airport
  geom_edge_arc(aes(color = color),
                width = 0.3, alpha = 0.7, strength = 0.2,
                arrow = arrow(length = unit(0.1, "cm")),
                show.legend = FALSE) +
  
  
  
  # All destination airports
  geom_node_point(color = "darkgreen", size = 1.5, alpha = 0.8) +
  
  # Highlighted Bangladesh airports (reduced size 20%)
  geom_point(data = ind_airport,
             aes(x = Longitude, y = Latitude),
             color = "green", size = 0.5, alpha = 0.95, inherit.aes = FALSE) +
  
  # Airport labels with bold text and dark halo
  geom_text_repel(
    data = left_join(edges, vertices, by = c("dest" = "IATA")) %>%
      distinct(dest, City, Country, lon, lat),
    aes(x = lon, y = lat, label = paste0(Country)),
    color = "#A0C878", size = 2.5, fontface = "bold",
    segment.color = NA, direction = "both", force = 0.5, max.overlaps = 20,
    bg.color = "#1a1a1a", bg.r = 0.15
  ) +
  
  # Scale and North arrow
  annotation_scale(location = "bl", width_hint = 0.15, text_cex = 0.6, line_col = "white", text_col = "white") +
  annotation_north_arrow(location = "tr", style = north_arrow_fancy_orienteering(fill = c("white", "white")),
                         height = unit(0.8, "cm"), width = unit(0.8, "cm")) +
  
  # Zoom bounds
  coord_sf(xlim = xlim, ylim = ylim, crs = st_crs(4326)) +
  
  
  # Title and theme
  ggtitle("International Flight Network of Bangladesh") +
  theme_void() +
  theme(
    plot.title = element_text(hjust = 0.5, color = "white", size = 16, face = "bold"),
    panel.background = element_rect(fill = "#1a1a1a"),
    plot.background = element_rect(fill = "#1a1a1a"),
    plot.margin = margin(5, 5, 5, 5, "mm")
  )

# ---- Save Output ----
ggsave(output_path, plot = flight_map,
       width = 11.7, height = 8.3,
       dpi = 600, bg = "#1a1a1a", limitsize = FALSE)
