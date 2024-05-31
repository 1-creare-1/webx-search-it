if get == nil then get, fetch = require(game:GetService("ServerStorage").Types) end

get("version").set_content("v0.0.7")
local query = get("query")
local cards = get("card", true);

local links = get("link", true)
local descriptions = get("desc", true)
local domains = get("domain", true)

local visible = false;

local page = 0
local cardCount = #cards

local outputLabel, errorLabel = get("output"), get("error")
function log(msg)
	outputLabel.set_content(msg)
end

function warn(msg)
	errorLabel.set_content(msg)
end

-- Returns the Levenshtein distance between the two given strings
function levenshtein(str1, str2)
	local len1 = string.len(str1)
	local len2 = string.len(str2)
	local matrix = {}
	local cost = 0

	-- quick cut-offs to save time
	if (len1 == 0) then
		return len2
	elseif (len2 == 0) then
		return len1
	elseif (str1 == str2) then
		return 0
	end

	-- initialise the base matrix values
	for i = 0, len1, 1 do
		matrix[i] = {}
		matrix[i][0] = i
	end
	for j = 0, len2, 1 do
		matrix[0][j] = j
	end

	-- actual Levenshtein algorithm
	for i = 1, len1, 1 do
		for j = 1, len2, 1 do
			if (str1:byte(i) == str2:byte(j)) then
				cost = 0
			else
				cost = 1
			end

			matrix[i][j] = math.min(matrix[i-1][j] + 1, matrix[i][j-1] + 1, matrix[i-1][j-1] + cost)
		end
	end

	-- return the last value - this is the Levenshtein distance
	return matrix[len1][len2]
end

function query_domain(ip)
	-- https://github.com/creeperita09/Webx-bio
	-- https://raw.githubusercontent.com/creeperita09/Webx-bio/main/index.html
	local url = ip
	if string.find(ip, "github") then
		url = string.gsub(ip, "https://github.com/", "https://raw.githubusercontent.com/") .. "/main/index.html"
	end
	local res = fetch({
		url = url,
		method = "GET",
		headers = { ["Content-Type"] = "application/json" },
		body = '',
	})
	return res
end

function load_domains()
	local res = fetch({
		url = "https://api.buss.lol/domains",
		method = "GET",
		headers = { ["Content-Type"] = "application/json" },
		body = '',
	})
	return res
end

function sort_domains(domains, query)
	local sorted = domains
	table.sort(sorted, function(a, b)
		return levenshtein(query, a) < levenshtein(query, b)
	end)
	
	return sorted
end

function percentage(value, min, max)
	if value < min then
		value = min
	elseif value > max then
		value = max
	end

	local percentage = ((value - min) / (max - min)) * 100

	if percentage < 0 then
		percentage = 0
	elseif percentage > 100 then
		percentage = 100
	end

	return string.format("%.2f", percentage)
end

function RenderDomains(domainList)
	for i, _ in pairs(cards) do
		local link = links[i];
		local desc = descriptions[i];
		local domain = domains[i];

		-- local URL = percentage(v["rating"], -999, 2) .. "% | buss://" .. v["domain"];
		local thisDomain = domainList[i+page*cardCount]
		local url = thisDomain["name"] .. "." .. thisDomain["tld"]

		domain.set_content(url)
		link.set_content(url)
		link.set_href("buss://" .. url)
		desc.set_content(thisDomain["ip"])
	end
end

function SetPage(newPage)
	page = newPage
	
	if page < 0 then
		page = 0
	end
	
	if page > 100 then
		page = 100
	end
	
	get("pagenumber").set_content("Page "..page)
	log("Page set to " .. page)
end


log("Getting domains...")
local domainList = load_domains()
log("Got domains")

local sortedDomains = domainList

query.on_submit(function(content)xpcall(function(content)
		if not visible then
			for k,v in pairs(cards) do
				v.set_opacity(1.0)
			end
			visible = true
		end

		sortedDomains = sort_domains(domainList, content)
		SetPage(0)
		RenderDomains(sortedDomains)
end,warn,content)end)

get("nextpagebtn").on_click(function(content)xpcall(function(content)
	log("Next page")
	SetPage(page + 1)
	RenderDomains(sortedDomains)
end,warn)end)

get("prevpagebtn").on_click(function(content)xpcall(function(content)
	log("Preious page")
	SetPage(page - 1)
	RenderDomains(sortedDomains)
end,warn)end)
