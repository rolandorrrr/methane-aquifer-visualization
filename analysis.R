# ============================================================================
# Final Project - Analysis of Oil Wells and Water Well Contamination
# This project explores the relationship between derelict oil wells and 
# water well contamination in the United States
# ============================================================================

# Chunk 1 - Setting Up Our Environment
# First, we need to load all the special R packages that give us extra tools:
# tidyverse: for data manipulation and visualization
# sf: for handling spatial (map) data
# nngeo: for analyzing nearest neighbors
# ggplot2: for creating beautiful plots
# tigris: for working with US geographic data
# viridis: for color palettes that are colorblind-friendly
library(tidyverse)
library(sf)
library(nngeo)
library(ggplot2)
library(tigris)
library(viridis)

# This line makes numbers display normally instead of scientific notation
# (e.g., 10000 instead of 1e+04)
options(scipen=999)

# Tell R where to find our project files
setwd("/Users/rolandojrrabines/Desktop/Final.Project")

# Import our datasets:
# DerelictOilWell: locations of abandoned oil wells
# WaterWell: locations of water wells
# ContaminationData: methane measurements from water wells
# allStates: map data for US states
DerelictOilWell <- read.csv("data/DerelictWell.csv")
WaterWell <- read.csv("data/CoordinateData.csv")
ContaminationData <- read.csv("data/McMahon_Methane_in_US_Aquifers_Table1.csv")
allStates<-st_read("data/ne_50m_admin_1_states_provinces.shp")

# Chunk 2 - Creating Maps
# First, let's make a basic map of all states
ggplot()+
  geom_sf(data=allStates)

# Create a new dataset with just the 50 US states (no territories)
# diss_me values 3513:3563 represent the 50 states
fiftyStates<-allStates %>% 
  filter(diss_me %in% c(3513:3563))

# Adjust Alaska and Hawaii's position on the map to make it look better
# This moves them below the continental US
fiftyStatesShifted<-shift_geometry(fiftyStates,position=c("below"))

# Plot our new, adjusted map
ggplot()+
  geom_sf(data=fiftyStatesShifted)

# Convert our well data into special spatial objects that R can plot on maps
# We use the longitude and latitude to place them
WaterWellData <- st_as_sf(WaterWell, coords = c("Adj_DD_Long", "Adj_DD_Lat"), crs = 4326)
OilWellData <- st_as_sf(DerelictOilWell, coords = c("Longitude", "Latitude"), crs = 4326)

# Chunk 3 - Creating a Combined Map of Wells
# Combine our water and oil well data into one dataset
# We add a 'Type' column to distinguish between them
combined_data1 <- bind_rows(
  WaterWellData %>% mutate(Type = "Water Well"),
  OilWellData %>% mutate(Type = "Oil Well")
)

# Convert the combined data into a spatial format
combined_data_sf <- st_as_sf(
  combined_data1,
  coords = c("X", "Y"),
  crs = 4326  # This is the standard coordinate system for GPS data
)

# Create a beautiful map showing both types of wells
ggplot() +
  # Draw the US map in the background
  geom_sf(data = fiftyStatesShifted, fill = "gray90", color = "gray50", alpha = 0.2, size = 0.3) +
  # Add points for each well, colored by type
  geom_sf(data = combined_data_sf, aes(color = Type), size = 0.5, alpha = 0.25) +
  
  # Make the map pretty with colors and labels
  scale_fill_viridis_d(option="viridis") +
  labs(
    color = "Well Type",
    title = "Spatial Distribution of Orphaned Oil Wells and Water Wells in the United States",
    x = "Longitude",
    y = "Latitude"
  ) +
  # Make the legend points bigger so they're easier to see
  guides(color = guide_legend(override.aes = list(size = 4))) +
  theme_classic() +
  coord_sf()

# Chunk 4 - Finding Nearby Wells
# Find water wells that are within 1000 meters (1km) of oil wells
Nearest <- st_nn(OilWellData, WaterWellData, maxdist = 1000, returnDist = TRUE) 

# Get the information about which wells are close to each other
nearest_WW_row <- unlist(Nearest$nn)
distances <- unlist(Nearest$dist)

# Create a dataset of just the water wells within 1km of oil wells
water_wells_within_1km <- WaterWellData[unique(nearest_WW_row), ]

