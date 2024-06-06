local get, fetch = get, fetch

local VERSION = "v1.0.0"
local API_URL = "https://webx-external-api.vercel.app/api/v1"
-- local API_URL = "http://127.0.0.1:5000/api/v1"

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
	local links = get("results_link", true)
	local descriptions = get("results_desc", true)
	local scores = get("results_score", true)
	local cardHolders = get("card", true)
	log("ea sports")
	for i = 1, #cardHolders do
		cards[i] = {
			Link = links[i],
			Description = descriptions[i],
			Scores = scores[i],
			Card = cardHolders[i],
		}
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
	return true, res.domains
end

local function render_cards(results)
	for i, card in pairs(cards) do
		local result = results[i]

		if result == nil then
			card.Card.set_opacity(0.0)
		else
			card.Card.set_opacity(1.0)
			local domain = result[1]
			local tld = result[2]
			local score = result[3]

			local url = domain .. "." .. tld

			card.Scores.set_content(score)
			card.Link.set_content(url)
			card.Link.set_href("buss://" .. url)
			-- card.Description.set_content()
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
			render_cards(result)
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