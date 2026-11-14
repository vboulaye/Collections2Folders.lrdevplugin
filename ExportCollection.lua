local LrExportSession = import 'LrExportSession'
local Utils = require 'Utils'

local function exportCollection(collection, path, exportSettings) 
  local photos = {}
  for _, photo in ipairs(collection:getPhotos()) do
    if photo:getRawMetadata('rating') == 5 and photo:getRawMetadata('pickStatus') ~= -1 then
      table.insert(photos, photo)
    end
  end

  if (Utils.len(photos) == 0) then
    return
  end

  local folderName = collection:getName():gsub("/", '-'):gsub(":", "-"):gsub("!", ""):gsub("?", ""):gsub("¿", ""):gsub("¡", "")
  local outputPath = Utils.defineDestination(path, folderName)

  if not exportSettings then
    exportSettings = Utils.loadExportSettings()
  end
  exportSettings['LR_export_destinationType'] = "specificFolder"
  exportSettings['LR_export_destinationPathPrefix'] = outputPath
  exportSettings['LR_export_useSubfolder'] = false
  local renameEx = exportSettings

  local exportSession = LrExportSession({
    photosToExport = photos,
    exportSettings = renameEx,
    outputPath = outputPath,
  })

  exportSession:doExportOnCurrentTask()
end

return {
  exportCollection = exportCollection
}