# Chunk 5 - Combining Well and Contamination Data
# Add methane concentration data to our nearby water wells
water_wells_within_1km <- as.data.frame(st_coordinates(water_wells_within_1km)) %>%
  # Rename coordinates to match our original data
  rename(Adj_DD_Long = X, Adj_DD_Lat = Y) %>%
  # Join with water well IDs
  left_join(WaterWell %>% select(Well.id, Adj_DD_Long, Adj_DD_Lat), 
            by = c("Adj_DD_Long", "Adj_DD_Lat")) %>%
  # Add methane concentration data
  left_join(
    ContaminationData %>% select(NAWQA.ID, Methane) %>% rename(Well.id = NAWQA.ID),
    by = "Well.id")

# Make sure methane values are treated as numbers
water_wells_within_1km$Methane <- as.numeric(water_wells_within_1km$Methane)

# Chunk 6 - Visualizing and Describing Relationships
# Match coordinates to Well.id for filtered water wells
water_well_coords <- water_wells_within_1km %>%
  select(Well.id, Adj_DD_Long, Adj_DD_Lat)

# Join with contamination data to get methane values
combined_data <- water_well_coords %>%
  left_join(
    ContaminationData %>% select(NAWQA.ID, Methane) %>% rename(Well.id = NAWQA.ID),
    by = "Well.id"
  )

# Ensure Methane is numeric, replacing non-numeric entries with NA
combined_data$Methane <- as.numeric(combined_data$Methane)
combined_data$Methane[is.na(combined_data$Methane)] <- 0

# Verify that methane values are properly aligned
if (all(is.na(combined_data$Methane))) {
  stop("Methane values are all NA. Check data processing in earlier chunks.")
}

# Return the cleaned data for use in the next chunk
combined_data

# Chunk 7 - Visualization of Methane Concentration Distributions by Distance Range
# Prepare data for box plots
# Define distance ranges
max_distances <- c(5000, 10000, 25000)
distance_labels <- c("5KM", "10KM", "25KM")

# Extract distances and indices of nearest water wells
nearest <- st_nn(OilWellData, WaterWellData, maxdist = max(max_distances), returnDist = TRUE)
nearest_WW_row <- unlist(nearest$nn)
nearest_distances <- unlist(nearest$dist)

# Create a combined data frame for all distance ranges
combined_distance_data <- data.frame()

for (i in seq_along(max_distances)) {
  if (i == 1) {
    # "5KM": distances <= 5000
    filter_condition <- nearest_distances <= max_distances[i]
  } else {
    # Other ranges (e.g., "10KM", "25KM")
    filter_condition <- nearest_distances > max_distances[i - 1] & nearest_distances <= max_distances[i]
  }
  
  # Get water wells within the current range
  water_wells_within_dist <- WaterWellData[unique(nearest_WW_row[filter_condition]), ]
  
  # Add methane concentrations by matching coordinates
  filtered_data <- as.data.frame(st_coordinates(water_wells_within_dist)) %>%
    rename(Adj_DD_Long = X, Adj_DD_Lat = Y) %>%
    left_join(WaterWell %>% select(Well.id, Adj_DD_Long, Adj_DD_Lat), by = c("Adj_DD_Long", "Adj_DD_Lat")) %>%
    left_join(
      ContaminationData %>% select(NAWQA.ID, Methane) %>% rename(Well.id = NAWQA.ID),
      by = "Well.id"
    ) %>%
    filter(!is.na(Methane)) %>%
    mutate(
      Methane = as.numeric(Methane),  # Convert Methane to numeric
      DistanceRange = distance_labels[i]
    )
  
  # Combine data
  combined_distance_data <- bind_rows(combined_distance_data, filtered_data)
}

# Ensure DistanceRange is a factor with the correct order
combined_distance_data$DistanceRange <- factor(
  combined_distance_data$DistanceRange,
  levels = distance_labels
)

# Chunk 7: Revised Visualization
# Add jittered points
# Fill colors for box plot
# Colors for jittered points
# New Y-Scale to capture all of the box-and-whisker plots
ggplot(combined_distance_data, aes(x = DistanceRange, y = Methane, fill = DistanceRange)) +
  geom_boxplot() +  # Box plot with whiskers
  geom_jitter(aes(color = DistanceRange), width = 0.2, size = 1.5, alpha = 0.7) +  # Add jittered points
  scale_fill_brewer(palette = "Dark2", name = "Distance Range") +  # Darker fill colors for box plot
  scale_color_brewer(palette = "Dark2", name = "Distance Range") +  # Darker colors for jittered points
  labs(
    title = "Methane Concentration by Distance Range",
    x = "Distance Range",
    y = "Methane Concentration (mg/L)"
  ) +
  ylim(0.000000001, 30) +
  scale_y_log10() +
  theme_minimal()

