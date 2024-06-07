local get, fetch = get, fetch

-- Debug Helpers
local outputLabel, errorLabel = get("output"), get("error")
function log(msg)
	outputLabel.set_content(tostring(msg) .. "\n" .. outputLabel.get_content())
end

function warn(msg)
	errorLabel.set_content(tostring(msg) .. "\n" .. errorLabel.get_content())
end

-- Constants
local VERSION = "v1.1.2"
local API_URL = "https://webx-external-api.vercel.app/api/v1"
-- local API_URL = "http://127.0.0.1:5000/api/v1"

-- Init
get("version").set_content(VERSION)
log("Loaded")

-- Error Handling
xpcall(function()

-- Search box
local queryTextBox = get("query")

-- Get the search result cards
local cards = {}
do
	local cardHolders = get("card", true)

	local icons = get("card_icon", true)
	local names = get("card_sitename", true) -- name part of name.tld with added spaces between words
	local urls = get('card_url', true) -- Full buss:// url
	local titles = get("card_title", true) -- The text that is in the <title> tag on the site
	local descriptions = get("card_description", true) -- The description meta tag
	local scores = get("card_score", true) -- How well the site scores

	for i = 1, #cardHolders do
		cards[i] = {
			icon = icons[i],
			name = names[i],
			url = urls[i],
			title = titles[i],
			description = descriptions[i],
			score = scores[i],
			card = cardHolders[i],
		}
		cardHolders[i].set_opacity(0.0)
	end
end
log("Got cards")
local current_page = 0

-- Generic request function to my API
local function request(endpoint)
	-- Do not be the reason I need to add a ratelimit to this
	local res = fetch({
		url = API_URL .. endpoint,
		method = "GET",
		headers = { ["Content-Type"] = "application/json" },
		body = '',
	})

	return res.success, res
end

-- Set the search result cards to show data from a table of results
local function render_cards(results)
	for i, card in pairs(cards) do
		local result = results[i]

		if result == nil then
			card.card.set_opacity(0.0)
		else
			card.card.set_opacity(1.0)
			local domain = result[1]
			local tld = result[2]
			local score = result[3]
			local title = result[4]
			local icon = result[5]
			local description = result[6]

			local url = domain .. "." .. tld

			local name = string.upper(string.sub(domain, 1, 1)) .. string.sub(domain, 2, -1)

			card.icon.set_content(i)
			card.name.set_content(name)
			card.url.set_content("buss://" .. url .. "/")
			card.title.set_content(title)
			card.title.set_href("buss://" .. url)
			card.description.set_content(description)
			card.score.set_content("Score " .. score)
		end
	end
end

-- URL Encode: https://smolkit.com/blog/posts/how-to-url-encode-in-lua/
local function url_encode(str)
	str = string.gsub(str, "([^%w%.%- ])", function(c)
	  return string.format("%%%02X", string.byte(c))
	end)
	str = string.gsub(str, " ", "+")
	return str
end

-- Split string on seperator character
local function split_string(inputstr, sep)
	if sep == nil then
	  sep = "%s"
	end
	local t = {}
	for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
	  table.insert(t, str)
	end
	return t
end

local function Search(query, page)
	xpcall(function()
		if page == nil then
			current_page = 1
			page = 1
		end
		query = query or queryTextBox.get_content()
		-- local firstWord = split_string(content, " ")[1]
		log("Searching for " .. query)
		local success, result = request("/search?q="..url_encode(query).."&fuzziness="..(0.4).."&limit="..#cards.."&page="..page)
		if success then
			render_cards(result.domains)
			-- Show elapsed time & results
			local elapsed = math.floor(result['elapsed_time'] * 1000) / 1000
			get("query_results").set_content("About "..result.result_count.." results ("..elapsed.." seconds)")
		else
			render_cards({})
			log(result.error)
		end
	end,warn)
end

local function set_page(newPage)
	current_page = newPage
	
	if current_page < 0 then current_page = 0 end
	Search(nil, current_page)
	get("pagenumber").set_content("Page " .. current_page)
	log("Page set to " .. current_page)
end

local TOTAL_DOMAINS = "ERROR"
do
	local success, response = request("/count")
	if success then
		TOTAL_DOMAINS = response.count
	else
		warn(response.error)
	end
end

get("info_header").set_content("About " .. TOTAL_DOMAINS .. " Websites! Please give up to 24 hours for your domain to be listed. Created by _creare_")
get("searchbtn").on_click(Search)
get("luckybtn").on_click(function()xpcall(function()
	local success, response = request("/random")
	if success then
		render_cards({response.page})
		-- Show elapsed time & results
		local elapsed = math.floor(response['elapsed_time'] * 1000) / 1000
		get("query_results").set_content("Random site in " .. elapsed .. " seconds")
	else
		warn(response.error)
	end
end, warn)end)

queryTextBox.on_submit(Search)

get("nextpagebtn").on_click(function()xpcall(function()
	set_page(current_page + 1)
end,warn)end)

get("prevpagebtn").on_click(function()xpcall(function()
	set_page(current_page - 1)
end,warn)end)
end,warn)