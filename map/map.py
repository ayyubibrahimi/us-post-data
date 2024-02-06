import pandas as pd
from PIL import Image, ImageDraw, ImageEnhance
import os

FL_LOC_TOP_LEFT = (-88, 31.0)
FL_LOC_BOTTOM_RIGHT = (-80, 24.5)
MAP_LINE_COLOR = "blue"
NODE_HIGHLIGHT_COLOR = "orange"

df = pd.read_csv(
    "data/fl-post-limited.csv", parse_dates=["employ_start_date", "separation_date"]
)

department_locations = (
    df.groupby("agcy_name")
    .agg({"latitude": "first", "longitude": "first"})
    .to_dict(orient="index")
)

department_movements = {name: 0 for name in department_locations}


def lat_lon_to_pixels(lat, lon, width, height):
    # Map boundaries
    delta_x = FL_LOC_BOTTOM_RIGHT[0] - FL_LOC_TOP_LEFT[0]
    delta_y = FL_LOC_TOP_LEFT[1] - FL_LOC_BOTTOM_RIGHT[1]
    # Pixel conversion
    x_pix = (lon - FL_LOC_TOP_LEFT[0]) * width / delta_x
    y_pix = (FL_LOC_TOP_LEFT[1] - lat) * height / delta_y
    return int(x_pix), int(y_pix)


def draw_line(draw, start_pos, end_pos, color):
    draw.line((start_pos, end_pos), fill=color, width=10)


base_map = Image.open("data/map.png").convert("RGBA")
draw = ImageDraw.Draw(base_map)


def draw_enhance_node(draw, position, intensity, color):
    # Increase the radius of the circle based on the intensity
    radius = 5 + intensity * 2
    # Draw the circle
    draw.ellipse(
        [
            (position[0] - radius, position[1] - radius),
            (position[0] + radius, position[1] + radius),
        ],
        fill=color,
        outline=color,
    )


# Sort movements by date
sorted_movements = df.sort_values("employ_start_date")

frame_file_paths = []

base_map_path = "data/map.png"

person_last_department = {}


for i, row in sorted_movements.iterrows():
    # Load the base map image
    base_map = Image.open(base_map_path).convert("RGBA")
    draw = ImageDraw.Draw(base_map)

    person_id = row["person_nbr"]
    current_department = row["agcy_name"]
    start_date = row["employ_start_date"]
    end_date = row["separation_date"]

    # If the person has moved, draw a line from their last known department to the new one
    if person_id in person_last_department and end_date:
        previous_department = person_last_department[person_id]["department"]
        previous_department_location = department_locations[previous_department]
        current_department_location = department_locations[current_department]

        # Get pixel positions for the start and end points
        start_pos = lat_lon_to_pixels(
            previous_department_location["latitude"],
            previous_department_location["longitude"],
            base_map.width,
            base_map.height,
        )
        end_pos = lat_lon_to_pixels(
            current_department_location["latitude"],
            current_department_location["longitude"],
            base_map.width,
            base_map.height,
        )

        draw_line(draw, start_pos, end_pos, MAP_LINE_COLOR)

    person_last_department[person_id] = {
        "department": current_department,
        "date": start_date,
    }

    # Update department movement count
    department_movements[current_department] += 1

    # Save the frame
    frame_file_path = f"data/frame_{i}.png"
    base_map.save(frame_file_path)
    frame_file_paths.append(frame_file_path)

    base_map.close()

frames = [Image.open(frame) for frame in frame_file_paths]
frames[0].save(
    "data/movement_animation.gif",
    format="GIF",
    append_images=frames[1:],
    save_all=True,
    duration=300,
    loop=0,
)

for frame_path in frame_file_paths:
    if os.path.exists(frame_path):
        os.remove(frame_path)
    else:
        print(f"Warning: The file {frame_path} does not exist and cannot be removed.")

animated_gif_path = "data/movement_animation.gif"