# Chunk 8 - Correlation Analysis Between Methane Levels and Proximity
# Convert DistanceRange to a numeric variable for correlation analysis
combined_distance_data$DistanceRange_numeric <- as.numeric(as.factor(combined_distance_data$DistanceRange))

# Perform a Spearman rank correlation test
correlation_result <- cor.test(combined_distance_data$DistanceRange_numeric, combined_distance_data$Methane, method = "spearman")

# Print test results
print(correlation_result)

# Chunk 9 
# Visualization #3 
# Group 1: Water wells with oil wells within 5KM
nearest_5km <- st_nn(OilWellData, WaterWellData, maxdist = 5000, returnDist = TRUE)
nearest_5km_row <- unlist(nearest_5km$nn)

# Filter water wells within 5KM
water_wells_within_5km <- WaterWellData[unique(nearest_5km_row), ]

# Add methane concentrations
group_1 <- as.data.frame(st_coordinates(water_wells_within_5km)) %>%
  rename(Adj_DD_Long = X, Adj_DD_Lat = Y) %>%
  left_join(WaterWell %>% select(Well.id, Adj_DD_Long, Adj_DD_Lat), by = c("Adj_DD_Long", "Adj_DD_Lat")) %>%
  left_join(
    ContaminationData %>% select(NAWQA.ID, Methane) %>% rename(Well.id = NAWQA.ID),
    by = "Well.id"
  ) %>%
  filter(!is.na(Methane)) %>%
  mutate(Group = "Water Wells with Oil Well within 5KM")

# Group 2: Random sample of 100 water wells
set.seed(123)  # For reproducibility
group_2 <- WaterWell %>%
  sample_n(100) %>%
  left_join(
    ContaminationData %>% select(NAWQA.ID, Methane) %>% rename(Well.id = NAWQA.ID),
    by = "Well.id"
  ) %>%
  filter(!is.na(Methane)) %>%
  mutate(Group = "Random Sample")

# Combine groups
combined_data <- bind_rows(group_1, group_2)
# Ensure Methane is numeric
combined_data <- combined_data %>%
  mutate(Methane = as.numeric(Methane))

# Create box plot with adjusted y-axis
# Darker fill colors for box plot
# Highlight outliers
# Add jittered points
# Darker colors for jittered points
ggplot(combined_data, aes(x = Group, y = Methane, fill = Group)) +
  geom_boxplot() + 
  scale_color_viridis_d(option = "viridis") +
  labs(
    title = "Methane Comparison: Random Wells vs. Water Wells with Oil Well in 5KM",
    x = "Groups",
    y = "Methane Concentration (mg/L)"
  ) +
  scale_y_log10() +
  theme_minimal()

# Chunk 10
# Perform a Mann-Whitney U test
test_result <- wilcox.test(
  Methane ~ Group,
  data = combined_data,
  alternative = "greater"
)

# Print test results
print(test_result)

# Chunk 11
# Convert DistanceRange to a numeric variable for correlation analysis
combined_distance_data$DistanceRange_numeric <- as.numeric(as.factor(combined_distance_data$DistanceRange))

# Perform a Spearman rank correlation test
correlation_result <- cor.test(combined_distance_data$DistanceRange_numeric, combined_distance_data$Methane, method = "spearman")

# Print test results
print(correlation_result)

# Chunk 12
# Extract nearest indices and distances
nearest_indices <- unlist(Nearest$nn)  # Indices of nearest water wells
nearest_distances <- unlist(Nearest$dist)  # Distances to nearest water wells

# Map methane values to the nearest distances
# Use the indices to retrieve methane values for each matched water well
aligned_methane <- water_wells_within_1km$Methane[nearest_indices]

# Combine distances and methane concentrations into a single data frame
distance_methane_data <- data.frame(
  Distance = nearest_distances,
  Methane = aligned_methane
)

# Filter out missing or zero methane values
distance_methane_data <- distance_methane_data %>%
  filter(!is.na(Methane) & Methane > 0)