require 'xlua'
require 'pl'

-- global settings

if package.preload.settings then
   return package.preload.settings
end

-- default tensor type
torch.setdefaulttensortype('torch.FloatTensor')

local settings = {}

local cmd = torch.CmdLine()
cmd:text()
cmd:text("waifu2x")
cmd:text("Options:")
cmd:option("-seed", 11, 'fixed input seed')
cmd:option("-data_dir", "./data", 'data directory')
cmd:option("-test", "images/miku_small.png", 'test image file')
cmd:option("-model_dir", "./models", 'model directory')
cmd:option("-method", "scale", '(noise|scale|noise_scale)')
cmd:option("-noise_level", 1, '(1|2)')
cmd:option("-category", "anime_style_art", '(anime_style_art|photo)')
cmd:option("-color", 'rgb', '(y|rgb)')
cmd:option("-color_noise", 0, 'enable data augmentation using color noise (1|0)')
cmd:option("-scale", 2.0, 'scale')
cmd:option("-learning_rate", 0.00025, 'learning rate for adam')
cmd:option("-random_half", 1, 'enable data augmentation using half resolution image (0|1)')
cmd:option("-crop_size", 128, 'crop size')
cmd:option("-batch_size", 2, 'mini batch size')
cmd:option("-epoch", 200, 'epoch')
cmd:option("-core", 2, 'cpu core')

local opt = cmd:parse(arg)
for k, v in pairs(opt) do
   settings[k] = v
end
if settings.method == "noise" then
   settings.model_file = string.format("%s/noise%d_model.t7",
				       settings.model_dir, settings.noise_level)
elseif settings.method == "scale" then
   settings.model_file = string.format("%s/scale%.1fx_model.t7",
				       settings.model_dir, settings.scale)
elseif settings.method == "noise_scale" then
   settings.model_file = string.format("%s/noise%d_scale%.1fx_model.t7",
				       settings.model_dir, settings.noise_level, settings.scale)
else
   error("unknown method: " .. settings.method)
end
if not (settings.color == "rgb" or settings.color == "y") then
   error("color must be y or rgb")
end
if not (settings.scale == math.floor(settings.scale) and settings.scale % 2 == 0) then
   error("scale must be mod-2")
end
if not (settings.category == "anime_style_art" or
	settings.category == "photo") then
   error(string.format("unknown category: %s", settings.category))
end
if settings.random_half == 1 then
   settings.random_half = true
else
   settings.random_half = false
end
if settings.color_noise == 1 then
   settings.color_noise = true
else
   settings.color_noise = false
end
torch.setnumthreads(settings.core)

settings.images = string.format("%s/images.t7", settings.data_dir)
settings.image_list = string.format("%s/image_list.txt", settings.data_dir)

settings.validation_ratio = 0.1
settings.validation_crops = 30

local srcnn = require './srcnn'
if (settings.method == "scale" or settings.method == "noise_scale") and settings.scale == 4 then
   settings.create_model = srcnn.waifu4x
   settings.block_offset = 13
else
   settings.create_model = srcnn.waifu2x
   settings.block_offset = 7
end

return settings
