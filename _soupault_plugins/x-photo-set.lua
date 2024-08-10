page_dir = Sys.dirname(page_file)
set_details_defs = {
    {key = "camera", prefix = "📷"},
    {key = "lens", prefix = "👓"},
    {key = "scope", prefix = "🔭"},
    {key = "bird", prefix = "🐦"},
}

function copy_original_photo(filename)
    local script_path = Sys.join_path(page_dir, "copy-original-photo.sh")
    local photo_path = Sys.join_path(page_dir, filename)
    if not Sys.file_exists(photo_path) then
        Log.debug("x-photo-set: copying " .. filename)
    end
    if Sys.run_program(String.join(" ", {
        "'" .. script_path .. "'",
        "'" .. filename .. "'",
        "'" .. page_dir .. "'",
    })) then
        return photo_path
    else
        Log.error("Failed to copy original photo for " .. filename)
    end
end

function get_original_photo_filename(id)
    local script_path = Sys.join_path(page_dir, "get-original-photo-filename.sh")
    local response_path = Sys.join_path(page_dir, id)
    if not Sys.file_exists(response_path) then
        Log.debug("x-photo-set: making cohost request for " .. id)
    end
    local result = Sys.get_program_output(String.join(" ", {
        "'" .. script_path .. "'",
        "'" .. id .. "'",
        "'" .. page_dir .. "'",
    }))
    if result then
        return String.trim(result)
    else
        Log.error("Failed to get original photo filename for " .. id)
    end
end

function get_photo_path(id)
    -- local location_path = Sys.join_path(page_dir, id .. ".location")
    -- local photo_url = String.trim(Sys.read_file(location_path))
    -- local photo_filename = Sys.basename_url(photo_url)
    local photo_filename = get_original_photo_filename(id)
    return copy_original_photo(photo_filename)
end

function get_exif_data(id, key)
    local path = get_photo_path(id)
    local result = Sys.read_file(path .. ".json")
    result = JSON.from_string(result)
    if result[1] then
        return result[1][key]
    end
end

function exiftool_timestamp_to_date(timestamp)
    local words = Regex.split(timestamp, " ")
    return Regex.replace_all(words[1], ":", "-")
end

function render_set_detail(dl, prefix, dd)
    local dt = HTML.create_element("dt", prefix)
    HTML.append_child(dl, dt)
    HTML.set_attribute(dd, "style", "list-style-type: '" .. prefix .. " ';")
    HTML.append_child(dl, dd)
end

local article = HTML.select_one(page, "article")
local toc = HTML.create_element("ul")
HTML.prepend_child(article, toc)

local x_photo_sets = HTML.select(article, "x-photo-set")
local meta = {}
local i = 1
while x_photo_sets[i] do
    local cohost_imgs = HTML.select(x_photo_sets[i], "cohost-img")
    meta[i] = {
        title = HTML.get_attribute(x_photo_sets[i], "title"),
    }

    -- We have: <x-photo-set> text <cohost-img/>... </x-photo-set>
    -- We want: <h2/> text <dl/> <cohost-img/>...

    -- 1. <x-photo-set> <h2/> text <cohost-img/>... <dl/> </x-photo-set>
    local h2 = HTML.create_element("h2", meta[i].title)
    HTML.set_attribute(h2, "id", meta[i].title)
    HTML.prepend_child(x_photo_sets[i], h2)
    local dl = HTML.create_element("dl")
    HTML.append_child(x_photo_sets[i], dl)

    -- Populate the table of contents
    local li = HTML.create_element("li")
    HTML.append_child(toc, li)
    local a = HTML.create_element("a", meta[i].title)
    HTML.set_attribute(a, "href", "#" .. meta[i].title)
    HTML.append_child(li, a)

    -- Populate the <dl> with set details
    local representative_set_details = {}
    if cohost_imgs[1] then
        local id = HTML.get_attribute(cohost_imgs[1], "id")
        local date = exiftool_timestamp_to_date(get_exif_data(id, "DateTimeOriginal"))
        representative_set_details = {
            {key = "date", prefix = "🗓️", value = date},
        }
        HTML.insert_before(a, HTML.create_text(date .. ", "))
    end
    local j = 1
    while representative_set_details[j] do
        local key = representative_set_details[j].key
        local prefix = representative_set_details[j].prefix
        local value = representative_set_details[j].value
        local dd = HTML.create_element("dd", value)
        render_set_detail(dl, prefix, dd)
        j = j + 1
    end
    local j = 1
    while set_details_defs[j] do
        local key = set_details_defs[j].key
        local prefix = set_details_defs[j].prefix
        local values = HTML.select(x_photo_sets[i], key)
        local k = 1
        while values[k] do
            HTML.set_tag_name(values[k], "dd")
            render_set_detail(dl, prefix, values[k])
            k = k + 1
        end
        j = j + 1
    end

    -- 2. <x-photo-set> <h2/> text <dl/> </x-photo-set> <figure/>...
    local j = 1
    while cohost_imgs[j] do
        local id = HTML.get_attribute(cohost_imgs[j], "id")
        -- local url = "https://cohost.org/rc/attachment-redirect/" .. id
        local url = Sys.basename_url(get_photo_path(id))
        local width = HTML.get_attribute(cohost_imgs[j], "width")
        local height = HTML.get_attribute(cohost_imgs[j], "height")

        local figure = HTML.create_element("figure")
        HTML.replace_element(cohost_imgs[j], figure)
        HTML.insert_after(x_photo_sets[i], figure)

        local figcaption = HTML.create_element("figcaption", String.join(", ", {
            "ISO " .. get_exif_data(id, "ISO"),
            "f/" .. get_exif_data(id, "Aperture"),
            get_exif_data(id, "ShutterSpeed"),
        }))
        HTML.append_child(figure, figcaption)

        local a = HTML.create_element("a")
        HTML.set_attribute(a, "target", "_blank")
        HTML.set_attribute(a, "href", url)
        HTML.append_child(figure, a)

        -- FIXME: soupault bug (PataphysicalSociety/soupault#66)
        local img = HTML.select_one(HTML.parse("<img>"), "*")
        HTML.set_attribute(img, "loading", "lazy")
        HTML.set_attribute(img, "src", url)
        if width then
            HTML.set_attribute(img, "width", width)
        end
        if height then
            HTML.set_attribute(img, "height", height)
        end
        HTML.append_child(a, img)

        j = j + 1
    end

    -- 3. <h2/> text <dl/> <figure/>...
    HTML.unwrap(x_photo_sets[i])
    i = i + 1
end
