get("version").set_content("v0.0.1")
local query = get("query")
local cards = get("card", true);

local links = get("link", true)
local descriptions = get("desc", true)
local domains = get("domain", true)

local visible = false;

local page = 0
local cardCount = #cards


function log(msg)
	get("error").set_content(msg)
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
	return domains
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
		local domain = domainList[i+page*cardCount]
		local url = domainList["name"] .. "." .. domainList["tld"]

		domain.set_content(url)
		link.set_content(url)
		link.set_href("buss://" .. url)
		desc.set_content(domain["ip"])
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
	
	get("pagenumber").set_content("p."..page)
end


log("Getting domains...")
local domainList = load_domains()
log("Got domains")

local sortedDomains = domainList

query.on_submit(function(content)
	if not visible then
		for k,v in pairs(cards) do
			v.set_opacity(1.0)
		end
		visible = true
	end
	
	sortedDomains = sort_domains(domainList, content)
	SetPage(0)
	RenderDomains(sortedDomains)
end)



get("nextpagebtn").on_input(function()
	SetPage(page + 1)
	RenderDomains(sortedDomains)
end)

get("nextpagebtn").on_input(function()
	SetPage(page - 1)
	RenderDomains(sortedDomains)
end)
