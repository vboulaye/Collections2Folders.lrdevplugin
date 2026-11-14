local LrExportSession = import 'LrExportSession'
local LrFileUtils = import 'LrFileUtils'
local LrPathUtils = import 'LrPathUtils'
local Utils = require 'Utils'

local mediaFileExtensions = {
  jpg = true, jpeg = true, png = true, tif = true, tiff = true,
  psd = true, dng = true, heic = true, avif = true,
  raw = true, cr2 = true, cr3 = true, nef = true, nrw = true,
  arw = true, raf = true, orf = true, rw2 = true, pef = true,
  srw = true, ['3fr'] = true, iiq = true, dcr = true, kdc = true,
  mos = true, mrw = true, rwl = true, x3f = true, erf = true,
  fff = true, mef = true, cap = true, mov = true, mp4 = true,
  m4v = true, avi = true, mpg = true, mpeg = true,
}

local function addExpectedPaths(exportSession, expectedPaths, checkForFreshExports)
  for _, rendition in exportSession:renditions() do
    local destinationPath = rendition.destinationPath
    expectedPaths[LrPathUtils.standardizePath(destinationPath)] = true

    if checkForFreshExports then
      local fileAttributes = LrFileUtils.fileAttributes(destinationPath)
      local existingModificationDate = fileAttributes.fileModificationDate
      local lastEditTime = rendition.photo:getRawMetadata('lastEditTime')

      -- Both timestamps use Lightroom's seconds-since-2001 time base.
      -- Re-export on equal timestamps to avoid missing edits within the same second.
      if type(existingModificationDate) == 'number'
        and type(lastEditTime) == 'number'
        and existingModificationDate > lastEditTime then
        rendition:skipRender()
      end
    end
  end
end

local function deleteUnmatchedMediaFiles(outputPath, expectedPaths)
  local unmatchedFiles = {}
  for filePath in LrFileUtils.files(outputPath) do
    local extension = LrPathUtils.extension(filePath):lower():gsub('^%.', '')
    local normalizedPath = LrPathUtils.standardizePath(filePath)
    if mediaFileExtensions[extension] and not expectedPaths[normalizedPath] then
      table.insert(unmatchedFiles, filePath)
    end
  end

  for _, filePath in ipairs(unmatchedFiles) do
    LrFileUtils.delete(filePath)
  end
end

local function exportCollection(collection, path, exportSettings, deleteUnmatchedFiles)
  local allPhotos = collection:getPhotos()
  local photos = {}
  for _, photo in ipairs(allPhotos) do
    if photo:getRawMetadata('rating') == 5 and photo:getRawMetadata('pickStatus') ~= -1 then
      table.insert(photos, photo)
    end
  end

  if Utils.len(photos) == 0 and not deleteUnmatchedFiles then
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

  local expectedPaths = {}

  -- Keep files for photos still in the collection, including photos that no
  -- longer meet the export rating/flag filter.
  if deleteUnmatchedFiles and Utils.len(allPhotos) > 0 then
    local allPhotosSession = LrExportSession({
      photosToExport = allPhotos,
      exportSettings = renameEx,
      outputPath = outputPath,
    })
    addExpectedPaths(allPhotosSession, expectedPaths, false)
  end

  if Utils.len(photos) > 0 then
    local exportSession = LrExportSession({
      photosToExport = photos,
      exportSettings = renameEx,
      outputPath = outputPath,
    })

    addExpectedPaths(exportSession, expectedPaths, true)
    exportSession:doExportOnCurrentTask()
  end

  if deleteUnmatchedFiles then
    deleteUnmatchedMediaFiles(outputPath, expectedPaths)
  end
end

return {
  exportCollection = exportCollection
}
