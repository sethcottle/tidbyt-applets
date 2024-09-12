"""
Applet: On This Day
Summary: Historical Events
Description: See Events, Births, Deaths, or Holidays using Wikipedia's "On This Day" data.
Author: Seth Cottle
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

def main(config):
    category = config.get("category", "events")
    scroll_speed = int(config.get("scroll", "90"))  # Default to very slow scroll
    now = time.now()
    month = now.format("1")
    day = now.format("2")

    url = "https://api.wikimedia.org/feed/v1/wikipedia/en/onthisday/{}/{}/{}".format(category, month, day)
    headers = {"User-Agent": "TidbytApp/1.0"}

    response = http.get(url, headers = headers)

    if response.status_code != 200:
        return render.Root(
            child = render.Text("Error fetching data"),
        )

    data = json.decode(response.body())

    if category not in data or len(data[category]) == 0:
        return render.Root(
            child = render.Text("No {} found".format(category)),
        )

    items = data[category][:5]  # Get up to 5 items
    item_texts = []
    for item in items:
        if category == "holidays":
            item_texts.append(item["text"])
        else:
            item_texts.append("{}: {}".format(item["year"], item["text"]))

    # Join all texts with newline characters and add extra padding
    all_text = "\n\n".join(item_texts)
    padded_text = "\n\n" + all_text + "\n\n\n\n\n"

    return render.Root(
        child = render.Column(
            children = [
                render.Box(
                    height = 8,
                    color = "#fff",
                    child = render.Text("On This Day", font = "5x8", color = "#000"),
                ),
                render.Box(
                    height = 1,
                    color = "#ccc",
                ),
                render.Marquee(
                    height = 23,
                    scroll_direction = "vertical",
                    offset_start = 23,
                    offset_end = 32,
                    child = render.WrappedText(
                        content = padded_text,
                        width = 62,
                        align = "left",
                    ),
                ),
            ],
        ),
        delay = scroll_speed,
    )

def get_schema():
    categories = [
        schema.Option(display = "Events", value = "events"),
        schema.Option(display = "Births", value = "births"),
        schema.Option(display = "Deaths", value = "deaths"),
        schema.Option(display = "Holidays", value = "holidays"),
    ]

    scroll_speed_options = [
        schema.Option(display = "Very Slow", value = "90"),
        schema.Option(display = "Slow", value = "65"),
        schema.Option(display = "Medium", value = "45"),
        schema.Option(display = "Fast", value = "30"),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "category",
                name = "Category",
                desc = "Choose the category of historical events",
                icon = "list",
                default = "events",
                options = categories,
            ),
            schema.Dropdown(
                id = "scroll",
                name = "Scroll Speed",
                desc = "Choose the scrolling speed",
                icon = "stopwatch",
                default = scroll_speed_options[0].value,
                options = scroll_speed_options,
            ),
        ],
    )
