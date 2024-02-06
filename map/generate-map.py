import matplotlib.pyplot as plt
from mpl_toolkits.basemap import Basemap

# Define the boundaries of Florida (approximate)
llon = -87.6349  # lower left longitude
llat = 24.3963   # lower left latitude
ulon = -80.0314  # upper right longitude
ulat = 31.0000   # upper right latitude

## Create a figure and a Basemap instance centered on Florida with the specified color scheme
plt.figure(figsize=(8, 8))
m = Basemap(projection='merc', 
            llcrnrlat=24.5, urcrnrlat=31.0,  # latitudes of Florida with a slight margin
            llcrnrlon=-88, urcrnrlon=-80,  # longitudes of Florida with a slight margin
            resolution='i')

# Draw coastlines, map boundary, and fill continents with the colors black for land and white for water
m.drawcoastlines()
m.drawmapboundary(fill_color='black')
m.fillcontinents(color='grey', lake_color='black')

# Draw states and counties
m.drawstates()
m.drawcounties()

# Save the figure to a PNG file with the updated color scheme and centered view
florida_map_path = 'data/florida_map_custom.png'
plt.savefig(florida_map_path, bbox_inches='tight', dpi=300, facecolor='black')


# Close the figure
plt.close()