local budoux = {}

function budoux.load_model(raw)
	local model = {}
	for _, k in ipairs({ "UW1", "UW2", "UW3", "UW4", "UW5", "UW6", "BW1", "BW2", "BW3", "TW1", "TW2", "TW3", "TW4" }) do
		model[k] = raw[k] or {}
	end

	local sum = 0
	for _, value in pairs(model) do
		for _, v in pairs(value) do
			sum = sum + v
		end
	end
	model.base_score = -0.5 * sum
	model.parse = function(str)
		return budoux.parse(model, str)
	end
	return model
end

function budoux.load_language_model(module, src)
	local ok, raw = pcall(require, module)
	if not ok then
		raw = dofile(src)
	end
	return budoux.load_model(raw)
end

function budoux.load_japanese_model()
	return budoux.load_language_model(
		"budoux.japanese.ja",
		debug.getinfo(1, "S").source:sub(2):gsub("[^/]*/?$", "") .. "/models/ja.lua"
	)
end

local function concat(chars, i, j)
	if i < 1 then
		return nil
	end
	local ret = ""
	for k = i, j do
		ret = ret .. (chars[k] or "")
	end
	return ret
end

function budoux.score(model, chars, i)
	local s = model.base_score

	s = s + (model.UW1[chars[i - 3 + 1]] or 0)
	s = s + (model.UW2[chars[i - 2 + 1]] or 0)
	s = s + (model.UW3[chars[i - 1 + 1]] or 0)
	s = s + (model.UW4[chars[i + 0 + 1]] or 0)
	s = s + (model.UW5[chars[i + 1 + 1]] or 0)
	s = s + (model.UW6[chars[i + 2 + 1]] or 0)
	s = s + (model.BW1[concat(chars, i - 2 + 1, i)] or 0)
	s = s + (model.BW2[concat(chars, i - 1 + 1, i + 1)] or 0)
	s = s + (model.BW3[concat(chars, i + 1, i + 2)] or 0)
	s = s + (model.TW1[concat(chars, i - 3 + 1, i)] or 0)
	s = s + (model.TW2[concat(chars, i - 2 + 1, i + 1)] or 0)
	s = s + (model.TW3[concat(chars, i - 1 + 1, i + 2)] or 0)
	s = s + (model.TW4[concat(chars, i + 1, i + 3)] or 0)

	return s
end

local function load_lpeg()
	local ok, lpeg = pcall(require, "lpeg")
	if ok then
		return lpeg
	end
	if vim and vim.lpeg then
		return lpeg
	end
end

local function split(str, lpeg)
	if not lpeg then
		return vim.fn.split(str, [[\zs]])
	end
	return (lpeg.Ct(lpeg.C(lpeg.utfR(0, 0x10ffff)) ^ 0)):match(str)
end

function budoux.parse(model, str, lpeg)
	local chars = split(str, lpeg or load_lpeg())
	if #chars == 0 then
		return {}
	end
	local chunks = { chars[1] }
	local last = #chars
	for i = 2, last do
		if budoux.score(model, chars, i - 1) > 0 then
			table.insert(chunks, chars[i])
		else
			chunks[#chunks] = chunks[#chunks] .. chars[i]
		end
	end
	return chunks
end

return budoux
