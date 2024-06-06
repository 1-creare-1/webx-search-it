local get, fetch = get, fetch

local VERSION = "v1.1.0"
-- local API_URL = "https://webx-external-api.vercel.app/api/v1"
local API_URL = "http://127.0.0.1:5000/api/v1"

get("version").set_content(VERSION)

-- Debug Helpers
local outputLabel, errorLabel = get("output"), get("error")
function log(msg)
	outputLabel.set_content(msg)
end

function warn(msg)
	errorLabel.set_content(msg)
end

log("Loaded")
xpcall(function()

local queryTextBox = get("query")

-- Get the cards
local cards = {}
do
--[[

<div>
	<h6 class="card_icon">ICON</h6>
	<div class="card_sublist">
		<p class="card_sitename">Website Name</p>
		<p class="card_url">buss://websitename.tld</p>
	</div>
</div>

<a href="https://example.com" class="card_title">Website Title - Cool Stuff</a>
<p class="card_description">Website Description lore ipsum lore ipsum lore ipsum lore ipsum lore ipsum lore ipsum lore ipsum </p>
<p class="card_score">Rank 0</p>
]]
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
local page = 0

local function make_query(term, limit, fuzziness)
	-- Do not be the reason I need to add a ratelimit to this
	local res = fetch({
		url = API_URL .. "/search?q="..term.."&fuzziness="..fuzziness.."&limit="..limit,
		method = "GET",
		headers = { ["Content-Type"] = "application/json" },
		body = '',
	})

	if res.error then
		return false, res.error
	end
	-- log("Got " .. #res .. " results: " .. res)
	return true, res
end

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

			local url = domain .. "." .. tld

			local name = string.upper(string.sub(domain, 1, 1)) .. string.sub(domain, 2, -1)

			card.icon.set_content(i)
			card.name.set_content(name)
			card.url.set_content("buss://" .. url .. "/")
			card.title.set_content(domain .. " - Cool Stuff TODO")
			card.title.set_href("buss://" .. url)
			card.description.set_content("Description TODO")
			card.score.set_content(score)
		end
	end
end

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

-- function SetPage(newPage)
-- 	page = newPage
	
-- 	if page < 0 then
-- 		page = 0
-- 	end
	
-- 	if page > 100 then
-- 		page = 100
-- 	end
	
-- 	get("pagenumber").set_content("Page "..page)
-- 	log("Page set to " .. page)
-- end

function Search(content)
	xpcall(function()
		local firstWord = split_string(content, " ")[1]
		log("Searching for " .. firstWord)
		local success, result = make_query(firstWord, #cards, 0.4)
		if success then
			render_cards(result.domains)
			-- Show elapsed time & results
			local elapsed = math.floor((result['elapsed_time'] + 0.5) * 100) / 100
			get("query_results").set_content("About "..#result.domains.." results ("..elapsed.." seconds)")
		else
			render_cards({})
			log(result)
		end
	end,warn)
end

get("searchbtn").on_click(function()
	Search(queryTextBox.get_content())
end)

queryTextBox.on_submit(Search)

-- get("nextpagebtn").on_click(function()xpcall(function()
-- 	-- log("Next page")
-- 	-- SetPage(page + 1)
-- 	-- RenderDomains(sortedDomains)
-- end,warn)end)

-- get("prevpagebtn").on_click(function()xpcall(function()
-- 	-- log("Preious page")
-- 	-- SetPage(page - 1)
-- 	-- RenderDomains(sortedDomains)
-- end,warn)end)
end,warn)